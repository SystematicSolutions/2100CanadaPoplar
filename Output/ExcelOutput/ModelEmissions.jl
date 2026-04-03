#
# ModelEmissions.jl
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

Base.@kwdef struct ModelEmissionsData
  db::String

  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int}     = collect(Select(Area))
  ECC::SetArray    = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray  = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int}     = collect(Select(ECC))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray    = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int}  = collect(Select(FuelEP))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db,"MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  Poll::SetArray   = ReadDisk(db,"MainDB/PollKey")
  PollKey::SetArray   = ReadDisk(db,"MainDB/PollKey")  
  Polls::Vector{Int}  = collect(Select(Poll))  
  Year::SetArray   = ReadDisk(db,"MainDB/YearDS")

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  EnFPol::VariableArray{5} = ReadDisk(db,"SOutput/EnFPol") #[FuelEP,ECC,Poll,Area,Year] Energy Related Pollution (Tonnes/Yr) 
  PolConv::VariableArray{1}  = ReadDisk(db,"SInput/PolConv")  #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PolImports::VariableArray{3} = ReadDisk(db, "SOutput/PolImports") # [Poll,Area,Year] Imported Electricity Emissions (Tonnes)
  PolTot::VariableArray{5} = ReadDisk(db, "SOutput/PolTot") # [ECC,Poll,PCov,Area,Year] Total Pollution (Tonnes/Yr)
  # xEnFPol::VariableArray{5} = ReadDisk(db,"SInput/xEnFPol") # [FuelEP,ECC,Poll,Area,Year] Actual Energy Related Pollution (Tonnes/Yr)
  # xPolImports::VariableArray{3} = ReadDisk(db,"SInput/xPolImports") # [Poll,Area,Year] Imported Electricity Emissions (Tonnes)
  # xPolTot::VariableArray{5} = ReadDisk(db,"SInput/xPolTot") # [ECC,Poll,PCov,Area,Year] Historical Pollution (Tonnes/Yr)

  ZZZ::VariableArray{1} = zeros(Float32,length(Year))

end

function ModelEmissions_DtaRun(data,polls,area)
  (; Area,AreaDS,ECC,ECCDS,ECCs,FuelEPDS,FuelEPs,PCovDS,PCovs,Poll,Year) = data
  (; SceName,EnFPol,PolConv,PolImports,PolTot,ZZZ) = data
  
  years = collect(Yr(1990):Final)

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the Carbon Tax Summary.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  println(iob, "$(AreaDS[area]) Emissions (MT/Yr);;    ", join(Year[years], ";"))
  print(iob,"PolTot;Total")  
  for year in years  
    ZZZ[year]=(sum(PolTot[ecc,poll,pcov,area,year]*PolConv[poll] for pcov in PCovs, poll in polls, ecc in ECCs)+
            sum(PolImports[poll,area,year]*PolConv[poll] for poll in polls))/1e6   
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"PolTot;$(ECCDS[ecc])")  
    for year in years  
      ZZZ[year]=(sum(PolTot[ecc,poll,pcov,area,year]*PolConv[poll] for pcov in PCovs, poll in polls))/1e6   
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  print(iob,"PolImports;Electric Imports")  
  for year in years  
    ZZZ[year]=(sum(PolImports[poll,area,year]*PolConv[poll] for poll in polls))/1e6   
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  for pcov in PCovs
    println(iob, "$(AreaDS[area]) $(PCovDS[pcov]) Emissions (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"PolTot;Total")  
    for year in years  
      ZZZ[year]=(sum(PolTot[ecc,poll,pcov,area,year]*PolConv[poll] for poll in polls, ecc in ECCs)+
              sum(PolImports[poll,area,year]*PolConv[poll] for poll in polls))/1e6   
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob,"PolTot;$(ECCDS[ecc])")  
      for year in years  
        ZZZ[year]=(sum(PolTot[ecc,poll,pcov,area,year]*PolConv[poll] for poll in polls))/1e6   
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  # Energy Related Emissions
  #
  println(iob, "$(AreaDS[area]) Energy Related Pollution (MT/Yr);;    ", join(Year[years], ";"))
  print(iob,"EnFPol;Total")  
  for year in years  
    ZZZ[year]=sum(EnFPol[fuelep,ecc,poll,area,year]*PolConv[poll] for poll in polls, ecc in ECCs, fuelep in FuelEPs)/1e6   
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"EnFPol;$(ECCDS[ecc])")  
    for year in years  
      ZZZ[year]=sum(EnFPol[fuelep,ecc,poll,area,year]*PolConv[poll] for poll in polls, fuelep in FuelEPs)/1e6   
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$(AreaDS[area]) Energy Related Pollution (MT/Yr);;    ", join(Year[years], ";"))
  print(iob,"EnFPol;Total")  
  for year in years  
    ZZZ[year]=sum(EnFPol[fuelep,ecc,poll,area,year]*PolConv[poll] for poll in polls, ecc in ECCs, fuelep in FuelEPs)/1e6   
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for fuelep in FuelEPs
    print(iob,"EnFPol;$(FuelEPDS[fuelep])")  
    for year in years  
      ZZZ[year]=sum(EnFPol[fuelep,ecc,poll,area,year]*PolConv[poll] for poll in polls, ecc in ECCs)/1e6   
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  for ecc in ECCs
    println(iob, "$(AreaDS[area]) $(ECCDS[ecc]) Energy Related Pollution (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"EnFPol;Total")  
    for year in years  
      ZZZ[year]=sum(EnFPol[fuelep,ecc,poll,area,year]*PolConv[poll] for poll in polls, fuelep in FuelEPs)/1e6   
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for fuelep in FuelEPs
      print(iob,"EnFPol;$(FuelEPDS[fuelep])")  
      for year in years  
        ZZZ[year]=sum(EnFPol[fuelep,ecc,poll,area,year]*PolConv[poll] for poll in polls)/1e6   
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  # Create *.dta filename and write output values
  #
  filename = "ModelEmissions-$(Area[area])-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function ModelEmissions_DtaControl(db)
  @info "ModelEmissions_DtaControl"

  data = ModelEmissionsData(; db)
  (; db,Area,Areas,AreaDS,Poll,Polls)= data

  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])

  for area in Areas
    ModelEmissions_DtaRun(data,polls,area)
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
ModelEmissions_DtaControl(DB)
end
