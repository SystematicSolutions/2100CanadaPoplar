rem
rem  RunTOMExport.bat
rem
rem  %1 - database (*.db)
rem  %2 - output file (*.csv)
rem  %2 - selection (*.sel) file listing the series to export.
rem  %4 - format
rem  %5 - model directory
rem

rem  -d | --database         - The model database (.DB) file which is starting point for the command.
rem  -y | --start-year       - The first year for which data should be exported. Defaults to the earliest year in the selected database(s).
rem  -e | --end-year         - The last year for which data should be exported. Defaults to the latest year in the selected database(s).
rem  -a | --output-annual    - The file to which annual series will be exported. Any existing file will be overwritten.
rem  -o | --output-database  - The model database (.DB) which holds the result of the command.
rem  -q | --output-quarterly - The file to which quarterly series will be exported. Any existing file will be overwritten.
rem  -i | --input-file       - The file from which variable data will be imported.
rem  -t | --solution-range   - The range of periods to be solved in the form YYYYQQ-YYYYQQ
rem  -s | --selection        - A selection (.SEL) file listing the series to export. If missing, export level values for all series.
rem  -f | --format           - A named format to use for importing and exporting data.
rem  -m | --model-directory  - The working directory of the TOM Model.
rem
rem
rem  ***************************
rem

echo mdl export -d %1 -a %2 -s %3 -f %4 -m %5 >  RunTOMExport.out
     mdl export -d %1 -a %2 -s %3 -f %4 -m %5
