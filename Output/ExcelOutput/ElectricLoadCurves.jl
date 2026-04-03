#
# ElectricLoadCurves.jl
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


Base.@kwdef struct ElectricLoadCurvesData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  DayDS::SetArray = ReadDisk(db,"MainDB/DayDS")
  Days::Vector{Int} = collect(Select(Day))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  HourDS::SetArray = ReadDisk(db,"MainDB/HourDS")
  Hours::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db,"MainDB/Year")

  CgEC::VariableArray{3} = ReadDisk(db,"SOutput/CgEC") # Cogeneration by Economic Category (GWh/YR) [ECC,Area,Year]
  CgLDCECC::VariableArray{6} = ReadDisk(db,"SOutput/CgLDCECC") # [ECC,Hour,Day,Month,Area]# Cogeneration Load Curve (MW)
  CgLDCSoldECC::VariableArray{6} = ReadDisk(db,"SOutput/CgLDCSoldECC") # [ECC,Hour,Day,Month,Area]# Cogeneration Sold to Grid Load Curve (MW)
  ElecDmd::VariableArray{3} = ReadDisk(db,"SOutput/ElecDmd") # [ECC,Area]   # Electricity Gross Demands (GWh/Yr)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month (Hours/Month)
  LDCECC::VariableArray{6} = ReadDisk(db,"SOutput/LDCECC") # [ECC,Hour,Day,Month,Area] # Electric Loads Dispatched (MW)
  LDCECCGrid::VariableArray{6} = ReadDisk(db,"SOutput/LDCECCGrid") # [ECC,Hour,Day,Month,Area] # Electric Loads from Grid (MW)
  MonOut::VariableArray{3} = ReadDisk(db,"SOutput/MonOut") #[Month,Area,Year]  Monthly Output (GWh/Month)
  PkLoad::VariableArray{3} = ReadDisk(db,"SOutput/PkLoad") # (Month,Area,Year),Monthly Peak Load (MW)
  PSoECC::VariableArray{3} = ReadDisk(db,"SOutput/PSoECC") # [ECC,Area] # Power Sold to Grid (GWh/Yr)
  SaEC::VariableArray{3} = ReadDisk(db,"SOutput/SaEC") # [ECC,Area] # Electricity Sales (GWh/Yr)
  TDEF::VariableArray{3} = ReadDisk(db,"SInput/TDEF") # [Fuel,Area,Year] T&D Efficiency (MW/MW)

  # Scratch Variables
  ZZZ = zeros(Float32,length(Year))

end

function ElectricLoadCurves_DtaRun(data,TitleKey,TitleName,areas)
  (; SceName,Area,AreaDS,Day,DayDS,Days,ECC,ECCDS,ECCs,Fuel,FuelDS,Fuels) = data
  (; Hour,HourDS,Hours,Month,MonthDS,Months,Year) = data
  (; CgEC,CgLDCECC,CgLDCSoldECC,ElecDmd,HoursPerMonth,LDCECC) = data
  (; LDCECCGrid,MonOut,PkLoad,PSoECC,SaEC,TDEF) = data
  (; ZZZ) = data

  iob = IOBuffer()
  
  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob,"$TitleName; is the area being output.")
  println(iob,"This file was produced by ElectricLoadCurves.jl")
  println(iob)

  years = collect(Yr(1990):Final)
  println(iob,"Year;",";    ",join(Year[years],";"))
  println(iob)

  #
  # Peak Loads
  #
  print(iob,TitleName," Peak Loads (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"PkLoad;Annual")
  for year in years
    ZZZ[year] = maximum(sum(PkLoad[month,area,year] for area in areas) for month in Months)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Monthly Output
  #
  print(iob,TitleName," Monthly Output (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"MonOut;Total")
  for year in years
    ZZZ[year] = sum(MonOut[month,area,year] for area in areas, month in Months)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob,TitleName," Electric Loads Purchased from Grid (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"LDCECCGrid;Total")
  day=Select(Day,"Average")
  for year in years
    ZZZ[year] = sum(LDCECCGrid[ecc,hour,day,month,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob,TitleName," Electric Loads Supplied with Utility Power including Losses (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"LDCECC w/Losses;Total")
  fuel=Select(Fuel,"Electric")
  day=Select(Day,"Average")
  for year in years
    @finite_math ZZZ[year] = sum(LDCECC[ecc,hour,day,month,area,year]/TDEF[fuel,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob,TitleName," Electric Loads Supplied with Utility Power (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"LDCECC;Total")
  day=Select(Day,"Average")
  for year in years
    ZZZ[year] = sum(LDCECC[ecc,hour,day,month,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Sales
  #
  print(iob,TitleName," Electricity Sales (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"SaEC;Total")
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Electric Demands
  #
  print(iob,TitleName," Electric Demands (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"ElecDmd;Total")
  for year in years
    ZZZ[year] = sum(ElecDmd[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Cogeneration Generation
  #
  print(iob,TitleName," Cogeneration by Economic Category (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgEC;Total")
  for year in years
    ZZZ[year] = sum(CgEC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Cogeneration Sold to Grid
  #
  print(iob,TitleName," Generation Sold to Grid (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"PSoECC;Total")
  for year in years
    ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,TitleName," Cogeneration Average Load Curve (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgLDCECC;Total")
  day=Select(Day,"Average")
  for year in years
    ZZZ[year] = sum(CgLDCECC[ecc,hour,day,month,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,TitleName," Cogeneration Sold to Grid Average Load Curve (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgLDCSoldECC;Total")
  day=Select(Day,"Average")
  for year in years
    ZZZ[year] = sum(CgLDCSoldECC[ecc,hour,day,month,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  ##########################################

  #
  # Peak Loads
  #
  print(iob,TitleName," Peak Loads (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"PkLoad;Annual")
  for year in years
    ZZZ[year] = maximum(sum(PkLoad[month,area,year] for area in areas) for month in Months)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob,"PkLoad;$(MonthDS[month])")
    for year in years
      ZZZ[year] = sum(PkLoad[month,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Monthly Output
  #
  print(iob,TitleName," Monthly Output (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"MonOut;Total")
  for year in years
    ZZZ[year] = sum(MonOut[month,area,year] for area in areas, month in Months)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob,"MonOut;$(MonthDS[month])")
    for year in years
      ZZZ[year] = sum(MonOut[month,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob,TitleName," Electric Loads Purchased from Grid (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"LDCECCGrid;Total")
  day=Select(Day,"Average")
  for year in years
    ZZZ[year] = sum(LDCECCGrid[ecc,hour,day,month,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"LDCECCGrid;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(LDCECCGrid[ecc,hour,day,month,area,year]*
          HoursPerMonth[month] for area in areas, month in Months, hour in Hours)/1000
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,TitleName," Electric Loads Supplied with Utility Power including Losses (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"LDCECC w/Losses;Total")
  fuel=Select(Fuel,"Electric")
  day=Select(Day,"Average")
  for year in years
    @finite_math ZZZ[year] = sum(LDCECC[ecc,hour,day,month,area,year]/TDEF[fuel,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob,"LDCECC w/Losses;$(MonthDS[month])")
    for year in years
      @finite_math ZZZ[year] = sum(LDCECC[ecc,hour,day,month,area,year]/TDEF[fuel,area,year]*
          HoursPerMonth[month] for area in areas, hour in Hours, ecc in ECCs)/1000
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,TitleName," Electric Loads Supplied with Utility Power (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"LDCECC;Total")
  day=Select(Day,"Average")
  for year in years
    ZZZ[year] = sum(LDCECC[ecc,hour,day,month,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"LDCECC;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(LDCECC[ecc,hour,day,month,area,year]*
          HoursPerMonth[month] for area in areas, month in Months, hour in Hours)/1000
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  #
  # Sales
  #
  print(iob,TitleName," Electricity Sales (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"SaEC;Total")
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"SaEC;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Electric Demands
  #
  print(iob,TitleName," Electric Demands (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"ElecDmd;Total")
  for year in years
    ZZZ[year] = sum(ElecDmd[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"ElecDmd;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(ElecDmd[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)


  #
  # Cogeneration Generation
  #
  print(iob,TitleName," Cogeneration by Economic Category (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgEC;Total")
  for year in years
    ZZZ[year] = sum(CgEC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"CgEC;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(CgEC[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Cogeneration Sold to Grid
  #
  print(iob,TitleName," Generation Sold to Grid (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"PSoECC;Total")
  for year in years
    ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"PSoECC;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob,TitleName," Cogeneration Average Load Curve (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgLDCECC;Total")
  day=Select(Day,"Average")
  for year in years
    ZZZ[year] = sum(CgLDCECC[ecc,hour,day,month,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"CgLDCECC;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(CgLDCECC[ecc,hour,day,month,area,year]*
      HoursPerMonth[month] for area in areas, hour in Hours, month in Months)/1000
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob,TitleName," Cogeneration Sold to Grid Average Load Curve (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgLDCSoldECC;Total")
  day=Select(Day,"Average")
  for year in years
    ZZZ[year] = sum(CgLDCSoldECC[ecc,hour,day,month,area,year]*
        HoursPerMonth[month] for area in areas, month in Months, hour in Hours, ecc in ECCs)/1000
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"CgLDCSoldECC;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(CgLDCSoldECC[ecc,hour,day,month,area,year]*
      HoursPerMonth[month] for area in areas, hour in Hours, month in Months)/1000
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  filename = "ElectricLoadCurves-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end
end

function ElectricLoadCurves_DtaControl(db)
  @info "ElectricLoadCurves_DtaControl"
  data = ElectricLoadCurvesData(; db)
  Area = data.Area
  AreaDS = data.AreaDS

  #
  # Canada
  #
  areas=Select(Area,(from ="ON",to="NU"))
  for area in areas
    ElectricLoadCurves_DtaRun(data,Area[area],AreaDS[area],area)
  end
  ElectricLoadCurves_DtaRun(data,"CN","Canada",areas)

  #
  # US
  #
  areas=Select(Area,(from ="CA",to="Pac"))
  for area in areas
    ElectricLoadCurves_DtaRun(data,Area[area],AreaDS[area],area)
  end
  ElectricLoadCurves_DtaRun(data,"US","US",areas)

  #
  # MX
  #
  area=Select(Area,"MX")
  ElectricLoadCurves_DtaRun(data,Area[area],AreaDS[area],area)


end
if abspath(PROGRAM_FILE) == @__FILE__
ElectricLoadCurves_DtaControl(DB)
end
