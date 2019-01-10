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
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  HB_LEFT_PIN=24
  HB_RIGHT_PIN=25
  Dual=1
  Manual=0
  WHEEL_VELOCITY=0
  TREAD_VEL_L=1000 '1000=reverse; 2000=forward
  TREAD_VEL_R=2000 '2000=reverse; 1000=forward
VAR

OBJ
  HB_25_LEFT:"HB25"
  HB_25_RIGHT:"HB25"
PUB Main
  HB_25_LEFT.config(HB_LEFT_PIN, 1, 1)  'pin, 0-single 1-dual, 0-manual 1-auto refresh, returns ID of refresh cog
  HB_25_RIGHT.config(HB_RIGHT_PIN, 1, 1)
  repeat
    HB_25_LEFT.set_motor1(1500+WHEEL_VELOCITY)  '1000 is forward--Right wheel; greater than 1500set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms
    HB_25_LEFT.set_motor2(TREAD_VEL_L)  'set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms
    HB_25_LEFT.pulse_motors    'send pulse(s) to HB-25(s)

    HB_25_RIGHT.set_motor1(1500-WHEEL_VELOCITY)  '1000 is forward--Right wheel; greater than 1500set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms
    HB_25_RIGHT.set_motor2(TREAD_VEL_R)  'set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms
    HB_25_RIGHT.pulse_motors    'send pulse(s) to HB-25(s)
  'repeat