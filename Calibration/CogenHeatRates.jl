#
# CogenHeatRates.jl
#
using EnergyModel

module CogenHeatRates

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgHRtM::VariableArray{4} = ReadDisk(db,"$Input/CgHRtM") # [Tech,EC,Area,Year] Marginal Cogeneration Heat Rate (Btu/KWh)
  xCgHRtA::VariableArray{4} = ReadDisk(db,"$Input/xCgHRtA") # [Tech,EC,Area,Year] Historic Average Cogeneration Heat Rate (Btu/KWh)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;ECs,Nation,Tech,Techs,Areas,Years) = data
  (;ANMap,CgHRtM,xCgHRtA) = data

  #
  # Historical Cogeneration Heat Rate
  #
  for year in Years, area in Areas, ec in ECs, tech in Techs
    xCgHRtA[tech,ec,area,year] = CgHRtM[tech,ec,area,year]
  end

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  years = collect(Yr(2000):Yr(2008))
  tech = Select(Tech,"Gas")
  xCgHRtA[tech,1,areas,years] .= [
  #/                         2000      2001    2002    2003    2004    2005    2006    2007    2008
  #/Canada                   8898      9360    8705    8314    8977    9438    9922    9830    9724
  #=Ontario=#                8610      8632    7407    6787    3932    10749   8434    8214    8193
  #=Quebec=#                 6852      6743    6100    6301    6476    6348    6077    5603    5649
  #=British Columbia=#       9401      11092   10099   10028   9893    10183   10163   9975    9562
  #=Alberta=#                8557      8915    8658    8324    14078   8971    10421   10573   10394
  #=Manitoba=#               8898      9360    8705    8314    8977    9438    9922    9830    9724
  #=Saskatchewan=#           12217     12290   12504   13099   13615   5482    5392    5336    5378
  #=New Brunswick=#          8898      9360    8705    8314    8977    8005    8307    8819    9044
  #=Nova Scotia=#            8898      9360    8705    8314    8977    9438    9922    9830    9724
  #=Newfoundland=#           8319      8328    8326    9225    11012   11014   11010   11378   11412
  #=PEI=#                    8898      9360    8705    8314    8977    9438    9922    9830    9724
  #=Yukon=#                  12652     12643   13645   14232   9848    12178   11387   11374   11428
  #=Northwest Territory=#    12652     12643   13645   14232   9848    12178   11387   11374   11428
  #=Nunavut=#                12652     12643   13645   14232   9848    12178   11387   11374   11428
  ]
  for year in years, area in areas, ec in ECs
    xCgHRtA[tech,ec,area,year] = xCgHRtA[tech,1,area,Yr(2000)]
  end
  years = collect(Yr(1985):Yr(1999))
  for year in years, area in areas, ec in ECs
    xCgHRtA[tech,ec,area,year] = xCgHRtA[tech,ec,area,Yr(2000)]
  end
  years = collect(Yr(2009):Final)
  for year in years, area in areas, ec in ECs
    xCgHRtA[tech,ec,area,year] = xCgHRtA[tech,ec,area,Yr(2008)]
  end
  

  #
  # For Canada set histoical marginal (CgHRtM) equal to historical average (xCgHRtA)
  #
  years = collect(Zero:Last)
  for ec in ECs, area in areas, year in years
    CgHRtM[tech,ec,area,year] = xCgHRtA[tech,ec,area,year]
  end

  WriteDisk(db,"$Input/CgHRtM",CgHRtM)
  WriteDisk(db,"$Input/xCgHRtA",xCgHRtA)

end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgHRtM::VariableArray{4} = ReadDisk(db,"$Input/CgHRtM") # [Tech,EC,Area,Year] Marginal Cogeneration Heat Rate (Btu/KWh)
  xCgHRtA::VariableArray{4} = ReadDisk(db,"$Input/xCgHRtA") # [Tech,EC,Area,Year] Historic Average Cogeneration Heat Rate (Btu/KWh)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,Areas,EC,ECs,Nation,Tech,Techs) = data
  (;Techs,Years) = data
  (;ANMap,CgHRtM,xCgHRtA) = data

  #
  # Cogeneration Heat Rate - this value is from the NRTEE study, but we need
  # to review and possibly revise the values.  J. Amlin 07/12/07
  #
  for year in Years, area in Areas, ec in ECs, tech in Techs
    CgHRtM[tech,ec,area,year] = 10500
  end
  
  Solar = Select(Tech,"Solar")
  for year in Years, area in Areas, ec in ECs
    CgHRtM[Solar,ec,area,year] = 1
  end
  
  #
  # Update TD (in the context of the CER): using ECD value to align with NextGrid (implementing the average of different plant types)
  tech = Select(Tech,"Gas")
  for year in Years, area in Areas, ec in ECs
    CgHRtM[tech,ec,area,year] = 7941
  end
  tech = Select(Tech,"LPG")
  for year in Years, area in Areas, ec in ECs
    CgHRtM[tech,ec,area,year] = 8298
  end
  tech = Select(Tech,"Oil")
  for year in Years, area in Areas, ec in ECs
    CgHRtM[tech,ec,area,year] = 8298
  end


  #
  # Biomass use mid-range quote from ACEEE article of 63 kwh/MBtu
  # 15873=1000000/63
  # Update TD (in the context of the CER): using ECD value to align with NextGrid
  #
  Biomass = Select(Tech,"Biomass")
  for year in Years, area in Areas, ec in ECs
    CgHRtM[Biomass,ec,area,year] = 9554
  end  

  #
  # Adjust cogeneration heat rate for oil and gas (AB) from Rajean and Glasha
  #
  AB = Select(Area,"AB")
  techs = Select(Tech,["Gas","LPG","Oil"])
  for year in Years, ec in ECs, tech in techs 
    CgHRtM[tech,ec,AB,year] = 8550
  end

  for year in Years, area in Areas, ec in ECs, tech in Techs
    xCgHRtA[tech,ec,area,year] = CgHRtM[tech,ec,area,year]
  end

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  years = collect(Yr(2000):Yr(2008))
  tech = Select(Tech,"Gas")
  xCgHRtA[tech,1,areas,years] .= [
  #/                         2000      2001    2002    2003    2004    2005    2006    2007    2008
  #/Canada                   8898      9360    8705    8314    8977    9438    9922    9830    9724
  #=Ontario=#                8610      8632    7407    6787    3932    10749   8434    8214    8193
  #=Quebec=#                 6852      6743    6100    6301    6476    6348    6077    5603    5649
  #=British Columbia=#       9401      11092   10099   10028   9893    10183   10163   9975    9562
  #=Alberta=#                8557      8915    8658    8324    14078   8971    10421   10573   10394
  #=Manitoba=#               8898      9360    8705    8314    8977    9438    9922    9830    9724
  #=Saskatchewan=#           12217     12290   12504   13099   13615   5482    5392    5336    5378
  #=New Brunswick=#          8898      9360    8705    8314    8977    8005    8307    8819    9044
  #=Nova Scotia=#            8898      9360    8705    8314    8977    9438    9922    9830    9724
  #=Newfoundland=#           8319      8328    8326    9225    11012   11014   11010   11378   11412
  #=PEI=#                    8898      9360    8705    8314    8977    9438    9922    9830    9724
  #=Yukon=#                  12652     12643   13645   14232   9848    12178   11387   11374   11428
  #=Northwest Territory=#    12652     12643   13645   14232   9848    12178   11387   11374   11428
  #=Nunavut=#                12652     12643   13645   14232   9848    12178   11387   11374   11428
  ]
  for year in years, area in areas, ec in ECs
    xCgHRtA[tech,ec,area,year] = xCgHRtA[tech,1,area,Yr(2000)]
  end
  years = collect(Yr(1985):Yr(1999))
  for year in years, area in areas, ec in ECs
    xCgHRtA[tech,ec,area,year] = xCgHRtA[tech,ec,area,Yr(2000)]
  end
  years = collect(Yr(2009):Final)
  for year in years, area in areas, ec in ECs
    xCgHRtA[tech,ec,area,year] = xCgHRtA[tech,ec,area,Yr(2008)]
  end
  
  #
  # For Canada set histoical marginal (CgHRtM) equal to historical average (xCgHRtA)
  #
  years = collect(Zero:Last)
  for year in years, area in areas, ec in ECs
    CgHRtM[tech,ec,area,year] = xCgHRtA[tech,ec,area,year]
  end

  #
  # Oil Sands Heat Rates
  #
  ecs = Select(EC,["SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders"])
  years = collect(Yr(2004):Yr(2010))
  xCgHRtA[tech,ecs,AB,years] .= [
  #/                           2004   2005   2006   2007   2008   2009   2010
  #=SAGD Oil Sands=#          13648  13648  13648  13648  13648  13648  13648
  #=CSS Oil Sands=#            6540   6540   6540   6540   6540   6540   6540
  #=Oil Sands Mining=#        10154   9928  13031  12680  12682  12463  12260
  #=Oil Sands Upgraders=#      9763   9763   9763   9763   9763   9763   9763
  ]
  Gas = Select(Tech,"Gas")
  for year in years, ec in ecs, tech in Techs 
    xCgHRtA[tech,ec,AB,year] = xCgHRtA[Gas,ec,AB,year]
  end
  years = collect(Yr(1985):Yr(2003))
  for year in years, ec in ecs, tech in Techs 
    xCgHRtA[tech,ec,AB,year] = xCgHRtA[tech,ec,AB,Yr(2004)]
  end
  years = collect(Yr(2011):Final)
  for year in years, ec in ecs, tech in Techs 
    xCgHRtA[tech,ec,AB,year] = xCgHRtA[tech,ec,AB,Yr(2010)]
  end

  for year in Years, ec in ecs, tech in Techs 
    CgHRtM[tech,ec,AB,year] = xCgHRtA[tech,ec,AB,year]
  end
  
  #
  # Cut Heat Rates in half until we get better numbers
  # - Jeff Amlin 6/22/13
  #
  for year in Years, area in Areas, ec in ECs, tech in Techs
    CgHRtM[tech,ec,area,year] = CgHRtM[tech,ec,area,year]/2
  end 
  Solar = Select(Tech,"Solar")
  for year in Years, area in Areas, ec in ECs
    CgHRtM[Solar,ec,area,year] = 1
  end  
  for year in Years, area in Areas, ec in ECs, tech in Techs
    xCgHRtA[tech,ec,area,year] = xCgHRtA[tech,ec,area,year]/2
  end
  Solar = Select(Tech,"Solar")
  for year in Years, area in Areas, ec in ECs
    xCgHRtA[Solar,ec,area,year] = 1
  end
  
  WriteDisk(db,"$Input/CgHRtM",CgHRtM)
  WriteDisk(db,"$Input/xCgHRtA",xCgHRtA)

end

function CalibrationControl(db)
  @info "CogenHeatRates.jl - CalibrationControl"

  CCalibration(db)
  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
