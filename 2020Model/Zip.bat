

  if %1==Results (
    rem wzzip -es %2 %3 %4 %5 %6 %7 %8 %9
    7z a -tzip -mx3 %2 %3 %4 %5 %6 %7 %8 %9
    GoTo :End
    )
  if %1==ResultsRecursive (
    rem wzzip -es -P -r %2 %3 %4 %5 %6 %7 %8 %9
    7z a -tzip -r -mx3 %2 %3 %4 %5 %6 %7 %8 %9 
    GoTo :End
    )
  if %1==ModelFiles (
  
     rem wzzip -es -P -r -x*.zip -x*.dta -x*.hdf5 ModelFiles *.*
     rem wzzip -es -P -r  ModelFiles -a 2020TOM\TOMForecast\Baseline\*.zip
     rem wzzip -es -P -r  ModelFiles -a 2020TOM\TOMForecast\Baseline_Ref25A\*.zip
     rem wzzip -es -P -r  ModelFiles -a 2020TOM\sectors
     rem wzzip -es -P -r  ModelFiles -a 2020TOM\RECNUM
     
     rem wzzip -es -P -r  StartBase_Results -a 2020Model\StartBase\*.zip
     rem wzzip -es -P -r  OGRef_Results -a 2020Model\OGRef\*.zip
     rem wzzip -es -P -r  Base_Results -a 2020Model\Base\*.zip
     rem wzzip -es -P -r  Ref25_Results -a 2020Model\Ref25\*.zip
     
     rem wzzip -es -P -r  Ref25A_Results -a 2020Model\Ref25A\*ExcelDTAs.zip
     rem wzzip -es -P -r  Ref25A_Results -a 2020Model\Ref25A\*AccessDTAs.zip
     rem wzzip -es -P -r  Ref25A_Results -a 2020Model\Ref25A\*AccessDBs.zip
     
     rem wzzip -es -P -r  Ref25_TOM_Results -a 2020Model\Ref25_TOM\*ExcelDTAs.zip
     rem wzzip -es -P -r  Ref25_TOM_Results -a 2020Model\Ref25_TOM\*AccessDTAs.zip
     rem wzzip -es -P -r  Ref25_TOM_Results -a 2020Model\Ref25_TOM\*AccessDBs.zip
     rem wzzip -es -P -r  Ref25_TOM_Results -a 2020Model\Ref25_TOM\*TOMFiles.zip
     
     7z a -tzip -r -mx3 ModelFiles.zip *.* -x!*.zip -x!*.dta -x!*.hdf5 
     7z a -tzip -r -mx3 ModelFiles.zip 2020TOM\TOMForecast\Baseline\*.zip 
     7z a -tzip -r -mx3 ModelFiles.zip 2020TOM\TOMForecast\Baseline_Ref25A\*.zip 
     7z a -tzip -r -mx3 ModelFiles.zip 2020TOM\sectors
     7z a -tzip -r -mx3 ModelFiles.zip 2020TOM\RECNUM

     7z a -tzip -r -mx3 StartBase_Results.zip 2020Model\StartBase\*.zip
     7z a -tzip -r -mx3 OGRef_Results.zip 2020Model\OGRef\*.zip
     7z a -tzip -r -mx3 Base_Results.zip 2020Model\Base\*.zip
     7z a -tzip -r -mx3 Ref25_Results.zip 2020Model\Ref25\*.zip
     
     7z a -tzip -r -mx3 Ref25A_Results.zip 2020Model\Ref25A\*ExcelDTAs.zip
     7z a -tzip -r -mx3 Ref25A_Results.zip 2020Model\Ref25A\*AccessDTAs.zip
     7z a -tzip -r -mx3 Ref25A_Results.zip 2020Model\Ref25A\*AccessDBs.zip
     
     7z a -tzip -r -mx3 Ref25_TOM_Results.zip 2020Model\Ref25_TOM\*ExcelDTAs.zip
     7z a -tzip -r -mx3 Ref25_TOM_Results.zip 2020Model\Ref25_TOM\*AccessDTAs.zip
     7z a -tzip -r -mx3 Ref25_TOM_Results.zip 2020Model\Ref25_TOM\*AccessDBs.zip
     7z a -tzip -r -mx3 Ref25_TOM_Results.zip 2020Model\Ref25_TOM\*TOMFiles.zip
     
    GoTo :End
    )
    
  echo "Invalid Option"
  pause
  :End
