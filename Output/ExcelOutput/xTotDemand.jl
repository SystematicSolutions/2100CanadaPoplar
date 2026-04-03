#
# xTotDemand.jl
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

Base.@kwdef struct xTotDemandData
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

  xTotDemand::VariableArray{4} = ReadDisk(db,"SInput/xTotDemand") # Energy Demands (TBtu/Yr) [Fuel,ECC,Area,Year]

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))
end

function xTotDemand_DtaRun(data,areas,AreaName,AreaKey)
  (; SceName,Area, AreaDS, Areas, ECC, ECCDS, ECCs, Fuel, FuelDS, Fuels, Year) = data
  (; xTotDemand,ZZZ) = data
  KJBtu = 1.054615
  years = collect(Yr(1985):Yr(2050))

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob, "Total Energy Demands include enduse, cogeneration and feedstock demands.")
  println(iob)
  println(iob,"Year;",";",join(Year[years],";"))
  println(iob)

  #
  # TotDemand by ECC
  #
  print(iob,AreaName," Total Energy Demands (PJ/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"xTotDemand;N/A")
  for year in years
    ZZZ[year] = sum(xTotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in Fuels) * KJBtu
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob,"xTotDemand;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(xTotDemand[fuel,ecc,area,year] for area in areas, fuel in Fuels) * KJBtu
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)  
  end
  println(iob)
  
  #
  # TotDemand by Fuel
  #  
  print(iob,AreaName," Total Energy Demands (PJ/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"xTotDemand;N/A")
  for year in years
    ZZZ[year] = sum(xTotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in Fuels) * KJBtu
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in Fuels
    print(iob,"xTotDemand;",FuelDS[fuel])
    for year in years
      ZZZ[year] = sum(xTotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs) * KJBtu
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob) 
  end
  println(iob)   
    
  #
  # TotDemand by Fuel for each ECC
  #    
  for ecc in ECCs 
    print(iob,AreaName," ",ECCDS[ecc]," Total Energy Demands (PJ/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"xTotDemand;Total")
    for year in years
      ZZZ[year] = sum(xTotDemand[fuel,ecc,area,year] for area in areas, fuel in Fuels) * KJBtu
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
    for fuel in Fuels   
      print(iob,"xTotDemand;",FuelDS[fuel])
      for year in years
        ZZZ[year] = sum(xTotDemand[fuel,ecc,area,year] for area in areas) * KJBtu
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end 
  
  #
  # TotDemand by ECC for each Fuel
  #  
  for fuel in Fuels
    print(iob,AreaName," ",FuelDS[fuel]," Total Energy Demands (PJ/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"xTotDemand;Total")
    for year in years
      ZZZ[year] = sum(xTotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs) * KJBtu
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs    
      print(iob,"xTotDemand;",ECCDS[ecc])
      for year in years
        ZZZ[year] = sum(xTotDemand[fuel,ecc,area,year] for area in areas) * KJBtu
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  # Create *.dta filename and write output values
  #
  filename = "xTotDemand-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end

end

function xTotDemand_DtaControl(db)
  @info "xTotDemand_DtaControl"
  data = xTotDemandData(; db)
  (; Area,Areas,AreaDS) = data

  #
  # Canada
  #
  areas = Select(Area,(from="ON",to="NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  xTotDemand_DtaRun(data,areas,AreaName,AreaKey)

  #
  #  US
  #
  areas = Select(Area,(from="CA",to="Pac"))
  AreaName = "United States"
  AreaKey = "US"
  xTotDemand_DtaRun(data,areas,AreaName,AreaKey)

  #
  # Individual Areas
  #
  for areas in Areas
    AreaName = AreaDS[areas]
    AreaKey = Area[areas]
    xTotDemand_DtaRun(data,areas,AreaName,AreaKey)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
xTotDemand_DtaControl(DB)
end
