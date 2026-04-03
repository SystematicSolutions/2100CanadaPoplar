rem
rem  RunSensitivity.bat
rem
rem %1 - Beginning Year
rem %2 - Ending Year
rem %3 - Scenario Name
rem
rem  Unzip required databases
rem
     Call StartScenario             StartBase %3 Base Base Base Base %3 
     Call RunJulia StartScenario.jl StartBase %3 Base Base Base Base %3 

     cd..\Policy
       Call RunJulia %3.jl
       Copy PolicyEmpty.jl            Policy.jl    
       Copy PolicyMarketShareEmpty.jl PolicyMarketShare.jl
       Copy PolicyTestEmpty.jl        PolicyTest.jl 
     cd..\2020Model

rem
rem  Execute the model
rem
     Call RunScenario %1 %2 %3 Base Base Base Base %3  All   
rem          
