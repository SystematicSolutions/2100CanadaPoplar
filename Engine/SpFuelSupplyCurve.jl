#
# SpFuelSupplyCurve.jl - Fuel Supply Curve
#

module SpFuelSupplyCurve

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  SCPoint::SetArray = ReadDisk(db,"MainDB/SCPointKey")
  SCPoints::Vector{Int} = collect(Select(SCPoint))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation] Map between Area and Nation
  DemandNation::VariableArray{2} = ReadDisk(db,"SOutput/DemandNation",year) #[Fuel,Nation,Year] National Demand (TBtu/Yr)
  DmFracMaxCurveNext::VariableArray{3} = ReadDisk(db,"SInput/DmFracMaxCurve",next) #[SCPoint,Fuel,Nation,Year] Maximum Blending for Fuel in Supply Curve (Btu/Btu)
  DmFracMaxSCNext::VariableArray{2} = ReadDisk(db,"SOutput/DmFracMaxSC",next) #[Fuel,Nation,Year] Maximum Blending for Low-Carbon Fuel (Btu/Btu)
  EIOfficialCurveNext::VariableArray{3} = ReadDisk(db,"SInput/EIOfficialCurve",next) #[SCPoint,Fuel,Nation,Year] Emission Intensity for Fuel in Supply Curve (Tonnes/TBtu)
  EIOfficialNext::VariableArray{2} = ReadDisk(db,"SInput/EIOfficial",next) #[Fuel,Area,Year] Official Value for Emission Intensity (Tonnes/TBtu)
  ENPNCurveNext::VariableArray{3} = ReadDisk(db,"SInput/ENPNCurve",next) #[SCPoint,Fuel,Nation,Year] Wholesale Price Supply Curve ($/mmBtu)
  ENPNNext::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",next) #[Fuel,Nation,Year] Wholesale Price ($/mmBtu)
  FuelSCMap::VariableArray{2} = ReadDisk(db,"SInput/FuelSCMap",year) #[Fuel,Nation,Year] Map for Fuels with a Supply Curve (1=Supply Curve)
  SubsidySCNext::VariableArray{2} = ReadDisk(db,"SInput/SubsidySC",next) #[Fuel,Nation,Year] Subsidy for Supply Curve Fuels ($/mmBtu)
  SupplyCurve::VariableArray{3} = ReadDisk(db,"SInput/SupplyCurve",year) #[SCPoint,Fuel,Nation,Year] Supply in Fuel Supply Curve (TBtu/Yr)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) #[Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
end

function NationalDemands(data::Data,nation,areas)
  (; db,year) = data
  (; ECCs,Fuels) = data
  (; DemandNation,TotDemand) = data

  for fuel in Fuels
    DemandNation[fuel,nation] = 
      sum(TotDemand[fuel,ecc,area] for ecc in ECCs, area in areas)
  end

  WriteDisk(db,"SOutput/DemandNation",year,DemandNation)
end

function PopulateSupplyCurveUsingMultipliers(data::Data,fuel,nation)
  (; Fuel,SCPoints) = data
  (; DemandNation,ENPNNext,EIOfficialNext,ENPNCurveNext,EIOfficialCurveNext,SupplyCurve) = data

  Diesel = Select(Fuel,"Diesel")

  if Fuel[fuel] == "Biodiesel"
    for scpoint in SCPoints
      SupplyCurve[scpoint,fuel,nation] = 
        SupplyCurve[scpoint,fuel,nation]*DemandNation[Diesel,nation]
    end
  else
    for scpoint in SCPoints
      SupplyCurve[scpoint,fuel,nation] = 
        SupplyCurve[scpoint,fuel,nation]*DemandNation[fuel,nation]
    end
  end

  for scpoints in SCPoints
    ENPNCurveNext[scpoint,fuel,nation] = ENPNCurveNext[scpoint,fuel,nation]*ENPN[fuel,nation]
  end
  
  for scpoints in SCPoints    
    EIOfficialCurveNext[scpoint,fuel,nation] = 
      EIOfficialCurveNext[scpoint,fuel,nation]*EIOfficialNext[fuel,nation]
  end
end

function FindPointOnSupplyCurve(data::Data,fuel,nation)
  (; SCPoints) = data
  (; DemandNation,SupplyCurve) = data
  
  PtSC = 1
  PointIsFound = false
  PtSCMax = length(SCPoints)

  while !PointIsFound && PtSC < PtSCMax
    if DemandNation[fuel,nation] < SupplyCurve[PtSC,fuel,nation]
      PointIsFound = true
    else
      PtSC = PtSC+1
    end
  end

  return PtSC
end

function ExtractDataFromSupplyCurve(data::Data,PtSC,fuel,nation)
  (; DmFracMaxSCNext,DmFracMaxCurveNext,EIOfficialNext,EIOfficialCurveNext) = data
  (; ENPNNext,ENPNCurveNext,SubsidySCNext) = data

  ENPNNext[fuel,nation] = ENPNCurveNext[PtSC,fuel,nation]+SubsidySCNext[fuel,nation]
  DmFracMaxSCNext[fuel,nation] = DmFracMaxCurveNext[PtSC,fuel,nation]
  EIOfficialNext[fuel,nation] = EIOfficialCurveNext[PtSC,fuel,nation]
end

function Control(data::Data)
  (; db,year,next) = data
  (; Area,Areas,Fuels,Nations) = data
  (; ANMap,DemandNation,DmFracMaxSCNext,EIOfficialNext) = data
  (; ENPNNext,FuelSCMap) = data

  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)

    NationalDemands(data,nation,areas)

    for fuel in Fuels
    
      if FuelSCMap[fuel,nation] == 1
        PtSC = FindPointOnSupplyCurve(data,fuel,nation)
        ExtractDataFromSupplyCurve(data,PtSC,fuel,nation)
        
      elseif FuelSCMap[fuel,nation] == 2
        PopulateSupplyCurveUsingMultipliers(data,fuel,nation)
        PtSC = FindPointOnSupplyCurve(data,fuel,nation)
        ExtractDataFromSupplyCurve(data,PtSC,fuel,nation)
      end
    end
  end

  WriteDisk(db,"SOutput/DmFracMaxSC",next,DmFracMaxSCNext)
  WriteDisk(db,"SInput/EIOfficial",next,EIOfficialNext) 
  WriteDisk(db,"SOutput/ENPN",next,ENPNNext)
  WriteDisk(db,"SOutput/DemandNation",year,DemandNation)
end

end # module SpFuelSupplyCurve
