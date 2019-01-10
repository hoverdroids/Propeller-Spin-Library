{This object goes onto the propeller that is connected to the computer in order to output the received values to the screen}
{Also, DO NOT modify this program; it receives the correct byte from FDSPSimpleTransmit}

CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_250_000

        tx_pin=19
        rx_pin=18

VAR
  byte  Fx[1]
   
OBJ
  comm      : "FullDuplexSerialPlus"
  debug      :"FullDuplexSerialPlus"
  
PUB main
debug.start(31,30,0,57600)
waitcnt(clkfreq*2+cnt)

comm.start(rx_pin,tx_pin,0,115200)
waitcnt(clkfreq*2+cnt)

dira[tx_pin]:=1

repeat
  comm.rxtime(1)                        'transmit sync number
  Fx[1]:=Comm.rx

  debug.str(string("receive value is: ",13))
  debug.str(@Fx[1])  
         