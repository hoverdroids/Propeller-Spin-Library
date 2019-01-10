''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
'' File: EnterAndDisplayValues.spin
'' Messages to/from Propeller chip with Parallax Serial Terminal. Prompts you to enter a '' value, and displays the value in decimal, binary, and hexadecimal formats.

CON
   
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
   

OBJ
   
  Debug: "FullDuplexSerialPlus"
   
   
PUB TwoWayCom | value

  ''Test Parallax Serial Terminal number entry and display.
 
  Debug.start(31, 30, 0, 57600)
  waitcnt(clkfreq*2 + cnt)
  Debug.tx(16)

  repeat

     Debug.Str(String("Enter a decimal value: "))
     value := Debug.getDec
     Debug.Str(String(13, "You Entered", 13, "--------------"))
     Debug.Str(String(13, "Decimal: "))
     Debug.Dec(value)
     Debug.Str(String(13, "Hexadecimal: "))
     Debug.Hex(value, 8)
     Debug.Str(String(13, "Binary: "))
     Debug.Bin(value, 32)
     repeat 2
        Debug.Str(String(13))     