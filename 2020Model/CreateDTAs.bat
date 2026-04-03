rem
rem  CreateDTAs.bat for a single scenario
rem
rem  %1 - Scenario Name
rem  %2 - Reference Scenario
rem  %3 - Scenario for zInitial in Access outputs
rem  %4 - Output Type - ExcelDTAs, AccessDTAs, All, None
rem
rem  Optional Database switch CAUTION Only use paramteres below if confident
rem  this option is correct, may cause bad results.
rem  %5 - NoUnZip - Do not unzip %1 Scenario Databases 
rem  %5 - NoDelete - Do not delete Reference Databases for %1
rem  %5 - NoUnZipNoDelete - Do not unzip DBs and do not delete Reference Databases
rem
rem  1. Update list file
rem
rem     echo %1 >> ScenarioList.txt
rem     If "%5"=="" (Set RunType=Normal) Else (Set RunType=%5)
rem     Set NoUnZip=NoUnZip
rem     Set NoDelete=NoDelete
rem     Set NoUnZipNoDelete=NoUnZipNoDelete
rem
rem     If %4==None Goto NoOutput 
rem     If %RunType%==%NoUnZip% Goto SkipUnzip
rem     If %RunType%==%NoUnZipNoDelete% Goto SkipUnzip
rem
rem  2. Unzip scenario databases
rem
rem     Call UnZip %1
rem     :SkipUnzip
rem
rem  3. Unzip Reference databases (fi this is needed, we need to rethink - Jeff Amlin 3/1/24  
rem
rem  Call StartScenario %1 %1 %2 %2 %2 %3 %1   

     Echo %Date% ;%Time%; Begin DTAs  %computername% >> CreateOutputs_Report.log
rem
rem  4. Output Files
rem
     If %4==None Goto EndOfOutput
       RD /s/q out
       MD out
       Del .\%1\*.dta     
       set JULIA_NUM_THREADS=20
       Call RunJulia CoreCounter.jl
       Call SetThreadCount    
       Call RunJulia OutputThreader.jl %4     
       Echo %Date% ;%Time%; End Parallel DTAs  %computername% >> CreateOutputs_Report.log       
rem
rem    Single Output Files
rem
rem    Call RunJulia RunDTAs.jl %1 %2 %4 EnergyModel
     
rem
rem    Exceptions
rem
rem       CD..
rem         Set Root=%CD%
rem       CD %Root%\2020Model       
rem    julia --project %Root%\Output/AccessOutput//ElectricUnits/zUnPol.jl     
rem    julia --project %Root%\Output/AccessOutput//ElectricUnits/zUnNode.jl
rem    julia --project %Root%\Output/AccessOutput//ElectricUnits/zUnRCGA.jl
rem    julia --project %Root%\Output/AccessOutput//TransPollution/zTrOREnFPol.jl

       Echo %Date% ;%Time%; End Single DTAs  %computername% >> CreateOutputs_Report.log       
       
rem
rem    Save(Zip) output files (some may not exist)
rem
       Copy .\out\*.* .\%1
rem       Call Zip Results %1\%1_AccessDTAs %1\z*.dta %1\q*.dta
       Call Zip Results %1\%1_AccessDTAs .\%1\z*.dta
       Call Zip Results %1\%1_AccessDTAs .\%1\q*.dta
       Del %1\z*.dta %1\q*.dta
rem       Call Zip Results %1\%1_ExcelDTAs %1\*.dta
       Call Zip Results %1\%1_ExcelDTAs .\%1\*.dta
rem    Del %1\*.dta
rem
rem    Create Access Databases
rem
     Echo %Date% ;%Time%; Begin Access Databases %computername% >> CreateOutputs_Report.log
     If %4==ExcelDTAs Goto EndOfOutput 
     If %4==Test Goto EndOfOutput     
rem    Del *-%1*.accdb
rem    Del %1\%1_AccessDBs.zip
rem    Call CreateAccessOutputDatabases %1    
rem    Del z*.dta q*.dta *-%1*.accdb
     :EndOfOutput
     Echo %Date% ;%Time%; End Access Databases   %computername% >> CreateOutputs_Report.log


rem
rem  5. Create Disaggregated Unit Data
rem
rem     If %4==Short Goto DeleteDBs
rem     If %4==None Goto DeleteDBs
rem     If %4==ExcelDTAs Goto DeleteDBs
rem     Call DisaggregateUnitData %1   
rem
rem  6. Delete Reference and Initial Databases
rem
rem    :DeleteDBs
rem     If not "%ScenarioName%" == "" Goto SkipDelete
rem     If %RunType%==%NoDelete% Goto SkipDelete 
rem     If %RunType%==%NoUnZipNoDelete% Goto SkipDelete
rem     Call ..\VBInput\DatabaseUnzipper.exe DeleteDatabases
rem     :SkipDelete  
rem
rem  7. UnZip Summary DTAs for SSI PCs
rem
rem     Call UnzipExcelDTAs %1
rem
rem 

     
