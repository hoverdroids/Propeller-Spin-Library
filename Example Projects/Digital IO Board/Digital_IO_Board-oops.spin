{{
This code controls the DIOB using a propeller
' =========================================================================
'
'   File...... DIOB Serial Test V1.0.spin
'   Purpose... Test Serial Control Of Digital I/O Board
'   Author.... Chris Sprague, Bulbinc
'   E-mail.... spragucm@gmail.com
'   Started... 11-6-2012
'   Revision History...
' =========================================================================
' -----[ Program Description ]---------------------------------------------

' Connect the I/O pins of your Propeller to the pins on the Digital I/O
' Board as referenced in the I/O definitions below.  Note that the Data
' and Clock lines are being shared.  This reduces the number of pins
' required for the serial interface.

' This program tests Serial I/O by stepping through the relays
' counting up from 0 to 255.  This causes the relays to switch on/off in
' a binary pattern.  During this time the status of inputs
' are displayed below the outputs.  A one (1) indicates the
' specified input/output is on while a zero (0) indicates it is off.

' /OE_RLY goes to VSS (ground)

' Try changing the position of the 3-pin jumper (JP1) below the 74HC165
' and observe the results.

There are several objectives:
1. When the main method in AIQBReceive gets a command over XBee for state change,
  the state needs to be set to the requested state
2. On startup and periodically thereafter, this object will be called to provide a reading
  of the current state-battery level and AC presence-in order to determine which relays
  are latched/unlatched.  when this is called for a reading, it will read the values at
  the present time and save them to vars in the main program
3. To fire the ball into the wheel and then retract the slider
4. When this is called to read the state it also determines whether or not the auxilliary
   chargers and aesthetic lights should be on
CHANGE:I think that the AC & battery level reads should be done by the main code; this
code should simply set the buses when called; this would mean that
the first three inputs to this object are needed but not the fourth;
how to use this same function for firing the ball without disturbing the power state?
I need to test the powering on of the secondary bus through a fire command; does AC
get interrupted or Prop2 reset? (i hope not since there are caps in everything)
}}


CON

        DATA_IO_PIN=12   ' DIN & DATA_RLY
        CLOCK_PIN=  13   ' SCLK_IN & SCLK_RLY
        HC595_PIN=  11   ' LAT_RLY Pin
        HC165_PIN=  10   ' LOAD_IN Pin

        ' SHIFTOUT Constants
        LSBFIRST = 0
        MSBFIRST = 1

         ' SHIFTIN Constants
        MSBPRE   = 0
        LSBPRE   = 1
        MSBPOST  = 2
        LSBPOST  = 3
        OnClock  = 4   ' Used for I2C

        cntMin     = 400      ' Minimum waitcnt value to prevent lock-up

VAR                          
  Byte index  'Index variable
  Byte optos  'Opto status byte
  long s, ms, us
  Byte DataIn[50]
  
PUB Main
s:= clkfreq                               ' Clock cycles for 1 s
ms:= clkfreq / 1_000                      ' Clock cycles for 1 ms
us:= clkfreq / 1_000_000                  ' Clock cycles for 1 us

outa[HC165_PIN]:=1 
dira[HC165_PIN]:=1 'shouldn't dira go first?

'-----[ Program Code ]----------------------------------------------------
'repeat
  'if fire==1
    'no need to set vars, just sample the state;how to measure non-input states?just use vars
    'since a reset would reset all states except for input states? auxpwr and chgpwr depend
    'on the input states, not on user input
    '1.Turn on relays to move forward
    '2.turn on power to move forward
    '3.turn off power when the slider reaches the front, as measured by the IR sensor
    '4.turn on relays to move backward
    '5.turn off power and movement relays when the slider reaches the back, as mesured by the IR sensor
    'index:=%00000000
  'elseif fire==0
    '1.if the machine is off and issued the off command, ignore command
    '2.if the machine is on and issued the on command, ignore command
    '3.if the machine is off and issued the on command, turn it on
    '4.if the machine is on and issued the off command, turn it off

    '1.if AC power is present
    repeat
      index:=%01010111'relaySet
      Out_595
  
  'In_165
  'index:=IND'%10100001'index+1 'RLY...87654321
  'waitcnt(clkfreq/2+cnt)

PUB Out_595

SHIFTOUT(DATA_IO_PIN,CLOCK_PIN,index,MSBFIRST,8)
PULSOUT(HC595_PIN,5)       'Latch outputs; for 5 uS?

'Out_595:
  'SHIFTOUT DataIO, Clock, MSBFIRST, [index]
  'PULSOUT HC595, 5                      ' Latch Outputs
  'RETURN
PUB In_165

PULSOUT(HC165_PIN,5)
optos:=SHIFTIN(DATA_IO_PIN,CLOCK_PIN,MSBPRE,8)

'In_165:
  'PULSOUT HC165, 5                      ' Load Inputs
  'SHIFTIN DataIO, Clock, MSBPRE, [optos]
  'RETURN
PUB SHIFTOUT (Dpin, Cpin, Value, Mode, Bits)| bitNum
{{
   Shift data out, master clock, for mode use ObjName#LSBFIRST, #MSBFIRST
   Clock rate is ~16Kbps.  Use at 80MHz only is recommended.
     BS2.SHIFTOUT(5,6,"B",BS2#LSBFIRST,8)
}}
    outa[Dpin]:=0                                          ' Data pin = 0
    dira[Dpin]~~                                           ' Set data as output
    outa[Cpin]:=0
    dira[Cpin]~~

    If Mode == LSBFIRST                                    ' Send LSB first    
       REPEAT Bits
          outa[Dpin] := Value                              ' Set output
          Value := Value >> 1                              ' Shift value right
          !outa[Cpin]                                      ' cycle clock
          !outa[Cpin]
          waitcnt(1000 + cnt)                              ' delay

    elseIf Mode == MSBFIRST                                ' Send MSB first               
       REPEAT Bits                                                                
          outa[Dpin] := Value >> (bits-1)                  ' Set output           
          Value := Value << 1                              ' Shift value right    
          !outa[Cpin]                                      ' cycle clock          
          !outa[Cpin]                                                             
          waitcnt(1000 + cnt)                              ' delay                
    outa[Dpin]~                                            ' Set data to low
PUB SHIFTIN (Dpin, Cpin, Mode, Bits) : Value | InBit
{{
   Shift data in, master clock, for mode use BS2#MSBPRE, #MSBPOST, #LSBPRE, #LSBPOST
   Clock rate is ~16Kbps.  Use at 80MHz only is recommended.
     X := BS2.SHIFTIN(5,6,BS2#MSBPOST,8)
}}
    dira[Dpin]~                                            ' Set data pin to input
    outa[Cpin]:=0                                          ' Set clock low 
    dira[Cpin]~~                                           ' Set clock pin to output 
                                                
    If Mode == MSBPRE                                      ' Mode - MSB, before clock
       Value:=0
       REPEAT Bits                                         ' for number of bits
          InBit:= ina[Dpin]                                ' get bit value
          Value := (Value << 1) + InBit                    ' Add to  value shifted by position
          !outa[Cpin]                                      ' cycle clock
          !outa[Cpin]
          waitcnt(1000 + cnt)                              ' time delay

    elseif Mode == MSBPOST                                 ' Mode - MSB, after clock              
       Value:=0                                                          
       REPEAT Bits                                         ' for number of bits                    
          !outa[Cpin]                                      ' cycle clock                         
          !outa[Cpin]                                         
          InBit:= ina[Dpin]                                ' get bit value                          
          Value := (Value << 1) + InBit                    ' Add to  value shifted by position                                         
          waitcnt(1000 + cnt)                              ' time delay                            
                                                                 
    elseif Mode == LSBPOST                                 ' Mode - LSB, after clock                    
       Value:=0                                                                                         
       REPEAT Bits                                         ' for number of bits                         
          !outa[Cpin]                                      ' cycle clock                          
          !outa[Cpin]                                                                             
          InBit:= ina[Dpin]                                ' get bit value                        
          Value := (InBit << (bits-1)) + (Value >> 1)      ' Add to  value shifted by position    
          waitcnt(1000 + cnt)                              ' time delay                           

    elseif Mode == LSBPRE                                  ' Mode - LSB, before clock             
       Value:=0                                                                                   
       REPEAT Bits                                         ' for number of bits                   
          InBit:= ina[Dpin]                                ' get bit value                        
          Value := (Value >> 1) + (InBit << (bits-1))      ' Add to  value shifted by position    
          !outa[Cpin]                                      ' cycle clock                          
          !outa[Cpin]                                                                             
          waitcnt(1000 + cnt)                              ' time delay

    elseif Mode == OnClock                                            
       Value:=0
       REPEAT Bits                                         ' for number of bits
                                        
          !outa[Cpin]                                      ' cycle clock
          waitcnt(500 + cnt)                               ' get bit value
          InBit:= ina[Dpin]                               ' time delay
          Value := (Value << 1) + InBit                    ' Add to  value shifted by position
          !outa[Cpin]
          waitcnt(500 + cnt)                           
PUB PULSOUT(Pin,Duration)  | clkcycles
{{
   Produces an opposite pulse on the pin for the duration in 2uS increments
   Smallest value is 10 at clkfreq = 80Mhz
   Largest value is around 50 seconds at 80Mhz.
     BS2.Pulsout(500)   ' 1 mS pulse
}}
  ClkCycles := (Duration * us * 2 - 1250) #> cntMin        ' duration * clk cycles for 2us
                                                           ' - inst. time, min cntMin
  dira[pin]~~                                              ' Set to output                                         
  !outa[pin]                                               ' set to opposite state
  waitcnt(clkcycles + cnt)                                 ' wait until clk gets there 
  !outa[pin]                                               ' return to orig. state     
    