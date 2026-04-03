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
     Call Zip ResultsRecursive Backup AccessTextConverter\*.*  >nul  >nul
     Call Zip ResultsRecursive Backup DatabaseUnzipper\*.*  >nul  >nul
     Call Zip ResultsRecursive Backup E3NA_E2020\*.*  >nul  >nul
     Call Zip ResultsRecursive Backup InputDatabaseMaker\*.*  >nul  >nul
     Call Zip ResultsRecursive Backup OutputGenerator\*.*  >nul  >nul
     Call Zip ResultsRecursive Backup UnitDataManager\*.*  >nul  >nul
     Call Zip ResultsRecursive Backup VBInput\*.*  >nul  >nul
     Call Zip ResultsRecursive Backup UsElectricUnits\*.*  >nul  >nul
     Call Zip ResultsRecursive Backup E3NA_E2020\*.*  >nul  >nul
     
rem
rem  Support files - sets, maps, etc.
rem
     Call Zip ResultsRecursive Backup Support\*.*  >nul
