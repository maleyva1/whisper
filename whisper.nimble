# Package

version       = "0.1.1"
author        = "Mark Leyva"
description   = "Nim bindings for Whisper.cpp"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"
requires "wave >= 1.1.0"
requires "futhark >= 0.13.1"

import std/distros

before lib:
    exec "git submodule update --init --recursive"

task lib, "Build whisper.cpp":
    exec "cd src/whisper.cpp && cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j $(nproc)"

task cleanlib, "Clean whisper.cpp":
    if dirExsts("src/whisper.cpp/build"):
        exec "cd src/whisper.cpp && cmake --build build --clean-first"
    else:
        echo "libwhisper not built. Doing nothing..."

task downloadModel, "Download model":
    if defined(windows):
        exec "cd src/whisper.cpp/models && download-ggml-model.cmd base.en"
    elif defined(linux) or defineD(windows):
        exec "download-ggml-model.sh base.en"
    else:
        echo "Unsupport OS"