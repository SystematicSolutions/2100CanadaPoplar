#
# EPeakHydro.jl
#

module EPeakHydro

  import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime
  import ...EnergyModel: finite_inverse,@autoinfiltrate

  const VariableArray{N} = Array{Float32,N} where {N}
  const SetArray = Vector{String}

  Base.@kwdef struct Data
    db::String
    year::Int
    prior::Int
    next::Int
    CTime::Int
    
    Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
    Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
    Months::Vector{Int} = collect(Select(Month))
    Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
    Node::SetArray = ReadDisk(db,"MainDB/NodeKey")   
    Nodes::Vector{Int} = collect(Select(Node))
    NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey") 
    TimeA::SetArray = ReadDisk(db,"MainDB/TimeAKey")
    TimeAs::Vector{Int} = collect(Select(TimeA))
    TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
    TimePs::Vector{Int} = collect(Select(TimeP))
    Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")   

    ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
    HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
    HDPDP::VariableArray{3} = ReadDisk(db,"EGOutput/HDPDP",year) #[Node,TimeP,Month,Year]  Peak (Highest) Load in Interval (MW)
    HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month 
    LLMax::VariableArray{4} = ReadDisk(db,"EGInput/LLMax",year) #[Node,NodeX,TimeP,Month,Year]  Maximum Loading on Transmission Lines (MW)
    PHEG0::VariableArray{1} = ReadDisk(db,"EGOutput/PHEG0",year) #[Node,Year]  Generation Available - Energy (GWh)
    PHEGAv::VariableArray{2} = ReadDisk(db,"EGOutput/PHEGAv",year) #[Node,TimeA,Year]  Generation Available - Energy (GWh)
    PHEGC0::VariableArray{1} = ReadDisk(db,"EGOutput/PHEGC0",year) #[Node,Year]  Effective Generation Capacity Total (MW)
    PHEGC1::VariableArray{2} = ReadDisk(db,"EGOutput/PHEGC1",year) #[Node,TimeA,Year]  Effective Generation Capacity from Peak Method (MW)
    PHEGC2::VariableArray{2} = ReadDisk(db,"EGOutput/PHEGC2",year) #[Node,TimeA,Year]  Effective Generation Capacity from Base Method (MW)
    PHEGC3::VariableArray{2} = ReadDisk(db,"EGOutput/PHEGC3",year) #[Node,TimeA,Year]  Effective Generation Capacity Combined (MW)
    PHEGC4::VariableArray{2} = ReadDisk(db,"EGOutput/PHEGC4",year) #[Node,TimeA,Year]  Effective Generation Capacity Normalized (MW)
    PHEGCAv::VariableArray{2} = ReadDisk(db,"EGOutput/PHEGCAv",year) #[Node,TimeA,Year]  Generation Available - Capacity (MW)
    PHPDP0::VariableArray{2} = ReadDisk(db,"EGOutput/PHPDP0",year) #[Node,TimeA,Year]  Effective Peak including Exports (MW)
    PHPDP1::VariableArray{2} = ReadDisk(db,"EGOutput/PHPDP1",year) #[Node,TimeA,Year]  Effective Peak including Exports (MW)
    PHSpillage::VariableArray{3} = ReadDisk(db,"EGInput/PHSpillage",year) #[TimeP,Month,Node,Year]  Peak Hydro Spillage (MW/MW)
    UnArea = ReadDisk(db,"EGInput/UnArea") #[Unit]  Area Pointer
    UnCode = ReadDisk(db,"EGInput/UnCode") #[Unit]  Unit Code
    UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
    UnCounter = ReadDisk(db,"EGInput/UnCounter",year) #[Year]  Number of Units
    UnEAF::VariableArray{2} = ReadDisk(db,"EGInput/UnEAF",year) #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)
    UnEGC::VariableArray{3} = ReadDisk(db,"EGOutput/UnEGC",year) #[Unit,TimeP,Month,Year]  Effective Generating Capacity (MW)
    UnGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",year) #[Unit,Year]  Gross Generating Capacity (MW)
    UnGenCo = ReadDisk(db,"EGInput/UnGenCo") #[Unit]  Generating Company
    UnNode = ReadDisk(db,"EGInput/UnNode") #[Unit]  Transmission Node
    UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
    UnOR::VariableArray{3} = ReadDisk(db,"EGInput/UnOR",year) #[Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
    UnOOR::VariableArray{1} = ReadDisk(db,"EGCalDB/UnOOR",year) #[Unit,Year]  Outage Rate (MW/MW)
    UnOUREG::VariableArray{1} = ReadDisk(db,"EGInput/UnOUREG",year) #[Unit,Year]  Own Use Rate for Generation (GWh/GWh)
    UnOURGC::VariableArray{1} = ReadDisk(db,"EGInput/UnOURGC",year) #[Unit,Year]  Own Use Rate for Generating Capacity (MW/MW)
    UnPlant = ReadDisk(db,"EGInput/UnPlant") #[Unit]  Plant Type
    UnRetire::VariableArray{1} = ReadDisk(db,"EGInput/UnRetire",year) #[Unit,Year]  Retirement Date (Year)

    # Scratch variables
    AlTot = zeros(Float32)    # 'Allocation Total'
    Done = zeros(Int)    # 'Loop Completed Value'
    HRtA0::VariableArray{1} = zeros(Int,length(TimeA)) #'Hours in Annual Time Period (Hours)'
    HRtA1::VariableArray{1} = zeros(Int,length(TimeA)) #'Hours in Annual Time Period (Hours)'
    HRtACum::VariableArray{1} = zeros(Int,length(TimeA)) # 'Cumulative Hours in Annual Time Period (Hours)'
    Loop3P = 1     # 'Loop 3 TimeP Pointer'
    Loop4P = 1     # 'Loop 4 TimeP Pointer'
    PHEGTot = zeros(Float32) # 'Total Generation (GWh)'
    PtTA = 1             # 'Pointer for TimeA'
    PtTA0 = zeros(Int,length(TimeA)) # 'Pointer for TimeA'
    PtTA1 = zeros(Int,length(TimeA)) # 'Pointer for TimeA'
    PtMo = zeros(Int,length(TimeA))     # 'Pointer for Month'
    PtTP = zeros(Int,length(TimeA))     # 'Pointer for TimeP'
    TACount = zeros(Int)  # 'Counter for TimeA'
  end

  function GetUtilityUnits(data::Data)
    (; CTime) = data
    (; UnCogen,UnCounter,UnOnLine,UnRetire) = data

    UnitsActive = 1:Int(UnCounter)
    UnitsNotCogen = Select(UnCogen,==(0.0))
    UnitsOnline = Select(UnOnLine,<=(CTime))
    UnitsNotRetired = Select(UnRetire,>(CTime))
    UtilityUnits = intersect(UnitsActive,UnitsOnline,UnitsNotRetired,UnitsNotCogen)

    return UtilityUnits

  end
  
  #
  ######################
  #
  function BuildAnnualLoadCurve(data::Data)
    (; Months,Nodes,TimePs) = data
    (; HDHours,HDPDP,LLMax,HRtA0,PHSpillage,PHPDP0,PtMo,PtTP,PtTA0) = data
    (; TACount) = data
    
    #
    # Build an annual load duration curve from the monthly load duration curves
    # Move data from monthly time periods (Month and TimeP) into
    # annual time periods (TimeA) since we will be allocating the
    # hydro across months and time periods.
    #
    TACount = 1
    
    for month in Months, timep in TimePs
     
      #
      # Effective Peak Load (including possible exports)
      #
      for FromNode in Nodes
        PHPDP0[FromNode,TACount] = HDPDP[FromNode,timep,month]+
          (sum(LLMax[ToNode,FromNode,timep,month] for ToNode in Nodes)*
          (1-PHSpillage[timep,month,FromNode]))
      end
     
      #
      # Hours in each Time Period
      #
      HRtA0[TACount] = HDHours[timep,month]

      #
      # Pointers
      #
      PtMo[TACount] = month
      PtTP[TACount] = timep
      PtTA0[TACount] = TACount

      TACount = TACount+1
    end # for month, timep
  end # BuildAnnualLoadCurve

  function CreateLoadCurveTimeA(data::Data,node)
    (; TimeAs) = data
    (; PHPDP1,HRtA1,PtTA1,PHPDP0,HRtA0,PtTA0) = data
    
    # @info "  EPeakHydro.jl - CreateLoadCurveTimeA"
    
    #
    # We now create a Load Curve (PHPDP1) where the highest load is in TimeA(1),
    # next highest in TimeA(2), etc. We also save the pointer (PtTA1) and
    # the hours in each period (HRtA1) for this new load curve.
    #
    new_order = sortperm(PHPDP0[node,TimeAs],rev = true)
    
    PtTA1[TimeAs] = PtTA0[new_order]
    PHPDP1[node,TimeAs] = PHPDP0[node,new_order]
    HRtA1[TimeAs] = HRtA0[new_order]
 
  end
  
  #
  # *************************
  #
  function CumulativeHours(data::Data,node)
    (; TimeAs) = data
    (; HRtA1,HRtACum) = data

    # 
    # Cumulative Hours
    #
    for T in TimeAs     
      if T > 1
        HRtACum[T] = HRtACum[T-1]+HRtA1[T]
      else
        HRtACum[T] = HRtA1[T]
      end  
    end        
    
  end # CumulativeHours
  
  #
  # ************************
  #
  function TotalHours(data::Data,node)
    (; HRtA1) = data
    HrTATot = sum(HRtA1)
    return HrTATot
  end

  #
  # ************************* 
  #  
  function GetPeakLoadUnits(data::Data,node)
    (; UnPlant,UnNode,Node) = data

    # @info "  EPeakHydro.jl - GetPeakLoadUnits"

    UtilityUnits = GetUtilityUnits(data::Data)
    UnitsNode = Select(UnNode, ==(Node[node]))
    UnitsPeakHydro = Select(UnPlant, ==("PeakHydro"))
    
    PeakHydroNodeUnits = intersect(UtilityUnits,UnitsNode,UnitsPeakHydro)
    
    return (PeakHydroNodeUnits)
  end

  function TotalCapacityAndEnergy(data::Data,node,Units)
    (; Months) = data;
    (; PHEGC0,UnGC,UnOURGC,UnOR,UnOOR,PHEG0,UnOUREG,UnEAF,HoursPerMonth) = data;
    
    # @info "  EPeakHydro.jl - TotalCapacityAndEnergy"
    #
    # TODO what happens with UnOR? - Jeff Amlin 2/20/25
    #
    timep = 1; month = 1 # TODO this isn't what we want with UnOR - Peter Volkmar 3/21/25
    PHEGC0[node] = sum(UnGC[unit]*(1-UnOURGC[unit])*(1-UnOR[unit,timep,month])*(1-UnOOR[unit])
                       for unit in Units)
    PHEG0[node] = sum([UnGC[unit]*(1-UnOUREG[unit])*UnEAF[unit,month]*
                       (1-UnOOR[unit])*HoursPerMonth[month] 
                       for month in Months, unit in Units])/1000
  end

  function InitalizePeakHydro(data::Data,node)
    (; TimeA,TimeAs) = data;
    (; PHEG0,PHEGAv,PHEGC0,PHEGC2,PHEGCAv) = data;

    # @info "  EPeakHydro.jl - InitalizePeakHydro"

    Loop1 = 1   # 'Loop 1 Indicator'
    Loop2 = 1   # 'Loop 2 Indicator'
    Loop1P = 1
    Loop2P = length(TimeA)
    
    #
    # Initialize Capacity Available and Energy Available
    #
    for timea in TimeAs
      PHEGC2[node,timea] = 0.0
      PHEGCAv[node,timea] = 0.0
      PHEGAv[node,timea] = 0.0
    end
    PHEGCAv[node,Loop1P] = PHEGC0[node] 
    PHEGAv[node,Loop1P] = PHEG0[node]
    
    return Loop1,Loop2,Loop1P,Loop2P
  end

  function AllocateHydroStartingWithBaseload(data::Data,node,Loop2,Loop2P,)
    (; TimeA) = data;
    (; PHEGCAv,PHEGAv,HRtACum,PHPDP1,PHEGC2) = data;
    # @info "  EPeakHydro.jl - AllocateHydroStartingWithBaseload"

    T = Loop2P
    #
    # Marginal Effective Generating Capacity
    #
    if Loop2P == length(TimeA)
      PHEGC2[node,T] = min(PHEGCAv[node,T],PHEGAv[node,T]/HRtACum[T]*1000,
                         PHPDP1[node,T])
    else
      PHEGC2[node,T] = min(PHEGCAv[node,T],PHEGAv[node,T]/HRtACum[T]*1000,
                         PHPDP1[node,T]-PHPDP1[node,T+1])
    end # Do If
    #
    # Update Available Capacity and Energy
    #
    if Loop2P > 1
      PHEGCAv[node,T-1] = PHEGCAv[node,T]-PHEGC2[node,T]
      PHEGAv[node,T-1] = PHEGAv[node,T]-PHEGC2[node,T]*HRtACum[T]/1000
      Loop2P = Loop2P-1
    else
      Loop2 = 0
    end
    return Loop2,Loop2P
  end

  function AllocateHydroStartingWithPeak(data::Data,node,HrTATot,Loop1,Loop2,Loop1P,Loop2P)
    (; TimeA) = data;
    (; PHEGC1,PHEGCAv,PHEGAv,HRtACum,PHPDP1) = data;
    # @info "  EPeakHydro.jl - AllocateHydroStartingWithPeak"
    
    T = Loop1P
    
    #
    # Marginal Effective Generating Capacity
    #
    if (Loop1P+1) <= length(TimeA)
      PHEGC1[node,T] = min(PHEGCAv[node,T],PHEGAv[node,T]/HRtACum[T]*1000,
                         PHPDP1[node,T]-PHPDP1[node,T+1])
    else
      PHEGC1[node,T] = min(PHEGCAv[node,T],PHEGAv[node,T]/HRtACum[T]*1000,
                         PHPDP1[node,T])
    end
    
    #
    # Update Available Capacity and Energy
    #
    if (Loop1P+1) <= length(TimeA)
      PHEGCAv[node,T+1] = PHEGCAv[node,T]-PHEGC1[node,T]
      PHEGAv[node,T+1] = PHEGAv[node,T]-PHEGC1[node,T]*HRtACum[T]/1000
      
      #
      # Check to see if capacity remaining is enough to use all the energy
      # This test is not perfect, but should work with only minimal errors.
      #
      if PHEGCAv[node,T+1] < (PHEGAv[node,T+1]/HrTATot*1000)
      
        #
        # Do not return to Loop 1
        #
        Loop1 = 0
        
        #
        # Remove last allocation of hydro
        #
        PHEGC1[node,T] = 0
        
        #
        # Initialize Capacity Available and Energy Available for Loop 2 equal
        # to the values left from Loop 1
        #
        PHEGCAv[node,Loop2P] = PHEGCAv[node,Loop1P]
        PHEGAv[node,Loop2P] = PHEGAv[node,Loop1P]
        
        #
        # Loop 2 - Allocate hydro starting with the Baseload Periods
        #
        while Loop2 == 1
          Loop2,Loop2P = AllocateHydroStartingWithBaseload(data,node,Loop2,Loop2P)
        end
      else
        Loop1P = Loop1P+1
      end
    else
      Loop1 = 0
    end # (T+1)
    return Loop1,Loop1P,Loop2,Loop2P
  end

  function CombineCapacityFromPeakAndBase(data::Data,node)
    (; TimeA) = data;
    (; Loop3P,PHEGC1,PHEGC2,PHEGC3) = data;
    
    # @info "  EPeakHydro.jl - CombineCapacityFromPeakAndBase"

    Loop3P=1
    for Loop3P in 1:length(TimeA)
      timeas = Loop3P:length(TimeA)  # TODOJulia this is confusing
      PHEGC3[node,Loop3P] = sum(PHEGC1[node,timea]+PHEGC2[node,timea] for timea in timeas)
    end
  end

  function NormalizeToTotalCapacityAndTotalEnergy(data::Data,node)
    (; TimeAs) = data;
    (; HRtA1,Loop4P,PHEG0,PHEGC0,PHEGC3,PHEGC4,PHEGTot) = data;
    
    # @info "  EPeakHydro.jl - NormalizeToTotalCapacityAndTotalEnergy"
    
    #
    # Normalize to total capacity (PHEGC0) and total energy (PHEG0)
    #
    for timea in TimeAs
      PHEGC4[node,timea] = min(PHEGC3[node,timea],PHEGC0[node])
    end
    for Loop4P in 1:4
      PHEGTot = sum(PHEGC4[node,timea]*HRtA1[timea]/1000 for timea in TimeAs)
      for timea in TimeAs
        PHEGC4[node,timea] = PHEGC4[node,timea]/PHEGTot*PHEG0[node]
        PHEGC4[node,timea] = min(PHEGC4[node,timea],PHEGC0[node])
      end
    end
  end

  function AllocateToUnitsAndMapBackToMonthsAndTimePeriods(data::Data,node,units)
    (; TimeAs) = data;
    (; AlTot,PtTA,PtTA1,PtMo,PtTP,UnGC,UnEGC,UnOURGC,UnEAF,UnOOR,PHEGC4) = data;

    # @info "  EPeakHydro.jl - AllocateToUnitsAndMapBackToMonthsAndTimePeriods"

    for timea in TimeAs
      PtTA = PtTA1[timea]
      month = PtMo[PtTA]
      timep = PtTP[PtTA]
      AlTot = sum(UnGC[unit]*(1-UnOURGC[unit])*UnEAF[unit,month]*
                 (1-UnOOR[unit]) for unit in units)
      for unit in units
        UnEGC[unit,timep,month] = UnGC[unit]*(1-UnOURGC[unit])*
          UnEAF[unit,month]*(1-UnOOR[unit])/AlTot*PHEGC4[node,timea]
      end
    end
  end

  function HydroControl(data::Data)
    (; db,year) = data
    (; Nodes) = data
    (; PHEG0,PHEGAv,PHEGC0,PHEGC1,PHEGC2,PHEGC3,PHEGC4) = data
    (; PHEGCAv,PHPDP0,PHPDP1,UnEGC) = data

    # @info "  EPeakHydro.jl - HydroControl"
  
    Loop1::Int=0   
    Loop2::Int=0  
    Loop1P::Int=0
    Loop2P::Int=0

    #
    # This procedure simulates an "optimal" allocation of the
    # available "water" (effective capacity or UnEGC) to the
    # time periods within the year.
    #
    BuildAnnualLoadCurve(data)
    #
    for node in Nodes
    
      CreateLoadCurveTimeA(data,node)
      CumulativeHours(data,node)
      HrTATot = TotalHours(data,node)
      units = GetPeakLoadUnits(data,node)
      
      if length(units) > 0
      
        TotalCapacityAndEnergy(data,node,units)
        Loop1,Loop2,Loop1P,Loop2P = InitalizePeakHydro(data,node)
        
        while Loop1 == 1
          Loop1,Loop1P,Loop2,Loop2P = AllocateHydroStartingWithPeak(data,node,HrTATot,Loop1,Loop2,Loop1P,Loop2P)
        end # Loop1
      
        CombineCapacityFromPeakAndBase(data,node)
        NormalizeToTotalCapacityAndTotalEnergy(data,node)
        AllocateToUnitsAndMapBackToMonthsAndTimePeriods(data,node,units)
        
      end # length(units) > 0
      
    end  # for node
    
    
    WriteDisk(db,"EGOutput/PHEG0",year,PHEG0)
    WriteDisk(db,"EGOutput/PHEGAv",year,PHEGAv)
    WriteDisk(db,"EGOutput/PHEGC0",year,PHEGC0)
    WriteDisk(db,"EGOutput/PHEGC1",year,PHEGC1)
    WriteDisk(db,"EGOutput/PHEGC2",year,PHEGC2)
    WriteDisk(db,"EGOutput/PHEGC3",year,PHEGC3)
    WriteDisk(db,"EGOutput/PHEGC4",year,PHEGC4)
    WriteDisk(db,"EGOutput/PHEGCAv",year,PHEGCAv)
    WriteDisk(db,"EGOutput/PHPDP0",year,PHPDP0)
    WriteDisk(db,"EGOutput/PHPDP1",year,PHPDP1)
    WriteDisk(db,"EGOutput/UnEGC",year,UnEGC)
  end # function HydroControl
end # module EPeakHydro
