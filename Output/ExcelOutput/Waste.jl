#
# Waste.jl
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

Base.@kwdef struct WasteData
  db::String

  
  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray  = ReadDisk(db,"MainDB/ECCDS")
  ECCKey::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))

  Nation::SetArray = ReadDisk(db, "MainDB/Nation")
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

function Waste_DtaRun(data, areas, areaname, areakey, polls, eccs, waste)
  (; Waste, Year) = data
  (; CH4Captured, CH4CorrectionFactor, CH4Emitted, CH4Flared, CH4FlaredLosses, CH4FlaringFraction, 
     CH4Generated, CH4GenerationRate, CH4Oxidized, CH4RecoveryFraction, CH4Volume, DisposedWastePerDriver, 
     DOCDecomposeFraction, DOCDecomposed, DOCDeposited, DOCPerWaste, DOCStock, MEPol, MEReduce, OxidationFactor, 
     PopT, ProportionDivertedWaste, WasteDeposited, WasteDiverted, WasteDisposed, WasteExported, WasteExportedFraction, 
     WasteGenerated, WasteIncinerated, WasteIncineratedFraction, WastePerDriver,SceName) = data
  (; ANMap, Nations, ) = data

  iob = IOBuffer()
  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file produced by Waste.jl")
  println(iob, " ")

  year = Select(Year, (from = "1990", to = "2050"))
  println(iob, "Year;", ";    ", join(Year[year], ";"))
  println(iob, " ")

  println(iob, areaname, " Waste Summary (Tonnes/Yr);;    ", join(Year[year], ";"))
  ZZZ[year] = sum(WasteGenerated[waste,area,year] for area in areas)
  print(iob, "WasteGenerated;Generated;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(WasteDiverted[waste,area,year] for area in areas)
  print(iob, "WasteDiverted;Diverted;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(WasteExported[waste,area,year] for area in areas)
  print(iob, "WasteExported;Exported;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(WasteIncinerated[waste,area,year] for area in areas)
  print(iob, "WasteIncinerated;Incinerated;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(WasteDeposited[waste,area,year] for area in areas)
  print(iob, "WasteDeposited;Deposited in Landfill;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " DOC Summary (Tonnes);;    ", join(Year[year], ";"))
  ZZZ[year] = sum(DOCStock[waste,area,year] for area in areas)
  print(iob, "DOCStock;DOC in Landfill;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(DOCDeposited[waste,area,year] for area in areas)
  print(iob, "DOCDeposited;Deposited;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(DOCDecomposed[waste,area,year] for area in areas)
  print(iob, "DOCDecomposed;Decomposed;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " CH4 Summary (Tonnes/Yr);;    ", join(Year[year], ";"))
  ZZZ[year] = sum(CH4Generated[waste,area,year] for area in areas)
  print(iob, "CH4Generated;Generated;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(CH4Captured[waste,area,year] for area in areas)
  print(iob, "CH4Captured;Captured;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(CH4Flared[waste,area,year] for area in areas)
  print(iob, "CH4Flared;Flared;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(CH4FlaredLosses[waste,area,year] for area in areas)
  print(iob, "CH4FlaredLosses;Flared Losses;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(CH4Oxidized[waste,area,year] for area in areas)
  print(iob, "CH4Oxidized;Oxidized;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  ZZZ[year] = sum(CH4Emitted[waste,area,year] for area in areas)
  print(iob, "CH4Emitted;Emitted;")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " Waste Steam after Waste Diverted (Tonnes/Yr);;    ", join(Year[year], ";"))
  ZZZ[year] = sum(WasteDisposed[waste,area,year] for area in areas)
  print(iob, "WasteDisposed;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " Population (Millions);;    ", join(Year[year], ";"))
  ZZZ[year] = sum(PopT[area,year] for area in areas)
  print(iob, "PopT;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " CH4 Non Energy Reductions (Tonnes/Yr);;    ", join(Year[year], ";"))
  ZZZ[year] = sum(MEReduce[eccs,polls,area,year] for area in areas)
  print(iob, "MEReduce;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " CH4 Non-Energy Pollution (Tonnes/Yr);;    ", join(Year[year], ";"))
  ZZZ[year] = sum(MEPol[eccs,polls,area,year] for area in areas)
  print(iob, "MEPol;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " Waste Generated per Driver (WGC) (kg/person);;    ", join(Year[year], ";"))
  ZZZ[year] = sum(WastePerDriver[waste,area,year] for area in areas)
  print(iob, "WastePerDriver;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " Disposed Waste per Driver (DsWC) (kg/person);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(DisposedWastePerDriver[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "DisposedWastePerDriver;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " Proportion of Diverted Waste (PDvW) (Tonnes/Tonnes);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(ProportionDivertedWaste[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "ProportionDivertedWaste;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " Percentage of Waste Exported (Tonnes/Tonnes);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(WasteExportedFraction[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "WasteExportedFraction;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)
  
  println(iob, areaname, " Percentage of Waste Incinerated (Tonnes/Tonnes);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(WasteIncineratedFraction[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "WasteIncineratedFraction;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)
  
  println(iob, areaname, " Fraction of Degradable Organic Carbon per Waste Landfilled (Tonnes/Tonnes);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(DOCPerWaste[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "DOCPerWaste;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)
    
  println(iob, areaname, "  Fraction of Decomposable DOC (DOCf) (Tonnes/Tonnes);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(DOCDecomposeFraction[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "DOCDecomposeFraction;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)
    
  println(iob, areaname, "  CH4 Correction Factor (MCF) for Aerobic Decomposition (T/T);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(CH4CorrectionFactor[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "CH4CorrectionFactor;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)
    
  println(iob, areaname, "  CH4 Generation Constant (k);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(CH4GenerationRate[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "CH4GenerationRate;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)
      
  println(iob, areaname, "  Fraction of CH4 by Volume in Landfill Gas (F) (1/1);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = CH4Volume[waste]
  end
  print(iob, "CH4Volume;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)
    
  println(iob, areaname, "  Oxidation Factor;;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(OxidationFactor[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "OxidationFactor;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)
      
  println(iob, areaname, "  CH4 Recovery Fraction (Rt) (Tonnes/Tonnes);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(CH4RecoveryFraction[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "CH4RecoveryFraction;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)
      
  println(iob, areaname, "  CH4 Flaring Fraction (Tonnes/Tonnes);;    ", join(Year[year], ";"))
  for y in year
    ZZZ[y] = sum(CH4FlaringFraction[waste,area,y]*PopT[area,y] for area in areas)/
                 sum(PopT[area,y] for area in areas)
  end
  print(iob, "CH4FlaringFraction;", areaname,";")
  for zzz in ZZZ[year]
    print(iob, @sprintf("%12.4f;", zzz))
  end
  println(iob)
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  wastekey = Waste[waste]
  filename = "Waste-$wastekey-$areakey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function Waste_DtaControl(db)
  @info "Waste_DtaControl"
  data = WasteData(; db)
  (; Nation, Area, AreaDS, ECC, Poll, Waste) = data
  (; Nations, Areas, ECCs, Polls) = data
  
  polls = Select(Poll, "CH4")
  eccs = Select(ECC, "SolidWaste")
  wastes = Select(Waste, ["AshDry", "WoodWastePulpPaper"])
  areas = Select(Area, (from = "ON", to = "NU"))

  for area in areas
    areaname = AreaDS[area]
    areakey = Area[area]
    for waste in wastes
      Waste_DtaRun(data, area, areaname, areakey, polls, eccs, waste)
    end 
  end
  
  areaname = "Canada"
  areakey = "CN"
  for waste in wastes
    Waste_DtaRun(data, areas, areaname, areakey, polls, eccs, waste)
  end 

end
if abspath(PROGRAM_FILE) == @__FILE__
Waste_DtaControl(DB)
end
