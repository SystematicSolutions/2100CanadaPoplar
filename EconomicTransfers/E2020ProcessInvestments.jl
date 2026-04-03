#
# E2020ProcessInvestments.jl - ENERGY 2100 process investments (PInv) are aligned to TOM's construction plus machinery & equipment investments
#                               To send TOM just the construction portion, we subtract off device investmentments (DInv) from PInv.
#
using EnergyModel

module E2020ProcessInvestments

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String
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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case) 
  IFCe::VariableArray{3} = ReadDisk(db,"KOutput/IFCe") # [ECCTOM,AreaTOM,Year] E2020 Fixed Investments (2017 $M/Yr)
  IFC_PolE::VariableArray{3} = ReadDisk(db,"KOutput/IFC_PolE") # [ECCTOM,AreaTOM,Year] E2020 Fixed Investments from Policy (2017 $M/Yr)
  # IFCHH_BAU::VariableArray{2} = ReadDisk(db,"KOutput/IFCHH_BAU") # [AreaTOM,Year] TOM Residential Investments in Construction (2017 $M/Yr)
  IFCHHe::VariableArray{2} = ReadDisk(db,"KOutput/IFCHHe") # [AreaTOM,Year] E2020 Residential Investments in Construction (2017 $M/Yr)
  IFCHH_PolE::VariableArray{2} = ReadDisk(db,"KOutput/IFCHH_PolE") # [AreaTOM,Year] Residential Investments in Construction from Policy (2017 $M/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  SplitECCtoTOMIFC::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFC") # [ECC,ECCTOM,AreaTOM,Year] Split ECC to TOM based on Construction Investments, IFCe ($/$)
  SplitECCtoTOMIFME::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFME") # [ECC,ECCTOM,AreaTOM,Year] Split ECC to TOM based on M&E Investments, IFMEe ($/$)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  DInv::VariableArray{3} = ReadDisk(db,"SOutput/DInv") # [ECC,Area,Year] Device Investments (M$/Yr)
  DeviceInvestmentsRun1::VariableArray{3} = ReadDisk(Run1NameDB,"SOutput/DInv") # [ECC,Area,Year] Device Investments (M$/Yr)
  DeviceInvestmentsRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/DInv") # [ECC,Area,Year] Device Investments (M$/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  PInv::VariableArray{3} = ReadDisk(db,"SOutput/PInv") # [ECC,Area,Year] Process Investments in Reference Case (M$/Yr)
  PInvRun1::VariableArray{3} = ReadDisk(Run1NameDB,"SOutput/PInv") # [ECC,Area,Year] Process Investments (M$/Yr)
  PInvRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/PInv") # [ECC,Area,Year] Process Investments in Reference Case (M$/Yr)
  TDInv::VariableArray{2} = ReadDisk(db,"SOutput/TDInv") # [Area,Year] Electric Transmission and Distribution Investments (M$/Yr)
  TDInvRun1::VariableArray{2} = ReadDisk(Run1NameDB,"SOutput/TDInv") # [Area,Year] Electric Transmission and Distribution Investments (M$/Yr)
  TDInvRef::VariableArray{2} = ReadDisk(RefNameDB,"SOutput/TDInv") # [Area,Year] Electric Transmission and Distribution Investments (M$/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index in Reference Case ($/$)
  xInflationRef::VariableArray{2} = ReadDisk(RefNameDB,"MInput/xInflation") # [Area,Year] Inflation Index in Reference Case ($/$)

  #
  # Scratch Variables
  #
  ConstructionInvestmentsRef::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] Process Investments minus Device Investments, Reference Case (M$/Yr)
  ConstructionInvestmentsRun1::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] Process Investments minus Device Investments, Run1 (M$/Yr)
  # ConstructionTime 'Construction Time for New Building/Facility Investments (Years)'
  # Count    'Index for Construction Time (Counter)'
  DeviceInvestmentsMappedRef::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] Device Investments (M$/Yr)
  DeviceInvestmentsMappedRun1::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] Device Investments (M$/Yr)
  IFCHHe_Change::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Residential Investments in Construction from Policy (2017 $M/Yr)
  IFCHHe_Ref::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] E2020 Residential Investments in Construction (2017 $M/Yr)
  IFCe_Change::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] E2020 Change in Fixed Investments from Policy (2017 $M/Yr)
  IFCe_Frac::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] E2020 Fraction Change in Fixed Investments from Policy (2017 $M/Yr)
  IFCe_Ref::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] E2020 Reference Case Fixed Investments (2017 $M/Yr)
  # InvYear  'Year of Investment (Year)'
  PInvMappedRef::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] Process Investments (M$/Yr)
  PInvMappedRun1::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] Process Investments (M$/Yr)
  PInvSmoothRef::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] Construction Investments Adjusted for Construction Time, Reference Case (M$/Yr)
  PInvSmoothRun1::VariableArray{3} = zeros(Float32,length(ECCTOM),length(AreaTOM),length(Year)) # [ECCTOM,AreaTOM,Year] Construction Investments Adjusted for Construction Time (M$/Yr)
 # YrIndex
end

function ReadDatabases(data)
  (; BaseSw,RefSwitch,Run1Name,SceName) = data
  (; DInv,DeviceInvestmentsRun1,DeviceInvestmentsRef) = data
  (; PInv,PInvRun1,PInvRef,TDInv,TDInvRun1,TDInvRef,xInflation,xInflationRef) = data

  if (BaseSw == 0) && (RefSwitch == 0)
    # xInflationRef from Reference Case
    # DeviceInvestmentsRef from Reference Case
    # PInvRef from Reference Case
    # TDInvRef from Reference Case
    if Run1Name != SceName[1]
      # DeviceInvestmentsRun1 from Run1
      # PInvRun1 from Run1
      # TDInvRun1 from Run1
    else
      # DeviceInvestmentsRun1 from default database
      @. DeviceInvestmentsRun1 = DInv
      @. PInvRun1 = PInv
      @. TDInvRun1 = TDInv
    end
    #
    # Read TOM Reference (BAU) values
    #
  elseif ((BaseSw != 0) || (RefSwitch != 0)) && (Run1Name != "Ref25A_TOM_1")
    # variables from default database
    @. xInflationRef = xInflation
    @. DeviceInvestmentsRef = DInv
    @. PInvRef = PInv
    @. TDInvRef = TDInv
    @. DeviceInvestmentsRun1 = DInv
    @. PInvRun1 = PInv
    @. TDInvRun1 = TDInv
  end
end

function SmoothProcessInvestments(data,areas,ecctoms)
  (; Area,AreaTOM,AreaTOMs,ECC,ECCDS,ECCs,Years) = data
  (; DeviceInvestmentsRun1,DeviceInvestmentsRef,PInvRun1,PInvRef) = data
  (; ConstructionInvestmentsRef,ConstructionInvestmentsRun1) = data
  (; DeviceInvestmentsMappedRef,DeviceInvestmentsMappedRun1) = data
  (; MapAreaTOM,PInvMappedRef,PInvMappedRun1,PInvSmoothRef,PInvSmoothRun1) = data
  (; SplitECCtoTOMIFC,SplitECCtoTOMIFME) = data

  #
  # Adjust process investments to account for construction
  #
  ConstructionTime = 4
  @. PInvSmoothRun1 = 0
  @. PInvSmoothRef = 0
  @. PInvMappedRun1 = 0

  #
  # Eliminate NaNs from PInv
  #
  for year in Years, area in areas, ecc in ECCs
    if isnan(PInvRun1[ecc,area,year])
      PInvRun1[ecc,area,year] = 0
      PInvRef[ecc,area,year] = 0
    end
  end 

  #
  # Map E2020 investments ECCs to ECCTOM
  #
  for area in areas
    areatom = Select(AreaTOM,Area[area])
    for year in Years, ecctom in ecctoms
      PInvMappedRun1[ecctom,areatom,year] = 
        sum(PInvRun1[ecc,area,year]*SplitECCtoTOMIFC[ecc,ecctom,areatom,year] for ecc in ECCs)

      DeviceInvestmentsMappedRun1[ecctom,areatom,year] = 
        sum(DeviceInvestmentsRun1[ecc,area,year]*SplitECCtoTOMIFME[ecc,ecctom,areatom,year] for ecc in ECCs)

      PInvMappedRef[ecctom,areatom,year] = 
        sum(PInvRef[ecc,area,year]*SplitECCtoTOMIFC[ecc,ecctom,areatom,year] for ecc in ECCs)

      DeviceInvestmentsMappedRef[ecctom,areatom,year] = 
        sum(DeviceInvestmentsRef[ecc,area,year]*SplitECCtoTOMIFME[ecc,ecctom,areatom,year] for ecc in ECCs)
    end

    for year in Years, ecctom in ecctoms
      ConstructionInvestmentsRun1[ecctom,areatom,year] = PInvMappedRun1[ecctom,areatom,year]-
        DeviceInvestmentsMappedRun1[ecctom,areatom,year]
 
      ConstructionInvestmentsRef[ecctom,areatom,year] = PInvMappedRef[ecctom,areatom,year]-
        DeviceInvestmentsMappedRef[ecctom,areatom,year]  
    end
  end

  #
  # Do not allow investments to be negative
  #
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    ConstructionInvestmentsRun1[ecctom,areatom,year] = max(ConstructionInvestmentsRun1[ecctom,areatom,year],0)
    ConstructionInvestmentsRef[ecctom,areatom,year] = max(ConstructionInvestmentsRef[ecctom,areatom,year],0)
  end

  years=collect(Zero:Final)

  for year in years
    Count = ConstructionTime-1  
    while Count >= 0
      InvYear = Int(min(year+Count,Final))
      for areatom in AreaTOMs, ecctom in ecctoms
        @finite_math PInvSmoothRun1[ecctom,areatom,year] = PInvSmoothRun1[ecctom,areatom,year] +
            ConstructionInvestmentsRun1[ecctom,areatom,InvYear]/ConstructionTime
        @finite_math PInvSmoothRef[ecctom,areatom,year] = PInvSmoothRef[ecctom,areatom,year] +
            ConstructionInvestmentsRef[ecctom,areatom,InvYear]/ConstructionTime
      end
      Count = Count-1
    end
  end

end

function ProcessInvestments(data,areas,ecctoms)
  (; db) = data
  (; Area,AreaTOM,AreaTOMs,ECCs,Years) = data
  (; IFCe,IFC_PolE) = data
  (; IFCe_Change,IFCe_Ref) = data
  (; PInvSmoothRef,PInvSmoothRun1,TOMBaseYear,xInflationRef) = data

  #
  # IFC_PolE is the change in Construction Investments due to Policy changes (PInvRun1-PInvRef).
  #
  @. IFCe = 0
  @. IFCe_Ref = 0
  @. IFC_PolE = 0
  
  for area in areas
    areatom = Select(AreaTOM,Area[area])
    for year in Years, ecctom in ecctoms
      @finite_math IFCe[ecctom,areatom,year] = PInvSmoothRun1[ecctom,areatom,year]/
          xInflationRef[area,year]*xInflationRef[area,TOMBaseYear]
      @finite_math IFCe_Ref[ecctom,areatom,year] = PInvSmoothRef[ecctom,areatom,year]/
          xInflationRef[area,year]*xInflationRef[area,TOMBaseYear]
      IFCe_Change[ecctom,areatom,year] = IFCe[ecctom,areatom,year]-IFCe_Ref[ecctom,areatom,year]
    end
  end

  #
  # Change in investments is sent to TOM only in forecast years
  #
  years = collect(Future+2:Yr(2050))
  for year in years, areatom in AreaTOMs, ecctom in ecctoms
    IFC_PolE[ecctom,areatom,year] = IFCe_Change[ecctom,areatom,year]
  end
  
  WriteDisk(db,"KOutput/IFCe",IFCe)
  WriteDisk(db,"KOutput/IFC_PolE",IFC_PolE)

end

function ResidentialInvestments(data,areas,ecctoms)
  (; db) = data
  (; Area,AreaTOM,AreaTOMs,ECC,Years) = data
  (; IFCHHe_Change,IFCHHe,IFCHHe_Ref,IFCHH_PolE) = data
  (; PInvRun1,PInvRef,TOMBaseYear,xInflationRef) = data

  eccs=Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential"])
  for area in areas
    areatom=Select(AreaTOM,Area[area])
    for year in Years
      IFCHHe[areatom,year] = sum(PInvRun1[ecc,area,year]/
          xInflationRef[area,year]*xInflationRef[area,TOMBaseYear] for ecc in eccs)
      IFCHHe_Ref[areatom,year] = sum(PInvRef[ecc,area,year]/
        xInflationRef[area,year]*xInflationRef[area,TOMBaseYear] for ecc in eccs)
      IFCHHe_Change[areatom,year] = IFCHHe[areatom,year]-IFCHHe_Ref[areatom,year]
    end
  end

  #
  # Change in investments is sent to TOM only in forecast years
  #
  years = collect(Future+2:Yr(2050))
  for year in years, areatom in AreaTOMs
    # IFCHH_PolE[areatom,year]=(IFCHHe_Change[areatom,year]/IFCHHe_Ref[areatom,year])*IFCHH_BAU[areatom,year]
    IFCHH_PolE[areatom,year] = IFCHHe_Change[areatom,year]
  end
  
  WriteDisk(db,"KOutput/IFCHHe",IFCHHe)
  WriteDisk(db,"KOutput/IFCHH_PolE",IFCHH_PolE)

end

function CalcInvestments(db)
  data = MControl(; db)
  (; Nation,ToTOMVariable) = data
  (; ANMap,IsActiveToECCTOM) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas_cn = findall(ANMap[:,CN] .== 1)
  areas_us = findall(ANMap[:,US] .== 1)
  areas = union(areas_cn,areas_us)

  totomvariable = Select(ToTOMVariable,"IFC_PolE")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)

  ReadDatabases(data)

  SmoothProcessInvestments(data,areas,ecctoms)
  ProcessInvestments(data,areas,ecctoms)
  ResidentialInvestments(data,areas,ecctoms)
end

function Control(db)
  @info "E2020ProcessInvestments.jl - Control"
  CalcInvestments(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
