# Qt 6 构建说明

本工作区使用 Qt 6.8.3、MSVC 2022 x64 和 Ninja。PCL、VTK 与相机 SDK 均为 MSVC 二进制库，因此不能选择 MinGW Kit。

## 命令行构建

在项目根目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deploy.ps1
.\build\gui\SLMasterGui.exe
```

`build.ps1` 会使用 `--fresh` 重新生成 CMake 缓存，项目目录移动后无需手工修改旧缓存。`deploy.ps1` 会复制 Qt、PCL、VTK、OpenCV 和相机 SDK 的运行依赖。

## Qt Creator

首次使用或 Qt Creator 配置被清理后，执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-qtcreator-kit.ps1
```

重启 Qt Creator，选择 `SLMaster Qt 6.8.3 MSVC 2022 x64`，构建目录设为项目内的 `build`。如果弹窗中显示 `mingw_64`，应丢弃该配置并切换到上述 MSVC Kit。
