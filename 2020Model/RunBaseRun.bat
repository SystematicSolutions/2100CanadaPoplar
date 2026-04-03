rem
rem  RunBaseRun.bat
rem
rem  RunBase.bat - executes a Base case 
rem
     Echo ENERGY 2100 Model Run Base    > RunBase_Report.log
     Echo Version:     %cd%            >> RunBase_Report.log
     Echo Computer:    %computername%  >> RunBase_Report.log
     Echo %Date% ;%Time%; Start Run Base >> RunBase_Report.log
rem
     Call RunBase 2020 2050
rem
     Echo %Date% ;%Time%; End Run Base >> RunBase_Report.log
     
     pause
