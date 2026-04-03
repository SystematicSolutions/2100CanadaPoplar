rem
rem  RunE2100Runs.Bat
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
rem  Call RunE2100 Base   Base   TestEmpty 2020 2050 Base  Base  Base   ExcelDTAs
rem  Call RunE2100 OGRef  OGRef  TestEmpty 2020 2050 Base  Base  Base   ExcelDTAs
rem  Call RunE2100 Ref25  Ref25  TestEmpty 2020 2050 Base  Base  Base   ExcelDTAs
rem  Call RunE2100 Ref25A Ref25A TestEmpty 2020 2050 Ref25 Ref25 Ref25A ExcelDTAs

rem  Call RunE2100 CCSTestB Ref25 CCSTestB 2020 2050 Base  Base  Base   ExcelDTAs
rem  Call RunE2100 CCSTestA Ref25 CCSTestA 2020 2050 Base  Base  Base   ExcelDTAs
rem  Call RunE2100 CCSTestC Ref25 CCSTestC 2020 2050 Base  Base  Base   ExcelDTAs
rem  Call RunE2100 No_OBA Ref25 No_OBA 2020 2050 Base  Base  Base ExcelDTAs
rem  Call RunE2100 YDEMM3_Exo Base PolicyYDEMM03 2020 2050 Base  Base  Base ExcelDTAs

rem  Call RunE2100 Ref25_400             Ref25_400             TestEmpty 2020 2050 Base  Base  Base ExcelDTAs
rem  Call RunE2100 Ref25_NOITCCFRCEROBPS Ref25_NOITCCFRCEROBPS TestEmpty 2020 2050 Base  Base  Base ExcelDTAs

     Call RunE2100 Ref_000   Ref_000     TestEmpty 2020 2050 Base  Base  Base ExcelDTAs
     Call RunE2100 Ref_400   Ref_400     TestEmpty 2020 2050 Base  Base  Base ExcelDTAs
     Call RunE2100 Ref_999   Ref_999     TestEmpty 2020 2050 Base  Base  Base ExcelDTAs



     pause

