{{DS00 Laser Range Finder Comms
This object connects the Propeller to the DS00 using one serial line (no UI) and the prop then connects to the
Parallax serial terminal using another serial line.  All the prop is doing is acting as the middle man
by taking DS00 data from its TX line and feeding it to the PST screen, and allowing a user to command the
DS00 using the PST UI.



}}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        'DS00 serial data from James Portman at Lightware:  57600,8,N,1
        DS00_RX_PIN=14
        DS00_TX_PIN=15
        DS00_Baud=57600

        'PST data  on COM13 of laptop (11-8-12)
        PST_RX_PIN=31
        PST_TX_PIN=30
        PST_Baud=57600 '9600

       
        CLS=16 'This won't let me reference the constant in FDSP

VAR
  Byte myByte
  Byte MyByteArray[ 11 ]
  Byte DS00_Cmd
  

OBJ

  Debug              :"FullDuplexSerialPlus"
  DS00_Comms         :"FullDuplexSerialPlus"
   
PUB Main
'-------[Initialization]------------
'the EBT module is waiting for a byte to establish a connection; press any ky
'in the top window pane of the debug to do this
dira[DS00_RX_PIN]:=0
dira[DS00_TX_PIN]:=1
dira[PST_RX_PIN]:=0
dira[PST_TX_PIN]:=1

Debug.start(PST_RX_PIN,PST_TX_PIN,0,PST_Baud)
DS00_Comms.start(DS00_RX_PIN,DS00_TX_PIN,0,DS00_Baud)

waitcnt(clkfreq*3+cnt)
Debug.tx(16)
Debug.Str(String(13,"Initialization Complete"))
waitcnt(clkfreq*1+cnt)
Launch_Debug_Listener
  
myByte:=0


repeat
  'Debug.Str(String(13,"DS00 sent the following value:  "))
  'myByte:=DS00_Comms.getDec
  myByte:=DS00_Comms.getStr(MyByteArray)
  Debug.Str(myByte)
  Debug.Str(String(13))
  'Debug.Dec(myByte)
  'repeat 2
    'Debug.Str(string(13))
  
PUB Launch_Debug_Listener|Cmd_confirm[11],Cmd_confirm_str,Cmd_confirm_bin,exit_loop
exit_loop:=0

repeat while exit_loop<>=1
  Debug.Str(String(13,"Please enter a command",13))
  DS00_Cmd:=Debug.getStr(MyByteArray)
  Debug.Str(String(13,"Your DS00 command was:  "))
  Debug.Str(DS00_Cmd)
  Debug.Str(String(13,"Is this correct? (Y/N)",13))
  Debug.getStr(Cmd_confirm)
  if STRCOMP(Cmd_confirm,string("y"))
    Debug.Str(String("Command Accepted"))
    waitcnt(clkfreq*2+cnt)
    Debug.Str(String(CLS))
    exit_loop:=1
  else
    Debug.Str(string("Command Ignored"))
    waitcnt(clkfreq*2+cnt)
    Debug.Str(String(CLS))
  

  
if STRCOMP(DS00_Cmd,string("S"))
  DS00_Comms.Str(DS00_Cmd)

