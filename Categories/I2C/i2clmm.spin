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
┌──────────────────────────────────────────┐
│ LMM I2C Driver 1.0                       │
│ Author: Tim Moore                        │
│ Copyright (c) June 2010 Tim Moore        │
│ See end of file for terms of use.        │
└──────────────────────────────────────────┘

  Started from Dave Hein pasm_i2c_driver

  Assumes pull-ups on both SCL and SDA

  Supports slave clock stretching

  Clock speed is 400KHz
}}
CON
'i2c funtions available
SETUP           = 0                                     'get i2ctable, i2cscl, device address from stack and setup scl/sda masks
START           = 4                                     'i2c start
RESTART         = 8                                     'i2c restart
STOP            = 12                                    'i2c stop
READ            = 16                                    'i2c read byte
WRITE           = 20                                    'i2c write byte
WRITEADDR       = 24                                    'write address byte, if write do a start first, else do a restart first
READWORD        = 28                                    'read word lsb 1st and sign extend to 32bits
READWORDR       = 32                                    'read word msb 1st and sign extend to 32bits
WRITEMBYTE      = 36                                    'write bytes
READREGHEADER   = 40                                    'write read register header

OBJ
  lmm         : "SpinLMM"

PUB GetOffsets
  return @I2CFunctions

DAT
I2CFunctions            long @@@i2csetup
                        long @@@startfunc
                        long @@@restartfunc
                        long @@@stopfunc
                        long @@@readbytefunc
                        long @@@writebytefunc
                        long @@@writeaddrfunc
                        long @@@readwordfunc
                        long @@@readwordrfunc
                        long @@@writemultiple
                        long @@@readregheaderfunc

i2csetup                sub     lmm#dcurr,#4
                        rdlong  lmm#reg8,lmm#dcurr          'scl
                        sub     lmm#dcurr,#4
                        rdlong  lmm#a,lmm#dcurr             '_deviceAddress

                        mov     lmm#reg9, #1
                        shl     lmm#reg9, lmm#reg8          'sclbit
                        mov     lmm#reg10, #1
                        shl     lmm#reg10, lmm#reg8
                        shl     lmm#reg10, #1                'sdabit
                        mov     lmm#lmm_pc, lmm#lmm_ret

                        ' reg9 is scl
                        ' reg10 is sda
                        ' y is ret address
                        ' x used by delay
                        ' reg1 used by delay
startfunc               mov     lmm#y, lmm#lmm_ret
                        andn    dira, lmm#reg9              ' Set SCL high
                        andn    outa, lmm#reg9              ' SCL pin low when output
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        andn    dira, lmm#reg10             ' Set SDA high
                        andn    outa, lmm#reg10             ' SDA pin low when output
                        add     lmm#lmm_pc, #20             ' skip 5 instructions

                        ' reg9 is scl
                        ' reg10 is sda
                        ' y is ret address
                        ' x used by delay
                        ' reg1 used by delay
restartfunc             mov     lmm#y, lmm#lmm_ret
                        andn    dira, lmm#reg10             ' Set SDA high
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        andn    dira, lmm#reg9              ' Set SCL high
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        or      dira, lmm#reg10             ' Set SDA LOW
                        jmp     #lmm#fcall
                        long    @@@delays1
                        or      dira, lmm#reg9              ' Set SCL LOW
                        jmp     #lmm#fcall
                        long    @@@delays1
                        mov     lmm#lmm_pc, lmm#y

                        ' reg9 is scl
                        ' reg10 is sda
                        ' reg11 is address byte
                        ' reg12 is shifted data
                        ' reg13 is bit counter
                        ' reg14 is ack bit
                        ' op2 is ret address
                        ' y is used by start/restart/writebyte
                        ' x used by delay
                        ' reg8 used by delay
                        ' if bit 0 is 0 do i2c start
                        ' else do i2c restart
writeaddrfunc           mov     lmm#op2, lmm#lmm_ret
                        test    lmm#reg11, #%01     wc
        if_nc           jmp     #lmm#fcall
                        long    @@@startfunc
        if_c            jmp     #lmm#fcall
                        long    @@@restartfunc

                        jmp     #lmm#fcall
                        long    @@@writebytefunc

                        mov     lmm#lmm_pc, lmm#op2

                        ' reg9 is scl
                        ' reg10 is sda
                        ' y is ret address
                        ' x used by delay
                        ' reg1 used by delay
stopfunc                andn    dira, lmm#reg9              ' Set SCL HIGH
                        andn    dira, lmm#reg10             ' Set SDA HIGH
                        mov     lmm#lmm_pc, lmm#lmm_ret

                        ' x ret address
delays                  nop                                 'note each instruction is really 32 clocks
delays1                 nop
                        mov     lmm#lmm_pc, lmm#lmm_ret

                        ' reg9 is scl
                        ' reg10 is sda
                        ' reg11 is input byte
                        ' reg12 is shifted data
                        ' reg13 is bit counter
                        ' reg14 is ack bit
                        ' y is ret address
                        ' x used by delay
                        ' reg1 used by delay
writebytefunc           mov     lmm#y, lmm#lmm_ret
                        mov     lmm#reg12, lmm#reg11        ' Get the data byte
                        mov     lmm#reg13, #8               ' Set loop count for 8 bits

wloop                   shl     lmm#reg12, #1               ' Shift left one bit
                        test    lmm#reg12, #$100   wc       ' Check MSB
                        muxnc   dira, lmm#reg10             ' Set SDA HIGH if not zero
                        jmp     #lmm#fcall
                        long    @@@delays
                        andn    dira, lmm#reg9              ' Set SCL HIGH
                        jmp     #lmm#fcall
                        long    @@@delays
                        or      dira, lmm#reg9              ' Set SCL LOW
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        djnz    lmm#reg13, #lmm#fjmp
                        long    @@@wloop

                        andn    dira, lmm#reg10             ' Set SDA high/input
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        andn    dira, lmm#reg9              ' Set SCL HIGH
waitlow3                test    lmm#reg9, ina    wc
        if_nc           jmp     #lmm#fjmp
                        long    @@@waitlow3
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        test    lmm#reg10, ina   wc         ' Check SDA input
                        rcl     lmm#reg14, #1               ' Set to zero if LOW, 1 if HIGH
                        or      dira, lmm#reg9              ' Set SCL LOW
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        or      dira, lmm#reg10             ' Set SDA low
                        mov     lmm#lmm_pc, lmm#y

                        ' reg9 is scl
                        ' reg10 is sda
                        ' reg11 is output byte
                        ' reg12 is shifted data
                        ' reg13 is bit counter
                        ' reg14 is ack bit
                        ' y is ret address
                        ' x used by delay
                        ' reg1 used by delay
readbytefunc            mov     lmm#y, lmm#lmm_ret
                        mov     lmm#reg12, #0               ' Initialize data byte to zero
                        andn    dira, lmm#reg10             ' Set SDA high
                        mov     lmm#reg13, #8               ' Set loop count for 8
rloop                   nop
                        nop
                        andn    dira, lmm#reg9              ' Set SCL HIGH/input
waitlow                 nop
                        nop
                        test    lmm#reg10, ina   wc
                        rcl     lmm#reg12, #1               ' shift left 1 bit and set LSB if input bit is HIGH
                        or      dira, lmm#reg9              ' Set SCL LOW
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        djnz    lmm#reg13, #lmm#fjmp
                        long    @@@rloop

                        rcr     lmm#reg14, #01   wc         ' get ack
                        muxnc   dira, lmm#reg10             ' Set SDA as output
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        andn    dira, lmm#reg9              ' Set SCL HIGH
waitlow2                nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        test    lmm#reg9, ina    wc
        if_nc           jmp     #lmm#fjmp
                        long    @@@waitlow2
                        or      dira, lmm#reg9              ' Set SCL LOW
                        nop                                 ' 32 + 16 -> 48 (0.6us @80MHz)
                        jmp     #lmm#lmm_loop
                        or      dira, lmm#reg10             ' Set SDA LOW
                        mov     lmm#reg11, lmm#reg12        ' Return the data byte
                        mov     lmm#lmm_pc, lmm#y

                        ' reg9 is scl
                        ' reg10 is sda
                        ' reg11 is output byte
                        ' reg12 is shifted data
                        ' reg13 is bit counter
                        ' reg14 is ack bit
                        ' reg17 is sign extended output
                        ' op2 is ret address
                        ' t2 flag for reverse or not
                        ' y is used by start/restart/writebyte
                        ' x used by delay
                        ' reg1 used by delay
                        ' changes c but not z flags
readwordrfunc           mov     lmm#t2, #1

                        add     lmm#lmm_pc, #4              'skip next instruction

                        ' reg9 is scl
                        ' reg10 is sda
                        ' reg11 is output byte
                        ' reg12 is shifted data
                        ' reg13 is bit counter
                        ' reg14 is ack bit
                        ' reg17 is sign extended output
                        ' t2 flag for reverse or not
                        ' op2 is ret address
                        ' y is used by start/restart/writebyte
                        ' x used by delay
                        ' reg1 used by delay
readwordfunc            mov     lmm#t2, #0

                        mov     lmm#op2, lmm#lmm_ret

                        jmp     #lmm#fcall
                        long    @@@readbytefunc

                        mov     lmm#reg17, lmm#reg11        'save and shift

                        jmp     #lmm#fcall                  'read with ACL
                        long    @@@readbytefunc

                        cmp     lmm#t2, #1        wc
        if_nc           shl     lmm#reg17, #8
        if_c            shl     lmm#reg11, #8
                        or      lmm#reg17, lmm#reg11        'merge with previous read
                        shl     lmm#reg17, #16
                        sar     lmm#reg17, #16              'sign extend from 16 to 32

                        and     lmm#reg14, #$1ff
                        cmp     lmm#reg14, #$01   wc

        if_c            jmp     #lmm#fcall
                        long    @@@stopfunc

                        mov     lmm#lmm_pc, lmm#op2

                        ' reg9 is scl
                        ' reg10 is sda
                        ' reg11 is output bytes
                        ' reg12 is shifted data
                        ' reg13 is bit counter
                        ' reg14 is ack bit
                        ' reg15 is bytes to send and stop
                        ' op2 is ret address
                        ' y is used by start/restart/writebyte
                        ' x used by delay
                        ' reg1 used by delay
writemultiple           mov     lmm#op2, lmm#lmm_ret

writenextbyte           jmp     #lmm#fcall
                        long    @@@writebytefunc
                        shr     lmm#reg11, #8           'next byte

                        shr     lmm#reg15, #1   wc      'end of bytes
        if_nc           sub     lmm#lmm_pc, #20         'writenextbyte

                        shr     lmm#reg15, #1   wc      'stop?
        if_c            jmp     #lmm#fcall
                        long    @@@stopfunc

                        mov     lmm#lmm_pc, lmm#op2

                        ' reg9 is scl
                        ' reg10 is sda
                        ' reg11 is address byte
                        ' reg12 is shifted data
                        ' reg13 is bit counter
                        ' reg14 is ack bit
                        ' reg15 is byte to send
                        ' op is ret address
                        ' op2 is used by writeaddr
                        ' y is used by start/restart/writebyte
                        ' x used by delay
                        ' reg1 used by delay
readregheaderfunc       mov     lmm#op, lmm#lmm_ret

                        mov     lmm#reg14, #0           'init ack status
                        mov     lmm#reg11, lmm#a        'i2c address
                        jmp     #lmm#fcall
                        long    @@@writeaddrfunc

                        mov     lmm#reg11, lmm#reg15
                        jmp     #lmm#fcall
                        long    @@@writebytefunc

                        mov     lmm#lmm_ret, lmm#op     'return directly from writeaddrfunc

                        mov     lmm#reg11, lmm#a        'i2c address with read bit set
                        or      lmm#reg11, #1
                        jmp     #lmm#fjmp
                        long    @@@writeaddrfunc
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
