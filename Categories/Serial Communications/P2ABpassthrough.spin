{{
***************************************
* P2ABpassthrough.spin *
***************************************
* See end of file for terms of use. *
***************************************
This file is to be loaded onto the P2AB propeller and tested with AIQBreceive
loaded onto the AIQB Propeller1. This file provides serial pass through from PC to AIQB Prop1
while AIQBreceive disects the message type and message value and then displays the message
number and value on the two 8 segment displays.

Baud rate may differ between units though FullDuplexSerial can
buffer only 16 bytes.
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 6_000_000
  
  ' Set pins and Baud rate for XBee comms
  XB_Rx = 24'26 '13 ' XBee DOUT
  XB_Tx = 25'27'14 ' XBee DIN
  XB_Baud =  9600
  
  ' Set pins and baud rate for PC comms
  PC_Rx = 31
  PC_Tx = 30
  PC_Baud = 9600
  
Var
  long stack[50] ' stack space for second cog
  byte myString[16]'was 12
  
OBJ
  PC : "FullDuplexSerialPlus"
  XB : "FullDuplexSerialPlus"
  
Pub Start
  PC.start(PC_Rx, PC_Tx, 0, PC_Baud) ' Initialize comms for PC
  XB.start(XB_Rx, XB_Tx, 0, XB_Baud) ' Initialize comms for XBee
  cognew(XB_to_PC,@stack) ' Start cog for XBee--> PC comms

  PC.rxFlush ' Empty buffer for data from PC
  repeat
    'XB.tx(PC.rx) ' Accept data from PC and send to XBee
     PC.getstr(@myString)
     XB.str(@myString)
     'XB.str(string("Check  ",13))
     XB.str(string(13))
     waitcnt(clkfreq*2+cnt)
Pub XB_to_PC | xbString[12] 
  XB.rxFlush ' Empty buffer for data from XB
  waitcnt(clkfreq*3+cnt)
  repeat
    'PC.tx(XB.rx) ' Accept data from XBee and send to PC
     'PC.str(string("You hit the receive wall",13))
     'waitcnt(clkfreq+cnt)
     PC.str(string(13))
     XB.getstr(@xbString)
     PC.str(@xbString)