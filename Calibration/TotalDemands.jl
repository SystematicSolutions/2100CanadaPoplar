#
# TotalDemands.jl
#
using EnergyModel

module TotalDemands

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation (Name)  
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
  xCgDemand::VariableArray{4} = ReadDisk(db,"SInput/xCgDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (TBtu/Yr)
  xCgEC::VariableArray{3} = ReadDisk(db,"SInput/xCgEC") # [ECC,Area,Year] Cogeneration by Economic Category (GWh/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # [Fuel,ECC,Area,Year] Feedstock Demands (TBtu/Yr)
  xTotDemand::VariableArray{4} = ReadDisk(db,"SInput/xTotDemand") # [Fuel,ECC,Area,Year] Total Energy Demands (TBtu/Yr)
  xUnDmd::VariableArray{3} = ReadDisk(db,"EGInput/xUnDmd") # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)
end

function CalcCogenDemands(db)
  data = MControl(; db)
  (;Area,Areas,ECC,FuelEPs,Fuels,Nation,Nations,Units,Years) = data
  (;xUnDmd,FFPMap,UnArea,UnCogen,xCgDemand,UnNation,UnSector) = data

  utilitygen = Select(ECC,"UtilityGen")

  xCgDemand .= 0
  for nation in Nations
    for unit in findall(UnNation .== Nation[nation])
      if UnCogen[unit] .== 1
        for area in findall(Area .== UnArea[unit])
          for ecc in findall(ECC .== UnSector[unit])
            for fuel in Fuels, year in Years
              xCgDemand[fuel,ecc,area,year] = 
                xCgDemand[fuel,ecc,area,year]+sum(xUnDmd[unit,fep,year]*FFPMap[fep,fuel] for fep in FuelEPs)
            end
          end
        end
      end
    end
  end
  
  WriteDisk(db,"SInput/xCgDemand",xCgDemand)

end

function CalcTotalDemands(db)
  data = MControl(; db)
  (;Areas,ECCs,Fuel,Years) = data
  (;EEConv,xCgDemand,xCgEC,xEuDemand,xFsDemand,xTotDemand) = data

  #
  # Total Fuel Demands
  #
  @. xTotDemand = xEuDemand + xCgDemand + xFsDemand

  Electric = Select(Fuel,"Electric")
  for year in Years, area in Areas, ecc in ECCs
    xTotDemand[Electric,ecc,area,year] = xTotDemand[Electric,ecc,area,year]-
                                         xCgEC[ecc,area,year]*EEConv/1E6
  end

  WriteDisk(db,"SInput/xTotDemand",xTotDemand)
end

function Control(db)
  @info "TotalDemands.jl - Control"
  CalcCogenDemands(db)
  CalcTotalDemands(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
