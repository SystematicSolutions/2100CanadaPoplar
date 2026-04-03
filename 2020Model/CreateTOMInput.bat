rem 
rem CreateTOMInput.bat
rem
rem %1 Name of TOM database (TOMInitial.db)
rem %2 Name of  output file (TOMInitial.csv)
rem
   cd ..\2020TOM
     Call ImportCsvIntoDatabase %1 %2
   cd ..\2020Model
rem
rem  Copy output to Output directory
rem
    Move *.dat ..\InputData\Process
    