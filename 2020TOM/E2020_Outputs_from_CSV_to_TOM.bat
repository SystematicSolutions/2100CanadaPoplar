rem
rem  E2020_Outputs_from_CSV_to_TOM.bat - E2020 Outputs are transfered from a .CSV file 
rem                                      to the TOM database
rem
rem %1 Name of TOM database to update (*.db)
rem %2 Name of E2020 Output file (*.csv)
rem %3 Name of TOM database after update (*.db)
rem    
    Call ImportCsvIntoTOMDatabase %1 %2 %3

      