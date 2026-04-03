#
# zECFP.jl - Fuel Price by End-use Technology
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

# Residential Segment Data Structure
Base.@kwdef struct zECFPResidentialData
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Age::SetArray = ReadDisk(db, "MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db, "MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zECFP::VariableArray{5} = ReadDisk(db, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  zECFPRef::VariableArray{5} = ReadDisk(RefNameDB, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables  
  #
  Conversion::VariableArray{2} = ones(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

# Commercial Segment Data Structure
Base.@kwdef struct zECFPCommercialData
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Age::SetArray = ReadDisk(db, "MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db, "MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zECFP::VariableArray{5} = ReadDisk(db, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  zECFPRef::VariableArray{5} = ReadDisk(RefNameDB, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables  
  #
  Conversion::VariableArray{2} = ones(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

# Industrial Segment Data Structure
Base.@kwdef struct zECFPIndustrialData
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Age::SetArray = ReadDisk(db, "MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db, "MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zECFP::VariableArray{5} = ReadDisk(db, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  zECFPRef::VariableArray{5} = ReadDisk(RefNameDB, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables  
  #
  Conversion::VariableArray{2} = ones(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

# Transportation Segment Data Structure
Base.@kwdef struct zECFPTransportationData
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Age::SetArray = ReadDisk(db, "MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db, "MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zECFP::VariableArray{5} = ReadDisk(db, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  zECFPRef::VariableArray{5} = ReadDisk(RefNameDB, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables  
  #
  Conversion::VariableArray{2} = ones(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zECFP_DtaRun(data,nation,segment_name,use_heat_filter=true)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,Enduse,EnduseDS,Enduses,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,Tech,TechDS,Techs,Year,YearDS,Ages) = data
  (; ANMap,BaseSw,CDTime,CDYear,Conversion,EndTime,UnitsDS) = data
  (; zECFP,zECFPRef,SceName,NationOutputMap) = data

  if NationOutputMap[nation] != 1
    return
  end

  if BaseSw != 0
    @. zECFPRef = zECFP
  end

  # Set up units
  for n in Nations
    Conversion[n,:] .= 1.0
    UnitsDS[n] = "\$/mmBtu"
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Tech;Enduse;Units;zData;zInitial")

  areas = findall(ANMap[:,nation] .== 1)
  years = collect(1:Yr(EndTime))

  # Filter enduses - R/C/I only use Heat, T uses all enduses
  target_enduses = if use_heat_filter
    heat_idx = Select(Enduse,"Heat")
    [heat_idx]
  else
    Enduses
  end

  for year in years
    for area in areas
      for ec in ECs
        for tech in Techs
          for enduse in target_enduses
            ZZZ = zECFP[enduse,tech,ec,area,year] * Conversion[nation,year]
            CCC = zECFPRef[enduse,tech,ec,area,year] * Conversion[nation,year]
            if ZZZ != 0 || CCC != 0
              println(iob,"zECFP;",YearDS[year],";",AreaDS[area],";",ECDS[ec],";",
                      TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",
                      @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
            end
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zECFP-$segment_name-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do file
    write(file, String(take!(iob)))
  end
end

function zECFP_DtaControl(db)
  @info "zECFP_DtaControl"

  # Process CN for all segments
  CN = Select(ReadDisk(db, "MainDB/NationKey"),"CN")
  
  # Process Residential segment for CN (Heat only)
  res_data = zECFPResidentialData(; db)
  zECFP_DtaRun(res_data,CN,"Residential",true)

  # Process Commercial segment for CN (Heat only)
  com_data = zECFPCommercialData(; db)
  zECFP_DtaRun(com_data,CN,"Commercial",true)

  # Process Industrial segment for CN (Heat only)
  ind_data = zECFPIndustrialData(; db)
  zECFP_DtaRun(ind_data,CN,"Industrial",true)

  # Process Transportation segment for CN (all enduses)
  trn_data = zECFPTransportationData(; db)
  zECFP_DtaRun(trn_data,CN,"Transportation",false)
end
  
if abspath(PROGRAM_FILE) == @__FILE__
  zECFP_DtaControl(DB)
end
