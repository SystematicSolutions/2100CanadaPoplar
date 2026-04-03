#
# UnitEmissions.jl - Electric Plant Emissions
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

Base.@kwdef struct UnitEmissionsData
  db::String

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db, "MainDB/Unit")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnDmd::VariableArray{3} = ReadDisk(db,"EGOutput/UnDmd") # [Unit,FuelEP,Year] Energy Demands (TBtu)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnMEPol::VariableArray{3} = ReadDisk(db,"EGOutput/UnMEPol") #[Unit,Poll,Year]  Process Pollution (Tonnes)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnOwner::Vector{String} = ReadDisk(db, "EGInput/UnOwner") #[Unit]  Generating Company
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  UnPol::VariableArray{4} = ReadDisk(db,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution (Tonnes)
  xUnDmd::VariableArray{3} = ReadDisk(db,"EGInput/xUnDmd") # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)

  #
  # Scratch Variables
  #
  Sum1 = zeros(Float32, length(Unit), length(FuelEP))
  UnGCYLoc = zeros(Float32, length(Unit))
  UnMMM = zeros(Float32, length(Unit), length(Year))
  UnPPP = zeros(Float32, length(Unit), length(FuelEP), length(Year))
  ZZZ = zeros(Float32, length(Year))  
end

function UnitEmissions_DtaRun(data, polls, PollKey, PollName)
  (; SceName, FuelEP,FuelEPDS,FuelEPs,Poll,PollDS,Polls,Unit,Units,Year) = data
  (; PolConv,UnCode,UnCogen,UnDmd,UnGC,UnMEPol,UnName,UnNation) = data
  (; UnNode,UnOwner,UnPlant,UnPol,xUnDmd) = data
  (; Sum1,UnGCYLoc,UnMMM,UnPPP,ZZZ) = data

  years = collect(Yr(2005):Final)
  for unit in Units
    UnGCYLoc[unit] = maximum(UnGC[unit,year] for year in years)
  end  
  
  iob = IOBuffer()
  print(iob, "Unit Code;Owner;Plant Name;Plant Type;Node;Nation;Cogen;Capacity (MW);")
  print(iob, "Pollutant;Fuel")
  for year in years
    print(iob,";",Year[year]," Tonnes")
  end
  println(iob)

  #
  # Convert GHG to eCO2 and sum across all GHG before display
  #
  if PollKey == "GHG"
    for year in years, fuelep in FuelEPs, unit in Units
      UnPPP[unit,fuelep,year]=sum(UnPol[unit,fuelep,poll,year]*PolConv[poll] for poll in polls)
    end
  else
    for year in years, fuelep in FuelEPs, unit in Units
      UnPPP[unit,fuelep,year]=sum(UnPol[unit,fuelep,poll,year] for poll in polls)
    end
  end
  #
  if PollKey == "GHG"
    for year in years, unit in Units
      UnMMM[unit,year]=sum(UnMEPol[unit,poll,year]*PolConv[poll] for poll in polls)
    end
  else
    for year in years, unit in Units
      UnMMM[unit,year]=sum(UnMEPol[unit,poll,year] for poll in polls)
    end
  end
        
  for unit in Units
    for fuelep in FuelEPs
      Sum1[unit,fuelep]=sum(UnDmd[unit,fuelep,year] for year in years) + xUnDmd[unit,fuelep,Yr(2004)]
      if Sum1[unit,fuelep] > 0.0
        print(iob,UnCode[unit])
        print(iob,";",UnOwner[unit])
        print(iob,";",UnName[unit])
        print(iob,";",UnPlant[unit])
        print(iob,";",UnNode[unit])
        print(iob,";",UnNation[unit])
        print(iob,";",Int(UnCogen[unit]))
        print(iob,";",@sprintf("%.5f", UnGCYLoc[unit]))
        print(iob,";",PollName)
        print(iob,";",FuelEPDS[fuelep])
        for year in years
          ZZZ[year] = UnPPP[unit,fuelep,year]
          print(iob,";",@sprintf("%.6e",ZZZ[year]))
        end
        println(iob)
      end
    end
    print(iob,UnCode[unit])
    print(iob,";",UnOwner[unit])
    print(iob,";",UnName[unit])
    print(iob,";",UnPlant[unit])
    print(iob,";",UnNode[unit])
    print(iob,";",UnNation[unit])
    print(iob,";",Int(UnCogen[unit]))
    print(iob,";",@sprintf("%.5f", UnGCYLoc[unit]))
    print(iob,";",PollName)
    print(iob,";Process")
    for year in years
      ZZZ[year] = UnMMM[unit,year]
      print(iob,";",@sprintf("%.6e",ZZZ[year]))
    end
    println(iob)

  end
 
  filename = "UnitEmissions-$PollKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnitEmissions_DtaControl(db)
  @info "UnitEmissions_DtaControl"
  data = UnitEmissionsData(; db)
  (; Poll,PollDS) = data

  polls=Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  UnitEmissions_DtaRun(data, polls, "GHG", "GHG")
  for poll in polls
    UnitEmissions_DtaRun(data, poll, Poll[poll], PollDS[poll])
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
UnitEmissions_DtaControl(DB)
end
