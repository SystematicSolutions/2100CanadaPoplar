rem
rem  UnZipPromulaDatabase.bat
rem 
rem  %1 - scenario
rem
rem  UnZip Promula database
rem
     Call UnZip C:\2020CanadaSpruce\2020Model\%1
     Call RunJulia StartScenario.jl %1 %1 %1 %1 %1 %1 %1
  