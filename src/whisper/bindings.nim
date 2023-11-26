const wheader = "../../whisper.cpp/whisper.h"

{.link: "../../build/libwhisper.a".}

const 
    SampleRate* = 16000
    NoFFT* = 400
    HopLength* = 160
    ChunkSize* = 30

type
    Context* {.importc: "struct whisper_context", header: wheader.} = object
    State* {.importc: "struct whisper_state", header: wheader.} = object
    Position* = cint
    Token* = cint
    SeqId* = cint
    ContextParams* {.importc: "struct whisper_context_params", header: wheader.} = object
        use_gpu*: bool
    TokenData* {.importc: "struct whisper_token_data", header: wheader.} = object
        id*, tid*: Token
        p*, plog*, pt*, ptsum*: cfloat
        t0*, t1*: clonglong
        vlen*: cfloat
    ModelLoader* {.importc: "struct whisper_model_loader", header: wheader.} = object
        context*: pointer
        read*: proc(ctx, ouput: pointer; readSize: csize_t): csize_t
        eof*: proc(ctx: pointer): bool
        close*: proc(ctx: pointer): void
    GrammarElementKind* {.importc: "enum whisper_gretype", header: wheader.} = enum
        End, Alt, RuleRef, Char, CharNot, CharRngUpper, CharAlt
    GrammarElement* {.importc: "struct whisper_grammar_element", header: wheader.} = object
        `type`*: GrammarElementKind
        value*: cuint
    SamplingStrategy* {.importc: "enum whisper_sampling_strategy", header: wheader.} = enum
        Greedy, BeamSearch
    NewSegment* = proc(
        ctx: ptr Context;
        state: ptr State;
        nNew: cint;
        userData: pointer
    ): void
    Progress* = proc(
        ctx: ptr Context;
        state: ptr State;
        progress: cint;
        userData: pointer
    ): void
    EncoderBegin* = proc(
        ctx: ptr Context;
        state: ptr State;
        userData: pointer
    ): bool
    Abort* = proc(user_data: pointer): bool
    LogitsFilter* = proc(
        ctx: ptr Context;
        state: ptr State;
        tokens: ptr TokenData;
        nTokens: cint;
        logits: ptr cfloat;
        userData: pointer
    ): void
    FullParams* {.importc: "struct whisper_full_params", header: wheader.} = object
        strategy*: SamplingStrategy
        n_threads, n_max_text_ctx, offset_ms, duration_ms: cint
        translate, no_context, no_timestampts, single_segment, print_special, print_progress, print_realtime, print_timestampts: bool
        token_timestamps: bool
        thold_pt, thold_ptsum: cfloat
        max_len: cint
        split_on_word: bool
        max_tokens: cint
        speed_up, debug_mode: bool
        audio_ctx: cint
        tdrz_enable: bool
        initial_prompt: cstring
        prompt_tokens: cstring
        prompt_n_tokens: cint
        language*: cstring
        detect_language: bool
        suppress_blank, suppress_non_speech_tokens: bool
        temperature, max_initial_ts, length_penalty: cfloat
        temperature_inc, entropy_thold, logprob_thold, no_speech_thold: cfloat
        # greedy: Greedy
        # beam_search: BeamSearch
        new_segment_callback*: NewSegment
        new_segment_callback_user_data*: pointer
        progress_callback*: Progress
        progress_callback_user_data*: pointer
        encoder_begin_callback*: EncoderBegin
        encoder_begin_callback_user_data*: pointer
        abort_callback*: Abort
        abort_callback_user_data*: pointer
        logits_filter_callback*: LogitsFilter
        logits_filter_callback_user_data*: pointer
        grammar_rules*: ptr ptr GrammarElement
        n_grammar_rules*, i_start_rule*: csize_t
        grammar_penalty*: cfloat

proc initFromFileWithParams*(
    buffer: cstring; 
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_from_file_with_params", header: wheader.}

proc initFromBufferWithParams*(
    buffer: pointer;
    params: ContextParams
    ): ptr Context {.importc: "whipser_init_from_buffer_with_params", header: wheader.}

proc initWithParams*(
    loader: ptr ModelLoader;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_with_params", header: wheader.}

proc initFromFileWithParamsNoState*(
    model: cstring;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_from_file_with_params_no_state", header: wheader.}

proc initFromBufferWithParamsNoState*(
    buffer: pointer;
    bufferSize: csize_t;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_from_buffer_with_params_no_state", header: wheader.}

proc initWithParamsNoState*(
    loader: ptr ModelLoader;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_with_params_no_state", header: wheader.}

proc initState*(
    ctx: ptr Context
    ): ptr State {.importc: "whisper_init_state", header: wheader.}

proc initOpenvinoEncoder*(
    ctx: ptr Context;
    modelPath, device, cache_dir: cstring
): cint {.importc: "whisper_ctx_init_openvino_encoder", header: wheader.}

proc free*(ctx: ptr Context) {.importc: "whisper_free", header: wheader.}
proc freeState*(ctx: ptr State) {.importc: "whisper_free_state", header: wheader.}
proc freeParams*(params: ptr FullParams) {.importc: "whisper_free_params", header: wheader.}
proc freeContextParams*(params: ptr ContextParams) {.importc: "whisper_free_context_params", header: wheader.}

proc pcmToMel*(
    ctx: ptr Context;
    samples: ptr cfloat;
    noSamples, noThreads: cint
): cint {.importc: "whipser_pcm_to_mel", header: wheader.}
proc pcmToMelWithState*(
    ctx: ptr Context;
    state: ptr State;
    samples: ptr cfloat;
    noSamples, noThreads: cint
): cint {.importc: "whipser_pcm_to_mel_with_state", header: wheader.}
proc pcmToMelPhaseVocoder*(
    ctx: ptr Context;
    samples: ptr cfloat;
    noSamples, noThreads: cint
): cint {.importc: "whipser_pcm_to_mel_phase_vocoder", header: wheader.}
proc pcmToMelPhaseVocoderWithState*(
    ctx: ptr Context;
    state: ptr State;
    samples: ptr cfloat;
    noSamples, noThreads: cint
): cint {.importc: "whisper_pcm_to_mel_phase_vocoder_with_state", header: wheader.}
proc setMel*(
    ctx: ptr Context;
    data: ptr cfloat;
    noLen, noMel: cint
): cint {.importc: "whisper_set_mel", header: wheader.}
proc setMelWithState*(
    ctx: ptr Context;
    state: ptr State;
    data: ptr cfloat;
    noLen, noMel: cint
): cint {.importc: "whisper_set_mel_with_state", header: wheader.}

proc encode*(
    ctx: ptr Context;
    offset, noThreads: cint
    ): cint {.importc: "whisper_encode", header: wheader.}
proc encodeWithState*(
    ctx: ptr Context;
    state: ptr State;
    offset, noThreads: cint
    ): cint {.importc: "whisper_encode_with_state", header: wheader.}
proc decode*(
    ctx: ptr Context;
    tokens: cstring;
    noTokens, noPast, noThreads: cint
    ): cint {.importc: "whisper_decode", header: wheader.}
proc decodedWithState*(
    ctx: ptr Context;
    state: ptr State;
    tokens: cstring;
    noTokens, noPast, noThreads: cint
): cint {.importc: "whisper_decode_with_state", header: wheader.}

proc tokenize*(
    ctx: ptr Context;
    text: cstring;
    tokens: ptr Token;
    noMaxTokens: cint
): cint {.importc: "whisper_tokenize", header: wheader.}

proc langMaxId*(): cint {.importc: "whisper_lang_max_id", header: wheader.}
proc langId*(lang: cstring): cint {.importc: "whisper_lang_id", header: wheader.}
proc langStr*(id: cint): cstring {.importc: "whisper_lang_str", header: wheader.}
proc langStrFull*(id: cint): cstring {.importc: "whisper_lang_str_full", header: wheader.}

proc langAutoDetect*(
    ctx: ptr Context;
    offsetMs, noThreads: cint;
    langProbs: ptr cfloat
): cint {.importc: "whipser_lang_auto_detect", header: wheader.}

proc langAutoDetectWithState*(
    ctx: ptr Context;
    state: ptr State;
    offsetMs, noThreads: cint;
    langProbs: ptr cfloat
): cint {.importc: "whipser_lang_auto_detect_with_state", header: wheader.}

proc nLen*(ctx: ptr Context): cint {.importc: "whisper_n_len", header: wheader.}
proc nLenFromState*(ctx: ptr Context): cint {.importc: "whisper_n_len_from_state", header: wheader.}
proc nVocab*(ctx: ptr Context): cint {.importc: "whisper_n_vocab", header: wheader.}
proc nTextCtx*(ctx: ptr Context): cint {.importc: "whisper_n_text_ctx", header: wheader.}
proc nAudioCtx*(ctx: ptr Context): cint {.importc: "whisper_n_audio_ctx", header: wheader.}
proc isMultilingual*(ctx: ptr Context): cint {.importc: "whisper_is_multilingual", header: wheader.}

proc modelNVocab*(ctx: ptr Context): cint {.importc: "whisper_model_n_vocab", header: wheader.}
proc modelNAudioCtx*(ctx: ptr Context): cint {.importc: "whisper_model_n_audio_ctx", header: wheader.}
proc modelNAudioState*(ctx: ptr Context): cint {.importc: "whisper_model_n_audio_state", header: wheader.}
proc modelNAudioHead*(ctx: ptr Context): cint {.importc: "whisper_model_n_audio_head", header: wheader.}
proc modelNAudioLayer*(ctx: ptr Context): cint {.importc: "whisper_model_n_audio_layer", header: wheader.}
proc modelNTextCtx*(ctx: ptr Context): cint {.importc: "whisper_model_n_text_ctx", header: wheader.}
proc modelNTextState*(ctx: ptr Context): cint {.importc: "whisper_model_n_text_state", header: wheader.}
proc modelNTextHead*(ctx: ptr Context): cint {.importc: "whisper_model_n_text_head", header: wheader.}
proc modelNTextLayer*(ctx: ptr Context): cint {.importc: "whisper_model_n_text_layer", header: wheader.}
proc modelNMels*(ctx: ptr Context): cint {.importc: "whisper_model_n_mels", header: wheader.}
proc modelFType*(ctx: ptr Context): cint {.importc: "whisper_model_n_ftype", header: wheader.}
proc modelType*(ctx: ptr Context): cint {.importc: "whisper_model_n_type", header: wheader.}

proc getLogits*(ctx: ptr Context): ptr cfloat {.importc: "whisper_get_logits", header: wheader.}
proc getLogitsFromState*(ctx: ptr Context): ptr cfloat {.importc: "whisper_get_logits_from_state", header: wheader.}

proc tokenToStr*(ctx: ptr Context; token: Token): cstring {.importc: "whisper_token_to_str", header: wheader.}
proc modelTypeReadable*(ctx: ptr Context): cstring {.importc: "whisper_model_type_readable", header: wheader.}

proc tokenEot*(ctx: ptr Context): Token {.importc: "whisper_token_eot", header: wheader.}
proc tokenSot*(ctx: ptr Context): Token {.importc: "whisper_token_sot", header: wheader.}
proc tokenSolm*(ctx: ptr Context): Token {.importc: "whisper_token_solm", header: wheader.}
proc tokenPrv*(ctx: ptr Context): Token {.importc: "whisper_token_prev", header: wheader.}
proc tokenNosp*(ctx: ptr Context): Token {.importc: "whisper_token_nosp", header: wheader.}
proc tokenNot*(ctx: ptr Context): Token {.importc: "whisper_token_not", header: wheader.}
proc tokenBeg*(ctx: ptr Context): Token {.importc: "whisper_token_beg", header: wheader.}
proc tokenLang*(ctx: ptr Context; langId: cint): Token {.importc: "whisper_token_lang", header: wheader.}

proc tokenTranslate*(ctx: ptr Context): Token {.importc: "whisper_token_translate", header: wheader.}
proc tokenTranscribe*(ctx: ptr Context): Token {.importc: "whisper_token_transcribe", header: wheader.}

proc printTimings*(ctx: ptr Context) {.importc: "whisper_print_timings", header: wheader.}
proc resetTimings*(ctx: ptr Context) {.importc: "whisper_reset_timings", header: wheader.}

proc printSystemInfo*(): cstring {.importc: "whisper_print_system_info", header: wheader.}

proc contextDefaultParamsByRef*(): ptr ContextParams {.importc: "whisper_context_default_params_by_ref", header: wheader.}
proc contextDefaultParams*(): ContextParams {.importc: "whisper_context_default_params", header: wheader.}
proc fullDefaultParamsByRef*(strategy: SamplingStrategy): ptr FullParams {.importc: "whisper_full_default_params", header: wheader.}
proc fullDefaultParams*(strategy: SamplingStrategy): FullParams {.importc: "whisper_full_default_params", header: wheader.}

proc full*(
    ctx: ptr Context;
    params: FullParams;
    buffer: ptr cfloat;
    bufferSize: cint
): cint {.importc: "whisper_full", header: wheader.}
proc fullWithState*(
    ctx: ptr Context;
    state: ptr State;
    params: FullParams;
    buffer: ptr cfloat;
    bufferSize: cint
): cint {.importc: "whisper_full_with_state", header: wheader.}
proc fullParallel*(
    ctx: ptr Context;
    params: FullParams;
    buffer: ptr cfloat;
    bufferSize, noProcessors: cint
): cint {.importc: "whisper_full_parallel", header: wheader.}

proc fullNSegments*(ctx: ptr Context): cint {.importc: "whisper_full_n_segments", header: wheader.}
proc fullNSegmentsFromState*(state: ptr State): cint {.importc: "whisper_full_n_segments__from_state", header: wheader.}

proc fullLangId*(ctx: ptr Context): cint {.importc: "whisper_full_lang_id", header: wheader.}

proc fullLangIdFromState*(state: ptr State): cint {.importc: "whisper_full_lang_id_from_state", header: wheader.}

proc fullGetSegmentT0*(ctx: ptr Context; segment: cint): clonglong {.importc: "whisper_full_get_segment_t0", header: wheader.}
proc fullGetSegmentT0FromState*(state: ptr State; segment: cint): clonglong {.importc: "whisper_full_get_segment_t0_from_state", header: wheader.}

proc fullGetSegmentT1*(ctx: ptr Context; segment: cint): clonglong {.importc: "whisper_full_get_segment_t1", header: wheader.}
proc fullGetSegmentT1FromState*(state: ptr State; segment: cint): clonglong {.importc: "whisper_full_get_segment_t1_from_state", header: wheader.}

proc fullGetSegmentSpeakerTurnNext*(state: ptr State; segment: cint): bool {.importc: "whisper_full_get_segment_speaker_turn_next", header: wheader.}
proc fullGetSegmentSpeakerTurnNextFromState*(
    state: ptr State;
    segment: cint
): bool {.importc: "whisper_full_get_segment_speaker_turn_next_from_state", header: wheader.}

proc fullGetSegmentText*(ctx: ptr Context; segment: cint): cstring {.importc: "whisper_full_get_segment_text", header: wheader.}
proc fullGetSegmentTextFromState*(ctx: ptr State; segment: cint): cstring {.importc: "whisper_full_get_segment_text_from_state", header: wheader.}

proc fullNTokens*(ctx: ptr Context; segment: cint): cint {.importc: "whisper_full_n_tokens", header: wheader.}
proc fullNTokensFromState*(state: ptr State; segment: cint): cint {.importc: "whisper_full_n_tokens_from_state", header: wheader.}

proc fullGetTokenNext*(ctx: ptr Context; segment, token: cint): cstring {.importc: "whisper_full_get_token_next", header: wheader.}
proc fullGetTokenNextFromState*(ctx: ptr Context; state: ptr State; segment, token: cint): cstring {.importc: "whisper_full_get_token_next_from_state", header: wheader.}

proc fullGetTokenId*(ctx: ptr Context; segment, token: cint): Token {.importc: "whisper_full_get_token_id", header: wheader.}
proc fullGetTokenIdFromState*(state: ptr State; segment, token: cint): Token {.importc: "whisper_full_get_token_id_from_state", header: wheader.}

proc fullGetTokenData*(ctx: ptr Context; segment, token: cint): TokenData {.importc: "whisper_full_get_token_data", header: wheader.}
proc fullGetTokenDataFromState*(state: ptr State; segment, token: cint): TokenData {.importc: "whisper_full_get_token_data_from_state", header: wheader.}

proc fullGetTokenP*(ctx: ptr Context; segment, token: cint): cfloat {.importc: "whisper_full_get_token_p", header: wheader.}
proc fullGetTokenPFromState*(ctx: ptr Context; segment, token: cint): cfloat {.importc: "whisper_full_get_token_p", header: wheader.}

proc benchMemcpy*(threads: cint): cint {.importc: "whisper_bench_memcpy", header: wheader.}
proc benchMemcpyStr*(threads: cint): cstring {.importc: "whisper_bench_memcpy_str", header: wheader.}
proc benchMemcpyGgmlMulMat*(threads: cint): cint {.importc: "whisper_bench_ggml_mul_mat", header: wheader.}
proc benchMemcpyGgmlMulMatStr*(threads: cint): cstring {.importc: "whisper_bench_ggml_mul_mat_str", header: wheader.}

type 
    GgmlLogLevel*{.importc: "enum ggml_log_level", header: "ggml.h".} = enum
        Error = 2,
        Warn = 3,
        Info = 4
    GgmlLogCallback* = proc(level: GgmlLogLevel; text: cstring; userData: pointer): void
proc logSet*(callback: GgmlLogCallback; userData: pointer): void {.importc: "whisper_log_set", header: wheader.}
