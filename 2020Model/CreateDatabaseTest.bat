rem
rem  RunCreateDatabase.bat
rem

Set CurrentPath=%CD%
CD..
   for /f "delims=" %%A in ('cd') do (
     set modelfoldername=%%~nxA
    )
CD %CurrentPath%

     Call RunJulia ModelDatabaseCreate.jl %modelfoldername%
     
     
rem
rem  Pause till the user hits a key to exit
rem
    pause
