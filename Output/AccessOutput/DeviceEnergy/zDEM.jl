#
# zDEM.jl - Maximum Device Efficiency
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
Base.@kwdef struct zDEMResidentialData
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
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  LastYear::Int = Yr(EndTime)
  zDEM::VariableArray{4} = ReadDisk(db, "$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  zDEMRef::VariableArray{4} = ReadDisk(RefNameDB, "$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  EUPC::VariableArray{6} = ReadDisk(db, "$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity by Enduse (M$/Yr)
  EUPCRef::VariableArray{6} = ReadDisk(RefNameDB, "$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity by Enduse (M$/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SectorDS::SetArray = ReadDisk(db, "MainDB/SectorDS") # [Sector] Sector Description

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  KJBtu::Float32 = 1.054615 # Kilo Joule per BTU
  Conversion::VariableArray{1} = ones(Float32,length(Nation)) # [Nation] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

# Commercial Segment Data Structure
Base.@kwdef struct zDEMCommercialData
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
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  LastYear::Int = Yr(EndTime)
  zDEM::VariableArray{4} = ReadDisk(db, "$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  zDEMRef::VariableArray{4} = ReadDisk(RefNameDB, "$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  EUPC::VariableArray{6} = ReadDisk(db, "$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity by Enduse (M$/Yr)
  EUPCRef::VariableArray{6} = ReadDisk(RefNameDB, "$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity by Enduse (M$/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SectorDS::SetArray = ReadDisk(db, "MainDB/SectorDS") # [Sector] Sector Description

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  KJBtu::Float32 = 1.054615 # Kilo Joule per BTU
  Conversion::VariableArray{1} = ones(Float32,length(Nation)) # [Nation] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

# Industrial Segment Data Structure
Base.@kwdef struct zDEMIndustrialData
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
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  LastYear::Int = Yr(EndTime)
  zDEM::VariableArray{4} = ReadDisk(db, "$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  zDEMRef::VariableArray{4} = ReadDisk(RefNameDB, "$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  EUPC::VariableArray{6} = ReadDisk(db, "$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity by Enduse (M$/Yr)
  EUPCRef::VariableArray{6} = ReadDisk(RefNameDB, "$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity by Enduse (M$/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SectorDS::SetArray = ReadDisk(db, "MainDB/SectorDS") # [Sector] Sector Description

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  KJBtu::Float32 = 1.054615 # Kilo Joule per BTU
  Conversion::VariableArray{1} = ones(Float32,length(Nation)) # [Nation] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zDEM_DtaRun(data,nation,segment_name)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,Enduse,EnduseDS,Enduses,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,Tech,TechDS,Techs,Year,Ages,SceName,SectorDS) = data
  (; ANMap,BaseSw,CDTime,CDYear,Conversion,EndTime,KJBtu,UnitsDS,LastYear) = data
  (; zDEM,zDEMRef,EUPC,EUPCRef,NationOutputMap) = data

  if NationOutputMap[nation] != 1
    return
  end

  if BaseSw != 0
    @. zDEMRef = zDEM
    @. EUPCRef = EUPC
  end

  # Set up units (no conversion needed for efficiency ratios)
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  Conversion[US] = 1.0
  UnitsDS[US] = "(Btu/Btu)"
  Conversion[CN] = 1.0
  UnitsDS[CN] = "(Btu/Btu)"

  iob = IOBuffer()
  println(iob,"Variable;Area;Sector;Technology;Enduse;Units;zData;zInitial")

  areas = findall(ANMap[:,nation] .== 1)

  # First loop: EC → Enduse → Tech with both national and area level outputs
  for ec in ECs
    for enduse in Enduses
      for tech in Techs
        # Calculate capacity-weighted averages using last year capacity
        total_cap = sum(sum(EUPC[enduse,t,age,ec,area,LastYear] for age in Ages) for t in Techs, area in areas)
        total_cap_ref = sum(sum(EUPCRef[enduse,t,age,ec,area,LastYear] for age in Ages) for t in Techs, area in areas)
        
        if total_cap > 0 || total_cap_ref > 0
          ZZZ = sum(zDEM[enduse,t,ec,area]*sum(EUPC[enduse,t,age,ec,area,LastYear] for age in Ages) 
                   for t in Techs, area in areas) / max(total_cap, 1e-12) * Conversion[nation]
          CCC = sum(zDEMRef[enduse,t,ec,area]*sum(EUPCRef[enduse,t,age,ec,area,LastYear] for age in Ages) 
                   for t in Techs, area in areas) / max(total_cap_ref, 1e-12) * Conversion[nation]
          
          if ZZZ != 0 || CCC != 0
            println(iob,"zDEM;",NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
          end
        end
        
        # Area-level outputs
        for area in areas
          total_cap_area = sum(sum(EUPC[enduse,t,age,ec,area,LastYear] for age in Ages) for t in Techs)
          total_cap_ref_area = sum(sum(EUPCRef[enduse,t,age,ec,area,LastYear] for age in Ages) for t in Techs)
          
          if total_cap_area > 0 || total_cap_ref_area > 0
            ZZZ = sum(zDEM[enduse,t,ec,area]*sum(EUPC[enduse,t,age,ec,area,LastYear] for age in Ages) 
                     for t in Techs) / max(total_cap_area, 1e-12) * Conversion[nation]
            CCC = sum(zDEMRef[enduse,t,ec,area]*sum(EUPCRef[enduse,t,age,ec,area,LastYear] for age in Ages) 
                     for t in Techs) / max(total_cap_ref_area, 1e-12) * Conversion[nation]
            
            if ZZZ != 0 || CCC != 0
              println(iob,"zDEM;",AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
            end
          end
        end
      end
    end
  end

  # Second loop: Enduse → Tech with sector-level aggregation
  for enduse in Enduses
    for tech in Techs
      # Calculate sector-wide averages
      total_cap = sum(sum(EUPC[enduse,t,age,ec,area,LastYear] for age in Ages) for t in Techs, ec in ECs, area in areas)
      total_cap_ref = sum(sum(EUPCRef[enduse,t,age,ec,area,LastYear] for age in Ages) for t in Techs, ec in ECs, area in areas)
      
      if total_cap > 0 || total_cap_ref > 0
        ZZZ = sum(zDEM[enduse,t,ec,area]*sum(EUPC[enduse,t,age,ec,area,LastYear] for age in Ages) 
                 for t in Techs, ec in ECs, area in areas) / max(total_cap, 1e-12) * Conversion[nation]
        CCC = sum(zDEMRef[enduse,t,ec,area]*sum(EUPCRef[enduse,t,age,ec,area,LastYear] for age in Ages) 
                 for t in Techs, ec in ECs, area in areas) / max(total_cap_ref, 1e-12) * Conversion[nation]
        
        if ZZZ != 0 || CCC != 0
          println(iob,"zDEM;",NationDS[nation],";",SectorDS[1],";",TechDS[tech],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
        end
      end
      
      # Area-level sector outputs
      for area in areas
        total_cap_area = sum(sum(EUPC[enduse,t,age,ec,area,LastYear] for age in Ages) for t in Techs, ec in ECs)
        total_cap_ref_area = sum(sum(EUPCRef[enduse,t,age,ec,area,LastYear] for age in Ages) for t in Techs, ec in ECs)
        
        if total_cap_area > 0 || total_cap_ref_area > 0
          ZZZ = sum(zDEM[enduse,t,ec,area]*sum(EUPC[enduse,t,age,ec,area,LastYear] for age in Ages) 
                   for t in Techs, ec in ECs) / max(total_cap_area, 1e-12) * Conversion[nation]
          CCC = sum(zDEMRef[enduse,t,ec,area]*sum(EUPCRef[enduse,t,age,ec,area,LastYear] for age in Ages) 
                   for t in Techs, ec in ECs) / max(total_cap_ref_area, 1e-12) * Conversion[nation]
          
          if ZZZ != 0 || CCC != 0
            println(iob,"zDEM;",AreaDS[area],";",SectorDS[1],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zDEM-$segment_name-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do file
    write(file, String(take!(iob)))
  end
end

function zDEM_DtaControl(db)
  @info "zDEM_DtaControl"

  # Process CN for all segments
  CN = Select(ReadDisk(db, "MainDB/NationKey"),"CN")
  
  # Process Residential segment for CN
  res_data = zDEMResidentialData(; db)
  zDEM_DtaRun(res_data,CN,"Residential")

  # Process Commercial segment for CN  
  com_data = zDEMCommercialData(; db)
  zDEM_DtaRun(com_data,CN,"Commercial")

  # Process Industrial segment for CN
  ind_data = zDEMIndustrialData(; db)
  zDEM_DtaRun(ind_data,CN,"Industrial")

  # Process US for all segments
  US = Select(ReadDisk(db, "MainDB/NationKey"),"US")
  
  # Process Residential segment for US
  zDEM_DtaRun(res_data,US,"Residential")

  # Process Commercial segment for US  
  zDEM_DtaRun(com_data,US,"Commercial")

  # Process Industrial segment for US
  zDEM_DtaRun(ind_data,US,"Industrial")
end
if abspath(PROGRAM_FILE) == @__FILE__
  zDEM_DtaControl(DB)
end
