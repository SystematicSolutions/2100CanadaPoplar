#
# zMapUSfromECCTOM.jl
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

Base.@kwdef struct zMapUSfromECCTOMData
  db::String

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))

  MapUSfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSfromECCTOM") # [ECC,ECCTOM] Map between ECCTOM and ECC
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
end

function zMapUSfromECCTOM_DtaRun(data)
  (; ECC,ECCs,ECCTOM,ECCTOMs) = data
  (; MapUSfromECCTOM) = data

  iob = IOBuffer()

  println(iob,"Variable,ECCTOM,ECC,Data")
  for ecc in ECCs
    for ecctom in ECCTOMs
      if MapUSfromECCTOM[ecc,ecctom] == 1
        println(iob,"MapUSfromECCTOM,",ECCTOM[ecctom],",",ECC[ecc],",",@sprintf("%.0f",MapUSfromECCTOM[ecc,ecctom]))
      end
    end
  end
  
  filename = "zMapUSfromECCTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapUSfromECCTOM_DtaControl(db)
  data = zMapUSfromECCTOMData(; db)

  @info "zMapUSfromECCTOM_DtaControl"

  zMapUSfromECCTOM_DtaRun(data)
end

