''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
'' TerminalButtonLogger.spin
'' Log times the button connected to P23 was pressed/released in 
'' Parallax Serial Terminal.

CON
   
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
   

OBJ
   
  Debug      : "FullDuplexSerialPlus"
  Button     : "Button"
  Time       : "TickTock"

  
VAR

  long days, hours, minutes, seconds
  
                     
PUB TestDatMessages 
 
  Debug.start(31, 30, 0, 57600)         ' Start FullDuplexSerialPlus object.
  waitcnt(clkfreq*3 + cnt)              ' Wait for three seconds.
  Debug.tx(Debug#CLS)


  Time.Start(0, 0, 0, 0)                ' Start the TickTock object and initialize 
                                        ' the day, hour, minute, and second.
  Debug.Str(@BtnPrompt)                 ' Display instructions in Parallax Serial Terminal
  repeat
  
    if Button.Time(23)                  ' If button pressed.
       ' Pass variables to TickTock object for update.
       Time.Get(@days, @hours, @minutes, @seconds)
       DisplayTime                      ' Display the current time.
       

PUB DisplayTime
      
      Debug.tx(Debug#CR)
      Debug.Str(String("Day:"))
      Debug.Dec(days)
      Debug.Str(String("  Hour:"))
      Debug.Dec(hours)
      Debug.Str(String("  Minute:"))
      Debug.Dec(minutes)
      Debug.Str(String("  Second:"))
      Debug.Dec(seconds)
      

DAT

BtnPrompt   byte    Debug#CLS, "Press/release P23 pushbutton periodically...", 0