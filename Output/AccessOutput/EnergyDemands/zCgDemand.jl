#
# zCgDemand.jl - Write Enduse Demands for Access Database
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

Base.@kwdef struct zCgDemand_ED_SControl
  db::String
  
  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  zCgDemand::VariableArray{4} = ReadDisk(db,"SOutput/CgDemand") #[Fuel,ECC,Area,Year]  Cogeneration Energy Demands (TBtu/Yr)
  zCgDemandRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/CgDemand") #[Fuel,ECC,Area,Year]  Cogeneration Energy Demands (TBtu/Yr)

  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zCgDemand_ED_AssignConversions(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1*1.054615*1000
  end

  UnitsDS[US] = "TBtu/Yr"
  UnitsDS[CN] = "TJ/Yr"
end

function zCgDemand_ED_DtaRun(data,TitleKey,nation)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs) = data
  (; Fuel,FuelDS,Fuels,Nation,Year) = data
  (; ANMap,BaseSw,EndTime,zCgDemand,zCgDemandRef) = data
  (; Conversion,UnitsDS,CCC,ZZZ,SceName) = data

  if BaseSw != 0
    @. zCgDemandRef = zCgDemand
  end

  iob = IOBuffer()

  println(iob,"Variable;Year;Area;Sector;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for year in years
    for area in areas
      for ecc in ECCs
        for fuel in Fuels
          ZZZ[year] = zCgDemand[fuel,ecc,area,year]*Conversion[nation,year]
          CCC[year] = zCgDemandRef[fuel,ecc,area,year]*Conversion[nation,year]
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          if ZZZ[year] != 0.0 || CCC[year] != 0.0
            println(iob,"zCgDemand;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
              FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for fuel
      end # for ecc
    end # for area
  end # for year

  filename = "zCgDemand_ED-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end


function zCgDemand_ED_DtaControl(db)
  data = zCgDemand_ED_SControl(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zCgDemand_DtaControl"

  zCgDemand_ED_AssignConversions(data)
  for nation in Nations
    if NationOutputMap[nation] == 1
      zCgDemand_ED_DtaRun(data,Nation[nation],nation)
    end
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
  zCgDemand_ED_DtaControl(DB)
end
