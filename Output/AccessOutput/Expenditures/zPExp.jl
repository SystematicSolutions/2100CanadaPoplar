#
# zPExp.jl
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

Base.@kwdef struct zPExpData
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
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPExp::VariableArray{4} = ReadDisk(db, "SOutput/PExp") # [ECC,Poll,Area,Year] Permits Expenditures (M$/Yr)
  zPExpRef::VariableArray{4} = ReadDisk(RefNameDB, "SOutput/PExp") # [ECC,Poll,Area,Year] Permits Expenditures (M$/Yr)
  zPExpExo::VariableArray{4} = ReadDisk(db, "SInput/PExpExo") # [ECC,Poll,Area,Year] Exogenous Permits Expenditures (M$/Year)
  zPExpExoRef::VariableArray{4} = ReadDisk(RefNameDB, "SInput/PExpExo") # [ECC,Poll,Area,Year] Exogenous Permits Expenditures (M$/Year)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zPExp_DtaRun(data,nation)
  (; Area,AreaDS,ECCs,ECCDS,Areas,Nation,Polls,Year) = data
  (; ANMap,BaseSw,CDTime,CDYear,Conversion,EndTime,InflationNation,SceName) = data
  (; UnitsDS,zPExp,zPExpRef,zPExpExo,zPExpExoRef) = data

  if BaseSw != 0
    @. zPExpRef = zPExp
    @. zPExpExoRef = zPExpExo
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")


  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0/InflationNation[US,year]*InflationNation[US,CDYear]
    UnitsDS[US] = " US M\$/Yr"
    Conversion[CN,year] = 1.0/InflationNation[CN,year]*InflationNation[CN,CDYear]
    UnitsDS[CN] = " CN M\$/Yr"
  end

  for ecc in ECCs
    for area in areas
      for year in years
        ZZZ = sum(zPExp[ecc,poll,area,year]+zPExpExo[ecc,poll,area,year] for poll in Polls)*Conversion[nation,year]
        CCC = sum(zPExpRef[ecc,poll,area,year]+zPExpExoRef[ecc,poll,area,year] for poll in Polls)*Conversion[nation,year]
        if ZZZ != 0 || CCC != 0
          println(iob,"zPExp;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",CDTime,UnitsDS[nation],";",
            @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zPExp-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zPExp_DtaControl(db)
  data = zPExpData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zPExp_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zPExp_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zPExp_DtaControl(DB)
end
