#
# Trans_USForecast.jl - Forecast Efficiencies from AEO
#
#########################
#
using EnergyModel

module Trans_USForecast

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DAct::VariableArray{5} = ReadDisk(db,"$Input/DAct") # [Enduse,Tech,EC,Area,Year] Device Activity Level (Ton-Miles/Vehicle-Mile)
  DPConv::VariableArray{5} = ReadDisk(db,"$Input/DPConv") # [Enduse,Tech,EC,Area,Year] Device Process Conversion (Vehicle Mile/Passenger Mile)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 
  xXDEE::VariableArray{5} = ReadDisk(db,"$Input/xXDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Miles/mmBtu)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  ForecastInput::VariableArray{3} = zeros(Float32,length(EC),length(Tech),length(Year)) # [EC,Tech,Year]
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,Years,EC,ECs,Enduses,Nation,Tech,Techs) = data
  (;ANMap,DAct,DPConv,xDEE,xXDEE) = data
  (;ForecastInput) = data

for year in Years, tech in Techs, ec in ECs
  ForecastInput[ec,tech,year] = -99
end

  #*
  #* Freight trucks
  #*
  years = collect(Yr(2009):Yr(2050))
  ec = Select(EC,"Freight")
  techs = Select(Tech,["HDV45Diesel","HDV45Gasoline","HDV45Electric","HDV45NaturalGas",
                       "HDV45Propane","HDV67Diesel","HDV67Gasoline","HDV67Electric",
                       "HDV67NaturalGas","HDV67Propane","HDV67FuelCell","HDV8Diesel",
                       "HDV8Gasoline","HDV8Electric","HDV8NaturalGas","HDV8Propane","HDV8FuelCell"])
  ForecastInput[ec,techs,years] .= [
  #/                    2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
  #=HDV3Diesel    =# 13.8595 13.8595 13.8595 13.8595 13.8595 13.8595 13.8595 13.8595 13.8595 14.0616 14.2626 14.4508 14.6433 14.8373 15.0416 15.2629 15.5075 15.7746 16.0582 16.3324 16.5946 16.8418 17.0641 17.2679 17.4584 17.6270 17.7696 17.9048 18.0315 18.1535 18.2724 18.3801 18.4905 18.5887 18.6750 18.7600 18.8443 18.9169 18.9773 19.0377 19.0889 19.1332
  #=HDV3Gasoline  =#  9.6014  9.6014  9.6014  9.6014  9.6014  9.6014  9.6014  9.6014  9.6014  9.7177  9.8371  9.9567 10.0906 10.2315 10.3832 10.5485 10.7285 10.9229 11.1342 11.3505 11.5694 11.7940 12.0122 12.2285 12.4274 12.6191 12.7937 12.9521 13.1005 13.2356 13.3671 13.4803 13.5982 13.7022 13.7967 13.8899 13.9834 14.0731 14.1595 14.2496 14.3372 14.4218
  #=HDV3Electric  =# 24.1229 24.1229 24.1229 24.1229 24.1229 24.1229 24.1229 24.1229 24.1229 26.6524 26.7677 26.8189 26.8943 26.9798 27.0761 27.1936 27.3372 27.5079 27.7002 27.8795 28.0575 28.2321 28.3974 28.5467 28.6775 28.7898 28.8843 28.9626 29.0294 29.0867 29.1362 29.1791 29.2200 29.2602 29.2955 29.3278 29.3566 29.3816 29.4026 29.4190 29.4309 29.4449
  #=HDV3NaturalGas=#  9.9828  9.9828  9.9828  9.9828  9.9828  9.9828  9.9828  9.9828  9.9828 12.8325 12.4340 12.3024 12.2828 12.2972 12.3320 12.3906 12.4778 12.5924 12.7309 12.8577 12.9872 13.1172 13.2442 13.3579 13.4542 13.5349 13.6012 13.6550 13.6985 13.7333 13.7616 13.7854 13.8052 13.8211 13.8333 13.8413 13.8469 13.8504 13.8520 13.8523 13.8520 13.8487
  #=HDV3Propane   =#  8.2869  8.2869  8.2869  8.2869  8.2869  8.2869  8.2869  8.2869  8.2869 10.9876 11.5423 11.7765 11.9555 12.0991 12.2227 12.3455 12.4791 12.6308 12.8023 12.9569 13.1079 13.2562 13.3975 13.5099 13.6243 13.7314 13.7889 13.8373 13.8810 13.9219 13.9653 14.0116 14.0619 14.1164 14.1744 14.2345 14.2946 14.3518 14.4047 14.4519 14.4927 14.5159
  #/HDV3FuelCell  =# 0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000
  #=HDV6Diesel    =#  8.6861  8.6861  8.6861  8.6861  8.6861  8.6861  8.6861  8.6861  8.6861  8.7869  8.8896  8.9813  9.0932  9.2232  9.3645  9.5178  9.6868  9.8718 10.0718 10.2738 10.4844 10.7113 10.9396 11.1718 11.3947 11.6005 11.7795 11.9381 12.0810 12.2121 12.3332 12.4477 12.5567 12.6405 12.7047 12.7592 12.8151 12.8587 12.8936 12.9268 12.9577 12.9839
  #=HDV6Gasoline  =#  6.4736  6.4736  6.4736  6.4736  6.4736  6.4736  6.4736  6.4736  6.4736  6.5150  6.5592  6.6011  6.6550  6.7189  6.7895  6.8668  6.9558  7.0533  7.1620  7.2740  7.3887  7.5213  7.6483  7.7863  7.9227  8.0406  8.1532  8.2533  8.3518  8.4312  8.5205  8.5970  8.6710  8.7305  8.7762  8.8235  8.8695  8.9113  8.9502  8.9817  9.0222  9.0533
  #=HDV6Electric  =# 16.8710 16.8710 16.8710 16.8710 16.8710 16.8710 16.8710 16.8710 16.8710 16.8710 16.9323 16.9699 17.1192 17.2689 17.4257 17.6063 17.8205 18.0715 18.3518 18.6161 18.9066 19.2143 19.5296 19.8371 20.1215 20.3775 20.6015 20.7934 20.9714 21.1280 21.2641 21.3807 21.4828 21.5719 21.6495 21.7172 21.7763 21.8278 21.8739 21.9140 21.9497 22.0325
  #=HDV6NaturalGas=#  6.2829  6.2829  6.2829  6.2829  6.2829  6.2829  6.2829  6.2829  6.2829  6.4828  6.6099  6.7006  6.8039  6.9099  7.0173  7.1307  7.2556  7.3922  7.5385  7.6809  7.8307  7.9905  8.1557  8.3165  8.4699  8.6099  8.7412  8.8558  8.9591  9.0440  9.1097  9.1786  9.2183  9.2690  9.3212  9.3563  9.3815  9.4084  9.4365  9.4620  9.4825  9.4908
  #=HDV6Propane   =#  6.6389  6.6389  6.6389  6.6389  6.6389  6.6389  6.6389  6.6389  6.6389  6.7218  6.7761  6.8236  6.8872  6.9621  7.0455  7.1394  7.2459  7.3668  7.4965  7.6391  7.7858  7.9476  8.1177  8.2658  8.4151  8.5584  8.6788  8.7845  8.8761  8.9547  9.0217  9.0784  9.1264  9.1673  9.2025  9.2330  9.2596  9.2831  9.2651  9.3286  9.3523  9.3675
  #=HDV6FuelCell  =# 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5204 11.5473
  #=HDV8Diesel    =#  6.1509  6.1509  6.1509  6.1509  6.1509  6.1509  6.1509  6.1509  6.1509  6.2388  6.3280  6.4096  6.4868  6.5700  6.6559  6.7466  6.8458  6.9564  7.0782  7.2028  7.3315  7.4612  7.5896  7.7118  7.8269  7.9294  8.0164  8.0934  8.1590  8.2195  8.2707  8.3263  8.3661  8.4020  8.4302  8.4522  8.4743  8.4945  8.5103  8.5253  8.5431  8.5569
  #=HDV8Gasoline  =#  5.3368  5.3368  5.3368  5.3368  5.3368  5.3368  5.3368  5.3368  5.3368  5.3561  5.3827  5.4138  5.4521  5.4964  5.5519  5.6221  5.6990  5.7799  5.8622  5.9622  6.0540  6.1643  6.2792  6.3944  6.5164  6.6119  6.7353  6.8292  6.9049  6.9776  7.0686  7.1197  7.1962  7.2851  7.3319  7.3675  7.3970  7.4254  7.4399  7.4601  7.4630  7.4892
  #=HDV8Electric  =#  7.9115  7.9115  7.9115  7.9115  7.9115  7.9115  7.9115  7.9115  7.9115  7.9115  9.6103 10.2754 10.6813 10.9884 11.2269 11.4317 11.6246 11.8157 12.0093 12.1916 12.3796 12.5737 12.7714 12.9658 13.1488 13.3185 13.4691 13.5968 13.7248 13.8478 13.9505 14.0217 14.0888 14.1457 14.1938 14.2336 14.2668 14.2943 14.3176 14.3377 14.3552 14.4094
  #=HDV8NaturalGas=#  5.8910  5.8910  5.8910  5.8910  5.8910  5.8910  5.8910  5.8910  5.8910  5.9870  6.0744  6.1476  6.2226  6.3043  6.3903  6.4831  6.5866  6.7036  6.8347  6.9685  7.1109  7.2593  7.4100  7.5561  7.6895  7.8080  7.9099  7.9940  8.0651  8.1238  8.1714  8.2102  8.2416  8.2690  8.2904  8.3071  8.3230  8.3339  8.3448  8.3524  8.3585  8.3604
  #=HDV8Propane   =#  5.5682  5.5682  5.5682  5.5682  5.5682  5.5682  5.5682  5.5682  5.5682  5.7343  5.8515  5.9401  6.0300  6.1214  6.2116  6.3052  6.3996  6.4982  6.5981  6.7076  6.8143  6.9235  7.0528  7.1647  7.2637  7.3454  7.4099  7.4622  7.5042  7.5364  7.5607  7.5787  7.5912  7.5995  7.6046  7.6072  7.6080  7.6067  7.5978  7.5943  7.5990  7.5977
  #=HDV8FuelCell  =#  7.8920  7.8920  7.8920  7.8920  7.8920  7.8920  7.8920  7.8920  7.8920  7.8920  7.9806  8.0074  8.0203  8.0289  8.0347  8.0388  8.0421  8.0448  8.0472  8.0493  8.0511  8.0527  8.0542  8.0554  8.0564  8.0572  8.0578  8.0581  8.0586  8.0592  8.0595  8.0594  8.0595  8.0597  8.0598  8.0599  8.0600  8.0600  8.0601  8.0602  8.0602  8.0822
  ]
  
  #*
  #* Map efficiencies into similar sized techs per AEO assumptions documentation:
  #*
  HDV2B3Gasoline = Select(Tech,"HDV2B3Gasoline")
  HDV2B3Diesel = Select(Tech,"HDV2B3Diesel")
  HDV2B3Electric = Select(Tech,"HDV2B3Electric")
  HDV2B3NaturalGas = Select(Tech,"HDV2B3NaturalGas")
  HDV2B3Propane = Select(Tech,"HDV2B3Propane")
  HDV2B3FuelCell = Select(Tech,"HDV2B3FuelCell")
  HDV45FuelCell = Select(Tech,"HDV45FuelCell")
  HDV45Gasoline = Select(Tech,"HDV45Gasoline")
  HDV45Diesel = Select(Tech,"HDV45Diesel")
  HDV45Electric = Select(Tech,"HDV45Electric")
  HDV45NaturalGas = Select(Tech,"HDV45NaturalGas")
  HDV45Propane = Select(Tech,"HDV45Propane")
  HDV67FuelCell = Select(Tech,"HDV67FuelCell")
  
  years = collect(Yr(1985):Yr(2050))
  for year in years, ec in ECs
    ForecastInput[ec,HDV2B3Gasoline,year] = ForecastInput[ec,HDV45Gasoline,year]
  end  
  for year in years, ec in ECs  
    ForecastInput[ec,HDV2B3Diesel,year] = ForecastInput[ec,HDV45Diesel,year]
  end  
  for year in years, ec in ECs  
    ForecastInput[ec,HDV2B3Electric,year] = ForecastInput[ec,HDV45Electric,year]
  end  
  for year in years, ec in ECs  
    ForecastInput[ec,HDV2B3NaturalGas,year] = ForecastInput[ec,HDV45NaturalGas,year]
  end  
  for year in years, ec in ECs  
    ForecastInput[ec,HDV2B3Propane,year] = ForecastInput[ec,HDV45Propane,year]
  end  
  for year in years, ec in ECs  
    ForecastInput[ec,HDV2B3FuelCell,year] = ForecastInput[ec,HDV67FuelCell,year]
  end  
  for year in years, ec in ECs  
    ForecastInput[ec,HDV45FuelCell,year] = ForecastInput[ec,HDV67FuelCell,year]
  end  

  #*
  #* Convert to ton miles per mmbtu using the appropriate fuel heat rate and activity rate
  #* Use NEng DAct
  #*
  NEng = Select(Area,"NEng")
  techs = Select(Tech,["HDV2B3Gasoline","HDV45Gasoline","HDV67Gasoline","HDV8Gasoline",
                       "HDV2B3NaturalGas","HDV45NaturalGas","HDV67NaturalGas",
                       "HDV67Electric","HDV67FuelCell","HDV2B3Propane","HDV45Propane",
                       "HDV67Propane","HDV8Propane"])
  for enduse in Enduses, tech in techs, year in years
    ForecastInput[ec,tech,year] = ForecastInput[ec,tech,year] / 125000 * 1e6 *
                                  DAct[enduse,tech,ec,NEng,year]
  end

  techs = Select(Tech,["HDV2B3Diesel","HDV45Diesel","HDV67Diesel","HDV8Diesel",
                       "HDV8NaturalGas","HDV2B3Electric","HDV45Electric",
                       "HDV8Electric","HDV2B3FuelCell","HDV45FuelCell","HDV8FuelCell"])
  for enduse in Enduses, tech in techs, year in years
    ForecastInput[ec,tech,year] = ForecastInput[ec,tech,year] / 139000 * 1e6 *
                                  DAct[enduse,tech,ec,NEng,year]
  end
  
  #*
  #* Freight Train and Marine are in ton-miles per mmbtu - Explicitly select Freight sectors since passenger vehicles are different
  #*
  years = collect(Yr(2009):Yr(2050))
  techs = Select(Tech,["TrainDiesel","TrainFuelCell","MarineLight","MarineHeavy",
                       "MarineFuelCell"])
  ForecastInput[ec,techs,years] .= [
  #/                     2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
  #=TrainDiesel   =#  3436.43 3439.87 3436.36 3432.86 3429.35 3425.85 3422.35 3422.35 3422.35 3444.54 3466.88 3489.37 3512.00 3534.78 3557.71 3580.79 3604.01 3627.39 3650.91 3674.59 3698.43 3722.42 3746.56 3770.86 3795.32 3819.94 3844.71 3869.65 3894.75 3920.01 3945.44 3971.03 3996.78 4022.71 4048.80 4075.06 4101.49 4128.09 4154.87 4181.82 4208.94 4236.24
  #=TrainFuelCell =#  3436.43 3439.87 3436.36 3432.86 3429.35 3425.85 3422.35 3422.35 3422.35 3444.54 3466.88 3489.37 3512.00 3534.78 3557.71 3580.79 3604.01 3627.39 3650.91 3674.59 3698.43 3722.42 3746.56 3770.86 3795.32 3819.94 3844.71 3869.65 3894.75 3920.01 3945.44 3971.03 3996.78 4022.71 4048.80 4075.06 4101.49 4128.09 4154.87 4181.82 4208.94 4236.24
  #=MarineLight   =#  2397.14 2401.94 2872.89 3343.84 3814.78 4285.73 4756.68 4756.68 4756.68 4784.94 4813.37 4841.96 4870.73 4899.66 4928.77 4958.05 4987.51 5017.14 5046.95 5076.93 5107.09 5137.43 5167.96 5198.66 5229.54 5260.61 5291.86 5323.30 5354.93 5386.74 5418.75 5450.94 5483.32 5515.90 5548.67 5581.63 5614.79 5648.15 5681.71 5715.46 5749.42 5783.57
  #=MarineHeavy   =#  2397.14 2401.94 2872.89 3343.84 3814.78 4285.73 4756.68 4756.68 4756.68 4784.94 4813.37 4841.96 4870.73 4899.66 4928.77 4958.05 4987.51 5017.14 5046.95 5076.93 5107.09 5137.43 5167.96 5198.66 5229.54 5260.61 5291.86 5323.30 5354.93 5386.74 5418.75 5450.94 5483.32 5515.90 5548.67 5581.63 5614.79 5648.15 5681.71 5715.46 5749.42 5783.57     
  #=MarineFuelCell=#  2397.14 2401.94 2872.89 3343.84 3814.78 4285.73 4756.68 4756.68 4756.68 4784.94 4813.37 4841.96 4870.73 4899.66 4928.77 4958.05 4987.51 5017.14 5046.95 5076.93 5107.09 5137.43 5167.96 5198.66 5229.54 5260.61 5291.86 5323.30 5354.93 5386.74 5418.75 5450.94 5483.32 5515.90 5548.67 5581.63 5614.79 5648.15 5681.71 5715.46 5749.42 5783.57     
  ]

  #*
  #* Plane efficiencies are in Seat Miles per gallon
  #*
  years = collect(Yr(2009):Yr(2050))
  ec = Select(EC,"Passenger")
  techs = Select(Tech,["PlaneJetFuel","PlaneGasoline","PlaneFuelCell"])
  ForecastInput[ec,techs,years] .= [
  #/                     2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
  #=PlaneJetFuel =#   68.4026 68.4026 68.4026 68.4026 68.4026 68.4026 68.4026 68.4026 72.6728 73.6355 73.8426 73.9235 74.6334 75.3386 76.0478 76.7568 76.8314 77.9926 79.1548 80.3182 81.4843 81.5573 82.0004 82.4477 82.8876 83.3429 83.4466 83.9955 84.5478 85.1275 85.7419 86.3598 86.5575 86.7891 87.0173 87.2304 87.4861 87.7214 87.9841 88.2966 88.5876 88.9070
  #=PlaneGasoline=#   68.4026 68.4026 68.4026 68.4026 68.4026 68.4026 68.4026 68.4026 72.6728 73.6355 73.8426 73.9235 74.6334 75.3386 76.0478 76.7568 76.8314 77.9926 79.1548 80.3182 81.4843 81.5573 82.0004 82.4477 82.8876 83.3429 83.4466 83.9955 84.5478 85.1275 85.7419 86.3598 86.5575 86.7891 87.0173 87.2304 87.4861 87.7214 87.9841 88.2966 88.5876 88.9070
  #=PlaneFuelCell=#   68.4026 68.4026 68.4026 68.4026 68.4026 68.4026 68.4026 68.4026 72.6728 73.6355 73.8426 73.9235 74.6334 75.3386 76.0478 76.7568 76.8314 77.9926 79.1548 80.3182 81.4843 81.5573 82.0004 82.4477 82.8876 83.3429 83.4466 83.9955 84.5478 85.1275 85.7419 86.3598 86.5575 86.7891 87.0173 87.2304 87.4861 87.7214 87.9841 88.2966 88.5876 88.9070
  ]
  
  #*
  #* Convert to Vehicles Miles per mmbtu using passenger activity rate
  #* Use NEng activity rate
  #*
  for enduse in Enduses, tech in techs, year in years
    ForecastInput[ec,tech,year] = ForecastInput[ec,tech,year] / 125000 * 1e6 * 
                                  DPConv[enduse,tech,ec,NEng,year]
  end
  
  #*
  #* The 2016 AEO forecast efficiencies includes the projected impacts of CAFE
  #* fleet efficiency standards on marginal efficiency in the forecast years.
  #* Read this in as the default efficiency standard in the forecast - Ian 09/30/16
  #*
  #* Values from "Transportation Sales and Efficiency AEO 2019.xlsx"
  #* 
  years = collect(Yr(2017):Yr(2050))
  techs = Select(Tech,(from = "LDVGasoline", to = "LDTFuelCell"))
  ForecastInput[ec,techs,years] .= [
  #/                    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
  #=LDVGasoline   =#  36.526  37.060  37.654  39.047  40.534  42.507  44.618  46.084  48.433  48.575  48.682  48.719  48.790  48.810  48.810  48.792  48.755  48.709  48.653  48.600  48.530  48.466  48.405  48.341  48.392  48.320  48.235  48.147  48.062  47.978  47.892  47.813  47.729  47.647
  #=LDVDiesel     =#  45.591  45.995  46.462  47.483  48.646  50.057  51.380  52.391  54.248  54.186  54.165  54.101  54.087  54.052  54.013  53.959  53.891  53.806  53.704  53.602  53.490  53.383  53.281  53.180  53.075  52.970  52.856  52.740  52.624  52.493  52.358  52.228  52.094  51.964
  #=LDVElectric   =# 101.607 102.656 104.419 109.429 111.356 113.771 116.722 118.808 120.959 121.001 120.980 120.997 121.000 120.965 120.969 120.997 121.008 121.041 121.077 121.112 121.152 121.191 121.230 121.272 121.290 121.301 121.307 121.312 121.319 121.325 121.330 121.336 121.340 121.344
  #=LDVNaturalGas =#  39.087  37.767  38.334  39.746  41.221  43.454  45.600  46.988  49.426  49.452  49.492  49.463  49.479  49.469  49.446  49.397  49.329  49.247  49.162  49.078  48.979  48.884  48.796  48.711  48.623  48.543  48.440  48.310  48.178  48.049  47.919  47.794  47.667  47.544
  #=LDVPropane    =#  37.237  37.565  38.098  39.549  41.068  43.229  45.509  46.848  49.272  49.296  49.337  49.307  49.328  49.312  49.295  49.243  49.179  49.105  49.022  48.944  48.849  48.755  48.668  48.584  48.497  48.417  48.328  48.240  48.153  48.068  47.983  47.904  47.822  47.743
  #=LDVEthanol    =#  36.084  36.445  36.983  38.314  39.741  41.641  43.679  45.079  47.305  47.390  47.440  47.427  47.442  47.420  47.393  47.349  47.291  47.223  47.149  47.081  47.001  46.927  46.858  46.791  46.716  46.643  46.564  46.482  46.399  46.318  46.236  46.159  46.079  46.003
  #=LDVHybrid     =#  63.576  65.463  65.608  65.079  66.390  68.397  70.432  72.222  74.872  75.974  76.046  76.013  76.298  76.333  76.405  76.462  76.501  76.540  76.566  76.588  76.548  76.597  76.595  76.585  76.542  76.507  76.424  76.354  76.299  76.238  76.162  76.108  76.033  75.960
  #=LDVFuelCell   =#  52.224  52.292  52.546  54.979  56.065  57.493  59.091  60.267  61.496  61.509  61.500  61.489  61.478  61.466  61.454  61.440  61.426  61.424  61.423  61.423  61.423  61.423  61.423  61.423  61.424  61.424  61.424  61.424  61.424  61.424  61.424  61.424  61.425  61.425
  #=LDTGasoline   =#  27.843  28.151  28.758  29.950  32.014  34.113  35.936  37.662  40.132  40.158  40.178  40.145  40.112  40.051  40.002  40.009  40.169  40.103  40.017  39.934  39.848  39.820  39.757  39.677  39.771  39.704  39.599  39.492  39.515  39.437  39.355  39.273  39.182  39.095
  #=LDTDiesel     =#  33.203  34.755  35.113  35.826  37.067  38.345  39.565  40.745  42.745  42.704  42.704  42.670  42.628  42.523  42.418  42.362  42.404  42.307  42.192  42.078  41.962  41.872  41.746  41.599  41.590  41.459  41.304  41.144  41.102  40.961  40.812  40.660  40.504  40.356
  #=LDTElectric   =#  87.313  87.313  87.313  89.605  92.427  94.985  97.043  99.153  102.352 102.341 102.323 102.296 102.266 102.231 102.179 102.139 102.110 102.043 101.969 101.887 101.791 101.689 101.578 101.458 101.358 101.236 101.114 100.989 100.936 100.801 100.672 100.540 100.411 100.289
  #=LDTNaturalGas =#  27.581  26.736  27.239  28.280  30.112  32.179  34.200  36.042  37.903  37.911  37.949  37.921  37.875  37.815  37.768  37.794  38.149  38.139  38.100  38.064  38.020  38.094  38.073  38.020  38.245  38.216  38.152  38.086  38.128  38.072  38.012  37.951  37.884  37.819
  #=LDTPropane    =#  26.519  26.790  27.290  28.337  30.170  32.243  34.273  36.127  38.035  38.039  38.080  38.052  38.016  37.957  37.912  37.950  38.283  38.273  38.234  38.198  38.158  38.230  38.224  38.191  38.423  38.403  38.341  38.277  38.301  38.245  38.183  38.126  38.064  38.005
  #=LDTEthanol    =#  28.028  28.339  28.948  30.131  32.207  34.311  36.126  37.839  40.360  40.371  40.379  40.332  40.283  40.205  40.138  40.130  40.275  40.209  40.104  40.002  39.896  39.848  39.765  39.665  39.740  39.657  39.543  39.417  39.423  39.302  39.196  39.091  38.973  38.853
  #=LDTHybrid     =#  50.585  51.587  51.685  50.874  53.542  56.036  57.811  59.021  63.960  64.986  64.966  64.829  64.804  64.720  64.660  64.599  64.623  64.651  64.435  64.279  64.099  63.919  63.812  63.646  63.476  63.441  63.255  63.056  62.896  62.900  62.764  62.627  62.453  62.279
  #=LDTFuelCell   =#  49.517  49.552  49.625  50.352  51.674  52.931  54.051  55.217  53.490  53.484  53.474  53.463  53.453  53.443  53.433  53.441  53.453  53.451  53.451  53.451  53.451  53.453  53.453  53.453  53.462  53.462  53.462  53.462  53.478  53.478  53.478  53.478  53.478  53.478    
  ]

  years = collect(Yr(2017):Final)

  #*
  #* Convert to miles per mmbtu using gasoline heat rate
  #*
  for tech in techs, year in years
    ForecastInput[ec,tech,year] = ForecastInput[ec,tech,year] / 125000 * 1e6
  end

  #*
  #* Set offroad and motorcycle equal to LDVGasoline for now
  #*
  techs = Select(Tech,["OffRoad","Motorcycle"])
  LDVGasoline = Select(Tech,"LDVGasoline")
  for tech in techs 
    ForecastInput[ec,tech,:] .= ForecastInput[ec,LDVGasoline,:]
  end

  #*
  #* Assign forecast values across similar ECs
  #*
  Passenger = Select(EC,"Passenger")
  Freight = Select(EC,"Freight")
  ecs = Select(EC,["AirPassenger","ForeignPassenger"])
  for year in Years, tech in Techs, ec in ecs 
    ForecastInput[ec,tech,year] = ForecastInput[Passenger,tech,year]
  end
  ecs = Select(EC,["AirFreight","ForeignFreight","ResidentialOffRoad",
                   "CommercialOffRoad"])
  for year in Years, tech in Techs, ec in ecs 
    ForecastInput[ec,tech,year] = ForecastInput[Freight,tech,year]
  end
  
  #*
  #* Select US Areas and scale input to match historical xDEE
  #* 2016 is the last year with historical values for all Techs. Apply 
  #* this value through Last where needed
  #*
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)
  years = collect(Yr(2017):Last)
  for enduse in Enduses, ec in ECs, tech in Techs, area in areas, year in years
    if xXDEE[enduse,tech,ec,area,year] == -99
      xXDEE[enduse,tech,ec,area,year] = xXDEE[enduse,tech,ec,area,Yr(2016)]
      xDEE[enduse,tech,ec,area,year] = xDEE[enduse,tech,ec,area,Yr(2016)]
    end
  end

  #
  # Apply forecast trend to efficiency forecast
  #
  years = collect(Future:Final)
  for ec in ECs, tech in Techs, year in years
    if ForecastInput[ec,tech,year] > 0
      for enduse in Enduses, area in areas
        xXDEE[enduse,tech,ec,area,year] = xXDEE[enduse,tech,ec,area,Last] * 
                                          ForecastInput[ec,tech,year] / ForecastInput[ec,tech,Future]
        xDEE[enduse,tech,ec,area,year] = xDEE[enduse,tech,ec,area,Last] * 
                                         ForecastInput[ec,tech,year] / ForecastInput[ec,tech,Future]
      end
    end
  end

  #
  # MX same as CA
  #
  CA = Select(Area,"CA")
  area = Select(Area,"MX")
  for year in Years, ec in ECs, tech in Techs, enduse in Enduses
    xXDEE[enduse,tech,ec,area,year] = xXDEE[enduse,tech,ec,CA,year]
  end
  CA = Select(Area,"CA")
  area = Select(Area,"MX")
  for year in Years, ec in ECs, tech in Techs, enduse in Enduses
    xDEE[enduse,tech,ec,area,year] = xDEE[enduse,tech,ec,CA,year]
  end  

  WriteDisk(db,"$Input/xXDEE",xXDEE)
  WriteDisk(db,"$Input/xDEE",xDEE)

 end

function CalibrationControl(db)
  @info "Trans_USForecast.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
