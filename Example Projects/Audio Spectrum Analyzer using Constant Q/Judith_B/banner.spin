PUB getAddress
    return @banner
DAT

banner_marker

BYTE "BANER_MARKER", 0

banner

'BYTE "���������� ����� ������� JUDITH B. === ���������� ��� DIYAUDIO.RU "
 BYTE "                                                                  "

banner_zeros    BYTE 0[129 - (@banner_zeros - @banner)]
