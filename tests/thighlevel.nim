import std/unittest
from std/os import fileExists
import std/streams

import whisper/highlevel

proc ensureModelExists(): void =
    if not fileExists("ggml-base.bin"):
        stderr.writeLine("ggml-base.bin does not exist!")
        stderr.writeLine("Ensure file exists before proceeding")
        fail()

test "Liftime tracking hooks":
    ensureModelExists()
    let options = newDefaultOptions("ggml-base.bin")
    let 
        w = newWhisper(options)
        x: Whisper = w
        y: Whisper = x
        z: WHisper = y
    try:
        discard z.infer("samples/jfk.wav")
    except WhisperInferenceError:
        fail()

test "End to end usage":
    ensureModelExists()
    let options = newDefaultOptions("ggml-base.bin")
    let w = newWhisper(options)
    try:
        let result = w.infer("samples/jfk.wav")
        doAssert result == " And so my fellow Americans ask not what your country can do for you. Ask what you can do for your country."
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
        doAssert result == " Hello, how are you?"
    except WhisperInferenceError:
        stderr.writeLine(getCurrentExceptionMsg())
        fail()