#
# zCreditsInventory.jl
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

Base.@kwdef struct zCreditsInventoryData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Market::SetArray = ReadDisk(db, "MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zCreditsInventory::VariableArray{2} = ReadDisk(db, "SOutput/CreditsInventory") # [Market,Year] CFS Credits Inventory (Tonnes/Yr)
  zCreditsInventoryRef::VariableArray{2} = ReadDisk(RefNameDB, "SOutput/CreditsInventory") # [Market,Year] CFS Credits Inventory (Tonnes/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  #
  # Scratch Variables
  #
  MarketDS::SetArray = [string(i) for i in 1:length(Market)] # [Market] Market Description (created as string indices)
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zCreditsInventory_DtaRun(data,nation)
  (; Market,MarketDS,Markets,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,Year) = data
  (; BaseSw,CDTime,Conversion,EndTime,UnitsDS,zCreditsInventory,zCreditsInventoryRef,SceName) = data

  if BaseSw != 0
    @. zCreditsInventoryRef = zCreditsInventory
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Market;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "Tonnes/Yr"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "Tonnes/Yr"
  end

  for market in Markets
    for year in years
      ZZZ = zCreditsInventory[market,year]*Conversion[nation,year]
      CCC = zCreditsInventoryRef[market,year]*Conversion[nation,year]
      if ZZZ != 0 || CCC != 0
        println(iob,"zCreditsInventory;",Year[year],";",MarketDS[market],";",UnitsDS[nation],";",
          @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zCreditsInventory-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zCreditsInventory_DtaControl(db)
  data = zCreditsInventoryData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zCreditsInventory_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zCreditsInventory_DtaRun(data,nation)
    end
  end
end


if abspath(PROGRAM_FILE) == @__FILE__
zCreditsInventory_DtaControl(DB)
end

