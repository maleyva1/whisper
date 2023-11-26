# Package

version       = "0.1.0"
author        = "Mark Leyva"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"

task libwhisper, "Build libwhisper":
    exec "cmake -G Ninja -B build -S whisper.cpp -DBUILD_SHARED_LIBS=OFF"
    exec "cmake --build build/ --config Release"
