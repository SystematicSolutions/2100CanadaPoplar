rem
rem  CreateAccessDatabases.bat Create Access DBs for a single scenario
rem
rem  %1 - Scenario Name
rem

rem
rem  Unzip Access *.dta files
rem
     Call UnZip Access %1

rem
rem  Extract Folder Name
rem
     Set CurrentPath=%CD%
     CD..
        for /f "delims=" %%A in ('cd') do (
        set modelfoldername=%%~nxA
        )
     CD %CurrentPath%
     echo %modelfoldername%

rem
rem  Create Path from Model Folder Name
rem
     MD C:\Path
     del C:\Path\Path.txt
     echo "%modelfoldername%" > C:\Path\Path.txt
     echo %1 > C:\Path\ScenarioName.txt
     
rem
rem  Create Access Databases
rem
     start /wait "C:\Program Files (x86)\Microsoft Office\root\Office16\msaccess.exe" C:\%modelfoldername%\2020Model\AccessDatabaseGenerator.accdb /x MakeScenarioDBs

rem
rem  Save Results and Clean-up Files
rem
     Call Zip Results %1\%1_AccessDBs *.accdb
     del *-%1*.accdb
     del *-%1*.dta
