repeat while STRCmd_confirm<>="y"
  Cmd_confirm:=string("yes")
  Debug.Str(Cmd_confirm)
  Debug.Str(String(13,"Please enter a command",13))
  DS00_Cmd:=Debug.getStr(MyByteArray)
  Debug.Str(String(13,"Your DS00 command was:  "))
  Debug.Str(DS00_Cmd)
  Debug.Str(String(13,"Is this correct? (Y/N)",13))
  Cmd_confirm_str:=Debug.getStr(Cmd_confirm)
  if STRCOMP(Cmd_confirm_str,Cmd_confirm)
    Debug.Str(string("inside!"))
  else
    Debug.Str(string("not inside :("))
  'Debug.Str(Cmd_confirm)          
  'Cmd_confirm_bin:=Debug.StrToBin(Cmd_confirm_str)
  'Debug.bin(Cmd_confirm_bin,32)
  
  waitcnt(clkfreq*2+cnt)
  Debug.Str(String(CLS))

  
  'if DS00_Cmd<>=0
    'DS00_Comms.Str(DS00_Cmd)