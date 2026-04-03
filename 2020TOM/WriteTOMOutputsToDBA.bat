rem
rem  WriteTOMOutputsToDBA.bat - TOM outputs are transferred from a .CSV file
rem                                    to the Interface database (KOutput.dba)
rem
rem  %1 -Name of CSV file (*.csv)
rem  %2 -Name of Interface database (*.dba)
rem     
     Call ImportCsvIntoE2020Database TOM_Outputs_Process.csv KOutput.dba
      