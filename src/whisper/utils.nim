import wave

const CommonSampleRate = 16000'u32

type
    WaveException* = object of CatchableError

proc toInt16Seq(buffer: seq[byte]): seq[int16] =
    result = newSeq[int16]()
    for i in countup(0, buffer.len, 2):
        if i in buffer.low .. buffer.high:
            let
                upper = buffer[i + 1].int16
                lower = buffer[i].int16
                t: int16 = (upper shl 8) or lower
            result.add(t)

proc readWav*(path: string): seq[cfloat] {.raises: [WaveException, IOError,
        OSError, WaveRIFFChunkDescriptorError, WaveFormatSubChunkError,
        WaveFormatError, WaveDataSubChunkError, WaveFactSubChunkError].} =
    ## Helper function to read a WAV file into the proper
    ## format for libwhisper.
    ##
    var wav = openWaveReadFile(path)
    if wav.numChannels != 1 and wav.numChannels != 2:
        wav.close()
        raise newException(WaveException, "WAV is not mono nor stereo")
    if wav.sampleRate != CommonSampleRate:
        wav.close()
        raise newException(WaveException, "WAV is not 16kHz")
    if wav.bitsPerSample != 16:
        wav.close()
        raise newException(WaveException, "WAV is not 16 bits per sample")
    var pcm16 = wav.readFrames(2).toInt16Seq()
    result = newSeq[cfloat]()
    case wav.numChannels:
        of numChannelsMono:
            for i in pcm16:
                let t = i.float / 32768.0
                result.add(t.cfloat)
        of numChannelsStereo:
            for i in countup(0, (wav.numFrames - 1).int):
                let ch = pcm16[2*i].cfloat + (pcm16[2*i + 1].cfloat / 65536.0)
                result.add(ch)
        else:
            discard
    wav.close()
