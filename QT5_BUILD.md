# Qt 5.15 构建说明

扫描结果保存需要 OpenCV 的 TIFF 编码器，用于无损保存 32 位浮点深度图。编译 OpenCV 时须启用 `-DWITH_TIFF=ON -DBUILD_TIFF=ON`，Release 和 Debug 都要重新编译安装，并通过 `scripts/deploy.ps1` 更新运行目录中的 DLL。保存结果包含所选的 PLY/PCD 点云，以及同名的 BMP 纹理图和 TIFF 深度图。

本工作区默认使用 `.deps/Qt/5.15.2/msvc2019_64` 中的 Qt 5.15.2、MSVC 2022 x64 和 Ninja。Qt 的 MSVC 2019 二进制与当前 MSVC 工具链配合使用；PCL、VTK 和相机 SDK 也均为 MSVC 二进制库，因此不能使用 MinGW Kit。

Qt 5 版 VTK 界面模块位于 `.deps/vtk-qt-install`。不要混入 `.deps/vtk-qt6-install` 或 Qt 6 的运行库。

Debug 需要对应的 Qt、PCL、VTK 和 OpenCV 调试库。当前工作区已安装两种配置；OpenCV 调试库文件名包含 `4120d`。项目使用 MSVC 动态运行库，Debug 为 `/MDd`，其他配置为 `/MD`。

## 命令行构建

在项目根目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
.\build\gui\SLMasterGui.exe
```

`build.ps1` 默认构建 Release。Debug 使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Configuration Debug
```

脚本先构建并安装相同配置的 VTK/Qt 界面模块，再使用 `--fresh` 重新生成应用的 CMake 缓存。VTK 9.3 源码需已放在 `.deps/vtk-qt-source`。可通过 `-QtRoot` 指定其他 Qt 5.15 MSVC x64 安装目录。

CMake 在应用链接后自动部署对应配置的 Qt 平台插件、QML 插件和其他运行依赖。Debug 使用 `qwindowsd.dll`，Release 使用 `qwindows.dll`。手动重新部署时可执行 `scripts/deploy.ps1`，它默认读取构建目录中的 `CMAKE_BUILD_TYPE`；多配置构建需显式传入 `-Configuration`、`-BuildDirectory` 和 `-Executable`。

Ninja、CMake、sdktool 和 Qt Creator 本身可以来自 `C:/Qt/Qt6/Tools`；工具所在目录不决定应用链接的 Qt 版本。

## Qt Creator

注册 Kit：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-qtcreator-kit.ps1
```

重启 Qt Creator，选择 `SLMaster Qt 5.15.2 MSVC x64`，构建目录设为项目内的 `build`。

Kit 使用 Qt 5 版 VTK 配置，并将旧设置备份到 `.deps/qtcreator-settings-backup`。切换 Qt 大版本时，应使用独立或清理过的构建目录，避免混用 QML 插件和 DLL。

首次使用某个配置前，先运行上述 `build.ps1` 命令以安装相应的 VTK/Qt 模块。随后在 Qt Creator 中正常构建即可自动部署，不需要单独复制平台插件。`QML debugging is enabled` 是 Debug 构建的提示，不是启动失败原因。
