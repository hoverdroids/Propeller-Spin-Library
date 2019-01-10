 {{
***************************************
* Serial_Pass_Through *
***************************************
* See end of file for terms of use. *
***************************************
Provides serial pass through for XBee (or other devices)
from the PC to the device via the Propeller. Baud rate
may differ between units though FullDuplexSerial can
buffer only 16 bytes.
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 6_250_000
  
  ' Set pins and Baud rate for XBee comms
  XB_Rx = 13 ' XBee DOUT
  XB_Tx = 14 ' XBee DIN
  XB_Baud = 9600
  
  ' Set pins and baud rate for PC comms
  PC_Rx = 31
  PC_Tx = 30
  PC_Baud = 9600
  
Var
  long stack[50] ' stack space for second cog
  byte go[2]
  
OBJ
  PC : "FullDuplexSerial"
  XB : "FullDuplexSerial"
  
Pub Start
  'PC.start(PC_Rx, PC_Tx, 0, PC_Baud) ' Initialize comms for PC
  XB.start(XB_Rx, XB_Tx, 0, XB_Baud) ' Initialize comms for XBee
  'cognew(XB_to_PC,@stack) ' Start cog for XBee--> PC comms

  'PC.rxFlush ' Empty buffer for data from PC
  go[0]:="A"
  repeat
    XB.tx(go[0]) ' Accept data from Xbee RX(i.e. remote PC) and send to XBee
    waitcnt(clkfreq+cnt)

'Pub XB_to_PC
  'XB.rxFlush ' Empty buffer for data from XB
  'repeat
    'PC.tx(XB.rx) ' Accept data from XBee and send to PC