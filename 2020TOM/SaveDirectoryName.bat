rem
rem SaveDirectoryName.bat
rem

:: retrieving  name of current directory
cd ..
for %%* in (.) do set MyDir=%%~n*
:: adding safety factor for no directory, i.e a drive
if not defined MyDir set MyDir=%CD:\=%
:: telling you what it is
cd\%MyDir%\2020TOM
echo %MyDir% >ModelName.tmp