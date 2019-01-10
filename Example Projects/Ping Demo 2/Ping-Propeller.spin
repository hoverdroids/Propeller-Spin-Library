OBJ

  pst   : "FullDuplexSerial"
  ping  : "Ping"

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ping_pin = 0                      ' I/O pin for Ping
  
VAR

  long  range
  
PUB Go

  pst.start(31,30,0,115200)
  waitcnt(ClkFreq + Cnt)
    
  repeat                            ' Repeat forever
    range := ping.Inches(ping_pin)  ' Get range in inches
    pst.dec(range)                  ' Display result
    pst.tx(13)
    WaitCnt(ClkFreq / 4 + Cnt)	' Short delay until next read