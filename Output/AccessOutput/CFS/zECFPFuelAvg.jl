#
# zECFPFuelAvg.jl - Write National Average Fuel Prices for Access Database
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


using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}


# Residential Segment Data Structure
Base.@kwdef struct zECFPFuelAvgResidentialData
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # [EC,ECC] Map between EC and ECC
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  EuDemand::VariableArray{4} = ReadDisk(db, "SOutput/EuDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu)
  EuDemandRef::VariableArray{4} = ReadDisk(RefNameDB, "SOutput/EuDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu)
  zECFPFuel::VariableArray{4} = ReadDisk(db, "$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price ($/mmBtu)
  zECFPFuelRef::VariableArray{4} = ReadDisk(RefNameDB, "$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price ($/mmBtu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  TotDmd::VariableArray{3} = zeros(Float32,length(Fuel),length(EC),length(Year)) # [Fuel,EC,Year] Total National Energy Demands (TBtu)
  TotDmdRef::VariableArray{3} = zeros(Float32,length(Fuel),length(EC),length(Year)) # [Fuel,EC,Year] Total National Energy Demands (TBtu)

end

# Commercial Segment Data Structure
Base.@kwdef struct zECFPFuelAvgCommercialData
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # [EC,ECC] Map between EC and ECC
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  EuDemand::VariableArray{4} = ReadDisk(db, "SOutput/EuDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu)
  EuDemandRef::VariableArray{4} = ReadDisk(RefNameDB, "SOutput/EuDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu)
  zECFPFuel::VariableArray{4} = ReadDisk(db, "$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price ($/mmBtu)
  zECFPFuelRef::VariableArray{4} = ReadDisk(RefNameDB, "$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price ($/mmBtu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  TotDmd::VariableArray{3} = zeros(Float32,length(Fuel),length(EC),length(Year)) # [Fuel,EC,Year] Total National Energy Demands (TBtu)
  TotDmdRef::VariableArray{3} = zeros(Float32,length(Fuel),length(EC),length(Year)) # [Fuel,EC,Year] Total National Energy Demands (TBtu)

end

# Industrial Segment Data Structure
Base.@kwdef struct zECFPFuelAvgIndustrialData
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # [EC,ECC] Map between EC and ECC
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  EuDemand::VariableArray{4} = ReadDisk(db, "SOutput/EuDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu)
  EuDemandRef::VariableArray{4} = ReadDisk(RefNameDB, "SOutput/EuDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu)
  zECFPFuel::VariableArray{4} = ReadDisk(db, "$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price ($/mmBtu)
  zECFPFuelRef::VariableArray{4} = ReadDisk(RefNameDB, "$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price ($/mmBtu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  TotDmd::VariableArray{3} = zeros(Float32,length(Fuel),length(EC),length(Year)) # [Fuel,EC,Year] Total National Energy Demands (TBtu)
  TotDmdRef::VariableArray{3} = zeros(Float32,length(Fuel),length(EC),length(Year)) # [Fuel,EC,Year] Total National Energy Demands (TBtu)

end

function zECFPFuelAvg_DtaRun(data,nation,segment_name)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,ECC,ECCDS,ECCs,Fuel,FuelDS,Fuels,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,Year,YearDS) = data
  (; ANMap,ECCMap,BaseSw,Conversion,EndTime,UnitsDS,TotDmd,TotDmdRef) = data
  (; EuDemand,EuDemandRef,zECFPFuel,zECFPFuelRef,NationOutputMap,SceName) = data

  if NationOutputMap[nation] != 1
    return
  end

  if BaseSw != 0
    @. zECFPFuelRef = zECFPFuel
    @. EuDemandRef = EuDemand
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "\$/mmBtu"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "\$/mmBtu"
  end

  # Calculate total demands for national averages
  for fuel in Fuels
    for ec in ECs
      for year in years
        TotDmd[fuel,ec,year] = sum(sum(EuDemand[fuel,ecc,area,year]*ECCMap[ec,ecc] for ecc in ECCs) for area in areas)
        TotDmdRef[fuel,ec,year] = sum(sum(EuDemandRef[fuel,ecc,area,year]*ECCMap[ec,ecc] for ecc in ECCs) for area in areas)
      end
    end
  end

  # Calculate national average prices
  for year in years
    for ec in ECs
      for fuel in Fuels
        if TotDmd[fuel,ec,year] != 0 || TotDmdRef[fuel,ec,year] != 0
          ZZZ = sum(zECFPFuel[fuel,ec,area,year]*Conversion[nation,year]*
                    sum(EuDemand[fuel,ecc,area,year]*ECCMap[ec,ecc] for ecc in ECCs) for area in areas) / 
                max(TotDmd[fuel,ec,year], 1e-12)
          CCC = sum(zECFPFuelRef[fuel,ec,area,year]*Conversion[nation,year]*
                    sum(EuDemandRef[fuel,ecc,area,year]*ECCMap[ec,ecc] for ecc in ECCs) for area in areas) / 
                max(TotDmdRef[fuel,ec,year], 1e-12)
          
          if ZZZ != 0 || CCC != 0
            println(iob,"zECFPFuel;",YearDS[year],";",NationDS[nation],";",ECDS[ec],";",
              FuelDS[fuel],";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zECFPFuelAvg-$segment_name-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zECFPFuelAvg_DtaControl(db)
  @info "zECFPFuelAvg_DtaControl"

  # Process Residential segment for CN
  res_data = zECFPFuelAvgResidentialData(; db)
  CN = Select(res_data.Nation,"CN")
  zECFPFuelAvg_DtaRun(res_data,CN,"Residential")

  # Process Commercial segment for CN  
  com_data = zECFPFuelAvgCommercialData(; db)
  CN = Select(com_data.Nation,"CN")
  zECFPFuelAvg_DtaRun(com_data,CN,"Commercial")

  # Process Industrial segment for CN
  ind_data = zECFPFuelAvgIndustrialData(; db)
  CN = Select(ind_data.Nation,"CN")
  zECFPFuelAvg_DtaRun(ind_data,CN,"Industrial")
end
if abspath(PROGRAM_FILE) == @__FILE__
zECFPFuelAvg_DtaControl(DB)
end

