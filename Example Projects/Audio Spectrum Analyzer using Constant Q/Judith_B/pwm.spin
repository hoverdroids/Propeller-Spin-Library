CON
    _XINFREQ = 5_000_000
    _CLKMODE = XTAL1 | PLL16X

    PIN_CLK     = 19
    PIN_LOAD    = 18
    PIN_DATA    = 17

    RESERVED    = 7

VAR
    long    gPWMValues[50]

PUB fullBuffer
    return @gPWMValues

PUB workingBuffer
    return @gPWMValues + RESERVED * 4

PUB start(pCols, pRows)
    writeMode := (%00100 << 26) | (PIN_DATA << 0)
    clockLineMode := (%00100 << 26) | (PIN_CLK << 0) ' NCO, 50% duty cycle
    screen := @gPWMValues
    cols := pCols
    longfill(@gPWMValues, -1, RESERVED)
    rows := pRows + RESERVED
    colsrows := pCols * rows
    cognew(@entry, @gPWMValues)
    
DAT
entry               mov     DIRA, mask_clk
                    or      DIRA, mask_data
                    or      DIRA, mask_load
                    mov     CTRA, writeMode
                    mov     CTRB, clockLineMode

                    mov     tmp, #start_send
                    add     tmp, cols
                    movd    :wr_stop, tmp
                    add     tmp, #1
                    movd    :wr_go, tmp
:wr_stop            mov     0-0, stop_clock
:wr_go              mov     0-0, goto_load
                    
:llll               mov     address, PAR
                    mov     row_ctr, rows
:lll                rdlong  bits, address
                    call    #send_bits
                    add     address, #4
                    djnz    row_ctr, #:lll
                    jmp     #:llll
                    


send_bits           
                    mov     PHSB, #0             ' make sure my clock accumulator is right
                    mov     PHSA, bits
                    ror     PHSA, cols
start_send          movi    FRQB, #%010000000
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    rol     PHSA, #1
                    mov     FRQB, #0             ' shuts the clock off, _after_ this instruction
                    jmp     #load_reg
load_reg            or      OUTA, mask_load
                    andn    OUTA, mask_load
send_bits_ret       ret

stop_clock          mov     FRQB, #0
goto_load           jmp     #load_reg

mask_data           long    1 << PIN_DATA
mask_clk            long    1 << PIN_CLK
mask_load           long    1 << PIN_LOAD
screen              long    0
cols                long    0
rows                long    0
colsrows            long    0
c_512               long    512
pwm_phase           long    0
writeMode           long    0
clockLineMode       long    0
values              long    0[40]

value               res     1
pwm                 res     1
bit_cnt             res     1
bits                res     1
address             res     1
col_ctr             res     1
row_ctr             res     1
tmp                 res     1
pwm_ctr             res     1

