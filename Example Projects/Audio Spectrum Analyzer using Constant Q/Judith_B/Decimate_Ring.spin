CON
    '' 80_000_000 / 1736 / 6 = 7680,49 Hz sampling rate
    '' Factor-6 decimation => 1280,08 Hz rate
    CYCLES      = 1736 * 6

VAR
    long    gCogId


{{
    pParams should point to an array of LONGs

    Offset  Name            Description
    ----------------------------------------------------------------------------
    0       Source          Address of LONG where samples are read
    1       BufStart        Ring buffer address
    2       BufSize         Size of ring buffer
    3       BufPos          Receives current write position in buffer
                            (zero-based, relative to BufStart, from 0 to BufSize-1)
}}
PUB start(pParams)
    stop
    gCogId := cognew(@decimate_entry, pParams) + 1
    return gCogId

PUB stop
    if gCogId
        cogStop(gCogId~ - 1)

DAT
                    org     0
decimate_entry

                    movd    :zero, #astage
                    mov     counter, #FIR_SIZE
:zero               mov     astage + 0, #0
                    add     :zero, c_512
                    djnz    counter, #:zero

                    mov     adc_cnt, PAR
                    rdlong  in_addr, adc_cnt
                    add     adc_cnt, #4
                    rdlong  buf_start, adc_cnt
                    add     adc_cnt, #4
                    rdlong  buf_size, adc_cnt

                    '' start sampling

                    mov     adc_cnt, cnt
                    add     adc_cnt, adc_cycles
:restart
                    mov     decimate_ctr, #6
                    mov     counter, buf_size
                    mov     buf_addr, buf_start
                    mov     buf_pos, #0

:loop               waitcnt adc_cnt, adc_cycles         'wait for next CNT value
                    rdword  x, in_addr
                    shl     x, #16
                    sar     x, #16
                    call    #fir
                    djnz    decimate_ctr, #:loop
                    mov     decimate_ctr, #6
                    wrword  y, buf_addr
                    mov     y, PAR
                    add     y, #12
                    wrlong  buf_pos, y
                    add     buf_addr, #2
                    add     buf_pos, #1
                    djnz    counter, #:loop
                    jmp     #:restart

fir

                    mov       h+20,x                  'DO NOT MODIFY.
                    mov       h+19,x                  'DO NOT MODIFY.
                    sar       x,#1                    'DO NOT MODIFY.
                    mov       h+15,x                  'DO NOT MODIFY.
                    mov       h+17,x                  'DO NOT MODIFY.
                    mov       h+14,x                  'DO NOT MODIFY.
                    mov       h+18,x                  'DO NOT MODIFY.
                    mov       h+16,x                  'DO NOT MODIFY.
                    sar       x,#1                    'DO NOT MODIFY.
                    mov       h+13,x                  'DO NOT MODIFY.
                    sub       h+20,x                  'DO NOT MODIFY.
                    mov       h+12,x                  'DO NOT MODIFY.
                    sub       h+19,x                  'DO NOT MODIFY.
                    sar       x,#1                    'DO NOT MODIFY.
                    add       h+17,x                  'DO NOT MODIFY.
                    sub       h+14,x                  'DO NOT MODIFY.
                    add       h+18,x                  'DO NOT MODIFY.
                    mov       h+11,x                  'DO NOT MODIFY.
                    sar       x,#1                    'DO NOT MODIFY.
                    mov       h+10,x                  'DO NOT MODIFY.
                    sub       h+15,x                  'DO NOT MODIFY.
                    sub       h+20,x                  'DO NOT MODIFY.
                    sub       h+12,x                  'DO NOT MODIFY.
                    sub       h+19,x                  'DO NOT MODIFY.
                    sar       x,#1                    'DO NOT MODIFY.
                    mov       h+6,x                   'DO NOT MODIFY.
                    mov       h+5,x                   'DO NOT MODIFY.
                    mov       h+3,x                   'DO NOT MODIFY.
                    mov       h+7,x                   'DO NOT MODIFY.
                    mov       h+4,x                   'DO NOT MODIFY.
                    sub       h+17,x                  'DO NOT MODIFY.
                    add       h+16,x                  'DO NOT MODIFY.
                    sar       x,#1                    'DO NOT MODIFY.
                    mov       h+9,x                   'DO NOT MODIFY.
                    add       h+13,x                  'DO NOT MODIFY.
                    mov       h+2,x                   'DO NOT MODIFY.
                    mov       h+8,x                   'DO NOT MODIFY.
                    sub       h+14,x                  'DO NOT MODIFY.
                    add       h+18,x                  'DO NOT MODIFY.
                    sar       x,#1                    'DO NOT MODIFY.
                    add       h+6,x                   'DO NOT MODIFY.
                    add       h+5,x                   'DO NOT MODIFY.
                    sub       h+3,x                   'DO NOT MODIFY.
                    mov       h+1,x                   'DO NOT MODIFY.
                    sub       h+16,x                  'DO NOT MODIFY.
                    sub       h+19,x                  'DO NOT MODIFY.
                    sar       x,#1                    'DO NOT MODIFY.
                    add       h+15,x                  'DO NOT MODIFY.
                    add       h+13,x                  'DO NOT MODIFY.
                    add       h+20,x                  'DO NOT MODIFY.
                    sub       h+8,x                   'DO NOT MODIFY.
                    sub       h+14,x                  'DO NOT MODIFY.
                    add       h+18,x                  'DO NOT MODIFY.
                    sub       h+11,x                  'DO NOT MODIFY.
                    sar       x,#1                    'DO NOT MODIFY.
                    add       h+9,x                   'DO NOT MODIFY.
                    add       h+6,x                   'DO NOT MODIFY.
                    sub       h+2,x                   'DO NOT MODIFY.
                    mov       h+0,x                   'DO NOT MODIFY.
                    add       h+12,x                  'DO NOT MODIFY.
                    sub       h+5,x                   'DO NOT MODIFY.
                    sub       h+3,x                   'DO NOT MODIFY.
                    sub       h+4,x                   'DO NOT MODIFY.
                    sub       h+17,x                  'DO NOT MODIFY.
                    sub       h+16,x                  'DO NOT MODIFY.

                    'Apply input * coefficients to FIR stages and shift one step.

                    mov       y,astage+0              'DO NOT MODIFY.
                    sar       y,#3                    'DO NOT MODIFY.

                    sub       astage+1,h+0            'DO NOT MODIFY.
                    mov       astage+0,astage+1       'DO NOT MODIFY.
                    sub       astage+2,h+1            'DO NOT MODIFY.
                    mov       astage+1,astage+2       'DO NOT MODIFY.
                    sub       astage+3,h+2            'DO NOT MODIFY.
                    mov       astage+2,astage+3       'DO NOT MODIFY.
                    sub       astage+4,h+3            'DO NOT MODIFY.
                    mov       astage+3,astage+4       'DO NOT MODIFY.
                    sub       astage+5,h+4            'DO NOT MODIFY.
                    mov       astage+4,astage+5       'DO NOT MODIFY.
                    sub       astage+6,h+5            'DO NOT MODIFY.
                    mov       astage+5,astage+6       'DO NOT MODIFY.
                    sub       astage+7,h+6            'DO NOT MODIFY.
                    mov       astage+6,astage+7       'DO NOT MODIFY.
                    sub       astage+8,h+6            'DO NOT MODIFY.
                    mov       astage+7,astage+8       'DO NOT MODIFY.
                    sub       astage+9,h+7            'DO NOT MODIFY.
                    mov       astage+8,astage+9       'DO NOT MODIFY.
                    sub       astage+10,h+8           'DO NOT MODIFY.
                    mov       astage+9,astage+10      'DO NOT MODIFY.
                    add       astage+11,h+9           'DO NOT MODIFY.
                    mov       astage+10,astage+11     'DO NOT MODIFY.
                    add       astage+12,h+10          'DO NOT MODIFY.
                    mov       astage+11,astage+12     'DO NOT MODIFY.
                    add       astage+13,h+11          'DO NOT MODIFY.
                    mov       astage+12,astage+13     'DO NOT MODIFY.
                    add       astage+14,h+12          'DO NOT MODIFY.
                    mov       astage+13,astage+14     'DO NOT MODIFY.
                    add       astage+15,h+13          'DO NOT MODIFY.
                    mov       astage+14,astage+15     'DO NOT MODIFY.
                    add       astage+16,h+14          'DO NOT MODIFY.
                    mov       astage+15,astage+16     'DO NOT MODIFY.
                    add       astage+17,h+15          'DO NOT MODIFY.
                    mov       astage+16,astage+17     'DO NOT MODIFY.
                    add       astage+18,h+16          'DO NOT MODIFY.
                    mov       astage+17,astage+18     'DO NOT MODIFY.
                    add       astage+19,h+17          'DO NOT MODIFY.
                    mov       astage+18,astage+19     'DO NOT MODIFY.
                    add       astage+20,h+18          'DO NOT MODIFY.
                    mov       astage+19,astage+20     'DO NOT MODIFY.
                    add       astage+21,h+19          'DO NOT MODIFY.
                    mov       astage+20,astage+21     'DO NOT MODIFY.
                    add       astage+22,h+20          'DO NOT MODIFY.
                    mov       astage+21,astage+22     'DO NOT MODIFY.
                    add       astage+23,h+19          'DO NOT MODIFY.
                    mov       astage+22,astage+23     'DO NOT MODIFY.
                    add       astage+24,h+18          'DO NOT MODIFY.
                    mov       astage+23,astage+24     'DO NOT MODIFY.
                    add       astage+25,h+17          'DO NOT MODIFY.
                    mov       astage+24,astage+25     'DO NOT MODIFY.
                    add       astage+26,h+16          'DO NOT MODIFY.
                    mov       astage+25,astage+26     'DO NOT MODIFY.
                    add       astage+27,h+15          'DO NOT MODIFY.
                    mov       astage+26,astage+27     'DO NOT MODIFY.
                    add       astage+28,h+14          'DO NOT MODIFY.
                    mov       astage+27,astage+28     'DO NOT MODIFY.
                    add       astage+29,h+13          'DO NOT MODIFY.
                    mov       astage+28,astage+29     'DO NOT MODIFY.
                    add       astage+30,h+12          'DO NOT MODIFY.
                    mov       astage+29,astage+30     'DO NOT MODIFY.
                    add       astage+31,h+11          'DO NOT MODIFY.
                    mov       astage+30,astage+31     'DO NOT MODIFY.
                    add       astage+32,h+10          'DO NOT MODIFY.
                    mov       astage+31,astage+32     'DO NOT MODIFY.
                    add       astage+33,h+9           'DO NOT MODIFY.
                    mov       astage+32,astage+33     'DO NOT MODIFY.
                    sub       astage+34,h+8           'DO NOT MODIFY.
                    mov       astage+33,astage+34     'DO NOT MODIFY.
                    sub       astage+35,h+7           'DO NOT MODIFY.
                    mov       astage+34,astage+35     'DO NOT MODIFY.
                    sub       astage+36,h+6           'DO NOT MODIFY.
                    mov       astage+35,astage+36     'DO NOT MODIFY.
                    sub       astage+37,h+6           'DO NOT MODIFY.
                    mov       astage+36,astage+37     'DO NOT MODIFY.
                    sub       astage+38,h+5           'DO NOT MODIFY.
                    mov       astage+37,astage+38     'DO NOT MODIFY.
                    sub       astage+39,h+4           'DO NOT MODIFY.
                    mov       astage+38,astage+39     'DO NOT MODIFY.
                    sub       astage+40,h+3           'DO NOT MODIFY.
                    mov       astage+39,astage+40     'DO NOT MODIFY.
                    sub       astage+41,h+2           'DO NOT MODIFY.
                    mov       astage+40,astage+41     'DO NOT MODIFY.
                    sub       astage+42,h+1           'DO NOT MODIFY.
                    mov       astage+41,astage+42     'DO NOT MODIFY.
                    sub       astage+43,h+0           'DO NOT MODIFY.
                    mov       astage+42,astage+43     'DO NOT MODIFY.
                    mov       astage+43,astage+44     'DO NOT MODIFY.

fir_ret             ret

minus1              long    -1
c_512               long    512
adc_cycles          long    CYCLES


buf_pos             res     1
buf_start           res     1
buf_size            res     1
adc_cnt             res     1
buf_addr            res     1
in_addr             res     1
counter             res     1
x                   res     1
decimate_ctr        res     1

y                   res     1                       'DO NOT MODIFY.
h                   res     FIR_SIZE / 2 + 1        'DO NOT MODIFY.
astage              res     FIR_SIZE                'DO NOT MODIFY.

                    FIT     496

CON
        FIR_SIZE = 45

