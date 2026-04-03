#
# zDmdNet.jl - Write Enduse Demands for Access Database
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

Base.@kwdef struct zDmdNet_SControl
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
  
  StPur::VariableArray{3} = ReadDisk(db,"SOutput/StPur") #[ECC,Area,Year]  Net Steam Purchases (tBtu/Yr)
  StPurRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/StPur") #[ECC,Area,Year]  Net Steam Purchases (tBtu/Yr)
  StSold::VariableArray{3} = ReadDisk(db,"SOutput/StSold") # Excess Steam Generated (tBtu/Yr) [ECC,Area]
  StSoldRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/StSold") # Excess Steam Generated (tBtu/Yr) [ECC,Area]
  zTotDemand::VariableArray{4} = ReadDisk(db,"SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  zTotDemandRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)

  #
  # Scratch Variables
  #
  DmdNet::VariableArray{4} = zeros(Float32,length(Fuel),length(ECC),length(Area),length(Year)) # [Fuel,ECC,Area,Year] Net Energy Demand (TBtu/Yr)
  DmdNetRef::VariableArray{4} = zeros(Float32,length(Fuel),length(ECC),length(Area),length(Year)) # [Fuel,ECC,Area,Year] Net Energy Demand (TBtu/Yr)
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zDmdNet_AssignConversions(data)
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

function zDmdNet_DtaRun(data,TitleKey,nation)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs) = data
  (; Fuel,FuelDS,Fuels,Nation,Year) = data
  (; ANMap,BaseSw,EndTime,StPur,StPurRef,StSold,StSoldRef,zTotDemand,zTotDemandRef) = data
  (; DmdNet,DmdNetRef,Conversion,UnitsDS,CCC,ZZZ,SceName) = data

  if BaseSw != 0
    @. StPurRef = StPur
    @. StSoldRef = StSold
    @. zTotDemandRef = zTotDemand
  end

  iob = IOBuffer()

  println(iob,"Variable;Year;Area;Sector;Fuel;Units;zData;zInitial")

  years = collect(Yr(1985):Final)
  areas = findall(ANMap[Areas,nation] .== 1)
  #
  # Note for electricity TotDemand is Net Electricity Demands
  #
  @. DmdNet=zTotDemand
  @. DmdNetRef=zTotDemandRef

  fuel=Select(Fuel,"Steam")
  for year in years, area in areas, ecc in ECCs
    DmdNet[fuel,ecc,area,year]=StPur[ecc,area,year]-StSold[ecc,area,year]
    DmdNetRef[fuel,ecc,area,year]=StPurRef[ecc,area,year]-StSoldRef[ecc,area,year]
  end

  for year in years
    for area in areas
      for ecc in ECCs
        for fuel in Fuels
          ZZZ[year] = DmdNet[fuel,ecc,area,year]*Conversion[nation,year]
          CCC[year] = DmdNetRef[fuel,ecc,area,year]*Conversion[nation,year]
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          if ZZZ[year] != 0.0 || CCC[year] != 0.0
            println(iob,"zDmdNet;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
              FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for fuel
      end # for ecc
    end # for area
  end # for year

  filename = "zDmdNet-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function zDmdNet_DtaControl(db)
  data = zDmdNet_SControl(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zDmdNet_DtaControl"

  zDmdNet_AssignConversions(data)
  for nation in Nations
    if NationOutputMap[nation] == 1
      zDmdNet_DtaRun(data,Nation[nation],nation)
    end
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
  zDmdNet_DtaControl(DB)
end
