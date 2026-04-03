rem
rem  CleanUpOutput.bat
rem
rem  %1 - ScenarioName
rem  %2 - ZipFileName
rem  %3 - OutputsToMove
rem
rem    
rem Move DTAsToMove (To Folder) ScenarioName
rem
    Move %3 %1   
rem 
rem Zip the dta files that were moved into specified zip file
rem
rem Call Zip.bat ScenarioName\ScenarioName_ZipFileName ScenarioName\DTAsToMove
rem
    Call Zip Results %1\%1_%2 %1\%3
rem   
rem Delete DTA Files
rem
rem Delete ScenarioName\DTAsToMove
rem
    Del %1\%3


