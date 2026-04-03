rem
rem  ImportCsvIntoTOMDatabase.bat
rem
rem %1 Name of TOM database to update (*.db)
rem %2 Name of Input file (*.csv)
rem %3 Name of TOM database after update (*.db)
rem    

Call ..\VBInput\E3NA_E2020.exe ImportCsvIntoTOMDatabase %1 %2 %3

      