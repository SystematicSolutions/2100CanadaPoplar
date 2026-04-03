#
# zCgFPol.jl
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

Base.@kwdef struct zCgFPolData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))  
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))  

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  PolConv::VariableArray{1}  = ReadDisk(db,"SInput/PolConv")  #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PollType::SetArray = ReadDisk(db,"MainDB/PollType") # [Poll] "Pollution Type - CAC/GHG/Neither(Name)","Name")
  zCgFPol::VariableArray{5} = ReadDisk(db,"SOutput/CgFPol") #[FuelEP,ECC,Poll,Area,Year] Cogeneration Pollution (Tonnes/Yr) 
  zCgFPolRef::VariableArray{5} = ReadDisk(RefNameDB,"SOutput/CgFPol") #[FuelEP,ECC,Poll,Area,Year] Energy Related Pollution (Tonnes/Yr) 

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion = zeros(Float32,length(Poll)) # [Poll] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Poll)) # [Poll] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zCgFPol_DtaRun(data,polls,nation)
  (; AreaDS,ECC,ECCDS,ECCs,FuelEP,FuelEPDS,FuelEPs,SceName) = data
  (; Nation,Poll,PollDS,Polls,Year) = data
  (; ANMap,CCC,Conversion,EndTime,PolConv) = data
  (; PollType,UnitsDS,zCgFPol,zCgFPolRef,ZZZ) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Pollutant;Sector;Fuel;Units;zData;zInitial")

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

  for fuelep in FuelEPs
    for ecc in ECCs
      for poll in polls
        for area in areas
          for year in years
            ZZZ[year] = zCgFPol[fuelep,ecc,poll,area,year]*Conversion[poll]
            CCC[year] = zCgFPolRef[fuelep,ecc,poll,area,year]*Conversion[poll]
            if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || 
              CCC[year] > 0.0000001 || CCC[year] < -0.0000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zCgFPol;",Year[year],";",AreaDS[area],";",PollDS[poll],";",
                ECCDS[ecc],";",FuelEPDS[fuelep],";",UnitsDS[poll],";",zData,";",zInitial)
            end
          end
        end
      end
    end
  end

  polltype = first(PollType[polls])
  pollunit = first(UnitsDS[polls])
    
  #
  # TODOJulia: PollType should be "GHG" or "CAC", but right now it is equal to "Poll".
  # Update this code when database is updated. 4/22/25 R.Levesque
  #
  if polltype == "CO2"
    polltype = "GHG"
  elseif polltype == "SOX"
    polltype = "CAC"
  end 
  
  if polltype == "GHG"
    for fuelep in FuelEPs
      for ecc in ECCs
        for area in areas
          for year in years
            ZZZ[year] = sum(zCgFPol[fuelep,ecc,poll,area,year]*
              PolConv[poll] for poll in polls)/1000
            CCC[year] = sum(zCgFPolRef[fuelep,ecc,poll,area,year]*
              PolConv[poll] for poll in polls)/1000
            if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || 
              CCC[year] > 0.0000001 || CCC[year] < -0.0000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zCgFPol;",Year[year],";",AreaDS[area],";","GHG",";",
                ECCDS[ecc],";",FuelEPDS[fuelep],";",pollunit,";",zData,";",zInitial)
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
  filename = "zCgFPol-$polltype-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zCgFPol_DtaControl(db)
  data = zCgFPolData(; db)
  (; db,Nation,Nations,Poll)= data
  (; ANMap,NationOutputMap)= data

  @info "zCgFPol_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      polls = Select(Poll,["SOX","COX","NOX","PMT","VOC","PM25","PM10","Hg","NH3","BC"])
      zCgFPol_DtaRun(data,polls,nation)

      polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
      zCgFPol_DtaRun(data,polls,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zCgFPol_DtaControl(DB)
end
