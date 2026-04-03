#
# zvDmd.jl
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

Base.@kwdef struct zvDmdData
  db::String

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
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))  
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zvDmd::VariableArray{5} = ReadDisk(db,"VBInput/vDmd") # [vEnduse,Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion = 0.0
  UnitsDS = ""
  ZZZ = zeros(Float32,length(Year))
end

function zvDmd_DtaRun(data,nation)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,) = data
  (; Fuel,FuelDS,Fuels,Nation,vEnduse,vEnduseDS,vEnduses,Year) = data
  (; ANMap,Conversion,EndTime) = data
  (; UnitsDS,zvDmd,ZZZ,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Fuel;Enduse;Units;zData")

  years = collect(1:Final)
  areas = findall(ANMap[:,nation] .== 1)
  
  Conversion = 1054.615
  UnitsDS = "TJ/Yr"
  
  for venduse in vEnduses
    for fuel in Fuels
      for ecc in ECCs
        for area in areas
          for year in years
            ZZZ[year] = zvDmd[venduse,fuel,ecc,area,year]*Conversion
            if ZZZ[year] != 0.0
              zData = ZZZ[year]
              println(iob,"zvDmd;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
                FuelDS[fuel],";",vEnduseDS[venduse],";",UnitsDS,";",zData)
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
  filename = "zvDmd-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zvDmd_DtaControl(db)
  data = zvDmdData(; db)
  (; db,Nation)= data

  @info "zvDmd_DtaControl"

  nation = Select(Nation,"CN")
  zvDmd_DtaRun(data,nation)
end
if abspath(PROGRAM_FILE) == @__FILE__
  zvDmd_DtaControl(DB)
end
