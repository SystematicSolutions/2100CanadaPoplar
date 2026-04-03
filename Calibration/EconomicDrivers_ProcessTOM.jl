#
# EconomicDrivers_ProcessTOM.jl - When running TOM, assign US households from AEO (temporary);
#                                  and split CN and US total population by housing type.
#
using EnergyModel

module EconomicDrivers_ProcessTOM

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  xHHSAEO::VariableArray{3} = ReadDisk(db,"MInput/xHHSAEO") # [ECC,Area,Year] Households from AEO (Households)
  xHHS::VariableArray{3} = ReadDisk(db,"MInput/xHHS") # [ECC,Area,Year] Households (Households)
  xPop::VariableArray{3} = ReadDisk(db,"MInput/xPop") # [ECC,Area,Year] Population (Millions)
  xPopT::VariableArray{2} = ReadDisk(db,"MInput/xPopT") # [Area,Year] Population (Millions of People)
  xPopAEO::VariableArray{3} = ReadDisk(db,"MInput/xPopAEO") # [ECC,Area,Year] Population by Household Type (Millions)
  xPopTAEO::VariableArray{2} = ReadDisk(db,"MInput/xPopTAEO") # [Area,Year] Population (Millions)
  xPopTOM::VariableArray{3} = ReadDisk(db,"MInput/xPopTOM") # [ECC,Area,Year] Population by Household Type from TOM (Millions)
  xTHHS::VariableArray{2} = ReadDisk(db,"MInput/xTHHS") # [Area,Year] Total Households (Households)

  # Scratch Variables
end

function MCalibration(db)
  data = MControl(; db)
  (;Area,AreaDS,Areas,ECC,ECCDS,ECCs,Nation,Year,YearDS,Years) = data
  (;ANMap,SecMap,xHHSAEO,xHHS,xPop,xPopT,xPopAEO,xPopTAEO,xPopTOM,xTHHS) = data

  #
  # Only do this code if running with TOM macro model.
  #
  US=Select(Nation,"US")
  # TODOJulia MacroSwitch
  # if MacroSwitch[US] == "TOM"
    areas=findall(ANMap[:,US] .== 1)
    #
    # We do not read US households from TOM (this will change); temporarily assign AEO households.
    #
    eccs=Select(ECC,(from="SingleFamilyDetached",to="OtherResidential"))
    for year in Years, area in areas, ecc in eccs
      xHHS[ecc,area,year]=xHHSAEO[ecc,area,year]
    end
    for year in Years, area in areas
      xTHHS[area,year]=sum(xHHS[ecc,area,year] for ecc in eccs)
    end
    #
    # Split TOM's US total population by housing type using AEO splits
    #
    for year in Years, area in areas, ecc in eccs
      @finite_math xPop[ecc,area,year]=xPopT[area,year]*
        (xPopAEO[ecc,area,year]/sum(xPopAEO[ectemp,area,year] for ectemp in eccs))
    end

    #
    # Split TOM's CN total population by housing type using household splits
    #
    CN=Select(Nation,"CN")
    areas=findall(ANMap[:,CN] .== 1)
    eccs=Select(ECC,(from="SingleFamilyDetached",to="OtherResidential"))
    for year in Years, area in areas, ecc in eccs
      @finite_math xPop[ecc,area,year]=xPopT[area,year]*
          (xHHS[ecc,area,year]/xTHHS[area,year])
    end

    @. xPopTOM=xPop

    WriteDisk(db,"MInput/xHHS",xHHS)
    WriteDisk(db,"MInput/xTHHS",xTHHS)
    WriteDisk(db,"MInput/xPop",xPop)
    WriteDisk(db,"MInput/xPopTOM",xPopTOM)

  # end

end

function CalibrationControl(db)
  @info "EconomicDrivers_ProcessTOM.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
