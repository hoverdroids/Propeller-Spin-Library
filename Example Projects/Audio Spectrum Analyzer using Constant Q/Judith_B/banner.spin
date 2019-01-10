PUB getAddress
    return @banner
DAT

banner_marker

BYTE "BANER_MARKER", 0

banner

'BYTE "¿Õ¿À»«¿“Œ– ¿”ƒ»Œ —œ≈ “–¿ JUDITH B. === —œ≈÷»¿À‹ÕŒ ƒÀﬂ DIYAUDIO.RU "
 BYTE "                                                                  "

banner_zeros    BYTE 0[129 - (@banner_zeros - @banner)]
