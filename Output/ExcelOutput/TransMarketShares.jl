#
# TransMarketShares.jl
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

Base.@kwdef struct TransMarketSharesData
  db::String

  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  CTech::SetArray    = ReadDisk(db,"TInput/CTechKey")
  CTechDS::SetArray  = ReadDisk(db,"TInput/CTechDS")
  EC::SetArray    = ReadDisk(db,"TInput/ECKey")
  ECDS::SetArray  = ReadDisk(db,"TInput/ECDS")
  ECs::Vector{Int}     = collect(Select(EC))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech::SetArray    = ReadDisk(db,"TInput/TechKey")
  TechDS::SetArray  = ReadDisk(db,"TInput/TechDS")
  Year::SetArray   = ReadDisk(db,"MainDB/YearDS")

  AMSF::VariableArray{5} = ReadDisk(db, "TOutput/AMSF") #[Enduse,Tech,EC,Area,Year] Average Market Share ($/$)
  CMSF::VariableArray{6} = ReadDisk(db, "TOutput/CMSF") #[Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Fraction by Device ($/$)
  Dmd::VariableArray{5} = ReadDisk(db, "TOutput/Dmd") #[Enduse,Tech,EC,Area,Year]  Total Energy Demand (TBtu/Yr)
  DPConv::VariableArray{5} = ReadDisk(db, "TInput/DPConv") #[Enduse,Tech,EC,Area,Year] Device Process Conversion (Vehicle Mile/Passenger Mile)
  MMSF::VariableArray{5} = ReadDisk(db, "TOutput/MMSF") #[Enduse,Tech,EC,Area,Year]  Market Share Fraction by Device ($/$)
  VDT::VariableArray{5} = ReadDisk(db, "TOutput/VDT") #[Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  VehicleSales::VariableArray{5} = ReadDisk(db, "TOutput/VehicleSales") #[Enduse,Tech,EC,Area,Year] Total Sales of Vehicles (Vehicles)
  VehicleStock::VariableArray{5} = ReadDisk(db, "TOutput/VehicleStock") #[Enduse,Tech,EC,Area,Year] Stock of Vehicles (Vehicles)
end

function TechSelect_MSF(data,eckey)
  (; EC,Tech) = data

  if eckey == "Passenger"
    techs = Select(Tech,(from="LDVGasoline", to="TrainFuelCell"))
  elseif eckey == "Freight"
    techs_a =  Select(Tech,(from="TrainDiesel", to="MarineFuelCell"))
    techs_b = Select(Tech,"OffRoad")
    techs = union(techs_a,techs_b)
  elseif eckey == "AirPassenger"
    techs = Select(Tech,["PlaneJetFuel","PlaneGasoline","OffRoad"])
  elseif eckey == "AirFreight"
    techs = Select(Tech,["PlaneJetFuel","PlaneGasoline","PlaneFuelCell","OffRoad"])
  elseif eckey == "ForeignPassenger"
    techs = Select(Tech,["PlaneJetFuel","PlaneGasoline","PlaneFuelCell","MarineLight","MarineHeavy","MarineFuelCell","OffRoad"])
  elseif eckey == "ForeignFreight"
    techs = Select(Tech,["PlaneJetFuel","PlaneGasoline","PlaneFuelCell","MarineLight","MarineHeavy","MarineFuelCell","OffRoad"])
  elseif eckey == "ResidentialOffRoad"
    techs = Select(Tech,"OffRoad")
  elseif eckey == "CommercialOffRoad"
    techs = Select(Tech,"OffRoad")
  else
    techs = Select(Tech)
  end

  return techs
end

function TransMarketShares_DtaRun(data,areas,AreaName,AreaKey)
  (; SceName,Area,AreaDS,CTech,CTechDS,EC,ECDS,Tech,TechDS,Year) = data
  (; AMSF,CMSF,Dmd,DPConv,MMSF,VDT,VehicleSales,VehicleStock) = data

  MSFTemp = zeros(Float32, length(Area), length(Year))
  DmdTemp = zeros(Float32, length(Area), length(Year))
  Total = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))

  enduse = 1
  # size(Dmd)  = (1, 57, 8, 25, 67)
  # size(MMSF) = (1, 57, 8, 25, 67)
  area_one = first(areas)
  # year = Select(Year, (from = "1990", to = "2050"))
  years = collect(Yr(1990):Yr(2050))
  iob = IOBuffer()

  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Total; for all geographical areas.")
  println(iob, "This is the Transportation Market Share Summary.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  ecs = Select(EC,"Passenger")
  for ec in ecs
    techs = TechSelect_MSF(data,EC[ec])

    print(iob, AreaName, " ",ECDS[ec]," Market Share of Energy Demand (1/1);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      Total[year] = sum(Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs)
      ZZZ[year] = sum(Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs) / Total[year]
    end
    print(iob, "Dmd;Total")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(Dmd[enduse,tech,ec,area,year] for area in areas) / Total[year]
      end
      print(iob, "Dmd;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Market Share of Vehicle Sales (1/1);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      Total[year] = sum(VehicleSales[enduse,tech,ec,area,year] for area in areas, tech in techs)
      ZZZ[year] = sum(VehicleSales[enduse,tech,ec,area,year] for area in areas, tech in techs) / Total[year]
    end
    print(iob, "VehicleSales;Total")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(VehicleSales[enduse,tech,ec,area,year] for area in areas) / Total[year]
      end
      print(iob, "VehicleSales;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.6f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Market Share of Vehicle Stock (1/1);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      Total[year] = sum(VehicleStock[enduse,tech,ec,area,year] for area in areas, tech in techs)
      ZZZ[year] = sum(VehicleStock[enduse,tech,ec,area,year] for area in areas, tech in techs) / Total[year]
    end
    print(iob, "VehicleStock;Total")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(VehicleStock[enduse,tech,ec,area,year] for area in areas) / Total[year]
      end
      print(iob, "VehicleStock;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.6f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Market Share of Vehicle Miles (1/1);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      Total[year] = sum(VDT[enduse,tech,ec,area,year] for area in areas, tech in techs)
      ZZZ[year] = sum(VDT[enduse,tech,ec,area,year] for area in areas, tech in techs) / Total[year]
    end
    print(iob, "VDT;Total")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(VDT[enduse,tech,ec,area,year] for area in areas) / Total[year]
      end
      print(iob, "VDT;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.6f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Market Share of Passenger Miles (1/1);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      Total[year] = sum(VDT[enduse,tech,ec,area,year] ./ DPConv[enduse,tech,ec,area,year] for area in areas, tech in techs)
      ZZZ[year] = sum(VDT[enduse,tech,ec,area,year] ./ DPConv[enduse,tech,ec,area,year] for area in areas, tech in techs) / Total[year]
    end  
    print(iob, "VDT/DPConv;Total")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(VDT[enduse,tech,ec,area,year] / DPConv[enduse,tech,ec,area,year] for area in areas) / Total[year]
      end
      print(iob, "VDT/DPConv;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.6f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," TODOJulia Marginal Market Share (1/1);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years, area in areas
      MSFTemp[area,year] = sum(MMSF[enduse,tech,ec,area,year] for tech in techs)
      DmdTemp[area,year] = sum(Dmd[enduse,tech,ec,area,year] for tech in techs)
    end
    for year in years
      Total[year] = sum(Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs)
      ZZZ[year] = sum(MSFTemp[area,year] * DmdTemp[area,year] for area in areas) / Total[year]
      # ZZZ[year] = sum(MMSF[enduse,tech,ec,area,year] .* Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs) ./ Total[year]
    end
    print(iob, "MMSF;Total")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(MMSF[enduse,tech,ec,area,year] * Dmd[enduse,tech,ec,area,year] for area in areas) / Total[year]
      end
      print(iob, "MMSF;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.6f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," TODOJulia Average Market Share (1/1);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years, area in areas
      MSFTemp[area,year] = sum(AMSF[enduse,tech,ec,area,year] for tech in techs)
      DmdTemp[area,year] = sum(Dmd[enduse,tech,ec,area,year] for tech in techs)
    end
    for year in years
      Total[year] = sum(Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs)
      ZZZ[year] = sum(MSFTemp[area,year] * DmdTemp[area,year] for area in areas) / Total[year]
      # ZZZ[year] = sum(AMSF[enduse,tech,ec,area,year] .* Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs) ./ Total[year]
    end  
    print(iob, "AMSF;Total")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years, area in areas
        MSFTemp[area,year] = AMSF[enduse,tech,ec,area,year]
        DmdTemp[area,year] = Dmd[enduse,tech,ec,area,year]
      end
      for year in years
        ZZZ[year] = sum(MSFTemp[area,year] * DmdTemp[area,year] for area in areas) / Total[year]
        # ZZZ[year] = sum(AMSF[enduse,tech,ec,area,year] .* Dmd[enduse,tech,ec,area,year] for area in areas) ./ Total[year]
      end  
      print(iob, "AMSF;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.6f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    for ctech in techs
      print(iob, AreaName, " ",ECDS[ec]," TODOJulia Conversion Market Share From ", CTechDS[ctech]," (1/1);")
      for year in years  
        print(iob,";",Year[year])
      end
      println(iob)
      for year in years, area in areas
        MSFTemp[area,year] = sum(CMSF[enduse,tech,ctech,ec,area,year] for tech in techs)
        DmdTemp[area,year] = sum(Dmd[enduse,tech,ec,area,year] for tech in techs)
      end
      for year in years
        Total[year] = sum(Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs)
        ZZZ[year] = sum(MSFTemp[area,year] * DmdTemp[area,year] for area in areas) / Total[year]
        # ZZZ[year] = sum(CMSF[enduse,tech,ctech,ec,area,year] .* Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs) ./ Total[year]
      end  
      print(iob, "CMSF;Total")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
      for tech in techs
        for year in years
          ZZZ[year] = sum(CMSF[enduse,tech,ctech,ec,area,year] * Dmd[enduse,tech,ec,area,year] for area in areas) / Total[year]
        end
        print(iob, "CMSF;", TechDS[tech])
        for year in years
          print(iob,";",@sprintf("%.6f", ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end
    println(iob)

  end

  #
  # Create *.dta filename and write output values
  #
  filename = "TransMarketShares-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TransMarketShares_DtaControl(db)
  @info "TransMarketShares_DtaControl"

  data = TransMarketSharesData(; db)
  (; db,Area,AreaDS)= data

  areas = Select(Area, (from = "ON", to = "NU"))
  #
  # Individual Areas
  #
  for areas in areas
    AreaName = AreaDS[areas]
    AreaKey = Area[areas]
    TransMarketShares_DtaRun(data,areas,AreaName,AreaKey)
  end
  #
  # Canada
  #
  AreaName = "Canada"
  AreaKey = "CN"
  TransMarketShares_DtaRun(data,areas,AreaName,AreaKey)

end
if abspath(PROGRAM_FILE) == @__FILE__
TransMarketShares_DtaControl(DB)
end

