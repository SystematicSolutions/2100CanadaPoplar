#
# WasteArea.jl
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

Base.@kwdef struct WasteAreaData
  db::String
  
  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray  = ReadDisk(db,"MainDB/ECCDS")
  ECCKey::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))

  Nation::SetArray = ReadDisk(db, "MainDB/Nation")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))

  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray  = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Waste::SetArray = ReadDisk(db, "MainDB/WasteKey")
  WasteDS::SetArray = ReadDisk(db, "MainDB/WasteDS")
  Wastes::Vector{Int} = collect(Select(Waste))
  
  Year::SetArray = ReadDisk(db, "MainDB/Year")

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CH4Captured::VariableArray{3} = ReadDisk(db, "MOutput/CH4Captured") # [Waste,Area,Year] CH4 Captured (Tonnes/Yr)
  CH4CorrectionFactor::VariableArray{3} = ReadDisk(db, "MInput/CH4CorrectionFactor") # [Waste,Area,Year] CH4 Correction Factor (MCF) for Aerobic Decomposition (Kg/Kg)
  CH4Emitted::VariableArray{3} = ReadDisk(db, "MOutput/CH4Emitted") # [Waste,Area,Year] CH4 Generated After Recovery (Qt)  (kt/Yr)
  CH4Flared::VariableArray{3} = ReadDisk(db, "MOutput/CH4Flared") # [Waste,Area,Year] CH4 Flared (Tonnes/Yr)
  CH4FlaredLosses::VariableArray{3} = ReadDisk(db, "MOutput/CH4FlaredLosses") # [Waste,Area,Year] CH4 Flared (Tonnes/Yr)
  CH4FlaringFraction::VariableArray{3} = ReadDisk(db, "MInput/CH4FlaringFraction") # [Waste,Area,Year] CH4 Flaring Fraction (Tonnes/Tonnes)
  CH4Generated::VariableArray{3} = ReadDisk(db, "MOutput/CH4Generated") # [Waste,Area,Year] CH4 Generated From Decomposable Material (Qtx) (kt/Yr)
  CH4GenerationRate::VariableArray{3} = ReadDisk(db, "MInput/CH4GenerationRate") # [Waste,Area,Year] CH4 Generation Constant (k)
  CH4Oxidized::VariableArray{3} = ReadDisk(db, "MOutput/CH4Oxidized") # [Waste,Area,Year] CH4 Generated From Decomposable Material <Qtx> (Tonnes/Yr)
  CH4RecoveryFraction::VariableArray{3} = ReadDisk(db, "MInput/CH4RecoveryFraction") # [Waste,Area,Year] CH4 Recovery Fraction (Rt) (kt/kt)
  CH4Volume::VariableArray{1} = ReadDisk(db, "MInput/CH4Volume") # [Waste] Fraction of CH4 by Volume in Landfill Gas (F) (1/1)
  DisposedWastePerDriver::VariableArray{3} = ReadDisk(db, "MInput/DisposedWastePerDriver") # [Waste,Area,Year] Disposed Waste per Driver (DsWC) (kg/person)
  DOCDecomposeFraction::VariableArray{3} = ReadDisk(db, "MInput/DOCDecomposeFraction") # [Waste,Area,Year] Fraction of Decomposable DOC (DOCf) (T/T)
  DOCDecomposed::VariableArray{3} = ReadDisk(db, "MOutput/DOCDecomposed") # [Waste,Area,Year] DOC Decomposed (DDOCm Decomp) (Tonnes/Yr)
  DOCDeposited::VariableArray{3} = ReadDisk(db, "MOutput/DOCDeposited") # [Waste,Area,Year] DOC Deposited (DDOCm) (Tonnes/Yr)
  DOCPerWaste::VariableArray{3} = ReadDisk(db, "MInput/DOCPerWaste") # [Waste,Area,Year] Fraction of Degradable Organic Carbon per Waste Landfilled (T/T)
  DOCStock::VariableArray{3} = ReadDisk(db, "MOutput/DOCStock") # [Waste,Area,Year] Landfill Stock of Decomposable DOC (DDOCma) (Tonnes)
  MEPol::VariableArray{4} = ReadDisk(db, "SOutput/MEPol") # [ECC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)
  MEReduce::VariableArray{4} = ReadDisk(db, "SOutput/MEReduce") # [ECC,Poll,Area,Year] Non Energy Reductions (Tonnes/Yr)
  OxidationFactor::VariableArray{3} = ReadDisk(db, "MInput/OxidationFactor") # [Waste,Area,Year] Oxidation Factor (OX) (1/1)
  PopT::VariableArray{2} = ReadDisk(db, "MOutput/PopT") # [Area,Year] Population (Millions)
  ProportionDivertedWaste::VariableArray{3} = ReadDisk(db, "MInput/ProportionDivertedWaste") # [Waste,Area,Year] Proportion of Diverted Waste (PDvW) (T/T)
  WasteDeposited::VariableArray{3} = ReadDisk(db, "MOutput/WasteDeposited") # [Waste,Area,Year] Waste Deposited in Landfill (Tonnes/Yr)
  WasteDiverted::VariableArray{3} = ReadDisk(db, "MOutput/WasteDiverted") # [Waste,Area,Year] Diverted Waste (Tonnes/Yr)
  WasteDisposed::VariableArray{3} = ReadDisk(db, "MOutput/WasteDisposed") # [Waste,Area,Year] Waste Steam after Waste Diverted (Tonnes/Yr)
  WasteExported::VariableArray{3} = ReadDisk(db, "MOutput/WasteExported") # [Waste,Area,Year] Exported Waste (Tonnes/Yr)
  WasteExportedFraction ::VariableArray{3} = ReadDisk(db, "MInput/WasteExportedFraction") # [Waste,Area,Year] Percentage of Waste Exported (T/T)
  WasteGenerated::VariableArray{3} = ReadDisk(db, "MOutput/WasteGenerated") # [Waste,Area,Year] Waste Generated (Tonnes/Yr)
  WasteIncinerated::VariableArray{3} = ReadDisk(db, "MOutput/WasteIncinerated") # [Waste,Area,Year] Incinerated Waste (Tonnes/Yr)
  WasteIncineratedFraction::VariableArray{3} = ReadDisk(db, "MInput/WasteIncineratedFraction") # [Waste,Area,Year] Percentage of Waste Incinerated (T/T)
  WastePerDriver::VariableArray{3} = ReadDisk(db, "MInput/WastePerDriver") # [Waste,Area,Year] Waste Generated per Driver (WGC) (kg/person)

end

function WasteArea_DtaRun(data, nation, areas, titlename, titlekey, polls, eccs, waste)
  (; AreaDS, ECCDS, Nations, NationDS, Waste, Year) = data
  (; CH4Captured, CH4CorrectionFactor, CH4Emitted, CH4Flared, CH4FlaredLosses, CH4FlaringFraction, 
     CH4Generated, CH4GenerationRate, CH4Oxidized, CH4RecoveryFraction, CH4Volume, DisposedWastePerDriver, 
     DOCDecomposeFraction, DOCDecomposed, DOCDeposited, DOCPerWaste, DOCStock, MEPol, MEReduce, OxidationFactor, 
     PopT, ProportionDivertedWaste, WasteDeposited, WasteDiverted, WasteDisposed, WasteExported, WasteExportedFraction, 
     WasteGenerated, WasteIncinerated, WasteIncineratedFraction, WastePerDriver,SceName) = data
  (; ANMap) = data

  iob = IOBuffer()
  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file produced by WasteArea.jl")
  println(iob, " ")

  years = Select(Year, (from = "1990", to = "2050"))
  println(iob, "Year;", ";", join(Year[years], ";"))
  println(iob, " ")

  println(iob, "Population (Millions);;    ", join(Year[years], ";"))
  print(iob, "PopT;$titlename")
  for year in years
    ZZZ[year] = sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "PopT;$(AreaDS[area])")
    for year in years
      ZZZ[year] = PopT[area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Waste Generated (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "WasteGenerated;$titlename")
  for year in years
    ZZZ[year] = sum(WasteGenerated[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "WasteGenerated;$(AreaDS[area])")
    for year in years
      ZZZ[year] = WasteGenerated[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Diverted Waste (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "WasteDiverted;$titlename")
  for year in years
    ZZZ[year] = sum(WasteDiverted[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "WasteDiverted;$(AreaDS[area])")
    for year in years
      ZZZ[year] = WasteDiverted[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Waste Steam after Waste Diverted  (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "WasteDisposed;$titlename")
  for year in years
    ZZZ[year] = sum(WasteDisposed[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "WasteDisposed;$(AreaDS[area])")
    for year in years
      ZZZ[year] = WasteDisposed[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Exported Waste (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "WasteExported;$titlename")
  for year in years
    ZZZ[year] = sum(WasteExported[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "WasteExported;$(AreaDS[area])")
    for year in years
      ZZZ[year] = WasteExported[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Incinerated Waste (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "WasteIncinerated;$titlename")
  for year in years
    ZZZ[year] = sum(WasteIncinerated[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "WasteIncinerated;$(AreaDS[area])")
    for year in years
      ZZZ[year] = WasteIncinerated[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Waste Deposited in Landfill (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "WasteDeposited;$titlename")
  for year in years
    ZZZ[year] = sum(WasteDeposited[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "WasteDeposited;$(AreaDS[area])")
    for year in years
      ZZZ[year] = WasteDeposited[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Waste Generated per Driver (WGC) (kg/person);;    ", join(Year[years], ";"))
  print(iob, "WastePerDriver;$titlename")
  for year in years
    ZZZ[year] = sum(WastePerDriver[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "WastePerDriver;$(AreaDS[area])")
    for year in years
      ZZZ[year] = WastePerDriver[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Disposed Waste per Driver (DsWC) (kg/person);;    ", join(Year[years], ";"))
  print(iob, "DisposedWastePerDriver;$titlename")
  for year in years
    ZZZ[year] = sum(DisposedWastePerDriver[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "DisposedWastePerDriver;$(AreaDS[area])")
    for year in years
      ZZZ[year] = DisposedWastePerDriver[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Proportion of Diverted Waste (PDvW) (Tonnes/Tonnes);;    ", join(Year[years], ";"))
  print(iob, "ProportionDivertedWaste;$titlename")
  for year in years
    ZZZ[year] = sum(ProportionDivertedWaste[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "ProportionDivertedWaste;$(AreaDS[area])")
    for year in years
      ZZZ[year] = ProportionDivertedWaste[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Percentage of Waste Exported (Tonnes/Tonnes);;    ", join(Year[years], ";"))
  print(iob, "WasteExportedFraction;$titlename")
  for year in years
    ZZZ[year] = sum(WasteExportedFraction[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "WasteExportedFraction;$(AreaDS[area])")
    for year in years
      ZZZ[year] = WasteExportedFraction[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Percentage of Waste Incinerated (Tonnes/Tonnes);;    ", join(Year[years], ";"))
  print(iob, "WasteIncineratedFraction;$titlename")
  for year in years
    ZZZ[year] = sum(WasteIncineratedFraction[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "WasteIncineratedFraction;$(AreaDS[area])")
    for year in years
      ZZZ[year] = WasteIncineratedFraction[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "DOC Deposited (DDOCm) (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "DOCDeposited;$titlename")
  for year in years
    ZZZ[year] = sum(DOCDeposited[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "DOCDeposited;$(AreaDS[area])")
    for year in years
      ZZZ[year] = DOCDeposited[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "DOC Decomposed (DDOCm Decomp) (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "DOCDecomposed;$titlename")
  for year in years
    ZZZ[year] = sum(DOCDecomposed[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "DOCDecomposed;$(AreaDS[area])")
    for year in years
      ZZZ[year] = DOCDecomposed[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Stock of Decomposable DOC in Landfill (DDOCma) (Tonnes);;    ", join(Year[years], ";"))
  print(iob, "DOCStock;$titlename")
  for year in years
    ZZZ[year] = sum(DOCStock[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "DOCStock;$(AreaDS[area])")
    for year in years
      ZZZ[year] = DOCStock[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Fraction of Degradable Organic Carbon per Waste Landfilled (Tonnes/Tonnes);;    ", join(Year[years], ";"))
  print(iob, "DOCPerWaste;$titlename")
  for year in years
    ZZZ[year] = sum(DOCPerWaste[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "DOCPerWaste;$(AreaDS[area])")
    for year in years
      ZZZ[year] = DOCPerWaste[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Fraction of Decomposable DOC (DOCf) (Tonnes/Tonnes);;    ", join(Year[years], ";"))
  print(iob, "DOCDecomposeFraction;$titlename")
  for year in years
    ZZZ[year] = sum(DOCDecomposeFraction[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "DOCDecomposeFraction;$(AreaDS[area])")
    for year in years
      ZZZ[year] = DOCDecomposeFraction[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Generated From Decomposable Material (Qtx) (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "CH4Generated;$titlename")
  for year in years
    ZZZ[year] = sum(CH4Generated[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4Generated;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4Generated[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Captured (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "CH4Captured;$titlename")
  for year in years
    ZZZ[year] = sum(CH4Captured[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4Captured;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4Captured[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Flared (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "CH4Flared;$titlename")
  for year in years
    ZZZ[year] = sum(CH4Flared[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4Flared;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4Flared[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Flared Losses (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "CH4FlaredLosses;$titlename")
  for year in years
    ZZZ[year] = sum(CH4FlaredLosses[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4FlaredLosses;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4FlaredLosses[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Oxidized (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "CH4Oxidized;$titlename")
  for year in years
    ZZZ[year] = sum(CH4Oxidized[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4Oxidized;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4Oxidized[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Emitted (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "CH4Emitted;$titlename")
  for year in years
    ZZZ[year] = sum(CH4Emitted[waste,area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4Emitted;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4Emitted[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Correction Factor (MCF) for Aerobic Decomposition (T/T);;    ", join(Year[years], ";"))
  print(iob, "CH4CorrectionFactor;$titlename")
  for year in years
    ZZZ[year] = sum(CH4CorrectionFactor[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4CorrectionFactor;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4CorrectionFactor[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Generation Constant (k);;    ", join(Year[years], ";"))
  print(iob, "CH4GenerationRate;$titlename")
  for year in years
    ZZZ[year] = sum(CH4GenerationRate[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4GenerationRate;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4GenerationRate[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Fraction of CH4 by Volume in Landfill Gas (F) (1/1);;    ", join(Year[years], ";"))
  print(iob, "CH4Volume;$titlename")
  for year in years
    ZZZ[year] = CH4Volume[waste]
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4Volume;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4Volume[waste]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Oxidation Factor;;    ", join(Year[years], ";"))
  print(iob, "OxidationFactor;$titlename")
  for year in years
    ZZZ[year] = sum(OxidationFactor[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "OxidationFactor;$(AreaDS[area])")
    for year in years
      ZZZ[year] = OxidationFactor[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Recovery Fraction (Rt) (Tonnes/Tonnes);;    ", join(Year[years], ";"))
  print(iob, "CH4RecoveryFraction;$titlename")
  for year in years
    ZZZ[year] = sum(CH4RecoveryFraction[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4RecoveryFraction;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4RecoveryFraction[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "CH4 Flaring Fraction (Tonnes/Tonnes);;    ", join(Year[years], ";"))
  print(iob, "CH4FlaringFraction;$titlename")
  for year in years
    ZZZ[year] = sum(CH4FlaringFraction[waste,area,year]*PopT[area,year] for area in areas)/
      sum(PopT[area,year] for area in areas)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "CH4FlaringFraction;$(AreaDS[area])")
    for year in years
      ZZZ[year] = CH4FlaringFraction[waste,area,year]
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  ecc_single=first(eccs)
  println(iob, "$(ECCDS[ecc_single]) CH4 Non Energy Reductions (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "MEReduce;$titlename")
  for year in years
    ZZZ[year] = sum(MEReduce[ecc,poll,area,year] for area in areas, poll in polls, ecc in eccs)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "MEReduce;$(AreaDS[area])")
    for year in years
      ZZZ[year] = sum(MEReduce[ecc,poll,area,year] for poll in polls, ecc in eccs)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$(ECCDS[ecc_single]) CH4 Non-Energy Pollution (Tonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "MEPol;$titlename")
  for year in years
    ZZZ[year] = sum(MEPol[ecc,poll,area,year] for area in areas, poll in polls, ecc in eccs)
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "MEPol;$(AreaDS[area])")
    for year in years
      ZZZ[year] = sum(MEPol[ecc,poll,area,year] for poll in polls, ecc in eccs)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  wastekey = Waste[waste]
  filename = "WasteArea-$wastekey-$titlekey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function WasteArea_DtaControl(db)
  @info "WasteArea_DtaControl"
  data = WasteAreaData(; db)
  (; Nation, NationDS, Area, AreaDS, ECC, Poll, Wastes) = data
  (; Nations, Areas, ECCs, Polls) = data
  
  polls = Select(Poll, "CH4")
  eccs = Select(ECC, "SolidWaste")
  nation = Select(Nation,"CN")
  areas = Select(Area, (from = "ON", to = "NU"))

  titlename = NationDS[nation]
  titlekey = Nation[nation]
  for waste in Wastes
    WasteArea_DtaRun(data, nation, areas, titlename, titlekey, polls, eccs, waste)
  end 

end
if abspath(PROGRAM_FILE) == @__FILE__
WasteArea_DtaControl(DB)
end
