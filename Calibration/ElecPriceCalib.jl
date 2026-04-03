#
# ElecPriceCalib.jl for electric price calibration
#
using EnergyModel

module ElecPriceCalib

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  ClassDS::SetArray = ReadDisk(db,"MainDB/ClassDS")
  Classes::Vector{Int} = collect(Select(Class))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  ExportsPE::VariableArray{2} = ReadDisk(db,"EOutput/ExportsPE") # [Area,Year] Electric Exports Revenues per MWh ($/MWh)
  FPSMF::VariableArray{4} = ReadDisk(db,"SInput/FPSMF") # [Fuel,ES,Area,Year] Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db,"SInput/FPTaxF") # [Fuel,ES,Area,Year] Fuel Tax (Real $/mmBtu)
  PECalc::VariableArray{3} = ReadDisk(db,"EOutput/PECalc") # [ECC,Area,Year] Calculated Price of Electricity ($/MWh)
  PEClass::VariableArray{3} = ReadDisk(db,"EOutput/PEClass") # [Class,Area,Year] Price of Electricity ($/MWh)
  PEDC::VariableArray{3} = ReadDisk(db,"ECalDB/PEDC") # [ECC,Area,Year] Real Elect. Delivery Chg. ($/MWh)
  PPUC::VariableArray{2} = ReadDisk(db,"EOutput/PPUC") # [Area,Year] Unit Cost of Purchased Power ($/MWh)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xPE::VariableArray{3} = ReadDisk(db,"EInput/xPE") # [ECC,Area,Year] Historical Retail Electricity Price ($/MWh)
  xPEClass::VariableArray{3} = ReadDisk(db,"EInput/xPEClass") # [Class,Area,Year] Exogenous Retail Electricity Price (1985 $/MWH)
end

function ElecPriceCalibDataCalibration(db)
  data = EControl(; db)
  (;Areas,Classes,ECC,ECCs,ES) = data
  (;Fuel) = data
  (;EEConv,ExportsPE,FPSMF,FPTaxF,PECalc,PEClass,PEDC,PPUC) = data
  (;SecMap,xInflation,xPE,xPEClass) = data

  # 
  # Electric Price Calibation of Retail Differential Charge (PEDC)
  # 
  # Select the ECCs in residential (SecMap=1), commercial (SecMap=2),
  # industrial (SecMap=3), and transportation (SecMap=4) sectors.
  # 
  Future5=Last+5
  Future6=Last+6
  for area in Areas
    # 
    # Residential Electric Prices
    # 
    fuel = Select(Fuel,"Electric")
    eccs = findall(SecMap .== 1)
    es = Select(ES,"Residential")
    years = collect(First:Future5)
    for year in years, ecc in eccs
      PEDC[ecc,area,year] =
        (xPE[ecc,area,year]*xInflation[area,year]/(1+FPSMF[fuel,es,area,year])-
        (PPUC[area,year-1]-ExportsPE[area,year-1]+FPTaxF[fuel,es,area,year]))/
        xInflation[area,year]
    end

    # 
    # Commercial Electric Prices
    # 
    eccs = findall(SecMap .== 2)
    es = Select(ES,"Commercial")
    years = collect(First:Future5)
    for year in years, ecc in eccs
      PEDC[ecc,area,year] =
        (xPE[ecc,area,year]*xInflation[area,year]/(1+FPSMF[fuel,es,area,year])-
        (PPUC[area,year-1]-ExportsPE[area,year-1]+FPTaxF[fuel,es,area,year]))/
        xInflation[area,year]
    end
    
    # 
    # Industrial Electric Prices
    # 
    eccs = findall(SecMap .== 3)
    es = Select(ES,"Industrial")
    years = collect(First:Future5)
    for year in years, ecc in eccs
      PEDC[ecc,area,year] =
        (xPE[ecc,area,year]*xInflation[area,year]/(1+FPSMF[fuel,es,area,year])-
        (PPUC[area,year-1]-ExportsPE[area,year-1]+FPTaxF[fuel,es,area,year]))/
        xInflation[area,year]
    end
    
    # 
    # Transportation Electric Prices uses Commercial Price
    # 
    eccs = findall(SecMap .== 4)
    es = Select(ES,"Commercial")
    years = collect(First:Future5)
    for year in years, ecc in eccs
      PEDC[ecc,area,year] =
        (xPE[ecc,area,year]*xInflation[area,year]/(1+FPSMF[fuel,es,area,year])-
        (PPUC[area,year-1]-ExportsPE[area,year-1]+FPTaxF[fuel,es,area,year]))/
        xInflation[area,year]
    end

    # 
    # Hydrogen Production Prices use Industrial Price
    # 
    ecc = Select(ECC,"H2Production")
    es = Select(ES,"Industrial")
    years = collect(First:Future5)
    for year in years
      PEDC[ecc,area,year] = ((xPE[ecc,area,year]*xInflation[area,year]-
        FPTaxF[fuel,es,area,year]*EEConv/1000*xInflation[area,year])/(1+FPSMF[fuel,es,area,year])-
        PPUC[area,year-1]+ExportsPE[area,year-1])/xInflation[area,year]
    end
  end
  
  years = collect(Future6:Final)
  for year in years, area in Areas, ecc in ECCs
    PEDC[ecc,area,year] = PEDC[ecc,area,year-1]
  end
  
  # 
  # Fix up early years
  # 
  years = collect(First:Future5)
  for year in years, area in Areas, class in Classes
    PEClass[class,area,year] = xPEClass[class,area,year]*xInflation[area,year] 
  end

  years = collect(First:Future5)
  for year in years, area in Areas, ecc in ECCs 
    PECalc[ecc,area,year] = xPE[ecc,area,year]*xInflation[area,year]
  end
  
  WriteDisk(db,"EOutput/PECalc",PECalc)
  WriteDisk(db,"EOutput/PEClass",PEClass)
  WriteDisk(db,"ECalDB/PEDC",PEDC)
end

function CalibrationControl(db)
  @info "ElecPriceCalib.jl - CalibrationControl"

  ElecPriceCalibDataCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
