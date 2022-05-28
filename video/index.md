Перекодирование видео
=====================

Объединение файлов при помощи ffmpeg:

    $ ffmpeg -i "concat:VTS_02_1.VOB|VTS_02_2.VOB|VTS_02_3.VOB" -c copy VTS_02.VOB

Настроим профили mpv для перекодирования видео в файле /etc/mpv/encoding-profiles.conf:

    [enc-v-mpeg4]
    profile-desc = "MPEG-4 Part 2 (FFmpeg)"
    ovc = mpeg4
    ovcopts = qscale=4
    vf = scale=720:-2
    
    [enc-v-mpeg4-hd]
    profile-desc = "MPEG-4 Part 2 (FFmpeg)"
    ovc = mpeg4
    ovcopts = qscale=4
    vf = scale=1080:-2
    
    [enc-a-mp3]
    profile-desc = "MP3 (LAME)"
    oac = libmp3lame
    oacopts = b=128k
    audio-samplerate = 22050
    audio-format = s16
    
    [enc-f-avi]
    profile-desc = "MPEG-4 + MP3 (for AVI)"
    of = avi
    profile = enc-v-mpeg4
    profile = enc-a-mp3
    ofopts = ""
            
    [enc-f-avi-hd]
    profile-desc = "MPEG-4 HD + MP3 (for AVI)"
    of = avi
    profile = enc-v-mpeg4-hd
    profile = enc-a-mp3
    ofopts = ""

Перекодирование файла при помощи mpv при помощи настроенного профиля:

    $ mpv VTS_02.VOB --profile enc-f-avi --o video.avi
