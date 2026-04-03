rem
rem ReadTOMForecastScenario.bat
rem
rem  %1 - End Year
rem  %2 - Scenario Name
rem  %3 - Base Case
rem  %4 - Reference Case
rem  %5 - TOM Scenario
rem  %6 - Base Case Switch (Base, Reference, Policy)
rem  %7 - OG Price
rem  %8 - E2020 Policy Batch File
rem
rem                              %EndYr %Scenario %BCase %RefCase %BSwitch %TOMFcst OGPrice
rem                              ----------------------------------------------------------
     Call InitializeNonIntegratedTOM  %1    %2      %3     %4      %6        %5     %7
rem
     Call :GetInitialDatabase
     Call :ReadTOMDatabase
     Call :TransferTOMToE2020

rem
     :GetInitialDatabase
       echo   GetInitialDatabase %TOMScenario% >> %LogFileName%
       cd %Root%\2020TOM\
         del TOMInitial.db
         echo     Copy 2020TOM\TOMForecast\%TOMScenario%\TOMInitial.db to 2020TOM\TOMInitial.db >> %LogFileName%
         Copy %Root%\2020TOM\TOMForecast\%TOMScenario%\TOMInitial.db %Root%\2020TOM\TOMInitial.db
         Copy TOMInitial.db TOMDatabase_%ScenarioName%.db  
       cd %Root%\2020Model
     Exit /B 0

rem
     :ReadTOMDatabase
       echo   ReadTOMDatabase >> %LogFileName%
       
       cd %Root%\2020TOM\
         echo     Call TOM_Outputs_from_TOM_to_CSV from TOMDatabase_%ScenarioName%.db into TOM_Outputs_%ScenarioName%.csv  >> %LogFileName%
         Call TOM_Outputs_from_TOM_to_CSV  TOMDatabase_%ScenarioName%.db  TOM_Outputs_%ScenarioName%.csv

         echo     Copy TOMDatabase_%ScenarioName%.db to \2020Model\TOMDatabase_%ScenarioName%.db  >> %LogFileName%
         Copy TOMDatabase_%ScenarioName%.db %Root%\2020Model\TOMDatabase_%ScenarioName%.db
         echo     Copy TOM_Outputs_%ScenarioName%.csv to \2020Model\TOM_Outputs_%ScenarioName%.csv  >> %LogFileName%
         Copy TOM_Outputs_%ScenarioName%.csv %Root%\2020Model\TOM_Outputs_%ScenarioName%.csv
       cd %Root%\2020Model\
     Exit /B 0
 
 rem
     :TransferTOMToE2020
       echo   TransferTOMToE2020 >> %LogFileName%

       echo     Call TOM_Outputs_from_CSV_to_E2020 Database.hdf5 TOM_Outputs_%ScenarioName%.csv >> %LogFileName%
       Call     TOM_Outputs_from_CSV_to_E2020      Database.hdf5 TOM_Outputs_%ScenarioName%.csv

       echo     Move *.dat files to \InputData\Process; Call RunDataReader>> %LogFileName%
       Move *.dat ..\InputData\Process
       cd ..\InputData
         Call RunDataReader TOM
       cd ..\2020TOM

       echo       MapTOMtoE2020.jl  >> %LogFileName%
       echo       ScaleMissingGrossOutput_TOM.jl  >> %LogFileName%
       cd..\Input\Scripts
         Call RunJulia MapTOMtoE2020.jl     
       cd..\..\Calibration
         Call RunJulia ScaleMissingGrossOutput_TOM.jl
       cd !Root!\2020Model

     Exit /B 0
