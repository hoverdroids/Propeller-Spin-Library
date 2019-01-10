'' *****************************
'' SOURCE: http://obex.parallax.com/object/413
''
'' GPS routines
''  (c) 2007 Perry James Mole
''  pjm@ridge-communications.ca
''
''  Tim Moore May 2008
''    Support app COG
''    Fix some bugs
''    Merge in FV-E8 support (WAAS, switch to 38400 baud, etc)
''    Use pcFullduplexserial4
'' *****************************

' PVH Comment - Excellent small GPS reader routines.
' $GPRMC  Recommended minimum data                 ie: $GPRMC,081836,A,3751.6565,S,14507.3654,E,000.0,360.0,130998,011.3,E*62
' $GPGGA  GPS Fix Data                             ie: $GPGGA,170834,4124.8963,N,08151.6838,W,1,05,1.5,280.2,M,-34.0,M,,,*75
' $PGRMZ  eTrex proprietary barametric altitude ft ie: $PGRMZ,453,f,2*18

CON
  CR = 13                                             ' ASCII <CR>
  LF = 10                                             ' ASCII <LF>

' NMEASTate
  WAITFORSTARTLINE = 0
  WAITFORENDLINE   = 1
    
VAR  
   long gps_stack[10] 
   byte GPRMCb[68],GPGGAb[80],PGRMZb[40]   
   long GPRMCa[20],GPGGAa[20],PGRMZa[20]   

   byte gps_buff[80]',cksum
   long cog,cptr,ptr,arg,j,Rx
   long Null[1]
   long NMEAState
   long port
         
OBJ
  'Init, AddPort and Start need to be called for this object from main COG
  uarts :  "pcfullduplexserial4FC"

PUB Start(portp) : okay
'' Starts uart object (at baud specified) in a cog
'' -- returns false if no cog available
  okay := Init(portp)

  return cog := cognew(readNEMA,@gps_stack) + 1 

PUB Init(portp) : okay
''Init GPS serial without a COG to read from port
''If app calls this directly rather than Start then app needs to call GetNMEALine repeatly
  port := portp
  NMEAState := WAITFORSTARTLINE
  Null[0] := 0

PUB configbaud
  waitcnt(clkfreq + cnt)                             'Delay while serial initializes
  uarts.str(port,string("$PMTK251,38400*27",CR,LF))    'configure my GPS to use 38400 baud
  uarts.txflush(port)                                  'Wait until all chars txed
  waitcnt(clkfreq + cnt)                             'delay for last char to be sent

'split into separate config since some of these will not work until baud rate has been changed
PUB configgps
  waitcnt(clkfreq + cnt)                             'Delay while serial initializes
  'configure my GPS to send only the strings i want (GGA and RMC)
  uarts.str(port,string("$PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*28",CR,LF))
  uarts.str(port,string("$PMTK313,1*2E",CR,LF))        'configure my GPS to use WAAS
  uarts.str(port,string("$PMTK301,2*2E",CR,LF))        'configure my GPS to use WAAS
  uarts.str(port,string("$PMTK220,200*2C",CR,LF))      'configure my GPS to update at 5Hz

PUB readNEMA
' if start is called this processes reads from GPS on a COG
  repeat
    GetNMEALine
      
PUB GetNMEALine
'Needs to be called often enough that uart rx buffer doesn't overflow
'May never return if serial receive rate is faster than processing rate

  'process all characters in uart receive buffer
  repeat while (Rx := uarts.rxcheck(port)) <> -1
    uarts.tx(0,Rx)
    'uarts.hex(0,Rx,2)
    'uarts.tx(0," ")
    CASE NMEAState
      WAITFORSTARTLINE:
        if Rx == "$"                      'wait for the $ to insure we are starting with
          NMEAState := WAITFORENDLINE     'a complete NMEA sentence
          longfill(@gps_buff,0,20)        'empty line buffer
          cptr := 0
      WAITFORENDLINE:
        CASE Rx                           'continue to collect data until the end of the NMEA sentence
          "," :
            gps_buff[cptr++] := 0         'If "," replace the character with 0
          CR:
            ProcessNMEALine               'Process the just received line
            NMEAState := WAITFORSTARTLINE 'Start looking for start of NMEA line
          OTHER:
            gps_buff[cptr++] := Rx        'else save the character        

PUB ProcessNMEALine
   
  if gps_buff[2] == "G"             
    if gps_buff[3] == "G"            
      if gps_buff[4] == "A"            
        copy_buffer(@GPGGAb, @GPGGAa)
   
  if gps_buff[2] == "R"             
    if gps_buff[3] == "M"            
      if gps_buff[4] == "C"           
        copy_buffer(@GPRMCb, @GPRMCa)
   
  ' Garmin specific                   
  if gps_buff[0] == "P"
    if gps_buff[1] == "G"  
      if gps_buff[2] == "R"
        if gps_buff[3] == "M"  
          if gps_buff[4] == "Z"
            copy_buffer(@PGRMZb, @PGRMZa)
               
pub copy_buffer (buffer,args)
  bytemove(buffer,@gps_buff,cptr)   'copy received data to buffer
  ptr := buffer
  arg := 0
  repeat j from 0 to 78             'build array of pointers
    if byte[ptr] == 0               'to each
      if byte[ptr+1] == 0           'record
        long[args][arg] := Null     'in 
      else                          'the
        long[args][arg] := ptr+1    'data buffer
      arg++
    ptr++
   
' now we just need to return the pointer to the desired record
pub altitude
   return PGRMZa[0]

pub valid
   return GPRMCa[1]
      
pub speed
   return GPRMCa[6]

pub heading
   return GPRMCa[7]
   
pub date
   return GPRMCa[8]
    
pub GPSaltitude
   return GPGGAa[8]

pub time
   return GPGGAa[0]

pub latitude
   return GPGGAa[1]
    
pub N_S
   return GPGGAa[2]
     
pub longitude
   return GPGGAa[3]
    
pub E_W
   return GPGGAa[4]

pub satellites
   return GPGGAa[6]
    
pub hdop
   return GPGGAa[7]

pub vdop
   return GPGGAa[14]
'   return GPGSAa[14]

pub noGPSData
   GPRMCa.long[1] := string("X")

PUB crc8bitwise(pBuf, buflen, poly, initial): crc | i,k
'pBuf is the string to be CRCs
'buflen is thelength of th ebuffer to be CRCd
'poly is the ?
'initial is the inital value of CRC
 
  crc := initial
  repeat i from 0 to buflen - 1
    crc ^= (BYTE[pBuf][i] >< 8)
    repeat k from 0 to 7
      if crc & $80
        crc := (crc << 1) ^ poly
      else
        crc <<= 1
  crc &= $ff
  crc ><= 8
 
