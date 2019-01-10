' Note that this file will make assumptions about the hardware -- specifically that it's a thalamoid board and that it can switch stuff on and off.


' CC Attribution Noncommercial Sharealike

CON
  _clkmode = xtal1 + pll16x
'  _xinfreq = 6_000_000
  _clkfreq = 96_000_000


OBJ
  com: "pcFullDuplexSerial4FC128PlusReadline"
  adb:"adb-shell-module-autoenum"
  outbuf:"stringoutput_external_buffer"
  inbuf[4]:"stringoutput_external_buffer"
  str:"StupidStringUtil"
  servo:"Servo32Simplified"

dat

P0TX byte 30          ' console (will get shell output, even from commands that are issued from other ports)
P0RX byte 31          ' console (will get shell output, even from commands that are issued from other ports)

P1TX byte 6           ' xbee
P1RX byte 7          ' xbee

P2TX byte 11          ' uses the RS232 shield that I built.
P2RX byte 10          ' uses the RS232 shield that I built.

P3TX byte 26          ' uses the RS232 shield that I built.
P3RX byte 25          ' uses the RS232 shield that I built.

P0BD long 9600
P1BD long 9600
P2BD long 9600
P3BD long 9600

con PIN_PWR = 12  ' optional turns USB on and off

  
PUB demo

  UsbPwr(1)
  
  outbuf.init(@outbufmem,BUFFER_SIZE)            
  inbuf[0].init(@inbuf0mem,BUFFER_SIZE)
  inbuf[1].init(@inbuf1mem,BUFFER_SIZE)
  inbuf[2].init(@inbuf2mem,BUFFER_SIZE)
  inbuf[3].init(@inbuf3mem,BUFFER_SIZE)
  errtimes~

  serialstart


  
  
  repeat
    com.str(0,string(" Sync",13,10))
    result := \adb.PrimaryHandshake
    
    if result>-1
       result := \CommandLoop
    else
       lasterror:=result   

    if (result<>-999)
      com.dec(0,result)
      com.str(0,string(" Aborted",13,10))
      if (lasterror==result)
         if(lasterror == -3 or lasterror == -4000) ' -3 is usb enumeration and is fixed by going back and changing IFD's, so it's a special case: allow many errors to happen. -4000 is similar (talking to the wrong interface)
            errtimes++
         else
            errtimes+=50
      else
         errtimes~
         lasterror:=result
      
      if errtimes>500'result == -135 or result == -4)
        com.str(0,string("Errors>threshold, rebooting module",13,10))
        UsbPwr(0)     
        waitcnt(cnt+ constant(_clkfreq*2))
        reboot

pub UsbPwr(off)
dira[PIN_PWR]~~
outa[PIN_PWR]:=!off


pub serialstart  

  com.stop
  com.AddPort(0,P0RX,P0TX,-1,-1,-1,-3*(P0BD<0),||P0BD)
  com.AddPort(1,P1RX,P1TX,-1,-1,-1,-3*(P1BD<0),||P1BD)
  com.AddPort(2,P2RX,P2TX,-1,-1,-1,-3*(P2BD<0),||P2BD)
  com.AddPort(3,P3RX,P3TX,-1,-1,-1,-3*(P3BD<0),||P3BD)
  com.start


con
CONNECTION_SHELL = 0
CONNECTION_LCAT  = 1
CONNECTION_COM   = 2
CONNECTION_SPARE = 3
con

BUFFER_SIZE = 256

var
long logcycle
var
byte lastcommand[BUFFER_SIZE+1]
byte nextcommand[BUFFER_SIZE+1]
var                                                        
long lasterror
byte errtimes


dat
sd0               byte "cd "
startingdirectory byte "/data/data/re.BridgeTerm/cache"  ' change this depending on your app (or use /sdcard/ etc.)
sd1               byte 13,10,0
dat
commandecho       byte 255
pri CommandLoop 

derpdebug
' connections:
' 3 is output to file
' 2 is ADC output to file
' 1 is input from logcat
' 0 is shell
CommandsExpected:=-10
logcycle:=log_period
logcycles~
globalecho~

cmd (string("logcat -c;logcat -v raw PB_IN:* *:S",13,10),CONNECTION_LCAT)
derpdebug
cmd (string("su",13,10),CONNECTION_COM)
derpdebug
cmd (@sd0,CONNECTION_COM)
derpdebug
cmd (@sd0,CONNECTION_SHELL)
derpdebug
cmd (string("chmod 777 .;chmod 777 ./COM*",13,10),CONNECTION_COM)
derpdebug                                                                  

globalecho~~


repeat

  derpdebug
  ExecuteCommandIfThere
  listen

  --logcycle

  case logcycle
   5: ConsoleToBuffer(3)
   4: ConsoleToBuffer(2)
   3: ConsoleToBuffer(1)
   2: ConsoleToBuffer(0)
   1: if (CommandQueued)
        cmd(@lastcommand,CONNECTION_SHELL)  ' missed a command? try again.
        CommandQueued~
   0: logcycle:=6
      logcycles++


pub ConsoleToBuffer(port) | buffaddr

  case port
       0:buffaddr:=@inbuf0mem
       1:buffaddr:=@inbuf1mem
       2:buffaddr:=@inbuf2mem
       3:buffaddr:=@inbuf3mem
       other:return
       
  chin~    
  repeat
    chin := com.rxcheck(port)
   if (chin>0)

     if (chin==quote and byte[buffaddr]<>"@" and byte[buffaddr]<>"$") ' escape quotes
        inbuf[port].tx("\")
     inbuf[port].tx(chin)

     
    if (chin==13 or inbuf[port].remaining < 80)
    
     if (byte[buffaddr]=="@")       '@ propeller command
     
       bytemove(@nextcommand,buffaddr+1,BUFFER_SIZE)
       inbuf[port].zap(0)

       commandecho:=0 ' comment this out for silent prop commands from console
       'commandecho:=port ' comment this out for "whoever sent a valid command last is the console"
       
     elseif (byte[buffaddr]=="$")   '$ shell command

       bytemove(@lastcommand,buffaddr+1,BUFFER_SIZE)
       inbuf[port].zap(0)
       CommandQueued~~
       cmd(@lastcommand,CONNECTION_SHELL)

     else ' send thru to port file like normal

        outbuf.zap(0)
        portstr0 := "0"+port
        'outbuf.str(string("echo -n ",quote))  ' using this will remove carriage returns unless they're by themselves (so 2xCR => 1xCR)
        outbuf.str(string("echo ",quote))
        outbuf.str(buffaddr)
        outbuf.str(@portstr1)    
        cmd(@outbufmem,CONNECTION_COM)
        inbuf[port].zap(0)
 
     
  until chin==-1

con
log_period = 5
quote = 34


dat
portstr1 byte quote," >> ./"
portstr  byte "COM"
portstr0 byte "1",13,0
pri PortToBuffer(portnum)

      ' read from serial, save to appropriate buffer. as atomic as possible.
      
      if (com.rxpeek(portnum) > 0)
        portstr0 := "0"+portnum
        outbuf.zap(0)
        outbuf.str(string("echo -n ",quote))
        repeat 
          if (com.rxpeek(portnum) == quote)
            outbuf.tx("\")
          outbuf.tx(com.rxcheck(portnum))
        while (com.rxpeek(portnum) <> -1)
        outbuf.str(@portstr1)    
        cmd(@outbufmem,CONNECTION_COM)
        'com.str(0,@outbufmem)


pri ExecuteCommandIfThere 


    ' executes commands (for routing etc)

    ' todo: allow this to also act as a serial splitter?
    result~
    if strsize(@nextcommand)
    
     ' change working directory   
        if byte[@nextcommand]=="D"
           outbuf.zap(0)
           outbuf.str(string("cd /"))
           outbuf.str(@nextcommand+2)
           cmd(@outbufmem,CONNECTION_COM)
           cmd(@outbufmem,CONNECTION_SHELL)
           result~~

     ' reboot
        if byte[@nextcommand]=="~"
           UsbPwr(0)
           reboot

           
     ' change baudrates   

     ' B0+0096
     ' B1+1152
     ' B2-0003

        if byte[@nextcommand]=="B"
          if byte[@nextcommand+1]>constant("0"-1) and byte[@nextcommand+1]<constant("4")
           if byte[@nextcommand+2] == "+" or byte[@nextcommand+2] == "-"
              result := str.StupidNumberParser(@nextcommand+3)
                if (result > 0)
                    result := result * 100
                    if (byte[@nextcommand+2]=="-")
                        result := result * -1
                    if (byte[@nextcommand+1]=="0") 
                        P0BD := result
                    if (byte[@nextcommand+1]=="1") 
                        P1BD := result
                    if (byte[@nextcommand+1]=="2") 
                        P2BD := result
                    if (byte[@nextcommand+1]=="3") 
                        P3BD := result
                    serialstart    
                        
     ' send string on com port
     ' S0:datadatadata
     ' S1;datadatadata<cr>
     
        if byte[@nextcommand]=="S"
          if byte[@nextcommand+1]>constant("0"-1) and byte[@nextcommand+1]<constant("4")
           if byte[@nextcommand+2] == ":" or byte[@nextcommand+2] == ";"
              com.str(byte[@nextcommand+1]-"0", @nextcommand+3)
              result~~
                if byte[@nextcommand+2] == ":" '";"
                     com.tx(byte[@nextcommand+1]-"0", 13)

      if (commandecho<255)
        if (result)
          repeat 3
            com.tx(commandecho,":")
        else
          repeat 3
            com.tx(commandecho,"?")
        com.tx(commandecho,"@")
        com.str(commandecho,@nextcommand)
        com.tx(commandecho,13)
                     

        commandecho:=255

        
      bytefill(@nextcommand,0,BUFFER_SIZE)

        
        
pri cmd(what, who)
listen
result:=adb.str(what,who)
listen   
CommandsExpected++

if (globalecho and CommandsExpected < -2)
    CommandsExpected:=-2
if (CommandsExpected > 0)
    CommandsExpected~
    com.tx(0,"[")
    com.dec(0,logcycles)
    com.tx(0,"]")

    abort -999


pri listendebug
 
    return
    com.tx(0,",")
    com.tx(0,",")
    com.tx(0,",")
    com.dec(0,adb.debug_message_command)
    com.tx(0,",")
    com.dec(0,adb.debug_message_arg0)
    com.tx(0,",")
    com.dec(0,adb.debug_message_arg1)
    com.tx(0,"=")
    com.tx(0,">")
    com.dec(0,adb.debug_activeconn)
    com.tx(0,",")
    com.dec(0,adb.debug_stat(adb.debug_activeconn))
    com.tx(0,13)
pri derpdebug : a
  return
   
  com.dec(0,logcycle)
  a~
  com.tx(0," ")
  repeat adb#NUMCONNS
    com.dec(0,a)
    com.tx(0,",")
    com.dec(0,adb.debug_loc(a))
    com.tx(0,",")
    com.dec(0,adb.debug_rem(a))
    com.tx(0,",")
    com.dec(0,adb.debug_stat(a))
    com.tx(0," ")
    a++
  com.tx(0,13)
  

  


pri listen
  result~~
  repeat 

   result := adb.rx
   if (adb.debug_message_command)
     CommandsExpected-=2
   listendebug

   if (result) ' can this be done better?
     CommandsExpected-=2
     if (adb.id == CONNECTION_SHELL)
        CommandQueued~
     if (adb.id == CONNECTION_LCAT)
        bytemove(@nextcommand,adb.rxbuf,BUFFER_SIZE)
        
     if (EchoConnection(adb.id))
       if (strsize(adb.rxbuf)>1)
         com.tx(0,"{")
         com.dec(0,adb.id)
         com.tx(0,"|")
         com.dec(0,strsize(adb.rxbuf))
         com.tx(0,"}")
         com.tx(0,13)
         com.str(0,adb.rxbuf)
     adb.rxclr
  until result==0

pri EchoConnection(which)
    if (globalecho==0 or which==CONNECTION_COM or which==CONNECTION_SPARE)
         return false
    return true
var
long logcycles
long chin
byte globalecho
byte inbuf0mem[BUFFER_SIZE+1]
byte inbuf1mem[BUFFER_SIZE+1]
byte inbuf2mem[BUFFER_SIZE+1]
byte inbuf3mem[BUFFER_SIZE+1]
byte outbufmem[BUFFER_SIZE+1]
long CommandsExpected
byte CommandQueued     