#
# zMapCNAreaTOM.jl
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

Base.@kwdef struct zMapCNAreaTOMData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  CNAreaTOM::SetArray = ReadDisk(db,"KInput/CNAreaTOMKey")
  CNAreaTOMDS::SetArray = ReadDisk(db,"KInput/CNAreaTOMDS")
  CNAreaTOMs::Vector{Int} = collect(Select(CNAreaTOM))

  MapCNAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,CNAreaTOM] Map between Area and CNAreaTOM
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
end

function zMapCNAreaTOM_DtaRun(data)
  (; Area,AreaDS,Areas,CNAreaTOM,CNAreaTOMs) = data
  (; MapCNAreaTOM,SceName) = data
  
  iob = IOBuffer()

  println(iob,"Variable,CNAreaTOM,Area,Data")
  for cnareatom in CNAreaTOMs
    for area in Areas
      if MapCNAreaTOM[area,cnareatom] == 1
        println(iob,"MapCNAreaTOM,",CNAreaTOM[cnareatom],",",Area[area],",",@sprintf("%.0f",MapCNAreaTOM[area,cnareatom]))
      end
    end
  end
#
  filename = "zMapCNAreaTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapCNAreaTOM_DtaControl(db)
  data = zMapCNAreaTOMData(; db)

  @info "zMapCNAreaTOM_DtaControl"
  zMapCNAreaTOM_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  zMapCNAreaTOM_DtaControl(DB)
end
