const
  WHISPER_SAMPLE_RATE* = 16000
  WHISPER_N_FFT* = 400
  WHISPER_HOP_LENGTH* = 160
  WHISPER_CHUNK_SIZE* = 30

##
##  C interface
##
##  The following interface is thread-safe as long as the sample whisper_context is not used by multiple threads
##  concurrently.
##
##  Basic usage:
##
##      #include "whisper.h"
##
##      ...
##
##      whisper_context_params cparams = whisper_context_default_params();
##
##      struct whisper_context * ctx = whisper_init_from_file_with_params("/path/to/ggml-base.en.bin", cparams);
##
##      if (whisper_full(ctx, wparams, pcmf32.data(), pcmf32.size()) != 0) {
##          fprintf(stderr, "failed to process audio\n");
##          return 7;
##      }
##
##      const int n_segments = whisper_full_n_segments(ctx);
##      for (int i = 0; i < n_segments; ++i) {
##          const char * text = whisper_full_get_segment_text(ctx, i);
##          printf("%s", text);
##      }
##
##      whisper_free(ctx);
##
##      ...
##
##  This is a demonstration of the most straightforward usage of the library.
##  "pcmf32" contains the RAW audio data in 32-bit floating point format.
##
##  The interface also allows for more fine-grained control over the computation, but it requires a deeper
##  understanding of how the model works.
##

type
  WhisperContext* {.importc: "struct whisper_context",
      header: "whisper.h", incompletestruct.} = object
  WhisperState* {.importc: "struct whisper_state",
      header: "whisper.h", incompletestruct.} = object
  WhisperPos* = int32
  WhisperToken* = int32
  WhisperSeqId* = int32
  WhisperContextParams* {.importc: "struct whisper_context_params", header: "whisper.h",
                         bycopy.} = object
    useGpu* {.importc: "use_gpu".}: bool

  WhisperTokenData* {.importc: "struct whisper_token_data", header: "whisper.h",
      bycopy.} = object
    id* {.importc: "id".}: WhisperToken   ##  token id
    tid* {.importc: "tid".}: WhisperToken ##  forced timestamp token id
    p* {.importc: "p".}: cfloat           ##  probability of the token
    plog* {.importc: "plog".}: cfloat     ##  log probability of the token
    pt* {.importc: "pt".}: cfloat         ##  probability of the timestamp token
    ptsum* {.importc: "ptsum".}: cfloat   ##  sum of probabilities of all timestamp tokens
    t0* {.importc: "t0".}: int64          ##  token-level timestamp data
                                   ##  do not use if you haven't computed token-level timestamps
    t1* {.importc: "t1".}: int64          ##    end time of the token
    vlen* {.importc: "vlen".}: cfloat
    ##  voice length of the token

  WhisperModelLoader* {.importc: "struct whisper_model_loader",
      header: "whisper.h", bycopy.} = object
    context* {.importc: "context".}: pointer
    read* {.importc: "read".}: proc (ctx: pointer; output: pointer;
        readSize: csize_t): csize_t {.
        cdecl.}
    eof* {.importc: "eof".}: proc (ctx: pointer): bool {.cdecl.}
    close* {.importc: "close".}: proc (ctx: pointer) {.cdecl.}


type
  WhisperGretype* {.size: sizeof(cint).} = enum ##  grammar element type
    WHISPER_GRETYPE_END = 0,                    ##  start of alternate definition for rule
    WHISPER_GRETYPE_ALT = 1,                    ##  non-terminal element: reference to rule
    WHISPER_GRETYPE_RULE_REF = 2,               ##  terminal element: character (code point)
    WHISPER_GRETYPE_CHAR = 3,                   ##  inverse char(s) ([^a], [^a-b] [^abc])
    WHISPER_GRETYPE_CHAR_NOT = 4, ##  modifies a preceding WHISPER_GRETYPE_CHAR or LLAMA_GRETYPE_CHAR_ALT to
                                                ##  be an inclusive range ([a-z])
    WHISPER_GRETYPE_CHAR_RNG_UPPER = 5, ##  modifies a preceding WHISPER_GRETYPE_CHAR or
                                          ##  WHISPER_GRETYPE_CHAR_RNG_UPPER to add an alternate char to match ([ab], [a-zA])
    WHISPER_GRETYPE_CHAR_ALT = 6


type
  WhisperGrammarElement* {.importc: "struct whisper_grammar_element", header: "whisper.h",
                          bycopy.} = object
    `type`* {.importc: "type".}: WhisperGretype
    value* {.importc: "value".}: uint32
    ##  Unicode code point or rule ID

type
  WhisperSamplingStrategy* {.size: sizeof(
      cint).} = enum ## /////////////////////////////////////////////////////////////////////////
                                 ##  Available sampling strategies
    WHISPER_SAMPLING_GREEDY,     ##  similar to OpenAI's GreedyDecoder
    WHISPER_SAMPLING_BEAM_SEARCH ##  similar to OpenAI's BeamSearchDecoder


type
  WhisperNewSegmentCallback* = proc (ctx: ptr WhisperContext; state: ptr WhisperState;
                                  nNew: cint;
                                      userData: pointer) {.cdecl.} ##  Text segment callback
                                                                      ##  Called on every newly generated text segment
                                                                      ##  Use the whisper_full_...() functions to obtain the text segments

type
  WhisperProgressCallback* = proc (ctx: ptr WhisperContext; state: ptr WhisperState;
                                progress: cint;
                                    userData: pointer) {.cdecl.} ##  Progress callback

type
  WhisperEncoderBeginCallback* = proc (ctx: ptr WhisperContext;
                                    state: ptr WhisperState;
                                        userData: pointer): bool {.
      cdecl.} ##  Encoder begin callback
             ##  If not NULL, called before the encoder starts
             ##  If it returns false, the computation is aborted

type
  WhisperAbortCallback* = proc (userData: pointer): bool {.cdecl.} ##  Abort callback
                                                            ##  If not NULL, called before ggml computation
                                                            ##  If it returns true, the computation is aborted

type
  WhisperLogitsFilterCallback* = proc (ctx: ptr WhisperContext;
                                    state: ptr WhisperState;
                                    tokens: ptr WhisperTokenData; nTokens: cint;
                                    logits: ptr cfloat;
                                        userData: pointer) {.cdecl.} ##  Logits filter callback
                                                                               ##  Can be used to modify the logits before sampling
                                                                               ##  If not NULL, called after applying temperature to logits

type
  INNER_C_STRUCT_whisper_0* {.importc: "no_name", header: "whisper.h",
      bycopy.} = object ##  Parameters for the whisper_full() function
                   ##  If you change the order or add new parameters, make sure to update the default values in whisper.cpp:
                   ##  whisper_full_default_params()
    bestOf* {.importc: "best_of".}: cint
    ##  ref: https://github.com/openai/whisper/blob/f82bc59f5ea234d4b97fb2860842ed38519f7e65/whisper/transcribe.py#L264

  INNER_C_STRUCT_whisper_1* {.importc: "no_name", header: "whisper.h",
      bycopy.} = object
    beamSize* {.importc: "beam_size".}: cint ##  ref: https://github.com/openai/whisper/blob/f82bc59f5ea234d4b97fb2860842ed38519f7e65/whisper/transcribe.py#L265
    patience* {.importc: "patience".}: cfloat
    ##  TODO: not implemented, ref: https://arxiv.org/pdf/2204.05424.pdf

  WhisperFullParams* {.importc: "struct whisper_full_params",
      header: "whisper.h", bycopy.} = object
    strategy* {.importc: "strategy".}: WhisperSamplingStrategy
    nThreads* {.importc: "n_threads".}: cint
    nMaxTextCtx* {.importc: "n_max_text_ctx".}: cint ##  max tokens to use from past text as prompt for the decoder
    offsetMs* {.importc: "offset_ms".}: cint ##  start offset in ms
    durationMs* {.importc: "duration_ms".}: cint ##  audio duration to process in ms
    translate* {.importc: "translate".}: bool
    noContext* {.importc: "no_context".}: bool ##  do not use past transcription (if any) as initial prompt for the decoder
    noTimestamps* {.importc: "no_timestamps".}: bool ##  do not generate timestamps
    singleSegment* {.importc: "single_segment".}: bool ##  force single segment output (useful for streaming)
    printSpecial* {.importc: "print_special".}: bool ##  print special tokens (e.g. <SOT>, <EOT>, <BEG>, etc.)
    printProgress* {.importc: "print_progress".}: bool ##  print progress information
    printRealtime* {.importc: "print_realtime".}: bool ##  print results from within whisper.cpp (avoid it, use callback instead)
    printTimestamps* {.importc: "print_timestamps".}: bool ##  print timestamps for each text segment when printing realtime
    tokenTimestamps* {.importc: "token_timestamps".}: bool ##  [EXPERIMENTAL] token-level timestamps
    tholdPt* {.importc: "thold_pt".}: cfloat ##  timestamp token probability threshold (~0.01)
    tholdPtsum* {.importc: "thold_ptsum".}: cfloat ##  timestamp token sum probability threshold (~0.01)
    maxLen* {.importc: "max_len".}: cint     ##  max segment length in characters
    splitOnWord* {.importc: "split_on_word".}: bool ##  split on word rather than on token (when used with max_len)
    maxTokens* {.importc: "max_tokens".}: cint ##  max tokens per segment (0 = no limit)
    speedUp* {.importc: "speed_up".}: bool   ##  [EXPERIMENTAL] speed-up techniques
                                             ##  note: these can significantly reduce the quality of the output
    debugMode* {.importc: "debug_mode".}: bool ##  enable debug_mode provides extra info (eg. Dump log_mel)
    audioCtx* {.importc: "audio_ctx".}: cint ##  overwrite the audio context size (0 = use default)
    tdrzEnable* {.importc: "tdrz_enable".}: bool ##  [EXPERIMENTAL] [TDRZ] tinydiarize
    initialPrompt* {.importc: "initial_prompt".}: cstring ##  tokens to provide to the whisper decoder as initial prompt
                                             ##  these are prepended to any existing text context from a previous call
    promptTokens* {.importc: "prompt_tokens".}: ptr WhisperToken
    promptNTokens* {.importc: "prompt_n_tokens".}: cint
    language* {.importc: "language".}: cstring ##  for auto-detection, set to nullptr, "" or "auto"
    detectLanguage* {.importc: "detect_language".}: bool
    suppressBlank* {.importc: "suppress_blank".}: bool ##  common decoding parameters:
    suppressNonSpeechTokens* {.importc: "suppress_non_speech_tokens".}: bool ##  ref: https://github.com/openai/whisper/blob/7858aa9c08d98f75575035ecd6481f462d66ca27/whisper/tokenizer.py#L224-L253
    temperature* {.importc: "temperature".}: cfloat ##  initial decoding temperature, ref: https://ai.stackexchange.com/a/32478
    maxInitialTs* {.importc: "max_initial_ts".}: cfloat ##  ref: https://github.com/openai/whisper/blob/f82bc59f5ea234d4b97fb2860842ed38519f7e65/whisper/decoding.py#L97
    lengthPenalty* {.importc: "length_penalty".}: cfloat ##  ref: https://github.com/openai/whisper/blob/f82bc59f5ea234d4b97fb2860842ed38519f7e65/whisper/transcribe.py#L267
    temperatureInc* {.importc: "temperature_inc".}: cfloat ##  fallback parameters
                                             ##  ref: https://github.com/openai/whisper/blob/f82bc59f5ea234d4b97fb2860842ed38519f7e65/whisper/transcribe.py#L274-L278
    entropyThold* {.importc: "entropy_thold".}: cfloat ##  similar to OpenAI's "compression_ratio_threshold"
    logprobThold* {.importc: "logprob_thold".}: cfloat
    noSpeechThold* {.importc: "no_speech_thold".}: cfloat ##  TODO: not implemented
    greedy* {.importc: "greedy".}: INNER_C_STRUCT_whisper_0
    beamSearch* {.importc: "beam_search".}: INNER_C_STRUCT_whisper_1
    newSegmentCallback* {.importc: "new_segment_callback".}: WhisperNewSegmentCallback ##  called for every newly generated text segment
    newSegmentCallbackUserData* {.importc: "new_segment_callback_user_data".}: pointer
    progressCallback* {.importc: "progress_callback".}: WhisperProgressCallback ##  called on each progress update
    progressCallbackUserData* {.importc: "progress_callback_user_data".}: pointer
    encoderBeginCallback* {.importc: "encoder_begin_callback".}: WhisperEncoderBeginCallback ##  called each time before the encoder starts
    encoderBeginCallbackUserData* {.importc: "encoder_begin_callback_user_data".}: pointer
    abortCallback* {.importc: "abort_callback".}: WhisperAbortCallback ##  called each time before ggml computation starts
    abortCallbackUserData* {.importc: "abort_callback_user_data".}: pointer
    logitsFilterCallback* {.importc: "logits_filter_callback".}: WhisperLogitsFilterCallback ##  called by each decoder to filter obtained logits
    logitsFilterCallbackUserData* {.importc: "logits_filter_callback_user_data".}: pointer
    grammarRules* {.importc: "grammar_rules".}: ptr ptr WhisperGrammarElement
    nGrammarRules* {.importc: "n_grammar_rules".}: csize_t
    iStartRule* {.importc: "i_start_rule".}: csize_t
    grammarPenalty* {.importc: "grammar_penalty".}: cfloat




proc whisperInitFromFileWithParams*(pathModel: cstring;
                                   params: WhisperContextParams): ptr WhisperContext {.
    cdecl, importc: "whisper_init_from_file_with_params",
        dynlib: "libwhisper.so".}
  ##  Various functions for loading a ggml whisper model.
  ##  Allocate (almost) all memory needed for the model.
  ##  Return NULL on failure
proc whisperInitFromBufferWithParams*(buffer: pointer; bufferSize: csize_t;
                                     params: WhisperContextParams): ptr WhisperContext {.
    cdecl, importc: "whisper_init_from_buffer_with_params",
        dynlib: "libwhisper.so".}
proc whisperInitWithParams*(loader: ptr WhisperModelLoader;
                           params: WhisperContextParams): ptr WhisperContext {.
    cdecl, importc: "whisper_init_with_params", dynlib: "libwhisper.so".}
proc whisperInitFromFileWithParamsNoState*(pathModel: cstring;
    params: WhisperContextParams): ptr WhisperContext {.cdecl,
    importc: "whisper_init_from_file_with_params_no_state",
    dynlib: "libwhisper.so".}
  ##  These are the same as the above, but the internal state of the context is not allocated automatically
  ##  It is the responsibility of the caller to allocate the state using whisper_init_state() (#523)
proc whisperInitFromBufferWithParamsNoState*(buffer: pointer;
    bufferSize: csize_t;params: WhisperContextParams): ptr WhisperContext {.cdecl,
    importc: "whisper_init_from_buffer_with_params_no_state",
    dynlib: "libwhisper.so".}
proc whisperInitWithParamsNoState*(loader: ptr WhisperModelLoader;
                                  params: WhisperContextParams): ptr WhisperContext {.
    cdecl, importc: "whisper_init_with_params_no_state",
        dynlib: "libwhisper.so".}

proc whisperInitState*(ctx: ptr WhisperContext): ptr WhisperState {.cdecl,
    importc: "whisper_init_state", dynlib: "libwhisper.so".}
proc whisperCtxInitOpenvinoEncoder*(ctx: ptr WhisperContext; modelPath: cstring;
                                   device: cstring;
                                       cacheDir: cstring): cint {.cdecl,
    importc: "whisper_ctx_init_openvino_encoder", dynlib: "libwhisper.so".}
  ##  Given a context, enable use of OpenVINO for encode inference.
  ##  model_path: Optional path to OpenVINO encoder IR model. If set to nullptr,
  ##                       the path will be generated from the ggml model path that was passed
  ##                       in to whisper_init_from_file. For example, if 'path_model' was
  ##                       "/path/to/ggml-base.en.bin", then OpenVINO IR model path will be
  ##                       assumed to be "/path/to/ggml-base.en-encoder-openvino.xml".
  ##  device: OpenVINO device to run inference on ("CPU", "GPU", etc.)
  ##  cache_dir: Optional cache directory that can speed up init time, especially for
  ##                      GPU, by caching compiled 'blobs' there.
  ##                      Set to nullptr if not used.
  ##  Returns 0 on success. If OpenVINO is not enabled in build, this simply returns 1.
proc whisperFree*(ctx: ptr WhisperContext) {.cdecl, importc: "whisper_free",
    dynlib: "libwhisper.so".}
  ##  Frees all allocated memory
proc whisperFreeState*(state: ptr WhisperState) {.cdecl,
    importc: "whisper_free_state", dynlib: "libwhisper.so".}
proc whisperFreeParams*(params: ptr WhisperFullParams) {.cdecl,
    importc: "whisper_free_params", dynlib: "libwhisper.so".}
proc whisperFreeContextParams*(params: ptr WhisperContextParams) {.cdecl,
    importc: "whisper_free_context_params", dynlib: "libwhisper.so".}
proc whisperPcmToMel*(ctx: ptr WhisperContext; samples: ptr cfloat; nSamples: cint;
                     nThreads: cint): cint {.cdecl,
                         importc: "whisper_pcm_to_mel",
    dynlib: "libwhisper.so".}
  ##  Convert RAW PCM audio to log mel spectrogram.
  ##  The resulting spectrogram is stored inside the default state of the provided whisper context.
  ##  Returns 0 on success
proc whisperPcmToMelWithState*(ctx: ptr WhisperContext; state: ptr WhisperState;
                              samples: ptr cfloat; nSamples: cint;
                                  nThreads: cint): cint {.
    cdecl, importc: "whisper_pcm_to_mel_with_state", dynlib: "libwhisper.so".}
proc whisperPcmToMelPhaseVocoder*(ctx: ptr WhisperContext; samples: ptr cfloat;
                                 nSamples: cint; nThreads: cint): cint {.cdecl,
    importc: "whisper_pcm_to_mel_phase_vocoder", dynlib: "libwhisper.so".}
  ##  Convert RAW PCM audio to log mel spectrogram but applies a Phase Vocoder to speed up the audio x2.
  ##  The resulting spectrogram is stored inside the default state of the provided whisper context.
  ##  Returns 0 on success
proc whisperPcmToMelPhaseVocoderWithState*(ctx: ptr WhisperContext;
    state: ptr WhisperState; samples: ptr cfloat; nSamples: cint;
        nThreads: cint): cint {.
    cdecl, importc: "whisper_pcm_to_mel_phase_vocoder_with_state",
    dynlib: "libwhisper.so".}
proc whisperSetMel*(ctx: ptr WhisperContext; data: ptr cfloat; nLen: cint;
    nMel: cint): cint {.
    cdecl, importc: "whisper_set_mel", dynlib: "libwhisper.so".}
  ##  This can be used to set a custom log mel spectrogram inside the default state of the provided whisper context.
  ##  Use this instead of whisper_pcm_to_mel() if you want to provide your own log mel spectrogram.
  ##  n_mel must be 80
  ##  Returns 0 on success
proc whisperSetMelWithState*(ctx: ptr WhisperContext; state: ptr WhisperState;
                            data: ptr cfloat; nLen: cint;
                                nMel: cint): cint {.cdecl,
    importc: "whisper_set_mel_with_state", dynlib: "libwhisper.so".}
proc whisperEncode*(ctx: ptr WhisperContext; offset: cint;
    nThreads: cint): cint {.cdecl,

importc: "whisper_encode", dynlib: "libwhisper.so".}
  ##  Run the Whisper encoder on the log mel spectrogram stored inside the default state in the provided whisper context.
  ##  Make sure to call whisper_pcm_to_mel() or whisper_set_mel() first.
  ##  offset can be used to specify the offset of the first frame in the spectrogram.
  ##  Returns 0 on success
proc whisperEncodeWithState*(ctx: ptr WhisperContext; state: ptr WhisperState;
                            offset: cint; nThreads: cint): cint {.cdecl,
    importc: "whisper_encode_with_state", dynlib: "libwhisper.so".}
proc whisperDecode*(ctx: ptr WhisperContext; tokens: ptr WhisperToken; nTokens: cint;
                   nPast: cint; nThreads: cint): cint {.cdecl,
    importc: "whisper_decode", dynlib: "libwhisper.so".}
  ##  Run the Whisper decoder to obtain the logits and probabilities for the next token.
  ##  Make sure to call whisper_encode() first.
  ##  tokens + n_tokens is the provided context for the decoder.
  ##  n_past is the number of tokens to use from previous decoder calls.
  ##  Returns 0 on success
  ##  TODO: add support for multiple decoders
proc whisperDecodeWithState*(ctx: ptr WhisperContext; state: ptr WhisperState;
                            tokens: ptr WhisperToken; nTokens: cint;
                                nPast: cint;
                            nThreads: cint): cint {.cdecl,
    importc: "whisper_decode_with_state", dynlib: "libwhisper.so".}
proc whisperTokenize*(ctx: ptr WhisperContext; text: cstring;
                     tokens: ptr WhisperToken; nMaxTokens: cint): cint {.cdecl,
    importc: "whisper_tokenize", dynlib: "libwhisper.so".}
  ##  Convert the provided text into tokens.
  ##  The tokens pointer must be large enough to hold the resulting tokens.
  ##  Returns the number of tokens on success, no more than n_max_tokens
  ##  Returns -1 on failure
  ##  TODO: not sure if correct
proc whisperLangMaxId*(): cint {.cdecl, importc: "whisper_lang_max_id",
                              dynlib: "libwhisper.so".}
  ##  Largest language id (i.e. number of available languages - 1)
proc whisperLangId*(lang: cstring): cint {.cdecl, importc: "whisper_lang_id",
                                       dynlib: "libwhisper.so".}
  ##  Return the id of the specified language, returns -1 if not found
  ##  Examples:
  ##    "de" -> 2
  ##    "german" -> 2
proc whisperLangStr*(id: cint): cstring {.cdecl, importc: "whisper_lang_str",
                                      dynlib: "libwhisper.so".}
  ##  Return the short string of the specified language id (e.g. 2 -> "de"), returns nullptr if not found
proc whisperLangStrFull*(id: cint): cstring {.cdecl,
    importc: "whisper_lang_str_full", dynlib: "libwhisper.so".}
  ##  Return the short string of the specified language name (e.g. 2 -> "german"), returns nullptr if not found
proc whisperLangAutoDetect*(ctx: ptr WhisperContext; offsetMs: cint; nThreads: cint;
                           langProbs: ptr cfloat): cint {.cdecl,
    importc: "whisper_lang_auto_detect", dynlib: "libwhisper.so".}
  ##  Use mel data at offset_ms to try and auto-detect the spoken language
  ##  Make sure to call whisper_pcm_to_mel() or whisper_set_mel() first
  ##  Returns the top language id or negative on failure
  ##  If not null, fills the lang_probs array with the probabilities of all languages
  ##  The array must be whisper_lang_max_id() + 1 in size
  ##  ref: https://github.com/openai/whisper/blob/main/whisper/decoding.py#L18-L69
proc whisperLangAutoDetectWithState*(ctx: ptr WhisperContext;
                                    state: ptr WhisperState; offsetMs: cint;
                                    nThreads: cint;
                                        langProbs: ptr cfloat): cint {.
    cdecl, importc: "whisper_lang_auto_detect_with_state",
        dynlib: "libwhisper.so".}
proc whisperNLen*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_n_len", dynlib: "libwhisper.so".}
  ##  mel length
proc whisperNLenFromState*(state: ptr WhisperState): cint {.cdecl,
    importc: "whisper_n_len_from_state", dynlib: "libwhisper.so".}
  ##  mel length
proc whisperNVocab*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_n_vocab", dynlib: "libwhisper.so".}
proc whisperNTextCtx*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_n_text_ctx", dynlib: "libwhisper.so".}
proc whisperNAudioCtx*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_n_audio_ctx", dynlib: "libwhisper.so".}
proc whisperIsMultilingual*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_is_multilingual", dynlib: "libwhisper.so".}
proc whisperModelNVocab*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_vocab", dynlib: "libwhisper.so".}
proc whisperModelNAudioCtx*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_audio_ctx", dynlib: "libwhisper.so".}
proc whisperModelNAudioState*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_audio_state", dynlib: "libwhisper.so".}
proc whisperModelNAudioHead*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_audio_head", dynlib: "libwhisper.so".}
proc whisperModelNAudioLayer*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_audio_layer", dynlib: "libwhisper.so".}
proc whisperModelNTextCtx*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_text_ctx", dynlib: "libwhisper.so".}
proc whisperModelNTextState*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_text_state", dynlib: "libwhisper.so".}
proc whisperModelNTextHead*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_text_head", dynlib: "libwhisper.so".}
proc whisperModelNTextLayer*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_text_layer", dynlib: "libwhisper.so".}
proc whisperModelNMels*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_n_mels", dynlib: "libwhisper.so".}
proc whisperModelFtype*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_ftype", dynlib: "libwhisper.so".}
proc whisperModelType*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_model_type", dynlib: "libwhisper.so".}
proc whisperGetLogits*(ctx: ptr WhisperContext): ptr cfloat {.cdecl,
    importc: "whisper_get_logits", dynlib: "libwhisper.so".}
  ##  Token logits obtained from the last call to whisper_decode()
  ##  The logits for the last token are stored in the last row
  ##  Rows: n_tokens
  ##  Cols: n_vocab
proc whisperGetLogitsFromState*(state: ptr WhisperState): ptr cfloat {.cdecl,
    importc: "whisper_get_logits_from_state", dynlib: "libwhisper.so".}
proc whisperTokenToStr*(ctx: ptr WhisperContext;
    token: WhisperToken): cstring {.cdecl,

importc: "whisper_token_to_str", dynlib: "libwhisper.so".}
  ##  Token Id -> String. Uses the vocabulary in the provided context
proc whisperModelTypeReadable*(ctx: ptr WhisperContext): cstring {.cdecl,
    importc: "whisper_model_type_readable", dynlib: "libwhisper.so".}
proc whisperTokenEot*(ctx: ptr WhisperContext): WhisperToken {.cdecl,
    importc: "whisper_token_eot", dynlib: "libwhisper.so".}
  ##  Special tokens
proc whisperTokenSot*(ctx: ptr WhisperContext): WhisperToken {.cdecl,
    importc: "whisper_token_sot", dynlib: "libwhisper.so".}
proc whisperTokenSolm*(ctx: ptr WhisperContext): WhisperToken {.cdecl,
    importc: "whisper_token_solm", dynlib: "libwhisper.so".}
proc whisperTokenPrev*(ctx: ptr WhisperContext): WhisperToken {.cdecl,
    importc: "whisper_token_prev", dynlib: "libwhisper.so".}
proc whisperTokenNosp*(ctx: ptr WhisperContext): WhisperToken {.cdecl,
    importc: "whisper_token_nosp", dynlib: "libwhisper.so".}
proc whisperTokenNot*(ctx: ptr WhisperContext): WhisperToken {.cdecl,
    importc: "whisper_token_not", dynlib: "libwhisper.so".}
proc whisperTokenBeg*(ctx: ptr WhisperContext): WhisperToken {.cdecl,
    importc: "whisper_token_beg", dynlib: "libwhisper.so".}
proc whisperTokenLang*(ctx: ptr WhisperContext;
    langId: cint): WhisperToken {.cdecl,

importc: "whisper_token_lang", dynlib: "libwhisper.so".}
proc whisperTokenTranslate*(ctx: ptr WhisperContext): WhisperToken {.cdecl,
    importc: "whisper_token_translate", dynlib: "libwhisper.so".}
  ##  Task tokens
proc whisperTokenTranscribe*(ctx: ptr WhisperContext): WhisperToken {.cdecl,
    importc: "whisper_token_transcribe", dynlib: "libwhisper.so".}
proc whisperPrintTimings*(ctx: ptr WhisperContext) {.cdecl,
    importc: "whisper_print_timings", dynlib: "libwhisper.so".}
  ##  Performance information from the default state.
proc whisperResetTimings*(ctx: ptr WhisperContext) {.cdecl,
    importc: "whisper_reset_timings", dynlib: "libwhisper.so".}
proc whisperPrintSystemInfo*(): cstring {.cdecl,
                                       importc: "whisper_print_system_info",
                                       dynlib: "libwhisper.so".}
  ##  Print system information

proc whisperContextDefaultParamsByRef*(): ptr WhisperContextParams {.cdecl,
    importc: "whisper_context_default_params_by_ref", dynlib: "libwhisper.so".}
  ##  NOTE: this function allocates memory, and it is the responsibility of the caller to free the pointer - see whisper_free_context_params & whisper_free_params()
proc whisperContextDefaultParams*(): WhisperContextParams {.cdecl,
    importc: "whisper_context_default_params", dynlib: "libwhisper.so".}
proc whisperFullDefaultParamsByRef*(strategy: WhisperSamplingStrategy): ptr WhisperFullParams {.
    cdecl, importc: "whisper_full_default_params_by_ref",
        dynlib: "libwhisper.so".}
proc whisperFullDefaultParams*(strategy: WhisperSamplingStrategy): WhisperFullParams {.
    cdecl, importc: "whisper_full_default_params", dynlib: "libwhisper.so".}
proc whisperFull*(ctx: ptr WhisperContext; params: WhisperFullParams;
                 samples: ptr cfloat; nSamples: cint): cint {.cdecl,
    importc: "whisper_full", dynlib: "libwhisper.so".}
  ##  Run the entire model: PCM -> log mel spectrogram -> encoder -> decoder -> text
  ##  Not thread safe for same context
  ##  Uses the specified decoding strategy to obtain the text.
proc whisperFullWithState*(ctx: ptr WhisperContext; state: ptr WhisperState;
                          params: WhisperFullParams; samples: ptr cfloat;
                          nSamples: cint): cint {.cdecl,
    importc: "whisper_full_with_state", dynlib: "libwhisper.so".}
proc whisperFullParallel*(ctx: ptr WhisperContext; params: WhisperFullParams;
                         samples: ptr cfloat; nSamples: cint;
                             nProcessors: cint): cint {.
    cdecl, importc: "whisper_full_parallel", dynlib: "libwhisper.so".}
  ##  Split the input audio in chunks and process each chunk separately using whisper_full_with_state()
  ##  Result is stored in the default state of the context
  ##  Not thread safe if executed in parallel on the same context.
  ##  It seems this approach can offer some speedup in some cases.
  ##  However, the transcription accuracy can be worse at the beginning and end of each chunk.
proc whisperFullNSegments*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_full_n_segments", dynlib: "libwhisper.so".}
  ##  Number of generated text segments
  ##  A segment can be a few words, a sentence, or even a paragraph.
proc whisperFullNSegmentsFromState*(state: ptr WhisperState): cint {.cdecl,
    importc: "whisper_full_n_segments_from_state", dynlib: "libwhisper.so".}
proc whisperFullLangId*(ctx: ptr WhisperContext): cint {.cdecl,
    importc: "whisper_full_lang_id", dynlib: "libwhisper.so".}
  ##  Language id associated with the context's default state
proc whisperFullLangIdFromState*(state: ptr WhisperState): cint {.cdecl,
    importc: "whisper_full_lang_id_from_state", dynlib: "libwhisper.so".}
  ##  Language id associated with the provided state
proc whisperFullGetSegmentT0*(ctx: ptr WhisperContext;
    iSegment: cint): int64 {.cdecl, importc: "whisper_full_get_segment_t0",
        dynlib: "libwhisper.so".}
  ##  Get the start and end time of the specified segment
proc whisperFullGetSegmentT0FromState*(state: ptr WhisperState;
    iSegment: cint): int64 {.
    cdecl, importc: "whisper_full_get_segment_t0_from_state",
    dynlib: "libwhisper.so".}
proc whisperFullGetSegmentT1*(ctx: ptr WhisperContext;
    iSegment: cint): int64 {.cdecl, importc: "whisper_full_get_segment_t1",
        dynlib: "libwhisper.so".}
proc whisperFullGetSegmentT1FromState*(state: ptr WhisperState;
    iSegment: cint): int64 {.
    cdecl, importc: "whisper_full_get_segment_t1_from_state",
    dynlib: "libwhisper.so".}
proc whisperFullGetSegmentSpeakerTurnNext*(ctx: ptr WhisperContext;
    iSegment: cint): bool {.
    cdecl, importc: "whisper_full_get_segment_speaker_turn_next",
    dynlib: "libwhisper.so".}
  ##  Get whether the next segment is predicted as a speaker turn
proc whisperFullGetSegmentSpeakerTurnNextFromState*(state: ptr WhisperState;
    iSegment: cint): bool {.cdecl, importc: "whisper_full_get_segment_speaker_turn_next_from_state",
                         dynlib: "libwhisper.so".}
proc whisperFullGetSegmentText*(ctx: ptr WhisperContext;
    iSegment: cint): cstring {.
    cdecl, importc: "whisper_full_get_segment_text", dynlib: "libwhisper.so".}
  ##  Get the text of the specified segment
proc whisperFullGetSegmentTextFromState*(state: ptr WhisperState;
    iSegment: cint): cstring {.
    cdecl, importc: "whisper_full_get_segment_text_from_state",
    dynlib: "libwhisper.so".}
proc whisperFullNTokens*(ctx: ptr WhisperContext; iSegment: cint): cint {.cdecl,
    importc: "whisper_full_n_tokens", dynlib: "libwhisper.so".}
  ##  Get number of tokens in the specified segment
proc whisperFullNTokensFromState*(state: ptr WhisperState;
    iSegment: cint): cint {.
    cdecl, importc: "whisper_full_n_tokens_from_state",
        dynlib: "libwhisper.so".}
proc whisperFullGetTokenText*(ctx: ptr WhisperContext; iSegment: cint;
    iToken: cint): cstring {.
    cdecl, importc: "whisper_full_get_token_text", dynlib: "libwhisper.so".}
  ##  Get the token text of the specified token in the specified segment
proc whisperFullGetTokenTextFromState*(ctx: ptr WhisperContext;
                                      state: ptr WhisperState; iSegment: cint;
                                      iToken: cint): cstring {.cdecl,
    importc: "whisper_full_get_token_text_from_state", dynlib: "libwhisper.so".}
proc whisperFullGetTokenId*(ctx: ptr WhisperContext; iSegment: cint;
    iToken: cint): WhisperToken {.
    cdecl, importc: "whisper_full_get_token_id", dynlib: "libwhisper.so".}
proc whisperFullGetTokenIdFromState*(state: ptr WhisperState; iSegment: cint;
                                    iToken: cint): WhisperToken {.cdecl,
    importc: "whisper_full_get_token_id_from_state", dynlib: "libwhisper.so".}
proc whisperFullGetTokenData*(ctx: ptr WhisperContext; iSegment: cint;
    iToken: cint): WhisperTokenData {.
    cdecl, importc: "whisper_full_get_token_data", dynlib: "libwhisper.so".}
  ##  Get token data for the specified token in the specified segment
  ##  This contains probabilities, timestamps, etc.
proc whisperFullGetTokenDataFromState*(state: ptr WhisperState; iSegment: cint;
                                      iToken: cint): WhisperTokenData {.cdecl,
    importc: "whisper_full_get_token_data_from_state", dynlib: "libwhisper.so".}
proc whisperFullGetTokenP*(ctx: ptr WhisperContext; iSegment: cint;
    iToken: cint): cfloat {.
    cdecl, importc: "whisper_full_get_token_p", dynlib: "libwhisper.so".}
  ##  Get the probability of the specified token in the specified segment
proc whisperFullGetTokenPFromState*(state: ptr WhisperState; iSegment: cint;
                                   iToken: cint): cfloat {.cdecl,
    importc: "whisper_full_get_token_p_from_state", dynlib: "libwhisper.so".}
proc whisperBenchMemcpy*(nThreads: cint): cint {.cdecl,
    importc: "whisper_bench_memcpy", dynlib: "libwhisper.so".}
  ## /////////////////////////////////////////////////////////////////////////
  ##  Temporary helpers needed for exposing ggml interface
proc whisperBenchMemcpyStr*(nThreads: cint): cstring {.cdecl,
    importc: "whisper_bench_memcpy_str", dynlib: "libwhisper.so".}
proc whisperBenchGgmlMulMat*(nThreads: cint): cint {.cdecl,
    importc: "whisper_bench_ggml_mul_mat", dynlib: "libwhisper.so".}
proc whisperBenchGgmlMulMatStr*(nThreads: cint): cstring {.cdecl,
    importc: "whisper_bench_ggml_mul_mat_str", dynlib: "libwhisper.so".}

type
  GgmlLogLevel*{.importc: "enum ggml_log_level", header: "ggml.h".} = enum
    Error = 2,
    Warn = 3,
    Info = 4
  GgmlLogCallback* = proc(level: GgmlLogLevel; text: cstring;
            userData: pointer): void {.cdecl.}
proc whisperLogSet*(logCallback: GgmlLogCallback; userData: pointer) {.cdecl,
    importc: "whisper_log_set", dynlib: "libwhisper.so".}
  ##  Control logging output; default behavior is to print to stderr
