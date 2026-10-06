@echo off
rem Opens the ParamKit gallery with Qt's qml runner: no build needed.
setlocal
set "QML="
for %%V in (6.11.2 6.10.3 6.10.2) do (
    if not defined QML if exist "C:\Qt\%%V\msvc2022_64\bin\qml.exe" set "QML=C:\Qt\%%V\msvc2022_64\bin\qml.exe"
)
if not defined QML (
    echo Could not find qml.exe under C:\Qt. Edit run-gallery.bat to point at it.
    exit /b 1
)
"%QML%" -I "%~dp0." "%~dp0gallery\Gallery.qml" %*
