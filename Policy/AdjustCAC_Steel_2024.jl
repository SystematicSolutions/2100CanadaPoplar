#
# AdjustCAC_Steel_2024.jl - This jl models the VOC in certain products (SOR/2021-268) Regulations
# 
# This TXP Models emission reductions to the Iron&Steel sector in Ontario
# These reductions are associated with the Algoma and Arcelor projects 
# Where conversion to DRI-EAF will lead to significant reductions from these 2 plants
# Since the impact of these projects is mostly captured in FsDmd, but no AP emissions are produced from it
# Pro-rating the impact to combustion and process emissions to obtain anticipated levels of emissions. 
# The assumptions were taken from 2022 Projection sent to EAD (Oct 21, 2022)_Iron&STeel.xlsx 
# Received from the Metals and Minerals Processing Division on Oct 21 2022
# Proportional reduction were applied to Ref22 to develop the Pollution Coefficient Reduction Multipliers
# See 2022 Iron&Steel projections_AB_221103.xlsx for detail calculations
# These assumptions should be reviewed yearly 
# By Audrey Bernard 22.10.24

using EnergyModel

module AdjustCAC_Steel_2024

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
  MEInput::String = "MEInput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Economic Driver)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
  Temp::VariableArray{2} = zeros(Float32,length(Poll),length(Year)) # [ECC,Poll,Area,Year] Scratch Variable For Input Reductions
end

function IndPolicy(db)
  data = IControl(; db)
  (; Area,EC,ECC,Enduses,FuelEPs,Poll) = data
  (; Input,MEInput) = data
  (; MEPOCX,POCX,Temp) = data

  #
  # Adjust Combustion Emissions
  #
  polls = Select(Poll,["NH3","BC","COX","NOX","PMT","PM10","PM25","SOX","VOC"])
  years = collect(Yr(2023):Yr(2035))
  ec = Select(EC,"IronSteel")
  area = Select(Area,"ON")

  Temp[polls,years] .= [
    #/(Poll,Year)                   2023     2024     2025     2026     2027      2028     2029     2030     2031     2032     2033     2034     2035  
    #=Ammonia=#                   0.0000   0.0000   0.0000   0.0194   0.0194    0.0194   0.0671   0.0671   0.0671   0.0671   0.0671   0.0671   0.0671
    #=Black Carbon=#              0.0000   0.0000   0.0000   0.3386   0.3386    0.3386   0.5587   0.5587   0.5587   0.5587   0.5587   0.5587   0.5587
    #=Carbon Monoxide=#           0.0000   0.0000   0.0000   0.0084   0.0084    0.0084   0.1108   0.1108   0.1108   0.1108   0.1108   0.1108   0.1108
    #=Nitrogen Oxides=#           0.0000   0.0000   0.0000   0.1878   0.1878    0.1878   0.2153   0.2153   0.2153   0.2153   0.2153   0.2153   0.2153
    #=Total Particulate Matter=#  0.0000   0.0000   0.0000   0.1076   0.1076    0.1076   0.1708   0.1708   0.1708   0.1708   0.1708   0.1708   0.1708
    #=Particulate Matter 10=#     0.0000   0.0000   0.0000   0.0812   0.0812    0.0812   0.1229   0.1229   0.1229   0.1229   0.1229   0.1229   0.1229
    #=Particulate Matter 2.5=#    0.0000   0.0000   0.0000   0.0879   0.0879    0.0879   0.1128   0.1128   0.1128   0.1128   0.1128   0.1128   0.1128
    #=Sulphur Oxides=#            0.0000   0.0000   0.0000   0.2647   0.2647    0.2647   0.7727   0.7727   0.7727   0.7727   0.7727   0.7727   0.7727
    #=Volatile Org Comp=#         0.0000   0.0000   0.0000   0.0585   0.0585    0.0585   0.0727   0.0727   0.0727   0.0727   0.0727   0.0727   0.0727
    ]

  for enduse in Enduses, poll in polls, fuelep in FuelEPs
    years = collect(Yr(2023):Yr(2035))
    for year in years
      POCX[enduse,fuelep,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,area,year]*
        (1-Temp[poll,year])
    end
    years = collect(Yr(2036):Final)
    for year in years
      POCX[enduse,fuelep,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,area,year]*
        (1-Temp[poll,Yr(2035)])
    end
  end
  WriteDisk(db,"$Input/POCX",POCX)

  #
  # Adjust Process Emissions
  #
  polls = Select(Poll,["NH3","COX","NOX","PMT","PM10","PM25","SOX","VOC"])
  years = collect(Yr(2023):Yr(2035))
  ecc = Select(ECC,"IronSteel")
  area = Select(Area,"ON")

  Temp[polls,years] .= [
    #/(Poll,Year)                   2023     2024     2025     2026     2027      2028     2029     2030     2031     2032     2033     2034     2035  
    #=Ammonia=#                   0.0000   0.0000   0.0000   0.0194   0.0194    0.0194   0.0671   0.0671   0.0671   0.0671   0.0671   0.0671   0.0671
    #=Carbon Monoxide=#           0.0000   0.0000   0.0000   0.0084   0.0084    0.0084   0.1108   0.1108   0.1108   0.1108   0.1108   0.1108   0.1108
    #=Nitrogen Oxides=#           0.0000   0.0000   0.0000   0.1878   0.1878    0.1878   0.2153   0.2153   0.2153   0.2153   0.2153   0.2153   0.2153
    #=Total Particulate Matter=#  0.0000   0.0000   0.0000   0.1076   0.1076    0.1076   0.1708   0.1708   0.1708   0.1708   0.1708   0.1708   0.1708
    #=Particulate Matter 10=#     0.0000   0.0000   0.0000   0.0812   0.0812    0.0812   0.1229   0.1229   0.1229   0.1229   0.1229   0.1229   0.1229
    #=Particulate Matter 2.5=#    0.0000   0.0000   0.0000   0.0879   0.0879    0.0879   0.1128   0.1128   0.1128   0.1128   0.1128   0.1128   0.1128
    #=Sulphur Oxides=#            0.0000   0.0000   0.0000   0.2647   0.2647    0.2647   0.7727   0.7727   0.7727   0.7727   0.7727   0.7727   0.7727
    #=Volatile Org Comp=#         0.0000   0.0000   0.0000   0.0585   0.0585    0.0585   0.0727   0.0727   0.0727   0.0727   0.0727   0.0727   0.0727
    ]

  for poll in polls
    years = collect(Yr(2023):Yr(2035))
    for year in years
      MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*(1-Temp[poll,year])
    end
    years = collect(Yr(2036):Final)
    for year in years
      MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*(1-Temp[poll,Yr(2035)])
    end
  end
  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)

end


function PolicyControl(db)
  @info "AdjustCAC_Steel_2024.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
