{{RC_Receiver.spin
-----------------------------------------------------------------------------------------------
Read servo control pulses from a generic R/C receiver, handling up to 8 pins/channels
Use 4.7K resistors (or 4050 buffers) between each Propeller input and receiver signal output.

                   +5V
   ┌──────────────┐│     4.7K
 ──┤   R/C     [] ┣┼──────────• P[0..7] Propeller input(s) 
 ──┤ Receiver  [] ┣┘    Signal
 ──┤Channel(s) [] ┣┐
   └──────────────┘│
                   GND(VSS)

 Note: +5 and GND on all the receiver channels are usally interconnected,
 so to power the receiver only one channel need to be connected to +5V and GND.
-----------------------------------------------------------------------------------------------

The getrc function was modified to return values centered at zero instead of 1500.

Timmoore
  Modified to support 8 contiguous pins on any pin
  Support failsafe on channel 2 - check if RC pulses and added getstatus
}}
Con
  Mhz    = (80+10)                                      ' System clock frequency in Mhz. + init instructions
   
VAR
  long  Cog
  long  Pins[8]
  long  Status
  long  PinShift                                          
  long  PinMask
  long  delay

PUB setpins(_pinmask)
'' Set pinmask for active input pins [0..31]
'' Example: setpins(%0010_1001) to read from pin 0, 3 and 5
  Status := 0
  PinMask := _pinmask
  PinShift := 0
  repeat 32
    if _pinmask & 1
      quit
    _pinmask >>= 1
    PinShift++ 

PUB start : sstatus
'' Start driver (1 Cog)  
'' - Note: Call setpins() before start
  delay := clkfreq/10
  Status := 0
  if not Cog
    repeat sstatus from 0 to 7
      Pins[sstatus] := (clkfreq/1_000_000) * 1500       ' Center Pins[1..7]
    sstatus := Cog := cognew(@INIT, @Pins) + 1

PUB stop
'' Stop driver and release cog
  if Cog
    cogstop(Cog~ - 1)

PUB getraw(_pin) : value                                ' Get pulse width in clock tics
    value := Pins[_pin]
    
PUB get(_pin) : value
'' Get receiver servo pulse width in µs. 
  value := Pins[_pin]                                   ' Get puls width from Pins[..]
  value /= (clkfreq / 1_000_000)                        ' Pulse width in usec.

PUB getrc(_pin) : value
'' Get receiver servo pulse width as normal r/c values (±500) 
  value := Pins[_pin]                                  ' Get puls width from Pins[..]
  value /= (clkfreq / 1_000_000)                        ' Pulse width in µsec.
  value -= 1500                                        ' Make 0 center

PUB getstatus
  return Status

DAT
        org   0

INIT    mov   p1, par                           ' Get data pointer
        add   p1, #4*9                          ' Point to PinMask
        rdlong shift, p1                        ' Read PinMask
        add   p1, #4
        rdlong pin_mask, p1                     ' Read PinMask
        andn  dira, pin_mask                    ' Set input pins
        add   p1, #4
        rdlong edelay, p1                       ' Read PinMask
        mov   pe2, cnt
        sub   pe2, edelay

'=================================================================================

:loop   mov   d2, d1                            ' Store previous pin status
        waitpne d1, pin_mask                    ' Wait for change on pins
        mov   d1, ina                           ' Get new pin status 
        mov   c1, cnt                           ' Store change cnt                           
        and   d1, pin_mask                      ' Remove unrelevant pin changes
        shr   d1, shift                         ' Get relevant pins in 8 LSB
{
d2      1100
d1      1010
-------------
!d2     0011
&d1     1010
=       0010 POS edge

d2      1100
&!d1    0101
=       0100 NEG edge     
}
        ' Mask for POS edge changes
        mov   d3, d1
        andn  d3, d2

        ' Mask for NEG edge changes
        andn  d2, d1

'=================================================================================

:POS    tjz  d3, #:NEG                          ' Skip if no POS edge changes
'Pin 0
        test  d3, #%0000_0001   wz              ' Change on pin?
if_nz   mov   pe0, c1                           ' Store POS edge change cnt
'Pin 1
        test  d3, #%0000_0010   wz              ' ...
if_nz   mov   pe1, c1
'Pin 2
        test  d3, #%0000_0100   wz
if_nz   mov   pe2, c1
'Pin 3
        test  d3, #%0000_1000   wz
if_nz   mov   pe3, c1
'Pin 4
        test  d3, #%0001_0000   wz
if_nz   mov   pe4, c1
'Pin 5
        test  d3, #%0010_0000   wz
if_nz   mov   pe5, c1
'Pin 6
        test  d3, #%0100_0000   wz
if_nz   mov   pe6, c1
'Pin 7
        test  d3, #%1000_0000   wz
if_nz   mov   pe7, c1

'=================================================================================

:NEG    tjz   d2, #:loop                        ' Skip if no NEG edge changes
'Pin 0
        mov   p1, par                           ' Get data pointer
        test  d2, #%0000_0001   wz              ' Change on pin 0?
if_nz   mov   d4, c1                            ' Get NEG edge change cnt
if_nz   sub   d4, pe0                           ' Get pulse width
if_nz   wrlong d4, p1                           ' Store pulse width
'Pin 1
        add   p1, #4                            ' Get next data pointer
        test  d2, #%0000_0010   wz              ' ...
if_nz   mov   d4, c1              
if_nz   sub   d4, pe1             
if_nz   wrlong d4, p1             
'Pin 2
        add   p1, #4
        test  d2, #%0000_0100   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe2             
if_nz   wrlong d4, p1             
if_nz   mov   stat, #1                          ' RC transmitter should be on to get a pulse
'Pin 3
        add   p1, #4
        test  d2, #%0000_1000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe3             
if_nz   wrlong d4, p1             
'Pin 4
        add   p1, #4
        test  d2, #%0001_0000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe4             
if_nz   wrlong d4, p1             
'Pin 5
        add   p1, #4
        test  d2, #%0010_0000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe5             
if_nz   wrlong d4, p1             
'Pin 6
        add   p1, #4
        test  d2, #%0100_0000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe6             
if_nz   wrlong d4, p1
'Pin 7
        add   p1, #4
        test  d2, #%1000_0000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe7             
if_nz   wrlong d4, p1

        add   p1, #4
        wrlong stat, p1                         'write current RC transmitter status

        test  d2, #%0000_0100   wz              ' Change on pin 2?

if_nz   jmp   #:loop

        mov   c1, pe2                           ' time of last +ve edge
        add   c1, edelay
        sub   c1, cnt
        cmps  c1, #0 wc
if_c    mov   stat, #0                          ' no pulse for edelay so note no RC transmitter
        jmp   #:loop

fit Mhz                                         ' Check for at least 1µs resolution with current clock speed

'=================================================================================

pin_mask long %0000_0000
shift   long  0
edelay  long  0
stat    long  0

c1      long  0
               
d1      long  0
d2      long  0
d3      long  0
d4      long  0

p1      long  0

pe0     long  0
pe1     long  0
pe2     long  0
pe3     long  0
pe4     long  0
pe5     long  0
pe6     long  0
pe7     long  0

        FIT   496