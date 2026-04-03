#
# UnitGeneration_MX.jl
#
using EnergyModel

module UnitGeneration_MX

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  xEUD::VariableArray{3} = ReadDisk(db,"EGInput/xEUD") # [FuelEP,Area,Year] Electric Utility Fuel Demands (TBtu/Yr)
  xUnDmd::VariableArray{3} = ReadDisk(db,"EGInput/xUnDmd") # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation (GWh)

  # Scratch Variables
  FuelEPSort::VariableArray{1} = zeros(Float32,length(FuelEP)) # [FuelEP] Variable to Sort FuelEP
  HeatRateAdjust::VariableArray{3} = zeros(Float32,length(FuelEP),length(Area),length(Year)) # [FuelEP,Area,Year] Heat Rate Adjustment (Btu/Btu)
  xEUDEstimate::VariableArray{3} = zeros(Float32,length(FuelEP),length(Area),length(Year)) # [FuelEP,Area,Year] Electric Utility Fuel Demands (TBtu/Yr)
  xUnDmdEstimate::VariableArray{3} = zeros(Float32,length(Unit),length(FuelEP),length(Year)) # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,FuelEP,FuelEPs) = data
  (;Years) = data
  (;UnCode,xUnFlFr,UnHRt,UnNation,xEUD,xUnDmd,xUnEGA) = data
  (;HeatRateAdjust,xEUDEstimate,xUnDmdEstimate) = data

  #
  # Sources: U.S. Energy Information Administration, https://www.eia.gov/beta/international/data/browser/#?iso=MEX
  #          "Guide to Electric Power in Mexico" Center for Energy Economics Bureau of Economic
  #          Geology, The University of Texas at Austin and Instituto Tecnológico y de Estudios Superiores
  #          de Monterrey; http://www.beg.utexas.edu/energyecon/2013%20E.pdf
  # Working File: "Mexico - EIA Electric Data v2.xlsx", 1.16.2018, Luke Davulis
  #
  # Generation By Type (GWH)
  #
  years=collect(Yr(1985):Yr(2015))

  MX_OGCT=Select(UnCode,"MX_OGCT")
  MX_OGCC=Select(UnCode,"MX_OGCC")
  MX_OGSteam=Select(UnCode,"MX_OGSteam")
  MX_Coal=Select(UnCode,"MX_Coal")
  MX_Nuclear=Select(UnCode,"MX_Nuclear")
  MX_PeakHydro=Select(UnCode,"MX_PeakHydro")
  MX_Biomass=Select(UnCode,"MX_Biomass")
  MX_OnshoreWind=Select(UnCode,"MX_OnshoreWind")
  MX_Geothermal=Select(UnCode,"MX_Geothermal")
  MX_SolarPV=Select(UnCode,"MX_SolarPV")
  #                                1985    1986    1987    1988    1989    1990    1991    1992    1993    1994    1995    1996    1997    1998    1999    2000    2001    2002    2003    2004    2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015
  xUnEGA[MX_OGCT,years] =        [ 5658    6364    7083    7274    7656    7399    7742    7659    8042    9539    9003    9536   10779   11521   11633   12575   13466   13982   14061   15203   15644   15952   16751   16209   17031   17738   19498   20156   19369   18818   19825]
  xUnEGA[MX_OGCC,years] =        [12068   13573   15107   15512   16328   15779   16512   16334   17150   20343   19200   20337   22989   24570   24810   33100   42054   50405   57350   69088   78247   86964   98731  102583  115069  120146  132403  136866  131522  127781  134622]
  xUnEGA[MX_OGSteam,years] =     [38858   43705   48644   49950   52577   50808   53168   52594   55224   65504   61823   65486   74026   79117   79889   80075   79143   75434   69198   67743   62547   56603   52032   43297   38208   39500   43083   44536   42797   41580   43806]
  xUnEGA[MX_Coal,years] =        [ 8939   10054   11190   11491   12095   11688   12231   12099   12704   15069   14222   15065   17029   18200   18378   20161   21901   23056   23499   25741   26823   27689   29425   28803   30606   33047   37654   38924   37404   36340   38285]
  xUnEGA[MX_Nuclear,years] =     [    0       0       0       0       0    2790    4030    3723    4684    4027    8021    7484    9937    8800    9502    7810    8290    9260    9975    8734   10318   10400    9947    9359   10108    5592    9313    8412   11377    9312   11185]
  xUnEGA[MX_PeakHydro,years] =   [25968   19817   18243   20974   24398   23243   21635   25908   25973   19848   27253   31128   26166   24379   32454   32802   28217   24701   19681   24954   27382   30090   27003   38786   26446   36790   35928   31587   27722   38549   30614]
  xUnEGA[MX_Biomass,years] =     [    0       0       0       0       0       0    1493    2109    2339    2331    2798    1711    1512    1757    1611    1672    2509    2477    2454    2515    3074    2332    2363     708     631     776     731    1170    1322    1430    1788]
  xUnEGA[MX_OnshoreWind,years] = [    0       0       0       0       0       1       1       1       1       5       7       6      12      15      17      19      18      21      19      20      19      59     262     269     596    1237    1634    3667    4168    6351    8453]
  xUnEGA[MX_Geothermal,years] =  [ 1600    3400    4300    4700    4700    5124    5435    5804    5877    5598    5669    5729    5466    5657    5623    5901    5567    5398    6282    6577    7299    6685    7404    7056    6740    6294    6192    5511    5762    5702    5995]
  xUnEGA[MX_SolarPV,years] =     [    0       0       0       0       0       1       2       3       4       5       5       6       6       7       7       7       8       8       8       9       9      10       9       9      12      31      41      69     106     221     245]

  units=findall(UnNation[:] .== "MX")
  years=collect(Yr(2016):Final)
  for year in years, unit in units
    if UnNation[unit] == "MX"
      xUnEGA[unit,year]=xUnEGA[unit,Yr(2015)]
    end
  end

  #
  # Historical Electric Supply Fuel Demands (TBtu, Source?)
  #
  MX=Select(Area,"MX")
  years=collect(Yr(1985):Yr(2015))
  fueleps=Select(FuelEP,["NaturalGas","Coal","HFO"])
  #! format: off
  xEUD[fueleps,MX,years] .= [
    # 1985     1986     1987     1988     1989     1990     1991     1992     1993     1994     1995     1996     1997     1998     1999     2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013     2014     2015
    720.84   609.16   615.20   623.53   577.61   679.38   694.41   692.10   702.69   740.79   767.88   824.45   841.48   922.81   888.48  1002.72  1026.90  1155.19  1252.12  1219.62  1210.45  1418.51  1554.13  1633.38  2059.39  1847.90  1858.52  1956.22  2088.16  1997.00  2174.04 # Gas
     54.50    66.30    60.12    52.02    57.24    94.88    85.90    85.20   102.42    94.61   121.43   156.27   161.30   163.65   181.93   177.65   232.94   270.64   363.62   265.81   358.66   384.74   342.74   289.61   298.18   399.67   423.15   367.91   407.67   388.83   390.76 # Coal
    796.25   869.96   914.13   941.73  1070.36   892.82  1009.37  1048.27  1066.65  1124.19  1035.50  1014.89  1041.82  1074.29  1131.25  1103.52   993.73   806.68   671.09   820.41   829.31   691.55   672.92   687.50   316.05   759.31   446.44   394.87   259.05   328.75   177.20 # Oil
  ]
  #! format: on

  #
  # Estimate Unit Fuel Demands from Default Heat Rate
  #
  fueleps=Select(FuelEP,["NaturalGas","Coal","HFO"])
  years=collect(First:Last)
  units=findall(UnNation[:] .== "MX")
  for year in years, fuelep in fueleps, unit in units
    xUnDmdEstimate[unit,fuelep,year]=max(xUnEGA[unit,year]*UnHRt[unit,year]/1e6*xUnFlFr[unit,fuelep,year],0)
  end
  for year in Years, fuelep in fueleps
    xEUDEstimate[fuelep,MX,year]=sum(xUnDmdEstimate[unit,fuelep,year] for unit in units)
  end

  #
  # Estimate Required Adjustment to Heat Rate
  #
  @. HeatRateAdjust=1
  fueleps=Select(FuelEP,["NaturalGas","Coal","HFO"])
  for year in years, fuelep in fueleps
    @finite_math HeatRateAdjust[fuelep,MX,year]=xEUD[fuelep,MX,year]/xEUDEstimate[fuelep,MX,year]
  end

  #
  # Adjust Heat Rate of Mexico Units
  #
  units=findall(UnNation[:] .== "MX")
  for unit in units
    years=collect(First:Last)
    for year in years
      # for fuelep in fueleps
      #   FuelEPSort[fuelep]=xUnFlFr[unit,fuelep,year]
      # end
      # # Sort Descending FuelEP using FuelEPSort
      # fueleps_sorted = fueleps[sortperm(FuelEPSort[fueleps],rev=true)]
      # fuelep=first(fueleps_sorted)
      fuelep_max=argmax(xUnFlFr[unit,FuelEPs,year])
      UnHRt[unit,year]=UnHRt[unit,year]*HeatRateAdjust[fuelep_max,MX,year]
    end
    years=collect(Future:Final)
    for year in years
      UnHRt[unit,year]=UnHRt[unit,Last]
    end
  end


  years=collect(First:Last)
  units=findall(UnNation[:] .== "MX")
  for year in years, fuelep in FuelEPs, unit in units
    xUnDmd[unit,fuelep,year]=max(xUnEGA[unit,year]*UnHRt[unit,year]/1e6*xUnFlFr[unit,fuelep,year],0)
  end

  WriteDisk(db,"EGInput/UnHRt",UnHRt)
  WriteDisk(db,"EGInput/xEUD",xEUD)
  WriteDisk(db,"EGInput/xUnEGA",xUnEGA)
  WriteDisk(db,"EGInput/xUnDmd",xUnDmd)

end

function CalibrationControl(db)
  @info "UnitGeneration_MX.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
