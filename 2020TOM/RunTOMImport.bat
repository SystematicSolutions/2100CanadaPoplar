rem
rem  RunTOMImport.bat
rem
rem  %1 - input database (*.db)
rem  %2 - name of file to import (*.csv)
rem  %3 - output database (*.db)
rem  %4 - model directory
rem  %5 - format ( CSV_V or CSV_H )
rem  %6 - run file (*.run)
rem
rem  -d | --input-database   - The input database for the solution.
rem  -i | --input-file       - The path to the file from which variable data will be imported.
rem  -r | --run-file         - The path to which a copy of the import run file will be saved. (Optional)
rem  -m | --model-directory  - The working directory of the TOM Model.
rem  -o | --output-database  - The model database (.DB) which holds the result of the command.
rem  -f | --format           - A named format to use for importing and exporting data.
rem
rem  ***************************
rem

echo mdl import -d %1 -i %2 -o %3 -m %4 -f %5 -r %6 >> RunTOMInput.out
     mdl import -d %1 -i %2 -o %3 -m %4 -f %5 -r %6 >> RunTOMInput.out

