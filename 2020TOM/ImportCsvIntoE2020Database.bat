rem
rem  ImportCsvIntoE2020Database.bat
rem
rem %1 Name of E2020 database (database.hdf5)
rem %2 Name of  output file (TOM_Outputs_*.csv)
rem     

Call ..\VBInput\E3NA_E2020.exe ImportCsvIntoDatabase %1 %2
      