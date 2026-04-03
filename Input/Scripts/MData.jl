#
# MData.jl
#
using EnergyModel

module MData

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  CNArea::SetArray = ReadDisk(db,"MainDB/CNAreaKey")
  CNAreaDS::SetArray = ReadDisk(db,"MainDB/CNAreaDS")
  CNAreas::Vector{Int} = collect(Select(CNArea))
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
  CNAMap::VariableArray{2} = ReadDisk(db,"MInput/CNAMap") # [Area,CNArea] Map between Area and Canada Economic Areas (CNArea)
  DriverMultiplier::VariableArray{3} = ReadDisk(db,"MInput/DriverMultiplier") # [ECC,Area,Year] Economic Driver (Driver/Driver)
  DrSwitch::VariableArray{3} = ReadDisk(db,"MInput/DrSwitch") # [ECC,Area,Year] Economic Driver Switch
  INST::Float32 = ReadDisk(db,"MInput/INST")[1] # [tv] Inflation Rate Smooth Time (Years)
  GOMAT::VariableArray{3} = ReadDisk(db,"MInput/GOMAT") # [ECC,Area,Year] Adjustment Time for Gross Output Multiplier (Years)
  MacroSwitch::SetArray = ReadDisk(db,"MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TOM,Stokes,AEO,CER)
  MoneyUnitDS::SetArray = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  MPC::Float32 = ReadDisk(db,"MInput/MPC")[1] # [tv] Production Capacity of a Mature Industry (M$/Yr)
  PCMGR::VariableArray{1} = ReadDisk(db,"MInput/PCMGR") # [ECC] Maximum Growth Rate of Production Capacity ($/M$)
  YUPC::Float32 = ReadDisk(db,"MInput/YUPC")[1] # [tv] Upper Error Limit for PC (PERCENT)
  FSFraction::VariableArray{2} = ReadDisk(db,"MInput/FSFraction") # [ECC,Year] Fraction to Split Economic Model Floorspace into ENERGY 2100 Sectors (Sq Ft/Sq Ft)
  FSUnit::VariableArray{3} = ReadDisk(db,"MInput/FSUnit") # [ECC,Area,Year] Floorspace per Unit (Sq Ft/Building)
  MapOther::VariableArray{2} = ReadDisk(db,"MInput/MapOther") # [ECC,Year] Map for Economic Sectors to sum as Other (1=Include)

end

function MData_Inputs(db)
  data = MControl(; db)
  (; Area,Areas,CNArea,CNAreas,ECC,ECCs,Nation,Nations,Years) = data
  (; ANMap,CNAMap,DriverMultiplier,DrSwitch,INST,GOMAT,MacroSwitch) = data
  (; MoneyUnitDS,MPC,PCMGR,YUPC,FSFraction,FSUnit,MapOther) = data

  #
  ########################
  #
  # CNAMap[Area,CNArea] Map between Area and Canada Economic Areas (CNArea)
  #
  @. CNAMap = 0
  for area in Areas, cnarea in CNAreas
    if Area[area] == CNArea[cnarea]
      CNAMap[area,cnarea]=1
    end
  end
  TT=Select(CNArea,"TT")
  areas=Select(Area,["YT","NT","NU"])
  CNAMap[areas,TT] .= 1

  WriteDisk(db,"MInput/CNAMap",CNAMap)

  #
  ########################
  #
  # DriverMultiplier[ECC,Area,Year] Economic Driver (Driver/Driver)
  #
  @. DriverMultiplier=1
  WriteDisk(db,"MInput/DriverMultiplier",DriverMultiplier)

  #
  ########################
  #
  # INST[--] Inflation Rate Smooth Time (Years)
  #
  # The inflation smoothing time is the time required for a change
  # in inflation to affect the interest rates. This value was developed
  # by Jeff Amlin based on the interest and inflation rates.
  #
  INST=2.0
  WriteDisk(db,"MInput/INST",INST)

  #
  ########################
  #
  # GOMAT[ECC,Area,Year] Adjustment Time for Gross Output Multiplier (Years)
  #
  # @. GOMAT=5
  @. GOMAT=1
  WriteDisk(db,"MInput/GOMAT",GOMAT)

  #
  ########################
  #
  # MacroSwitch[Nation] String Indicator of Macroeconomic Forecast (TOM,Stokes,AEO,CER)
  #
  for nation in Nations
    MacroSwitch[nation]="None"
  end

  # Open TxtFile "MacroModel.tmp",Status=Old
  # Read TxtFile(MacroName)
  MacroName="TOM"
  # TODO Needs read statements.

  if MacroName == "TOM"
     MacroSwitch[Select(Nation,"US")] = "TOM"
     MacroSwitch[Select(Nation,"CN")] = "TOM"
     MacroSwitch[Select(Nation,"MX")] = "Exogenous"
     MacroSwitch[Select(Nation,"ROW")] = "N/A"
  else
     MacroSwitch[Select(Nation,"US")] = "Other"
     MacroSwitch[Select(Nation,"CN")] = "Other"
     MacroSwitch[Select(Nation,"MX")] = "Other"
     MacroSwitch[Select(Nation,"ROW")] = "Other"
  end

  WriteDisk(db,"MInput/MacroSwitch",MacroSwitch)

  #
  ########################
  #
  # MoneyUnitDS[Area] Descriptor for Monetary Units
  #
  areas=findall(ANMap[:,Select(Nation,"CN")] .== 1)
  for area in areas
    MoneyUnitDS[area]="CN\$"
  end

  areas=findall(ANMap[:,Select(Nation,"US")] .== 1)
  for area in areas
    MoneyUnitDS[area]="US\$"
  end

  area=Select(Area,"MX")
  MoneyUnitDS[area]="MX Pesos"
  WriteDisk(db,"MInput/MoneyUnitDS",MoneyUnitDS)


  #
  ########################
  #
  # Calibration - Flags, Switches, Limits, etc.
  #
  ########################
  #
  # MPC[--] Production Capacity of a Mature Industry (M$/Yr)
  #
  MPC=100
  WriteDisk(db,"MInput/MPC",MPC)

  #
  ########################
  #
  # PCMGR[ECC] Maximum Growth Rate of Production Capacity ($/M$)
  #
  # 1. This data is an estimation from numerous model runs.
  # 2. The residential and commercial max is set to 50 percent while the 
  #    industrial is 15 percent.
  # 3. Jeff Amlin 10/24/95
  #
  @. PCMGR=0.15
  eccs=Select(ECC,(from="SingleFamilyDetached",to="StreetLighting"))
  PCMGR[eccs] .= 0.50
  WriteDisk(db,"MInput/PCMGR",PCMGR)

  #
  ########################
  #
  # YUPC[--] Upper Error Limit for PC (PERCENT)
  #
  # 2. The data is assigned a value via an equation.
  # 3. Jeff Amlin 10/24/95
  #
  YUPC=0.1
  WriteDisk(db,"MInput/YUPC",YUPC)

  #
  ########################
  #
  # DrSwitch[ECC,Area,Year] Economic Driver Switch
  #
  # Default Driver is Gross Output (DrSwitch=21)
  #
  @. DrSwitch=21
  WriteDisk(db,"MInput/DrSwitch",DrSwitch)

  #
  ########################
  #
  # FSFraction[ECC,Year] Fraction to Split Economic Model Floorspace into ENERGY 2100 Sectors (Sq Ft/Sq Ft)
  #
  @. FSFraction=1.0
  #
  # Retail and Wholesale are combined in economic model. The combined total is read into both the
  # ENERGY 2100 Retail and Wholsale slots, then reduced using this fraction (FSFraction).
  # The Retail and Wholesale fractions use outputs from the industrial stock
  # floorspace database from Monique Brugger via Glasha Obrekht in Feb 2016
  #
  ecc=Select(ECC,"Retail")
  FSFraction[ecc,:].=0.9051
  ecc=Select(ECC,"Wholesale")
  FSFraction[ecc,:].=0.0949
  WriteDisk(db,"MInput/FSFraction",FSFraction)

  #
  ########################
  #
  # FSUnit[ECC,Area,Year] Floorspace per Unit (Sq Units/Building)
  #
  @. FSUnit=1
  WriteDisk(db,"MInput/FSUnit",FSUnit)

  #
  ########################
  #
  # Other Economic Categories
  # 
  # MapOther[ECC,Area] Map for Economic Sectors to sum as Other (1=Include)
  #
  @. MapOther=0
  WriteDisk(db,"MInput/MapOther",MapOther)

end # end MData_Inputs

function Control(db)
  MData_Inputs(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end #end module
