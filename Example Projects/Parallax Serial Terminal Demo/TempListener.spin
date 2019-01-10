{Object_Title_and_Purpose}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_250_000
        tx_pin=15
        rx_pin=14

VAR
  byte  lightValue[2]
  byte  myStr[30]        'the string from Prop1
   
OBJ
  comms      : "FullDuplexSerialPlus"
  debug      : "FullDuplexSerialPlus"
  
  
PUB Main
dira[0..28]:=0
dira[18]:=1
dira[tx_pin]:=1
lightValue[1]:=0
debug.start(31,30,0,57600)
waitcnt(clkfreq*3+cnt)


comms.start(rx_pin,tx_pin,0,9600)      'rx,tx
waitcnt(clkfreq*4+cnt)
debug.str(string("started ok", 13))
repeat 10
  !outa[18]
  waitcnt(clkfreq/8+cnt)

repeat
  debug.getstr(@myStr)
  debug.str(string("got past the string", 13))
  repeat 10
    !outa[18]
    waitcnt(clkfreq+cnt)
  lightValue[0]:=myStr[0]
  debug.str(string("light value: "))
  debug.str(@lightValue)
  debug.str(13)
  
  if strcomp(@lightValue,@Str1)
    debug.str(string("I blink for you", 13))
    repeat 20
      !outa[18]
      waitcnt(clkfreq/10+cnt)
    outa[18]:=0
  lightValue[0]:=0
    
Dat
Str1 byte "A",0
