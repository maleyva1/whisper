# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import std/unittest
import std/streams

import whisper/bindings

test "Full Params by Ref":
    var params = fullDefaultParamsByRef(SamplingStrategy.Greedy)
    doAssert params != nil
    freeParams(params)

test "Context Params by Ref":
    var params = contextDefaultParamsByRef()
    doAssert params != nil
    freeContextParams(params)

test "Init from file with params":
    let file = "ggml-base.en.bin".cstring
    var 
        params = contextDefaultParams()
        ctx = initFromFileWithParams(file, params)
    doAssert ctx != nil
    free(ctx)

test "Init from buffer with params":
    let file = "ggml-base.en.bin"
    var 
        f = newFileStream(file, fmRead)
        buffer: string
    if f.isNil():
        fail()
    else:
        buffer = f.readAll()
    f.close()
    var
        params = contextDefaultParams()
        ctx = initFromBufferWithParams(buffer[0].addr, buffer.len.csize_t, params)
    doAssert ctx != nil
    free(ctx)