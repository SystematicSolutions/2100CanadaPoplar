rem
rem  RunE2100.bat - Execute ENERGY 2100
rem
rem  %1 - Scenario Name
rem  %2 - Reference Policy File
rem  %3 - Test Policy File
rem  %4 - Beginning Year
rem  %5 - Ending Year 
rem  %6 - Reference Case
rem  %7 - Scenario for zInitial in Access outputs
rem  %8 - Economic Model Investments Case (see Jeff)
rem  %9 - Output Files (All, ExcelDTAs, AccessDTAs, or None) 
rem
rem  Unzip required databases
rem 
     If %1==Base GoTo SpecialStartScenario
     If %1==OGRef GoTo SpecialStartScenario     
       Call StartScenario             StartBase %1 Base %6 OGRef %7 %8 
       Call RunJulia StartScenario.jl StartBase %1 Base %6 OGRef %7 %8 
       GoTo EndStartScenario
     :SpecialStartScenario
       Call StartScenario             StartBase %1 Base %6 Base %7 %8 
       Call RunJulia StartScenario.jl StartBase %1 Base %6 Base %7 %8      
     :EndStartScenario
rem
rem  Policy Files
rem
     cd..\Policy
       If %1==Base GoTo SpecialPolicy
         Copy %2.jl                    Policy.jl
         Copy PolicyMarketShareFull.jl PolicyMarketShare.jl
         Copy Policy%3.jl              PolicyTest.jl  
         GoTo EndPolicy
       :SpecialPolicy  
         Copy %2.jl                     Policy.jl
         Copy PolicyMarketShareEmpty.jl PolicyMarketShare.jl
         Copy Policy%3.jl               PolicyTest.jl       
       :EndPolicy  
     cd..\2020Model
rem
rem  Execute the model
rem
     If %1==Base GoTo SpecialRunScenario
     If %1==OGRef GoTo SpecialRunScenario     
       Call RunScenario %4 %5 %1 Base %6 OGRef %7 %8 %9        
       GoTo EndRunScenario
     :SpecialRunScenario
       Call RunScenario %4 %5 %1 Base %6 Base %7 %8 %9
     :EndRunScenario  
rem          
