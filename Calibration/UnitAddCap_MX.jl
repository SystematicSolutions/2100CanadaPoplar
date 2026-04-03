#
#  UnitAddCap_MX.jl - Add Capacity
#
using EnergyModel

module UnitAddCap_MX

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") # [Plant,Year] Construction Delay (YEARS)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnGC::VariableArray{2} = ReadDisk(db,"EGOutput/UnGC") # [Unit,Year] Generating Capacity (MW)
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)
  xUnGCCI::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCI") # [Unit,Year] Generating Capacity Initiated (MW)
  xUnGCCR::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCR") # [Unit,Year] Exogenous Generating Capacity Completion Rate (MW)
end

function GetUnitSets(data,unit)
  (;Plant) = data
  (;UnPlant) = data

  #
  # This procedure selects the sets for a particular unit
  #
  if (UnPlant[unit] != "Null")
    plant = Select(Plant,UnPlant[unit])
    valid = true
  else
    plant=1
    valid = false
  end
  return plant,valid
end

# function ResetUnitSets(data)
# end

function AddCapacity(data,UCode,YearCapacityOnLine,CapacityAdditions)
  (;Yrv) = data
  (;CD,UnCode,UnOnLine,xUnGC,xUnGCCI,xUnGCCR) = data

  unit=findall(UnCode[:] .== UCode)
  if length(unit) > 1 || isempty(unit)
      @info "Could not match UnCode $UCode"
  else
    #
    # Select GenCo, Area, Node, and Plant Type for this Unit
    #
    plant,valid=GetUnitSets(data,unit)
    CD_temp=CD[plant,Yr(1985)]
    if valid==true
      #
      #   Update Online year if needed.
      #
      for u in unit
        UnOnLine[u]=min(UnOnLine[u],Yrv[Yr(YearCapacityOnLine)])
      end

      #
      # Initial Year
      #
      if YearCapacityOnLine == ITime
        year=Int(YearCapacityOnLine-ITime+1)
        for u in unit
          xUnGC[u,year]=CapacityAdditions/1000
        end
      #
      # If capacity additions are negative, then adjust capacity (xUnGCCR)
      #
      elseif CapacityAdditions < 0
        year=Int(YearCapacityOnLine-ITime+1)
        for u in unit
          xUnGCCR[u,year]=xUnGCCR[u,year]+CapacityAdditions/1000
        end
      #
      #   If capacity comes on later, then simulate construction (xUnGCCI)
      #

      elseif (YearCapacityOnLine-CD_temp[]) > (ITime+1)
        year=Int(YearCapacityOnLine-CD_temp[]-ITime+1)
        for u in unit
          xUnGCCI[u,year]=xUnGCCI[u,year]+CapacityAdditions/1000
        end
      #
      #   If capacity on-line in the first few years, then there is no
      #   time to simulate construction, so just adjust capacity (xUnGCCR)
      #
      else
        year=Int(YearCapacityOnLine-ITime+1)
        for u in unit
          xUnGCCR[u,year]=xUnGCCR[u,year]+CapacityAdditions/1000
        end
      end
    end
  end
end

function ECalibration(db)
  data = EControl(; db)
  (;Years,Yrv) = data
  (;CD,UnNation,UnOnLine,UnGC,xUnGC,xUnGCCI,xUnGCCR) = data

  #
  # Initialize Mexico units
  #
  units=findall(UnNation[:] .== "MX")
  for unit in units
    if UnNation[unit] == "MX"
      for year in Years
        xUnGC[unit,year]=0
        xUnGCCI[unit,year]=0
        xUnGCCR[unit,year]=0
      end
    end
  end

  #                UnCode                Year     xUnGCCI
  AddCapacity(data,"MX_OGCT",            1985,    2249014)
  AddCapacity(data,"MX_OGCT",            1986,      48187)
  AddCapacity(data,"MX_OGCT",            1987,     102964)
  AddCapacity(data,"MX_OGCT",            1988,     112712)
  AddCapacity(data,"MX_OGCT",            1989,      77978)
  AddCapacity(data,"MX_OGCT",            1990,      19220)
  AddCapacity(data,"MX_OGCT",            1991,     229267)
  AddCapacity(data,"MX_OGCT",            1992,      40225)
  AddCapacity(data,"MX_OGCT",            1993,     199339)
  AddCapacity(data,"MX_OGCT",            1994,     203457)
  AddCapacity(data,"MX_OGCT",            1995,      75233)
  AddCapacity(data,"MX_OGCT",            1996,     145386)
  AddCapacity(data,"MX_OGCT",            1997,      69055)
  AddCapacity(data,"MX_OGCT",            1998,      63014)
  AddCapacity(data,"MX_OGCT",            1999,      63563)
  AddCapacity(data,"MX_OGCT",            2000,     160762)
  AddCapacity(data,"MX_OGCT",            2001,     280612)
  AddCapacity(data,"MX_OGCT",            2002,     439177)
  AddCapacity(data,"MX_OGCT",            2003,     529236)
  AddCapacity(data,"MX_OGCT",            2004,     224599)
  AddCapacity(data,"MX_OGCT",            2005,      28006)
  AddCapacity(data,"MX_OGCT",            2006,     352824)
  AddCapacity(data,"MX_OGCT",            2007,     234347)
  AddCapacity(data,"MX_OGCT",            2008,      76880)
  AddCapacity(data,"MX_OGCT",            2009,     128637)
  AddCapacity(data,"MX_OGCT",            2010,     229130)
  AddCapacity(data,"MX_OGCT",            2011,      93354)
  AddCapacity(data,"MX_OGCT",            2012,      91020)
  AddCapacity(data,"MX_OGCT",            2013,     -49286)
  AddCapacity(data,"MX_OGCT",            2014,     105435)
  AddCapacity(data,"MX_OGCT",            2015,      58209)

  AddCapacity(data,"MX_OGSteam",         1985,    9724411)
  AddCapacity(data,"MX_OGSteam",         1986,     208355)
  AddCapacity(data,"MX_OGSteam",         1987,     445203)
  AddCapacity(data,"MX_OGSteam",         1988,     487348)
  AddCapacity(data,"MX_OGSteam",         1989,     337167)
  AddCapacity(data,"MX_OGSteam",         1990,      83104)
  AddCapacity(data,"MX_OGSteam",         1991,     991318)
  AddCapacity(data,"MX_OGSteam",         1992,     173926)
  AddCapacity(data,"MX_OGSteam",         1993,     861912)
  AddCapacity(data,"MX_OGSteam",         1994,     879720)
  AddCapacity(data,"MX_OGSteam",         1995,     325295)
  AddCapacity(data,"MX_OGSteam",         1996,     628626)
  AddCapacity(data,"MX_OGSteam",         1997,     298583)
  AddCapacity(data,"MX_OGSteam",         1998,     272464)
  AddCapacity(data,"MX_OGSteam",         1999,     274838)
  AddCapacity(data,"MX_OGSteam",         2000,    -518713)
  AddCapacity(data,"MX_OGSteam",         2001,    -153975)
  AddCapacity(data,"MX_OGSteam",         2002,     235209)
  AddCapacity(data,"MX_OGSteam",         2003,     274138)
  AddCapacity(data,"MX_OGSteam",         2004,    -867236)
  AddCapacity(data,"MX_OGSteam",         2005,   -1465969)
  AddCapacity(data,"MX_OGSteam",         2006,    -730108)
  AddCapacity(data,"MX_OGSteam",         2007,   -1132806)
  AddCapacity(data,"MX_OGSteam",         2008,   -1499478)
  AddCapacity(data,"MX_OGSteam",         2009,   -1440867)
  AddCapacity(data,"MX_OGSteam",         2010,     256649)
  AddCapacity(data,"MX_OGSteam",         2011,      60659)
  AddCapacity(data,"MX_OGSteam",         2012,     266792)
  AddCapacity(data,"MX_OGSteam",         2013,     -69619)
  AddCapacity(data,"MX_OGSteam",         2014,     148934)
  AddCapacity(data,"MX_OGSteam",         2015,      82224)

  AddCapacity(data,"MX_OGCC",            1985,    3020004)
  AddCapacity(data,"MX_OGCC",            1986,      64706)
  AddCapacity(data,"MX_OGCC",            1987,     138262)
  AddCapacity(data,"MX_OGCC",            1988,     151350)
  AddCapacity(data,"MX_OGCC",            1989,     104710)
  AddCapacity(data,"MX_OGCC",            1990,      25809)
  AddCapacity(data,"MX_OGCC",            1991,     307863)
  AddCapacity(data,"MX_OGCC",            1992,      54014)
  AddCapacity(data,"MX_OGCC",            1993,     267675)
  AddCapacity(data,"MX_OGCC",            1994,     273205)
  AddCapacity(data,"MX_OGCC",            1995,     101023)
  AddCapacity(data,"MX_OGCC",            1996,     195225)
  AddCapacity(data,"MX_OGCC",            1997,      92727)
  AddCapacity(data,"MX_OGCC",            1998,      84616)
  AddCapacity(data,"MX_OGCC",            1999,      85354)
  AddCapacity(data,"MX_OGCC",            2000,    1429695)
  AddCapacity(data,"MX_OGCC",            2001,    1744109)
  AddCapacity(data,"MX_OGCC",            2002,    2253461)
  AddCapacity(data,"MX_OGCC",            2003,    2724868)
  AddCapacity(data,"MX_OGCC",            2004,    2139966)
  AddCapacity(data,"MX_OGCC",            2005,    1624672)
  AddCapacity(data,"MX_OGCC",            2006,    2729445)
  AddCapacity(data,"MX_OGCC",            2007,    2460771)
  AddCapacity(data,"MX_OGCC",            2008,    1935132)
  AddCapacity(data,"MX_OGCC",            2009,    2169808)
  AddCapacity(data,"MX_OGCC",            2010,    1041753)
  AddCapacity(data,"MX_OGCC",            2011,     468349)
  AddCapacity(data,"MX_OGCC",            2012,     248991)
  AddCapacity(data,"MX_OGCC",            2013,    -209666)
  AddCapacity(data,"MX_OGCC",            2014,     448533)
  AddCapacity(data,"MX_OGCC",            2015,     247628)

  AddCapacity(data,"MX_Coal",            1985,    1388571)
  AddCapacity(data,"MX_Coal",            1986,      29751)
  AddCapacity(data,"MX_Coal",            1987,      63571)
  AddCapacity(data,"MX_Coal",            1988,      69590)
  AddCapacity(data,"MX_Coal",            1989,      48145)
  AddCapacity(data,"MX_Coal",            1990,      11867)
  AddCapacity(data,"MX_Coal",            1991,     141553)
  AddCapacity(data,"MX_Coal",            1992,      24835)
  AddCapacity(data,"MX_Coal",            1993,     123074)
  AddCapacity(data,"MX_Coal",            1994,     125617)
  AddCapacity(data,"MX_Coal",            1995,      46450)
  AddCapacity(data,"MX_Coal",            1996,      89763)
  AddCapacity(data,"MX_Coal",            1997,      42635)
  AddCapacity(data,"MX_Coal",            1998,      38906)
  AddCapacity(data,"MX_Coal",            1999,      39245)
  AddCapacity(data,"MX_Coal",            2000,      99256)
  AddCapacity(data,"MX_Coal",            2001,     173253)
  AddCapacity(data,"MX_Coal",            2002,     271154)
  AddCapacity(data,"MX_Coal",            2003,     326757)
  AddCapacity(data,"MX_Coal",            2004,     138671)
  AddCapacity(data,"MX_Coal",            2005,      17291)
  AddCapacity(data,"MX_Coal",            2006,     217838)
  AddCapacity(data,"MX_Coal",            2007,     144689)
  AddCapacity(data,"MX_Coal",            2008,      47467)
  AddCapacity(data,"MX_Coal",            2009,      79422)
  AddCapacity(data,"MX_Coal",            2010,     141468)
  AddCapacity(data,"MX_Coal",            2011,      57638)
  AddCapacity(data,"MX_Coal",            2012,      56197)
  AddCapacity(data,"MX_Coal",            2013,     -30430)
  AddCapacity(data,"MX_Coal",            2014,      65097)
  AddCapacity(data,"MX_Coal",            2015,      35939)

  AddCapacity(data,"MX_Nuclear",         1989,     654000)
  AddCapacity(data,"MX_Nuclear",         1990,     -14000)
  AddCapacity(data,"MX_Nuclear",         1992,      14000)
  AddCapacity(data,"MX_Nuclear",         1994,     602000)
  AddCapacity(data,"MX_Nuclear",         1996,      18000)
  AddCapacity(data,"MX_Nuclear",         1997,     -32000)
  AddCapacity(data,"MX_Nuclear",         1998,      68000)
  AddCapacity(data,"MX_Nuclear",         1999,      54000)
  AddCapacity(data,"MX_Nuclear",         2000,     -74000)
  AddCapacity(data,"MX_Nuclear",         2002,      70000)
  AddCapacity(data,"MX_Nuclear",         2008,     -60000)
  AddCapacity(data,"MX_Nuclear",         2012,      30000)
  AddCapacity(data,"MX_Nuclear",         2015,     110000)

  AddCapacity(data,"MX_PeakHydro",       1985,    6600000)
  AddCapacity(data,"MX_PeakHydro",       1987,    1021000)
  AddCapacity(data,"MX_PeakHydro",       1988,     203000)
  AddCapacity(data,"MX_PeakHydro",       1989,      12000)
  AddCapacity(data,"MX_PeakHydro",       1990,      44000)
  AddCapacity(data,"MX_PeakHydro",       1991,     113000)
  AddCapacity(data,"MX_PeakHydro",       1992,      75000)
  AddCapacity(data,"MX_PeakHydro",       1993,     103000)
  AddCapacity(data,"MX_PeakHydro",       1994,     950000)
  AddCapacity(data,"MX_PeakHydro",       1995,     208000)
  AddCapacity(data,"MX_PeakHydro",       1996,     705000)
  AddCapacity(data,"MX_PeakHydro",       1998,    -331000)
  AddCapacity(data,"MX_PeakHydro",       1999,     -69000)
  AddCapacity(data,"MX_PeakHydro",       2001,       2000)
  AddCapacity(data,"MX_PeakHydro",       2002,      -1000)
  AddCapacity(data,"MX_PeakHydro",       2003,      15000)
  AddCapacity(data,"MX_PeakHydro",       2004,     915000)
  AddCapacity(data,"MX_PeakHydro",       2005,      33000)
  AddCapacity(data,"MX_PeakHydro",       2006,     202000)
  AddCapacity(data,"MX_PeakHydro",       2007,     777000)
  AddCapacity(data,"MX_PeakHydro",       2008,    -106000)
  AddCapacity(data,"MX_PeakHydro",       2009,      72000)
  AddCapacity(data,"MX_PeakHydro",       2010,      83000)
  AddCapacity(data,"MX_PeakHydro",       2011,      20000)
  AddCapacity(data,"MX_PeakHydro",       2012,     -20000)
  AddCapacity(data,"MX_PeakHydro",       2013,       7000)
  AddCapacity(data,"MX_PeakHydro",       2014,     831000)
  AddCapacity(data,"MX_PeakHydro",       2015,    -241000)

  AddCapacity(data,"MX_Geothermal",      1985,     400000)
  AddCapacity(data,"MX_Geothermal",      1986,     100000)
  AddCapacity(data,"MX_Geothermal",      1987,     200000)
  AddCapacity(data,"MX_Geothermal",      1992,      50000)
  AddCapacity(data,"MX_Geothermal",      2000,      50000)
  AddCapacity(data,"MX_Geothermal",      2003,     200000)
  AddCapacity(data,"MX_Geothermal",      2011,    -100000)

  AddCapacity(data,"MX_OnshoreWind",     2005,      18000)
  AddCapacity(data,"MX_OnshoreWind",     2006,      83000)
  AddCapacity(data,"MX_OnshoreWind",     2009,     374000)
  AddCapacity(data,"MX_OnshoreWind",     2010,      94000)
  AddCapacity(data,"MX_OnshoreWind",     2011,      32000)
  AddCapacity(data,"MX_OnshoreWind",     2012,    1214000)
  AddCapacity(data,"MX_OnshoreWind",     2013,     307000)
  AddCapacity(data,"MX_OnshoreWind",     2014,     447000)
  AddCapacity(data,"MX_OnshoreWind",     2015,     702000)

  AddCapacity(data,"MX_Biomass",         1991,     300000)
  AddCapacity(data,"MX_Biomass",         1992,      50000)
  AddCapacity(data,"MX_Biomass",         2000,      50000)
  AddCapacity(data,"MX_Biomass",         2001,     100000)

  AddCapacity(data,"MX_SolarPV",         2005,      16000)
  AddCapacity(data,"MX_SolarPV",         2007,       3000)
  AddCapacity(data,"MX_SolarPV",         2009,       6000)
  AddCapacity(data,"MX_SolarPV",         2010,       4000)
  AddCapacity(data,"MX_SolarPV",         2011,      10000)
  AddCapacity(data,"MX_SolarPV",         2012,      21000)
  AddCapacity(data,"MX_SolarPV",         2013,      22000)
  AddCapacity(data,"MX_SolarPV",         2014,      34000)
  AddCapacity(data,"MX_SolarPV",         2015,      57000)

  #
  # Update xUnGC for Mexico units
  #
  units=findall(UnNation[:] .== "MX")
  for unit in units
    if UnNation[unit] == "MX"
      plant,valid=GetUnitSets(data,unit)
      if valid==true
        years=collect(First:Final)
        for year in years
          YearStartConstruction=Int(max(Yrv[year]-CD[plant,year]-ITime+1,1))
          xUnGC[unit,year]=xUnGC[unit,year-1]+xUnGCCI[unit,YearStartConstruction]+
            xUnGCCR[unit,year]
        end
        UnGC[unit,Yr(1985)]=xUnGC[unit,Yr(1985)]
      end
    end
  end

  WriteDisk(db,"EGInput/UnOnLine",UnOnLine)
  WriteDisk(db,"EGOutput/UnGC",UnGC)
  WriteDisk(db,"EGInput/xUnGC",xUnGC)
  WriteDisk(db,"EGInput/xUnGCCI",xUnGCCI)
  WriteDisk(db,"EGInput/xUnGCCR",xUnGCCR)
end

function CalibrationControl(db)
  @info "UnitAddCap_MX.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
