CON
        PIN_CS      = 16
        PIN_DATA    = 18
        PIN_WR      = 17
        PIN_CLK     = 23

        CMD_RC_MASTER_MODE      = %00011000
        CMD_EXT_CLK_MASTER_MODE = %00011100
        CMD_SYS_EN              = %00000001     ' Turn on system oscillator
        CMD_LED_ON              = %00000011     ' Turn on LED duty cycle generator
        CMD_N_MOS_COM8          = %00100000
        CMD_PWM_16              = %10101111

VAR
    long    gStack[32]

OBJ
    rgb : "colors"

PUB start(pScreen, pCols, pRows)
    row_cols := pRows * pCols
    cognew(@entry, pScreen)
    
        
DAT
entry
                    or      OUTA, mask_cs
                    or      DIRA, mask_cs
                    or      DIRA, mask_clk
                    or      DIRA, mask_data
                    or      DIRA, mask_wr

                    call    #init
                    mov     frame_ctr, #511

:loop
                    mov     start_addr, #0
                    mov     pattern_1, # rgb#COLOR_GREEN
                    mov     pattern_2, # rgb#COLOR_GREEN_ONLY
                    mov     pattern_3, # rgb#COLOR_YELLOW
                    call    #plane
                    mov     start_addr, #32
                    mov     pattern_1, # rgb#COLOR_RED
                    mov     pattern_2, # rgb#COLOR_RED
                    mov     pattern_3, # rgb#COLOR_YELLOW
                    call    #plane
                    djnz    frame_ctr, #:loop
                    mov     frame_ctr, #511
                    call    #init
                    jmp     #:loop

init
                    mov     data, #CMD_SYS_EN
                    call    #send_cmd
                    mov     data, #CMD_LED_ON
                    call    #send_cmd
                    mov     data, #CMD_RC_MASTER_MODE
                    call    #send_cmd
                    mov     data, #CMD_N_MOS_COM8
                    call    #send_cmd
                    mov     data, #CMD_PWM_16
                    call    #send_cmd
init_ret            ret

' ************************************************************
plane
                    add     start_addr, #30
                    neg     running, #1
                    andn    running, #%0100
                    mov     ctr, row_cols
                    mov     address, PAR

:loop
                    test    ctr, #7             wz
        if_nz       jmp     #:no_cs

                    mov     bits, #%1111   ' select none
                    call    #select

                    test    ctr, #255             wz
        if_z        rol     running, #1
        if_z        sub     start_addr, #30
        if_z        jmp     #:no_test

                    test    ctr, #15             wz
        if_z        rol     running, #2
        if_z        add     start_addr, #2
        if_z        jmp     #:no_test
                    
                    ror     running, #2
:no_test
                    mov     bits, running
                    call    #select

                    
                    mov     bits, #%101
                    mov     nBits, #3
                    call    #send_bits
                    mov     bits, start_addr
                    mov     nBits, #7
                    call    #send_bits
:no_cs
                    mov     bits, #0
:next_byte          rdbyte  data, address
                    cmp     data, pattern_1     wz
        if_nz       cmp     data, pattern_2     wz
        if_nz       cmp     data, pattern_3     wz
                    shl     bits, #1
                    muxz    bits, #1
                    add     address, #1
                    sub     ctr, #1
                    test    ctr, #7            wz
        if_nz       jmp     #:next_byte
                    mov     nBits, #8
                    call    #send_bits
:no_send            cmp     ctr, #0             wz
        if_nz       jmp     #:loop

                    mov     bits, #%1111   ' select none
                    call    #select
plane_ret           ret
                    
send_cmd            
                    mov     bits, #0    ' select all
                    call    #select
                    mov     bits, #%100
                    mov     nBits, #3
                    call    #send_bits
                    shl     data, #1
                    mov     bits, data
                    mov     nBits, #9
                    call    #send_bits
                    mov     bits, #%1111    ' select none
                    call    #select
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

select              mov     nBits, #8
                    shl     bits, #4
                    or      bits, #%1111
:loop               shr     bits, #1        wc
                    muxc    OUTA, mask_cs
                    call    #delay
                    or      OUTA, mask_clk
                    call    #delay
                    andn    OUTA, mask_clk
                    djnz    nBits, #:loop
                    call    #delay
select_ret          ret                    

delay               mov     time, #5
                    djnz    time, #$
delay_ret           ret

                    
mask_cs             long    1 << PIN_CS
mask_clk            long    1 << PIN_CLK
mask_data           long    1 << PIN_DATA
mask_wr             long    1 << PIN_WR
row_cols            long    0

pattern_1           res     1
pattern_2           res     1
pattern_3           res     1

time                res     1
nBits               res     1
bits                res     1
data                res     1
ctr                 res     1
address             res     1
running             res     1
start_addr          res     1
frame_ctr           res     1