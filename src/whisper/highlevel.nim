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
        params: WhisperContextParams
        case mlKind: ModelLoadingKind:
            of FromFile:
                filePath: string
            of FromBuffer:
                buffer: seq[byte]
    Whisper* = object ## \
        ## Wraps libwhisper's context to be used in Nim
        ## 
        context: ptr WhisperContext

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

proc infer*(whisper: Whisper; audioSamplePath: string; language: string = "en"; translate: bool = false): string =
    ## Transcribe from `audioSamplePath`, assuming the audio is in language `language`.
    ## Returns the transcribed Text.
    ## 
    ## **Note**: `audioSamplePath` must be a 16 kHz WAV file
    ## 
    ## **Note**: Blocking
    ## 
    if language != "auto" and whisperLangId(language.cstring) == -1:
        raise newException(WhisperInferenceError, language & " is unknown")
    if language != "en":
        if whisperIsMultilingual(whisper.context) == 0:
            raise newException(WhisperInferenceError, "Loaded whisper model is not multilingual")
    var fullParams = whisperFullDefaultParams(WHISPER_SAMPLING_GREEDY)
    fullParams.language = language.cstring
    fullParams.translate = translate
    var buffer = readWav(audioSamplePath)
    if whisperFull(whisper.context, fullParams, buffer[0].addr, buffer.len.cint) != 0:
        raise newException(WhisperInferenceError, "Unable to transcribe from audio")
    let n = whisperFullNSegments(whisper.context)
    for i in countup(0 , n - 1):
        result &= whisperFullGetSegmentText(whisper.context, i.cint)

proc `=destroy`(self: Whisper) =
    ## Deallocates the whisper context
    ## 
    if self.context != nil:
        whisperFree(self.context)

proc `=sink`(dest: var Whisper; source: Whisper) =
    `=destroy`(dest)
    wasMoved(dest)
    dest.context = source.context

proc `=copy`(dest: var Whisper; source: Whisper) =
    if dest.context != source.context:
        `=destroy`(dest)
        wasMoved(dest)
        copyMem(dest.context, source.context, sizeof(source.context))