#
# UnitPermits.jl
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

Base.@kwdef struct UnitPermitsData
  db::String

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db,"MainDB/Unit")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  InflationUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationUnit") # [Unit,Year] Inflation Index ($/$)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  UnCode::Vector{String} = ReadDisk(db,"EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnCoverage::VariableArray{3} = ReadDisk(db,"EGInput/UnCoverage") # [Unit,Poll,Year] Fraction of Unit Covered in Emission Market (1=100% Covered)
  UnDmd::VariableArray{3} = ReadDisk(db,"EGOutput/UnDmd") # [Unit,FuelEP,Year] Energy Demands (TBtu)
  UnEGA::VariableArray{2} = ReadDisk(db,"EGOutput/UnEGA") # [Unit,Year] Generation (GWh)
  UnFlFr::VariableArray{3} = ReadDisk(db,"EGOutput/UnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnGC::VariableArray{2} = ReadDisk(db,"EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnGP::VariableArray{4} = ReadDisk(db,"EGOutput/UnGP") #[Unit,FuelEP,Poll,Year]  Unit Intensity Target or Gratis Permits (kg/MWh)
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") #[Unit,Year]  Heat Rate (BTU/KWh)
  UnName::Vector{String} = ReadDisk(db,"EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db,"EGInput/UnNode") #[Unit]  Transmission Node
  UnOffsets::VariableArray{3} = ReadDisk(db,"EGInput/UnOffsets") # [Unit,Poll,Year] Offsets (Tonnes/GWh) 
  UnOffValue::VariableArray{3} = ReadDisk(db,"EGOutput/UnOffValue") #[Unit,Poll,Year]  Offset Value ($/MWh)
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPGratis::VariableArray{3} = ReadDisk(db,"EGOutput/UnPGratis") # [Unit,Poll,Year] Gratis Permits (Tonnes/Yr)
  UnPlant::Vector{String} = ReadDisk(db,"EGInput/UnPlant") #[Unit]  Plant Type
  UnPOCA::VariableArray{4} = ReadDisk(db,"EGOutput/UnPOCA") #[Unit,FuelEP,Poll,Year]  Pollution Coefficient (Tonnes/TBtu)
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)
  UnPol::VariableArray{4} = ReadDisk(db,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution (Tonnes)
  UnPoTR::VariableArray{2} = ReadDisk(db,"EGOutput/UnPoTR") #[Unit,Year]  Pollution Tax Rate ($/MWh)
  UnPoTRExo::VariableArray{2} = ReadDisk(db,"EGInput/UnPoTRExo") # [Unit,Year] Exogenous Pollution Tax Rate (Real $/MWh)
  UnPoTxR::VariableArray{4} = ReadDisk(db,"EGOutput/UnPoTxR") #[Unit,FuelEP,Poll,Year]  Marginal Pollution Tax Rate ($/MWh)
 
  #
  # Scratch Variables
  #
  Un1Coverage = zeros(Float32,length(Unit)) # Fraction of Unit Covered in Emission Market (1=100% Covered)

  Un1GP = zeros(Float32,length(Unit)) 
  Un1Offsets = zeros(Float32,length(Unit))   
  Un1OffValue = zeros(Float32,length(Unit))   
  Un1PCX = zeros(Float32,length(Unit)) 
  Un1PGratis = zeros(Float32,length(Unit))   
  Un1POCA = zeros(Float32,length(Unit)) 
  Un1POCHR = zeros(Float32,length(Unit)) 
  Un1Pol = zeros(Float32,length(Unit)) 
  Un1PoTxR = zeros(Float32,length(Unit)) 
  UnGCMax = zeros(Float32,length(Unit)) # 'Maximum Unit Capacity (MW)'
  UnPOCHR = zeros(Float32,length(Unit),length(FuelEP),length(Poll))
  #
  ZZZ = zeros(Float32,length(Year))  
end

function UnitPermits_DtaRun(data,polls,year,PollName)
  (; SceName,FuelEP,FuelEPs,Poll,Polls,Unit,Units,Year,Years) = data
  (; InflationUnit,PolConv,UnCode,UnCogen,UnCoverage,UnDmd,UnEGA,UnFlFr,UnGC) = data
  (; UnGP,UnHRt,UnName,UnNode,UnOffsets,UnOffValue,UnOnLine) = data
  (; UnPlant,UnPGratis,UnPOCA,UnPOCX,UnPol,UnPoTR,UnPoTRExo,UnPoTxR) = data
  (; UnGCMax,UnPOCHR,Un1POCHR,Un1Pol,Un1PoTxR,Un1POCA,Un1PCX,Un1PGratis,Un1GP) = data
  (; UnGCMax,Un1Coverage,Un1Offsets,Un1OffValue,ZZZ) = data

  CO2 = Select(Poll,"CO2")
  # CO2 = 7

  iob = IOBuffer()
  print(iob,"Unit Code;Name;Plant Type;Node;Ind Cogen;Online Date;")
  print(iob,"Market Coverage (1=Covered);",
      "Gratis Permits (Tonnes);",
      "Gratis Permits (kg/MWh);",
      "Generation (GWh);",
      "Pollution (Tonnes);",
      "Coefficient (kg/MWh);",
      "Coefficient (Tonnes/TBtu);",
      "Heat Rate (Btu/KWh);",
      "UnOffsets Offsets (kg/MWh);",       
      "UnOffValue Offset (\$/MWh);",     
      "UnPoTxR Marginal Pollution Tax Rate (\$/MWh);",
      "UnPoTR Pollution Tax Rate (\$/MWh);",
      "UnPoTRExo Exogenous Pollution Tax Rate (\$/MWh);")
  println(iob)

  for unit in Units
     UnGCMax[unit] = maximum(UnGC[unit,y] for y in Years)
         
     Un1Coverage[unit] = UnCoverage[unit,CO2,year]
     Un1Offsets[unit] = UnOffsets[unit,CO2,year]
     Un1OffValue[unit] = UnOffValue[unit,CO2,year]
  
    # if UnGCMax[unit] > 0.0
    
      Un1PGratis[unit] = sum(UnPGratis[unit,poll,year]*PolConv[poll]
        for poll in polls)
    
      #
      # kg/MWh
      #
      for fuelep in FuelEPs, poll in polls
        UnPOCHR[unit,fuelep,poll] = UnPOCA[unit,fuelep,poll,year]*UnHRt[unit,year]/1e6
      end
      #
      # Remove FuelEP
      #
      Un1POCHR[unit] = sum(UnPOCHR[unit,fuelep,poll]*PolConv[poll]*
        UnFlFr[unit,fuelep,year] for fuelep in FuelEPs, poll in polls)
        
      Un1Pol[unit] = sum(UnPol[unit,fuelep,poll,year]*PolConv[poll]
        for fuelep in FuelEPs, poll in polls)
      
      Un1PoTxR[unit] = sum(UnPoTxR[unit,fuelep,poll,year]*PolConv[poll]*
        UnFlFr[unit,fuelep,year] for fuelep in FuelEPs, poll in polls)
        
      Un1POCA[unit] = sum(UnPOCA[unit,fuelep,poll,year]*PolConv[poll]*
        UnFlFr[unit,fuelep,year] for fuelep in FuelEPs, poll in polls)
      #
      UnPoTRExo[unit,year] = UnPoTRExo[unit,year]*InflationUnit[unit,year]
    # end
    #
    # If unit burns fuel, then gratis permits may vary by fuel.
    #
    if sum(UnFlFr[unit,fuelep,year] for fuelep in FuelEPs) > 0.0
      Un1GP[unit] = sum(UnGP[unit,fuelep,poll,year]*PolConv[poll]*
        UnFlFr[unit,fuelep,year] for fuelep in FuelEPs, poll in polls)
    #
    # Else unit does not burn fuel, so use UnGP in first FuelEP slot.
    # This addesses the offsets for renewables and nuclear
    #
    else
      Un1GP[unit] = sum(UnGP[unit,1,poll,year]*PolConv[poll]
        for poll in polls)
    end    
  end

  for unit in Units
    # if UnGCMax[unit] > 0.0
      print(iob,UnCode[unit])
      print(iob,";",UnName[unit])
      print(iob,";",UnPlant[unit])
      print(iob,";",UnNode[unit])
      print(iob,";",Int(UnCogen[unit]))
      print(iob,";",@sprintf("%.0f",UnOnLine[unit]))
      print(iob,";",@sprintf("%.1f",Un1Coverage[unit]))      
      print(iob,";",@sprintf("%.0f",Un1PGratis[unit]))
      print(iob,";",@sprintf("%.3f",Un1GP[unit]))
      print(iob,";",@sprintf("%.3f",UnEGA[unit,year]))
      print(iob,";",@sprintf("%.3f",Un1Pol[unit]))
      print(iob,";",@sprintf("%.3f",Un1POCHR[unit]))
      print(iob,";",@sprintf("%.3f",Un1POCA[unit]))
      print(iob,";",@sprintf("%.0f",UnHRt[unit,year]))
      print(iob,";",@sprintf("%.3f",Un1Offsets[unit]))
      print(iob,";",@sprintf("%.3f",Un1OffValue[unit]))
      print(iob,";",@sprintf("%.3f",Un1PoTxR[unit]))
      print(iob,";",@sprintf("%.3f",UnPoTR[unit,year]))
      print(iob,";",@sprintf("%.3f",UnPoTRExo[unit,year]))
      println(iob)
    # end
  end
 
  filename = "UnitPermits-$(PollName)-$(Year[year])-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end
end

function UnitPermits_DtaControl(db)
  @info "UnitPermits_DtaControl"
  data = UnitPermitsData(; db)
  (; Poll) = data

  #
  # CO2 Permits
  #
  polls = Select(Poll,["CO2"])
  PollName = "CO2"
  years = [Yr(2015),Yr(2020),Yr(2025),Yr(2030),Yr(2040),Yr(2050)]
  for year in years
    UnitPermits_DtaRun(data,polls,year,PollName)
  end

  #
  # GHG Permits (all permits are currently in CO2)
  #
  #polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  #PollName = "GHG"
  #years = [Yr(2015),Yr(2020),Yr(2025),Yr(2030),Yr(2040),Yr(2050)]
  #for year in years
  #  UnitPermits_DtaRun(data,polls,year,PollName)
  #end

end

if abspath(PROGRAM_FILE) == @__FILE__
UnitPermits_DtaControl(DB)
end
