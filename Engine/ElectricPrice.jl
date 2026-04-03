#
# ElectricPrice.jl
#

module ElectricPrice

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,DT,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  Classes::Vector{Int} = collect(Select(Class))

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESes::Vector{Int} = collect(Select(ES))

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")

  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))

  PPSet::SetArray = ReadDisk(db,"EInput/PPSetKey")
  PPSets::Vector{Int} = collect(Select(PPSet))

  #
  ACE::VariableArray{2} = ReadDisk(db,"EOutput/ACE",year) #[Plant,GenCo,Year]  Average Cost of Power ($/MWh)
  DACost::VariableArray{1} = ReadDisk(db,"EOutput/DACost",year) #[Area,Year]  Direct Access Contract
  DCCost::VariableArray{1} = ReadDisk(db,"EOutput/DCCost",year) #[Area,Year]  Capacity Cost (M$/Yr)
  DVCost::VariableArray{1} = ReadDisk(db,"EOutput/DVCost",year) #[Area,Year]  Variable Cost (M$/Yr)
  ECCCLMap::VariableArray{2} = ReadDisk(db,"MainDB/ECCCLMap") #[ECC,Class]  Map Between ECC and Class (map)
  ECCPrMap::VariableArray{1} = ReadDisk(db,"EInput/ECCPrMap",year) #[ECC,Year]  Map between ECC and Sector for Electric Prices
  ECCRV::VariableArray{2} = ReadDisk(db,"EOutput/ECCRV",year) #[ECC,Area,Year]  Electricity Revenues (M$/Yr)
  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  EGA::VariableArray{2} = ReadDisk(db,"EGOutput/EGA",year) #[Plant,GenCo,Year]  Electricity Generated (GWh/Yr)
  EGBI::VariableArray{3} = ReadDisk(db,"EOutput/EGBI",year) #[Area,GenCo,Plant,Year]  Electricity sold thru Contracts (GWh/Yr)
  EGBIPG::VariableArray{1} = ReadDisk(db,"EOutput/EGBIPG",year) #[Area,Year]  Electricity sold thru Contracts (GWh/Yr)
  ElecPrSw::VariableArray{1} = ReadDisk(db,"SInput/ElecPrSw",year) #[Area,Year]  Electricity Price Switch (0 = Exogenous Prices)
  Exogenous::Float32 = ReadDisk(db,"MainDB/Exogenous")[1] # [tv] Exogenous = 0  
  ExportsPE::VariableArray{1} = ReadDisk(db,"EOutput/ExportsPE",year) #[Area,Year]  Electric Exports Unit Revenues in Price ($/MWh)
  ExportsRevenues::VariableArray{1} = ReadDisk(db,"SOutput/ExportsRevenues",year) #[Area,Year]  Electric Exports Revenues (M$/Yr)
  ExportsUR::VariableArray{1} = ReadDisk(db,"EOutput/ExportsUR",year) #[Area,Year]  Electric Exports Unit Revenues ($/MWh)
  ExportsURFraction::VariableArray{1} = ReadDisk(db,"EInput/ExportsURFraction",year) #[Area,Year]  Electric Exports Unit Revenues Flag (0 = exclude)

  FPBaseF::VariableArray{3} = ReadDisk(db,"SOutput/FPBaseF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price without Taxes ($/mmBtu)
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FPSMF::VariableArray{3} = ReadDisk(db,"SInput/FPSMF",year) #[Fuel,ES,Area,Year]  Energy Sales Tax ($/$)
  FPSMFNext::VariableArray{3} = ReadDisk(db,"SInput/FPSMF",next) # [Fuel,ES,Area,Year] Energy Sales Tax ($/$)
  FPTaxF::VariableArray{3} = ReadDisk(db,"SInput/FPTaxF",year) #[Fuel,ES,Area,Year]  Fuel Tax (Real $/mmBtu)
  FPTaxFNext::VariableArray{3} = ReadDisk(db,"SInput/FPTaxF",next) # [Fuel,ES,Area,Year] Fuel Tax (Real $/mmBtu)
  GPRefA::VariableArray{1} = ReadDisk(db,"SOutput/GPRefA",year) #[Area,Year]  Gratis Permit Electricity Refunds by Area (M$)
  GPURef::VariableArray{1} = ReadDisk(db,"EOutput/GPURef",year) #[Area,Year]  Gratis Permit Unit Refund ($/MWh)
  GRefSwitch::VariableArray{1} = ReadDisk(db,"EInput/GRefSwitch") #[Year]  Gratis Permits Refunded in Retail Prices Switch (1 = Yes)

  HMPrA::VariableArray{1} = ReadDisk(db,"EOutput/HMPrA",year) #[Area,Year]  Average Spot Market Price ($/MWh)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationNext::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",next) #[Area,Year]  Inflation Index ($/$)
  NPACNext::VariableArray{2} = ReadDisk(db,"EOutput/NPAC",next) #[ECC,Area,Year]  Non-Power Average Unit Cost ($/MWh)
  NPAddNext::VariableArray{2} = ReadDisk(db,"EOutput/NPAdd",next) #[ECC,Area,Year]  Non-Power Cost Additions (M$/Yr)
  NPCosts::VariableArray{2} = ReadDisk(db,"EOutput/NPCosts",year) #[ECC,Area,Year]  Non-Power Costs (M$/Yr)
  NPCostsNext::VariableArray{2} = ReadDisk(db,"EOutput/NPCosts",next) #[ECC,Area,Year]  Non-Power Costs (M$/Yr)
  NPICostsNext::VariableArray{2} = ReadDisk(db,"EOutput/NPICosts",next) #[ECC,Area,Year]  Non-Power Indicated Costs (M$/Yr)
  NPPL::VariableArray{1} = ReadDisk(db,"EInput/NPPL",year) #[Area,Year]  Non-Power Cost Lifetime (Years)
  NPRetireNext::VariableArray{2} = ReadDisk(db,"EOutput/NPRetire",next) #[ECC,Area,Year]  Non-Power Cost Retirements (M$/Yr)

  NPSwitchNext::VariableArray{1} = ReadDisk(db,"EInput/NPSwitch") #[Year]  Non-Power Costs Explicitly in Retail Price Switch (1=Yes)
  NPTime::Float32 = ReadDisk(db,"EInput/NPTime")[1] #[tv]  Non-Power Costs Endogenous Time (Year)

  NPUCNext::VariableArray{2} = ReadDisk(db,"ECalDB/NPUC",next) #[ECC,Area,Year]  Non-Power Marginal Unit Cost ($/MWh)
  PDP::VariableArray{2} = ReadDisk(db,"EOutput/PDP",year) #[Month,Area,Year]  Annual Peak Load
  PDPT::VariableArray{1} = ReadDisk(db,"EOutput/PDPT",year) #[Area,Year]  Total Peak Demand (MW)
  PDPTPrior::VariableArray{1} = ReadDisk(db,"EOutput/PDPT",prior) #[Area,Prior]  Total Peak Demand (MW)
  PE::VariableArray{2} = ReadDisk(db,"EOutput/PE",year) #[ECC,Area,Year]  Marketer Price of Electricity ($/MWh)
  PECalc::VariableArray{2} = ReadDisk(db,"EOutput/PECalc",year) #[ECC,Area,Year]  Calculated Price of Electricity ($/MWh)
  PECalcNext::VariableArray{2} = ReadDisk(db,"EOutput/PECalc",next) #[ECC,Area,Year]  Calculated Price of Electricity ($/MWh)
  PEClass::VariableArray{2} = ReadDisk(db,"EOutput/PEClass",year) #[Class,Area,Year]  Price of Electricity ($/MWh)
  PEDC::VariableArray{2} = ReadDisk(db,"ECalDB/PEDC",year) #[ECC,Area,Year]  Electric Delivery Charge ($/MWh)
  PEDCNext::VariableArray{2} = ReadDisk(db,"ECalDB/PEDC",next) #[ECC,Area,Year]  Electric Delivery Charge ($/MWh)
  PEDCSwitch::VariableArray{1} = ReadDisk(db,"EGInput/PEDCSwitch",year) #[Area,Year]  Switch to execute alternative PEDC calculation (1=execute)
  PEDmd::VariableArray{2} = ReadDisk(db,"SOutput/PE",year) #[ECC,Area,Year]  Price of Electricity for Demand Sector ($/MWh)
  PPCT::VariableArray{2} = ReadDisk(db,"EOutput/PPCT",year) #[PPSet,Area,Year]  Cost of Purchase Power (M$/Yr)
  PPEGA::VariableArray{2} = ReadDisk(db,"EOutput/PPEGA",year) #[PPSet,Area,Year]  Spot Market Purchases (GWh)
  PPUC::VariableArray{1} = ReadDisk(db,"EOutput/PPUC",year) #[Area,Year]  Unit Cost of Purchased Power ($/MWh)
  RECSwitchNext::Float32 = ReadDisk(db,"EInput/RECSwitch",next) #[Year]  Renewable Energy Credit (REC) in Retail Price Switch (1=Yes)
  Rev::VariableArray{1} = ReadDisk(db,"EOutput/Rev",year) #[Area,Year]  Revenue (M$/Yr)
  RnACENext::Float32 = ReadDisk(db,"EOutput/RnACE",next) #[Year]  Average Unit Cost of Renewable Power ($/MWh)
  RnCostsNext::VariableArray{1} = ReadDisk(db,"EOutput/RnCosts",next) #[Area,Year]  Renewable RECs Costs (M$/Yr)
  RnFrNext::VariableArray{1} = ReadDisk(db,"EGInput/RnFr",next) #[Area,Year]  Renewable Fraction (GWh/GWh)
  RnPE::VariableArray{1} = ReadDisk(db,"EOutput/RnPE",year) #[Area,Year]  RECs Contribution to Retail Price ($/MWh)
  RnPENext::VariableArray{1} = ReadDisk(db,"EOutput/RnPE",next) #[Area,Year]  RECs Contribution to Retail Price ($/MWh)
  RnRqNext::VariableArray{1} = ReadDisk(db,"EOutput/RnRq",next) #[Area,Year]  Renewable Purchases Required (GWh)
  RnSelfNext::VariableArray{1} = ReadDisk(db,"EOutput/RnSelf",next) #[Area,Year]  Renewable Purchases from Bilateral Contracts (GWh)
  RnSwitch::VariableArray{2} = ReadDisk(db,"EGInput/RnSwitch") #[Plant,Area]  Renewable Plant Type Switch (1=Renewable)
  RV::VariableArray{2} = ReadDisk(db,"EOutput/RV",year) #[Class,Area,Year]  Electricity Revenues (M$/Yr)
  SACL::VariableArray{2} = ReadDisk(db,"EOutput/SACL",year) #[Class,Area,Year]  Electricity Sales (GWh/Yr)
  SAEC::VariableArray{2} = ReadDisk(db,"EOutput/SAEC",year) #[ECC,Area,Year]  Electricity Sales (GWh/Yr)
  SaECD::VariableArray{2} = ReadDisk(db,"SOutput/SaEC",year) #[ECC,Area,Year]  Electricity Sales (GWh/Yr)
  SaECDPrior::VariableArray{2} = ReadDisk(db,"SOutput/SaEC",prior) #[ECC,Area,Year]  Electricity Sales (GWh/Yr)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets
  SICstFr::VariableArray{2} = ReadDisk(db,"EInput/SICstFr",year) #[Area,GenCo,Year]  Stranded Investment Cost Allocation Fraction ($/$)
  SICstG::VariableArray{1} = ReadDisk(db,"EOutput/SICstG",year) #[GenCo,Year]  Stranded Investment Cost by GenCo (M$/Yr)
  SICstPE::VariableArray{1} = ReadDisk(db,"EOutput/SICstPE",year) #[Area,Year]  Stranded Investment Cost in Retail Price ($/MWh)
  SICstR::VariableArray{1} = ReadDisk(db,"EOutput/SICstR",year) #[Area,Year]  Stranded Investment Cost by Area (M$/Yr)
  TSales::VariableArray{1} = ReadDisk(db,"EOutput/TSales",year) #[Area,Year]  Electricity Sales (GWh/Yr)
  UCConts::VariableArray{1} = ReadDisk(db,"EOutput/UCConts",year) #[Area,Year]  Unit Cost of Contracts ($/KW)
  UPURPP::VariableArray{1} = ReadDisk(db,"EOutput/UPURPP",year) #[Area,Year]  UNIT Cost OF PURCHASES
  xPE::VariableArray{2} = ReadDisk(db,"EInput/xPE",year) #[ECC,Area,Year]  Historical Retail Electricity Price (Real $/MWh)
  xPEDmd::VariableArray{2} = ReadDisk(db,"SInput/xPE",year) # [ECC,Area,Year]  Historical Price of Electricity ($/MWh)
end

#
# Page 1 - Electricity Price calculations at the start of each year
#

function TotalPeakDemands(data::Data)
  (; db, year, Area, Month) = data
  (; PDP, PDPT) = data

  # Calculate maximum peak demand across months for each area
  for area in Select(Area)
    PDPT[area] = maximum(PDP[month,area] for month in Select(Month))
  end

  WriteDisk(db,"EOutput/PDPT",year,PDPT)
end

function DeliveryCharge(data::Data)
  (; db,next,year) = data
  (; Area,Areas, ECC, ECCs) = data
  (; PEDCSwitch, PEDC, PEDCNext, PDPT, PDPTPrior) = data

  #
  # Alternative PEDC calculation
  # TODO Julia - I revised this code, but it needs to be tested
  # - Jeff Amlin 4/22/25
  #
  for area in Areas
    if PEDCSwitch[area] == 1
      for ecc in ECCs
        if PEDC[ecc,area] > 0
          #
          # Next year's peak load is not available, use previous year's growth ratio
          #
          @finite_math PEDCNext[ecc,area] = PEDC[ecc,area]*PDPT[area]/PDPTPrior[area]
        end
      end  
    end
  end
  WriteDisk(db,"ECalDB/PEDC",next,PEDCNext)    

end

function RetailCompanyPrices(data::Data)
  (; db,year) = data
  (; Areas,ECCs) = data #sets
  (; ElecPrSw,Exogenous,Inflation,PE,PECalc,xPE) = data

  for area in Areas, ecc in ECCs
    if ElecPrSw[area] != Exogenous
      PE[ecc,area] = PECalc[ecc,area]
    else
      PE[ecc,area] = xPE[ecc,area]*Inflation[area]
    end
  end

  WriteDisk(db,"EOutput/PE",year,PE)
end # function RetailCompanyPrices

function PricesForDemandSectors(data::Data)
  (; db,year) = data
  (; Areas,ECCs,ES) = data #sets
  (; ECCPrMap,PE,PEDmd) = data

  for area in Areas, ecc in ECCs
    PEDmd[ecc,area] = PE[ecc,area]
  end

  WriteDisk(db,"SOutput/PE",year,PEDmd)
end # function PricesForDemandSectors

function ExogenousPricesForDemandSectors(data::Data)
  (; db,year) = data
  (; Areas,ECCs) = data #sets
  (; ElecPrSw,Exogenous,Inflation,PEDmd,xPEDmd) = data

  for area in Areas, ecc in ECCs
    if ElecPrSw[area] == Exogenous
      PEDmd[ecc,area] = xPEDmd[ecc,area]*Inflation[area]
    end
  end

  WriteDisk(db,"SOutput/PE",year,PEDmd)
end # function ExogenousPricesForDemandSectors

function AssignElectricPricesToFuelPrices(data::Data)
  (; db,year) = data
  (; Areas,ES,ESes,Fuel) = data #sets
  (; EEConv,FPBaseF,FPF,FPSMF,FPTaxF) = data
  (; PEDmd,SaECDPrior,SecMap) = data

  @. SaECDPrior = max(SaECDPrior,0.001)

  fuel = Select(Fuel,"Electric")
  ess = Select(ES,(from = "Residential",to = "Transport"))
  for area in Areas, es in ess
    eccs = findall(SecMap .== es)
    FPF[fuel,es,area] = sum(PEDmd[ecc,area]*SaECDPrior[ecc,area] for ecc in eccs)/
                        sum(SaECDPrior[ecc,area] for ecc in eccs)/EEConv*1000
    FPBaseF[fuel,es,area] = FPF[fuel,es,area]/(1+FPSMF[fuel,es,area])-FPTaxF[fuel,es,area]
  end

  electric = Select(Fuel,"Electric")
  for area in Areas, es in ESes, fuel in Select(Fuel, ["Geothermal", "Solar"])
    FPF[fuel,es,area] = FPF[electric,es,area]
    FPBaseF[fuel,es,area] = FPBaseF[electric,es,area]
  end

  WriteDisk(db,"SOutput/FPF",year,FPF)
  WriteDisk(db,"SOutput/FPBaseF",year,FPBaseF)
end # function AssignElectricPricesToFuelPrices

function ElectricFuelPrices(data::Data)
  RetailCompanyPrices(data)
  PricesForDemandSectors(data)
  ExogenousPricesForDemandSectors(data)
  AssignElectricPricesToFuelPrices(data)
end # function ElectricFuelPrices


function Revenue(data::Data)
  (; db,year) = data
  (; Areas,Classes,ECCs) = data #sets
  (; ECCCLMap,ECCRV,PE,RV,Rev,SAEC) = data

  for area in Areas, ecc in ECCs
    ECCRV[ecc,area] = SAEC[ecc,area]*PE[ecc,area]/1000
  end

  for area in Areas, class in Classes
    RV[class,area] = sum(ECCRV[ecc,area]*ECCCLMap[ecc,class] for ecc in ECCs)
  end

  for area in Areas
    Rev[area] = sum(RV[class,area] for class in Classes)
  end

  WriteDisk(db,"EOutput/ECCRV",year,ECCRV)
  WriteDisk(db,"EOutput/Rev",year,Rev)
  WriteDisk(db,"EOutput/RV",year,RV)
end # function Revenue

function RetailCompanyIncome(data::Data)
  (; db,year) = data
  (; Areas,Classes) = data #sets
  (; PEClass,RV,SACL) = data

  Revenue(data)

  for area in Areas, class in Classes
    @finite_math PEClass[class,area] = RV[class,area]/SACL[class,area]*1000
  end

  WriteDisk(db,"EOutput/PEClass",year,PEClass)
end # function RetailCompanyIncome

function RefundGratisToCustomers(data::Data)
  (; db,year) = data
  (; Areas) = data #sets
  (; GPRefA,GPURef,GRefSwitch,TSales) = data

  #
  # 23.08.02, LJD: correct numerical format for "1"?
  #
  if GRefSwitch == 1
    for area in Areas
      @finite_math GPURef[area] = GPRefA[area]/TSales[area]*1000
    end
  else
    for area in Areas
      GPURef[area] = 0.0
    end
  end

  WriteDisk(db,"EOutput/GPURef",year,GPURef)
  
  #
  #23.08.02, LJD: moved Write Disk outside of the loop
  #
end

function RnGenerationFromSelfDealing(data::Data)
  (; db,next) = data
  (; Areas,GenCos,Plants) = data #sets
  (; EGBI,RnSelfNext,RnSwitch) = data

  #
  # 23.08.02, LJD: requires the RnSwitch in place of a promula select for only renewable plants
  #
  for area in Areas
    RnSelfNext[area] = sum(EGBI[area,genco,plant]*RnSwitch[area,plant] for genco in GenCos, plant in Plants)
  end

  WriteDisk(db,"EOutput/RnSelf",next,RnSelfNext)
end


function RenewableRequirement(data::Data)
  (; db,next) = data
  (; Areas,ECCs) = data #sets
  (; RnFrNext,RnRqNext,SAEC) = data

  for area in Areas
    RnRqNext[area] = sum(SAEC[ecc,area]*RnFrNext[area] for ecc in ECCs)
  end

  WriteDisk(db,"EOutput/RnRq",next,RnRqNext)
end

function RenewableAverageCost(data::Data)
  (; db) = data
  (; GenCos,Plants) = data #sets
  (; ACE,EGA,RnACENext,RnSwitch) = data

  #
  # 23.08.03, LJD: Investigate whether this works with the RnSwitch map.
  # RnACENext = sum(P,G)(ACE(P,G)*EGA(P,G))/sum(PP,GG)(EGA(PP,GG))
  #

  var1 = sum(ACE[genco,plant]*EGA[genco,plant]*RnSwitch[genco,plant] for plant in Plants, genco in GenCos)
  var2 = sum(EGA[genco,plant]*RnSwitch[genco,plant] for plant in Plants, genco in GenCos)
  @finite_math RnACENext=var1/var2


  WriteDisk(db,"EOutput/RnACE",RnACENext)
end

function RECsCosts(data::Data)
  (; db,next) = data
  (; Areas) = data #sets
  (; HMPrA,RnACENext,RnCostsNext,RnRqNext,RnSelfNext) = data

  for area in Areas
    RnCostsNext[area] = max(RnACENext-HMPrA[area],0.0)*max(RnRqNext[area]-RnSelfNext[area],0.0)
  end

  WriteDisk(db,"EOutput/RnCosts",next,RnCostsNext)
end

function FinalRECsPrice(data::Data)
  (; db,year,next) = data
  (; Areas) = data #sets
  (; RnCostsNext,RnPE,RnPENext,TSales) = data

  for area in Areas
    @finite_math RnPE[area] = RnCostsNext[area]/TSales[area]*1000
    RnPENext[area] = RnPE[area]
  end

  WriteDisk(db,"EOutput/RnPE",year,RnPE)
  WriteDisk(db,"EOutput/RnPE",next,RnPENext)
end

function RECSPrice(data::Data)
  (; db,next) = data
  (; Areas) = data #sets
  (; RECSwitchNext,RnPENext) = data

  if RECSwitchNext == 1
    # Renewable Plant Type selection moved within functions
    RnGenerationFromSelfDealing(data)
    RenewableRequirement(data)
    RenewableAverageCost(data)
    RECsCosts(data)
    FinalRECsPrice(data)
  else
    for area in Areas
      RnPENext[area] = 0.0
      WriteDisk(db,"EOutput/RnPE",next,RnPENext)
    end
  end
end # function RECSPrice

function IndicatedNonPowerCosts(data::Data)
  (; db,next) = data
  (; Areas,ECCs) = data #sets
  (; InflationNext,NPICostsNext,NPUCNext,SaEC) = data

  for area in Areas, ecc in ECCs
    NPICostsNext[ecc,area] = SaEC[ecc,area]*NPUCNext[ecc,area]*InflationNext[area]/1000
  end

  WriteDisk(db,"EOutput/NPICosts",next,NPICostsNext)
end

function UpdateNonPowerCostStock(data::Data)
  (; db,next) = data
  (; Areas,ECCs) = data #sets
  (; NPCosts,NPPL,NPRetireNext,NPAddNext,NPICostsNext) = data

  #
  # Non-Power Costs Retired (Depreciated)
  #

  for area in Areas, ecc in ECCs
    @finite_math NPRetireNext[ecc,area] = NPCosts[ecc,area]/NPPL[area]
  end

  WriteDisk(db,"EOutput/NPRetireNext",next,NPRetireNext)

  #
  # Non-Power Costs Added to Cost Basis
  #
  for ecc in ECCs, area in Areas
    NPAddNext[ecc,area]=max(NPICostsNext[ecc,area]-NPCosts[ecc,area],0)
  end
  #
  WriteDisk(db,"EOutput/NPAdd",next,NPAddNext)
end

function TotalNonPowerCosts(data::Data)
  (; db,year,next) = data
  (; Areas,ECCs) = data #sets
  (; NPAddNext,NPCosts,NPICostsNext,NPCostsNext,NPRetireNext,NPTime) = data

  if year > NPTime
    for area in Areas, ecc in ECCs
      NPCostsNext[ecc,area] = NPCosts[ecc,area]+NPAddNext[ecc,area]+NPRetireNext[ecc,area]
    end
  else
    for area in Areas, ecc in ECCs
      NPCostsNext[ecc,area] = NPICostsNext[ecc,area]
    end
  end

  WriteDisk(db,"EOutput/NPCosts",next,NPCostsNext)
end

function AverageNonPowerCosts(data::Data)
  (; db,year,next) = data
  (; Areas,ECCs) = data #sets
  (; NPACNext,NPCostsNext,SaEC) = data

  for area in Areas, ecc in ECCs
    @finite_math NPACNext[ecc,area] = NPCostsNext[ecc,area]/SaEC[ecc,area]*1000
  end

  WriteDisk(db,"EOutput/NPAC",next,NPACNext)
end

function NonPowerCosts(data::Data)
  (; db,next) = data
  (; Areas,ECCs) = data #sets
  (; NPACNext,NPSwitchNext) = data

  if NPSwitchNext[next] == 1
    IndicatedNonPowerCosts(data)
    UpdateNonPowerCostStock(data)
    TotalNonPowerCosts(data)
    AverageNonPowerCosts(data)
  else
    for area in Areas, ecc in ECCs
      NPACNext[ecc,area] = 0
    end
    WriteDisk(db,"EOutput/NPAC",next,NPACNext)
  end
end

function StrandedCostsByArea(data::Data)
  (; db,year) = data
  (; Areas,GenCos) = data #sets
  (; SICstFr,SICstG,SICstR) = data

  #
  #23.08.03, LJD: Renaming SICstR to SICstA seems appropriate
  #
  for area in Areas
    SICstR[area] = sum(SICstG[genco]*SICstFr[area,genco] for genco in GenCos)
  end

  WriteDisk(db,"EOutput/SICstR",year,SICstR)
end

function UnitStrandedCosts(data::Data)
  (; db,year) = data
  (; Areas) = data #sets
  (; SICstPE,SICstR,TSales) = data

  for area in Areas
    @finite_math SICstPE[area] = SICstR[area]/TSales[area]*1000
  end
  WriteDisk(db,"EOutput/SICstPE",year,SICstPE)
end

function StrandedInvestments(data::Data)
  StrandedCostsByArea(data)
  UnitStrandedCosts(data)
end

function ExportsUnitRevenues(data::Data)
  (; db,year) = data
  (; Areas,ECCs) = data #sets
  (; ExportsPE,ExportsRevenues,ExportsUR,ExportsURFraction,SaECD) = data

  for area in Areas
    @finite_math ExportsUR[area] = ExportsRevenues[area]/sum(SaECD[ecc,area] for ecc in ECCs)*1000
    ExportsPE[area] = ExportsUR[area]*ExportsURFraction[area]
  end
  WriteDisk(db,"EOutput/ExportsUR",year,ExportsUR)
  WriteDisk(db,"EOutput/ExportsPE",year,ExportsPE)

end

function FinalElectricPrice(data::Data)
  (; db,next) = data
  (; Areas,ECCs,ES,Fuel) = data #sets
  (; ECCPrMap,PECalcNext,PPUC,ExportsPE,NPACNext,RnPENext,SICstPE,GPURef,PEDCNext,InflationNext,FPTaxFNext,EEConv,FPSMFNext) = data

  #
  # Electricity Price (PECalc) is unit cost of purhcases (PPUC) plus
  # delivery charge (PEDC) less any gratis permit refunds (GPURef) plus
  # taxes (FPTax, FPSM).
  # Adjust to remove export revenues (ExportsPER) 03/15/2021 R.Levesque
  #
  ess = Select(ES,(from = "Residential",to = "Industrial"))
  for es in ess
    for area in Areas, ecc in ECCs, fuel in Select(Fuel, "Electric")
      if es == ECCPrMap[ecc]
        PECalcNext[ecc,area] = (PPUC[area]-ExportsPE[area]+NPACNext[ecc,area]+
        RnPENext[area]+SICstPE[area]-GPURef[area]+PEDCNext[ecc,area]*InflationNext[area]+
        FPTaxFNext[fuel,es,area]*InflationNext[area]*EEConv/1000)*(1+FPSMFNext[fuel,es,area])
      end
    end
  end

  WriteDisk(db,"EOutput/PECalc",next,PECalcNext)
end

function ElectricPrices(data::Data)
  
  #
  # Select Fuel(Electric) moved within functions
  #
  TotalPeakDemands(data)
  DeliveryCharge(data)
  RefundGratisToCustomers(data)
  RECSPrice(data)
  NonPowerCosts(data)
  StrandedInvestments(data)
  ExportsUnitRevenues(data)
  FinalElectricPrice(data)
end # function ElectricPrices


function SummaryContractCosts(data::Data)
  (; db,year) = data
  (; Areas) = data #sets
  (; DACost,DCCost,DVCost) = data

  for area in Areas
    DACost[area] = DVCost[area]+DCCost[area]
  end
  WriteDisk(db,"EOutput/DACost",year,DACost)
end

function UnitContractCosts(data::Data)
  (; db,year) = data
  (; Areas) = data #sets
  (; DCCost,DVCost,EGBIPG,UCConts) = data

  for area in Areas
    @finite_math UCConts[area] = (DCCost[area]+DVCost[area])/EGBIPG[area]*1000
  end

  WriteDisk(db,"EOutput/UCConts",year,UCConts)
end

function UnitPurchaseCosts(data::Data)
  (; db,year) = data
  (; Area,Areas,PPSets) = data #sets
  (; PPEGA,PPCT,UPURPP) = data

  SumPPEGA::VariableArray = zeros(Float32,length(Area))

  for area in Areas
    SumPPEGA[area] = sum(PPEGA[ppset,area] for ppset in PPSets)
    @finite_math UPURPP[area] = sum(PPCT[ppset,area] for ppset in PPSets)/SumPPEGA[area]*1000
  end

  WriteDisk(db,"EOutput/UPURPP",year,UPURPP)
end

function CreateSummaryVariables(data::Data)
  SummaryContractCosts(data)
  UnitContractCosts(data)
  UnitPurchaseCosts(data)
  TotalPeakDemands(data)
end # function CreateSummaryVariables

function Finance(data::Data)
  RetailCompanyIncome(data)
  ElectricPrices(data)
  CreateSummaryVariables(data)
end # function Finance

end # module ElectricPrice
