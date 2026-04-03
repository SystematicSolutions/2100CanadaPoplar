#
# zMapAreaTOMNation.jl
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

Base.@kwdef struct zMapAreaTOMNationData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))

  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
end

function zMapAreaTOMNation_DtaRun(data)
  (; AreaTOM,AreaTOMs,Nation,NationDS,Nations) = data
  (; MapAreaTOMNation,SceName) = data
  
  iob = IOBuffer()

  println(iob,"Variable,AreaTOM,Nation,Data")
  for areatom in AreaTOMs
    for nation in Nations
      if MapAreaTOMNation[areatom,nation] == 1
        println(iob,"MapAreaTOMNation,",AreaTOM[areatom],",",NationDS[nation],",",@sprintf("%.0f",MapAreaTOMNation[areatom,nation]))
      end
    end
  end
#
  filename = "zMapAreaTOMNation.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapAreaTOMNation_DtaControl(db)
  data = zMapAreaTOMNationData(; db)

  @info "zMapAreaTOMNation_DtaControl"
  zMapAreaTOMNation_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  zMapAreaTOMNation_DtaControl(DB)
end
