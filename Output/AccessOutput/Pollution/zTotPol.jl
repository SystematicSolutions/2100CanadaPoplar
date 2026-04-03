#
# zTotPol.jl
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

Base.@kwdef struct zTotPolData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))  
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  PolConv::VariableArray{1}  = ReadDisk(db,"SInput/PolConv")  #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PollType::SetArray = ReadDisk(db,"MainDB/PollType") # [Poll] "Pollution Type - CAC/GHG/Neither(Name)","Name")
  zTotPol::VariableArray{4} = ReadDisk(db,"SOutput/TotPol")  #[ECC,Poll,Area,Year]  Pollution (Tonnes/Yr)
  zTotPolRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/TotPol")  #[ECC,Poll,Area,Year]  Pollution (Tonnes/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion = zeros(Float32,length(Poll)) # [Poll] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Poll)) # [Poll] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zTotPol_DtaRun(data,polls,nation)
  (; AreaDS,ECC,ECCDS,ECCs,Nation,Poll,PollDS,Polls,Year) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime,PolConv,PollType) = data
  (; UnitsDS,zTotPol,zTotPolRef,ZZZ,SceName) = data

  if BaseSw != 0
    @. zTotPolRef = zTotPol
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Pollutant;Sector;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  for poll in Polls
    Conversion[poll] = 0.001
    UnitsDS[poll] = "Kilotonnes"
    if Poll[poll] == "Hg"
      Conversion[poll] = 1000
      UnitsDS[poll] = "Kilograms"
    end
  end

  for ecc in ECCs
    for poll in polls
      for area in areas
        for year in years
          ZZZ[year] = zTotPol[ecc,poll,area,year]*Conversion[poll]
          CCC[year] = zTotPolRef[ecc,poll,area,year]*Conversion[poll]
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zTotPol;",Year[year],";",AreaDS[area],";",PollDS[poll],";",
              ECCDS[ecc],";",UnitsDS[poll],";",zData,";",zInitial)
          end
        end
      end
    end
  end

  polltype = first(PollType[polls])
  pollunit = first(UnitsDS[polls])

  if polltype == "CO2"
    polltype = "GHG"
  elseif polltype == "SOX"
    polltype = "CAC"
  end 

  if polltype == "GHG"
    for ecc in ECCs
      for area in areas
        for year in years
          ZZZ[year] = sum(zTotPol[ecc,poll,area,year]*PolConv[poll] for poll in polls)/1000
          CCC[year] = sum(zTotPolRef[ecc,poll,area,year]*PolConv[poll] for poll in polls)/1000
          if ZZZ[year] != 0.0 || CCC[year] != 0.0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zTotPol;",Year[year],";",AreaDS[area],";",polltype,";",
              ECCDS[ecc],";",pollunit,";",zData,";",zInitial)
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zTotPol-$polltype-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zTotPol_DtaControl(db)
  data = zTotPolData(; db)
  (; db,Nation,Nations,Poll)= data
  (; ANMap,NationOutputMap)= data

  @info "zTotPol_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      polls = Select(Poll,["SOX","COX","NOX","PMT","VOC","PM25","PM10","Hg","NH3","BC"])
      zTotPol_DtaRun(data,polls,nation)
    
      polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
      zTotPol_DtaRun(data,polls,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zTotPol_DtaControl(DB)
end
