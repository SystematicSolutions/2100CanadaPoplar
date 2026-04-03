rem
rem  RunE2020.bat
rem
rem  %1 - Policy Batch File
rem  %2 - Carbon Price
rem  %3 - Reference Case
rem  %4 - Comparison Case
rem  %5 - Start Year
rem  %6 - Ending Year
rem  %7 - Outputs
rem
rem  Unzip required databases
rem
     Call StartScenario               StartBase %1_%2 Base %3 OGRef %4 %1_%2
     Call RunJulia StartScenario.jl StartBase %1_%2 Base %3 OGRef %4 %1_%2 
rem
rem  Compile policies
rem
     cd..\Policy
       Call RunJulia SetAsReferenceCase.jl
       Call %1
       Call CP_%2
     cd..\2020Model
rem
rem  Execute the model
rem
     Call RunScenario %5 %6 %1_%2 Base %3   OGRef %4 %1_%2 %7  
rem          
