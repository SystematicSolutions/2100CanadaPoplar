#
# HydrogenMarginalCost.jl
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

Base.@kwdef struct HydrogenMarginalCostData
  db::String
  
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))

  H2Tech::SetArray = ReadDisk(db, "MainDB/H2TechKey")
  H2TechDS::SetArray = ReadDisk(db, "MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))

  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Yr2016 = 2016 - 1985 + 1

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  eCO2Price::VariableArray{2} = ReadDisk(db, "SOutput/eCO2Price") # [Area,Year] Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ExchangeRate::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  H2CC::VariableArray{3} = ReadDisk(db, "SpOutput/H2CC") # [H2Tech,Area,Year] Hydrogen Production Capital Cost ($/mmBtu)
  H2CCM::VariableArray{3} = ReadDisk(db, "SpInput/H2CCM") # [H2Tech,Area,Year] Hydrogen Production Capital Cost Multiplier ($/$)
  H2CCR::VariableArray{3} = ReadDisk(db, "SpInput/H2CCR") # [H2Tech,Area,Year] Hydrogen Production Capital Charge Rate
  H2CUFP::VariableArray{3} = ReadDisk(db, "SpInput/H2CUFP") # [H2Tech,Area,Year] Hydrogen Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  H2ECFP::VariableArray{3} = ReadDisk(db, "SpOutput/H2ECFP") # [H2Tech,Area,Year] Fuel Prices for Hydrogen Production ($/mmBtu)
  H2Eff::VariableArray{3} = ReadDisk(db, "SpInput/H2Eff") # [H2Tech,Area,Year] Hydrogen Production Energy Efficiency (Btu/Btu)
  H2EI::VariableArray{3} = ReadDisk(db, "SpOutput/H2EI") # [H2Tech,Area,Year] Hydrogen Production GHG Emission Intensity (Tonnes eCO2/TBtu)
  H2EIDmd::VariableArray{3} = ReadDisk(db, "SpOutput/H2EIDmd") # [H2Tech,Area,Year] Hydrogen Production GHG Combustion Emission Intensity (Tonnes eCO2/TBtu)
  H2EIFs::VariableArray{3} = ReadDisk(db, "SpOutput/H2EIFs") # [H2Tech,Area,Year] Hydrogen Production GHG Feedstock Emission Intensity (Tonnes eCO2/TBtu)
  H2EmissionCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2EmissionCost") # [H2Tech,Area,Year] Hydrogen Emission Cost ($/mmBtu)
  H2FeedstockCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2FeedstockCost") # [H2Tech,Area,Year] Hydrogen Feedstock Cost ($/mmBtu)
  H2FOMCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2FOMCost") # [H2Tech,Area,Year] Hydrogen Fixed Production O&M Costs ($/mmBtu)
  H2FsPrice::VariableArray{3} = ReadDisk(db, "SpOutput/H2FsPrice") # [H2Tech,Area,Year] Hydrogen Feedstock Price ($/mmBtu)
  H2FsYield::VariableArray{3} = ReadDisk(db, "SpInput/H2FsYield") # [H2Tech,Area,Year] Hydrogen Yield From Feedstock (Btu/Btu)
  H2FuelCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2FuelCost") # [H2Tech,Area,Year] Hydrogen Fuel Cost ($/mmBtu)
  H2MCE::VariableArray{3} = ReadDisk(db, "SpOutput/H2MCE") # [H2Tech,Area,Year] Hydrogen Levelized Marginal Cost ($/mmBtu)
  H2OF::VariableArray{3} = ReadDisk(db, "SpInput/H2OF") # [H2Tech,Area,Year] Hydrogen Production O&M Cost Factor (Real $/$/Yr)
  H2PL::VariableArray{2} = ReadDisk(db, "SpInput/H2PL") # [H2Tech,Year] Hydrogen Production Physical Lifetime (Years)
  H2Prod::VariableArray{3} = ReadDisk(db, "SpOutput/H2Prod") # [H2Tech,Area,Year] Hydrogen Production (TBtu/Yr)
  H2Subsidy::VariableArray{2} = ReadDisk(db, "SpInput/H2Subsidy") # [Area,Year] Hydrogen Production Subsidy ($/mmBtu)
  H2Trans::VariableArray{3} = ReadDisk(db, "SpInput/H2Trans") # [H2Tech,Area,Year] Hydrogen Incremental Transmission Cost (Real $/mmBtu)
  H2TransCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2TransCost") # [H2Tech,Area,Year] Hydrogen Transmission Costs ($/mmBtu)
  H2VC::VariableArray{3} = ReadDisk(db, "SpOutput/H2VC") # [H2Tech,Area,Year] Hydrogen Variable Cost ($/mmBtu)
  H2VOMCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2VOMCost") # [H2Tech,Area,Year] Hydrogen Variable Production O&M Costs ($/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") # [Area] Descriptor for Monetary Units Type=String(15)
end


function HydrogenMarginalCost_DtaRun(data, TitleKey, TitleName, areas)
  (; SceName,Area,AreaDS,Areas,H2Tech,H2TechDS,H2Techs) = data
  (; Nation,NationDS,Nations,Year,Yr2016) = data
  (; ANMap,eCO2Price,ExchangeRate,H2CC,H2CCM,H2CCR) = data
  (; H2CUFP,H2ECFP,H2Eff,H2EI,H2EIDmd,H2EIFs,H2EmissionCost) = data
  (; H2FeedstockCost,H2FOMCost,H2FsPrice,H2FsYield,H2FuelCost) = data
  (; H2MCE,H2OF,H2PL,H2Prod,H2Subsidy,H2Trans,H2TransCost,H2VC) = data
  (; H2VOMCost,Inflation,MoneyUnitDS) = data

  iob = IOBuffer()

  H2ProdTot = zeros(Float32, length(H2Tech), length(Year))
  ZZZ = zeros(Float32, length(Year))

  area_single = first(areas)

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "This is the Hydrogen Marginal Cost of Energy Inputs and Outputs Summary.")
  println(iob, " ")

  years = collect(Yr(1990):Final)
  # year = Select(Year)  
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  for year in years, h2tech in H2Techs, area in areas
    H2Prod[h2tech,area,year] = max(H2Prod[h2tech,area,year],0.00001)
  end

  for h2tech in H2Techs

    for year in years
      H2ProdTot[h2tech,year] = sum(H2Prod[h2tech,area,year] for area in areas)
    end

    print(iob, TitleName, " ",H2TechDS[h2tech], " Hydrogen Cost Summary (",MoneyUnitDS[area_single],"2016/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(H2MCE[h2tech,area,year]/Inflation[area,year]*Inflation[area,Yr2016]-H2Subsidy[area,year]*Inflation[area,Yr2016] for area in areas)
    end
    print(iob, "H2FP;Delivered Price")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    
    #
    # Hydrogen Subsidy ($/mmBtu)
    #
    for year in years
      ZZZ[year] = sum(H2Subsidy[area,year]*Inflation[area,Yr2016] for area in areas)
    end
    print(iob, "H2Subsidy;Subsidy")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Delivery Charge ($/mmBtu)
    #
    for year in years
      ZZZ[year] = 0.0
    end
    print(iob, "  ;Delivery Charge")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Cost of Production ($/mmBtu)
    #  
    for year in years
      @finite_math ZZZ[year] = sum(H2MCE[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2MCE;Marginal Cost of Production")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Transmission Costs ($/mmBtu)
    #
    for year in years
      ZZZ[year] = sum(H2TransCost[h2tech,area,year]*Inflation[area,Yr2016] for area in areas)
    end
    print(iob, "H2TransCost;Hydrogen Transmission Costs")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Variable Cost ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2VC[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2VC;Variable Cost")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Cost ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2CC[h2tech,area,year]*H2CCR[h2tech,area,year]/H2CUFP[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2CC*H2CCR/H2CUFP;Levelized Capital Cost")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Cost ($/mmBtu/Yr)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2CC[h2tech,area,year]*H2CCR[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2CC*H2CCR;Charged Capital Cost")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Overnight Construction Cost ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2CC[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2CC;Overnight Capital Cost")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Cost Multiplier ($/$)'
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2CCM[h2tech,area,year]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2CCM;Capital Cost Trend")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Charge Rate (1/Yr)
    #
    for year in years
      ZZZ[year] = H2CCR[h2tech,area_single,year]
    end
    print(iob, "H2CCR;Capital Charge Rate (1/Yr)")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
    #
    for year in years
      ZZZ[year] = H2CUFP[h2tech,area_single,year]
    end
    print(iob, "H2CUFP;Capacity Utilization Factor (Btu H2/Btu H2);")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fixed O&M Cost ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2FOMCost[h2tech,area,year]/H2CUFP[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2FOMCost;Levelized Fixed O&M Cost")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Production O&M Cost Factor (Real $/$/Yr))
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2OF[h2tech,area,year]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2OF;O&M Cost Fraction of Capital Cost ((\$/Yr)/\$)")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Variable O&M Cost ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2VOMCost[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2VOMCost;Variable O&M Cost")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fuel Cost ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2FuelCost[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016] for area in areas)
    end
    print(iob, "H2FuelCost;Fuel Cost")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Production Energy Efficiency (Btu/Btu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2Eff[h2tech,area,year]*
      H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2Eff;Energy Efficiency (Btu H2/Btu Tech)")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fuel Price ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2ECFP[h2tech,area,year]/
      Inflation[area,year]*Inflation[area,Yr2016] for area in areas)
    end
    print(iob, "H2ECFP;  Average Fuel Price")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Feedstock Cost ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2FeedstockCost[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016] for area in areas)
    end
    print(iob, "H2FeedstockCost;NG Feedstock Cost")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Yield From Feedstock (Btu/Btu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2FsYield[h2tech,area,year] for area in areas)
    end
    print(iob, "H2FsYield;Yield From NG Feedstock (Btu H2/Btu NG)")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Feedstock Price ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2FsPrice[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016] for area in areas)
    end
    print(iob, "H2FsPrice;NG Feedstock Price")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Emission Cost ($/mmBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2EmissionCost[h2tech,area,year]/
        Inflation[area,year]*Inflation[area,Yr2016]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2EmissionCost;Emission Cost")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
    #
    for year in years
      @finite_math ZZZ[year] = sum(eCO2Price[area,year]/
        Inflation[area,year]*Inflation[area,Yr2016] for area in areas)
    end
    print(iob, "eCO2Price;Carbon Tax plus Permit Cost (", MoneyUnitDS[area_single],"2016/eCO2 Tonnes)")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Production GHG Emission Intensity (Tonnes eCO2/TBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2EI[h2tech,area,year]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2EI;GHG Emission Intensity (Tonnes eCO2/TBtu)")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Production GHG Combustion Emission Intensity (Tonnes eCO2/TBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2EIDmd[h2tech,area,year]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2EIDmd;GHG Combustion Emission Intensity (Tonnes eCO2/TBtu)")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Production GHG Feedstock Emission Intensity (Tonnes eCO2/TBtu)
    #
    for year in years
      @finite_math ZZZ[year] = sum(H2EIFs[h2tech,area,year]*
        H2Prod[h2tech,area,year] for area in areas)/H2ProdTot[h2tech,year]
    end
    print(iob, "H2EIFs;GHG NG Feedstock Emission Intensity (Tonnes eCO2/TBtu)")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Production Physical Lifetime (Years)
    #
    for year in years
      @finite_math ZZZ[year] = H2PL[h2tech,year]
    end
    print(iob, "H2PL;Physical Lifetime (Years)")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    println(iob, " ")

  end

  print(iob, TitleName, " Additional Variables;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    @finite_math ZZZ[year] = ExchangeRate[area_single,year]
  end
  print(iob, "ExchangeRate;Local Currency/US\$ Exchange Rate (Local/US\$)")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  println(iob, " ")

  filename = "HydrogenMarginalCost-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function HydrogenMarginalCost_DtaControl(db)
  @info "HydrogenMarginalCost_DtaControl"
  data = HydrogenMarginalCostData(; db)
  Area = data.Area
  AreaDS = data.AreaDS

  for area in Select(Area,(from ="ON", to="NU"))
    HydrogenMarginalCost_DtaRun(data, Area[area], AreaDS[area], area)
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
HydrogenMarginalCost_DtaControl(DB)
end

