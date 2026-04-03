#
# TOM_IntensityReport_OilGasExtraction.jl - Summarizes transfers from E2020 to TOM:
#     Investments, electric prices, energy intensity, GDP, Personal Income
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

Base.@kwdef struct TOM_IntensityReport_OilGasExtractionData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db, "KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db, "KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db, "KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db, "KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelAggTOM::SetArray = ReadDisk(db,"KInput/FuelAggTOMKey")
  FuelAggTOMDS::SetArray = ReadDisk(db,"KInput/FuelAggTOMDS")
  FuelAggTOMs::Vector{Int} = collect(Select(FuelAggTOM))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMDS::SetArray = ReadDisk(db,"KInput/FuelTOMDS")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation

  Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  EIntE::VariableArray{4} = ReadDisk(db,"KOutput/EIntE") # [FuelTOM,ECCTOM,AreaTOM,Year] Energy Intensity (mmBtu/2017$M)
  GrossDemands::VariableArray{4} = ReadDisk(db,"KOutput/GrossDemands") # [Fuel,ECC,Area,Year]  Gross Energy Demands (TBtu/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelTOM") # [Fuel,FuelTOM] Map between Fuel and FuelTOM
  Qe::VariableArray{3} = ReadDisk(db,"KOutput/Qe") # [FuelAggTOM,AreaTOM,Year] Energy Production (TBtu/Yr)

  #
  # Scratch Variables
  #
  # EIntCalc::VariableArray{4} = zeros(Float32,length(FuelTOM),length(ECCTOM),length(AreaTOM),length(Year))
  GrossDemandsFuelTOM::VariableArray{4} = zeros(Float32,length(FuelTOM),length(ECC),length(Area),length(Year))
  ZZZ = zeros(Float32, length(Year))
end

function TOM_IntensityReport_OilGasExtraction_DtaRun(data, TitleKey, TitleName, areas, areatoms)
  (; SceName,Area,AreaDS,Areas,AreaTOM,AreaTOMDS,AreaTOMs,ECC,ECCDS,ECCs,ECCTOM,ECCTOMDS,ECCTOMs) = data
  (; Fuel,FuelDS,Fuels,FuelAggTOM,FuelAggTOMDS,FuelAggTOMs,FuelTOM,FuelTOMDS,FuelTOMs) = data
  (; Nation,NationDS,Nations,Year,Years) = data
  (; ANMap,Driver,EIntE,GrossDemands,MapAreaTOM,MapFuelTOM,Qe) = data
  (; GrossDemandsFuelTOM,ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "Summary Variable Transfers from ENERGY 2020 to TOM.")
  println(iob, " ")

  years = collect(Future:Final)
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  #
  # Exception: Oil and Gas industry driven by OG production, not gross output
  # Exclude OilSandsUpgraders, GasProcessing, and LNG production
  #
  eccs1 = Select(ECC,(from="LightOilMining",to="OilSandsMining"))
  eccs2 = Select(ECC,["ConventionalGasProduction","UnconventionalGasProduction"])
  eccs = union(eccs1,eccs2)
  ecctom = Select(ECCTOM,"OilGasExtraction")
  
  #
  # Gross Demands - OilGasExtraction
  #
  for year in years, area in areas, ecc in eccs, fueltom in FuelTOMs
    GrossDemandsFuelTOM[fueltom,ecc,area,year]=sum(GrossDemands[fuel,ecc,area,year]*MapFuelTOM[fuel,fueltom] for fuel in Fuels)
  end

  print(iob, "$TitleName OilGasExtraction Energy Demand (TBtu/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "GrossDemandsFuelTOM;Total")
  for year in years
    ZZZ[year] = sum(GrossDemandsFuelTOM[fueltom,ecc,area,year] for area in areas, ecc in eccs, fueltom in FuelTOMs)
    print(iob, ";", @sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for fueltom in FuelTOMs
    print(iob, "GrossDemandsFuelTOM;$(FuelTOM[fueltom])")
    for year in years
      ZZZ[year] = sum(GrossDemandsFuelTOM[fueltom,ecc,area,year] for area in areas, ecc in eccs)
      print(iob, ";", @sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Oil Gas Industry Driver
  #
  print(iob, "$TitleName Economic Driver (TBtu/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "Driver;Total")
  for year in years
    ZZZ[year] = sum(Driver[ecc,area,year] for area in areas, ecc in eccs)
    print(iob, ";", @sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob, "Driver;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(Driver[ecc,area,year] for area in areas)
      print(iob, ";", @sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  #
  # Model Value Energy Intensity
  #
  print(iob, "$TitleName OilGasExtraction Energy Intensity (TBtu/TBtu);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  for fueltom in FuelTOMs
    print(iob, "EIntE;$(FuelTOM[fueltom])")
    for year in years
      ZZZ[year] = sum(EIntE[fueltom,ecctom,areatom,year] for areatom in areatoms)
      print(iob, ";", @sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Energy Production
  #
  print(iob, "$TitleName Energy Production (TBtu/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  for fuelaggtom in FuelAggTOMs
    print(iob, "Qe;$(FuelAggTOMDS[fuelaggtom])")
    for year in years
      ZZZ[year] = sum(Qe[fuelaggtom,areatom,year] for areatom in areatoms)
      print(iob, ";", @sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # print(iob, "$TitleName OilGasExtraction Energy Demand (TBtu/Yr);")
  # for year in years
  #   print(iob, ";", Year[year])
  # end
  # println(iob)
  # print(iob, "GrossDemands;Total")
  # for year in years
  #   ZZZ[year] = sum(GrossDemands[fuel,ecc,area,year] for area in areas, ecc in eccs, fuel in Fuels)
  #   print(iob, ";", @sprintf("%15.4f", ZZZ[year]))
  # end
  # println(iob)
  # for fuel in Fuels
  #   print(iob, "GrossDemands;$(Fuel[fuel])")
  #   for year in years
  #     ZZZ[year] = sum(GrossDemands[fuel,ecc,area,year] for area in areas, ecc in eccs)
  #     print(iob, ";", @sprintf("%15.4f", ZZZ[year]))
  #   end
  #   println(iob)
  # end
  # println(iob)

  # print(iob, "MapFuelTOM;")
  # for fueltom in FuelTOMs
  #   print(iob, ";$(FuelTOM[fueltom])")
  # end
  # println(iob)
  # for fuel in Fuels
  #   print(iob, "MapFuelTOM;$(Fuel[fuel])")
  #   for fueltom in FuelTOMs
  #     print(iob, ";", @sprintf("%5.f", MapFuelTOM[fuel,fueltom]))
  #   end
  #   println(iob)
  # end
  # println(iob)


  filename = "TOM_IntensityReport_OilGasExtraction-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TOM_IntensityReport_OilGasExtraction_DtaControl(db)
  @info "TOM_IntensityReport_OilGasExtraction_DtaControl"
  data = TOM_IntensityReport_OilGasExtractionData(; db)
  (; Area, AreaDS, Areas, AreaTOM, AreaTOMDS, AreaTOMs, Nation) = data
  (; ANMap, MapAreaTOM) = data

  CN=Select(Nation,"CN")
  areatoms=Select(AreaTOM,(from="AB",to="YT"))
  for areatom in areatoms
    areas = findall(MapAreaTOM[Areas,areatom] .== 1)
    if !isempty(areas)
      area = first(areas)
      TOM_IntensityReport_OilGasExtraction_DtaRun(data, Area[area], AreaTOMDS[areatom], area, areatom)
    end
  end
  areas=findall(ANMap[Areas,CN] .== 1)
  TOM_IntensityReport_OilGasExtraction_DtaRun(data, "CN", "Canada", areas, areatoms)


  US=Select(Nation,"US")
  areatoms=Select(AreaTOM,(from="NEng",to="CA"))
  for areatom in areatoms
    areas = findall(MapAreaTOM[Areas,areatom] .== 1)
    if !isempty(areas)
      area = first(areas)
      TOM_IntensityReport_OilGasExtraction_DtaRun(data, Area[area], AreaTOMDS[areatom], area, areatom)
    end
  end
  areas=findall(ANMap[Areas,US] .== 1)
  TOM_IntensityReport_OilGasExtraction_DtaRun(data, "US", "US", areas, areatoms,)

end
if abspath(PROGRAM_FILE) == @__FILE__
TOM_IntensityReport_OilGasExtraction_DtaControl(DB)
end
