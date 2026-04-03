rem
rem  UnZip.bat
rem
rem %1-%7 optional WinZip parameters
rem

  if %1==DB (
    rem    wzunzip -o %2\database.zip
    7z e %2\database.zip -y
    GoTo :End
    )
  if %1==RefDB (
    rem wzunzip -n %2\database.zip %2\ database.hdf5
    7z e %2\database.zip -o%2\ -y
    GoTo :End
    )
  if %1==ModelFiles (
    rem wzunzip -d -o ModelFiles.zip     
    rem wzunzip -d -o Ref25_Results.zip
    rem wzunzip -d -o Ref25A_Results.zip
    rem wzunzip -d -o Ref25_170_TOM_Results.zip
    rem wzunzip -d -o StartBase_Results.zip
    rem wzunzip -d -o OGRef_Results.zip
    rem wzunzip -d -o Base_Results.zip
    7z x ModelFiles.zip -y     
    7z x Ref25_Results.zip -y  
    7z x Ref25A_Results.zip -y  
    7z x Ref25_TOM_Results.zip -y  
    7z x StartBase_Results.zip -y  
    7z x OGRef_Results.zip -y  
    7z x Base_Results.zip -y  
    GoTo :End
    )
  if %1==TOM (
    rem wzunzip -o %2\%2_TOMFiles.zip %3 %4 %5 %6 %7 %8
    7z e %2\%2_TOMFiles.zip %3 -y
    7z e %2\%2_TOMFiles.zip %4 -y
    GoTo :End
    )
  if %1==Access (
    7z e %2\%2_AccessDTAs.zip -y
    GoTo :End
    )
  
  echo "Invalid Option"
  pause
  :End

    
  



