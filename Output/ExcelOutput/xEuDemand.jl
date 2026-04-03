#
# xEuDemand.jl
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

Base.@kwdef struct xEuDemandData
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
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # Energy Demands (TBtu/Yr) [Fuel,ECC,Area,Year]

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))
end

function xEuDemand_DtaRun(data,areas,AreaName,AreaKey)
  (; SceName,Area, AreaDS, Areas, ECC, ECCDS, ECCs, Fuel, FuelDS, Fuels, Year) = data
  (; xEuDemand,ZZZ) = data
  KJBtu = 1.054615
  years = collect(Yr(1985):Yr(2050))

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob,"Enduse Energy Demands")
  println(iob)
  println(iob,"Year;",";",join(Year[years],";"))
  println(iob)

  #
  # EuDemand by ECC
  #
  print(iob,AreaName," Enduse Energy Demands (PJ/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"xEuDemand;N/A")
  for year in years
    ZZZ[year] = sum(xEuDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in Fuels) * KJBtu
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"EuDemand;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(xEuDemand[fuel,ecc,area,year] for area in areas, fuel in Fuels) * KJBtu
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)  
  end
  println(iob)
  
  #
  # EuDemand by Fuel
  #  
  print(iob,AreaName," Enduse Energy Demands (PJ/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"xEuDemand;N/A")
  for year in years
    ZZZ[year] = sum(xEuDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in Fuels) * KJBtu
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in Fuels
    print(iob,"EuDemand;",FuelDS[fuel])
    for year in years
      ZZZ[year] = sum(xEuDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs) * KJBtu
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob) 
  end
  println(iob)   
    
  #
  # EuDemand by Fuel for each ECC
  #    
  for ecc in ECCs 
    print(iob,AreaName," ",ECCDS[ecc]," Enduse Energy Demands (PJ/Yr);;")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"xEuDemand;Total")
    for year in years
      ZZZ[year] = sum(xEuDemand[fuel,ecc,area,year] for area in areas, fuel in Fuels) * KJBtu
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
    for fuel in Fuels   
      print(iob,"EuDemand;",FuelDS[fuel])
      for year in years
        ZZZ[year] = sum(xEuDemand[fuel,ecc,area,year] for area in areas) * KJBtu
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end 
  
  #
  # EuDemand by ECC for each Fuel
  #  
  for fuel in Fuels
    print(iob,AreaName," ",FuelDS[fuel]," Enduse Energy Demands (PJ/Yr);;")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"xEuDemand;Total")
    for year in years
      ZZZ[year] = sum(xEuDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs) * KJBtu
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs    
      print(iob,"EuDemand;",ECCDS[ecc])
      for year in years
        ZZZ[year] = sum(xEuDemand[fuel,ecc,area,year] for area in areas) * KJBtu
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  # Create *.dta filename and write output values
  #
  filename = "xEuDemand-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end

end

function xEuDemand_DtaControl(db)
  @info "xEuDemand_DtaControl"
  data = xEuDemandData(; db)
  (; Area,Areas,AreaDS) = data

  #
  # Canada
  #
  areas = Select(Area,(from="ON",to="NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  xEuDemand_DtaRun(data,areas,AreaName,AreaKey)

  #
  #  US
  #
  areas = Select(Area,(from="CA",to="Pac"))
  AreaName = "United States"
  AreaKey = "US"
  xEuDemand_DtaRun(data,areas,AreaName,AreaKey)

  #
  # Individual Areas
  #
  for areas in Areas
    AreaName = AreaDS[areas]
    AreaKey = Area[areas]
    xEuDemand_DtaRun(data,areas,AreaName,AreaKey)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
xEuDemand_DtaControl(DB)
end

