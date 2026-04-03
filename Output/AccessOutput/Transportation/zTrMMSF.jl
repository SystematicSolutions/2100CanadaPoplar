#
# zTrMMSF.jl
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

Base.@kwdef struct zTrMMSFData
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
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
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
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  VDTRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  zTrMMSF::VariableArray{5} = ReadDisk(db, "$Outpt/MMSF") #[Enduse,Tech,EC,Area,Year]  Market Share Fraction by Device ($/$)
  zTrMMSFRef::VariableArray{5} = ReadDisk(RefNameDB, "$Outpt/MMSF") #[Enduse,Tech,EC,Area,Year]  Market Share Fraction by Device ($/$)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Convert::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray{1} = zeros(Float32,length(Year))
  ZZZ::VariableArray{1} = zeros(Float32,length(Year))
end

function zTrMMSF_DtaRun(data,nation)
  (; AreaDS,EC,ECDS,ECs,Enduses,FuelDS,Fuels,TechDS,Techs) = data
  (; Nation,NationDS,Year) = data
  (; ANMap,CCC,EndTime) = data
  (; UnitsDS,VDTRef,zTrMMSF,zTrMMSFRef,ZZZ,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    UnitsDS[US] = "Marginal Market Share Fraction (\$/\$)"
    UnitsDS[CN] = "Marginal Market Share Fraction (\$/\$)"
  end
  
  enduse = 1 # One enduse in Transportation

  for tech in Techs, ec in ECs, area in areas, year in years
    VDTRef[enduse,tech,ec,area,year] = max(VDTRef[enduse,tech,ec,area,year],0.0)
  end

  for tech in Techs
    for ec in ECs
      for area in areas
        for year in years
          ZZZ[year] = zTrMMSF[enduse,tech,ec,area,year]
          CCC[year] = zTrMMSFRef[enduse,tech,ec,area,year]
          if (ZZZ[year] != 0) || (CCC[year] != 0)
            println(iob,"zTrMMSF;",Year[year],";",AreaDS[area],";",ECDS[ec],";", TechDS[tech],";",
            UnitsDS[nation],";",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
          end
        end
      end
    end
  end

  for tech in Techs
    for ec in ECs
      for year in years
        ZZZ[year] = sum(zTrMMSF[enduse,tech,ec,area,year]*VDTRef[enduse,tech,ec,area,year] for area in areas)/
                    sum(VDTRef[enduse,tech,ec,area,year] for area in areas)
        CCC[year] = sum(zTrMMSFRef[enduse,tech,ec,area,year]*VDTRef[enduse,tech,ec,area,year] for area in areas)/
                    sum(VDTRef[enduse,tech,ec,area,year] for area in areas)
        if (ZZZ[year] != 0) || (CCC[year] != 0)
          println(iob,"zTrMMSF;",Year[year],";",NationDS[nation],";",ECDS[ec],";", TechDS[tech],";",
          UnitsDS[nation],";",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
        end
       end
    end
  end  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zTrMMSF-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zTrMMSF_DtaControl(db)
  data = zTrMMSFData(; db)
  (; Nations)= data
  (; NationOutputMap)= data

  @info "zTrMMSF_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zTrMMSF_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zTrMMSF_DtaControl(DB)
end
