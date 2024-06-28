# Package

version       = "1.0.0"
author        = "Mark Leyva"
description   = "Nim bindings for Whisper.cpp"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"
requires "wave >= 1.1.0"
requires "futhark >= 0.13.1"

import std/distros


task lib, "Build whisper.cpp":
    withDir("src/whisper.cpp"):
        if not fileExists("CMakeLists.txt"):
            exec "git submodule update --init --recursive"
        exec "cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j $(nproc)"

task cleanlib, "Clean whisper.cpp":
    withDir("src/whisper.cpp"):
        if dirExists("build"):
            exec "cmake --build build -- clean"
        else:
            echo "libwhisper not built. Doing nothing..."

task downloadModel, "Download model":
    if defined(windows):
        withDir("src/whisper.cpp/models"):
            exec "./download-ggml-model.cmd base.en"
    elif defined(linux) or defined(macosx):
        withDir("src/whisper.cpp/models"):
            exec "./download-ggml-model.sh base.en"
    else:
        echo "Unsupported OS"
    mvFile("src/whisper.cpp/models/ggml-base.en.bin", thisDir() & "/ggml-base.en.bin")
