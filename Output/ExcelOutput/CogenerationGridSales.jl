#
# CogenerationGridSales.jl
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
Base.@kwdef struct CogenerationGridSalesData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  CgCurtailFraction::VariableArray{3} = ReadDisk(db,"SOutput/CgCurtailFraction") #[ECC,Area,Year]  Fraction of Cogeneration Curtailed (GWh/GWh)
  CgEC::VariableArray{3} = ReadDisk(db,"SOutput/CgEC") # Cogeneration by Economic Category (GWh/YR) [ECC,Area,Year]
  CgECGrid::VariableArray{3} = ReadDisk(db,"SOutput/CgECGrid") # Cogeneration for Grid by Economic Category (GWh/YR) [ECC,Area,Year]
  CgECNoGrid::VariableArray{3} = ReadDisk(db,"SOutput/CgECNoGrid") # Cogeneration not for Grid by Economic Category (GWh/YR) [ECC,Area,Year]
  CgECShutdown::VariableArray{3} = ReadDisk(db,"SOutput/CgECShutdown") #[ECC,Area,Year]  Cogeneration Curtailed by Economic Category (GWh/YR)
  GrElec::VariableArray{3} = ReadDisk(db,"SOutput/GrElec") # Gross Electric Usage (GWh) [ECC,Area,Year]
  MinPurF::VariableArray{3} = ReadDisk(db,"SInput/MinPurF") # [ECC,Area,Year] Minimum Fraction of Electricity which is Purchased (GWh/GWh)
  PSoECC::VariableArray{3} = ReadDisk(db,"SOutput/PSoECC") # [ECC,Area,Year] # Power Sold to Grid (GWh/Yr)
  PSoNoGrid::VariableArray{3} = ReadDisk(db,"SOutput/PSoNoGrid") #[ECC,Area,Year]  Excess Power that cannot be Sold to Grid (GWh)
  PurECC::VariableArray{3} = ReadDisk(db, "SOutput/PurECC") #[ECC,Area,Year]  Purchases from Electric Grid (GWh/Yr)
  # SaEC::VariableArray{3} = ReadDisk(db,"SOutput/SaEC") # [ECC,Area,Year] # Electricity Sales (GWh/Yr)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))
end

function CogenerationGridSales_DtaRun(data,areas,AreaName,AreaKey)
  (; SceName,Area,AreaDS,Areas,ECC,ECCDS,ECCs,Year) = data
  (; CgCurtailFraction,CgEC,CgECGrid,CgECNoGrid,CgECShutdown) = data
  (; GrElec,MinPurF,PSoECC,PSoNoGrid,PurECC,ZZZ) = data

  years = collect(Yr(1990):Yr(2050))

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob,"This is the Cogeneration Grid Sales.")
  println(iob)
  print(iob,"Year;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  println(iob)

  # Total
  print(iob,AreaName," Total Cogeneration Grid Sales (GWh/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob,"CgEC;  Cogeneration Generation Total")
  for year in years
    ZZZ[year] = sum(CgEC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"CgECGrid;  Cogeneration Available for Grid Sales")
  for year in years
    ZZZ[year] = sum(CgECGrid[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"CgECNoGrid;  Cogeneration Not Available for Grid Sales")
  for year in years
    ZZZ[year] = sum(CgECNoGrid[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"GrElec;  Gross Electric Usage (GWh)")
  for year in years
    ZZZ[year] = sum(GrElec[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"GrElec*MinPurF;   Minimum Electricity Sales")
  for year in years
    ZZZ[year] = sum(GrElec[ecc,area,year]*MinPurF[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"PurECC;  Purchases from Electric Grid")
  for year in years
    ZZZ[year] = sum(PurECC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
   
  print(iob,"CgECShutdown;  Cogeneration Curtailed")
  for year in years
    ZZZ[year] = sum(CgECShutdown[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"PSoECC;  Cogeneration Sold to Grid")
  for year in years
    ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  
  print(iob,"PSoNoGrid;  Cogeneration Not Sold to Grid")
  for year in years
    ZZZ[year] = sum(PSoNoGrid[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"CgCurtailFraction;  Fraction of Cogeneration Curtailed")
  for year in years
    area=first(areas)
    ecc=first(ECCs)
    ZZZ[year] = CgCurtailFraction[ecc,area,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"CgCurtailCalc;  Calculated Fraction of Cogeneration Curtailed")
  for year in years
    @finite_math ZZZ[year] = sum(CgECShutdown[ecc,area,year] for area in areas, ecc in ECCs) /
        sum(CgECNoGrid[e,a,year] for a in areas, e in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  # print(iob,"PSoNoGrid;  Excess CoGen power that cannot be Sent to Grid (should be zero)")
  # for year in years
  #   ZZZ[year] = sum(max(CgECNoGrid[ecc,area,year]-(GrElec[ecc,area,year]-GrElec[ecc,area,year]*MinPurF[ecc,area,year]),0) for area in areas, ecc in ECCs)
  #   print(iob,";",@sprintf("%.4f",ZZZ[year]))
  # end
  # println(iob)

  # print(iob,"PSoECCwithShutdowns;  Sales to grid with hypothetical shut down")
  # for year in years
  #   area=first(areas)
  #   ecc=first(ECCs)
  #   ZZZ[year] = (CgECGrid[ecc,area,year]+PurECC[ecc,area,year])-max((GrElec[ecc,area,year]-CgECNoGrid[ecc,area,year]),0)
  #   print(iob,";",@sprintf("%.4f",ZZZ[year]))
  # end
  # println(iob)

  println(iob)

  #Individual ECCs
    for ecc in ECCs
    print(iob,AreaName," ",ECCDS[ecc]," Cogeneration Grid Sales (GWh/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
  
    print(iob,"CgEC;  Cogeneration Generation ",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(CgEC[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  
    print(iob,"CgECGrid;  Cogeneration Available for Grid Sales")
    for year in years
      ZZZ[year] = sum(CgECGrid[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  
    print(iob,"CgECNoGrid;  Cogeneration Not Available for Grid Sales")
    for year in years
      ZZZ[year] = sum(CgECNoGrid[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  
    print(iob,"GrElec;  Gross Electric Usage (GWh)")
    for year in years
      ZZZ[year] = sum(GrElec[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  
    print(iob,"GrElec*MinPurF;   Minimum Electricity Sales")
    for year in years
      ZZZ[year] = sum(GrElec[ecc,area,year]*MinPurF[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  
    print(iob,"PurECC;  Purchases from Electric Grid")
    for year in years
      ZZZ[year] = sum(PurECC[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
     
    print(iob,"CgECShutdown;  Cogeneration Curtailed")
    for year in years
      ZZZ[year] = sum(CgECShutdown[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  
    print(iob,"PSoECC;  Cogeneration Sold to Grid")
    for year in years
      ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
    
    print(iob,"PSoNoGrid;  Cogeneration Not Sold to Grid")
    for year in years
      ZZZ[year] = sum(PSoNoGrid[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  
    print(iob,"CgCurtailFraction;  Fraction of Cogeneration Curtailed")
    for year in years
      area=first(areas)
      ZZZ[year] = CgCurtailFraction[ecc,area,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  
    print(iob,"CgCurtailCalc;  Calculated Fraction of Cogeneration Curtailed")
    for year in years
      @finite_math ZZZ[year] = sum(CgECShutdown[ecc,area,year] for area in areas) /
          sum(CgECNoGrid[ecc,a,year] for a in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  
    # print(iob,"PSoNoGrid;  Excess CoGen power that cannot be Sent to Grid (should be zero)")
    # for year in years
    #   ZZZ[year] = sum(max(CgECNoGrid[ecc,area,year]-(GrElec[ecc,area,year]-GrElec[ecc,area,year]*MinPurF[ecc,area,year]),0) for area in areas)
    #   print(iob,";",@sprintf("%.4f",ZZZ[year]))
    # end
    # println(iob)
  
    # print(iob,"PSoECCwithShutdowns;  Sales to grid with hypothetical shut down")
    # for year in years
    #   area=first(areas)
    #   ZZZ[year] = (CgECGrid[ecc,area,year]+PurECC[ecc,area,year])-max((GrElec[ecc,area,year]-CgECNoGrid[ecc,area,year]),0)
    #   print(iob,";",@sprintf("%.4f",ZZZ[year]))
    # end
    # println(iob)

    println(iob)
  end
    

  #
  # Create *.dta filename and write output values
  #
  filename = "CogenerationGridSales-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end

end

function CogenerationGridSales_DtaControl(db)
  @info "CogenerationGridSales_DtaControl"
  data = CogenerationGridSalesData(; db)
  (; Area,Areas,AreaDS) = data

  #
  # Canada
  #
  areas = Select(Area,(from="ON",to="NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  CogenerationGridSales_DtaRun(data,areas,AreaName,AreaKey)

  #
  # Individual Areas
  #
  for areas in areas
    AreaName = AreaDS[areas]
    AreaKey = Area[areas]
    CogenerationGridSales_DtaRun(data,areas,AreaName,AreaKey)
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
CogenerationGridSales_DtaControl(DB)
end
