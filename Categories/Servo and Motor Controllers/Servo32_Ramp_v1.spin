{{
*****************************************
* Servo32v5 Ramp Driver            v1.0 *
* Author: Beau Schwabe                  *
* Copyright (c) 2009 Parallax           *
* See end of file for terms of use.     *
*****************************************

*****************************************************************
 Control ramping of up to 32-Servos      Version1     05-11-2009 
*****************************************************************
 Coded by Beau Schwabe (Parallax).                                              
*****************************************************************


 History:
                           Version 1 - (05-11-2009) initial concept

}}
PUB StartRamp (ServoData)
    cognew(@RampStart,ServoData)                                             

DAT

'*********************
'* Assembly language *
'*********************

'' Note: It takes aproximately 3100 clocks to process all 32 Channels,
''       So the resolution is about 38.75us

                        org
'------------------------------------------------------------------------------------------------------------------------------------------------
RampStart               
                        mov     Address1,       par              'ServoData
                        mov     Address2,       Address1                 
                        add     Address2,       #128             'ServoTarget
                        mov     Address3,       Address2                 
                        add     Address3,       #128             'ServoDelay
'---------------------------------------------------------------------------------------
Ch01                    sub      dly + 00,      #1      wc 
                   if_c rdlong   dly + 00,      Address3         'Move Delay into temp delay value
                        call     #RampCore                        
'---------------------------------------------------------------------------------------
Ch02                    sub      dly + 01,      #1      wc
                   if_c rdlong   dly + 01,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch03                    sub      dly + 02,      #1      wc
                   if_c rdlong   dly + 02,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch04                    sub      dly + 04,      #1      wc
                   if_c rdlong   dly + 04,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch05                    sub      dly + 05,      #1      wc
                   if_c rdlong   dly + 05,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch06                    sub      dly + 06,      #1      wc
                   if_c rdlong   dly + 06,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch07                    sub      dly + 07,      #1      wc
                   if_c rdlong   dly + 07,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch08                    sub      dly + 08,      #1      wc
                   if_c rdlong   dly + 08,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch09                    sub      dly + 09,      #1      wc
                   if_c rdlong   dly + 09,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch10                    sub      dly + 10,      #1      wc
                   if_c rdlong   dly + 10,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch11                    sub      dly + 11,      #1      wc
                   if_c rdlong   dly + 11,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch12                    sub      dly + 12,      #1      wc
                   if_c rdlong   dly + 12,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch13                    sub      dly + 13,      #1      wc
                   if_c rdlong   dly + 13,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch14                    sub      dly + 14,      #1      wc
                   if_c rdlong   dly + 14,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch15                    sub      dly + 15,      #1      wc
                   if_c rdlong   dly + 15,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch16                    sub      dly + 16,      #1      wc
                   if_c rdlong   dly + 16,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch17                    sub      dly + 17,      #1      wc
                   if_c rdlong   dly + 17,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch18                    sub      dly + 18,      #1      wc
                   if_c rdlong   dly + 18,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch19                    sub      dly + 19,      #1      wc
                   if_c rdlong   dly + 19,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch20                    sub      dly + 20,      #1      wc
                   if_c rdlong   dly + 20,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch21                    sub      dly + 21,      #1      wc
                   if_c rdlong   dly + 21,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch22                    sub      dly + 22,      #1      wc
                   if_c rdlong   dly + 22,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch23                    sub      dly + 23,      #1      wc
                   if_c rdlong   dly + 23,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch24                    sub      dly + 24,      #1      wc
                   if_c rdlong   dly + 24,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch25                    sub      dly + 25,      #1      wc
                   if_c rdlong   dly + 25,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch26                    sub      dly + 26,      #1      wc
                   if_c rdlong   dly + 26,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch27                    sub      dly + 27,      #1      wc
                   if_c rdlong   dly + 27,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch28                    sub      dly + 28,      #1      wc
                   if_c rdlong   dly + 28,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch29                    sub      dly + 29,      #1      wc
                   if_c rdlong   dly + 29,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch30                    sub      dly + 30,      #1      wc
                   if_c rdlong   dly + 30,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch31                    sub      dly + 31,      #1      wc
                   if_c rdlong   dly + 31,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
Ch32                    sub      dly + 32,      #1      wc
                   if_c rdlong   dly + 32,      Address3         'Move Delay into temp delay value
                        call     #RampCore
'---------------------------------------------------------------------------------------
                        jmp     #RampStart
'-------------------------------------------------------------------
'-------------------------------------------------------------------
RampCore
                        rdlong   temp1,         Address1         'Move ServoData into temp1               
                        rdlong   temp2,         Address2         'Move ServoTarget into temp2
                  if_nc jmp      #CodeBalance
                        cmp      temp1,         temp2   wc,wz      
            if_c_and_nz add      temp1,         CoreSpeed        'Increment ServoData if ServoTarget is greater   
           if_nc_and_nz sub      temp1,         CoreSpeed        'Decrement ServoData if ServoTarget is less
OutLoop                 wrlong   temp1,         Address1         'Update ServoData value

                        add      Address1,      #4               'Increment Delay pointer
                        add      Address2,      #4               'Increment ServoData pointer         
                        add      Address3,      #4
RampCore_ret            ret                        

CodeBalance             nop                                      'makes for equal code branch path               
                        jmp     #OutLoop
'-------------------------------------------------------------------
'-------------------------------------------------------------------
time1                   long    0
time2                   long    0


CoreSpeed               long    310          '' increment/decrement pulse width every 3100 clocks
                                             '' So at 2us and a full sweep 500us to 2500us (Delta of 2000us)
                                             '' the total time travel would be 38.75ms
                                             ''
                                             '' 160 = 2us      @ 38.750ms
                                             '' 240 = 3us      @ 25.833ms
                                             '' 310 = 3.875us  @ 20ms
                                             '' 320 = 4us      @ 19.375ms
                                             '' 400 = 5us      @ 15.500ms
                                             '' 413 = 5.1625us @ 15.012ms
                                             '' 480 = 6us      @ 12.917ms
                                             '' 560 = 7us      @ 11.071ms
                                             '' 620 = 7.75us   @ 10ms
                                             '' 640 = 8us      @ 9.6875ms
{{
        The 'Core Speed' is the incremental resolution you are sending to the servo's.
        Most Hobby servos are only sensitive to about 5us so anything over that, a
        value of 400 may cause the servo to shake in an idle position.  With this ramp
        code it takes 3100 clocks to complete a cycle for all 32 servos, so the ramp
        will update once every 38.75us.  If your incremental resolution is 5us, this
        means that it would take 15.5ms to travel a full 500us to 2500us servo pulse
        width.

        Total_Time = [ {delta servo width} / {incremental resolution} ] * {ramp update}

        Total_Time = [ 2000us / 5us ] * 38.75us
        Total_Time = 400 * 38.75us
        Total_Time = 15500us

        This means that if you want the servo to take 1 minute (60000ms) to go from a
        pulse width of 500us to 2000us you would need to specify a delay of 3871 with
        the SetRamp command.

        Delay = 60000ms / 15.5ms
        Delay = 3871 

        3871 can be a little difficult to manage in your calculations and you can make
        this a little easier on yourself by selecting a Total_time that will be more
        evenly divisible than 15.5 and provide nicer numbers to deal with.


        CoreSpeed = [{delta servo width} * {ramp update} * (clkfrequency/1000000us)] / {Total_time} 

        CoreSpeed = [2000us * 38.75 * 80 ] / 20000us
        CoreSpeed = [77500 * 80 ] / 20000
        CoreSpeed = 6200000 / 20000
        CoreSpeed = 310

        This gives an incremental servo resolution of 3.875us ... 310 / 80 = 3.875

        Just to double check that this works out to an above formula...

        Total_Time = [ {delta servo width} / {incremental resolution} ] * {ramp update}
        Total_Time = [ 2000us / 3.875us ] * 38.75us
        Total_Time = 516.129 * 38.75us
        Total_Time = 20000us

        Now if you want the servo to take 1 minute (60000ms) to go from a pulse width
        of 500us to 2000us you would need to specify a delay of 3000 with the SetRamp
        command.

        Delay = 60000ms / 20ms
        Delay = 3000
                                                                                                          
}}

Address1                long    0
Address2                long    0
Address3                long    0
Address4                long    0

temp1                   long    0
temp2                   long    0

dly                     long    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                        long    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                        
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