CON

    CYCLE_US = 50_000
    CYCLE_HZ = 20

    #0
    O_ROWS
    O_COLS
    O_COLORS
    O_POWERS
    O_DB_TABLE
    O_EFFECT
    
    
    E_MASK_SPEED            = $000F

    E_SPEED_FAST            = $0000
    E_SPEED_SLOW            = $0001
    
    E_MASK_EFFECT           = $00F0

    E_RAIN_ONLY             = $0000
    E_PEAKS_ONLY            = $0010
    
    E_MAX                   = E_PEAKS_ONLY
    
VAR
    long    gPeaks[32]
    long    gPeakTimers[32]
    long    gCurrent[32]
    long    gCog
    
OBJ
    rgb: "colors"

PUB start(pParams)
    stop
    cPeakTimers := @gPeakTimers
    cPeaks := @gPeaks
    cCurrentValues := @gCurrent

    cRainSpeedSlow := speed(pParams, 1_500_000)
    cRainSpeedFast := speed(pParams, 0_550_000)
    cPeakSpeedSlow := speed(pParams, 3_000_000)
    cPeakSpeedFast := speed(pParams, 2_000_000)
    cDelaySlow := delay(0_600_000)
    cDelayFast := delay(0_300_000)

    cCycleDelay := CLKFREQ / CYCLE_HZ
    
    cYellowTh := long[pParams][O_ROWS] * 5 / 8
    cRedTh    := long[pParams][O_ROWS] * 7 / 8

    
    return gCog := (cognew(@entry, pParams) + 1)


PUB stop
    if gCog
        cogstop(gCog~ - 1)


PUB nextEffect(pCurrent, pColors) | i, j
    pColors := 0 '' Eliminate compiler warning - unused variable
    i := pCurrent & E_MASK_SPEED
    j := pCurrent & E_MASK_EFFECT
    i++
    if i > E_SPEED_SLOW
        i := E_SPEED_FAST
        j += $10
     if j > E_MAX
        j := 0
    return i | j

PRI speed(pParams, pSpeed)
    return (long[pParams][O_ROWS] << 8) / (pSpeed / CYCLE_US)

PRI delay(pUs)
    return (pUs / CYCLE_US)

DAT
entry               ORG     0
                    mov     cAddress, PAR
                    rdlong  cRows, cAddress
                    add     cAddress, #4
                    rdlong  cCols, cAddress
                    add     cAddress, #4
                    rdlong  cScreen, cAddress
                    add     cAddress, #4
                    rdlong  cPowers, cAddress
                    add     cAddress, #4
                    rdlong  cDBTable, cAddress
                    mov     cTimer, CNT
                    add     cTimer, cCycleDelay

loop                
                    waitcnt cTimer, cCycleDelay
                    mov     cAddress, PAR
                    add     cAddress, #O_EFFECT * 4
                    rdlong  cEffect, cAddress

                    mov     x, cEffect
                    and     x, #E_MASK_SPEED

                    cmp     x, #E_SPEED_SLOW          wz
        if_z        mov     cPeakDelay, cDelaySlow
        if_z        mov     cPeakSpeed, cPeakSpeedSlow
        if_z        mov     cRainSpeed, cRainSpeedSlow

                    cmp     x, #E_SPEED_FAST          wz
        if_z        mov     cPeakDelay, cDelayFast
        if_z        mov     cPeakSpeed, cPeakSpeedFast
        if_z        mov     cRainSpeed, cRainSpeedFast

                    mov     x, cEffect
                    and     x, #E_MASK_EFFECT
                    
                    mov     cEffectHandler, #effect_rain

                    cmp     x, #E_RAIN_ONLY                 wz
        if_z        mov     cEffectHandler, #effect_rain
                    cmp     x, #E_PEAKS_ONLY                wz
        if_z        mov     cEffectHandler, #effect_peaks

                    mov     cTimerAddress, cPeakTimers
                    mov     cPeakAddress, cPeaks
                    mov     cCurrentAddress, cCurrentValues
                    mov     cScreenAddr, cScreen
                    mov     cPowerAddr, cPowers
                    mov     c1, cCols
                    mov     bit_mask, #1

cols_loop           rdlong  x, cPowerAddr
                    call    #db
                    shl     x, #8

                    rdlong  cCurrent, cCurrentAddress
                    cmpsub  cCurrent, cRainSpeed            wc
        if_nc       mov     cCurrent, #0
                    min     cCurrent, x
                    wrlong  cCurrent, cCurrentAddress

                    rdlong  cPeak, cPeakAddress
                    cmp     cPeak, x                        wz, wc
        if_be       mov     cPeak, x
        if_be       wrlong  cPeakDelay, cTimerAddress
        if_be       jmp     #:peak_done
                    
                    rdlong  y, cTimerAddress                wz
                    
        if_nz       sub     y, #1
        if_nz       wrlong  y, cTimerAddress
        if_nz       jmp     #:peak_done

                    cmpsub  cPeak, cPeakSpeed               wc
        if_nc       mov     cPeak, #0
                    min     cPeak, x
:peak_done          wrlong  cPeak, cPeakAddress

                    shr     cCurrent, #8
                    shr     cPeak, #8
                    mov     c2, cRows

bar_loop            mov     c3, black
                    jmpret  0, cEffectHandler               nr
paint
                    cmp     c3, #0                          wz
                    rdlong  c3, cScreenAddr
                    muxnz   c3, bit_mask
                    wrlong  c3, cScreenAddr
                    add     cScreenAddr, #4
                    djnz    c2, #bar_loop
                    add     cPowerAddr, #4
                    mov     cScreenAddr, cScreen
                    
                    add     cCurrentAddress, #4
                    add     cTimerAddress, #4
                    add     cPeakAddress, #4
                    shl     bit_mask, #1
                    djnz    c1, #cols_loop

                    jmp     #loop


db                  mov     c2, cRows
                    mov     cAddress, cDBTable
:loop               rdlong  y, cAddress
                    cmp     y, x                        wz, wc
        if_a        jmp     #:done
                    add     cAddress, #4
                    djnz    c2, #:loop
:done               sub     cAddress, cDBTable
                    shr     cAddress, #2
                    mov     x, cAddress
db_ret              ret


effect_rain
                    cmp     c2, cCurrent                wz, wc
        if_be       mov     c3, # rgb#COLOR_GREEN_ONLY
                    jmp     #paint
effect_peaks
                    cmp     c2, cPeak                   wz, wc
        if_be       mov     c3, # rgb#COLOR_RED
                    jmp     #paint
                    
black               long    %%0000


inf                 long    $7FFF_FFFF

cCycleDelay         long    0

cPeaks              long    0
cCurrentValues      long    0
cPeakTimers         long    0

cRainSpeedSlow      long    0
cRainSpeedFast      long    0
cPeakSpeedSlow      long    0
cPeakSpeedFast      long    0
cDelaySlow          long    0
cDelayFast          long    0

cYellowTh           long    0
cRedTh              long    0

cEffectHandler      res     1
cTimer              res     1
cPeakDelay          res     1
cPeakSpeed          res     1
cRainSpeed          res     1
cPeakAddress        res     1
cCurrentAddress     res     1
cTimerAddress       res     1

cCurrent            res     1
cPeak               res     1

x                   res     1
y                   res     1
c1                  res     1
c2                  res     1
c3                  res     1
cAddress            res     1
cScreenAddr         res     1
cPowerAddr          res     1
bit_mask            res     1

cEffect             res     1

cRows               res     1
cCols               res     1
cScreen             res     1
cPowers             res     1
cDBTable            res     1
