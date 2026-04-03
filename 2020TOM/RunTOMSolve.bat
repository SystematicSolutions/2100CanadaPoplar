rem
rem  RunTOMSolve.bat
rem
rem  %1 - database (*.db)
rem  %2 - output database (*.db)
rem  %3 - run-file (.run)
rem  %4 - model directory
rem  %5 -solution-files-directory (Path for OUT file)
rem
rem
rem  -d | --input-database              - Required. The input database for the solution.
rem  -o | --output-database             - Required. Target location for the output database.
rem  -r | --run-file                    - The path to a run file to be applied to the Model before solving. (Optional)
rem  -t | --solution-range              - The range of periods to be solved in the form YYYYQQ-YYYYQQ. Exactly one of this option or 'run-file' must be specified.
rem  -m | --model-directory             - The working directory of the Model. Specifically this should contain files called sectors and OEFHelp_Kit.mdb. Defaults to the current working directory.
rem  -p | --show-progress               - Show progress throughout the solution
rem  -a | --solution-files-directory    - The directory to which the .out file for the solution will be saved. Each file will have the name of the output database and an existing file of the same name will be overwritten.
rem  -n | --no-copy                     - By default the input database is copied to a temporary location prior to solving to avoid locking it. Use this option to solve directly from the input database.
rem  -s | --suppress-errors             - Suppress error messages in the output.
rem
rem  ***************************
rem

echo mdl solve -d %1 -o %2 -r %3 -m %4 -a %5 >> RunTOMSolve1.out     
     mdl solve -d %1 -o %2 -r %3 -m %4 -a %5 >> RunTOMSolve2.out
     

