#
# zDInvTechTrans.jl - Write Process Investments for Access Database
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
#
# Transportation
#
Base.@kwdef struct zDInvTechTransData
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
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
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
  zDInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 
  zDInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDInvTechTrans(data)
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

function zDInvTechTrans_DtaRun(data,iob,nation)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zDInvTech,zDInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    zDInvTechRef .= zDInvTech
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zDInvTech[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zDInvTechRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            
            if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zDInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                EnduseDS[enduse],";",TechDS[tech],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech
        end # for ec
      end # for area
    end #for year
  end # for enduse
end # function zDInvTechTrans_DtaRun


function zDInvTech_Transport(db,iob,nation)
  data = zDInvTechTransData(; db)
  AssignConversions_zDInvTechTrans(data)
  zDInvTechTrans_DtaRun(data,iob,nation)
end

function CreateDInvTechTransOutputFile(db,iob,nationkey,SceName)
  filename = "zDInvTechTrans-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zDInvTechTrans_DtaControl(db)
  data = zDInvTechTransData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zDInvTechTrans_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Enduse;Technology;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDInvTech_Transport(db,iob,nation)

      CreateDInvTechTransOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zDInvTechTrans_DtaControl(DB)
end
