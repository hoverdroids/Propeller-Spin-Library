{This object goes onto the propeller that is not connected to the computer}
{DO NOT modify this because it works with FDSPSimpleReceive}

CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_000_000

        tx_pin=9'19'15
        rx_pin=10'18'14

VAR
  byte  myStr[10]
  byte i
   
OBJ
  comm      : "FullDuplexSerialPlus"
  debug     : "FullDuplexSerialPlus"
PUB main
debug.start(31,30,0,57600)
waitcnt(clkfreq*2+cnt)
comm.start(rx_pin,tx_pin,0,115200)
waitcnt(clkfreq*2+cnt)

dira[tx_pin]:=1

repeat strsize(str1)
  myStr[i++]:=str1[i]

repeat
  comm.str(@myStr)
  comm.str(string(13))                        '  
  waitcnt(clkfreq*2 + cnt)              'wait for other prop to catch up
DAT
 str1 byte "testing",0