rem
rem  RunRef25ARun.Bat
rem
     Echo ENERGY 2100 Model RunRef25ARun      > RunRef25ARun_Report.log
     Echo Version:     %cd%                  >> RunRef25ARun_Report.log
     Echo Computer:    %computername%        >> RunRef25ARun_Report.log
     Echo %Date% ;%Time%; Start RunRef25ARun >> RunRef25ARun_Report.log
rem
rem  RunRef25A.bat - executes a Ref25A case 
rem
     Call RunE2100 Ref25A Ref25A TestEmpty 2020 2050 Ref25 Ref25 Ref25A      
     Echo %Date% ;%Time%;   End RunRef25ARun >> RunRef25ARun_Report.log      
rem
     pause

