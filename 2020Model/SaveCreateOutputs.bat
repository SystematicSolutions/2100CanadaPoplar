rem
rem  SaveCreateOutputs.bat
rem
rem  %1 - Scenario Name
rem
rem  Save database
rem
     Call SaveDatabase %1
rem
rem  Create output files
rem
     Call CreateDTAs %1 %1 %1 ExcelDTAs NoUnZip     