{{
OBEX LISTING:
  http://obex.parallax.com/object/102

  Easily control several 74HC595 shift registers in series. Now includes a variation which leaves out the PWM feature and instead supports up to 100 chips! Still also includes the multi-PWM driver, which allows you to set PWM frequency and duty cycle for any or all of 32 outputs. The PWM driver remembers whether you've set an output to PWM or a steady high or low value, and manages the PWM outputs for you automatically. Also includes the version 1.0 Simple_74HC595 object for those who just want to understand how to shift data out to the 74HC595 chip.

  If you downloaded the version 2.0 or 2.1 driver, you should download and replace it with the new version 2.2 driver, which has some bugs fixed; see the release notes at the top of the 74HC595_MultiPWM.spin file for detailed information.
}}
CON
{{
        74HC595 Driver v1.0 March 2009
        Data output to up to 4 74HC595's in series
        
        Copyright Dennis Ferron 
        Contact:  dennis.ferron@gmail.com
        See end of file for terms of use

Summary:
        Easily control up to four 74HC595 shift registers in series (gives up to 32 outputs).
        An assembly language cog free-runs, continuously updating the shift registers.
        The handshake-free operation of this code is easy to understand and use.

Operation:        
        This driver works as simply as possible:  it reads the value in the ShiftData
        variable continuously (thousands of times a second) and shifts the 32 bits of
        data in the variable out to up to four 74HC595's.  There is no handshaking,
        no commands to pass to the assembly routine or waiting for output to finish.
        Just whatever bits you set in ShiftData will be set in the 74HC595 outputs.

        If you have less than four shift registers, don't worry; the driver will
        simply use however many you have.  The most significant bits will end up
        in the shift registers furthest out, while the least significant bits stay
        in the closest shift register.  For instance, if you have only two shift
        registers, bits 0 - 7 will be in the first stage, bits 8 - 15 will be
        output to the second stage, and bits 16 - 31 will just drop into nothingness.

        The order in which bits end up in the shift registers is the LSB of
        each byte will be in QA and the MSB will be in QH. 

Wiring:
        Different vendors name the pins of the '595 differently, making things very
        confusing.  Motorola's names are the most descriptive; the rest
        are ridiculous gobbledygook.  Here's a table of equivalent pin names:

                  Pins
        Vendor    14    13   12     11     10     9

        Phillips  Ds    /OE  STcp   SHcp   /MR    Q7'

        ST        SI    /G   RCK    SCK    /SCLR  QH'
        
        Motorola  A     Out. Latch  Shift  RESET  SQH
                        En.  Clock  Clock
        
        Propeller Data       Latch  Shift
        Pin name  Pin        Pin    Pin

        I've used Motorola's pin names in the following diagram:
                
                      ┌──────┐
                  QB  ┫1•  16┣  Vcc                 
                  QC  ┫2   15┣  QA                                
                  QD  ┫3   14┣─────────────────────────────── ← A (Data in from Propeller)              
                  QE  ┫4   13┣─────────────────────• Output Enable (Ground each one)            
                  QF  ┫5   12┣───────────────┐     ← Latch Clock         
                  QG  ┫6   11┣─────────────┐ │     ← Shift Clock 
                  QH  ┫7   10┣──────────────────┐  ← RESET 
                 gnd  ┫7    9┣───────┐ QH' │ │  │
                      └──────┘       │     │ │  │    Notes:
                                     │     │ │  │    • Propeller feeds data into "A" input of first stage.
                      ┌──────┐       │     │ │  │    • QH' from first stage feeds into A of next stage
                  QB  ┫1•  16┣  Vcc  │     │ │  │    • Tie all RESET, Latch Clock and Shift Clock pins together    
                  QC  ┫2   15┣  QA   │     │ │  │    • QA - QH are data outputs: Vcc = 1, gnd = 0                  
                  QD  ┫3   14┣───────┘ A   │ │  │             
                  QE  ┫4   13┣─────────────│─│──│───•  Output Enable (Ground each output enable)               
                  QF  ┫5   12┣─────────────│─┻──│───•  Latch Clock (to LatchPin from Propeller)                 
                  QG  ┫6   11┣─────────────┻────│───•  Shift Clock (to ClockPin from Propeller)
                  QH  ┫7   10┣──────────────────┻───•  RESET (to Vcc or to Propeller's Reset pin)
                 gnd  ┫7    9┣───────┐ Qh'
                      └──────┘       │
                                    to next 74HC595 Data in (pin 14)
                                     or leave disconnected if last one

        Note 1: This object doesn't use the output enables, so I have you ground them to leave
                them always on.  If you need output enable control, tie all the output enables
                together and then set the output enable in your own code as you need it.
                
        Note 2: When you program the Propeller, whatever outputs were 1 at the time the Propeller
                halted to accept its new program, will remain on for the duration of the download
                of the new program.  This can have bad consequences on a robot if, for instance,
                that 1 that was set is controlling a motor, and the motor continues to run.
                I haven't tried it, but it should be possible to connect the reset lines from
                all the 74HC595's to the reset line of the Propeller, so that when the Propeller
                programming tool (i.e. Prop Plug) resets the Propeller, it will also clear
                the shift registers and set their outputs to 0.

}}


VAR

  ' This block of variables is used to pass pin information to initialize
  ' the asm routine.  After initialization, ShiftData continues to
  ' function as the place to write a value to be picked up by the
  ' asm routine, which monitors ShiftData continuously.
  long ShiftData
  long ClockPin
  long LatchPin
  long DataPin

PUB init(clock_pin, latch_pin, data_pin)
{{ Launches the shift-out asm routine. }}

  ClockPin := clock_pin
  LatchPin := latch_pin
  DataPin  := data_pin
  cognew(@init_asm, @ShiftData)

PUB Out(data)
{{ Outputs value of data directly.
  Use this to set all the outputs to a known state at once. }}

  ShiftData := data

PUB What
{{  Returns the last data shifted out.
}}

  return ShiftData

PUB DataPtr
{{  Returns a pointer to the shiftdata variable, so it can be passed to an asm routine.
}}
  return @ShiftData

PUB High(bit_pos)
{{  Sets specified bit high.
}}

  ShiftData |= (1 << bit_pos)

PUB Low(bit_pos)
{{  Sets specified bit low.
}}

  ShiftData &= !(1 << bit_pos)

PUB SetBit(bit_pos, state)
{{  Sets specified bit to specified state.
}}

  if state
    High(bit_pos)
  else
    Low(bit_pos)

DAT

{{  Assembly language 74HC595 driver.  Runs continously.  }}

              org       0

init_asm
              mov       t1, par

              ' Get pin assignments and use to create
              ' masks for setting those pins.
              
              add       t1, #4                  ' Go to clock pin input
              rdlong    t2, t1                  ' Get clock pin
              mov       srclk, #1               ' Prepare srclk mask
              shl       srclk, t2               ' Move srclk mask into position

              add       t1, #4                  ' Go to latch pin input
              rdlong    t2, t1                  ' Get latch pin
              mov       srlatch, #1             ' Prepare srlatch mask
              shl       srlatch, t2             ' Move srlatch bit into position 

              add       t1, #4                  ' Go to data pin input
              rdlong    t2, t1                  ' Get data pin
              mov       srdata, #1              ' Prepare srdata mask
              shl       srdata, t2              ' Move srdata bit into position

              ' Set the direction bits for the pins.
              or        dira, srclk
              or        dira, srlatch
              or        dira, srdata

              ' Set Z flag so we can use muxz/muxnz to flip output bits.
              mov       t1, #0  wz

              muxnz     outa, srclk             ' Clock starts low

do_loop
              rdlong    val, par                ' Get value to shift out.

              muxnz     outa, srlatch           ' Latch starts low

              mov       count, #32               ' Shift 32 bits            
shift_bit
              shl       val, #1 wc              ' Consume a bit from val; store it in carry flag
              muxnz     outa, srclk             ' Make clock low
              muxc      outa, srdata            ' Output the consumed bit to the shift register
              nop                               ' Let data line settle (this nop is optional)
              muxz      outa, srclk             ' Clock high to latch bit of data
              djnz      count, #shift_bit       ' Do next bit

              muxz      outa, srlatch           ' Latch the data output

              jmp       #do_loop                ' Do it all over again. 

' Input parameters
val     res   1
srclk   res   1
srlatch res   1
srdata  res   1

' Scratch registers.
bit     res   1
t1      res   1        
t2      res   1
count   res   1

DAT

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
