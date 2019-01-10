{This object goes onto the propeller that is connected to the computer in order to output the received values to the screen}
{Also, DO NOT modify this program; it receives the correct byte from FDSPSimpleTransmit}

CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_000_000

        tx_pin=8'15'19
        rx_pin=9'14'18

        blinkPin=3

VAR
  byte  myRecString[10]
   
OBJ
  comm      : "FullDuplexSerialPlus"
  debug      :"FullDuplexSerialPlus"
  cogCounter : "COG_counter"
PUB main
dira[blinkPin]:=1

debug.start(31,30,0,57600)
waitcnt(clkfreq+cnt)

comm.start(rx_pin,tx_pin,0,115200)
waitcnt(clkfreq*5+cnt)

dira[tx_pin]:=1

debug.str(string("Starting communications",13))
debug.str(string(13))
debug.str(string("Number of Cogs:"))
debug.dec(cogCounter.free_cogs)
repeat
  repeat 4
   !outa[blinkPin]
   waitcnt(clkfreq/10+cnt)
  comm.getstr(@myRecString)
  debug.str(string("rx is: ",13))
  debug.str(@myRecString)
  debug.str(string(13))
  bytefill(@myRecString,0,10)
     
Dat
Str1    byte  "Testing",0        