rem
rem TestNewTOMDB.bat - check new TOM DB for missing data
rem
rem  Output TOM DB to CSV
rem

    mdl export -d TomInitial.db -a TomInitial.csv -f Classic_h

rem
rem  Run tool to compare vs expected data set
rem


    Call ..\VBInput\E3NA_E2020.exe MakeExclusionFile


