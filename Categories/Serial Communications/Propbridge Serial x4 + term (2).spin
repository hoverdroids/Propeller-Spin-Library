' Note that this file will make assumptions about the hardware -- specifically that it's a thalamoid board and that it can switch stuff on and off.
{Chris Notes: adb opens up 4 shells on the phone through pins0 and 1; this code also opens up 4 tx/rx lines not including
the phone tx/rx
}


CON
  _clkmode = xtal1 + pll16x
'  _xinfreq = 6_000_000
  _clkfreq = 96_000_000


OBJ
  com: "pcFullDuplexSerial4FC128PlusReadline"
  adb:"adb-shell-module-autoenum"
  outbuf:"stringoutput_external_buffer"
  inbuf:"stringoutput_external_buffer"
  str:"StupidStringUtil"

dat

P0TX byte 30          '30 'CHRIS:port 0 is serial comms on pc
P0RX byte 31          '31

P1TX byte 6           '6' CHRIS:port 1 is the connection to the phone?
P1RX byte 7           '7
                      'CHRIS:if I use port 2 and 3 for my own stuff, will it screw with what he's written? Does this mean
                      ' I shouldn't enable these ports or pins?
P2TX byte 11          ' uses the RS232 shield that I built.
P2RX byte 10          ' uses the RS232 shield that I built.

P3TX byte 26          '26 ' uses the RS232 shield that I built.
P3RX byte 25          '25 ' uses the RS232 shield that I built.

P0BD long 9600  '115200
P1BD long 9600
P2BD long 9600
P3BD long 9600   '115200

con PIN_PWR = 12  ' optional turns USB on and off
                  'CHRIS:I assume this is for the mosfet on his mini?

  
PUB demo

  UsbPwr(1)                        'Power off the USB power to phone
  
  outbuf.init(@outbufmem,256)      'set the output buffer to 256 bytes      
  inbuf.init(@inbufmem,BUFFER_SIZE)'set the input buffer to buffer_size, which is currently 256
  errtimes~                        'null the number of errors

  serialstart                       'start the serial ports; current starts the following ports on the P2AB (not the phone)
                                    'Port0-TX=30,RX=31-P2AB serial terminal
                                    'Port1-TX=6, RX=7 -Will use for Xbee
                                    'Port2-TX=11,RX=10-Will use for Prop1 on ASD, nothing on ACD
                                    'Port3-TX=26,RC=25-Will not be used


  
  
  repeat
    com.str(0,string(" Sync",13,10))'send the "sync" string with <cr> and a new line feed (ASCII)
    result := \adb.PrimaryHandshake 'slash catches an abort if it happens; if not, the result is>-1 and indicates a successful handshake with the phone                                                                    
    
    if result>-1
       result := \CommandLoop       'if handshake didn't abort, launch the command loop (comms loop)
    else
       lasterror:=result            'if handshake aborted, catch it in the lasterror variable

    if (result<>-999)               'if result is not -999;if it is,don't display anything 
      com.dec(0,result)                    'send the result to port0, the debug terminal
      com.str(0,string(" Aborted",13,10))  'send "aborted", <cr> and line feed string to port0, the debug terminal
      if (lasterror==result)                'phone comm fixing stuff?
         if(lasterror == -3 or lasterror == -4000) ' -3 is usb enumeration and is fixed by going back and changing IFD's, so it's a special case: allow many errors to happen. -4000 is similar (talking to the wrong interface)
            errtimes++
         else
            errtimes+=50
      else
         errtimes~
         lasterror:=result
      
      if errtimes>500'result == -135 or result == -4) 'if too many errors then reboot the P2AB
        com.str(0,string("Errors>threshold, rebooting module",13,10))
        UsbPwr(0)     
        waitcnt(cnt+ constant(_clkfreq*2))
        reboot

pub UsbPwr(off)
dira[PIN_PWR]~~
outa[PIN_PWR]:=!off


pub serialstart  
  'CHRIS:I believe this is where the user adds more serial lines to the propbridge; does adding ports here add them to the android?
  com.stop                                             'all comports must be stopped before chaning/updating ports
  com.AddPort(0,P0RX,P0TX,-1,-1,-1,-3*(P0BD<0),||P0BD)  'add port 0 on given pins at given baud; the non-obvious is required; ignore it
  com.AddPort(1,P1RX,P1TX,-1,-1,-1,-3*(P1BD<0),||P1BD)   'add port 1...
  com.AddPort(2,P2RX,P2TX,-1,-1,-1,-3*(P2BD<0),||P2BD)    'add port 2...
  com.AddPort(3,P3RX,P3TX,-1,-1,-1,-3*(P3BD<0),||P3BD)    'add port 3...
  com.start                                               'start the above ports


con
CONNECTION_SHELL = 0   'CHRIS:I think this is the command shell;also, are all of these shells talking through the one serialport?
CONNECTION_LCAT  = 1    'I think this is the logcat "shell" which catches the log info for the user
CONNECTION_COM   = 2    'what comm is here
CONNECTION_SPARE = 3
con

BUFFER_SIZE = 256  'CHRIS:this is where the user sets the desired buffer size

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
pri CommandLoop 
                           
derpdebug                  'at present this does nothing
' connections:
' 3 is output to file
' 2 is ADC output to file
' 1 is input from logcat   'CHRIS:from logcat to serial terminal window?
' 0 is shell               'CHRIS:shell is the "keyboard input" on the phone;if not reading the shell, then what is the phone reading when displaying data on the screen?
CommandsExpected:=-10      '???Not sure what this is
logcycle:=log_period       '???not sure what this is
logcycles~                 'set the number of log cycles to 0 each time the command loop is started
globalecho~                '???not sure what this is
'the following uses cmd to send strings to the phone using adb.str(what,who) while listening for the phone;it's here that the phone TX/RX pins happen first
cmd (string("logcat -c;logcat -v raw PB_IN:* *:S",13,10),CONNECTION_LCAT)'send this string to the logcat phone shell
derpdebug                                                                'not used 
cmd (string("su",13,10),CONNECTION_COM)                                  'send the SU string to the com phone shell (0)
derpdebug
cmd (@sd0,CONNECTION_COM)                                                '???what does sending sd0 address to com do?
derpdebug
cmd (@sd0,CONNECTION_SHELL)                                              '???what does sending sd0 address to con_shell do?
derpdebug
cmd (string("chmod 777 .;chmod 777 ./COM*",13,10),CONNECTION_COM)
derpdebug                                                                  

globalecho~~                                                            '???what is global echo; why "start" it?


repeat

  derpdebug                                                            'not used
  ExecuteCommandIfThere                                                'check to see if the debug terminal sent command; if so, execute it
  listen

  --logcycle                                                            
 if (logcycle==1)

      if (CommandQueued)
        cmd(@lastcommand,CONNECTION_SHELL)  ' missed a command? try again.
        CommandQueued~

 elseif (logcycle==0) ' asynchronous stuff here (in this case, dump to filesystem)

      'com.tx(0,".")

      PortToBuffer(1)
      PortToBuffer(2)
      PortToBuffer(3)

      logcycle:=log_period
      logcycles++

 else

   chin~    
  repeat
    chin := com.rxcheck(0)   'i think this is where the input is checked; it only checks port0 for input
   if (chin>-1)              'rxcheck returns -1 if no byte received
    inbuf.tx(chin)
    if (chin==13 or inbuf.remaining < 80)
    
     if (byte[@inbufmem]=="@")                      'if the first byte is an @ symbol, move the incoming buffer to "nextcommand"
       bytemove(@nextcommand,@inbufmem+1,BUFFER_SIZE)
       inbuf.zap(0)
     elseif (byte[@inbufmem]==">") 
      if (byte[@inbufmem+1]=="<") 
        'p.off(p#PWR_PHONE)
        reboot
        
      byte[@inbufmem+1+strsize(@inbufmem+1)-1]~ 
      outbuf.zap(0)
      outbuf.str(string("cat ./PB_O_C >> /sdcard/PB_O_L;echo ")) 'why send this string?
      'outbuf.str(string("echo "))
      outbuf.str(@inbufmem+1)
      outbuf.str(string(" > ./PB_O_C",13,10))
      cmd(@outbufmem,CONNECTION_SPARE)
      inbuf.zap(0)
      'cmd(string("cat ./PB_O_C >> /sdcard/PB_O_L",13),CONNECTION_L)

     else

      bytemove(@lastcommand,@inbufmem,BUFFER_SIZE)
      CommandQueued~~
      cmd(@lastcommand,CONNECTION_SHELL)
      inbuf.zap(0)

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
    'this is the directional component of the code; everything else seems to store the input/output to next command based
    'on certain conditions; this executes and sends "next command"

    ' executes commands (for routing etc)

    ' todo: allow this to also act as a serial splitter?<-MK Borri...Chris thinks this is where "nextcommand" can be forwarded to other serial devices
    result~
    if strsize(@nextcommand)
    
     ' change working directory on the phone shell  
        if byte[@nextcommand]=="D"
           outbuf.zap(0)
           outbuf.str(string("cd /"))
           outbuf.str(@nextcommand+2)
           cmd(@outbufmem,CONNECTION_COM)     '???why is this info being sent to the ADC output file and the shell?
           cmd(@outbufmem,CONNECTION_SHELL)
           result~~

     ' echo back                                          'send the string to the to the shell using the echo command and adb
        if byte[@nextcommand]=="@"
           outbuf.zap(0)                                  'null every byte in the outbuffer
           portstr0:="0"
           result:=@nextcommand
           repeat strsize(@nextcommand)
             if byte[++result]==13 or byte[result]==10
                byte[result]~
           outbuf.str(string("echo -n ",quote))           'prefix the output with echo -n
           outbuf.str(@nextcommand+1)                      'add the rest of the string
           outbuf.str(@portstr1)                            'add the port number string for routing
           cmd(@outbufmem,CONNECTION_SHELL)                'send the string to the port including the echo -n;this gets the command to the phone lo


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
     
        if byte[@nextcommand]=="S"                                   'if the byte after the first @ sign is an S
          if byte[@nextcommand+1]>constant("0"-1) and byte[@nextcommand+1]<constant("4") 'and if the byte after the s is between 0 and 4
           if byte[@nextcommand+2] == ":" or byte[@nextcommand+2] == ";"    'if the next byte is ; or :
              com.str(byte[@nextcommand+1]-"0", @nextcommand+3)             'then send the message to the noted port,not including @ or S3;
              result~~
                  if byte[@nextcommand+2] == ";"                             'and if the ; was requested, send the carriage return
                     com.tx(byte[@nextcommand+1]-"0", 13)
                                                                            'big note:this is sending using com, not adb




        if (result)                                                 'if an @ was received but no other command; send ??? to terminal
          repeat 3
            com.tx(0,":")
        else
          repeat 3
            com.tx(0,"?")
        com.tx(0,"@")
        com.str(0,@nextcommand)
        com.tx(0,13)
                     

        bytefill(@nextcommand,0,BUFFER_SIZE)

        
        
pri cmd(what, who)  'simply,cmd sends the what(a string) to the who(a phone channel) and returns an error and aborts on an error 
listen                   'launch a listener for???
result:=adb.str(what,who)'send the what string to the who channel on the phone
listen                   'launch that listener again for???
CommandsExpected++       'add one to commandsexpected; why???

if (globalecho and CommandsExpected < -2) 'if globalecho and commandsexpected vars are both less thna 2, reset comexp to -2; why ???
    CommandsExpected:=-2
if (CommandsExpected > 0)                 'if comexp greater than 0, display [logcycles] on the port0 debug terminal
    CommandsExpected~
    com.tx(0,"[")
    com.dec(0,logcycles)
    com.tx(0,"]")
                                           'then abort cmd with -999 value
    abort -999


pri listendebug
 
    return       'immendiately exit the private method; why???
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
  return         'immediately exite the private method;why does this immediately exit???
   
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
  

  


pri listen 'this listens for a message until there is no message from the phone shells
  result~~
  repeat 

   result := adb.rx
   if (adb.debug_message_command)
     CommandsExpected-=2
   listendebug

   if (result) ' can this be done better?
     CommandsExpected-=2
     if (adb.id == CONNECTION_SHELL)              'if the connection shell sent a string
        CommandQueued~                            'if the connection_lcat sent a string
     if (adb.id == CONNECTION_LCAT)
        bytemove(@nextcommand,adb.rxbuf,BUFFER_SIZE)'if the input was received from the logcat, move that to the nextcommand buffer
        
     if (EchoConnection(adb.id))                      'this shows {N|M} <cr> and then adb.rxbuf is displayed;then adb rxbuf is cleared
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
byte inbufmem[513]
byte outbufmem[BUFFER_SIZE+1]
long CommandsExpected
byte CommandQueued     
