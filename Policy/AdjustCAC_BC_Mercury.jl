#
# AdjustCAC_BC_Mercury.jl - This jl adjusts exceptional 2023 mercury emissions from BC's other non ferrous metal sector
#

using EnergyModel

module AdjustCAC_BC_Mercury

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB")#  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Process Emissions Coefficient (Tonnes/Driver)

  # Scratch Variables
  Reduce::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Year)) # [ECC,Poll,Year] Scratch Variable For Input Reductions
end

function MacroPolicy(db)
  data = MControl(; db)
  (; Area,ECC) = data
  (; Poll) = data
  (; MEPOCX) = data
  (; Reduce) = data

  #
  @. Reduce=1

  #
  ################
  #British Columbia
  ################
  #
  areas = Select(Area,"BC")
  eccs = Select(ECC,"OtherNonferrous")
  years = collect(Yr(2024):Yr(2025))
  Hg = Select(Poll,"Hg")
  #! format: off
  Reduce[eccs, Hg, years] = [
    # 2024    2025 # Mercury
      0.2541  0.1376
    ]
  #! format: on

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2025))
  for year in years, area in areas, poll in Hg, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2026):Final)
  for year in years, area in areas, poll in Hg, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2025)]
  end

  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
end

function PolicyControl(db)
  @info "AdjustCAC_BC_Mercury.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
