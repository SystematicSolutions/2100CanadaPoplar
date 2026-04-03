rem
rem  RunModelDatabaseCreate.bat
rem
rem  TODO Do we execute every file in the subdirectory?  No room for temps? - Jeff Amlin 5/7/25
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
rem    pause
