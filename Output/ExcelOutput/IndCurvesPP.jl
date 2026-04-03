#
# IndCurvesPP.jl
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

Base.@kwdef struct IndCurvesPPData
  db::String

  Input = "IInput"
  Outpt = "IOutput"
  CalDB = "ICalDB"

  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")

  EC::SetArray  = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray  = ReadDisk(db,"$Input/ECDS")

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray  = ReadDisk(db,"MainDB/ECCDS")

  Enduse::SetArray   = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")

  Nation::SetArray = ReadDisk(db, "MainDB/Nation")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  Tech::SetArray   = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int}    = collect(Select(Tech))

  Year::SetArray = ReadDisk(db, "MainDB/Year")

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)


  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CERSM::VariableArray{4} = ReadDisk(db, "$CalDB/CERSM") # [Enduse,EC,Area,Year] Capital Energy Requirement (Btu/Btu)
  CUF::VariableArray{5} = ReadDisk(db, "$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Capacity Utilization Factor ($/Yr/$/Yr)
  Dmd::VariableArray{5} = ReadDisk(db, "$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  Driver::VariableArray{3} = ReadDisk(db, "MOutput/Driver") # [ECC,Area,Year] Economic Driver (M$/Yr)
  ECFP::VariableArray{5} = ReadDisk(db, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index
  MCFU::VariableArray{5} = ReadDisk(db, "$Outpt/MCFU") # [Enduse,Tech,EC,Area,Year] Marginal Cost of Fuel Use ($/mmBtu)
  PCC::VariableArray{5} = ReadDisk(db, "$Outpt/PCC") # [Enduse,Tech,EC,Area,Year] Process Capital Cost ($/($/Yr))
  PEE::VariableArray{5} = ReadDisk(db, "$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Marginal Process Efficiency ($/Btu)
  PEEA::VariableArray{5} = ReadDisk(db, "$Outpt/PEEA") # [Enduse,Tech,EC,Area,Year] Average Process Efficiency ($/Btu)
  PEECurve::VariableArray{5} = ReadDisk(db, "$Outpt/PEECurve") # [Enduse,Tech,EC,Area,Year] Process Efficiency from Cost Curve ($/Btu)
  PEEPrice::VariableArray{5} = ReadDisk(db, "$Outpt/PEEPrice") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
end

function IndCurvesPP_DtaRun(data,nation,areas,areaName,areaKey,enduse,ecs,eccs)
  (; SceName,Area, AreaDS, Nation, EC, ECDS, ECC, ECCDS, Enduse, EnduseDS, Techs, TechDS, Year) = data
  (; CERSM,CUF,Dmd,Driver,ECFP,MCFU,PCC,PEE,PEEA,PEECurve,PEEPrice) = data
  (; ANMap, Inflation, CDTime, CDYear) = data
  ZZZ = zeros(Float32, length(Year))
  # year = Select(Year, (from = "1985", to = "2050"))
  years = collect(Yr(1985):Final)
  CDYear = max(CDYear,1)

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, " ")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Energy Demands (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years 
    ZZZ[year] = sum(Dmd[enduse,tech,ecs,area,year] for tech in Techs, area in areas)
  end
  print(iob, "Dmd;Total")
  for year in years
    print(iob, @sprintf("%15.6f;", ZZZ[year]))
  end
  println(iob)
  for tech in Techs
    for year in years
      ZZZ[year] = sum(Dmd[enduse,tech,ecs,area,year] for area in areas)
    end
    print(iob, "Dmd;",TechDS[tech])
    for year in years
      print(iob, @sprintf("%15.6f;", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaName," ",ECCDS[eccs]," ",EnduseDS[enduse], " Economic Driver (Units of Driver/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(Driver[ecc,area,year] for ecc in eccs, area in areas)
  end
  print(iob, "Driver;",ECCDS[eccs])
  for year in years
    print(iob, @sprintf("%15.6f;", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Average Process Efficiency (\$/mmbtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for tech in Techs
    for years in years
      ZZZ[years] = sum(PEEA[enduses,tech,ec,area,years]*1e6*Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse)*finite_inverse(
        sum(Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse))
    end
    print(iob, "PEEA;",TechDS[tech])
    for year in years
      print(iob, @sprintf("%15.6f;", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Marginal Process Efficiency (\$/GJ);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for tech in Techs
    for years in years
      ZZZ[years] = sum(PEE[enduses,tech,ec,area,years]*1e6/1.055*Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse)*finite_inverse(
        sum(Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse))
    end
    print(iob, "PEE;",TechDS[tech])
    for year in years
      print(iob, @sprintf("%15.6f;", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Process Efficiency (\$/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for tech in Techs
    for years in years
      ZZZ[years] = sum(PEEPrice[enduses,tech,ec,area,years]*1e6*Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse)*finite_inverse(
        sum(Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse))
    end
    print(iob, "PEEPrice;",TechDS[tech])
    for year in years
      print(iob, @sprintf("%15.6f;", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Process Efficiency from Cost Curve (\$/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for tech in Techs
    for years in years
      ZZZ[years] = sum(PEECurve[enduses,tech,ec,area,years]*1e6*Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse)*finite_inverse(
        sum(Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse))
    end
    print(iob, "PEECurve;",TechDS[tech])
    for year in years
      print(iob, @sprintf("%15.6f;", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Capital Energy Requirement (Btu/Btu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for years in years
    ZZZ[years] = sum(CERSM[enduses,ec,area,years]*sum(Dmd[enduses,tech,ec,area,years] for tech in Techs) for area in areas, ec in ecs, enduses in enduse)*
      finite_inverse(sum(Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, tech in Techs, enduses in enduse))
  end
  print(iob, "CERSM;All Techs")
  for years in years
    print(iob, @sprintf("%15.6f;", ZZZ[years]))
  end
  println(iob)
  println(iob)

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Capacity Utilization Factor (\$/Yr/\$/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for tech in Techs
    for years in years
      ZZZ[years] = sum(CUF[enduses,tech,ec,area,years]*Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse)*
        finite_inverse(sum(Dmd[enduses,tech,ec,area,years] for area in areas, ec in ecs, enduses in enduse))
    end
    print(iob, "CUF;",TechDS[tech])
    for years in years
      print(iob, @sprintf("%15.6f;", ZZZ[years]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Marginal Cost of Fuel Use (2017 CN\$/GJ);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for tech in Techs
    for yearInfla in years
      ZZZ[yearInfla] = sum(MCFU[enduses,tech,ec,area,yearInfla]/Inflation[area,yearInfla]*Inflation[area,CDYear]/1.055*
        Dmd[enduses,tech,ec,area,yearInfla] for area in areas, ec in ecs, enduses in enduse)*
        finite_inverse(sum(Dmd[enduses,tech,ec,area,yearInfla] for area in areas, ec in ecs, enduses in enduse))
    end
    print(iob, "MCFU;",TechDS[tech])
    for year in years
      print(iob, @sprintf("%15.6f;", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Fuel Price (2017 CN\$/GJ);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for tech in Techs
    for yearInfla in years
      ZZZ[yearInfla] = sum(ECFP[enduses,tech,ec,area,yearInfla]/Inflation[area,yearInfla]*Inflation[area,CDYear]/1.055*
        Dmd[enduses,tech,ec,area,yearInfla] for area in areas, ec in ecs, enduses in enduse)*
        finite_inverse(sum(Dmd[enduses,tech,ec,area,yearInfla] for area in areas, ec in ecs, enduses in enduse))
    end
    print(iob, "ECFP;",TechDS[tech])
    for year in years
      print(iob, @sprintf("%15.6f;", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaName," ",ECDS[ecs]," ",EnduseDS[enduse], " Process Capital Cost (2017 CN\$/(\$/Yr));")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for tech in Techs
    for yearInfla in years
      ZZZ[yearInfla] = sum(PCC[enduses,tech,ec,area,yearInfla]/Inflation[area,yearInfla]*Inflation[area,CDYear]*
        Dmd[enduses,tech,ec,area,yearInfla] for area in areas, ec in ecs, enduses in enduse)*
        finite_inverse(sum(Dmd[enduses,tech,ec,area,yearInfla] for area in areas, ec in ecs, enduses in enduse))
    end
    print(iob, "PCC;",TechDS[tech])
    for year in years
      print(iob, @sprintf("%15.6f;", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Promula version is using Area(1) when multiple Areas are selected in nation output. Using
  # AreaKey to try to match what old file is doing - Ian 12/28/23
  #
  print(iob, "Inflation Index (\$/\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  if areaKey == "CN"
    for year in years
      ZZZ[year] = Inflation[1,year]
    end
  else
    for year in years
      ZZZ[year] = Inflation[areas,year]
    end
  end
  print(iob, "Inflation;(\$/\$);")
  for year in years
    print(iob, @sprintf("%15.6f;", ZZZ[year]))
  end
  println(iob)
  println(iob)
  #
  # Create *.dta filename and write output values
  #
  AreaKeyOut = areaKey
  EnduseKeyOut = Enduse[enduse]
  filename = "IndCurvesPP-$AreaKeyOut-$EnduseKeyOut-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function IndCurvesPP_DtaControl(db)
  @info "IndCurvesPP_DtaControl"
  data = IndCurvesPPData(; db)
  (; Area, AreaDS, Nation, EC, ECC, Enduse) = data

  nations = Select(Nation, "CN")
  areas = Select(Area, (from = "ON", to = "NU"))

  enduses = Select(Enduse,["Heat","Motors"])
  ecs = Select(EC,"PulpPaperMills")
  eccs = Select(ECC,"PulpPaperMills")

  for area in areas
    areaName = AreaDS[area]
    areaKey = Area[area]
    for enduse in enduses
      IndCurvesPP_DtaRun(data,nations,area,areaName,areaKey,enduse,ecs,eccs)
    end
  end
  
  areaName = "Canada"
  areaKey = "CN"
  for enduse in enduses
    IndCurvesPP_DtaRun(data,nations,areas,areaName,areaKey,enduse,ecs,eccs)
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
IndCurvesPP_DtaControl(DB)
end
