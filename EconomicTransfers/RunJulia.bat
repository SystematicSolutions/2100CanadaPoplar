rem
rem  RunJulia.bat
rem
rem  %1 - Julia file to execute
rem
     julia --project %1 %2 %3 %4 %5 %6 %7 %8 %9
     
     if %errorlevel%==1 goto ErrorFound
       echo File Successful
       exit /b 0     
          
     :ErrorFound
       echo File Failed
       Pause
     
