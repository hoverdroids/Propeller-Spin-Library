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
}}


CON
        '_clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        '_xinfreq = 5_000_000

        DATA_IO_PIN=12   ' DIN & DATA_RLY
        CLOCK_PIN=  13   ' SCLK_IN & SCLK_RLY
        HC595_PIN=  11   ' LAT_RLY Pin
        HC165_PIN=  10   ' LOAD_IN Pin

        Yes=1 '? 
        No= 0 '?

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
  long s, ms, us,Last_Freq,Last_FreqB
  Byte DataIn[50],DEBUG_PIN,DEBUGIN_PIN
  
PUB Main(IND)
s:= clkfreq                               ' Clock cycles for 1 s
ms:= clkfreq / 1_000                      ' Clock cycles for 1 ms
us:= clkfreq / 1_000_000                  ' Clock cycles for 1 us
'--[Initialization]------------------------
'DEBUG CLS 'code from BS2; not used here; it may be required when clearing the terminl screen?
outa[HC165_PIN]:=1 'make this pin an output
dira[HC165_PIN]:=1 'set this pin to high; why?

'-----[ Program Code ]----------------------------------------------------
'repeat
  index:=IND'%10101011   'IND'%10100001'index+1 'RLY...87654321
  Out_595
  In_165
  'repeat
  'waitcnt(clkfreq/2+cnt)

  'the following if loop is meant to simplify coding for reading AC presence; if ever there is a need
  'to read more input on the DIOB than AC Presence,this will need to be removed and the main loop modified
  if optos== %00000010
    optos:=1
  else
    optos:=0
  return optos 'chris added

PUB Out_595

SHIFTOUT(DATA_IO_PIN,CLOCK_PIN,index,MSBFIRST,8)
PULSOUT(HC595_PIN,5)       'Latch outputs; for 5 uS?

PUB In_165

PULSOUT(HC165_PIN,5)
optos:=SHIFTIN(DATA_IO_PIN,CLOCK_PIN,MSBPRE,8)

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
    