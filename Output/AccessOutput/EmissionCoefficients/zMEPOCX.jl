#
# zMEPOCX.jl
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

Base.@kwdef struct MzMEPOCXData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  
  MEInput::String = "MEInput"
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zMEPOCX::VariableArray{4} = ReadDisk(db, "$MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/$B-output)
  zMEPOCXRef::VariableArray{4} = ReadDisk(RefNameDB, "$MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/$B-output)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # Pollution Conversion Factor (convert GHGs to eCO2)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{1} = zeros(Float32,length(Poll)) # [Poll] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Poll)) # [Poll] Units Description

end

function zMEPOCX_conversion_data(data)
  (; Poll, Conversion, UnitsDS) = data
  
  # Initialize conversion factors
  poll_conversions = Dict(
    "SOX" => 0.001, "NOX" => 0.001, "PMT" => 0.001, "VOC" => 0.001,
    "N2O" => 0.001, "COX" => 0.001, "CO2" => 0.001, "CH4" => 0.001,
    "SF6" => 0.001, "PFC" => 0.001, "HFC" => 0.001, "PM25" => 0.001,
    "PM10" => 0.001, "Hg" => 1000.0, "O3" => 0.001, "NH3" => 0.001,
    "H2O" => 0.001, "BC" => 0.001, "NF3" => 0.001
  )
  
  # Initialize units descriptions
  poll_units = Dict(
    "SOX" => "Tonnes/\$B-output", "NOX" => "Tonnes/\$B-output", "PMT" => "Tonnes/\$B-output", 
    "VOC" => "Tonnes/\$B-output", "N2O" => "Tonnes/\$B-output", "COX" => "Tonnes/\$B-output", 
    "CO2" => "Tonnes/\$B-output", "CH4" => "Tonnes/\$B-output", "SF6" => "Tonnes/\$B-output", 
    "PFC" => "Tonnes/\$B-output", "HFC" => "Tonnes/\$B-output", "PM25" => "Tonnes/\$B-output",
    "PM10" => "Tonnes/\$B-output", "Hg" => "Grams/\$B-output", "O3" => "Tonnes/\$B-output", 
    "NH3" => "Tonnes/\$B-output", "H2O" => "Tonnes/\$B-output", "BC" => "Tonnes/\$B-output", 
    "NF3" => "Tonnes/\$B-output"
  )
  
  for poll_idx in eachindex(Poll)
    poll_key = Poll[poll_idx]
    if haskey(poll_conversions, poll_key)
      Conversion[poll_idx] = poll_conversions[poll_key]
    else
      Conversion[poll_idx] = 1.0
    end
    
    if haskey(poll_units, poll_key)
      UnitsDS[poll_idx] = poll_units[poll_key]
    else
      UnitsDS[poll_idx] = "Units"
    end
  end
end



function zMEPOCX_DtaRun(data, nation, polls, PollType)
  (; Area, AreaDS, Areas, Nation, NationDS, Nations) = data
  (; Poll, PollDS, Polls, ECC, ECCDS, ECCs, Year,SceName) = data
  (; ANMap, BaseSw, Conversion, EndTime, UnitsDS, zMEPOCX, zMEPOCXRef, NationOutputMap) = data

  zMEPOCX_conversion_data(data)

  if BaseSw != 0
    @. zMEPOCXRef = zMEPOCX
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Pollutant;Sector;Units;zData;zInitial")

  # Select specific years (2005,2010,2015,2020,2025,2030,2035,2040,2045,2050)
  selected_years = [2005, 2010, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050]
  year_indices = [Yr(year) for year in selected_years if Yr(year) <= length(Year)]
  
  areas = findall(ANMap[Areas,nation] .== 1)

  if NationOutputMap[nation] == 1
    for year_idx in year_indices
      for ecc in ECCs
        for poll in polls
          for area in areas
            ZZZ = zMEPOCX[ecc,poll,area,year_idx] * Conversion[poll]
            CCC = zMEPOCXRef[ecc,poll,area,year_idx] * Conversion[poll]
            
            if ZZZ > 0.01 || CCC > 0.01
              println(iob,"zMEPOCX;",Year[year_idx],";",AreaDS[area],";",PollDS[poll],";",
                ECCDS[ecc],";",UnitsDS[poll],";",
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
  filename = "zMEPOCX-$PollType-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do file
    write(file, String(take!(iob)))
  end
end

function zMEPOCX_DtaControl(db)
  @info "zMEPOCX_DtaControl"
  data = MzMEPOCXData(; db)

  # Select specific pollutants (SOX,COX,NOX,PMT,VOC,PM25,PM10,Hg,NH3,BC)
  polls=Select(data.Poll,["SOX", "COX", "NOX", "PMT", "VOC", "PM25", "PM10", "Hg", "NH3", "BC"])
  PollType = "CAC"

  nations = Select(data.Nation,["CN", "US"])
  
  for nation_idx in nations
    if nation_idx > 0
      zMEPOCX_DtaRun(data, nation_idx, polls, PollType)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  zMEPOCX_DtaControl(DB)
end
