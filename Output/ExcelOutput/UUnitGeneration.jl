#
# UUnitGeneration.jl
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

Base.@kwdef struct UUnitGenerationData
  db::String

  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int}    = collect(Select(Year))

  Yr2004 = 2004 - 1985 + 1
  Yr2005 = 2005 - 1985 + 1

  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEAF::VariableArray{2} = ReadDisk(db, "EGInput/UnEAF", Final) #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)
  UnEGA::VariableArray{2} = ReadDisk(db, "EGOutput/UnEGA") #[Unit,Year]  Generation (GWh)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db, "EGInput/UnGenCo") #[Unit]  Generating Company
  UnHRt::VariableArray{1} = ReadDisk(db, "EGInput/UnHRt", Final) #[Unit,Year]  Heat Rate (BTU/KWh)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnOR::VariableArray{3} = ReadDisk(db, "EGInput/UnOR", Final) # [Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
  UnOwner::Vector{String} = ReadDisk(db, "EGInput/UnOwner") #[Unit]  Generating Company
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  UUnEGA::VariableArray{2} = ReadDisk(db, "EGOutput/UUnEGA") #[Unit,Year]  Generation (GWh)
  xUnEGA::VariableArray{1} = ReadDisk(db, "EGInput/xUnEGA", Yr2004) #[Unit,Year]  Historical Unit Generation
end

function UUnitGeneration_DtaRun(data)
  (; SceName,Unit,Year, Units) = data
  (; UnCode,UnCogen,UnEAF,UnGC,UnGenCo,UnHRt) = data
  (; UnName,UnNode,UnOR,UnOwner,UnPlant,UUnEGA,xUnEGA) = data


  iob = IOBuffer()

  UnGCYLoc = zeros(Float32, length(Unit))
  ZZZ = zeros(Float32, length(Year))
  
  timep = 1
  month = 1
  years = collect(Yr(1990):Final)

  print(iob, "Unit Code;Owner;Plant Name;Plant Type;Node;Capacity;Heat Rate;")
  print(iob, "Energy Avail Factor;Outage Rate;Ind Cogen;2004 GWH")
  for year in years
    print(iob,";",Year[year]," GWH")
  end
  println(iob)
  
  for unit in Units
    UnGCYLoc[unit] = maximum(UnGC[unit,year] for year in years)
    UnHRt[unit] = UnHRt[unit]*1.0546150
  end

  #
  for unit in Units
    # if UnGCYLoc[unit] > 0.0
      print(iob, UnCode[unit])
      print(iob, ";", UnOwner[unit])
      print(iob, ";", UnName[unit])
      print(iob, ";", UnPlant[unit])
      print(iob, ";", UnNode[unit])
      print(iob, ";", @sprintf("%.5f", UnGCYLoc[unit]))
      print(iob, ";", @sprintf("%.5f", UnHRt[unit]))
      print(iob, ";", @sprintf("%.5f", UnEAF[unit]))
      print(iob, ";", @sprintf("%.5f", UnOR[unit,timep,month]))
      print(iob, ";", Int(UnCogen[unit]))
      print(iob, ";", @sprintf("%.5f", xUnEGA[unit]))
      for year in years
        ZZZ[year]=UUnEGA[unit,year]
        print(iob, ";", @sprintf("%.5f", ZZZ[year]))
      end
      println(iob)
    # end
  end
  println(iob)

  filename = "UUnitGeneration-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UUnitGeneration_DtaControl(db)
  @info "UUnitGeneration_DtaControl"
  data = UUnitGenerationData(; db)

  UUnitGeneration_DtaRun(data)

end
if abspath(PROGRAM_FILE) == @__FILE__
UUnitGeneration_DtaControl(DB)
end
