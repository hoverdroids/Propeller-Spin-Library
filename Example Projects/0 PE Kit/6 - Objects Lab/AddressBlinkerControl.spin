''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
'' AddressBlinkerControl.spin
'' Enter LED states into Parallax Serial Terminal and send to Propeller chip via 
'' Parallax Serial Terminal.

CON
   
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
 
  
OBJ
   
  Debug:    "FullDuplexSerialPlus"
  AddrBlnk: "AddressBlinker"

   
VAR
  
  long pin, rateDelay
   

PUB UpdateVariables

  '' Update variables that get watched by AddressBlinker object.
 
  Debug.start(31, 30, 0, 57600)
  waitcnt(clkfreq*2 + cnt)
  Debug.tx(Debug#CLS)

  pin := 4
  rateDelay := 10_000_000

  AddrBlnk.start(@pin, @rateDelay)

  dira[4..9]~~

  repeat

     Debug.Str(String("Enter pin number: "))
     pin := Debug.getDec
     Debug.Str(String("Enter delay clock ticks:"))
     rateDelay := Debug.getDec
     Debug.Str(String(Debug#CR))