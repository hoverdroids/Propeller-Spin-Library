{{
OBEX LISTING:
  http://obex.parallax.com/object/419

  Full featured autopilot for boats, planes and rovers. Tested over 3 years. You can see the videos under Spiritplumber on youtube. This version does not contain the graphical console, but text i/o is possible and fairly easy to do.

  Other versions are maintained here http://robots-everywhere.com/portfolio/navcom_ai/ and may be downloaded there. If you intend to use this commercially, please see licensing information on that page.

  A note: It is possible to build functional drone bombers or similar with this. You the downloader are explicitly denied permission to do so. If you want to build autonomous weapons do your own homework, or better yet, go get your head examined.

  Videos of the drones in action!

  http://www.youtube.com/watch?v=5wJHj3hOcuI
  http://www.youtube.com/watch?v=diAZD68Y3Cw
  http://www.youtube.com/watch?v=AIbPvxf3hrk
  http://www.youtube.com/watch?v=en5TCSHZDyY
  http://www.youtube.com/watch?v=Dd1R-WeGWkU
  http://www.youtube.com/watch?v=9m6H5se6-nE
}}
{{
***************************
* Stack Length v1.0       *
* (C) 2006 Parallax, Inc. *
***************************

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

obj l: "NavAI_Lib"

VAR
  long  Addr                                                                    'Address of stack
  long  Size                                                                    'Size of stack
  long  Seed                                                                    'Current pseudo-random seed value
  long  USize
  long  ISeed
  long  Idx
PUB Init(StackAddr, Longs)
{{Initialize stack with pseudo-random values.
  Parameters: StackAddr = address of stack to initialize and measure later.
              Longs = length of reserved stack space, in longs.}}
  Addr := StackAddr                                                             'Remember address
  Size := Longs-1                                                               'Remember size
  Seed := cnt                                                                   'Initialize Random Value
  repeat Idx from 0 to Size                                                     'Write pseudo-random values to entire stack
    long[Addr][Idx] := Seed?
  Seed?                                                                         'Set seed in prep for Length method
                                                                                     
PUB GetLength ' returns an integer
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
    USize~~     ' set to -1

  return USize                                                                    '  flag as inconclusive
  

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
}}
