{Object_Title_and_Purpose}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

VAR
  long symbol,blinkRate
  long stack[30]
   
OBJ
  Debug      : "FullDuplexSerialPlus"
  
PUB Main |value
''send test messages and to parallax serial terminal
Debug.start(31,30,0,57600)
waitcnt(clkfreq*2+cnt)
Debug.tx(16)
dira[18]:=1
value:=1

repeat
  Debug.Str(String("Enter a decimal value:  "))
  value:=Debug.getDec
  coginit(6,Blink(value),@stack[0])
  Debug.Str(String(13, "You Entered", 13,"---------"))
  Debug.Str(String(13, "Decimal:  "))
  Debug.Dec(value)
  Debug.Str(String(13,"Hexadecimal:  "))
  Debug.Hex(value,8)
  Debug.Str(string(13, "Binary:  "))
  Debug.Bin(value,32)
  repeat 2
    Debug.Str(string(13))
  

PUB Blink(value2)

  dira[18]:=1
  
  repeat 2000
    !outa[18]
    waitcnt(clkfreq/value2+cnt)


