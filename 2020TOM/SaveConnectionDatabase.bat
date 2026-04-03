rem
echo SaveConnectionDatabase.bat %1 >> %Root%\%LogFileName%
rem
rem  %1 - Scenario Name plus Iteration
rem
     Copy ScenarioInfo.tmp %1     
     Call Zip Results %1\dba *.dba  ScenarioInfo.tmp
rem    
     Move TOM_Outputs_%1.csv   %1 
     Move E2020_Outputs_%1.csv %1 
     Call Zip Results %1\%1_TOM_csv %1\*.csv
rem
     Call ZipMove %1\%1_TOMDatabase TOMDatabase_%1.db TOMDatabase_%1.out   
     Call ZipMove %1\%1_TOMDatabase TOMDatabase_%1a.db     
rem
