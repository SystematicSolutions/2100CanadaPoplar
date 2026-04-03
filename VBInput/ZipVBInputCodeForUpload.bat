rem
     del Backup.zip
rem     
rem  Root Files
rem
     Call Zip ResultsRecursive Backup *.exe  >nul
     Call Zip ResultsRecursive Backup *.src  >nul
     Call Zip ResultsRecursive Backup *.bat  >nul
rem
rem  Program Code
rem
     Call Zip ResultsRecursive Backup AccessTextConverter\*.vb  >nul
     Call Zip ResultsRecursive Backup DatabaseUnzipper\*.vb  >nul
     Call Zip ResultsRecursive Backup E3NA_E2020\*.vb  >nul
     Call Zip ResultsRecursive Backup InputDatabaseMaker\*.vb  >nul
     Call Zip ResultsRecursive Backup OutputGenerator\*.vb  >nul
     Call Zip ResultsRecursive Backup UnitDataManger\*.vb  >nul
     Call Zip ResultsRecursive Backup VBInput\*.vb  >nul
     Call Zip ResultsRecursive Backup UsElectricUnits\*.vb  >nul
     Call Zip ResultsRecursive Backup E3NA_E2020\*.vb  >nul
     
rem
rem  Support files - sets, maps, etc.
rem
     Call Zip ResultsRecursive Backup Support\*.*  >nul
