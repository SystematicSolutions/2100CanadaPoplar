#
# TOMValues.jl
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

Base.@kwdef struct TOMValuesData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db, "KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db, "KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  CNAreaTOM::SetArray = ReadDisk(db,"KInput/CNAreaTOMKey")
  CNAreaTOMs::Vector{Int} = collect(Select(CNAreaTOM))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCFloorspaceTOM::SetArray = ReadDisk(db,"KInput/ECCFloorspaceTOMKey")
  ECCFloorspaceTOMs::Vector{Int} = collect(Select(ECCFloorspaceTOM))
  ECCResTOM::SetArray = ReadDisk(db,"KInput/ECCResTOMKey")
  ECCResTOMs::Vector{Int} = collect(Select(ECCResTOM))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  NationTOM::SetArray = ReadDisk(db,"KInput/NationTOMKey")
  NationTOMs::Vector{Int} = collect(Select(NationTOM))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CD::VariableArray{2} = ReadDisk(db,"KOutput/CD") # [AreaTOM,Year] Household Appliance Investments (2017 $M/Yr)
  EmpTOM::VariableArray{3} = ReadDisk(db,"KOutput/EmpTOM") # [ECCTOM,AreaTOM,Year]  Employment, All Industries, NAICS 1, Persons (People)
  FlrSpc::VariableArray{3} = ReadDisk(db,"KOutput/FlrSpc") # [ECCFloorspaceTOM,CNAreaTOM,Year]  Floorspace (1000 Sq Meters)
  GDP::VariableArray{2} = ReadDisk(db,"KOutput/GDP")  # [AreaTOM,Year] GDP Gross Domestic Product (2017 $M/Yr)
  GY::VariableArray{3} = ReadDisk(db,"KOutput/GY")    # [ECCTOM,AreaTOM,Year] Gross Output (2017 $M/Yr)
  HH::VariableArray{3} = ReadDisk(db,"KOutput/HH")    # [ECCResTOM,CNAreaTOM,Year] Households (Households)
  IFC::VariableArray{3} = ReadDisk(db,"KOutput/IFC") # [ECCTOM,AreaTOM,Year] Investments in Construction (2017 $M/Yr)
  IFME::VariableArray{3} = ReadDisk(db,"KOutput/IFME") # [ECCTOM,AreaTOM,Year] TOM Investments in Machinery & Equipment (2017 $M/Yr)
  IPRD::VariableArray{2} = ReadDisk(db,"KOutput/IPRD")  # [AreaTOM,Year] Residential Investments (2017 $M/Yr)
  K::VariableArray{3} = ReadDisk(db,"KOutput/K")    # [ECCTOM,AreaTOM,Year] Capital Stock (2017 $M)
  KRD::VariableArray{2} = ReadDisk(db,"KOutput/KRD")    # [AreaTOM,Year] Residential Capital Stock (2017 $M)
  PEDY::VariableArray{2} = ReadDisk(db,"KOutput/PEDY")     # [AreaTOM,Year]  Income, personal disposable, real (2017 $M/Yr)
  PEY::VariableArray{2} = ReadDisk(db,"KOutput/PEY")  # [AreaTOM,Year]  Personal Income, Real, LCU (2017 $M/Yr)
  PGDP::VariableArray{2} = ReadDisk(db,"KOutput/PGDP") # [NationTOM,Year] Implicit Price Deflator: Gross domestic product at market prices (Index 2017=100)
  PopTOM::VariableArray{2} = ReadDisk(db,"KOutput/PopTOM") # [AreaTOM,Year]  Population (People)
  RXD::VariableArray{2} = ReadDisk(db,"KOutput/RXD")  # [NationTOM,Year]  Exchange Rates (CN$/US$)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32, length(Year))
end

function TOMValues_DtaRun(data,TitleKey,TitleName,area,areatom)
  (; SceName,Area,AreaDS,Areas,AreaTOM,AreaTOMDS,AreaTOMs,CNAreaTOM,CNAreaTOMs) = data
  (; ECC,ECCs,ECCFloorspaceTOM,ECCFloorspaceTOMs,ECCResTOM,ECCResTOMs) = data
  (; ECCTOM,ECCTOMs,Nation,NationDS,Nations,NationTOM,NationTOMs,Year,Years) = data
  (; ANMap,CD,EmpTOM,FlrSpc,GDP,GY,HH,IFC,IFME,IPRD,K,KRD,PEDY) = data
  (; PEY,PGDP,PopTOM,RXD,TOMBaseTime) = data
  (; ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "TOM Output Values.")
  println(iob, " ")

  years = collect(Yr(1985):Final)
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  print(iob, "$TitleName GDP Gross Domestic Product ($TOMBaseTime\$M/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "GDP;$(AreaTOM[areatom])")
  for year in years
    ZZZ[year] = GDP[areatom,year]
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$TitleName Personal Disposable Income ($TOMBaseTime\$M/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "PEDY;$(AreaTOM[areatom])")
  for year in years
    ZZZ[year] = PEDY[areatom,year]
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$TitleName Personal Income ($TOMBaseTime\$M/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "PEY;$(AreaTOM[areatom])")
  for year in years
    ZZZ[year] = PEY[areatom,year]
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$TitleName Population (Persons);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "PopTOM;$(AreaTOM[areatom])")
  for year in years
    ZZZ[year] = PopTOM[areatom,year]
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$TitleName Household Appliance Investments ($TOMBaseTime\$M/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "CD;$(AreaTOM[areatom])")
  for year in years
    ZZZ[year] = CD[areatom,year]
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$TitleName Residential Investments ($TOMBaseTime\$M/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "IPRD;$(AreaTOM[areatom])")
  for year in years
    ZZZ[year] = IPRD[areatom,year]
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$TitleName Residential Capital Stock ($TOMBaseTime\$M/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "KRD;$(AreaTOM[areatom])")
  for year in years
    ZZZ[year] = KRD[areatom,year]
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$TitleName Implicit Price Deflator: GDP at market prices (Index);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  for nationtom in NationTOMs
    print(iob, "PGDP;$(NationTOM[nationtom])")
    for year in years
      ZZZ[year] = PGDP[nationtom,year]
      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, "$TitleName Exchange Rates (CN\$/US\$);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  for nationtom in NationTOMs
    print(iob, "RXD;$(NationTOM[nationtom])")
    for year in years
      ZZZ[year] = RXD[nationtom,year]
      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, "$TitleName Employment (Persons);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "EmpTOM;Total")
  for year in years
    ZZZ[year] = sum(EmpTOM[ecctom,areatom,year] for ecctom in ECCTOMs)
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  for ecctom in ECCTOMs
    print(iob, "EmpTOM;$(ECCTOM[ecctom])")
    for year in years
      ZZZ[year] = EmpTOM[ecctom,areatom,year]
      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, "$TitleName Gross Output ($TOMBaseTime\$M/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "GY;Total")
  for year in years
    ZZZ[year] = sum(GY[ecctom,areatom,year] for ecctom in ECCTOMs)
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  for ecctom in ECCTOMs
    print(iob, "GY;$(ECCTOM[ecctom])")
    for year in years
      ZZZ[year] = GY[ecctom,areatom,year]
      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  cnareatoms = findall(CNAreaTOM[:] .== AreaTOM[areatom])
  print(iob, "$TitleName Floor Space (1000 Sq Meters);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "FlrSpc;Total")
  for year in years
    if !isempty(cnareatoms)
      ZZZ[year] = sum(FlrSpc[eccfloorspacetom,cnareatom,year] for cnareatom in cnareatoms, eccfloorspacetom in ECCFloorspaceTOMs)
    else
      ZZZ[year] = 0
    end
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  for eccfloorspacetom in ECCFloorspaceTOMs
    print(iob, "FlrSpc;$(ECCFloorspaceTOM[eccfloorspacetom])")
    for year in years
      if !isempty(cnareatoms)
        ZZZ[year] = sum(FlrSpc[eccfloorspacetom,cnareatom,year] for cnareatom in cnareatoms)
      else
        ZZZ[year] = 0
      end
      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, "$TitleName Households(HouseHolds);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "HH;Total")
  for year in years
    if !isempty(cnareatoms)
      ZZZ[year] = sum(HH[eccrestom,cnareatom,year] for cnareatom in cnareatoms, eccrestom in ECCResTOMs)
    else
      ZZZ[year] = 0
    end
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  for eccrestom in ECCResTOMs
    print(iob, "HH;$(ECCResTOM[eccrestom])")
    for year in years
      if !isempty(cnareatoms)
        ZZZ[year] = sum(HH[eccrestom,cnareatom,year] for cnareatom in cnareatoms)
      else
        ZZZ[year] = 0
      end
      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, "$TitleName Investments in Construction ($TOMBaseTime\$M);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "IFC;Total")
  for year in years
    ZZZ[year] = sum(IFC[ecctom,areatom,year] for ecctom in ECCTOMs)
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  for ecctom in ECCTOMs
    print(iob, "IFC;$(ECCTOM[ecctom])")
    for year in years
      ZZZ[year] = IFC[ecctom,areatom,year]
      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, "$TitleName Investments in Machinery and Equipment ($TOMBaseTime\$M);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "IFME;Total")
  for year in years
    ZZZ[year] = sum(IFME[ecctom,areatom,year] for ecctom in ECCTOMs)
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  for ecctom in ECCTOMs
    print(iob, "IFME;$(ECCTOM[ecctom])")
    for year in years
      ZZZ[year] = IFME[ecctom,areatom,year]
      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, "$TitleName Capital Stock ($TOMBaseTime\$M);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "K;Total")
  for year in years
    ZZZ[year] = sum(K[ecctom,areatom,year] for ecctom in ECCTOMs)
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  for ecctom in ECCTOMs
    print(iob, "K;$(ECCTOM[ecctom])")
    for year in years
      ZZZ[year] = K[ecctom,areatom,year]
      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  filename = "TOMValues-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TOMValues_DtaControl(db)
  @info "TOMValues_DtaControl"
  data = TOMValuesData(; db)
  (; ANMap, Area, AreaDS, Areas, AreaTOM, AreaTOMs, Nation) = data

  CN=Select(Nation,"CN")
  areas=findall(ANMap[Areas,CN] .== 1)
  for area in areas
    areatoms = findall(AreaTOM[AreaTOMs] .== Area[area])
    if !isempty(areatoms)
      areatom = first(areatoms)
      TOMValues_DtaRun(data, Area[area], AreaDS[area], area, areatom)
    end
  end

  US=Select(Nation,"US")
  areas=findall(ANMap[Areas,US] .== 1)
  for area in areas
    areatoms = findall(AreaTOM[AreaTOMs] .== Area[area])
    if !isempty(areatoms)
      areatom = first(areatoms)
      TOMValues_DtaRun(data, Area[area], AreaDS[area], area, areatom)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
TOMValues_DtaControl(DB)
end

