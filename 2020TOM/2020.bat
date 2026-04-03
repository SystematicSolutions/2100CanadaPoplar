rem
rem  2020.bat
rem
     copy Name.txt ..\Interface
     cd ..\Interface
     If Not Exist 2020.xeq GoTo End
       prm/w run 2020.xeq
     :End
