rem
rem  RunJulia.bat
rem
     julia --project %1
     
     if %errorlevel%==1 goto ErrorFound
       echo File Successful
       exit /b 0     
          
     :ErrorFound
       echo File Failed
       Pause
     
