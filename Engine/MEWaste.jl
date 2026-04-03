#
# MEWaste.jl
#

module MEWaste

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime,@finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))

  Offset::SetArray = ReadDisk(db,"MainDB/OffsetKey")
  Offsets::Vector{Int} = collect(Select(Offset))

  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))

  Waste::SetArray = ReadDisk(db,"MainDB/WasteKey")
  Wastes::Vector{Int} = collect(Select(Waste))

  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  CH4Captured::VariableArray{2} = ReadDisk(db,"MOutput/CH4Captured",year) #[Waste,Area,Year]  CH4 Captured (Tonnes/Yr)
  CH4CapturedOffsets::VariableArray{2} = ReadDisk(db,"MOutput/CH4CapturedOffsets",year) #[Waste,Area,Year]  CH4 Captured from Offsets (Tonnes/Yr)
  CH4CorrectionFactor::VariableArray{2} = ReadDisk(db,"MInput/CH4CorrectionFactor",year) #[Waste,Area,Year]  CH4 Correction Factor <MCF> for Aerobic Decomposition (Tonnes/Tonnes)
  CH4DivertedOffsets::VariableArray{2} = ReadDisk(db,"MOutput/CH4DivertedOffsets",year) #[Waste,Area,Year]  CH4 Reductions from Diverted Waste Offset (Tonnes/Yr)
  CH4Emitted::VariableArray{2} = ReadDisk(db,"MOutput/CH4Emitted",year) #[Waste,Area,Year]  CH4 Generated After Recovery <Qt>  (Tonnes/Yr)
  CH4Flared::VariableArray{2} = ReadDisk(db,"MOutput/CH4Flared",year) #[Waste,Area,Year]  CH4 Flared (Tonnes/Yr)
  CH4FlaredLosses::VariableArray{2} = ReadDisk(db,"MOutput/CH4FlaredLosses",year) #[Waste,Area,Year]  CH4 Flared (Tonnes/Yr)
  CH4FlaringFraction::VariableArray{2} = ReadDisk(db,"MInput/CH4FlaringFraction",year) #[Waste,Area,Year]  CH4 Flaring Fraction (Tonnes/Tonnes)
  CH4Generated::VariableArray{2} = ReadDisk(db,"MOutput/CH4Generated",year) #[Waste,Area,Year]  CH4 Generated From Decomposable Material <Qtx> (Tonnes/Yr)
  CH4GenerationRate::VariableArray{2} = ReadDisk(db,"MInput/CH4GenerationRate",year) #[Waste,Area,Year]  CH4 Generation Constant <k>
  CH4MolarRatio::Float32 = ReadDisk(db,"MInput/CH4MolarRatio")[1] #[tv]  Molar Ratio CH4/C  (1/1)
  CH4Oxidized::VariableArray{2} = ReadDisk(db,"MOutput/CH4Oxidized",year) #[Waste,Area,Year]  CH4 Generated From Decomposable Material <Qtx> (Tonnes/Yr)
  CH4RecoveryFraction::VariableArray{2} = ReadDisk(db,"MInput/CH4RecoveryFraction",year) #[Waste,Area,Year]  CH4 Recovery Fraction <Rt> (Tonnes/Tonnes)
  CH4Volume::VariableArray{1} = ReadDisk(db,"MInput/CH4Volume") #[Waste]  Fraction of CH4 by Volume in Landfill Gas <F> (1/1)
  DivertedBaseline::VariableArray{2} = ReadDisk(db,"MOutput/DivertedBaseline",year) #[Waste,Area,Year]  Diverted Waste from Exogenous Fraction (Tonnes/Yr)
  DivertedOffsets::VariableArray{2} = ReadDisk(db,"MOutput/DivertedOffsets",year) #[Waste,Area,Year]  Diverted Waste from Offsets (Tonnes/Yr)
  DivertedPolicyFraction::VariableArray{2} = ReadDisk(db,"MInput/DivertedPolicyFraction",year) #[Waste,Area,Year]  Fraction of Disposed Waste Policy which is Diverted (Tonne/Tonne)
  DisposedSwitch::VariableArray{2} = ReadDisk(db,"MInput/DisposedSwitch",year) #[Waste,Area,Year]  Disposed Waste Policy Switch (1=Active)
  DisposedWastePerDriver::VariableArray{2} = ReadDisk(db,"MInput/DisposedWastePerDriver",year) #[Waste,Area,Year]  Disposed Waste per Driver <DsWC> (Tonnes/person)
  DOCDecomposeFraction::VariableArray{2} = ReadDisk(db,"MInput/DOCDecomposeFraction",year) #[Waste,Area,Year]  Fraction of Decomposable DOC <DOCf> (Tonnes/Tonnes)
  DOCDecomposed::VariableArray{2} = ReadDisk(db,"MOutput/DOCDecomposed",year) #[Waste,Area,Year]  DOC Decomposed <DDOCm Decomp> (Tonnes/Yr)
  DOCDeposited::VariableArray{2} = ReadDisk(db,"MOutput/DOCDeposited",year) #[Waste,Area,Year]  DOC Deposited <DDOCm> (Tonnes/Yr)
  DOCPerWaste::VariableArray{2} = ReadDisk(db,"MInput/DOCPerWaste",year) #[Waste,Area,Year]  Fraction of Degradable Organic Carbon per Waste Landfilled (Tonnes/Tonnes)
  DOCStock::VariableArray{2} = ReadDisk(db,"MOutput/DOCStock",year) #[Waste,Area,Year]  Landfill Stock of Decomposable DOC <DDOCma> (Tonnes)
  DOCStockPrior::VariableArray{2} = ReadDisk(db,"MOutput/DOCStock",prior) #[Waste,Area,Prior]  Landfill Stock of Decomposable DOC <DDOCmat-1> (Tonnes)
  Driver::VariableArray{2} = ReadDisk(db,"MOutput/Driver",year) #[ECC,Area,Year]  Economic Driver (Various Millions/Yr)
  FlaringEfficiency::VariableArray{2} = ReadDisk(db,"MInput/FlaringEfficiency",year) #[Waste,Area,Year]  Emissions Efficiency of Flaring (Tonnes/Tonnes)
  MEDriver::VariableArray{2} = ReadDisk(db,"MOutput/MEDriver",year) #[ECC,Area,Year]  Driver for Process Emissions (Various Millions/Yr)
  MEDriverPrior::VariableArray{2} = ReadDisk(db,"MOutput/MEDriver",prior) #[ECC,Area,Prior]  Driver for Process Emissions (Various Millions/Yr)
  MEPol::VariableArray{3} = ReadDisk(db,"SOutput/MEPol",year) #[ECC,Poll,Area,Year]  Process Pollution (Tonnes/Yr)
  OxidationFactor::VariableArray{2} = ReadDisk(db,"MInput/OxidationFactor",year) #[Waste,Area,Year]  Oxidation Factor <OX> (1/1)
  PopT::VariableArray{1} = ReadDisk(db,"MOutput/PopT",year) #[Area,Year]  Population (Millions)
  ProportionDivertedWasteInput::VariableArray{2} = ReadDisk(db,"MInput/ProportionDivertedWaste",year) #[Waste,Area,Year]  Proportion of Diverted Waste <PDvW> (Tonnes/Tonnes)
  ProportionDivertedWasteOutput::VariableArray{2} = ReadDisk(db,"MOutput/ProportionDivertedWasteOutput",year) #[Waste,Area,Year]  Proportion of Diverted Waste <PDvW> (Tonnes/Tonnes)
  ReReductions::VariableArray{3} = ReadDisk(db,"MEOutput/ReReductions",year) #[Offset,Poll,Area,Year]  Reductions (Tonnes/Yr)
  WasteDeposited::VariableArray{2} = ReadDisk(db,"MOutput/WasteDeposited",year) #[Waste,Area,Year]  Waste Deposited in Landfill (Tonnes/Yr)
  WasteDisposed::VariableArray{2} = ReadDisk(db,"MOutput/WasteDisposed",year) #[Waste,Area,Year]  Waste Steam after Waste Diverted (Tonnes/Yr)
  WasteDisposedBaseline::VariableArray{2} = ReadDisk(db,"MOutput/WasteDisposedBaseline",year) #[Waste,Area,Year]  Waste Disposed from Exogenous Fraction (Tonnes/Yr)
  WasteDiverted::VariableArray{2} = ReadDisk(db,"MOutput/WasteDiverted",year) #[Waste,Area,Year]  Diverted Waste (Tonnes/Yr)
  WasteDivertedBaseline::VariableArray{2} = ReadDisk(db,"MOutput/WasteDivertedBaseline",year) #[Waste,Area,Year]  Diverted Waste from Exogenous Fraction (Tonnes/Yr)
  WasteDriver::VariableArray{2} = ReadDisk(db,"MOutput/WasteDriver",year) #[Waste,Area,Year]  Driver for Waste Generations (Various Units/Yr)
  WasteDriverMap::Vector{String} = ReadDisk(db,"MOutput/WasteDriverMap") #[Waste]  Map for Waste Generation Driver
  WasteExported::VariableArray{2} = ReadDisk(db,"MOutput/WasteExported",year) #[Waste,Area,Year]  Exported Waste (Tonnes/Yr)
  WasteExportedFraction::VariableArray{2} = ReadDisk(db,"MInput/WasteExportedFraction",year) #[Waste,Area,Year]  Fraction of Waste Exported (Tonnes/Tonnes)
  WasteGenerated::VariableArray{2} = ReadDisk(db,"MOutput/WasteGenerated",year) #[Waste,Area,Year]  Waste Generated (Tonnes/Yr)
  WasteIncinerated::VariableArray{2} = ReadDisk(db,"MOutput/WasteIncinerated",year) #[Waste,Area,Year]  Incinerated Waste (Tonnes/Yr)
  WasteIncineratedFraction::VariableArray{2} = ReadDisk(db,"MInput/WasteIncineratedFraction",year) #[Waste,Area,Year]  Fraction of Waste Incinerated (Tonnes/Tonnes)
  WasteIncineratedPrior::VariableArray{2} = ReadDisk(db,"MOutput/WasteIncinerated",prior) #[Waste,Area,Prior]  Incinerated Waste (Tonnes/Yr)
  WastePerDriverInput::VariableArray{2} = ReadDisk(db,"MInput/WastePerDriver",year) #[Waste,Area,Year]  Waste Generated per Driver <WGC> (Tonnes/Driver)
  WastePerDriverOutput::VariableArray{2} = ReadDisk(db,"MOutput/WastePerDriverOutput",year) #[Waste,Area,Year]  Waste Generated per Driver <WGC> (Tonnes/Driver)
  WasteSwitch::Float32 = ReadDisk(db,"MInput/WasteSwitch",year) #[Year]  Waste Switch (1=Use Waste Sector)
  xCH4Emitted::VariableArray{2} = ReadDisk(db,"MInput/xCH4Emitted",year) #[Waste,Area,Year]  Exogenous CH4 Generated After Recovery <Qt>  (Tonnes/Yr)
  xDOCStock::VariableArray{2} = ReadDisk(db,"MInput/xDOCStock",year) #[Waste,Area,Year]  Initial Landfill Stock of Decomposable DOC <DDOCma> (Tonnes)
  xGO::VariableArray{2} = ReadDisk(db,"MInput/xGO",year) #[ECC,Area,Year]  Gross Output (Real M$/Yr)
end

function DriverForWaste(data::Data)
  (; db,year) = data
  (; Areas,ECC,ECCs,Wastes) = data
  (; Driver,PopT,WasteDriver,WasteDriverMap) = data

  #
  # Waste default driver is Poplulation (Persons)
  #
  for area in Areas, waste in Wastes
    WasteDriver[waste,area] = PopT[area]*1e6
  end

  #
  # Wood Waste Driver is Forestry Gross Output (Million 1997 CN$/YR)
  #
  for waste in Wastes, ecc in ECCs
    if WasteDriverMap[waste] == ECC[ecc]
      for area in Areas
        WasteDriver[waste,area] = Driver[ecc,area]
      end
    end
  end

  WriteDisk(db,"MOutput/WasteDriver",year,WasteDriver)

end

function GenerateWaste(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; WasteGenerated,WasteDriver,WastePerDriverInput) = data

  for area in Areas, waste in Wastes
    WasteGenerated[waste,area] = WasteDriver[waste,area]*WastePerDriverInput[waste,area]
  end

  WriteDisk(db,"MOutput/WasteGenerated",year,WasteGenerated)

end

function DivertWasteOffsets(data::Data)
  (; db,year) = data
  (; Areas,Offset,Poll,Waste,Wastes) = data
  (; CH4DivertedOffsets,ReReductions,WasteGenerated,DivertedOffsets,DOCPerWaste,DOCDecomposeFraction,CH4CorrectionFactor,CH4Volume,CH4MolarRatio) = data

  CH4 = Select(Poll,"CH4")
  AC = Select(Offset,"AC")

  #
  # Split Offset based on relative share of waste generated
  #
  NotPulpPaperWastes = Select(Waste, !=("WoodWastePulpPaper"))
  NotSolidWoodWastes = Select(Waste, !=("WoodWasteSolidWood"))
  wastes = intersect(NotPulpPaperWastes,NotSolidWoodWastes)

  for area in Areas, waste in wastes
    @finite_math CH4DivertedOffsets[waste,area] = 
      ReReductions[AC,CH4,area]*WasteGenerated[waste,area]/
      sum(WasteGenerated[w,area] for w in wastes)
  end

  WriteDisk(db,"MOutput/WasteGenerated",year,WasteGenerated)

  for area in Areas, waste in Wastes
    @finite_math DivertedOffsets[waste,area] = CH4DivertedOffsets[waste,area]/
      (DOCPerWaste[waste,area]*DOCDecomposeFraction[waste,area]*
      CH4CorrectionFactor[waste,area]*CH4Volume[waste]*CH4MolarRatio)
  end

  WriteDisk(db,"MOutput/DivertedOffsets",year,DivertedOffsets)

end

function DivertWaste(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; DivertedBaseline,ProportionDivertedWasteInput,WasteGenerated,WasteDiverted,DivertedOffsets) = data

  for area in Areas, waste in Wastes
    DivertedBaseline[waste,area] = ProportionDivertedWasteInput[waste,area]*WasteGenerated[waste,area]
  end
  WriteDisk(db,"MOutput/DivertedBaseline",year,DivertedBaseline)

  for area in Areas, waste in Wastes
    WasteDiverted[waste,area] = max(DivertedBaseline[waste,area],DivertedOffsets[waste,area])
  end
  WriteDisk(db,"MOutput/WasteDiverted",year,WasteDiverted)

end

function DisposeWaste(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; WasteDisposed,WasteGenerated,WasteDiverted) = data

  for area in Areas, waste in Wastes
    WasteDisposed[waste,area] = WasteGenerated[waste,area]-WasteDiverted[waste,area]
  end

  WriteDisk(db,"MOutput/WasteDisposed",year,WasteDisposed)

end

function DisposeWastePolicy(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; WasteDivertedBaseline,WasteDisposedBaseline,WasteDisposed,WasteGenerated,WasteDiverted,WasteDriver,DisposedWastePerDriver,DivertedPolicyFraction,DisposedSwitch) = data

  for area in Areas, waste in Wastes
    WasteDivertedBaseline[waste,area] = WasteDiverted[waste,area]
  end

  WriteDisk(db,"MOutput/WasteDivertedBaseline",year,WasteDivertedBaseline)

  for area in Areas, waste in Wastes
    WasteDisposedBaseline[waste,area] = WasteDisposed[waste,area]
  end

  WriteDisk(db,"MOutput/WasteDisposedBaseline",year,WasteDisposedBaseline)

  for area in Areas, waste in Wastes
    if DisposedSwitch[waste,area] == 1
      WasteDisposed[waste,area] = WasteDriver[waste,area]*DisposedWastePerDriver[waste,area]

      WasteDiverted[waste,area] = max(WasteDivertedBaseline[waste,area]+
                        (WasteDisposed[waste,area]-WasteDisposedBaseline[waste,area])*DivertedPolicyFraction[waste,area],0)

      WasteGenerated[waste,area] = WasteDisposed[waste,area]+WasteDiverted[waste,area]
    end
  end

  WriteDisk(db,"MOutput/WasteDisposed",year,WasteDisposed)
  WriteDisk(db,"MOutput/WasteDiverted",year,WasteDiverted)
  WriteDisk(db,"MOutput/WasteGenerated",year,WasteGenerated)
end

function OutputRatios(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; WastePerDriverOutput,WasteGenerated,WasteDriver,ProportionDivertedWasteOutput,WasteDiverted) = data

  for area in Areas, waste in Wastes
    @finite_math WastePerDriverOutput[waste,area] = WasteGenerated[waste,area]/WasteDriver[waste,area]
  end
  WriteDisk(db,"MOutput/WastePerDriverOutput",year,WastePerDriverOutput)

  for area in Areas, waste in Wastes
    @finite_math ProportionDivertedWasteOutput[waste,area] = WasteDiverted[waste,area]/WasteGenerated[waste,area]
  end
  WriteDisk(db,"MOutput/ProportionDivertedWasteOutput",year,ProportionDivertedWasteOutput)
end

function ExportWaste(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; WasteExported,WasteDisposed,WasteExportedFraction) = data

  for area in Areas, waste in Wastes
    WasteExported[waste,area] = WasteDisposed[waste,area]*WasteExportedFraction[waste,area]
  end

  WriteDisk(db,"MOutput/WasteExported",year,WasteExported)

end

function IncinerateWaste(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; WasteIncinerated,WasteDisposed,WasteIncineratedFraction) = data

  for area in Areas, waste in Wastes
    WasteIncinerated[waste,area] = WasteDisposed[waste,area]*WasteIncineratedFraction[waste,area]
  end
  WriteDisk(db,"MOutput/WasteIncinerated",year,WasteIncinerated)
end

function DepositWaste(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; WasteDeposited,WasteGenerated,WasteDiverted,WasteExported,WasteIncinerated) = data

  for area in Areas, waste in Wastes
    WasteDeposited[waste,area] = WasteGenerated[waste,area]-WasteDiverted[waste,area]-WasteExported[waste,area]-WasteIncinerated[waste,area]
  end
  WriteDisk(db,"MOutput/WasteDeposited",year,WasteDeposited)
end

function DepositDOC(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; WasteDeposited,DOCDeposited,DOCPerWaste,DOCDecomposeFraction,CH4CorrectionFactor) = data

  for area in Areas, waste in Wastes
    DOCDeposited[waste,area] = WasteDeposited[waste,area]*DOCPerWaste[waste,area]*DOCDecomposeFraction[waste,area]*CH4CorrectionFactor[waste,area]
  end

  WriteDisk(db,"MOutput/DOCDeposited",year,DOCDeposited)
end

function DecomposeDOC(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; DOCDecomposed,DOCStockPrior,CH4GenerationRate) = data

  for area in Areas, waste in Wastes
    @finite_math DOCDecomposed[waste,area] = DOCStockPrior[waste,area]*(1-exp(-CH4GenerationRate[waste,area]))
  end

  WriteDisk(db,"MOutput/DOCDecomposed",year,DOCDecomposed)
end

function UpdateDOCStock(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; DOCStock,DOCDecomposed,DOCStockPrior,DOCDeposited,xDOCStock) = data

  for area in Areas, waste in Wastes
    if xDOCStock[waste,area] == -99
      DOCStock[waste,area] = DOCStockPrior[waste,area]+DOCDeposited[waste,area]-DOCDecomposed[waste,area]
    else
      DOCStock[waste,area] = xDOCStock[waste,area]
    end
  end

  WriteDisk(db,"MOutput/DOCStock",year,DOCStock)
end

function GenerateCH4(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; CH4Generated,DOCDecomposed,CH4Volume,CH4MolarRatio) = data

  for area in Areas, waste in Wastes
    CH4Generated[waste,area] = DOCDecomposed[waste,area]*CH4Volume[waste]*CH4MolarRatio
  end

  WriteDisk(db,"MOutput/CH4Generated",year,CH4Generated)
end

function CaptureCH4(data::Data)
  (; db,year) = data
  (; Areas,Offset,Poll,Waste,Wastes) = data
  (; CH4Generated,WasteGenerated,CH4CapturedOffsets,ReReductions,CH4Captured,CH4RecoveryFraction) = data

  CH4 = Select(Poll,"CH4")
  LFG = Select(Offset,"LFG")

  #
  # Split Offset based on relative share of waste generated
  #
  NotPulpPaperWastes = Select(Waste, !=("WoodWastePulpPaper"))
  NotSolidWoodWastes = Select(Waste, !=("WoodWasteSolidWood"))
  wastes = intersect(NotPulpPaperWastes,NotSolidWoodWastes)

  for area in Areas, waste in wastes
    @finite_math CH4CapturedOffsets[waste,area] = 
      ReReductions[LFG,CH4,area]*WasteGenerated[waste,area]/
      sum(WasteGenerated[w,area] for w in wastes)
  end

  WriteDisk(db,"MOutput/CH4CapturedOffsets",year,CH4CapturedOffsets)

  #
  # AMD has removed CH4 Captured by Landfill Gas Offsets from captured CH4
  # and thus increased Solid Waste emissions (MEPol).  Presumably the CH4
  # offsets from Landfill Gas should be removed? - Jeff Amlin 7/26/19
  #

  for area in Areas, waste in Wastes
    CH4Captured[waste,area] = CH4Generated[waste,area]*CH4RecoveryFraction[waste,area]
  end

  WriteDisk(db,"MOutput/CH4Captured",year,CH4Captured)
end

function OxidizeCH4(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; CH4Oxidized,CH4Generated,CH4Captured,OxidationFactor) = data

  for area in Areas, waste in Wastes
    CH4Oxidized[waste,area] = (CH4Generated[waste,area]-CH4Captured[waste,area])*OxidationFactor[waste,area]
  end

  WriteDisk(db,"MOutput/CH4Oxidized",year,CH4Oxidized)

end

function FlareCH4(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; CH4Flared,CH4Captured,CH4FlaringFraction) = data

  for area in Areas, waste in Wastes
      CH4Flared[waste,area] = CH4Captured[waste,area]*CH4FlaringFraction[waste,area]
  end

  WriteDisk(db,"MOutput/CH4Flared",year,CH4Flared)
end

function FlaredLossesCH4(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; CH4FlaredLosses,CH4Flared,FlaringEfficiency) = data

  for area in Areas, waste in Wastes
    CH4FlaredLosses[waste,area] = CH4Flared[waste,area]*(1-FlaringEfficiency[waste,area])
  end

  WriteDisk(db,"MOutput/CH4FlaredLosses",year,CH4FlaredLosses)
end

function EmitCH4(data::Data)
  (; db,year) = data
  (; Areas,Wastes) = data
  (; CH4Emitted,CH4Generated,CH4Captured,CH4Oxidized,CH4FlaredLosses) = data

  for area in Areas, waste in Wastes
    CH4Emitted[waste,area] = CH4Generated[waste,area]-CH4Captured[waste,area]-CH4Oxidized[waste,area]+CH4FlaredLosses[waste,area]
  end

  WriteDisk(db,"MOutput/CH4Emitted",year,CH4Emitted)
end

function SolidWasteEmissions(data::Data)
  (; db,year) = data
  (; Areas,ECC,Poll,Wastes) = data
  (; CH4Emitted,MEPol,WasteSwitch) = data

  if WasteSwitch == 1
    for area in Areas, poll in Select(Poll,"CH4"), ecc in Select(ECC,"SolidWaste")
      MEPol[ecc,poll,area] = sum(CH4Emitted[waste,area] for waste in Wastes)
    end

    WriteDisk(db,"SOutput/MEPol",year,MEPol)

  end
end

function IncinerationEmissions(data::Data)
  
  #
  # Define Procedure IncinerationEmissions
  # 
  #  AMD has removed Incinerated Wastes from Incineration emissions (MEPol)
  #  This should be checked to see if we are losing the emissions from
  #  incineration (these should be CO2 emissions) - Jeff Amlin 7/26/19
  # 
  #  Incineration emissions are based on the last historical year for now.
  #  Use growth in incinerated waste to change coefficient in forecast while
  #  controlling for MEDriver changes.
  # 
  #  Check if logic below actually makes sense
  # 
  # Do If WasteSwitch eq 1
  #   Select ECC(Incineration), Poll(CH4)
  #   MEPol(ECC,Poll,Area)=sum(Waste)(WasteIncinerated(Waste,Area))
  #   Select ECC*, Poll*
  #   Write Disk(MEPol)
  # End Do If
  # 
  # End Procedure IncinerationEmissions
end

function Control(data::Data)
  (; CTime) = data

  # @info "  MEWaste.jl - Control"
  
  #
  #  Fred requested that this only run in forecast years. Start in last historical
  #  year for now to generate a value for DOCStockPrior
  #
  if CTime >= 2017
    DriverForWaste(data)
    GenerateWaste(data)
    DivertWasteOffsets(data)
    DivertWaste(data)
    DisposeWaste(data)
    DisposeWastePolicy(data)
    OutputRatios(data)
    ExportWaste(data)
    IncinerateWaste(data)
    DepositWaste(data)
    DepositDOC(data)
    DecomposeDOC(data)
    UpdateDOCStock(data)
    GenerateCH4(data)
    CaptureCH4(data)
    OxidizeCH4(data)
    FlareCH4(data)
    FlaredLossesCH4(data)
    EmitCH4(data)
    SolidWasteEmissions(data)
  
  #
  #  IncinerationEmissions(data)
  #
  end

end # function Control

end # module MEWaste
