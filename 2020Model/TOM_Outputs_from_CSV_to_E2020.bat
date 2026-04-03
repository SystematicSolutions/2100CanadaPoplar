rem
rem  TOM_Outputs_from_CSV_to_E2020.bat - TOM outputs are transferred from a .CSV file
rem                                    to the Interface database (KOutput.dba)
rem  echo       %date% ;%time%; TOM_Outputs_from_CSV_to_E2020.bat from %1 to %2 >> %LogFileName%
rem
rem  %2 -Name of E2020 database (database.hdf5)
rem  %1 -Name of CSV file (*.csv)
rem     
    cd ..\2020TOM
      Call ImportCsvIntoE2020Database %1 %2
    cd ..\2020Model
 
      