#
# Pollution.jl
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

Base.@kwdef struct PollutionData
  db::String

  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int}     = collect(Select(Area))
  ECC::SetArray    = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray  = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int}     = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))  
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray    = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int}  = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Poll::SetArray   = ReadDisk(db,"MainDB/PollKey")
  PollKey::SetArray   = ReadDisk(db,"MainDB/PollKey")  
  Polls::Vector{Int}  = collect(Select(Poll))  
  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  Year::SetArray   = ReadDisk(db,"MainDB/YearDS")

  CgFPol::VariableArray{5}   = ReadDisk(db,"SOutput/CgFPol")  #[FuelEP,ECC,Poll,Area,Year]  Cogeneration Related Pollution (Tonnes/Yr)
  CgPol::VariableArray{4}    = ReadDisk(db,"SOutput/CgPol")   #[ECC,Poll,Area,Year]  Cogeneration Related Pollution (Tonnes/Yr)
  DACProduction::VariableArray{2} = ReadDisk(db, "SOutput/DACProduction") #[Area,Year]  DAC Production (eCO2 Tonnes/Yr)
  EuFPol::VariableArray{5}   = ReadDisk(db,"SOutput/EuFPol")  #[FuelEP,ECC,Poll,Area,Year]  Energy Pollution including Cogeneration (Tonnes/Yr)
  EnPol::VariableArray{4}    = ReadDisk(db,"SOutput/EnPol")   #[ECC,Poll,Area,Year]  Energy Related Pollution (Tonnes/Yr)
  FlPol::VariableArray{4}    = ReadDisk(db,"SOutput/FlPol")   #[ECC,Poll,Area,Year]  Fugitive Flaring Emissions (Tonnes/Yr)
  FuPol::VariableArray{4}    = ReadDisk(db,"SOutput/FuPol")   #[ECC,Poll,Area,Year]  Other Fugitive Emissions (Tonnes/Yr)
  MEPol::VariableArray{4}    = ReadDisk(db,"SOutput/MEPol")   #[ECC,Poll,Area,Year]  Non-Energy Pollution (Tonnes/Yr)
  NcFPol::VariableArray{5}   = ReadDisk(db,"SOutput/NcFPol")  #[Fuel,ECC,Poll,Area,Year] Non Combustion Related Pollution (Tonnes/Yr) 
  NcPol::VariableArray{4}    = ReadDisk(db,"SOutput/NcPol")   #[ECC,Poll,Area,Year]  Non Combustion Related Pollution (Tonnes/Yr)
  PolConv::VariableArray{1}  = ReadDisk(db,"SInput/PolConv")  #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PolOthImports::VariableArray{3} = ReadDisk(db, "EGOutput/PolOthImports") #[Poll,Area,Year]  Emissions from Non-Specified Imports (Tonnes)
  PolRnImports::VariableArray{3} = ReadDisk(db, "EGOutput/PolRnImports") #[Poll,Area,Year]  Emissions from Renewable Imports (Tonnes)
  PolSpImport::VariableArray{3} = ReadDisk(db, "EGOutput/PolSpImport") #[Poll,Area,Year]  Emissions from Imports from Specified Units (Tonnes)
  SqPol::VariableArray{4}    = ReadDisk(db,"SOutput/SqPol")   #[ECC,Poll,Area,Year]  Sequestering Emissions (Tonnes/Yr)
  TotPol::VariableArray{4}   = ReadDisk(db,"SOutput/TotPol")  #[ECC,Poll,Area,Year]  Pollution (Tonnes/Yr)
  VnPol::VariableArray{4}    = ReadDisk(db,"SOutput/VnPol")   #[ECC,Poll,Area,Year]  Venting Emissions (Tonnes/Yr)

  Convert = zeros(Float32, length(Poll))
  PolUnits::SetArray = fill("",length(Poll)) # New Unit Number
  ZZZ::VariableArray{1} = zeros(Float32,length(Year))

end
#
# TODOJulia add Convert (Hg is the only exception) - Jeff Amlin 11/7/23
#
# Read Convert\7
# SOx   0.001
# NOx   0.001
# PMT   0.001
# VOC   0.001
# N2O   0.001
# CO    0.001
# CO2   0.001
# CH4   0.001
# SF6   0.001
# PFC   0.001
# HFC   0.001
# PM25  0.001
# PM10  0.001
# Hg    1000
# O3    0.001
# NH3   0.001
# H2O   0.001
# BC    0.001
# NF3   0.001
#
# TODOJulia add PolUnits (Hg is the only exception) - Jeff Amlin 11/7/23
#
# Read PolUnits\7
# SOx   Kilotonnes
# NOx   Kilotonnes
# PMT   Kilotonnes
# VOC   Kilotonnes
# N2O   Kilotonnes
# CO    Kilotonnes
# CO2   Kilotonnes
# CH4   Kilotonnes
# SF6   Kilotonnes
# PFC   Kilotonnes
# HFC   Kilotonnes
# PM25  Kilotonnes
# PM10  Kilotonnes
# Hg    Kilograms
# O3    Kilotonnes
# NH3   Kilotonnes
# H2O   Kilotonnes
# BC    Kilotonnes
# NF3   Kilotonnes
#

function Pollution_DtaRun(data,polls,areas,AreaName,AreaKey,PollName,PolUnit)
  (; SceName,AreaDS,ECC,ECCDS,ECCs,Fuels,FuelDS,FuelEPDS,FuelEPs,Poll,Year) = data
  (; CgFPol,CgPol,Convert,DACProduction,EnPol,EuFPol,FlPol,FuPol,MEPol,NcFPol,NcPol) = data
  (; PolOthImports,PolRnImports,PolSpImport,SqPol,TotPol,VnPol,ZZZ) = data
  
  years = collect(Yr(1990):Final)

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Emissions $Convert")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  #
  # Canada Official Definition of Emissions
  #
  OfficialECCs_1 = Select(ECC, !=("ForeignPassenger"))
  OfficialECCs_2 = Select(ECC, !=("ForeignFreight"))
  OfficialECCs_3 = Select(ECC, !=("LandUse"))
  OfficialECCs = intersect(OfficialECCs_1,OfficialECCs_2,OfficialECCs_3)
  CO2=Select(Poll,"CO2")

  #
  # Official Emissions
  #
  print(iob,AreaName, " Total ",PollName," Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"Official;Total")  
  for year in years  
    ZZZ[year] = sum(TotPol[ecc,poll,area,year]*Convert[poll]
      for area in areas, ecc in OfficialECCs, poll in polls)-
      sum(DACProduction[area,year]*Convert[CO2] for area in areas)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  # Direct Air Capture
  #
  ecc=Select(ECC,"DirectAirCapture")
  print(iob,AreaName," Gross Direct Air Capture CO2 Reduction ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob,"DACProduction;",ECCDS[ecc])  
  for year in years  
    ZZZ[year] = 0-sum(DACProduction[area,year]*Convert[CO2] for area in areas)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Emissions before Direct Air Capture
  #
  print(iob,AreaName," Total ",PollName," Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "Total;Total")
  for year in years
   ZZZ[year] = sum(TotPol[ecc,poll,area,year]*Convert[poll]
                   for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob,"TotPol;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(TotPol[ecc,poll,area,year]*Convert[poll] for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Energy Related Emissions
  #
  print(iob,AreaName," Total ",PollName," Energy Related Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "EnPol;Total")
  for year in years
    ZZZ[year] = sum(EnPol[ecc,poll,area,year]*Convert[poll] 
                    for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob, "EnPol;", ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(EnPol[ecc,poll,area,year]*Convert[poll] for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Non-Energy Emissions
  #
  print(iob,AreaName," Total ",PollName," Non-Energy Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "MEPol;Total")
  for year in years
    ZZZ[year] = sum(MEPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob, "MEPol;", ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(MEPol[ecc,poll,area,year]*Convert[poll] for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Non-Combustion Emissions
  #
  print(iob,AreaName," Total ",PollName," Non-Combustion Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "NcPol;Total")
  for year in years
    ZZZ[year] = sum(NcPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob, "NcPol;", ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(NcPol[ecc,poll,area,year]*Convert[poll] for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Total Fugitive Emissions
  #
  print(iob,AreaName," ",PollName," Fugitive Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "Fugitive;Total")
  for year in years
    ZZZ[year] = sum((VnPol[ecc,poll,area,year]*Convert[poll]+
      FlPol[ecc,poll,area,year]*Convert[poll]+
      FuPol[ecc,poll,area,year]*Convert[poll]) for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob, "Fugitive;", ECCDS[ecc])
    for year in years
      ZZZ[year] = sum((VnPol[ecc,poll,area,year]*Convert[poll]+
        FlPol[ecc,poll,area,year]*Convert[poll]+
        FuPol[ecc,poll,area,year]*Convert[poll]) for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Venting Emissions
  #
  print(iob,AreaName," ",PollName," Venting Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "VnPol;Total")
  for year in years
    ZZZ[year] = sum(VnPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob, "VnPol;", ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(VnPol[ecc,poll,area,year]*Convert[poll] for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Flaring Emissions
  #
  print(iob,AreaName," ",PollName," Flaring Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "FlPol;Total")
  for year in years
    ZZZ[year] = sum(FlPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob, "FlPol;", ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(FlPol[ecc,poll,area,year]*Convert[poll] for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Other Fugitive Emissions
  #
  print(iob,AreaName," ",PollName," Other Fugitive Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "FuPol;Total")
  for year in years
    ZZZ[year] = sum(FuPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob, "FuPol;", ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(FuPol[ecc,poll,area,year]*Convert[poll] for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Cogeneration Related Pollution
  #
  print(iob,AreaName," ",PollName," Cogeneration Related Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "CgPol;Total")
  for year in years
    ZZZ[year] = sum(CgPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob, "CgPol;", ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(CgPol[ecc,poll,area,year]*Convert[poll] for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Sequestered Pollution
  #
  print(iob,AreaName," ",PollName," Sequestered Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "SqPol;Total")
  for year in years
    ZZZ[year] = sum(SqPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for ecc in OfficialECCs
    print(iob, "SqPol;", ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(SqPol[ecc,poll,area,year]*Convert[poll] for area in areas, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Canada Official Definition of Emissions by Fuel
  #
  print(iob,AreaName," Total Official ",PollName," Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  print(iob, "Official;Total")
  for year in years
    ZZZ[year] = sum(TotPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  for fuelep in FuelEPs
    print(iob, "EuFPol;", FuelEPDS[fuelep])
    for year in years
      ZZZ[year] = sum(EuFPol[fuelep,ecc,poll,area,year]*Convert[poll]
        for area in areas, ecc in OfficialECCs, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  for fuelep in FuelEPs
    print(iob, "CgFPol;", FuelEPDS[fuelep])
    for year in years
      ZZZ[year] = sum(CgFPol[fuelep,ecc,poll,area,year]*Convert[poll]
        for area in areas, ecc in OfficialECCs, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end
  for fuel in Fuels
    print(iob, "NcFPol;", FuelDS[fuel])
    for year in years
      ZZZ[year] = sum(NcFPol[fuel,ecc,poll,area,year]*Convert[poll]
                      for area in areas, ecc in OfficialECCs, poll in polls)
      print(iob,";",@sprintf("%.7f",ZZZ[year]))
    end
    println(iob)
  end  
  print(iob, "MEPol;Total")
  for year in years
  ZZZ[year] = sum(MEPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  print(iob, "VnPol;Total")
  for year in years
    ZZZ[year] = sum(VnPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  print(iob, "FlPol;Total")
  for year in years
    ZZZ[year] = sum(FlPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  print(iob, "FuPol;Total")
  for year in years
    ZZZ[year] = sum(FuPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  print(iob, "SqPol;Total")
  for year in years
    ZZZ[year] = sum(SqPol[ecc,poll,area,year]*Convert[poll] 
                    for area in areas, ecc in OfficialECCs, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  print(iob,"DACProduction;Total")
  for year in years  
    ZZZ[year] = 0-sum(DACProduction[area,year]*Convert[CO2] for area in areas)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  println(iob)  
  
  #
  # Electricity Imports Emissions
  #
  print(iob,AreaName," Electricity Imports ",PollName," Pollution ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year],)
  end
  println(iob)  
  print(iob, "PolImport;Total")
  for year in years
    ZZZ[year] = sum((PolSpImport[poll,area,year]+PolOthImports[poll,area,year]+
      PolRnImports[poll,area,year])*Convert[poll] for area in areas, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PolSpImport;Specified")
  for year in years
    ZZZ[year] = sum(PolSpImport[poll,area,year]*Convert[poll] for area in areas, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PolRnImports;Renewable")
  for year in years
    ZZZ[year] = sum(PolRnImports[poll,area,year]*Convert[poll] for area in areas, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PolOthImports;Other")
  for year in years
    ZZZ[year] = sum(PolOthImports[poll,area,year]*Convert[poll] for area in areas, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Total with Imports
  #
  print(iob,AreaName," Total ",PollName," Pollution with Imports ($PolUnit/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)    
  print(iob, "Total with Imports;Total")
  for year in years
    ZZZ[year] = sum(TotPol[ecc,poll,area,year]*Convert[poll] for area in areas, ecc in OfficialECCs, poll in polls)+
      sum((PolSpImport[poll,area,year]+PolOthImports[poll,area,year]+
      PolRnImports[poll,area,year])*Convert[poll] for area in areas, poll in polls)
    print(iob,";",@sprintf("%.7f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "Pollution-$PollName-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function Pollution_DtaControl(db)
  @info "Pollution_DtaControl"

  data = PollutionData(; db)
  (; db,Area,Areas,AreaDS,Nation,Poll,PollKey,Polls)= data
  (; Convert,PolConv)= data
  (; PolUnits)= data

  for poll in Polls
    Convert[poll] = 0.001
    PolUnits[poll] = "Kilotonnes"
    if PollKey[poll] == "Hg"
      Convert[poll] = 1000
      PolUnits[poll] = "Kilograms"
    end
  end

  
  #
  ####################
  #
  # CAC Emissions
  #
  polls = Select(Poll,["SOX","PMT","BC"])

  #
  # CAC Emissions for each Area in Canada
  #
  for area in Select(Area, (from = "ON", to = "NU")), poll in polls
    AreaName = AreaDS[area]
    AreaKey = Area[area]
    PollName = PollKey[poll]
    PolUnit = PolUnits[poll]
    Pollution_DtaRun(data,poll,area,AreaName,AreaKey,PollName,PolUnit)
  end

  polls = Select(Poll,["SOX","COX","NOX","PMT","VOC","PM25","PM10","Hg","NH3","BC"])

  #
  # CAC Emissions for Canada
  #
  areas = Select(Area, (from = "ON", to = "NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  for poll in polls
    PollName = PollKey[poll]
    PolUnit = PolUnits[poll]
    Pollution_DtaRun(data,poll,areas,AreaName,AreaKey,PollName,PolUnit)
  end

  #
  # CAC Emissions for United States
  #
  areas = Select(Area, (from = "CA", to = "Pac"))
  AreaName = "United States"
  AreaKey = "US"
  for poll in polls
    PollName = PollKey[poll]
    PolUnit = PolUnits[poll]
    Pollution_DtaRun(data,poll,areas,AreaName,AreaKey,PollName,PolUnit)
  end

  #
  # CAC Emissions for Mexico
  #
  areas = Select(Area, "MX")
  AreaName = "Mexico"
  AreaKey = "MX"
  for poll in polls
    PollName = PollKey[poll]
    PolUnit = PolUnits[poll]
    Pollution_DtaRun(data,poll,areas,AreaName,AreaKey,PollName,PolUnit)
  end



  #
  ####################
  #
  # Emissions for each Area (? CH4 Emissions for Canada)
  #

  poll = Select(Poll, "CH4")
  PollName = PollKey[poll]
  PolUnit = PolUnits[poll]
  for areas in Select(Area, (from = "ON", to = "NU"))
    AreaName = AreaDS[areas]
    AreaKey = Area[areas]
    Pollution_DtaRun(data,poll,areas,AreaName,AreaKey,PollName,PolUnit)
  end

  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])


  #
  # GHG Emissions for Canada
  #
  areas = Select(Area, (from = "ON", to = "NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  for poll in polls
    PollName = PollKey[poll]
    PolUnit = PolUnits[poll]
    Pollution_DtaRun(data,poll,areas,AreaName,AreaKey,PollName,PolUnit)
  end


  #
  # GHG Emissions for United States
  #
  areas = Select(Area, (from = "CA", to = "Pac"))
  AreaName = "United States"
  AreaKey = "US"

  for poll in polls
    PollName = PollKey[poll]
    PolUnit = PolUnits[poll]
    Pollution_DtaRun(data,poll,areas,AreaName,AreaKey,PollName,PolUnit)
  end


  #
  # GHG Emissions for Mexico
  #
  areas = Select(Area, "MX")
  AreaName = "Mexico"
  AreaKey = "MX"
  for poll in polls
    PollName = PollKey[poll]
    PolUnit = PolUnits[poll]
    Pollution_DtaRun(data,poll,areas,AreaName,AreaKey,PollName,PolUnit)
  end

  #
  ####################
  #
  # Total GHG Emissions for each Area
  #
  
  for poll in Polls
    Convert[poll] = PolConv[poll]*0.001
    PolUnits[poll] = "Kilotonnes"
    if PollKey[poll] == "Hg"
      Convert[poll] = PolConv[poll]*1000
      PolUnits[poll] = "Kilograms"
    end
  end
  
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
  PollName = "GHG"
  PolUnit = PolUnits[polls[1]]

  for areas in Areas
    AreaName = AreaDS[areas]
    AreaKey = Area[areas]
    Pollution_DtaRun(data,polls,areas,AreaName,AreaKey,PollName,PolUnit)
  end

  #
  # Total GHG Emissions for Canada
  #
  areas = Select(Area, (from = "ON", to = "NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  Pollution_DtaRun(data,polls,areas,AreaName,AreaKey,PollName,PolUnit)

  #
  # Total GHG Emissions for United States
  #
  areas = Select(Area, (from = "CA", to = "Pac"))
  AreaName = "United States"
  AreaKey = "US"
  Pollution_DtaRun(data,polls,areas,AreaName,AreaKey,PollName,PolUnit)

  #
  # Total GHG Emissions for Mexico
  #
  areas = Select(Area, "MX")
  AreaName = "Mexico"
  AreaKey = "MX"
  Pollution_DtaRun(data,polls,areas,AreaName,AreaKey,PollName,PolUnit)

  #
  # Total High GWP Emissions for California
  #
  polls = Select(Poll,["SF6","PFC","HFC","NF3"])
  PollName = "GWP"
  PolUnit = PolUnits[polls[1]]
  areas = Select(Area, "CA")
  AreaName = "California"
  AreaKey = "CA"
  Pollution_DtaRun(data,polls,areas,AreaName,AreaKey,PollName,PolUnit)

end
if abspath(PROGRAM_FILE) == @__FILE__
Pollution_DtaControl(DB)
end
