#
# zMapUSECCtoTOM.jl
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

Base.@kwdef struct zMapUSECCtoTOMData
  db::String

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))

  MapUSECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSECCtoTOM") # [ECC,ECCTOM] Map between ECC and ECCTOM
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
end

function zMapUSECCtoTOM_DtaRun(data)
  (; ECC,ECCs,ECCTOM,ECCTOMs) = data
  (; MapUSECCtoTOM) = data

  iob = IOBuffer()

  println(iob,"Variable,ECCTOM,ECC,Data")
  for ecc in ECCs
    for ecctom in ECCTOMs
      if MapUSECCtoTOM[ecc,ecctom] == 1
        println(iob,"MapUSECCtoTOM,",ECCTOM[ecctom],",",ECC[ecc],",",@sprintf("%.0f",MapUSECCtoTOM[ecc,ecctom]))
      end
    end
  end
  
  filename = "zMapUSECCtoTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapUSECCtoTOM_DtaControl(db)
  data = zMapUSECCtoTOMData(; db)

  @info "zMapUSECCtoTOM_DtaControl"

  zMapUSECCtoTOM_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  zMapUSECCtoTOM_DtaControl(DB)
end
