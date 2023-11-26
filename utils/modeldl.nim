const
    url = "https://huggingface.co/ggerganov/whisper.cpp"
    prefix = "resolve/main/ggml"

let models = @[
    "tiny.en",
    "tiny",
    "tiny-q5_1",
    "tiny.en-q5_1",
    "base.en",
    "base",
    "base-q5_1",
    "base.en-q5_1",
    "small.en",
    "small.en-tdrz",
    "small",
    "small-q5_1",
    "small.en-q5_1",
    "medium",
    "medium.en",
    "medium-q5_0",
    "medium.en-q5_0",
    "large-v1",
    "large-v2",
    "large-v3",
    "large-q5_0",
]

when isMainModule:
    discard