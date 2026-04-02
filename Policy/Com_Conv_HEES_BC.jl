#
# Com_Conv_HEES_BC.jl - based on ResCom_MS_Conversions.txp
#
# This policy simulates the prohibition of replacing fossil fuel heaters
# at the end of their devince lifetime(conversions) as part of the Canada
# Green Buildings Strategy. This Policy .JL works in combination with
# FossilFuelHeatingProhibition.jl, which sets the the non-price factor MMSM0
# to -170 to prohibit new installations of fossil fuel heaters. 
# This Policy .JL copies the MMSM0 values into the conversion non-price
# factor variable CMSM0 so that conversions are also prohibited via 
# non-price factors.
#
# Last updated by Kevin Palmer-Wilson on 2023-04-20
#

using EnergyModel

module Com_Conv_HEES_BC

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String
  
  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
  CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
  CTechs::Vector{Int} = collect(Select(CTech))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PI::SetArray = ReadDisk(db,"$Input/PIKey")
  PIDS::SetArray = ReadDisk(db,"$Input/PIDS")
  PIs::Vector{Int} = collect(Select(PI))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CFraction::VariableArray{5} = ReadDisk(db,"$Input/CFraction") # [Enduse,Tech,EC,Area,Year] Fraction of Production Capacity open to Conversion ($/$)
  CMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
  CnvrtEU::VariableArray{4} = ReadDisk(db,"$Input/CnvrtEU") # Conversion Switch [Enduse,EC,Area]
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1

end

function ComPolicy(db)
  data = CControl(; db)
  (; CalDB,Input,Outpt) = data
  (; Area,CTech,CTechs,ECs,Enduse,Enduses,Nation) = data 
  (; Tech,Techs,Years) = data
  (; ANMap,CFraction,CMSM0,CnvrtEU,DPL,Endogenous) = data


  #
  # Policy does not apply to territories per 23/10/30 meeting with ECCC - Ian
  #
  area=Select(Area,"BC")

  #
  # Prohibition of conversions start five years before start of policy
  #
  years = collect(Yr(2030):Final)
   
  for year in years, ec in ECs, enduse in Enduses
    CnvrtEU[enduse,ec,area,year] = Endogenous
  end
  WriteDisk(db,"$Input/CnvrtEU",CnvrtEU)

  for year in years, ec in ECs, enduse in Enduses, tech in Techs
    CFraction[enduse,tech,ec,area,year] = 1.0
  end
  WriteDisk(db,"$Input/CFraction",CFraction)
  
  #
  # CMSM0 is would be overwritten in Ind_MS_Converstion.jl, so remove
  # from this file (which will change results) - Jeff Amlin 12/10/25
  #
  #years = collect(Yr(2030):Yr(2050))
  #for year in years, ec in ECs, enduse in Enduses, tech in Techs, ctech in CTechs
  #  CMSM0[enduse,tech,ctech,ec,area,year] = CMSM0[enduse,tech,ctech,ec,area,Future]
  #end
  #
  #
  # Conversions from Oil use Gas CMSM0. Conversions to Oil are zeroed out due to prohibition.
  #
  #Oil_CT=Select(CTech,"Oil")
  #Gas_CT=Select(CTech,"Gas")
  #for year in years, ec in ECs, enduse in Enduses, tech in Techs
  #  CMSM0[enduse,tech,Oil_CT,ec,area,year] = CMSM0[enduse,tech,Gas_CT,ec,area,year]
  #end
  #
  #techs=Select(Tech,["Oil","Gas"])
  #for year in years, ec in ECs, enduse in Enduses, tech in techs, ctech in CTechs
  #  CMSM0[enduse,tech,ctech,ec,area,year] = -170
  #end
  #WriteDisk(db,"$CalDB/CMSM0",CMSM0)

  #
  # 5 - Use 20+5 for Commerical lifespans
  #
  enduses=Select(Enduse,["Heat","HW"])
  techs=Select(Tech,["Oil","Gas"])
  years = collect(Yr(2030):Yr(2050))
  for year in years, ec in ECs, enduse in enduses, tech in techs
    DPL[enduse,tech,ec,area,year] = 25
  end
  WriteDisk(db,"$Outpt/DPL",DPL)
  
end

function PolicyControl(db)
  @info "Com_Conv_HEES_BC.jl - PolicyControl"
  ComPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
