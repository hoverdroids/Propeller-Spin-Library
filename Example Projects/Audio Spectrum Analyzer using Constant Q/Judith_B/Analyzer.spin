CON
    _XINFREQ = 5_000_000
    _CLKMODE = XTAL1 | PLL16X

    FsLOW   = 1280
    FsMID   = 7681
    FsHIGH  = 46083

    RANGE_DB = 30
    POWER_0_DB  = 45000

    BS_OFF      = 0
    BS_DEBOUNCE = 1
    BS_ON       = 2
    BS_HELD     = 3
    
    PIN_BUTTON  = 14
    PIN_CHANNEL = 13

    PIN_DEBUG   = 4

#ifdef VGA
    COLRS_ENABLED = true
#else
#ifdef HT1632_C
    COLRS_ENABLED = true
#else
#ifdef REGISTERS2
    COLRS_ENABLED = true
#else
    COLRS_ENABLED = false
#endif
#endif
#endif

OBJ
    f32         : "F32"
    adc         : "ADC_Decimate_Ring"
    dec         : "Decimate_Ring"
    cqt[3]      : "cqt"
    eeprom      : "eeprom"
    loader      : "snd_loader_2"

#ifdef VGA
    vga         : "vga"
#endif

#ifdef PWM
    effects     : "effects_pwm"
    pwm         : "pwm"
    waves       : "waves"
#else
    effects     : "effects"
    scroller    : "scroller"
#endif

#ifdef REGISTERS
    registers   : "registers"
#endif
#ifdef REGISTERS2
    registers   : "registers2"
#endif
#ifdef HT1632
    ht1632c     : "HT1632C"
#endif
#ifdef HT1632_C
    ht1632c2    : "HT1632C2"
#endif

#ifndef PWM
    banner      : "banner"
#endif

    'debug       : "FullDuplexSerial"
 
VAR
    word    gLowBuf[1024]
    word    gMidBuf[768 * 2]
    word    gHighBuf[768 * 2]
    
    long    gFStepLow[15], gFStepMid[15], gFStepHigh[15]
    long    gWStepLow[15], gWStepMid[15], gWStepHigh[15]
    long    gWSizeLow[15], gWSizeMid[15], gWSizeHigh[15]
    
    long    gPowers[35]
    
    
    long    gSpectrumThresholds[80]

    long    gDecSource
    long    gDecBufStart
    long    gDecBufSize
    long    gDecBufPos
    
    long    gADCPins
    long    gADCLowBufStart
    long    gADCLowBufSize
    long    gADCLowBufPos
    long    gADCHighBufStart
    long    gADCHighBufSize
    long    gADCHighBufPos
    long    gADCSample
    long    gADCOverloadA
    long    gADCOverloadB
    long    gADCMode

#ifdef VGA
    long    gDisplayParams[6]
#endif

    long    gCQTParams1[7]
    long    gCQTParams2[7]
    long    gCQTParams3[7]
    
    long    gCqtResult[3]
    byte    gCqtBusy[3]

#ifndef PWM
    long    gColors[32 * 45 / 4]
#endif    
    byte    gButtonState
    word    gButtonTimer
    
    word    Q
    
PUB main : i | lBufPos, timer, lProcessedMask, j, lWaitingMask, zero, idle

    gADCPins := 9 + 8 << 5 + 11 << 10 + 10 << 15
    gADCLowBufStart := @gMidBuf
    gADCLowBufSize := 768 * 2
    gADCHighBufStart := @gHighBuf
    gADCHighBufSize := 768 * 2

    DIRA[PIN_DEBUG]~~
    OUTA[PIN_DEBUG]~~
    i := INA[PIN_BUTTON]
    timer := CNT
    repeat 150
        waitcnt(timer += CLKFREQ / 100)
        if i  <> INA[PIN_BUTTON]
            repeat 100
                waitcnt(timer += CLKFREQ / 100)
                if i  == INA[PIN_BUTTON]
                    loader.main
            testMode
    DIRA[PIN_DEBUG]~

    f32.start
    calculateThresholds
    f32.stop

    adc.start(@gADCPins)
    
    gDecSource := @gADCSample
    gDecBufStart := @gLowBuf
    gDecBufSize := 1024

    dec.start(@gDecSource)

    cqt[0].start(@gCQTParams1)
    cqt[1].start(@gCQTParams2)
    cqt[2].start(@gCQTParams3)
    gCqtBusy[0] := gCqtBusy[1] := gCqtBusy[2] := 255
    
    calcSteps
    
#ifdef VGA
    gDisplayParams[vga#O_ROWS] := SPECTRUM_TICKS
    gDisplayParams[vga#O_COLS] := N_BANDS
    gDisplayParams[vga#O_XVIS] := 640
    gDisplayParams[vga#O_YVIS] := 14 * SPECTRUM_TICKS
    gDisplayParams[vga#O_COLORS] := @gColors
    vga.start(@gDisplayParams)
#endif

#ifdef HT1632
    ht1632c.start(@gColors, (N_BANDS) & !7 + 8, SPECTRUM_TICKS)
#endif

#ifdef HT1632_C
    ht1632c2.start(@gColors, (N_BANDS) & !7 + 8, SPECTRUM_TICKS)
#endif

#ifdef REGISTERS
    registers.start(@gColors, N_BANDS, SPECTRUM_TICKS)
#endif

#ifdef REGISTERS2
    registers.start(@gColors, N_BANDS, SPECTRUM_TICKS)
#endif

#ifdef PWM
    pwm.start(N_BANDS, SPECTRUM_TICKS)
    gEffectsParams[effects#O_COLORS] := pwm.workingBuffer
#else
    gEffectsParams[effects#O_COLORS] := @gColors
#endif

    
    gEffectsParams[effects#O_COLS] := N_BANDS
    gEffectsParams[effects#O_DB_TABLE] := @gSpectrumThresholds
    gEffectsParams[effects#O_POWERS] := @gPowers
    gEffectsParams[effects#O_ROWS] := SPECTRUM_TICKS
    effects.start(@gEffectsParams)

    timer := CNT
    repeat
        case  INA[PIN_CHANNEL .. PIN_CHANNEL-1]
            %10: gADCMode := 1
            %01: gADCMode := 2
            other: gADCMode := 0
        zero := TRUE
        if lWaitingMask := scanButton
            gEffectsParams[effects#O_EFFECT] := effects.nextEffect(gEffectsParams[effects#O_EFFECT], COLRS_ENABLED)
            if lWaitingMask == 1
                saveEffect
                timer := CNT    
            
        waitcnt(timer += 4000000)
        lWaitingMask := lProcessedMask := (-1 >> (32 - N_LOW_BANDS))
        repeat while lProcessedMask
            repeat j from 0 to 2
                if gCqtBusy[j] <> 255
                    ifnot cqt[j].isBusy
                        i := gCqtBusy[j]
                        lBufPos := gWSizeLow[i]  / 8
                        gCqtBusy[j] := 255
                        if (gPowers[i] := gCqtResult[j] / lBufPos / lBufPos) => gSpectrumThresholds[1]
                            zero := false
                        lProcessedMask &= !(1 << i)
                if gCqtBusy[j] == 255
                    i := (>|lWaitingMask) - 1
                    if i > -1
                        gCqtBusy[j] := i
                        lBufPos := gDecBufPos - gWSizeLow[i]
                        if lBufPos < 0
                            lBufPos += 1024
                        cqt[j].transformRing(@gLowBuf, @gCqtResult + j * 4, gWSizeLow[i], gWStepLow[i], gFStepLow[i], lBufPos, 1024, false)
                        lWaitingMask &= !(1 << i)
                            
        lWaitingMask := lProcessedMask := (-1 >> (32 - N_MID_BANDS))
        repeat while lProcessedMask
            repeat j from 0 to 2
                if gCqtBusy[j] <> 255
                    ifnot cqt[j].isBusy
                        i := gCqtBusy[j]
                        lBufPos := gWSizeMid[i]  / 8
                        gCqtBusy[j] := 255
                        if (gPowers[i + N_LOW_BANDS] := gCqtResult[j] / lBufPos / lBufPos) => gSpectrumThresholds[1]
                            zero := false

                        lProcessedMask &= !(1 << i)
                if gCqtBusy[j] == 255
                    i := (>|lWaitingMask) - 1
                    if i > -1
                        gCqtBusy[j] := i
                        lBufPos := gADCLowBufPos - gWSizeMid[i]
                        if lBufPos < 0
                            lBufPos += 768 * 2
                        cqt[j].transformRing(@gMidBuf, @gCqtResult + j * 4, gWSizeMid[i], gWStepMid[i], gFStepMid[i], lBufPos, 768*2, false)
                        lWaitingMask &= !(1 << i)

        lWaitingMask := lProcessedMask := (-1 >> (32 - N_HIGH_BANDS))
        repeat while lProcessedMask
            repeat j from 0 to 2
                if gCqtBusy[j] <> 255
                    ifnot cqt[j].isBusy
                        i := gCqtBusy[j]
                        lBufPos := gWSizeHigh[i]  / 8
                        gCqtBusy[j] := 255
                        if (gPowers[i + N_LOW_BANDS + N_MID_BANDS] := gCqtResult[j] / lBufPos / lBufPos) => gSpectrumThresholds[1]
                            zero := false
                        lProcessedMask &= !(1 << i)
                if gCqtBusy[j] == 255
                    i := (>|lWaitingMask) - 1
                    if i > -1
                        gCqtBusy[j] := i
                        lBufPos := gADCHighBufPos - gWSizeHigh[i]
                        if lBufPos < 0
                            lBufPos += 768 * 2
                        cqt[j].transformRing(@gHighBuf, @gCqtResult + j * 4, gWSizeHigh[i], gWStepHigh[i], gFStepHigh[i], lBufPos, 768*2, false)
                        lWaitingMask &= !(1 << i)
        if zero
            if idle < 100
                idle++
            else
#ifndef PWM
                ifnot scroller.running
                    effects.stop
                    scroller.start(@gColors, N_BANDS, SPECTRUM_TICKS, banner.getAddress)
#else
                ifnot waves.running
                    effects.stop
                    waves.start(pwm.workingBuffer, N_BANDS, SPECTRUM_TICKS)
#endif
        else 
            idle := 0
#ifndef PWM
            if scroller.running
                scroller.stop
                effects.start(@gEffectsParams)
#else
            if waves.running
                waves.stop
                effects.start(@gEffectsParams)
#endif
                    

PRI scanButton | x
    x := NOT INA[PIN_BUTTON]
    if gButtonState == BS_OFF
        if x
            gButtonState := BS_DEBOUNCE
            gButtonTimer := 0
        return false
    if gButtonState == BS_DEBOUNCE
        if not x
            gButtonState := BS_OFF
            gButtonTimer := 0
            return false
        if gButtonTimer++ == 2
            gButtonState := BS_ON
            gButtonTimer := 0
            return 1
    if gButtonState == BS_ON
        if x
            gButtonState := BS_HELD
            gButtonTimer := 0
        if gButtonTimer++ == 2
            gButtonState := BS_OFF
            gButtonTimer := 0
        return false
    if gButtonState == BS_HELD
        if x
            if gButtonTimer++ == 600
                gButtonTimer := 0
                return 2
            return false
        gButtonState := BS_OFF
        gButtonTimer := 0
        return false
            
    

PRI calcSteps : lAddr | lCenter, lNk, i
    lAddr := @FreqData
    Q := word[lAddr]
    lAddr += 2
    i := 0
    repeat
        lCenter := word[lAddr][i]
        ifnot lCenter
            quit
        lNk := FsLOW * Q / lCenter / 256
        gWSizeLow[i] := lNk
        gWStepLow[i] := $1000_0000 / lNk
        gFStepLow[i] := $0010_0000 / lNk * Q
        i++

    lAddr += N_LOW_BANDS * 2
    i := 0
    repeat
        lCenter := word[lAddr][i]
        ifnot lCenter
            quit
        lNk := FsMID * Q / lCenter / 256
        gWSizeMid[i] := lNk
        gWStepMid[i] := $1000_0000 / lNk
        gFStepMid[i] := $0010_0000 / lNk * Q
        i++

    lAddr += N_MID_BANDS * 2
    i := 0
    repeat
        lCenter := word[lAddr][i]
        ifnot lCenter
            quit
        lNk := FsHIGH * Q / lCenter / 256
        gWSizeHigh[i] := lNk
        gWStepHigh[i] := $1000_0000 / lNk
        gFStepHigh[i] := $0010_0000 / lNk * Q
        i++

PRI calculateThresholds : i | lRdBdiv10, lOneDivNTicks, lTmp, lPower0
    lRdBdiv10 := f32.FDiv(f32.FFloat(RANGE_DB), 10.0)
    lOneDivNTicks := f32.FDiv(1.0, f32.FFloat(SPECTRUM_TICKS))
    lPower0 := f32.FFloat(POWER_0_DB)

    '' for Ith tick, threshold is (POWER(10, (RANGE_DB*(I/NTICKS-1))/10)*POWER_0_DB
    repeat i from 0 to SPECTRUM_TICKS
        lTmp := f32.FMul ( f32.FFloat(i), lOneDivNTicks)
        lTmp := f32.FSub ( lTmp, 1.0)
        lTmp := f32.FMul ( lTmp, lRdBdiv10)
        lTmp := f32.Pow(10.0, lTmp)
        lTmp := f32.FMul(lTmp, lPower0)
        gSpectrumThresholds[i] := f32.FRound(lTmp)



PRI saveEffect
    eeprom.writeBlock(@gEffectsParams + effects#O_EFFECT * 4, @gEffectsParams + effects#O_EFFECT * 4, 4)

PRI testMode : i
    adc.start(@gADCPins)
    gADCMode := 0
    repeat
        OUTA[PIN_DEBUG]~
        if gADCOverloadA OR gADCOverloadB
            if gADCOverloadA AND gADCOverloadB
                OUTA[PIN_DEBUG]~
            else
                if i < 2 AND gADCOverloadA
                    OUTA[PIN_DEBUG]~~
                if i > 1 AND gADCOverloadB
                    OUTA[PIN_DEBUG]~~
        else
            OUTA[PIN_DEBUG]~~
        gADCOverloadA := gADCOverloadB := 0
        waitcnt(CNT + CLKFREQ / 10)
        i++
        if i > 15
            i := 0
DAT


#ifdef BANDS_11
FreqData
                word    683
                word    20, 40, 80, 160
                word    320, 640
                word    1280, 2560, 5120, 10240, 20480
#endif

#ifdef BANDS_16
FreqData
                word    1024
                word    20, 32, 50, 80, 128
                word    200, 320, 500, 800
                word    1280, 2030, 3225, 5120, 8130, 12900, 20480
#endif

#ifdef BANDS_21
FreqData
                word    1365
                word    20, 28, 40, 57, 80, 113, 160
                word    226, 320, 452, 640, 905
                word    1280, 1810, 2560, 3620, 5120, 7241, 10240, 14482, 20480
#endif
                
#ifdef BANDS_31
FreqData
                word    2048
                word    20, 25, 32, 40, 50, 63, 80, 101, 127, 160
                word    201, 254, 320, 403, 508, 640, 806
                word    1016, 1280, 1613, 2032, 2560, 3225, 4064, 5120, 6451, 8127, 10240, 12902, 16255, 20480
#endif


gEffectsParams  long    0[6]

CON
#ifdef TICKS_8
    SPECTRUM_TICKS = 8
#endif
#ifdef TICKS_10
    SPECTRUM_TICKS = 10
#endif
#ifdef TICKS_12
    SPECTRUM_TICKS = 12
#endif
#ifdef TICKS_16
    SPECTRUM_TICKS = 16
#endif
#ifdef TICKS_20
    SPECTRUM_TICKS = 20
#endif
#ifdef TICKS_24
    SPECTRUM_TICKS = 24
#endif
#ifdef TICKS_30
    SPECTRUM_TICKS = 30
#endif


#ifdef BANDS_11
    N_LOW_BANDS     = 4
    N_MID_BANDS     = 2
    N_HIGH_BANDS    = 5
    N_BANDS         = 11
#endif

#ifdef BANDS_16
    N_LOW_BANDS     = 5
    N_MID_BANDS     = 4
    N_HIGH_BANDS    = 7
    N_BANDS         = 16
#endif

#ifdef BANDS_21
    N_LOW_BANDS     = 7
    N_MID_BANDS     = 5
    N_HIGH_BANDS    = 9
    N_BANDS         = 21
#endif
                
#ifdef BANDS_31
    N_LOW_BANDS     = 10
    N_MID_BANDS     = 7
    N_HIGH_BANDS    = 14
    N_BANDS         = 31
#endif
