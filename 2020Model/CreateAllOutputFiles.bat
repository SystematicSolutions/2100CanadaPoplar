rem
rem  CreateAllOutputFiles.bat
rem
rem  CreateOutputFiles.bat
rem
rem  %1 - Scenario Name
rem  %2 - Base Case Name
rem  %3 - Scenario for zInitial in Access outputs
rem 
rem     Echo ENERGY 2100 Model RunModel      > CreateOutputs_Report.log
rem     Echo Version:     %cd%              >> CreateOutputs_Report.log
rem     Echo Computer:    %computername%    >> CreateOutputs_Report.log
rem     Echo %Date% ;%Time%; Start RunModel >> CreateOutputs_Report.log
rem
rem     Echo %Date% ;%Time%; Begin Base All %computername% >> CreateOutputs_Report.log
rem     Call CreateOutputFiles Base           Base Base All   
rem
rem     Echo %Date% ;%Time%; Begin Ref25 All %computername% >> CreateOutputs_Report.log
     Call CreateOutputFiles Ref25          Base  Base  ExcelDTAs
rem     Call CreateOutputFiles Ref25_TOM      Base  Base  All  
rem     
rem     Echo %Date% ;%Time%; Begin Ref25A All %computername% >> CreateOutputs_Report.log
rem     Call CreateOutputFiles Ref25A         Base  Base  All
rem     Call CreateOutputFiles Ref25A_TOM     Base  Base  All
rem     
rem     Call CreateOutputFiles Process3 Process3 Process3 ExcelDTAs
rem     Call CreateOutputFiles Process2 Process2 Process2 Test
rem     Call CreateOutputFiles Process Process Process ExcelDTAs
rem     Call CreateOutputFiles Calib Calib Calib ExcelDTAs
rem     Call CreateOutputFiles Base  Base Base Test       
rem     Call CreateOutputFiles OGRef Base  Base  Test
rem     Call CreateOutputFiles Calib2 Calib2 Calib2 ExcelDTAs
rem     Call CreateOutputFiles Calib3 Calib3 Calib3 ExcelDTAs
rem     Call CreateOutputFiles Calib4 Calib4 Calib4 ExcelDTAs     
    
rem     Call CreateOutputFiles CalibInd CalibInd CalibInd ExcelDTAs
rem     Call CreateOutputFiles CalibTrans CalibTrans CalibTrans ExcelDTAs
rem     Call CreateOutputFiles CalibCom CalibCom CalibCom ExcelDTAs
rem     Call CreateOutputFiles CalibRes CalibRes CalibRes ExcelDTAs
rem     Call CreateOutputFiles CalibPrice CalibPrice CalibPrice ExcelDTAs
rem     Call CreateOutputFiles StartBase StartBase Base ExcelDTAs   
rem     Call CreateOutputFiles Base Base Base ExcelDTAs      

     Echo %Date% ;%Time%; End Create Outputs %computername% >> CreateOutputs_Report.log
rem
rem  Pause till the user hits a key to exit
rem
     Pause
