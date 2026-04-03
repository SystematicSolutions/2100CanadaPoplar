#
# zMapFuelTechECToVehicleFuelTOM.jl
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

Base.@kwdef struct zMapFuelTechECToVehicleFuelTOMData
  db::String
  
  EC::SetArray = ReadDisk(db,"TInput/ECKey")
  ECDS::SetArray = ReadDisk(db,"TInput/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECTrans::SetArray = ReadDisk(db,"MainDB/ECTransKey")
  ECTranses::Vector{Int} = collect(Select(ECTrans))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Tech::SetArray = ReadDisk(db,"TInput/TechKey")
  Techs::Vector{Int} = collect(Select(Tech))
  TechTrans::SetArray = ReadDisk(db,"MainDB/TechTransKey")
  TechTranses::Vector{Int} = collect(Select(TechTrans))
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  VehicleTOMs::Vector{Int} = collect(Select(VehicleTOM))

  MapFuelTechECToVehicleFuelTOM::VariableArray{5} = ReadDisk(db,"KInput/MapFuelTechECToVehicleFuelTOM") # [Fuel,TechTrans,ECTrans,FuelTOM,VehicleTOM] Map between Fuel,Tech and FuelTOM
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
 end

function zMapFuelTechECToVehicleFuelTOM_DtaRun(data)
  (; EC,ECs,ECTrans,ECTranses,FuelTOM,FuelTOMs,Fuel,Fuels) = data
  (; Tech,Techs,TechTrans,TechTranses,VehicleTOM,VehicleTOMs) = data
  (; MapFuelTechECToVehicleFuelTOM) = data

  iob = IOBuffer()

  println(iob,"Variable,VehicleTOM,FuelTOM,ECTrans,TechTrans,Fuel,Data")
  for vehicletom in VehicleTOMs
    for fueltom in FuelTOMs
      for ec in ECs
        for tech in Techs
          for fuel in Fuels
            if MapFuelTechECToVehicleFuelTOM[fuel,tech,ec,fueltom,vehicletom] == 1
              println(iob,"MapFuelTechECToVehicleFuelTOM,",VehicleTOM[vehicletom],",",FuelTOM[fueltom],
              ",",EC[ec],",",Tech[tech],",",Fuel[fuel],
              ",",@sprintf("%.0f",MapFuelTechECToVehicleFuelTOM[fuel,tech,ec,fueltom,vehicletom]))
            end
          end
        end
      end
    end
  end
  
  filename = "zMapFuelTechECToVehicleFuelTOM.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMapFuelTechECToVehicleFuelTOM_DtaControl(db)
  data = zMapFuelTechECToVehicleFuelTOMData(; db)

  @info "zMapFuelTechECToVehicleFuelTOM_DtaControl"

  zMapFuelTechECToVehicleFuelTOM_DtaRun(data)
end

