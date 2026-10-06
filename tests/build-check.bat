@echo off
rem Builds tests/consumer (the gallery as a compiled app linking HighlighterUI) to
rem prove the CMake module works. Needs VS 2022 Build Tools and Qt 6.10.2 msvc.
setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
copy /y "%~dp0..\gallery\Gallery.qml" "%~dp0consumer\Gallery.qml" >nul
"C:\Qt\Tools\CMake_64\bin\cmake.exe" -S "%~dp0consumer" -B "%~dp0consumer\build" -G Ninja -DCMAKE_MAKE_PROGRAM=C:/Qt/Tools/Ninja/ninja.exe -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=C:/Qt/6.10.2/msvc2022_64 || exit /b 1
"C:\Qt\Tools\CMake_64\bin\cmake.exe" --build "%~dp0consumer\build" || exit /b 1
echo Built %~dp0consumer\build\HighlighterUIGallery.exe
