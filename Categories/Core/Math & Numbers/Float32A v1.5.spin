{{
─────────────────────────────────────────────────
File: Float32A.spin
Version: 1.5
Copyright (c) 2009 Parallax, Inc.
See end of file for terms of use.

Author: Cam Thompson                                      
─────────────────────────────────────────────────
}}

{
HISTORY:
  This object is called by Float32Full and provides additional floating point
  routines and a user defined function processor. See Float32Full for further
  documentation.

  V1.5 - July 14, 2009
  • added comments
  V1.4 - September 25, 2007
  V1.3 - April 1, 2007
  • moved FMod routine from Float32 to Float32A
  V1.2 - March 26, 2007
  • corrected error in ATAN polynomial table
  V1.0 - May 17, 2006
  • original version

USAGE:
  • not called directly by user.
}

CON
  FAddCmd       = 1 << 16
  FSubCmd       = 2 << 16
  FMulCmd       = 3 << 16
  FDivCmd       = 4 << 16
  FFloatCmd     = 5 << 16 
  FTruncCmd     = 6 << 16
  FRoundCmd     = 7 << 16
  FSqrCmd       = 8 << 16
  FCmpCmd       = 9 << 16
  SinCmd        = 10 << 16
  CosCmd        = 11 << 16
  TanCmd        = 12 << 16
  LogCmd        = 13 << 16
  Log10Cmd      = 14 << 16
  ExpCmd        = 15 << 16
  Exp10Cmd      = 16 << 16
  PowCmd        = 17 << 16
  FracCmd       = 18 << 16

  FModCmd       = 19 << 16  
  ASinCmd       = 20 << 16
  ACosCmd       = 21 << 16
  ATanCmd       = 22 << 16
  ATan2Cmd      = 23 << 16
  FloorCmd      = 24 << 16
  CeilCmd       = 25 << 16

  FFuncCmd      = $8000<<16
  LoadCmd       = $8000<<16
  SaveCmd       = $8001<<16
  FNegCmd       = $8002<<16
  FAbsCmd       = $8003<<16
  JmpCmd        = $8004<<16
  JmpEqCmd      = $8005<<16
  JmpNeCmd      = $8006<<16
  JmpLtCmd      = $8007<<16
  JmpLeCmd      = $8008<<16
  JmpGtCmd      = $8009<<16
  JmpGeCmd      = $800A<<16
  JmpNaNCmd     = $800B<<16

  SignFlag      = $1
  ZeroFlag      = $2
  NaNFlag       = $8
  
VAR

  long  cog
  
PUB start(pointer) : okay

'' start floating point engine in a new cog
'' returns cog number plus 1 (or 0 if no cog available)

  stop
  okay := cog := cognew(@getCommand, pointer) + 1


PUB stop

'' stop floating point engine and release the cog

  if cog
    cogstop(cog~ - 1)

DAT

'---------------------------
' Assembly language routines
'---------------------------
                        org

getCommand              rdlong  cmdPtr, par wz          ' wait for command
          if_z          jmp     #getCommand
                        
                        mov     t2, cmdPtr wc           ' load fnumA
                        rdlong  fnumA, t2
                        add     t2, #4
          if_c          jmp     #:cmdList               ' check for command list
          
                        rdlong  fnumB, t2               ' load fnumB
                        mov     t1, cmdPtr              ' execute command 
                        call    #doCmd                  
                        jmp     #endCommand             ' return result

:cmdList                mov     cmdOffset, cmdPtr       ' get runtime offset
                        sub     cmdOffset, fnumA
                        and     cmdOffset, Mask16
                        add     cmdPtr, #4
                        mov     fnumA, #0               ' set fnumA to zero

:nextCmd                rdlong  t1, cmdPtr wz           ' get next command in list
          if_z          jmp     #endCommand             ' if zero, then done
                        add     cmdPtr, #4
                        mov     t1, t1 wc               ' if bit 31 set, function commands
          if_c          jmp     #:funcCmd
                        test    t1, Mask16 wz           ' check source for fnumB argument
          if_z          rdlong  fnumB, cmdPtr           ' load immediate
          if_z          add     cmdPtr, #4
          if_nz         add     t1, cmdOffset           ' load variable
          if_nz         rdlong  fnumB, t1
                        call    #doCmd                  ' execute command
                        jmp     #:nextCmd               ' get next command  

:funcCmd                add     t1, cmdOffset           ' get jump location
                        cmp     status, #0 wz, wc       ' check last compare status
                        mov     t2, t1                  ' jump to conditional
                        shr     t2, #15
                        and     t2, #$1F             
                        add     t2, #:jmpTable
                        jmp     t2

:jmpTable               rdlong  fnumA, t1               ' load fnumA
                        jmp     #:nextCmd
                        wrlong  fnumA, t1               ' save fnumA
                        jmp     #:nextCmd
                        xor     fnumA, Bit31            ' negate fnumA
                        jmp     #:nextCmd
                        andn    fnumA, Bit31            ' |fnumA|
                        jmp     #:nextCmd
                        mov     cmdPtr, t1              ' Jmp
                        jmp     #:nextCmd
          if_z          mov     cmdPtr, t1              ' JmpEQ
                        jmp     #:nextCmd
          if_nz         mov     cmdPtr, t1              ' JmpNE
                        jmp     #:nextCmd
          if_c          mov     cmdPtr, t1              ' JmpLT
                        jmp     #:nextCmd
          if_c_or_z     mov     cmdPtr, t1              ' JmpLE
                        jmp     #:nextCmd
          if_nc_and_nz  mov     cmdPtr, t1              ' JmpGT
                        jmp     #:nextCmd
          if_nc         mov     cmdPtr, t1              ' JmpGE
                        jmp     #:nextCmd
                        call    #_Unpack                ' JmpNaN
          if_c          mov     cmdPtr, t1
                        jmp     #:nextCmd

endCommand              mov     t1, par                 ' return result
                        add     t1, #4
                        wrlong  fnumA, t1
                        wrlong  Zero,par                ' clear command status
                        jmp     #getCommand             ' wait for next command

'------------------------------------------------------------------------------

doCmd                   mov     t2, t1                  ' get command
                        shr     t2, #16
                        cmp     t2, #FCmpCmd>>16 wz     ' check for FCmp
          if_z          jmp     #:cmdTable
                        cmp     t2, #FracCmd>>16 wc,wz  ' pass low commands to Float32
          if_c_or_z     jmp     #:cmdTable+2

                        sub     t2, #FracCmd>>16
                        cmp     t2, #((CeilCmd-FracCmd)>>16)+1 wc
          if_nc         jmp     #:exitNaN 
                        shl     t2, #1
                        add     t2, #:cmdTable+2 
                        jmp     t2                      ' jump to command

:cmdTable               call    #_FCmp                  ' command dispatch table
                        jmp     #doCmd_ret
                        call    #sendCmd
                        jmp     #doCmd_ret
                        call    #_FMod
                        jmp     #doCmd_ret
                        call    #_ASin
                        jmp     #doCmd_ret
                        call    #_ACos
                        jmp     #doCmd_ret
                        call    #_ATan
                        jmp     #doCmd_ret
                        call    #_ATan2
                        jmp     #doCmd_ret
                        call    #_Floor
                        jmp     #doCmd_ret
                        call    #_Ceil
                        jmp     #doCmd_ret
                        
:exitNaN                mov     fnumA, Nan              ' unknown command
:cmdTableEnd            
doCmd_ret               ret

'------------------------------------------------------------------------------
' _FMod fnumA = fnumA mod fnumB
'------------------------------------------------------------------------------

_FMod                   mov     t4, fnumA               ' save fnumA
                        mov     t5, fnumB               ' save fnumB
                        call    #_FDiv                  ' a - float(fix(a/b)) * b
                        call    #_FTrunc
                        call    #_FFloat
                        mov     fnumB, t5
                        call    #_FMul
                        or      fnumA, Bit31
                        mov     fnumB, t4
                        andn    fnumB, Bit31
                        call    #_FAdd
                        test    t4, Bit31 wz            ' if a < 0, set sign
          if_nz         or      fnumA, Bit31
_FMod_ret               ret

'------------------------------------------------------------------------------
' _ASin   fnumA = asin(fnumA)
'------------------------------------------------------------------------------

_ASin                   mov     t7, fnumA               ' save sign
                        andn    fnumA, Bit31            ' get absolute value
                        cmps    fnumA, One wc, wz       ' must be <= 1.0
          if_nc_and_nz  mov     fnumA, NaN
          if_nc_and_nz  jmp     _Asin_ret
          
                        mov     t4, fnumA               ' save x value
                        mov     t3, #ASinTable          ' result = Taylor series     
                        call    #poly

                        call    #_FAddI                 ' result = result + pi/2
pi2                     long    pi / 2.0
                        mov     t6, fnumA
                       
                        mov     fnumA, t4               ' calculate sqrt(1-x) 
                        xor     fnumA, Bit31 
                        call    #_FAddI
                        long    1.0
                        call    #_FSqr

                        mov     fnumB, t6               ' result = result * sqrt(1-x)   
                        call    #_FMul
                        xor     fnumA, Bit31            ' result = pi/2 - result
                        call    #_FAddI
                        long    pi / 2.0
                        test    t7, Bit31 wz            ' if sign, result = -result
          if_nz         xor     fnumA, Bit31
                        
_ASin_ret               ret

'------------------------------------------------------------------------------
' _ACos   fnumA = acos(fnumA)
'------------------------------------------------------------------------------

_ACos                   call    #_ASin                  ' result = pi/2 - asin(x)
                        xor     fnumA, Bit31
                        call    #_FAddI
                        long    pi / 2.0
_ACos_ret               ret

'------------------------------------------------------------------------------
' _ATan   fnumA = atan(fnumA)
'------------------------------------------------------------------------------

_ATan                   mov     t7, fnumA               ' save sign
                        andn     fnumA, Bit31           ' get absolute value
                        call    #_FAddI                 ' x = (x-1) / (x+1)
                        long    1.0
                        mov     t6, fnumA
                        call    #_FSubI
                        long    2.0
                        mov     fnumB, t6
                        call    #_FDiv        
                        mov     t6, fnumA
                        
                        mov     fnumB, fnumA            ' x2 = x ** 2
                        call    #_FMul
                        mov     t4, fnumA

                        mov     t3, #ATanTable          ' result = Taylor series
                        call    #poly      
                        mov     fnumB, t6               ' result = result * x + (pi / 4)
                        call    #_FMul
                        call    #_FAddI
                        long    pi / 4.0
                        test    t7, Bit31 wz            ' if sign, result = -result
          if_nz         xor     fnumA, Bit31
_ATan_ret               ret

'------------------------------------------------------------------------------
' _ATan2   fnumA = atan(fnumA / fnumB)
'------------------------------------------------------------------------------

_ATan2                  mov     t8, fnumA wc            ' bit 31 = sign fnumA
                        and     t8, Bit31               
                        test    fnumB, Bit31 wz         ' bit 30 = sign fnumB
          if_nz         or      t8, Bit30
                        andn    fnumA, Bit31 wz         ' get |fnumA|, check for zero
          if_z          jmp     #:exit2                 ' if 0 / n, then +0 or -0
                        andn    fnumB, Bit31 wz         ' get |fnumB|, check for zero
          if_z          mov     fnumA, pi2              ' if n / 0, then pi/2 or -pi/2
          if_z          jmp     #:exit2                 ' x = fnumA / fnumB
                        call    #_FDiv

                        call    #_ATan                  ' x = atan(a)
                        test    t8, Bit30 wz            ' check signs
          if_z          jmp     #:exit2                 ' if +/+ or +/-, then result = +x or -x
          
                        test    t8, Bit31 wz
          if_nz         jmp     #:exit1
          
                        xor     fnumA, Bit31            ' if +/-, then result = pi - x 
                        call    #_FAddI
                        long    pi
                        jmp     #_ATan2_ret                                          

:exit1                  call    #_FSubI                 ' if -/-, then result = x - pi 
                        long    pi
                        jmp     #_ATan2_ret
                            
:exit2                  test    t8, Bit31 wz            ' if numerator < 0, then negate
          if_nz         xor     fnumA, Bit31
_ATan2_ret              ret

'------------------------------------------------------------------------------
' _Floor fnumA = floor(fnumA)
' _Ceil fnumA = ceil(fnumA)
'------------------------------------------------------------------------------

_Ceil                   mov     t6, #1                  ' set adjustment value
                        jmp     #floor2
                        
_Floor                  neg     t6, #1                  ' set adjustment value

floor2                  call    #_Unpack                ' unpack variable
          if_c          jmp     #_Floor_ret             ' check for NaN
                        cmps     expA, #23 wc, wz       ' check for no fraction
          if_nc         jmp     #_Floor_ret              

                        mov     t4, fnumA               ' get integer value 
                        call    #_FTrunc
                        mov     t5, fnumA
                        xor     fnumA, t6
                        test    fnumA, Bit31 wz
          if_nz         jmp     #:exit

                        mov     fnumA, t4               ' get fraction  
                        call    #_Frac

                        or      fnumA, fnumA wz
          if_nz         add     t5, t6                  ' if non-zero, then adjust

:exit                   mov     fnumA, t5               ' convert integer to float 
                        call    #_FFloat                
_Ceil_ret
_Floor_ret              ret

'------------------------------------------------------------------------------
' linkage to Float32 routines
'------------------------------------------------------------------------------

_FSqr                   mov     t2, #FSqrCmd>>16
                        jmp     #send
_Frac                   mov     t2, #FracCmd>>16

send                    call    #sendCmd              
_FSqr_ret
_Frac_ret               ret

'------------------------------------------------------------------------------
' input:   t2           command
'          fnumA        32-bit floating point value
'          fnumB        32-bit floating point value 
' output:  fnumA        32-bit floating point result
'------------------------------------------------------------------------------

sendCmd                 shl     t2, #16                 ' send command to Float32  
                        mov     t1, par                 ' get pointer to command block
                        add     t1, #8
                        andn    t2, Mask16
                        or      t2, t1

                        wrlong  fnumA, t1               ' write fnumA argument
                        add     t1, #4
                        wrlong  fnumB, t1               ' write fnumB argument
                        add     t1, #4
                        wrlong  t2, t1                  ' write command to Float32

:wait                   rdlong  t2, t1 wz               ' wait until command is done
          if_nz         jmp     #:wait

                        add     t1, #4                  ' read result, store in fnumA
                        rdlong  fnumA, t1
sendCmd_ret             ret

'------------------------------------------------------------------------------
' _FAdd    fnumA = fnumA + fNumB
' _FAddI   fnumA = fnumA + {Float immediate}
' _FSub    fnumA = fnumA - fNumB
' _FSubI   fnumA = fnumA - {Float immediate}
'------------------------------------------------------------------------------

_FSubI                  movs    :getB, _FSubI_ret       ' get immediate value
                        add     _FSubI_ret, #1
:getB                   mov     fnumB, 0

_FSub                   xor     fnumB, Bit31            ' negate B
                        jmp     #_FAdd                  ' add values                                               

_FAddI                  movs    :getB, _FAddI_ret       ' get immediate value
                        add     _FAddI_ret, #1
:getB                   mov     fnumB, 0

_FAdd                   call    #_Unpack2               ' unpack two variables                    
          if_c_or_z     jmp     #_FAdd_ret              ' check for NaN or B = 0

                        test    flagA, #SignFlag wz     ' negate A mantissa if negative
          if_nz         neg     manA, manA
                        test    flagB, #SignFlag wz     ' negate B mantissa if negative
          if_nz         neg     manB, manB

                        mov     t1, expA                ' align mantissas
                        sub     t1, expB
                        abs     t1, t1
                        max     t1, #31
                        cmps    expA, expB wz,wc
          if_nz_and_nc  sar     manB, t1
          if_nz_and_c   sar     manA, t1
          if_nz_and_c   mov     expA, expB        

                        add     manA, manB              ' add the two mantissas
                        cmps    manA, #0 wc, nr         ' set sign of result
          if_c          or      flagA, #SignFlag
          if_nc         andn    flagA, #SignFlag
                        abs     manA, manA              ' pack result and exit
                        call    #_Pack  
_FSubI_ret
_FSub_ret 
_FAddI_ret
_FAdd_ret               ret      

'------------------------------------------------------------------------------
' _FMul    fnumA = fnumA * fNumB
' _FMulI   fnumA = fnumA * {Float immediate}
'------------------------------------------------------------------------------

_FMulI                  movs    :getB, _FMulI_ret       ' get immediate value
                        add     _FMulI_ret, #1
:getB                   mov     fnumB, 0

_FMul                   call    #_Unpack2               ' unpack two variables
          if_c          jmp     #_FMul_ret              ' check for NaN

                        xor     flagA, flagB            ' get sign of result
                        add     expA, expB              ' add exponents
                        mov     t1, #0                  ' t2 = upper 32 bits of manB
                        mov     t2, #32                 ' loop counter for multiply
                        shr     manB, #1 wc             ' get initial multiplier bit 
                                    
:multiply if_c          add     t1, manA wc             ' 32x32 bit multiply
                        rcr     t1, #1 wc
                        rcr     manB, #1 wc
                        djnz    t2, #:multiply

                        shl     t1, #3                  ' justify result and exit
                        mov     manA, t1                        
                        call    #_Pack 
_FMulI_ret
_FMul_ret               ret

'------------------------------------------------------------------------------
' _FDiv    fnumA = fnumA / fNumB
' _FDivI   fnumA = fnumA / {Float immediate}
'------------------------------------------------------------------------------

_FDivI                  movs    :getB, _FDivI_ret       ' get immediate value
                        add     _FDivI_ret, #1
:getB                   mov     fnumB, 0

_FDiv                   call    #_Unpack2               ' unpack two variables
          if_c_or_z     mov     fnumA, NaN              ' check for NaN or divide by 0
          if_c_or_z     jmp     #_FDiv_ret
        
                        xor     flagA, flagB            ' get sign of result
                        sub     expA, expB              ' subtract exponents
                        mov     t1, #0                  ' clear quotient
                        mov     t2, #30                 ' loop counter for divide

:divide                 shl     t1, #1                  ' divide the mantissas
                        cmps    manA, manB wz,wc
          if_z_or_nc    sub     manA, manB
          if_z_or_nc    add     t1, #1
                        shl     manA, #1
                        djnz    t2, #:divide

                        mov     manA, t1                ' get result and exit
                        call    #_Pack                        
_FDivI_ret
_FDiv_ret               ret
               
'------------------------------------------------------------------------------
' _FCmp    set Z and C flags for fnumA - fNumB
' _FCmpI   set Z and C flags for fnumA - {Float immediate}
'------------------------------------------------------------------------------

_FCmpI                  movs    :getB, _FCmpI_ret       ' get immediate value
                        add     _FCmpI_ret, #1
:getB                   mov     fnumB, 0

_FCmp                   mov     t1, fnumA               ' compare signs
                        xor     t1, fnumB
                        and     t1, Bit31 wz
          if_z          jmp     #:cmp1                  ' same, then compare magnitude
          
                        mov     t1, fnumA               ' check for +0 or -0 
                        or      t1, fnumB
                        andn    t1, Bit31 wz,wc         
          if_z          jmp     #:exit
                    
                        test    fnumA, Bit31 wc         ' compare signs
                        jmp     #:exit

:cmp1                   test    fnumA, Bit31 wz         ' check signs
          if_nz         jmp     #:cmp2
                        cmp     fnumA, fnumB wz,wc
                        jmp     #:exit

:cmp2                   cmp     fnumB, fnumA wz,wc      ' reverse test if negative

:exit                   mov     status, #1              ' if fnumA > fnumB, t1 = 1
          if_c          neg     status, status          ' if fnumA < fnumB, t1 = -1
          if_z          mov     status, #0              ' if fnumA = fnumB, t1 = 0
_FCmpI_ret
_FCmp_ret               ret

'------------------------------------------------------------------------------
' _FFloat   fnumA = float(fnumA)
'------------------------------------------------------------------------------
         
_FFloat                 mov     flagA, fnumA            ' get integer value
                        mov     fnumA, #0               ' set initial result to zero
                        abs     manA, flagA wz          ' get absolute value of integer
          if_z          jmp     #_FFloat_ret            ' if zero, exit
                        shr     flagA, #31              ' set sign flag
                        mov     expA, #31               ' set initial value for exponent
:normalize              shl     manA, #1 wc             ' normalize the mantissa 
          if_nc         sub     expA, #1                ' adjust exponent
          if_nc         jmp     #:normalize
                        rcr     manA, #1                ' justify mantissa
                        shr     manA, #2
                        call    #_Pack                  ' pack and exit
_FFloat_ret             ret

'------------------------------------------------------------------------------
' _FTrunc  fnumA = fix(fnumA)
' _FRound  fnumA = fix(round(fnumA))
'------------------------------------------------------------------------------

_FTrunc                 mov     t1, #0                  ' set for no rounding
                        jmp     #fix

_FRound                 mov     t1, #1                  ' set for rounding

fix                     call    #_Unpack                ' unpack floating point value
          if_c          jmp     #_FRound_ret            ' check for NaN
                        shl     manA, #2                ' left justify mantissa 
                        mov     fnumA, #0               ' initialize result to zero
                        neg     expA, expA              ' adjust for exponent value
                        add     expA, #30 wz
                        cmps    expA, #32 wc
          if_nc_or_z    jmp     #_FRound_ret
                        shr     manA, expA
                                                       
                        add     manA, t1                ' round up 1/2 lsb   
                        shr     manA, #1
                        
                        test    flagA, #signFlag wz     ' check sign and exit
                        sumnz   fnumA, manA
_FTrunc_ret
_FRound_ret             ret

'------------------------------------------------------------------------------
' input:   fnumA        32-bit floating point value
'          fnumB        32-bit floating point value 
' output:  flagA        fnumA flag bits (Nan, Infinity, Zero, Sign)
'          expA         fnumA exponent (no bias)
'          manA         fnumA mantissa (aligned to bit 29)
'          flagB        fnumB flag bits (Nan, Infinity, Zero, Sign)
'          expB         fnumB exponent (no bias)
'          manB         fnumB mantissa (aligned to bit 29)
'          C flag       set if fnumA or fnumB is NaN
'          Z flag       set if fnumB is zero
'------------------------------------------------------------------------------

_Unpack2                mov     t1, fnumA               ' save A
                        mov     fnumA, fnumB            ' unpack B to A
                        call    #_Unpack
          if_c          jmp     #_Unpack2_ret           ' check for NaN

                        mov     fnumB, fnumA            ' save B variables
                        mov     flagB, flagA
                        mov     expB, expA
                        mov     manB, manA

                        mov     fnumA, t1               ' unpack A
                        call    #_Unpack
                        cmp     manB, #0 wz             ' set Z flag                      
_Unpack2_ret            ret

'------------------------------------------------------------------------------
' input:   fnumA        32-bit floating point value 
' output:  flagA        fnumA flag bits (Nan, Infinity, Zero, Sign)
'          expA         fnumA exponent (no bias)
'          manA         fnumA mantissa (aligned to bit 29)
'          C flag       set if fnumA is NaN
'          Z flag       set if fnumA is zero
'------------------------------------------------------------------------------

_Unpack                 mov     flagA, fnumA            ' get sign
                        shr     flagA, #31
                        mov     manA, fnumA             ' get mantissa
                        and     manA, Mask23
                        mov     expA, fnumA             ' get exponent
                        shl     expA, #1
                        shr     expA, #24 wz
          if_z          jmp     #:zeroSubnormal         ' check for zero or subnormal
                        cmp     expA, #255 wz           ' check if finite
          if_nz         jmp     #:finite
                        mov     fnumA, NaN              ' no, then return NaN
                        mov     flagA, #NaNFlag
                        jmp     #:exit2        

:zeroSubnormal          or      manA, expA wz,nr        ' check for zero
          if_nz         jmp     #:subnorm
                        or      flagA, #ZeroFlag        ' yes, then set zero flag
                        neg     expA, #150              ' set exponent and exit
                        jmp     #:exit2
                                 
:subnorm                shl     manA, #7                ' fix justification for subnormals  
:subnorm2               test    manA, Bit29 wz
          if_nz         jmp     #:exit1
                        shl     manA, #1
                        sub     expA, #1
                        jmp     #:subnorm2

:finite                 shl     manA, #6                ' justify mantissa to bit 29
                        or      manA, Bit29             ' add leading one bit
                        
:exit1                  sub     expA, #127              ' remove bias from exponent
:exit2                  test    flagA, #NaNFlag wc      ' set C flag
                        cmp     manA, #0 wz             ' set Z flag
_Unpack_ret             ret       

'------------------------------------------------------------------------------
' input:   flagA        fnumA flag bits (Nan, Infinity, Zero, Sign)
'          expA         fnumA exponent (no bias)
'          manA         fnumA mantissa (aligned to bit 29)
' output:  fnumA        32-bit floating point value
'------------------------------------------------------------------------------

_Pack                   cmp     manA, #0 wz             ' check for zero                                        
          if_z          mov     expA, #0
          if_z          jmp     #:exit1

:normalize              shl     manA, #1 wc             ' normalize the mantissa 
          if_nc         sub     expA, #1                ' adjust exponent
          if_nc         jmp     #:normalize
                      
                        add     expA, #2                ' adjust exponent
                        add     manA, #$100 wc          ' round up by 1/2 lsb
          if_c          add     expA, #1

                        add     expA, #127              ' add bias to exponent
                        mins    expA, Minus23
                        maxs    expA, #255
 
                        cmps    expA, #1 wc             ' check for subnormals
          if_nc         jmp     #:exit1

:subnormal              or      manA, #1                ' adjust mantissa
                        ror     manA, #1

                        neg     expA, expA
                        shr     manA, expA
                        mov     expA, #0                ' biased exponent = 0

:exit1                  mov     fnumA, manA             ' bits 22:0 mantissa
                        shr     fnumA, #9
                        movi    fnumA, expA             ' bits 23:30 exponent
                        shl     flagA, #31
                        or      fnumA, flagA            ' bit 31 sign            
_Pack_ret               ret

'------------------------------------------------------------------------------
' input:   t3           address of polynomial coefficient table
'          t4           X value
' output:  fnumA        result of nth order polynomial calculation
'------------------------------------------------------------------------------

poly                    mov     fnumA, #0               ' set initial result to 0
                        movs    :getCnt, t3             ' get coefficient count 
                        add     t3, #1
:getCnt                 mov     t5, 0                  
                        and     t5, #$FF wz             ' restrict table size
          if_z          jmp     poly_ret
                        jmp     #:poly3                 ' calculate polynominal value
                        
:poly2                  mov     fnumB, t4               ' result = result * X
                        call    #_FMul
                         
:poly3                  movs    :getCoeff, t3           ' result = result + coefficient[n]
                        add     t3, #1
:getCoeff               mov     fnumB, 0
                        call    #_FAdd
                        djnz    t5, #:poly2             ' repeat for all coefficients                        
poly_ret                ret

'-------------------- constant values -----------------------------------------

Zero                    long    0                       ' constants
One                     long    $3F80_0000
NaN                     long    $7FFF_FFFF
Minus23                 long    -23
Mask16                  long    $0000_FFFF
Mask23                  long    $007F_FFFF
MaskExp                 long    $7F80_0000
Bit16                   long    $0001_0000
Bit29                   long    $2000_0000
Bit30                   long    $4000_0000
Bit31                   long    $8000_0000

ASinTable               long    6
                        long    -0.004337769
                        long    0.019349938
                        long    -0.044958886
                        long    0.08787631
                        long    -0.21451236
                        long    0

ATanTable               long    6
                        long    -0.0117212
                        long    0.05265332
                        long    -0.11643287
                        long    0.19354346
                        long    -0.33262348
                        long    0.99997723

'-------------------- local variables -----------------------------------------

t1                      res     1                       ' temporary values
t2                      res     1
t3                      res     1
t4                      res     1
t5                      res     1
t6                      res     1
t7                      res     1
t8                      res     1

cmdPtr                  res     1                       ' function code pointer
cmdOffset               res     1                       ' function code offset
status                  res     1                       ' last compare status

fnumA                   res     1                       ' floating point A value
flagA                   res     1
expA                    res     1
manA                    res     1

fnumB                   res     1                       ' floating point B value
flagB                   res     1
expB                    res     1
manB                    res     1

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}