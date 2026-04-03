#
# KInput.jl - Input Database creation file
#

Base.@kwdef struct KInput <: HDF5GroupDatabase
  db::String = DB
  ########################
  #
  # Define Sets
  #
  AreaTOM = ReadSetFromCSV("AreaTOM","Key")
  tv = ReadSetFromCSV("tv","Key")
  CNAreaTOM = ReadSetFromCSV("CNAreaTOM","Key")
  ECTrans = ReadSetFromCSV("ECTrans","Key")
  ECCFloorspaceTOM = ReadSetFromCSV("ECCFloorspaceTOM","Key")
  ECCResTOM = ReadSetFromCSV("ECCResTOM","Key")
  ECCTOM = ReadSetFromCSV("ECCTOM","Key")
  ES = ReadSetFromCSV("ES","Key")
  Fleet = ReadSetFromCSV("Fleet","Key")
  FuelAggTOM = ReadSetFromCSV("FuelAggTOM","Key")
  FuelTOM = ReadSetFromCSV("FuelTOM","Key")
  NationTOM = ReadSetFromCSV("NationTOM","Key")
  PriceTOM = ReadSetFromCSV("PriceTOM","Key")
  Process = ReadSetFromCSV("Process","Key")
  ResEnergyTOM = ReadSetFromCSV("ResEnergyTOM","Key")
  TechTrans = ReadSetFromCSV("TechTrans","Key")
  VehicleTOM = ReadSetFromCSV("VehicleTOM","Key")
  WorldTOM = ReadSetFromCSV("WorldTOM","Key")
  Area = ReadSetFromCSV("Area","Key")
  Nation = ReadSetFromCSV("Nation","Key")
  ECC = ReadSetFromCSV("ECC","Key")
  Fuel = ReadSetFromCSV("Fuel","Key")
  ToTOMVariable = ReadSetFromCSV("ToTOMVariable","Key")
  Year = ReadSetFromCSV("Year","Key")

  ########################
  #
  # Define Variables on Database
  #
  #! format: off
  AreaTOMDS = ReadSetFromCSV("AreaTOM","DS")
  AreaTOMKey = ReadSetFromCSV("AreaTOM","Key")
  AreaTOMLabel::SetArray = AreaTOM
  CNAreaTOMDS = ReadSetFromCSV("CNAreaTOM","DS")
  CNAreaTOMKey = ReadSetFromCSV("CNAreaTOM","Key")
  CNAreaTOMLabel::SetArray = CNAreaTOM
  ECCFloorspaceTOMDS = ReadSetFromCSV("ECCFloorspaceTOM","DS")
  ECCFloorspaceTOMKey = ReadSetFromCSV("ECCFloorspaceTOM","Key")
  ECCFloorspaceTOMLabel::SetArray = ECCFloorspaceTOM
  ECCResTOMDS = ReadSetFromCSV("ECCResTOM","DS")
  ECCResTOMKey = ReadSetFromCSV("ECCResTOM","Key")
  ECCResTOMLabel::SetArray = ECCResTOM
  ECCTOMDS = ReadSetFromCSV("ECCTOM","DS")
  ECCTOMKey = ReadSetFromCSV("ECCTOM","Key")
  ECCTOMLabel::SetArray = ECCTOM
  FleetDS = ReadSetFromCSV("Fleet","DS")
  FleetKey = ReadSetFromCSV("Fleet","Key")
  FleetLabel::SetArray = Fleet
  FuelAggTOMDS = ReadSetFromCSV("FuelAggTOM","DS")
  FuelAggTOMKey = ReadSetFromCSV("FuelAggTOM","Key")
  FuelAggTOMLabel::SetArray = FuelAggTOM
  FuelTOMDS = ReadSetFromCSV("FuelTOM","DS")
  FuelTOMKey = ReadSetFromCSV("FuelTOM","Key")
  FuelTOMLabel::SetArray = FuelTOM
  NationTOMDS = ReadSetFromCSV("NationTOM","DS")
  NationTOMKey = ReadSetFromCSV("NationTOM","Key")
  NationTOMLabel::SetArray = NationTOM
  PriceTOMDS = ReadSetFromCSV("PriceTOM","DS")
  PriceTOMKey = ReadSetFromCSV("PriceTOM","Key")
  PriceTOMLabel::SetArray = PriceTOM
  ResEnergyTOMDS = ReadSetFromCSV("ResEnergyTOM","DS")
  ResEnergyTOMKey = ReadSetFromCSV("ResEnergyTOM","Key")
  ResEnergyTOMLabel::SetArray = ResEnergyTOM
  ToTOMVariableDS = ReadSetFromCSV("ToTOMVariable","DS")
  ToTOMVariableKey = ReadSetFromCSV("ToTOMVariable","Key")
  ToTOMTOMVariableLabel::SetArray = ToTOMVariable
  VehicleTOMDS = ReadSetFromCSV("VehicleTOM","DS")
  VehicleTOMKey = ReadSetFromCSV("VehicleTOM","Key")
  VehicleTOMLabel::SetArray = VehicleTOM
  WorldTOMDS = ReadSetFromCSV("WorldTOM","DS")
  WorldTOMKey = ReadSetFromCSV("WorldTOM","Key")
  WorldTOMLabel::SetArray = WorldTOM

  TOMBaseTime = CreateVariableInHDF5(db,"KInput/TOMBaseTime", (:tv,),"Base Year for TOM Economic Model (Year)","Year")
  TOMBaseYear = CreateVariableInHDF5(db,"KInput/TOMBaseYear", (:tv,),"Base Year for TOM Economic Model (Index)","Index")
  IsActiveToECCTOM = CreateVariableInHDF5(db,"KInput/IsActiveToECCTOM", (:ECCTOM, :ToTOMVariable),"Flag Indicating Which ECCTOMs to into TOM by Variable","Flag")
  IsActiveToFuelTOM = CreateVariableInHDF5(db,"KInput/IsActiveToFuelTOM", (:FuelTOM, :ToTOMVariable),"Flag Indicating Which FuelTOMs go into TOM by Variable","Flag")
  MapAreaTOM = CreateVariableInHDF5(db,"KInput/MapAreaTOM", (:Area, :AreaTOM),"Map between Area and AreaTOM","NoUnit")
  MapCNAreaTOM = CreateVariableInHDF5(db,"KInput/MapCNAreaTOM", (:Area, :CNAreaTOM),"Map between Area and CNAreaTOM","NoUnit")
  MapAreaTOMNation = CreateVariableInHDF5(db,"KInput/MapAreaTOMNation", (:AreaTOM, :Nation),"Map between AreaTOM and Nation (Map)","Map")
  MapECCFloorspaceTOM = CreateVariableInHDF5(db,"KInput/MapECCFloorspaceTOM", (:ECC, :ECCFloorspaceTOM),"Map between ECC and ECCFloorspaceTOM","NoUnit")
  MapECCResTOM = CreateVariableInHDF5(db,"KInput/MapECCResTOM", (:ECC, :ECCResTOM),"Map between ECC and ECCResTOM","NoUnit")
  MapECCtoTOM = CreateVariableInHDF5(db,"KInput/MapECCtoTOM", (:ECC, :ECCTOM),"Map from ECC to TOM","NoUnit")
  MapFuelTOM = CreateVariableInHDF5(db,"KInput/MapFuelTOM", (:Fuel, :FuelTOM),"Map between Fuel and FuelTOM","NoUnit")
  MapFuelTechECToVehicleFuelTOM = CreateVariableInHDF5(db,"KInput/MapFuelTechECToVehicleFuelTOM", (:Fuel, :TechTrans, :ECTrans, :FuelTOM, :VehicleTOM),"Map Fuel, Tech, EC to VehicleTOM and FuelTOM","NoUnit")
  MapFuelAggTOM = CreateVariableInHDF5(db,"KInput/MapFuelAggTOM", (:Fuel, :FuelAggTOM),"Map between Fuel and FuelAggTOM","NoUnit")
  MapfromECCTOM = CreateVariableInHDF5(db,"KInput/MapfromECCTOM", (:ECC, :ECCTOM),"Map between ECC and ECCTOM","NoUnit")
  MapOGProductionTOM = CreateVariableInHDF5(db,"KInput/MapOGProductionTOM", (:Process, :FuelAggTOM),"Map of Oil Gas Processes to FuelAggTOM","NoUnit")
  MapPriceTOM = CreateVariableInHDF5(db,"KInput/MapPriceTOM", (:Fuel, :ES, :PriceTOM),"Map from Fuel and ES to PriceTOM","NoUnit")
  MapTechToFleet = CreateVariableInHDF5(db,"KInput/MapTechToFleet", (:TechTrans, :Fleet),"Map from Transportation Techs to Fleet","NoUnit")
  MapUSfromECCTOM = CreateVariableInHDF5(db,"KInput/MapUSfromECCTOM", (:ECC, :ECCTOM),"Map from ECCTOM to ECC","NoUnit")
  MapUSECCtoTOM = CreateVariableInHDF5(db,"KInput/MapUSECCtoTOM", (:ECC, :ECCTOM),"Map from ECC to TOM","NoUnit")
  HouseholdLDVFraction = CreateVariableInHDF5(db,"KInput/HouseholdLDVFraction", (:Area, :Year),"Fraction of LDV/LDT Investments from Households (vs Fleet) (Btu/Btu)","Btu/Btu")
  VehicleSalesRatio = CreateVariableInHDF5(db,"KInput/VehicleSalesRatio", (:Fleet, :ECCTOM, :AreaTOM, :Year),"Ratio of Transportation Investments to Gross Output (Btu/Btu)","Btu/Btu")
end # struct KInput
