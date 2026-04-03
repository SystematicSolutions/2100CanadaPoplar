#
# ElectricImports.jl
#
using EnergyModel

module ElectricImports

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  GrImpMult::VariableArray{3} = ReadDisk(db,"EGInput/GrImpMult") # [NodeX,Area,Year] Gross Imports Multiplier (GWh/GWh)
  OtISw::VariableArray{2} = ReadDisk(db,"EGInput/OtISw") # [Area,Year] Other (Unspecified) Imports Switch
  POCXOthImports::VariableArray{4} = ReadDisk(db,"EGInput/POCXOthImports") # [Poll,NodeX,Area,Year] Imported Emissions Coefficients (Tonnes/GWh)
  POCXRnImports::VariableArray{3} = ReadDisk(db,"EGInput/POCXRnImports") # [Poll,Area,Year] Renewable Imports Emissions Coefficient (Tonnes/GWh)
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnFrImports::VariableArray{3} = ReadDisk(db,"EGInput/UnFrImports") # [Unit,Area,Year] Fraction of Unit Imported to Area (GWH/GWH)
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,NodeX,NodeXs,Poll) = data
  (;Units,Years) = data
  (;GrImpMult,OtISw,POCXOthImports,POCXRnImports,UnCode,UnFrImports) = data

  # 
  # Imports, in this context, are only imports from Area outside the
  # Cap and Trade Area, so for the current WCI imports are flows into
  # California or Quebec excluding Laborador (LB). Jeff Amlin 23/12/15
  # 
  GrImpMult .= 0
  areas = Select(Area,["CA","QC","ON"])
  GrImpMult[NodeXs,areas,Years] .= 1.0
  nodexs = Select(NodeX,["CANO","CASO","QC","ON","LB"])
  GrImpMult[nodexs,areas,Years] .= 0

  #
  # Emissions Coefficient for Other Imported Electricity is 
  # 960 lbs CO2e/MWh (or 0.428 MT CO2e/MWh) per Lee Alter email (July 24,2011)
  # Convert to Tonnes/GWh 7/26/11 RBL
  # 
  CA = Select(Area,"CA")
  OtISw[CA,Years] .= 2.0

  # 
  # Emissions Coefficient for Other Imported Electricity is 
  # 960 lbs CO2e/MWh (or 0.428 MT CO2e/MWh) per Lee Alter email (July 24,2011)
  # Convert to Tonnes/GWh 7/26/11 RBL
  #
  CO2 = Select(Poll,"CO2")
  POCXOthImports[CO2,NodeXs,CA,Years] .= 960/2204.6*1000
  POCXRnImports[CO2,CA,Years] .= 0

  # 
  # Assume other WCI areas same as California - 960 lbs CO2e/MWh (convert to Tonnes/GWh)
  # 
  areas = Select(Area,["ON","BC","QC","MB"])
  POCXOthImports[CO2,NodeXs,areas,Years] .= 960/2204.6*1000
  POCXRnImports[CO2,areas,Years] .= 0
    
  # 
  # Assume non-WCI default 436 Tonnes/GWh. 8/15/11 RBL
  # 
  not_areas = ["CA","ON","BC","QC","MB"]
  areas = findall(x -> !(x in not_areas), Area)
  POCXOthImports[CO2,NodeXs,areas,Years] .= 436
  POCXRnImports[CO2,areas,Years] .= 0

  #
  #  * Ontario EFs per K. Stauffer email of 8/4/11
  # * 8/11/11 RBL
  # *
  # *     Balancing Area         E2020 Node   Default CO2e  
  # *                                             t/MWh     
  # * Newfoundland and Labrador   No LLMax        0.025 
  # * Nova Scotia                 No LLMax        0.803 
  # * New Brunswick               No LLMax        0.424 
  # * Quebec                      Quebec          0.011 
  # * Ontario                     Ontario         0.220 
  # * New England ISO             NEWE            0.462 
  # * New York ISO                NYUP            0.650 
  # * Penn, Jersey, MD RTO        PJME            0.924 
  # * Midwest ISO                 MISE            0.946 
  # *
  # * Ontario:
  # * source: emal from Maxime August 12, 2016 4:44 PM
  # * 
  # * Table 3. Proposed Default Emission Factors by Jurisdiction (tonnes per MWh)
  # * Jurisdiction    Off Peak   Peak
  # * ISO-NE            0.344   0.480
  # * NYISO             0.352   0.510
  # * PJM               0.812   0.605
  # * MISO              0.965   0.789
  # * Manitoba          0.000   0.000
  # * 
  # * Table 4. Proposed Default Emission Factor for Imports from Other Jurisdictions (tonnes per MWh)
  # * Jurisdiction    Off Peak   Peak
  # * Unspecified       0.800   0.600
  # 

  ON = Select(Area,"ON")
  POCXOthImports[CO2,Select(NodeX,"ISNE"),ON,Years] .= 0.344*1000
  POCXOthImports[CO2,Select(NodeX,"NYUP"),ON,Years] .= 0.352*1000
  POCXOthImports[CO2,Select(NodeX,"PJME"),ON,Years] .= 0.812*1000
  POCXOthImports[CO2,Select(NodeX,"MISW"),ON,Years] .= 0.965*1000
  POCXOthImports[CO2,Select(NodeX,"MB"),  ON,Years] .= 0.000*1000


  #
  #  * Quebec Import Emission Factors
  # * (per email of Francis Beland-Plante 8/4/11)
  # * (Metric tons of CO2eq per MWh) 8/31/11 RBL
  # *
  # * New England ISO       NEWE       0.457
  # * NYUP ISO              NYUP       0.567
  # * PJM-RTO               RFCM       0.933
  # * MW-RTO                MROW       0.999
  # *
  # * Newfoundland including Laborador 0.000
  # * New Brunswick 460 tonnes CO2e/GWh
  # * Ontario assume 460 tonnes CO2e/GWh
  # *
  # * Quebec:
  # *
  # * Table 2. Quebec’s Default Emission Factors for Electricity Imports (tonnes per MWh)
  # * Jurisdiction    Default Emission Factor
  # * Newfoundland and Labrador 0.021
  # * Nova Scotia               0.694
  # * New Brunswick             0.292
  # * Québec                    0.002
  # * Ontario                   0.077
  # * Manitoba                  0.003
  # * Vermont                   0.002
  # * ISO-NE                    0.290
  # * NYISO                     0.246
  # * PJM                       0.596
  # * MISO                      0.651
  # * SPP                       0.631
  # *                   
  # * Link to the report: http://www.energy.gov.on.ca/en/ontarios-electricity-system/climate-change/proposed-default-emission-factors-for-ontarios-cap-trade-program/
  # 

  QC = Select(Area,"QC")
  POCXOthImports[CO2,Select(NodeX,["NL","LB"]),QC,Years] .= 0.021*1000
  POCXOthImports[CO2,Select(NodeX,"NS"),QC,Years] .= 0.694*1000
  POCXOthImports[CO2,Select(NodeX,"NB"),QC,Years] .= 0.292*1000
  POCXOthImports[CO2,Select(NodeX,"ISNE"),QC,Years] .= 0.290*1000
  POCXOthImports[CO2,Select(NodeX,"NYUP"),QC,Years] .= 0.290*1000
  POCXOthImports[CO2,Select(NodeX,"PJME"),QC,Years] .= 0.596*1000
  POCXOthImports[CO2,Select(NodeX,"MISW"),QC,Years] .= 0.651*1000

  # 
  # Plants outside California which are part of California inventory
  # Plants are sold in 2012. Set values to zero.  PMC 8/26/11
  # 
  # Four Corners Unit 4 and 5
  # 
  for unit in Select(UnCode[Units],["Mtn_2442_4","Mtn_2442_5"])
    for year in First:Yr(2020)
      UnFrImports[unit,CA,year] = 0.480
    end
    for year in Yr(2021):Final
      UnFrImports[unit,CA,year] = 0.000
    end
  end

  # 
  # Hoover Dam in Nevada
  # 
  for unit in Select(UnCode[Units],["Mtn_154_N1","Mtn_154_N2","Mtn_154_N3","Mtn_154_N4","Mtn_154_N5","Mtn_154_N6","Mtn_154_N7","Mtn_154_N8"])
    for year in Years
      UnFrImports[unit,CA,year] = 0.550
    end
  end

  # 
  # Intermountain
  # 
  for unit in Select(UnCode[Units],["Mtn_6481_1","Mtn_6481_2"])
    for year in Years
      UnFrImports[unit,CA,year] = 0.789
    end
  end

  # 
  # Navajo
  # 
  for unit in findall(x -> x == "Mtn_4941_NAV1" || x == "Mtn_4941_NAV2" || x == "Mtn_4941_NAV3", UnCode)
    @show UnCode[unit]
    for year in Years
      UnFrImports[unit,CA,year] = 0.212
    end
  end

  # 
  # Palo Verde
  # 
  for unit in Select(UnCode[Units],["Mtn_6008_1","Mtn_6008_2","Mtn_6008_3"])
    for year in Years
      UnFrImports[unit,CA,year] = 0.274
    end
  end

  # 
  # Reid Gardner expires
  # 
  for unit in findall(UnCode .== "Mtn_2324_4")
    for year in Years
      UnFrImports[unit,CA,year] = 0.678*0.00
    end
  end

  # 
  # San Juan 3
  # 
  for unit in findall(UnCode .== "Mtn_2451_3")
    for year in Years
      UnFrImports[unit,CA,year] = 0.418
    end
  end

  # 
  # San Juan 4
  # 
  for year in Years
    UnFrImports[Select(UnCode,"Mtn_2451_4"),CA,year] = 0.388
  end

  # 
  # Yucca (Yuma AZ)
  # 
  for year in Years
    UnFrImports[Select(UnCode,"Mtn_120_ST1"),CA,year] = 0.100
  end

  WriteDisk(db,"EGInput/GrImpMult",GrImpMult)
  WriteDisk(db,"EGInput/OtISw",OtISw)
  WriteDisk(db,"EGInput/POCXOthImports",POCXOthImports)
  WriteDisk(db,"EGInput/POCXRnImports",POCXRnImports)
  WriteDisk(db,"EGInput/UnFrImports",UnFrImports)
  
end

function CalibrationControl(db)
  @info "ElectricImports.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
