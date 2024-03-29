{{
OBEX LISTING:
  http://obex.parallax.com/object/102

  Easily control several 74HC595 shift registers in series. Now includes a variation which leaves out the PWM feature and instead supports up to 100 chips! Still also includes the multi-PWM driver, which allows you to set PWM frequency and duty cycle for any or all of 32 outputs. The PWM driver remembers whether you've set an output to PWM or a steady high or low value, and manages the PWM outputs for you automatically. Also includes the version 1.0 Simple_74HC595 object for those who just want to understand how to shift data out to the 74HC595 chip.

  If you downloaded the version 2.0 or 2.1 driver, you should download and replace it with the new version 2.2 driver, which has some bugs fixed; see the release notes at the top of the 74HC595_MultiPWM.spin file for detailed information.
}}
CON
{{
        74HC595 MultiPWM Driver v2.2 March 2009
        PWM control on all outputs of up to four 74HC595's in series    
        
        Copyright Dennis Ferron 2009
        Contact:  dennis.ferron@gmail.com
        See end of file for terms of use

Summary:
        Set duty cycles for up to 32 outputs connected via 74HC595's.
        The intended use is to allow 3 Propeller pins to control many
        motor controllers via 754410 chips hooked up to the 74HC595's,
        although the object could also be used for other purposes as
        well, for instance controlling the brightness of 32 LED's.
        Outputs can also be set to a steady state instead of PWM.

Change Log:

        v2.2    Released 4/6/2009
                - Start routine now waits for init_asm to finish; before
                  the fix if you called Out, High, or Low too soon,
                  you could send a command before init_asm was done,
                  which changes the pins init_asm reads from the args.                                   

                - Added bounds checking on frequency and duty cycle:
                                Duty cycle < 0 limited to 0
                                Duty cycle > 100 limited to 100
                                Freq <= 0 turns off output

        v2.1    Released 4/2/2009
                - SetPWM now sets output to Low or High if duty cycle is 0% or 100%
                - Fixed bug which prevented PWM mask from working correctly before

        v2.0    Released 3/30/2009
                - Implemented multiPWM feature and command code based communication with cog.

        v1.0    Released 3/28/2009
                - Simple object; can set outputs high or low.        

Operation:
        Reads from an array of on-time / off-time parameters for 32 outputs.
        The on/off times are compared against the system counter, and will
        result in the corresponding bit of the '595 outputs flipping on and
        off at the duty cycle/frequency specified in the table.  The driver
        can also be used to simply turn outputs to a steady on or off; channels
        are masked as either PWM or steady state.

        Unlike the simpler plain 74HC595 driver, this driver uses command
        codes to set channel states, and waits for the command to be processed,
        so that you know that the state has been properly updated when the
        functions return.  There are functions for setting PWM state via
        clock ticks or frequency and duty cycle, and for querying the timings
        and the current state of all the outputs.

        The driver loops through and checks the 32 channels' timings one after another
        in a round robin fashion, and flips a bit on an internal variable if the time
        has expired for that particular slot.  (Channels set to steady state
        remain in the state until changed by a command or switched to PWM.)
        After calculating the next state of all of the 32 channels, the driver
        outputs the states to the 74HC595's.  This process repeats continuously
        many times per second.

        Timings are not clock-perfect, but will be within a few hundred clock
        cycles of the the desired timing.  At lower frequencies
        (hundreds to the low thousands of Hertz) the timing will be more
        than accurate enough for most purposes, especially motor control.

        If you have less than four shift registers, don't worry; the driver will
        simply use however many you have.

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

CON

  #1, _init, _getval, _settime, _gettime, _sethigh, _setlow, _setall


VAR

  ' This block of variables is used to pass pin information to initialize
  ' the asm routine.  After initialization, Command continues to
  ' function as the place to write a value to be picked up by the
  ' asm routine, which monitors Command continuously.
  long Command
  long Arg1
  long Arg2
  long Arg3

VAR
  ' Stores the value of the cog the driver is running in.
  long Cog
  
PUB Start(clock_pin, latch_pin, data_pin)
{{ Launches the shift-out asm routine. }}

  Stop

  Command := _init
  Arg1 := clock_pin
  Arg2 := latch_pin
  Arg3 := data_pin
  Cog := cognew(@init_asm, @Command) + 1

  ' v2.2: Bug fixed: Here we wait for init to finish, otherwise we
  ' might try to send another command and accidently change the pins specified! 
  repeat while Command
  
  return (Cog > 0)

PUB Stop
{{ Stops the shift-out asm routine. }}

  if Cog
    CogStop(Cog-1)
    Cog := 0
    

PUB What
{{ Returns what the driver last output to the shift registers.
}}

  Command := _getval
  repeat while Command
  return Arg2

PUB Out(value)
{{ Sets all outputs at once.  (Will halt any PWM in progress.)
    value is value to output to shift registers.
}}

  Arg2 := value
  Command := _setall
  repeat while Command

PUB SetTimes(channel, on_t, off_t)
{{ Sets on time and off time for a channel.
      channel is a 74HC595 output numbered 0 through 31
      on_t is a value measured in units of system clock ticks
      off_t is a value measured in units of system clock ticks
}}

  Arg1 := channel
  Arg2 := on_t
  Arg3 := off_t
  Command := _settime

  repeat while Command

PUB GetTimes(channel, p_on_t, p_off_t)
{{ Gets the current on and off time for a channel.
      channel is a 74HC595 output numbered 0 through 31
      p_on_time is the _address_ of a variable to store on time in
      p_off_time is the _address_ of a variable to store off time in

  Ex. usage:
      GetPWM(5, @MyOnTimeVar, @MyOffTimeVar)
}}

  Arg1 := channel

  Command := _gettime

  repeat while Command
  
  long[p_on_t] := Arg2
  long[p_off_t] := Arg3  

PUB SetPWM(channel, freq, duty) | total  

  ' v2.2 added:  Limit duty cycle 0% to 100%
  duty #>= 0
  duty <#= 100

  ' v2.2 added:  if freq == 0, turns off output.
  if duty == 0 or freq == 0
    Low(channel)
  elseif duty == 100
    High(channel)
  else
    total := clkfreq / freq
    Arg1 := channel
    Arg2 := duty * (total / 100)
    Arg3 := total - Arg2
    Command := _settime

    repeat while Command  

PUB High(channel)
{{  Sets specified channel always high.
}}

  Arg1 := channel
  Command := _sethigh

  repeat while Command

PUB Low(channel)
{{  Sets specified channel always low.
}}

  Arg1 := channel
  Command := _setlow

  repeat while Command

PUB SetBit(channel, state)
{{  Sets specified channel to specified state.
}}

  if state
    High(channel)
  else
    Low(channel)

DAT  {{  Assembly language 74HC595 PWM driver.  Runs continously.  }}

              org       0

DAT init_asm
              ' Get pin assignments and use to create
              ' masks for setting those pins.
              call      #read_args
              
              mov       srclk, #1               ' Prepare srclk mask
              shl       srclk, arg1_            ' Move srclk mask into position

              mov       srlatch, #1             ' Prepare srlatch mask
              shl       srlatch, arg2_          ' Move srlatch bit into position 

              mov       srdata, #1              ' Prepare srdata mask
              shl       srdata, arg3_           ' Move srdata bit into position

              ' Set the direction bits for the pins.
              or        dira, srclk
              or        dira, srlatch
              or        dira, srdata

              ' v2.2:  Clear command code to let start routine know we've got our pins.
              mov       cmd, #0
              wrlong    cmd, par

:do_loop
              call      #do_cmd                 ' Execute a command if one is present.

              mov       count, #32
:check_chnl
              ' Calculate channel number
              mov       chnl, #32               ' chnl starts at 0 when count is 32
              sub       chnl, count             ' chnl ends at 31 when count is 1

              ' Check whether this channel is configured for PWM
              mov       bit, #1
              shl       bit, chnl               ' Move bit to correct pos
              test      pwm_mask, bit wz        ' Check bit in mask
        if_z  jmp       #:skip_chnl             ' Skip if the channel is not PWM
              
              call      #check_time
:skip_chnl    djnz      count, #:check_chnl

              call      #shift_out
              jmp       #:do_loop               ' Do it all over again. 

              ' Never returns.

DAT read_args

              mov       arg1_, par
              add       arg1_, #(1*4)
              rdlong    arg1_, arg1_

              mov       arg2_, par
              add       arg2_, #(2*4)
              rdlong    arg2_, arg2_

              mov       arg3_, par
              add       arg3_, #(3*4)
              rdlong    arg3_, arg3_

read_args_ret ret


DAT shift_out
              ' Set Z flag so we can use muxz/muxnz to flip output bits.
              mov       t1, #0  wz

              mov       shiftout, out_states

              muxnz     outa, srlatch           ' Latch starts low

              mov       count, #32               ' Shift 32 bits            
:shift_bit
              shl       shiftout, #1 wc         ' Consume a bit from val; store it in carry flag
              muxnz     outa, srclk             ' Make clock low
              muxc      outa, srdata            ' Output the consumed bit to the shift register
              nop                               ' Let data line settle (this nop is optional)
              muxz      outa, srclk             ' Clock high to latch bit of data
              djnz      count, #:shift_bit      ' Do next bit

              muxz      outa, srlatch           ' Latch the data output

shift_out_ret ret

DAT check_time

              ' Figure out whether we're looking at on time or off time
              mov       bit, #1
              shl       bit, chnl
              test      bit, out_states wz

              ' Use on time or off time table depending on what the value of the bit is
        if_nz mov       t1, #on_time
        if_z  mov       t1, #off_time

              add       t1, chnl
              movs      :s_read_time, t1
              nop
:s_read_time  mov       t1, 0

              ' Get the last time the output was changed
              mov       t2, #last_time
              add       t2, chnl
              movs      :s_read_last, t2
              nop
:s_read_last  mov       t2, 0

              ' Find the difference between the current time and the last time
              mov       t3, cnt
              sub       t3, t2

              ' Is the difference greater than the allowed on/off time?
              cmp       t3, t1 wc, wz
        if_b  jmp       #check_time_ret         ' Skip the rest if the time hasn't expired

              ' If the time has expired, flip the bit and record our time
              xor       out_states, bit

              ' Store the new last time value
              mov       t3, #last_time
              add       t3, chnl
              movd      :d_store_last, t3
              nop
:d_store_last mov       0, cnt

check_time_ret ret

DAT do_cmd
              rdlong    cmd, par wz             ' Get command code if present
        if_z  jmp       #do_cmd_ret             ' No command code, return

              call      #read_args
        
              ' Get channel
              mov       chnl, arg1_

              cmp       cmd, #_getval wz
        if_e  call      #report_val
              
              cmp       cmd, #_settime wz
        if_e  call      #store_times

              cmp       cmd, #_gettime wz
        if_e  call      #read_times

              cmp       cmd, #_sethigh wz
        if_e  call      #set_high

              cmp       cmd, #_setlow wz
        if_e  call      #set_low

              cmp       cmd, #_setall wz
        if_e  call      #set_all

              ' Clear command code
              mov       cmd, #0
              wrlong    cmd, par 

do_cmd_ret    ret

DAT set_high

              mov       bit, #1 wz              ' Create bit mask and clear zero flag
              shl       bit, chnl               ' Move bit mask into position
              muxnz     out_states, bit         ' Set bit in out_states
              muxz      pwm_mask, bit           ' Clear bit in pwm_mask
              
set_high_ret  ret

DAT set_low

              mov       bit, #1 wz              ' Create bit mask and clear zero flag
              shl       bit, chnl               ' Move bit mask into position
              muxz      out_states, bit         ' Clear bit in out_states
              muxz      pwm_mask, bit           ' Clear bit in pwm_mask
              
set_low_ret   ret

DAT set_all
              mov       pwm_mask, #0            ' Turn off all PWM
              mov       out_states, arg2_       ' Set all outputs

set_all_ret   ret


DAT report_val

              mov t1, par
              add t1, #(2*4)
              wrlong out_states, t1

report_val_ret ret

DAT read_times

              ' Read the current on time
              mov       t3, #on_time
              add       t3, chnl
              movs      :s_read_on, t3
              nop
:s_read_on    mov       t3, 0

              mov       t1, par
              add       t1, #(2*4)              ' Point t1 at on-time (parameter 4)
              wrlong    t3, t1                  ' Write on time back to parameter

              ' Read the current off time
              mov       t3, #(off_time)
              add       t3, chnl
              movs      :s_read_off, t3
              nop
:s_read_off   mov       t3, 0

              mov       t2, par
              add       t2, #(3*4)              ' Point t2 at off-time (parameter 5)
              wrlong    t3, t2                  ' Write off time back to parameter

read_times_ret ret

DAT store_times
              
              ' Store the new on time
              mov       t3, #on_time
              add       t3, chnl
              movd      :d_store_on, t3
              nop
:d_store_on   mov       0, arg2_

              ' Store the new off time
              mov       t3, #off_time 
              add       t3, chnl
              movd      :d_store_off, t3
              nop
:d_store_off  mov       0, arg3_              

              ' Enable this channel for PWM
              mov       bit, #1
              shl       bit, chnl
              or        pwm_mask, bit

store_times_ret ret


DAT ' Asm Variables

' PWM configuration
pwm_mask      long      0

' Output states
out_states    long      0

' Command and argument values
cmd     res   1
arg1_   res   1
arg2_   res   1
arg3_   res   1

' Input parameters
srclk   res   1
srlatch res   1
srdata  res   1

shiftout res  1

' Scratch registers.
bit     res   1
t1      res   1        
t2      res   1
t3      res   1
count   res   1
chnl    res   1

' PWM timing tables
last_time     res 32
on_time       res 32
off_time      res 32

DAT ' License

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
