rem 
rem  RunOGScenario.bat 
rem
rem  %1 - Scenario Name
rem  %2 - Policy or Parameter File
rem  %3 - Price Specification
rem  %4 - Ending Year
rem
rem
rem  Reference Policies
rem
     Call StartScenario StartBase OG_%1       Base Base OGRef OGRef OG_%1
     Call RunJulia  StartScenario.jl  StartBase  OG_%1  Base  Base  OGRef  Base  OG_%1 

     cd..\Policy
       Copy Ref25.jl Policy.jl 
       Copy PolicyMarketShareFull.jl  PolicyMarketShare.jl
       Copy PolicyTestEmpty.jl        PolicyTest.jl         
     cd..\2020Model
        Call RunJulia IncorporatePolicies.jl
     cd..\Policy
       Copy PolicyEmpty.jl            Policy.jl    
       Copy PolicyMarketShareEmpty.jl PolicyMarketShare.jl
       Copy PolicyTestEmpty.jl        PolicyTest.jl 
     cd..\2020Model

rem
rem  Parameter and/or Policy File
rem
     If %2==None GoTo EndPolicy
       cd..\Policy
         Call RunJulia OG_UnitCalibration.jl    
       cd..\2020Model
     If %2==NoAdjust GoTo EndPolicy
       cd..\Policy
         Call RunJulia OG_AdjustTest_%2.jl
       cd..\2020Model
     :EndPolicy

rem
rem  Price Specification
rem
     If %3==None GoTo EndPrices
       cd..\Policy
         Call RunJulia WholesalePrices_%3.jl
       cd..\2020Model    

       cd..\Calibration        
         Call RunJulia WholesalePrices_Revisions.jl
         Call RunJulia WholesalePrices_Select.jl
       cd..\2020Model    

     :EndPrices  

rem 
     Call   RunScenario 2020 %4 OG_%1       Base Base OGRef Base OG_%1 All
     