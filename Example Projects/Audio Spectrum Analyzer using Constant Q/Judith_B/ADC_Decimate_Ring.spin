CON
    CYCLES      = 1736 '' 80_000_000 / 1736 = 46082,9 Hz sampling rate
    AVG_BITS    = 13


VAR
    long    gCogId

{{
    pParams should point to an array of LONGs

    Offset  Name            Description
    ----------------------------------------------------------------------------
    0       Pins            ADC pin A in bits [9..5], feedback pin A in bits [4..0]
                            ADC pin B in bits [19..15], feedback pin B in bits [14..10]
    1       LowBufStart     Ring buffer address
    2       LowBufSize      Size of ring buffer
    3       LowBufPos       Receives current write position in buffer
                            (zero-based, relative to BufStart, from 0 to BufSize-1)
    4       HighBufStart    Ring buffer address
    5       HighBufSize     Size of ring buffer
    6       HighBufPos      Receives current write position in buffer
                            (zero-based, relative to BufStart, from 0 to BufSize-1)
    7       FilterOut       Address to receive decimated samples
    8       OverloadA       Address to receive channel A overload flag. The flag is never 
                            cleared by ADC itself
    9       OverloadB       Address to receive channel B overload flag. The flag is never 
                            cleared by ADC itself
    10       Mode           1 - channel A, 2 - channel B, otherwise - sum of 2 channels
}}
PUB start(pParams)
    stop
    gCogId := cognew(@adc_entry, pParams) + 1
    return gCogId


PUB stop
    if gCogId
        cogStop(gCogId~ - 1)

DAT
                    org     0
adc_entry
                    '' Read pin numbers, setup DIRA and counter

                    rdlong  tmp, PAR
                    mov     x, #1
                    shl     x, tmp
                    mov     DIRA, x
                    mov     x, tmp
                    and     x, #31
                    movd    CTRA, x
                    shr     tmp, #5
                    mov     x, tmp
                    and     x, #31
                    movs    CTRA, tmp
                    movi    ctra,#%01001_000
                    mov     frqa,#1

                    shr     tmp, #5
                    mov     x, #1
                    shl     x, tmp
                    or      DIRA, x
                    mov     x, tmp
                    and     x, #31
                    movd    CTRB, x
                    shr     tmp, #5
                    mov     x, tmp
                    and     x, #31
                    movs    CTRB, tmp
                    movi    ctrb,#%01001_000
                    mov     frqb,#1

                    movd    :zero, #astage
                    mov     low_counter, #FIR_SIZE
:zero               mov     astage + 0, #0
                    add     :zero, c_512
                    djnz    low_counter, #:zero


                    mov     high_addr, PAR
                    add     high_addr, #4
                    rdlong  low_buf_start, high_addr
                    add     high_addr, #4
                    rdlong  low_buf_size, high_addr
                    add     high_addr, #4
                    mov     low_buf_pos_addr, high_addr
                    add     high_addr, #4
                    rdlong  high_buf_start, high_addr
                    add     high_addr, #4
                    rdlong  high_buf_size, high_addr
                    add     high_addr, #4
                    mov     high_buf_pos_addr, high_addr
                    add     high_addr, #4
                    mov     out_addr, high_addr

                    mov     avg_acc_a, #0
                    mov     avg_acc_b, #0
                    mov     avg_count, avg_samples
                    mov     decimate_ctr, #6

                    mov     low_addr, low_buf_start
                    mov     low_counter, low_buf_size
                    mov     low_buf_pos, #0
                    mov     high_addr, high_buf_start
                    mov     high_counter, high_buf_size
                    mov     high_buf_pos, #0

                    '' start sampling
                    mov     adc_cnt, cnt
                    add     adc_cnt, adc_cycles
                    mov     adc_old_a, phsa
                    mov     adc_old_b, phsb


:loop               waitcnt adc_cnt, adc_cycles         'wait for next CNT value

                    mov     x, phsa                 'capture PHSA and get difference
                    sub     x, adc_old_a
                    add     adc_old_a, x

                    mov     y, phsb                  'capture PHSA and get difference
                    sub     y, adc_old_b
                    add     adc_old_b, y

                    add     avg_acc_a, x
                    add     avg_acc_b, y
                    sub     avg_count, #1               wz
    if_z            shr     avg_acc_a, #AVG_BITS
    if_z            mov     center_a, avg_acc_a
    if_z            mov     avg_acc_a, #0
    if_z            shr     avg_acc_b, #AVG_BITS
    if_z            mov     center_b, avg_acc_b
    if_z            mov     avg_acc_b, #0
    if_z            mov     avg_count, avg_samples

                    sub     x, center_a
                    sub     y, center_b
                    
                    mov     tmp, x
                    abs     tmp, tmp
                    cmp     tmp, overload                 wz, wc
    if_a            mov     tmp, PAR
    if_a            add     tmp, #8 * 4
    if_a            wrlong  tmp, tmp
                    
                    mov     tmp, y
                    abs     tmp, tmp
                    cmp     tmp, overload                 wz, wc
    if_a            mov     tmp, PAR
    if_a            add     tmp, #9 * 4
    if_a            wrlong  tmp, tmp
                    
                    mov     tmp, PAR
                    add     tmp, #10 * 4
                    rdlong  tmp, tmp
                    cmp     tmp, #1                     wz
    if_z            jmp     #:sum_done
                    cmp     tmp, #2                     wz
    if_z            mov     x, y
    if_z            jmp     #:sum_done
                    add     x, y
                    sar     x, #1

:sum_done
                    wrlong  high_buf_pos, high_buf_pos_addr
                    mov     high_addr, high_addr         wz
    if_nz           wrword  x, high_addr
    if_nz           add     high_addr, #2
                    add     high_buf_pos, #1
                    djnz    high_counter, #:do_decimate
                    mov     high_counter, high_buf_size
                    mov     high_buf_pos, #0
                    mov     high_addr, high_buf_start
:do_decimate
                    call    #fir
                    djnz    decimate_ctr, #:loop
                    mov     decimate_ctr, #6
                    wrlong  low_buf_pos, low_buf_pos_addr
                    mov     low_addr, low_addr          wz
    if_nz           wrword  y, low_addr
    if_nz           add     low_addr, #2
                    add     low_buf_pos, #1
                    djnz    low_counter, #:loop
                    mov     low_counter, low_buf_size
                    mov     low_buf_pos, #0
                    mov     low_addr, low_buf_start
                    jmp     #:loop

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

                    'Writing the y value here allows overlapped processing with another cog.
                    'Delete the next line to process the output further in this cog.

                    mov       out_addr, out_addr    wz
        if_nz       wrword    y, out_addr

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
c_1024              long    1024
c_512               long    512
adc_cycles          long    CYCLES
center_a            long    624
center_b            long    624
zero                long    0
avg_samples         long    1 << AVG_BITS
overload            long    (CYCLES / 2) * 495 / 500


low_buf_start       res     1
high_buf_start      res     1
low_buf_size        res     1
high_buf_size       res     1
low_buf_pos         res     1
high_buf_pos        res     1
low_buf_pos_addr    res     1
high_buf_pos_addr   res     1
adc_cnt             res     1
adc_old_a           res     1
adc_old_b           res     1
low_addr            res     1
high_addr           res     1
out_addr            res     1
low_counter         res     1
high_counter        res     1
x                   res     1
x2                  res     1
tmp                 res     1
avg_count           res     1
avg_acc_a           res     1
avg_acc_b           res     1
decimate_ctr        res     1

y                   res     1                       'DO NOT MODIFY.
h                   res     FIR_SIZE / 2 + 1        'DO NOT MODIFY.
astage              res     FIR_SIZE                'DO NOT MODIFY.


CON
        FIR_SIZE = 45

