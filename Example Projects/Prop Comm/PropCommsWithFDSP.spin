{Object_Title_and_Purpose}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_250_000
        tx_pin=19
        rx_pin=18

VAR
  byte myRead
  byte msg[30]
  byte mybyte[2]
  byte myStr[30]
   
OBJ
  debug      : "FullDuplexSerialPlus"
  comms      : "FullDuplexSerialPlus"
  
PUB main
  dira[0..28]:=0
  'dira[18]:=1                   'set the LED direction to ouput                 
  dira[rx_pin]:=0                'set the prop receive pin to input                       
  dira[tx_pin]:=1                'set the prop transmit pin to output

  
  Debug.start(31,30,0,57600)
  waitcnt(clkfreq*3+cnt)
  Debug.Str(String(13, "this happens only on startup"))
  waitcnt(clkfreq*1+cnt)
  Debug.tx(16)
  
  Debug.Str(String(13,"Hit a key to start"))
  repeat until strcomp(myByte,string("0"))
    myByte:=Debug.getStr(myByte)
  Debug.Str(String(13,"You made it!"))
  Debug.Str(String(13,"Starting TX-RX with propeller"))
  Debug.Str(String(13))
  comms.start(rx_pin,tx_pin,0,57600)
  waitcnt(clkfreq*3+cnt)
  Debug.Str(string(13,"Finished TX-RX with propeller"))
  Debug.str(13)
  
  repeat
    debug.str(string(13,"start"))
    Debug.getStr(@myStr)  'this won't go into the loop until a dec is received
    waitcnt(clkfreq*4+cnt)
    Comms.str(@myStr)
    'Comms.tx(13)
    debug.str(string(13,"sent myByte"))
    waitcnt(clkfreq*4+cnt)
    Comms.str(@Str1)
    'if myByte>0
      'debug.str(string(13,"you're in!"))
      'outa[18]:=1
      'Comms.tx(myByte)
      'debug.str(string(13, "you're out!"))
    'else
      'outa[18]:=0
      'debug.str(string(13,"off"))
      
  'debug.str(string("poof"))
  'waitcnt(clkfreq*10+cnt)

DAT
Str1 byte "A",0
      