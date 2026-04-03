#
# UnitHeatRates.jl
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

Base.@kwdef struct UnitHeatRatesData
  db::String
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db, "MainDB/Unit")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") #[Unit,Year]  Heat Rate (BTU/KWh)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnOwner::Vector{String} = ReadDisk(db, "EGInput/UnOwner") #[Unit]  Generating Company
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  
  #
  # Scratch Variables
  #
  UnGCMax = zeros(Float32, length(Unit)) # 'Maximum Unit Capacity (MW)'
  ZZZ = zeros(Float32, length(Year))  
end

function UnitHeatRates_DtaRun(data)
  (; SceName,Unit,Units,Year) = data
  (; UnCode,UnCogen,UnGC,UnHRt,UnName,UnNode) = data
  (; UnOwner,UnPlant,UnGCMax,ZZZ) = data

  years = collect(Yr(1990):Final)

  for unit in Units
    UnGCMax[unit] = maximum(UnGC[unit,year] for year in years)
  end  
  
  #
  # Convert from Btu to KJ    
  #
  for year in years, unit in Units
    UnHRt[unit,year]=UnHRt[unit,year]*1.0546150
  end

  iob = IOBuffer()
  print(iob, "Unit Code;Owner;Plant Name;Plant Type;Node;Cogen Switch;Capacity")
  for year in years
    print(iob,";",Year[year]," KJ/KWh")
  end
  println(iob)
        
  for unit in Units
    # if UnGCMax[unit] > 0.0
      print(iob,UnCode[unit])
      print(iob,";",UnOwner[unit])
      print(iob,";",UnName[unit])
      print(iob,";",UnPlant[unit])
      print(iob,";",UnNode[unit])
      print(iob,";",Int(UnCogen[unit]))
      print(iob,";",@sprintf("%.5f", UnGCMax[unit]))
      for year in years
        ZZZ[year] = UnHRt[unit,year]
        print(iob,";",@sprintf("%.5f",ZZZ[year]))
      end
      println(iob)
    # end
  end
 
  filename = "UnitHeatRates-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnitHeatRates_DtaControl(db)
  @info "UnitHeatRates_DtaControl"
  data = UnitHeatRatesData(; db)

  UnitHeatRates_DtaRun(data)

end
if abspath(PROGRAM_FILE) == @__FILE__
UnitHeatRates_DtaControl(DB)
end
