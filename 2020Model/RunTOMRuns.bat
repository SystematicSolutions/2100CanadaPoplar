rem  
rem  RunTOMRuns.bat
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
rem                     Scenario Begin End   Base  Reference  Base       TOM            OGPrice 
rem                              Year  Year  Case  Case       Switch     Forecast                  
rem                     -----------------------------------------------------------------------
     Call RunPolicy_TOM Ref25    2020  2050  Base  Base       Reference  Baseline         None
     Call RunPolicy_TOM Ref25A   2020  2050  Base  Ref25_TOM  Policy     Baseline_Ref25A  None  
