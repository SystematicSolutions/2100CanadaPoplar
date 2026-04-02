#
# Com_BldgStdPolicy.jl - Future building code standards
#
# Last updated by Yang Li on 2025-06-06
########################
#
# This policy increases the process efficiency standard (PEStdP).
# The policy is aimed to reflect provincial actions aimed at increasing
# the energy efficiency of new commercial buildings.
#
# It is important to note that provincial measures are expressed as improvements to 
# energy intensity, while the PEStdP variable is expressed in terms of energy 
# efficiency. For this reason, the provincial energy intensity improvement targets 
# need to be converted to energy efficiency targets using the following equation:
# deltaEfficiency = 1/(1-deltaIntensity)-1 
# where deltaIntensity is expressed as a positive number.
#
# For background on how the energy efficiency values were developed, see 
# \\ncr.int.ec.gc.ca\shares\e\ECOMOD\Policy Support Work\Bld Codes Analysis\.
# Detailed factors available in "Bld Codes Stringencyv7.xlsx".
#
########################
#

using EnergyModel

module Com_BldgStdPolicy

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  # CalDB::String = "CCalDB"
  # Input::String = "CInput"
  # Outpt::String = "COutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"CInput/ECKey")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"CInput/EnduseKey")
  Tech::SetArray = ReadDisk(db,"CInput/TechKey")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PEE::VariableArray{5} = ReadDisk(db,"COutput/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEM::VariableArray{3} = ReadDisk(db,"CCalDB/PEM") # [Enduse,EC,Area] Maximum Process Efficiency ($/mmBtu)
  PEMM::VariableArray{5} = ReadDisk(db,"CCalDB/PEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu))
  PEStd::VariableArray{5} = ReadDisk(db,"CInput/PEStd") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard ($/Btu)
  PEStdP::VariableArray{5} = ReadDisk(db,"CInput/PEStdP") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard Policy ($/Btu)

  EEImprovement::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # Energy Efficiency Improvement from Baseline Value ($/Btu)/($/Btu) [Area,Year]
  EIImprovement::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # Energy Intensity Improvement from Baseline Value ($/Btu)/($/Btu) [Area,Year]
  PEEAvg_BC::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # Base Case Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEMMAvg_BC::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # Process Efficiency Max. Mult. ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
end

function ComPolicy(db)
  data = CControl(; db)
  (; Area,Areas,ECs,Enduse,Techs,Year,Years) = data
  (; EEImprovement,EIImprovement,PEE,PEEAvg_BC) = data
  (; PEM,PEMM,PEMMAvg_BC,PEStd,PEStdP) = data
     
  areas = Select(Area,"BC")
  for area in areas
      
    years = collect(Yr(2026):Yr(2030))
    for year in years
        EEImprovement[area,year] = 0.419
    end
    
    years = collect(Yr(2031):Yr(2035))
    for year in years
        EEImprovement[area,year] = 0.647
    end
    
    years = collect(Yr(2036):Yr(2050))
    for year in years
        EEImprovement[area,year] = 0.651
    end
    
  end
  
  for year in Years, area in Areas
    EIImprovement[area,year] = 1/(1-EEImprovement[area,year])-1
  end


  Heat = Select(Enduse,"Heat")

  areas = Select(Area,"BC")
  for area in areas, ec in ECs, tech in Techs
    years = Select(Year,(from = "2006",to = "2010"))
    PEEAvg_BC[Heat,tech,ec,area] = 
      sum(PEE[Heat,tech,ec,area,year] for year in years)/5
    PEMMAvg_BC[Heat,tech,ec,area] = sum(PEMM[Heat,tech,ec,area,year] for year in years)/5
  end

  years = collect(Yr(2026):Final)
  areas = Select(Area,"BC")
  for year in years, area in areas, ec in ECs, tech in Techs
    PEMM[Heat,tech,ec,area,year] = PEMM[Heat,tech,ec,area,year]*
      (1+EIImprovement[area,year])
    PEStdP[Heat,tech,ec,area,year] = max(PEStd[Heat,tech,ec,area,year],
      PEStdP[Heat,tech,ec,area,year],min(PEM[Heat,ec,area]*
        PEMM[Heat,tech,ec,area,year]*0.98,PEEAvg_BC[Heat,tech,ec,area]*
          (1+EIImprovement[area,year])))
  end

  WriteDisk(db,"CCalDB/PEMM",PEMM)
  WriteDisk(db,"CInput/PEStdP",PEStdP)
end

function PolicyControl(db)
  @info "Com_BldgStdPolicy.jl - PolicyControl"
  ComPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
