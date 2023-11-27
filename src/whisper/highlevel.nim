import bindings
import utils

type
    WhisperAllocationError* = object of CatchableError
    WhisperInferenceError* = object of CatchableError
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
    result = WhisperOptions(mlKind: FromFile, filePath: file)
    result.params = contextDefaultParams()

proc newDefaultOptions*(buffer: seq[byte]): WhisperOptions =
    result = WhisperOptions(mlKind: FromBuffer, buffer: buffer)
    result.params = contextDefaultParams()

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

proc transcribe*(whisper: Whisper; buffer: seq[float]): string =
    ## Transcribe from `buffer`. Returns the transcribed text.
    ## 
    let fullParams = fullDefaultParams(SamplingStrategy.Greedy)
    var temp = newSeq[cfloat]()
    for i in buffer:
        temp.add(i.cfloat)
    if full(whisper.context, fullParams, temp[0].addr, temp.len.cint) != 0:
        raise newException(WhisperInferenceError, "Unable to transcribe from audio")
    let n = fullNSegments(whisper.context)
    for i in countup(0 , n - 1):
        result &= fullGetSegmentText(whisper.context, i.cint)

proc transcribe*(whisper: Whisper; audioSamplePath: string): string =
    ## Transcribe from `audioSamplePath`. Returns the transcribed
    ## text.
    ## 
    ## **Note**: `audioSamplePath` must be a 16 kHz WAV file
    ## 
    let fullParams = fullDefaultParams(SamplingStrategy.Greedy)
    var buffer = readWav(audioSamplePath)
    if full(whisper.context, fullParams, buffer[0].addr, buffer.len.cint) != 0:
        raise newException(WhisperInferenceError, "Unable to transcribe from audio")
    let n = fullNSegments(whisper.context)
    for i in countup(0 , n - 1):
        result &= fullGetSegmentText(whisper.context, i.cint)

proc `=destroy`*(whisper: Whisper) =
    ## Deallocates the whisper context
    ## 
    if whisper.context != nil:
        free(whisper.context)