#
# zPNeed.jl
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

Base.@kwdef struct zPNeedData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zPNeed::VariableArray{4} = ReadDisk(db,"SOutput/PNeed") # [ECC,Poll,Area,Year] Permits Needed)
  zPNeedRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/PNeed") # [ECC,Poll,Area,Year] Permits Needed)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zPNeed_DtaRun(data,nation)
  (; Area,AreaDS,Areas,ECCDS,ECCs,Nation,NationDS,Nations) = data
  (; Polls,PollDS,Year,SceName) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime,UnitsDS,zPNeed,zPNeedRef,ZZZ) = data

  if BaseSw != 0
    @. zPNeedRef = zPNeed
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;ECC;Poll;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "Tonnes/Yr"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "Tonnes/Yr"
  end

  for area in areas
    for ecc in ECCs
      for poll in Polls
        for year in years
          ZZZ[year] = zPNeed[ecc,poll,area,year]*Conversion[nation,year]
          CCC[year] = zPNeedRef[ecc,poll,area,year]*Conversion[nation,year]
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zPNeed;",Year[year],";",AreaDS[area],";",
              ECCDS[ecc],";",PollDS[poll],";",
              UnitsDS[nation],";",zData,";",zInitial)
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zPNeed-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zPNeed_DtaControl(db)
  data = zPNeedData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zPNeed_DtaControl"

  for nation in Nations
#
# Output regardless of map to get CA results - Ian 12/2/25
#
#    if NationOutputMap[nation] == 1
      zPNeed_DtaRun(data,nation)
#    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zPNeed_DtaControl(DB)
end
