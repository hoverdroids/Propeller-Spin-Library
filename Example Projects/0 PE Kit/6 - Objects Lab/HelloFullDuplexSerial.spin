''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
''HelloFullDuplexSerial.spin
''Test message to Parallax Serial Terminal.

CON
   
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
   

OBJ
   
  Debug: "FullDuplexSerial"
   
   
PUB TestMessages

  ''Send test messages to Parallax Serial Terminal.
 
  Debug.start(31, 30, 0, 57600)

  repeat
    Debug.str(string("This is a test message!", 13))
    waitcnt(clkfreq + cnt)