{{
 Source: http://obex.parallax.com/object/769

┌───────────────────────────────────────────────────┐
│ ParallelIO.spin version 1.0.0                     │
├───────────────────────────────────────────────────┤
│                                                   │               
│ Author: Mark M. Owen                              │
│                                                   │                 
│ Copyright (C)2014 Mark M. Owen                    │               
│ MIT License - see end of file for terms of use.   │                
└───────────────────────────────────────────────────┘

Description:

  Some simple mechansims for transmission of arrays of data in
  eight bit parallel chunks.  Sender/receiver synchronization is
  accomplished using a request to send (RTS) signal initiated by the
  sender. Upon sensing an RTS signal the receiver raises a clear to
  send signal (CTS) when it is ready to receive the data. The sender
  drops RTS once the data bits are set on the pins and waits for the
  receiver to drop CTS thereby indicating it has received the data.
  A checksum byte is calculated and transmitted following the last
  data byte.  The calculated checksum is returned to the caller and
  may be examined by calling GetResult.  In addition, upon completion
  of a receive the internally computed checksum can be examined by
  calling GetValue.  The receiver can thereby detect a parity error
  by comparing GetResult with GetValue.  If they disagree, a parity
  error has occurred. 

  The data are buffered in COG memory.  Methods are provided to load
  the buffer from hub RAM prior to transmission, transmit the buffer,
  receive a buffer and to unload the buffer to hub RAM. 

  The COG buffer is 1KB in size. As a result transmissions may not
  exceed that size (1024 bytes or 256 longs). It can however be
  increased up to 1380 bytes (345 longs) if needed by changing the
  constant MSIZE.  At MSIZE=345 all available cog memory is in use.

  This object requires one cog for operation.

  Clocked at ~390kBytes (3.12Mbits) per second on a pair of 80MHz
  Propeller systems sending 1,024 Byte blocks.  If you need more
  speed you can a) over-clock the processors; b) modify the TxWait
  function to reduce the pulse duration of the RTS and data signals
  or c) reduce the PIO_waitinc value in Start to shorten the wait
  time to less than its current ~476nS value.
  
  Requires 10 I/O pins for operation:
        RTS
        CTS
        MSB...LSB - eight contiguous pins

Test Schematic:

                     Prop1              Prop2        
                     220Ω                220Ω
          MSB    P0──────────────────P0  MSB
                 P1──────────────────P1
                 P2──────────────────P2
                 P3──────────────────P3
                 P4──────────────────P4
                 P5──────────────────P5
                 P6──────────────────P6
          LSB    P7──────────────────P7  LSB
         
          RTS    P8────────┬─────────P8  RTS
                                 10k
        ground  Vss──────────┼───────────Vss ground
                                 10k
          CTS    P9────────┴─────────P9  CTS
         
         Note: the pulldown resistors are not
         absolutely necessary and their values
         if present should be chosen to avoid
         dividing the signal voltage by any
         substantial factor.

Timing Diagram:
        
          RTS   transmitter controlled
          CTS   receiver controlled
          P0   ─────────── 
          P1   ─────────── 
          P2   ─────────── 
          P3   ─────────── 
          P4   ─────────── 
          P5   ─────────── 
          P6   ─────────── 
          P7   ─────────── 

Example Code:

  CON
        _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
        _xinfreq = 5_000_000                       ' external crystal 5MHz
         
        BUFFERSIZE     = PIO#MSIZE
        PACKETSIZELONGS= 256
        PACKETSIZEBYTES= PACKETSIZELONGS<<2

        DATpin        = 0             ' 0..7 data bits
        RTSpin        = 8             ' request to send pin
        CTSpin        = 9             ' clear to send pin
               
  OBJ
        PIO : "ParallelIO"
  VAR
        long  buffer[BUFFERSIZE]

  
   PUB ATransmitter
        PIO.Start(PIO#AS_TRANSMITTER,DATpin, RTSpin, CTSpin)
        PIO.LoadBuffer(@buffer,PACKETSIZELONGS)
        if not PIO.TransmitBuffer(PACKETSIZEBYTES)
          { deal with transmit timeout }
        else
          { do what you will with the buffer content }
        
  PUB AReceiver
        PIO.Start(PIO#AS_RECEIVER, DATpin, RTSpin, CTSpin)
        if PIO.ReceiveBuffer(PACKETSIZEBYTES)
          if PIO.GetResult <> PIO.GetValue ' checksum error
            { deal with the parity error }
          else
            PIO.UnloadBuffer(@buffer,PACKETSIZELONGS)
            { do what you will with the buffer content }
        else
          { deal with receive timeout }

  PUB AModeSwitcher
        {to switch modes}
        PIO.Start(<<true or false>>, DATpin, RTSpin, CTSpin)
        ..etc..

Errata:
  nada at present        

Revision History:

  Initial version 2014Nov27     - MMOwen
  Added checksum  2014Dec05     - MMOwen
  Added timeouts  2014Dec06     - MMOwen

}}

CON
  _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
  _xinfreq = 5_000_000                       ' external crystal 5MHz


{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  Start method constants                                                                           │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘} 
  AS_TRANSMITTER  = true
  AS_RECEIVER     = false

CON
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  assembly function routing commands                                                               │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘} 
  #1
  CMD_HUBtoCOG
  CMD_COGtoHUB
  CMD_Transmit
  CMD_Receive

{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  cog resident memory buffer size in longs                                                         │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘} 
  MSIZE = 256   ' 345 maximum with current assembly code structure

   
VAR
  long  cog

VAR
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  assembly parameters                                                                              │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
  long  DOcmd
  long  DOvalue
  long  DOresult

PUB Start(InOut,DATpin, RTSpin, CTSpin)
{{
    Initiates ParallelIO processor in a new COG 

    Parameters:
      InOut       - function to perform - false: receiver; true: transmitter
      DATpin      - first of 8 consecutive pins used for data transmission
      RTSpin      - request to send signal
      CTSpin      - clear to send signal

    Returns:
      cog number + 1 if pulse timer is successfully started
      zero if no cog is available
}}
  Stop                                                                                         
  PIO_DATpin  :=  DATpin
  PIO_DATmask := $FF << DATpin
  PIO_RTSmask := 1   << RTSpin
  PIO_CTSmask := 1   << CTSpin
  if InOut
    PIO_PinMask := PIO_DATmask | PIO_RTSmask
  else
    PIO_PinMask := PIO_CTSmask
  PIO_waitinc := clkfreq >> 21 ' 21:~0.4765625µS 20:~0.953125 19:~1.90625 18:~3.8125 17:~7.625 16:~15.25 µS
  DO_waitinc  := clkfreq >> 16 ' 14:~61µS  16:~15.25µS
  result := (cog := cognew(@DO, @DOcmd) + 1)

PUB Stop
{{
    Terminates the ParallelIO processor

    Parameters:   none
                  
    Returns:      nothing
}}                                                                                         
  if cog
    cogstop(cog~ - 1)

PUB GetResult
    return DOresult
    
PUB GetValue
    return DOvalue

PUB LoadBuffer(aData,nlongs)
{{
    Copies the contents of a buffer located in hub RAM to the
    COGs memory.
    
    Does not return to the caller until the command has completed.
    
    Sleeps in 10µS increments while waiting.

    Parameters:
      aData       - address of hub RAM buffer
      nlongs      - size (in longs) of hub RAM buffer

    Returns:      nothing         
}}                                                                                         
  DOvalue := aData<<9 | nlongs
  DOcmd := CMD_HUBtoCOG
  repeat until DOcmd == 0 ' indicates command has completed
    waitcnt(clkfreq/100_000+cnt)

PUB TransmitBuffer(nBytes) | tick
{{
    Transmits the contents of the buffer currently in the COGs memory. Prior
    to calling this method, use LoadBuffer(...) to transfer data into the
    buffer.
    
    Sleeps in 10µS increments while waiting.

    Parameters:
      nBytes      - number of bytes to be transmitted from the COGs buffer

    Returns:      1 - success : 0 - timed out
}}
  tick~                                                                                         
  DOvalue := nBytes
  DOcmd := CMD_Transmit
  repeat until DOcmd == 0 ' indicates command has completed
    waitcnt(clkfreq/100_000+cnt)
    tick++
    if tick => 2000
      DOcmd~
      return 0
  ' checksum as transmitted is in DOresult
  return 1

PUB ReceiveBuffer(nBytes) | tick
{{
    Receives data into the buffer in the COGs memory. To access the data
    call UnloadBuffer(...).
    
    Sleeps in 10µS increments while waiting.

    Parameters:
      nBytes      - number of bytes to be received to the COGs buffer

    Returns:      1 - success : 0 - timed out
}}
  tick~                                                                                         
  DOvalue := nBytes
  DOcmd := CMD_Receive
  repeat until DOcmd == 0 ' indicates command has completed
    waitcnt(clkfreq/100_000+cnt)
    tick++
    if tick => 1000
      DOcmd~
      return 0
  ' checksum as received is in DOresult
  ' calculated checksum is in DOvalue
  return 1

PUB UnloadBuffer(aData,nLongs)
{{
    Copies the contents of a buffer located in the COGs memory to 
    hub RAM.
    
    Does not return to the caller until the command has completed.
    
    Sleeps in 10µS increments while waiting.

    Parameters:
      aData       - address of hub RAM buffer
      nlongs      - size (in longs) of hub RAM buffer

    Returns:      nothing
}}                                                                                         
  DOvalue := aData<<9 | nlongs
  DOcmd := CMD_COGtoHUB
  repeat until DOcmd == 0 ' indicates command has completed
    waitcnt(clkfreq/100_000+cnt)

DAT
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                 COG Process Entry Point                                                                           │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
DO            ORG
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  extracting parameters                                                                            │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
              mov     t,          par
              mov     DO_aCmd,    t               ' hub address of DOcmd
              add     t,          #4                                                                   
              mov     DO_aValue,  t               ' hub address of DOvalue 
              add     t,          #4                                                                   
              mov     DO_aResult, t               ' hub address of DOresult 
              add     t,          #4
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  indirect command router                                                                          │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
              jmp     #DOit                                                                    
DOcompleted   wrlong  ZERO,       DO_aCmd         ' indicate completion                                    
DOsleep       mov     DO_waitto,  cnt                                                                  
              add     DO_waitto,  DO_waitinc
              waitcnt DO_waitto,  DO_waitinc      ' sleep
DOit          rdlong  DO_cmd,     DO_aCmd     wz  ' get requested command                              
              add     DO_cmd,     #:DOcmds        ' offset to command jump table                       
  if_z        jmp     #DOsleep                    ' then check again
                                      
:DOcmds       jmp     DO_cmd                      ' jump indirect to command + offset                                                             
              jmp     #HUBtoCOG
              jmp     #COGtoHUB
              jmp     #Transmit
              jmp     #Receive
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  hub -> cog memory blocks                                                                         │                                                                                    │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
HUBtoCOG      mov     M_cogaddr,  #M_buffer       ' set up initial target address                                  
              movd    :Mget,      M_cogaddr       ' set up initial target address                                  
              rdlong  M_hubaddr,  DO_aValue       ' hub synch fetch parameter data                                             
              mov     M_size,     M_hubaddr       ' extract size                                           
              and     M_size,     #$1FF           ' discard address bits                                  
              shr     M_hubaddr,  #9              ' discard size bits                                      
:Mget         rdlong  0-0,        M_hubaddr       ' hub synch; fetch long at current address to cog memory buffer               
              add     M_hubaddr,  #4              ' 4                                                      
              add     M_cogaddr,  #1              ' 4                                                      
              movd    :Mget,      M_cogaddr       ' 4 set up next target address                           
              djnz    M_size,     #:Mget          ' 4 if jump or 8 otherwise; should stay in synch          
              jmp     #DOcompleted
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                 hub <- cog memory blocks                                                                          │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
COGtoHUB      mov     M_cogaddr,  #M_buffer       ' set up initial target address
              movd    :Mput,      M_cogaddr       ' set up initial target address                                  
              rdlong  M_hubaddr,  DO_aValue       ' hub synch fetch parameter data                                             
              mov     M_size,     M_hubaddr       ' extract size                                           
              and     M_size,     #$1FF           ' discard address bits                                  
              shr     M_hubaddr,  #9              ' discard size bits                                      
:Mput         wrlong  0-0,        M_hubaddr       ' hub synch; fetch long at cog memory buffer to hub buffer
              add     M_hubaddr,  #4              ' 4                                                      
              add     M_cogaddr,  #1              ' 4                                                      
              movd    :Mput,      M_cogaddr       ' 4 set up next target address                           
              djnz    M_size,     #:Mput          ' 4 if jump or 8 otherwise; should stay in synch          
              jmp     #DOcompleted
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  parallel IO outbound transmission                                                                │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
Transmit      mov     outa,       #0
              mov     dira,       PIO_PinMask
              
              mov     PIO_checksum,#0             ' zero checksum accumulator
              
              rdlong  PIO_nbytes, DO_aValue       ' get size in bytes
              movs    :a,         #M_buffer       ' set up initial target address
              
:nextlong     mov     t,          #4              ' set up byte count for this long              
:a            mov     PIO_4bytes, 0-0             ' fetch 4 bytes

:nextbyte     mov     PIO_1byte,  PIO_4bytes      ' extract it
              and     PIO_1byte,  #$FF            ' mask off all but rightmost 8 bits
              
              xor     PIO_checksum,PIO_1byte      ' accumulate checksum
              
              shl     PIO_1byte,  PIO_DATpin      ' align
              call    #TxWait    
              or      outa,       PIO_RTSmask     ' raise RTS to tell receiver we have something to send
              waitpeq PIO_CTSmask,PIO_CTSmask     ' wait CTS high; receiver says its ready
              or      outa,       PIO_1byte       ' set data bits
              call    #TxWait    
              andn    outa,       PIO_RTSmask     ' drop RTS to let receiver know the data is present
              waitpne PIO_CTSmask,PIO_CTSmask     ' wait CTS; low receiver says its done with the io pins
              andn    outa,       PIO_DATmask     ' reset the databits; receiver is no longer using them
              ror     PIO_4bytes, #8              ' rotate next byte to send into rightmost 8 bits
              sub     PIO_nbytes, #1          wz  ' decrement size
    if_z      jmp     #:done
    
              sub     t,          #1          wz  ' decrement long's bytes unprocessed count
    if_z      add     :a,         INCRSRC         ' increment cog buffer address of next long to fetch
    if_z      jmp     #:nextlong
    
              jmp     #:nextbyte               
:done
              { transmit checksum }
              call    #TxWait    
              or      outa,       PIO_RTSmask     ' raise RTS to tell receiver we have something to send
              waitpeq PIO_CTSmask,PIO_CTSmask     ' wait CTS high; receiver says its ready
              or      outa,       PIO_checksum    ' set data bits
              call    #TxWait    
              andn    outa,       PIO_RTSmask     ' drop RTS to let receiver know the data is present
              waitpne PIO_CTSmask,PIO_CTSmask     ' wait CTS; low receiver says its done with the io pins
              andn    outa,       PIO_DATmask     ' reset the databits; receiver is no longer using them
              wrlong  PIO_checksum,DO_aResult     ' return checksum
              
              jmp     #DOcompleted
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  parallel IO pulse width control                                                                  │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
TxWait        mov     PIO_waitto, cnt             
              add     PIO_waitto, PIO_waitinc              
              waitcnt PIO_waitto, PIO_waitinc
TxWait_ret    ret
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  parallel IO incoming transmission                                                                │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
Receive       mov     outa,       #0
              mov     dira,       PIO_PinMask

              mov     PIO_checksum,#0             ' zero checksum accumulator
              
              rdlong  PIO_nbytes, DO_aValue       ' get size in bytes
              movd    :a,         #M_buffer       ' set initial destination address
              movd    :b,         #M_buffer
              movd    :c,         #M_buffer
              movd    :d,         #M_buffer
              
:nextlong     mov     t,          #4              ' set up byte count for this long
:a            mov     0-0,        #0              ' starts out empty

:nextbyte     waitpeq PIO_RTSmask,PIO_RTSmask     ' wait RTS high; transmitter has someting for us
              or      outa,       PIO_CTSmask     ' raise CTS; tell transmitter we are ready
              waitpne PIO_RTSmask,PIO_RTSmask     ' wait RTS low; transmitter says data is present
              mov     PIO_1byte,  ina             ' get data bits
              shr     PIO_1byte,  PIO_DATpin      ' align
              and     PIO_1byte,  #$FF            ' mask off all but rightmost 8 bits
              andn    outa,       PIO_CTSmask     ' drop CTS; tell transmitter we are done

              xor     PIO_checksum,PIO_1byte      ' accumulate checksum

:b            or      0-0,        PIO_1byte       ' stuff the data into current byte 
:c            ror     0-0,        #8              ' rotate to the next empty slot    
              sub     PIO_nbytes, #1          wz  ' decrement size
    if_z      jmp     #:done
  
              sub     t,          #1          wz  ' decrement long's bytes unprocessed count
              
    if_z      add     :a,         INCRDEST        ' increment cog buffer address where next long is to be stored
    if_z      add     :b,         INCRDEST        ' same address as :a
    if_z      add     :c,         INCRDEST        ' same address as :a
    if_z      add     :d,         INCRDEST        ' same address as :a
    if_z      jmp     #:nextlong
  
              jmp     #:nextbyte
              
:done         sub     t,          #1          wz  ' decrement long bytes count          
:d  if_nz     ror     0-0,        #8              ' some empty cells, rotate into position
    if_nz     jmp     #:done            

              { receive checksum }
              waitpeq PIO_RTSmask,PIO_RTSmask     ' wait RTS high; transmitter has someting for us
              or      outa,       PIO_CTSmask     ' raise CTS; tell transmitter we are ready
              waitpne PIO_RTSmask,PIO_RTSmask     ' wait RTS low; transmitter says data is present
              mov     PIO_1byte,  ina             ' get data bits
              shr     PIO_1byte,  PIO_DATpin      ' align
              and     PIO_1byte,  #$FF            ' mask off all but rightmost 8 bits
              andn    outa,       PIO_CTSmask     ' drop CTS; tell transmitter we are done
              wrlong  PIO_checksum,DO_aValue      ' return calculated checksum 
              wrlong  PIO_1byte,  DO_aResult      ' return received checksum
              
              jmp     #DOcompleted
              
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  general purpose values                                                                           │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
ZERO          long    0                                                                                
ONE           long    1
INCRDEST      long    %000000_0000_0000_000000001_000000000
INCRSRC       long    %000000_0000_0000_000000000_000000001
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  indirect command router                                                                          │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
DO_waitinc    long    0         ' wait increment on no command [supplied by spin Start method]                                                    
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  Parallel IO parameters                                                                           │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
PIO_DATpin    long    0         ' data IO pin number           [supplied by spin Start method]        
PIO_DATmask   long    $FF       ' data IO pin mask             [supplied by spin Start method]
PIO_RTSmask   long    1         ' request to send IO pin mask  [supplied by spin Start method]
PIO_CTSmask   long    1         ' clear to send IO pin mask    [supplied by spin Start method]
PIO_PinMask   long    0         ' DIRA IO configuration        [supplied by spin Start method]
PIO_waitinc   long    0         ' increment for next wait      [supplied by spin Start method]
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  scratch pad variables                                                                            │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
t             res               ' temporary variable
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  indirect command router                                                                          │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
DO_cmd        res               ' command to execute, 0 if none                                                     
DO_waitto     res               ' wait completion value                                                    
DO_aCmd       res               ' hub address of command                                                     
DO_aValue     res               ' hub address of command argument
DO_aResult    res               ' hub address of command result                                                     
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  Parallel IO variables                                                                            │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
PIO_nbytes    res               ' number of bytes to send or receive
PIO_1byte     res               ' internal buffer for the current byte
PIO_4bytes    res               ' internal buffer for four bytes
PIO_waitto    res               ' wait completion value (delay before RTS and after data)
PIO_checksum  res
{┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                  hub <-> cog memory blocks                                                                        │                                                                                     │
 └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘}                                                                                 
M_hubaddr     res               ' memory block hub address                                                    
M_cogaddr     res               ' memory block cog address                                                     
M_size        res               ' memory block size                                                     
M_buffer      res       MSIZE   ' cog resident memory buffer

              FIT

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}        
