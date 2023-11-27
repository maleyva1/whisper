import std/unittest
from std/os import fileExists

import whisper/highlevel

test "End to end usage":
    if not fileExists("ggml-base.en.bin"):
        stderr.writeLine("ggml-base.en.bin does not exist!")
        stderr.writeLine("Ensure file exists before proceeding")
        fail()
    let options = newDefaultOptions("ggml-base.en.bin")
    let w = newWhisper(options)
    try:
        let result = w.infer("samples/jfk.wav")
        doAssert result == " And so my fellow Americans, ask not what your country can do for you, ask what you can do for your country."
    except WhisperInferenceError:
        fail()