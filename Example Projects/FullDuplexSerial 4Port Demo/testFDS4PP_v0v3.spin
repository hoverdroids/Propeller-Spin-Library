{Tracy Allen, EME systems.  18-Jan-2011
Test program for FullDuplexSerial4portPlus
Ports are set up with port 0 as a debug port at 9600 baud
Port 3 running in its own cog repeatedly generate a message, but with cts flow control.
Port 2 receives the message, with its rts enabled to control flow of the message.
The message is also transmitted out from port 2, and also out the debug port at a slower baud rate.

After each 10 iterations, it stops all ports and restarts them.

This version calls on routines that show the number of chars in the port 2 buffer
as well as the positions of the head and tail pointers, was helpful for debugging

Set up as follows (e.g. on the quickstart)
p11 is TX output from port 3, to p8 RX input to port 2.
------- Connect p11 to p8 with a wire
p10 is port 3 CTS input, to p6 port 2 RTS output.  Flow control from port 2 back to port 3.
------- Connect p5 to p10 with a wire.
p7 is TX output from port 2.  No flow control.   Can observe or receive elsewhere.

p30 is port0 debug output, also data from port 2, which should be the message sent by port 3.
  The debug also contains information,
    tick counter
    the number of bytes currently in the port2 receive buffer.
    the port 2 tail pointer
    the port 2 head pointer
    the message

Port 2 is set up with RTS active and a threshold (77 bytes), so RTS p5 should go high
to stop flow when the threshold is exceeded.  Observe with 'scope.

Port 3 is set up with CTS flow control active, and you can test that it works by connecting
a jumper from the CTS pin to either Vdd (stop flow)or to Vss (allow flow). Connect port 3 CTS input
to port 2 RTS output to see normal action of flow control.   The way this is set up, flow control
 is essential for correct data reception.  Experiment with buffer sizes, rtsThreshold, and baud rates
to see the effects on flow control and data integrity.
}

CON
_clkmode = xtal1 + pll16x
_xinfreq = 5_000_000

  BAUD = 57600   ' the chain to send data from port, 3->2.  The debug port stays at 9600
  PROBE_PORT = 2   ' set this to port 1 or port 2 to see what it has in its buffer


OBJ

FDS :       "FullDuplexSerial4portPlus_0v3"


VAR

long char, ticks, tocks, foxCog, stack[25]

PUB main

  init_uarts

  repeat
    ticks~
    repeat 9
    ' receive string on port2, send it to port 1 and then out debug port 0.  RTS enabled on port 2.
    ' input string comes from port 3 operating asychronously in another cog, with its CTS eneabled
      FDS.dec(0,ticks++)
      FDS.tx(0,32)
      FDS.dec(0,FDS.rxHowFull(PROBE_PORT))  ' status of port rx buffer?
      FDS.tx(0,32)
      FDS.dec(0,FDS.showhead(PROBE_PORT))  ' head?
      FDS.tx(0,32)
      FDS.dec(0,FDS.showtail(PROBE_PORT))  ' tail?
      FDS.tx(0,32)
      repeat                    ' move data from port 2 to port 3
        char := FDS.rxCheck(2)  '
        if char > -1
 '          FDS.hex(0,char,2)  ' enable these two instructions to see what gives hex-wise
 '          FDS.tx(0,32)
           FDS.tx(0,char)
           FDS.tx(2,char)
      until char==13
      pause(1000)
    pause(1000)
    FDS.str(0,string("restarting ports",13))
    pause(20) ' time to dequeue
    init_uarts

PUB sendFoxOverDog   ' this method gets its own cog
    repeat
      pause(20)  '
      FDS.str(3,string("A quick brown fox jumps over the lazy dog",13)) ' 42 chars including CR
      ' Flow is going to be regulated by cts input to port 3 from rts output from port 2

PUB init_uarts | extra
'' port 0-3 port index of which serial port
'' rx/tx/cts/rtspin pin number                          XXX#PINNOTUSED if not used
'' prop debug port rx on p31, tx on p30
'' cts is prop input associated with tx output flow control
'' rts is prop output associated with rx input flow control
'' rtsthreshold - buffer threshold before rts is used   XXX#DEFAULTTHRSHOLD means use default
'' mode bit 0 = invert rx                               XXX#INVERTRX
'' mode bit 1 = invert tx                               XXX#INVERTTX
'' mode bit 2 = open-drain/source tx                    XXX#OCTX
'' mode bit 3 = ignore tx echo on rx                    XXX#NOECHO
'' mode bit 4 = invert cts                              XXX#INVERTCTS
'' mode bit 5 = invert rts                              XXX#INVERTRTS
'' baudrate

  if foxCog                                ' stopping transmission from the ansynchronous foxCpg
    cogstop(foxCog-1)
  pause(100)

  extra := FDS.init                        ' returns the number of bytes beyond the FDS object footprint

  FDS.AddPort(3,-1,11,10,-1,0,%000000,BAUD)      ' tx on p11, all true (start bit high, stop bits low)
                                           ' cts is enabled on p10, tx will wait if cts is high, no rx
  FDS.AddPort(2,8,7,-1,6,77,%000000,BAUD)    ' rx on p8
                                           ' rts is enabled on p6, will go high if #chars in rx buffer exceeds threshold 20 bytes.
                                           ' connect p11 to p8 for tx-->rx
                                           ' connect p10 to p6 for cts[3]<--rts[2]
                                           ' the threshold parameter here is 77, open to experiment
                                           ' tx on p7 at BAUD, no flow control
  FDS.AddPort(0,3,30,-1,-1,0,%000000,9600) ' for what comes in on port 2, and for debugging
'  FDS.AddPort(1,1,-1,-1,-1,0,%000000,9600) ' for what comes in on port 1, and for debugging

  FDS.Start
  pause(100)

  FDS.str(0,string(13,"starting... "))
  FDS.dec(0,extra)
  FDS.str(0,string(" extra bytes beyond object footprint",13))
  FDS.tx(0,13)

  foxCog := cognew(sendFoxOverDog,@stack) + 1  ' start sending fox data
  FDS.rxflush(2)




PRI pause(ms)
  waitcnt(clkfreq/1000*ms + cnt)


