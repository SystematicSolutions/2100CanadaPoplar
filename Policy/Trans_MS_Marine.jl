#
# Trans_MS_Marine.jl
#
# 10% Electric boats by 2030; 900 KT of emissions from passenger ferries in 2019
# delivers about 120 kt of reductions in 2030
#

using EnergyModel

module Trans_MS_Marine

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TransMSMarineData
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
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
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  # Scratch Variables
  EVShare::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year]  Bus Market Share for Policy Vehicles (Driver/Driver)
  MarineTotal::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Bus Market Share Total (Driver/Driver)
  MSFTarget::VariableArray{3} = zeros(Float32,length(Tech),length(Area),length(Year)) # [Tech,Area,Year] Target Market Share for Policy Vehicles (Driver/Driver)

end

function TransPolicyMarine(db)
  data = TransMSMarineData(; db)
  (; CalDB) = data
  (; Area,EC,Enduse,Tech,Techs) = data
  (; EVShare,MarineTotal,MSFTarget,xMMSF) = data

  enduse = Select(Enduse,"Carriage")
  ec = Select(EC,"Freight")

  BC = Select(Area,"BC")
  AB = Select(Area,"AB")
  SK = Select(Area,"SK")
  MB = Select(Area,"MB")
  ON = Select(Area,"ON")
  QC = Select(Area,"QC")
  NB = Select(Area,"NB")
  NS = Select(Area,"NS")
  NL = Select(Area,"NL")
  PE = Select(Area,"PE")
  YT = Select(Area,"YT")
  NT = Select(Area,"NT")
  NU = Select(Area,"NU")

  #
  # Marine Electric - Data is share of Electric compared to Diesel - Ian 09/15/21
  #
  areas = Select(Area,["BC","AB","SK","MB","ON","QC","NB","NS","NL","PE","YT","NT","NU"])
  years = collect(Yr(2016):Yr(2050))
                      # 2016  2017  2018  2019  2020  2021  2022  2023  2024  2025  2026  2027  2028  2029  2030  2031  2032  2033  2034  2035  2036  2037  2038  2039  2040  2041  2042  2043  2044  2045  2046  2047  2048  2049  2050
  EVShare[BC,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[AB,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[SK,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[MB,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[ON,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[QC,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[NB,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[NS,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[NL,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[PE,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[YT,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[NT,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]
  EVShare[NU,years] = [0.000 0.000 0.000 0.000 0.00  0.00  0.00  0.00  0.00  0.05  0.06  0.07  0.08  0.09  0.10  0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100 0.100]

  tech = Select(Tech,"MarineLight")
  for year in years, area in areas
    MarineTotal[area,year] = xMMSF[enduse,tech,ec,area,year]
  end

  for year in years
    for area in areas
      tech = Select(Tech,"MarineFuelCell")
      MSFTarget[tech,area,year] = max(MarineTotal[area,year]*EVShare[area,year],xMMSF[enduse,tech,ec,area,year])
      tech = Select(Tech,"MarineLight")
      MSFTarget[tech,area,year] = max(MarineTotal[area,year]*(1-EVShare[area,year]),xMMSF[enduse,tech,ec,area,year])
    end
  end

  techs = Select(Tech,["MarineLight","MarineFuelCell"])
  years = collect(Future:Yr(2050))
  for year in years, area in areas, tech in techs
    xMMSF[enduse,tech,ec,area,year] = MSFTarget[tech,area,year]
  end

  WriteDisk(DB,"$CalDB/xMMSF",xMMSF)
end

function PolicyControl(db)
  @info ("Trans_MS_Marine.jl - PolicyControl")
  TransPolicyMarine(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
