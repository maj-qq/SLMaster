"""Extract Microsoft's portable MSVC packages selected from the official VS manifest."""
import concurrent.futures
import hashlib
import json
import pathlib
import sys
import time
import urllib.request
import zipfile

package_list = pathlib.Path(sys.argv[1])
destination = pathlib.Path(sys.argv[2]).resolve()
destination.mkdir(parents=True, exist_ok=True)
packages = json.loads(package_list.read_text(encoding="utf-8-sig"))
if isinstance(packages, dict):
    packages = [packages]

def install(package):
    payload = package["payload"]
    archive = package_list.parent / (package["id"] + ".vsix")
    for attempt in range(4):
        try:
            if not archive.exists() or hashlib.sha256(archive.read_bytes()).hexdigest().lower() != payload["sha256"].lower():
                with urllib.request.urlopen(payload["url"], timeout=60) as response, archive.open("wb") as output:
                    while chunk := response.read(1024 * 1024):
                        output.write(chunk)
            if hashlib.sha256(archive.read_bytes()).hexdigest().lower() != payload["sha256"].lower():
                raise RuntimeError("Package checksum mismatch")
            with zipfile.ZipFile(archive) as source:
                for member in source.infolist():
                    name = member.filename.replace("\\", "/")
                    if not name.startswith("Contents/") or member.is_dir():
                        continue
                    target = (destination / name.removeprefix("Contents/")).resolve()
                    if not target.is_relative_to(destination):
                        raise RuntimeError("Unsafe archive path")
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(source.read(member))
            print("Installed:", package["id"], flush=True)
            return
        except Exception:
            if attempt == 3:
                raise
            time.sleep(2)

with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    list(pool.map(install, packages))
