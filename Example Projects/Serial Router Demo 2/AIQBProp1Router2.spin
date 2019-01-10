CON
                                                                                                                              
        _clkmode                = xtal1 + pll16x
        _xinfreq                = 6_000_000'5_000_000
        _stack                  = 100 ' mah? set this to MainStack instead?                                                                                       




obj

 com:"TwelveSerialPorts32"  '32, 128 or 512 mean size of primary RX buffer.
'com:"TwelveSerialPorts128" '32, 128 or 512 mean size of primary RX buffer.
'com:"TwelveSerialPorts512" '32, 128 or 512 mean size of primary RX buffer.
terminal: "FullDuplexSerialExt"
dummyplug: "serial_output_thingy"

con
numbuffers  = 3'12  'modify the number of ports you want here; this doesn't include the debug port
buffersize  = com#SECONDARY_BUFFER_SIZE
delimchar   = "@" ' address delimiter
termichar   = 13  ' packet delimiter
termichar2  = 10  ' packet delimiter
con
' 0..11 are the port addresses
term        = 12 ' terminal address
router      = 13 ' if we get this address in, it means it's a command for the router, so handle accordingly.
aux0_cog1   = 14 ' if we get this address in, it means it's a command for the auxilliary cog, so handle accordingly.
devnull     = 99 ' guaranteed /dev/null for any conceivable reason
stealthmask = 50 ' This + address means "deliver the packet without sending information", useful for devices that don't know about the router, e.g. NMEA devices. 0 disables. Do not overlap ports or you'll miss the first stealthed x ports.


var  ' router variables
byte buffer[(buffersize+1)*numbuffers] ' includes padding
long ptr[numbuffers]

byte terminalbuffer[buffersize]   ' high speed port gets special treatment
byte terminalpad
long terminalptr



var ' spin stacks
long aux0_stack[128]


dat   'device num     0      1       2      3      4       5     6     7      8      9      10     11     term      device num
'                  bridge  Prop2   audio
inputpins      byte 24,     9,     14,     5,     2,     24,    13,    7,    17,    19,    21,    23,      31      ' Hardware input pin
outputpins     byte 25,     8,     15,     4,     1,     25,    12,    6,    16,    18,    20,    22,      30      ' Hardware output pin
inversions     byte %0000, %0000, %0000, %0000, %0000, %0011, %0011, %0011, %0011, %0011, %0011, %0011,   %0000   ' Signal flags (open collector, inversion etc.)
baudrates      long 9600,  9600,  38400,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  115200  ' Baud rate
defaultroute   byte 62,  term,  term,  term,  term,  term,  term,  term,  term,  term,  term,  term,    50  '0 was:term;term was:router If a packet coming from this port has no address, default to sending it to that port. Use stealthmask to strip packet information.
dat ' configuration options for the router
defaultaddress byte term   ' where to send things we don't know what to do with
bigbrother     byte  2     ' 0 none, 1 terminal monitors inter-device exchange, 2 terminal monitors that AND packet contents (useful to not have to send the same packet twice
doupcase       byte  0     ' if 1, convert lowercase letters to uppercase
dolowcase      byte  0     ' if 1, convert uppercase letters to lowercase


dat ' premade sentences
busystr byte "@__@BUSY",0
errstr  byte "@__@ERR "
errcode byte "_",0
okstr   byte "@__@OK",0

con 'For auxilliary cog functions, go at the end of this file.
debug = false
pub start | temp, bufferbaseaddr, port ' Main router code.
if (debug)
 dummyplug.start(12,-19200) ' sends test data to ports above. remove once debugging is over



terminal.start(byte[@inputpins+12],byte[@outputpins+12],byte[@inversions+12],long[@baudrates+12*4])    ' high speed port gets special treatment (update: should it?)

aux0_com.init(@aux0_buffer_tx,buffersize) ' virtual com port for aux0_ device


port~    ' start all the other ports here 
repeat numbuffers
  if (byte[@inputpins+port] < 32) and (byte[@outputpins+port] < 32)
    com.AddPortNoHandshake(port,byte[@inputpins+port],byte[@outputpins+port],byte[@inversions+port],long[@baudrates+port*4])'CHRIS:this is where the ports are "added"
    port++
com.start

' start aux0_illiary cog here (if wanted). Add cogs to fit.
repeat
  aux0_rxflag~
  aux0_cog := cognew(aux0_loop, @aux0_stack) + 1
until aux0_cog

' main loop
repeat
     ' device ports
   port~
   repeat numbuffers
      bufferbaseaddr := port*buffersize
      temp := com.rxcheck(port)
      if (temp > 0)
          buffer[bufferbaseaddr+ptr[port]]:=temp
          ptr[port]++
        if (temp == termichar or temp == termichar2 or ptr[port] => buffersize)
          buffer[bufferbaseaddr+ptr[port]] := 0
          output(@buffer+bufferbaseaddr,port)
          ptr[port] := 0
      port++

     ' terminal port (checked every round)
      temp := terminal.rxcheck
      if (temp > 0)
          terminalbuffer[terminalptr++]:=temp
        if (temp == termichar or temp == termichar2 or terminalptr > buffersize)
          terminalbuffer[terminalptr]~
          output(@terminalbuffer,term)
          terminalptr~

     ' internal virtual serial port (ok to check every round: virtually free)
      if(aux0_txflag)
       output(@aux0_buffer_tx,(constant(aux0_cog1)))
       aux0_com.zap(0)
       aux0_txflag~ 

pri ExecuteRouterCommand(CommandAddr, origin) : valid | cmdbyte, arg1, arg2 ' unrolled loops for speed here. use this to set verbosity, pins, baud rates etc. Can also set routing tables if we want to go that way. Synchronous, so it sehould be fast!
         valid~
         cmdbyte := upcase(byte[CommandAddr])
         if cmdbyte == "L" 'Lx ' logging level
            if isDigit(byte[CommandAddr+1])
               bigbrother := byte[CommandAddr+1]-"0"
               valid~~

         if cmdbyte == "R" 'reboot
            reboot

         if cmdbyte == "D" 'Dxx>yy ' default route for port x is y ( use stealthmask to strip!)
            if isDigit(byte[CommandAddr+1]) and isDigit(byte[CommandAddr+2]) and byte[CommandAddr+3] == ">" and isDigit(byte[CommandAddr+4]) and isDigit(byte[CommandAddr+5]) 
               arg1 := (byte[CommandAddr+1]-"0")*10
               arg1 += (byte[CommandAddr+2]-"0")

               arg2 := (byte[CommandAddr+4]-"0")*10
               arg2 += (byte[CommandAddr+5]-"0")

               byte[@defaultroute+arg1] := arg2 & $FF
               valid~~
{
         ' these are best set in hardware really...
         
         if cmdbyte == "B" 'Dxx:yyyy[-+] ' baud rate for port x is y
            if isDigit(byte[CommandAddr+1]) and isDigit(byte[CommandAddr+2]) and byte[CommandAddr+3] == ":" and isDigit(byte[CommandAddr+4]) and isDigit(byte[CommandAddr+5]) and isDigit(byte[CommandAddr+6]) and isDigit(byte[CommandAddr+7]) 
               arg1 := (byte[CommandAddr+1]-"0")*10
               arg1 += (byte[CommandAddr+2]-"0")
               
               arg2 := (byte[CommandAddr+3]-"0")*1000
               arg2 += (byte[CommandAddr+4]-"0")*100
               arg2 += (byte[CommandAddr+5]-"0")*10
               arg2 += (byte[CommandAddr+6]-"0")
               if byte[CommandAddr+8] == "-"
                   byte[@inversions+arg1]:=%0011
               else
                   byte[@inversions+arg1]:=%0000
               long[@baudrates+(arg1*4)] := arg2 & $FF
               valid~~

         if cmdbyte == "P" 'Pxx:yy:zz ' pins for port x are y and z
            if isDigit(byte[CommandAddr+1]) and isDigit(byte[CommandAddr+2]) and byte[CommandAddr+3] == ":" and isDigit(byte[CommandAddr+4]) and isDigit(byte[CommandAddr+5]) and byte[CommandAddr+6] == ":" and isDigit(byte[CommandAddr+7]) and isDigit(byte[CommandAddr+8]) 
               arg1 := (byte[CommandAddr+1]-"0")*10
               arg1 += (byte[CommandAddr+2]-"0")
               
               arg2 := (byte[CommandAddr+4]-"0")*10
               arg2 += (byte[CommandAddr+5]-"0")

               cmdbyte += (byte[CommandAddr+7]-"0")*10
               cmdbyte += (byte[CommandAddr+8]-"0")
               
               byte[@inputpins+(arg1*4)] := arg2 & $FF
               byte[@outputpins+(arg1*4)] := cmdbyte & $FF
               valid~~
}
         if (valid)
             BuildAddress(origin,@okstr)
             output(@okstr,router)
         else
             errcode:="U"
             BuildAddress(origin,@errstr)
             output(@errstr,router)

pri output(StringAddr,origin) | size, address, dobbout, sta

     
     address := defaultaddress ' default to term. Could also default to bit bucket if desired?
     dobbout := (origin <> term)

     if byte[StringAddr] == delimchar and byte[StringAddr+3] == delimchar    ' we got an address indicator, so generate an address. Default is send to terminal. Invalid addresses will be sent to terminal.
        address := (byte[++StringAddr]-"0")*10
        address += (byte[++StringAddr]-"0")
        StringAddr+=2
        if (address > 99 or address < 0)
          address := defaultaddress ' default
     else
        if (dobbout==false)
           address := byte[@defaultroute + 12] 
        elseif (origin > -1 and origin < numbuffers) ' no address? then default to the specified static routing table.
           address := byte[@defaultroute + origin]
       

     removetermchar(StringAddr)
     size := strsize(StringAddr) 

     if (size < 1)
         return
         

     case address

      router:
        ExecuteRouterCommand(StringAddr,origin) ' no need to have an address in there because this is delivered locally

      aux0_cog1:
        CallAsyncCommand(StringAddr,origin)     ' no need to have an address in there because this is delivered locally


      ' devices 0 to 11
      0..constant(numbuffers-1):  ' the terminal may still want to know what goes on, so let's enable it to monitor things
       com.tx(address,delimchar)
       com.tx(address,"0"+origin/10)
       com.tx(address,"0"+origin//10)
       com.tx(address,delimchar)
       sta := StringAddr
       repeat size
         com.tx(address,reformat(byte[sta++],address))
       com.tx(address,delimchar)
       com.tx(address,termichar)
       
      ' terminal
      term:
       dobbout~
       terminal.tx(delimchar)
       terminal.tx("0"+origin/10)
       terminal.tx("0"+origin//10)
       terminal.tx(delimchar)
       sta := StringAddr
       repeat size
         terminal.tx(reformat(byte[sta++],term))
       terminal.tx(delimchar)
       terminal.tx(termichar)

      ' devices 0 to 11, with stealth mask 
      stealthmask..constant(stealthmask+numbuffers-1):  ' the terminal may still want to know what goes on, so let's enable it to monitor things
       sta := StringAddr
       repeat size
         com.tx(address-stealthmask,reformat(byte[sta++],address))
       com.tx(address-stealthmask,termichar)

      ' terminal with stealth mask
      stealthmask+term:
       dobbout~
       sta := StringAddr
       repeat size
         terminal.tx(reformat(byte[sta++],term))
       terminal.tx(termichar)

      devnull: ' always nothing
      other: ' everything else: currently bit bucketed, unless terminal is monitoring it, see below

if(dobbout and bigbrother)
           terminal.tx(delimchar)
           terminal.tx("0"+origin/10)
           terminal.tx("0"+origin//10)
           terminal.tx(">")
           terminal.tx("0"+address/10)
           terminal.tx("0"+address//10)
           if (bigbrother>1)
               terminal.tx(delimchar)
               sta := StringAddr
               repeat size
                  terminal.tx(reformat(byte[sta++],term))
           terminal.tx(delimchar)
           terminal.tx(termichar)

pri CallAsyncCommand(CommandAddr,origin)
  if (aux0_busyflag)                      ' synchronously say that the other core is busy
     BuildAddress(@busystr,origin)
     output(@busystr,aux0_cog1)
  else
     bytemove(@aux0_buffer_rx,CommandAddr,buffersize) ' deliver the command to the virtual com port
     aux0_lastorigin:=origin
     aux0_rxflag~~
    
pri removetermchar(StringAddr) : i
    i := StringAddr
    repeat strsize(StringAddr)
       if (byte[i] == termichar or byte[i] == termichar2)
           byte[i] := 0 '32
       i++

pri reformat (ByteVal, destinationport) ' how about doing per-string instead of per-character? Probably faster...

    if (doupcase and ByteVal > constant("a"-1) and ByteVal < constant("z"+1))
         ByteVal-=$20
    if (dolowcase and ByteVal > constant("A"-1) and ByteVal < constant("Z"+1))
         ByteVal+=$20

{
    if (doupcase)
       ByteVal := upcase(ByteVal)
    elseif (dolowcase)
       ByteVal := lowcase(ByteVal)
}
    return ByteVal

pri upcase(ByteVal)
'' go to uppercase, 1 character -- that's all it does (used in parsing)

    if (ByteVal > constant("a"-1) and ByteVal < constant("z"+1))
         return (ByteVal-$20)
    return ByteVal
{
pri lowcase(ByteVal)
'' go to uppercase, 1 character -- that's all it does (used in parsing)

    if (ByteVal > constant("A"-1) and ByteVal < constant("Z"+1))
         return (ByteVal+$20)
    return ByteVal
}
pri BuildAddress(num,where) 
    byte[where] := delimchar
    byte[where+1] := "0"+num/10
    byte[where+2] := "0"+num//10
    byte[where+3] := delimchar
pri isDigit(char)
    if (char > "9" or char < "0")
       return false
    return true

con







































dpin = 26       'both din and dout of the mcp3208 are connected to this pin on the prop demo board.
cpin = 27       'the clock pin of the mcp3208 is connected to this pin on the prop demo board.
spin = 28       'the chip select pin of the mcp 3208 is connected to this pin on the prop demo board.
batLevCH=0      'battery level channel on the ADC
opStCh=1        'operational state channel on the ADC


' auxilliary cog functions here. This can be treated pretty much like a normal standalone microcontroller.
' Exception: use aux0_com for serial output and, to xmit, do aux0_txflag~~ for serial receive, use reacttopacket and read aux0_buffer_rx.
' Note that a blocking function is OK and will not impair the rest of the router! (see example)
obj
aux0_com:       "stringoutput_external_buffer"
DIOB:           "Digital_IO_Board4"
cogCounter :    "COG_counter"
numbers:        "Numbers"
adc:            "MCP3208"
math    :       "FloatMath"
fstring :       "FloatString"
var  ' auxilliary cog variables
byte aux0_buffer_rx[buffersize]   ' receive buffer for aux0_ cog / virtual com port
byte aux0_rxpad
byte aux0_busyflag
byte aux0_rxflag ' did anything come in?
byte aux0_buffer_tx[buffersize]   ' transmit buffer for aux0_ cog / virtual com port
byte aux0_txpad  ' used by the aux0_ cog as "clear to send" tag
byte aux0_txflag
long aux0_cog
long aux0_lastorigin
'timing between messages
long termWaitTime
long bridgeWaitTime
'AIQB state variables
byte direction      'this indicates a read or write to the state
byte secondaryPower
byte auxDCPower
byte auxChargerPower
byte acPresence
word index          'this is used to pass the relay state to DIOB
long batteryLevel       
long currentState      

'counters
byte ii,jj,kk,sevSegCnt
'disecting the message into parts
byte messageType[buffersize]   'byte space for the message type;should never reach this size
byte values[buffersize]     'for storing the values of the incoming message
long decValues[buffersize]
byte commas[buffersize]     'notes the locations of commas in the message
byte numCommas,diobIndex

pri aux0_loop ' auxiliary cog function. Should not need modifications.
    aiqbP1Init     'initialize AIQB functions-comms already started above

    repeat
     aux0_Activities  'the aux0_Activity will keep looping even though there are no received packets; the buffer is updated when a new message comes in
     if (aux0_rxflag) ' we got something in buffer
         aux0_rxflag~
         aux0_busyflag~~
         aux0_ReactToPacket'(@aux0_buffer_rx,aux0_lastorigin)
         aux0_busyflag~
    cogstop(aux0_cog~ - 1)

pub aux0_Activities|char1 ' auxilliary cog loop cycle (gets looped by aux0_loop). You can treat this as its own microcontroller basically.
  
''repeat 'don't use without a condition else it blocks
  if aux0_buffer_rx[0]<>0 'was =="A" 'note that the aux0_buffer_rx does not get reset until a new message is received;also, the buffer does not include the address
    disectMessage
    boardResponse
    if strcomp(@messageType,string("state"))
      state

    'BIG NOTE:
    'everything happening after the echo info is sent to the Android device is heavily dependent on
    'bridgeWaitTime. Too low and the messsages will be skipped entirely and hence unpredicatable behaviour
    'will ensue. Is there a way to fix this?Maybe increase the baud?
    ''aux0_com.str(string("@50@$echo ...   string received:"))
    ''aux0_com.str(@messageType)                   'tx(byte[@aux0_buffer_rx][0])
    ''aux0_com.str(string(">>./COM0 ")) 'sending a string to the serialterminal
    ''aux0_txflag~~
    ''waitcnt(bridgeWaitTime+cnt)
    
    clearOld
  
 
pub aux0_ReactToPacket'(PacketAddr,FromWhere) ' auxilliary cog function called when the virtual internal serial port got something. aux0_buffer_rx contains it and aux0_lastorigin says where it's from.

    repeat 5

         if (++result & 1)
             BuildAddress(aux0_lastorigin,@okstr)
             'aux0_com.str(@okstr)                   'chris removed
         else
             errcode:="!"
             BuildAddress(aux0_lastorigin,@errstr)
             'aux0_com.str(@errstr)

         'aux0_com.str(string(" AUX COMMAND PROCESSED!",13))    'chris removed
         'aux0_txflag~~

         waitcnt(cnt+clkfreq) 'does this need to be 1sec?

Pri aiqbP1Init
  {--Initialize wait times for comms--}
  termWaitTime:=clkfreq/100     'the terminal misses messages when no wait time; this number is the lowest that works
  bridgeWaitTime:=clkfreq   'the bridge includes messages that weren't directed at it without a wait time; this number is the lowest that works

  {--Initialize IO board---}'this isn't necessary,it's just visually showing the board works
  diobIndex:=%11111111
  DIOB.Main(diobIndex)
  waitcnt(clkfreq+cnt)
  index:=%00000000
  DIOB.Main(index)

  {---Initialize 7-seg displays}
  dira[0..7]:=%11111111        'set left 7-seg to output
  dira[16..23]:=%11110111         'set right 7-seg to output

  {--initialize state variables--}
  secondaryPower:="0"     'all initial state vars are 0 since no power should be applied before logical analysis/user input
  auxDCPower:="0"
  auxChargerPower:="0"
  direction:="0"

  {--Indicate the router has started}
  aux0_com.str(string("@62@Prop1 Router Initialized",13))
  aux0_txflag~~
  waitcnt(termWaitTime +cnt)

  {--initialize the decimal/string converter--}
  numbers.Init
  {--initialize the 8channel ADC------}
  adc.start(dpin, cpin, spin, 255)  'Start the MCP3208 object and enable all 8 channels as

  {--determine how many cogs are free--}
  aux0_com.str(string("@62@Number of Free Cogs:"))
  aux0_com.dec(cogCounter.free_cogs)
  aux0_txflag~~
  waitcnt(termWaitTime +cnt)
  aux0_com.str(string("@62@ ",13))
  aux0_txflag~~
  waitcnt(termWaitTime+cnt)
  'Cog count:6 for router,1 for ADC, 1 free for object detection
  
Pri disectMessage

  ii:=0  'null these just in case
  jj:=0
  kk:=1   'need to start noting value locations after the 0th element, since that is the first value
  repeat strsize(@aux0_buffer_rx) 'determine the message type, and only go for as long as was the received message
    if aux0_buffer_rx[ii]==","
      ii++
      Quit
    messageType[ii]:=aux0_buffer_rx[ii]
    ii++

    'now that the first comma is reached, store the values, add zero terminator and note their locations
  repeat strsize(@aux0_buffer_rx)-ii
    values[jj++]:=aux0_buffer_rx[ii++]   'the first element of values, is that after the first comma, not including the first comma
    if aux0_buffer_rx[ii]==","
      commas[kk]:=jj+1  'when hitting a comma,replace with a 0 in values matrix, and note the next value start location
      values[jj]:=0 'need to add a 0 string terminator where the comma was, but no need to add the comma
      kk++
      jj++
      ii++

  numCommas:=kk     'this notes how many zeros, i.e. number of values sent -1

  ii:=0
  jj:=0

  'convert the values matrix from strings to decimals 
  repeat numCommas
    jj:=commas[ii]
    decValues[ii]:=numbers.FromStr(@values[jj], numbers#DEC)
    ii++

  ii:=0
  jj:=0
  kk:=1
Pri clearOld
    ii:=0                        'reset i for later index
    jj:=0
    kk:=1
    bytefill(@aux0_buffer_rx,0,buffersize) 'clear the buffer after use
    bytefill(@messageType,0,buffersize) 'clear the messageType bytes to be null bytes
    bytefill(@commas,0,buffersize)
    bytefill(@values,0,buffersize)
    bytefill(@decValues,0,buffersize)

Pri State|v1,v2,v3,v4
{{this code still needs to read the AC presence and battery level and then transmit that info
}}
  'debugging code
  aux0_com.str(string("@62@entering state commands",13))
  aux0_txflag~~
  waitcnt(termWaitTime+cnt)
  if ((decValues[dirVal]==1) OR (decValues[dirVal]==2))'only respond to a state command where direction is 1 or 0, else ignore
    'the the direction was 2, update state variables
    if(decValues[dirVal]==2) 

      'if the input is 1 or 2, update the corresponding state var;else, ignore
      if ((decValues[sepVal]==1) OR (decValues[sepVal]==2))'
        secondaryPower:=decValues[sepVal]
      if ((decValues[adpVal]==1) OR (decValues[adpVal]==2))
        auxDCPower:=decValues[adpVal]
      if ((decValues[acpVal]==1) OR (decValues[acpVal]==2))
        auxChargerPower:=decValues[acpVal]
      
      'update the DIOB with the new results
      if secondaryPower==2
        diobIndex:=%00000001
      else
        diobIndex:=%00000000
      if auxDCPower==2              
        diobIndex:=diobIndex+%00000010
      if auxChargerPower==2
        diobIndex:=diobIndex+%00000100
      'DIOB.Main(diobIndex)

    'read AC presence from DIOB and write state (if diobIndex has not changed, the state won't either)
    acPresence:=DIOB.Main(diobIndex)

    'read battery level  
    batteryLevel:=math.FFloat(adc.in(batLevCh))                          'first convert the integer to a float
    batteryLevel:=math.FDiv(math.FMul(batteryLevel, 20.15),4096.0)       'convert the float to a voltage 
                                                                         'NOTE:20.15 is the multiply factor for the battery and voltage divider circuit on the AIQB
                                                                         'the 4096.0 is top bin number of the ADC and the .0 is required for the floating point math
    'read current operational state  
    currentState:=math.FFloat(adc.in(opStCh))'opStCh                         'first convert the integer to a float
    currentState:=math.FDiv(math.FMul(currentState, 5.015),4096.0)           'the 5.015 was determined through guess and matched the volmeter reading
    'currentState:=math.FTrunc(currentState)                                   'round the float to an integer for determining operational state
    if (math.FSub(currentState,3.0)>0)
      currentState:=2   'on and practice
    elseif (math.FSub(currentState,1.0)<0)
      currentState:=3   'should be 13 on and driving
    else
      currentState:=4   'should be 14 somewhere between driving and practice mode
      
    'convert new state variables to strings for transmission and send to ASD
    aux0_com.str(string("@50@$echo data,variable,secondaryPower,"))
    aux0_com.tx(byte[numbers.ToStr(secondaryPower, numbers#DEC)][1])                   'tx(byte[@aux0_buffer_rx][0])
    aux0_com.str(string(",auxDCPower,"))
    aux0_com.tx(byte[numbers.ToStr(auxDCPower, numbers#DEC)][1])
    aux0_com.str(string(",auxChargerPower,"))
    aux0_com.tx(byte[numbers.ToStr(auxChargerPower, numbers#DEC)][1])
    aux0_com.str(string(",acPresence,"))
    aux0_com.tx(byte[numbers.ToStr(acPresence, numbers#DEC)][1])
    aux0_com.str(string(",batteryLevel,")) 
    aux0_com.str(fstring.FloatToString(batteryLevel))
    aux0_com.str(string(",currentState,")) 
    aux0_com.tx(byte[numbers.ToStr(currentState, numbers#DEC)][1])
    aux0_com.str(string(">>./COM0 ")) 'sending a string to the serialterminal
    waitcnt(bridgeWaitTime+cnt)
    aux0_txflag~~
    waitcnt(bridgeWaitTime+cnt)

Pri boardResponse
  'show what is stored in the messagType variable
  aux0_com.str(string("@62@Message Type determined to be:"))
  aux0_com.str(@messageType)
  aux0_com.str(string(13))
  aux0_txflag~~
  waitcnt(termWaitTime+cnt)
  
 'note how many commas, and hence values, were sent
  aux0_com.str(string("@62@Number of Commas:"))
  aux0_com.dec(numCommas)
  aux0_com.str(string(13))
  aux0_txflag~~
  waitcnt(termWaitTime+cnt)
  
 'display the converted string values that are now decimals, in the decValues matrix
  ii:=0
  repeat numCommas
    aux0_com.str(string("@62@Value "))
    aux0_com.dec(ii)
    aux0_com.str(string(":"))
    aux0_com.dec(decValues[ii])
    aux0_com.str(string(13))
    aux0_txflag~~
    waitcnt(termWaitTime+cnt)
    ii++
  'display the message type and the first value on the board via the seven segment LEDs
  ii:=0
  jj:=0
  repeat msgN
      if strcomp(@messageType,@msgType[ii])
        outa[0..7]:=byte[@msgTypeDispNum][jj]
        QUIT
      ii:=ii+strsize(@msgType[ii])+1 'says to add the string size plus 1 to the current index; the plus 1 is due to the zero terminator after every string
      jj++
      if jj==msgN   'indicate that the received message wasn't in the acceptable list by displaying the "dot"
        outa[0..7]:=%00010000

  if jj<msgN        'if the message was within the list, display the first value
      ii:=0 
      repeat 10 'msgV, which is total number of displayable values(0 to 9)
        if (decValues[0]==msgValue[ii]) 'strcomp(@values,@msgValue[ii])
          outa[16..23]:=byte[@msgValueDispNum][ii]
          QUIT
        ii++'ii:=ii+strsize(@msgValue[ii])+1
  else
      outa[16..23]:=%00000000
        
    'outa[0..7]:=byte[@msgTypeDispNum][sevSegCnt]
    'outa[16..23]:=byte[@msgValueDispNum][sevSegCnt++]    
   
DAT 'this was inserted by CHRIS and is used for AIQB data
null byte %00000000   'used for turning off the 7-segment displays

{The following numbers correspond to the green 7-segment display (left side)on the AIQB Propeller1.
The assigned values correspond to pin0 through 7, from left to right. Also, note that these are given
in tens of values rather than single digits; it's because this display is on the left in the tens location
when using both 7-segment displays
}
  'uncomment the following 2 lines and comment their "live copies" in order to revert to message names being numbers
  msgN byte 1 'the number of messages in msgType
  msgType byte "state",0          
  'msgType byte "hundred",0,"ten",0,"twenty",0,"thirty",0,"fourty",0,"fifty",0,"sixty",0,"seventy",0,"eighty", 0,"ninety",0
  msgTypeDispNum byte %11101110, %00101000, %11001101, %01101101, %00101011, %01100111, %11100111, %00101100, %11101111, %00101111
  'state

  
{The following numbers correspond to the red 7-segment display (right side)on the AIQB Propeller1.
The assigned values correspond to pin16 through 23, from left to right;
NOTE:pin 20 is burned out at present so DO NOT TURN ON pin 20!
}
  msgV byte 10
  msgValue byte 0,1,2,3,4,5,6,7,8,9
  msgValueDispNum byte %01110111, %00010100, %10110011, %10110110, %11010100, %11100110, %11100111, %00110100, %11110111, %11110100
{Breakdown of Commands}
'State command structure: state,secondaryPower,auxDCPower,auxChargerPower,direction
'example: state,2,1,2,2 will cause the AIQBP&X to turn on secondary power and auxChargerPower but not auxDCPower
'and then the AIQBP&X will send a string containing the new state data to the ASD
'NOTE:0 isn't off and 1 isn't on because a patial message like state, could turn everything off randomly since
'the decValues var always resets to 0; hence, state changes only occur when intentionaly and hence 1=off, 2=on
             'state:saved to messageType
sepVal byte 0'secondaryPower: 1=off, 2=on
adpVal byte 1'auxDCPower:     1=off, 2=on
acpVal byte 2'auxChargerPower:1=off, 2=on
dirVal byte 3'direction:     :1=read only; 2=write to state and then read new state