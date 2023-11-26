import bindings

type
    WhisperAllocationError* = object of CatchableError
    ModelLoadingKind* = enum
        FromFile, FromBuffer
    WhisperOptions* = object
        params*: ContextParams
        case mlKind*: ModelLoadingKind:
            of FromFile:
                filePath*: string
            of FromBuffer:
                buffer*: seq[byte]
    Whisper* = object
        context: ptr Context

proc newDefaultOptions*(): WhisperOptions =
    result.params = contextDefaultParams()

proc newDefaultOptions*(file: string): WhisperOptions =
    result.params = contextDefaultParams()
    result.mlKind = FromFile
    result.filePath = file

proc newDefaultOptions*(buffer: seq[byte]): WhisperOptions =
    result.params = contextDefaultParams()
    result.mlKind = FromBuffer
    result.buffer = buffer

proc newWhisper*(options: WhisperOptions): Whisper =
    case options.mlKind:
        of FromFile:
            result.context = initFromFileWithParams(options.filePath.cstring,
                    options.params)
        of FromBuffer:
            result.context = initFromBufferWithParams(options.buffer[0].addr,
                    options.buffer.len.csize_t, options.params)
    if result.context == nil:
        raise newException(WhisperAllocationError, "Unable to initialize Whisper context")

proc transcribe(whisper: Whisper; buffer: seq[cfloat]): bool =
    let fullParams = fullDefaultParams(SamplingStrategy.Greedy)
    return full(whisper.context, fullParams, buffer[0].addr, buffer.len.cint) == 0

proc transcribe*(whisper: Whisper; audioSamplePath: string): bool =
    let fullParams = fullDefaultParams(SamplingStrategy.Greedy)
    return full(whisper.context, fullParams, nil, 0) == 0

proc `=destroy`*(whisper: Whisper) =
    if whisper.context != nil:
        free(whisper.context)