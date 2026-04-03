#
# zFsPOCX.jl
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

# Transportation Sector Data Structure
Base.@kwdef struct TzFsPOCXData
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zFsPOCX::VariableArray{6} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,Tech,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)
  zFsPOCXRef::VariableArray{6} = ReadDisk(RefNameDB,"$Input/FsPOCX") # [Fuel,Tech,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # Pollution Conversion Factor (convert GHGs to eCO2)

  #
  # Scratch Variables
  #
  Conversion::VariableArray{1} = zeros(Float32,length(Poll)) # [Poll] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Poll)) # [Poll] Units Description

end


function initialize_conversion_data(data)
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
    "SOX" => "Tonnes/TBtu", "NOX" => "Tonnes/TBtu", "PMT" => "Tonnes/TBtu", 
    "VOC" => "Tonnes/TBtu", "N2O" => "Tonnes/TBtu", "COX" => "Tonnes/TBtu", 
    "CO2" => "Tonnes/TBtu", "CH4" => "Tonnes/TBtu", "SF6" => "Tonnes/TBtu", 
    "PFC" => "Tonnes/TBtu", "HFC" => "Tonnes/TBtu", "PM25" => "Tonnes/TBtu",
    "PM10" => "Tonnes/TBtu", "Hg" => "Grams/TBtu", "O3" => "Tonnes/TBtu", 
    "NH3" => "Tonnes/TBtu", "H2O" => "Tonnes/TBtu", "BC" => "Tonnes/TBtu", 
    "NF3" => "Tonnes/TBtu"
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

function zFsPOCX_DtaRun_Transportation(db, nation, polls, polltype)
  data = TzFsPOCXData(; db)
  (; Area, AreaDS, Areas, EC, ECDS, ECs, Fuel, FuelDS, Fuels, SceName) = data
  (; Nation, NationDS, Nations, Poll, PollDS, Polls, Tech, TechDS, Techs, Year) = data
  (; ANMap, BaseSw, Conversion, EndTime, UnitsDS, zFsPOCX, zFsPOCXRef, NationOutputMap) = data
  
  initialize_conversion_data(data)

  if BaseSw != 0
    @. zFsPOCXRef = zFsPOCX
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Pollutant;Sector;Technology;Fuel;Units;zData;zInitial")

  # Select specific years (2005,2010,2015,2020,2025,2030,2035,2040,2045,2050)
  selected_years = [2005, 2010, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050]
  years = [Yr(year) for year in selected_years if Yr(year) <= length(Year)]
  
  areas = findall(ANMap[Areas,nation] .== 1)

  if NationOutputMap[nation] == 1
    for year in years
      for fuel in Fuels
        for tech in Techs
          for ec in ECs
            for poll in polls
              for area in areas
                ZZZ = zFsPOCX[fuel,tech,ec,poll,area,year] * Conversion[poll]
                CCC = zFsPOCXRef[fuel,tech,ec,poll,area,year] * Conversion[poll]
                
                if ZZZ > 0.01 || CCC > 0.01
                  println(iob,"zFsPOCX;",Year[year],";",AreaDS[area],";",PollDS[poll],";",
                    ECDS[ec],";",TechDS[tech],";",FuelDS[fuel],";",UnitsDS[poll],";",
                    @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
                end
              end
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
  filename = "zFsPOCX_Trans-$polltype-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end


function zFsPOCX_Trans_DtaControl(db)
  @info "zFsPOCX_DtaControl"
  data = TzFsPOCXData(; db)
  (; Nation,Nations,Poll) = data

  # Select specific pollutants (SOX,COX,NOX,PMT,VOC,PM25,PM10,Hg,NH3,BC)
  polls = Select(Poll,["SOX", "COX", "NOX", "PMT", "VOC", "PM25", "PM10", "Hg", "NH3", "BC"])
  PollType = "CAC"

  nations = Select(Nation,["CN", "US"])

  for nation in nations

    zFsPOCX_DtaRun_Transportation(db, nation, polls, PollType)
    
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zFsPOCX_Trans_DtaControl(DB)
end
