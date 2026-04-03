#
# UnitEmissions.jl  Input File for Electric Unit Data
#
using EnergyModel

module UnitEmissions

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECCom::SetArray = ReadDisk(db,"CInput/ECKey")
  ECComDS::SetArray = ReadDisk(db,"CInput/ECDS")
  ECComs::Vector{Int} = collect(Select(ECCom))
  ECInd::SetArray = ReadDisk(db,"IInput/ECKey")
  ECIndDS::SetArray = ReadDisk(db,"IInput/ECDS")
  ECInds::Vector{Int} = collect(Select(ECInd))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CgPOCXCom::VariableArray{5} = ReadDisk(db,"CInput/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Commercial Cogeneration Pollution Coeff. (Tonnes/TBtu)
  CgPOCXInd::VariableArray{5} = ReadDisk(db,"IInput/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Industrial Cogeneration Pollution Coeff. (Tonnes/TBtu)
  MEPOCX::VariableArray{4} = ReadDisk(db,"EGInput/MEPOCX") # [Plant,Poll,Area,Year] Process Emission Coefficients (Tonnes/GWH)
  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBTU)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") # [Year] Number of Units
  UnMECX::VariableArray{3} = ReadDisk(db,"EGInput/UnMECX") # [Unit,Poll,Year] Process Pollution Coefficient (Tonnes/GWH)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
  UnZeroFr::VariableArray{4} = ReadDisk(db,"EGInput/UnZeroFr") # [Unit,FuelEP,Poll,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)
  ZeroFr::VariableArray{4} = ReadDisk(db,"SInput/ZeroFr") # [FuelEP,Poll,Area,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)
end

function GetUnitSets(data,unit)
  (; Area,ECC,Plant) = data
  (; UnArea,UnPlant,UnSector) = data

  #
  # This procedure selects the sets for a particular unit
  #
  if UnPlant[unit] !== ""
    # genco = Select(GenCo,UnGenCo[unit])
    plant = Select(Plant,UnPlant[unit])
    # node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])
    UnitValid = true
  else
    plant = 1
    area = 1
    ecc = 1
    UnitValid = false
  end
    return plant,area,ecc,UnitValid
    # return genco,plant,node,area,ecc
end

function EmissionData(db)
  data = EControl(; db)
  (;ECC,ECCom,ECComs,ECInd,ECInds) = data
  (;FuelEPs,Polls,Units) = data
  (;Years) = data
  (;CgPOCXCom,CgPOCXInd,MEPOCX,POCX,UnCogen,UnCounter,UnMECX) = data
  (;UnPOCX,UnZeroFr,ZeroFr) = data

  ActiveUnits=maximum(Int(UnCounter[year]) for year in Years)
  units = collect(1:ActiveUnits)

  for unit in units
    plant,area,ecc,UnitValid = GetUnitSets(data,unit)
    if UnitValid

      if UnCogen[unit] == 0

        for year in Years, poll in Polls, fuelep in FuelEPs
          UnPOCX[unit,fuelep,poll,year] = POCX[fuelep,plant,poll,area,year]
        end

      else

        for eccom in ECComs
          ecccom = Select(ECC,ECCom[eccom])
          if ecccom == ecc
            for year in Years, poll in Polls, fuelep in FuelEPs
              UnPOCX[unit,fuelep,poll,year] = CgPOCXCom[fuelep,eccom,poll,area,year]
            end
          end
        end

        for ecind in ECInds
          eccind = Select(ECC,ECInd[ecind])
          if eccind == ecc
            for year in Years, poll in Polls, fuelep in FuelEPs
              UnPOCX[unit,fuelep,poll,year] = CgPOCXInd[fuelep,ecind,poll,area,year]
            end
          end
        end
      end

      for year in Years, poll in Polls
        UnMECX[unit,poll,year] = MEPOCX[plant,poll,area,year]
      end

      for year in Years, poll in Polls, fuelep in FuelEPs
        UnZeroFr[unit,fuelep,poll,year] = ZeroFr[fuelep,poll,area,year]
      end

    end
  end

  WriteDisk(db,"EGInput/UnMECX",UnMECX)
  WriteDisk(db,"EGInput/UnPOCX",UnPOCX)
  WriteDisk(db,"EGInput/UnZeroFr",UnZeroFr)
end

function Control(db)
  @info "UnitEmissions.jl - Control"
  EmissionData(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
