#
# AdjustCAC_Steel_2021.jl
#
# This TXP Models emission reductions to the Iron&Steel sector in Ontario
# These reductions are associated with the Algoma and Arcelor projects 
# Where conversion to DRI-EAF will lead to significant reductions from these 2 plants
# Since the impact of these projects is mostly captured in FsDmd, but no AP emissions are produced from it
# Pro-rating the impact to combustion and process emissions to obtain anticipated levels of emissions. 
# The assumptions were taken from 2022 Projection sent to EAD (Oct 21, 2022)_Iron&STeel.xlsx 
# Received from the Metals and Minerals Processing Division on Oct 21 2022
# Proportional reduction were applied to Ref22 to develop the Pollution Coefficient Reduction Multipliers
# See 2022 Iron&Steel projections_AB_221103.xlsx for detail calculations
# These assumptions should be reviewed yearly 
# By Audrey Bernard 22.10.24
#
#
using EnergyModel

module AdjustCAC_Steel_2021

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)

  # Scratch Variables
  Temp::VariableArray{2} = zeros(Float32,length(Poll),length(Year)) # [Poll,Year] Scratch Variable for Input
end

function IndCalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,EC) = data
  (;Enduses,FuelEPs,Poll,) = data
  (;Year) = data
  (;POCX) = data
  (;Temp) = data

  ON = Select(Area,"ON")
  IronSteel = Select(EC,"IronSteel")
  years = collect(Yr(2023):Yr(2035))

  BC = Select(Poll,"BC")
  Temp[BC,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   0.0842   0.0842   0.0842   0.0842   0.2232   0.2232   0.2684   0.3369   0.3369   0.3369   0.3369   0.3369   0.3369
  ]

  COX = Select(Poll,"COX")
  Temp[COX,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.0047  -0.0047  -0.0047  -0.0047   0.0259   0.0259   0.0218   0.0204   0.0204   0.0204   0.0204   0.0204   0.0204
  ]

  Hg = Select(Poll,"Hg")
  Temp[Hg,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.1154  -0.1154  -0.1154  -0.1154  -0.2233  -0.2233  -0.4087  -0.3130  -0.3130  -0.3130  -0.3130  -0.3130  -0.3130
  ]

  NOX = Select(Poll,"NOX")
  Temp[NOX,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   0.0287   0.0287   0.0287   0.0287   0.1122   0.1122   0.1353   0.1452   0.1452   0.1452   0.1452   0.1452   0.1452
  ]  

  PMT = Select(Poll,"PMT")
  Temp[PMT,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.0026  -0.0026  -0.0026  -0.0026   0.0048   0.0048   0.0022   0.0020   0.0020   0.0020   0.0020   0.0020   0.0020
  ]  

  PM10 = Select(Poll,"PM10")
  Temp[PM10,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.0020  -0.0020  -0.0020  -0.0020   0.0039   0.0039   0.0020   0.0018   0.0018   0.0018   0.0018   0.0018   0.0018
  ]  

  PM25 = Select(Poll,"PM25")
  Temp[PM25,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.0022  -0.0022  -0.0022  -0.0022   0.0040   0.0040   0.0019   0.0018   0.0018   0.0018   0.0018   0.0018   0.0018
  ]  

  VOC = Select(Poll,"VOC")
  Temp[VOC,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   0.0166   0.0166   0.0166   0.0166   0.1051   0.1051   0.1177   0.1251   0.1251   0.1251   0.1251   0.1251   0.1251
  ]  

  polls = Select(Poll,["BC","COX","Hg","NOX","PMT","PM10","PM25","VOC"])
  
  for enduse in Enduses, fuelep in FuelEPs, poll in polls, year in years
    POCX[enduse,fuelep,IronSteel,poll,ON,year] = POCX[enduse,fuelep,IronSteel,poll,ON,year] * (1-Temp[poll,year])
  end

  Yr2035 = Select(Year,"2035")
  years = collect(Yr(2036):Final)
  for enduse in Enduses, fuelep in FuelEPs, poll in polls, year in years
    POCX[enduse,fuelep,IronSteel,poll,ON,year] = POCX[enduse,fuelep,IronSteel,poll,ON,year] * (1-Temp[poll,Yr2035])
  end

  WriteDisk(db, "$Input/POCX", POCX)
end

Base.@kwdef struct MControl
  db::String

  MEInput::String = "MEInput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Economic Driver)

  # Scratch Variables
  Temp::VariableArray{2} = zeros(Float32,length(Poll),length(Year)) # [Poll,Year] Scratch Variable for Input
end

function MacroCalibration(db)
  data = MControl(; db)
  (;MEInput) = data
  (;Area,ECC) = data
  (;Poll) = data
  (;Year) = data
  (;MEPOCX) = data
  (;Temp) = data

  ON = Select(Area,"ON")
  IronSteel = Select(ECC,"IronSteel")
  years = collect(Yr(2023):Yr(2035))

  COX = Select(Poll,"COX")
  Temp[COX,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.0047  -0.0047  -0.0047  -0.0047   0.0259   0.0259   0.0218   0.0204   0.0204   0.0204   0.0204   0.0204   0.0204
  ]

  Hg = Select(Poll,"Hg")
  Temp[Hg,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.1154  -0.1154  -0.1154  -0.1154  -0.2233  -0.2233  -0.4087  -0.3130  -0.3130  -0.3130  -0.3130  -0.3130  -0.3130
  ]

  NOX = Select(Poll,"NOX")
  Temp[NOX,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   0.0287   0.0287   0.0287   0.0287   0.1122   0.1122   0.1353   0.1452   0.1452   0.1452   0.1452   0.1452   0.1452
  ]  

  PMT = Select(Poll,"PMT")
  Temp[PMT,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.0026  -0.0026  -0.0026  -0.0026   0.0048   0.0048   0.0022   0.0020   0.0020   0.0020   0.0020   0.0020   0.0020
  ]  

  PM10 = Select(Poll,"PM10")
  Temp[PM10,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.0020  -0.0020  -0.0020  -0.0020   0.0039   0.0039   0.0020   0.0018   0.0018   0.0018   0.0018   0.0018   0.0018
  ]  

  PM25 = Select(Poll,"PM25")
  Temp[PM25,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   -0.0022  -0.0022  -0.0022  -0.0022   0.0040   0.0040   0.0019   0.0018   0.0018   0.0018   0.0018   0.0018   0.0018
  ]  

  VOC = Select(Poll,"VOC")
  Temp[VOC,years] = [
   # 2023     2024     2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035  
   0.0166   0.0166   0.0166   0.0166   0.1051   0.1051   0.1177   0.1251   0.1251   0.1251   0.1251   0.1251   0.1251
  ]  

  polls = Select(Poll,["COX","Hg","NOX","PMT","PM10","PM25","VOC"])
  
  for poll in polls, year in years
    MEPOCX[IronSteel,poll,ON,year] = MEPOCX[IronSteel,poll,ON,year] * (1-Temp[poll,year])
  end

  Yr2035 = Select(Year,"2035")
  years = collect(Yr(2036):Final)
  for poll in polls, year in years
    MEPOCX[IronSteel,poll,ON,year] = MEPOCX[IronSteel,poll,ON,year] * (1-Temp[poll,Yr2035])
  end

  WriteDisk(db, "$MEInput/MEPOCX", MEPOCX)
end

function CalibrationControl(db)
  @info "AdjustCAC_Steel_2021.jl - CalibrationControl"

  IndCalibration(db)
  MacroCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
