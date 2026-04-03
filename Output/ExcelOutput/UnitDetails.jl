#
# UnitDetails.jl
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

Base.@kwdef struct UnitDetailsData
  db::String
  
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))

  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))

  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))

  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))

  TimeP::SetArray = ReadDisk(db, "MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))

  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))

  Year::SetArray = ReadDisk(db, "MainDB/YearKey")

  # Yr2010 = 2010 - ITime + 1
  Yr2010 = 2010 - 1985 + 1
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  CCR::VariableArray{3} = ReadDisk(db, "EGOutput/CCR") # [Plant,Area,Year] Capital Charge Rate (1/Yr)
  DPRSL::VariableArray{2} = ReadDisk(db, "EGInput/DPRSL") # [Area,Year] Straight Line Depreciation Rate (1/Yr)
  ECFPFuel::VariableArray{3} = ReadDisk(db,"EGOutput/ECFPFuel") #[FuelEP,Area,Year]  Fuel Price ($/mmBtu)
  ECFPMonth::VariableArray{4} = ReadDisk(db,"EGOutput/ECFPMonth") #[FuelEP,Month,Area,Year]  Monthly Fuel Price ($/mmBtu)
  InflationUnit::VariableArray{2} = ReadDisk(db, "MOutput/InflationUnit") # [Unit,Year] Inflation Index
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") # [Area] Descriptor for Monetary Units Type=String(15)
  UnAFC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAFC") # [Unit,Year] Average Fixed Costs ($/KW) 
  UnArea::Vector{String} = ReadDisk(db, "EGInput/UnArea") # [Unit] Area Type=String(15)
  UnAVC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAVC") # [Unit,Year] Average Variable Costs ($/MWh)
  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") # [Unit] Unit Code Type=String(20)
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") # [Unit] Industrial Generation Switch (1=Industrial Generation)
  UnCUC::VariableArray{2} = ReadDisk(db, "EGOutput/UnCUC") # [Unit,Year] Capacity Under Construction (MW)
  UnCW::VariableArray{2} = ReadDisk(db, "EGOutput/UnCW") # [Unit,Year] Construction Costs ($M/Yr)
  UnCWAC::VariableArray{2} = ReadDisk(db, "EGOutput/UnCWAC") # [Unit,Year] Construction Costs Accumulated ($M)
  UnCWGA::VariableArray{2} = ReadDisk(db, "EGOutput/UnCWGA") # [Unit,Year] Construction Costs to Gross Assets ($M) 
  UnDmd::VariableArray{3} = ReadDisk(db, "EGOutput/UnDmd") # [Unit,FuelEP,Year] Energy Demands (TBtu) 
  UnEG::VariableArray{4} = ReadDisk(db, "EGOutput/UnEG") # [Unit,TimeP,Month,Year] Generation (GWh) 
  UnEGA::VariableArray{2} = ReadDisk(db, "EGOutput/UnEGA") # [Unit,Year] Generation (GWh) 
  UnEGGross::VariableArray{2} = ReadDisk(db, "EGOutput/UnEGGross") # [Unit,Year] Gross Generation (GWh/Yr)
  UnFlFr::VariableArray{3} = ReadDisk(db,"EGOutput/UnFlFr") # [Unit,FuelEP,Year]  Fuel Fraction (Btu/Btu)
  UnFP::VariableArray{3} = ReadDisk(db, "EGOutput/UnFP") # [Unit,Month,Year] Fuel Price ($/mmBtu)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") # [Unit,Year] Generating Capacity (MW) 
  UnGCCC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGCCC") # [Unit,Year] Generating Unit Capital Cost (Real $/Kw)
  UnGCCE::VariableArray{2} = ReadDisk(db, "EGOutput/UnGCCE") # [Unit,Year] Endogenous Generating Capacity Completed (MW)
  UnGCCI::VariableArray{2} = ReadDisk(db, "EGOutput/UnGCCI") # [Unit,Year] Generating Capacity Initiated (MW)
  UnGCCR::VariableArray{2} = ReadDisk(db, "EGOutput/UnGCCR") # [Unit,Year] Generating Capacity Completed (MW) 
  UnGCNet::VariableArray{2} = ReadDisk(db, "EGOutput/UnGCNet") # [Unit,Year] Net Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db, "EGInput/UnGenCo") # [Unit] Generating Company Type=String(15)
  UnHRt::VariableArray{2} = ReadDisk(db, "EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnNA::VariableArray{2} = ReadDisk(db, "EGOutput/UnNA") # [Unit,Year] Net Asset Value of Generating Unit (M$) 
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") # [Unit] Plant Name Type=String(30)
  UnLife::VariableArray{2} = ReadDisk(db, "EGOutput/UnLife") # [Unit,Year] Number of years for Unit to Operate (years)
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") # [Unit] Transmission Node Type=String(15)
  UnOR::VariableArray{4} = ReadDisk(db, "EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnOUEG::VariableArray{2} = ReadDisk(db, "EGOutput/UnOUEG") # [Unit,Year] Own Use Generation (GWh/Yr)
  UnOUGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnOUGC") # [Unit,Year] Own Use Generating Capacity (MW)
  UnOUREG::VariableArray{2} = ReadDisk(db, "EGInput/UnOUREG") # [Unit,Year] Own Use Rate for Generation (MW/MW)
  UnOURGC::VariableArray{2} = ReadDisk(db, "EGInput/UnOURGC") # [Unit,Year] Own Use Rate for Generating Capacity (MW/MW)
  UnPCF::VariableArray{2} = ReadDisk(db, "EGOutput/UnPCF") # [Unit,Year] Unit Capacity Factor (MW/MW)
  UnPCFuu::VariableArray{2} = ReadDisk(db, "EGOutput/UnPCFuu") # [Unit,Year] Unit Capacity Factor (MW/MW)
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") # [Unit] Plant Type Type=String(15)
  UnPoTR::VariableArray{2} = ReadDisk(db, "EGOutput/UnPoTR") # [Unit,Year] Pollution Tax Rate ($/MWh)
  UnPoTRExo::VariableArray{2} = ReadDisk(db, "EGInput/UnPoTRExo") # [Unit,Year] Exogenous Pollution Tax Rate (Real $/MWh)
  UnPRCost::VariableArray{2} = ReadDisk(db, "EGOutput/UnPRCost") # [Unit,Year] Levelized Cost of Unit with Pollution Reduction Equipment ($/MWh)
  UnRCGA::VariableArray{2} = ReadDisk(db, "EGOutput/UnRCGA") # [Unit,Year] Emission Reduction Capital Costs (M$/Yr)
  UnRCOM::VariableArray{2} = ReadDisk(db, "EGOutput/UnRCOM") # [Unit,Year] Emission Reduction O&M Costs (M$/Yr)
  UnRes::VariableArray{2} = ReadDisk(db, "EGOutput/UnRes") # [Unit,Year] Generation while Unit is Forced On to Provide Reserves (GWh)
  UnRetire::VariableArray{2} = ReadDisk(db, "EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  UnSLDPR::VariableArray{2} = ReadDisk(db, "EGOutput/UnSLDPR") # [Unit,Year] Depreciation (M$/Yr)
  UnUFOMC::VariableArray{2} = ReadDisk(db, "EGInput/UnUFOMC") # [Unit,Year] Fixed O&M Costs ($/Kw/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db, "EGInput/UnUOMC") # [Unit,Year] Variable O&M Costs ($/Kw/Yr)
  UnXSw::VariableArray{2} = ReadDisk(db, "EGInput/UnXSw") # [Unit,Year] Exogneous Unit Data Switch (0=Exogenous)
  WCC::VariableArray{2} = ReadDisk(db, "EGInput/WCC") # [Area,Year] Weighted Cost of Capital (1/Yr)
  xUnGC::VariableArray{2} = ReadDisk(db, "EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)
  xUnGCCI::VariableArray{2} = ReadDisk(db, "EGInput/xUnGCCI") # [Unit,Year] Exogenous Generating Capacity Initiated (MW) 
  xUnGCCR::VariableArray{2} = ReadDisk(db, "EGInput/xUnGCCR") # [Unit,Year] Exogenous Generating Capacity Completion Rate (MW) 
end

function UnitDetails_DtaRun(data,unit,UnitCode,area,plant)
  (; Area,AreaDS,Areas,FuelEP,FuelEPDS,FuelEPs,Month,MonthDS,Months) = data
  (; Plant,PlantDS,Plants,TimeP,TimePs,Unit,Year,Yr2010) = data
  (; CCR,DPRSL,ECFPFuel,ECFPMonth,InflationUnit,MoneyUnitDS,UnAFC,UnArea) = data
  (; UnAVC,UnCode,UnCogen,UnCUC,UnCW,UnCWAC,UnCWGA,UnDmd) = data
  (; UnEG,UnEGA,UnEGGross,UnFlFr,UnFP,UnGC,UnGCCC,UnGCCE,UnGCCI) = data
  (; UnGCCR,UnGCNet,UnGenCo,UnHRt,UnNA,UnName,UnLife) = data
  (; UnNode,UnOR,UnOUEG,UnOUGC,UnOUREG,UnOURGC,UnPCF) = data
  (; UnPCFuu,UnPlant,UnPoTR,UnPoTRExo,UnPRCost,UnRCGA) = data
  (; UnRCOM,UnRes,UnRetire,UnSLDPR,UnUFOMC,UnUOMC,UnXSw) = data
  (; WCC,xUnGC,xUnGCCI,xUnGCCR,SceName) = data

  UnACE = zeros(Float32, length(Unit), length(Year))
  ZZZ = zeros(Float32, length(Year))

  years = Select(Year, (from = "1985", to = "2050")) 
 
  iob = IOBuffer() 

  println(iob, "$SceName; is the scenario name.")
  println(iob, "UnitDetails-$UnitCode-$SceName.dta")
  println(iob, "Unit Code is $UnitCode.  Name is ",UnName[unit],".")
  println(iob, "Area is ",UnArea[unit],".  Plant type is ",UnPlant[unit],".  Node is ",UnNode[unit],".")
  println(iob, " ")
  print(iob, "Year;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  println(iob, " ")

  print(iob, "Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "UnGCNet; Net Generating Capacity (MW)")
  for year in years
    ZZZ[year] = UnGCNet[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnOUGC; Own Use Generating Capacity (MW)")
  for year in years
    ZZZ[year] = UnOUGC[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnGC; Gross Generating Capacity (MW)")
  for year in years
    ZZZ[year] = UnGC[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnCUC; Capacity Under Construction (MW)")
  for year in years
    ZZZ[year] = UnCUC[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnGCCI; Capacity Initiated (MW)")
  for year in years
    ZZZ[year] = UnGCCI[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnGCCR; Generating Capacity Completed (MW)")
  for year in years
    ZZZ[year] = UnGCCR[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnGCCE; Endogenous Generating Capacity Completed (MW)")
  for year in years
    ZZZ[year] = UnGCCE[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xUnGC; Exogenous Generating Capacity (MW)")
  for year in years
    ZZZ[year] = xUnGC[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xUnGCCI; Exogenous Generating Capacity Initiated (MW)")
  for year in years
    ZZZ[year] = xUnGCCI[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xUnGCCR; Exogenous Generating Capacity Completed (MW)")
  for year in years
    ZZZ[year] = xUnGCCR[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  ##########

  print(iob, "Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "UnEGA; Net Generation (GWh)")
  for year in years
    ZZZ[year] = UnEGA[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnOUEG; Own Use Generation (GWh)")
  for year in years
    ZZZ[year] = UnOUEG[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnEGGross; Gross Generation (GWh)")
  for year in years
    ZZZ[year] = UnEGGross[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnRes; Generation while Unit is Forced On to Provide Reserves (GWh)")
  for year in years
    ZZZ[year] = UnRes[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  ##########

  print(iob, "Capital Costs;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "UnGCCC; Overnight Capital Costs (2010 CN\$/Kw)")
  for year in years
    @finite_math ZZZ[year] = UnGCCC[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnCW; Annual Construction Expenditures (2010 MCN\$)")
  for year in years
    @finite_math ZZZ[year] = UnCW[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  # print(iob, "UnCWAC; Construction Costs Accumulated (2010 MCN\$)")
  # for year in years
  #   @finite_math ZZZ[year] = UnCWAC[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
  #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  # end
  # println(iob)

  print(iob, "UnCWGA; Construction Cost (2010 MCN\$)")
  for year in years
    @finite_math ZZZ[year] = UnCWGA[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnRCGA; Emission Reduction Capital Costs (2010 MCN\$/Yr)")
  for year in years
    @finite_math ZZZ[year] = UnRCGA[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnNA; Net Assets (2010 MCN\$)")
  for year in years
    @finite_math ZZZ[year] = UnNA[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  ##########

  print(iob, "Annual Cost of Power;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "UnReturn; Return on Assets (2010 MCN\$)")
  for year in years
    @finite_math ZZZ[year] = UnNA[unit,year]*CCR[plant,area,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnSLDPR; Depreciation (2010 MCN\$)")
  for year in years
    @finite_math ZZZ[year] = UnSLDPR[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnOMC; Variable O&M Cost (2010 M\$)")
  for year in years
    @finite_math ZZZ[year] = UnUOMC[unit,year]*UnEGA[unit,year]*InflationUnit[unit,Yr2010]/1000
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnFOMC; Fixed O&M Cost (2010 M\$)")
  for year in years
    @finite_math ZZZ[year] = UnUFOMC[unit,year]*UnGC[unit,year]*InflationUnit[unit,Yr2010]/1000
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnRCOM; Emission Reduction O&M Costs (2010 MCN\$/Yr)")
  for year in years
    @finite_math ZZZ[year] = UnRCOM[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  ##########

  print(iob, "Unit Cost of Power;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)


  print(iob, "UnACE; Average Cost of Power (2010 ",MoneyUnitDS[area],"/MWh)")
  for year in years
    @finite_math UnACE[unit,year]=UnAFC[unit,year]*UnGC[unit,year]/UnEGA[unit,year]+UnAVC[unit,year]
    @finite_math ZZZ[year] = UnACE[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnReturn; Return on Assets (2010 ",MoneyUnitDS[area],"/MWh)")
  for year in years
    @finite_math ZZZ[year] = UnNA[unit,year]*CCR[plant,area,year]/UnEGA[unit,year]*1000/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnSLDPR; Depreciation (2010 ",MoneyUnitDS[area],"/MWh)")
  for year in years
    @finite_math ZZZ[year] = UnSLDPR[unit,year]/UnEGA[unit,year]*1000/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnUFOMC; Fixed O&M Costs (2010 ",MoneyUnitDS[area],"/MWh)")
  for year in years
    @finite_math ZZZ[year] = UnUFOMC[unit,year]*UnGC[unit,year]/UnEGA[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnUOMC; Variable O&M Costs (2010 ",MoneyUnitDS[area],"/MWh)")
  for year in years
    @finite_math ZZZ[year] = UnUOMC[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnFP; Fuel Costs (2010 ",MoneyUnitDS[area],"/MWh)")
  for year in years
    @finite_math ZZZ[year] = sum(UnFP[unit,month,year]*UnHRt[unit,year]/1000*UnEG[unit,timep,month,year] for month in Months, timep in TimePs)/
        UnEGA[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnPoTR; Pollution Tax Rate (2010 ",MoneyUnitDS[area],"/MWh)")
  for year in years
    @finite_math ZZZ[year] = UnPoTR[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnPoTRExo; Exogenous Pollution Tax Rate (Real 2010 ",MoneyUnitDS[area],"/MWh)")
  for year in years
    @finite_math ZZZ[year] = UnPoTRExo[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  ##########

  print(iob, "Unit Cost of Power, Support Variables;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "UnAVC; Average Variable Costs (2010 ",MoneyUnitDS[area],"/MWh)")
  for year in years
    @finite_math ZZZ[year] = UnAVC[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnAFC; Average Fixed Costs (\$/KW/Yr)")
  for year in years
    @finite_math ZZZ[year] = UnAVC[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnUFOMC; Fixed O&M Costs (2010 ",MoneyUnitDS[area],"/Kw/Yr)")
  for year in years
    @finite_math ZZZ[year] = UnUFOMC[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "DPRSL; Depreciation Rate (\$/(\$/Yr))")
  for year in years
    ZZZ[year] = DPRSL[area,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "CCR; Capital Charge Rate (\$/(\$/Yr))")
  for year in years
    ZZZ[year] = CCR[plant,area,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "WCC; Weighted Cost of Capital (\$/(\$/Yr))")
  for year in years
    ZZZ[year] = WCC[area,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnFP; Fuel Price (",MoneyUnitDS[area],"\$/mmBtu)")
  for year in years
    @finite_math ZZZ[year] = sum(UnFP[unit,month,year]*UnEG[unit,timep,month,year] for month in Months, timep in TimePs)/
        UnEGA[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnPRCost; Cost with Pollution Reductions ",MoneyUnitDS[area],"\$/MWh)")
  for year in years
    @finite_math ZZZ[year] = UnPRCost[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  ##########

  print(iob, "Capacity Factors and Outage Rates;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "UnPCF; Capacity Factor (MW/MW)")
  for year in years
    ZZZ[year] = UnPCF[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnOR; Outage Rate (MW/MW)")
  for year in years
    ZZZ[year] = UnOR[unit,1,1,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  
  print(iob, "UnOUREG; Own Use Rate for Generation (MW/MW)")
  for year in years
    ZZZ[year] = UnOUREG[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnOURGC; Own Use Rate for Generating Capacity (MW/MW)")
  for year in years
    ZZZ[year] = UnOURGC[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  ##########

  print(iob, "Fuel Demands (TBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  for fuelep in FuelEPs
    print(iob, "UnDmd;",FuelEPDS[fuelep],"")
    for year in years
      ZZZ[year] = UnDmd[unit,fuelep,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  ##########
  
  print(iob, "Miscellaneous Outputs;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "UnHRt; Heat Rate (Btu/KWh)")
  for year in years
    ZZZ[year] = UnHRt[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnLife; Number of years for Unit to Operate (years)")
  for year in years
    ZZZ[year] = UnLife[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnRetire; Retirement Date (Year)")
  for year in years
    ZZZ[year] = UnRetire[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "UnXSw; Exogneous Unit Data Switch (0=Exogenous)")
  for year in years
    ZZZ[year] = UnXSw[unit,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)
    
  # print(iob, "UnFP Calculation - ECFPFuel;")
  # for year in years
  #   print(iob,";",Year[year])
  # end
  # println(iob)
  # for fuelep in FuelEPs
  #   print(iob, "ECFPFuel;", FuelEPDS[fuelep],"")
  #   for year in years
  #     ZZZ[year] = ECFPFuel[fuelep,area,year]
  #     print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  #   end
  #   println(iob)
  # end
  # println(iob)
 
  # for month in Months
  #   print(iob, "UnFP Calculation - ", MonthDS[month]," ECFPMonth;")
  #   for year in years
  #     print(iob,";",Year[year])
  #   end
  #   println(iob)
  #   for fuelep in FuelEPs
  #     print(iob, "ECFPMonth;", FuelEPDS[fuelep],"")
  #     for year in years
  #       ZZZ[year] = ECFPMonth[fuelep,month,area,year]
  #       print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  #     end
  #     println(iob)
  #   end
  #   println(iob)
  # end
  
  # print(iob, "UnFP Calculation - UnFlFr;")
  # for year in years
  #   print(iob,";",Year[year])
  # end
  # for fuelep in FuelEPs
  #   print(iob, "UnFlFr;", FuelEPDS[fuelep],"")
  #   for year in years
  #     ZZZ[year] = UnFlFr[unit,fuelep,year]
  #     print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  #   end
  #   println(iob)
  # end
  # println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "UnitDetails-$UnitCode-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnitDetails_DtaControl(db)
  @info "UnitDetails_DtaControl"

  data = UnitDetailsData(; db)
  (; db,Units,UnArea,UnCode,Area, Plant, UnPlant)= data

  #for unit in Units
  #  UnitCode=UnCode[unit]
  #  if UnArea[unit] == "MX"
  #    if (UnArea[unit] != "Null") && (UnPlant[unit] != "Null")
  #      area = Select(Area,UnArea[unit])
  #      plant = Select(Plant,UnPlant[unit])
  #      UnitDetails_DtaRun(data,unit,UnitCode,area,plant,SceName)
  #    else
  #      nothing
  #    end
  #  end
  #end
  
   for unit in 14:18
     UnitCode=UnCode[unit]
     if (UnArea[unit] != "Null") && (UnPlant[unit] != "Null")
       area = Select(Area,UnArea[unit])
       plant = Select(Plant,UnPlant[unit])
       UnitDetails_DtaRun(data,unit,UnitCode,area,plant)
     else
       nothing
     end
   end

  for unit in Units
    if (UnArea[unit] != "Null") && (UnPlant[unit] == "BiomassCCS")
      UnitCode=UnCode[unit]
      area = Select(Area,UnArea[unit])
      plant = Select(Plant,UnPlant[unit])
      UnitDetails_DtaRun(data,unit,UnitCode,area,plant)
    else
      nothing
    end
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
UnitDetails_DtaControl(DB)
end
