#
# PeakHydro.jl
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct PeakHydroData
  db::String

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  TimeA::SetArray = ReadDisk(db,"MainDB/TimeAKey")
  TimeAKey::SetArray = ReadDisk(db,"MainDB/TimeAKey")
  TimeAs::Vector{Int} = collect(Select(TimeA))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CDTime::Int = ReadDisk(db,"SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db,"SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  HDADP::VariableArray{4} = ReadDisk(db,"EGOutput/HDADP") # [Node,TimeP,Month,Year] Average Load in Interval (MW)
  HDADPwithStorage::VariableArray{4} = ReadDisk(db,"EGOutput/HDADPwithStorage") # [Node,TimeP,Month,Year] Average Load in Interval with Generation to Fill Storage (MW)
  HDEnergy::VariableArray{4} = ReadDisk(db,"EGOutput/HDEnergy") # [Node,TimeP,Month,Year] Energy in Interval (GWh)
  HDHrMn::VariableArray{2} = ReadDisk(db,"EInput/HDHrMn") # [TimeP,Month] Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db,"EInput/HDHrPk") # [TimeP,Month] Peak Hour in the Interval (Hour)
  HDPDP::VariableArray{4} = ReadDisk(db,"EGOutput/HDPDP") # [Node,TimeP,Month,Year] Peak (Highest) Load in Interval (MW)
  PHEG0::VariableArray{2} = ReadDisk(db,"EGOutput/PHEG0") # [Node,Year] Generation Available - Energy (GWh)
  PHEGAv::VariableArray{3} = ReadDisk(db,"EGOutput/PHEGAv") # [Node,TimeA,Year] Generation Available - Energy (GWh)
  PHEGC0::VariableArray{2} = ReadDisk(db,"EGOutput/PHEGC0") # [Node,Year] Effective Generation Capacity Total (MW)
  PHEGC1::VariableArray{3} = ReadDisk(db,"EGOutput/PHEGC1") # [Node,TimeA,Year] Effective Generation Capacity from Peak Method (MW)
  PHEGC2::VariableArray{3} = ReadDisk(db,"EGOutput/PHEGC2") # [Node,TimeA,Year] Effective Generation Capacity from Base Method (MW)
  PHEGC3::VariableArray{3} = ReadDisk(db,"EGOutput/PHEGC3") # [Node,TimeA,Year] Effective Generation Capacity Combined (MW)
  PHEGC4::VariableArray{3} = ReadDisk(db,"EGOutput/PHEGC4") # [Node,TimeA,Year] Effective Generation Capacity Normalized (MW)
  PHEGCAv::VariableArray{3} = ReadDisk(db,"EGOutput/PHEGCAv") # [Node,TimeA,Year] Generation Available - Capacity (MW)
  PHPDP0::VariableArray{3} = ReadDisk(db,"EGOutput/PHPDP0") # [Node,TimeA,Year] Effective Peak including Exports (MW)
  PHPDP1::VariableArray{3} = ReadDisk(db,"EGOutput/PHPDP1") # [Node,TimeA,Year] Effective Peak including Exports (MW)
  PHSpillage::VariableArray{4} = ReadDisk(db,"EGInput/PHSpillage") # [TimeP,Month,Node,Year] Peak Hydro Spillage (MW/MW)
  StorEG::VariableArray{4} = ReadDisk(db,"EGOutput/StorEG") # [TimeP,Month,Node,Year] Electricity Generated from Storage Technologies (GWh/Yr)
  StorEnergy::VariableArray{4} = ReadDisk(db,"EGOutput/StorEnergy") # [TimeP,Month,Node,Year] Electricity Required to Recharge Storage Technologies (GWh/Yr)
end

function PeakHydro_DtaRun(data)
  (; SceName,Node,NodeDS,Nodes,TimeA,TimeAKey,TimeAs,TimeP,TimePs) = data
  (; Month,MonthDS,Months,Year,YearDS,Years) = data
  (; HDADP,HDADPwithStorage,HDEnergy,HDHrMn,HDHrPk,HDPDP,PHEG0,PHEGAv,PHEGC0) = data
  (; PHEGC1,PHEGC2,PHEGC3,PHEGC4,PHEGCAv,PHPDP0,PHPDP1,PHSpillage,StorEG,StorEnergy) = data
 
  iob = IOBuffer()
  ZZZ = zeros(Float32, length(Year))    
    
  year = Select(Year, (from = "1985", to = "2050"))
 
  println(iob, "Variable;Variable;Node;TimeA;",join(Year[year],";"))    
  
  for node in Nodes
    ZZZ[year] = PHEG0[node,year]
    println(iob,"PHEG0;Generation Available - Energy (GWh);",NodeDS[node],";",join(ZZZ[year],";"))
    ZZZ[year] = PHEGC0[node,year]
    println(iob,"PHEGC0;Effective Generation Capacity Total (MW);",NodeDS[node],";",join(ZZZ[year],";"))

    for timea in TimeAs
      ZZZ[year] = PHEGAv[node,timea,year]
      println(iob,"PHEGAv ;Generation Available - Energy (GWh);",NodeDS[node],";",TimeAKey[timea],";",join(ZZZ[year],";"))
      
      ZZZ[year] = PHEGC1[node,timea,year]
      println(iob,"PHEGC1 ;Effective Generation Capacity 1 from Peak Method (MW);",NodeDS[node],";",TimeAKey[timea],";",join(ZZZ[year],";"))
      ZZZ[year] = PHEGC2[node,timea,year]
      println(iob,"PHEGC2 ;Effective Generation Capacity 2 from Base Method (MW);",NodeDS[node],";",TimeAKey[timea],";",join(ZZZ[year],";"))
      ZZZ[year] = PHEGC3[node,timea,year]
      println(iob,"PHEGC3 ;Effective Generation Capacity 3 Combined (MW);",NodeDS[node],";",TimeAKey[timea],";",join(ZZZ[year],";"))
      ZZZ[year] = PHEGC4[node,timea,year]
      println(iob,"PHEGC4 ;Effective Generation Capacity 4 Normalized (MW);",NodeDS[node],";",TimeAKey[timea],";",join(ZZZ[year],";"))

      ZZZ[year] = PHEGCAv[node,timea,year]
      println(iob,"PHEGCAv;Generation Available - Capacity (MW);",NodeDS[node],";",TimeAKey[timea],";",join(ZZZ[year],";"))
      ZZZ[year] = PHPDP0[node,timea,year]
      println(iob,"PHPDP0 ;Effective Peak 0 including Exports (MW);",NodeDS[node],";",TimeAKey[timea],";",join(ZZZ[year],";"))
      ZZZ[year] = PHPDP1[node,timea,year]
      println(iob,"PHPDP1 ;Effective Peak 1 including Exports (MW);",NodeDS[node],";",TimeAKey[timea],";",join(ZZZ[year],";"))
    end
  end
  
  filename = "PeakHydro-$SceName.dta"
    open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end


end

function PeakHydro_DtaControl(db)
  @info "PeakHydro_DtaControl"
  data = PeakHydroData(; db)
  PeakHydro_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
PeakHydro_DtaControl(DB)
end
