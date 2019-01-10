'' this is out of servo32v7, minus ramping to save spaceCON     _1uS = 1_000_000 /        1                                                 'Divisor for 1 uS    ZonePeriod = 5_000                                                          '5mS (1/4th of typical servo period of 20mS)    NoGlitchWindow = 3_000                                                      '3mS Glitch prevention window (set value larger than maximum servo width of 2.5mS)                                                                                'Use at least 500uS for overhead (actual overhead about 300uS)     LowRange = 500             '<- during Debug I changed this value to 1 to test 1us resolution    HighRange = 2500                                                                                VAR        long          ZoneClocks        long          NoGlitch        long          ServoPinDirection        long          ServoData[32]                                             '0-31 Current Servo Value         long          precalc        long          cog PUB Start    stop    ZoneClocks := (precalc * ZonePeriod)                                 'calculate # of clocks per ZonePeriod    NoGlitch   := $FFFF_FFFF-(precalc * NoGlitchWindow)                  'calculate # of clocks for GlitchFree servos. Problem occurs when 'cnt' value rollover is less than the servo's pulse width.                                                                                                                                                                                                                             result := cog := cognew(@ServoStart,@ZoneClocks) + 1PUB Set(Pin, Width)                                                     'Set Servo value   if (width)                  Width := LowRange #> Width <# HighRange                                 'limit Width value      Pin := Pin & 31'   0 #>   Pin <# 31                                              'limit Pin value between 0 and 31      ServoData[Pin] := (precalc * Width)                           'calculate # of clocks for a specific Pulse Width       dira[Pin] := 1                                                         'set selected servo pin as an OUTPUT      ServoPinDirection := dira                                                 'Read I/O state of ALL pins   else      dira[Pin] := 0                                                            'set selected servo pin as an OUTPUT      ServoPinDirection := dira                                                 'Read I/O state of ALL pinsPUB get(Pin)       return servoData[Pin]/precalcPUB stop'' stop servo  engine and release the cog  precalc := clkfreq / _1uS  ServoPinDirection~  if cog    cogstop(cog~ - 1)    DAT'*********************'* Assembly language *'*********************                        org'------------------------------------------------------------------------------------------------------------------------------------------------ServoStart              mov     Index,                  par                     'Set Index Pointer                        rdlong  _ZoneClocks,            Index                   'Get ZoneClock value                        add     Index,                  #4                      'Increment Index to next Pointer                        rdlong  _NoGlitch,              Index                   'Get NoGlitch value                        add     Index,                  #4                      'Increment Index to next Pointer                        mov     PinDirectionAddress,    Index                   'Set pointer for I/O direction Address                        add     Index,                  #32                     'Increment Index to END of Zone1 Pointer                        mov     Zone1Index,             Index                   'Set Index Pointer for Zone1                        add     Index,                  #32                     'Increment Index to END of Zone2 Pointer                        mov     Zone2Index,             Index                   'Set Index Pointer for Zone2                        add     Index,                  #32                     'Increment Index to END of Zone3 Pointer                        mov     Zone3Index,             Index                   'Set Index Pointer for Zone3                        add     Index,                  #32                     'Increment Index to END of Zone4 Pointer                        mov     Zone4Index,             Index                   'Set Index Pointer for Zone4IOupdate                rdlong  dira,                   PinDirectionAddress     'Get and set I/O pin directions'------------------------------------------------------------------------------------------------------------------------------------------------Zone1                   mov     ZoneIndex,              Zone1Index              'Set Index Pointer for Zone1                        call    #ResetZone                        call    #ZoneCoreZone2                   mov     ZoneIndex,              Zone2Index              'Set Index Pointer for Zone2                        call    #IncrementZone                        call    #ZoneCoreZone3                   mov     ZoneIndex,              Zone3Index              'Set Index Pointer for Zone3                        call    #IncrementZone                        call    #ZoneCoreZone4                   mov     ZoneIndex,              Zone4Index              'Set Index Pointer for Zone4                        call    #IncrementZone                        call    #ZoneCore                        jmp     #IOupdate'------------------------------------------------------------------------------------------------------------------------------------------------ResetZone               mov     ZoneShift1,             #1                        mov     ZoneShift2,             #2                                                mov     ZoneShift3,             #4                        mov     ZoneShift4,             #8                        mov     ZoneShift5,             #16                        mov     ZoneShift6,             #32                        mov     ZoneShift7,             #64                        mov     ZoneShift8,             #128ResetZone_RET           ret                        '------------------------------------------------------------------------------------------------------------------------------------------------IncrementZone           shl     ZoneShift1,             #8                        shl     ZoneShift2,             #8                                                shl     ZoneShift3,             #8                        shl     ZoneShift4,             #8                        shl     ZoneShift5,             #8                        shl     ZoneShift6,             #8                        shl     ZoneShift7,             #8                        shl     ZoneShift8,             #8IncrementZone_RET       ret                        '------------------------------------------------------------------------------------------------------------------------------------------------ZoneCore                mov     ServoByte,              #0                      'Clear ServoByte                        mov     Index,                  ZoneIndex               'Set Index Pointer for proper ZoneZoneSync                mov     SyncPoint,              cnt                     'Create a Sync Point with the system counter'                       mov     temp,                   _NoGlitch'                       sub     temp,                   SyncPoint            wc                        sub     _NoGlitch,              SyncPoint         nr,wc 'Test to make sure 'cnt' value won't rollover within Servo's pulse width              if_C      jmp     #ZoneSync                                       'If C flag is set get a new Sync Point, otherwise we are ok.'                       add     SyncPoint,              #220                    '<- Debug - 2us becomes 1us'                       add     SyncPoint,              #300                    '<- Debug - 2us becomes 3us                        add     SyncPoint,              #260                    'Add overhead offset to counter Sync point                                                                                'midpoint from above Debug test.                                                                                                         mov     LoopCounter,            #8                      'Set Loop Counter to 8 Servos for this Zone                        movd    LoadServos,             #ServoWidth8            'Restore/Set self-modifying code on "LoadServos" line                        movd    ServoSync,              #ServoWidth8            'Restore/Set self-modifying code on "ServoSync" line        LoadServos      rdlong  ServoWidth8,            Index                   'Get Servo Data                        sub     Index,                  #4                      'Decrement Index pointer to next address                        nop        ServoSync       add     ServoWidth8,            SyncPoint               'Determine system counter location where pulse should end                        sub     LoadServos,             d_field                 'self-modify destination pointer for "LoadServos" line                        sub     ServoSync,              d_field                 'self-modify destination pointer for "ServoSync" line                        djnz    LoopCounter,            #LoadServos             'Do ALL 8 servo positions for this Zone                        mov     temp,                   _ZoneClocks             'Move _ZoneClocks into temp                        add     temp,                   SyncPoint               'Add SyncPoint to _ZoneClocks'----------------------------------------------Start Tight Servo code-------------------------------------------------------------         ZoneLoop       mov     tempcnt,                cnt                     '(4 - clocks) take a snapshot of current counter value                        cmpsub  ServoWidth1,            tempcnt       nr,wc     '(4 - clocks) compare system counter to ServoWidth ; write result in C flag                        muxc    ServoByte,              ZoneShift1              '(4 - clocks) Set ServoByte.Bit0 to "0" or "1" depending on the value of "C"                        cmpsub  ServoWidth2,            tempcnt       nr,wc     '(4 - clocks) compare system counter to ServoWidth ; write result in C flag                        muxc    ServoByte,              ZoneShift2              '(4 - clocks) Set ServoByte.Bit1 to "0" or "1" depending on the value of "C"                        cmpsub  ServoWidth3,            tempcnt       nr,wc     '(4 - clocks) compare system counter to ServoWidth ; write result in C flag                        muxc    ServoByte,              ZoneShift3              '(4 - clocks) Set ServoByte.Bit2 to "0" or "1" depending on the value of "C"                        cmpsub  ServoWidth4,            tempcnt       nr,wc     '(4 - clocks) compare system counter to ServoWidth ; write result in C flag                        muxc    ServoByte,              ZoneShift4              '(4 - clocks) Set ServoByte.Bit3 to "0" or "1" depending on the value of "C"                        cmpsub  ServoWidth5,            tempcnt       nr,wc     '(4 - clocks) compare system counter to ServoWidth ; write result in C flag                        muxc    ServoByte,              ZoneShift5              '(4 - clocks) Set ServoByte.Bit4 to "0" or "1" depending on the value of "C"                        cmpsub  ServoWidth6,            tempcnt       nr,wc     '(4 - clocks) compare system counter to ServoWidth ; write result in C flag                        muxc    ServoByte,              ZoneShift6              '(4 - clocks) Set ServoByte.Bit5 to "0" or "1" depending on the value of "C"                        cmpsub  ServoWidth7,            tempcnt       nr,wc     '(4 - clocks) compare system counter to ServoWidth ; write result in C flag                        muxc    ServoByte,              ZoneShift7              '(4 - clocks) Set ServoByte.Bit6 to "0" or "1" depending on the value of "C"                        cmpsub  ServoWidth8,            tempcnt       nr,wc     '(4 - clocks) compare system counter to ServoWidth ; write result in C flag                        muxc    ServoByte,              ZoneShift8              '(4 - clocks) Set ServoByte.Bit7 to "0" or "1" depending on the value of "C"                        mov     outa,                   ServoByte               '(4 - clocks) Send ServoByte to Zone Port                        cmp     temp,                   tempcnt       nr,wc     '(4 - clocks) Determine if cnt has exceeded width of _ZoneClocks ; write result in C flag              if_NC     jmp     #ZoneLoop                                       '(4 - clocks) if the "C Flag" is not set stay in the current Zone'-----------------------------------------------End Tight Servo code--------------------------------------------------------------'                                                                        Total = 80 - clocks  @ 80MHz that's 1uS resolution ZoneCore_RET            ret'------------------------------------------------------------------------------------------------------------------------------------------------d_field                 long    $0000_0200PinDirectionAddress     long    0counter                 long    0Address1                long    0Address2                long    0Address3                long    0temp1                   long    0temp2                   long    0tempcnt                 long    0dly                     long    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0                        long    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0ServoWidth1             res     1ServoWidth2             res     1ServoWidth3             res     1ServoWidth4             res     1ServoWidth5             res     1ServoWidth6             res     1ServoWidth7             res     1ServoWidth8             res     1ZoneShift1              res     1ZoneShift2              res     1ZoneShift3              res     1ZoneShift4              res     1ZoneShift5              res     1ZoneShift6              res     1ZoneShift7              res     1ZoneShift8              res     1temp                    res     1Index                   res     1ZoneIndex               res     1Zone1Index              res     1Zone2Index              res     1Zone3Index              res     1Zone4Index              res     1SyncPoint               res     1ServoByte               res     1LoopCounter             res     1_ZoneClocks             res     1_NoGlitch               res     1_ServoPinDirection      res     1