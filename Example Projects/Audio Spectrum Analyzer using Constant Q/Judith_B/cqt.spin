CON
    #0
    O_INPUT
    O_LEN
    O_F_PHASE
    O_W_PHASE
    O_OUTPUT
    O_BUFPOS
    O_BUFSIZE

VAR
    long    gCog
    long    gParams


PUB start(pParams)
    stop
    gParams := pParams
    return gCog := (cognew(@cqt_entry, pParams)+1)

PUB stop
    if gCog
        cogStop(gCog~ - 1)

PUB transform(pInput, pOutput, pLen, pWPhase, pFPhase, pWait)
    doTransform(pInput, pOutput, pLen, pWPhase, pFPhase, 0, pLen, pWait)

PUB transformRing(pInput, pOutput, pLen, pWPhase, pFPhase, pBufPos, pBufSize, pWait)
    doTransform(pInput, pOutput, pLen, pWPhase, pFPhase, pBufPos, pBufSize, pWait)

PRI doTransform(pInput, pOutput, pLen, pWPhase, pFPhase, pBufPos, pBufSize, pWait)
    wait
    long[gParams][O_BUFPOS]  := pBufPos
    long[gParams][O_BUFSIZE]  := pBufSize
    long[gParams][O_F_PHASE]  := pFPhase
    long[gParams][O_W_PHASE]  := pWPhase
    long[gParams][O_LEN]      := pLen
    long[gParams][O_OUTPUT]   := pOutput
    long[gParams][O_INPUT]    := pInput
    if pWait
        wait

PUB wait
    repeat while long[gParams][O_INPUT] <> 0

PUB isBusy
    return long[gParams][O_INPUT] <> 0

DAT

cqt_entry

:wait                   rdlong  cInput, PAR             wz
        if_z            jmp     #:wait

                        mov     c1, PAR
                        add     c1, #4
                        rdlong  len, c1
                        add     c1, #4
                        rdlong  cDFPhase, c1
                        add     c1, #4
                        rdlong  cDWPhase, c1
                        add     c1, #4
                        rdlong  cOutput, c1
                        add     c1, #4
                        rdlong  cBufPos, c1
                        add     c1, #4
                        rdlong  cBufSize, c1

                        mov     c1, len
                        mov     cWPhase, #0
                        mov     cFPhase, #0
                        mov     cAddress1, cBufPos
                        shl     cAddress1, #1
                        add     cAddress1, cInput
                        mov     re, #0
                        mov     im, #0
:mainloop
                        '' calculate Hamming window coefficient
                        mov     sin, cWPhase
                        shr     sin, #15
                        call    #getcos

                        mov     m_1, sin
                        mov     m_2, c_0_456521739
                        call    #mult
                        neg     m_3, m_3
                        add     m_3, c_0_543478261

                        
                        '' apply window
                        mov     m_1, m_3
                        rdword  m_2, cAddress1
                        shl     m_2, #16
                        sar     m_2, #16
                        call    #mult
                        mov     sample, m_3

                    '' calculate real and imaginary part
                        mov     sin, cFPhase
                        shr     sin, #15
                        call    #getcos
                        mov     m_1, sin
                        mov     m_2, m_3
                        call    #mult
                        add     re, m_3

                        mov     sin, cFPhase
                        shr     sin, #15
                        call    #getsin
                        mov     m_1, sin
                        mov     m_2, sample
                        call    #mult
                        add     im, m_3
                      
                        add     cAddress1, #2
                        add     cBufPos, #1
                        cmp     cBufPos, cBufSize       wz, wc
        if_ae           mov     cBufPos, #0
        if_ae           mov     cAddress1, cInput
                        add     cWPhase, cDWPhase
                        add     cFPhase, cDFPhase
                        djnz    c1, #:mainloop
                        
                        '' calculate power
                        sar     re, #3
                        abs     m_1, re
                        call    #mult2
                        mov     sample, m_3
                        sar     im, #3
                        abs     m_1, im
                        call    #mult2
                        add     sample, m_3

                        wrlong  sample, cOutput

:done                   mov     sample, #0
                        wrlong  sample, PAR
                        jmp     #:wait

mult
                        abs     m_1, m_1        wc
                        muxc    sgn, #1
                        mov     m_3, #0                          '' initialize product
                        shl     m_1, #16                         '' shift miltiplier's MSB to bit 31
:loop                   shl     m_1, #1          wc, wz          '' get bit
        if_c            add     m_3, m_2                          '' add multiplicand if bit was one
        if_nz           sar     m_2, #1          wz              '' shift multiplicand
        if_nz           jmp     #:loop                          '' repeat if there are more '1' bits
                        sar     m_3, #1                          '' scale product
                        test    sgn, #1         wc
                        negc    m_3, m_3
mult_ret                ret


mult2                   mov     m_3, #0
                        mov     m_2, m_1
:loop                   shr     m_1, #1          wc, wz
            if_c        add     m_3, m_2
                        shl     m_2, #1
            if_nz       jmp     #:loop
mult2_ret               ret


getcos                  add     sin ,PI_2
getsin                  test    sin, PI_2           wc
                        test    sin, PI_            wz
                        negc    sin, sin
                        or      sin, sin_table
                        shl     sin, #1
                        rdword  sin, sin
                        negnz   sin, sin
getsin_ret
getcos_ret ret

PI_2                    long    $0800
PI_                     long    $1000
sin_table               long    $E000 >> 1
c_8191                  long    8191

c_0_456521739           long    29919 '' (1 - 25/46) * 65536
c_0_543478261           long    35617 '' 25/46 * 65536
c_0_5                   long    32768

sin                     res     1
cos                     res     1
cInput                  res     1
cBufPos                 res     1
cBufSize                res     1
m_1                     res     1
m_2                     res     1
m_3                     res     1
cOutput                 res     1
len                     res     1
c1                      res     1
cDFPhase                res     1
cDWPhase                res     1
cFPhase                 res     1
cWPhase                 res     1
cAddress1               res     1
re                      res     1
im                      res     1
sample                  res     1
sgn                     res     1