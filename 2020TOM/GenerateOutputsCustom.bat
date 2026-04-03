rem
rem  GenerateOutputsCustom.bat
rem
rem  %1 - Scenario Name
rem
    Call SetScenarioName %1 Base_TOM Base_TOM
rem
     Call UnZip %1
rem
    Call PrmFile PermitExpendituresE2020.txo
    Call PrmFile PermitExpendituresTOM.txo
    Call PrmFile GovernmentSpendingE2020.txo
    Call PrmFile GovernmentSpendingTOM.txo
rem
    Move *.dta %1    
    Call Zip Results %1\%1_ConnectionDTAs %1\*.dta
    