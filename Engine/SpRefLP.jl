#
# SpRefLP.jl -  Petroleum Refining LP segment.
#
# The ENERGY 2100 model and all associated software are 
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc. 
# � 2018 Systematic Solutions, Inc.  All rights reserved.
#

########################
#
# Page 1 - CreateLPInputFile - Create LP Input File
#
# Write a text file with data in the required format
# by the LP to simulate operation of the refineries
# and the transportation of the RPP.
#
########################

function TopOfLPInputFile(data)

  LPName="RfLP"
  LPName = joinpath(E2020Folder,"log",LPName)
  return LPName

end

function CostOfPurchasingCrudeOil(data,rfunits)
  (; Crudes) = data
  (; RfFPCrudeUS) = data

  io = open(LPInput,"a")
  for rfunit in rfunits, crude in Crudes
    CrudeNum=rfunit*100+crude
    write(io,"+",string(round(RfFPCrudeUS[rfunit,crude]; digits = 2))," GOilCD",string(CrudeNum),"\n")
  end  
  close(io)

end

function VariableProductionCost(data,rfunits)
  (; Crudes,Fuels) = data
  (; RfVCProdUS) = data

  io = open(LPInput,"a")
  for rfunit in rfunits, crude in Crudes, fuel in Fuels
    ProdNum=rfunit*10000+crude*100+fuel
    if (RfVCProdUS[rfunit,fuel,crude] > 0.0)
      write(io,"+",string(round(RfVCProdUS[rfunit,fuel,crude]; digits = 2))," Prd",string(ProdNum),"\n")
    elseif(RfVCProdUS[rfunit,fuel,crude] < 0.0)
      write(io,"   ",string(round(RfVCProdUS[rfunit,fuel,crude]; digits = 2))," Prd",string(ProdNum),"\n")
    end
  end
  close(io)

end

function EmergencySupplyCost(data)
  (; Fuels,GNodes) = data
  (; RfEmgPriceUS) = data

  io = open(LPInput,"a")
  for gnode in GNodes, fuel in Fuels
    EmgNum=gnode*100+fuel
    write(io,"+",string(round(RfEmgPriceUS[gnode,fuel]; digits = 2))," Emg",string(EmgNum),"\n")
  end
  close(io)
  
end

function TransportationCost(data)
  (; Fuels,GNodes,GNodeXs) = data
  (; RfTrMax,RfPathVCUS,Epsilon) = data

  io = open(LPInput,"a")
  for gnode in GNodes, gnodex in GNodeXs, fuel in Fuels
    PathNum=gnode*10000+gnodex*100+fuel
    if ((RfTrMax[gnode,gnodex] > Epsilon) ||
      ((RfTrMax[gnodex,gnode] > Epsilon))) &&
      (gnode != gnodex)
      write(io,"+",string(round(RfPathVCUS[gnode,gnodex]; digits = 3))," Emg",string(PathNum),"\n")
    end
  end
  close(io)

end

function RPPProduction(data,rfunits,io,fuel,gnode)
  (; Crudes,GNode) = data
  (; RfFPCrudeUS,RfNode) = data

  for rfunit in RfUnits
    if RfNode[rfunit] == GNode[gnode]
      for crude in Crudes
        ProdNum=rfunit*10000+crude*100+fuel
        write(io,"+","Prd",string(ProdNum),"\n")
      end
    end
  end
  
end

function TransportationFlows(data,io,fuel,gnode)
  (; GNodeXs) = data
  (; Epsilon,RfPathEff,RfTrMax) = data

  for gnodex in GNodeXs
    PathInNum=gnode*10000+gnodex*100+fuel
    PathOutNum=gnodex*10000+gnode*100+fuel   
    if ((RfTrMax[gnode,gnodex] > Epsilon) ||
      ((RfTrMax[gnodex,gnode] > Epsilon))) &&
      (gnode != gnodex)
      write(io,"+",string(round(RfPathEff[gnode,gnodex]; digits = 2))," Trn",string(PathInNum)," - Trn",string(PathOutNum),"\n")
    end
  end
  
end

function EmergencySupply(data,io,fuel,gnode)

  EmgNum=gnode*100+fuel
  write(io,"+","Emg",string(EmgNum),"\n")

end

function RPPDemands(data,fuel,gnode)
  (; RPPDem) = data

  write(io,">=",string(round(RPPDem[gnode,fuel]; digits = 4)),"\n")
  
end

function ProductionCapacityConstraint(data,rfunits,LPInput)
  (; Crudes,Fuels) = data
  (; RfCapEffective) = data

  #
  # RPP Production must be less than the effective RPP Production Capacity
  #
  io = open(LPInput,"a")
  for rfunit in RfUnits, crude in Crudes
    CrudeNum=rfunit*100+crude
    for fuel in Fuels
      ProdNum=rfunit*10000+crude*100+fuel
      write(io,"+","Prd",string(ProdNum),"\n")
    end
    write(io,">=",string(round(RfCapEffective[rfunit,fuel]; digits = 4)),"\n")
  end
  close(io)

end

function ProductionCapacityConstraintByFuel(data,LPInput)

  #
  # Note: Commented Out in Promula
  #
  # RPP Production by type of RPP must be less than the effective RPP
  # Production Capacity by type of RPP
  #
  #Do RfUnit
  #  Do Fuel
  #    Do Crude
  #      ProdNum=RfUnit:s*10000+Crude:s*100+Fuel:s
  #      Write LPInput(" + ",         " Prd",ProdNum::0)
  #    End Do Crude
  #    Write LPInput(" <= ",RfCapEffective)
  #  End Do Fuel
  #End Do RfUnit   
  
end

function MaximumYieldConstraint(data,rfunits,LPInput)
  (; Crudes,Fuels) = data
  (; RfMaxYield) = data

  #
  # RPP production must be less than the maximum yield for each type of RPP
  #
  io = open(LPInput,"a")
  for rfunit in rfunits, crude in Crudes
    CrudeNum=rfunit*100+crude
    for fuel in Fuels
      ProdNum=rfunit*10000+crude*100+fuel
      write(io,"+","Prd",string(ProdNum),"\n")
      write(io,"-",string(round(RfMaxYield[rfunit,fuel,crude]; digits = 4)),"Oil",string(CrudeNum),"\n")
      write(io," <= 0.0","\n")
    end
  end
  close(io)

end

function MinimumYieldConstraint(data,rfunits,LPInput)
  (; Crudes,Fuels) = data
  (; RfMinYield) = data

  #
  # RPP production must exceed the minimum yield for each type of RPP
  #
  io = open(LPInput,"a")
  for rfunit in rfunits, crude in Crudes
    CrudeNum = rfunit*100+crude
    for fuel in Fuels
      ProdNum = rfunit*10000+crude*100+fuel
      write(io,"+","Prd",string(ProdNum),"\n")
      write(io,"-",string(round(RfMinYield[rfunit,fuel,crude]; digits = 4)),"Oil",string(CrudeNum),"\n")
      write(io," >= 0.0","\n")
    end
  end
  close(io)

end

function CrudeOilCapacityConstraint(data,rfunits,LPInput)
  (; Crudes) = data
  (; RfCap) = data

  #
  # Crude Oil processed at each refinery must be less than the 
  # production capacity of each refinery.
  #
  io = open(LPInput,"a")
  for rfunit in rfunits, crude in Crudes
    CrudeNum=rfunit*100+crude
    write(io,"+","Oil",string(CrudeNum),"\n")
    write(io," <= ",string(round(RfCap[rfunit]; digits = 4)),"\n")
  end
  close(io)
  
end

function MaximumCrudeConstraint(data,LPInput)
  (; db,year) = data
  (; Crudes) = data
  (; RfCap,RfMaxCrude,RfCrudeLimit) = data

  #
  # Crude Oil processed by type of Crude Oil must be less than the 
  # maximum Crude Oil by type available to each refininery
  #
  for rfunit in rfunits, crude in Crudes
    RfCrudeLimitp[rfunit,crude]=RfMaxCrude[rfunit,crude]*RfCap[rfunit]
  end
  WriteDisk(db, "SpOutput/RfCrudeLimit", year, RfCrudeLimit)
  
  io = open(LPInput,"a")
  for rfunit in rfunits, crude in Crudes
    CrudeNum=rfunit*100+crude
    write(io,"+","Oil",string(CrudeNum),"\n")
    write(io," <= ",string(round(RfCrudeLimit[rfunit,crude]; digits = 4)),"\n")
  end
  close(io)

end

function RPPProductionCrudeConstraint(data,rfunits,LPInput)
  (; Crudes,Fuels) = data

  #
  # RPP Production (summed over RPP) must be less than
  # the Crude Oil processed.
  #
  io = open(LPInput,"a")
  for rfunit in rfunits, crude in Crudes
    CrudeNum=rfunit*100+crude
    for fuel in Fuels
      ProdNum=rfunit*10000+crude*100+fuel
      write(io,"+","Prd",string(ProdNum),"\n")
    end
    write(io,"-","Oil",string(CrudeNum),"\n")
    write(io," <= 0.0","\n")
  end
  close(io)
  
end

function TransportationConstraint(data,LPInput)
  (; Fuels,GNodes,GNodeXs) = data
  (; RfTrMax,RfPathVCUS,Epsilon) = data

  #
  # RPP flows are constrained by Transportation path capacity 
  #

  io = open(LPInput,"a")
  for gnode in GNodes, gnodex in GNodeXs
    if RfTrMax[gnode,gnodex] > 0
      for  fuel in Fuels
        PathNum=gnode*10000+gnodex*100+fuel
        write(io,"+","Trn",string(PathNum),"\n")
      end
      write(io," <= ",string(round(RfTrMax[gnode,gnodex]; digits = 4)),"\n")
    end
  end
  close(io)

end

function CreateLPInputFile(data,rfunits)

  #
  # Page 1 "Headlines"
  #
  # @info "Petroleum Refining Write LP Input File in SpRefLP.jl"
  #
  LPInput = TopOfLPInputFile(data)
  #
  # Minimize the cost of supplying RPP to Canada and US
  #
  write(LPInput,"MINIMIZE\n")
  #
  CostOfPurchasingCrudeOil(data,rfunits,LPInput)
  VariableProductionCost(data,rfunits,LPInput)
  TransportationCost(data,LPInput)
  EmergencySupplyCost(data,LPInput)
  # 
  io = open(LPInput,"a")
  write(io,"SUBJECT TO\n")
  #
  # Supply and Demand Balance
  #
  for fuel in Fuels, gnode in GNodes
    RPPProduction(data,rfunits,io,fuel,gnode)
    TransportationFlows(data,io,fuel,gnode)
    EmergencySupply(data,io,fuel,gnode)
    RPPDemands(data,io,fuel,gnode)
  end
  #
  ProductionCapacityConstraint(data,rfunits,LPInput)
  #ProductionCapacityConstraintByFuel(data,LPInput)
  MaximumYieldConstraint(data,rfunits,LPInput)
  MinimumYieldConstraint(data,rfunits,LPInput)
  CrudeOilCapacityConstraint(data,rfunits,LPInput)
  MaximumCrudeConstraint(data,LPInput)
  RPPProductionCrudeConstraint(data,rfunits,LPInput)
  TransportationConstraint(data,LPInput)
  #
  write(io,"End")
  close(io)
  return (LPInput)
  
end

########################
#
# Page 2 - Execute LP Program - make DOS call to 
# execute the LP program.
#
########################


function ExecuteLP(LPInput)
  # Define Procedure ExecuteLP
  # *
  # Clear LPInput
  # DBClose
  # *
  # LPCom="glpsol --cpxlp "+LPName+".lp -o "+LPName+".dat > "+LPName+".log"
  # *
  # Run Dos LPCom
  # *
  # DBOpen
  # *
  # End Procedure ExecuteLP


  # NOTE: TODO: Copied from EDispatchLP.jl. Needs a second look.

  # 
  #  Write (" SpRefLP.jl,  ExecuteLP")
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

########################
#
# Page 3 - Read LP Output File
#
########################

function InitializeReadLPOutputFile(data)
  (; RfProd,RfCrude) = data

  @. RfProd=0.0
  @. RfCrude=0.0 
  
end

function CreateLPOutputFileName(data,LPName)

  LPFileName=LPName+".dat"
  LPFileName = joinpath(E2020Folder,"log",LPFileName)
  return LPName

end

function OpenLPOutputFile(LPFileName)

  if !isfile(LPFileName)
    @error "File Does Not Exist ",LPFileName,"\nPlease see ErrorLog.log."
    @info (" ")  
    @info ("Inside SpRef.src in procedure LPRead, the file ",LPFileName::0)
    @info ("does not exist.  This is the output file from the LP program")
    @info ("which dispatches refineries.  This error probably means that")
    @info ("the LP was not able to solve.  Review the RfLP.lp file")
    @info ("for clues as to why.  If you find ****** in the file")
    @info ("that is probably the problem. - Jeff Amlin 03/14/2012 ")
  end
  
end

function ReadLine(line)
  #@debug line
  if length(line) < 3
    AName = line[1:6]
    APoint = APrimal = ADual = ""
  else
    AName = line[1:6]
    APoint = parse(Int,line[7:15])
    APrimal = parse(Float32,line[16:28])
    ADual = parse(Float32,line[29:end])
  end
  return (AName,APoint,APrimal,ADual)
  
end

function ExtractRefineryProduction(data,AName,APoint,APrimal)
  (; RfProd) = data

  if AName == "   Prd"
    RfNum = Int(round(APoint/10000-.49999))
    CrudeNum = Int(round((APoint-RfNum*10000)/100-.49999))
    RPPNum = Int(APoint-RfNum*10000-CrudeNum*100)
    RfProd[RfNum,RPPNum] = RfProd[RfNum,RPPNum]+APrimal
  end

end

function ExtractCrudeOilUsed(data,AName,APoint,APrimal)
  (; RfCrude) = data

  if AName == "   Oil"
    RfNum=Int(round(APoint/100-.49999))
    CrudeNum=Int(APoint-RfNum*100)  
    RfCrude[RfNum,CrudeNum]=APrimal
  end
  
end

function ExtractTransportationFlows(data,AName,APoint,APrimal)
  (; RPPFlows) = data

  if AName == "   Trn"
    NodeNum =  Int(round( APoint         /10000              -.49999))
    NodeXNum = Int(round((APoint-NodeNum*10000)        /100  -.49999))
    RPPNum =   Int(round((APoint-NodeNum*10000-NodeXNum*100)))
    RPPFlows[NodeNum,NodeXNum,RPPNum] = APrimal
  end
  
end

function ExtractPricesAndEmergencySupply(data,AName,APoint,APrimal,ADual)
  (; RfEmgPriceUS,RPPEmgSupply,RPPNodePriceUS) = data

  if AName == "   Emg"
    NodeNum = Int(round(APoint/100-.49999))
    RPPNum  = Int(APoint-NodeNum*100)
    RPPEmgSupply[NodeNum,RPPNum] = APrimal
    RPPNodePriceUS[NodeNum,RPPNum]=min(max(RfEmgPriceUS[NodeNum,RPPNum]-ADual,0),
                                       RfEmgPriceUS[NodeNum,RPPNum])
  end
  
end

function SaveOutputFromLP(data)
  (; db,year) = data
  (; RfProd,RfCrude,RPPEmgSupply,RPPNodePriceUS,RPPFlows) = data

  WriteDisk(db, "SpOutput/RfProd", year, RfProd)
  WriteDisk(db, "SpOutput/RfCrude", year, RfCrude)
  WriteDisk(db, "SpOutput/RPPEmgSupply", year, RPPEmgSupply)
  WriteDisk(db, "SpOutput/RPPNodePriceUS", year, RPPNodePriceUS)
  WriteDisk(db, "SpOutput/RPPFlows", year, RPPFlows)

end

########################
#
# Page 3 - "Headlines"
#

function ReadLPOutputFile(data,LPName)

  InitializeReadLPOutputFile(data)

  LPFileName=CreateLPOutputFileName(LPName)
  OpenLPOutputFile(LPFileName)

  text = open(LPFileName,"r") do f
    readlines(f)
  end
  for line in text[3:end]
    (AName,APoint,APrimal,ADual) = ReadLine(line)
    ExtractRefineryProduction(data,AName,APoint,APrimal)
    ExtractCrudeOilUsed(data,AName,APoint,APrimal)
    ExtractTransportationFlows(data,AName,APoint,APrimal)
    ExtractPricesAndEmergencySupply(data,AName,APoint,APrimal,ADual)
  end

  SaveOutputFromLP(data)
  
end

function RPPProductionLP(data)
  (; Epsilon,RfCap) = data

  ########################
  #
  # Front Page "Headlines"
  #
  # @info "Petroleum Refining LP Control in SpRefLP.jl"
  #
  rfunits=findall(RfCap[:] .> Epsilon)
  if !isempty(rfunits)
    LPInput = CreateLPInputFile(data,rfunits)
    ExecuteLP(LPInput)
    ReadLPOutputFile(data,LPName)
  end
  
end

