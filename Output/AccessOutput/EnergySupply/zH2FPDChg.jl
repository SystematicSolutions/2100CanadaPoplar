#
# H2FPDChg.jl
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

Base.@kwdef struct H2FPDChgData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db, "MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  H2Tech::SetArray = ReadDisk(db,"MainDB/H2TechKey")
  H2TechDS::SetArray = ReadDisk(db,"MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  H2FPDChg::VariableArray{3} = ReadDisk(db,"SpInput/H2FPDChg") # [ES,Area,Year] Hydrogen Fuel Delivery Charge (Real $/mmBtu)
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

function zH2FPDChg_DtaRun(data,nation)
  (; Area,AreaDS,Areas,Nation,NationDS,Nations) = data
  (; H2Tech,H2TechDS,H2Techs,Year,SceName,ES,ESs) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime,UnitsDS,ESDS,H2FPDChg,H2FPDChg,ZZZ) = data

  if BaseSw != 0
    @. H2FPDChg = H2FPDChg
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  ess = Select(ES,(from = "Residential",to = "Transport"))

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "\$/mmBtu"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "\$/mmBtu"
  end

  for es in ess
    for area in areas
      for year in years
        ZZZ[year] = H2FPDChg[es,area,year]*Conversion[nation,year]
        CCC[year] = H2FPDChg[es,area,year]*Conversion[nation,year]
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"H2FPDChg;",Year[year],";",AreaDS[area],";",
            ESDS[es],";",UnitsDS[nation],";",zData,";",zInitial)
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zH2FPDChg-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zH2FPDChg_DtaControl(db)
  data = H2FPDChgData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zH2FPDChg_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zH2FPDChg_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zH2FPDChg_DtaControl(DB)
end
