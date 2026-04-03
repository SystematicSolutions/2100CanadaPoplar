#
# zMapAreaTOM.jl
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

Base.@kwdef struct zMapAreaTOMData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))

  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM")   # [Area,AreaTOM]  Map between Area and AreaTOM
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
end

function zMapAreaTOM_DtaRun(data)
  (; Area,AreaDS,Areas,AreaTOM,AreaTOMDS,AreaTOMs) = data
  (; MapAreaTOM,SceName) = data
  
  iob = IOBuffer()

  println(iob,"Variable,Area,AreaTOM,Data")
  for area in Areas
    for areatom in AreaTOMs
      if MapAreaTOM[area,areatom] == 1
        println(iob,"MapAreaTOM,",Area[area],",",AreaTOM[areatom],",",@sprintf("%.0f",MapAreaTOM[area,areatom]))
      end
    end
  end
#
  filename = "zMapAreaTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapAreaTOM_DtaControl(db)
  data = zMapAreaTOMData(; db)

  @info "zMapAreaTOM_DtaControl"
  zMapAreaTOM_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  zMapAreaTOM_DtaControl(DB)
end
