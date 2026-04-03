#
# EconomicDrivers_RestoreTOMValues.jl - Restore Future TOM Drivers for US Only (Overwrites AEO Growth)
#
########################
#
using EnergyModel

module EconomicDrivers_RestoreTOMValues

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MCalib
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  MacroSwitch::Vector{String} = ReadDisk(db,"MInput/MacroSwitch") #[Nation] String Indicator of Macroeconomic Forecast (TOM,Stokes,AEO,CER)
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xGOTOM::VariableArray{3} = ReadDisk(db,"MInput/xGOTOM") # [ECC,Area,Year] Gross Output (2017 M$/Yr)
  xGRP::VariableArray{2} = ReadDisk(db,"MInput/xGRP") # [Area,Year] Gross Regional Product (2017 $M/Yr)
  xGRPTOM::VariableArray{2} = ReadDisk(db,"MInput/xGRPTOM") # [Area,Year] Gross Regional Product from TOM (2017 $M/Yr)
  xHHS::VariableArray{3} = ReadDisk(db,"MInput/xHHS") # [ECC,Area,Year] Households (Households)
  xHHSTOM::VariableArray{3} = ReadDisk(db,"MInput/xHHSTOM") # [ECC,Area,Year] Households from TOM (Households)
  xPop::VariableArray{3} = ReadDisk(db,"MInput/xPop") # [ECC,Area,Year] Population (Millions)
  xPopTOM::VariableArray{3} = ReadDisk(db,"MInput/xPopTOM") # [ECC,Area,Year] Population by Household Type from TOM (Millions)
  xPopT::VariableArray{2} = ReadDisk(db,"MInput/xPopT") # [Area,Year] Population (Millions)
  xPopTTOM::VariableArray{2} = ReadDisk(db,"MInput/xPopTTOM") # [Area,Year] Population from TOM (Millions)
  xRPI::VariableArray{2} = ReadDisk(db,"MInput/xRPI") # [Area,Year] Total Personal Income (Real M$/Yr)
  xRPITOM::VariableArray{2} = ReadDisk(db,"MInput/xRPITOM") # [Area,Year] Total Personal Income from TOM (Real M$/Yr)
end

function MCalibration(db)
  data = MCalib(; db)
  (;ECCs,Nation) = data
  (;ANMap,MacroSwitch,xGO,xGOTOM,xGRP,xGRPTOM,xHHS,xHHSTOM,xPop,xPopTOM,xPopT) = data
  (;xPopTTOM,xRPI,xRPITOM) = data

  US = Select(Nation,"US")
  if MacroSwitch[US] == "TOM"
    areas = findall(ANMap[:,US] .== 1)
    years = collect(Future:Final)
    for year in years, area in areas
    
      xRPI[area,year] = xRPITOM[area,year]
      xPopT[area,year] = xPopTTOM[area,year]
      xGRP[area,year] = xGRPTOM[area,year]
      
      for ecc in ECCs
        # xHHS[ecc,area,year] = xHHSTOM[ecc,area,year]
        xPop[ecc,area,year] = xPopTOM[ecc,area,year]
        xGO[ecc,area,year] = xGOTOM[ecc,area,year]
      end
      
    end

    #
    # Do not overwrite US households until we read US households from TOM
    # 24/03/07
    #

    WriteDisk(db,"MInput/xGO",xGO)
    WriteDisk(db,"MInput/xGRP",xGRP)
    # WriteDisk(db,"MInput/xHHS",xHHS)
    WriteDisk(db,"MInput/xPop",xPop)
    WriteDisk(db,"MInput/xPopT",xPopT)  
    WriteDisk(db,"MInput/xRPI",xRPI)
     
  end
end

function CalibrationControl(db)
  @info "EconomicDrivers_RestoreTOMValues.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
