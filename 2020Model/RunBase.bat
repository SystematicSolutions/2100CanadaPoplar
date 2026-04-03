rem
rem  RunBase.bat
rem
rem  Unzip required databases
rem
     Call StartScenario             StartBase Base Base Base Base Base Base
     Call RunJulia StartScenario.jl StartBase Base Base Base Base Base Base
rem
rem  Compile policies
rem
     cd..\Policy
       Copy Base.jl Policy.jl 
       Echo %date% ;%time%; Inside RunBase.bat Copy Base.jl Policy.jl  >> Policy_Report.log         
     cd..\2020Model
rem
rem  Execute the model
rem
     Call RunScenario %1 %2 Base Base Base Base Base Base All   
rem
     Call SaveTOMResults Base
rem
