#
# zGCCC.jl
# Cost of Energy from New Capacity ($/kW)
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

  
Base.@kwdef struct zGCCCData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Power::SetArray = ReadDisk(db, "MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db, "MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] # Ending Year for Simulation (Year)
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  EGPA::VariableArray{3} = ReadDisk(db, "EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  EGPARef::VariableArray{3} = ReadDisk(RefNameDB, "EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  GCCC::VariableArray{3} = ReadDisk(db, "EGOutput/GCCC") # [Plant,Area,Year] Generation Capac. Capital Costs ($/KW)
  GCCCRef::VariableArray{3} = ReadDisk(RefNameDB, "EGOutput/GCCC") # [Plant,Area,Year] Generation Capac. Capital Costs ($/KW)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationRef::VariableArray{2} = ReadDisk(RefNameDB, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") # [Nation] Map for Output Control by Nation (0=No Output)(Map)

end

function zGCCC_InitializeOutFile(data, nation)
  (; BaseSw, GCCCRef, EGPARef, InflationRef, SceName) = data
  
  if BaseSw != 0
    @. GCCCRef = data.GCCC
    @. EGPARef = data.EGPA
    @. InflationRef = data.Inflation
  end

  iob = IOBuffer()
  println(iob, "Variable;Year;Area;Plant;Power;Units;zData;zInitial")
  
  return iob
end

function zGCCC_DtaRunArea(data, nation,  iob, area)
  (; AreaDS, PlantDS, PowerDS, Plants, Powers, Year, EndTime, CDTime) = data
  (; GCCC, GCCCRef, Inflation, InflationRef,SceName) = data

  # overnight Construction Cost
  # Select Plant*, Power(Base)
  base_power = Select(data.Power, "Base")
  
  years = collect(1:Yr(EndTime))
  
  for year in years
    for plant in Plants
      # Filter out extremely high values
      gccc_val = min(GCCC[plant, area, year], 1E6)
      gccc_ref_val = min(GCCCRef[plant, area, year], 1E6)
      
      # Fixed Cost ($/MWh)
      cdyear_idx = Yr(CDTime)
      ZZZ = gccc_val / Inflation[area, year] * Inflation[area, cdyear_idx]
      CCC = gccc_ref_val / InflationRef[area, year] * InflationRef[area, cdyear_idx]
      
      if ZZZ != 0 || CCC != 0
        println(iob, "zGCCC;", Year[year], ";", AreaDS[area], ";", PlantDS[plant], ";", 
               PowerDS[base_power], ";CN\$", CDTime, "/kW;", @sprintf("%.6E", ZZZ), ";", @sprintf("%.6E", CCC))
      end
    end
  end
end

function zGCCC_DtaRunNational(data, nation,  iob, areas, area_name)
  (; PlantDS, PowerDS, Plants, Powers, Year, EndTime, CDTime,SceName) = data
  (; GCCC, GCCCRef, Inflation, InflationRef, EGPA, EGPARef) = data

  # overnight Construction Cost
  # Select Plant*, Power(Base)
  base_power = Select(data.Power, "Base")
  
  years = collect(1:Yr(EndTime))
  
  for year in years
    for plant in Plants
      # Filter out extremely high values and calculate weighted averages
      numerator_zzz = 0.0
      numerator_ccc = 0.0
      denominator_zzz = 0.0
      denominator_ccc = 0.0
      
      cdyear_idx = Yr(CDTime)
      
      for area in areas
        gccc_val = min(GCCC[plant, area, year], 1E6)
        gccc_ref_val = min(GCCCRef[plant, area, year], 1E6)
        
        # Weighted by electricity generation
        weight_zzz = EGPA[plant, area, year]
        weight_ccc = EGPARef[plant, area, year]
        
        numerator_zzz += (gccc_val / Inflation[area, year] * Inflation[area, cdyear_idx]) * weight_zzz
        numerator_ccc += (gccc_ref_val / InflationRef[area, year] * InflationRef[area, cdyear_idx]) * weight_ccc
        
        denominator_zzz += weight_zzz
        denominator_ccc += weight_ccc
      end
      
      ZZZ = denominator_zzz > 0 ? numerator_zzz / denominator_zzz : 0.0
      CCC = denominator_ccc > 0 ? numerator_ccc / denominator_ccc : 0.0
      
      if ZZZ != 0 || CCC != 0
        println(iob, "zGCCC;", Year[year], ";", area_name, ";", PlantDS[plant], ";", 
               PowerDS[base_power], ";CN\$", CDTime, "/kW;", @sprintf("%.6E", ZZZ), ";", @sprintf("%.6E", CCC))
      end
    end
  end
end

function zGCCC_DtaControl(db)
  data = zGCCCData(; db)
  (; Nation, Nations, Area, Areas, AreaDS) = data
  (; ANMap, NationOutputMap, EndTime,SceName) = data

  @info "zGCCC_DtaControl"

  # Select Year(1986-Final)
  years = collect(Yr(1986):Yr(EndTime))
  
  for nation in Nations
    if NationOutputMap[nation] == 1
      nationkey = Nation[nation]
      
      # Find areas for this nation
      areas = findall(ANMap[:, nation] .== 1)
      
      # Initialize output file
      iob = zGCCC_InitializeOutFile(data, nation)
      
      # Process each area
      for area in areas
        zGCCC_DtaRunArea(data, nation, iob, area)
      end
      
      # National Weighted Average
      if nationkey == "CN"
        area_name = "Canada"
      elseif nationkey == "US"
        area_name = "United States"
      else
        area_name = nationkey
      end
      
      zGCCC_DtaRunNational(data, nation, iob, areas, area_name)
      
      # Create *.dta filename and write output values
      filename = "zGCCC-$nationkey-$SceName.dta"
      open(joinpath(OutputFolder, filename), "w") do file
        write(file, String(take!(iob)))
      end
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  zGCCC_DtaControl(DB)
end
