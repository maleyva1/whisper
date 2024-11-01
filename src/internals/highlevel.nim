import bindings
import utils

type
    WhisperAllocationError* = object of CatchableError ## \
     ## Exception thrown when run into an allocation issue in
     ## libwhisper
     ## 
    WhisperInferenceError* = object of CatchableError ## \
     ## Exception thrown when the inference fails
     ## 
    ModelLoadingKind = enum
        FromFile, FromBuffer
    WhisperOptions* = object ## libwhisper initialization options
        params: struct_whisper_context_params
        case mlKind: ModelLoadingKind:
            of FromFile:
                filePath: string
            of FromBuffer:
                buffer: seq[byte]
    Whisper* = object ## \
        ## Wraps libwhisper's context to be used in Nim
        ## 
        context: ptr struct_whisper_context 
    ConvFunc = proc(): seq[cfloat]

proc newDefaultOptions*(file: string): WhisperOptions =
    ## Create a new `WhisperOptions` object,
    ## loading the libwhisper model from `file`.
    ## 
    result = WhisperOptions(mlKind: FromFile, filePath: file)
    result.params = whisperContextDefaultParams()

proc newDefaultOptions*(buffer: seq[byte]): WhisperOptions =
    ## Create a new `WhisperOptions` object,
    ## loading the libwhisper model from `buffer`.
    ## 
    result = WhisperOptions(mlKind: FromBuffer, buffer: buffer)
    result.params = whisperContextDefaultParams()

proc newWhisper*(options: WhisperOptions): Whisper =
    ## Create a new `Whisper` object with `options`
    ## 
    case options.mlKind:
        of FromFile:
            result.context = whisperInitFromFileWithParams(options.filePath.cstring,
                    options.params)
        of FromBuffer:
            result.context = whisperInitFromBufferWithParams(options.buffer[0].addr,
                    options.buffer.len.csize_t, options.params)
    if result.context == nil:
        raise newException(WhisperAllocationError, "Unable to initialize Whisper context")
    else:
        discard whisperCtxInitOpenvinoEncoder(result.context, nil, "CPU".cstring, nil)

proc sharedLogic(whisper: Whisper; conv: ConvFunc; language: string; translate: bool): string =
    ## Shared logic
    ## 
    if language != "auto" and whisperLangId(language.cstring) == -1:
        raise newException(WhisperInferenceError, language & " is unknown")
    if language != "en":
        if whisperIsMultilingual(whisper.context) == 0:
            raise newException(WhisperInferenceError, "Loaded whisper model is not multilingual")
    var fullParams = whisperFullDefaultParams(WHISPER_SAMPLING_GREEDY)
    fullParams.strategy = WHISPER_SAMPLING_BEAM_SEARCH
    fullParams.language = language.cstring
    fullParams.translate = translate
    fullParams.greedy.bestOf = 5
    fullParams.beamSearch.beamSize = 5
    var buffer = conv()
    if whisperFull(whisper.context, fullParams, buffer[0].addr, buffer.len.cint) != 0:
        raise newException(WhisperInferenceError, "Unable to transcribe from audio")
    let n = whisperFullNSegments(whisper.context)
    for i in countup(0 , n - 1):
        result &= whisperFullGetSegmentText(whisper.context, i.cint)

proc infer*(whisper: Whisper; audioSamplePath: string; language: string = "en"; translate: bool = false): string =
    ## Transcribe from `audioSamplePath`, assuming the audio is in language `language`.
    ## Returns the transcribed Text.
    ## 
    ## **Note**: `audioSamplePath` must be a 16 kHz WAV file
    ## 
    ## **Note**: Blocking
    ## 
    proc custom(): seq[cfloat] =
        result = readWav(audioSamplePath)
    return whisper.sharedLogic(custom, language, translate)

proc infer*(whisper: Whisper; audio: seq[float32]; language: string = "en"; translate: bool = false): string =
    ## Same as the infer above except this one accepts a sequence of `float32`.
    ## This delegates the reading and proper conversion of the audio to the caller.
    ## 
    proc custom(): seq[cfloat] = 
        result = newSeq[cfloat]()
        for sample in audio:
            result.add(sample.cfloat)
    return whisper.sharedLogic(custom, language, translate)

proc `=destroy`*(self: Whisper) =
    ## Deallocates the whisper context
    ## 
    if self.context != nil:
        whisperFree(self.context)

proc `=wasMoved`*(self: var Whisper) =
    self.context = nil

proc `=sink`*(dest: var Whisper; source: Whisper) =
    `=destroy`(dest)
    wasMoved(dest)
    dest.context = source.context

proc `=copy`*(dest: var Whisper; source: Whisper) {.error.}
proc `=dup`*(self: Whisper): Whisper {.error.}