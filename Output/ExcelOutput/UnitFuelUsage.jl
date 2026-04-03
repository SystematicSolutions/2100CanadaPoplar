#
# UnitFuelUsage.jl
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

Base.@kwdef struct UnitFuelUsageData
  db::String

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db, "MainDB/Unit")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnDmd::VariableArray{3} = ReadDisk(db,"EGOutput/UnDmd") # [Unit,FuelEP,Year] Energy Demands (TBtu)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") #[Unit,Year]  Heat Rate (BTU/KWh)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnOwner::Vector{String} = ReadDisk(db, "EGInput/UnOwner") #[Unit]  Generating Company
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  xUnDmd::VariableArray{3} = ReadDisk(db,"EGInput/xUnDmd") # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)
 

  #
  # Scratch Variables
  #
  UnGCYLoc = zeros(Float32, length(Unit))
  ZZZ = zeros(Float32, length(Year))  
end

function UnitFuelUsage_DtaRun(data)
  (; SceName,FuelEP,FuelEPDS,FuelEPs,Unit,Units,Year) = data
  (; UnCode,UnCogen,UnDmd,UnGC,UnHRt,UnName,UnNode) = data
  (; UnOwner,UnPlant,xUnDmd,UnGCYLoc,ZZZ) = data

  years = collect(Yr(2005):Final)
  
  for unit in Units
    UnGCYLoc[unit] = maximum(UnGC[unit,year] for year in years)
  end  

  for year in years, unit in Units
    UnHRt[unit,year]=UnHRt[unit,year]*1.0546150
    for fuelep in FuelEPs
      xUnDmd[unit,fuelep,year]=xUnDmd[unit,fuelep,year]*1.0546150
      UnDmd[unit,fuelep,year]=UnDmd[unit,fuelep,year]*1.0546150
    end
  end

  iob = IOBuffer()
  print(iob, "Unit Code;Owner;Plant Name;Plant Type;Ind Cogen;Node;Capacity (MW);Heat Rate (KJ/KWH);")
  print(iob, "Fuel;2004 PJ")
  for year in years
    print(iob,";",Year[year]," PJ")
  end
  println(iob)
        
  for unit in Units
    for fuelep in FuelEPs
      # if (sum(UnDmd[unit,fuelep,year] for year in years) + xUnDmd[unit,fuelep,Yr(2004)]) > 0.0
        print(iob,UnCode[unit])
        print(iob,";",UnOwner[unit])
        print(iob,";",UnName[unit])
        print(iob,";",UnPlant[unit])
        print(iob,";",Int(UnCogen[unit]))
        print(iob,";",UnNode[unit])
        print(iob,";",@sprintf("%.5f", UnGCYLoc[unit]))
        print(iob,";",@sprintf("%.5f", UnHRt[unit,Yr(2005)]))
        print(iob,";",FuelEPDS[fuelep])
        print(iob,";",@sprintf("%.5f", xUnDmd[unit,fuelep,Yr(2004)]))
        for year in years
          ZZZ[year] = UnDmd[unit,fuelep,year]
          print(iob,";",@sprintf("%.5f",ZZZ[year]))
        end
        println(iob)
      # end
    end
  end
 
  filename = "UnitFuelUsage-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnitFuelUsage_DtaControl(db)
  @info "UnitFuelUsage_DtaControl"
  data = UnitFuelUsageData(; db)

  UnitFuelUsage_DtaRun(data)

end


if abspath(PROGRAM_FILE) == @__FILE__
UnitFuelUsage_DtaControl(DB)
end

