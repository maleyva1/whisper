# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import std/unittest
import std/streams

import whisper

test "Full Params by Ref":
    var params = whisperFullDefaultParamsByRef(WHISPER_SAMPLING_GREEDY)
    doAssert params != nil
    whisperFreeParams(params)

test "Context Params by Ref":
    var params = whisperContextDefaultParamsByRef()
    doAssert params != nil
    whisperFreeContextParams(params)

test "Init from file with params":
    let file = "ggml-base.bin".cstring
    var 
        params = whisperContextDefaultParams()
        ctx = whisperInitFromFileWithParams(file, params)
    doAssert ctx != nil
    whisperFree(ctx)

test "Init from buffer with params":
    let file = "ggml-base.bin"
    var 
        f = newFileStream(file, fmRead)
        buffer: string
    if f.isNil():
        fail()
    else:
        buffer = f.readAll()
    f.close()
    var
        params = whisperContextDefaultParams()
        ctx = whisperInitFromBufferWithParams(buffer[0].addr, buffer.len.csize_t, params)
    doAssert ctx != nil
    whisperFree(ctx)