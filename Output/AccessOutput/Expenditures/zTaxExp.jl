#
# zTaxExp.jl - Write Device Investments for Access Database
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

Base.@kwdef struct zTaxExpData
  db::String
  
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  zTaxExp::VariableArray{4} = ReadDisk(db,"SOutput/TaxExp") #[Fuel,ECC,Area,Year] Tax Expenditure (M$/Yr)
  zTaxExpRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/TaxExp") #[Fuel,ECC,Area,Year] Tax Expenditure (M$/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zTaxExp(data)
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

function zTaxExp_DtaRun(data,nation,nationkey)
  (; Area,AreaDS,ECC,ECCDS,ECCs) = data
  (; Fuels,Nation,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,SceName,zTaxExp,zTaxExpRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    zTaxExpRef .= zTaxExp
  end
  
  for ecc in ECCs
    for area in areas
      for year in years
        ZZZ[year] = sum(zTaxExp[fuel,ecc,area,year] for fuel in Fuels)*Conversion[nation,year]
        CCC[year] = sum(zTaxExpRef[fuel,ecc,area,year] for fuel in Fuels)*Conversion[nation,year]
        if ZZZ[year] != 0.0 || CCC[year] != -0.0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zTaxExp;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
            CDTime,UnitsDS[nation],";",zData,";",zInitial)
        end
      end # for year
    end #for area
  end # for ecc

  filename = "zTaxExp-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end


end # function zTaxExp_DtaRun


function zTaxExp_DtaControl(db)
  data = zTaxExpData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zTaxExp_DtaControl"
  AssignConversions_zTaxExp(data)
  for nation in Nations
    if NationOutputMap[nation] == 1
      zTaxExp_DtaRun(data,nation,Nation[nation])
    end
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
  zTaxExp_DtaControl(DB)
end
