{This object goes onto the propeller that is not connected to the computer}
{DO NOT modify this because it works with FDSPSimpleReceive}

CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_000_000

        tx_pin=9
        rx_pin=10

VAR
  byte  go
   
OBJ
  comm      : "FullDuplexSerialPlus"
  
PUB main

comm.start(rx_pin,tx_pin,0,115200)
waitcnt(clkfreq*2+cnt)

dira[tx_pin]:=1
go[0]:="A"
repeat
  comm.tx(go[0])                        'transmit sync number  
  waitcnt(clkfreq + cnt)              'wait for other prop to catch up