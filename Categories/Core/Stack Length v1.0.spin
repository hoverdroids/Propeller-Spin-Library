{{
*************************************
* Stack Length v1.0                 *
* Author: Jeff Martin               *
* Copyright (c) 2006 Parallax, Inc. *
* See end of file for terms of use. *
*************************************

Measures utilization of user-defined stack; used to determine actual run-time stack requirements for an object in development.

Any object that manually launches Spin code, via COGINIT or COGNEW commands, must reserve stack space for the new cog to use
at run-time.  Too little stack space results in malfunctioning code, while too much stack space is wasteful.

Run-time stack space is used by the Spin Interpreter to store temporary values (return addresses, return values, intermediate
expression values and operators, etc).  The amount of stack space needed for manually launched Spin code is impossible to
calculate at compile-time; it is a run-time phenomena that grows and shrinks depending on levels of nested calls, complexity
of expressions, and paths code takes in response to stimuli.

See "Theory of Operation" below for more information.

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
}}
VAR
  long  Addr                                                                    'Address of stack
  long  Size                                                                    'Size of stack
  long  Seed                                                                    'Current pseudo-random seed value

OBJ
  Num : "Numbers"
  
PUB Init(StackAddr, Longs) | Idx
{{Initialize stack with pseudo-random values.
  Parameters: StackAddr = address of stack to initialize and measure later.
              Longs = length of reserved stack space, in longs.}}
              
  Addr := StackAddr                                                             'Remember address
  Size := Longs-1                                                               'Remember size
  Seed := cnt                                                                   'Initialize Random Value
  repeat Idx from 0 to Size                                                     'Write pseudo-random values to entire stack
    long[Addr][Idx] := Seed?
  Seed?                                                                         'Set seed in prep for Length method
                                                                                     
PUB GetLength(TxPin, BaudRate): UsedLongsStr | USize, ISeed, Char, Time
{{Measure the maximum utilization of stack, given to Init, transmit it serially and return value as a string pointer.
  Call this method only after first calling Init and then fully exercising any code that uses the stack given to Init.
  Parameters: TxPin = pin number (0-31) to use for transmitting result serially, if desired.
              BaudRate = serial baud rate (ex: 19200) of transmission (0 = no transmission).
  Returns:    Pointer to string indicating actual utilization of stack, in form: "Stack Usage: #" where # is as follows:
              -1 = inconclusive; stack may be too small, increase size and try again.
               0 = stack never utilized.
              >0 = maximum utilization (in longs) of stack up to this moment.
  NOTE: Serial transmission is true-polarity, 8, N, 1}}

  {Determine utilization of stack}
  ISeed := Seed                                                                 'Remember initial seed value 
  USize := Size                                                                 'Start at end of stack
  repeat while (USize > -1) and (long[Addr][USize] == ?ISeed)                   'Read stack backwards, stop at first unmatched seed
    USize--
  if ++USize == Size+1                                                          'If stack is full
    USize~~                                                                     '  flag as inconclusive
  
  {Convert to string}
  Num.Init
  UsedLongsStr := Num.ToStr(USize, Num#DEC)                                     'Get utilized-size as string
  bytefill(@Text + 13, 0, 5)                                                    'Zero-terminate friendly string
  bytemove(@Text + 12, UsedLongsStr, strsize(UsedLongsStr))                     'Copy utilized-size to friendly string
  UsedLongsStr := USize := @Text                                                'Set return pointer and temp pointer

  {Transmit friendly string serially, if desired}
  if BaudRate                                                                   'If we should serially transmit result
    BaudRate := clkfreq / BaudRate                                              '  Convert BaudRate to bit period
    outa[TxPin] := dira[TxPin] := 1                                             '  Set TxPin to output high (resting state)
    repeat while Char := byte[USize++]                                          '  Repeat until zero terminator found
      Char := Char << 2 + %100_00000000                                         '    Prep Char; place stop bit/start bit
      Time := cnt                                                               '    Check time
      repeat 10                                                                 '    Repeat for 10 bits
        waitcnt(Time += BaudRate)                                               '      Wait for next bit period  
        outa[TxPin] := (Char >>= 1) & 1                                         '      Output bit (LSB first)
    dira[TxPin]~                                                                '  Set TxPin to input

DAT
  Text  byte  "Stack Usage: xxxxx", 0

{{


──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
                                                     THEORY OF OPERATION
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Follow these steps for developing objects that manually launch Spin code:


STEP 1: As you develop your object, provide a large amount of stack space for any Spin code launched via COGINIT or COGNEW.
        Simple code may take around 8 longs, but more complex code may take hundreds of longs. Start with a large value,
        128 longs for example, and increase it as needed to ensure proper operation.

STEP 2: When your object's development is complete, include this object ("Stack Length") within it and call Init before
        launching any Spin code.  NOTE: For the Init's parameters, make sure to specify the proper address and length (in longs)
        of the stack space you actually reserved. 

        Example:

        VAR
          long Stack[128]

        OBJ
          Stk : "Stack Length"

        PUB Start
          Stk.Init(@Stack, 128)                         'Initialize Stack for measuring later

          cognew(@MySpinCode, @Stack)                   'Launch code that utilizes Stack
    
Step 3: Fully exercise your object, being sure to affect every feature that will cause the greatest nested method calls and
        most complex set of run-time expressions to be evaluated.  This may have to be a combination of hard-coded tests and
        physical, external stimuli depending on the application.

Step 4: Call GetLength to measure the stack space actually utilized.  GetLength will return a pointer to a result string and
        will serially transmit the results on the TxPin at the BaudRate specified.  Use 0 for BaudRate if no transmission is
        desired.  The value returned in the string will be -1 if the test was inconclusive (try again, but with more stack
        space reserved), 0 if the stack was never used, or some other value indicating the maximum utilization (in longs) of
        your stack up to that moment in time.

        Example:  If the application uses an external 5 MHz resonator and its clock settings are as follows:
        
        CON
          _clkmode = xtal1 + pll16x
          _xinfreq = 5_000_000

        Then the following line will transmit "Stack Usage: #" on I/O pin 30 (the Tx pin normally used for programming) at
        19200 baud; where # is the utilization of your Stack.

          Stk.GetLength(30, 19200)

Step 5: Set your reserved Stack space to the measured size and remove this object, Stack Length, from your finished object.

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