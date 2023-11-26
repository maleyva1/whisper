import whisper/bindings

type
    Whisper* = object
        context: ptr Context
    TaskType* = enum
        Transcribe, Translate
    TaskOptions* = object
        path*: string
        model*: string
        case isVideo*: bool
            of true:
                shouldMux*: bool
            else:
                discard
        case task*: TaskType
            of Transcribe:
                discard
            of Translate:
                language*: string

proc newWhisper*(): Whisper =
    result.context = nil

proc `=destroy`*(whisper: Whisper) = discard