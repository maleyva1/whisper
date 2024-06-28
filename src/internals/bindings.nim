import std/os

import futhark

{.passL: currentSourcePath.parentDir() & "/../whisper.cpp/build/libwhisper.so".}

importc:
    path "../whisper.cpp"
    "whisper.h"
