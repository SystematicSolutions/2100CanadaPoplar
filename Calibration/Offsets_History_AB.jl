#
# Offsets_History_AB.jl - Adjust offset reductions to match historical
# offset reductions in AB - Jeff Amlin 10/28/13, Jeff Amlin 07/05/21
#
using EnergyModel

module Offsets_History_AB

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
  Offset::SetArray = ReadDisk(db,"MainDB/OffsetKey")
  OffsetDS::SetArray = ReadDisk(db,"MainDB/OffsetDS")
  Offsets::Vector{Int} = collect(Select(Offset))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  ReC0::VariableArray{3} = ReadDisk(db,"MEInput/ReC0") # [Offset,Area,Year] C Term in Reduction Curve (Tonnes/Yr)
  RePollutant::Array{String} = ReadDisk(db,"MEInput/RePollutant") # [Offset] Reduction Main Pollutant (Name)
  ReReductionsX::VariableArray{3} = ReadDisk(db,"MEInput/ReReductionsX") # [Offset,Area,Year] Reductions Exogenous (Tonnes/Yr)

  #
  # Scratch Variables
  #
  OffsetConv::VariableArray{1} = zeros(Float32,length(Offset)) # [Offset] Pollution Conversion Factor (convert GHGs to eCO2)
  RePotential::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Potential Offsets (Tonne/Yr)
  ReReductionsAB::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Historical Alberta Offsets (Tonnes/Yr)
  ReReductionsRemoved::VariableArray{3} = zeros(Float32,length(Offset),length(Area),length(Year)) # [Offset,Area,Year] Reductions Exogenous (Tonnes/Yr)
end

function OffsetData(db)
  data = MControl(; db)
  (;Area,Offsets,Poll) = data
  (;Years) = data
  (;PolConv,ReC0,RePollutant,ReReductionsX) = data
  (;RePotential,ReReductionsAB,ReReductionsRemoved) = data

  AB = Select(Area,"AB")
  
  #
  # Backfill ReC0
  #
  years = collect(Yr(2000):Yr(2006))
  for year in years, offset in Offsets
    ReC0[offset,AB,year] = ReC0[offset,AB,Yr(2007)]
  end
  
  
  #
  # Convert reductions to eCO2
  #
  for offset in Offsets  
    if RePollutant[offset] != "None"
      poll = Select(Poll,RePollutant[offset])
      for year in Years
        ReC0[offset,AB,year] = ReC0[offset,AB,year]*PolConv[poll]
      end
    else
      for year in Years    
        ReC0[offset,AB,year] = 0.0
      end
    end
  end

  #
  # Offset Potential
  #
  for year in Years
    RePotential[year] = sum(ReC0[offset,AB,year] for offset in Offsets)
  end

  #
  # Indicated Offset Construction
  #
  years = collect(Yr(2003):Yr(2013))
  for year in years
    ReReductionsAB[year] = 2.50*1e6
  end
  
  #
  # Scale to all types of Offsets
  #
  years = collect(Yr(2003):Yr(2013))
  for year in years, offset in Offsets
    @finite_math ReReductionsRemoved[offset,AB,year] =
      ReC0[offset,AB,year]/RePotential[year]*ReReductionsAB[year]
  end
  # WriteDisk(db,"MEInput/ReC0",ReC0) - do not write to disk! - Jeff Amlin 10/9/24

  #
  # Convert reductions from eCO2
  #
  years = collect(Yr(2003):Yr(2013))
  for offset in Offsets  
    if RePollutant[offset] != "None"
      poll = Select(Poll,RePollutant[offset])
      for year in Years
        ReReductionsRemoved[offset,AB,year] = 
          ReReductionsRemoved[offset,AB,year]/PolConv[poll]
      end
    else
      for year in Years
        ReReductionsRemoved[offset,AB,year] = 0.0
      end
    end
  end
  years = collect(Yr(2014):Final)
  for year in years, offset in Offsets
    ReReductionsRemoved[offset,AB,year] = ReReductionsRemoved[offset,AB,Yr(2013)]
  end
  
  #
  # Remove historical offsets
  #
  for year in Years, offset in Offsets
    ReReductionsX[offset,AB,year] = 
      ReReductionsX[offset,AB,year]-ReReductionsRemoved[offset,AB,year]
  end
  WriteDisk(db,"MEInput/ReReductionsX",ReReductionsX)

end

function Control(db)
  @info "Offsets_History_AB.jl - Control"
  OffsetData(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
