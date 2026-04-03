rem
rem  StartScenario.bat - UnZip the Start database
rem
rem  %1 - Start database name
rem  %2 - Scenario Name
rem  %3 - Base Case
rem  %4 - Reference Case
rem  %5 - Oil and Gas Reference Case
rem  %6 - Scenario for zInitial in Access outputs
rem  %7 - Case used for DInv, PInv
rem
rem
rem  UnZip Start Databases
rem
     Call UnZip DB %1
     RD /s/q out
     MD out
     
rem
rem  UnZip Base Case Databases
rem
     If %3==%2 GoTo BaseDone
       Call UnZip RefDB %3
     :BaseDone 

rem
rem UnZip Reference Case Databases
rem Please Do not change the format of the RefDone lines
rem
     If %4==%2 GoTo RefDone
       Call UnZip RefDB %4
     :RefDone 

rem
rem  UnZip zIniital Case Databases
rem  Please Do not change the format of the InitialDone lines
rem
     If %6==%2 GoTo InitialDone
     If %6==%3 GoTo InitialDone
       Call UnZip RefDB %6
    :InitialDone 

rem
rem  UnZip Oil and Gas Reference Case Databases
rem  Please Do not change the format of the OGRefDone lines
rem
     If %5==%4 GoTo OGRefDone 
       Call UnZip RefDB %5
    :OGRefDone 

rem
rem UnZip TIM Databases
rem
     If %7==%2 GoTo TIMDone
       Call UnZip RefDB %7
     :TIMDone 
     
rem
rem  Put Scenario Name into Promula Database
rem
     Echo %2 >ScenarioInfo.tmp
     Echo %3 >>ScenarioInfo.tmp 
     Echo %4 >>ScenarioInfo.tmp      
     Echo %5 >>ScenarioInfo.tmp  
     Echo %6 >>ScenarioInfo.tmp  
     Echo %7 >>ScenarioInfo.tmp  
rem
rem  Save Model Name
rem
rem  Call SaveDirectoryName    
rem  Call PrmFile GetScenarioName.run  
rem