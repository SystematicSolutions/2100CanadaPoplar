rem
rem  CleanupTOMFiles.bat
rem
       del ..\2020TOM\*.txtt
       del ..\2020TOM\*.txoo
       
       Ren KOutput.csv KOutput.ccc
       del *.csv
       Ren KOutput.ccc KOutput.csv

