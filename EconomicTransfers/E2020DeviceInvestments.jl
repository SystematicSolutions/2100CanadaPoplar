#
# E2020DeviceInvestments.jl - Change in device investments due to policy
#
using EnergyModel

module E2020DeviceInvestments

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case)
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Run1NameDB::String = ReadDisk(db,"MainDB/Run1NameDB") # Economic Model Investments Case Name
  Run1Name::String = ReadDisk(db,"MainDB/Run1Name") # Economic Model Investments Case Name
  SceName::String = ReadDisk(DB,"SInput/SceName") #  Scenario Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation

  CDe::VariableArray{2} = ReadDisk(db,"KOutput/CDe") # [AreaTOM,Year] E2020 Household Appliance Investments (2017 $M/Yr)
  CD_NRG::VariableArray{2} = ReadDisk(db,"KOutput/CD_NRG") # [AreaTOM,Year] E2020 Household Consumption, Energy Durables, Policy Driven (2017 $M/Yr)
  # TODORandy - the CgInv do not appear to be read from disk from their individual scenarios in Promula. LJD 25/03/03
  # CgInvRun1::VariableArray{3} = ReadDisk(Run1NameDB,"SOutput/CgInv") # [ECC,Area,Year] Cogeneration Investments (M$/Yr)
  # CgInvRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/CgInv") # [ECC,Area,Year] Cogeneration Investments (M$/Yr)
  CgInvRun1::VariableArray{3} = ReadDisk(db,"SOutput/CgInv") # [ECC,Area,Year] Cogeneration Investments (M$/Yr)
  CgInvRef::VariableArray{3} = ReadDisk(db,"SOutput/CgInv") # [ECC,Area,Year] Cogeneration Investments (M$/Yr)
  DInv::VariableArray{3} = ReadDisk(db,"SOutput/DInv") # [ECC,Area,Year] Device Investments (M$/Yr)
  DeviceInvestmentsRun1::VariableArray{3} = ReadDisk(Run1NameDB,"SOutput/DInv") # [ECC,Area,Year] Device Investments (M$/Yr)
  DeviceInvestmentsRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/DInv") # [ECC,Area,Year] Device Investments (M$/Yr)
  IFMEe::VariableArray{3} = ReadDisk(db,"KOutput/IFMEe") # [ECCTOM,AreaTOM,Year] E2020 Investments in Machinery & Equipment (2017 $M/Yr)
  IF_NRG::VariableArray{3} = ReadDisk(db,"KOutput/IF_NRG") # [ECCTOM,AreaTOM,Year] Policy Driver Energy Investments in Machinery & Equipment (2017 $M/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  SplitECCtoTOMIFME::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFME") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM based on M&E Investments, IFME ($/$)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index in Reference Case ($/$)
  xInflationRef::VariableArray{2} = ReadDisk(RefNameDB,"MInput/xInflation") # [Area,Year] Inflation Index in Reference Case ($/$)

  #
  # Scratch Variables
  #
  DInvRefReal::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Device Investments (2017 M$/Yr)
  DInvRun1Real::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Device Investments (2017 M$/Yr)
  IFMEeRef::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] E2020 Investments in Machinery & Equipment (2017 $M/Yr)
end

function ReadDatabases(data)
  (; BaseSw,RefSwitch,Run1Name,SceName) = data
  (; DInv,DeviceInvestmentsRun1,DeviceInvestmentsRef) = data
  (; TOMBaseYear,xInflation,xInflationRef) = data

  # TODORandy - add CgInv ?? LJD 25/03/03

  if (BaseSw == 0) && (RefSwitch == 0)
    # xInflationRef from Reference Case
    # DeviceInvestmentsRef from Reference Case
    if Run1Name != SceName[1]
      # DeviceInvestmentsRun1 from Run1
    else
      # DeviceInvestmentsRun1 from default database
      @. DeviceInvestmentsRun1 = DInv
    end
  elseif ((BaseSw != 0) || (RefSwitch != 0)) && (Run1Name != "Ref25A_TOM_1")
    # variables from default database
    @. xInflationRef = xInflation
    @. DeviceInvestmentsRef = DInv
    @. DeviceInvestmentsRun1 = DInv
  end

end

function Initialize(data)
  (; CDe,CD_NRG,IFMEe,IF_NRG) = data

  @. CDe = 0
  @. CD_NRG = 0
  @. IFMEe = 0
  @. IF_NRG = 0

end

function DInv(data,areas)
  (; db) = data
  (; Area,AreaTOM,AreaTOMs,ECC,ECCs,ECCTOM,ECCTOMs,Years) = data
  (; CgInvRun1,CgInvRef,DeviceInvestmentsRun1,DeviceInvestmentsRef) = data
  (; DInvRefReal,DInvRun1Real) = data
  (; IFMEe,IFMEeRef,IF_NRG) = data
  (; SplitECCtoTOMIFME,TOMBaseYear,xInflationRef) = data

  #
  # IF_NRG is the change in energy Device Investments due to policy
  # changes (DeviceInvestmentsRun1-DeviceInvestmentsRef).
  # Include investments in cogeneration as well (CgInv).
  #
  eccs = Select(ECC,(from="Wholesale",to="AnimalProduction"))

  for area in areas
    areatom = Select(AreaTOM,Area[area])
    for year in Years, ecc in eccs
      DInvRun1Real[ecc,area,year] = (DeviceInvestmentsRun1[ecc,area,year]+CgInvRun1[ecc,area,year])/
          xInflationRef[area,year]*xInflationRef[area,TOMBaseYear]
      DInvRefReal[ecc,area,year] = (DeviceInvestmentsRef[ecc,area,year]+CgInvRef[ecc,area,year])/
          xInflationRef[area,year]*xInflationRef[area,TOMBaseYear]
    end

    for ecc in eccs
      for year in Years, ecctom in ECCTOMs
          IFMEe[ecctom,areatom,year] = IFMEe[ecctom,areatom,year]+
            DInvRun1Real[ecc,area,year]*SplitECCtoTOMIFME[ecc,ecctom,areatom,year]

          IFMEeRef[ecctom,areatom,year] = IFMEeRef[ecctom,areatom,year]+
            DInvRefReal[ecc,area,year]*SplitECCtoTOMIFME[ecc,ecctom,areatom,year]
      end
    end
  end

  #
  # Change in energy investments is sent to TOM only in forecast years
  #
  years = collect(Future+2:Yr(2050))  
  for year in years, areatom in AreaTOMs, ecctom in ECCTOMs
    IF_NRG[ecctom,areatom,year] = IFMEe[ecctom,areatom,year]-IFMEeRef[ecctom,areatom,year]
  end

  WriteDisk(db,"KOutput/IFMEe",IFMEe)
  WriteDisk(db,"KOutput/IF_NRG",IF_NRG)

end

function HouseholdInvestments(data,areas)
  (; db) = data
  (; Area,AreaTOM,AreaTOMs,ECC,Years) = data
  (; CDe,CD_NRG,CgInvRun1,CgInvRef,DeviceInvestmentsRun1,DeviceInvestmentsRef) = data
  (; TOMBaseYear,xInflationRef) = data

  #
  # CD_NRG is the change in energy Device Investments due to policy changes
  # (DeviceInvestmentsRun1-DeviceInvestmentsRef) from all residential sectors.
  #
  # Household investments include residential Solar PV or other Cogen (CgInv).
  #
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential"])

  for area in areas
    areatom=Select(AreaTOM,Area[area])
    for year in Years
      CDe[areatom,year]=sum((DeviceInvestmentsRun1[ecc,area,year]+CgInvRun1[ecc,area,year])/
          xInflationRef[area,year]*xInflationRef[area,TOMBaseYear] for ecc in eccs)
    end
  end

  #
  # Change in investments is sent to TOM only in forecast years
  #
  years = collect(Future+2:Yr(2050))
  for year in years, areatom in AreaTOMs
    area = Select(Area,AreaTOM[areatom])
    CD_NRG[areatom,year]=sum((DeviceInvestmentsRun1[ecc,area,year]+CgInvRun1[ecc,area,year]-
      DeviceInvestmentsRef[ecc,area,year]-CgInvRef[ecc,area,year])/
      xInflationRef[area,year]*xInflationRef[area,TOMBaseYear] for ecc in eccs)
  end

  WriteDisk(db,"KOutput/CDe",CDe)
  WriteDisk(db,"KOutput/CD_NRG",CD_NRG)

end

function MapInvestments(db)
  data = MControl(; db)
  (;Nation) = data
  (;ANMap) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas_cn = findall(ANMap[:,CN] .== 1)
  areas_us = findall(ANMap[:,US] .== 1)
  areas = union(areas_cn,areas_us)

  Initialize(data)
  ReadDatabases(data)

  DInv(data,areas)
  HouseholdInvestments(data,areas)
end

function Control(db)
  @info "E2020DeviceInvestments.jl - Control"
  MapInvestments(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
