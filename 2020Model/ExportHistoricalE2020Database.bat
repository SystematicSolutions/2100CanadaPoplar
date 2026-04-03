rem
rem  E2020_Outputs_from_CSV_to_TOM.bat - E2020 Outputs are transfered from a .CSV file 
rem                                      to the TOM database
rem
rem %1 Name of HDF5 database
rem %2 Name of E2020 Output file (*.csv)
rem %3 Beginning year of export
rem %4 Ending year of export
rem    
     cd..\2020TOM
      Call RunJulia CsvMaker.jl database.hdf5 E2020_Outputs_Historical.csv 1985 2050
      Move E2020_Outputs_Historical.csv ..\2020Model\E2020_Outputs_Historical.csv
     cd..\2020Model


      