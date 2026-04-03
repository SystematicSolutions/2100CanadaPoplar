#
# CAC_Macroeconomy.jl - this file calculates the CAC Process emission coefficients
# (MEPOCX) for the sectors not included in the residential, commercial, industrial,
# transportation, or electric generation sectors. JSA 1/11/10
#
using EnergyModel

module CAC_MacroEconomy

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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
  EnPOCX::VariableArray{5} = ReadDisk(db,"MEInput/EnPOCX") # [FuelEP,ECC,Poll,Area,Year] Energy Pollution Coefficient (Tonnes/Economic Driver)
  FlPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FlPOCX") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions Coefficient (Tonnes/Driver)
  FuPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCX") # [ECC,Poll,Area,Year] Other Fugitive Emissions Coefficient (Tonnes/Driver)
  MEDriver::VariableArray{3} = ReadDisk(db,"MOutput/MEDriver") # [ECC,Area,Year] Driver for Process Emissions (Various Millions/Yr)
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Economic Driver)
  ORMEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/ORMEPOCX") # [ECC,Poll,Area,Year] Non-Energy Off Road Pollution Coefficient (Tonnes/Economic Driver)
  VnPOCX::VariableArray{4} = ReadDisk(db,"MEInput/VnPOCX") # [ECC,Poll,Area,Year] Fugitive Venting Emissions Coefficient (Tonnes/Driver)
  xEnFPol::VariableArray{5} = ReadDisk(db,"SInput/xEnFPol") # [FuelEP,ECC,Poll,Area,Year] Actual Energy Related Pollution (Tonnes/Yr)
  xFlPol::VariableArray{4} = ReadDisk(db,"SInput/xFlPol") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions (Tonnes/Yr)
  xFuPol::VariableArray{4} = ReadDisk(db,"SInput/xFuPol") # [ECC,Poll,Area,Year] Other Fugitive Emissions (Tonnes/Yr)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Process Pollution (Tonnes/Yr)
  xORMEPol::VariableArray{4} = ReadDisk(db,"SInput/xORMEPol") # [ECC,Poll,Area,Year] Actual Process Pollution (Tonnes/Yr)
  xVnPol::VariableArray{4} = ReadDisk(db,"SInput/xVnPol") # [ECC,Poll,Area,Year] Fugitive Venting Emissions (Tonnes/Yr)
end

function CalcCoefficients(data,polls,year)
  (;ECC,FuelEPs,Nation) = data
  (;ANMap,EnPOCX,FlPOCX,FuPOCX,MEDriver,MEPOCX) = data
  (;ORMEPOCX,VnPOCX,xEnFPol,xFlPol,xFuPol,xMEPol,xORMEPol,xVnPol) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  #  The CAC Energy emission coefficient (EnPOCX) is equal to the Energy emissions
  # (xEnFPol) divided by the process emission driver (MEDriver).
  #
  # eccs = findall(x -> x == "SolidWaste"
  #                     , ECC)
  eccs=Select(ECC,["SolidWaste","Wastewater","Incineration","LandUse","RoadDust","OpenSources","ForestFires","Biogenics"])
  for area in areas, ecc in eccs
    @finite_math @. EnPOCX[FuelEPs,ecc,polls,area,year] = xEnFPol[FuelEPs,ecc,polls,area,year] / MEDriver[ecc,area,year]
  end

  #
  #  The CAC Process emission coefficient (MEPOCX) is equal to the Process emissions
  # (xMEPol) divided by the process emission driver (MEDriver).
  #
  eccs=Select(ECC,["UtilityGen","BiofuelProduction","SolidWaste","Wastewater","Incineration","LandUse","RoadDust","OpenSources","ForestFires","Biogenics"])
  for area in areas, poll in polls, ecc in eccs
    @finite_math   MEPOCX[ecc,poll,area,year] =   xMEPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
    @finite_math ORMEPOCX[ecc,poll,area,year] = xORMEPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
    @finite_math   FlPOCX[ecc,poll,area,year] =   xFlPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
    @finite_math   FuPOCX[ecc,poll,area,year] =   xFuPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
    @finite_math   VnPOCX[ecc,poll,area,year] =   xVnPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
  end
end

function ExtCoefficients(data,polls,years,Yr1,Yr2)
  (;ECCs,FuPOCX,VnPOCX,ANMap,FuelEPs,Nation) = data
  (;EnPOCX,MEPOCX,FlPOCX) = data

  #
  # Extrapolate CAC emissions coefficients based on (YrData).
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  for year in years, area in areas, poll in polls, ecc in ECCs
    for fuelep in FuelEPs
      @finite_math EnPOCX[fuelep,ecc,poll,area,year] = EnPOCX[fuelep,ecc,poll,area,Yr1] +
        (EnPOCX[fuelep,ecc,poll,area,Yr2] - EnPOCX[fuelep,ecc,poll,area,Yr1]) /
        (Yr2 - Yr1) * (year - Yr1)
    end

    @finite_math MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr1] +
      (MEPOCX[ecc,poll,area,Yr2] - MEPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)

    @finite_math FlPOCX[ecc,poll,area,year] = FlPOCX[ecc,poll,area,Yr1] +
      (FlPOCX[ecc,poll,area,Yr2] - FlPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)

    @finite_math FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr1] +
      (FuPOCX[ecc,poll,area,Yr2] - FuPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)

    @finite_math VnPOCX[ecc,poll,area,year] = VnPOCX[ecc,poll,area,Yr1] +
      (VnPOCX[ecc,poll,area,Yr2] - VnPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)
  end

end

function MacroCalibration(db)
  data = MControl(; db)
  (;EnPOCX,FlPOCX,FuPOCX,Poll,MEPOCX,ORMEPOCX,VnPOCX) = data

  #
  # Calculate Coefficients for years which have data
  #
  polls = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","NH3","Hg","BC"])
  for year in Yr(1990):Yr(2023)
    CalcCoefficients(data,polls,year)
  end

  #
  # Specify values for missing years
  #
  ExtCoefficients(data,polls,1:Yr(1989),Yr(1990),Yr(1990))
  ExtCoefficients(data,polls,Yr(2024):Final,Yr(2023),Yr(2023))

  WriteDisk(db,"MEInput/EnPOCX",EnPOCX)
  WriteDisk(db,"MEInput/FlPOCX",FlPOCX)
  WriteDisk(db,"MEInput/FuPOCX",FuPOCX)
  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
  WriteDisk(db,"MEInput/ORMEPOCX",ORMEPOCX)
  WriteDisk(db,"MEInput/VnPOCX",VnPOCX)
end

function CalibrationControl(db)
  @info "CAC_MacroEconomy.jl - CalibrationControl"

  MacroCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
