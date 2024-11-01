import std/unittest
from std/os import fileExists

import whisper

proc ensureModelExists(): void =
    if not fileExists("ggml-base.bin"):
        stderr.writeLine("ggml-base.bin does not exist!")
        stderr.writeLine("Ensure file exists before proceeding")
        fail()

test "Liftime tracking hooks":
    ensureModelExists()
    proc helper(): bool =
        ## std/unitest causes scoping issues
        ## This helper proc wraps the lifetime tracking hooks
        result = true
        let options = newDefaultOptions("ggml-base.bin")
        var
            w = newWhisper(options)
            x = ensureMove w
            y = ensureMove x
            z = ensureMove y
        try:
            discard z.infer("samples/jfk.wav")
        except WhisperInferenceError:
            result = false
    if not helper():
        fail()

test "End to end usage":
    ensureModelExists()
    let options = newDefaultOptions("ggml-base.bin")
    let w = newWhisper(options)
    try:
        let result = w.infer("samples/jfk.wav")
        echo result
        doAssert result == " And so, my fellow Americans, ask not what your country can do for you, ask what you can do for your country."
    except WhisperInferenceError:
        fail()

test "Transcription in non-English language":
    ensureModelExists()
    let 
        options = newDefaultOptions("ggml-base.bin")
        w = newWhisper(options)
    try:
        let result = w.infer("samples/spanish.wav", "es")
        doAssert result == " Hola, como estás?"
    except WhisperInferenceError:
        stderr.writeLine(getCurrentExceptionMsg())
        fail()

test "High level translation":
    ensureModelExists()
    let 
        options = newDefaultOptions("ggml-base.bin")
        w = newWhisper(options)
    try:
        let result = w.infer("samples/spanish.wav", "es", true)
        echo result
        doAssert result == " Hi, how are you?"
    except WhisperInferenceError:
        stderr.writeLine(getCurrentExceptionMsg())
        fail()