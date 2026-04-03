rem
rem  RunOGRef.bat - OGRef with Base
rem
     Echo %Date% ;%Time%; Begin RunOGRef on %ComputerName% >> RunModel_Report.log  
rem
rem  Unzip required databases
rem
     Call StartScenario             StartBase OGRef Base Base Base Base OGRef 
     Call RunJulia StartScenario.jl StartBase OGRef Base Base Base Base OGRef 
rem
rem  Compile policies
rem
     cd..\Policy
       Copy OGRef.jl Policy.jl
       Echo %date% ;%time%; Inside RunOGRef.bat Copy OGRef.jl Policy.jl  >> Policy_Report.log       
     cd..\2020Model
rem
rem  Execute the model
rem
     Call RunScenario %1 %2 OGRef Base Base Base Base OGRef  ExcelDTAs   
rem          
     Echo %Date% ;%Time%; End RunOGRef on %ComputerName% >> RunModel_Report.log  