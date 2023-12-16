# Nim bindings for libwhisper

This package provides Nim bindings for `libwhisper` (1.5.0+)
(AKA [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)).

There are two major bindings:

- simple bindings
- higher level Nim wrapped bindings

The simple bindings expose the entirety of the `libwhisper` C API
to Nim, while the higher level Nim wrapped bindings provide simpler
but limited functionality.

## Example

Using the high level bindings, we can run inference on a 16-bit WAV files,
with the default `libwhisper` parameters. The high level bindings use Nim's
lifetime tracking hooks, so users need don't need to manually free resources.

```nim
import whisper/highlevel

let 
    options = newDefaultOptions("ggml-base.en.bin")
    w = newWhisper(options)
    result = w.infer("samples/jfk.wav")
```

The equivalent using the simple bindings is more cumbersome, but is a one-to-one
mapping of the C API.

```nim
import whisper/bindings

let file = "ggml-base.en.bin".cstring
var 
    params = whisperContextDefaultParams()
    ctx = whisperInitFromFileWithParams(file, params)
    fullParams = whisperFullDefaultParams(WHISPER_SAMPLING_GREEDY)
# Read 16-bit WAV file into bufffer (ptr cfloat)
# bufferLen contains the size of the buffer
whisperFull(ctx, fullParams, buffer, bufferLen)
whisperFree(ctx) # Free libwhisper context
```
