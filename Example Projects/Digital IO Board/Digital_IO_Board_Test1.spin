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
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

        DATA_IO_PIN=12   ' DIN & DATA_RLY
        CLOCK_PIN=  13   ' SCLK_IN & SCLK_RLY
        HC595_PIN=  11   ' LAT_RLY Pin
        HC165_PIN=  10   ' LOAD_IN Pin

        Yes=1 '? 
        No= 0 '?

        MSBFIRST=BS2_Functions#MSBFIRST

VAR
  Byte index  'Index variable
  Byte optos  'Opto status byte
   
OBJ
  BS2_Functions      : "BS2_Functions"
  
PUB Main
'Don't forget to start -Needed for timing:
BS2_Functions.Start(31,30)
'--[Initialization]------------------------
'DEBUG CLS 'code from BS2; not used here; it may be required when clearing the terminl screen?
outa[HC165_PIN]:=1 'make this pin an output
dira[HC165_PIN]:=1 'set this pin to high; why?

'-----[ Program Code ]----------------------------------------------------
repeat
  Out_595
  In_165
  index:=index+1 '%10100001 'RLY...87654321
  waitcnt(clkfreq/2+cnt)
  

  'DO
    'GOSUB Out_595                       ' Update 74HC595
    'DEBUG HOME, "       76543210", CR
    'DEBUG "RELAYS:", BIN8 index, CR     ' Display Current Output States
    'GOSUB In_165                        ' Read 74HC165
    'DEBUG "INPUTS:", BIN8 optos         ' Display Current Input States
    'index = index + 1                   ' Increment Counter
    'PAUSE 500                           ' Small Delay (1/2 Second)
  'LOOP
  'STOP


PUB Out_595

BS2_Functions.SHIFTOUT(DATA_IO_PIN,CLOCK_PIN,index,MSBFIRST,8)
BS2_Functions.PULSOUT(HC595_PIN,5)       'Latch outputs; for 5 uS?

'Out_595:
  'SHIFTOUT DataIO, Clock, MSBFIRST, [index]
  'PULSOUT HC595, 5                      ' Latch Outputs
  'RETURN
PUB In_165

BS2_Functions.PULSOUT(HC165_PIN,5)
optos:=BS2_Functions.SHIFTIN(DATA_IO_PIN,CLOCK_PIN,BS2_Functions#MSBPRE,8)

'In_165:
  'PULSOUT HC165, 5                      ' Load Inputs
  'SHIFTIN DataIO, Clock, MSBPRE, [optos]
  'RETURN