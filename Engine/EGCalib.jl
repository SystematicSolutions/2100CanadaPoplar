#
# EGCalib.jl
#

using EnergyModel

module EGCalib

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
import ...EnergyModel: Engine.ECosts
import ...EnergyModel: Engine.EPeakHydro
import ...EnergyModel: Engine.EDispatch
import ...EnergyModel: Engine.EGenerationSummary
import ...EnergyModel: Engine.EFlows
import ...EnergyModel: Engine.EFuelUsage
import ...EnergyModel: Engine.EPollution

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoKey::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EGCalSw::VariableArray{2} = ReadDisk(db,"EGInput/EGCalSw") # [Nation,Year] Switch for Years to Calibrate Generation (1=Calibrate)
  PlantSw::VariableArray{1} = ReadDisk(db,"EGInput/PlantSw") # [Plant] Iteration when this Plant Type begins to be calibrated
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnEGA::VariableArray{2} = ReadDisk(db,"EGOutput/UnEGA") # [Unit,Year] Generation (GWh)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnOOR::VariableArray{2} = ReadDisk(db,"EGCalDB/UnOOR") # [Unit,Year] Operational Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UUnEGA::VariableArray{2} = ReadDisk(db,"EGOutput/UUnEGA") # [Unit,Year] Generation (GWh)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation

  #
  # Scratch Variables
  #
  CtAll = 6          # Count when all Plant types are included in calibration
  CtMax = 10         # Maximum Iterations
  ErrLimit = 0.02    # Error Limit aka Error Target (GWh)
  OORLimit = -0.98   # Limit on Operational Outage Rate (MW/MW)

  TempErr::VariableArray{1} = zeros(Float32,length(Unit))

  UnErr1::VariableArray{1} = zeros(Float32,length(Unit))
  UnErr2::VariableArray{1} = zeros(Float32,length(Unit))
  UnOOR1::VariableArray{1} = zeros(Float32,length(Unit))
  UnOOR2::VariableArray{1} = zeros(Float32,length(Unit))


  # ExceedsLimit, Type=String(5)
  # Pt1       'Pointer to set values'
  SetYearFlag::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Years for Calibration Flag
  # UnitIsCalibrated, Type=String(5)
end

function GetUnitSets(data,unit)
  (;Area,GenCo,Node,Plant,) = data
  (;UnArea,UnGenCo,UnNode) = data
  (;UnPlant) = data

  if (UnGenCo[unit] != "Null") && (UnPlant[unit] != "Null") && (UnNode[unit] != "Null") && (UnArea[unit] != "Null")
    genco = Select(GenCo,UnGenCo[unit])
    plant = Select(Plant,UnPlant[unit])
    node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    UnitIsValid=true
  else
    genco = Int(1)
    plant = Int(1)
    node = Int(1)
    area = Int(1)
    UnitIsValid = false
  end

  return plant,node,genco,area,UnitIsValid
end


function SetYears(data)
  (;Nations,Years) = data
  (;EGCalSw,SetYearFlag) = data
  
  for year in Years
    SetYearFlag[year] = min(maximum(EGCalSw[nation,year] for nation in Nations),1)
  end
  years = findall(SetYearFlag[Years] .== 1)
  return years
end

function Initialization(data,year)
  (;db) = data
  (;Units,Years) = data
  (;UnOOR,UnErr1) = data

  for unit in Units
    UnOOR[unit,year] = 0.005
    UnErr1[unit] = -99
  end

  WriteDisk(db,"EGCalDB/UnOOR",UnOOR)
end

function InitUnCalProd(data,year)
  (;Nations) = data
  (;EGCalSw) = data

  for nation in Nations
    EGCalSw[nation,year] = 1
  end
end

function DebugLog(data,unit,plant,area,year,Ct,DoneOOR)
  (;db) = data
  (;Area,AreaDS,Areas,Nation,NationDS,Nations,Plant,PlantDS,Plants,Unit) = data
  (;Units,Year,YearDS,Years) = data
  (;ANMap,EGCalSw,PlantSw,UnArea,UnCode,UnEGA,UnErr1,UnErr2,UnGenCo) = data
  (;UnNation,UnNode,UnOnLine,UnOOR,UnOOR1,UnOOR2,UnPlant,UUnEGA,xUnEGA) = data
  (;SetYearFlag) = data
  
  UUnEGA::VariableArray{2} = ReadDisk(db,"EGOutput/UUnEGA") # [Unit,Year] Ge
  
  @info " "
  loc2 = Year[year]
  loc1 = UnCode[unit]
  @info " $loc1 Count = $Ct Done = $DoneOOR"
  loc1 = UUnEGA[unit,year]
  @info " UUnEGA[$unit,$year] = $loc1  $loc2" 
  loc1 = xUnEGA[unit,year]
  @info " xUnEGA = $loc1"
  loc1 = UnErr1[unit]
  @info " UnErr1 = $loc1"
  loc1 = UnErr2[unit]
  @info " UnErr2 = $loc1"  
  loc1 = UnOOR[unit,year]
  @info " UnOOR  = $loc1" 
  loc1 = UnOOR1[unit]
  @info " UnOOR1 = $loc1"   
  loc1 = UnOOR2[unit]
  @info " UnOOR2 = $loc1"    
end

function UnitProductionCalibration(data,year,unit,plant,node,genco,area,Ct,Ct12,DoneOOR)
  (;db) = data
  (;Area,AreaDS,Areas,Nation,NationDS,Nations,Plant,PlantDS,Plants,Unit) = data
  (;Units,Year,YearDS,Years) = data
  (;EGCalSw,ErrLimit,OORLimit,PlantSw) = data
  (;UnArea,UnCode,UnEGA,UnErr1,UnErr2,UnGenCo,UnNation,UnNode,UnOnLine) = data
  (;UnOOR,UnOOR1,UnOOR2,UnPlant,UUnEGA,xUnEGA) = data
  (;SetYearFlag) = data

  CN=Select(Nation,"CN")
  US=Select(Nation,"US")
  MX=Select(Nation,"MX")

  UUnEGA::VariableArray{2} = ReadDisk(db,"EGOutput/UUnEGA") # [Unit,Year] Generation (GWh)

  #
  # Select units to be calibrated
  #
  if (PlantSw[plant] <= Ct) &&
     (((UnNation[unit] == "CN") && (EGCalSw[CN,year] == 1)) ||
      ((UnNation[unit] == "US") && (EGCalSw[US,year] == 1)) ||
      ((UnNation[unit] == "MX") && (EGCalSw[MX,year] == 1)) )

    #
    # Calculate current Error
    #
    UnErr1[unit] = xUnEGA[unit,year]-UUnEGA[unit,year]

    #
    # Check if Error exceeds limit (ErrLimit)
    #
    if (abs(UnErr1[unit]) > ErrLimit) &&
      ((UnOOR[unit,year] > OORLimit) || (UUnEGA[unit,year] > xUnEGA[unit,year]))

      #
      # Adjust Operational Outage Rate (UnOOR) with Secant Method
      #
      # First Iteration perturb UnOOR
      #
      if Ct == PlantSw[plant]
        UnOOR[unit,year] = UnOOR[unit,year]*1.20
      #
      # Every twelve iterations perturb oscilations
      #
      elseif Ct12 == 10
         UnOOR[unit,year] = (UnOOR1[unit]+UnOOR2[unit]+UnOOR[unit,year])/3
      #
      # Actual solution Iteration
      #
      else
        @finite_math UnOOR[unit,year] = UnOOR1[unit]-
          (UnErr1[unit]*(UnOOR1[unit]-UnOOR2[unit])/(UnErr1[unit]-UnErr2[unit]))         

        #
        # If UnOOR drops to zero, then give it a small value
        #
        if UnOOR[unit,year] == 0
          UnOOR[unit,year] = UnOOR[unit,year]+0.005
        end

        #
        # If no change from previous error, then give UnOOR a push
        #
        if UnErr2[unit] == UnErr1[unit] && UnOOR[unit,year] < 0.99
          UnOOR[unit,year] = UnOOR[unit,year]*1.2
        else
          UnOOR[unit,year] = UnOOR[unit,year]*0.80
        end        

        #
        # If no generation (xUnEGPA=0), then set UnOOR close to 1.00.
        #
        if xUnEGA[unit,year] == 0
          UnOOR[unit,year] = 0.99             
        end
      end

      #
      # Limit Change
      #
      UnOOR[unit,year] = max(min(UnOOR[unit,year],UnOOR1[unit]+.10),UnOOR1[unit]-0.10)

      #
      # Trap outliers of UnOOR
      #
      UnOOR[unit,year] = max(min(UnOOR[unit,year],0.99),OORLimit)

      #
      #   Create debug log for selected unit
      #
      # if UnCode[unit] == "ON00011106701"
      # if unit == 14
      #   DebugLog(data,unit,plant,area,year,Ct,DoneOOR)
      # end

      #
      # Update errors and outage rates
      #
      UnErr2[unit] = UnErr1[unit]
      UnOOR2[unit] = UnOOR1[unit]
      UnOOR1[unit] = UnOOR[unit,year]
    end
  end

end

function FindMaxError(data)
  (;db) = data
  (;Units) = data
  (;TempErr,UnErr1) = data

  for unit in Units
    TempErr[unit] = abs(UnErr1[unit])
  end
  ErrMax = maximum(TempErr[unit] for unit in Units)
  return ErrMax
end

function CheckIfWeAreDone(data,DoneOOR,Ct,ErrMax)
  (;db) = data
  (;CtAll,ErrLimit,CtMax) = data

  #
  # If Count if high enough that all plant types have been calibrated
  # and maximum error is less than limit or Count grater than maximum
  # count, then we are done.
  #
  if ((Ct > CtAll) && (ErrMax < ErrLimit)) || (Ct > CtMax)
    DoneOOR = true
  end
  return DoneOOR
end

function CalProd(data,year,DoneOOR,Ct,Ct12)
  (;db) = data
  (;Area,AreaDS,Areas,Nation,NationDS,Nations,Plant,PlantDS,Plants,Unit) = data
  (;Units,Year,YearDS,Years) = data
  (;ANMap,EGCalSw,PlantSw,UnArea,UnCode,UnEGA,UnGenCo,UnNation,UnNode,UnOnLine) = data
  (;UnOOR,UnPlant,UUnEGA,xUnEGA) = data
  (;SetYearFlag) = data

  #
  InitUnCalProd(data,year)
  #
  for unit in Units
    plant,node,genco,area,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid == true
      UnitProductionCalibration(data,year,unit,plant,node,genco,area,Ct,Ct12,DoneOOR)
    end
  end

  WriteDisk(db,"EGCalDB/UnOOR",UnOOR)
end

function OORFuture(data)
  (;db) = data
  (;Units) = data
  (;UnOOR) = data

  years = collect(Future:Final)
  for year in years, unit in Units
    UnOOR[unit,year] = UnOOR[unit,Last]
  end

  WriteDisk(db,"EGCalDB/UnOOR",UnOOR)
end

function OORCalib(db)
  data = Data(; db)
  (;UUnEGA) = data
  
  years = SetYears(data)
    
  for year in years
    CTime = year+ITime-1
    current = CTime-ITime+1
    prior = max(1,current-1)
    prior2 = max(1,prior-1)
    prior3 = max(1,prior2-1)
    prior4 = max(1,prior3-1)
    next = current+1

    Initialization(data,year)
    
    DoneOOR = false
    Ct12 = 0
    Ct = 0

    while DoneOOR == false
    
      @info "EGCalib.jl - OORCalib - Count is $Ct for $CTime"

      #
      #  Dispatch Units
      #
      #@info "EGCalib.jl - OORCalib - ECosts"
      ECosts.Costs(ECosts.Data(; db,year,prior,next,CTime))  
      
      #@info "EGCalib.jl - OORCalib - EPeakHydro"
      EPeakHydro.HydroControl(EPeakHydro.Data(; db,year,prior,next,CTime))  
      
      #@info "EGCalib.jl - OORCalib - EDispatch - DispatchElectricity"
      EDispatch.DispatchElectricity(EDispatch.Data(; db,year,prior,next,CTime))  
      
      #@info "EGCalib.jl - OORCalib - EDispatch - EGenerationSummary"
      EGenerationSummary.GenSummary(EGenerationSummary.Data(; db,year,prior,next,CTime))
      
      #@info "EGCalib.jl - OORCalib - EFlows"
      EFlows.Flows(EFlows.Data(; db,year,prior,next,CTime))
      
      #@info "EGCalib.jl - OORCalib - EFuelUsage - RunFuelUsage"
      EFuelUsage.RunFuelUsage(EFuelUsage.Data(; db,year,prior,next,CTime))  
      
      #@info "EGCalib.jl - OORCalib - EPollution - Part2"
      EPollution.Part2(EPollution.Data(; db,year,prior,next,CTime))                    
      

      #
      # Adjust Outage Rates
      #
      CalProd(data,year,DoneOOR,Ct,Ct12)
      
      #
      # UpdateCounters - was procedure in Promula
      #
      if Ct12 == 12
        Ct12 = 0
      else
        Ct12 = Ct12+1
      end
      Ct = Ct+1
  
      ErrMax = FindMaxError(data)

      DoneOOR = CheckIfWeAreDone(data,DoneOOR,Ct,ErrMax)     
      
    end # while DoneOOR
    @info "Electric Production Calibration Complete inside EControl.src for $CTime"
  end # years

  #
  # Finalizations
  #
  OORFuture(data)

end # OORCalib

end # Module EGCalib
