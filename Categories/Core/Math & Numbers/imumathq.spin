{{
OBEX LISTING:
  http://obex.parallax.com/object/278

  These are I2C drivers for

  HMC5843 tri-axis compass
  ITG-3200 tri-axis gyro
  ADXL345 tri-axis accelerometer
  BMP085 pressure sensor
  BLINKM RGB led
  They use the SpinLMM object for inline PASM.
}}
{{
┌───────────────────────────────┬───────────────────┬────────────────────┐
│    SPIN_TrigPack.spin v0.1    │ Author: I.Kövesdi │  Rel.: 27 Aug 2009 │  
├───────────────────────────────┴───────────────────┴────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This small Qs15-16 Fixed-point trig package is written entirely in    │
│ SPIN and provides you complete floating point math and the basic       │
│ trigonometric functions for robot and navigation projects. You can     │
│ do ATAN2 without enlisting extra COGs to run a full Floating-point     │
│ library. This object contains StringToNumber, NumberToString conversion│
│ utilities to make Fixed-point math easy for your applications.         │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  32-bit Fixed-point arithmetic with SPIN is done in Qs15_16 format. The│
│ Qvalue numbers have a sign bit, 15 bits for the integer part and 16    │
│ bits for the fraction.                                                 │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  The natural expansion from the 32-bit Qvalue numbers will lead us to  │
│ the 64-bit dQvalue numbers, that have Qs31_32 double precision Fixed-  │
│ point format.                                                          │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘

  ┌────────────────────────────────────────────────────────┐
  │ Trimmed and tuned for imu usage                        │
  │ Author: Tim Moore                                      │               
  │ Copyright (c) Sept 2009 Tim Moore                      │               
  └────────────────────────────────────────────────────────┘

  Added Ln function
}}
CON

'ROM address constants----------------------------------------------------
_BASE_SINTABLE   = $E000
_BASEHALF        = _BASE_SINTABLE >> 1
_PIHALF          = $0800

'Trig
_360D            = (360 << 16)
_270D            = (270 << 16)
_180D            = (180 << 16)
_90D             = (90 << 16) 

'String parameters
_MAX_STR_LENGTH  = 10

_64K             = 65_536
_32K             = _64K / 2

OBJ 
'  uarts         : "pcFullDuplexSerial4FC"               '1 COG for 4 serial ports

DAT
'Strings
'BYTE             strB[12]       'String Buffer
        strB  BYTE             0[12]       'String Buffer

'64-bit results
'LONG             dQval[2]       '64-bit result
        dQval LONG             0[2]       '64-bit result

PUB QvalToStr(qV) : strP | ip, fp, d, nz, cp, c
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ QvalToStr │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a Qs15_16 (qValue) number into ASCII string
'' Parameters: Number in Qs15_16 format                              
''    Results: Pointer to zero terminated ASCII string             
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: SPIN_TrigPack_Error
'-------------------------------------------------------------------------
  'Set pointer to string buffer
  strP := @strB
  cp~

  'Check sign of qValue
  IF (qV < 0)
    qV := ||qV
    BYTE[strP][cp++] := "-" 

  'Separate Integer and Fractional parts
  ip := qV >> 16
  fp := (qV << 16) >> 16  

  d := 100_000                  '2^16 approx. 64K, 5 decimal
                                'digit range
  nz~
  REPEAT 6
    IF (ip => d)
      BYTE[strP][cp++] := (ip / d) + "0"               
      ip //= d
      nz~~                                
    ELSEIF (nz OR (d == 1))
      BYTE[strP][cp++] := (ip / d) + "0"      
    d /= 10

  IF (fp > 0)
    BYTE[strP][cp++] := "."     'Add decimal point
    fp := (fp * 3125) >> 11     'Normalize fractional part

    d := 10_000                 '1/2^16 approx. 2E-5, 4 decimal
                                'digit range
    fp := fp + 5
    REPEAT 4
      IF (fp => d)
        BYTE[strP][cp++] := (fp / d) + "0"               
        fp //= d                                
      ELSE
        BYTE[strP][cp++] := (fp / d) + "0"
      d /= 10

    'Remove trailing zeroes of decimal fraction
    REPEAT
      IF (BYTE[strP][--cp] <> "0")
        QUIT

    BYTE[strP][++cp] := 0
  ELSE
    BYTE[strP][cp] := 0   
'-------------------------------------------------------------------------
 
PUB StrToQval(strP) | sg, ip, d, fp, qv, r
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ StrToQval │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a String to Qs15_16 (qValue) format
'' Parameters: Pointer to zero terminated ASCII string
''    Results: Number in Qs15_16 Fixed-point qValue format
''+Reads/Uses: None
''    +Writes: None
''      Calls: SPIN_TrigPack_Error
'-------------------------------------------------------------------------
sg := 0
ip := 0
d := 0
fp := 0
REPEAT _MAX_STR_LENGTH
  CASE BYTE[strP]
    "-":
      sg := 1
    "+":

    ".",",":
      d := 1
    "0".."9":
      IF (d==0)                            'Collect integer part
        ip := ip * 10 + (BYTE[strP] - "0")
      ELSE                                 'Collect decimal part
        fp := fp * 10 + (BYTE[strP] - "0")
        d := d + 1
    0:
      QUIT
    OTHER:
      RETURN 0
  ++strP

'Process Integer part
IF (ip > _32K)
  RETURN 0
ip := ip << 16

'Process Fractional part
r~
IF (d > 1)
 fp := fp << (17 - d)
  REPEAT (d-1)
    r := fp // 5
    fp := fp / 5
    IF (r => 2)
      ++fp

qv := ip + fp

IF sg
  -qv

RETURN qv

PUB QvalToIangle(qV) : ia | s
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ QvalToIangle │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Converts Qs15_16 qValue Angle [deg] to iAngle format Angle
'' Parameters: Angle [deg] in Qs15_16 Fixed-point format                               
''    Results: Angle in iAngle (Index of Angle) format (4K=2Pi)                  
''+Reads/Uses: - _C_QVD2IA error constant
''             - _OVERFLOW error constant
''             - _94388224 overflow limit                  
''    +Writes: - e_orig    global error variable
''             - e_kind    global error variable                                
''      Calls: SPIN_TrigPack_Error
''       Note: - iAngle format is the index of the angle format for the 
''               ROM table reading procedures
''             - This procedure takes care of roundings
'-------------------------------------------------------------------------
  s~
  IF (qV < 0)
    -qV
    s~~

  'Scale up integer part of qValue.
  'Multiply up this scaled-up integer part
  'Calculate rounded iAngle
  ia := ((((qV >> 7) * 2912) >> 15) + 1) >> 1

  'Set sign
  IF s
    -ia
'-------------------------------------------------------------------------

PUB Qmul(arg1, arg2) : h | l, r, s
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Qmul │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies Qs15_16 Fixed-point numbers
'' Parameters: Multiplicand and Multiplier in Qs15_16 Fixed-point format                               
''    Results: Product in Qs15_16 Fixed-point format                   
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: None
''       Note: - Fixed-point addition and subtraction goes directly with
''               the + - operators of SPIN. 
''             - Intermediate results are in Qs31_32 double precision
''               Fixed-point format in (h, l), notated as dQvalue 
'-----------------------------1--------------------------------------------
' approx cost 163.25 us (80MHz)
'
'Check sign
  s~
  IF (arg1 < 0)
    s := 1
    arg1 := ||arg1
  IF (arg2 < 0)
    s := s ^ 1
    arg2 := ||arg2

  'Multiply  
  h := arg1 ** arg2
  l := arg1 * arg2

  'Convert dQvalue Qs31_32 double precision Fixed-point number in (h, l)
  'into Qs15_16 Qvalue number
  h := (h << 16) + (((l >> 15) + 1) >> 1)

  IF s
    -h
'-------------------------------------------------------------------------

PUB Qdiv(arg1, arg2) : qV | s, h, l
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Qdiv │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Divides Qs15_16 Fixed-point numbers
'' Parameters: Divider and Dividant are in Qs15_16 Fixed-point format                               
''    Results: Quotient in Qs15_16 Fixed-point format                   
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: None
''       Note: Fixed-point addition and subtraction goes directly, for
''             Multiplication and Division we have to take care of the
''             position of the decimal point and the rounding
'-------------------------------------------------------------------------
' approx cost 1530.75 us
'
'Check sign
  s~
  IF (arg1 < 0)
    s := 1
    arg1 := ||arg1
  IF (arg2 < 0)
    s := s ^ 1
    arg2 := ||arg2

  'Convert divident into 64-bit Fixed-point dQvalue
  h := arg1 >> 16
  l := arg1 << 16

  'Perform division
  REPEAT 32
    h := (h << 1) + (l >> 31)
    l <<= 1
    qV <<= 1
    IF (h > arg2)   
      qV++
      h -= arg2
    
  IF s
    -qV
'-------------------------------------------------------------------------

PUB Qsqr(arg) : qV | ls, fs, o, iv 
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Qsqr │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates the square root of a Qs15_16 Fixed-point number
'' Parameters: Argument in Qs15_16 Fixed-point format                                               
''    Results: Square-root of argument in Qs15_16 Fixed-point format    
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: Qdiv
'-------------------------------------------------------------------------
  ls := 32 - (>| arg)
  arg := arg << ls
  iv := ^^arg
  o := ls & 1
  ls := ls ~> 1
  IF ( ls =< 8)
    qV := iv << (8 - ls)
  ELSE
    qV := iv >> (ls - 8)

  IF o
    qV := Qmul(qV, constant((trunc((0.707106))<<16)|round(((0.707106)-float(trunc((0.707106))))*65536.0)))

'-------------------------------------------------------------------------
PRI Div64(dh, dl, dr) : qQ | cf
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ Div64 │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Divides a 64-bit dQvalue with q 32-bit Qvalue
' Parameters: - Hi and Lo part of dividend
'             - Divisor                                                                                     
'     Result: Quotient in Qs15_16 Fixed-point Qvalue format                                                                    
'+Reads/Uses: None                    
'    +Writes: None                                    
'      Calls: None
'       Note: - Assumes positive arguments
'             - Some optimization might be done for speed here
'-------------------------------------------------------------------------
  REPEAT 32
    cf := dh < 0
    dh := (dh << 1) + (dl >> 31)
    dl <<= 1
    qQ <<= 1
    IF (dh > dr) OR cf
      ++qQ
      dh -= dr

PUB Qradius(qX, qY) : qR | hx, lx, hy, ly, h, l, cf, ap
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ QRadius │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates Distance of point (X,Y) from the origo  
'' Parameters: X, Y Descartes coordinates in Qs15_16 Fixed-point format                                
''     Result: Distance from the origo in Qs15_16 Fixed-point format                   
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: Add64, Div64
''       Note: QAngle(qX, qY) is encrypted as Deg_ATAN2(qX, qY)
'-------------------------------------------------------------------------
  qX := ||qX
  qY := ||qY
  hx := qX ** qX
  lx := qX * qX
  hy := qY ** qY
  ly := qY * qY

  hx += hy
  IF ((lx < 0) AND (ly < 0)) OR (((lx < 0) OR (ly < 0)) AND ((lx + ly) => 0))
    hx++
  lx += ly

  'Check for zero hx
  IF (hx == 0)
    RETURN (Qsqr(lx) >> 8)  
  ELSE
    'Prepare SQR iteration loop
    qR := (^^hx) << 16                   
    'Do iteration 3 times
    REPEAT 3
      'Perform 64-bit division
      ap := Div64(hx, lx, qR)
      'Calculate next approximation as qR
      qR := (qR + ap) >> 1
      IF (qR == ap)
        QUIT

#ifndef QUICKATAN2
PUB Deg_ATAN2(qX,qY) :qV |ix,iy,x,y,xy,sh,n,d,ia,fa,iv,r,c,s,cr
'-------------------------------------------------------------------------
'------------------------------┌───────────┐------------------------------
'------------------------------│ Deg_ATAN2 │------------------------------
'------------------------------└───────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Calculates Arc Tangent of an Angle in [deg] between
''             [-180,180] from the X, Y rectangular coordinates
'' Parameters: - X, Y rectangular coordinates in Qs15_16 iValue format                                
''    Results: Angle [deg] in Qs15_16 format                   
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: SPIN_TrigPack_Error, Qdiv, Qmul, Qsqr, COS_Deg, SIN_Deg
''       Note: - This function is used mostly to convert from rectangular 
''               (X,Y) to  polar (R,Angle) coordinates that must satisfy
''
''                        X = R*COS(Angle) and Y = R*SIN(Angle)
''
''             - The ATAN2 function takes into account the signs of both
''               vector components, and places the angle in the correct
''               quadrant. For example
''                                                     
''                     ATAN2( .707, .707) =    pi/4 =>   45 degrees
''                     ATAN2(-.707, .707) =   -pi/4 =>  135 degrees    
''                     ATAN2( .707,-.707) =  3*pi/4 =>  -45 degrees
''                     ATAN2(-.707,-.707) = -3*pi/4 => -135 degrees
''
''                    (where the Qs15_16 iValue of 0.707 is 46333)
''
''             - The sign of ATAN2 is the same as the sign of Y.
''             - The ATAN2 function is useful in many applications
''               involving vectors in Euclidean space, such as finding the
''               direction from one point to another. A principal use is
''               in computer graphics rotations or in INS computations,
''               for converting rotation matrix representations into Euler
''               angles. For inclinometers it is used to calculate tilt
''               angles and with magnetometers to find heading. 
''             - Precision of this procedure is always better than 0.04
''               degrees over the[-180,180] range
''             - Average absolute precision is about 0.02 degrees
''             - It uses only a single parameter (0.28) in the equation
''
''                      Angle = (X * Y) / (X * X + 0.28 * Y * Y)
''
''               and that is followed by a Newton-Raphson refinement step 
''
''    Modified return angles for better IMU support
''
'-------------------------------------------------------------------------
  'Check arguments
  IF (qX==0)
    IF (qY>0)
      RETURN 0
    ELSE
      RETURN constant(_180D)
  IF (qY==0)
    IF (qX=>0)
      RETURN constant(_90D)
    ELSE
      RETURN constant(_270D) '-(_90D))

  ix := ||qX
  iy := ||qY

  x := >| ix
  y := >| iy

  sh := (19 - x - y)
  IF (sh => 0)
    sh := sh ~> 1 '/ 2
    ix := ix << sh
    iy := iy << sh
  ELSE
    sh := (||sh) ~> 1 '/ 2
    ix := ix >> sh
    iy := iy >> sh
  xy := ix * iy

  IF (xy =< 292812)
    REPEAT
      --sh
      xy := xy << 2
      IF (xy => 292812)
        ++sh
        QUIT
  ELSE
    REPEAT
      ++sh
      xy := xy >> 2
      IF (xy =< 292812)
        QUIT

  x := (||qX) >> (sh+1)         '+1 since overflow with x = 1, y = -256
  y := (||qY) >> (sh+1)

  IF (iy =< ix)
    'ia := (7334 * x * y) / (128 * x * x + 35 * y * y)   
    n := 7334 * x * y
    y *= y
    d := ((x * x) << 7) + (y << 5) + (y << 1) + y 
    ia := n / d
    fa := n // d
    'Normalize fractional part
    d := d >> 16
    fa := fa / d
    'Convert to iValue
    'Integer part
    iv := ia << 16
    'Combine with fractional part    
    qV := iv + fa
  ELSE
    'ia := 90 - (7334 * x * y) / (128 * y * y + 35 * x * x)
    n := 7334 * x * y
    x *= x
    d := ((y * y) << 7) + (x << 5) + (x << 1) + x 
    ia := n / d
    fa := n // d
    'Normalize fractional part
    d := d >> 16
    fa := fa / d
    'Convert to iValue
    'Integer part
    iv := ia << 16
    'Combine with fractional part    
    qV := iv + fa
    'Final result
    qV := _90D - qV

  'Normalize x and y so that x^2 + y^2 = 1.
  ix := ||qX
  iy := ||qY

  if ((ix & $ffff) == 0) AND ((iy & $ffff) == 0)        ' if fractional parts are zero
    r := (ix ** ix + iy ** iy)
    r := ^^r
    r <<= 16
  else
    r := Qradius(ix, iy)
{
    if ix => QCONS(128.0) OR iy => QCONS(128.0)
      ix ~>= 6
      iy ~>= 6
    r := Qmul(ix ,ix) + Qmul(iy, iy)
    r := Qsqr(r)
}
  'One-shot Newton-Raphson refinement of angle
  c := QMul(SIN_ROM(QvalToIangle(qV) + _PIHALF), r)     'Approx. Cosine
  s := QMul(SIN_ROM(QvalToIangle(qV)), r)               'Approx. Sine
  IF (ix =< iy)
    cr := -Qdiv(ix - c, s)
  ELSE
    cr := Qdiv(iy - s, c)
  qV := qV + QMul(cr, constant((trunc((57.3))<<16)|round(((57.3)-float(trunc((57.3))))*65536.0)))

  'Calc magnitude of angle
  IF (qX < 0)
    qV := constant(_180D) - qV
  'Calc sign of Angle
  IF (qY < 0)
    IF (qX < 0)
      qV := _360D -qV
    else
      -qV
  qV := constant(_90D) - qV
  if qV < 0
    qV += _360D
#endif
'-------------------------------------------------------------------------
{PUB SIN_ROM(iA)
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ SIN_ROM │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: - Reads value from SIN Table according to iAngle address
' Parameters: Angle in iAngle (Index of Angle) units                                 
'     Result: Sine value for Angle in Qs15_16 Qvalue format                    
'+Reads/Uses: - _BASE_SINTABLE   (= $E000)
'             - qValue from ROM SIN Table                  
'    +Writes: None                                    
'      Calls: None
'       Note: - SIN table contains 2K 16-bit word data for the 1st
'               quadrant in [$E000-$F000] 4KB locations
'             - Word index goes up and down and up and down in quadrants
'                  [0, 90]      [90, 180]      [180, 270]     [270, 380]
'                    up            down            up            down
'
'   quadrant:        1              2              3              4
'   angle:     $0000...$07FF  $0800...$0FFF  $1000...$17FF  $1800...$1FFF
'   w.index:   $0000...$07FF  $0800...$0001  $0000...$07FF  $0800...$0001
'       (The above 3 lines were taken after the Propeller Manual v1.1)
'
'             - Code size 70 bytes   
'             - Average exec. time is 3192 cnt (40 usec at 80 MHz)
'-------------------------------------------------------------------------
CASE (iA & %1_1000_0000_0000)
  %0_0000_0000_0000:                             '1st quadrant [0, 90]
    RETURN WORD[_BASE_SINTABLE][iA & $7FF]
  %0_1000_0000_0000:                             '2nd quadrant [90, 180]
    RETURN WORD[_BASE_SINTABLE][-iA & $7FF]  
  %1_0000_0000_0000:                             '3rd quadrant [180, 270]
    RETURN -WORD[_BASE_SINTABLE][iA & $7FF]
  %1_1000_0000_0000:                             '4th quadrant [270, 380]
    RETURN -WORD[_BASE_SINTABLE][-iA & $7FF]  
'-------------------------------------------------------------------------
PUB cos(x)

'' Cosine of the angle x: 0 to 360 degrees == $0000 to $2000,
''   with result renormalized to $1_0000.

  return sin(x + $800)
}

'' from PhiPi and Chip
PUB SIN_ROM(x) : value | t

'' Sine of the angle x: 0 to 360 degrees == $0000 to $2000,
''   with result renormalized to $1_0000.

  if (x & $800)
    t := -x & $fff                                      't ranges from $800 to $001
  else
    t := x & $7ff                                       't ranges from $000 to $7FF
  value := word[$e000][t] + ((sin_corr[t >> 5] >> (t & $1f)) & 1)
  if (x & $1000)
    value := -value

PUB QLn(X) : Y | T
''
'' base 2 log
''   input and output is Qs15_16 format
''
  y := $a65af
  if x < $00008000
    x <<= 16
    y -= $b1721
  if x < $00800000
    x <<= 8
    y -= $58b91
  if x < $08000000
    x <<= 4
    y -= $2c5c8
  if x < $20000000
    x <<= 2
    y -= $162e4
  if x < $40000000
    x <<= 1
    y -= $0b172
  t := x + (x>>1)
  if (t & $80000000) == 0
    x :=t
    y -= $067cd
  t := x + (x>>2)
  if (t & $80000000) == 0
    x := t
    y -= $03920
  t := x + (x>>3)
  if (t & $80000000) == 0
    x := t
    y -= $01e27
  t := x + (x>>4)
  if (t & $80000000) == 0
    x := t
    y -= $00f85
  t := x + (x>>5)
  if (t & $80000000) == 0
    x := t
    y -= $007e1
  t := x + (x>>6)
  if (t & $80000000) == 0
    x := t
    y -= $003f8
  t := x + (x>>7)
  if (t & $80000000) == 0
    x := t
    y -= $001fe
  x := $80000000 - x
  y -= x>>15

DAT
sin_corr      long      $00000000,$00000000,$00208010,$30002008,$4001c000,$00401040,$a0420004,$24040a80
              long      $0e042110,$21038000,$00084922,$30c4094a,$88600fc0,$4a150a48,$0000e312,$5529331c
              long      $07c31129,$aa92461f,$c07866d2,$4aa96cc3,$8e000732,$73256d49,$5ad9c1f0,$9ffe3369
              long      $f32d55b3,$7b5b3c00,$671ff1d9,$fff3b5ad,$3db6bdb9,$dbeb6780,$55b3c01e,$7dcff9db
              long      $ef81e6d5,$bffddbfe,$ffeedfdb,$ffddebfe,$ffb6fb6f,$feedf6df,$ff77ffdf,$ffb7bdbf
              long      $23ff77df,$c1f6fedf,$bfdffff7,$ffffffdf,$defdedff,$ffef7feb,$ffdfff7f,$ffffdeff
              long      $ffdfffff,$fffeffff,$7fffffef,$ffffffff,$ffefefff,$ffffffff,$fffffeff,$fffff7f7
              long      $ffffffff,$ffffffff,$fffff7ff,$bfffffff,$ffffffff,$ffffffff,$ffffffff,$ffffffff,1 'Nothing to see here, Folks.
{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}
