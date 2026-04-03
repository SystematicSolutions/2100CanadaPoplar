#
# DeviceSaturation_VB_Res.jl - Map residential device saturation from VBInput
#
using EnergyModel

module DeviceSaturation_VB_Res

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))

  ECCMap::VariableArray{2} = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] 'Map between EC and ECC'
  vDST::VariableArray{4} = ReadDisk(db,"VBInput/vDST") # [vEnduse,ECC,Area,Year] Device Saturation (Btu/Btu)
  vEUMap::VariableArray{2} = ReadDisk(db,"$Input/vEUMap") # [vEnduse,Enduse] Map between Enduse and vEnduse
  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu) 
end

function RCalibration(db)
  data = RControl(; db)
  (;Input,Areas,ECCs,ECs,Enduses,Years,ECCMap,vEnduses) = data
  (;vDST,vEUMap,xDSt) = data

  for ec in ECs
    for ecc in findall(ECCMap[ec,ECCs] .== 1.0)
      for eu in Enduses
        for veu in findall(vEUMap[vEnduses,eu] .== 1.0)
          for area in Areas, year in Years
            xDSt[eu,ec,area,year] = vDST[veu,ecc,area,year]
          end
        end
      end
    end
  end

  WriteDisk(db,"$Input/xDSt",xDSt)

end

function CalibrationControl(db)
  @info "DeviceSaturation_VB_Res.jl - CalibrationControl"

  RCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
