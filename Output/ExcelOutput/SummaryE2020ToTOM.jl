#
# SummaryE2020ToTOM.txo - Summarizes transfers from E2020 to TOM:
#                        Investments, electric prices, energy intensity, GDP, Personal Income
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SummaryE2020ToTOMData
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECCTOM::SetArray = ReadDisk(db, "KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db, "KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  FuelAggTOM::SetArray = ReadDisk(db,"KInput/FuelAggTOMKey")
  FuelAggTOMDS::SetArray = ReadDisk(db,"KInput/FuelAggTOMDS")
  FuelAggTOMs::Vector{Int} = collect(Select(FuelAggTOM))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PriceTOM::SetArray = ReadDisk(db,"KInput/PriceTOMKey")
  PriceTOMDS::SetArray = ReadDisk(db,"KInput/PriceTOMDS")
  PriceTOMs::Vector{Int} = collect(Select(PriceTOM))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  VehicleTOMDS::SetArray = ReadDisk(db,"KInput/VehicleTOMDS")
  VehicleTOMs::Vector{Int} = collect(Select(VehicleTOM))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  CD_NRG::VariableArray{2} = ReadDisk(db,"KOutput/CD_NRG") # [AreaTOM,Year] E2020 Household Consumption, Energy Durables, Policy Driven (2017 $M/Yr)
  CD_Tra::VariableArray{2} = ReadDisk(db,"KOutput/CD_Tra") # [AreaTOM,Year] E2020 Household Consumption, Transportation Durables, Policy Driven (2017 $M/Yr)
  EIntE::VariableArray{4} = ReadDisk(db,"KOutput/EIntE") # [FuelTOM,ECCTOM,AreaTOM,Year] Energy Intensity (mmBtu/2017$M)
  EIntETr::VariableArray{4} = ReadDisk(db,"KOutput/EIntETr") # [FuelTOM,VehicleTOM,AreaTOM,Year] Transportation Energy Intensity (mmBtu/Thousand KM)
  ENe::VariableArray{4} = ReadDisk(db,"KOutput/ENe") # [FuelTOM,ECCTOM,AreaTOM,Year] E2020 to TOM Energy Demands (TBtu/Yr)
  EnVehicleTOM::VariableArray{4} = ReadDisk(db,"KOutput/EnVehicleTOM") # [FuelTOM,VehicleTOM,AreaTOM,Year] Support Transportation Energy Demand Mapped to VehicleTOM (TBtu)
  EPermitE::VariableArray{3} = ReadDisk(db,"KOutput/EPermitE") # [ECCTOM,AreaTOM,Year] Cost of Emissions Permits ($M/Yr)
  EPermitHHe::VariableArray{2} = ReadDisk(db,"KOutput/EPermitHHe") # [AreaTOM,Year] Household Cost of Emissions Permits ($M/Yr)
  IFCe::VariableArray{3} = ReadDisk(db,"KOutput/IFCe") # [ECCTOM,AreaTOM,Year] E2020 Fixed Investments (2017 $M/Yr)
  IFC_PolE::VariableArray{3} = ReadDisk(db,"KOutput/IFC_PolE") # [ECCTOM,AreaTOM,Year] E2020 Fixed Investments from Policy (2017 $M/Yr)
  IFCHHe::VariableArray{2} = ReadDisk(db,"KOutput/IFCHHe") # [AreaTOM,Year] E2020 Residential Investments in Construction (2017 $M/Yr)
  IFCHH_PolE::VariableArray{2} = ReadDisk(db,"KOutput/IFCHH_PolE") # [AreaTOM,Year] Residential Investments in Construction from Policy (2017 $M/Yr)
  IFMEe::VariableArray{3} = ReadDisk(db,"KOutput/IFMEe") # [ECCTOM,AreaTOM,Year] E2020 Investments in Machinery & Equipment (2017 $M/Yr)
  IF_NRG::VariableArray{3} = ReadDisk(db,"KOutput/IF_NRG") # [ECCTOM,AreaTOM,Year] Policy Driver Energy Investments in Machinery & Equipment (2017 $M/Yr)
  IF_Tra::VariableArray{3} = ReadDisk(db,"KOutput/IF_Tra") # [ECCTOM,AreaTOM,Year] Policy Driver Transportation Investments in Machinery & Equipment from Policy (2017 $M/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  IsActiveToFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToFuelTOM") # [FuelTOM,ToTOMVariable] "Flag Indicating Which FuelTOMs go into TOM by Variable")
  KM_e::VariableArray{3} = ReadDisk(db,"KOutput/KM_e") # [VehicleTOM,AreaTOM,Year] Kilometers Traveled by Vehicle Type (Millions KM)  
  KMFuel::VariableArray{4} = ReadDisk(db,"KOutput/KMFuel") # [FuelTOM,VehicleTOM,AreaTOM,Year] Vehicle Distance Traveled by Vehicle Type and Fuel (Millions KM)
  KMShare_e::VariableArray{4} = ReadDisk(db,"KOutput/KMShare_e") # [FuelTOM,VehicleTOM,AreaTOM,Year] Fuel Share of Kilometers Traveled by Vehicle Type (KM/KM)  
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MNe::VariableArray{3} = ReadDisk(db,"KOutput/MNe") # [FuelAggTOM,AreaTOM,Year] Domestic Imports (TBtu/Yr)
  MXe::VariableArray{3} = ReadDisk(db,"KOutput/MXe") # [FuelAggTOM,AreaTOM,Year] International Imports (TBtu/Yr)
  OMExpE::VariableArray{3} = ReadDisk(db,"KOutput/OMExpE") # [ECCTOM,AreaTOM,Year] O&M Expenditures (M$) from ENERGY 2020 (2017 M$)
  Pe::VariableArray{3} = ReadDisk(db,"KOutput/Pe") # [PriceTOM,AreaTOM,Year] E2020toTOM Delivered Prices ($/mmBtu)
  Qe::VariableArray{3} = ReadDisk(db,"KOutput/Qe") # [FuelAggTOM,AreaTOM,Year] Energy Production (TBtu/Yr)
  XNe::VariableArray{3} = ReadDisk(db,"KOutput/XNe") # [FuelAggTOM,AreaTOM,Year] Domestic Exports (TBtu/Yr)
  XXe::VariableArray{3} = ReadDisk(db,"KOutput/XXe") # [FuelAggTOM,AreaTOM,Year] International Exports (TBtu/Yr)

  #
  # Scratch Variables
  #
  TotalInvestments = zeros(Float32,length(Year)) # 'Total M&E and Construction Investments (2017 $M/Yr)'
  ZZZ = zeros(Float32,length(Year))
end

function SummaryE2020ToTOM_DtaRun(data, areas, areatoms, areatomds, areatomkey, nation)
  (; ECCTOM,ECCTOMs,ECCTOMDS) = data
  (; FuelAggTOM,FuelAggTOMDS,FuelAggTOMs,FuelTOM,FuelTOMs) = data
  (; Nation,PriceTOM,PriceTOMs,SceName) = data
  (; ToTOMVariable,VehicleTOM,VehicleTOMDS,VehicleTOMs,Year) = data
  (; CD_NRG,CD_Tra,EIntE,EIntETr,ENe,EnVehicleTOM,EPermitE,EPermitHHe,IF_NRG) = data
  (; IFC_PolE,IF_Tra,IFCHH_PolE,IsActiveToECCTOM,IsActiveToFuelTOM,KM_e,KMFuel,MNe,MXe,Pe,Qe,XNe,XXe) = data

  iob = IOBuffer()
  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Summary Variable Transfers from ENERGY 2020 to TOM.")
  println(iob, " ")

  years = collect(Future:Final)
  println(iob, "Year;", ";", join(Year[years], ";    "))
  println(iob, " ")

  #
  # Energy Production
  #
  print(iob,areatomds," Energy Production (TBtu/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  #
  # Promula file is using first AreaTOM selected - Ian 05/21/25
  #
  areatomfirst = first(areatoms)
  for fuelaggtom in FuelAggTOMs
    print(iob,"Qe;",FuelAggTOMDS[fuelaggtom],";")
    for year in years
      ZZZ[year] = Qe[fuelaggtom,areatomfirst,year]
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)

  #
  # Delivered Prices
  #
  if length(areas) == 1
    print(iob,areatomds," Delivered Prices (\$/mmBtu);;")
    for year in years  
      print(iob,Year[year],";")
    end
    println(iob)
    for pricetom in PriceTOMs
      print(iob,"Pe;",PriceTOM[pricetom],";")
      for year in years
        ZZZ[year] = sum(Pe[pricetom,areatom,year] for areatom in areatoms)
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
  elseif length(areas) > 1 && Nation[nation] == "CN"
    print(iob,"Ontario Delivered Prices (\$/mmBtu);;")
    for year in years  
      print(iob,Year[year],";")
    end
    println(iob)
    for pricetom in PriceTOMs
      print(iob,"Pe;",PriceTOM[pricetom],";")
      for year in years
        ZZZ[year] = sum(Pe[pricetom,areatom,year] for areatom in areatoms)
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)
  elseif length(areas) > 1 && Nation[nation] == "US"
    print(iob,"New England Delivered Prices (\$/mmBtu);;")
    for year in years  
      print(iob,Year[year],";")
    end
    println(iob)
    for pricetom in PriceTOMs
      print(iob,"Pe;",PriceTOM[pricetom],";")
      for year in years
        ZZZ[year] = sum(Pe[pricetom,areatom,year] for areatom in areatoms)
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)  
  end
  println(iob)

  #
  # Permit Expenditures
  #
  print(iob,areatomds," Cost of Emissions Permits (2017 \$M/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"Total;Total;")
  for year in years
    ZZZ[year] = sum(EPermitHHe[areatom,year] for areatom in areatoms) +
                sum(EPermitE[ecctom,areatom,year] for ecctom in ECCTOMs, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  print(iob,"EPermitHHe;Household;")
  for year in years
    ZZZ[year] = sum(EPermitHHe[areatom,year] for areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  print(iob,"EPermitE;Industry;")  
  for year in years
    ZZZ[year] = sum(EPermitE[ecctom,areatom,year] for ecctom in ECCTOMs, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  println(iob)

  #
  # Trade Flows - Domestic Imports
  #
  print(iob,areatomds," Domestic Imports (TBtu/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"MNe;Total;")
  for year in years  
    ZZZ[year] = sum(MNe[fuelaggtom,areatom,year] for fuelaggtom in FuelAggTOMs, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)  
  for fuelaggtom in FuelAggTOMs
    print(iob,"MNe;",FuelAggTOM[fuelaggtom],";")
    for year in years
      ZZZ[year] = sum(MNe[fuelaggtom,areatom,year] for areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)

  #
  # Trade Flows - Domestic Exports
  #
  print(iob,areatomds," Domestic Exports (TBtu/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"XNe;Total;")
  for year in years  
    ZZZ[year] = sum(XNe[fuelaggtom,areatom,year] for fuelaggtom in FuelAggTOMs, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)  
  for fuelaggtom in FuelAggTOMs
    print(iob,"XNe;",FuelAggTOM[fuelaggtom],";")
    for year in years
      ZZZ[year] = sum(XNe[fuelaggtom,areatom,year] for areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)

  #
  # Trade Flows - International Imports
  #
  print(iob,areatomds," International Imports (TBtu/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"MXe;Total;")
  for year in years  
    ZZZ[year] = sum(MXe[fuelaggtom,areatom,year] for fuelaggtom in FuelAggTOMs, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)  
  for fuelaggtom in FuelAggTOMs
    print(iob,"MXe;",FuelAggTOM[fuelaggtom],";")
    for year in years
      ZZZ[year] = sum(MXe[fuelaggtom,areatom,year] for areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)

  #
  # Trade Flows - International Exports
  #
  print(iob,areatomds," International Exports (TBtu/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"XXe;Total;")
  for year in years  
    ZZZ[year] = sum(XXe[fuelaggtom,areatom,year] for fuelaggtom in FuelAggTOMs, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)  
  for fuelaggtom in FuelAggTOMs
    print(iob,"XXe;",FuelAggTOM[fuelaggtom],";")
    for year in years
      ZZZ[year] = sum(XXe[fuelaggtom,areatom,year] for areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)

  #
  # Vehicle Distance Travelled by Vehicle Type
  #
  print(iob,areatomds," Vehicle Distance Traveled by Vehicle Type (Millions KM);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"KM_e;Total;")
  for year in years  
    ZZZ[year] = sum(KM_e[vehicletom,areatom,year] for vehicletom in VehicleTOMs, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)  
  for vehicletom in VehicleTOMs
    print(iob,"KM_e;",VehicleTOM[vehicletom],";")
    for year in years
      ZZZ[year] = sum(KM_e[vehicletom,areatom,year] for areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)  

  #
  # Vehicle Distance Travelled by Fuel Type
  #
  totomvariable = Select(ToTOMVariable,"KMShare_e")
  fueltoms = findall(IsActiveToFuelTOM[:,totomvariable] .== 1)

  print(iob,areatomds," Vehicle Distance Traveled by Vehicle Type and Fuel (Million KM);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"KMFuel;Total;")
  for year in years  
    ZZZ[year] = sum(KMFuel[fueltom,vehicletom,areatom,year] for fueltom in fueltoms, vehicletom in VehicleTOMs, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)  
  for fueltom in fueltoms
    print(iob,"KMFuel;",FuelTOM[fueltom],";")
    for year in years
      ZZZ[year] = sum(KMFuel[fueltom,vehicletom,areatom,year] for vehicletom in VehicleTOMs, areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)  

  #
  # Change in Residential Investments
  #
  print(iob,areatomds," Change in Residential Investments Due to Policy (2017 \$M/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"CD_NRG+CD_Tra+IFCHH_PolE;Total;")
  for year in years
    ZZZ[year] = sum(CD_NRG[areatom,year] + CD_Tra[areatom,year] + IFCHH_PolE[areatom,year] for areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  print(iob,"CD_NRG;Durable Energy Devices;")
  for year in years
    ZZZ[year] = sum(CD_NRG[areatom,year] for areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  print(iob,"CD_Tra;Vehicles;")  
  for year in years
    ZZZ[year] = sum(CD_Tra[areatom,year] for areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  print(iob,"IFCHH_PolE;Construction;")  
  for year in years
    ZZZ[year] = sum(IFCHH_PolE[areatom,year] for areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  println(iob)

  totomvariable = Select(ToTOMVariable,"IF_NRG")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)
  
  #
  # Investments - Industry and Transportation
  #
  print(iob,areatomds," Change in Industry Investments Due to Policy (2017 \$M/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"TotalInvestments;Total;")
  for year in years
    ZZZ[year] = sum(IF_NRG[ecctom,areatom,year] + IF_Tra[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms) + 
                sum(IFC_PolE[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  print(iob,"IF_NRG;Industry Energy Devices;")
  for year in years
    ZZZ[year] = sum(IF_NRG[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  print(iob,"IF_Tra;Vehicles Industrial Sector;")
  for year in years
    ZZZ[year] = sum(IF_Tra[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  print(iob,"IFC_PolE;Industry Construction;")
  for year in years
    ZZZ[year] = sum(IFC_PolE[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  println(iob)

  #
  # Change in Device Investments by Industry
  #
  print(iob,areatomds," Change in Industry Investments Due to Policy (2017 \$M/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  for ecctom in ecctoms
    print(iob,"IF_NRG+IF_Tra;",ECCTOMDS[ecctom],";")
    for year in years
      ZZZ[year] = sum(IF_NRG[ecctom,areatom,year] + IF_Tra[ecctom,areatom,year] for areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)   

  #
  # Energy Intensity - Industrial
  #
  print(iob,areatomds," Energy Intensity (mmBtu/2017 CN\$1000);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  
  totomvariable = Select(ToTOMVariable,"EIntE")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)
  fueltoms = findall(IsActiveToFuelTOM[:,totomvariable] .== 1)

  print(iob,"EInt;Average;")
  for year in years
    @finite_math ZZZ[year] = 
      sum(EIntE[fueltom,ecctom,areatom,year]*ENe[fueltom,ecctom,areatom,year]
          for fueltom in fueltoms, ecctom in ecctoms, areatom in areatoms)/ 
      sum(ENe[fueltom,ecctom,areatom,year]
          for fueltom in fueltoms, ecctom in ecctoms, areatom in areatoms)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  for fueltom in fueltoms
    print(iob,"EInt;",FuelTOM[fueltom],";")
    for year in years
      @finite_math ZZZ[year] =
        sum(EIntE[fueltom,ecctom,areatom,year]*ENe[fueltom,ecctom,areatom,year]
            for ecctom in ecctoms, areatom in areatoms)/ 
        sum(ENe[fueltom,ecctom,areatom,year]
            for ecctom in ecctoms, areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)     

  #
  # Energy Intensity - Passenger
  #
  totomvariable = Select(ToTOMVariable,"EIntETr")
  fueltoms = findall(IsActiveToFuelTOM[:,totomvariable] .== 1)
  vehicletoms = Select(VehicleTOM,["AirPassenger","Bus","LDV","TrainPassenger"])

  print(iob,areatomds," Passenger Energy Intensity from E2020 (mmBtu/Thousand Passenger KM);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"EIntETr;Average;")
  for year in years
    ZZZ[year] = 0.0
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  for vehicletom in vehicletoms, fueltom in fueltoms
    print(iob,"EIntETr;",VehicleTOMDS[vehicletom]," ",FuelTOM[fueltom],";")
    for year in years
      ZZZ[year] = sum(EIntETr[fueltom,vehicletom,areatom,year] for areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)     

  #
  # Energy Intensity - Freight
  #
  totomvariable = Select(ToTOMVariable,"EIntETr")
  fueltoms = findall(IsActiveToFuelTOM[:,totomvariable] .== 1)
  vehicletoms = Select(VehicleTOM,["AirFreight","TrainFreight","HDV"])

  print(iob,areatomds," Freight Energy Intensity from E2020 (mmBtu/Thousand Ton-KM);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"EInt;Average;")
  for year in years
    ZZZ[year] = 0.0
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  for vehicletom in vehicletoms, fueltom in fueltoms
    print(iob,"EIntETr;",VehicleTOMDS[vehicletom]," ",FuelTOM[fueltom],";")
    for year in years
      ZZZ[year] = sum(EIntETr[fueltom,vehicletom,areatom,year] for areatom in areatoms)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)
  
  #
  # Create *.dta filename and write output values
  #
  filename = "SummaryE2020ToTOM-$areatomkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))  
  end   
end


function SummaryE2020ToTOM_DtaControl(db)
  @info "SummaryE2020ToTOM_DtaControl"
  data = SummaryE2020ToTOMData(; db)
  (; AreaTOM,AreaTOMDS,Nation) = data
  (; ANMap,MapAreaTOM) = data

  nation = Select(Nation,"CN")
  areatoms = Select(AreaTOM,(from="AB",to="YT"))
  for areatom in areatoms
    areas = findall(MapAreaTOM[:,areatom] .== 1)
    areatomkey = AreaTOM[areatom]
    areatomds = AreaTOMDS[areatom]
    SummaryE2020ToTOM_DtaRun(data,areas,areatom,areatomds,areatomkey,nation)
  end
  areas = findall(ANMap[:,nation] .== 1)
  areatomkey = "CN"
  areatomds = "Canada"
  SummaryE2020ToTOM_DtaRun(data,areas,areatoms,areatomds,areatomkey,nation)

  nation = Select(Nation,"US")
  areatoms = Select(AreaTOM,(from="NEng",to="CA"))
  for areatom in areatoms
    areas = findall(MapAreaTOM[:,areatom] .== 1)
    areatomkey = AreaTOM[areatom]
    areatomds = AreaTOMDS[areatom]
    SummaryE2020ToTOM_DtaRun(data,areas,areatom,areatomds,areatomkey,nation)
  end
  areas = findall(ANMap[:,nation] .== 1)
  areatomkey = "US"
  areatomds = "US"
  SummaryE2020ToTOM_DtaRun(data,areas,areatoms,areatomds,areatomkey,nation)
end

if abspath(PROGRAM_FILE) == @__FILE__
  SummaryE2020ToTOM_DtaControl(DB)
end
