#
# E2020DeviceInvestmentsTr.jl
#
using EnergyModel

module E2020DeviceInvestmentsTr

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Run1NameDB::String = ReadDisk(db,"MainDB/Run1NameDB") # Economic Model Investments Case Name
  Run1Name::String = ReadDisk(db,"MainDB/Run1Name") # Economic Model Investments Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fleet::SetArray = ReadDisk(db,"KInput/FleetKey")
  FleetDS::SetArray = ReadDisk(db,"KInput/FleetDS")
  Fleets::Vector{Int} = collect(Select(Fleet))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1 = Base Case)
  CDe::VariableArray{2} = ReadDisk(db,"KOutput/CDe") # [AreaTOM,Year] E2020 Household Appliance Investments (2017 $M/Yr)
  CD_Tra::VariableArray{2} = ReadDisk(db,"KOutput/CD_Tra") # [AreaTOM,Year] E2020 Household Consumption, Transportation Durables, Policy Driven (2017 $M/Yr)
  CDe_Ref::VariableArray{2} = ReadDisk(RefNameDB,"KOutput/CDe") # [AreaTOM,Year] E2020 Household Appliance Investments (2017 $M/Yr)
  CD::VariableArray{2} = ReadDisk(db,"KOutput/CD") # [AreaTOM,Year] TOM Household Appliance Investments (2017 $M/Yr)
  CD_BAU::VariableArray{2} = ReadDisk(RefNameDB,"KOutput/CD") # [AreaTOM,Year] TOM Reference Case Household Appliance Investments (2017 $M/Yr)
  DInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments in Reference Case (M$/Yr)
  DInvTechRun1::VariableArray{5} = ReadDisk(Run1NameDB,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr)
  DInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments in Reference Case (M$/Yr)
  FleetInvestments::VariableArray{3} = ReadDisk(db,"KOutput/FleetInvestments") # [Fleet,AreaTOM,Year] ENERGY 2020 Fleet Investments (2017 CN$M/Yr)
  FleetInvestmentsChange::VariableArray{3} = ReadDisk(db,"KOutput/FleetInvestmentsChange") # [Fleet,AreaTOM,Year] ENERGY 2020 Change in Fleet Investments (2017 CN$M/Yr)
  FleetInvestmentsRef::VariableArray{3} = ReadDisk(db,"KOutput/FleetInvestmentsRef") # [Fleet,AreaTOM,Year] ENERGY 2020 Reference Case Fleet Investments (2017 CN$M/Yr)
  GYinto::VariableArray{3} = ReadDisk(db,"KOutput/GYinto") # [ECCTOM,AreaTOM,Year] Gross Output for TOM Inputs (2017 $M/Yr)
  GY::VariableArray{3} = ReadDisk(db,"KOutput/GY") # [ECCTOM,AreaTOM,Year] Gross Output from TOM (2017 CN$M/Yr)
  HouseholdLDVFraction::VariableArray{2} = ReadDisk(db,"KInput/HouseholdLDVFraction") # [Area,Year] Fraction of LDV/LDT Investments from Households (vs Fleet) (Btu/Btu)
  IFMEe::VariableArray{3} = ReadDisk(db,"KOutput/IFMEe") # [ECCTOM,AreaTOM,Year] E2020 Investments in Machinery & Equipment (2017 $M/Yr)
  IFMEe_Ref::VariableArray{3} = ReadDisk(RefNameDB,"KOutput/IFMEe") # [ECCTOM,AreaTOM,Year] E2020 Investments in Machinery & Equipment (2017 $M/Yr)
  IFME::VariableArray{3} = ReadDisk(db,"KOutput/IFME") # [ECCTOM,AreaTOM,Year] TOM Investments in Machinery & Equipment (2017 $M/Yr)
  IFME_BAU::VariableArray{3} = ReadDisk(RefNameDB,"KOutput/IFME") # [ECCTOM,AreaTOM,Year] TOM Investments in Machinery & Equipment (2017 $M/Yr)
  IF_Tra::VariableArray{3} = ReadDisk(db,"KOutput/IF_Tra") # [ECCTOM,AreaTOM,Year] Policy Driver Transportation Investments in Machinery & Equipment from Policy (2017 $M/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapTechToFleet::VariableArray{2} = ReadDisk(db, "KInput/MapTechToFleet") # [Tech,Fleet] Map from Transportation Techs to Fleet
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1 = Reference Case) 
  ResTranspInvest::VariableArray{2} = ReadDisk(db,"KOutput/ResTranspInvest") # [AreaTOM,Year] Residential Transportation Investments (2017 $M/Yr)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  VehicleSalesRatio::VariableArray{4} = ReadDisk(db,"KInput/VehicleSalesRatio") # [Fleet,ECCTOM,AreaTOM,Year] Transportation Investments as Fraction of Gross Output (Btu/Btu)
  VehicleSalesImplied::VariableArray{4} = ReadDisk(db,"KOutput/VehicleSalesImplied") # [Fleet,ECCTOM,AreaTOM,Year] Vehicle Sales by Industry Implied by Historical Fraction of Gross Output ($/$)
  VehicleSalesImpliedFrac::VariableArray{4} = ReadDisk(db,"KOutput/VehicleSalesImpliedFrac") # [Fleet,ECCTOM,AreaTOM,Year] Vehicle Sales by Industry Implied by Historical Fraction of Gross Output (Excluding Electric Utility Industry) ($/$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index in Reference Case ($/$)
  xInflationRef::VariableArray{2} = ReadDisk(RefNameDB,"MInput/xInflation") # [Area,Year] Inflation Index in Reference Case ($/$)

  # Scratch Variables
  DInvHousehold::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Household Device Investments (M$/Yr)
  DInvHouseholdRef::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Household Device Investments in Reference Case (M$/Yr)
  DInvNonHousehold::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Non-Household Device Investments (M$/Yr)
  DInvNonHouseholdRef::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Non-Household Device Investments in Reference Case (M$/Yr)
  GYFleet::VariableArray{3} = zeros(Float32,length(Fleet),length(AreaTOM),length(Year)) # [Fleet,AreaTOM,Year] Gross Output of Transportation Industry by Mapped to Vehicle Types (2017 CN$M/Yr)
  ResTranspInvest_Change::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Change in Residential Transportation Investments ()
  ScaledChange::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] Scaled to TOM Vehicle Sales by Industry (2017 $M/Yr)
  TransportIndustry::VariableArray{3} = zeros(Float32,length(Fleet),length(AreaTOM),length(Year)) # [Fleet,AreaTOM,Year] Temporary variable to hold transportation industry scaled investments (2017 $M/Yr)
  VehicleSalesImpliedTotal::VariableArray{3} = zeros(Float32,length(Fleet),length(AreaTOM),length(Year)) # [Fleet,AreaTOM,Year] Total Vehicle Sales Across Industry (2017 $M/Yr)
  VehicleSalesChange::VariableArray{4} = zeros(Float32,length(Fleet),length(ECCTOM),length(AreaTOM),length(Year)) # [Fleet,ECCTOM,AreaTOM,Year] Vehicle Sales by Vehicle Type and Industry (2017 $M/Yr)
end

function ReadDatabases(data)
  (;BaseSw,RefSwitch,Run1Name,SceName) = data
  (;CDe,CDe_Ref,CD,CD_BAU,DInvTech,DInvTechRun1,DInvTechRef) = data
  (;IFMEe,IFMEe_Ref,IFME,IFME_BAU) = data
  (;xInflation,xInflationRef) = data

  if (BaseSw ==  0) && (RefSwitch ==  0)
    # xInflationRef from Reference Case
    # DInvTechRef from Reference Case
    if Run1Name !=  SceName[1]
      # DInvTechRun1 from Run1
    else
      # DInvTechRun1 from default database
      @. DInvTechRun1 = DInvTech
    end
    #
    # Read TOM Reference (BAU) values
    #
    # IFME_BAU from Reference Case
    # CD_BAU from Reference Case
    # CDe_Ref from Reference Case
    # IFMEe_Ref from Reference Case
  elseif ((BaseSw != 0) || (RefSwitch != 0)) && (Run1Name != "Ref25A_TOM_1")
    # variables from default database
    @. xInflationRef = xInflation
    @. DInvTechRef = DInvTech
    @. DInvTechRun1 = DInvTech
    @. IFME_BAU = IFME
    @. CD_BAU = CD
    @. CDe_Ref  = CDe
    @. IFMEe_Ref = IFMEe
  end

end

function InitializeVariables(data)
  (; FleetInvestments) = data
  (; IFMEe,ResTranspInvest) = data
  (; VehicleSalesImplied) = data
  (; VehicleSalesImpliedFrac) = data
  (; DInvHousehold,DInvHouseholdRef) = data

  @. DInvHousehold = 0
  @. DInvHouseholdRef = 0
  @. FleetInvestments = 0
  @. ResTranspInvest = 0
  @. VehicleSalesImplied = 0
  @. VehicleSalesImpliedFrac = 0

end

function MapGrossOutputToVehicles(data,areas)
  (; AreaTOMs,ECCTOM,Fleet,Fleets,Years) = data
  (; GY,GYFleet) = data

  for year in Years, areatom in AreaTOMs, fleet in Fleets
    GYFleet[fleet,areatom,year] = 1
  end

  #
  # Need gross output by Vehicle Type for equations below
  #
  # Split Transit gross output. 
  # Assume ratio of Bus, LDT, LDV. Update if Oxford has data.
  # 22.03.18 R.Levesque
  #
  Transit = Select(ECCTOM,"Transit")
  Bus = Select(Fleet,"Bus")
  LDT = Select(Fleet,"LDT")
  LDV = Select(Fleet,"LDV")
  for year in Years, areatom in AreaTOMs
    GYFleet[Bus,areatom,year] = GY[Transit,areatom,year]*0.90
    GYFleet[LDT,areatom,year] = GY[Transit,areatom,year]*0.05
    GYFleet[LDV,areatom,year] = GY[Transit,areatom,year]*0.05
  end

  # TODO: GYFleet set equal to 1 for fleet modes below. Should it be set equal to GY instead?
  # 10/6/25 R.Levesque
  fleet = Select(Fleet,"HDV")
  ecctom = Select(ECCTOM,"Truck")
  for year in Years, areatom in AreaTOMs
    GYFleet[fleet,areatom,year] = 1
  end

  fleet = Select(Fleet,"Plane")
  ecctom = Select(ECCTOM,"Air")
  for year in Years, areatom in AreaTOMs
    GYFleet[fleet,areatom,year] = 1
  end

  fleet = Select(Fleet,"Rail")
  ecctom = Select(ECCTOM,"Rail")
  for year in Years, areatom in AreaTOMs
    GYFleet[fleet,areatom,year] = 1
  end

  fleet = Select(Fleet,"Marine")
  ecctom = Select(ECCTOM,"Water")
  for year in Years, areatom in AreaTOMs
    GYFleet[fleet,areatom,year] = 1
  end

end

function AssignDInvHousehold(data,areas)
  (; EC,Enduses,Tech,Years) = data
  (; DInvTechRun1,DInvTechRef,HouseholdLDVFraction) = data
  (; DInvHousehold,DInvHouseholdRef) = data

  #
  # Divide Transportation DInvTech into residential and non-residential investments
  # using HouseholdLDVFraction 
  #
  ec = Select(EC,"Passenger")
  techs = Select(Tech,(from = "LDVGasoline",to = "LDTFuelCell"))
  for year in Years, area in areas, tech in techs, enduse in Enduses
    DInvHousehold[enduse,tech,ec,area,year] = DInvTechRun1[enduse,tech,ec,area,year]*
      HouseholdLDVFraction[area,year]
    DInvHouseholdRef[enduse,tech,ec,area,year] = DInvTechRef[enduse,tech,ec,area,year]*
      HouseholdLDVFraction[area,year]
  end

  tech = Select(Tech,"Motorcycle")
  for year in Years, area in areas, enduse in Enduses
    DInvHousehold[enduse,tech,ec,area,year] = DInvTechRun1[enduse,tech,ec,area,year]*
      HouseholdLDVFraction[area,year]
    DInvHouseholdRef[enduse,tech,ec,area,year] = DInvTechRef[enduse,tech,ec,area,year]*
      HouseholdLDVFraction[area,year]
  end

end

function AssignDInvNonHousehold(data,areas)
  (; EC,Enduses,Tech,Years) = data
  (; DInvTechRun1,DInvTechRef) = data
  (; DInvHousehold,DInvHouseholdRef,DInvNonHousehold,DInvNonHouseholdRef) = data

  #
  # Exclude foreign and off road
  #
  ecs = Select(EC,(from = "Passenger",to = "AirFreight"))
  techs = Select(Tech,(from = "LDVGasoline",to = "MarineFuelCell"))
  for year in Years, area in areas, ec in ecs, tech in techs, enduse in Enduses
    DInvNonHousehold[enduse,tech,ec,area,year] = DInvTechRun1[enduse,tech,ec,area,year]-
      DInvHousehold[enduse,tech,ec,area,year]
    DInvNonHouseholdRef[enduse,tech,ec,area,year] = DInvTechRef[enduse,tech,ec,area,year]-
      DInvHouseholdRef[enduse,tech,ec,area,year]
  end

end

function WriteHouseholdInvestmentsToTOM(data,areas)
  (; db) = data
  (; AreaTOMs,ECs,Enduses,Techs,Years) = data
  (; CDe,CD_Tra,MapAreaTOM,xInflationRef) = data
  (; DInvHousehold,DInvHouseholdRef,ResTranspInvest,ResTranspInvest_Change) = data
  (; TOMBaseTime,TOMBaseYear) = data

  #
  # Household vehicle investments are a fraction of DInv for LDV and LDT plus Motorcyles
  # CD_Tra is the change in household vehicle investments due to policy
  #
  for year in Years, areatom in AreaTOMs
    @finite_math ResTranspInvest[areatom,year] = sum(DInvHousehold[enduse,tech,ec,area,year]/
        xInflationRef[area,year]*xInflationRef[area,TOMBaseYear]*
          MapAreaTOM[area,areatom] for area in areas, ec in ECs, tech in Techs, enduse in Enduses)
          
    @finite_math ResTranspInvest_Change[areatom,year] = 
      sum((DInvHousehold[enduse,tech,ec,area,year]-DInvHouseholdRef[enduse,tech,ec,area,year])/
        xInflationRef[area,year]*xInflationRef[area,TOMBaseYear]*
          MapAreaTOM[area,areatom] for area in areas, ec in ECs, tech in Techs, enduse in Enduses)

    CD_Tra[areatom,year] = ResTranspInvest_Change[areatom,year]

    #
    # Update total investments variable to include transportation portion
    #
    CDe[areatom,year] = CDe[areatom,year] + ResTranspInvest[areatom,year]
  end

  #
  # Change in investments is sent to TOM only in forecast years
  #
  years = collect(Future+2:Yr(2050))
  for year in years, areatom in AreaTOMs
    CD_Tra[areatom,year] = ResTranspInvest_Change[areatom,year]

    #
    # Update total investments variable to include transportation portion
    #
    CDe[areatom,year] = CDe[areatom,year] + ResTranspInvest[areatom,year]
  end

  WriteDisk(db,"KOutput/ResTranspInvest",ResTranspInvest)
  WriteDisk(db,"KOutput/CDe",CDe)
  WriteDisk(db,"KOutput/CD_Tra",CD_Tra)

  #
  # To Do:  May need to scale total residential investments to TOM's BAU case
  # CD_Tra = (CD_Tra/CDe_Ref)*CD_BAU
  #

end

function MapNonHouseholdToFleet(data,areas)
  (; db) = data
  (; AreaTOMs,EC,ECs,Enduses,Fleets,Techs,Years) = data
  (; DInvNonHousehold,DInvNonHouseholdRef) = data
  (; FleetInvestments,FleetInvestmentsChange,FleetInvestmentsRef) = data
  (; MapAreaTOM,MapTechToFleet,TOMBaseYear,xInflationRef) = data

  ecs = Select(EC,(from="Passenger",to="AirFreight"))
  
  for year in Years, areatom in AreaTOMs, fleet in Fleets
    @finite_math FleetInvestmentsRef[fleet,areatom,year] = 
      sum(DInvNonHouseholdRef[enduse,tech,ec,area,year]*MapTechToFleet[tech,fleet]/
        xInflationRef[area,year]*xInflationRef[area,TOMBaseYear]*
        MapAreaTOM[area,areatom] for area in areas, ec in ecs, tech in Techs, enduse in Enduses)

    @finite_math FleetInvestments[fleet,areatom,year] = 
      sum(DInvNonHousehold[enduse,tech,ec,area,year]*MapTechToFleet[tech,fleet]/
        xInflationRef[area,year]*xInflationRef[area,TOMBaseYear]*
        MapAreaTOM[area,areatom] for area in areas, ec in ecs, tech in Techs, enduse in Enduses)

    FleetInvestmentsChange[fleet,areatom,year] = 
      FleetInvestments[fleet,areatom,year]-FleetInvestmentsRef[fleet,areatom,year]
  end

  # 
  # TODO: We are missing motorcycle and offroad techs in MapTechToFleet.csv. 
  #       Are we intentionally excluding offroad? 
  #       Probably update map to assign motorcyle to LDV.  8/6/25 R.Levesque

  WriteDisk(db,"KOutput/FleetInvestments",FleetInvestments)
  WriteDisk(db,"KOutput/FleetInvestmentsRef",FleetInvestmentsRef)
  WriteDisk(db,"KOutput/FleetInvestmentsChange",FleetInvestmentsChange)

end

function AllocateFleetToIndustry(data,areas)
  (;db) = data
  (; Area,AreaTOM,AreaTOMs) = data
  (; ECCTOM,ECCTOMs,Fleet,Fleets,ToTOMVariable,Years) = data
  (; FleetInvestments,FleetInvestmentsChange) = data
  (; GYFleet,GYinto,IFMEe,IFMEe_Ref,IFME_BAU) = data
  (; IF_Tra,IsActiveToECCTOM,ScaledChange) = data
  (; VehicleSalesImplied,VehicleSalesImpliedFrac) = data
  (; VehicleSalesImpliedTotal,VehicleSalesChange) = data
  (; VehicleSalesRatio) = data
  (; xInflationRef) = data

  totomvariable = Select(ToTOMVariable,"DefaultintoTOM")
  ecctoms = findall(IsActiveToECCTOM[ECCTOMs,totomvariable] .== 1)
  
  #
  # Calculate implied sales using ratio of vehicle sales to gross otuput
  #
  ecctoms1 = Select(ECCTOM,!=("Air"))
  ecctoms2 = Select(ECCTOM,!=("Water"))
  ecctoms3 = Select(ECCTOM,!=("Rail"))
  ecctoms4 = Select(ECCTOM,!=("Truck"))
  ecctoms5 = Select(ECCTOM,!=("Transit"))
  ecctoms = intersect(ecctoms1,ecctoms2,ecctoms3,ecctoms4,ecctoms5)

  for year in Years, areatom in AreaTOMs, ecctom in ECCTOMs, fleet in Fleets
    VehicleSalesImplied[fleet,ecctom,areatom,year] = 
      VehicleSalesRatio[fleet,ecctom,areatom,year]*
      GYinto[ecctom,areatom,year]
  end
  ecctoms = Select(ECCTOM,["Transit","Truck","Air","Rail","Water"])
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fleet in Fleets
    VehicleSalesImplied[fleet,ecctom,areatom,year] = VehicleSalesRatio[fleet,ecctom,areatom,year]*
    GYFleet[fleet,areatom,year]
  end

  totomvariable = Select(ToTOMVariable,"DefaultintoTOM")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)
  for year in Years, areatom in AreaTOMs, fleet in Fleets
    VehicleSalesImpliedTotal[fleet,areatom,year] = 
      sum(VehicleSalesImplied[fleet,ecctom,areatom,year] for ecctom in ecctoms)
  end

  #
  # Implied fractions (sum to 1.0 across industry & transp. industry)
  #
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fleet in Fleets
    @finite_math VehicleSalesImpliedFrac[fleet,ecctom,areatom,year] = 
      VehicleSalesImplied[fleet,ecctom,areatom,year]/
        VehicleSalesImpliedTotal[fleet,areatom,year]
  end

  #
  # Allocate fleet investments change to industries using implied fractions
  #
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fleet in Fleets
    VehicleSalesChange[fleet,ecctom,areatom,year] = FleetInvestmentsChange[fleet,areatom,year]*
      VehicleSalesImpliedFrac[fleet,ecctom,areatom,year]
  end
  
  #
  # Update total investment variables - add transport to energy investments (IFMEe)
  #
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    IFMEe[ecctom,areatom,year] = IFMEe[ecctom,areatom,year]+
      sum(FleetInvestments[fleet,areatom,year]*
        VehicleSalesImpliedFrac[fleet,ecctom,areatom,year] for fleet in Fleets)
  end

  #
  # Scale investment policy impacts to TOM's BAU levels
  #
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    @finite_math ScaledChange[ecctom,areatom,year] = 
      (sum(VehicleSalesChange[fleet,ecctom,areatom,year] for fleet in Fleets)/
        IFMEe_Ref[ecctom,areatom,year])*IFME_BAU[ecctom,areatom,year]
  end

  #
  # TOM policy variables. Change in investments is sent to TOM only in forecast years
  #
  years = collect(Future+2:Yr(2050))
  for year in years, areatom in AreaTOMs, ecctom in ecctoms
    IF_Tra[ecctom,areatom,year] = ScaledChange[ecctom,areatom,year]
  end

  WriteDisk(db,"KOutput/VehicleSalesImplied",VehicleSalesImplied)
  WriteDisk(db,"KOutput/VehicleSalesImpliedFrac",VehicleSalesImpliedFrac)
  WriteDisk(db,"KOutput/IFMEe",IFMEe)
  WriteDisk(db,"KOutput/IF_Tra",IF_Tra)
end

function CalcInvestmentsTr(db)
  data = MControl(; db)
  (;Nation) = data
  (;ANMap) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas_cn = findall(ANMap[:,CN] .== 1)
  areas_us = findall(ANMap[:,US] .== 1)
  areas = union(areas_cn,areas_us)

  ReadDatabases(data)
  InitializeVariables(data)
  MapGrossOutputToVehicles(data,areas)
  AssignDInvHousehold(data,areas)
  AssignDInvNonHousehold(data,areas)
  WriteHouseholdInvestmentsToTOM(data,areas)
  MapNonHouseholdToFleet(data,areas)
  AllocateFleetToIndustry(data,areas)
end

function Control(db)
  @info "E2020DeviceInvestmentsTr.jl - Control"
  CalcInvestmentsTr(db)
end

if abspath(PROGRAM_FILE) ==  @__FILE__
  Control(DB)
end

end
