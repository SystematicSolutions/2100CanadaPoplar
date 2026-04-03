rem
rem  SetScenarioName.bat
rem
rem  %1 - Scenario Name
rem  %2 - Base Case
rem  %3 - Reference Case
rem  %4 - Oil and Gas Reference Case
rem  %5 - Scenario for zInitial in Access outputs
rem  %6 - Case used for DInv, PInv
rem
     Echo %1  >ScenarioInfo.tmp
     Echo %2 >>ScenarioInfo.tmp   
     Echo %3 >>ScenarioInfo.tmp  
     Echo %4 >>ScenarioInfo.tmp 
     Echo %5 >>ScenarioInfo.tmp 
     Echo %6 >>ScenarioInfo.tmp 
rem
rem  Save Model Name
rem
     Call SaveDirectoryName
     Call PrmFile GetScenarioName.run 