rem
rem  SaveTOMResults.bat - Unzip the Start database
rem
rem  %1 - Scenario Name
rem
rem  Populate E2020 to TOM Transfer Variables
rem
     Echo %Date% ;%Time%; Call E2020_to_TOM for %1 >> RunModel_Report.log       
     cd..\2020TOM
      Call RunJulia CsvMaker.jl database.hdf5 E2020_Outputs_%1.csv 2020 2050
      Copy E2020_Outputs_%1.csv ..\2020Model\E2020_Outputs_%1.csv
     cd..\2020Model
     Echo %Date% ;%Time%; End Create E2020_Outputs_%1.csv >> RunModel_Report.log   
rem    
rem  Save TOM databases
rem
    Call Zip ResultsRecursive %1\%1_TOMFiles TOMDatabase_%1*.db  TOM_Outputs_%1.csv E2020_Outputs_*.csv TOMDatabase_%1.run TOMDatabase_%1.out
    Call CleanTOM
rem
     Echo %Date% ;%Time%; End SaveTOMResults %1 on %ComputerName% >> RunModel_Report.log       
