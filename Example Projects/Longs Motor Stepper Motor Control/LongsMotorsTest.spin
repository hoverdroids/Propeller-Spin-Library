{
 ************************************************************************************************************
 *                                                                                                          *
 *  AUTO-RECOVER NOTICE: This file was automatically recovered from an earlier Propeller Tool session.      *
 *                                                                                                          *
 *  ORIGINAL FOLDER:                                                                                        *
 *  TIME AUTO-SAVED:     over 3 days ago (10/5/2012 4:45:38 PM)                                             *
 *                                                                                                          *
 *  OPTIONS:             1)  RESTORE THIS FILE by deleting these comments and selecting File -> Save.       *
 *                           The existing file in the original folder will be replaced by this one.         *
 *                                                                                                          *
 *                           -- OR --                                                                       *
 *                                                                                                          *
 *                       2)  IGNORE THIS FILE by closing it without saving.                                 *
 *                           This file will be discarded and the original will be left intact.              *
 *                                                                                                          *
 ************************************************************************************************************
.}
{
 ************************************************************************************************************
 *                                                                                                          *
 *  AUTO-RECOVER NOTICE: This file was automatically recovered from an earlier Propeller Tool session.      *
 *                                                                                                          *
 *  ORIGINAL FOLDER:                                                                                        *
 *  TIME AUTO-SAVED:     6/30/2012 5:11:09 PM)                                                              *
 *                                                                                                          *
 *  OPTIONS:             1)  RESTORE THIS FILE by deleting these comments and selecting File -> Save.       *
 *                           The existing file in the original folder will be replaced by this one.         *
 *                                                                                                          *
 *                           -- OR --                                                                       *
 *                                                                                                          *
 *                       2)  IGNORE THIS FILE by closing it without saving.                                 *
 *                           This file will be discarded and the original will be left intact.              *
 *                                                                                                          *
 ************************************************************************************************************
.}
{This will test the functionality of the steppers from Long's Motors 

}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

VAR
  LONG THETA_V_PU_PIN ,THETA_V_DR_PIN ,THETA_V_MF_PIN 
  LONG THETA_H_PU_PIN ,THETA_H_DR_PIN ,THETA_H_MF_PIN
  LONG THETA_WT_PU_PIN,THETA_WT_DR_PIN,THETA_WT_MF_PIN
  LONG THETA_H_LB, THETA_H_RB,THETA_H_CNT
PUB Main

  THETA_H_CNT:=0

  THETA_V_PU_PIN:=3 'PU- line
  THETA_V_DR_PIN:=4 'DR- line
  THETA_V_MF_PIN:=5 'MF- line
  
  THETA_H_PU_PIN:=0 'PU- line
  THETA_H_DR_PIN:=1 'DR- line
  THETA_H_MF_PIN:=2 'MF- line
  
  THETA_WT_PU_PIN:=6 'PU- line
  THETA_WT_DR_PIN:=7 'DR- line
  THETA_WT_MF_PIN:=8 'MF- line
  
dira[THETA_V_PU_PIN]:=1 'all pins must be set to output
dira[THETA_V_DR_PIN]:=1 
dira[THETA_V_MF_PIN]:=1 

dira[THETA_H_PU_PIN]:=1 
dira[THETA_H_DR_PIN]:=1 
dira[THETA_H_MF_PIN]:=1 

dira[THETA_WT_PU_PIN]:=1 
dira[THETA_WT_DR_PIN]:=1 
dira[THETA_WT_MF_PIN]:=1 

outa[THETA_V_PU_PIN]:=0 'cycling this pin between 0 and 1 will get it to move
outa[THETA_V_DR_PIN]:=0 '0 pulls rod in and points top up; 1 pushes rod out and points top down
outa[THETA_V_MF_PIN]:=0 '0 says motor not "free" (i.e. it's engaged)

outa[THETA_H_PU_PIN]:=0 'cycling this pin between 0 and 1 will get it to move
outa[THETA_H_DR_PIN]:=0 '0 pulls rod in and points top up; 1 pushes rod out and points top down
outa[THETA_H_MF_PIN]:=0 '0 says motor not "free" (i.e. it's engaged)

outa[THETA_WT_PU_PIN]:=0 'cycling this pin between 0 and 1 will get it to move
outa[THETA_WT_DR_PIN]:=0 '0 pulls rod in and rotates to right; 1 pushes rod out and rotates to left
outa[THETA_WT_MF_PIN]:=0 '0 says motor not "free" (i.e. it's engaged)

'initialize all output to zero for no motion at startup

'outa[6]~~  'down is ~~ and up is ~

outa[THETA_V_DR_PIN]:=1 '1 Points up; 0 points down
outa[THETA_H_DR_PIN]:=1 '0 is swivel left, 1 is swivel right
outa[THETA_WT_DR_PIN]:=0 '1 is CCW when looking from right (loosten); 0 is cw (tighten)
'notes for theta horizontal:
'Heading of 203 to 196, 800 ticks, left swivel
'Heading of 196 to 200, 800 ticks, right swivel from initial of 203 (i.e. should have landed at 203)
'Heading of 200 to 207, 800 ticks, right swivel
'Heading of 207 to 202, 1600 ticks, left swivel
' 

repeat 700 '2350 is absoute range for theta H;
  outa[THETA_V_PU_PIN]:=1
  waitcnt(clkfreq*1/1000+cnt)
  outa[THETA_V_PU_PIN]:=0
  waitcnt(clkfreq*1/1000+cnt)

  'outa[THETA_H_PU_PIN]:=1
  'waitcnt(clkfreq*1/1000+cnt)
  'outa[THETA_H_PU_PIN]:=0
  'waitcnt(clkfreq*1/1000+cnt)

  'outa[THETA_WT_PU_PIN]:=1
  'waitcnt(clkfreq*1/1000+cnt)
  'outa[THETA_WT_PU_PIN]:=0
  'waitcnt(clkfreq*1/1000+cnt)
  
  

  
                                                      