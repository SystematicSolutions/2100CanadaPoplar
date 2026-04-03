rem
rem  ExecuteE2020.bat
rem 
     If !Iteration!==1 GoTo FirstIteration
echo     Call RunScenario %BeginningYear% %EndingYear% %ScenarioCurrent% %BaseCase% %RefCase% %OGRefCase% %RefCase% %InvCase%; %time% >> %LogFileName%
         Call RunScenario %BeginningYear% %EndingYear% %ScenarioCurrent% %BaseCase% %RefCase% %OGRefCase% %RefCase% %InvCase% All
     GoTo EndExecute
     :FirstIteration
echo     FirstIteration
rem
rem    Create a Subdirectory to Save Scenario
rem
       RD /s/q %ScenarioCurrent%
       MD %ScenarioCurrent%
rem     
rem    Save databses
rem
       Call Zip Results %ScenarioCurrent%\database database.hdf5
rem
rem    Create output files
rem    
       Call CreateDTAs %ScenarioCurrent% %RefCase% %RefCase% All NoUnZip
rem
     :EndExecute
     
     Exit /B 0
