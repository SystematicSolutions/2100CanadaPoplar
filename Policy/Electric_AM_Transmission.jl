#
# Electric_AM_Transmission.jl
#
# This file adds new interties that are specific to the Additional Measure scenario
#

using EnergyModel

module Electric_AM_Transmission

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Nodes::Vector{Int} = collect(Select(Node))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  LLMax::VariableArray{5} = ReadDisk(db,"EGInput/LLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Months,Node,NodeX,TimePs) = data
  (; LLMax) = data

  #
  # MB to SK - Phase 3. New link of 500 MW in 2030, without contract.
  # Update TD: Cancelled in Ref25 but enabled in Ref25A
  # TD 2025-09-16: cancelled in Ref25A because of NRCAN feedback on Ref25A
  #
  #  node = Select(Node,"SK")
  #  nodex = Select(NodeX,"MB")
  #  years = collect(Yr(2035):Final)
  #  for year in years, month in Months, timep in TimePs
  #    LLMax[node,nodex,timep,month,year] = LLMax[node,nodex,timep,month,year]+500
  #  end
  # 
  # ***********************
  # 
  # There would be a new transport line between Ontario (ON) and Pennsylvania (PJM)
  # 
  node = Select(Node,"ON")
  nodex = Select(NodeX,"PJME")
  years = collect(Yr(2030):Final)
  for year in years, month in Months, timep in TimePs
    LLMax[node,nodex,timep,month,year] = 1000
  end
  # 
  node = Select(Node,"PJME")
  nodex = Select(NodeX,"ON")
  years = collect(Yr(2030):Final)
  for year in years, month in Months, timep in TimePs
    LLMax[node,nodex,timep,month,year] = 1000
  end
  # 
  # ***********************
  # 
  WriteDisk(db,"EGInput/LLMax",LLMax)

  # *
  # ***********************
  # *
  # Define Variable
  # PEDC(ECC,Area,Year)   'Real Elect. Delivery Chg. ($/MWh)',
  #  Disk(ECalDB,PEDC(ECC,Area,Year)) 
  # xInflation(Area,Year)   'Inflation Index ($/$)',
  #  Disk(MInput,xInflation(Area,Year)) 
  # End Define Variable
  # *
  # * BC to AB. Restoration of existing link => $350M on AB 
  # * over 40 years, based on mean SaEC for 2030-2040 from Ref19 
  # * (i.e. 72,123 GWh/yr) and an interest rate of 3.5% (based 
  # * on E2020 WCC variable); gives $0.23/MWh.
  # *   
  # * Select Area(AB), Year(2030-Final)
  # * PEDC(ECC,Area,Y)=PEDC(ECC,Area,Y)+0.23/xInflation(Area,2019)
  # * Select Area*, Year*
  # *
  # ************************
  # *
  # * Write Disk(PEDC)
  # *
  # ************************
  # *
end

function PolicyControl(db)
  @info "Electric_AM_Transmission.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end

