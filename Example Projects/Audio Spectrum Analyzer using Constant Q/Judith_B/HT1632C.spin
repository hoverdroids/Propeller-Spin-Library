CON
        PIN_CS      = 16
        PIN_DATA    = 18
        PIN_WR      = 17
        PIN_SYNC    = 19

VAR
    long    gScreen
    long    gStack[32]
    
OBJ
    rgb : "colors"

PUB start(pScreen, pCols, pRows)
    gScreen := pScreen
    row_cols := pRows * pCols
    cognew(@entry, pScreen)
    
        
DAT
entry
                    or      OUTA, mask_cs
                    or      OUTA, mask_wr
                    or      DIRA, mask_cs
                    or      DIRA, mask_wr
                    or      DIRA, mask_data
                    
                    call    #init
                    mov     frame_ctr, #511

:main               waitpne mask_sync, mask_sync
                    xor     frame, #1
                    andn    OUTA, mask_cs
                    mov     bits, #%101
                    mov     nBits, #3
                    call    #send_bits
                    mov     bits, #0
                    mov     nBits, #7
                    call    #send_bits
                    
                    mov     bits, #0
                    mov     nBits, #16
                    call    #send_bits
                    
                    mov     ctr, row_cols
                    mov     addr, PAR
:outer              mov     ctr2, #16
                    mov     bits, #0
:inner              shl     bits, #1
                    rdbyte  nBits, addr     wz
                    test    frame, #1       wc
        if_nz_and_c cmp     nBits, # rgb#COLOR_GREEN  wz
                    muxnz   bits, #1
                    add     addr, #1
                    djnz    ctr2, #:inner
                    mov     nBits, #16
                    call    #send_bits
                    sub     ctr, #16        wz
    if_nz           jmp     #:outer
                    or      OUTA, mask_cs
                    call    #delay

                    andn    OUTA, mask_cs
                    call    #delay
                    mov     bits, #100
                    mov     nBits, #3
                    call    #send_bits
                    test    frame, #1       wc
        if_nc       mov     bits, #%1010_0110_0
        if_c        mov     bits, #%1010_1111_0
                    mov     nBits, #9
                    call    #send_bits
                    or      OUTA, mask_cs
                    call    #delay
                    djnz    frame_ctr, #:main
                    mov     frame_ctr, #511
                    call    #init
                    jmp     #:main

init
                    andn    OUTA, mask_cs
                    mov     data, #%0000_0001
                    call    #send_cmd
                    or      OUTA, mask_cs
                    call    #delay

                    andn    OUTA, mask_cs
                    mov     data, #%0000_0011
                    call    #send_cmd
                    or      OUTA, mask_cs
                    call    #delay

                    andn    OUTA, mask_cs
                    mov     data, #%0010_0100
                    call    #send_cmd
                    or      OUTA, mask_cs
                    call    #delay
                    
init_ret            ret
                    
send_cmd            mov     bits, #%100
                    mov     nBits, #3
                    call    #send_bits
                    shl     data, #1
                    mov     bits, data
                    mov     nBits, #9
                    call    #send_bits
send_cmd_ret        ret

send_bits           ror     bits, nBits     '' MSB in bit 31
                    andn    OUTA, mask_wr
                    call    #delay
:loop               rol     bits, #1        wc
                    muxc    OUTA, mask_data
                    or      OUTA, mask_wr
                    call    #delay
                    andn    OUTA, mask_wr
                    call    #delay
                    djnz    nBits, #:loop
send_bits_ret       ret

delay               mov     time, #12
                    djnz    time, #$
delay_ret           ret
                    
mask_data           long    1 << PIN_DATA
mask_wr             long    1 << PIN_WR
mask_cs             long    1 << PIN_CS
mask_sync           long    1 << PIN_SYNC
row_cols            long    0

bits                res     1
nBits               res     1
data                res     1
time                res     1
ctr                 res     1
ctr2                res     1
addr                res     1
frame               res     1
frame_ctr           res     1
