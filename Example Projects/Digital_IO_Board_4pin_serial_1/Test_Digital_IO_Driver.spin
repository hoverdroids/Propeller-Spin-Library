{{
OBEX LISTING:
  http://obex.parallax.com/object/441

  Control the Parallax Digital I/O Board via (SPI) serial connection with just 4 pins.
  Allows reading inputs and controlling relays using 1 cog. Controls the 74HC595 and 74HC165 IC
}}
'**************************************************************
'* Test_Digital_IO_Driver                                    
'*
'* Contains some examples of how to control the relays and
'* read the values on the inputes 
'**************************************************************
CON
    _clkmode = xtal1 + pll16x
    _clkfreq = 80_000_000
    
  PIN_DataIO  = 19     ' DIN & DATA_RLY
  PIN_Clock   = 18     ' SCLK_IN & SCLK_RLY
  PIN_HC595   = 17     'LAT_RLY
  PIN_HC165   = 16     'LOAD_IN
  
OBJ
 diob :        "74HC595_74HC165_4pinDriver" 'was DigitalIO4pinDriver
 pst :         "Parallax Serial Terminal"
 
VAR                                                            
  byte OUT_REG        'Setting the bits in this byte will turn the relays on and off
  byte IN_REG         'Contains the values of the 8 inputes
  
PUB main

  pst.start(115200)

  diob.start(PIN_DataIO, PIN_Clock, PIN_HC595, PIN_HC165, @IN_REG, @OUT_REG)
  OUT_REG:=%00000000  'Set All Relays to Off

  repeat
    waitcnt(2_000000 + cnt)    'Give some time for the Serial Terminal update
    pst.clear

    'Output the values of the inputs to the serial terminal
    pst.str(string("INPUT :"))
    pst.dec(diob.in(0))
    pst.dec(diob.in(1))
    pst.dec(diob.in(2))
    pst.dec(diob.in(3))
    pst.dec(diob.in(4))
    pst.dec(diob.in(5))
    pst.dec(diob.in(6))
    pst.dec(diob.in(7))
    
    OUT_REG:=%0000_1000 'Turn on Relay 3 and turn off all the other Relays
    
    diob.out(7,1) ' Turn Relay 8 on
    diob.out(6,0) ' Turn Relay 7 Off
     
    'Map IN1 Value to Relay 1 and 2    
    diob.out(0,diob.in(0))
    diob.out(1,diob.in(0))  
