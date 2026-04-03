rem 
rem  RunRef25TOMScenario.bat - Execute Integrated Reference Case Scenario
rem
rem  %1 - Scenario Name
rem  %2 - TOM Scenario (Baseline, Fast, Slow, HighPrice, LowPrice, FastHP, SlowLP) 
rem  %3 - OGPrice Scenario
rem  %4 - Beginning Year
rem  %5 - Ending Year
rem  %6 - TOM Flag - TOM, NoTOM, or OnlyTOM
rem
     Set ModelFolder=%CD%
     CD..
     Set Root=%CD%
     CD %ModelFolder%
     
     Set LogFileName=%Root%\RunRef25TOMScenario.log

     Echo RunRef25TOMScenario > %LogFileName%
     Echo Root %Root% >>  %LogFileName%
     Echo Version:     %Root% >> %LogFileName%
     Echo Computer:    %computername% >> %LogFileName%
     Echo %date% ;%time%; Start Time >> %LogFileName%
     Set LogRunStatus=%Root%\LogRunStatus.log

If %6==OnlyTOM GoTo BeginTOM

rem
rem  Non-Integrated Run
rem
     Echo   StartScenario StartBase Ref25_%1 Base Base OGRef Base Ref25_%1 >> %LogFileName%
     Call StartScenario               StartBase             Ref25_%1          Base      Base      OGRef       Base       Ref25_%1
     Call RunJulia  StartScenario.jl  StartBase             Ref25_%1          Base       Base     OGRef        Base      Ref25_%1 

     Echo   Execute Ref25.jl >> %LogFileName%
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
rem  OG Price Scenario
rem
     If %3==None GoTo EndPrices

       Echo   RunJulia WholesalePrices_%3.jl  >> %LogFileName%
       Echo   RunJulia WholesalePrices_Revisions.jl   >> %LogFileName%
       Echo   RunJulia WholesalePrices_Select.jl  >> %LogFileName%

       cd..\Policy
         Call RunJulia WholesalePrices_%3.jl
       cd..\2020Model    

       cd..\Calibration        
         Call RunJulia WholesalePrices_Revisions.jl
         Call RunJulia WholesalePrices_Select.jl
       cd..\2020Model  
     :EndPrices  

rem     
     Echo   Call ReadTOMForecastScenario %5 Ref25_%1 Base Base  %2 Reference %3 Ref25 >> %LogFileName%
     Call   ReadTOMForecastScenario   %5    Ref25_%1  Base  Base  %2 Reference %3 Ref25

     Echo   RunScenario    %4              %5          Ref25_%1          Base       Base      OGRef Base Ref25_%1 All >> %LogFileName%
     Call   RunScenario   %4              %5           Ref25_%1          Base       Base      OGRef       Base     Ref25_%1 All

If %6==NoTOM GoTo End
:BeginTOM

rem ============================================================
rem
rem  Integrated Scenario Runs 
rem
rem                              Scenario Begin End   Base  Reference  Base    TOM      OGPrice  Policy
rem                                       Year  Year  Case  Case       Switch  Forecast          File
rem                              -------------------------------------------------------------------------
     Call InitializeIntegratedTOM Ref25_%1  %4  %5   Base  Base     Reference %2        None    Ref25_%1
     Call IterateTOMScenario
     Call SaveFinalResults   

:End
exit /B 0
