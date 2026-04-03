#
# zTrFsDmd.jl
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

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FsFrac::VariableArray{5} = ReadDisk(db,"$Outpt/FsFrac") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  FsFracRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/FsFrac") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zTrFsDmd::VariableArray{4} = ReadDisk(db,"$Outpt/FsDmd") # Feedstock Energy Demand (TBtu/Yr) [Tech,EC,Area]
  zTrFsDmdRef::VariableArray{4} = ReadDisk(RefNameDB,"$Outpt/FsDmd") # Feedstock Energy Demand (TBtu/Yr) [Tech,EC,Area]

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray{1} = zeros(Float32,length(Year))
  ZZZ::VariableArray{1} = zeros(Float32,length(Year))
end

function zTrFsDmd_DtaRun(data,nation)
  (; AreaDS,EC,ECDS,ECs,FuelDS,Fuels,TechDS,Techs) = data
  (; Nation,Year) = data
  (; ANMap,CCC,Conversion,EndTime) = data
  (; UnitsDS,zTrFsDmd,zTrFsDmdRef,FsFrac,FsFracRef,ZZZ,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "TBtu/Yr"
    Conversion[CN,year] = 1.054615*1000
    UnitsDS[CN] = "TJ/Yr"
  end

  for year in years
    for area in areas
      for ec in ECs
        for tech in Techs
          for fuel in Fuels
            ZZZ[year] = zTrFsDmd[tech,ec,area,year]*FsFrac[fuel,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zTrFsDmdRef[tech,ec,area,year]*FsFracRef[fuel,tech,ec,area,year]*Conversion[nation,year]
            if (ZZZ[year] > 0.000001) || (CCC[year] > 0.000001)
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zTrFsDmd;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                TechDS[tech],";",FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
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
  filename = "zTrFsDmd-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zTrFsDmd_DtaControl(db)
  data = TControl(; db)
  (; Nations)= data
  (; NationOutputMap)= data

  @info "zTrFsDmd_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zTrFsDmd_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zTrFsDmd_DtaControl(DB)
end
