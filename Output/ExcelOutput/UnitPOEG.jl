#
# UnitPOEG.jl
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

Base.@kwdef struct UnitPOEGData
  db::String

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db, "MainDB/Unit")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PolConv::VariableArray{1}  = ReadDisk(db,"SInput/PolConv")  #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEGA::VariableArray{2} = ReadDisk(db,"EGOutput/UnEGA") # [Unit,Year] Generation (GWh)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnOwner::Vector{String} = ReadDisk(db, "EGInput/UnOwner") #[Unit]  Generating Company
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  UnPol::VariableArray{4} = ReadDisk(db,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution (Tonnes)

  #
  # Scratch Variables
  #
  Convert = zeros(Float32, length(Poll))  
  UnGCYLoc = zeros(Float32, length(Unit))
  UnPOEG::VariableArray{2}  = zeros(Float32, length(Unit), length(Year))
  ZZZ = zeros(Float32, length(Year))  
end

function UnitPOEG_DtaRun(data, polls, PollName, PollKey)
  (; SceName,FuelEPs,Poll,Unit,Units,Year,Years) = data
  (; PolConv,UnArea,UnCode,UnCogen,UnEGA,UnGC,UnName,UnNode) = data
  (; UnOwner,UnPlant,UnPol) = data
  (; Convert,UnGCYLoc,UnPOEG,ZZZ) = data

  years=collect(Yr(2022):Yr(2050))

  for poll in polls
    Convert[poll] = 1
    if Poll[poll] == "Hg"
      Convert[poll] = 1000
    end
  end

  for unit in Units
    UnGCYLoc[unit] = maximum(UnGC[unit,year] for year in years)
  end  

  for year in years, unit in Units
    @finite_math UnPOEG[unit,year]=sum(UnPol[unit,fuelep,poll,year]*PolConv[poll]*Convert[poll] for poll in polls, fuelep in FuelEPs)/UnEGA[unit,year]
  end

  iob = IOBuffer()
  print(iob, "Unit Code; Owner; Area; Plant Name; Plant Type; Node; Ind Cogen; Pollutant; Units")
  for year in years
    print(iob,";",Year[year]," Emissions")
  end
  println(iob)
        
  for unit in Units
    # if UnGCYLoc[unit] > 0.0
      print(iob,UnCode[unit])
      print(iob,";",UnOwner[unit])
      print(iob,";",UnArea[unit])
      print(iob,";",UnName[unit])
      print(iob,";",UnPlant[unit])
      print(iob,";",UnNode[unit])
      print(iob,";",Int(UnCogen[unit]))
      print(iob,";",PollName)
      if PollName=="Hg"
        print(iob,";Kilograms/GWh")
      else
        print(iob,";Tonnes/GWh")
      end
      for year in years
        ZZZ[year] = UnPOEG[unit,year]
        print(iob,";",@sprintf("%.5f",ZZZ[year]))
      end
      println(iob)
    # end
  end
 
  filename = "UnitPOEG-$PollKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnitPOEG_DtaControl(db)
  @info "UnitPOEG_DtaControl"
  data = UnitPOEGData(; db)
  (; Poll,PollDS,Polls) = data

  for poll in Polls
    PollName=PollDS[poll]
    PollKey=Poll[poll]
    UnitPOEG_DtaRun(data, poll, PollName, PollKey)
  end

  polls=Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  PollName="GHG"
  PollKey="GHG"
  UnitPOEG_DtaRun(data, polls, PollName, PollKey)

end
if abspath(PROGRAM_FILE) == @__FILE__
UnitPOEG_DtaControl(DB)
end

