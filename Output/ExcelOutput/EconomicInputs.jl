#
# EconomicInputs.jl - Economic Model Variables Assigned from TOM Inputs
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

Base.@kwdef struct EconomicInputsData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EmpTOM::VariableArray{3} = ReadDisk(db,"KOutput/EmpTOM") # [ECCTOM,AreaTOM,Year]  Employment, All Industries, NAICS 1, Persons (People)
  Floorspace::VariableArray{3} = ReadDisk(db,"MOutput/Floorspace")   # [ECC,Area,Year] Floor Space (Million Sq Ft)
  GDP::VariableArray{2} = ReadDisk(db,"KOutput/GDP")  # [AreaTOM,Year] GDP Gross Domestic Product (2017 $M/Yr)
  GDPDeflator::VariableArray{2} = ReadDisk(db,"MOutput/GDPDeflator") # [Nation,Year] GDP Deflator (Index)
  GDPDeflTOM::VariableArray{2} = ReadDisk(db,"MInput/GDPDeflTOM")   # [Nation,Year] Implicit Price Deflator: GDP at Market Prices (Index 2017=100)
  GDPSector::VariableArray{3} = ReadDisk(db,"MInput/GDPSector") # [ECC,Area,Year] GDP By Sector (1997 Million CN$/Yr)
  GDPSectorTOM::VariableArray{3} = ReadDisk(db,"MInput/GDPSectorTOM")    # [ECC,Area,Year]  GDP By Sector (2017 Real Million $/Yr)
  GVA_TOM::VariableArray{3} = ReadDisk(db,"KOutput/GVA_TOM")    # [ECCTOM,AreaTOM,Year] Gross Value Added (2017 $M/Yr)
  GYAdjust::VariableArray{3} = ReadDisk(db,"KOutput/GYAdjust")  # [ECCTOM,AreaTOM,Year] Gross Output from TOM, Adjusted (2017 $M/Yr)
  LaborForce::VariableArray{2} = ReadDisk(db,"MInput/LaborForce") # [Nation,Area]  Total Labor Force, Age 15+ (000s)
  RealDispInc::VariableArray{2} = ReadDisk(db,"MInput/RealDispInc") # [Area,Year]  Real Disposable Income (2017 $M/Yr)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  xEmp::VariableArray{3} = ReadDisk(db,"MInput/xEmp") # [ECC,Area,Year] Employment (Thousands)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate")   # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xFloorspaceTOM::VariableArray{3} = ReadDisk(db,"MInput/xFloorspaceTOM")     # [ECC,Area,Year]  Commercial Floor Space from TOM (Million Sq Ft)',
  xGDPChained::VariableArray{2} = ReadDisk(db,"MInput/xGDPChained") # [Nation,Year]  Chained National GDP(Chained 2017 Million $/Yr)',
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO")   # [ECC,Area,Year] Gross Output (2017 M$/Yr)
  xGOTOM::VariableArray{3} = ReadDisk(db,"MInput/xGOTOM")  # [ECC,Area,Year] Gross Output (2017 M$/Yr)
  xGRP::VariableArray{2} = ReadDisk(db,"MInput/xGRP") # [Area,Year] Gross Regional Product (2017 M$/Yr)
  xGRPTOM::VariableArray{2} = ReadDisk(db,"MInput/xGRPTOM")     # [Area,Year] Gross Regional Product from TOM (2012 $M/Yr)
  xHHS::VariableArray{3} = ReadDisk(db,"MInput/xHHS") # [ECC,Area,Year] Households (Households)
  xHHSTOM::VariableArray{3} = ReadDisk(db,"MInput/xHHSTOM")     # [ECC,Area,Year] Households from TOM (Households)
  xPopT::VariableArray{2} = ReadDisk(db,"MInput/xPopT")    # [Area,Year] Population (Millions)
  xPopTTOM::VariableArray{2} = ReadDisk(db,"MInput/xPopTTOM")   # [Area,Year] Population from TOM (Millions)
  xRPI::VariableArray{2} = ReadDisk(db,"MInput/xRPI") # [Area,Year] Total Personal Income (Real M$/Yr)
  xRPITOM::VariableArray{2} = ReadDisk(db,"MInput/xRPITOM")     # [Area,Year] Total Personal Income from TOM (Real M$/Yr)
  xTHHS::VariableArray{2} = ReadDisk(db,"MInput/xTHHS")    # [Area,Year] Total Households (Households)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))
end

function EconomicInputs_DtaRun(data,areas,areads,areakey,nation)
  (; Areas,ECC,ECCDS,ECCs,Nation,Nations,Year,Years) = data
  (; ANMap,GDPSectorTOM,Floorspace,LaborForce,RealDispInc) = data
  (; xEmp,xExchangeRate,xExchangeRateNation,xGRP) = data
  (; xHHS,xPopT,xRPI,xTHHS,ZZZ) = data
  (; SceName) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Economic Inputs Mapped from TOM.")
  println(iob, " ")

  years = collect(First:Final)
  println(iob, "Year;", ";", join(Year[years], ";    "))
  println(iob, " ")

 #
 # Gross Regional Product
 #
  print(iob,areads," Gross Regional Product (2017 \$M/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"xGRP;Total;")
  for year in years
    ZZZ[year] = sum(xGRP[area,year] for area in areas)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  println(iob, " ")

 #
 # Population
 #
  print(iob,areads," Population (Millions);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"xPopT;Total;")
  for year in years
    ZZZ[year] = sum(xPopT[area,year] for area in areas)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  println(iob, " ")

 #
 # Total Personal Income
 #
  print(iob,areads," Total Personal Income (2017 \$M/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"xRPI;Total;")
  for year in years
    ZZZ[year] = sum(xRPI[area,year] for area in areas)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  println(iob, " ")
  
  #
  # Real Disposable Income
  #
  print(iob,areads," Real Disposable Income (2017 \$M/Yr);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"RealDispInc;Total;")
  for year in years
    ZZZ[year] = sum(RealDispInc[area,year] for area in areas)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  println(iob, " ")

  #
  # Implicit Price Deflator (Index 2017=100)
  #
  print(iob,areads," Implicit Price Deflator: GDP at Market Prices (Index 2017=100);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"GDPSectorTOM;Total;")
  for year in years
    ZZZ[year] = sum(GDPSectorTOM[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)
  for ecc in ECCs
    print(iob,"GDPSectorTOM;",ECCDS[ecc],";")
    for year in years
      ZZZ[year] = sum(GDPSectorTOM[ecc,area,year] for area in areas)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Floorspace
  #
  eccs = Select(ECC,(from="SingleFamilyDetached",to="OtherCommercial"))
  print(iob,areads," Floor Space (Million Sq Ft);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  for ecc in eccs
    print(iob,"Floorspace;",ECCDS[ecc],";")
    for year in years
      ZZZ[year] = sum(Floorspace[ecc,area,year] for area in areas)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Employment 
  #
  print(iob,areads," Employment (Thousands);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"xEmp;Total;")
  for year in years  
    ZZZ[year] = sum(xEmp[ecc,area,year] for ecc in ECCs, area in areas)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)  
  for ecc in ECCs
    print(iob,"xEmp;",ECCDS[ecc],";")
    for year in years
      ZZZ[year] = sum(xEmp[ecc,area,year] for area in areas)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob, " ")

 #
 # Households
 #
  eccs = Select(ECC,(from="SingleFamilyDetached",to="OtherResidential"))
  print(iob,areads," Households (Households);;")
  for year in years  
    print(iob,Year[year],";")
  end
  println(iob)
  print(iob,"xTHHS;Total;")
  for year in years  
    ZZZ[year] = sum(xTHHS[area,year] for area in areas)
    print(iob,@sprintf("%.4f",ZZZ[year]),";")
  end
  println(iob)  
  for ecc in eccs
    print(iob,"xHHS;",ECCDS[ecc],";")
    for year in years
      ZZZ[year] = sum(xHHS[ecc,area,year] for area in areas)
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Create *.dta filename and write output values
  #
  filename = "EconomicInputs-$areakey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))  
  end   
end


function EconomicInputs_DtaControl(db)
  data = EconomicInputsData(; db)
  (; Area,AreaDS,Nation) = data
  (; ANMap) = data

  @info "EconomicInputs_DtaControl"

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  for area in areas
    EconomicInputs_DtaRun(data,area,AreaDS[area],Area[area],CN)
  end
  areakey = "CN"
  areads = "Canada"
  EconomicInputs_DtaRun(data,areas,areads,areakey,CN)


  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1)
  for area in areas
    EconomicInputs_DtaRun(data,area,AreaDS[area],Area[area],US)
  end
  areakey = "US"
  areads = "US"
  EconomicInputs_DtaRun(data,areas,areads,areakey,US)

end

if abspath(PROGRAM_FILE) == @__FILE__
  EconomicInputs_DtaControl(DB)
end
