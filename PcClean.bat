rem
rem PcClean.bat
rem %1 File extension to delete (*.dba)
rem
del FilesToDelete.txt
dir /b /s "%CD%\%1" > FilesToDelete.txt
rem
for /F "usebackq tokens=*" %%A in ("FilesToDelete.txt") do (
  echo %%~nxA
  if %%~nxA==informet.dba (
    echo Informet Found
  ) else (
    call del "%%A" 
  )  
)
del FilesToDelete.txt