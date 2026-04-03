     Echo   %date% ;%time%; Start Time >> LogTOMSpeed.log
rem  Unzip starting database either manually or here
rem
rem  Call Unzip \Ref25\database.zip   <-- this is not correct. do manually until fix.
rem  6/6/25 R.Levesque
rem
rem    cd ..\EconomicTransfers
rem       Call E2020_to_TOM
rem    cd ..\2020Model

     cd ..\2020TOM\
       Call RunJulia CsvMaker.jl database.hdf5 E2020_Outputs_Ref25_TOM_1.csv
       Call E2020_Outputs_From_CSV_To_TOM TOMDatabase_Ref25_TOM_1.db E2020_Outputs_Ref25_TOM_1.csv TOMDatabase_Ref25_TOM_2a.db
       Echo   %date% ;%time%; Before SolveTOM >> ..\2020Model\LogTOMSpeed.log

       Call SolveTOM TOMDatabase_Ref25_170_TOM_2a.db  TOMDatabase_Ref25_Test.db 2025 2050 CN_US

       Echo   %date% ;%time%; After SolveTOM >> ..\2020Model\LogTOMSpeed.log

       Call TOM_Outputs_from_TOM_to_CSV  TOMDatabase_Ref25_Test.db  TOM_Outputs_Ref25_Test.csv

       Echo   %date% ;%time%; After TOM_Outputs_from_TOM_to_CSV.bat >> ..\2020Model\LogTOMSpeed.log

       Copy TOMDatabase_Ref25_Test.db ..\2020Model\TOMDatabase_Ref25_Test.db
       Copy TOM_Outputs_Ref25_Test.csv ..\2020Model\TOM_Outputs_Ref25_Test.csv
     cd ..\2020Model\

rem
rem  Transfer TOM to E2020
rem
     Echo   %date% ;%time%; Begin Transfer TOM CSV to E2020 >> LogTOMSpeed.log
     Call TOM_Outputs_from_CSV_to_E2020 Database.hdf5 TOM_Outputs_Ref25_Test.csv

rem     Echo   %date% ;%time%; Begin RunDataReader TOM >> LogTOMSpeed.log
rem     Move *.dat ..\InputData\Process
rem     cd ..\InputData
rem       Call RunDataReader TOM
rem     cd ..\2020TOM

rem     Echo   %date% ;%time%; Begin MapTOMtoE2020 and ScaleMissingGrossOutput >> ..\2020Model\LogTOMSpeed.log
rem     cd..\Input\Scripts
rem       Call RunJulia MapTOMtoE2020.jl     
rem     cd..\..\Calibration
rem       Call RunJulia ScaleMissingGrossOutput_TOM.jl
rem     cd ..\2020Model
rem     Echo   %date% ;%time%; End MapTOMtoE2020 >> LogTOMSpeed.log

rem
rem CheckIfTOMSuccessful
rem
rem      cd..\EconomicTransfers
rem        Call RunJulia ErrorCheckTOM.jl
rem      cd..\2020Model
