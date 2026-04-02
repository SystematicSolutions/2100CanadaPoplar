#
# Com_PeakSavings.jl
#

using EnergyModel

module Com_PeakSavings

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
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmdRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Demand (TBtu/Yr)
  ECCMap::VariableArray{2} = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] # EC TO ECC Map
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets
  xPkSav::VariableArray{4} = ReadDisk(db,"$Input/xPkSav") # [Enduse,EC,Area,Year] Peak Savings from Programs (MW)
  xPkSavECC::VariableArray{3} = ReadDisk(db,"SInput/xPkSavECC") # [ECC,Area,Year] Peak Savings from Programs (MW)

  # Scratch Variables
  DmdTotal::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Demand (TBtu/Yr)
  DmFrac::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  TotPkSav::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Sector Demand Reductions (MW)
end

function ComPolicy(db)
  data = CControl(; db)
  (; Input) = data
  (; Area,ECC,EC,ECs,Enduses,Tech) = data
  (; DmdRef,DmdTotal,DmFrac,TotPkSav,xPkSav,xPkSavECC) = data

  #
  # Input Commercial Electric Peak Savings for British Columbia
  #
  area = Select(Area,"BC")
  TotPkSav[area,Yr(2025)] = 38.5/1.05
  TotPkSav[area,Yr(2026)] = 43.8/1.05
  TotPkSav[area,Yr(2027)] = 48.7/1.05
  TotPkSav[area,Yr(2028)] = 53.3/1.05
  TotPkSav[area,Yr(2029)] = 56.5/1.05
  TotPkSav[area,Yr(2030)] = 56.9/1.05
  TotPkSav[area,Yr(2031)] = 56.6/1.05
  TotPkSav[area,Yr(2032)] = 56.7/1.05
  TotPkSav[area,Yr(2033)] = 57.8/1.05
  TotPkSav[area,Yr(2034)] = 58.6/1.05
  TotPkSav[area,Yr(2035)] = 56.6/1.07
  TotPkSav[area,Yr(2036)] = 55.1/1.08
  TotPkSav[area,Yr(2037)] = 56.0/1.08
  TotPkSav[area,Yr(2038)] = 57.1/1.08
  TotPkSav[area,Yr(2039)] = 58.0/1.02
  TotPkSav[area,Yr(2040)] = 57.9/1.02

  years = collect(Yr(2041):Final)
  for year in years
    TotPkSav[area,year] =  57.9/1.02
  end

  #
  # Commercial Electric Peak Savings for Quebec
  #
  area = Select(Area,"QC")
  TotPkSav[area,Yr(2024)] = 57.1
  TotPkSav[area,Yr(2025)] = 116.6
  TotPkSav[area,Yr(2026)] = 176.2
  TotPkSav[area,Yr(2027)] = 234.6
  TotPkSav[area,Yr(2028)] = 295.7
  TotPkSav[area,Yr(2029)] = 356.5
  TotPkSav[area,Yr(2030)] = 417.6
  TotPkSav[area,Yr(2031)] = 479.6
  TotPkSav[area,Yr(2032)] = 542.2
  TotPkSav[area,Yr(2033)] = 605.2*1.5
  TotPkSav[area,Yr(2034)] = 667.4*1.5
  TotPkSav[area,Yr(2035)] = 729.2*1.5
  TotPkSav[area,Yr(2036)] = 729.2*1.5
  TotPkSav[area,Yr(2037)] = 729.2*1.5
  TotPkSav[area,Yr(2038)] = 729.2*1.5
  TotPkSav[area,Yr(2039)] = 729.2*1.5
  TotPkSav[area,Yr(2040)] = 729.2*1.5

  years = collect(Yr(2041):Final)
  for year in years
    TotPkSav[area,year] =  729.2*1.5
  end
  
  #
  # Commercial Electric Peak Savings for Nova Scotia
  #
  area = Select(Area,"NS")
  TotPkSav[area,Yr(2024)] = 0.00
  TotPkSav[area,Yr(2025)] = 0.00
  TotPkSav[area,Yr(2026)] = 7.52/1.2
  TotPkSav[area,Yr(2027)] = 14.8/1.2
  TotPkSav[area,Yr(2028)] = 22.0/1.2
  TotPkSav[area,Yr(2029)] = 29.1/1.13
  TotPkSav[area,Yr(2030)] = 36.1/1.12
  TotPkSav[area,Yr(2031)] = 43.2/1.11
  TotPkSav[area,Yr(2032)] = 50.2/1.1
  TotPkSav[area,Yr(2033)] = 57.3/1.1
  TotPkSav[area,Yr(2034)] = 64.6/1.1
  TotPkSav[area,Yr(2035)] = 71.8
  TotPkSav[area,Yr(2036)] = 71.8*1.2
  TotPkSav[area,Yr(2037)] = 71.8*1.2
  TotPkSav[area,Yr(2038)] = 71.8*1.2
  TotPkSav[area,Yr(2039)] = 71.8*1.2
  TotPkSav[area,Yr(2040)] = 71.8*1.2

  years = collect(Yr(2041):Final)
  for year in years
    TotPkSav[area,year] =  71.8*1.2
  end

  #
  # Allocate Demand Reduction to all Enduses
  #
  # Calculate the total demand across all enduses and commercial sectors for electric tech
  #
  areas = Select(Area,["NS","QC","BC"])
  years = collect(Yr(2024):Yr(2050))
  tech = Select(Tech,"Electric")

  #
  # Total across enduses
  #
  for area in areas, year in years
    DmdTotal[area,year] = sum(DmdRef[enduse,tech,ec,area,year] for enduse in Enduses,ec in ECs)

  #
  # Calcuate the fraction of electric tech's enduse demand served in each sector
  #
    for enduse in Enduses, ec in ECs
      DmFrac[enduse,ec,area,year] = DmdRef[enduse,tech,ec,area,year]/
                                               DmdTotal[area,year]
      xPkSav[enduse,ec,area,year] = DmFrac[enduse,ec,area,year]*TotPkSav[area,year]
    end

    for ec in ECs
      ecc = Select(ECC,EC[ec])
      xPkSavECC[ecc,area,year] = sum(xPkSav[enduse,ec,area,year] for enduse in Enduses)
    end
  end

  WriteDisk(db,"$Input/xPkSav",xPkSav)
  WriteDisk(db,"SInput/xPkSavECC",xPkSavECC)
end

function PolicyControl(db)
  @info "Com_PeakSavings.jl - PolicyControl"
  ComPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
