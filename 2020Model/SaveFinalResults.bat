rem
echo SaveFinalResults.bat %ScenarioName% >> %LogFileName%
rem
     Call :CreateE2020Subdirectory
     Call :SaveE2020Database
     Call :CopyAndSaveTOMFiles
     Call :CreateAndSaveE2020Outputs
     Call :CleanUpE2020Subdirectory
     Call :CleanUpTOMSubdirectory
     Exit /B 0
         
     :CreateE2020Subdirectory
      echo   CreateE2020Subdirectory %ScenarioName% >> %LogFileName%          
      Call SetScenarioName %ScenarioName% %BaseCase% %BaseCase% %BaseCase% %BaseCase% %InvCase%
      RD /s/q %ScenarioName%
      MD %ScenarioName% 
      Exit /B 0     
      
     :CopyAndSaveTOMFiles
      echo   CopyAndSaveTOMFiles from %ScenarioName%_%TotalIterations% to %ScenarioName% >> %LogFileName% 
      Call UnCall Zip -o %ScenarioName%_%TotalIterations%\%ScenarioName%_%TotalIterations%_TOMFiles.zip TOMDatabase*.* TOM_Outputs*.csv E2020_Outputs*.csv
      Rename TOMDatabase_%ScenarioName%_%TotalIterations%.db    TOMDatabase_%ScenarioName%.db
      Rename TOMDatabase_%ScenarioName%_%TotalIterations%a.db   TOMDatabase_%ScenarioName%a.db
      Rename TOMDatabase_%ScenarioName%_%TotalIterations%.out   TOMDatabase_%ScenarioName%.out
      Rename TOMDatabase_%ScenarioName%_%TotalIterations%.run   TOMDatabase_%ScenarioName%.run
      Rename TOM_Outputs_%ScenarioName%_%TotalIterations%.csv   TOM_Outputs_%ScenarioName%.csv
      Rename E2020_Outputs_%ScenarioName%_%TotalIterations%.csv E2020_Outputs_%ScenarioName%.csv
      Call Zip Results  %ScenarioName%\%ScenarioName%_TOMFiles.zip  TOMDatabase_%ScenarioName%.db
      Call Zip Results  %ScenarioName%\%ScenarioName%_TOMFiles.zip  TOMDatabase_%ScenarioName%a.db
      Call Zip Results  %ScenarioName%\%ScenarioName%_TOMFiles.zip  TOMDatabase_%ScenarioName%.out
      Call Zip Results  %ScenarioName%\%ScenarioName%_TOMFiles.zip  TOMDatabase_%ScenarioName%.run
      Call Zip Results  %ScenarioName%\%ScenarioName%_TOMFiles.zip  TOM_Outputs_%ScenarioName%.csv
      Call Zip Results  %ScenarioName%\%ScenarioName%_TOMFiles.zip  E2020_Outputs_%ScenarioName%.csv
      Exit /B0      
   
     :SaveE2020Database   
      echo   SaveE2020Database %ScenarioName% >> %LogFileName%          
      Call Zip Results %ScenarioName%\database *.HDF5 ScenarioInfo.tmp MacroModel.tmp TOMDatabase_%ScenarioName%.db       
      Call Zip Results %ScenarioName%\%ScenarioName%_TOMFiles TOMDatabase_%ScenarioName%*.db  TOM_Outputs_%ScenarioName%.csv E2020_Outputs_%ScenarioName%.csv TOMDatabase_%ScenarioName%.run TOMDatabase_%ScenarioName%.out         
      Exit /B 0 

     :CreateAndSaveE2020Outputs
      echo   CreateAndSaveE2020Outputs %ScenarioName% >> %LogFileName% 
      echo CreateOutputFiles %ScenarioName% %BaseCase% %RefCase% All >> %LogFileName% 
      Call CreateOutputFiles %ScenarioName% %BaseCase% %RefCase% All
      echo End of CreateOutputFiles %ScenarioName% %BaseCase% %RefCase% All >> %LogFileName% 
      Exit /B 0     
     
     :CleanUpE2020Subdirectory
      echo   CleanUpE2020Subdirectory %ScenarioName% >> %LogFileName% 
      cd %Root%\2020Model\
        del *.csv
        del *.db
        del TOMDatabase*.out
        del TOMDatabase*.run
        del *.txoo
        del *.txtt
        del *.runn
      cd %Root%\2020Model\%BaseCase%
        del *.dba
        del *.dta
      cd..
      cd %Root%\2020Model\%RefCase%
        del *.dba
        del *.dta
      cd %Root%\2020Model\%InvCase%
        del *.dba
        del *.dta
     Exit /B 0
     
     :CleanUpTOMSubdirectory
     echo   CleanUpTOMSubdirectory %ScenarioName% >> %LogFileName% 
     cd %Root%\2020TOM\
       ren KOutput.csv KOutput.ccc
       ren TOMInitial.db TOMInitial.dd
       del *.csv
       del TOMDatabase*.db
       ren KOutput.ccc KOutput.csv
       ren TOMInitial.dd TOMInitial.db
       del *.txoo
       del *.txtt
       del *.runn
       del ScenarioInfo*.tmp 
       del E2020_Outputs*.run
       del TOMDatabase*.run
       del TOMDatabase*.out
     cd %Root%\2020Model\
     Exit /B 0
     