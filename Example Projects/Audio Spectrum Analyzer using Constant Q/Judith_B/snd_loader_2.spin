CON
    _XINFREQ = 5_000_000
    _CLKMODE = XTAL1 | PLL16X

    PIN_INPUT       = 8
    PIN_FEEDBACK    = 9
    PIN_DEBUG       = 4
    
    CYCLES          = 300
    AVG_BITS        = 13
    
    AUDIO_RATE      = 32000
    
    PULSE_PRE      = 4
    PULSE_SYNC     = 3
    PULSE_ONE      = 2
    PULSE_ZERO     = 1


VAR 
    long  v
    long  ss

PUB main
    repeat result from 0 to 7
        if result <> cogid
            cogstop(result)
    'debug.start(31, 30, 0, 115200)
    'waitcnt(CLKFREQ + CNT)
    delay_0T5 := CLKFREQ / AUDIO_RATE / 2
    delay_1T  := CLKFREQ / AUDIO_RATE
    
    th_min  := delay_1T
    th_zero := delay_1T * 3
    th_one  := delay_1T * 5
    th_sync := delay_1T * 7
    th_max  := delay_1T * 9
    
    adc_cog := cognew(@adc, 0)
    cognew(@entry, @v)
    cogstop(cogid)

DAT

entry
                        mov     DIRA, debug_mask

start                   mov     led_mask, #1
                        shl     led_mask, #26
                        mov     pre_counter, #100
                        mov     byte_counter, #0
                        mov     bit_counter, #8
                        mov     bytes_to_read, #0
                        mov     count_read, #0
                        mov     checksum, #0
:preamble               call    #measure_pulse
                        cmp     pulse_len, #PULSE_PRE      wz
            if_nz       jmp     #start
                        djnz    pre_counter, #:preamble

:sync                   call    #measure_pulse
                        cmp     pulse_len, #PULSE_PRE      wz
            if_z        jmp     #:sync
                        cmp     pulse_len, #PULSE_SYNC     wz
            if_nz       jmp     #start
                        mov     led_mask, #1
                        shl     led_mask, #24

:data                   call    #measure_pulse
                        cmp     pulse_len, #PULSE_ZERO      wz
            if_nz       cmp     pulse_len, #PULSE_ONE       wz
            if_nz       jmp     #start
                        cmp     pulse_len, #PULSE_ONE       wz
                        shr     data_byte, #1
                        muxz    data_byte, #$80
                        djnz    bit_counter, #:data
                        and     data_byte, #$FF
                        mov     bit_counter, #8

                        cmp     count_read, #2              wz
        if_z            jmp     #:write_byte
                        shl     bytes_to_read, #8
                        or      bytes_to_read, data_byte
                        add     count_read, #1
                        'wrlong  bytes_to_read, PAR
                        jmp     #:data

                        
:write_byte             cmpsub  bytes_to_read, #1           wc
        if_nc           jmp     #:test_cs
                        add     checksum, data_byte
                        cmp     byte_counter, #4            wc, wz
        if_ae           wrbyte  data_byte, byte_counter
                        add     byte_counter, #1
                        jmp     #:data

:test_cs                and     checksum, #$FF
                        cmp     checksum, data_byte         wz
        if_nz           jmp     #start

' ----------------------------------------------------------------------------------
'                         STOP ALL COGS
' ----------------------------------------------------------------------------------
                        mov     bit_counter, #7
                        cogid   data_byte
:cogs_loop              cmp     data_byte, bit_counter      wz
        if_nz           cogstop bit_counter
                        cmpsub  bit_counter, #1             wc
        if_c            jmp     #:cogs_loop

' ----------------------------------------------------------------------------------
'                         ZERO RAM
' ----------------------------------------------------------------------------------
                        mov     bit_counter, h8000
                        sub     bit_counter, byte_counter
                        mov     data_byte, #0
:zero_loop              wrbyte  data_byte, bit_counter
                        add     bit_counter, #1
                        djnz    byte_counter, #:zero_loop
                        wrlong  h80M, #0
                        
                        
' ----------------------------------------------------------------------------------
'                         WRITE TO I2C EEPROM
' ----------------------------------------------------------------------------------
okk
                        mov     bytes_to_read, h8000
                        mov     byte_counter, #0
:loop                   call    #i2c_start
                        mov     i2c_data, #$A0
                        call    #i2c_send
        if_c            jmp     #start
                        mov     i2c_data, byte_counter
                        shr     i2c_data, #8
                        call    #i2c_send
                        mov     i2c_data, byte_counter
                        call    #i2c_send
                        mov     bit_counter, #64
:page                   rdbyte  i2c_data, byte_counter
                        add     byte_counter, #1
                        call    #i2c_send
                        djnz    bit_counter, #:page
:wait                   call    #i2c_stop
                        
                        call    #i2c_start
                        mov     i2c_data, #$A0
                        call    #i2c_send
        if_c            jmp     #:wait
                        call    #i2c_stop
                        
                        test    byte_counter, #511      wz
        if_z            xor     OUTA, debug_mask

                        sub     bytes_to_read, #64              wz
        if_nz           jmp     #:loop

                        or      OUTA, debug_mask
                        mov     timer, CNT
:halt                   waitcnt timer, #0
                        jmp     #:halt


i2c_delay               mov     timer, i2c_time
                        add     timer, CNT
                        waitcnt timer, #0
i2c_delay_ret           ret

i2c_start           or      DIRA, mask_sda
                    call    #i2c_delay
i2c_start_ret       ret

i2c_stop            or      DIRA, mask_scl
                    call    #i2c_delay
                    or      DIRA, mask_sda
                    call    #i2c_delay
                    andn    DIRA, mask_scl
                    call    #i2c_delay
                    andn    DIRA, mask_sda
                    call    #i2c_delay
i2c_stop_ret        ret

i2c_send            mov     i2c_count, #8
                    shl     i2c_data, #24

:loop               or      DIRA, mask_scl
                    call    #i2c_delay
                    shl     i2c_data, #1            wc
                    muxnc   DIRA, mask_sda
                    call    #i2c_delay
                    andn    DIRA, mask_scl
                    call    #i2c_delay
                    djnz    i2c_count, #:loop

                    or      DIRA, mask_scl
                    call    #i2c_delay
                    andn    DIRA, mask_sda
                    call    #i2c_delay
                    test    mask_sda, INA           wc
                    or      DIRA, mask_sda
                    call    #i2c_delay
                    andn    DIRA, mask_scl
                    call    #i2c_delay
i2c_send_ret        ret

measure_pulse
                        mov     thold, neg_th
                        call    #wait
        if_be           jmp     #:exit
                        mov     thold, pos_th
                        call    #wait
        if_be           jmp     #:exit

                        mov     timer, CNT

                        mov     thold, neg_th
                        call    #wait
        if_be           jmp     #:exit

                        mov     pulse_len, CNT
                        sub     pulse_len, timer
                        'add     pulse_len, delay_1T
                        
                        mov     timer, #0
                        cmp     pulse_len, th_max               wz, wc
        if_a            jmp     #:exit
                        cmp     pulse_len, th_min               wz, wc
        if_b            jmp     #:exit
                        cmp     pulse_len, th_sync              wz, wc
        if_a            mov     timer, #PULSE_PRE
        if_a            jmp     #:exit
                        cmp     pulse_len, th_one              wz, wc
        if_a            mov     timer, #PULSE_SYNC
        if_a            jmp     #:exit
                        cmp     pulse_len, th_zero              wz, wc
        if_a            mov     timer, #PULSE_ONE
        if_a            jmp     #:exit
                        mov     timer, #PULSE_ZERO
:exit                   mov     pulse_len, timer
measure_pulse_ret       ret

wait                    mov     wait_timer, #1
                        shl     wait_timer, #10
:loop                   rdlong  pulse_len, #0
                        test    led_mask, CNT               wc
                        muxc    OUTA, debug_mask
                        cmps    thold, #0                   wc, wz
        if_b            jmp     #:cmp_neg
                        cmps    pulse_len, thold         wz, wc
                        jmp     #:cmp_done
:cmp_neg                cmps    thold, pulse_len           wz, wc
:cmp_done
        if_a            jmp     #wait_ret
                        djnz    wait_timer, #:loop
                        cmp     wait_ret, wait_ret         wz, wc
wait_ret                ret

input_mask              long    1 << PIN_INPUT
debug_mask              long    1 << PIN_DEBUG
feedback_mask           long    1 << PIN_FEEDBACK
delay_0T5               long    0
delay_1T                long    0
neg_th                  long    -5
pos_th                  long    5
h8000                   long    $8000
h80M                    long    80_000_000
time_10ms               long    480000
reset                   long    128
mask_sda                long    1 << 29
mask_scl                long    1 << 28

th_min                  long    0
th_zero                 long    0
th_one                  long    0
th_sync                 long    0
th_pre                  long    0
th_max                  long    0
count_read              long    0
bytes_to_read           long    0
adc_cog                 long    0

i2c_time                long    150

wait_timer              res     1
led_mask                res     1
data_byte               res     1
bit_counter             res     1
byte_counter            res     1
pre_counter             res     1
timer                   res     1
pulse_len               res     1
thold                   res     1
checksum                res     1
i2c_count               res     1
i2c_data                res     1

                        FIT     496
                        
'***********************************************************************
adc                 ORG     0
'***********************************************************************

                    mov     DIRA, dira_mask
                    
                    movd    CTRA, #PIN_FEEDBACK
                    movs    CTRA, #PIN_INPUT
                    movi    CTRA, #%01001_000
                    mov     FRQA,#1

                    mov     avg_samples, #1
                    shl     avg_samples, #AVG_BITS

                    mov     adc_cnt, CNT
                    add     adc_cnt, adc_cycles
                    mov     adc_old, phsa

                    mov     avg_acc, #0
                    mov     avg_count, avg_samples

:loop               waitcnt adc_cnt, adc_cycles         'wait for next CNT value
                    mov     x, phsa                 'capture PHSA and get difference
                    sub     x, adc_old
                    add     adc_old, x

                    
                    add     avg_acc, x
                    sub     avg_count, #1               wz
    if_z            shr     avg_acc, #AVG_BITS
    if_z            mov     center, avg_acc
    if_z            mov     avg_acc, #0
    if_z            mov     avg_count, avg_samples
                    sub     x, center
                    
                    wrlong  x, #0
                    jmp     #:loop

adc_cycles          long    CYCLES
dira_mask           long    1 << PIN_FEEDBACK


x                   res     1
adc_old             res     1
adc_cnt             res     1
avg_acc             res     1
avg_count           res     1
avg_samples         res     1
center              res     1

                    FIT     496
