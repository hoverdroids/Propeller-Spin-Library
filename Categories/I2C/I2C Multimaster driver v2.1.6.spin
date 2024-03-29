{{
OBEX LISTING:
  http://obex.parallax.com/object/700

  Includes Spin-based and PASM-based open-drain and push-pull drivers, with methods for reading and writing any number of bytes, words, and longs in big-endian or little-endian format.  All drivers tested with the 24LC256 EEPROM, DS1307 real time clock, MMA7455L 3-axis accelerometer, L3G4200D gyroscope module, MS5607 altimeter module, and BMP085 pressure sensor.  Includes a demo programs for each.

  Also includes a polling routine that displays the device address and name of everything on the I2C bus.

  Also includes a slave object that runs in a PASM cog with a Spin handler, and provides 32 byte-sized registers for a master running on another device to write to and read from.  Tested okay up to 1Mbps (max speed of my PASM push-pull object).  Includes demo for the slave object.

  Newly added multi-master object that can share the bus with other masters, provided of course that the other masters also allow sharing.
}}
{{┌──────────────────────────────────────────┐
  │ I2C multi-master driver with slave  2.1.6│      This routine requires the use of pull-up resistors on the SDA and SCL lines 
  │ Author: Chris Gadd                       │      - Does NOT work with the EEPROM on the demo board, which only has a pull-up on SDA
  │ Copyright (c) 2013 Chris Gadd            │      - This version supports clock stretching between the data byte and the ack bit
  │ See end of file for terms of use.        │          clock-stretching after the ack bit will cause this driver to abort, as that might also be caused by 
  └──────────────────────────────────────────┘          a second master attempting to transmit

  This object creates an I2C driver that is able to share the I2C bus with other masters - provided that the other masters also support multi-master sharing
    Before transmitting, this master ensures that another master isn't transmitting by monitoring the bus for an idle condition for 25 - 127us.
    If this master and another master attempt to transmit at precisely the same time, whichever master releases the clock or data lines first loses arbitration.
     If this master loses arbitration, it waits for the bus to idle for 25 - 127us before attempting again.

   This object was written to be as tolerant of other masters as possible, though it's still entirely possible that collisions might occur
     This master waits for the bus to idle for between 25 and 127us, which is a pseudo-random time delay in order to reduce the possiblity of repeated collisions
     Once the time delay has elapsed, the master begins transmitting, while continuing to monitor the SDA and SCL lines.
     If the master detects a low on SDA or SCL while they're supposed to be high, it aborts the transmission.
       The master allows a short amount of time (1/4 bit-width) for SCL to float high
     SCL is not checked for a low during the acknowledge bit, as that might also be caused by a slave device stretching the clock
   If the other master isn't written as tolerant and proceeds to transmit while this master is also transmitting, the transmitted data is likely to be corrupted.
     It is possible that a slave device might try to acknowledge a corrupted message or mis-interepret it as a read request, which actually happened during testing
       In that instance, the slave device might hold SDA low while waiting for further clocks that the master won't ever send until SDA idles high
       To prevent that, this master waits between 25 and 127us for SDA to go high, resetting the timer whenever SCL toggles
       If the time delay elapses, this master toggles SCL until SDA floats high, effectively flushing the data out of SDA

   When not transmitting, this object acts as a slave and listens for a start bit from another master.
     This device uses a 7-bit ID + read/write bit and an 8-bit register address - though only 32 registers are supported in this version
     Supports single, repeated, and page reads and writes
     The master cannot talk to its own slave through I2C
       In order to write and read values to and from the slave registers, the parent object can use the put and get methods       

  To use:
    I2C.start(28,29,100_000,$42)                    Start the I2C driver using p28 for clock, p29 for data, at 100Kbps, and with slave device address $42          
   Master methods:                                                                                                                                                 
    I2C.write(I2C#EEPROM,$0123,$45)                 Write $45 to EEPROM address $0123 
    I2C.write_page(I2C#EEPROM,$0123,@Array,500)     Write 500 bytes from Array to EEPROM starting at address $0123
    I2C.command(I2C#Alt,$48)                        Issue command to 'convert D1' to a MS5607 altimeter (Altimeter is the only device, so far discovered, that needs this routine)
    I2C.read(I2C#EEPROM,$0123)                      Returns a byte read from EEPROM address $0123
    I2C.read_next(I2C#EEPROM)                       Returns a byte read from EEPROM address $0124 (the next address following a 'read')
    I2C.read_page(I2C#EEPROM,$0123,@Array,500)      Read 500 bytes from an EEPROM starting at address $0123 and store each byte in Array
   Slave methods:
    I2C.check                                       Returns the index (31-0) of the highest byte in the register that was written to by a master                 
                                                     Subsequent calls to check return the index of the next highest byte with new data                    
    I2C.check_reg(5)                                Returns the contents of register 5 only if the new-data flag for that register is set, returns -1 otherwise  
    I2C.get(10)                                     Returns the value of register 10                                                                             
    I2C.put(11,#2)                                  Stores the value 2 in register 11                                                                            
    I2C.flush                                       Clears all 32 registers to 0                                                                                 
    I2C.address                                     Returns the base address of the slave registers - useful for directly operating on the registers             
                                                     by higher-level objects                                                                                    
   
    This routine performs ACK polling to determine when a device is ready.
    Routine will abort a transmission if no ACK is received within ~8ms of polling - prevents I2C routine from stalling if a device becomes disconnected
    No other ACK testing is performed
      If transmission is successful, _command var will be set to $FF
      If transmission is aborted, _command var will be set to 0                                                      ┌──────────────────────────────────────────┐
      All methods except read and read_next return _command as the result in order to test by the calling method.    │ if not I2C.command(EEPROM,0)             │
        (read and read_next return the read values)                                                                  │   FDS.str(string("EEPROM not present"))  │
                                                                                                                     └──────────────────────────────────────────┘
    This routine automatically uses two bytes when addressing an EEPROM.  EEPROM is the only device, so far discovered, that uses two-byte addresses.
                 
'----------------------------------------------------------------------------------------------------------------------
  This object uses a four step count for every bit sent.
    T0 - Put bit to be sent on the SDA pin if writing, float if reading data or Ack/NAK
    T1 - Float SCL pin (already floating on start)
    T2 - Sample SDA pin if reading data or Ack/NAK, or set/release SDA pin for start/stop 
    T3 - Pull SCL pin low (except on stop)

    Bit diagram:  
        ┌─Start─┬─1-bit─┬─0-bit─┬─Read──┬─Ack(r)┬─Ack(t)┬──NAK──┬─Stop──┐         
    SCL          
    SDA ───────────────  
        0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3    
                                                                                 
                                    sample  sample         
  The command, bytes_counter, device, address, and data / data_pointer are read into the PASM cog before I2C transmission starts
         
}}                                                                                                                                                
CON
'Device codes
  EEPROM = %0101_0000           ' Device code for 24LC256 EEPROM with all chip select pins tied to ground
  RTC    = %0110_1000           ' Device code for DS1307 real time clock
  ACC    = %0001_1101           ' Device code for MMA7455L 3-axis accelerometer
  GYRO   = %0110_1001           ' Device code for L3G4200D gyroscope (SDO to Vdd)
  ALT    = %0111_0110           ' Device code for MS5607 altimeter (CS floating)

  IO     = %0010_0001           ' Device code for CY8C9520A IO port expander (Strong pull-up (330Ω or less on A0))
                                '  Pull-up required when using the CY8C9520A EEPROM device, addressed at 101_000a
  

'Jump table offsets  
  SINGLE_WRITE  = 1
  PAGE_WRITE    = 2
  SINGLE_READ   = 3
  REPEATED_READ = 4
  PAGE_READ     = 5
  SEND_COMMAND  = 6

VAR
  long  flags
  long  bit_ticks
  word  _bytes
  word  _address
  word  _data                   

  byte  _command
  byte  _device

  byte  _slave_address
  byte  SCL_pin
  byte  SDA_pin

  byte  register[32]
  byte  cog                    

PUB start(clk_pin, data_pin, bitrate, slave_add) : okay

  stop
  SCL_pin := clk_pin
  SDA_pin := data_pin
  bit_ticks := clkfreq / (bitrate * 4)
  _slave_address := slave_add
  
  okay := cog := cognew(@entry, @flags) + 1

PUB stop

  if cog
    cogstop(cog~ - 1)

PUB write(device,address,data)                                                  ' Write a single byte

  wait_for_ready                                                                ' Wait until completed operation                                                                               

  _device := device << 1
  _address := address
  _data := data                                                                 ' Setting _Command to other than 0 signals the PASM routine to load the _Device, _Address, and _Data values   
  _command := SINGLE_WRITE                                                      '  therefore, _Command must be set after the other parameters

  wait_for_ready
  result := _command                                                            ' Returns $FF if successful / $00 if no response from device (device not found)
  
PUB write_page(device,address,dataAddress,bytes)                                ' Write many bytes

  wait_for_ready                                                                
                                                                                
  _device := device << 1                                                        
  _address := address
  _data := dataAddress
  _bytes := bytes
  _command := PAGE_WRITE

  wait_for_ready
  result := _command

PUB command(device,comm)                                                        ' Write the device and address, no data.  Used in the altimeter

  wait_for_ready

  _device := device << 1
  _address := comm
  _command := SEND_COMMAND

  wait_for_ready
  result := _command
  
PUB read(device,address)                                                        ' Read a single byte

  wait_for_ready

  _device := device << 1
  _address := address
  _command := SINGLE_READ
  _data := 1
                    
  wait_for_ready
  result := _data

PUB read_next(device)                                                           ' Read from next address

  wait_for_ready

  _device := device << 1
  _command := REPEATED_READ

  wait_for_ready
  result := _data

PUB read_page(device,address,dataAddress,bytes)                                 ' Read many bytes

  wait_for_ready

  _device := device << 1
  _address := address
  _data := dataAddress
  _bytes := bytes
  _command := PAGE_READ

  wait_for_ready
  result := _command

PUB get_address
  return @register
 
PUB check : index
{{
  Returns the number of the highest byte that was written to:
    If an I2C master wrote to addresses 3 and 7 of the slave's buffer, #7 is returned
    The flag for the highest byte is then cleared, so a subsequent check would return #3
  Returns -1 if all updated byte addresses have been returned (no new data)
}}                                                                                      
  index := (>| flags) - 1                                                                    
  flags := flags & !(|< index)                          ' Clear the highest set bit         
  
PUB check_reg(index)
{{
  Returns the value of the indexed register if that register has new data
  Returns -1 otherwise
}}
                                 
  if |< index & flags
    flags := flags & !(|< index)
    return register[index]
  return -1

PUB get(index)
  return register[index]

PUB put(index,data)
  register[index] := data
  
PUB flush | i  
  flags~
  bytefill(@register,0,32)

PRI wait_for_ready | t

  t := cnt
  
  repeat until _Command == $00 or _Command == $FF                               ' _command is set to $FF upon success by PASM, or set to $00 if no response from device within 10ms
    if cnt - t > clkfreq / 10                                                  
      return false                                                              ' escape if no valid response from PASM routine (just in case--shouldn't ever happen) <-does happen at very low bitrates
  return true                                                                   '    

DAT                     org
entry
                        rdlong    _8ms,#0                                       ' read the clock frequency
                        shr       _8ms,#7                                       ' ~7.8ms abort delay (using cnt loop)
                        rdlong    idle_delay,#0
                        shr       idle_delay,#20                                ' ~20us idle delay (using djnz loop)
                        mov       t1,par                                        ' Load parameter addresses
                        mov       flags_address,t1
                        add       t1,#4
                        rdlong    I2C_bit_delay,t1
                        add       t1,#4
                        mov       loops_address,t1
                        add       t1,#2
                        mov       address_address,t1
                        add       t1,#2
                        mov       data_address,t1                            
                        add       t1,#2
                        mov       command_address,t1
                        add       t1,#1
                        mov       device_address,t1
                        add       t1,#1
                        rdbyte    slave_address,t1
                        shl       slave_address,#1
                        add       t1,#1                                   
                        rdbyte    t2,t1
                        mov       SCL_mask,#1                                   ' Create masks for clock and data pins                                                                                                               
                        shl       SCL_mask,t2                                                                                                                                                                                        
                        add       t1,#1                                                                                                                                                                                              
                        rdbyte    t2,t1
                        mov       SDA_mask,#1
                        shl       SDA_mask,t2
                        mov       idle_mask,SCL_mask
                        or        idle_mask,SDA_mask
                        add       t1,#1
                        mov       register_address,t1
'----------------------------------------------------------------------------------------------------------------------
main
                        call      #get_random                                   ' Get a number between 100 and 355 - not truly random, but random enough to ensure                                                                                              
                        andn      dira,idle_mask                                '  that two masters don't repeatedly interfere with each other.           
                        test      SDA_mask,ina                wc                                                                                    
          if_c          jmp       #:wait_for_idle                               
:wait_for_sda                                                                   ' Wait 25 - 89us for the SDA line to float high - not time critical so a djnz loop works fine
                        mov       t2,random_value                               ' This is to prevent a problem whereby a slave device might try to acknowledge
                        test      SCL_mask,ina                wz                '  a partial message or interpret it as a read and hold the SDA line low
:sda_loop                                                                       '  while waiting for another clock from the master that never comes
                        test      SDA_mask,ina                wc
          if_c          jmp       #:wait_for_idle                               ' Exit if SDA goes high
                        test      SCL_mask,ina                wc
          if_c_eq_z     jmp       #:wait_for_sda                                ' Reset timeout if clock toggles
                        djnz      t2,#:sda_loop
:flush_sda                                                                      ' Flush the SDA line if it remains high for 25 - 89us with no clocks detected
                        mov       cnt,I2C_bit_delay                             
                        add       cnt,cnt             
:flush_loop
                        waitcnt   cnt,I2C_bit_delay
                        xor       dira,SCL_mask
                        test      SDA_mask,ina                wc
          if_nc         jmp       #:flush_loop                                  ' Toggle SCL until SDA goes high
                        andn      dira,SCL_mask
:wait_for_idle
                        mov       t2,random_value                               ' Wait 40 - 142us before attempting a transmission to ensure that no other master is transmitting
:idle_loop                                                                      
                        test      idle_mask,ina               wz                
          if_z          jmp       #:wait_for_SDA                                ' Wait for the SDA line to go high if both SDA and SCL are low
                        test      SCL_mask,ina                wz
          if_z          jmp       #:wait_for_idle                               ' Reset timer if just SCL is low                      
                        test      SDA_mask,ina                wc                                
          if_nc         test      SCL_mask,ina                wz                
          if_nc_and_nz  jmp       #slave_start                                  ' Start bit detected if SDA goes low while SCL is high   
                        djnz      t2,#:idle_loop
:check_master_start
                        rdbyte    command_byte,command_address wz               ' Check the command register for a transmission
          if_z          jmp       #:check_slave_start                           ' command_byte is 0 if no transmission is ready
                        cmp       command_byte,#$FF           wz
          if_e          jmp       #:check_slave_start                           ' command_byte is FF if previous transmission aborted and no new transmission is ready
                        jmp       #master_start
:check_slave_start                                                              ' SCL 
                        test      SCL_mask,ina                wz                ' SDA 
          if_z          jmp       #:wait_for_idle                               ' Start bit missed if SCL goes low before SDA is detected low
                        test      SDA_mask,ina                wc
          if_nc         jmp       #slave_start                                  ' Start bit detected if SDA goes low while SCL is high
                        jmp       #:check_master_start
'======================================================================================================================
slave_start
                        call      #receive                                      ' Receive the 7-bit device ID and r/w flag
                        mov       t1,I2C_byte
                        and       t1,#%1111_1110                                ' clear the read/write flag and compare received                                 
                        cmp       t1,slave_address            wz                '  device address with assigned address
          if_ne         jmp       #main                                         ' Ignore the message if addresses don't match
                        call      #ack                                          '  otherwise, acknowledge and...
                        test      I2C_byte,#%0000_0001        wc                '  test read(1) or write(0) bit of device address
          if_nc         jmp       #:write
:read '(from_master)
                        call      #respond                                      ' The master sends an ACK or NAK in response to
                        add       register_index,#1                             '  every byte sent back from the slave 
                        and       register_index,#31
                        mov       indexed_address,register_address
                        add       indexed_address,register_index
          if_nc         jmp       #:read                                        '  Send another byte if ACK (c=0)
                        jmp       #main                                         '  Stop if NAK (c=1)
:write '(from_master)
                        rdlong    t1,flags_address                              ' Use t1 to hold all flags
                        mov       t2,#1                                         ' Use t2 to hold the flag of the current register
                        mov       indexed_address,register_address              ' Prepare to store new data
                        call      #receive                                      ' First byte received is a register address
                        mov       register_index,I2C_byte
                        and       register_index,#31         
                        add       indexed_address,register_index
                        shl       t2,register_index                             ' Shift the flag to the appropriate register
                        call      #ack
:loop
                        call      #receive                                      ' Receive a data byte
                        wrbyte    I2C_byte,indexed_address                      ' Store in the addressed register
                        add       register_index,#1                             ' address the next register
                        and       register_index,#31
                        mov       indexed_address,register_address
                        add       indexed_address,register_index                                  
                        or        t1,t2                                         ' Update the flags
                        wrlong    t1,flags_address
                        rol       t2,#1                                         ' Shift the flag to the next register
                        call      #ack
                        jmp       #:loop
'----------------------------------------------------------------------------------------------------------------------
receive                                                                         '      (Read) 
                        mov       loop_counter,#7                               '            
                        mov       I2C_byte,#0                                   ' SCL 
                        waitpne   SCL_mask,SCL_mask                             ' SDA ───────
                        waitpeq   SCL_mask,SCL_mask
                        test      SDA_mask,ina                wc
                        rcl       I2C_byte,#1
          if_c          jmp       #:detect_restart                              ' The first bit of a received byte may be b7, 
:detect_stop                                                                    ' SCL       ' a stop, or a restart.             
                        test      SCL_mask,ina                wz                ' SDA       ' Not a stop or restart if          
          if_z          jmp       #:loop                                                            '  clock goes low without           
                        test      SDA_mask,ina                wz                                    '  data changing state              
          if_nz         jmp       #main                                                                                        
                        jmp       #:detect_stop
:detect_restart                                                                 ' SCL 
                        test      SCL_mask,ina                wz                ' SDA 
          if_z          jmp       #:loop
                        test      SDA_mask,ina                wz
          if_z          jmp       #slave_start
                        jmp       #:detect_restart
:loop
                        waitpne   SCL_mask,SCL_mask
                        waitpeq   SCL_mask,SCL_mask
                        test      SDA_mask,ina                wc
                        rcl       I2C_byte,#1
                        djnz      loop_counter,#:loop
receive_ret             ret
'----------------------------------------------------------------------------------------------------------------------
respond                                                                         '   (Write)      (Read ACK or NAK)
                        mov       loop_counter,#8                               '                             
                        rdbyte    I2C_byte,indexed_address                      ' SCL             
                        shl       I2C_byte,#32-8                                ' SDA  ───────           
:loop
                        waitpne   SCL_mask,SCL_mask
                        shl       I2C_byte,#1                 wc
                        muxnc     dira,SDA_mask
                        waitpeq   SCL_mask,SCL_mask
                        waitpne   SCL_mask,SCL_mask
                        djnz      loop_counter,#:loop
                        andn      dira,SDA_mask
'receive_ack_or_nak
                        waitpne   SCL_mask,SCL_mask
                        waitpeq   SCL_mask,SCL_mask
                        test      SDA_mask,ina                wc                ' C is set if NAK
                        waitpne   SCL_mask,SCL_mask                            
respond_ret             ret                                          
'----------------------------------------------------------------------------------------------------------------------
ack                                                                             ' SCL 
                        waitpne   SCL_mask,SCL_mask                             ' SDA 
                        or        dira,SDA_mask
                        waitpeq   SCL_mask,SCL_mask
                        waitpne   SCL_mask,SCL_mask
                        andn      dira,SDA_mask
ack_ret                 ret                        
'----------------------------------------------------------------------------------------------------------------------
nak                                                                             ' SCL    
                        waitpne   SCL_mask,SCL_mask                             ' SDA 
                        waitpeq   SCL_mask,SCL_mask
                        waitpne   SCL_mask,SCL_mask                             ' Send a NAK if the master tries addressing an out-of-range register
nak_ret                 ret                        
'======================================================================================================================
master_start
                        rdbyte    device_byte,device_address                                                                                      
                        mov       t1,command_byte                                                                                                 
                        add       t1,#:jump_table                               ' Use value in Command_byte (1-6) to                              
:jump_table             jmp       t1                                            '  determine which routine to jump to                             
                        jmp       #:write_byte                                                                                                    
                        jmp       #:write_page                                                                                                    
                        jmp       #:read_byte                                                                                                     
                        jmp       #:read_next                                                                                                     
                        jmp       #:read_page                                                                                                     
                        jmp       #:send_command                                                                                                  
'......................................................................................................................                           
:write_byte
                        mov       loop_counter,#1                                                                                                 
                        mov       t2,data_address                               ' Retrieve the value to be sent from _data                        
                        jmp       #:write_entry                                                                                                   
:write_page
                        rdword    loop_counter,loops_address
                        rdword    t2,data_address                               ' Retrieve the values to be send from an array addressed by _data
:write_entry
                        call      #send_start                                   ' Send a start bit, device code, and address
:write_loop
                        rdbyte    I2C_byte,t2                                   ' Read from the _data var or from an array
                        call      #I2C_write                                    '  and send the byte
                        add       t2,#1                                         '  increment the array address
          if_nc         djnz      loop_counter,#:write_loop                     ' Repeat until all bytes are sent, or stop if NAK
                        call      #I2C_stop
                        jmp       #main
'......................................................................................................................
:read_byte
                        call      #send_start                                   ' Send a start bit, device code, and address
:read_next
                        mov       loop_counter,#1                               
                        mov       t2,data_address                               ' Store the read value in the _data var
                        jmp       #:read_entry
:read_page
                        call      #send_start                                   ' Send a start bit, device code, and address
                        rdword    loop_counter,loops_address
                        rdword    t2,data_address                               ' Store the read values in an array addressed by the _data var
:read_entry
                        mov       timeout,_8ms                                  ' This timeout is necessary as the read_next command doesn't use the 
                        add       timeout,cnt                                   '  send_start subroutine, and needs some other way to check for no response
:loop
                        mov       t1,timeout
                        sub       t1,cnt
                        cmps      t1,#0                       wc
          if_c          jmp       #No_response
                        call      #I2C_start                                    ' Send a start / restart
                        mov       I2C_byte,device_byte
                        or        I2C_byte,#1
                        call      #I2C_write                                    ' Send the device code with the read bit set
          if_c          jmp       #:loop
:read_loop
                        call      #I2C_read                                     ' Read a byte
                        wrbyte    I2C_byte,t2                                   '  and either store in _data or in an array
                        add       t2,#1                                         '  increment the array address
                        sub       loop_counter,#1             wz
          if_nz         call      #I2C_ack                                      ' Send an ack if reading more bytes
          if_nz         jmp       #:read_loop
                        call      #I2C_nak                                      ' Otherwise send a NAK
                        call      #I2C_stop                                     '  and stop
                        jmp       #main
'......................................................................................................................
:send_command
                        call      #send_start
                        call      #I2C_stop
                        jmp       #main
'======================================================================================================================
send_start
                        mov       timeout,_8ms                                  ' Prepare a 7.8ms timeout (prevents routine from hanging if a device
                        add       timeout,cnt                                   '  becomes disconnected or unresponsive)
:loop
                        mov       t1,timeout                                    ' Check if 7.8ms has elapsed
                        sub       t1,cnt                                        '  Abort if it has
                        cmps      t1,#0                       wc
          if_c          jmp       #No_response
                        mov       I2C_byte,device_byte                          ' Send the start bit and device code
                        call      #I2C_start                                    '  Device will respond with Ack or NAK if ready/not ready
                        call      #I2C_write                                      
          if_c          jmp       #:loop                                        ' Loop until device is ready (C is set if NAK)
                        mov       t1,device_byte                                ' Determine if device code is for EEPROM (%101_0xxx)
                        and       t1,#%1111_0000                                ' Clear chip select bits
                        cmp       t1,#%1010_0000              wz                ' Z is set if device is an EEPROM
          if_z          rdword    I2C_byte,address_address                      ' Send high byte of EEPROM address 
          if_z          shr       I2C_byte,#8
          if_z          call      #I2C_write
                        rdword    I2C_byte,address_address
                        call      #I2C_write
          if_c          jmp       #:loop                                        ' C is set if NAK (Some devices acknowledge the device code even when not ready)
send_start_ret          ret
'======================================================================================================================
I2C_start                                                                       ' SCL     
                        andn      dira,idle_mask                                ' SDA     
                        mov       target_cnt,I2C_bit_delay                      '     0 1 2 3     
                        add       target_cnt,cnt
:loop1                                                                          ' This loop allows time for the bus to float up to idle
                        test      idle_mask,ina               wc,wz
          if_nc_and_nz  jmp       #:loop2_init
                        mov       cnt,target_cnt
                        sub       cnt,cnt
                        cmps      cnt,#0                      wc
          if_nc         jmp       #:loop1
                        jmp       #main                                         ' Abort if bus doesn't return to idle within 1/4 bit-width
:loop2_init                                                                     ' This loop keeps the bus at idle for another 1/4 bit width 
                        mov       target_cnt,I2C_bit_delay
                        add       target_cnt,cnt
:loop2                                                                          
                        test      idle_mask,ina               wc,wz
          if_c_or_z     jmp       #main                                         ' Abort if bus leaves idle state
                        mov       cnt,target_cnt
                        sub       cnt,cnt
                        cmps      cnt,#0                      wc
          if_nc         jmp       #:loop2
:loop3_init                                                                     ' This loop ensures SCL is floating while SDA is low
                        or        dira,SDA_mask
                        mov       target_cnt,I2C_bit_delay
                        add       target_cnt,cnt
:loop3
                        test      SCL_mask,ina                wc
          if_nc         jmp       #main                                         ' Abort if SCL goes low
                        mov       cnt,target_cnt
                        sub       cnt,cnt
                        cmps      cnt,#0                      wc
          if_nc         jmp       #:loop3
                        or        dira,SCL_mask                                 ' Pull SCL low for final 1/4 bit width
                        mov       cnt,I2C_bit_delay
                        add       cnt,cnt
                        waitcnt   cnt,I2C_bit_delay                             ' Simple waitcnt works here as both lines are outputs and cannot be asserted high
I2C_start_ret           ret
'----------------------------------------------------------------------------------------------------------------------
I2C_write                                                                        '   (Write)      (Read ACK or NAK)
                        shl       I2C_byte,#24                                   '                      
                        mov       bit_counter,#8                                 ' SCL    
                        mov       cnt,I2C_bit_delay                              ' SDA  ───────  
                        add       cnt,cnt                                        '     0 1 2 3  0 1 2 3       
:Loop                                                                               
                        rcl       I2C_byte,#1                 wc               
                        muxnc     dira,SDA_mask
                        waitcnt   cnt,I2C_bit_delay                             
                        test      SDA_mask,ina                wz
          if_c_and_z    jmp       #main                                         ' lost arbitration if SDA is low while outputting a 1
                        andn      dira,SCL_mask
                        waitcnt   cnt,I2C_bit_delay                             
                        test      SCL_mask,ina                wz
          if_z          jmp       #main                                         ' lost arbitration if SCL is still low 1/4 bitwidth after setting it to float
                        waitcnt   cnt,I2C_bit_delay                             ' might want to ensure that SCL stays floating during this 1/4 bitwidth...
                        or        dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay
                        djnz      bit_counter,#:Loop
:Read_ack_or_nak
                        andn      dira,SDA_mask
                        waitcnt   cnt,I2C_bit_delay
                        andn      dira,SCL_mask
                        waitpeq   SCL_mask,SCL_mask                             ' wait for clock-stretching 
                        mov       cnt,I2C_bit_delay                             ' resync clock 
                        add       cnt,cnt                                                                             
                        waitcnt   cnt,I2C_bit_delay
                        test      SDA_mask,ina                wc                ' C is set if NAK
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay                                                                   
I2C_write_ret           ret
'----------------------------------------------------------------------------------------------------------------------
I2C_read                                                                        '      (Read) 
                        mov       cnt,I2C_bit_delay                             '               
                        add       cnt,cnt                                       ' SCL    
                        mov       bit_counter,#8                                ' SDA ───────   
:loop                                                                           '     0 1 2 3    
                        andn      dira,SDA_mask                                 
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SCL_mask
                        waitcnt   cnt,I2C_bit_delay                                           
                        waitpeq   SCL_mask,SCL_mask                             ' wait for clock-stretching 
                        mov       cnt,I2C_bit_delay                             ' resync clock
                        add       cnt,cnt                                                     
                        test      SDA_mask,ina                wc                ' Read
                        rcl       I2C_byte,#1                                   ' Store in lsb
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay
                        djnz      bit_counter,#:Loop                            ' Repeat until eight bits received
I2C_read_ret            ret                        
'----------------------------------------------------------------------------------------------------------------------
I2C_ack                                                                          
                        mov       cnt,I2C_bit_delay                             ' SCL  
                        add       cnt,cnt                                       ' SDA  
                        or        dira,SDA_mask                                 '     0 1 2 3  
                        waitcnt   cnt,I2C_bit_delay                              
                        andn      dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay   
I2C_ack_ret             ret
'----------------------------------------------------------------------------------------------------------------------
I2C_nak                                                                         '                           
                        mov       cnt,I2C_bit_delay                             ' SCL      
                        add       cnt,cnt                                       ' SDA      
                        andn      dira,SDA_mask                                 '     0 1 2 3      
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay                             
                        waitcnt   cnt,I2C_bit_delay                             
                        or        dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay                             
I2C_nak_ret             ret
'----------------------------------------------------------------------------------------------------------------------
I2C_stop
                        mov       cnt,I2C_bit_delay                             ' SCL  
                        add       cnt,cnt                                       ' SDA  
                        or        dira,SDA_mask                                 '     0 1 2 3  
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SDA_mask
                        waitcnt   cnt,I2C_bit_delay                             
                        waitcnt   cnt,I2C_bit_delay
                        mov       t1,#$FF
                        wrbyte    t1,command_address
I2C_Stop_ret            ret
'----------------------------------------------------------------------------------------------------------------------
no_response
                        mov       t1,#0
                        wrbyte    t1,command_address
                        jmp       #main
'======================================================================================================================
get_random
                        cogid     t1                                            ' cogid is primarily here for testing this same object on two cogs
                        add       random_value,cnt
                        ror       random_value,t1                                 
                        and       random_value,#255
                        add       random_value,#100
get_random_ret          ret
'======================================================================================================================
random_value            res       1
target_cnt              res       1

_8ms                    res       1                                     
command_address         res       1                                     
device_address          res       1                                     
address_address         res       1                                     
loops_address           res       1                                     
data_address            res       1                                     
command_byte            res       1
device_byte             res       1
SCL_mask                res       1                                             
SDA_mask                res       1                                             
I2C_bit_delay           res       1                                           
bit_counter             res       1
I2C_byte                res       1
loop_counter            res       1
t1                      res       1
t2                      res       1
timeout                 res       1
idle_delay              res       1
idle_mask               res       1

slave_address           res       1
flags_address           res       1
register_address        res       1
indexed_address         res       1
register_index          res       1



                        fit       496
DAT                     
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
