{{
Demo of Fast Propeller Communication on a single Propeller
Chris: This Object connects a first prop to the computer using the FDSP and the serial terminal; then, it
connects to another propeller on the PX and RX pins.  This uses 3 cogs; 1 for TX and 1 for RX.

Process description:
1. Everything initializes; tx and rx are started in new cogs
2. Tx fills each of its longs in the TX_buff variable "array" with random values
3. After filling the array, it transmits them on the TX pin and gives time for the RX to receive the entire "long array"
4. The RX loop in the main object waits for the TX to fill and be received;
5. The RX loop in the main object then compares the data received to the random variables that should have come through
6. If the values that came through weren't as predicted, an error flag is sent to the terminal window
}}
CON

  { ==[ CLOCK SET ]== }
  _CLKMODE      = XTAL1 + PLL16X
  _XINFREQ      = 6_250_000

  RX_pin = 18'9
  TX_pin = 19'8

OBJ

  DEBUG  : "FullDuplexSerial"    
  PCRX   : "PROP_COMM_RX"
  PCTX   : "PROP_COMM_TX" 

VAR

  LONG tx_stack[30]             ' probably be safe at 22 longs

PUB Main | rx_buff, i, seed, v

  dira[20]:=1
  DEBUG.start(31, 30, 0, 57600) 'initializes fullduplex serial on said pins at said baud
  waitcnt(clkfreq + cnt)        'why is this waiting?
  DEBUG.tx($D)                  'transmit the number 13 ($D), meaning a carriage return in ASCII
  DEBUG.str(string("If 'Warning' shows up, input does not match expected value",$D))'i'm not sure why this is stated; CR after that notes next line 

  'cognew(tx, @tx_stack)         ' start transmit cog      'starts the tx object(defined below) at the stated stack location(defined above)

'' -----------------------------------------------------
'' setup recieve cog

  rx_buff := PCRX.recieve(RX_pin)                       ' start RX in new cog;and save the rxcog address 
  seed := $9876_5432                                    ' make sure it(the seed) is the same as tx cog<-how did they know this number?
                                                        'the above line is ONLY giving a seed value to the random num generator that will eventually be used
  REPEAT                                                'indefinitely loop through
    PCRX.waitrx_wd(100)                                 ' wait up to 100ms for information to be recieved.
    REPEAT i FROM 0 TO constant(PCRX#BUFFER_SIZE - 1)   'PCRX#BUFFER_SIZE is a constant defined in PCRX
      DEBUG.str(string(13,"the number is: "))
      DEBUG.dec(long[rx_buff][i])
      if long[rx_buff][i]==200
        Debug.str(string(13,"lights"))
        outa[20]:=1
        waitcnt(clkfreq+cnt)
        outa[20]:=0
      'IF (?seed <> long[rx_buff][i])                    ' if information differs from what it is supposed to be
        'DEBUG.str(string("Warning",$D)) 
    'DEBUG.str(string("Buffer Good",$D))

PUB tx | tx_buff, i, seed
'' setup transmit cog
                        
  tx_buff := PCTX.send(TX_pin)                          ' start TX cog
  seed := $9876_5432                                    ' make sure it(rand num gen seed value) is the same as rx cog    
                                                        'the above line only
  REPEAT
    REPEAT i FROM 0 TO constant(PCTX#BUFFER_SIZE - 1)
      long[tx_buff][i] := ?seed                         ' fill buffer with the forward random value;long[tx_buff][i] says to set the long at the tx_buff address to the random value
    PCTX.transmitwait_wd(100)                           ' send buffer, then wait up to 100ms for it to complete
    waitcnt(120000 + cnt)                               ' give enough time for RX cog to "analize" data
  
  