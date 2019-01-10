{{
┌──────────────────────────────┬───────────────────┬─────────────────────┐
│     FPU32_FFT_Driver v3.0    │ Author: I.Kövesdi │ Rel.:  30 Dec 2011  │
├──────────────────────────────┴───────────────────┴─────────────────────┤
│                    Copyright (c) 2011 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This is an FFT driver object for the uM-FPU v3.1 coprocessor using    │
│ 2-wire SPI protocol for communication with the Propeller.              │                          
│  The driver focuses on DFT with FFT. It inherits the the version number│
│ of the latest FPU32_SPI_Driver, from which it is expanded.             │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  The FPU provides the user a comprehensive set of IEE 754 32-bit float,│
│ 32-bit LONG, string, FFT and matrix operations. It also has two 12-bit │
│ ADCs, a programmable serial TTL interface and an NMEA parser. The FPU  │
│ contains Flash memory and EEPROM for storing user defined functions and│
│ data and 128 32-bit registers for float and LONG integer data.         │
│  Mobilizing the User Defined Function capabilities of the FPU, compact │
│ code and fast data processing speed can be achieved with low-cost and  │
│ low power consumption in your embedded application. See, for example,  │
│ the INS_Math_WGS84_Earth application in OBEX, where a fully-fledged INS│
│ algorithm is packed within a few hundred bytes of the FPU with faster  │
│ then 250 Hz 6DOF data integration rate.                                │ 
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  The data burst transfer rate is of this driver is about 200 Kbyte/sec.│ 
│  This driver does not use a separate driver for the SPI protocol. The  │
│ only necessary SPI functionalities are coded using PASM aLONG with some│
│ other useful procedures which are designed for the easy programming of │
│ the FPU.                                                               │
│  SPIN can generate for you the 32-bit FLOAT representation of a number │
│ during compile time. But, during run time, the responsibility is upon  │
│ to you to convert LONGs to FLOATs, or vice versa. You can use native   │
│ FPU code for that and there are some conversion utilities in the       │
│ driver, too. Check that and take care.                                 │
│  This FFT driver is a member of a family of drivers for the uM-FPU     │
│ v3.1 with 2-wire SPI connection. The family has been placed on OBEX:   │
│                                                                        │
│  FPU32_SPI     (Core driver of the FPU32 family)                       │
│  FPU32_ARITH   (Basic arithmetic operations)                           │
│  FPU32_MATRIX  (Basic and advanced matrix operations)                  │
│ *FPU32_FFT     (FFT with advanced options)                             │
│                                                                        │
│  The procedures and functions of these drivers can be cherry picked and│
│ used together to build application specific uM-FPU v3.1 drivers.       │
│  Other specialized drivers, as GPS, MEMS, IMU, MAGN, NAVIG, ADC, DSP,  │
│ ANN, STR are in preparation with similar cross-compatibility features  │
│ around the instruction set and with the user defined function ability  │
│ of the uM-FPU v3.1.                                                    │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘
}}


CON

'FFT parameters-----------------------------------------------------------
_MAX_FFT_SIZE    = 2048    'Complex points   
'_MAX_FFT_SIZE    = 1024    'Complex points    'For more HUB left
_MAX_BLOCK_SIZE  =   64    'Complex points

'Note: For real only data just define imaginary parts as zero
'      Real parts are at even indices of the input array
'      Imaginary parts are at odd indices of the input array
'      The "Longs_To_Complexes" procedure converts a long array to
'      complex array.

'Window types
'For continuous signals and not for transients 
_NOWINDOW        =  0        'No window function (Rectangular in Greek)
_HANNING         =  1        'Hanning window
_GAUSS           =  2        'Gaussian window
'For transient signals with duration within the time of data collection
_EXPONENTIAL     = 10        'Exponential window for S/N enhancement
_RESENHANCE      = 11        'Window for frequency resolution enhancement

'FFT output formats
_REAL_IMAG       = 0
_MAGN_PHASE      = 1
_PWR_DBPWR       = 2

'FFT Error response
_CONTINUE        = 0
_NOTIFY          = 1
_ABORT           = 2      

'FPU PASM driver commands-------------------------------------------------
#1,  _INIT, _RST, _CHECK, _WAIT                                   '1-4
#5,  _WRTBYTE, _WRTCMDBYTE, _WRTCMD2BYTES, _WRTCMD3BYTES          '5-8
#9,  _WRTCMD4BYTES, _WRTCMDREG, _WRTCMDRNREG                      '9-11
#12, _WRTCMDCNTREGS, _WRTCMDSTRING                                '12-13
#14, _RDBYTE, _RDREG, _RDREGS, _RDSTRING                          '14-17
'These are the enumerated PASM command No.s (_INIT=1, _RST=2,etc..)They
'should be in harmony with the Cmd_Table of the PASM program in the DAT
'section of this object

_MAXSTRL   = 16        'Max string length
_FTOAD     = 20_000    'FTOA delay max 250 us
  
'uM-FPU V3.1 opcodes and indexes------------------------------------------
_NOP       = $00       'No Operation
_SELECTA   = $01       'Select register A  
_SELECTX   = $02       'Select register X

_CLR       = $03       'Reg[nn] = 0
_CLRA      = $04       'Reg[A] = 0
_CLRX      = $05       'Reg[X] = 0, X = X + 1
_CLR0      = $06       'Reg[0] = 0

_COPY      = $07       'Reg[nn] = Reg[mm]
_COPYA     = $08       'Reg[nn] = Reg[A]
_COPYX     = $09       'Reg[nn] = Reg[X], X = X + 1
_LOAD      = $0A       'Reg[0] = Reg[nn]
_LOADA     = $0B       'Reg[0] = Reg[A]
_LOADX     = $0C       'Reg[0] = Reg[X], X = X + 1
_ALOADX    = $0D       'Reg[A] = Reg[X], X = X + 1
_XSAVE     = $0E       'Reg[X] = Reg[nn], X = X + 1
_XSAVEA    = $0F       'Reg[X] = Reg[A], X = X + 1
_COPY0     = $10       'Reg[nn] = Reg[0]
_COPYI     = $11       'Reg[nn] = LONG(unsigned bb)
_SWAP      = $12       'Swap Reg[nn] and Reg[mm]
_SWAPA     = $13       'Swap Reg[A] and Reg[nn]
  
_LEFT      = $14       'Left parenthesis
_RIGHT     = $15       'Right parenthesis
  
_FWRITE    = $16       'Write 32-bit float to Reg[nn]
_FWRITEA   = $17       'Write 32-bit float to Reg[A]
_FWRITEX   = $18       'Write 32-bit float to Reg[X], X = X + 1
_FWRITE0   = $19       'Write 32-bit float to Reg[0]

_FREAD     = $1A       'Read 32-bit float from Reg[nn]
_FREADA    = $1B       'Read 32-bit float from Reg[A]
_FREADX    = $1C       'Read 32-bit float from Reg[X], X = X + 1
_FREAD0    = $1D       'Read 32-bit float from Reg[0]

_ATOF      = $1E       'Convert ASCII string to float, store in Reg[0]
_FTOA      = $1F       'Convert float in Reg[A] to ASCII string.
  
_FSET      = $20       'Reg[A] = Reg[nn] 

_FADD      = $21       'Reg[A] = Reg[A] + Reg[nn]
_FSUB      = $22       'Reg[A] = Reg[A] - Reg[nn]
_FSUBR     = $23       'Reg[A] = Reg[nn] - Reg[A]
_FMUL      = $24       'Reg[A] = Reg[A] * Reg[nn]
_FDIV      = $25       'Reg[A] = Reg[A] / Reg[nn]
_FDIVR     = $26       'Reg[A] = Reg[nn] / Reg[A]
_FPOW      = $27       'Reg[A] = Reg[A] ** Reg[nn]
_FCMP      = $28       'FLOAT compare Reg[A] - Reg[nn]
  
_FSET0     = $29       'Reg[A] = Reg[0]
_FADD0     = $2A       'Reg[A] = Reg[A] + Reg[0]
_FSUB0     = $2B       'Reg[A] = Reg[A] - Reg[0]
_FSUBR0    = $2C       'Reg[A] = Reg[0] - Reg[A]
_FMUL0     = $2D       'Reg[A] = Reg[A] * Reg[0]
_FDIV0     = $2E       'Reg[A] = Reg[A] / Reg[0]
_FDIVR0    = $2F       'Reg[A] = Reg[0] / Reg[A]
_FPOW0     = $30       'Reg[A] = Reg[A] ** Reg[0]
_FCMP0     = $31       'FLOAT compare Reg[A] - Reg[0]  

_FSETI     = $32       'Reg[A] = float(bb)
_FADDI     = $33       'Reg[A] = Reg[A] + float(bb)
_FSUBI     = $34       'Reg[A] = Reg[A] - float(bb)
_FSUBRI    = $35       'Reg[A] = float(bb) - Reg[A]
_FMULI     = $36       'Reg[A] = Reg[A] * float(bb)
_FDIVI     = $37       'Reg[A] = Reg[A] / float(bb) 
_FDIVRI    = $38       'Reg[A] = float(bb) / Reg[A]
_FPOWI     = $39       'Reg[A] = Reg[A] ** bb
_FCMPI     = $3A       'FLOAT compare Reg[A] - float(bb)
  
_FSTATUS   = $3B       'FLOAT status of Reg[nn]
_FSTATUSA  = $3C       'FLOAT status of Reg[A]
_FCMP2     = $3D       'FLOAT compare Reg[nn] - Reg[mm]

_FNEG      = $3E       'Reg[A] = -Reg[A]
_FABS      = $3F       'Reg[A] = | Reg[A] |
_FINV      = $40       'Reg[A] = 1 / Reg[A]
_SQRT      = $41       'Reg[A] = sqrt(Reg[A])    
_ROOT      = $42       'Reg[A] = root(Reg[A], Reg[nn])
_LOG       = $43       'Reg[A] = log(Reg[A])
_LOG10     = $44       'Reg[A] = log10(Reg[A])
_EXP       = $45       'Reg[A] = exp(Reg[A])
_EXP10     = $46       'Reg[A] = exp10(Reg[A])
_SIN       = $47       'Reg[A] = sin(Reg[A])
_COS       = $48       'Reg[A] = cos(Reg[A])
_TAN       = $49       'Reg[A] = tan(Reg[A])
_ASIN      = $4A       'Reg[A] = asin(Reg[A])
_ACOS      = $4B       'Reg[A] = acos(Reg[A])
_ATAN      = $4C       'Reg[A] = atan(Reg[A])
_ATAN2     = $4D       'Reg[A] = atan2(Reg[A], Reg[nn])
_DEGREES   = $4E       'Reg[A] = degrees(Reg[A])
_RADIANS   = $4F       'Reg[A] = radians(Reg[A])
_FMOD      = $50       'Reg[A] = Reg[A] MOD Reg[nn]
_FLOOR     = $51       'Reg[A] = floor(Reg[A])
_CEIL      = $52       'Reg[A] = ceil(Reg[A])
_ROUND     = $53       'Reg[A] = round(Reg[A])
_FMIN      = $54       'Reg[A] = min(Reg[A], Reg[nn])
_FMAX      = $55       'Reg[A] = max(Reg[A], Reg[nn])
  
_FCNV      = $56       'Reg[A] = conversion(nn, Reg[A])
  _F_C       = 0       '├─>F to C
  _C_F       = 1       '├─>C to F
  _IN_MM     = 2       '├─>in to mm
  _MM_IN     = 3       '├─>mm to in
  _IN_CM     = 4       '├─>in to cm
  _CM_IN     = 5       '├─>cm to in
  _IN_M      = 6       '├─>in to m
  _M_IN      = 7       '├─>m to in
  _FT_M      = 8       '├─>ft to m
  _M_FT      = 9       '├─>m to ft
  _YD_M      = 10      '├─>yd to m
  _M_YD      = 11      '├─>m to yd
  _MI_KM     = 12      '├─>mi to km
  _KM_MI     = 13      '├─>km to mi
  _NMI_M     = 14      '├─>nmi to m
  _M_NMI     = 15      '├─>m to nmi
  _ACR_M2    = 16      '├─>acre to m2
  _M2_ACR    = 17      '├─>m2 to acre
  _OZ_G      = 18      '├─>oz to g
  _G_OZ      = 19      '├─>g to oz
  _LB_KG     = 20      '├─>lb to kg
  _KG_LB     = 21      '├─>kg to lb
  _USGAL_L   = 22      '├─>USgal to l
  _L_USGAL   = 23      '├─>l to USgal
  _UKGAL_L   = 24      '├─>UKgal to l
  _L_UKGAL   = 25      '├─>l to UKgal
  _USOZFL_ML = 26      '├─>USozfl to ml
  _ML_USOZFL = 27      '├─>ml to USozfl
  _UKOZFL_ML = 28      '├─>UKozfl to ml
  _ML_UKOZFL = 29      '├─>ml to UKozfl
  _CAL_J     = 30      '├─>cal to J
  _J_CAL     = 31      '├─>J to cal
  _HP_W      = 32      '├─>hp to W
  _W_HP      = 33      '├─>W to hp
  _ATM_KP    = 34      '├─>atm to kPa
  _KP_ATM    = 35      '├─>kPa to atm
  _MMHG_KP   = 36      '├─>mmHg to kPa
  _KP_MMHG   = 37      '├─>kPa to mmHg
  _DEG_RAD   = 38      '├─>degrees to radians
  _RAD_DEG   = 39      '└─>radians to degrees    

_FMAC      = $57       'Reg[A] = Reg[A] + (Reg[nn] * Reg[mm])
_FMSC      = $58       'Reg[A] = Reg[A] - (Reg[nn] * Reg[mm])

_LOADBYTE  = $59       'Reg[0] = float(signed bb)
_LOADUBYTE = $5A       'Reg[0] = float(unsigned byte)
_LOADWORD  = $5B       'Reg[0] = float(signed word)
_LOADUWORD = $5C       'Reg[0] = float(unsigned word)
  
_LOADE     = $5D       'Reg[0] = 2.7182818             
_LOADPI    = $5E       'Reg[0] = 3.1415927
  
_LOADCON   = $5F       'Reg[0] = float constant(nn)                        
  _ONE      = 0        '├─>1e0 one
  _1E1      = 1        '├─>1e1
  _1E2      = 2        '├─>1e2
  _KILO     = 3        '├─>1e3 kilo
  _1E4      = 4        '├─>1e4
  _1E5      = 5        '├─>1e5
  _MEGA     = 6        '├─>1e6 mega
  _1E7      = 7        '├─>1e7
  _1E8      = 8        '├─>1e8
  _GIGA     = 9        '├─>1e9 giga
  _MAXFLOAT = 10       '├─>3.4028235e38   :Largest 32-bit f.p. value                                   
  _MINFLOAT = 11       '├─>1.4012985e-45  :Smallest nonzero 32-bit f.p.
  _C        = 12       '├─>299792458.0    :Speed of light in vaccum[m/s]
  _GRAVCON  = 13       '├─>6.6742e-11     :Const. of grav. [m3/(kg*s2)]
  _MEANG    = 14       '├─>9.80665        :Mean accel. of gravity [m/s2]
  _EMASS    = 15       '├─>9.1093826e-31  :Electron mass [kg]
  _PMASS    = 16       '├─>1.67262171e-27 :Proton mass [kg]
  _NMASS    = 17       '├─>1.67492728e-27 :Neutron mass [kg]
  _A        = 18       '├─>6.0221415e23   :Avogadro constant [1/mol]
  _ELCHRG   = 19       '├─>1.60217653e-19 :Elementary charge [coulomb]
  _STDATM   = 20       '└─>101.325        :Standard atmosphere [kPa]

_FLOAT     = $60       'Reg[A] = float(Reg[A])     :LONG to float  
_FIX       = $61       'Reg[A] = fix(Reg[A])       :float to LONG
_FIXR      = $62       'Reg[A] = fix(round(Reg[A])):rounded float to lng
_FRAC      = $63       'Reg[A] = fraction(Reg[A])  
_FSPLIT    = $64       'Reg[A] = int(Reg[A]), Reg[0] = frac(Reg[A])
  
_SELECTMA  = $65       'Select matrix A
_SELECTMB  = $66       'Select matrix B
_SELECTMC  = $67       'Select matrix C
_LOADMA    = $68       'Reg[0] = matrix A[bb, bb]
_LOADMB    = $69       'Reg[0] = matrix B[bb, bb]
_LOADMC    = $6A       'Reg[0] = matrix C[bb, bb]
_SAVEMA    = $6B       'Matrix A[bb, bb] = Reg[0] Please correct TFM!                     
_SAVEMB    = $6C       'Matrix B[bb, bb] = Reg[0] Please correct TFM!                         
_SAVEMC    = $6D       'Matrix C[bb, bb] = Reg[0] Please correct TFM!

_MOP       = $6E       'Matrix operation
  '-------------------------For each r(ow), c(olumn)--------------------
  _SCALAR_SET  = 0     '├─>MA[r, c] = Reg[0]
  _SCALAR_ADD  = 1     '├─>MA[r, c] = MA[r, c] + Reg[0]
  _SCALAR_SUB  = 2     '├─>MA[r, c] = MA[r, c] - Reg[0]
  _SCALAR_SUBR = 3     '├─>MA[r, c] = Reg[0] - MA[r, c] 
  _SCALAR_MUL  = 4     '├─>MA[r, c] = MA[r, c] * Reg[0]
  _SCALAR_DIV  = 5     '├─>MA[r, c] = MA[r, c] / Reg[0]
  _SCALAR_DIVR = 6     '├─>MA[r, c] = Reg[0] / MA[r, c]
  _SCALAR_POW  = 7     '├─>MA[r, c] = MA[r, c] ** Reg[0]
  _EWISE_SET   = 8     '├─>MA[r, c] = MB[r, c]
  _EWISE_ADD   = 9     '├─>MA[r, c] = MA[r, c] + MB[r, c]
  _EWISE_SUB   = 10    '├─>MA[r, c] = MA[r, c] - MB[r, c]                                 
  _EWISE_SUBR  = 11    '├─>MA[r, c] = MB[r, c] - MA[r, c]
  _EWISE_MUL   = 12    '├─>MA[r, c] = MA[r, c] * MB[r, c]
  _EWISE_DIV   = 13    '├─>MA[r, c] = MA[r, c] / MB[r, c]
  _EWISE_DIVR  = 14    '├─>MA[r, c] = MB[r, c] / MA[r, c]
  _EWISE_POW   = 15    '├─>MA[r, c] = MA[r, c] ** MB[r, c]
  '---------------------│-----------------------------------------------
  _MX_MULTIPLY = 16    '├─>MA = MB * MC 
  _MX_IDENTITY = 17    '├─>MA = I = Identity matrix (Diag. of ones)
  _MX_DIAGONAL = 18    '├─>MA = Reg[0] * I
  _MX_TRANSPOSE= 19    '├─>MA = Transpose of MB
  '---------------------│-----------------------------------------------
  _MX_COUNT    = 20    '├─>Reg[0] = Number of elements in MA 
  _MX_SUM      = 21    '├─>Reg[0] = Sum of elements in MA
  _MX_AVE      = 22    '├─>Reg[0] = Average of elements in MA
  _MX_MIN      = 23    '├─>Reg[0] = Minimum of elements in MA 
  _MX_MAX      = 24    '├─>Reg[0] = Maximum of elements in MA
  '---------------------│------------------------------------------------
  _MX_COPYAB   = 25    '├─>MB = MA 
  _MX_COPYAC   = 26    '├─>MC = MA
  _MX_COPYBA   = 27    '├─>MA = MB 
  _MX_COPYBC   = 28    '├─>MC = MB
  _MX_COPYCA   = 29    '├─>MA = MC 
  _MX_COPYCB   = 30    '├─>MB = MC
  '---------------------│-----------------------------------------------
  _MX_DETERM   = 31    '├─>Reg[0]=Determinant of MA (for 2x2 OR 3x3 MA)
  _MX_INVERSE  = 32    '├─>MA = Inverse of MB (for 2x2 OR 3x3 MB)
  '---------------------│-----------------------------------------------
  _MX_ILOADRA  = 33    '├─>Indexed Load Registers to MA
  _MX_ILOADRB  = 34    '├─>Indexed Load Registers to MB
  _MX_ILOADRC  = 35    '├─>Indexed Load Registers to MC
  _MX_ILOADBA  = 36    '├─>Indexed Load MB to MA
  _MX_ILOADCA  = 37    '├─>Indexed Load MC to MA 
  _MX_ISAVEAR  = 38    '├─>Indexed Load MA to Registers
  _MX_ISAVEAB  = 39    '├─>Indexed Load MA to MB
  _MX_ISAVEAC  = 40    '└─>Indexed Load MA to MC

_FFT       = $6F       'FFT operation
  _FIRST_STAGE = 0     '├─>Mode : First stage 
  _NEXT_STAGE  = 1     '├─>Mode : Next stage 
  _NEXT_LEVEL  = 2     '├─>Mode : Next level
  _NEXT_BLOCK  = 3     '├─>Mode : Next block
  '---------------------│-----------------------------------------------
  _BIT_REVERSE = 4     '├─>Mode : Pre-processing bit reverse sort 
  _PRE_ADJUST  = 8     '├─>Mode : Pre-processing for inverse FFT
  _POST_ADJUST = 16    '└─>Mode : Post-processing for inverse FFT
  
_WRBLK     = $70       'Write register block
_RDBLK     = $71       'Read register block

_LOADIND   = $7A       'Reg[0] = Reg[Reg[nn]]
_SAVEIND   = $7B       'Reg[Reg[nn]] = Reg[A]
_INDA      = $7C       'Select A using Reg[nn]
_INDX      = $7D       'Select X using Reg[nn]

_FCALL     = $7E       'Call function in Flash memory
_EECALL    = $7F       'Call function in EEPROM memory
  
_RET       = $80       'Return from function
_BRA       = $81       'Unconditional branch
_BRACC     = $82       'Conditional branch
_JMP       = $83       'Unconditional jump
_JMPCC     = $84       'Conditional jump
_TABLE     = $85       'Table lookup
_FTABLE    = $86       'FLOATing point reverse table lookup
_LTABLE    = $87       'LONG integer reverse table lookup
_POLY      = $88       'Reg[A] = nth order polynomial
_GOTO      = $89       'Computed goto
_RETCC     = $8A       'Conditional return from function
 
_LWRITE    = $90       'Write 32-bit LONG integer to Reg[nn]
_LWRITEA   = $91       'Write 32-bit LONG integer to Reg[A]
_LWRITEX   = $92       'Write 32-bit LONG integer to Reg[X], X = X + 1
_LWRITE0   = $93       'Write 32-bit LONG integer to Reg[0]

_LREAD     = $94       'Read 32-bit LONG integer from Reg[nn] 
_LREADA    = $95       'Read 32-bit LONG integer from Reg[A]
_LREADX    = $96       'Read 32-bit LONG integer from Reg[X], X = X + 1   
_LREAD0    = $97       'Read 32-bit LONG integer from Reg[0]

_LREADBYTE = $98       'Read lower 8 bits of Reg[A]
_LREADWORD = $99       'Read lower 16 bits Reg[A]
  
_ATOL      = $9A       'Convert ASCII to LONG integer
_LTOA      = $9B       'Convert LONG integer to ASCII

_LSET      = $9C       'reg[A] = reg[nn]
_LADD      = $9D       'reg[A] = reg[A] + reg[nn]
_LSUB      = $9E       'reg[A] = reg[A] - reg[nn]
_LMUL      = $9F       'reg[A] = reg[A] * reg[nn]
_LDIV      = $A0       'reg[A] = reg[A] / reg[nn]
_LCMP      = $A1       'Signed LONG compare reg[A] - reg[nn]
_LUDIV     = $A2       'reg[A] = reg[A] / reg[nn]
_LUCMP     = $A3       'Unsigned LONG compare of reg[A] - reg[nn]
_LTST      = $A4       'LONG integer status of reg[A] AND reg[nn] 
_LSET0     = $A5       'reg[A] = reg[0]
_LADD0     = $A6       'reg[A] = reg[A] + reg[0]
_LSUB0     = $A7       'reg[A] = reg[A] - reg[0]
_LMUL0     = $A8       'reg[A] = reg[A] * reg[0]
_LDIV0     = $A9       'reg[A] = reg[A] / reg[0]
_LCMP0     = $AA       'Signed LONG compare reg[A] - reg[0]
_LUDIV0    = $AB       'reg[A] = reg[A] / reg[0]
_LUCMP0    = $AC       'Unsigned LONG compare reg[A] - reg[0]
_LTST0     = $AD       'LONG integer status of reg[A] AND reg[0] 
_LSETI     = $AE       'reg[A] = LONG(bb)
_LADDI     = $AF       'reg[A] = reg[A] + LONG(bb)
_LSUBI     = $B0       'reg[A] = reg[A] - LONG(bb)
_LMULI     = $B1       'Reg[A] = Reg[A] * LONG(bb)
_LDIVI     = $B2       'Reg[A] = Reg[A] / LONG(bb); Remainder in Reg0

_LCMPI     = $B3       'Signed LONG compare Reg[A] - LONG(bb)
_LUDIVI    = $B4       'Reg[A] = Reg[A] / unsigned LONG(bb)
_LUCMPI    = $B5       'Unsigned LONG compare Reg[A] - uLONG(bb)
_LTSTI     = $B6       'LONG integer status of Reg[A] AND uLONG(bb)
_LSTATUS   = $B7       'LONG integer status of Reg[nn]
_LSTATUSA  = $B8       'LONG integer status of Reg[A]
_LCMP2     = $B9       'Signed LONG compare Reg[nn] - Reg[mm]
_LUCMP2    = $BA       'Unsigned LONG compare Reg[nn] - Reg[mm]
  
_LNEG      = $BB       'Reg[A] = -Reg[A]
_LABS      = $BC       'Reg[A] = | Reg[A] |
_LINC      = $BD       'Reg[nn] = Reg[nn] + 1
_LDEC      = $BE       'Reg[nn] = Reg[nn] - 1
_LNOT      = $BF       'Reg[A] = NOT Reg[A]

_LAND      = $C0       'reg[A] = reg[A] AND reg[nn]
_LOR       = $C1       'reg[A] = reg[A] OR reg[nn]
_LXOR      = $C2       'reg[A] = reg[A] XOR reg[nn]
_LSHIFT    = $C3       'reg[A] = reg[A] shift reg[nn]
_LMIN      = $C4       'reg[A] = min(reg[A], reg[nn])
_LMAX      = $C5       'reg[A] = max(reg[A], reg[nn])
_LONGBYTE  = $C6       'reg[0] = LONG(signed byte bb)
_LONGUBYTE = $C7       'reg[0] = LONG(unsigned byte bb)
_LONGWORD  = $C8       'reg[0] = LONG(signed word wwww)
_LONGUWORD = $C9       'reg[0] = LONG(unsigned word wwww)
_SETSTATUS = $CD       'Set status byte

_SEROUT    = $CE       'Serial output
_SERIN     = $CF       'Serial Input

_SETOUT    = $D0       'Set OUT1 and OUT2 output pins
_ADCMODE   = $D1       'Set A/D trigger mode
_ADCTRIG   = $D2       'A/D manual trigger
_ADCSCALE  = $D3       'ADCscale[ch] = B
_ADCLONG   = $D4       'reg[0] = ADCvalue[ch]
_ADCLOAD   = $D5       'reg[0] = float(ADCvalue[ch]) * ADCscale[ch]
_ADCWAIT   = $D6       'wait for next A/D sample
_TIMESET   = $D7       'time = reg[0]
_TIMELONG  = $D8       'reg[0] = time (LONG)
_TICKLONG  = $D9       'reg[0] = ticks (LONG)
_EESAVE    = $DA       'EEPROM[nn] = reg[mm]
_EESAVEA   = $DB       'EEPROM[nn] = reg[A]
_EELOAD    = $DC       'reg[nn] = EEPROM[mm]
_EELOADA   = $DD       'reg[A] = EEPROM[nn]
_EEWRITE   = $DE       'Store bytes in EEPROM
_EXTSET    = $E0       'external input count = reg[0]
_EXTLONG   = $E1       'reg[0] = external input counter (LONG)
_EXTWAIT   = $E2       'wait for next external input
_STRSET    = $E3       'Copy string to string buffer
_STRSEL    = $E4       'Set selection point
_STRINS    = $E5       'Insert string at selection point
_STRCMP    = $E6       'Compare string with string buffer
_STRFIND   = $E7       'Find string and set selection point
_STRFCHR   = $E8       'Set field separators
_STRFIELD  = $E9       'Find field and set selection point
_STRTOF    = $EA       'Convert string selection to float
_STRTOL    = $EB       'Convert string selection to LONG
_READSEL   = $EC       'Read string selection
_STRBYTE   = $ED       'Insert 8-bit byte at selection point
_STRINC    = $EE       'increment selection point
_STRDEC    = $EF       'decrement selection point  
 
_SYNC      = $F0       'Get synchronization character 
  _SYNC_CHAR = $5C     '└─>Synchronization character(Decimal 92)
    
_READSTAT  = $F1       'Read status byte 
_READSTR   = $F2       'Read string from string buffer    
_VERSION   = $F3       'Copy version string to string buffer     
_CHECKSUM  = $F6       'Calculate checksum for uM-FPU   

_READVAR   = $FC       'Read internal variable, store in Reg[0]
  _A_REG    = 0        '├─>Reg[0] = A register
  _X_REG    = 1        '├─>Reg[0] = X register
  _MA_REG   = 2        '├─>Reg[0] = MA register
  _MA_ROWS  = 3        '├─>Reg[0] = MA rows
  _MA_COLS  = 4        '├─>Reg[0] = MA columns
  _MB_REG   = 5        '├─>Reg[0] = MB register
  _MB_ROWS  = 6        '├─>Reg[0] = MB rows
  _MB_COLS  = 7        '├─>Reg[0] = MB columns
  _MC_REG   = 8        '├─>Reg[0] = MC register
  _MC_ROWS  = 9        '├─>Reg[0] = MC rows
  _MC_COLS  = 10       '├─>Reg[0] = MC columns
  _INTMODE  = 11       '├─>Reg[0] = Internal mode word
  _STATBYTE = 12       '├─>Reg[0] = Last status byte
  _TICKS    = 13       '├─>Reg[0] = Clock ticks per milisecond
  _STRL     = 14       '├─>Reg[0] = Current length of string buffer
  _STR_SPTR = 15       '├─>Reg[0] = String selection starting point
  _STR_SLEN = 16       '├─>Reg[0] = String selection length
  _STR_SASC = 17       '├─>Reg[0] = ASCII char at string selection point
  _INSTBUF  = 18       '└─>Reg[0] = Number of bytes in instr. buffer

_RESET     = $FF       'NOP (but 9 consecutive $FF bytes cause a reset
                       'in SPI protocol)

_ZERO_BIT  = %0000_0001     'Zero bit mask of the status register  
_SIGN_BIT  = %0000_0010     'Sign bit mask of the status register
_NAN_BIT   = %0000_0100     'Not-a-Number bit mask of the status reg.
_INF_BIT   = %0000_1000     'Infinity bit mask of the status register                         


VAR

LONG   ownCOG, command, par1, par2, par3, par4, par5

BYTE   str[_MAXSTRL]   'The holder of strings. StartCOG passes its
                       'address to the PASM code when it calls
                       'the _INIT procedure

'FFT variables
LONG dataSize, dA_
'Note: dataSize can be any number from 2..._MAX_FFT_SIZE

LONG fftSize, fftSizet2, fftSized2, fftSizem1, log2fftSize
LONG maxStages, maxBlockStages                              


DAT '------------------------Start of SPIN code---------------------------


PUB Start_Driver(dio_Pin, clk_Pin, addrCogID_) : oKay
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ Start_Driver │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: -Starts a COG to run uMFPU_Driver
''             -Initializes driver            
'' Parameters: -Propeller pin to the DIO line of the FPU
''             -Propeller pin to the CLK line of the FPU
''             -HUB address of COG ID
''     Result: HUB/oKay boolean
''+Reads/Uses: /_INIT
''    +Writes: command, ownCOG, par1, par2, par3 
''      Calls: COG/#Init
''       Note: The #Init procedure makes a simple check of the FPU. 
'-------------------------------------------------------------------------
Stop_Driver                          'Stop previous copy of this driver,
                                     'if any
command~
ownCOG := COGNEW(@uMFPU, @command)   'Try to start a COG with a PASM
                                     'program that waits for a
                                     'nonzero "command"
                                     'if sucesfull then
                                     '  ownCOG = actual COG No.
                                     'else
                                     '  ownCOG = -1

LONG[addrCogID_] := ownCOG++         'Use, then increment ownCOG
                                       
IF (ownCOG)                          'if ownCOG is not zero then
                                     '  Own COG has been started
  par1 := dio_Pin                    '  Initialize PASM Driver with the 
  par2 := clk_Pin                    '  DIO and CLK pins and with a
  par3 := @str                       '  pointer to HUB/str chr array
  command := _INIT                   

  REPEAT WHILE command       'Wait for _INIT command to be sent and
                             'finished. This command performs a simple
                             'hardware check of the FPU, too  
  okay := par1               'Signal back FPU state (from par1)
      
ELSE                         'Else Own COG has not been started

  okay := FALSE              'Signal back error
 
RETURN okay                  'if okay then Own COG was available and FPU
                             'seemed to work.
'---------------------------End of Star_tDriver---------------------------


PUB Stop_Driver                                          
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Stop_Driver │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Stops uMFPU_Driver PASM code by freeing a COG in which it
''             is running
'' Parameters: None
''     Result: None 
''+Reads/Uses: /ownCOG
''    +Writes: command, ownCOG
''      Calls: None
''       Note: Own COG (to stop) is identified via ownCOG global variable 
'-------------------------------------------------------------------------
command~                             'Clear "command" register
                                     'Here you can initiate a shut off
                                     'PASM routine if necessary 

IF (ownCOG)                          'if ownCOG is not zero then
                                     'it is running so we can Stop it
                                     
                                     'Actual COG ID is one less! 
  COGSTOP(ownCOG~ - 1)               'Stop Own COG, then clear ownCOG
'----------------------------End of Stop_Driver---------------------------


DAT 'Conversions


PUB L32_To_F32(l32)                             
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ L32_To_F32 │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a 32-bit LONG value to 32-bit FLOAT              
'' Parameters: 32-bit LONG value
''     Result: 32-bit FLOAT approximation of the LONG argument
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLong(_LWRITEA, l32)
WriteCmd(_FLOAT)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'----------------------------End of L32_To_F32----------------------------


PUB F32_To_L32(f32)                             
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ F32_To_L32 │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a 32-bi FLOAT value to 32-bit LONG                            
'' Parameters: 32-bit FLOAT
''     Result: 32-bit LONG approximation of the FLOAT
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLong(_FWRITEA, f32)
WriteCmd(_FIXR)
Wait
WriteCmd(_LREADA)
RESULT := ReadReg
'----------------------------End of F32_To_L32----------------------------


PUB F32_To_STR(f32, format)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ F32_To_STR │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a 32-bit FLOAT into a string 
'' Parameters: -32-bit FLOAT value
''             -Format code in FPU convention
''     Result: Pointer to string in HUB
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:127
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLong(_FWRITEA, f32) 
RESULT := ReadRaFLOATAsStr(format) 
'------------------------------End of F32_To_STR--------------------------


PUB L32_To_STR(l32, format)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ L32_To_STR │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a 32-bit LONG into a string 
'' Parameters: -32-bit LONG value
''             -Format code in FPU convention
''     Result: Pointer to string in HUB
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:127
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLong(_LWRITEA, l32) 
RESULT := ReadRaLONGAsStr(format) 
'-----------------------------End of L32_To_STR---------------------------


PUB STR_To_F32(strPtr_)
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ STR_To_F32 │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a string into a 32-bit FLOAT
'' Parameters: Pointer to string
''     Result: 32-bit FLOAT
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:0
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 0)
WriteCmdStr(_ATOF, strPtr_) 
Wait
WriteCmd(_FREADA)
RESULT := ReadReg 
'-----------------------------End of STR_To_F32---------------------------


PUB STR_To_L32(strPtr_)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ STR_To_L32 │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a string into a 32-bit LONG 
'' Parameters: Pointer to string
''     Result: 32-bit LONG 
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:0
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 0)
WriteCmdStr(_ATOL, strPtr_) 
Wait
WriteCmd(_LREADA)
RESULT := ReadReg 
'-----------------------------End of STR_To_L32---------------------------


DAT '32-bit FLOAT operations


PUB F32_NEG(f32)                                                  
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_NEG │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Negates a 32-bit FLOAT value                           
'' Parameters: 32-bit FLOAT value
''     Result: Negated 32-bit FLOAT value
''+Reads/Uses: None
''    +Writes: None       
''      Calls: None
''       Note: No check for NaN argument 
'-------------------------------------------------------------------------
RESULT := f32 ^ $8000_0000                                 'Flip sign  bit 
'------------------------------End of F32_NEG-----------------------------


PUB F32_INV(f32)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_INV │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Takes reciprocal of a 32-bit FLOAT value                           
'' Parameters: Float Value
''     Result: 32-bit reciprocal of argument
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
''       Note: No check for zero or NaN argument 
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32)
WriteCmd(_FINV)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------End of F32_INV-----------------------------


PUB F32_ADD(f32_a, f32_b)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_ADD │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Adds two 32-bit FLOAT values                           
'' Parameters: Float values
''     Result: Sum of float values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: No checks for NaN arguments 
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_FADD, 126)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------END of F32_ADD-----------------------------


PUB F32_SUB(f32_a, f32_b)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_SUB │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Subtracts two float values                           
'' Parameters: Float values
''     Result: Difference between float values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: fA-fB, no checks for NaN arguments
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_FSUB, 126)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------End of F32_SUB-----------------------------


PUB F32_MUL(f32_a, f32_b)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_MUL │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies two float values                           
'' Parameters: Float values
''     Result: Multiplication result of float values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: No checks for NaN arguments
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_FMUL, 126)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------End of F32_MUL-----------------------------


PUB F32_DIV(f32_a, f32_b)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_DIV │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Divides two float values                              
'' Parameters: Float values
''     Result: Ratio of float values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: fA/fB, no checks for NaN arguments or for a zero fB
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_FDIV, 126)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------End of F32_DIV-----------------------------


DAT 'FFT data processing


PUB Longs_To_Complexes(dAddr_, dSize) | er, i, n
'-------------------------------------------------------------------------
'---------------------------┌────────────────────┐------------------------
'---------------------------│ Longs_To_Complexes │------------------------
'---------------------------└────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Creates a complex FLOAT array overwriting the input array
''             of LONGs. In the complex FLOAT array all imaginary parts
''             are zero                                     
'' Parameters: - HUB Address of LONG array
''             - Number of datapoints in LONG array (size of)
''     Result: None
''     Effect: Complex FLOAT array is written back into HUB 
''+Reads/Uses: CON/_MAX_FFT_SIZE 
''    +Writes: - dataSize, dA_                           (VAR/LONG)
''             - See effect 
''      Calls: L32_To_F32 
'-------------------------------------------------------------------------
dA_ := dAddr_
dataSize := dSize    

IF (dataSize < 2) OR (dataSize > _MAX_FFT_SIZE)
  er := _ABORT
  FFT_Error(er)

n := dataSize - 1
REPEAT i FROM n TO 0
  LONG[dA_][i << 1] := L32_To_F32(LONG[dA_][i])
  LONG[dA_][(i << 1) + 1] := 0.0
'--------------------------End of Longs_To_Complexes----------------------
  

PUB Remove_DC(dAddr_, dSize) | er, i, n
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ Remove_DC │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Removes DC component from complex input signal                                                  
'' Parameters: - HUB address of complex data array
''             - Number of complex datapoints
''     Result: None
''     Effect: Complex data array adjusted not to have DC component
''+Reads/Uses: - _ABORT                                    HUB/CON
''             - Several FPU driver CONs                   HUB/CON
''    +Writes: - dA_, dataSize                             HUB/VAR/LONG
''             - See effect
''      Calls: FFT_Error
''             WriteCmdByte
''             WriteCmd
''             WriteCmdRnLong
''             Wait
''             ReadReg
'-------------------------------------------------------------------------
dA_ := dAddr_
dataSize := dSize

IF (dataSize < 2) OR (dataSize > _MAX_FFT_SIZE)
  er := _ABORT
  FFT_Error(er)

'Calculate sums
WriteCmdByte(_SELECTA, 0)
WriteCmd(_CLRA)
WriteCmdByte(_SELECTA, 1)
WriteCmd(_CLRA)
n := dataSize - 1
REPEAT i FROM 0 TO n
  WriteCmdRnLong(_FWRITE, 2, LONG[dA_][i << 1])
  WriteCmdRnLong(_FWRITE, 3, LONG[dA_][(i << 1) + 1])  
  WriteCmdByte(_SELECTA, 0)
  WriteCmdByte(_FADD, 2)
  WriteCmdByte(_SELECTA, 1)
  WriteCmdByte(_FADD, 3)

WriteCmdByte(_SELECTA, 4)  
WriteCmdLong(_LWRITEA, dataSize)
WriteCmd(_FLOAT)
WriteCmd(_FINV)

'Calculate averages
WriteCmdByte(_SELECTA, 0)
WriteCmdByte(_FMUL, 4)
WriteCmdByte(_SELECTA, 1)
WriteCmdByte(_FMUL, 4) 

'Remove DC offset
WriteCmdByte(_SELECTA, 2)
REPEAT i FROM 0 TO n
  WriteCmdLong(_FWRITEA, LONG[dA_][i << 1])
  WriteCmdByte(_FSUB, 0)
  Wait
  WriteCmd(_FREADA)
  LONG[dA_][i << 1] := ReadReg
  WriteCmdLong(_FWRITEA, LONG[dA_][(i << 1) + 1]) 
  WriteCmdByte(_FSUB, 1)
  Wait
  WriteCmd(_FREADA)
  LONG[dA_][(i << 1) + 1] := ReadReg     
'------------------------------End of Remove_DC---------------------------


PUB Window(windType) | i, n
'-------------------------------------------------------------------------
'---------------------------------┌────────┐------------------------------
'---------------------------------│ Window │------------------------------
'---------------------------------└────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Applies selected window function to complex input data                                                  
' Parameters: Window selector 
'     Result: Not used
'     Effect: Windowed input data overwrites original in place 
'+Reads/Uses: - dataSize                       HUB/VAR/LONG
'             - _NOWINDOW                      HUB/CON
'             - _HANNING                       HUB/CON
'             - _GAUSS                         HUB/CON
'             - _EXPONENTIAL                   HUB/CON
'             - _RESENHANCE                    HUB/CON
'             - FPU command constants          HUB/CON
'    +Writes: See effect  
'      Calls: WriteCmdByte
'             WriteCmdLong
'             WriteCmd
'             Wait
'             ReadReg
'-------------------------------------------------------------------------
n := dataSize - 1 
CASE windType
  _NOWINDOW:
    RETURN
  _HANNING:
    'w( i ) = 0.5 * ( 1 - COS( 2 * Pi * i / N))
    'where N is the number of datapoints - 1, and i goes from 0 to N
    WriteCmdByte(_SELECTA, 1)
    WriteCmdLong(_LWRITEA, n)  
    WriteCmd(_FLOAT)
    WriteCmdByte(_SELECTA, 0)
    WriteCmd(_LOADPI)
    WriteCmdByte(_FMULI, 2)
    WriteCmdByte(_FDIV, 1)
    'Now Reg(0) contains 2*Pi/N
    REPEAT i FROM 0 TO n
      WriteCmdByte(_SELECTA, 1) 
      WriteCmdLong(_LWRITEA, i)  
      WriteCmd(_FLOAT)
      WriteCmd(_FMUL0)
      WriteCmd(_COS)
      WriteCmd(_FNEG)
      WriteCmdByte(_FADDI, 1)
      WriteCmdByte(_FDIVI, 2)
      'Now Reg(1) contains w(i)
      WriteCmdByte(_SELECTA, 2)
      WriteCmdLong(_FWRITEA, LONG[dA_][i << 1])
      WriteCmdByte(_FMUL, 1)
      Wait
      WriteCmd(_FREADA)
      LONG[dA_][i << 1] := ReadReg
      WriteCmdLong(_FWRITEA, LONG[dA_][(i << 1) + 1])
      WriteCmdByte(_FMUL, 1)
      Wait
      WriteCmd(_FREADA)
      LONG[dA_][(i << 1) + 1] := ReadReg
       
  _GAUSS:
    'w( i ) = EXP(-(i-(N/2))/(N/2))^2)*3.125)
    'where N is the number of datapoints - 1, and i goes from 0 to N
    'implicit sigma is 0.4   
    WriteCmdByte(_SELECTA, 1)
    WriteCmdLong(_LWRITEA, n)  
    WriteCmd(_FLOAT)
    WriteCmdByte(_FDIVI, 2)
    'Reg(1) now contains N/2
    WriteCmdByte(_SELECTA, 2)
    WriteCmdLong(_FWRITEA, -3.125)
    'Reg(2) now contains -3.125
    REPEAT i FROM 0 TO n
      WriteCmdByte(_SELECTA, 0) 
      WriteCmdLong(_LWRITEA, i)  
      WriteCmd(_FLOAT)
      WriteCmdByte(_FSUB, 1)
      WriteCmdByte(_FDIV, 1)
      WriteCmdByte(_FMUL, 0)
      WriteCmdByte(_FMUL, 2)
      WriteCmd(_EXP)
      'Now Reg(0) contains w(i)
      WriteCmdByte(_SELECTA, 3)
      WriteCmdLong(_FWRITEA, LONG[dA_][i << 1])
      WriteCmd(_FMUL0)
      Wait
      WriteCmd(_FREADA)
      LONG[dA_][i << 1] := ReadReg
      WriteCmdLong(_FWRITEA, LONG[dA_][(i << 1) + 1])
      WriteCmd(_FMUL0)
      Wait
      WriteCmd(_FREADA)
      LONG[dA_][(i << 1) + 1] := ReadReg
      
  _EXPONENTIAL:
    'w(i) = EXP(-(i / N) * 4)
    'where N is the number of datapoints - 1, and i goes from 0 to N
    'This is good to enhance S/N a lot but broadens spectral peaks 
    WriteCmdByte(_SELECTA, 0)
    WriteCmdLong(_LWRITEA, n)  
    WriteCmd(_FLOAT)
    WriteCmd(_FINV)
    WriteCmdByte(_FMULI, 4)
    WriteCmd(_FNEG)
    'Reg(0) now contains -4/N
    REPEAT i FROM 0 TO n
      WriteCmdByte(_SELECTA, 1) 
      WriteCmdLong(_LWRITEA, i)  
      WriteCmd(_FLOAT)
      WriteCmd(_FMUL0)
      WriteCmd(_EXP)
      'Now Reg(1) contains w(i)
      WriteCmdByte(_SELECTA, 2)
      WriteCmdLong(_FWRITEA, LONG[dA_][i << 1])
      WriteCmdByte(_FMUL, 1)
      Wait
      WriteCmd(_FREADA)
      LONG[dA_][i << 1] := ReadReg
      WriteCmdLong(_FWRITEA, LONG[dA_][(i << 1) + 1])
      WriteCmdByte(_FMUL, 1)
      Wait
      WriteCmd(_FREADA)
      LONG[dA_][(i << 1) + 1] := ReadReg
  
  _RESENHANCE:
    'w( i ) = 1+COS(Pi*i/N)+2*EXP(-(i-(N/2))/(N/2))^2)*4)
    WriteCmdByte(_SELECTA, 1)
    WriteCmdLong(_LWRITEA, n)  
    WriteCmd(_FLOAT)
    WriteCmdByte(_SELECTA, 0)
    WriteCmd(_LOADPI)
    WriteCmdByte(_FDIV, 1)
    'Now Reg(0) contains Pi/N
    WriteCmdByte(_SELECTA, 1)
    WriteCmdByte(_FDIVI, 2)
    'Now Reg(1) contains N/2
    REPEAT i FROM 0 TO n
      WriteCmdByte(_SELECTA, 3) 
      WriteCmdLong(_LWRITEA, i)  
      WriteCmd(_FLOAT)
      WriteCmdByte(_SELECTA, 2)
      WriteCmdByte(_FSET, 3)
      WriteCmd(_FMUL0)
      WriteCmd(_COS)
      WriteCmdByte(_FADDI, 1)
      'Reg(2) contains 1+COS(Pi*i/N)
      'and Reg(3) contains i
      WriteCmdByte(_SELECTA, 3)
      WriteCmdByte(_FSUB, 1)
      WriteCmdByte(_FDIV, 1)
      WriteCmdByte(_FMUL, 3)
      WriteCmdByte(_FMULI, -4)
      WriteCmd(_EXP)
      WriteCmdByte(_FMULI, 2)
      'Reg(3) contains 2*EXP(-(i-(N/2))/(N/2))^2)*4)
      WriteCmdByte(_FADD, 2)
      'Reg(3) contains w(i)
      WriteCmdByte(_SELECTA, 4)
      WriteCmdLong(_FWRITEA, LONG[dA_][i << 1])
      WriteCmdByte(_FMUL, 3)
      Wait
      WriteCmd(_FREADA)
      LONG[dA_][i << 1] := ReadReg
      
      WriteCmdLong(_FWRITEA, LONG[dA_][(i << 1) + 1])
      WriteCmdByte(_FMUL, 3)
      Wait
      WriteCmd(_FREADA)
      LONG[dA_][(i << 1) + 1] := ReadReg
'-------------------------------End of Window-----------------------------


PUB ReIm_To_MagnPhase(dAddr_, dSize) | er, i, n
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ ReIm_To_MagnPhase │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Converts complex data array to magnitude/phase format                                                  
'' Parameters: - HUB address of complex data array
''             - Number of complex datapoints
''     Result: None
''     Effect: Complex data array stored as magnitude/phase pairs in place
''             of input array of Real/Imag pairs
''+Reads/Uses: _ABORT 
''    +Writes: dA_, dataSize                             VAR/LONG  
''      Calls: FFT_Error
''             WriteCmdByte
''             WriteCmd
''             WriteCmdRnLong
''             Wait
''             ReadReg
'-------------------------------------------------------------------------
dA_ := dAddr_
dataSize := dSize

IF (dataSize < 2) OR (dataSize > _MAX_FFT_SIZE)
  er := _ABORT
  FFT_Error(er)

'Calculate magnitude and phase for each complex point
n := dataSize - 1
REPEAT i FROM 0 TO n
  WriteCmdRnLong(_FWRITE, 1, LONG[dA_][i << 1])
  WriteCmdRnLong(_FWRITE, 2, LONG[dA_][(i << 1) + 1])  
  WriteCmdByte(_SELECTA, 3)
  WriteCmd(_CLRA)
  WriteCmdByte(_FADD, 1)
  WriteCmdByte(_FMUL, 1)
  WriteCmdByte(_SELECTA, 4)
  WriteCmd(_CLRA)
  WriteCmdByte(_FADD, 2)
  WriteCmdByte(_FMUL, 2)
  WriteCmdByte(_FADD, 3)
  WriteCmd(_SQRT)
  'Reg(4) now contains magnitude
  WriteCmdByte(_SELECTA, 1)
  WriteCmdByte(_ATAN2, 2)
  'Reg(1) now contains phase in radians
  'Load data back into HUB
  Wait
  WriteCmdByte(_FREAD, 4)
  LONG[dA_][i << 1] := ReadReg
  Wait
  WriteCmdByte(_FREAD, 1)
  LONG[dA_][(i << 1) + 1] := ReadReg   
'-------------------------End of ReIm_To_MagnPhase------------------------


PUB ReIm_To_PwrdB(dAddr_, dSize) | er, i, n
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ ReIm_To_PwrdB │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Converts complex data array to Power/dB format                                                  
'' Parameters: - HUB address of complex data array
''             - Number of complex datapoints
''     Result: None
''     Effect: Complex data array stored as Power/dB pairs in place of
''             input array of Real/Imag pairs
''+Reads/Uses: _ABORT 
''    +Writes: dA_, dataSize                             VAR/LONG  
''      Calls: FFT_Error
''             WriteCmdByte
''             WriteCmd
''             WriteCmdRnLong
''             Wait
''             ReadReg
'-------------------------------------------------------------------------
dA_ := dAddr_
dataSize := dSize

IF (dataSize < 2) OR (dataSize > _MAX_FFT_SIZE)
  er := _ABORT
  FFT_Error(er)

'Calculate power and 10*log(power) for each complex point
n := dataSize - 1
REPEAT i FROM 0 TO n
  WriteCmdRnLong(_FWRITE, 1, LONG[dA_][i << 1])
  WriteCmdRnLong(_FWRITE, 2, LONG[dA_][(i << 1) + 1])  
  WriteCmdByte(_SELECTA, 3)
  WriteCmd(_CLRA)
  WriteCmdByte(_FADD, 1)
  WriteCmdByte(_FMUL, 1)
  WriteCmdByte(_SELECTA, 4)
  WriteCmd(_CLRA)
  WriteCmdByte(_FADD, 2)
  WriteCmdByte(_FMUL, 2)
  WriteCmdByte(_FADD, 3)
  'Reg(4) now contains power
  WriteCmdByte(_SELECTA, 5)
  WriteCmdByte(_FSET, 4)
  WriteCmd(_LOG10)
  WriteCmdByte(_FMULI, 10)
  'Reg(5) now contains power in dB
  'Load data back into HUB
  Wait
  WriteCmdByte(_FREAD, 4)
  LONG[dA_][i << 1] := ReadReg
  Wait
  WriteCmdByte(_FREAD, 5)
  LONG[dA_][(i << 1) + 1] := ReadReg   
'---------------------------End of ReIm_To_PwrdB--------------------------


DAT 'FFT procedures


PUB FFT(dAddr_, dSize, windType, invYes) | er
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ FFT │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Does Discrete Fourier Transform with FFT algorithm    
'' Parameters: - Address of complex data array
''             - Number of datapoints
''             - Window type
''             - TRUE/FALSE to indicate inverse transform
''     Result: None
''     Effect: Original 32-Bit FLOAT data is replaced with its transform
''+Reads/Uses: - dA_, fftSize, fftSizet2                   (VAR/LONG)
''              - _MAX_FFT_SIZE, _MAX_BLOCK_SIZE           (CON)
''    +Writes: - dA_, dataSize                             (VAR/LONG)
''             - See effect
''      Calls: - FFT_Error
''             - SetupParameters
''             - Window
''             - ZeroFill
''             - OneStepFFT
''             - MultiStepFFT
'-------------------------------------------------------------------------
dA_ := dAddr_
dataSize := dSize

IF (dataSize < 2) OR (dataSize > _MAX_FFT_SIZE)
  er := _ABORT
  FFT_Error(er)
  
SetupParameters

Window(windType) 

ZeroFill

IF fftSize =< _MAX_BLOCK_SIZE
  OneStepFFT(invYes)
ELSE   
  MultiStepFFT(invYes) 
'---------------------------------End of FFT------------------------------


PUB Spectrum_Analyzer(dAddr_,dSize,adcRate,windType,outForm,mF_,fR_,nB_)|e
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Spectrum_Analyzer │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: - Removes DC component
''             - Does FFT with optional window function
''             - Transforms result to output format
''             - Calculates Max.Freq and Freq.Res                                                             
'' Parameters: - Pointer to array of LONGs from ADC counts
''             - Number of data points as LONG
''             - Sampling rate of the ADC as LONG
''             - Window function type
''             - Output format
''             - Pointer to Maximum useful frequency (Tek)
''             - Pointer to Frequency resolution
''     Result: None
''     Effect: Positive frequency spectrum in the desired format replaces
''             input LONG data array 
''+Reads/Uses: _MAX_FFT_SIZE                             (CON) 
''    +Writes: See effect  
''      Calls: - FFT_Error
''             - Remove_DC
''             - FFT
''             - ReIm_To_MagnPhase
''             - ReIm_To_PwrdB
''             - Several low level FPU procedures  
''       Note: - Select window function according to signal type. For
''             continuous signals select _HANNING or _GAUSS, for transient
''             signal use _EXPONENTIAL or _RESENHANCE.
''             - You can be less conservative than Tektronix
''             recommendation and can use more spectrum points than here,
''             as all data are in the HUB memory. Modify last part of the
''             procedure to achieve that.  
'-------------------------------------------------------------------------
IF (dSize < 2) OR (dSize > _MAX_FFT_SIZE)
  e := _ABORT
  FFT_Error(e)
  
'Remove DC component of input signal
Remove_DC(dAddr_, dSize)

'Calculate discrete Fourier transform with FFT algorithm
'Apply window function
FFT(dAddr_, dSize, windType, FALSE)

'Calculate output in desired format
CASE outForm
  1:
    ReIm_To_MagnPhase(dAddr_, dSize)
  2:
    ReIm_To_PwrdB(dAddr_, dSize)

'Calculate parameters for frequency scale
'   Maximum frequency = (Sampling rate) / 5  (Tetronix good industry practice)
'Frequency Resolution = (Sampling rate) / (FFT size)
'Number of freq. bins = (FFT size) / 5
WriteCmdByte(_SELECTA, 2)
WriteCmdLong(_LWRITEA, adcRate)
WriteCmd(_FLOAT)
'WriteCmdByte(_FDIVI, 2)              'According to Nyquist
WriteCmdByte(_FDIVI, 5)              'According to Tektronix practice
'Reg(2) now contains Maximum frequency. Read it back
Wait
WriteCmd(_FREADA)
LONG[mF_][0] := ReadReg

WriteCmdByte(_SELECTA, 1)
WriteCmdLong(_LWRITEA, fftSize)
WriteCmd(_FLOAT)
WriteCmdByte(_SELECTA, 0)
WriteCmdLong(_LWRITEA, adcRate)
WriteCmd(_FLOAT)
WriteCmdByte(_FDIV, 1)
'Reg(0) now contains size of frequency bins. Read it back
Wait
WriteCmd(_FREADA)
LONG[fR_][0] := ReadReg

WriteCmdByte(_SELECTA, 2)  
WriteCmdByte(_FDIV, 0)
WriteCmd(_FIX)
'Reg(0) now contains the number of frequency bins. Read it back
Wait
WriteCmd(_LREADA)
LONG[nB_][0] := ReadReg
'-------------------------End of Spectrum_Analyzer------------------------


PRI SetupParameters | i
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ SetupParameters │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Calculates several parameters for the FFT             
'' Parameters: None 
''     Result: None
''     Effect: Prepared HUB/VAR/LONG parameters for FFT
''+Reads/Uses: dataSize                                  VAR/LONG
''             _MAX_FFT_SIZE, _MAX_BLOCK_SIZE            CON/LONG
''    +Writes: - fftSize, log2fftSize                    VAR/LONG
''             - fftSizet2, fftSized2, fftSizem1         VAR/LONG
''             - maxStages, maxBlockStages               VAR/LONG
''      Calls: FFT_Error
''       Note: None 
'-------------------------------------------------------------------------
IF dataSize > _MAX_FFT_SIZE
  FFT_Error(_ABORT)

fftSize := 2
log2fftSize := 1
REPEAT WHILE (fftSize < dataSize)
  fftSize <<= 1 
  log2fftSize += 1

fftSizet2 := fftSize << 1  
fftSized2 := fftSize >> 1  
fftSizem1 := fftSize - 1

maxStages := log2fftSize - 1

maxBlockStages := 0
i := _MAX_BLOCK_SIZE
REPEAT WHILE (i > 1)
  i >>= 1
  maxBlockStages += 1
'--------------------------End of SetupParameters-------------------------


PRI ZeroFill | i
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ FFT │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Appends complex zeroes to data array up to fftSize    
' Parameters: None 
'     Result: None
'     Effect: Zeroes are appended to data array
'+Reads/Uses: dataSize, fftSize                        VAR/LONG
'    +Writes: Part of data array
'      Calls: None 
'-------------------------------------------------------------------------
IF (dataSize < fftSize)
  REPEAT i FROM dataSize TO (fftSize -1)
    LONG[dA_][i << 1] := 0.0
    LONG[dA_][(i << 1) + 1] := 0.0
  'LONGMOVE(@dA_ + (dataSize << 3), 0.0, (fftSize - dataSize) << 1) 
'-------------------------------End of FFT--------------------------------


PRI OneStepFFT(invYes)
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ OneStepFFT │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Does Discrete Fourier Transform with FFT algorithm    
' Parameters: TRUE/FALSE to indicate inverse transform
'     Result: None
'     Effect: Original 32-Bit FLOAT data replaced with its transform
'+Reads/Uses: - dA_, fftSize, fftSizet2                  (VAR/LONG)
'             - Some other CONs of driver
'    +Writes: See effect  
'      Calls: Several FPU level procedures
'       Note: This does transform in one step inside FPU  
'-------------------------------------------------------------------------
'Select MA matrix
WriteCmd3Bytes(_SELECTMA, 0, fftSize, 2)
'Fill from HUB
WriteCmdCntLONGs(_WRBLK, fftSizet2, dA_)

IF invYes
  'Do one-shot in-place inverz FFT with full processing
  WriteCmdByte(_FFT,_FIRST_STAGE+_BIT_REVERSE+_PRE_ADJUST+_POST_ADJUST)
ELSE
  'Do one-shot in-place FFT with bit-reverse sort pre-processing
  WriteCmdByte(_FFT,_FIRST_STAGE+_BIT_REVERSE)

'Read back data from FPU to HUB
ReadRegs(1, fftSizet2 - 1, dA_ + 4)     
WriteCmdByte(_SELECTA, 0)
WriteCmd(_FREADA)
LONG[dA_][0] := ReadReg  
'-----------------------------End of OneStepFFT---------------------------


PRI MultiStepFFT(invYes)|nLevels,stage,fin,bS,level,n,index,i,j,k,l,t,type
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ MultiStepFFT │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Does Discrete Fourier Transform with FFT algorithm where it
'             - sorts the input data points in bit-reverse order
'             - performs a series of butterfly calculations
' Parameters: TRUE/FALSE to indicate inverse transform
'     Result: None
'     Effect: Original 32-Bit FLOAT data is replaced with its transform
'+Reads/Uses: - dA_, fftSize, fftSizet2                  (VAR/LONG)
'             - maxBlockSize, maxBlockStages             (VAR/LONG)
'             - Some other CONs of driver
'    +Writes: See effect 
'      Calls: Several FPU level procedures
'-------------------------------------------------------------------------
'Bit reverse sort of input data
j := fftSize >> 1                     
REPEAT i FROM 1 TO (fftSize - 1)
  IF (i < j)
    k := i << 1
    l := j << 1
    t:= LONG[dA_][l]
    LONG[dA_][l] := LONG[dA_][k]
    LONG[dA_][k] := t
    t := LONG[dA_][l + 1]
    LONG[dA_][l + 1] := LONG[dA_][k + 1]
    LONG[dA_][k + 1] := t
  k := fftSize >> 1                   
  REPEAT WHILE (j => k) AND (j)
    j -= k
    k >>= 1                       
  j += k  

'Prepare butterfly loop parameters  
nLevels := 1
bS := _MAX_BLOCK_SIZE
stage := 0
fin := FALSE  

REPEAT UNTIL fin

  'Find max blocksize for this stage
  REPEAT WHILE ((nlevels * bS) > fftSize)
    bS >>= 1

  'Select MA matrix
  WriteCmd3Bytes(_SELECTMA, 0, bS, 2)
    
  REPEAT level FROM 0 TO (nLevels - 1)

    REPEAT n FROM 0 TO (fftSize - 1) STEP (bS * nLevels)

      'Write block of data
      WriteCmdByte(_SELECTX, 0)
      index := level + n
      REPEAT i FROM 0 TO (bS - 1)  
        WriteCmdLong(_FWRITEX, LONG[dA_][index << 1])
        WriteCmdLong(_FWRITEX, LONG[dA_][(index << 1) + 1])
        index := index + nLevels

      'Figure out FFT type  
      IF (stage == 0)
        type := _FIRST_STAGE
      ELSEIF ((level == 0) AND (n == 0))
        type := _NEXT_STAGE
      ELSEIF (n == 0)
        type := _NEXT_LEVEL
      ELSE
        type := _NEXT_BLOCK

      IF invYes  
        'Pre adjust for inverse FFT
        IF (stage == 0)
          type := type + _PRE_ADJUST
  
      'Perform FFT  
      WriteCmdByte(_FFT, type)

      'Read block of transformed data
      WriteCmdByte(_SELECTX, 0)
      index := level + n
      REPEAT i FROM 0 TO (bS - 1)
        Wait
        WriteCmd(_FREADX)
        LONG[dA_][index << 1] := ReadReg
        Wait
        WriteCmd(_FREADX)
        LONG[dA_][(index << 1) + 1] := ReadReg
        index := index + nLevels

  'figure out new stage and nLevels
  IF (stage == 0)
    stage := stage + maxBlockStages
    nLevels := _MAX_BLOCK_SIZE
  ELSE
    stage := stage + 1
    nLevels <<= 1

  IF stage > maxStages
    fin := TRUE

IF invYes
  'Transformation done. Now post adjust for inverse FFT
  WriteCmdByte(_SELECTA, 0)
  WriteCmdLong(_LWRITEA, fftSize)
  WriteCmd(_FLOAT)
  WriteCmd(_FINV)
  'Reg(0) now contains 1/ffSize
  WriteCmdByte(_SELECTA, 1)
  n := fftSizem1
  REPEAT i FROM 0 TO n
    WriteCmdLong(_FWRITEA, LONG[dA_][i << 1])
    WriteCmd(_FMUL0)                            'Divide by fftSize
    Wait
    WriteCmd(_FREADA)
    LONG[dA_][i << 1] := ReadReg
    WriteCmdLong(_FWRITEA, LONG[dA_][(i << 1) + 1])
    WriteCmd(_FMUL0)
    WriteCmd(_FNEG)                             'Change sign of imag
    Wait
    WriteCmd(_FREADA)
    LONG[dA_][(i << 1) + 1] := ReadReg
'-----------------------------End of MultiStepFFT-------------------------


PRI FFT_Error(response)
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ FFT_Error │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Handels errors. User defines here what to do.
' Parameters: Response to error                                 
'     Result: None                    
'+Reads/Uses: - _CONTINUE, _NOTIFY, _ABORT                     (CON/LONG)                
'    +Writes: None                                    
'      Calls: None
'       Note: Any further action should be user defined here
'-------------------------------------------------------------------------
CASE response
  _CONTINUE:
    RETURN 
  _NOTIFY:
  _ABORT:
    ABORT     

RETURN 
'-------------------------------End of FFT_Error--------------------------


DAT 'Core FPU32 procedures


PUB Reset                                 
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ Reset │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Initiates a Software Reset of the FPU                                                 
'' Parameters: None                      
''     Result: TRUE if reset was succesfull else FALSE
''+Reads/Uses: /_RST
''    +Writes: command, par1        
''      Calls: #Rst (in COG)
'-------------------------------------------------------------------------
DoCommand(_RST)

RESULT := par1               'Read back FPU's READY status
'--------------------------------End of Reset-----------------------------                                                                    


PUB CheckReady                            
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ CheckReady │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Checks for an empty instruction buffer of the FPU. It
''             returns the result immediately and does not wait for that
''             "READY" state unlike the Wait command, which does wait                             
'' Parameters: None                      
''     Result: TRUE if FPU is idle else FALSE
''+Reads/Uses: /_IDLING    
''    +Writes: command        
''      Calls: #IdlingCheck (in COG)
'-------------------------------------------------------------------------
DoCommand(_CHECK)

RESULT := par1
'-----------------------------End of CheckReady---------------------------


PUB Wait                                   
'-------------------------------------------------------------------------
'---------------------------------┌──────┐--------------------------------
'---------------------------------│ Wait │--------------------------------
'---------------------------------└──────┘--------------------------------
'-------------------------------------------------------------------------
''     Action: Waits for FPU ready                             
'' Parameters: None                      
''     Result: None 
''+Reads/Uses: /_WAIT    
''    +Writes: command        
''      Calls: #WaitForReady (in COG)
'-------------------------------------------------------------------------
DoCommand(_WAIT)
'--------------------------------End of Wait------------------------------


PUB ReadSyncChar                                              
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ ReadSyncChar │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads syncronization character from FPU                             
'' Parameters: None                      
''     Result: Sync Char response of FPU (should be $5C=dec 92 if FPU OK)  
''+Reads/Uses: /_SYNC    
''    +Writes: None        
''      Calls: WriteCmd, ReadByte
''       Note: No Wait here before the read operation
'-------------------------------------------------------------------------
WriteCmd(_SYNC)
RESULT := ReadByte  
'----------------------------End of ReadSyncChar--------------------------


PUB ReadInterVar(index)                                            
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ ReadInterVar │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads an Internal Variable from FPU                           
'' Parameters: Index of variable        
''     Result: Selected Internal variable of FPU
''+Reads/Uses: /_READVAR, _LREAD0   
''    +Writes: None        
''      Calls: WriteCmdByte
''             Wait
''             WriteCmd
'-------------------------------------------------------------------------
WriteCmdByte(_READVAR, index)
Wait
WriteCmd(_LREAD0)
RESULT := ReadReg                
'----------------------------End of ReadInterVar--------------------------


PUB ReadRaFloatAsStr(format)
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ ReadRaFloatAsStr │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Reads the float value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB/str                           
'' Parameters: Format of string in FPU convention        
''     Result: Pointer to string HUB/str
''+Reads/Uses: /_FTOA, _FTOAD   
''    +Writes: None        
''      Calls: WriteCmdByte
''             Wait
''             ReadStr
'-------------------------------------------------------------------------
WriteCmdByte(_FTOA, format)
WAITCNT(_FTOAD + CNT)
Wait
RESULT := ReadStr
'--------------------------End of ReadRaFloatAsStr------------------------


PUB ReadRaLongAsStr(format)
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ ReadRaLongAsStr │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Reads the LONG value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB/str                           
'' Parameters: Format of string in FPU convention        
''     Result: Pointer to string HUB/str
''+Reads/Uses: /_LTOA, _FTOAD   
''    +Writes: None        
''      Calls: WriteCmdByte
''             Wait
''             ReadStr
'-------------------------------------------------------------------------
WriteCmdByte(_LTOA, format)
WAITCNT(_FTOAD + CNT)
Wait
RESULT := ReadStr
'---------------------------End of ReadRaLongAsStr------------------------


PUB WriteCmd(cmd)                                    
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ WriteCmd │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte to FPU                           
'' Parameters: Command byte                       
''     Result: None
''+Reads/Uses: /_WRTBYTE    
''    +Writes: par1, command                                              
''      Calls: #WrtByte (in COG)
'-------------------------------------------------------------------------
par1 := cmd

DoCommand(_WRTBYTE)
'------------------------------End of WriteCmd----------------------------


PUB WriteCmdByte(cmd, byt)                            
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ WriteCmdByte │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus a Data byte to FPU          
'' Parameters: -Command byte
''             -Data byte
''     Result: None
''+Reads/Uses: /_WRTCMDBYTE  
''    +Writes: par1, par2, command        
''      Calls: #WrtCmdByte (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := byt

DoCommand(_WRTCMDBYTE)
'---------------------------End of WriteCmdByte---------------------------


PUB WriteCmd2Bytes(cmd, b1, b2)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd2Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 2 Data bytes to FPU          
'' Parameters: -Command byte
''             -Data bytes 1, 2
''     Result: None
''+Reads/Uses: /_WRTCMD2BYTES  
''    +Writes: par1, par2, par3, command        
''      Calls: #WrtCmd2Bytes (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := b1
par3 := b2

DoCommand(_WRTCMD2BYTES)
'--------------------------End of WriteCmd2Bytes--------------------------


PUB WriteCmd3Bytes(cmd, b1, b2, b3)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd3Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 3 Data bytes to FPU          
'' Parameters: -Command byte
''             -Data bytes 1...3
''     Result: None
''+Reads/Uses: /_WRTCMD3BYTES  
''    +Writes: par1, par2, par3, par4, command        
''      Calls: #WrtCmd3Bytes (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := b1
par3 := b2
par4 := b3

DoCommand(_WRTCMD3BYTES)
'--------------------------End of WriteCmd3Bytes--------------------------


PUB WriteCmd4Bytes(cmd, b1, b2, b3, b4)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd4Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 4 Data bytes to FPU          
'' Parameters: -Command byte
''             -Data bytes 1...4
''     Result: None
''+Reads/Uses: /_WRTCMD4BYTES  
''    +Writes: par1, par2, par3, par4, par5, command        
''      Calls: #WrtCmd4Bytes (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := b1
par3 := b2
par4 := b3
par5 := b4

DoCommand(_WRTCMD4BYTES)
'--------------------------End of WriteCmd4Bytes--------------------------


PUB WriteCmdLong(cmd, longVal )                            
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ WriteCmdLong │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte plus a 32-bit LONG value to FPU          
'' Parameters: -Command byte
''             -32-bit LONG value
''     Result: None
''+Reads/Uses: /_WRTCMDREG  
''    +Writes: par1, par2, command        
''      Calls: #WrtCmdReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := longVal

DoCommand(_WRTCMDREG)

'----------------------------End of WriteCmdLong--------------------------


PUB WriteCmdRnLong(cmd, regN, longVal)
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmdRnLong │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + RegNo byte + LONG data to FPU                          
'' Parameters: -Command byte
''             -RegNo byte
''             -LONG (32-bit) data                      
''     Result: None
''+Reads/Uses: /_WRTCMDRNREG   
''    +Writes: par1, par2, par3, command        
''      Calls: #WrtCmdRnReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := regN
par3 := longVal

DoCommand(_WRTCMDRNREG)
'--------------------------End of WriteCmdRnLong--------------------------


PUB WriteCmdCntLongs(cmd, cntr, longPtr) 
'-------------------------------------------------------------------------
'--------------------------┌──────────────────┐---------------------------
'--------------------------│ WriteCmdCntLongs │---------------------------
'--------------------------└──────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command + Counter byte + LONG Data array into FPU                          
'' Parameters: -Command byte
''             -Counter
''             -Pointer to array of LONGs                      
''     Result: None
'' Reads/Uses: /_WRTCMDCNTREGS     
''    +Writes: par1, par2, par3, command         
''      Calls: #WrtCmdCntRegs (in COG)
''       Note: Counter byte is (should be) the size of the array of LONGs
'-------------------------------------------------------------------------
par1 := cmd
par2 := cntr
par3 := longPtr

DoCommand(_WRTCMDCNTREGS)
'-------------------------End of WriteCmdCntLongs--------------------------


PUB WriteCmdStr(cmd, strPtr)
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ WriteCmdStr │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + a String into FPU                          
'' Parameters: -Command byte
''             -Pointer to HUB/String                      
''     Result: None
''+Reads/Uses: /_WRTCMDSTRING     
''    +Writes: par1, par2, command       
''      Calls: #WrtCmdString (in COG)
''       Note: No need for counter byte, zero terminates string
'-------------------------------------------------------------------------
par1 := cmd
par2 := strPtr

DoCommand(_WRTCMDSTRING)
'----------------------------End of WriteCmdStr---------------------------


PUB ReadByte                                              
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadByte │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads a byte from FPU                           
'' Parameters: None                      
''     Result: Byte from FPU
''+Reads/Uses: /command, _RDBYTE, par1    
''    +Writes: command, par1        
''      Calls: #RByte (in COG)
'-------------------------------------------------------------------------
DoCommand(_RDBYTE)

RESULT := par1               'Get fpuByte from par1
'------------------------------End of ReadByte----------------------------


PUB ReadReg                                             
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadReg │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a 32-bit Register from FPU                           
'' Parameters: None                      
''     Result: 32-bit LONG from FPU
''+Reads/Uses: /_RDBYTE    
''    +Writes: command, par1        
''      Calls: #RdReg (in COG)
'-------------------------------------------------------------------------
DoCommand(_RDREG)

RESULT := par1               'Get fpuReg from par1
'------------------------------End of ReadReg-----------------------------


PUB ReadRegs(regX, cntr, floatPtr)                                    
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadRegs │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads 32-bit Registers from FPU starting from Reg[X]                           
'' Parameters: - Reg[X]
''             - Number of registers to read
''             - pointer to HUB address of register array                      
''     Result: FPU registers from Reg[X] stored in HUB sequentially from
''             the address floatPtr
''+Reads/Uses: /_RDREGS    
''    +Writes: par1, par2, par3, command        
''      Calls: #RdRegs (in COG)
'-------------------------------------------------------------------------
Wait
par1 := regX
par2 := cntr
par3 := floatPtr

DoCommand(_RDREGS)
'-----------------------------End of ReadRegs-----------------------------


PUB ReadStr                                             
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadStr │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a String from FPU                           
'' Parameters: None                      
''     Result: Pointer to HUB/str where the string from the FPU is copied
''+Reads/Uses: /_RDSTRING, @str    
''    +Writes: command        
''      Calls: #RdString (in COG)
''       Note: _READSTR FPU command is issued by the PASM routine
'-------------------------------------------------------------------------
DoCommand(_RDSTRING)

RESULT := @str               'Pointer to HUB/str
'------------------------------End of ReadStr-----------------------------


PRI DoCommand(cmd)
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ DoCommand │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: -Initiates a PASM routine via the command register in HUB
''             -Waits for the completition of PASM routine             
'' Parameters: Code of command                      
''     Result: Directly none, PASM routine is performed
''+Reads/Uses: None    
''    +Writes: command        
''      Calls: Corresponding PASM routines in COG
''       Note: Waits until command register is zeroed by the PASM code
'-------------------------------------------------------------------------
command := cmd                'Wait for cmd to be sent and processed
REPEAT WHILE command
'-----------------------------End of DoCommand----------------------------


DAT '-------------------------Start of PASM code-------------------------- 
'-------------------------------------------------------------------------
'-------------DAT section for PASM program and COG registers--------------
'-------------------------------------------------------------------------

uMFPU    ORG             0             'Start of PASM code

Get_Command
RDLONG   r1,             PAR WZ        'Read "command" register from HUB
IF_Z     JMP             #Get_Command  'Wait for a nonzero value

ADD      r1,             #Cmd_Table-1  'Add it to the value of
                                       '#Cmd_Table-1

JMP      r1                            'Jump to command in Cmd_Table
                                       'JMP counts jumps in register units 
                                     
Cmd_Table                              'Command dispatch table
JMP      #Init                         '(Init=command No.1)
JMP      #Rst                          '(Reset=command No.2)
JMP      #CheckForReady                '(Check=command No.3)
JMP      #WaitForReady                 '(Wait=command No.4)
JMP      #WrtByte                      '(WrtByte=command No. 5)
JMP      #WrtCmdByte                   '(WrtCmdByte=command No. 6)
JMP      #WrtCmd2Bytes                 '(WrtCmd2Bytes=command No. 7)
JMP      #WrtCmd3Bytes                 '(WrtCmd3Bytes=command No. 8)
JMP      #WrtCmd4Bytes                 '(WrtCmd4Bytes=command No. 9)
JMP      #WrtCmdReg                    '(WrtCmdReg=command No. 10)
JMP      #WrtCmdRnReg                  '(WrtCmdRnReg=command No. 11)
JMP      #WrtCmdCntRegs                '(WrtCmdCntRegs=command No. 12)
JMP      #WrtCmdString                 '(WrtCmdString=command No. 13)
JMP      #RByte                        '(RByte=command No. 14)
JMP      #RdReg                        '(RdReg=command No. 15)
JMP      #RdRegs                       '(RdReg=command No. 16)
JMP      #RdString                     '(RdString=command No. 17)

Done                                   'Common return point of commands     
'Command has been sent to the FPU and in the case of Read operations the
'actual data readings has been finished. Signal this back to the SPIN code
'of this driver by clearing the "command" register, then jump back to the
'entry point of this PASM code and fetch the next command.
WRLONG   _Zero,          PAR           'Write 0 to command(in HUB)    
JMP      #Get_Command                  'Get next command

'Note that "command" is cleared usually after it is sent with the
'following attached data, not when it is actually finished by the FPU.
'Exceptions to this are the four Read operations - RByte, RdReg, RdRegs,
'RdSring - where the command register is cleared only after the fully
'finished data reading. In other words, you can send several processing
'commands plus write data one after the other to the FPU that has a 256
'bytes instruction buffer. If you send many commands quickly you should
'check the instruction buffer sometimes (e.g. after 256 bytes sent) to
'prevent overflow. FPU can perform autonomously some kind of tasks, e.g.
'driving digital lines and/or sending serial data depending on the values
'in its internal registers and timers. However, in a usual programming
'situation sometimes you would like to get back some results from it.
'Before any read operation you should wait for all sent commands to be
'executed. For that task there is the #WaitForReady procedure. The
'#CheckForReady procedure will just return the "NOT BUSY" status of the
'FPU. TRUE means that FPU is ready (Idling) and can do a read operation
'immediately. FALSE means the FPU is busy with processing commands. In
'this case you can send a command to it, but you have to wait with a Read
'operation.   


DAT 'Init
'-------------------------------------------------------------------------
'---------------------------------┌──────┐--------------------------------
'---------------------------------│ Init │--------------------------------
'---------------------------------└──────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: -Initializes DIO and CLK Pin Masks
'             -Stores HUB addresses of parameters.
'             -Preforms a simple FPU ready TEST (DIO line is LOW?)
' Parameters: -HUB/dio, clk, @str
'             -COG/par
'    Results: COG/dio_Mask, clk_Mask
'             COG/par1_Addr_, par2_Addr_, par3_Addr_, str_Addr_
'             HUB/par1 (Flag of success)  
'+Reads/Uses: /par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_, par5_Addr_
'             dio_Mask, clk_Mask, 
'    +Writes: r1, r2
'      Calls: None
'-------------------------------------------------------------------------
Init

MOV      r1,             PAR           'Get HUB memory address of "command"

ADD      r1,             #4            'r1 now points to "par1" in HUB 
MOV      par1_Addr_,     r1            'Store this address
RDLONG   r2,             r1            'Load DIO pin No. from HUB into r2
MOV      dio_Mask, #1                  'Setup DIO pin mask 
SHL      dio_Mask, r2
ANDN     OUTA,           dio_Mask      'Pre-Set Data pin LOW
ANDN     DIRA,           dio_Mask      'Set Data pin as INPUT 

ADD      r1,             #4            'r1 now points to "par2" in HUB       
MOV      par2_Addr_,     r1            'Store this address
RDLONG   r2,             r1            'Load CLK pin No. from HUB into r2
MOV      clk_Mask, #1                  'Setup CLK pin mask
SHL      clk_Mask, r2
ANDN     OUTA,           clk_Mask      'Pre-Set Clock pin LOW (Idle)
OR       DIRA,           clk_Mask      'Set Clock pin as an OUTPUT

ADD      r1,             #4            'r1 now points to "par3" in HUB       
MOV      par3_Addr_,     r1            'Store this address
RDLONG   str_Addr_,      r1            'Read pointer to str char array

ADD      r1,             #4            'r1 now points to "par4" in HUB        
MOV      par4_Addr_,     r1            'Store this address
ADD      r1,             #4            'r1 now points to "par5" in HUB       
MOV      par5_Addr_,     r1            'Store this address                              

'Check DIO line for FPU ready
TEST     dio_Mask,       INA WC        'Read DIO state into 'C' flag
                                       'If Cary then not LOW, not ready
IF_C     MOV r1,         #0            'Prepare to send FALSE back 
IF_C     JMP #:Signal                  'Send it

NEG      r1,             #1            'Prepare to send TRUE back

:Signal  
WRLONG   r1,             par1_Addr_    'Send back result of DIO line test
  
JMP      #Done         
'-------------------------------------------------------------------------


DAT 'Rst
'-------------------------------------------------------------------------
'----------------------------------┌─────┐--------------------------------
'----------------------------------│ Rst │--------------------------------
'----------------------------------└─────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Does a Software Reset of FPU
' Parameters: None
'    Results: "Okay" in HUB/par1
'+Reads/Uses: /_RESET, _Data_Period, _Reset_Delay
'             dio_Mask, par1_Addr_
'    +Writes: r1, r4, time
'      Calls: #Write_Byte
'       Note: #Write_Byte and descendants use r2, r3
'-------------------------------------------------------------------------
Rst

MOV      r1,             #_RESET       'Byte to send
MOV      r4,             #10           '10 times

:Loop
CALL     #Write_Byte                   'Write byte to FPU 
DJNZ     r4,             #:Loop        'Repeat Loop 10 times 

MOV      r1,             #0            'Write a 0 byte to enforce DIO LOW
CALL     #Write_Byte

'Wait for a  Reset Delay of 10 msec
MOV      time,           CNT           'Find the current time
ADD      time,           _Reset_Delay  'Prepare a 10 msec Reset Delay
WAITCNT  time,           #0            'Wait for 10 msec

'Check DIO for FPU ready
TEST     dio_Mask,       INA WC        'Read DIO state into 'C' flag
                                       'If Cary (DIO not LOW) 
IF_C     MOV r1,         #0            'Not ready, send FALSE back
IF_C     JMP #:Signal

NEG      r1,             #1            'Ready, send TRUE back

:Signal  
WRLONG   r1,             par1_Addr_  

JMP      #Done
'-------------------------------------------------------------------------


DAT 'CheckForReady
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ CheckForReady │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Checks for an empty instruction buffer of the FPU. It
'             returns immediately with the result and does not wait for
'             that state unlike the WaitForReady command, which does.
' Parameters: None
'    Results: True OR false in par1 according to FPU's availability status
'+Reads/Uses: /dio_Mask, _Data_Period
'    +Writes: time, CARRY flag
'      Calls: None
'       Note: -This routine is especially useful when you have more than
'             one FPU in your system. If you use the "WaitForReady" (as
'             "Wait" in SPIN) procedure then your main program will really
'             wait and wait... for the busy FPU. However, If you use this 
'             ( as "CheckReady" in SPIN) procedure then you have back the  
'             control immediately. If the checked FPU is busy this routine
'             will respond with FALSE and you may delegate the pending
'             computing task to an other FPU. Idling FPU will respond with
'             TRUE. In this way you can feed with tasks several FPUs
'             parallely.
'             -Prop is fast enough at 80 MHz to check DIO line before FPU
'             is able to rise DIO line in response to a received command.
'             That is why a Data Period Delay is inserted before the
'             check.
'             -You can send commands and data one after the other without
'             checking the "availability" of the FPU since it has a 256
'             bytes instruction buffer. However, before you read any data
'             back from the FPU you have to wait for all of its previous
'             instructions to be completed.
'-------------------------------------------------------------------------
CheckForReady

ANDN     DIRA,           dio_Mask      'Set DIO pin as an INPUT

'Insert Data Period Delay 
MOV      time,           CNT           'Find the current time
ADD      time,           _Data_Period  '1.6 us Data Period Delay
WAITCNT  time,           #0            'Wait for 1.6 usec  

'Check DIO line for FPU ready, i.e. available
TEST     dio_Mask,       INA WC        'Read DIO state into 'C' flag
                                       'If Cary (DIO not LOW)
IF_C     MOV r1,         #0            'Not ready, send FALSE (busy) back
IF_C     JMP #:Signal                  'since the are unprocessed
                                       'instructions in the FPU. You can
                                       'send new processing commands but
                                       'not Read commands

NEG      r1,             #1            'DIO is LOW, i.e. FPU's instruction
                                       'buffer is empty and you can send a
                                       'Read commands or processing 
                                       'commands, as well. 

:Signal  
WRLONG   r1,             par1_Addr_  

JMP      #Done    
'-------------------------------------------------------------------------


DAT 'WaitForReady
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ WaitForReady │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Waits for a LOW DIO, i.e for a ready FPU with empty
'             instruction buffer
' Parameters: None
'    Results: None 
'+Reads/Uses: None
'    +Writes: None
'      Calls: #Wait4Ready
'-------------------------------------------------------------------------
WaitForReady
                                     
CALL     #Wait_4_Ready

JMP      #Done          
'-------------------------------------------------------------------------


DAT 'WrtByte 
'-------------------------------------------------------------------------
'----------------------------------┌─────────┐----------------------------
'----------------------------------│ WrtByte │----------------------------
'----------------------------------└─────────┘----------------------------
'-------------------------------------------------------------------------
'      Action: Sends a byte to FPU 
'  Parameters: Byte to send in HUB/par1 (LS byte of a 32-bit value)
'     Results: None 
' +Reads/Uses: /par1_Addr_
'     +Writes: r1
'       Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtByte

RDLONG   r1,             par1_Addr_    'Load byte from HUB
CALL     #Write_Byte                   'Write it to FPU
   
JMP      #Done        
'-------------------------------------------------------------------------


DAT 'WrtCmdByte 
'-------------------------------------------------------------------------
'-----------------------------┌────────────┐------------------------------
'-----------------------------│ WrtCmdByte │------------------------------
'-----------------------------└────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus Data byte sequence to FPU
' Parameters: -Command byte in HUB/par1
'             -Data byte    in HUB/par2
'    Results: None                                                                                             
'+Reads/Uses: /par1_Addr_, par2_Addr_
'    +Writes: r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmdByte

'Send an 8 bit Command + 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'-------------------------------------------------------------------------


DAT 'WrtCmd2Bytes
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd2Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 2 Data bytes to FPU
' Parameters: -Command byte in HUB/par1
'             -Data bytes   in HUB/par2, par3
'    Results: None                                                                                             
'+Reads/Uses: /par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd2Bytes

'Send an 8 bit Command + 2 x 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load 1st Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par3_Addr_    'Load 2nd Data byte from par3
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'-------------------------------------------------------------------------


DAT 'WrtCmd3Bytes
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd3Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 3 Data bytes to FPU
' Parameters: -Command byte in HUB/par1
'             -Data bytes   in HUB/par2, par3, par4
'    Results: None                                                                                             
'+Reads/Uses: /par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'    +Writes: r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd3Bytes

'Send an 8 bit Command + 3 x 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load 1st Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par3_Addr_    'Load 2nd Data byte from par3
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par4_Addr_    'Load 3nd Data byte from par4
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'-------------------------------------------------------------------------


DAT 'WrtCmd4Bytes
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd4Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 4 Data bytes to FPU
' Parameters: -Command byte in HUB/par1
'             -Data bytes   in HUB/par2, par3, par4, par5
'    Results: None                                                                                             
'+Reads/Uses: /par1_Addr_,par2_Addr_,par3_Addr_,par4_Addr_ ,par5_Addr
'    +Writes: r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd4Bytes

'Send an 8 bit Command + 3 x 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load 1st Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par3_Addr_    'Load 2nd Data byte from par3
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par4_Addr_    'Load 3nd Data byte from par4
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par5_Addr_    'Load 3nd Data byte from par4
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'-------------------------------------------------------------------------


DAT 'WrtCmdReg
'-------------------------------------------------------------------------
'------------------------------┌───────────┐------------------------------
'------------------------------│ WrtCmdReg │------------------------------
'------------------------------└───────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus a 32-bit Register sequence to FPU
' Parameters: -Command byte          in HUB/par1
'             -32-bit Register value in HUB/par2
'    Results: None                                                                                             
'+Reads/Uses: /par1_Addr_, par2_Addr_
'    +Writes: r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdReg

'Send an 8 bit Command + 32-bit Register sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par2_Addr_    'Load 32-bit Reg. value from par2
CALL     #Write_Reg                    'and write it to FPU
  
JMP      #Done
'-------------------------------------------------------------------------


DAT 'WrtCmdRnReg
'-------------------------------------------------------------------------
'-----------------------------┌─────────────┐-----------------------------
'-----------------------------│ WrtCmdRnReg │-----------------------------
'-----------------------------└─────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + Reg[n] byte + 32-bit data to FPU
' Parameters: -Command byte in HUB/par1
'             -Reg[n] byte  in HUB/par2
'             -32-bit data  in HUB/par3
'    Results: None                                                                                             
'+Reads/Uses: /par1_Addr_,par2_Addr_,par3_Addr_
'    +Writes: r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdRnReg

'Send Command byte + Reg[n] byte + 32-bit data to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load Reg[n] from par2
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par3_Addr_    'Load 32-bit Reg. value from par3
CALL     #Write_Reg                    'and write it to FPU
  
JMP      #Done
'-------------------------------------------------------------------------


DAT 'WrtCmdCntRegs
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ WrtCmdCntRegs │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + Cntr byte + 32-bit data array to FPU
' Parameters: - Command byte                 in HUB/par1
'             - Cntr byte                    in HUB/par2
'             - Pointer to 32-bit data array in HUB/par3
'    Results: None                                                                                             
'+Reads/Uses: /par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: r1, r4, r5, r6          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdCntRegs

'Send Command byte + Cntr byte + 32-bit data array to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r5,             par2_Addr_    'Load Counter from par2
MOV      r1,             r5
CALL     #Write_Byte                   'Write it to FPU 
RDLONG   r6,             par3_Addr_    'Load pointer to float array in HUB

:Loop
RDLONG   r4,             r6            'Load next 32-bit value from HUB
CALL     #Write_Reg                    'and write it to FPU 
ADD      r6,             #4            'Increment pointer to HUB memory
DJNZ     r5,             #:Loop        'Decrement r5; jump if not zero 
  
JMP      #Done
'-------------------------------------------------------------------------


DAT 'WrtCmdString
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ WrtCmdString │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + String to FPU
' Parameters: - Command byte      in HUB/par1
'             - Pointer to String in HUB/par2
'    Results: None                                                                                             
'+Reads/Uses: /par1_Addr_, par2_Addr_
'    +Writes: r1, r4          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmdString

'Send Command byte + String (array of Chars then 0) to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par2_Addr_    'Load pointer to HUB/Str from par2

'Write String from HUB to FPU
:Loop
RDBYTE   r1,             r4 WZ         'Read character from HUB
CALL     #Write_Byte                   'Write char or zero to FPU
                                       'If char was not zero  
IF_NZ    ADD r4,         #1            'Increment pointer to HUB memory
IF_NZ    JMP #:Loop                    'Read next byte 
  
JMP      #Done
'-------------------------------------------------------------------------


DAT 'RByte
'-------------------------------------------------------------------------
'----------------------------------┌───────┐------------------------------
'----------------------------------│ RByte │------------------------------
'----------------------------------└───────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads a byte from FPU 
' Parameters: None
'    Results: byte entry in HUB/par1 (LSB of) 
'+Reads/Uses: /par1_Addr_
'    +Writes: r1
'      Calls: #Read_Setup_Delay , #Read_Byte
'-------------------------------------------------------------------------
RByte

CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Byte
WRLONG   r1,             par1_Addr_    'Write r1 into HUB/par1
   
JMP      #Done          
'-------------------------------------------------------------------------


DAT 'RdReg
'-------------------------------------------------------------------------
'----------------------------------┌───────┐------------------------------
'----------------------------------│ RdReg │------------------------------
'----------------------------------└───────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 32-bit register from FPU 
' Parameters: None
'    Results: Register Entry in HUB/par1 
'+Reads/Uses: /par1_Addr_
'    +Writes: r1                       
'      Calls: #Read_Setup_Delay, #Read_Register
'-------------------------------------------------------------------------
RdReg

CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Register
WRLONG   r1,             par1_Addr_    'Write r1 into HUB/par1
   
JMP      #Done         
'-------------------------------------------------------------------------


DAT 'RdRegs
'-------------------------------------------------------------------------
'---------------------------------┌────────┐------------------------------
'---------------------------------│ RdRegs │------------------------------
'---------------------------------└────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads 32-bit registers from FPU 
' Parameters: - Reg X    in HUB/par1
'             - Cntr     in HUB/par2
'             - floatPtr in HUB/par3
'    Results: Registers in HUB 
'+Reads/Uses: /par1_Addr_, par2_Addr_, par3_Addr_, _SELECTX, _RDBLK
'    +Writes: r1, r5, r6
'      Calls: #WaitForReady, #Write_Byte, #Read_Setup_Delay,
'             #Read_Register 
'-------------------------------------------------------------------------
RdRegs
 
'Set Reg[X] 
MOV      r1,             #_SELECTX     'Select Reg[X] command
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par1_Addr_    'Load X from par1
CALL     #Write_Byte                   'Write it to FPU

RDLONG   r5,             par2_Addr_    'Load Cntr from par2
RDLONG   r6,             par3_Addr_    'Load pointer to HUB/floats from p3 

CALL     #Wait_4_Ready                 'Before a read operation

'Send the RDBLK command
MOV      r1,             #_RDBLK
CALL     #Write_Byte
MOV      r1,             r5            'Send No. of registers to read
CALL     #Write_Byte

:Loop
CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Register                'Read register from FPU
WRLONG   r1,             r6            'Write register into HUB
ADD      r6,             #4  
DJNZ     r5,             #:Loop        'Get next register 
   
JMP      #Done           
'-------------------------------------------------------------------------


DAT 'RdString
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ RdString │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads String from the String Buffer of FPU 
' Parameters: None
'    Results: String in HUB/str 
'+Reads/Uses: /_READSTR
'    +Writes: r1
'      Calls: #Wait4Ready, #Write_Byte, #Read_Setup_Delay, #Read_String  
'-------------------------------------------------------------------------
RdString

'Send a _READSTR command to read the String Buffer from FPU
CALL     #Wait_4_Ready 
MOV      r1,             #_READSTR     'Send _READSTR          
CALL     #Write_Byte
CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_String                  'Now read String Buffer of FPU
                                       'into HUB RAM   
JMP      #Done       
'-------------------------------------------------------------------------


DAT '----------------------------PRI PASM code----------------------------
'Now come the "PRIVATE" PASM routines of this Driver. They are "PRI" in
'the sense that they do not have "command No." and they do not use par1,
'par2, etc.... They are service routines for the user accesable tasks.


DAT 'Wait_4_Ready
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ Wait_4_Ready │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Waits for a LOW DIO, i.e for a ready FPU with empty
'             instruction buffer
' Parameters: None
'    Results: None 
'+Reads/Uses: /dio_Mask, time, _Data_Period
'    +Writes: time, CARRY flag
'      Calls: None
'       Note: Prop is fast enough at 80 MHz to check DIO line before FPU
'             is able to rise it in response to a received command. That's
'             why a Data Period Delay is inserted before the check.
'-------------------------------------------------------------------------
Wait_4_Ready
                                     
ANDN     DIRA,           dio_Mask      'Set DIO pin as an INPUT

'Insert Data Period Delay 
MOV      time,           CNT           'Find the current time
ADD      time,           _Data_Period  '1.6 us Data Period Delay
WAITCNT  time,           #0            'Wait for 1.6 usec  

:Loop
TEST     dio_Mask,       INA WC        'Read SOUT state into 'C' flag
IF_C{
}JMP     #:Loop                        'Wait until DIO LOW

Wait_4_Ready_Ret
RET          
'-------------------------------------------------------------------------


DAT 'Write_Byte
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Write_Byte │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a byte to FPU 
' Parameters: Byte to send in Least Significant Byte of r1
'    Results: None 
'+Reads/Uses: /_Data_Period, dio_Mask
'    +Writes: time
'      Calls: #Shift_Out_Byte
'-------------------------------------------------------------------------
Write_Byte

'Wait for the Minimum Data Period
MOV      time,           CNT           'Find the current time
ADD      time,           _Data_Period  '1.6 us minimum data period
WAITCNT  time,           #0            'Wait for  1.6 us

CALL     #Shift_Out_Byte               'Write byte to FPU
   
Write_Byte_Ret
RET              
'-------------------------------------------------------------------------


DAT 'Write_Reg
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ Write_Reg │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a 32-bit value to FPU
' Parameters: 32-bit value in r4 to send (MSB first)
'    Results: None 
'+Reads/Uses: /_Byte_Mask
'    +Writes: r1
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
Write_Reg

'Send MS byte of r4
MOV      r1,             r4
ROR      r1,             #24
CALL     #Write_Byte

'Send 2nd byte of r4
MOV      r1,             r4
ROR      r1,             #16
CALL     #Write_Byte

'Send 3rd byte of r4
MOV      r1,             r4
ROR      r1,             #8
CALL     #Write_Byte

'Send LS byte of r4
MOV      r1,             r4
CALL     #Write_Byte
  
Write_Reg_Ret
RET              
'-------------------------------------------------------------------------


DAT 'Read_Setup_Delay
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Read_Setup_Delay │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Inserts 15 usec Read Setup Delay
' Parameters: None
'    Results: None
'+Reads/Uses: /_Read_Setup_Delay 
'    +Writes: time
'      Calls: None
'-------------------------------------------------------------------------
Read_Setup_Delay

MOV      time,           CNT                 'Find the current time
ADD      time,           _Read_Setup_Delay   '15 usec Read Setup Delay
WAITCNT  time,           #0                  'Wait for 15 usec
  
Read_Setup_Delay_Ret
RET              
'-------------------------------------------------------------------------


DAT 'Read_Byte
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ Read_Byte │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Reads a byte from FPU
' Parameters: None
'    Results: Entry in r1
'+Reads/Uses: /_Read_Byte_Delay
'    +Writes: time
'      Calls: #Shift_In_Byte
'-------------------------------------------------------------------------
Read_Byte

'Insert a 1 us Read byte Delay
MOV      time,           CNT               'Find the current time
ADD      time,           _Read_Byte_Delay  '1 us Read byte Delay
WAITCNT  time,           #0                'Wait for 1 usec       
  
CALL     #Shift_In_Byte                    'Read a byte from FPU
  
Read_Byte_Ret
RET              
'-------------------------------------------------------------------------


DAT 'Read_Register
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Read_Register │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 32-bit register form FPU
' Parameters: None
'    Results: Entry in r1
'+Reads/Uses: None
'    +Writes: r3
'      Calls: #Read_Byte
'       note: #Read_Byte's descendant uses r2
'-------------------------------------------------------------------------
Read_Register

'Collect FPU register in r3 
CALL     #Read_Byte
MOV      r3,             r1
CALL     #Read_Byte
SHL      r3,             #8
ADD      r3,             r1
CALL     #Read_Byte
SHL      r3,             #8
ADD      r3,             r1
CALL     #Read_Byte
SHL      r3,             #8
ADD      r3,             r1

MOV      r1,             r3            'Done. Copy sum from r3 into r1
  
Read_Register_Ret
RET              
'-------------------------------------------------------------------------


DAT 'Read_String
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Read_String │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Reads a zero terminated string from FPU into HUB memory
' Parameters: None
'    Results: Sring in HUB/str
'+Reads/Uses: /str_Addr_
'    +Writes: r1, r3
'      Calls: #Read_Byte
'       Note: Writes to HUB the terminating zero, as well
'-------------------------------------------------------------------------
Read_String

'Prepare loop to read string from FPU to HUB
MOV      r3,             str_Addr_
 
:Loop
CALL     #Read_Byte                    'Read a character from FPU
WRBYTE   r1,             r3            'Write character to HUB memory
CMP      r1,             #0 WZ         'String terminated if char is 0
                                       'If char not zero    
IF_NZ{
}ADD     r3,             #1            'Increment pointer to HUB memory 
IF_NZ{
}JMP     #:Loop                        'Jump to fetch next character 
  
Read_String_Ret
RET              
'-------------------------------------------------------------------------

DAT '---------------------------------SPI---------------------------------

DAT 'Shift_Out_Byte
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Shift_Out_Byte │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Shifts out a byte to FPU  (MSBFIRST)
' Parameters: Byte to send in r1
'    Results: None
'+Reads/Uses: /dio_Mask         
'    +Writes: r2, r3
'      Calls: #Clock_Pulse
'-------------------------------------------------------------------------
Shift_Out_Byte                               

OR       DIRA,           dio_Mask      'Set DIO pin as an OUTPUT 
MOV      r2,             #8            'Set length of byte         
MOV      r3,             #%1000_0000   'Set bit mask (MSBFIRST)
                                                               
:Loop
TEST     r1,             r3 WC         'Test a bit of data byte
MUXC     OUTA,           dio_Mask      'Set DIO HIGH or LOW
SHR      r3,             #1            'Prepare for next data bit  
CALL     #Clock_Pulse                  'Send a clock pulse
DJNZ     r2,             #:Loop        'Decrement r2; jump if not zero
         
Shift_Out_Byte_Ret
RET
'-------------------------------------------------------------------------


DAT 'Shift_In_Byte
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Shift_In_Byte │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Shifts in a byte from FPU (MSBPRE)
' Parameters: None
'    Results: Entry byte in r1
'+Reads/Uses: /dio_Mask 
'    +Writes: r2
'      Calls: #Clock_Pulse
'-------------------------------------------------------------------------
Shift_In_Byte
ANDN     DIRA,           dio_Mask      'Set DIO pin as an INPUT
MOV      r2,             #8            'Set length of byte
MOV      r1,             #0            'Clear r1   
          
:Loop
TEST     dio_Mask,       INA WC        'Read Data Bit into 'C' flag
RCL      r1,             #1            'Left rotate 'C' flag into r1  
CALL     #Clock_Pulse                  'Send a clock pulse   
DJNZ     r2,             #:Loop        'Decrement r2; jump if not zero

Shift_In_Byte_Ret        
RET              
'-------------------------------------------------------------------------


DAT 'Clock_Pulse
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Clock_Pulse │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a 50 ns LONG HIGH pulse to CLK pin of FPU
' Parameters: None
'    Returns: None 
'+Reads/Uses: /clk_Mask 
'    +Writes: None
'      Calls: None
'       Note: At 80_000_000 Hz the CLK pulse width is about 50 ns(4 ticks)
'             and the CLK pin is pulsed at the rate about 2.5 MHz. This
'             rate is determined by the cycle time of the loop containing
'             the "CALL #Clock_Pulse" instruction. You can make the rate a
'             bit faster using inline code instead of DJNZ in the shift
'             in/out routines. However, the overal data burst speed will
'             not increase that much since the necessary delays affect it,
'             as well. They should remain in the time sequence, of course.
'-------------------------------------------------------------------------
Clock_Pulse

OR       OUTA,           clk_Mask      'Set CLK Pin HIGH
ANDN     OUTA,           clk_Mask      'Set CLK Pin LOW

Clock_Pulse_Ret         
RET
'------------------------------------------------------------------------- 


DAT '-----------COG memory allocation defined by PASM symbols-------------
  
'-------------------------------------------------------------------------
'----------------------Initialized data for constants---------------------
'-------------------------------------------------------------------------
_Zero                LONG    0

'-------------------------Delays at 80_000_000 MHz------------------------
_Data_Period         LONG    128       '1.6 us Minimum Data Period  
_Reset_Delay         LONG    800_000   '10 ms Reset Delay
_Read_Setup_Delay    LONG    1_200     '15 us Read Setup Delay
_Read_Byte_Delay     LONG    80        '1 us Read byte Delay

'-------------------------------------------------------------------------
'---------------------Uninitialized data for variables--------------------
'-------------------------------------------------------------------------

'----------------------------------Pin Masks------------------------------
dio_Mask             RES     1         'Pin mask in Propeller for DIO
clk_Mask             RES     1         'Pin mask in Propeller for CLK

'----------------------------HUB memory addresses-------------------------
par1_Addr_           RES     1
par2_Addr_           RES     1
par3_Addr_           RES     1
par4_Addr_           RES     1
par5_Addr_           RES     1
str_Addr_            RES     1
time                 RES     1

'------------------------Recycled Temporary Registers---------------------
r1                   RES     1         
r2                   RES     1         
r3                   RES     1
r4                   RES     1
r5                   RES     1
r6                   RES     1          

FIT                  496               'For sure


DAT '----------------------------MIT License------------------------------


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