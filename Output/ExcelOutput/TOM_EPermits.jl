#
# TOM_EPermits.jl - Emission Permit Ependitures from E2020 to TOM
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

Base.@kwdef struct TOM_EPermitsData
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  FuelAggTOM::SetArray = ReadDisk(db,"KInput/FuelAggTOMKey")
  FuelAggTOMDS::SetArray = ReadDisk(db,"KInput/FuelAggTOMDS")
  FuelAggTOMs::Vector{Int} = collect(Select(FuelAggTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  VehicleTOMDS::SetArray = ReadDisk(db,"KInput/VehicleTOMDS")
  VehicleTOMs::Vector{Int} = collect(Select(VehicleTOM))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  EPermitE::VariableArray{3} = ReadDisk(db,"KOutput/EPermitE") # [ECCTOM,AreaTOM,Year] Cost of Emissions Permits ($M/Yr)
  EPermitHHe::VariableArray{2} = ReadDisk(db,"KOutput/EPermitHHe") # [AreaTOM,Year] Household Cost of Emissions Permits ($M/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))
end

function TOM_EPermits_DtaRun(data,areas,areatoms,areatomds,areatomkey,nation)
  (; SceName,ECCTOM,ECCTOMDS) = data
  (; Nation,ToTOMVariable,Year) = data
  (; EPermitE,EPermitHHe,IsActiveToECCTOM,ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Summary Variable Transfers from ENERGY 2020 to TOM.")
  println(iob, " ")

  years = collect(Future:Final)
  println(iob, "Year;", ";", join(Year[years], ";    "))
  println(iob, " ")

  #
  # Permit Expenditures
  #
  totomvariable = Select(ToTOMVariable,"EPermitE")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)
  
  print(iob,areatomds," Cost of Emissions Permits (2017 \$M/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"Total;Total")
  for year in years
    ZZZ[year] = sum(EPermitHHe[areatom,year] for areatom in areatoms) +
                sum(EPermitE[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  print(iob,"EPermitHHe;Household")
  for year in years
    ZZZ[year] = sum(EPermitHHe[areatom,year] for areatom in areatoms)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  print(iob,"EPermitE;Industry, Incl. Transportation and Electric Utility")  
  for year in years
    ZZZ[year] = sum(EPermitE[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  ecctoms = Select(ECCTOM,["Transit","Truck","Air","Rail","Water"])
  print(iob,"EPermitE;Transportation")  
  for year in years
    ZZZ[year] = sum(EPermitE[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  ecctoms = Select(ECCTOM,"UtilityGen")
  print(iob,"EPermitE;Electric Utility")  
  for year in years
    ZZZ[year] = sum(EPermitE[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  totomvariable = Select(ToTOMVariable,"EPermitE")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)

  #
  # Industrial Permit Expenditures
  #
  print(iob,areatomds," Cost of Industrial Emissions Permits (2017 \$M/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"EPermitE;Total")  
  for year in years
    ZZZ[year] = sum(EPermitE[ecctom,areatom,year] for ecctom in ecctoms, areatom in areatoms)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for ecctom in ecctoms
    print(iob,"EPermitE;",ECCTOMDS[ecctom])  
    for year in years
      ZZZ[year] = sum(EPermitE[ecctom,areatom,year] for areatom in areatoms)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)    
  end
  println(iob)
  
  #
  # Create *.dta filename and write output values
  #
  filename = "TOM_EPermits-$areatomkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))  
  end   
end

function TOM_EPermits_DtaControl(db)
  @info "TOM_EPermits_DtaControl"
  data = TOM_EPermitsData(; db)
  (; AreaTOM,AreaTOMDS,Nation) = data
  (; ANMap,MapAreaTOM) = data

  nation = Select(Nation,"CN")
  areatoms = Select(AreaTOM,(from="AB",to="YT"))
  for areatom in areatoms
    areas = findall(MapAreaTOM[:,areatom] .== 1)
    areatomkey = AreaTOM[areatom]
    areatomds = AreaTOMDS[areatom]
    TOM_EPermits_DtaRun(data,areas,areatom,areatomds,areatomkey,nation)
  end
  areas = findall(ANMap[:,nation] .== 1)
  areatomkey = "CN"
  areatomds = "Canada"
  TOM_EPermits_DtaRun(data,areas,areatoms,areatomds,areatomkey,nation)

  nation = Select(Nation,"US")
  areatoms = Select(AreaTOM,(from="NEng",to="CA"))
  for areatom in areatoms
    areas = findall(MapAreaTOM[:,areatom] .== 1)
    areatomkey = AreaTOM[areatom]
    areatomds = AreaTOMDS[areatom]
    TOM_EPermits_DtaRun(data,areas,areatom,areatomds,areatomkey,nation)
  end
  areas = findall(ANMap[:,nation] .== 1)
  areatomkey = "US"
  areatomds = "US"
  TOM_EPermits_DtaRun(data,areas,areatoms,areatomds,areatomkey,nation)
end
if abspath(PROGRAM_FILE) == @__FILE__
TOM_EPermits_DtaControl(DB)
end
