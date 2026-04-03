rem
rem  IterateTOMScenario.bat
rem
     setlocal enabledelayedexpansion
rem
     echo   IterateTOMScenario.bat !ScenarioCurrent! E2020 Start Year = !BeginningYear! TOM Start Year - !TOMStartYear! End Year = !EndingYear! >> !LogFileName!
rem
     Set ScenarioCurrent=!ScenarioName!_1
     Call :RunStartScenario
     Call :InitializeE2020
     echo     ===== >> !LogFileName!

rem          
     for /l %%x in (1, 1, !TotalIterations!) do (
       
       Set /A Iteration=%%x
echo     Iteration !Iteration! >> !LogFileName!
         Set ScenarioCurrent=!ScenarioName!_!Iteration!
echo     ScenarioCurrent !ScenarioCurrent! >> !LogFileName!
echo     ScenarioPrior !ScenarioPrior! >> !LogFileName!
       
       Call :UnzipInvCaseDatabases
       If not !Iteration!==1 Call :UnZipScenarioPrior
       Call :SetUpE2020Policies     
       Call :SolveTOMUsingE2020ScenarioPrior
       Call :TransferTOMtoE2020
       Call :CheckIfTOMSuccessful
       echo     ExecuteE2020.bat !ScenarioCurrent! >> !LogFileName!
       If not !Iteration!==1 Call RunJulia StartScenario.jl StartBase !ScenarioCurrent! !BaseCase! !RefCase! !OGRefCase! !BaseCase! !InvCase!
       Call ExecuteE2020 
       Call SaveTOMResults !ScenarioCurrent!
       If not !Iteration!==%TotalIterations% Call :Clean2020ModelTOMFiles      
       Set ScenarioPrior=!ScenarioCurrent!
       
     )
     Exit /B !ERRORLEVEL!

rem
     :RunStartScenario
     echo      Run StartScenario    !ScenarioFirst! !ScenarioCurrent! !BaseCase! !RefCase! !OGRefCase! !BaseCase! !InvCase!; !time! >> !LogFileName!
     Call          StartScenario    !ScenarioFirst! !ScenarioCurrent! !BaseCase! !RefCase! !OGRefCase! !BaseCase! !InvCase!
     Call RunJulia StartScenario.jl !ScenarioFirst! !ScenarioCurrent! !BaseCase! !RefCase! !OGRefCase! !BaseCase! !InvCase!

     Exit /B 0

rem
     :InitializeE2020
     echo     InitializeE2020 unzip !ScenarioCurrent! !BaseCase! !InvCase! Model DBAs; !time! >> !LogFileName!
     Call UnZip RefDB !ScenarioCurrent! 
     Call UnZip RefDB !InvCase!
     Call UnZip RefDB !BaseCase!
     Call UnZip RefDB !RefCase!
     Exit /B 0

rem
     :SetUpE2020Policies
     echo     SetUpE2020Policies >> !LogFileName!

     cd..\Policy
       Copy PolicyEmpty.jl            Policy.jl    
       Copy PolicyMarketShareEmpty.jl PolicyMarketShare.jl
       Copy PolicyTestEmpty.jl        PolicyTest.jl  
     cd..\2020Model

     Set OGPrice=!OGPrice!
     echo     OGPrice = !OGPrice! >> !LogFileName!
     If !OGPrice!==None GoTo EndPricesTOM

       echo     RunJulia WholesalePrices_!OGPrice!.jl >> !LogFileName!
       cd..\Policy
         Call RunJulia WholesalePrices_!OGPrice!.jl
       cd..\2020Model    

       echo     RunJulia WholesalePrices-Revisions.jl >> !LogFileName!
       echo     RunJulia WholesalePrices_Select_NEB.jl >> !LogFileName!
       cd..\Calibration
         Call RunJulia WholesalePrices_Revisions.jl
         Call RunJulia WholesalePrices_Select.jl
       cd..\2020Model

     :EndPricesTOM

     Exit/B 0

rem  
     :UnzipInvCaseDatabases
     echo     UnzipInvCaseDatabases !InvCase!  >> !LogFileName!
     cd !Root!\2020Model\       
     Call UnZip RefDB !InvCase!
     Exit /B 0
rem
     :UnZipScenarioPrior
echo     UnZipScenarioPrior !ScenarioPrior!\!ScenarioPrior!_TOMFiles.zip to 2020Model\ E2020_Outputs_!ScenarioPrior!.csv TOMDatabase_!ScenarioPrior!.db >> !LogFileName!
         Call UnZip TOM !ScenarioPrior! E2020_Outputs_!ScenarioPrior!.csv TOMDatabase_!ScenarioPrior!.db
echo     Copy E2020_Outputs_!ScenarioPrior!.csv and TOMDatabase_!ScenarioPrior!.db to \2020TOM >> !LogFileName!
         Copy E2020_Outputs_!ScenarioPrior!.csv ..\2020TOM\E2020_Outputs_!ScenarioPrior!.csv
         Copy TOMDatabase_!ScenarioPrior!.db ..\2020TOM\TOMDatabase_!ScenarioPrior!.db
     Exit /B 0

     :SolveTOMUsingE2020ScenarioPrior
     echo     SolveTOMUsingE2020ScenarioPrior >> !LogFileName!
     echo       Change directory to !Root!\2020TOM >> !LogFileName!
     cd !Root!\2020TOM\
       Copy !Root!\2020TOM\TOMForecast\!TOMScenario!\TOMInitial.db TOMInitial.db
       If !Iteration!==1 echo       Copy TOMInitial.db TOMDatabase_!ScenarioCurrent!.db >> !Root!\2020Model\!LogFileName!
       If !Iteration!==1            Copy TOMInitial.db TOMDatabase_!ScenarioCurrent!.db       
       
       If not !Iteration!==1 echo       Call E2020_Outputs_From_CSV_To_TOM TOMDatabase_!ScenarioPrior!.db E2020_Outputs_!ScenarioPrior!.csv TOMDatabase_!ScenarioCurrent!a.db >> !Root!\2020Model\!LogFileName!
       If not !Iteration!==1            Call E2020_Outputs_From_CSV_To_TOM TOMDatabase_!ScenarioPrior!.db E2020_Outputs_!ScenarioPrior!.csv TOMDatabase_!ScenarioCurrent!a.db
         
       If not !Iteration!==1 echo       Call SolveTOM TOMDatabase_!ScenarioCurrent!a.db TOMDatabase_!ScenarioCurrent!.db !TOMStartYear! !EndingYear! !NationsToRun! >> !Root!\2020Model\!LogFileName!
       If not !Iteration!==1            Call SolveTOM TOMDatabase_!ScenarioCurrent!a.db TOMDatabase_!ScenarioCurrent!.db !TOMStartYear! !EndingYear! !NationsToRun!
       
echo       Call TOM_Outputs_from_TOM_to_CSV TOMDatabase_!ScenarioCurrent!.db TOM_Outputs_!ScenarioCurrent!.csv  >> !Root!\2020Model\!LogFileName!
           Call TOM_Outputs_from_TOM_to_CSV TOMDatabase_!ScenarioCurrent!.db TOM_Outputs_!ScenarioCurrent!.csv

echo       Copy TOMDatabase_!ScenarioCurrent!.db to !Root!\2020Model  >> !Root!\2020Model\!LogFileName!
           Copy TOMDatabase_!ScenarioCurrent!.db  !Root!\2020Model\TOMDatabase_!ScenarioCurrent!.db
           Copy TOMDatabase_!ScenarioCurrent!a.db !Root!\2020Model\TOMDatabase_!ScenarioCurrent!a.db
           Copy TOMDatabase_!ScenarioCurrent!.out !Root!\2020Model\TOMDatabase_!ScenarioCurrent!.out
           Copy TOMDatabase_!ScenarioCurrent!.run !Root!\2020Model\TOMDatabase_!ScenarioCurrent!.run

echo       Copy TOM_Outputs_!ScenarioCurrent!.csv to !Root!\2020Model  >> !Root!\2020Model\!LogFileName!
           Copy TOM_Outputs_!ScenarioCurrent!.csv    !Root!\2020Model\TOM_Outputs_!ScenarioCurrent!.csv
           del TOMDatabase_*.db  TOMDatabase_*.out  TOMDatabase_*.run
rem        Ren KOutput.csv KOutput.ccc
rem        del *.csv
rem        Ren KOutput.ccc KOutput.csv
echo       Change directory to !Root!\2020Model >> !Root!\2020Model\!LogFileName!
     cd !Root!\2020Model\

     Exit /B 0

rem
     :TransferTOMtoE2020
echo     TransferTOMtoE2020 >> !LogFileName!
echo       Call TOM_Outputs_from_CSV_to_E2020 Database.hdf5 TOM_Outputs_!ScenarioCurrent!.csv >> !LogFileName!
           Call TOM_Outputs_from_CSV_to_E2020 Database.hdf5 TOM_Outputs_!ScenarioCurrent!.csv
echo       Move *.dat files to \InputData\Process; Call RunDataReader>> !LogFileName!
           Move *.dat ..\InputData\Process
     cd ..\InputData
       Call RunDataReader TOM
     cd ..\2020TOM

     echo       MapTOMtoE2020.jl  >> !LogFileName!
     echo       ScaleMissingGrossOutput_TOM.jl  >> !LogFileName!
     cd..\Input\Scripts
       Call RunJulia MapTOMtoE2020.jl     
     cd..\..\Calibration
       Call RunJulia ScaleMissingGrossOutput_TOM.jl
     cd !Root!\2020Model
     Exit /B 0

rem
     :CheckIfTOMSuccessful
echo     CheckIfTOMSuccessful >> !LogFileName!

      cd..\EconomicTransfers
        Call RunJulia ErrorCheckTOM.jl
      cd..\2020Model

        @echo off

        set /p TOMErrorCheck=<ErrorCheckTOMDrivers.log  
        set firstFiveChrs=%TOMErrorCheck:~0,5%
        set firstTenChrs=%TOMErrorCheck:~0,10%
echo     TOMErrorCheck !firstFiveChrs! >> !LogFileName!
        if !firstFiveChrs! == ERROR GoTo :TOMError

      Exit /B0
      
rem
     :Clean2020ModelTOMFiles
     echo     Clean2020ModelTOMFiles >> !LogFileName!
     del *.csv
     del TOMDatabase_*.db
     del TOMDatabase_*.out
     del TOMDatabase_*.run
     Exit /B 0

:EndRun

rem
    :TOMError
      echo Copy and Zip TOM Files into !ScenarioCurrent! >> !LogFileName!
      RD /s/q !ScenarioCurrent!
      MD !ScenarioCurrent!

      Call Zip Results !ScenarioCurrent!\!ScenarioCurrent!_TOMFiles TOMDatabase_!ScenarioCurrent!*.*  TOM_Outputs_!ScenarioCurrent!.csv E2020_Outputs_!ScenarioPrior!.csv

      @echo off
      echo *
      echo ******** TOM ENCOUNTERED ERROR SOLVING !ScenarioCurrent! ********
      echo *

      @echo off
      FOR /F "tokens=* delims=" %%x in (errorchecktomdrivers.log) Do echo          %%x
      echo *     
      
      pause  
      GoTo :EndRun

Exit /B 0      
