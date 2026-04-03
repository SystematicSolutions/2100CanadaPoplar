rem
rem  RunTOMScenarioRuns.bat
rem 
rem  %1 - Scenario Name
rem  %2 - TOM Scenario (Baseline, Fast, Slow, HighPrice, LowPrice) 
rem  %3 - OGPrice Scenario
rem  %4 - Ending Year
rem  %5 - TOM Flag - TOM, NoTOM, or OnlyTOM
rem       

     Call RunRef25TOMScenario Ref        Baseline   CER25_Ref  2020  2040  TOM    
rem     Call RunRef25TOMScenario Fast       Fast       CER25_Ref  2020  2040  TOM
rem     Call RunRef25TOMScenario Slow       Slow       CER25_Ref  2020  2040  TOM
rem  Call RunRef25TOMScenario HighPrice  HighPrice  CER25_High 2020  2040  TOM
rem  Call RunRef25TOMScenario LowPrice   LowPrice   CER25_Low  2020  2040  TOM
rem  Call RunRef25TOMScenario HighTariff HighTariff CER25_Ref  2020  2040  TOM
rem  Call RunRef25TOMScenario LowTariff  LowTariff  CER25_Ref  2020  2040  TOM
rem  Call RunRef25TOMScenario FastHP     FastHP     CER25_High 2020  2040  TOM
rem  Call RunRef25TOMScenario SlowLP     SlowLP     CER25_Low  2040  TOM   

rem Call CreateAccessOutputDatabases ScenarioList.txt
    
