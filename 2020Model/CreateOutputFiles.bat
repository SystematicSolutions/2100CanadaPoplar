rem
rem  CreateOutputFiles.bat
rem
rem  %1 - Scenario Name
rem  %2 - Base Case Name
rem  %3 - Scenario for zInitial in Access outputs
rem  %4 - Output Type - ExcelDTAs, AccessDTAs, All, None
rem  %5 - NoUnZip - Optional - Do not unzip %1 Scenario Databases 
rem
     Call StartScenario %1 %1 %2 %2 %2 %3 %1 
     Call RunJulia StartScenario.jl %1 %1 %2 %2 %2 %3 %1
     
     Call CreateDTAs %1 %2 %3 %4
     
       



