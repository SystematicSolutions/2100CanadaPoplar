rem
rem  RunScenario.bat - Unzip the Start database
rem
rem %1 - Beginning Year
rem %2 - Ending Year
rem %3 - Scenario Name
rem %4 - Base Case 
rem %5 - Reference Case
rem %6 - Oil and Gas Reference Case
rem %7 - Scenario for zInitial in Access outputs
rem %8 - Economic Model Investments Case (see Jeff)
rem %9 - DTA List "Short" or blank
rem
rem  Execute the model
rem
     Echo %Date% ;%Time%; Call RunScenario %1 %2 %3 %4 %5 %6 %7 %8 >> RunModel_Report.log       
     Call RunJulia RunScenario.jl %1 %2 %3 %4 %5 %6 %7 %8
     
     if %errorlevel%==1 goto ErrorFound
       echo File Successful
       goto Exit              
     :ErrorFound
       echo File Failed
       Pause   
     :Exit   
     
     Echo %Date% ;%Time%; Call E2020_to_TOM >> RunModel_Report.log       
     cd..\EconomicTransfers
       Call E2020_to_TOM
     cd..\2020Model     
rem
rem     for /f %%a in (RunType.txt) do set var=%%a
rem     echo %var%
rem     if %var%==Fast GoTo SkipDB
rem
rem  Create a Subdirectory to Save Scenario
rem
     RD /s/q %3
     MD %3
rem     
rem  Save databases
rem
     Call Zip Results %3\database database.hdf5
rem
rem  Create output files
rem    
     Call CreateDTAs %3 %5 %7 %9 NoUnZip
rem
     Echo %Date% ;%Time%; End RunScenario %3 on %ComputerName% >> RunModel_Report.log       
