CON
    PIN_SCK     = 19
    PIN_LOAD    = 18
    PIN_DATA    = 17

VAR

   byte gScreen[16*8] 

OBJ
    rgb : "colors"

PUB start(pScreen, pCols, pRows)
    mask_data := 1 << PIN_DATA
    mask_sck := 1 << PIN_SCK
    mask_load := 1 << PIN_LOAD
    screen := pScreen
    cols := pCols
    rows := pRows
    colsrows := pCols * pRows
    cognew(@entry, 0)

DAT

entry

                            or      dira, mask_sck
                            or      dira, mask_load
                            or      dira, mask_data

                            mov     timer, CNT
                            add     timer, delay
restart                     mov     c1, rows
                            mov     cAddress, screen
                            
:loop
                            'waitcnt timer, delay
                            mov     c3, #6
:pwm
                            neg     data, #2 '' zero in bit 0
                            ror     data, c1
                            rol     data, rows
                            mov     bits, rows
                            call    #shift

                            mov     c2, cols
                            mov     data, #0

:row                        
                            rdbyte  tmp, cAddress           wz
                            add     cAddress, rows

                            muxnz   data, #1
                            cmp     c3, #1                  wz
            if_e            jmp     #:no_pwm
                            cmp     tmp, # rgb#COLOR_GREEN  wz
            if_z            andn    data, #1
:no_pwm
                            ror     data, #1
                            djnz    c2, #:row
                            sub     cAddress, colsrows
                            rol     data, cols
                            mov     bits, cols
                            call    #shift
                            or      outa, mask_load
                            nop
                            andn    outa, mask_load
                            djnz    c3, #:pwm
                            add     cAddress, #1

                            djnz    c1, #:loop
                            jmp     #entry

                            

shift                       rol     data, #PIN_DATA
:loop                       mov     tmp, data
                            and     tmp, mask_data
                            xor     tmp, mask_data
                            mov     OUTA, tmp
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            or      OUTA, mask_sck
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            nop
                            andn    OUTA, mask_sck
                            ror     data, #1
                            djnz    bits, #:loop
shift_ret                   ret

mask_data                   long    0
mask_sck                    long    0
mask_load                   long    0
screen                      long    0
cols                        long    0
rows                        long    0
colsrows                    long    0

delay                       long    5000

timer                       res     1
c1                          res     1
c2                          res     1
c3                          res     1

cAddress                    res     1

data                        res     1
bits                        res     1
counter                     res     1
tmp                         res     1
