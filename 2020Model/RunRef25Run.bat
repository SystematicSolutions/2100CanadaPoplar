rem
rem  RunRef25Run.Bat
rem
     Echo ENERGY 2100 Model RunRef25Run      > RunRef25Run_Report.log
     Echo Version:     %cd%                 >> RunRef25Run_Report.log
     Echo Computer:    %computername%       >> RunRef25Run_Report.log
     Echo %Date% ;%Time%; Start RunRef25Run >> RunRef25Run_Report.log
rem
rem  RunRef25.bat - executes a Ref25 case 
rem
     Call RunE2100 Ref25 Ref25 TestEmpty 2020 2050 Base Base Base All
     Echo %Date% ;%Time%;   End RunRef25Run >> RunRef25Run_Report.log      
rem
     pause

