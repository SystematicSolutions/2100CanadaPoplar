rem
rem  RunAll_Debug.bat
rem
     md log
     Echo ENERGY 2100 Model RunAll      > RunAll_Report.log
     Echo Version:     %cd%            >> RunAll_Report.log
     Echo Computer:    %computername%  >> RunAll_Report.log
     Echo %Date% ;%Time%; Start RunAll >> RunAll_Report.log
rem 
rem  Assign the Current Directory to the variable "Root"
rem
     CD..
       Set Root=%CD%
     CD %Root%\2020Model
     echo %Date% ;%Time%; Root = %Root% >> RunAll_Report.log
rem
rem  Initialize with empty policy code
rem
     CD %Root%\Policy
       Copy PolicyEmpty.jl            Policy.jl    
       Copy PolicyMarketShareEmpty.jl PolicyMarketShare.jl
       Copy PolicyTestEmpty.jl        PolicyTest.jl 
     CD %Root%\2020Model     
     
rem
rem  Create Model Databases
rem
     CD %Root%\InputData
       Call RunJulia UnitInitialize.jl
     CD %Root%\2020Model
     Call RunModelDatabaseCreate
     Echo %Date% ;%Time%; End Database Creation %computername% >> RunAll_Report.log

rem
rem ============================================================
rem
rem  Input data to fill the Process database
rem
     set JULIA_NUM_THREADS=20
     Call RunJulia CoreCounter.jl
     Call SetThreadCount 
     Call InputProcessData
     Echo %Date% ;%Time%; End Process Data %computername% >> RunAll_Report.log

rem
rem ============================================================
rem
     Echo %date% ;%time%; Begin RunTOM_ExtractData_Initial %computername% >> RunAll_Report.log       
     CD %Root%\2020TOM
       Copy %CD%\TOMForecast\Baseline\TOMInitial.db ..\2020TOM\TOMDatabase_Process.db
       Call TOM_Outputs_from_TOM_to_CSV  TOMDatabase_Process.db  TOM_Outputs_Process.csv
       Move TOMDatabase_Process.db  ..\2020Model
       Move TOM_Outputs_Process.csv ..\2020Model
       Call CleanupTOMFiles

     CD %Root%\2020Model      
       echo 2050 > TOMEndYear.log
       Call TOM_Outputs_from_CSV_to_E2020 database.hdf5  TOM_Outputs_Process.csv
       Move *.dat ..\InputData\Process
     cd ..\InputData
       Call RunDataReader TOM
     cd ..\2020Model
       Rename TOM_Outputs_Process.csv TOM_Outputs_Process.ccc
       Rename TOMDatabase_Process.db TOMDatabase_Process.dd
       Call CleanTOM
       Rename TOM_Outputs_Process.ccc TOM_Outputs_Process.csv
       Rename TOMDatabase_Process.dd TOMDatabase_Process.db

     Echo %date% ;%time%; Begin CheckTOMDrivers.jl %computername% >> RunAll_Report.log
     cd..\EconomicTransfers
       Call RunJulia CheckTOMDrivers.jl
     cd..\2020Model
       set /p TOMErrorCheck=< errorchecktomdrivers.log  
       set TOMErrorCode=%TOMErrorCheck%
       Echo %date% ;%time%; TOMErrorCode=%TOMErrorCode% %computername% >> RunAll_Report.log
       if %TOMErrorCode%==ERROR GoTo :TOMError
     Echo %date% ;%time%; End RunTOM_ExtractData_Initial %computername% >> RunAll_Report.log       

     cd..\Input\Scripts
       Call RunJulia MapTOMtoE2020.jl     
     cd..\..\2020Model
     Echo %Date% ;%Time%; End Map TOM to E2020 %computername% >> RunAll_Report.log
rem
rem  Create .DAT files of TOM Inflation and Exchange values
rem
     cd..\InputData
       Call RunJulia InflationReader.jl
     cd..\2020Model
     Echo %Date% ;%Time%; End Initial Data %computername% >> RunAll_Report.log     

rem
rem ============================================================
rem
rem  Convert user friendly *.dat files into Julia friendly *.dat files
rem
     Call CreateVBInput
     Echo %Date% ;%Time%; End CreateVBInput %computername% >> RunAll_Report.log     
rem
     
     Call CreateElectricUnitDBs
     Echo %Date% ;%Time%; End CreateElectricUnitDBs %computername% >> RunAll_Report.log
rem
rem  Fill database with data from Julia friendly *.dat files
rem
rem  TODO: RunDataReader reads in all .dat files below; however, the 
rem        TOM .dat files have already been read in. Add option to read non-TOM
rem        7/12/25 R.Levesque
rem
     cd..\InputData
       Call RunDataReader All
     cd..\2020Model
     Echo %Date% ;%Time%; End DataReader %computername% >> RunAll_Report.log

     cd..\Input\Scripts
       Call RunJulia Elec_UnRetire_VB.jl
     cd..\..\2020Model
     Call SaveDatabase Process   
     Echo %Date% ;%Time%; End Process Data %computername% >> RunAll_Report.log

rem
rem  Start the RunModel.bat file
rem
     Echo %Date% ;%Time%; Begin RunModel %computername% >> RunAll_Report.log
     Call RunModel Debug
     Echo %Date% ;%Time%; End RunModel %computername% >> RunAll_Report.log
     GoTo :EndRun     
rem
rem  End of RunAll
rem
     Echo %Date% ;%Time%; End RunAll %computername% >> RunAll_Report.log

  :TOMError
    echo ***** Problem reading TOM drivers! *****
    pause

  :EndRun
