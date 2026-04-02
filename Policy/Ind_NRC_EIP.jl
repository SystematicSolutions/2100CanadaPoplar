#
# Ind_NRC_EIP.jl - Process standard with input of process investment expenditures
#
# Increase in the energy efficiency standard to simulate NRCan RD&D Energy Innovation Program (EIP)(2017)
# Target is 1.9 Mt (SAGD), 0.2 Mt (Petrochemicals) and 0.1 Mt (Food, Cement) direct reductions annually by 2030.
#
# (RW 06/02/2021)
# Updated by RST 05Oct2022, re-tuning to Ref23
#

using EnergyModel

module Ind_NRC_EIP

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
  PEERef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Base Year Process Efficiency ($/Btu)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEStd::VariableArray{5} = ReadDisk(db,"$Input/PEStd") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard ($/Btu)
  PEStdP::VariableArray{5} = ReadDisk(db,"$Input/PEStdP") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard Policy ($/Btu)
  PInvExo::VariableArray{5} = ReadDisk(db,"$Input/PInvExo") # [Enduse,Tech,EC,Area,Year] Process Exogenous Investments (M$/Yr)
  PEMMRef::VariableArray{5} = ReadDisk(BCNameDB,"$CalDB/PEMM") # Process Efficiency Max. Mult. ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM") # Process Efficiency Max. Mult. ($/Btu/($/Btu)) [Enduse,Tech,EC,Area,Year]
  PEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM") # Maximum Process Efficiency ($/Btu) [Enduse,EC,Area]
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  CCC::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Variable for Displaying Outputs
  Change::VariableArray{2} = zeros(Float32,length(EC),length(Year)) # [EC,Year] Change in Policy Variable
  DDD::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Variable for Displaying Outputs
  PEENew::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] New PEE
  PolicyCost::VariableArray{2} = zeros(Float32,length(EC),length(Year)) # [EC,Year] Policy Cost (M$/Yr)
end

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Input) = data
  (; Area,EC) = data
  (; Enduse,Nation) = data
  (; Tech) = data
  (; ANMap,Change,PEENew,PEERef,PEM,PEMM,PEMMRef) = data
  (; PEStd,PEStdP,PInvExo) = data
  (; PolicyCost,xInflation) = data

  CN = Select(Nation,"CN");
  areas = findall(ANMap[:,CN] .== 1);

  #
  # New facilities are x% more efficient/year beginning in 2026
  #  
  @. Change = 1.0;
  years = collect(Yr(2026):Yr(2050));
  SAGDOilSands = Select(EC,"SAGDOilSands")
  Food = Select(EC,"Food")
  Cement = Select(EC,"Cement")
  Petrochemicals = Select(EC,"Petrochemicals")
  for year in years
    Change[SAGDOilSands,year] = 1.151
    Change[Food,year] = 1.2855
    Change[Cement,year] = 1.288
    Change[Petrochemicals,year] = 1.106
  end

  years = collect(Yr(2026):Final);
  ecs = Select(EC,["SAGDOilSands","Food","Petrochemicals","Cement"]);
  techs = Select(Tech,"Gas");
  enduses = Select(Enduse,"Heat");
  AB = Select(Area,"AB");
  for year in years, area in AB, ec in ecs, tech in techs, enduse in enduses
    PEENew[enduse,tech,ec,area,year] = PEERef[enduse,tech,ec,area,Yr(2018)] *
      Change[ec,year]
    PEMM[enduse,tech,ec,area,year] = max(PEMM[enduse,tech,ec,area,year],
      (PEMMRef[enduse,tech,ec,area,Yr(2018)] * Change[ec,year]))
    PEStdP[enduse,tech,ec,area,year] = min((PEM[enduse,ec,area]*
      PEMM[enduse,tech,ec,area,year]*0.98),max(PEStd[enduse,tech,ec,area,year],
        PEStdP[enduse,tech,ec,area,year],PEERef[enduse,tech,ec,area,year],
          PEENew[enduse,tech,ec,area,year]))
  end

  WriteDisk(db,"$CalDB/PEMM",PEMM)
  WriteDisk(db,"$Input/PEStdP",PEStdP)

  #
  # Program Costs are $110 million (CN$) spent equally between 2022 and 2026
  #  
  years = collect(Yr(2022):Yr(2026));
  for year in years
    PolicyCost[SAGDOilSands,year] = 105/(2026-2021)/xInflation[AB,year]
    PolicyCost[Food,year] = 5/(2026-2021)/xInflation[AB,year]
    PolicyCost[Cement,year] = 4/(2026-2021)/xInflation[AB,year]
    PolicyCost[Petrochemicals,year] = 8/(2026-2021)/xInflation[AB,year]
  end

  for year in years, area in AB, ec in ecs, tech in techs, enduse in enduses
    PInvExo[enduse,tech,ec,area,year] = PInvExo[enduse,tech,ec,area,year]+
      PolicyCost[ec,year]
  end
  
  WriteDisk(db,"$Input/PInvExo",PInvExo)
end

function PolicyControl(db)
  @info "Ind_NRC_EIP.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
