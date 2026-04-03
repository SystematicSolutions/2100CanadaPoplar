#
# SpBiofuel.jl
#

module SpBiofuel

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
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
  Biofuel::SetArray = ReadDisk(db,"MainDB/BiofuelKey")
  Biofuels::Vector{Int} = collect(Select(Biofuel))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESs::Vector{Int} = collect(Select(ES))
  Feedstock::SetArray = ReadDisk(db,"MainDB/FeedstockKey")
  Feedstocks::Vector{Int} = collect(Select(Feedstock))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"SInput/TechKey")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  BfCap::VariableArray{4} = ReadDisk(db,"SpOutput/BfCap",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Capacity (TBtu/Yr)
  BfCapPrior::VariableArray{4} = ReadDisk(db,"SpOutput/BfCap",prior) #[Biofuel,Tech,Feedstock,Area,Prior]  Biofuel Production Capacity (TBtu/Yr)
  BfCapCR::VariableArray{4} = ReadDisk(db,"SpOutput/BfCapCR",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Capacity Completion Rate (TBtu/Yr)
  BfCapI::VariableArray{4} = ReadDisk(db,"SpOutput/BfCapI",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Indicated Production Capacity (TBtu/Yr)
  BfCapRR::VariableArray{4} = ReadDisk(db,"SpOutput/BfCapRR",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Capacity Retirement Rate (TBtu/Yr)
  BfCC::VariableArray{4} = ReadDisk(db,"SpInput/BfCC",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Capital Cost (Real $/mmBtu)
  BfCCR::VariableArray{3} = ReadDisk(db,"SpInput/BfCCR",year) #[Biofuel,Feedstock,Area,Year]  Biofuel Production Capital Charge Rate
  BfCD::VariableArray{1} = ReadDisk(db,"SpInput/BfCD",year) #[Biofuel,Year]  Biofuel Production Construction Delay (Years)
  BfCUF::VariableArray{4} = ReadDisk(db,"SpOutput/BfCUF",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Capacity Utilization Factor (mmBtu/mmBtu)
  BfCUFMax::VariableArray{2} = ReadDisk(db,"SpInput/BfCUFMax",year) #[Biofuel,Area,Year]  Biofuel Production Capacity Utilization Factor Maximum (mmBtu/mmBtu)
  BfCUFP::VariableArray{2} = ReadDisk(db,"SpInput/BfCUFP",year) #[Biofuel,Area,Year]  Biofuel Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  BfDChg::VariableArray{2} = ReadDisk(db,"SpInput/BfDChg",year) #[ES,Area,Year]  Biofuel Delivery Charge (Real $/mmBtu)
  BfDChgNext::VariableArray{2} = ReadDisk(db,"SpInput/BfDChg",next) #[ES,Area,Year]  Biofuel Delivery Charge (Real $/mmBtu)
  BfDem::VariableArray{2} = ReadDisk(db,"SpOutput/BfDem",year) #[Biofuel,Area,Year]  Demand for Biofuel (TBtu/Yr)
  BfDemand::VariableArray{4} = ReadDisk(db,"SpOutput/BfDemand",year) #[Fuel,Biofuel,Feedstock,Area,Year]  Biofuel Production Energy Usage (TBtu/Yr)
  BfDemNation::VariableArray{2} = ReadDisk(db,"SpOutput/BfDemNation",year) #[Biofuel,Nation,Year]  National Demand for Biofuel (TBtu/Yr)
  BfDmd::VariableArray{4} = ReadDisk(db,"SpOutput/BfDmd",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Energy Usage (TBtu/Yr)
  BfDmFrac::VariableArray{3} = ReadDisk(db,"SpInput/BfDmFrac",year) #[Fuel,Tech,Area,Year]  Biofuel Production Energy Usage Fraction
  BfECFP::VariableArray{2} = ReadDisk(db,"SpOutput/BfECFP",year) #[Tech,Area,Year]  Fuel Prices for Biofuel Production ($/mmBtu)
  BfEff::VariableArray{4} = ReadDisk(db,"SpInput/BfEff",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Energy Efficiency (Btu/Btu)
  BfENPN::VariableArray{2} = ReadDisk(db,"SpOutput/BfENPN",year) #[Biofuel,Nation,Year]  Biofuel Wholesale Price ($/mmBtu)
  BfENPNNext::VariableArray{2} = ReadDisk(db,"SpOutput/BfENPN",next) #[Biofuel,Nation,Year]  Biofuel Wholesale Price ($/mmBtu)
  BfExportFraction::VariableArray{2} = ReadDisk(db,"SpInput/BfExportFraction",year) #[Biofuel,Nation,Year]  Biofuel Export Fraction (Btu/Btu)
  BfFsReq::VariableArray{4} = ReadDisk(db,"SpOutput/BfFsReq",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Feedstock Required (Tonnes/Year)
  BfFsPrice::VariableArray{2} = ReadDisk(db,"SpInput/BfFsPrice",year) #[Feedstock,Area,Year]  Biofuel Feedstock Price ($/Tonne)
  BfFsYield::VariableArray{4} = ReadDisk(db,"SpInput/BfFsYield",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Yield From Feedstock (Btu/Tonne)
  BfHRt::VariableArray{4} = ReadDisk(db,"SpInput/BfHRt",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Heat Rate (Btu/Btu)
  BfImportFraction::VariableArray{2} = ReadDisk(db,"SpInput/BfImportFraction",year) #[Biofuel,Nation,Year]  Biofuel Import Fraction (Btu/Btu)
  BfMCE::VariableArray{4} = ReadDisk(db,"SpOutput/BfMCE",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Levelized Marginal Cost ($/mmBtu)
  BfMCE0::VariableArray{4} = ReadDisk(db,"SpOutput/BfMCE",First) #[Biofuel,Tech,Feedstock,Area,First]  Biofuel Levelized Marginal Cost ($/mmBtu)
  BfMSF::VariableArray{4} = ReadDisk(db,"SpOutput/BfMSF",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Market Share (mmBtu/mmBtu)
  BfMSM0::VariableArray{4} = ReadDisk(db,"SpInput/BfMSM0",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Market Share Non-Price Factor (mmBtu/mmBtu)
  BfOF::VariableArray{4} = ReadDisk(db,"SpInput/BfOF",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production O&M Cost Factor (Real $/$/Yr)
  BfPL::Float32 = ReadDisk(db,"SpInput/BfPL",year) #[Year]  Biofuel Production Physical Lifetime (Years)
  BfPOCX::VariableArray{3} = ReadDisk(db,"SpInput/BfPOCX",year) #[FuelEP,Poll,Area,Year]  Biofuel Pollution Coefficient (Tonnes/TBtu)
  BfPol::VariableArray{4} = ReadDisk(db,"SpOutput/BfPol",year) #[FuelEP,Biofuel,Poll,Area,Year]  Biofuel Production Pollution (Tonnes/Yr)
  BfProd::VariableArray{4} = ReadDisk(db,"SpOutput/BfProd",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production (TBtu/Yr)
  BfProdFrac::VariableArray{3} = ReadDisk(db,"SpInput/BfProdFrac",year) #[Biofuel,Area,Nation,Year]  Biofuel Production as a Fraction of National Demands (Btu/Btu)
  BfProdNation::VariableArray{2} = ReadDisk(db,"SpOutput/BfProdNation",year) #[Biofuel,Nation,Year]  Biofuel Production (TBtu/Yr)
  BfProdTarget::VariableArray{2} = ReadDisk(db,"SpOutput/BfProdTarget",year) #[Biofuel,Area,Year]  Biofuel Production Target (TBtu/Yr)
  BfProdTargetN::VariableArray{2} = ReadDisk(db,"SpOutput/BfProdTargetN",year) #[Biofuel,Nation,Year]  Biofuel Production Target (TBtu/Yr)
  BfProduction::VariableArray{1} = ReadDisk(db,"SOutput/BfProduction",year) #[Area,Year]  Biofuel Production (TBtu/Yr)
  BfSubsidyNext::VariableArray{2} = ReadDisk(db,"SpInput/BfSubsidy",next) #[Biofuel,Nation,Year]  Biofuel Production Subsidy ($/mmBtu)
  BfUOMC::VariableArray{4} = ReadDisk(db,"SpInput/BfUOMC",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production O&M Costs (Real $/mmBtu)
  BfVC::VariableArray{4} = ReadDisk(db,"SpOutput/BfVC",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Variable Cost ($/mmBtu)
  BfVF::VariableArray{4} = ReadDisk(db,"SpInput/BfVF",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Market Share Variance Factor (mmBtu/mmBtu)
  CgCC::VariableArray{2} = ReadDisk(db,"SpInput/CgCC",year) #[Tech,Area,Year]  Cogeneration Capital Cost ($/mmBtu/Yr)
  CgCUF::VariableArray{2} = ReadDisk(db,"SpInput/CgCUF") #[Tech,Area]  Cogeneration Capacity Utilization Factor (Btu/Btu)
  CgDemand::VariableArray{3} = ReadDisk(db,"SOutput/CgDemand",year) #[Fuel,ECC,Area,Year]  Cogeneration Demands (TBtu/Yr)
  CgDmd::VariableArray{2} = ReadDisk(db,"SpOutput/CgDmd",year) #[Tech,Area,Year]  Cogeneration Energy Demand (TBtu/Yr)
  CgEC::VariableArray{2} = ReadDisk(db,"SOutput/CgEC",year) #[ECC,Area,Year]  Cogeneration by Economic Category (GWh/Yr)
  CgEG::VariableArray{2} = ReadDisk(db,"SpOutput/CgEG",year) #[Tech,Area,Year]  Electricity from Cogeneration (GWh/Yr)
  CgHRt::VariableArray{2} = ReadDisk(db,"SpOutput/CgHRt",year) #[Tech,Area,Year]  Cogeneration Heat Rate (Btu/KWh)
  CgGC::VariableArray{2} = ReadDisk(db,"SpOutput/CgGC",year) #[Tech,Area,Year]  Cogeneration Gen. Capacity (MW)
  CgGCCR::VariableArray{2} = ReadDisk(db,"SpOutput/CgGCCR",year) #[Tech,Area,Year]  Cogeneration Capacity Construction Rate (MW/Yr)
  CgGCI::VariableArray{2} = ReadDisk(db,"SpOutput/CgGCI",year) #[Tech,Area,Year]  Cogen. Indicated Gen. Cap. (MW)
  CgGCRR::VariableArray{2} = ReadDisk(db,"SpOutput/CgGCRR",year) #[Tech,Area,Year]  Cogeneration Capaciaty Retirements (MW/Yr)
  CgInv::VariableArray{2} = ReadDisk(db,"SOutput/CgInv",year) #[ECC,Area,Year]  Cogeneration Investments (M$/Yr)
  CgMSF::VariableArray{2} = ReadDisk(db,"SpInput/CgMSF",year) #[Tech,Area,Year]  Cogeneration Market Share (Btu/Btu)
  CgOF::VariableArray{2} = ReadDisk(db,"SpInput/CgOF") #[Tech,Area]  Cogeneration Operation Cost Fraction ($/Yr/$)
  CgOMExp::VariableArray{2} = ReadDisk(db,"SOutput/CgOMExp",year) #[ECC,Area,Year]  Cogeneration O&M Expenditures (M$)
  CgPL::VariableArray{2} = ReadDisk(db,"SpInput/CgPL") #[Tech,Area]  Cogeneration Equipment Lifetime (Years)
  CgPolBf::VariableArray{3} = ReadDisk(db,"SpOutput/CgPolBf",year) #[FuelEP,Poll,Area,Year]  Cogeneration Pollution in Biofuel Sector (Tonnes/Yr)
  CgPot::VariableArray{2} = ReadDisk(db,"SpOutput/CgPot",year) #[Tech,Area,Year]  Cogeneration Potential (MW)
  CgFPol::VariableArray{4} = ReadDisk(db,"SOutput/CgFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Cogeneration Pollution (Tonnes/Yr)
  CgPol::VariableArray{3} = ReadDisk(db,"SOutput/CgPol",year) #[ECC,Poll,Area,Year]  Cogeneration Pollution (Tonnes/Yr)
  DInv::VariableArray{2} = ReadDisk(db,"SOutput/DInv",year) #[ECC,Area,Year]  Device Investments (M$/Yr)
  DOMExp::VariableArray{2} = ReadDisk(db,"SOutput/DOMExp",year) #[ECC,Area,Year]  Device O&M Expenditures (M$)
  ENPNNext::VariableArray{2} = ReadDisk(db, "SOutput/ENPN", next)  # [Fuel,Nation] Wholesale Price ($/mmBtu)
  ENPNSwNext::VariableArray{2} = ReadDisk(db, "SInput/ENPNSw", next) # [Fuel,Nation] Wholesale Price (ENPN) Switch (1=Endogenous)
  EuFPol::VariableArray{4} = ReadDisk(db,"SOutput/EuFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Energy Pollution with Cogeneration (Tonnes/Yr)
  EuPol::VariableArray{3} = ReadDisk(db,"SOutput/EuPol",year) #[ECC,Poll,Area,Year]  Energy Related Pollution (Tonnes/Yr)
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) #[Fuel,ECC,Area,Year]  Enduse Energy Demands (TBtu/Yr)
  Exports::VariableArray{2} = ReadDisk(db,"SpOutput/Exports",year) #[FuelEP,Nation,Year]  Primary Exports (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FPFNext::VariableArray{3} = ReadDisk(db,"SOutput/FPF",next) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FuelExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/FuelExpenditures",year) #[ECC,Area,Year]  Fuel Expenditures (M$)
  FsDemand::VariableArray{3} = ReadDisk(db,"SOutput/FsDemand",year) #[Fuel,ECC,Area,Year]  Feedstock Demands (tBtu)
  GrElec::VariableArray{2} = ReadDisk(db,"SOutput/GrElec",year) #[ECC,Area,Year]  Gross Electric Usage (GWh)
  Imports::VariableArray{2} = ReadDisk(db,"SpOutput/Imports",year) #[FuelEP,Nation,Year]  Primary Imports (TBtu/Yr)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationNationNext::VariableArray{1} = ReadDisk(db, "MOutput/InflationNation", next) # [Nation] Inflation Index ($/$)
  InflationNext::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",next) #[Area,Year]  Inflation Index ($/$)
  MinPurF::VariableArray{2} = ReadDisk(db,"SInput/MinPurF",year) #[ECC,Area,Year]  Minimum Fraction of Electricity which is Purchased (GWh/GWh)
  OMExp::VariableArray{2} = ReadDisk(db,"SOutput/OMExp",year) #[ECC,Area,Year]  O&M Expenditures (M$)
  PInv::VariableArray{2} = ReadDisk(db,"SOutput/PInv",year) #[ECC,Area,Year]  Process Investments (M$/Yr)
  POMExp::VariableArray{2} = ReadDisk(db,"SOutput/POMExp",year) #[ECC,Area,Year]  Process O&M Expenditures (M$)
  PSoECC::VariableArray{2} = ReadDisk(db,"SOutput/PSoECC",year) #[ECC,Area,Year]  Power Sold to Grid (GWh)
  PurECC::VariableArray{2} = ReadDisk(db,"SOutput/PurECC",year) #[ECC,Area,Year]  Purchases from Electric Grid (GWh)
  SupplyAdjustments::VariableArray{2} = ReadDisk(db,"SpOutput/SupplyAdjustments",year) #[FuelEP,Nation,Year]  Oil and Gas Supply Adjustments (TBtu/Yr)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (TBtu/Yr)
  xExports::VariableArray{2} = ReadDisk(db,"SpInput/xExports",year) #[FuelEP,Nation,Year]  Primary Exports (TBtu/Yr)
  xImports::VariableArray{2} = ReadDisk(db,"SpInput/xImports",year) #[FuelEP,Nation,Year]  Primary Imports (TBtu/Yr)

  #
  # Scratch Variables
  #
  BfMAW::VariableArray{4} = zeros(Float32,length(Biofuel),length(Tech),length(Feedstock),length(Area)) # Biofuel Market Share Allocation Weight (mmBtu/mmBtu)
  BfTAW::VariableArray{2} = zeros(Float32,length(Biofuel),length(Area)) # Biofuel Market Share Total Allocation Weight (mmBtu/mmBtu)
end

############################
#
# Biofuel Demand
#
############################

function BiofuelDemand(data::Data)
  (; db,year) = data
  (; Biofuel,Biofuels,ECCs,Fuel,Fuels,Nations) = data
  (; ANMap,BfDem,BfDemNation,TotDemand) = data

  # @info "  SpBiofuel.jl - BiofuelDemand"

  for nation in Nations, fuel in Fuels, bf in Biofuels
    if Fuel[fuel] == Biofuel[bf]
      areas = findall(ANMap[:,nation] .== 1)
      for area in areas
        if ANMap[area,nation] == 1
          BfDem[bf,area] = sum(TotDemand[fuel,ecc,area] for ecc in ECCs)
        end
      end
      BfDemNation[bf,nation] = sum(BfDem[bf,area] for area in areas)
    end
  end

  WriteDisk(db,"SpOutput/BfDem",year,BfDem)
  WriteDisk(db,"SpOutput/BfDemNation",year,BfDemNation)

end

############################
#
# Biofuel Supply
#
############################

function EstimateImportsExports(data::Data)
  (; db,year) = data
  (; Biofuel,Biofuels,FuelEP,FuelEPs,Nations) = data
  (; BfDemNation,BfExportFraction,BfImportFraction,xExports,xImports) = data


  for nation in Nations, fuelep in FuelEPs, bf in Biofuels
    if FuelEP[fuelep] == Biofuel[bf]
      
      #
      # Enhance - make BfImportFraction a function of Import price versus Canada cost
      #
        xImports[fuelep,nation] = BfDemNation[bf,nation]*BfImportFraction[bf,nation]
        xExports[fuelep,nation] = BfDemNation[bf,nation]*BfExportFraction[bf,nation]
    end
  end

  WriteDisk(db,"SpInput/xExports",year,xExports)
  WriteDisk(db,"SpInput/xImports",year,xImports)

end

function ProductionTarget(data::Data)
  (; db,year) = data
  (; Biofuel,Biofuels,FuelEP,FuelEPs,Nations) = data
  (; ANMap,BfDemNation,BfProdFrac,BfProdTarget,BfProdTargetN,xExports,xImports) = data

  # @info "  SpBiofuel.jl - ProductionTarget"

  for nation in Nations, fuelep in FuelEPs, bf in Biofuels
    if FuelEP[fuelep] == Biofuel[bf]
      BfProdTargetN[bf,nation] = BfDemNation[bf,nation]-xImports[fuelep,nation]+xExports[fuelep,nation]

      areas = findall(ANMap[:,nation] .== 1)

      for area in areas
        if ANMap[area,nation] == 1
          BfProdTarget[bf,area] = BfProdTargetN[bf,nation]*BfProdFrac[bf,area,nation]
        end
      end
    end
  end

  WriteDisk(db,"SpOutput/BfProdTarget",year,BfProdTarget)
  WriteDisk(db,"SpOutput/BfProdTargetN",year,BfProdTargetN)

end

function FuelPrices(data::Data)
  (; db,year) = data
  (; Areas,ES,Fuels,Techs) = data
  (; BfECFP,BfDmFrac,FPF) = data

  # @info "  SpBiofuel.jl - FuelPrices"

  es = Select(ES,"Industrial")
  for area in Areas, tech in Techs
    BfECFP[tech,area] = sum(FPF[fuel,es,area]*BfDmFrac[fuel,tech,area] for fuel in Fuels)
  end

  #
  # CFS - need to increase BfECFP by EI times CFS credit price
  #
  WriteDisk(db,"SpOutput/BfECFP",year,BfECFP)

  # 
  #  CFS - need to add new variable which is BfFsPrice EI times CFS credit price
  # 


end

#
#
# CFS - add procedure for BfEff as a function of BfECFP plus EI times CFS credit price
# CFS - add equations for BfFsYield as a function of BfFsPrice plus EI times CFS credit price
#
#


function MarginalCost(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,Feedstocks,Techs) = data
  (; BfCC,BfCCR,BfCUFP,BfECFP,BfEff,BfFsPrice) = data
  (; BfFsYield,BfMCE,BfOF,BfVC,Inflation) = data

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    @finite_math BfVC[bf,tech,fs,area] = (BfCC[bf,tech,fs,area]*BfOF[bf,tech,fs,area])*Inflation[area]+BfECFP[tech,area]/BfEff[bf,tech,fs,area]+BfFsPrice[fs,area]/BfFsYield[bf,tech,fs,area]*1E6

    @finite_math BfMCE[bf,tech,fs,area] = BfCCR[bf,fs,area]*BfCC[bf,tech,fs,area]/BfCUFP[bf,area]*Inflation[area]+BfVC[bf,tech,fs,area]
  end

  WriteDisk(db,"SpOutput/BfMCE",year,BfMCE)
  WriteDisk(db,"SpOutput/BfVC",year,BfVC)

end

function MarketShare(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,Feedstocks,Techs) = data
  (; BfMCE,BfMCE0,BfMSF,BfMSM0,BfVF) = data
  (; BfMAW,BfTAW) = data

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    @finite_math BfMAW[bf,tech,fs,area] = exp(BfMSM0[bf,tech,fs,area]+BfVF[bf,tech,fs,area]*log(BfMCE[bf,tech,fs,area]/BfMCE0[bf,tech,fs,area]))
  end

  for area in Areas, bf in Biofuels
    BfTAW[bf,area] = sum(BfMAW[bf,tech,fs,area] for fs in Feedstocks, tech in Techs)
  end

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    @finite_math  BfMSF[bf,tech,fs,area] = BfMAW[bf,tech,fs,area]/BfTAW[bf,area]
  end

  WriteDisk(db,"SpOutput/BfMSF",year,BfMSF)

end

function CapacityIndicated(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,Feedstocks,Techs) = data
  (; BfCapI,BfCUFP,BfMSF,BfProdTarget) = data

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    @finite_math BfCapI[bf,tech,fs,area] = BfProdTarget[bf,area]*BfMSF[bf,tech,fs,area]/BfCUFP[bf,area]
  end

  WriteDisk(db,"SpOutput/BfCapI",year,BfCapI)

end

function CapacityRetirementRate(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,Feedstocks,Techs) = data
  (; BfCapPrior,BfCapRR,BfPL) = data

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    @finite_math BfCapRR[bf,tech,fs,area] = BfCapPrior[bf,tech,fs,area]/BfPL
  end

  WriteDisk(db,"SpOutput/BfCapRR",year,BfCapRR)

end

function CapacityCompletionRate(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,Feedstocks,Techs) = data
  (; BfCD,BfCapCR,BfCapI,BfCapPrior,BfCapRR) = data

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    @finite_math BfCapCR[bf,tech,fs,area] = max(0,BfCapI[bf,tech,fs,area]-BfCapPrior[bf,tech,fs,area]+BfCapRR[bf,tech,fs,area])/BfCD[bf]
  end

  WriteDisk(db,"SpOutput/BfCapCR",year,BfCapCR)

end

function ProductionCapacity(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,Feedstocks,Techs) = data
  (; BfCap,BfCapCR,BfCapPrior,BfCapRR) = data

  # @info "  SpBiofuel.jl - ProductionCapacity"

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    BfCap[bf,tech,fs,area] = BfCapPrior[bf,tech,fs,area]+DT*(BfCapCR[bf,tech,fs,area]-BfCapRR[bf,tech,fs,area])
  end

  WriteDisk(db,"SpOutput/BfCap",year,BfCap)

end

function Production(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,Feedstocks,Nations,Techs) = data
  (; ANMap,BfCap,BfCUF,BfCUFMax,BfCUFP,BfProd,BfProdNation,BfProduction) = data
  # BfCapTotal::VariableArray{2} = zeros(Float32,length(Biofuel),length(Area)) # Biofuel Production Total Capacity (TBtu/Yr)

  # for area in Areas, bf in Biofuels
  #   BfCapTotal[bf,area] = sum(BfCap[bf,tech,fs,area] for fs in Feedstocks, tech in Techs)
  # end

  # BfProd = min(BfCap*BfProdTarget/BfCapTotal,BfCap*BfCUFMax) # commented out in Promula

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    BfProd[bf,tech,fs,area] = min(BfCap[bf,tech,fs,area]*BfCUFP[bf,area],BfCap[bf,tech,fs,area]*BfCUFMax[bf,area])
  end

  for nation in Nations, bf in Biofuels
    BfProdNation[bf,nation] = sum(BfProd[bf,tech,fs,area]*ANMap[area,nation] for area in Areas, fs in Feedstocks, tech in Techs)
  end


  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    @finite_math BfCUF[bf,tech,fs,area] = BfProd[bf,tech,fs,area]/BfCap[bf,tech,fs,area]
  end

  for area in Areas
    BfProduction[area] = sum(BfProd[bf,tech,fs,area] for fs in Feedstocks, tech in Techs, bf in Biofuels)
  end

  WriteDisk(db,"SpOutput/BfCUF",year,BfCUF)
  WriteDisk(db,"SpOutput/BfProd",year,BfProd)
  WriteDisk(db,"SpOutput/BfProdNation",year,BfProdNation)
  WriteDisk(db,"SOutput/BfProduction",year,BfProduction)

end

function ImportsExports(data::Data)
  (; db,year,CTime) = data
  (; Biofuel,Biofuels,FuelEP,FuelEPs,Nation,Nations) = data
  (; BfDemNation,BfProdNation,Exports,Imports,SupplyAdjustments,xExports) = data

  for nation in Nations, fuelep in FuelEPs, bf in Biofuels
    if FuelEP[fuelep] == Biofuel[bf]
      Imports[fuelep,nation] = max(BfDemNation[bf,nation]-BfProdNation[bf,nation]+
        xExports[fuelep,nation]-SupplyAdjustments[fuelep,nation],0)
      Exports[fuelep,nation] = max(BfProdNation[bf,nation]-BfDemNation[bf,nation]+
        Imports[fuelep,nation]+SupplyAdjustments[fuelep,nation],0)
    end
  end

  WriteDisk(db,"SpOutput/Exports",year,Exports)
  WriteDisk(db,"SpOutput/Imports",year,Imports)

end

function EnergyUsage(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,ECC,Fuels,Feedstocks,Techs) = data
  (; BfDemand,BfDmd,BfDmFrac,BfEff,BfProd,EuDemand) = data

  ecc = Select(ECC,"BiofuelProduction")

  # @info "  SpBiofuel.jl - FeedstockRequired"

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    @finite_math BfDmd[bf,tech,fs,area] = BfProd[bf,tech,fs,area]/BfEff[bf,tech,fs,area]
  end

  for area in Areas, fs in Feedstocks, bf in Biofuels, fuel in Fuels
    BfDemand[fuel,bf,fs,area] = sum(BfDmd[bf,tech,fs,area]*BfDmFrac[fuel,tech,area] for tech in Techs)
  end

  for area in Areas, fuel in Fuels
    EuDemand[fuel,ecc,area] = sum(BfDemand[fuel,bf,fs,area] for fs in Feedstocks, bf in Biofuels)
  end

  #
  # Do not write to global variables to avoid double counting - Jeff Amlin 8/30/19
  #
  WriteDisk(db,"SpOutput/BfDemand",year,BfDemand)
  WriteDisk(db,"SpOutput/BfDmd",year,BfDmd)
  # WriteDisk(db,"SOutput/EuDemand",year,EuDemand)

  # 

end

function FeedstockRequired(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,ECC,Feedstocks,Techs) = data
  (; BfFsReq,BfFsYield,BfProd) = data

  ecc = Select(ECC,"BiofuelProduction")

  # @info "  SpBiofuel.jl - FeedstockRequired"

  for area in Areas, fs in Feedstocks, tech in Techs, bf in Biofuels
    @finite_math BfFsReq[bf,tech,fs,area] = BfProd[bf,tech,fs,area]/BfFsYield[bf,tech,fs,area]*1e9
  end

  #  Select Fuel(Biomass)
  #  FsDemand[fuel,ecc,area] = sum(Bf,Tech,Fs)(BfFsReq[bf,tech,fs,area])*Conversion
  #  Select Fuel*

  WriteDisk(db,"SpOutput/BfFsReq",year,BfFsReq)

end

function ProductionEmissions(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,ECC,Fuels,FuelEPs,Feedstocks,Polls) = data
  (; BfDemand,BfPOCX,BfPol,EuFPol,EuPol,FFPMap) = data

  ecc = Select(ECC,"BiofuelProduction")

  for area in Areas, poll in Polls, bf in Biofuels, fuelep in FuelEPs
  BfPol[fuelep,bf,poll,area] = sum(BfDemand[fuel,bf,fs,area]*FFPMap[fuelep,fuel] for fuel in Fuels, fs in Feedstocks)*
    BfPOCX[fuelep,poll,area]
  end

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EuFPol[fuelep,ecc,poll,area] = sum(BfPol[fuelep,bf,poll,area] for bf in Biofuels)
  end

  for area in Areas, poll in Polls
    EuPol[ecc,poll,area] = sum(EuFPol[fuelep,ecc,poll,area] for fuelep in FuelEPs)
  end

  #
  # Do not write to global variables to avoid double counting - Jeff Amlin 8/30/19
  #
  WriteDisk(db,"SpOutput/BfPol",year,BfPol)
  # WriteDisk(db,"SpOutput/EuFPol",year,EuFPol)
  # WriteDisk(db,"SpOutput/EuPol",year,EuPol)

end

function Cogeneration(data::Data)
  (; db,year) = data
  (; Areas,Biofuels,ECC,Fuel,Fuels,FuelEPs,Feedstocks,Polls,Techs) = data
  (; BfDmd,BfPOCX,CgCUF,CgDemand,CgDmd,CgEC,CgEG,CgFPol) = data
  (; CgGC,CgGCCR,CgGCI,CgGCRR,CgHRt,CgMSF,CgPL) = data
  (; CgPol,CgPolBf,CgPot,EuDemand,FFPMap,GrElec,MinPurF) = data
  (; PSoECC,PurECC) = data

  ecc = Select(ECC,"BiofuelProduction")

  #
  # Cogeneration Potential
  #
  for area in Areas, tech in Techs
    @finite_math CgPot[tech,area] = sum(BfDmd[bf,tech,fs,area] for fs in Feedstocks, bf in Biofuels)/
                                  CgHRt[tech,area]/8760*1000
  end

  WriteDisk(db,"SpOutput/CgPot",year,CgPot)

  #
  # Cogeneration Capacity Retirements
  #
  for area in Areas, tech in Techs
    @finite_math CgGCRR[tech,area] = CgGC[tech,area]/CgPL[tech,area]
  end

  WriteDisk(db,"SpOutput/CgGCRR",year,CgGCRR)

  #
  # Cogeneration Construction
  #
  for area in Areas, tech in Techs
    CgGCI[tech,area] = CgPot[tech,area]*CgMSF[tech,area]
    CgGCCR[tech,area] = max(CgGCI[tech,area]-CgGC[tech,area]+CgGCRR[tech,area],0)
  end

  WriteDisk(db,"SpOutput/CgGCCR",year,CgGCCR)
  WriteDisk(db,"SpOutput/CgGCI",year,CgGCI)

  #
  # Cogeneration Capacity
  #
  for area in Areas, tech in Techs
    CgGC[tech,area] = CgGC[tech,area]+DT*(CgGCCR[tech,area]-CgGCRR[tech,area])
  end

  WriteDisk(db,"SpOutput/CgGC",year,CgGC)

  #
  # Electric Generation from Cogeneration
  #
  for area in Areas, tech in Techs
    CgEG[tech,area] = CgGC[tech,area]*CgCUF[tech,area]*8760/1000
  end

  for area in Areas, tech in Techs
    CgEC[tech,area] = sum(CgEG[tech,area] for tech in Techs)
  end

  #
  # Do not write to global variables to avoid double counting - Jeff Amlin 8/30/19
  #
  # WriteDisk(db,"SpOutput/CgEG",year,CgEG)
  # WriteDisk(db,"SpOutput/CgEC",year,CgEC)

  #
  # Fuel Demands from Cogeneration
  #
  for area in Areas, tech in Techs
    CgDmd[tech,area] = CgEG[tech,area]*CgHRt[tech,area]/1E6
  end
  
  #
  # Do not write to global variables to avoid double counting - Jeff Amlin 8/30/19
  #
  # WriteDisk(db,"SpOutput/CgDemand",year,CgDemand)
  WriteDisk(db,"SpOutput/CgDmd",year,CgDmd)

  #
  # Gross Electric Usage
  #
  fuels = Select(Fuel,["Electric","Solar"])
  for area in Areas
    GrElec[ecc,area] = sum(EuDemand[fuel,ecc,area] for fuel in fuels)/3412*1e6
  end

  #
  # Do not write to global variables to avoid double counting - Jeff Amlin 8/30/19
  #
  # WriteDisk(db,"SpOutput/GrElec",year,GrElec)

  #
  # Purchase from Electric Grid
  #
  for area in Areas
    PurECC[ecc,area] = max(GrElec[ecc,area]-CgEC[ecc,area],GrElec[ecc,area]*MinPurF[ecc,area])
  end
  
  #
  # Do not write to global variables to avoid double counting - Jeff Amlin 8/30/19
  #
  # WriteDisk(db,"SpOutput/PurECC",year,PurECC)

  #
  # Power Sold back to Grid
  #
  for area in Areas
    PSoECC[ecc,area] = max(CgEC[ecc,area]+PurECC[ecc,area]-GrElec[ecc,area],0)
  end
  
  #
  # Do not write to global variables to avoid double counting - Jeff Amlin 8/30/19
  #
  # WriteDisk(db,"SpOutput/PSoECC",year,PSoECC)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    CgPolBf[fuelep,poll,area] = sum(CgDemand[fuel,ecc,area]*FFPMap[fuelep,fuel] for fuel in Fuels)*
                                        BfPOCX[fuelep,poll,area]
    CgFPol[fuelep,ecc,poll,area] = CgPolBf[fuelep,poll,area]
  end

  for area in Areas, poll in Polls
    CgPol[ecc,poll,area] = sum(CgFPol[fuelep,ecc,poll,area] for fuelep in FuelEPs)
  end
  
  #
  # Do not write to global variables to avoid double counting - Jeff Amlin 8/30/19
  #
  WriteDisk(db,"SpOutput/CgPolBf",year,CgPolBf)
  
  # WriteDisk(db,"SpOutput/CgFPol",year,CgFPol)
  # WriteDisk(db,"SpOutput/CgPol",year,CgPol)

end

#
# CFS - add EI calculations by Fuel, Biofuel, Feedstock combinations for each Area
# CFS - add EI calculation for average by Biofuel for each Area
# CFS - map Areas without Biofuel Production to Areas with Biofuel Production
# CFS - deteremine roll of national EI and import EI
#

function Investments(data::Data)

  #
  # Currently, no equations in this function are run with meaning in Promula.
  #
  
  #
  # Read Disk(CgInv,CgOMExp,DInv,DOMExp,FuelExpenditures,
  # OMExp,PInv,POMExp)
  # 
  #  Device Investments
  # 
  # DInv(ECC,Area)=0.0
  # 
  #  Device O&M Expenditures
  # 
  # DOMExp(ECC,Area)=0.0
  # 
  #  Process Investments
  # 
  # PInv(ECC,Area)=sum(Bf,Tech,Fs)(BfCapCR[bf,tech,fs,area]*
  #                        BfCC[bf,tech,fs,area]*Inflation(Area))
  # 
  #  Process O&M Expenditures
  # 
  # POMExp(ECC,Area)=sum(Bf,Tech,Fs)(BfCC[bf,tech,fs,area]*
  #                          BfUOMC[bf,tech,fs,area]*Inflation(Area))
  # 
  #  Cogeneration Investments
  # 
  # CgInv(ECC,Area)=sum(Tech)(CgCC[tech,area]*CgGCCR[tech,area]*
  #                   CgHRt[tech,area]*8760*Inflation(Area)/1e9)
  # 
  #  Cogeneration O&M Expenditures
  # 
  # CgOMExp(ECC,Area)=sum(Tech)(CgCC[tech,area]*CgOF[tech,area])*Inflation(Area)
  # 
  #  O&M Expenditures
  # 
  # OMExp=DOMExp+POMExp+CgOMExp
  # 
  #  Fuel Expenditures
  # 
  # FuelExpenditures(ECC,Area)=sum(Tech)((sum(Bf,Fs)(BfDmd[bf,tech,fs,area])+
  #                               CgDmd[tech,area])*BfECFP[tech,area])
  # 
  # 
  #  Do not write to global variables to avoid double counting - Jeff Amlin 8/30/19
  # 
  # Write Disk(CgInv,CgOMExp,DInv,DOMExp,FuelExpenditures,
  #            OMExp,PInv,POMExp)
  # 

end

function SupplyBiofuel(data::Data)
  # @info "  SpBiofuel.jl - SupplyBiofuel"

  BiofuelDemand(data)

  EstimateImportsExports(data)
  ProductionTarget(data)

  FuelPrices(data)
  MarginalCost(data)
  MarketShare(data)

  CapacityIndicated(data)
  CapacityRetirementRate(data)
  CapacityCompletionRate(data)
  ProductionCapacity(data)
  Production(data)
  ImportsExports(data)
  EnergyUsage(data)
  FeedstockRequired(data)
  ProductionEmissions(data)
  Cogeneration(data)
  
  #
  # Investments(data)
  #
end # function SupplyBiofuel

function WholesalePrice(data::Data)
  (; db,next) = data
  (; Biofuel, Biofuels, Fuel, Fuels, Nations, Tech, Techs, Feedstock, Feedstocks) = data
  (; ANMap, BfENPNNext, BfMCE, BfProd, BfSubsidyNext, ENPNNext, ENPNSwNext, InflationNationNext) = data

  for nation in Nations, bf in Biofuels, fuel in Fuels
    if Fuel[fuel] == Biofuel[bf]
      areas = findall(ANMap[:, nation] .== 1.0)
      if !isempty(areas)
        # Calculate weighted average marginal cost
        numer = sum(BfMCE[bf, tech, fs, area] * BfProd[bf, tech, fs, area]
                    for tech in Techs, fs in Feedstocks, area in areas)
        denom = sum(BfProd[bf, tech, fs, area]
                    for tech in Techs, fs in Feedstocks, area in areas)

        @finite_math BfENPNNext[bf, nation] = numer / denom - BfSubsidyNext[bf, nation]

        # Handle endogenous price switch
        if ENPNSwNext[fuel, nation] == 1
          @finite_math ENPNNext[fuel, nation] = BfENPNNext[bf, nation] / InflationNationNext[nation]
        end
      end
    end
  end

  WriteDisk(db, "SOutput/ENPN", next, ENPNNext)
  WriteDisk(db, "SpOutput/BfENPN", next, BfENPNNext)
end # function WholesalePrice

function RetailPrice(data::Data)
  (; db, next) = data
  (; Biofuel, Biofuels, ES, ESs, Fuel, Fuels, Nations) = data
  (; ANMap, BfENPNNext, BfDChgNext, ENPNSwNext, FPFNext, InflationNext) = data

  for nation in Nations, bf in Biofuels, fuel in Fuels
    if Fuel[fuel] == Biofuel[bf]
      areas = findall(ANMap[:, nation] .== 1)
      for area in areas, es in ESs
        # Only update prices if endogenous switch is on
        if ENPNSwNext[fuel, nation] == 1 && ANMap[area, nation] == 1
          @finite_math FPFNext[fuel, es, area] = BfENPNNext[bf, nation] +
                                                 BfDChgNext[es, area] * InflationNext[area]
        end
      end
    end
  end

  # Commented out as per original code
  # WriteDisk(db,"SOutput/FPF",next,FPFNext)
end # function RetailPrice

function PriceBiofuel(data::Data)
  # @info "  SpBiofuel.jl - PriceBiofuel"

  WholesalePrice(data)
  RetailPrice(data)

end # function PriceBiofuel

end # module SpBiofuel
