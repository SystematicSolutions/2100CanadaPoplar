
rem  PrmFileTxo.bat

Del PrmFile.log
Echo Attempting to compile %1.txo  >> PrmFile.log

If Exist %1.log Del %1.log
If Not Exist %1.txo GoTo WriteLog
  prm  run compiler %1.txo
  Echo %1 has been compiled >> PrmFile.log       
  GoTo End
  
:WriteLog
  Call LogReport "Missing File %1.txo"
  Pause
:End
