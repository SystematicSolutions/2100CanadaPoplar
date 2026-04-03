#
# zE2020TOMMaps.jl
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

Base.@kwdef struct zE2020TOMMapsData
  db::String
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECTrans::SetArray = ReadDisk(db,"MainDB/ECTransKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCFloorspaceTOM::SetArray = ReadDisk(db,"KInput/ECCFloorspaceTOMKey")
  ECCFloorspaceTOMDS::SetArray = ReadDisk(db,"KInput/ECCFloorspaceTOMDS")
  ECCFloorspaceTOMs::Vector{Int} = collect(Select(ECCFloorspaceTOM))
  ECCResTOM::SetArray = ReadDisk(db,"KInput/ECCResTOMKey")
  ECCResTOMDS::SetArray = ReadDisk(db,"KInput/ECCResTOMDS")
  ECCResTOMs::Vector{Int} = collect(Select(ECCResTOM))
  ECCTOM::SetArray = ReadDisk(db, "KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db, "KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  FuelAggTOM::SetArray = ReadDisk(db,"KInput/FuelAggTOMKey")
  FuelAggTOMDS::SetArray = ReadDisk(db,"KInput/FuelAggTOMDS")
  FuelAggTOMs::Vector{Int} = collect(Select(FuelAggTOM))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMDS::SetArray = ReadDisk(db,"KInput/FuelTOMDS")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  TechTrans::SetArray = ReadDisk(db,"MainDB/TechTransKey")
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case) 
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM")   # [Area,AreaTOM]  Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MapECCFloorspaceTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCFloorspaceTOM")     # [ECC,ECCFloorspaceTOM] Map between ECCFloorspaceTOM and ECC
  MapfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapfromECCTOM") # [ECC,ECCTOM] Map between ECCTOM and ECC
  MapECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCtoTOM") # [ECC,ECCTOM] Map between ECC and ECCTOM
  MapECCResTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCResTOM") # [ECC,ECCResTOM] Map between ECCResTOM and ECC
  MapFuelAggTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelAggTOM") # [Fuel,FuelAggTOM] Map between Fuel and FuelAggTOM
  MapFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelTOM") # [Fuel,FuelTOM] Map between Fuel and FuelTOM
  MapFuelTechECToVehicleFuelTOM::VariableArray{5} = ReadDisk(db,"KInput/MapFuelTechECToVehicleFuelTOM") # [Fuel,TechTrans,ECTrans,FuelTOM,VehicleTOM] Map between Fuel,Tech and FuelTOM
  MapUSECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSECCtoTOM") # [ECC,ECCTOM] Map between ECC and ECCTOM
  MapUSfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSfromECCTOM") # [ECC,ECCTOM] Map between ECC and ECCTOM
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM ($/$)
  SplitECCtoTOMIFC::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFC") # [ECC,ECCTOM,AreaTOM,Year]  Split ECC into ECCTOM based on Construction Investments, IFC ($/$)
  SplitECCtoTOMIFME::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFME") # [ECC,ECCTOM,AreaTOM,Year]  Split ECC into ECCTOM based on M&E Investments, IFME ($/$)

end

function zE2020TOMMaps_DtaRun(data)
  (; AreaTOM,AreaTOMs,ECC,ECCDS,ECCs) = data
  (; ECCFloorspaceTOMs,ECCFloorspaceTOMDS) = data
  (; ECCResTOM,ECCResTOMDS,ECCResTOMs,ECCTOM,ECCTOMDS,ECCTOMs) = data
  (; FuelAggTOMs,Fuel,FuelDS,Fuels,FuelTOM,FuelTOMDS,FuelTOMs) = data
  (; Nation,Nations,ToTOMVariable) = data
  (; IsActiveToECCTOM,MapAreaTOMNation,MapECCFloorspaceTOM,MapfromECCTOM) = data
  (; MapECCtoTOM,MapECCResTOM,MapUSfromECCTOM,MapUSECCtoTOM) = data
  (; SplitECCtoTOM,SplitECCtoTOMIFC,SplitECCtoTOMIFME) = data
  (; MapFuelTOM,MapFuelAggTOM,MapFuelTechECToVehicleFuelTOM,SceName) = data
  
  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob,"E2020TOM Maps")
  println(iob, " ")

  #
  # Sector Maps from TOM
  #
  println(iob,"Variable Name;From TOM;To E2020;Canada Map;US Map")
  eccs = Select(ECC,(from="SingleFamilyDetached",to="OtherResidential"))
  for ecc in eccs
    eccrestoms = findall(MapECCResTOM[ecc,:] .== 1)
    for eccrestom in eccrestoms
      println(iob,"MapECCResTOM;",ECCResTOMDS[eccrestom],";",ECCDS[ecc],";",
        @sprintf("%.0f",MapECCResTOM[ecc,eccrestom]),";",@sprintf("%.0f",MapECCResTOM[ecc,eccrestom]))
    end
  end
  eccs = Select(ECC,(from="Wholesale",to="CommercialOffRoad"))
  for ecc in eccs
    for ecctom in ECCTOMs
      if (MapfromECCTOM[ecc,ecctom] == 1) || (MapUSfromECCTOM[ecc,ecctom] == 1)
        println(iob,"MapfromECCTOM;",ECCTOMDS[ecctom],";",ECCDS[ecc],";",
          @sprintf("%.0f",MapfromECCTOM[ecc,ecctom]),";",@sprintf("%.0f",MapUSfromECCTOM[ecc,ecctom]))
      end
    end
  end
  println(iob)

  #
  # Map Floorspace ECCs into ECCFloorspaceTOM
  #
  println(iob,"Variable Name;TOM Sector;E2020 Sector;Map")
  eccs = Select(ECC,(from="SingleFamilyDetached",to="OtherResidential"))
  for ecc in eccs
    for eccfloorspacetom in ECCFloorspaceTOMs
      if MapECCFloorspaceTOM[ecc,eccfloorspacetom] == 1
        println(iob,"MapECCFloorspaceTOM;",ECCFloorspaceTOMDS[eccfloorspacetom],";",
          ECCDS[ecc],";",@sprintf("%.0f",MapECCFloorspaceTOM[ecc,eccfloorspacetom]))
      end
    end
  end
  println(iob)
  
  #
  # Sector Maps into TOM
  #
  println(iob,"Variable Name;From E2020;To TOM Sector;Canada Map;US Map;GrossOutputSplit;DeviceInvestmentSplit;ProcessInvestmentSplit")
  eccs = Select(ECC,(from="SingleFamilyDetached",to="OtherResidential"))
  for ecc in eccs
    eccrestoms = findall(MapECCResTOM[ecc,:] .== 1)
    for eccrestom in eccrestoms
      println(iob,"MapECCResTOM;",ECCDS[ecc],";",ECCResTOMDS[eccrestom],";",
        @sprintf("%.0f",MapECCResTOM[ecc,eccrestom]),";",@sprintf("%.0f",MapECCResTOM[ecc,eccrestom]),";1;1;1")
    end
  end
  eccs = Select(ECC,(from="Wholesale",to="AnimalProduction"))

  ON = Select(AreaTOM,"ON")
  for ecc in eccs
    for ecctom in ECCTOMs
      if (MapECCtoTOM[ecc,ecctom] == 1) || (MapUSECCtoTOM[ecc,ecctom] == 1)
        println(iob,"MapECCtoTOM;",ECCDS[ecc],";",ECCTOMDS[ecctom],";",
          @sprintf("%.0f",MapECCtoTOM[ecc,ecctom]),";",
          @sprintf("%.0f",MapUSECCtoTOM[ecc,ecctom]),";",
          @sprintf("%.3f",SplitECCtoTOM[ecc,ecctom,ON,Future]),";",
          @sprintf("%.3f",SplitECCtoTOMIFME[ecc,ecctom,ON,Future]),";",
          @sprintf("%.3f",SplitECCtoTOMIFC[ecc,ecctom,ON,Future]))
      end
    end
  end

  #
  # MapAreaTOMNation
  #
  println(iob,"Variable Name;AreaTOM;Nation;Map")
  for areatom in AreaTOMs
    for nation in Nations
      if MapAreaTOMNation[areatom,nation] == 1
        println(iob,"MapAreaTOMNation;",AreaTOM[areatom],";",Nation[nation],";",@sprintf("%.0f",MapAreaTOMNation[areatom,nation]))
      end
    end
  end
  println(iob)
 
  #
  # Fuel Map
  #
  #println(iob,"Variable Name;E2020 Fuel;TOM Fuel (FuelTOM);Map Value")
  #for fueltom in FuelTOMs
  #  for fuel in Fuels
  #    if MapFuelTOM[fuel,fueltom] == 1
  #      println(iob,"MapFuelTOM;",FuelDS,";",FuelTOMDS::0,";",MapFuelTOM[Fuel,FuelTOM])
  #    end
  #  end
  #end
  #println(iob)
#
  ##
  ## FuelAggTOM Map
  ##
  #println(iob,"Variable Name;E2020 Fuel;TOM Fuel (FuelAggTOM);Map Value")
  #for fuelaggtom in FuelAggTOMs
  #  fuels = findall(MapFuelAggTOM[fuel,fuelaggtom] > 0)
  #  for fuel in fuels
  #    println(iob,"MapFuelAggTOM;",FuelDS,";",FuelAggTOMDS,";",MapFuelAggTOM[fuel,fuelaggtom])
  #  end
  #end
  #println(iob)
#
  filename = "zE2020TOMMaps-$SceName.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zE2020TOMMaps_DtaControl(db)
  data = zE2020TOMMapsData(; db)

  @info "zE2020TOMMaps_DtaControl"

  zE2020TOMMaps_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  zE2020TOMMaps_DtaControl(DB)
end
