rem
rem  Test_E2020Transfers.bat - 01/03/2023 R.Levesque
rem            - Run this file to test changes to E2020 transfer variables.
rem            - Example:  Modified E2020EnergyIntensity.txt.
rem            - Assumes Scenario_TOM_1 has been executed already.
rem            - Unzip 2020Model\Scenario_TOM_1\DBA.zip into 2020Model first.
rem          *** Review "TOM_Outputs_Scenario_Test.csv". Check if all years executed.  ***
rem
     Set LogFileName=Test_E2020Transfers.log
rem     
rem  Recreate ENERGY 2100 transfer files off of Scenario_TOM_1
rem
rem     Call E2020_Outputs_from_E2020_to_DBA
rem     Call E2020_Outputs_from_DBA_to_CSV KOutput.dba E2020_Outputs_TestTransfers.csv 2022-2050
rem     Call E2020_Outputs_from_CSV_to_TOM TOMInitial.db E2020_Outputs_Ref25_170_TOM_1.csv TOMDatabase_TestTransfersA.db
rem
rem  Rerun TOM and create TOM_Outputs_Base_TOM_1.csv
rem
rem     Call SolveTOM TOMDatabase_TestTransfersA.db TOMDatabase_TestTransfers.db 2022 2025  CN_US
rem     Call SolveTOM TOMInitial.db TOM_Ref25_Test.db 2022 2050  CN_US
     Call TOM_Outputs_from_TOM_to_CSV TOM_Ref25_Test.db TOM_Outputs_Ref25_Test.csv
      