rem
rem  echo       %date% ;%time%; TOM_Outputs_from_TOM_to_CSV.bat from %1 to %2 >> %LogFileName%
rem
rem  %1 Name of TOM database (TOMDatabaseInitial.db)
rem  %2 Name of TOM Output CSV file (TOMDatabaseInitial.csv)
rem     
     Call ExportTOMDatabaseToCSV %1 %2
      