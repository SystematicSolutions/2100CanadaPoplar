rem
rem  SaveCompareUnZip.bat
rem 
rem  %1 - scenario
rem
     Call SaveDatabase %1
     Call CompareDatabase %1
     Call UnZipPromulaDatabase %1    
