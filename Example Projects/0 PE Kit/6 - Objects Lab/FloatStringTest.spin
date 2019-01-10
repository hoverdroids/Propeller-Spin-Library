''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
''FloatStringTest.spin
''Solve a floating point math problem and display the result with Parallax Serial
''Terminal.

CON
   
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
   

OBJ
   
  Debug   : "FullDuplexSerialPlus"
  fMath   : "FloatMath"
  fString : "FloatString"
   
   
PUB TwoWayCom | a, b, c

  '' Solve a floating point math problem and display the result.
 
  Debug.start(31, 30, 0, 57600)
  Waitcnt(clkfreq*2 + cnt)
  Debug.tx(Debug#CLS)

  a := 1.5
  b := pi

  c := fmath.FAdd(a, b)

  Debug.str(String("1.5 + Pi = "))

  debug.str(fstring.FloatToString(c)) 
 