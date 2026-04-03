rem
echo   InitializeNonIntegratedTOM.bat %1 %2 %3 %4 %5 %6 %7 >> %LogFileName%
rem 
rem  %1 - Ending Year
rem  %2 - Scenario
rem  %3 - Base Case
rem  %4 - Reference Case
rem  %5 - Base Switch
rem  %6 - TOM Forecast Scenario
rem  %7 - OG Price Scenario (NEB25_Ref, NEB25_Fast, etc.)
rem
     Set ScenarioName=%2
     Set OGPrice=%7
     Set RunType=AllYears
     Set NationsToRun=CN_US
     Set /A BeginningYear=2020
     Set /A TOMStartYear=2025
     Set /A EndingYear=%1
     Set TOMPolicyFile=NoTOM    
     Set BaseCase=%3
     Set RefCase=%4
     Set OGRefCase=OGRef
     Set /A TotalIterations=0
     Set InvCase=%ScenarioName%
     Set ScenarioCurrent=%ScenarioName%
     Set ScenarioPrior=%6
     Set CurrentYear=%BeginningYear% 
     Set PriorYear=%BeginningYear%
     Set BaseSwitch=%5
     Set TOMScenario=%6
     Set /A Iteration=0
     
     Call LogRunVariables   
     exit /B 0   
