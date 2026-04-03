#
# ScaleMissingGrossOutput_TOM.jl
#
using EnergyModel

module ScaleMissingGrossOutput_TOM

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  GYAdjust::VariableArray{3} = ReadDisk(db,"KOutput/GYAdjust") # [ECCTOM,AreaTOM,Year] Gross Output from TOM, Adjusted (2017 CN$M/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapfromECCTOM") # [ECC,ECCTOM] Map from ECCTOM to ECC
  MapUSfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSfromECCTOM") # [ECC,ECCTOM] Map from ECCTOM to ECC for the US
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (2012 $M/Yr)
  xGOTOM::VariableArray{3} = ReadDisk(db,"MInput/xGOTOM") # [ECC,Area,Year] Gross Output (2012 M$/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Total Energy Demands (TBtu/Yr)
  xCgDemand::VariableArray{4} = ReadDisk(db,"SInput/xCgDemand") # [Fuel,ECC,Area,Year] Total Energy Demands (TBtu/Yr)

  #
  # Scratch Variables
  #
  DemandTot::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Total Demands Across All Fuels (TBtu/Yr)
end

function CalcDemandTotals(data)
  (;Areas,ECCs,Fuel,Years) = data
  (;xEuDemand,xCgDemand) = data
  (;DemandTot) = data

  fuels = Select(Fuel,!=("Electric"))
  Electric = Select(Fuel,"Electric")
  for year in Years, area in Areas, ecc in ECCs
    DemandTot[ecc,area,year] = sum(xEuDemand[fuel,ecc,area,year]+
        xCgDemand[fuel,ecc,area,year] for fuel in fuels)
    DemandTot[ecc,area,year] = DemandTot[ecc,area,year]+xEuDemand[Electric,ecc,area,year]
  end

end

function FindValidYear(data,years,ecc,area)
  (;Yrv) = data
  (;DemandTot,xGO) = data

  #
  # Find year where gross output greater than 0.001 and Demand greater than 0
  #
  Found=false
  # Count=1
  # @info " FindValidYear "
  for year in years
    if (xGO[ecc,area,year] > 0.001) && (DemandTot[ecc,area,year] > 0.0) && (Found == false)
      Y1 = Int(Yrv[year]-Yrv[1]+1)
      Found = true
    end
  end

  if Found==false
    Y1 = Int(Future+0)
  end

  return Y1
end

function ScaleFirstYears(data,Y1,ecc,area,ecctoms,areatom)
  (;Area,ECC,ECCTOM,Year) = data
  (;DemandTot,GYAdjust,xGO) = data

  # @info " ScaleFirstYears "
  if Y1 > Zero
    Prior = Int(max(Y1-1,1))
    yearsP = collect(Zero:Prior)

    for year in yearsP
      @finite_math xGO[ecc,area,year] = xGO[ecc,area,Y1]*DemandTot[ecc,area,year]/DemandTot[ecc,area,Y1]
      for ecctom in ecctoms
        @finite_math GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Y1]*
          DemandTot[ecc,area,year]/DemandTot[ecc,area,Y1]
      end
    end
  end

end

function ScaleMissingYears(data,ecc,area,ecctoms,areatom)
  (;Year) = data
  (;GYAdjust,xGO) = data
  (;DemandTot) = data

  years=collect(First:Last)
  for year in years
    if (xGO[ecc,area,year] <= 0.001) && (DemandTot[ecc,area,year] > 0.0)
      @finite_math xGO[ecc,area,year]=xGO[ecc,area,year-1]*
          DemandTot[ecc,area,year]/DemandTot[ecc,area,year-1]
      for ecctom in ecctoms
        @finite_math GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,year-1]*
            DemandTot[ecc,area,year]/DemandTot[ecc,area,year-1]
      end
    end
  end
end

function FillInMissingGrossOutput(data,nation,areas)
  (;Area,Areas,ECC,ECCs,Nation,Year) = data
  (;MapAreaTOM,MapfromECCTOM,MapUSfromECCTOM,xGO) = data
  (;DemandTot) = data

  years = collect(First:Last)
  for area in areas
    areatom = first(findall(MapAreaTOM[area,:] .==1))
    if !isempty(areatom)
      for ecc in ECCs
        if Nation[nation]=="US"
          ecctoms = findall(MapUSfromECCTOM[ecc,:] .==1)
        else
          ecctoms = findall(MapfromECCTOM[ecc,:] .==1)
        end
        if !isempty(ecctoms)
          TotYearDmd=sum(DemandTot[ecc,area,year] for year in years)
          if (xGO[ecc,area,Zero] <= 0.001) && (TotYearDmd > 0.0)
            Y1=FindValidYear(data,years,ecc,area)
            ScaleFirstYears(data,Y1,ecc,area,ecctoms,areatom)
          end
          ScaleMissingYears(data,ecc,area,ecctoms,areatom)
        end
      end
    end
  end
  

end

function AdjustGrossOutput(data)
  (; db) = data
  (;AreaTOM,Nation) = data
  (;ANMap,xGO,xGOTOM,GYAdjust) = data

  CalcDemandTotals(data)

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  FillInMissingGrossOutput(data,CN,areas)

  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1)
  FillInMissingGrossOutput(data,US,areas)

  @. xGOTOM = xGO

  WriteDisk(db,"MInput/xGO",xGO)
  WriteDisk(db,"MInput/xGOTOM",xGOTOM)
  WriteDisk(db,"KOutput/GYAdjust",GYAdjust)

end

function MCalibration(db)
  data = MControl(; db)
  (;Nation) = data
  # (;MacroSwitch) = data

  # TODOJulia MacroSwitch

  # CN = Select(Nation,"CN")
  # if MacroSwitch[CN] == "TOM"
    AdjustGrossOutput(data)
  # end

end

function CalibrationControl(db)
  @info "ScaleMissingGrossOutput_TOM.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
