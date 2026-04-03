rem
rem  RunOGCalibrationShort.bat
rem
rem  UnZip required databases
rem
     Call StartScenario             StartBase StartBase StartBase OGRef StartBase StartBase StartBase
     Call RunJulia StartScenario.jl StartBase StartBase StartBase OGRef StartBase StartBase StartBase
rem
     cd..\Calibration
rem     
rem    Transfer Calibration Data To StartBase
rem
       Call RunJulia OG_UnitCalibration.jl
rem
rem    Final Adjustments
rem
       Call RunJulia OG_Endogenous.jl
       Call RunJulia OG_AdjustForecast.jl
       Call RunJulia OG_ROITrap.jl
rem
     cd..\2020Model
rem
rem  Save data in StartBase
rem
     Call Zip Results StartBase\database *.hdf5     