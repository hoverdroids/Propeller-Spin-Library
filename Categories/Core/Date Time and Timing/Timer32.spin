''****************************************
''*  Timer32                             *
''*  Authors: Jean-Marc Spaggiari        *
''*           jean-marc@spaggiari.org    *
''*  See end of file for terms of use.   *
''****************************************

{{
  Adapted version of Timer.spin based on Timer.java from Peter Verkaik (Javelin file)


  A general purpose 32 bit timer.
   
  This timer is using internal CNT propeller counter and is incremented
  every 12.8us only (every 10000 clock cycles at 80Mhz). Which mean accuracy
  will be +/- 12.8us.

  If your propeller is not running at 80Mhz, you can comment and uncomment specified
  blocks in the code related to the dividers (See in the CON, VAR and PUB Init secion)

  I do not recommand to use this timer for accurate delays under 200us.

  Therefore:
     1 millisecond =          78
     1 second      =      78,125
     1 minute      =   4,687,500
     1 hour        = 281,250,000

  The timer will overflow every 149 hours.

  For each timer created, you will need to call tick method as often as possible.
  If you prefer, instead of calling tick for each timer, you can call tickAll
  wich will tick all the timers. Another option is to start a cog to do that (see start method)

  A single timer would typically be used in code like the following:

  OBJ
    timer : "Timer32"
  PUB main
    timer.Init '' Not required if you are at 80Mhz
    timer.Mark
    repeat
      timer.Tick
      if (timer.TimeOutMS(500))
        timer.Mark
        '' Perform a periodic action.

  For multiple timers, you can go that way:

  OBJ
    timer1 : "Timer32"
    timer2 : "Timer32"
  PUB main
    timer1.Init '' Add timer1 to the list of timers to tickall
    timer2.Init '' Add timer2 to the list of timers to tickall
    timer1.Start '' No need to start more than one timer. That will tickall the timers.
    timer1.Mark
    timer2.Mark
    repeat
      if (timer1.TimeOutMS(500))
        timer1.Mark
        '' Perform a periodic action every 5 seconds
      if (timer2.TimeOutS(3))
        timer2.mark
        '' Perform a periodic action every 3 seconds

  In this 2nd example, the tick is done in the backgroung by a dedicated cog.
  However, if you have to save a cog, just comment the timer1.Start line, and
  the timer.init lines and add timer1.tickAll in the main loop. This will tick
  all the timers, even those running on other cogs or parts of the code.

  If you just need one single instance of this class on all you code,
  you can remove the init method, the timerStack, the DAT section and
  the tickAll method. Else, you can remove the tick method.

  @author Jean-Marc Spaggiari
  @version 1.0 02/10/2010
  @version 1.1 04/10/2010 Improvement of tick method performances. Now 30 times faster.
  @version 1.2 06/10/2010 Adding optionnal COG ticking.
  @version 1.3 07/10/2010 Adding DIVIDERs option to use the timer with non-80Mhz propellers.
 
}}


'' Comment the CON block if you want to dynamically assign dividers
'CON
  'DIVIDER_SECONDS  = 78125
  'DIVIDER_MSECONDS =    78


VAR
  long tickCNT  ' Used to store the timer counter
  long subtick  ' Used to store the internal sub-counter. Will increment tick each time sub reach 1000
  long startCNT ' Mark the start of the timer
  long lastCNT  ' Last CNT value to increment subtick and/or if required.

  long timerStack [16]

  '' Uncomment this block if you want to dynamically assign dividers
  long DIVIDER_SECONDS
  long DIVIDER_MSECONDS


''
'' Initialisation of the timer. Will store its variables
'' addressess in the shared zone (DAT) for global tick.
''
PUB init | tempValue

  '' Uncomment this block if you want to dynamically assign dividers
  DIVIDER_MSECONDS := (clkfreq / 1000) >> 10
  DIVIDER_SECONDS  := clkfreq >> 10

  tempValue := LONG[@instances_number][0]
  LONG[@tickCNTs][tempValue] := @tickCNT
  LONG[@subticks][tempValue] := @subtick
  LONG[@lastCNTs][tempValue] := @lastCNT
  LONG[@instances_number][0]++


''
'' Start the go calling tickAll
''
PUB start
  cognew(loop, @timerStack)


''
'' Mark the current timer. So the timeout will be based on this mark.
''
PUB mark
  tickCNT := 0
  subtick := 0
  lastCNT := cnt


''
'' Tick all timers having called init. This (or tickAll) need to be called as often as possible.
'' Big delays between calls might give non expected results.
''
PUB TickAll | index, currentCNT
  if instances_number > 0
    repeat index from 0 to instances_number - 1
      currentCNT := cnt
      if (currentCNT > LONG[LONG[@lastCNTs][index]])
        LONG[LONG[@subticks][index]] += currentCNT - LONG[LONG[@lastCNTs][index]]
      else
        LONG[LONG[@subticks][index]] += $FFFF - LONG[LONG[@lastCNTs][index]] + currentCNT

      LONG[LONG[@lastCNTs][index]] := currentCNT

      LONG[LONG[@tickCNTs][index]] += (LONG[LONG[@subticks][index]] >> 10)
      LONG[LONG[@subticks][index]] -= (LONG[LONG[@subticks][index]] & %1111_1111_1111_1111_1111_1100_0000_0000)


''
'' Tick current timer. This (or tickAll) need to be called as often as possible.
'' Big delays between calls might give non expected results.
''
PUB Tick | currentCNT
  currentCNT := cnt
  if (currentCNT > lastCNT)
    subtick += currentCNT - lastCNT
  else
    subtick += $FFFF - lastCNT + currentCNT

  lastCNT := currentCNT

  tickCNT += (subtick >> 10)
  subtick -= (subtick & %1111_1111_1111_1111_1111_1100_0000_0000)

''
'' Calculate the time passed since the last call to the mark method.
'' The returned value is in millisecond units.
''
PUB PassedMS
  return (tickCNT - startCNT) / DIVIDER_MSECONDS


''
'' Calculate the time passed since the last call to the mark method.
'' The returned value is in second units.
''
PUB PassedS
  return (tickCNT - startCNT) / DIVIDER_SECONDS


''
'' Checks whether timeMS milliseconds have elapsed since
'' the last call to mark.
''
PUB TimeOutMS(timeMS)
  return (tickCNT - startCNT) / DIVIDER_MSECONDS => timeMS



''
'' Checks whether timeS seconds have elapsed since
'' the last call to mark. The maximum timeout is 54975 seconds.
''
PUB TimeOutS(timeS)
  return (tickCNT - startCNT) / DIVIDER_SECONDS => timeS


''
'' Main loop for the cog to call tickAll again and again
PUB loop
  repeat
    tickAll

DAT
tickCNTs                 long 0[16] ' Addresses of tickCNTs values
subticks                 long 0[16] ' Addresses of subticks values
lastCNTs                 long 0[16] ' Addresses of lastCNTs values
instances_number         long 0


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