#
# AdjustElectricImports.jl
#
using EnergyModel

module AdjustElectricImports

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCXOthImports::VariableArray{4} = ReadDisk(db,"EGInput/POCXOthImports") # [Poll,NodeX,Area,Year] Imported Emissions Coefficients (Tonnes/GWh)

  # Scratch Variables
  Multiplier1::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Import Emission Multiplier (Tonnes/GWh/(Tonnes/GWh))
  Multiplier2::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Import Emission Multiplier (Tonnes/GWh/(Tonnes/GWh))
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,AreaDS,Areas,NodeX,NodeXDS,NodeXs,Poll,PollDS,Polls,Year) = data
  (;YearDS,Years) = data
  (;POCXOthImports) = data
  (;Multiplier1,Multiplier2) = data

  #
  # Emissions Coefficient for Other Imported Electricity is calibrated
  # so electric emissions match invenetory - Jeff Amlin 2/27/16
  # Updated factors based on revised Ref22 historical generation - R.Levesque 09/26/23
  # 
  CA = Select(Area,"CA")
  #                                 1990    1991    1992    1993    1994    1995    1996    1997    1998    1999    2000    2001    2002    2003    2004    2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019   2020
  Multiplier1[Yr(1990):Yr(2020)] = [1.328,  1.247,  1.328,  1.383,  1.558,  1.366,  1.123,  1.155,  1.389,  1.280,  1.383,  1.540,  1.236,  1.294,  1.293,  1.267,  1.191,  1.184,  1.246,  1.156,  1.064,  1.114,  1.081,  1.087,  1.077,  1.045,  1.055,  1.069,  1.062,  1.133,  1.006]
  
  for year in Yr(1985):Yr(1989)
    Multiplier1[year] = Multiplier1[Yr(1990)]
  end
  for year in Yr(2021):Final
    Multiplier1[year] = Multiplier1[Yr(2020)]
  end

  #                                 1990    1991    1992    1993    1994    1995    1996    1997    1998    1999    2000    2001    2002    2003    2004    2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035
  Multiplier2[Yr(1990):Yr(2035)] = [1.45,   1.35,   1.51,   1.62,   2.01,   1.69,   1.19,   1.21,   1.65,   1.38,   1.65,   1.79,   1.30,   1.37,   1.35,   1.31,   1.28,   1.26,   1.34,   1.22,   1.10,   1.14,   1.11,   1.12,   1.11,   1.07,   1.08,   1.10,   1.09,   1.20,   1.01,   0.47,   0.20,   0.25,   0.52,   0.59,   0.69,   0.73,   0.80,   0.80,   0.84,   1.06,   1.44,   1.43,   1.77,   1.71]
  
  for year in Yr(1985):Yr(1989)
    Multiplier2[year] = Multiplier2[Yr(1990)]
  end
  for year in Yr(2036):Final
    Multiplier2[year] = Multiplier2[Yr(2035)]
  end

  for poll in Polls, nodex in NodeXs, year in Years
    POCXOthImports[poll,nodex,CA,year] = POCXOthImports[poll,nodex,CA,year]*Multiplier1[year]*Multiplier2[year]
  end

  WriteDisk(db,"EGInput/POCXOthImports",POCXOthImports)
  
end

function CalibrationControl(db)
  @info "AdjustElectricImports.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
