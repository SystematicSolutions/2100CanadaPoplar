     Echo   %date% ;%time%; Start Time >> LogTOMSpeed.log
rem  Unzip starting database either manually or here
rem
rem  Call Unzip \Ref25\database.zip   <-- this is not correct. do manually until fix.
rem  6/6/25 R.Levesque
rem
    cd ..\EconomicTransfers
       Call E2020_to_TOM
rem       Call RunJulia E2020GrossOutputTransform.jl
       pause
    cd ..\2020Model
