#
# CCS_ITC.jl - Investment Tax Credit (ITC) for Carbon Sequestration. The tax credit is designed to provide a discount on
# capital costs associated with the installation of carbon capture and storage facilities in Canada. Legislation was finalized in June 2024.
# Alberta introduced their own CCUS investment tax credit to complement the federal tax credit which increaes
# the total amount that can be claimed in Alberta throughout the projection period. The Alberta version can be
# claimed on top of the federal credit, with eligible projects back dated to 2022.
#

using EnergyModel

module CCS_ITC

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  SqIVTC::VariableArray{2} = ReadDisk(db,"MEInput/SqIVTC") # [Area,Year] Sequestering CO2 Reduction Investment Tax Credit ($/$)
end

function MacroPolicy(db)
  data = MControl(; db)
  (; Areas,Years) = data
  (; SqIVTC) = data
  
  years = collect(Yr(2024):Yr(2030))
  for area in Areas, year in years
    SqIVTC[area,year] = 0.5
  end
  years = collect(Yr(2031):Yr(2040))
  for area in Areas, year in years
    SqIVTC[area,year] = 0.25
  end
  years = collect(Yr(2041):Final)
  for area in Areas, year in years
    SqIVTC[area,year] = 0.0
  end

  WriteDisk(db,"MEInput/SqIVTC",SqIVTC)
end

function PolicyControl(db)
  @info "CCS_ITC.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
