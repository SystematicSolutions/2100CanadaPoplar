rem
rem  InitializeIntegratedTOM.bat
rem
echo InitializeIntegratedTOM.bat %1 %2 %3 %4 %5 %6 %7 %8 >> %LogFileName%
rem 
rem  %1 - Scenario
rem  %2 - Beginning Year
rem  %3 - Ending Year
rem  %4 - Base Case
rem  %5 - Reference Case
rem  %6 - Base Switch
rem  %7 - TOM Forecast Scenario
rem  %8 - OG Price Scenario (NEB25_Ref, NEB25_Fast, etc.)
rem
     If     %6==Base Set ScenarioName=%1
     If Not %6==Base Set ScenarioName=%1_TOM
     Set ScenarioFirst=%1
     Set OGPrice=%8
     Set RunType=AllYears
     Set NationsToRun=CN_US
     Set /A BeginningYear=%2
     Set /A TOMStartYear=2025
     Set /A EndingYear=%3
     Set TOMPolicyFile=NoTOM    
     Set BaseCase=%4
     Set RefCase=%5
     Set OGRefCase=OGRef
     Set /A TotalIterations=5
     Set InvCase=%ScenarioName%_1
     Set ScenarioCurrent=%ScenarioName%_1
     Set ScenarioPrior=%BaseCase%
     Set CurrentYear=%BeginningYear% 
     Set PriorYear=%BeginningYear%
     Set BaseSwitch=%6
     Set TOMScenario=%7
     Set /A Iteration=1
     
     Call LogRunVariables   

     exit /B 0   
 