rem 
rem  RunOGScenarioRuns.bat
rem 
rem  RunOGScenario.bat 
rem
rem  %1 - Scenario Name
rem  %2 - Policy or Parameter File
rem  %3 - Price Specification
rem  %4 - Ending Year
rem                                 
rem  Del ScenarioList.txt
rem
rem                     Scenario      Policy    Prices     End Year
     Call RunOGScenario High25        None      CER25_High 2050 
     Call RunOGScenario Low25         None      CER25_Low  2050       
     Call RunOGScenario Ref25         None      CER25_Ref  2050   
rem
rem     Call RunOGScenario HighNoAdjust  NoAdjust  CER21_High   2050 
rem     Call RunOGScenario LowNoAdjust   NoAdjust  CER21_Low    2050       
rem     Call RunOGScenario RefNoAdjust   NoAdjust  CER21_Ref    2050        
rem     
rem  Call CreateAccessOutputDatabases ScenarioList.txt
rem