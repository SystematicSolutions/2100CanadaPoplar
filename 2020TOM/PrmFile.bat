rem
rem  PrmFile.bat

rem
rem  Define Parameters
rem    1% - Name of file being compiled
rem  End Parameters
rem
Del PrmFile.log
Echo Attempting to compile %1  >> PrmFile.log

If Not Exist %1 GoTo WriteLog
  prm run compiler %1 || Pause
  Echo %1 has been compiled >> PrmFile.log       
  GoTo End
  
:WriteLog
  Call LogReport "Missing File %1"
  Pause
:End
