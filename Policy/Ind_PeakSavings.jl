#
# Ind_PeakSavings.jl
#

using EnergyModel

module Ind_PeakSavings

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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
 ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
 SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets
 xPkSav::VariableArray{4} = ReadDisk(db,"$Input/xPkSav") # [Enduse,EC,Area,Year] Peak Savings from Programs (MW)
 xPkSavECC::VariableArray{3} = ReadDisk(db,"SInput/xPkSavECC") # [ECC,Area,Year] Peak Savings from Programs (MW)

  # Scratch variables
  DmFrac::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year))
  DmdTotal::VariableArray{2} = zeros(Float32,length(Area),length(Year))
  TotPkSav::VariableArray{2} = zeros(Float32,length(Area),length(Year))
end

function IndPolicy(db)
  data = IControl(; db)

 (; Input) = data
  (; Area,Areas,EC,ECs,ECC,ECCs,Enduse,Enduses,Tech,Techs,Year,Years) = data
 (; ECCMap,DmdRef,xPkSav,xPkSavECC,DmFrac,DmdTotal,SecMap,TotPkSav) = data

  # BC peak savings
  area = Select(Area, "BC")
  TotPkSav[area,Yr(2025)] = 149.0/1.05
  TotPkSav[area,Yr(2026)] = 160.0/1.05
  TotPkSav[area,Yr(2027)] = 172.0/1.05
  TotPkSav[area,Yr(2028)] = 184.0/1.05
  TotPkSav[area,Yr(2029)] = 192.0/1.05
  TotPkSav[area,Yr(2030)] = 194.0/1.05
  TotPkSav[area,Yr(2031)] = 195.0/1.05
  TotPkSav[area,Yr(2032)] = 202.0/1.05
  TotPkSav[area,Yr(2033)] = 207.0/1.05
  TotPkSav[area,Yr(2034)] = 207.0/1.05
  TotPkSav[area,Yr(2035)] = 208.0/1.07
  TotPkSav[area,Yr(2036)] = 208.0/1.08
  TotPkSav[area,Yr(2037)] = 211.0/1.08
  TotPkSav[area,Yr(2038)] = 211.0/1.08
  TotPkSav[area,Yr(2039)] = 214.0/1.02
  TotPkSav[area,Yr(2040)] = 214.0/1.02

  years = collect(Yr(2041):Final)
  for year in years
    TotPkSav[area,year] = 214.0/1.02
  end

  # QC peak savings
  area = Select(Area, "QC")
  TotPkSav[area,Yr(2024)] = 132.0
  TotPkSav[area,Yr(2025)] = 262.0
  TotPkSav[area,Yr(2026)] = 388.0
  TotPkSav[area,Yr(2027)] = 518.0
  TotPkSav[area,Yr(2028)] = 645.0
  TotPkSav[area,Yr(2029)] = 771.0
  TotPkSav[area,Yr(2030)] = 899.0
  TotPkSav[area,Yr(2031)] = 1024.0
  TotPkSav[area,Yr(2032)] = 1151.0
  TotPkSav[area,Yr(2033)] = 1278.0
  TotPkSav[area,Yr(2034)] = 1411.0*1.2
  TotPkSav[area,Yr(2035)] = 1548.0*1.2

  years = collect(Yr(2036):Final)
  for year in years
    TotPkSav[area,year] = 1548.0*1.5
  end

  # NS peak savings
  area = Select(Area, "NS")
  TotPkSav[area,Yr(2024)] = 0.00
  TotPkSav[area,Yr(2025)] = 0.00
  TotPkSav[area,Yr(2026)] = 3.81/1.2
  TotPkSav[area,Yr(2027)] = 7.86/1.2
  TotPkSav[area,Yr(2028)] = 11.90/1.2
  TotPkSav[area,Yr(2029)] = 15.89/1.13
  TotPkSav[area,Yr(2030)] = 19.83/1.12
  TotPkSav[area,Yr(2031)] = 23.70/1.11
  TotPkSav[area,Yr(2032)] = 27.52/1.1
  TotPkSav[area,Yr(2033)] = 31.28/1.1
  TotPkSav[area,Yr(2034)] = 35.00/1.1
  TotPkSav[area,Yr(2035)] = 38.68

  years = collect(Yr(2036):Final)
  for year in years
    TotPkSav[area,year] = 38.68*1.2
  end

  # Allocate demand reduction
  areas = Select(Area, ["NS","QC","BC"])
  years = collect(Yr(2024):Yr(2050))
  tech = Select(Tech, "Electric")

  for area in areas, year in years
    # Total across enduses
    DmdTotal[area,year] = sum(DmdRef[enduse,tech,ec,area,year]
                             for enduse in Enduses, ec in ECs)

    # Calculate fraction of electric tech's enduse demand per sector
    for enduse in Enduses, ec in ECs
      DmFrac[enduse,ec,area,year] = DmdRef[enduse,tech,ec,area,year] /
                                   DmdTotal[area,year]
      xPkSav[enduse,ec,area,year] = DmFrac[enduse,ec,area,year] *
                                   TotPkSav[area,year]
    end

    # Calculate ECC values
   for ec in ECs
    ecc = Select(ECC,EC[ec])
    xPkSavECC[ecc,area,year] = sum(xPkSav[enduse,ec,area,year] for enduse in Enduses)
    end
  end

 WriteDisk(db,"$Input/xPkSav",xPkSav)
 WriteDisk(db,"SInput/xPkSavECC",xPkSavECC)
end

function PolicyControl(db)
  @info "Ind_PeakSavings.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
