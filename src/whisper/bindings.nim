const wheader = "whisper.h"

const
    SampleRate* = 16000
    NoFFT* = 400
    HopLength* = 160
    ChunkSize* = 30

type
    Context* {.importc: "struct whisper_context", incompleteStruct,
            header: wheader.} = object
    State* {.importc: "struct whisper_state", incompleteStruct,
            header: wheader.} = object
    Position* {.importc: "whisper_pos", header: wheader.} = cint
    Token* {.importc: "whisper_token", header: wheader.} = cint
    SeqId* {.importc: "whisper_seq_id", header: wheader.} = cint
    ContextParams* {.importc: "struct whisper_context_params",
            header: wheader.} = object
        use_gpu*: bool
    TokenData* {.importc: "struct whisper_token_data",
            header: wheader.} = object
        id*, tid*: Token
        p*, plog*, pt*, ptsum*: cfloat
        t0*, t1*: clonglong
        vlen*: cfloat
    ModelLoader* {.importc: "struct whisper_model_loader",
            header: wheader.} = object
        context*: pointer
        read*: proc(ctx, ouput: pointer; readSize: csize_t): csize_t
        eof*: proc(ctx: pointer): bool
        close*: proc(ctx: pointer): void
    GrammarElementKind* {.importc: "enum whisper_gretype",
            header: wheader.} = enum
        End, Alt, RuleRef, Char, CharNot, CharRngUpper, CharAlt
    GrammarElement* {.importc: "struct whisper_grammar_element",
            header: wheader.} = object
        `type`*: GrammarElementKind
        value*: cuint
    SamplingStrategy* {.importc: "enum whisper_sampling_strategy",
            header: wheader.} = enum
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
    GreedyO* = object
        best_of*: cint
    BeamSearchO* = object
        beam_size*: cint
        patience*: cfloat
    FullParams* {.importc: "struct whisper_full_params",
            header: wheader.} = object
        strategy*: SamplingStrategy
        n_threads, n_max_text_ctx, offset_ms, duration_ms: cint
        translate, no_context, no_timestampts, single_segment, print_special,
            print_progress, print_realtime, print_timestampts: bool
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
        greedy: GreedyO
        beam_search: BeamSearchO
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
    file: cstring;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_from_file_with_params",
            dynlib: "libwhisper.so".}

proc initFromBufferWithParams*(
    buffer: pointer;
    bufferSize: csize_t;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_from_buffer_with_params",
            dynlib: "libwhisper.so".}

proc initWithParams*(
    loader: ptr ModelLoader;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_with_params",
            dynlib: "libwhisper.so".}

proc initFromFileWithParamsNoState*(
    model: cstring;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_from_file_with_params_no_state",
            dynlib: "libwhisper.so".}

proc initFromBufferWithParamsNoState*(
    buffer: pointer;
    bufferSize: csize_t;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_from_buffer_with_params_no_state",
            dynlib: "libwhisper.so".}

proc initWithParamsNoState*(
    loader: ptr ModelLoader;
    params: ContextParams
    ): ptr Context {.importc: "whisper_init_with_params_no_state",
            dynlib: "libwhisper.so".}

proc initState*(
    ctx: ptr Context
    ): ptr State {.importc: "whisper_init_state", dynlib: "libwhisper.so".}

proc initOpenvinoEncoder*(
    ctx: ptr Context;
    modelPath, device, cache_dir: cstring
): cint {.importc: "whisper_ctx_init_openvino_encoder",
        dynlib: "libwhisper.so".}

proc free*(ctx: ptr Context) {.importc: "whisper_free",
        dynlib: "libwhisper.so".}
proc freeState*(ctx: ptr State) {.importc: "whisper_free_state",
        dynlib: "libwhisper.so".}
proc freeParams*(params: ptr FullParams) {.importc: "whisper_free_params",
        dynlib: "libwhisper.so".}
proc freeContextParams*(params: ptr ContextParams) {.importc: "whisper_free_context_params",
        dynlib: "libwhisper.so".}

proc pcmToMel*(
    ctx: ptr Context;
    samples: ptr cfloat;
    noSamples, noThreads: cint
): cint {.importc: "whipser_pcm_to_mel", dynlib: "libwhisper.so".}
proc pcmToMelWithState*(
    ctx: ptr Context;
    state: ptr State;
    samples: ptr cfloat;
    noSamples, noThreads: cint
): cint {.importc: "whipser_pcm_to_mel_with_state", dynlib: "libwhisper.so".}
proc pcmToMelPhaseVocoder*(
    ctx: ptr Context;
    samples: ptr cfloat;
    noSamples, noThreads: cint
): cint {.importc: "whipser_pcm_to_mel_phase_vocoder", dynlib: "libwhisper.so".}
proc pcmToMelPhaseVocoderWithState*(
    ctx: ptr Context;
    state: ptr State;
    samples: ptr cfloat;
    noSamples, noThreads: cint
): cint {.importc: "whisper_pcm_to_mel_phase_vocoder_with_state",
        dynlib: "libwhisper.so".}
proc setMel*(
    ctx: ptr Context;
    data: ptr cfloat;
    noLen, noMel: cint
): cint {.importc: "whisper_set_mel", dynlib: "libwhisper.so".}
proc setMelWithState*(
    ctx: ptr Context;
    state: ptr State;
    data: ptr cfloat;
    noLen, noMel: cint
): cint {.importc: "whisper_set_mel_with_state", dynlib: "libwhisper.so".}

proc encode*(
    ctx: ptr Context;
    offset, noThreads: cint
    ): cint {.importc: "whisper_encode", dynlib: "libwhisper.so".}
proc encodeWithState*(
    ctx: ptr Context;
    state: ptr State;
    offset, noThreads: cint
    ): cint {.importc: "whisper_encode_with_state", dynlib: "libwhisper.so".}
proc decode*(
    ctx: ptr Context;
    tokens: cstring;
    noTokens, noPast, noThreads: cint
    ): cint {.importc: "whisper_decode", dynlib: "libwhisper.so".}
proc decodedWithState*(
    ctx: ptr Context;
    state: ptr State;
    tokens: cstring;
    noTokens, noPast, noThreads: cint
): cint {.importc: "whisper_decode_with_state", dynlib: "libwhisper.so".}

proc tokenize*(
    ctx: ptr Context;
    text: cstring;
    tokens: ptr Token;
    noMaxTokens: cint
): cint {.importc: "whisper_tokenize", dynlib: "libwhisper.so".}

proc langMaxId*(): cint {.importc: "whisper_lang_max_id",
        dynlib: "libwhisper.so".}
proc langId*(lang: cstring): cint {.importc: "whisper_lang_id",
        dynlib: "libwhisper.so".}
proc langStr*(id: cint): cstring {.importc: "whisper_lang_str",
        dynlib: "libwhisper.so".}
proc langStrFull*(id: cint): cstring {.importc: "whisper_lang_str_full",
        dynlib: "libwhisper.so".}

proc langAutoDetect*(
    ctx: ptr Context;
    offsetMs, noThreads: cint;
    langProbs: ptr cfloat
): cint {.importc: "whipser_lang_auto_detect", dynlib: "libwhisper.so".}

proc langAutoDetectWithState*(
    ctx: ptr Context;
    state: ptr State;
    offsetMs, noThreads: cint;
    langProbs: ptr cfloat
): cint {.importc: "whipser_lang_auto_detect_with_state",
        dynlib: "libwhisper.so".}

proc nLen*(ctx: ptr Context): cint {.importc: "whisper_n_len",
        dynlib: "libwhisper.so".}
proc nLenFromState*(ctx: ptr Context): cint {.importc: "whisper_n_len_from_state",
        dynlib: "libwhisper.so".}
proc nVocab*(ctx: ptr Context): cint {.importc: "whisper_n_vocab",
        dynlib: "libwhisper.so".}
proc nTextCtx*(ctx: ptr Context): cint {.importc: "whisper_n_text_ctx",
        dynlib: "libwhisper.so".}
proc nAudioCtx*(ctx: ptr Context): cint {.importc: "whisper_n_audio_ctx",
        dynlib: "libwhisper.so".}
proc isMultilingual*(ctx: ptr Context): cint {.importc: "whisper_is_multilingual",
        dynlib: "libwhisper.so".}

proc modelNVocab*(ctx: ptr Context): cint {.importc: "whisper_model_n_vocab",
        dynlib: "libwhisper.so".}
proc modelNAudioCtx*(ctx: ptr Context): cint {.importc: "whisper_model_n_audio_ctx",
        dynlib: "libwhisper.so".}
proc modelNAudioState*(ctx: ptr Context): cint {.importc: "whisper_model_n_audio_state",
        dynlib: "libwhisper.so".}
proc modelNAudioHead*(ctx: ptr Context): cint {.importc: "whisper_model_n_audio_head",
        dynlib: "libwhisper.so".}
proc modelNAudioLayer*(ctx: ptr Context): cint {.importc: "whisper_model_n_audio_layer",
        dynlib: "libwhisper.so".}
proc modelNTextCtx*(ctx: ptr Context): cint {.importc: "whisper_model_n_text_ctx",
        dynlib: "libwhisper.so".}
proc modelNTextState*(ctx: ptr Context): cint {.importc: "whisper_model_n_text_state",
        dynlib: "libwhisper.so".}
proc modelNTextHead*(ctx: ptr Context): cint {.importc: "whisper_model_n_text_head",
        dynlib: "libwhisper.so".}
proc modelNTextLayer*(ctx: ptr Context): cint {.importc: "whisper_model_n_text_layer",
        dynlib: "libwhisper.so".}
proc modelNMels*(ctx: ptr Context): cint {.importc: "whisper_model_n_mels",
        dynlib: "libwhisper.so".}
proc modelFType*(ctx: ptr Context): cint {.importc: "whisper_model_n_ftype",
        dynlib: "libwhisper.so".}
proc modelType*(ctx: ptr Context): cint {.importc: "whisper_model_n_type",
        dynlib: "libwhisper.so".}

proc getLogits*(ctx: ptr Context): ptr cfloat {.importc: "whisper_get_logits",
        dynlib: "libwhisper.so".}
proc getLogitsFromState*(ctx: ptr Context): ptr cfloat {.importc: "whisper_get_logits_from_state",
        dynlib: "libwhisper.so".}

proc tokenToStr*(ctx: ptr Context; token: Token): cstring {.importc: "whisper_token_to_str",
        dynlib: "libwhisper.so".}
proc modelTypeReadable*(ctx: ptr Context): cstring {.importc: "whisper_model_type_readable",
        dynlib: "libwhisper.so".}

proc tokenEot*(ctx: ptr Context): Token {.importc: "whisper_token_eot",
        dynlib: "libwhisper.so".}
proc tokenSot*(ctx: ptr Context): Token {.importc: "whisper_token_sot",
        dynlib: "libwhisper.so".}
proc tokenSolm*(ctx: ptr Context): Token {.importc: "whisper_token_solm",
        dynlib: "libwhisper.so".}
proc tokenPrv*(ctx: ptr Context): Token {.importc: "whisper_token_prev",
        dynlib: "libwhisper.so".}
proc tokenNosp*(ctx: ptr Context): Token {.importc: "whisper_token_nosp",
        dynlib: "libwhisper.so".}
proc tokenNot*(ctx: ptr Context): Token {.importc: "whisper_token_not",
        dynlib: "libwhisper.so".}
proc tokenBeg*(ctx: ptr Context): Token {.importc: "whisper_token_beg",
        dynlib: "libwhisper.so".}
proc tokenLang*(ctx: ptr Context; langId: cint): Token {.importc: "whisper_token_lang",
        dynlib: "libwhisper.so".}

proc tokenTranslate*(ctx: ptr Context): Token {.importc: "whisper_token_translate",
        dynlib: "libwhisper.so".}
proc tokenTranscribe*(ctx: ptr Context): Token {.importc: "whisper_token_transcribe",
        dynlib: "libwhisper.so".}

proc printTimings*(ctx: ptr Context) {.importc: "whisper_print_timings",
        dynlib: "libwhisper.so".}
proc resetTimings*(ctx: ptr Context) {.importc: "whisper_reset_timings",
        dynlib: "libwhisper.so".}

proc printSystemInfo*(): cstring {.importc: "whisper_print_system_info",
        dynlib: "libwhisper.so".}

proc contextDefaultParamsByRef*(): ptr ContextParams {.importc: "whisper_context_default_params_by_ref",
        dynlib: "libwhisper.so".}
proc contextDefaultParams*(): ContextParams {.importc: "whisper_context_default_params",
        dynlib: "libwhisper.so".}
proc fullDefaultParamsByRef*(strategy: SamplingStrategy): ptr FullParams {.importc: "whisper_full_default_params_by_ref",
        dynlib: "libwhisper.so".}
proc fullDefaultParams*(strategy: SamplingStrategy): FullParams {.importc: "whisper_full_default_params",
        dynlib: "libwhisper.so".}

proc full*(
    ctx: ptr Context;
    params: FullParams;
    buffer: ptr cfloat;
    bufferSize: cint
): cint {.importc: "whisper_full", dynlib: "libwhisper.so".}
proc fullWithState*(
    ctx: ptr Context;
    state: ptr State;
    params: FullParams;
    buffer: ptr cfloat;
    bufferSize: cint
): cint {.importc: "whisper_full_with_state", dynlib: "libwhisper.so".}
proc fullParallel*(
    ctx: ptr Context;
    params: FullParams;
    buffer: ptr cfloat;
    bufferSize, noProcessors: cint
): cint {.importc: "whisper_full_parallel", dynlib: "libwhisper.so".}

proc fullNSegments*(ctx: ptr Context): cint {.importc: "whisper_full_n_segments",
        dynlib: "libwhisper.so".}
proc fullNSegmentsFromState*(state: ptr State): cint {.importc: "whisper_full_n_segments__from_state",
        dynlib: "libwhisper.so".}

proc fullLangId*(ctx: ptr Context): cint {.importc: "whisper_full_lang_id",
        dynlib: "libwhisper.so".}

proc fullLangIdFromState*(state: ptr State): cint {.importc: "whisper_full_lang_id_from_state",
        dynlib: "libwhisper.so".}

proc fullGetSegmentT0*(ctx: ptr Context;
        segment: cint): clonglong {.importc: "whisper_full_get_segment_t0",
        dynlib: "libwhisper.so".}
proc fullGetSegmentT0FromState*(state: ptr State;
        segment: cint): clonglong {.importc: "whisper_full_get_segment_t0_from_state",
        dynlib: "libwhisper.so".}

proc fullGetSegmentT1*(ctx: ptr Context;
        segment: cint): clonglong {.importc: "whisper_full_get_segment_t1",
        dynlib: "libwhisper.so".}
proc fullGetSegmentT1FromState*(state: ptr State;
        segment: cint): clonglong {.importc: "whisper_full_get_segment_t1_from_state",
        dynlib: "libwhisper.so".}

proc fullGetSegmentSpeakerTurnNext*(state: ptr State;
        segment: cint): bool {.importc: "whisper_full_get_segment_speaker_turn_next",
        dynlib: "libwhisper.so".}
proc fullGetSegmentSpeakerTurnNextFromState*(
    state: ptr State;
    segment: cint
): bool {.importc: "whisper_full_get_segment_speaker_turn_next_from_state",
        dynlib: "libwhisper.so".}

proc fullGetSegmentText*(ctx: ptr Context;
        segment: cint): cstring {.importc: "whisper_full_get_segment_text",
        dynlib: "libwhisper.so".}
proc fullGetSegmentTextFromState*(ctx: ptr State;
        segment: cint): cstring {.importc: "whisper_full_get_segment_text_from_state",
        dynlib: "libwhisper.so".}

proc fullNTokens*(ctx: ptr Context; segment: cint): cint {.importc: "whisper_full_n_tokens",
        dynlib: "libwhisper.so".}
proc fullNTokensFromState*(state: ptr State;
        segment: cint): cint {.importc: "whisper_full_n_tokens_from_state",
        dynlib: "libwhisper.so".}

proc fullGetTokenNext*(ctx: ptr Context; segment,
        token: cint): cstring {.importc: "whisper_full_get_token_next",
        dynlib: "libwhisper.so".}
proc fullGetTokenNextFromState*(ctx: ptr Context; state: ptr State; segment,
        token: cint): cstring {.importc: "whisper_full_get_token_next_from_state",
        dynlib: "libwhisper.so".}

proc fullGetTokenId*(ctx: ptr Context; segment,
        token: cint): Token {.importc: "whisper_full_get_token_id",
        dynlib: "libwhisper.so".}
proc fullGetTokenIdFromState*(state: ptr State; segment,
        token: cint): Token {.importc: "whisper_full_get_token_id_from_state",
        dynlib: "libwhisper.so".}

proc fullGetTokenData*(ctx: ptr Context; segment,
        token: cint): TokenData {.importc: "whisper_full_get_token_data",
        dynlib: "libwhisper.so".}
proc fullGetTokenDataFromState*(state: ptr State; segment,
        token: cint): TokenData {.importc: "whisper_full_get_token_data_from_state",
        dynlib: "libwhisper.so".}

proc fullGetTokenP*(ctx: ptr Context; segment,
        token: cint): cfloat {.importc: "whisper_full_get_token_p",
        dynlib: "libwhisper.so".}
proc fullGetTokenPFromState*(ctx: ptr Context; segment,
        token: cint): cfloat {.importc: "whisper_full_get_token_p",
        dynlib: "libwhisper.so".}

proc benchMemcpy*(threads: cint): cint {.importc: "whisper_bench_memcpy",
        dynlib: "libwhisper.so".}
proc benchMemcpyStr*(threads: cint): cstring {.importc: "whisper_bench_memcpy_str",
        dynlib: "libwhisper.so".}
proc benchMemcpyGgmlMulMat*(threads: cint): cint {.importc: "whisper_bench_ggml_mul_mat",
        dynlib: "libwhisper.so".}
proc benchMemcpyGgmlMulMatStr*(threads: cint): cstring {.importc: "whisper_bench_ggml_mul_mat_str",
        dynlib: "libwhisper.so".}

type
    GgmlLogLevel*{.importc: "enum ggml_log_level", header: "ggml.h".} = enum
        Error = 2,
        Warn = 3,
        Info = 4
    GgmlLogCallback* = proc(level: GgmlLogLevel; text: cstring;
            userData: pointer): void
proc logSet*(callback: GgmlLogCallback; userData: pointer): void {.importc: "whisper_log_set",
        dynlib: "libwhisper.so".}
