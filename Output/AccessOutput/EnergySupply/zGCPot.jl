#
# zGCPot.jl
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

Base.@kwdef struct zGCPotData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zGCPot::VariableArray{4} = ReadDisk(db,"EGOutput/GCPot") #[Plant,Node,Area,Year]  Maximum Potential Generation Capacity (MW)
  zGCPotRef::VariableArray{4} = ReadDisk(RefNameDB,"EGOutput/GCPot") #[Plant,Node,Area,Year]  Maximum Potential Generation Capacity (MW)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zGCPot_DtaRun(data,nation)
  (; Area,AreaDS,Areas,Nation,NationDS,Nations) = data
  (; Nodes,NodeDS,Plants,PlantDS,Year) = data
  (; ANMap,BaseSw,CCC,EndTime,zGCPot,zGCPotRef,ZZZ,SceName) = data

  if BaseSw != 0
    @. zGCPotRef = zGCPot
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Node,Plant;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  for year in years
    for area in areas
      for node in Nodes
        for plant in Plants
          ZZZ[year] = zGCPot[plant,node,area,year]
          CCC[year] = zGCPotRef[plant,node,area,year]
          if ZZZ[year] != 0 || CCC[year] != 0
            println(iob,"zGCPot;",Year[year],";",AreaDS[area],";",NodeDS[node],";",
              PlantDS[plant],";MW;",ZZZ[year],";",CCC[year])
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zGCPot-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zGCPot_DtaControl(db)
  data = zGCPotData(; db)
  (; db,Nation,Nations)= data
  (; ANMap,NationOutputMap)= data

  @info "zGCPot_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zGCPot_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zGCPot_DtaControl(DB)
end
