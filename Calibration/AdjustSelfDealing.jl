#
# AdjustSelfDealing.jl
#
using EnergyModel

module AdjustSelfDealing

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ECalib
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  SelfG::VariableArray{3} = ReadDisk(db,"EInput/SelfG") # [Area,GenCo,Year] Minimum Fraction of GenCo Total Capacity purchased by Area (MW/MW)
  SelfPlant::VariableArray{4} = ReadDisk(db,"EInput/SelfPlant") # [Plant,Area,GenCo,Year] Minimum Fraction of GenCo Plant Capacity purchased by Area (MW/MW)
  SelfR::VariableArray{3} = ReadDisk(db,"EInput/SelfR") # [Area,GenCo,Year] Minimum Fraction of LSE Load purchased from GenCo (MW/MW)
  xCapacity::VariableArray{6} = ReadDisk(db,"EInput/xCapacity") # [Area,GenCo,Plant,TimeP,Month,Year] Capacity under Contract (MW)
  xCapSw::VariableArray{4} = ReadDisk(db,"EInput/xCapSw") # [Area,GenCo,Plant,Year] Switch for Exogenous Contract (1=Contract)
  xEnergy::VariableArray{4} = ReadDisk(db,"EInput/xEnergy") # [Area,GenCo,Plant,Year] Energy Limit on Contracts (Gwh/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xUCCost::VariableArray{4} = ReadDisk(db,"EInput/xUCCost") # [Area,GenCo,Plant,Year] Capacity Cost for Exogenous Contracts ($/KW)
  xUECost::VariableArray{4} = ReadDisk(db,"EInput/xUECost") # [Area,GenCo,Plant,Year] Energy Cost for Exogenous Contracts ($/MWh)
  AFCM::VariableArray{2} = ReadDisk(db,"EGInput/AFCM") # [GenCo,Year] Average Fixed Cost Multiplier (Dless)

  # Scratch Variables
end

function ECalibration(db)
  data = ECalib(; db)
  (;Area,Areas,GenCo,GenCos,Months,Plant) = data
  (;Plants,TimePs,Years) = data
  (;SelfG,SelfPlant,SelfR,xCapacity,xCapSw,xEnergy,xInflation,xUCCost,xUECost,AFCM) = data
  
  #
  # The retail company self-dealing fraction (SelfR) is the fraction of the 
  # retail company peak for which they sign a bilateral contract with the
  # generator.  The value of the fraction can be greater than 1.0 to give
  # the retail company a margin.
  #
  # Initialize all companies to no competition
  #
  years = collect(Yr(2006):Final)
  @. SelfR[Areas, GenCos, years] = 0.0
  @. SelfPlant[Plants, Areas, GenCos, years] = 0.0
  
  for area in Areas
    areaKey = Area[area]
    for genco in GenCos
      if GenCo[genco] == areaKey
        @. SelfR[area,  genco, years] = 1.1
      end
    end
  end
  
  #
  # Self Dealing is zero for Alberta (all energy market)
  #
  AB = Select(Area, "AB")
  for genco in GenCos
    if GenCo[genco] == "AB"
      @. SelfR[AB, genco, Years] = 0.0
      @. SelfPlant[Plants, AB, genco, Years] = 0.0
    end
  end
  WriteDisk(db,"EInput/SelfR",SelfR)
  WriteDisk(db,"EInput/SelfPlant",SelfPlant)
  
  #
  # The generator self-dealing fraction (SelfG) is the fraction of generator
  # capacity which the retail company is required to purchase.  This may be
  # the case with fully integrated utility companies.
  #
  @. SelfG[Areas, GenCos, Years] = 0.0
  areas = Select(Area,["SK","NS","YT","NT","NU"])
  
  for area in areas
    areaKey = Area[area]
    for genco in GenCos
      if GenCo[genco] == areaKey
        @. SelfG[area, genco, years] = 1.0
      end
    end
  end
  
  WriteDisk(db,"EInput/SelfG",SelfG)
  
  #
  # Establish a 100 MW contract between NB and PEI with an 80% capacity factor
  # and a price based on the cost of combined cycle natural gas (OGCC) in 2019.
  #
  PE = Select(Area, "PE")
  OGCC = Select(Plant, "OGCC")
  for genco in GenCos
    if GenCo[genco] == "NB"
      @. xCapSw[PE, genco, OGCC, Years] = 1.0
      @. xCapacity[PE, genco, OGCC, TimePs, Months, Years] = 100
    end
  end
  years = collect(Yr(2030):Final)
  for year in years, genco in GenCos
    if GenCo[genco] == "NB"
      @. xCapacity[PE, genco, OGCC, TimePs, Months, year] = xCapacity[PE, genco, OGCC, TimePs, Months, year-1] * 1.015
    end
  end
  
  for genco in GenCos
    if GenCo[genco] == "NB"
      @. xEnergy[PE, genco, OGCC, Years] = xCapacity[PE, genco, OGCC, TimePs[1], Months[1], Years] *8760/1000*0.80
    end
  end
  
  WriteDisk(db,"EInput/xCapacity",xCapacity)
  WriteDisk(db,"EInput/xCapSw",xCapSw)
  WriteDisk(db,"EInput/xEnergy",xEnergy)
  
  #
  # Peter Volkmar 2022.04.01 - Updated figures with MVC, MFC estimates from 2019
  # taken from model output for OGCC in Electric Marinal Cost
  #
   
  gencos = Select(GenCo, "NB")
  for year in Years
    @finite_math xUCCost[PE, gencos, OGCC, year] = 47.0521 / xInflation[PE,Yr(2019)]
    @finite_math xUECost[PE, gencos, OGCC, year] = 12.5092 / xInflation[PE,Yr(2019)]
  end
  
  
  WriteDisk(db,"EInput/xUCCost",xUCCost)
  WriteDisk(db,"EInput/xUECost",xUECost)
  
  #
  # US Companies charge fixed costs
  #
  
  gencos = Select(GenCo, ["CA","NEng","MAtl","ENC","WNC","SAtl","ESC","WSC","Mtn","Pac"])
  @. AFCM[gencos, Years] = 1.0
  WriteDisk(db,"EGInput/AFCM",AFCM)

end

function CalibrationControl(db)
  @info "AdjustSelfDealing.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
