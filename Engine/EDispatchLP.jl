#
# EDispatchLP.jl
#


function InitializeAggregateData(data::Data)
  (; AgUnits,Polls) = data
  (; AgEGC,AgPOCGWh,AgVCost) = data
  
  for agunit in AgUnits
    AgEGC[agunit] = 0
    AgVCost[agunit] = 0
  end
  
  for poll in Polls, agunit in AgUnits
    AgPOCGWh[agunit,poll] = 0
  end

end

function ConvertBidsToUSDollars(data::Data,timep,month)
  (; db) = data
  (; Node,Unit) = data
  (; ExchangeRateNode,ExchangeRateUnit,HDEmVCost,HDEmVCostUS,UnVCost,UnVCostUS) = data

  for unit in Select(Unit)
    @finite_math UnVCostUS[unit] = UnVCost[unit,timep,month]/ExchangeRateUnit[unit]
  end
  WriteDisk(db,"EGOutput/UnVCostUS",UnVCostUS)

  for node in Select(Node)
    HDEmVCostUS[node,timep,month] = HDEmVCost[node,timep,month]/ExchangeRateNode[node]
  end
  # WriteDisk(db,"EGOutput/HDEmVCostUS",HDEmVCostUS)

end

function AssignUnitsToEmissionGroups(data::Data)
  (; Area,Areas,Poll,Units) = data
  (; EmissionGroup,EmissionGroupInterval,MaximumNumberOfEmissionGroups) = data
  (; PollLimitGHGFlag,UnArea,UnPOCGWh) = data

  CO2 = Select(Poll,"CO2")
  #
  # Areas without Emission Limits have all units in Group 1
  #
  for unit in Units
    EmissionGroup[unit] = 1
  end
  
  #
  # Areas with Emission Limits group units with similar emissions
  #
  for area in Areas
    if PollLimitGHGFlag[area] > 1
      units = Select(UnArea,Area[area])
      for unit in units
        if UnPOCGWh[unit,CO2] > EmissionGroupInterval/2
          @finite_math EmissionGroup[unit] = min(round(UnPOCGWh[unit,CO2]/
                       EmissionGroupInterval),MaximumNumberOfEmissionGroups)
        end
      end
    else
    end
  end

end

function GetUnitsInSameEmissionGroup(data::Data,node,EmissionGroupNumber)
  (; Node,UnNode,EmissionGroup) = data

  UtilityUnits = GetUtilityUnits(data)
  UnitsNode = Select(UnNode, ==(Node[node]))
  UnitsEmissionGroup = findall(EmissionGroup .==EmissionGroupNumber)
  units = intersect(UtilityUnits,UnitsNode,UnitsEmissionGroup)
  if length(units) > 0
    UnitInSameEmissionGroup = true
  else
    UnitInSameEmissionGroup = false
  end

  return units, UnitInSameEmissionGroup

end

function CreateNewAggUnit(data::Data,node,AgNum)
  (; AgUnit,AgNode,NodeKey) = data

  AgNum = AgNum+1
  #@debug "CreateNewAggUnit, AgNum = $AgNum"
  if AgNum < length(AgUnit)
    AgNode[AgNum] = NodeKey[node]
  else
    @info " Aggregate number of generating units is equal to maximum"

    #
    # TODOJulia Writing to proper output log file.
    #
    #   Select Output "ErrorLog.log", Printer=ON

    @info " "
    @info "Inside EDispatchLP.src in procedure CreateNewAggUnit,"
    @info "the number of aggregated units (AgNum) is equal to the "
    @info "maximum number of units (AgUnit:m). The solution is to"
    @info "increase the size of the aggregate units set (AgUnit)"
    @info "or expand the 5% price limit for defining the aggregate"
    @info "categories. Jeff Amlin 10/13/2010"
    @info " "

    #   Select Printer=OFF
    #   Stop Promula
  end

  return AgNum

end

function SortUnitsByBidPrices(data::Data,units)
  (; UnVCostUS) = data;
  
  #
  # Sort Units from lowest to highest bid prices
  #
  UnitsSorted = units[sortperm(UnVCostUS[units])]
  return UnitsSorted
end


function CheckIfUnitBidCloseToAggregateBid(data::Data,unit,AgNum)
  (; AgVCost,UnVCostUS) = data

  if (UnVCostUS[unit] <= (AgVCost[AgNum]*1.05)) ||
     (UnVCostUS[unit] <= (AgVCost[AgNum]+0.001))

    UnitBidIsCloseToAggUnitBid = true
  else
    UnitBidIsCloseToAggUnitBid = false
  end
  return UnitBidIsCloseToAggUnitBid
end


function UpdateAggUnitValues(data::Data,unit,timep,month,AgNum)
  (; Poll) = data;
  (; AgEGC,AgPOCGWh,AgVCost,UnAgNum,UnEGC,UnPOCGWh,UnVCostUS) = data;

  UnAgNum[unit] = AgNum
  @finite_math AgVCost[AgNum] = (AgVCost[AgNum]*AgEGC[AgNum]+UnVCostUS[unit]*UnEGC[unit,timep,month])/(AgEGC[AgNum]+UnEGC[unit,timep,month])
  for poll in Select(Poll)
    @finite_math AgPOCGWh[AgNum,poll] = (AgPOCGWh[AgNum,poll]*AgEGC[AgNum]+UnPOCGWh[unit,poll]*UnEGC[unit,timep,month])/(AgEGC[AgNum]+UnEGC[unit,timep,month])
  end
  AgEGC[AgNum] = AgEGC[AgNum]+UnEGC[unit,timep,month]
end

function PutAggData(data::Data,AgNum)
  (; db,year) = data
  (; AgEGC,AgNode,AgVCost,UnAgNum,AgPOCGWh) = data

  WriteDisk(db,"EGOutput/AgNode",AgNode)
  WriteDisk(db,"EGOutput/AgNum",year,AgNum)
  WriteDisk(db,"EGOutput/AgEGC",AgEGC)
  WriteDisk(db,"EGOutput/AgVCost",AgVCost)
  WriteDisk(db,"EGOutput/AgPOCGWh",AgPOCGWh)
  WriteDisk(db,"EGOutput/UnAgNum",UnAgNum)

end

#
# Page 1 "Headlines"
#
function AggregateUnitsBeforeDispatch(data::Data,timep,month)
  (; Node) = data;
  (; MaximumNumberOfEmissionGroups) = data;

  InitializeAggregateData(data)
  AgNum = 0
  ConvertBidsToUSDollars(data,timep,month)
  AssignUnitsToEmissionGroups(data)

  for node in Select(Node)
    EmissionGroupNumber = 1
    while EmissionGroupNumber <= MaximumNumberOfEmissionGroups
      units, UnitInSameEmissionGroup = GetUnitsInSameEmissionGroup(data,node,EmissionGroupNumber)
      if UnitInSameEmissionGroup == true
        #
        # Create first Aggregate Unit with this level of emission
        #
        AgNum = CreateNewAggUnit(data,node,AgNum)

        units = SortUnitsByBidPrices(data,units)

        for unit in units
          UnitBidIsCloseToAggUnitBid = CheckIfUnitBidCloseToAggregateBid(data::Data,unit,AgNum)
          if UnitBidIsCloseToAggUnitBid == true
            UpdateAggUnitValues(data,unit,timep,month,AgNum)
          else
            #
            # Create Additional Units as Bid Prices Change
            #
            AgNum = CreateNewAggUnit(data,node,AgNum)
            UpdateAggUnitValues(data,unit,timep,month,AgNum)
          end
        end
      end
      EmissionGroupNumber = EmissionGroupNumber+1
    end
  end

  PutAggData(data,AgNum)
  return AgNum
end

############################
#
# Page 2 - WriteLPOutputFile
#
# Write a text file with all the data in the required format
# for the dispatch using the LP program.
#
############################

function TopOfLPInputFile(data::Data,timep,month)
  (; Month) = data

  TxtTimeP = string(timep)
  TxtMon = string(Month[month])
  LPName = "LP"*TxtMon*TxtTimeP*".lp"
  LPName = joinpath(E2020Folder,"log",LPName)
  return LPName

end

function CostOfGeneration(data::Data,LPInput)
  (; AgUnits) = data;
  (; AgEGC,AgVCost,Epsilon) = data;

  io = open(LPInput,"a")
  for agunit in AgUnits
    if AgEGC[agunit] > Epsilon
      if AgVCost[agunit] > 0
        write(io,"+ ",string(round(AgVCost[agunit]; digits = 2))," GCD",string(agunit),"\n")
      elseif AgVCost[agunit] < 0
        write(io,"  ",string(round(AgVCost[agunit]; digits = 2))," GCD",string(agunit),"\n")
      end
    end
  end
  close(io)

end

function CostOfEmergencyPower(data::Data,LPInput)
  (; Node) = data
  (; HDEmVCostUS) = data

  io = open(LPInput,"a")
  for node in Select(Node)
    write(io,"+",string(round(HDEmVCostUS[node]; digits = 2))," EMG",string(node),"\n")
  end
  close(io)

end

function CostOfTransmission(data,LPInput,timep,month)
  (; Node) = data
  (; LLVC,LLMax) = data
  (; Epsilon) = data

  io = open(LPInput,"a")
  for node in Select(Node),nodex in setdiff(Select(Node),node)
    LL1 = node*100+nodex
    # print("Node#: ", node, "  NodeX#: ", nodex, "\n")
    if ((LLMax[node,nodex,timep,month] > Epsilon) || (LLMax[nodex,node,timep,month] > Epsilon))
      write(io,"+ ",string(round(LLVC[node, nodex]; digits = 3))," LLL",string(LL1),"\n")
    end
  end
  close(io)

end

function GeneratingCapacityDispatched(data::Data,io,node)
  (; AgNode,AgUnits,Node) = data
  (; AgEGC,Epsilon) = data
  #
  #  Energy Balance Constraint - Generation at the Node
  #
  for agunit in AgUnits  
    if AgNode[agunit] == Node[node] && AgEGC[agunit] > Epsilon
      write(io,"+"," GCD",string(agunit),"\n")
    end
  end

end

function PowerTransmitted(data,io,node,timep,month)
  (; Node) = data
  (; LLMax,LLEff) = data
  (; Epsilon) = data
  #
  # Energy Balance Constraint - Tranmission Into and Out Of Node
  #
  for nodex in setdiff(Select(Node),node)
    LL1 = string(node*100+nodex)
    LL2 = string(nodex*100+node)
    if ((LLMax[node,nodex,timep,month] > Epsilon) || (LLMax[nodex,node,timep,month] > Epsilon))
      write(io,"+ ",string(round(LLEff[node,nodex]; digits = 3))," LLL",LL1," - LLL",LL2,"\n")
    end
  end

end

function EmergencyPower(io,node)
  
  #
  # Energy Balance Constraint - Emergency Power at the Node
  #
  write(io,"+"," EMG",string(node),"\n")
end

function PeakDemand(data,io,node,timep,month)
  (; HDPDP,HDADPwithStorage) = data
  
  #
  # Check for invalid values (NaN)
  #
  if (isnan(HDPDP[node,timep,month]) == false) &&
     (isnan(HDADPwithStorage[node,timep,month]) == false)
    
    #
    # Energy Balance Constraint - Electricity Demand at the Node
    #
    if timep <= 2
      write(io,">= ",string(Int(round(HDPDP[node,timep,month]))),"\n")
    elseif timep > 2
      write(io,">= ",string(Int(round(HDADPwithStorage[node,timep,month]))),"\n")
    end
  else
    @info "Invalid values for HDPDP or HDADPwithStorage for $node ,$timep ,$month"
    write(io,">= 100 ","\n")
  end
end

function TransmissionConstraints(data::Data,io,timep,month)
  (; Node) = data
  (; LLMax) = data
  (; HDXLoad,Epsilon) = data
  
  #
  # Transmission Constraint - Transmission flows must be less than
  # or equal to transmission line capacity and greater than the
  # required contract flows.
  #
  for node in Select(Node),nodex in setdiff(Select(Node),node)
    LL1 = string(node*100+nodex)
    if ((LLMax[node,nodex,timep,month] > Epsilon) || (LLMax[nodex,node,timep,month] > Epsilon))
      write(io,"LLL",LL1," <= ",string(Int(round(LLMax[node,nodex,timep,month]))),"\n")
      xLoad = min(HDXLoad[node,nodex,timep,month],LLMax[node,nodex,timep,month])
      write(io,"LLL",LL1," >= ",string(Int(round(xLoad))),"\n")
    end
  end

end

function GenerationConstraints(data::Data,io)
  (; AgNode,AgUnits,Node,Nodes) = data
  (; AgEGC,Epsilon) = data
  
  #
  # Capacity Constraint - Capacity dispatched is less or equal to
  # capacity available.
  #
  for node in Nodes
    for agunit in AgUnits 
      if AgNode[agunit] == Node[node] && AgEGC[agunit] > Epsilon
        write(io,"GCD",string(agunit)," <= ",string(round(AgEGC[agunit];digits = 2)),"\n")
      end
    end
  end

end

function PollutionConstraints(data::Data,io,timep,month)
  (; Node,AgNode) = data
  (; AgPOCGWh,AgEGC,Epsilon) = data
  (; PollLimit,HDHours) = data
  
  #
  # Pollution Constraint - Pollution must be less or equal to Pollution Limit
  #
  # Northwest Territories (NT) has negative net loads historically,
  # so do not execute for NT.  Jeff Amlin 1/2/15
  #
  nodes = Select(Node, !=("NT"))
  for node in nodes
    polls = findall(PollLimit[:,timep,month,node] .> 0)
    for poll in polls
      IsPollLimit = 0
      for agu in findall(AgNode .== Node[node])
        POCMW = AgPOCGWh[agu,poll]*HDHours[timep,month]/1000
        if (AgNode[agu] == Node[node]) && (AgEGC[agu] > Epsilon) && (POCMW > Epsilon)
          write(io,"+ ",string(POCMW)," GCD",string(agu),"\n")
          IsPollLimit = 1
        end # if
      end # AgUnit
      if IsPollLimit == 1
        write(io,"<= ",string(PollLimit[poll,timep,month,node]),"\n")
      end # if IsPollLimit
    end
  end

end

#
# Promula Procedure BottomOfLPInputFile not necessary in Julia
#

#
# Page 2 "Headlines"
#
function WriteLPInputFile(data::Data,timep,month)
  (; Node) = data
  #
  # print(" EDispatchLP.src,  WriteLPInputFile")
  #
  LPInput = TopOfLPInputFile(data,timep,month)

  write(LPInput,"MINIMIZE\n")

  CostOfGeneration(data,LPInput)
  CostOfEmergencyPower(data,LPInput)
  CostOfTransmission(data,LPInput,timep,month)

  io = open(LPInput,"a")
  write(io,"SUBJECT TO\n")

  #
  # Generation Balance Constraint
  #
  for node in Select(Node)
    GeneratingCapacityDispatched(data,io,node)
    PowerTransmitted(data,io,node,timep,month)
    EmergencyPower(io,node)
    PeakDemand(data,io,node,timep,month)
  end # for node

  TransmissionConstraints(data,io,timep,month)

  GenerationConstraints(data,io)

  PollutionConstraints(data,io,timep,month)

  write(io,"End\n")
  close(io)
  return (LPInput)
end

#
# Page 3 - RunLP
#
# Make a DOS call to execute the LP program
#
function RunLP(LPInput)

  # 
  #  Write (" EDispatchLP.src,  RunLP")
  # 
  LPName = LPInput[1:(end-3)] # remove ".lp" from string
  LPOutput = LPName*".dat"
  LPOut = LPName*".log"
  write(LPOutput," ")
  # run(`glpsol --cpxlp $LPInput --log $LPOut -o $LPOutput`)
  # run(`glpsol --cpxlp $LPInput -o $LPOutput \> $LPOut`)
  cmd = Cmd(`glpsol --cpxlp $LPInput --log $LPOut -o $LPOutput`,dir = E2020Folder)

  inp = Pipe()
  out = Pipe()
  err = Pipe()

  process = run(pipeline(cmd,stdin=inp,stdout=out,stderr=err),wait=false)
  close(out.in)
  close(err.in)
  stdout = @async String(read(out))
  stderr = @async String(read(err))
  write(process,"")
  close(inp)
  wait(process)
  if process isa Base.ProcessChain
    exitcode = maximum([p.exitcode for p in process.processes])
  else
    exitcode = process.exitcode
  end

  stdout = fetch(stdout)
  write(LPOut,stdout)
  stderr = fetch(stderr)
  # LPCom = "glpsol --cpxlp "*LPName*".lp -o "*LPName*".dat > "*LPName*".log"
  # Run Dos LPCom

end

#
# Page 4 - ReadLPOutputFile
#
# Read the output file generated by the LP program
#
function InitializeReadLPOutputFile(data::Data,timep,month)
  (; AgUnits,Units,Nodes,NodeXs) = data
  (; AgGCD,EmEGA,HDEmMDS,HDLLoad,HDPrA,UnEG,UnGCD) = data
  
  for agunit in AgUnits
    AgGCD[agunit] = 0.0
  end
  for node in Nodes
    EmEGA[node,timep,month] = 0.0
    HDEmMDS[node,timep,month] = 0.0
    HDPrA[node,timep,month] = 0.0
  end
  for nodex in NodeXs, node in Nodes
    HDLLoad[node,nodex,timep,month] = 0.0
  end 
  for unit in Units
    UnEG[unit,timep,month]  = 0.0
    UnGCD[unit,timep,month]= 0.0
  end
end

#
# Note: Promula Procedure CreateLPOutputFileName
# not required with current Julia structure
#

function OpenLPOutputFile(data::Data,LPFileName,timep,month)
  (; Month,Year,year) = data

  if !isfile(LPFileName)
    @error "File Does Not Exist: ",LPFileName,"\nPlease see info log."
    @info " "
    @info "In Time Period ",timep," ",Month[month]," ",Year[year]," inside"
    @info "EDispatchLP.jl in OpenLPOutputFile,the file ",LPFileName
    @info "does not exist.  This is the output file from the LP program"
    @info "which dispatches the electric generating units.  This error"
    @info "probably means that the LP was not able to solve the dispatch"
    @info "equations. Review the LPName.lp file for clues as to why the"
    @info "dispatch did not solve.  If you will find ****** for the peak"
    @info "load value,then the peak load is way too high. You may also "
    @info "see a NaN in the file "    
    @info "Jeff Amlin 10/13/2010 and 6/24/25"
  end

end

function ReadLine(line)
  #@debug line
  if length(line) < 29
    AName = APoint = APrimal = ADual = ""
  else
    AName = line[1:6]
    APoint = parse(Int,line[7:11])
    APrimal = parse(Float32,line[12:29])
    ADual = parse(Float32,line[30:end])
  end
  return (AName,APoint,APrimal,ADual)
end

function ExtractGeneration(data::Data,AName,APoint,APrimal)
  (; AgGCD) = data

  if AName == "   GCD" # Generation
    AgGCD[APoint] = APrimal
  end
end

function ExtractTransmissionLoads(data::Data,timep,month,AName,APoint,APrimal)
  (; HDLLoad) = data

  if AName == "   LLL" # Transmission Loads
    node = Int(round(APoint/100-0.49999))
    nodex = Int(APoint-node*100)
    HDLLoad[node,nodex,timep,month] = APrimal
  end
end

function ExtractPricesAndEmergencyPower(data::Data,timep,month,AName,APoint,APrimal,ADual)
  (; ExchangeRateNode,HDPrA,HDPrAUS,HDEmMDS,HDEmVCostUS) = data

  if AName == "   EMG" # Prices and Emergency Power
    node = APoint
    HDEmMDS[node,timep,month] = APrimal
    HDPrAUS[node,timep,month] =
      min(max(HDEmVCostUS[node,timep,month]-ADual,0),HDEmVCostUS[node,timep,month])
    HDPrA[node,timep,month] = HDPrAUS[node,timep,month]*ExchangeRateNode[node]
  end
end

function SaveOutputFromLP(data::Data)
  (; db,year) = data
  (; AgGCD,HDEmMDS,HDLLoad,HDPrA) = data

  WriteDisk(db,"EGOutput/AgGCD",AgGCD)
  WriteDisk(db,"EGOutput/HDEmMDS",year,HDEmMDS)
  WriteDisk(db,"EGOutput/HDLLoad",year,HDLLoad)
  WriteDisk(db,"EOutput/HDPrA",year,HDPrA)
end

#
# Page 4 "Headlines"
#
function ReadLPOutputFile(data::Data,timep,month)
  (; Month) = data

  #
  # Write (" EDispatchLP.src,  ReadLPOutputFile")
  #
  LPFileName = "LP"*Month[month]*string(timep)*".dat"
  LPFileName = joinpath(E2020Folder,"log",LPFileName)
  OpenLPOutputFile(data,LPFileName,timep,month)
  text = open(LPFileName,"r") do f
    readlines(f)
  end
  for line in text[3:end]
    (AName,APoint,APrimal,ADual) = ReadLine(line)
    ExtractGeneration(data,AName,APoint,APrimal)
    ExtractTransmissionLoads(data,timep,month,AName,APoint,APrimal)
    ExtractPricesAndEmergencyPower(data,timep,month,AName,APoint,APrimal,ADual)
  end

  SaveOutputFromLP(data)

end

#
# Page 5 - DisaggregateUnitsAfterDispatch
#
function DisaggregateCapacityDispatched(data::Data,timep,month)
  (; CTime,UnGCD,UnAgNum,AgEGC,UnEGC,AgGCD,Epsilon) = data
  
  #
  # Unit generating capacity dispatched (UnEGC) is the aggregate unit
  # capacity dispatched (AgGCD) times the fraction of the aggregate unit
  # capacity bid (AgEGC) represented by this unit (UnEGC).  The aggregate
  # unit pointer (UnAGNum) points to the aggregate unit of this unit.
  #
  units_utility = GetUtilityUnits(data)
  units_ag = findall(UnAgNum .> 0)
  units = intersect(units_utility,units_ag)
  for unit in units
    ag_unit = Int(UnAgNum[unit])
    if AgEGC[ag_unit] > Epsilon
      @finite_math UnGCD[unit,timep,month] = AgGCD[ag_unit]*UnEGC[unit,timep,month]/AgEGC[ag_unit]
    end
  end
end

function ConvertCapacityDispatchedToGeneration(data::Data,timep,month)
  (; Nodes,Units) = data
  (; UnEG,UnGCD,HDHours,EmEGA,HDEmMDS) = data

  for unit in Units
    UnEG[unit,timep,month] = UnGCD[unit,timep,month]*HDHours[timep,month]/1000
  end
  
  for node in Nodes
    EmEGA[node,timep,month] = HDEmMDS[node,timep,month]*HDHours[timep,month]/1000
  end
  
end

function SaveDisaggregateResults(data::Data)
  (; db,year) = data
  (; EmEGA,UnEG,UnGCD) = data

  WriteDisk(db,"EGOutput/UnGCD",year,UnGCD)
  WriteDisk(db,"EGOutput/UnEG",year,UnEG)
  WriteDisk(db,"EGOutput/EmEGA",year,EmEGA)
end

function DisaggregateUnitsAfterDispatch(data::Data,timep,month)
  
  DisaggregateCapacityDispatched(data,timep,month)
  ConvertCapacityDispatchedToGeneration(data,timep,month)
  SaveDisaggregateResults(data)
end

########################
#
# Front Page "Headlines"
#
########################

function ElectricDispatchLP(data::Data,timep,month)

  #@debug "EDispatchLP.jl - ElectricDispatchLP"

  AgNum = AggregateUnitsBeforeDispatch(data,timep,month)
  LPInput = WriteLPInputFile(data,timep,month)
  RunLP(LPInput)
  ReadLPOutputFile(data,timep,month)
  DisaggregateUnitsAfterDispatch(data,timep,month)

  #@debug "EDispatchLP.jl - ElectricDispatchLP - end"

end
