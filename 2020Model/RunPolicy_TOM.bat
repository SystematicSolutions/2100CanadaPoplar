rem  
rem  RunPolicy_TOM.bat - Execute Integrated Policy or Reference Cases
rem 
rem  %1 - Scenario Name
rem  %2 - Begin Year
rem  %3 - End Year
rem  %4 - Base Case
rem  %5 - Reference Case
rem  %6 - Base Switch (Base, Reference, Policy)
rem  %7 - TOM Forecast Scenario (Baseline, Fast, Slow, HighPrice, LowPrice, FastHigh, SlowLow)
rem  %8 - OG Price Scenario (NEB25_Ref, NEB25_Fast, etc.)
rem
Echo %Date% ;%Time%; Begin %1_TOM %computername% >> RunAll_Report.log  
rem
rem  Assign Root directories
rem
     Set ModelFolder=%CD%
     CD..
     Set Root=%CD%
     CD %ModelFolder%
rem
     Set LogFileName=RunPolicy_TOM.log
     Echo RunPolicy_TOM > %LogFileName%
     Echo   ENERGY 2100 Model RunPolicy_TOM >> %LogFileName%
     Echo   Version:     %ModelFolder% >> %LogFileName%
     Echo   Computer:    %computername% >> %LogFileName%
     Echo   %date% ;%time%; Start Time >> %LogFileName%
     Echo   ---   >> %LogFileName%
     Echo %3 > TOMEndYear.log
     Set LogRunStatus=%ModelFolder%\LogRunStatus.log
rem
rem                              Scenario Begin End   Base  Reference  Base    TOM      OGPrice
rem                                       Year  Year  Case  Case       Switch  Forecast        
rem                              --------------------------------------------------------------
     Call InitializeIntegratedTOM %1      %2    %3    %4    %5         %6      %7        None
     Call IterateTOMScenario
     Call SaveFinalResults   
rem
Echo %Date% ;%Time%; End   %1_TOM %computername% >> RunAll_Report.log   

exit /B 0
