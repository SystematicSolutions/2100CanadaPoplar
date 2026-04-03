rem
rem echo       SolveTOM.bat starting with %1 solve into %2 %3 %4 %4 >> %LogFileName%     
rem
rem  %1 - database (*.db)
rem  %2 - output database (*.db)
rem  %3 - Start Year (1985)
rem  %4 - End Year (2050)
rem  %5 - Nations to run (CN, US, or CN_US)

rem  Pass in begin year end year and CN, US or CN_US
     
     Call ..\VBInput\E3NA_E2020.exe SolveTOM %1 %2 %3 %4 %5
