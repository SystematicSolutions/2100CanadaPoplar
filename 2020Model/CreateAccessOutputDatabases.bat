rem
rem  CreateAccessOutputDatabases.bat
rem
     Call CreateAccessDatabases Base
     Call CreateAccessDatabases Ref25
     Call CreateAccessDatabases Ref25A
     Call CreateAccessDatabases Ref25_TOM
     Call CreateAccessDatabases Ref25A_TOM
       
     if %errorlevel%==1 goto ErrorFound
       echo File Successful
       exit /b 0     
          
     :ErrorFound
       echo File Failed
       Pause
    
    