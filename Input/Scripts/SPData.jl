#
# SPData.jl
#
using EnergyModel

module SPData

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  GPDDSw::VariableArray{2} = ReadDisk(db,"SpInput/GPDDSw") #[Nation,Year] Switch to Adjust Gas Production (1=New & Existing, 2=New Only)
  GPGPrSw::VariableArray{2} = ReadDisk(db,"SInput/GPGPrSw") #[Market,Year] Natural Gas Production Intensity Based Gratis Permits Switch
  GPOPrSw::VariableArray{2} = ReadDisk(db,"SInput/GPOPrSw") #[Market,Year] Crude Oil Production Intensity Based Gratis Permits Switch
  GSElas::VariableArray{2} = ReadDisk(db,"SpInput/GSElas") #[Process,Nation] Gas Price Elasticity to Change Supply
  GSMSw::VariableArray{1} = ReadDisk(db,"SpInput/GSMSw") #[Year] Gas Supply Multiplier from Price Changes Switch
  GSPElas::VariableArray{1} = ReadDisk(db,"SpInput/GSPElas") #[Year] Gas Supply Elasticity to Change Prices
  GSPMSw::VariableArray{1} = ReadDisk(db,"SpInput/GSPMSw") #[Year] Gas Price Multiplier from Supply Changes Switch
  OIPElas::VariableArray{1} = ReadDisk(db,"SpInput/OIPElas") #[Year] Oil Import Price Elasticity
  OIPSw::VariableArray{1} = ReadDisk(db,"SpInput/OIPSw") #[Year] Oil Import Price Switch
  OPDDSw::VariableArray{2} = ReadDisk(db,"SpInput/OPDDSw") #[Nation,Year] Switch to Adjust Oil Production (1=New & Existing, 2=New Only)
  OSElas::VariableArray{2} = ReadDisk(db,"SpInput/OSElas") #[Process,Nation]  Oil Supply Elasticity
  OSMSw::VariableArray{1} = ReadDisk(db, "SpInput/OSMSw") # [Year] Oil Supply Multiplier Switch
  RPPASw::VariableArray{2} = ReadDisk(db,"SpInput/RPPASw") #[Area,Year] Refined Petroleum Products (RPP) Area Production Switch
  RPPSw::VariableArray{2} = ReadDisk(db,"SpInput/RPPSw") #[Area,Year] Refined Petroleum Products (RPP) Switch

end

function SPData_Inputs(db)
  data = SControl(; db)
  (; Nation,Process) = data
  (; GPDDSw,GPGPrSw,GPOPrSw,GSElas,GSMSw,GSPElas,GSPMSw) = data
  (; OIPElas,OIPSw,OPDDSw,OSElas,OSMSw,RPPASw,RPPSw) = data

  ########################
  # Gas and Oil Data
  ########################

  ########################
  # GPDDSw[Nation,Year] Switch to Adjust Gas Production (1=New & Existing, 2=New Only)
  #
  @. GPDDSw=0
  WriteDisk(db,"SpInput/GPDDSw",GPDDSw)

  ########################
  # GPDDSw[Market,Year] Natural Gas Production Intensity Based Gratis Permits Switch
  #
  # 0 = Permit Costs are not reflected in Marginal Production Costs
  # 1 = Gratis Permits are not Intensity Based so full Permit Cost in included in 
  #     Marginal Production Costs
  # 2 = Gratis Permits are Intensity Based so Permit Cost minus Gratis Permits are
  #     included in Marginal Production Costs
  #
  # Natural Gas Production Gratis Permits are not Intensity Based  (1=Not Intensity Based)
  #
  @. GPGPrSw=1
  WriteDisk(db,"SInput/GPGPrSw",GPGPrSw)

  ########################
  # GPOPrSw[Market,Year] Crude Oil Production Intensity Based Gratis Permits Switch
  #
  # 0 = Permit Costs are not reflected in Marginal Production Costs
  # 1 = Gratis Permits are not Intensity Based so full Permit Cost in included in 
  #     Marginal Production Costs
  # 2 = Gratis Permits are Intensity Based so Permit Cost minus Gratis Permits are
  #     included in Marginal Production Costs
  #
  # Crude Oil Production Gratis Permits are not Intensity Based  (1=Not Intensity Based)
  #
  @. GPOPrSw=1
  WriteDisk(db,"SInput/GPOPrSw",GPOPrSw)

  ########################
  # GPDDSw[Process,Nation] Gas Price Elasticity to Change Supply
  # GPDDSw[Year] Gas Supply Multiplier from Price Changes Switch
  #
  @. GSElas=1
  CN=Select(Nation,"CN")
  GSElas[:,CN] .= 0.40
  @. GSMSw=0
  WriteDisk(db,"SpInput/GSElas",GSElas)
  WriteDisk(db,"SpInput/GSMSw",GSMSw)

  ########################
  # GSPElas[Year] Gas Supply Elasticity to Change Prices
  # GSPMSw[Year] Gas Price Multiplier from Supply Changes Switch
  #
  @. GSPElas = -0.40
  @. GSPMSw=0
  WriteDisk(db,"SpInput/GSPElas",GSPElas)
  WriteDisk(db,"SpInput/GSPMSw",GSPMSw)

  ########################
  # GSPElas[Year] Gas Supply Elasticity to Change Prices
  # GSPMSw[Year] Gas Price Multiplier from Supply Changes Switch
  #
  @. GSPElas = -0.40
  @. GSPMSw=0
  WriteDisk(db,"SpInput/GSPElas",GSPElas)
  WriteDisk(db,"SpInput/GSPMSw",GSPMSw)

  ########################
  # OIPElas[Year] Oil Import Price Elasticity
  # OIPSw[Year] Oil Import Price Switch
  #
  # From "International Oil.doc" via G. Backus 11/29/01
  #
  @. OIPElas=15.0
  @. OIPSw=0
  WriteDisk(db,"SpInput/OIPElas",OIPElas)
  WriteDisk(db,"SpInput/OIPSw",OIPSw)

  ########################
  # OSElas[Process,Nation] Oil Supply Elasticity
  # OSMSw[Year] Oil Supply Multiplier Switch
  #
  # From AEO 2000 Appendix B and D
  #
  @. OSElas=1.0
  #
  # From Abha via George via Jeff
  #
  OSElas[:,CN] .= 1.0
  processes=Select(Process,["LightOilMining","HeavyOilMining","FrontierOilMining"])
  OSElas[processes,CN] .= 0.40
  processes=Select(Process,["PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders"])
  OSElas[processes,CN] .= .50
  #
  @. OSMSw=0
  WriteDisk(db,"SpInput/OSElas",OSElas)
  WriteDisk(db,"SpInput/OSMSw",OSMSw)

  ########################
  # OPDDSw[Nation,Year] Switch to Adjust Oil Production (1=New & Existing, 2=New Only)
  #
  @. OPDDSw=0
  WriteDisk(db,"SpInput/OPDDSw",OPDDSw)

  ########################
  # RPPASw[Area,Year] Refined Petroleum Products (RPP) Area Production Switch
  #
  @. RPPASw=0
  WriteDisk(db,"SpInput/RPPASw",RPPASw)

  ########################
  # RPPSw[Area,Year] Refined Petroleum Products (RPP) Switch
  #
  years=collect(First:Last)
  RPPSw[:,years] .= 0
  years=collect(Future:Final)
  RPPSw[:,years] .= 1

  WriteDisk(db,"SpInput/RPPSw",RPPSw)
  
end # end SPData_Inputs

function Control(db)
  SPData_Inputs(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end #end module
