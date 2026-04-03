#
# SpHydrogenInput.jl
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

Base.@kwdef struct SpHydrogenInputData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  H2Tech::SetArray = ReadDisk(db, "MainDB/H2TechKey")
  H2TechDS::SetArray = ReadDisk(db, "MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation

  H2CCM::VariableArray{3} = ReadDisk(db, "SpInput/H2CCM") # [H2Tech,Area,Year] Hydrogen Production Capital Cost Multiplier ($/$)
  H2CCN::VariableArray{3} = ReadDisk(db,"SpInput/H2CCN") # [H2Tech,Area,Year] Hydrogen Production Capital Cost (Real $/mmBtu)
  H2CCR::VariableArray{3} = ReadDisk(db, "SpInput/H2CCR") # [H2Tech,Area,Year] Hydrogen Production Capital Charge Rate
  H2CD::VariableArray{1} = ReadDisk(db,"SpInput/H2CD") # [Year] Hydrogen Production Construction Delay (Years)
  H2CUFMax::VariableArray{2} = ReadDisk(db,"SpInput/H2CUFMax") # [Area,Year] Hydrogen Production Capacity Utilization Factor Maximum (mmBtu/mmBtu)
  H2CUFP::VariableArray{3} = ReadDisk(db, "SpInput/H2CUFP") # [H2Tech,Area,Year] Hydrogen Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  H2DmFrac::VariableArray{4} = ReadDisk(db,"SpInput/H2DmFrac") # [Fuel,H2Tech,Area,Year] Hydrogen Production Energy Usage Fraction
  H2DemandMSM0::VariableArray{2} = ReadDisk(db,"SpInput/H2DemandMSM0") # [Nation] Hydrogen Domestic Demand Non-Price Factors ($/$)
  H2Eff::VariableArray{3} = ReadDisk(db,"SpInput/H2Eff") # [H2Tech,Area,Year] Hydrogen Production Energy Efficiency (Btu/Btu)
  H2ExportsCharge::VariableArray{2} = ReadDisk(db,"SpInput/H2ExportsCharge") # [Nation,Year] Hydrogen Exports Charge ($/mmBtu)
  H2ExportsMSM0::VariableArray{2} = ReadDisk(db,"SpInput/H2ExportsMSM0") # [Nation,Year] Hydrogen Exports Non-Price Factors ($/$)
  H2ExportsVF::VariableArray{2} = ReadDisk(db,"SpInput/H2ExportsVF") # [Nation,Year] Hydrogen Exports Variance Factors ($/$)
  H2FsFrac::VariableArray{4} = ReadDisk(db,"SpInput/H2FsFrac") # [Fuel,H2Tech,Area,Year] Hydrogen Feedstock Fuel/H2Tech Split (Btu/Btu)
  H2FsYield::VariableArray{3} = ReadDisk(db,"SpInput/H2FsYield") # [H2Tech,Area,Year] Hydrogen Yield From Feedstock (Btu/Btu)
  H2ImportsCharge::VariableArray{2} = ReadDisk(db,"SpInput/H2ImportsCharge") # [Nation,Year] Hydrogen Imports Charge ($/mmBtu)
  H2ImportsMSM0::VariableArray{2} = ReadDisk(db,"SpInput/H2ImportsMSM0") # [Nation,Year] Hydrogen Imports Non-Price Factors ($/$)
  H2ImportsVF::VariableArray{2} = ReadDisk(db,"SpInput/H2ImportsVF") # [Nation,Year] Hydrogen Imports Variance Factors ($/$)
  H2MSM0::VariableArray{3} = ReadDisk(db,"SpInput/H2MSM0") # [H2Tech,Area,Year] Hydrogen Market Share Non-Price Factor (mmBtu/mmBtu)
  H2OF::VariableArray{3} = ReadDisk(db,"SpInput/H2OF") # [H2Tech,Area,Year] Hydrogen Production O&M Cost Factor (Real $/$/Yr)
  H2PL::VariableArray{2} = ReadDisk(db,"SpInput/H2PL") # [H2Tech,Year] Hydrogen Production Physical Lifetime (Years)
  H2Production::VariableArray{2} = ReadDisk(db, "SpOutput/H2Production") # [Area,Year] Hydrogen Production (TBtu/Yr)
  H2SmT::VariableArray{1} = ReadDisk(db,"SpInput/H2SmT") # [Year] Hydrogen Production Growth Rate Smoothing Time (Years)
  H2Subsidy::VariableArray{2} = ReadDisk(db,"SpInput/H2Subsidy") # [Area,Year] Hydrogen Production Subsidy ($/mmBtu)
  H2SupplyMSM0::VariableArray{2} = ReadDisk(db,"SpInput/H2SupplyMSM0") # [Nation] Hydrogen Domestic Supply Non-Price Factors ($/$)
  H2Trans::VariableArray{3} = ReadDisk(db, "SpInput/H2Trans") # [H2Tech,Area,Year] Hydrogen Incremental Transmission Cost (Real $/mmBtu)
  H2UOMC::VariableArray{3} = ReadDisk(db,"SpInput/H2UOMC") # [H2Tech,Area,Year] Hydrogen Production Variable O&M Costs (Real $/mmBtu)
  H2VF::VariableArray{3} = ReadDisk(db,"SpInput/H2VF") # [H2Tech,Area,Year] Hydrogen Market Share Variance Factor (mmBtu/mmBtu)
  # Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  # PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # [Poll] Greenhouse Gas Coversion (eCO2 Tonnes/Tonnes)
  ZZZ = zeros(Float32, length(Year))
end

function SpHydrogenInput_DtaRun(data, areas, AreaName, AreaKey, nation)
  (; Area,AreaDS,Areas,Fuel,FuelDS,Fuels,H2Tech,H2TechDS,H2Techs) = data
  (; Nation,NationDS,Nations,Year) = data
  (; CDTime,CDYear,SceName,ANMap,H2CCM,H2CCN,H2CCR,H2CD,H2CUFMax,H2CUFP,H2DmFrac) = data
  (; H2DemandMSM0,H2Eff,H2ExportsCharge,H2ExportsMSM0,H2ExportsVF) = data
  (; H2FsFrac,H2FsYield,H2ImportsCharge,H2ImportsMSM0,H2ImportsVF,H2MSM0,H2OF,H2PL) = data
  (; H2Production,H2SmT,H2Subsidy,H2SupplyMSM0,H2Trans,H2UOMC,H2VF,ZZZ) = data
  
  years = collect(Yr(1990):Final)
  for year in years, area in areas
    H2Production[area,year] = max(H2Production[area,year],0.00001)
  end

  iob = IOBuffer()

  println(iob)
  println(iob, "$SceName; is the scenario name.")
  println(iob)
  println(iob, "This file was produced by SpHydrogenInput.jl")
  println(iob)
  println(iob, "Year;", ";", join(Year[years], ";"))
  println(iob)

  println(iob, "$AreaName Hydrogen Production Capital Cost Multiplier (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "H2CCM;Total")  
  for year in years
    ZZZ[year] = sum(H2CCM[h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2CCM;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2CCM[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Production Capital Cost (Real \$/mmBtu);;    ", join(Year[years], ";"))
  print(iob, "H2CCN;Total")  
  for year in years
    ZZZ[year] = sum(H2CCN[h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2CCN;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2CCN[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Production Capital Charge Rate;;    ", join(Year[years], ";"))
  print(iob, "H2CCR;Total")  
  for year in years
    ZZZ[year] = sum(H2CCR[h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2CCR;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2CCR[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Production Construction Delay (Years);;    ", join(Year[years], ";"))
  print(iob, "H2CD;Years")  
  for year in years
    ZZZ[year] = H2CD[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Production Growth Rate Smoothing Time (Years);;    ", join(Year[years], ";"))
  print(iob, "H2SmT;Years")  
  for year in years
    ZZZ[year] = H2SmT[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Production Capacity Utilization Factor Maximum (mmBtu/mmBtu);;    ", join(Year[years], ";"))
  print(iob, "H2CUFMax;")  
  for year in years
    ZZZ[year] = sum(H2CUFMax[area,year]*H2Production[area,year] for area in areas)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Production Capacity Utilization Factor for Planning (mmBtu/mmBtu);;    ", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "H2CUFP;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2CUFP[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Incremental Transmission Cost (Real \$/mmBtu);;    ", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "H2Trans;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2Trans[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Production Energy Usage Fraction (Btu/Btu);;    ", join(Year[years], ";"))
  print(iob, "H2DmFrac;Total")  
  for year in years
    ZZZ[year] = sum(H2DmFrac[fuel,h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs, fuel in Fuels)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2DmFrac;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2DmFrac[fuel,h2tech,area,year]*H2Production[area,year] for area in areas, fuel in Fuels)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Domestic Demand Non-Price Factors (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "H2DemandMSM0;$(NationDS[nation])")  
  for year in years
    ZZZ[year] = H2DemandMSM0[nation,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Production Energy Efficiency (Btu/Btu);;    ", join(Year[years], ";"))
  print(iob, "H2Eff;Total")  
  for year in years
    ZZZ[year] = sum(H2Eff[h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2Eff;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2Eff[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Exports Charge (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "H2ExportsCharge;$(NationDS[nation])")  
  for year in years
    ZZZ[year] = H2ExportsCharge[nation,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Exports Non-Price Factors (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "H2ExportsMSM0;$(NationDS[nation])")  
  for year in years
    ZZZ[year] = H2ExportsMSM0[nation,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Exports Variance Factors (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "H2ExportsVF;$(NationDS[nation])")  
  for year in years
    ZZZ[year] = H2ExportsVF[nation,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Feedstock Fuel/Tech Split (Btu/Btu);;    ", join(Year[years], ";"))
  for h2tech in H2Techs, fuel in Fuels
    print(iob, "H2FsFrac;$(H2TechDS[h2tech]) $(FuelDS[fuel])")  
    for year in years
      ZZZ[year] = sum(H2FsFrac[fuel,h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Yield From Feedstock (Btu/Btu);;    ", join(Year[years], ";"))
  print(iob, "H2FsYield;Total")  
  for year in years
    ZZZ[year] = sum(H2FsYield[h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2FsYield;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2FsYield[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Imports Charge (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "H2ImportsCharge;$(NationDS[nation])")  
  for year in years
    ZZZ[year] = H2ImportsCharge[nation,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Imports Non-Price Factors (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "H2ImportsMSM0;$(NationDS[nation])")  
  for year in years
    ZZZ[year] = H2ImportsMSM0[nation,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Imports Variance Factors (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "H2ImportsVF;$(NationDS[nation])")  
  for year in years
    ZZZ[year] = H2ImportsVF[nation,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Market Share Non-Price Factor (mmBtu/mmBtu);;    ", join(Year[years], ";"))
  print(iob, "H2MSM0;Total")  
  for year in years
    ZZZ[year] = sum(H2MSM0[h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2MSM0;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2MSM0[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Production Fixed O&M Cost Factor (\$/\$/Yr);;    ", join(Year[years], ";"))
  print(iob, "H2OF;Total")  
  for year in years
    ZZZ[year] = sum(H2OF[h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2OF;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2OF[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Production Variable O&M Cost (Real \$/mmBtu);;    ", join(Year[years], ";"))
  print(iob, "H2UOMC;Total")  
  for year in years
    ZZZ[year] = sum(H2UOMC[h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2UOMC;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2UOMC[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # TODO Possibly awkward selection of H2Tech. LJD, 25/09/08
  println(iob, "$AreaName Hydrogen Production Physical Lifetime (Years);;    ", join(Year[years], ";"))
  for h2tech in [1]
    print(iob, "H2PL;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = H2PL[h2tech,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Hydrogen Production Subsidy (\$/mmBtu);;    ", join(Year[years], ";"))
  print(iob, "H2Subsidy;")  
  for year in years
    ZZZ[year] = sum(H2Subsidy[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Domestic Supply Non-Price Factors (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "H2SupplyMSM0;$(NationDS[nation])")  
  for year in years
    ZZZ[year] = H2SupplyMSM0[nation,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName Hydrogen Market Share Variance Factor (mmBtu/mmBtu);;    ", join(Year[years], ";"))
  print(iob, "H2VF;Total")  
  for year in years
    ZZZ[year] = sum(H2VF[h2tech,area,year]*H2Production[area,year] for area in areas, h2tech in H2Techs)/
      sum(H2Production[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2VF;$(H2TechDS[h2tech])")  
    for year in years
      ZZZ[year] = sum(H2VF[h2tech,area,year]*H2Production[area,year] for area in areas)/
        sum(H2Production[area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  filename = "SpHydrogenInput-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function SpHydrogenInput_DtaControl(db)
  @info "SpHydrogenInput_DtaControl"
  data = SpHydrogenInputData(; db)
  (; ANMap,Area,AreaDS,Nation,Nations) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[Nations,CN] .== 1)
  SpHydrogenInput_DtaRun(data,areas,"Canada","CN",CN)
  for area in areas
    AreaName = AreaDS[area]
    AreaKey = Area[area]
    SpHydrogenInput_DtaRun(data,area,AreaName,AreaKey,CN)
  end

  US = Select(Nation,"US")
  areas = findall(ANMap[Nations,US] .== 1)
  # SpHydrogenInput_DtaRun(data,areas,"US","US",US)
  for area in areas
    AreaName = AreaDS[area]
    AreaKey = Area[area]
    SpHydrogenInput_DtaRun(data,area,AreaName,AreaKey,US)
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
SpHydrogenInput_DtaControl(DB)
end

