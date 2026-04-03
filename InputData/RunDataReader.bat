rem
rem  RunDataReader.bat
rem
rem  %1 Data to read - All or TOM (optional, default is All)
rem

Set CurrentPath=%CD%
CD..
   for /f "delims=" %%A in ('cd') do (
     set modelfoldername=%%~nxA
    )
CD %CurrentPath%

Call RunJulia DataReader.jl %modelfoldername% %1