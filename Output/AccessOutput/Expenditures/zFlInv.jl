#
# zFlInv.jl - Write Device Investments for Access Database
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

Base.@kwdef struct zFlInvData
  db::String
  
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zFlInv::VariableArray{3} = ReadDisk(db,"SOutput/FlInv") #[ECC,Area,Year] Flaring Reduction Investments (M$/Yr)
  zFlInvRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/FlInv") #[ECC,Area,Year] Flaring Reduction Investments (M$/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zFlInv(data)
  (; Nation,Years,CDYear,Conversion,InflationNation,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
    Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]
  end

  UnitsDS[US] = " US M\$/Yr"
  UnitsDS[CN] = " CN M\$/Yr"
end

function zFlInv_DtaRun(data,nation,nationkey)
  (; Area,AreaDS,ECC,ECCDS,ECCs) = data
  (; Nation,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,SceName,zFlInv,zFlInvRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    zFlInvRef .= zFlInv
  end
  
  for ecc in ECCs
    for area in areas
      for year in years
        ZZZ[year] = zFlInv[ecc,area,year]*Conversion[nation,year]
        CCC[year] = zFlInvRef[ecc,area,year]*Conversion[nation,year]
        if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zFlInv;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
            CDTime,UnitsDS[nation],";",zData,";",zInitial)
        end
      end # for year
    end #for area
  end # for ecc

  filename = "zFlInv-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end


end # function zFlInv_DtaRun


function zFlInv_DtaControl(db)
  data = zFlInvData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zFlInv_DtaControl"
  AssignConversions_zFlInv(data)
  for nation in Nations
    if NationOutputMap[nation] == 1
      zFlInv_DtaRun(data,nation,Nation[nation])
    end
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
  zFlInv_DtaControl(DB)
end
