''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
'' TestMessages.spin
'' Send text messages stored in the DAT block to Parallax Serial Terminal.

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ
  Debug: "FullDuplexSerialPlus"
   
   
PUB TestDatMessages | value, counter

  ''Send messages stored in the DAT block.
 
  Debug.start(31, 30, 0, 57600)
  waitcnt(clkfreq*2 + cnt)
  Debug.tx(Debug#CLS)
  
  repeat
     Debug.Str(@MyString)
     Debug.Dec(counter++)
     Debug.Str(@MyOtherString)
     Debug.Str(@BlankLine)
     waitcnt(clkfreq + cnt)

DAT
  MyString        byte    "This is test message number: ", 0  
  MyOtherString   byte    ", ", Debug#CR, "and this is another line of text.", 0 
  BlankLine       byte    Debug#CR, Debug#CR, 0