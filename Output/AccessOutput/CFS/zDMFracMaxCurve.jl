#
# zDMFracMaxCurve.jl
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

Base.@kwdef struct zDMFracMaxCurveData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  SCPoint::SetArray = ReadDisk(db, "MainDB/SCPointKey")
  SCPoints::Vector{Int} = collect(Select(SCPoint))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zDMFracMaxCurve::VariableArray{4} = ReadDisk(db, "SInput/DmFracMaxCurve") # [SCPoint,Fuel,Nation,Year] Maximum Blending for Fuel in Supply Curve (Btu/Btu)
  zDMFracMaxCurveRef::VariableArray{4} = ReadDisk(RefNameDB, "SInput/DmFracMaxCurve") # [SCPoint,Fuel,Nation,Year] Maximum Blending for Fuel in Supply Curve (Btu/Btu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  SCPointDS::SetArray = [string(i) for i in 1:length(SCPoint)] # [SCPoint] Supply Curve Point Description (created as string indices)
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zDMFracMaxCurve_DtaRun(data,nation)
  (; Fuel,FuelDS,Fuels,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,SCPoint,SCPointDS,SCPoints,Year) = data
  (; BaseSw,CDTime,Conversion,EndTime,UnitsDS,zDMFracMaxCurve,zDMFracMaxCurveRef,SceName) = data

  if BaseSw != 0
    @. zDMFracMaxCurveRef = zDMFracMaxCurve
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;SCPoint;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "Btu/Btu"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "Btu/Btu"
  end

  for scpoint in SCPoints
    for fuel in Fuels
      for year in years
        ZZZ = zDMFracMaxCurve[scpoint,fuel,nation,year]*Conversion[nation,year]
        CCC = zDMFracMaxCurveRef[scpoint,fuel,nation,year]*Conversion[nation,year]
        if ZZZ != 0 || CCC != 0
          println(iob,"zDMFracMaxCurve;",Year[year],";",SCPointDS[scpoint],";",FuelDS[fuel],";",UnitsDS[nation],";",
            @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zDMFracMaxCurve-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zDMFracMaxCurve_DtaControl(db)
  data = zDMFracMaxCurveData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zDMFracMaxCurve_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDMFracMaxCurve_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
zDMFracMaxCurve_DtaControl(DB)
end
