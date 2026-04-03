#
# IronSteel_EfficiencyInputs.jl - Assign curve parameters and switches for
#                            selected industrial sectors and technologies
#
using EnergyModel

module IronSteel_EfficiencyInputs

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ICalib
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
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
  DCCA0::VariableArray{5} = ReadDisk(db,"$Input/DCCA0") # [Enduse,Tech,EC,Area,Year] Device Capital Cost A0 Coeffcient for Efficiency Program (Btu/Btu)
  DCCB0::VariableArray{5} = ReadDisk(db,"$Input/DCCB0") # [Enduse,Tech,EC,Area,Year] Device Capital Cost B0 Coeffcient for Efficiency Program (Btu/Btu)
  DCCC0::VariableArray{5} = ReadDisk(db,"$Input/DCCC0") # [Enduse,Tech,EC,Area,Year] Device Capital Cost C0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEB0::VariableArray{5} = ReadDisk(db,"$Input/DEEB0") # [Enduse,Tech,EC,Area,Year] Device B0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEC0::VariableArray{5} = ReadDisk(db,"$Input/DEEC0") # [Enduse,Tech,EC,Area,Year] Device C0 Coeffcient for Efficiency Program (Btu/Btu)
  DEESw::VariableArray{5} = ReadDisk(db,"$Input/DEESw") # [Enduse,Tech,EC,Area,Year] Switch for Device Efficiency (Switch)
  InitialDemandYear::VariableArray{2} = ReadDisk(db,"$Input/InitialDemandYear") # [EC,Area] First Year of Calibration
  PCCA0::VariableArray{5} = ReadDisk(db,"$Input/PCCA0") # [Enduse,Tech,EC,Area,Year] Process Capital Cost A0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PCCB0::VariableArray{5} = ReadDisk(db,"$Input/PCCB0") # [Enduse,Tech,EC,Area,Year] Process Capital Cost B0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PCCC0::VariableArray{5} = ReadDisk(db,"$Input/PCCC0") # [Enduse,Tech,EC,Area,Year] Process Capital Cost C0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PCCCurveM::VariableArray{5} = ReadDisk(db,"$Outpt/PCCCurveM") # [Enduse,Tech,EC,Area,Year] Process Capital Cost from Cost Curve Multplier (1/1)
  PEEB0::VariableArray{5} = ReadDisk(db,"$Input/PEEB0") # [Enduse,Tech,EC,Area,Year] Process B0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PEEC0::VariableArray{5} = ReadDisk(db,"$Input/PEEC0") # [Enduse,Tech,EC,Area,Year] Process C0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PEECurveM::VariableArray{5} = ReadDisk(db,"$Outpt/PEECurveM") # [Enduse,Tech,EC,Area,Year] Process Efficiency from Cost Curve Multiplier(1/1)
  PEESw::VariableArray{5} = ReadDisk(db,"$Input/PEESw") # [Enduse,Tech,EC,Area,Year] Switch for Process Efficiency (Switch)

  # Scratch Variables
  DCCA0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
  DCCB0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
  DCCC0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
  DEEB0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
  DEEC0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
  InputYear::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Input Data Year
  PCCA0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
  PCCB0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
  PCCC0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
  PEEB0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
  PEEC0Input::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Year)) # [Tech,EC,Year] Data Input Variable
end


function ICalibration(db)
  data = ICalib(; db)
  (;EC,Enduse,Nation) = data
  (;Tech,Years) = data
  (;ANMap,DCCA0,DCCB0,DCCC0,DEEB0,DEEC0,DEESw,Input,PCCA0,PCCB0,Outpt) = data
  (;PCCC0,PCCCurveM,PEEB0,PEEC0,PEECurveM,PEESw) = data


  # *
  # * Default curve value
  # *
  @. PEECurveM = 1.0
  @. PCCCurveM = 1.0

  WriteDisk(db,"$Outpt/PCCCurveM",PCCCurveM)
  WriteDisk(db,"$Outpt/PEECurveM",PEECurveM)

  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  # Iron Steel Process Heat Natural Gas
  #
  IronSteel = Select(EC,"IronSteel")
  Heat = Select(Enduse,"Heat")
  Gas = Select(Tech,"Gas")

  calendar_years = collect(2000:2050)

  # *
  # * DEE=DEEC0+DEEB0*ln(ECFP)
  # * DCC=DCCC0+exp((DEE-DCCB0)/DCCA0)
  # * Source: "20.09.10 Pulp-Paper Natural Gas Process Heat.xlsx", original data from Thou
  # * Ian 10/01/2020
  # *
  @. DEESw[Heat,Gas,IronSteel,areas,Years] = 10.0

  DEECoefficients = zeros(Float32,10,6)
  DEECoefficients[:,:] .= [
  # /             DEEB0   DEEC0    DCCA0    DCCB0    DCCC0
  2000-2005   0.014450  0.803090 0.009416 0.831804 3.014
  2005-2010   0.014652  0.803502 0.009548 0.832362 3.014
  2010-2015   0.014857  0.803926 0.009681 0.832929 3.014
  2015-2020   0.015065  0.804360 0.009817 0.833506 3.014
  2020-2025   0.015277  0.804806 0.009955 0.834093 3.014
  2025-2030   0.015491  0.805263 0.010094 0.834690 3.014
  2030-2035   0.015708  0.805732 0.010236 0.835297 3.014
  2035-2040   0.015929  0.806214 0.010380 0.835915 3.014
  2040-2045   0.016153  0.806707 0.010526 0.836544 3.014
  2045-2050   0.016381  0.807213 0.010674 0.837183 3.014
  ]

  # *
  # * PEE=PEEC0+PEEB0*ln(MCFU)
  # * PCC=PCCC0+exp((PEE-PCCB0)/PCCA0)
  # * Source: "20.09.10 Pulp-Paper Natural Gas Process Heat.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *

  @. PEESw[Heat,Gas,IronSteel,areas,Years] = 10.0
  PEECoefficients = zeros(Float32,10,6)

  PEECoefficients[:,:] .= [
  # /             PEEB0     PEEC0    PCCA0    PCCB0  PCCC0
  2000-2005   09.88822  71.64537 3.784498 101.2696 0.4328
  2005-2010   10.18082  71.58871 3.863534 101.8444 0.4328
  2010-2015   10.48358  71.52891 3.944463 102.4325 0.4328
  2015-2020   10.79693  71.46581 4.027338 103.0340 0.4328
  2020-2025   11.12126  71.39927 4.112215 103.6494 0.4328
  2025-2030   11.45702  71.32911 4.199151 104.2791 0.4328
  2030-2035   11.80467  71.25516 4.288203 104.9234 0.4328
  2035-2040   12.16469  71.17726 4.379432 105.5828 0.4328
  2040-2045   12.53757  71.09521 4.472902 106.2577 0.4328
  2045-2050   12.92383  71.00882 4.568678 106.9485 0.4328
  ]

  for year in calendar_years, area in areas
    gap = min((div((year - 2000) , 5)) + 1, 10)
    DEEB0[Heat,Gas,IronSteel,area,Yr(year)] = DEECoefficients[gap,2]
    DEEC0[Heat,Gas,IronSteel,area,Yr(year)] = DEECoefficients[gap,3]
    DCCA0[Heat,Gas,IronSteel,area,Yr(year)] = DEECoefficients[gap,4]
    DCCB0[Heat,Gas,IronSteel,area,Yr(year)] = DEECoefficients[gap,5]
    DCCC0[Heat,Gas,IronSteel,area,Yr(year)] = DEECoefficients[gap,6]

    PEEB0[Heat,Gas,IronSteel,area,Yr(year)] = PEECoefficients[gap,2]
    PEEC0[Heat,Gas,IronSteel,area,Yr(year)] = PEECoefficients[gap,3]
    PCCA0[Heat,Gas,IronSteel,area,Yr(year)] = PEECoefficients[gap,4]
    PCCB0[Heat,Gas,IronSteel,area,Yr(year)] = PEECoefficients[gap,5]
    PCCC0[Heat,Gas,IronSteel,area,Yr(year)] = PEECoefficients[gap,6]
  end


  # *
  # * Iron Steel Process Heat Coal
  # *
  Coal = Select(Tech,"Coal")
  # *
  # * DEE=DEEC0+DEEB0*ln(ECFP)
  # * DCC=DCCC0+exp((DEE-DCCB0)/DCCA0)
  # * Source: "20.09.21 Iron Steel Coal Process Heat.xlsx", original data from Thou
  # * Ian 10/01/2020
  # *
  @. DEESw[Heat,Coal,IronSteel,areas,Years] = 10.0
  DEECoefficients[:,:] .= [
  # /             DEEB0   DEEC0    DCCA0    DCCB0    DCCC0
  2000-2005   0.037820  0.696663 0.017777 0.799488 5.668
  2005-2010   0.038362  0.696304 0.018031 0.799839 5.668
  2010-2015   0.038912  0.695953 0.018289 0.800199 5.668
  2015-2020   0.039470  0.695609 0.018552 0.800567 5.668
  2020-2025   0.040037  0.695272 0.018818 0.800944 5.668
  2025-2030   0.040613  0.694943 0.019088 0.801329 5.668
  2030-2035   0.041198  0.694623 0.019363 0.801723 5.668
  2035-2040   0.041792  0.694311 0.019642 0.802126 5.668
  2040-2045   0.042396  0.694007 0.019925 0.802538 5.668
  2045-2050   0.043009  0.693713 0.020213 0.802959 5.668
  ]
  # *
  # * PEE=PEEC0+PEEB0*ln(MCFU)
  # * PCC=PCCC0+exp((PEE-PCCB0)/PCCA0)
  # * Source: "20.09.21 Iron Steel Coal Process Heat.xlsx", original data from Thou
  # * Ian 10/01/2020
  # *
  @. PEESw[Heat,Coal,IronSteel,areas,Years] = 10.0
  PEECoefficients[:,:] .= [
  # /             PEEB0   PEEC0    PCCA0    PCCB0   PCCC0
  2000-2005   4.351765  46.06216 2.528516 58.45159 0.4328
  2005-2010   4.472954  46.06777 2.577930 58.72990 0.4328
  2010-2015   4.597939  46.07291 2.628355 59.01412 0.4328
  2015-2020   4.726854  46.07757 2.679816 59.30437 0.4328
  2020-2025   4.908224  46.03976 2.747809 59.65483 0.4328
  2025-2030   5.053610  46.03666 2.803796 59.96614 0.4328
  2030-2035   5.203777  46.03275 2.860957 60.28420 0.4328
  2035-2040   5.358901  46.02797 2.919318 60.60918 0.4328
  2040-2045   5.526506  46.02070 2.984240 60.96336 0.4328
  2045-2050   5.692766  46.01379 3.045427 61.30411 0.4328
  ]

  for year in calendar_years, area in areas
    gap = min((div((year - 2000) , 5)) + 1, 10)
    DEEB0[Heat,Coal,IronSteel,area,Yr(year)] = DEECoefficients[gap,2]
    DEEC0[Heat,Coal,IronSteel,area,Yr(year)] = DEECoefficients[gap,3]
    DCCA0[Heat,Coal,IronSteel,area,Yr(year)] = DEECoefficients[gap,4]
    DCCB0[Heat,Coal,IronSteel,area,Yr(year)] = DEECoefficients[gap,5]
    DCCC0[Heat,Coal,IronSteel,area,Yr(year)] = DEECoefficients[gap,6]

    PEEB0[Heat,Coal,IronSteel,area,Yr(year)] = PEECoefficients[gap,2]
    PEEC0[Heat,Coal,IronSteel,area,Yr(year)] = PEECoefficients[gap,3]
    PCCA0[Heat,Coal,IronSteel,area,Yr(year)] = PEECoefficients[gap,4]
    PCCB0[Heat,Coal,IronSteel,area,Yr(year)] = PEECoefficients[gap,5]
    PCCC0[Heat,Coal,IronSteel,area,Yr(year)] = PEECoefficients[gap,6]
  end


  # *
  # * Iron Steel Process Heat Oil
  # *
  Oil = Select(Tech,"Oil")
  # *
  # * DEE=DEEC0+DEEB0*ln(ECFP)
  # * DCC=DCCC0+exp((DEE-DCCB0)/DCCA0)
  # * Source: "20.09.21 Iron Steel Fuel Oil Process Heat.xlsx", original data from Thou
  # * Ian 10/01/2020
  # *
  @. DEESw[Heat,Oil,IronSteel,areas,Years] = 10.0
  DEECoefficients[:,:] .= [
  # /             DEEB0   DEEC0    DCCA0    DCCB0    DCCC0
  2000-2005   0.039041  0.666151 0.018222 0.784633 5.668
  2005-2010   0.039595  0.665404 0.018480 0.784779 5.668
  2010-2015   0.040158  0.664659 0.018743 0.784930 5.668
  2015-2020   0.040729  0.663915 0.019010 0.785086 5.668
  2020-2025   0.041309  0.663174 0.019280 0.785247 5.668
  2025-2030   0.041898  0.662434 0.019555 0.785413 5.668
  2030-2035   0.042495  0.661697 0.019834 0.785585 5.668
  2035-2040   0.043102  0.660963 0.020118 0.785762 5.668
  2040-2045   0.043719  0.660231 0.020405 0.785945 5.668
  2045-2050   0.044345  0.659503 0.020698 0.786133 5.668
  ]

  # *
  # * PEE=PEEC0+PEEB0*ln(MCFU)
  # * PCC=PCCC0+exp((PEE-PCCB0)/PCCA0)
  # * Source: "20.09.21 Iron Steel Fuel Oil Process Heat.xlsx", original data from Thou
  # * Ian 10/01/2020
  # *
  @. PEESw[Heat,Oil,IronSteel,areas,Years] = 10.0
  PEECoefficients[:,:] .= [
  # /             PEEB0   PEEC0    PCCA0    PCCB0   PCCC0
  2000-2005   3.145397  20.88695 1.485146 28.25284 0.4328
  2005-2010   3.164148  20.88805 1.485146 28.27212 0.4328
  2010-2015   3.183143  20.88901 1.485146 28.29140 0.4328
  2015-2020   3.202384  20.88983 1.485146 28.31068 0.4328
  2020-2025   3.221875  20.89051 1.485146 28.32996 0.4328
  2025-2030   3.241620  20.89105 1.485146 28.34924 0.4328
  2030-2035   3.261620  20.89145 1.485146 28.36853 0.4328
  2035-2040   3.281881  20.89170 1.485146 28.38781 0.4328
  2040-2045   3.302404  20.89181 1.485146 28.40709 0.4328
  2045-2050   3.323195  20.89177 1.485146 28.42637 0.4328
  ]

  for year in calendar_years, area in areas
    gap = min((div((year - 2000) , 5)) + 1, 10)
    DEEB0[Heat,Oil,IronSteel,area,Yr(year)] = DEECoefficients[gap,2]
    DEEC0[Heat,Oil,IronSteel,area,Yr(year)] = DEECoefficients[gap,3]
    DCCA0[Heat,Oil,IronSteel,area,Yr(year)] = DEECoefficients[gap,4]
    DCCB0[Heat,Oil,IronSteel,area,Yr(year)] = DEECoefficients[gap,5]
    DCCC0[Heat,Oil,IronSteel,area,Yr(year)] = DEECoefficients[gap,6]

    PEEB0[Heat,Oil,IronSteel,area,Yr(year)] = PEECoefficients[gap,2]
    PEEC0[Heat,Oil,IronSteel,area,Yr(year)] = PEECoefficients[gap,3]
    PCCA0[Heat,Oil,IronSteel,area,Yr(year)] = PEECoefficients[gap,4]
    PCCB0[Heat,Oil,IronSteel,area,Yr(year)] = PEECoefficients[gap,5]
    PCCC0[Heat,Oil,IronSteel,area,Yr(year)] = PEECoefficients[gap,6]
  end


  # *
  # * Iron Steel Electric Machine Drive
  # *
  Electric = Select(Tech,"Electric")
  Motors = Select(Enduse,"Motors")

  # *
  # * DEE=DEEC0+DEEB0/ECFP
  # * DCC=DCCC0+exp((DEE-DCCB0)/DCCA0)
  # * Source: "20.09.21 Iron Steel Elec Machine Drive.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *
  @. DEESw[Motors,Electric,IronSteel,areas,Years] = 12.0
  DEECoefficients[:,:] .= [
  # /             DEEB0     DEEC0    DCCA0    DCCB0  DCCC0
  2000-2005   -0.64375  0.917291 0.012080 0.880000 0.000
  2005-2010   -0.66748  0.919228 0.012523 0.880000 0.000
  2010-2015   -0.68820  0.921162 0.013002 0.881000 0.000
  2015-2020   -0.70930  0.923162 0.013428 0.881000 0.000
  2020-2025   -0.73066  0.925226 0.013856 0.881000 0.000
  2025-2030   -0.75155  0.927263 0.014293 0.882000 0.000
  2030-2035   -0.77385  0.929487 0.014729 0.882000 0.000
  2035-2040   -0.79649  0.931786 0.015167 0.882000 0.000
  2040-2045   -0.81949  0.934165 0.015607 0.883000 0.000
  2045-2050   -0.84287  0.936627 0.016050 0.883000 0.000
  ]

  # *
  # * PEE=PCCC0+PCCB0*ln(PCC)
  # * PCC=exp((PEE-PCCC0)/PCCB0)
  # * Source: "20.09.10 Pulp-Paper Elec Machine Drive.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *
  @. PEESw[Motors,Electric,IronSteel,areas,Years] = 11.0
  PEECoefficients[:,:] .= [
  # /             PEEB0     PEEC0    PCCA0    PCCB0   PCCC0
  2000-2005   -156.8713 328.4776 -99.0000 10.04348 312.39
  2005-2010   -158.6526 330.0116 -99.0000 10.10903 313.26
  2010-2015   -160.4614 331.5678 -99.0000 10.17520 314.15
  2015-2020   -162.2984 333.1464 -99.0000 10.24202 315.04
  2020-2025   -164.1641 334.7480 -99.0000 10.30947 315.94
  2025-2030   -166.0588 336.3730 -99.0000 10.37759 316.85
  2030-2035   -167.9832 338.0216 -99.0000 10.44636 317.77
  2035-2040   -169.9377 339.6943 -99.0000 10.51581 318.70
  2040-2045   -171.9230 341.3916 -99.0000 10.58594 319.63
  2045-2050   -173.9395 343.1139 -99.0000 10.65676 320.58
  ]
  # *
  # * Remove PCC from Motors for now (zeroing out PCC inputs) - Ian 10/07/20
  # *

  years = collect(Yr(2000):Yr(2050))
  @. PCCA0[Motors,Electric,IronSteel,areas,years]=0.0
  @. PCCB0[Motors,Electric,IronSteel,areas,years]=0.0
  @. PCCC0[Motors,Electric,IronSteel,areas,years]=0.0

  for year in calendar_years, area in areas
    gap = min((div((year - 2000) , 5)) + 1, 10)
    DEEB0[Motors,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,2]
    DEEC0[Motors,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,3]
    DCCA0[Motors,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,4]
    DCCB0[Motors,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,5]
    DCCC0[Motors,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,6]

    PEEB0[Motors,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,2]
    PEEC0[Motors,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,3]
    PCCA0[Motors,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,4]
    PCCB0[Motors,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,5]
    PCCC0[Motors,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,6]
  end



  # *
  # * Iron Steel Electric Arc Furnace
  # *
  # * DEE=DEEC0+DEEB0/ECFP
  # * DCC=DCC=DCCC0+exp((DEE-DCCB0)/DCCA0)
  # * Source: "20.09.21 Iron Steel Elec Machine Drive.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *
  @. DEESw[Heat,Electric,IronSteel,areas,Years] = 12.0
  DEECoefficients[:,:] .= [
  # /             DEEB0     DEEC0    DCCA0    DCCB0  DCCC0
  2000-2005   -0.53846  0.956090 0.008314 0.928000 0.000
  2005-2010   -0.56111  0.957733 0.008920 0.928000 0.000
  2010-2015   -0.58707  0.959461 0.009444 0.928000 0.000
  2015-2020   -0.61300  0.961219 0.009968 0.928000 0.000
  2020-2025   -0.63890  0.963006 0.010494 0.928000 0.000
  2025-2030   -0.65515  0.964511 0.011029 0.928000 0.000
  2030-2035   -0.67984  0.966311 0.011545 0.928000 0.000
  2035-2040   -0.70448  0.968138 0.012063 0.928000 0.000
  2040-2045   -0.72907  0.969994 0.012582 0.928000 0.000
  2045-2050   -0.75361  0.971878 0.013103 0.928000 0.000
  ]
  # *
  # * PEE=PEEC0+PEEB0/sqrt(MCFU)
  # * PCC=exp((PEE-PCCC0)/PCCB0)
  # * Source: "20.09.10 Pulp-Paper Elec Machine Drive.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *
  @. PEESw[Heat,Electric,IronSteel,areas,Years] = 11.0
  PEECoefficients[:,:] .= [
  # /             PEEB0     PEEC0    PCCA0    PCCB0   PCCC0
  2000-2005   -123.0170 252.1182 -99.0000 4.500913 240.0383
  2005-2010   -123.4960 252.5054 -99.0000 4.532289 240.2910
  2010-2015   -123.9270 252.8970 -99.0000 4.563898 240.5458
  2015-2020   -124.3920 253.2930 -99.0000 4.595742 240.8027
  2020-2025   -124.8630 253.6937 -99.0000 4.627823 241.0616
  2025-2030   -125.3410 254.0989 -99.0000 4.660142 241.3226
  2030-2035   -125.8260 254.5088 -99.0000 4.692702 241.5858
  2035-2040   -126.3180 254.9235 -99.0000 4.725504 241.8511
  2040-2045   -126.8160 255.3430 -99.0000 4.758551 242.1186
  2045-2050   -127.3220 255.7674 -99.0000 4.791845 242.3882
  ]

  for year in calendar_years, area in areas
    gap = min((div((year - 2000) , 5)) + 1, 10)
    DEEB0[Heat,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,2]
    DEEC0[Heat,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,3]
    DCCA0[Heat,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,4]
    DCCB0[Heat,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,5]
    DCCC0[Heat,Electric,IronSteel,area,Yr(year)] = DEECoefficients[gap,6]

    PEEB0[Heat,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,2]
    PEEC0[Heat,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,3]
    PCCA0[Heat,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,4]
    PCCB0[Heat,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,5]
    PCCC0[Heat,Electric,IronSteel,area,Yr(year)] = PEECoefficients[gap,6]
  end

  # * Set initialization year to 2000
  # *
  # *InitialDemandYear(EC,A)=2000
  # *
  # *Write Disk(InitialDemandYear)
  # *

  #
  backfill_years=collect(Zero:Yr(1999))
  techs=Select(Tech,["Gas","Coal","Oil","Electric"])
  for year in backfill_years, area in areas, tech in techs
    DEEB0[Heat,tech,IronSteel,area,year] = DEEB0[Heat,tech,IronSteel,area,Yr(2000)]
    DEEC0[Heat,tech,IronSteel,area,year] = DEEC0[Heat,tech,IronSteel,area,Yr(2000)]
    DCCA0[Heat,tech,IronSteel,area,year] = DCCA0[Heat,tech,IronSteel,area,Yr(2000)]
    DCCB0[Heat,tech,IronSteel,area,year] = DCCB0[Heat,tech,IronSteel,area,Yr(2000)]
    DCCC0[Heat,tech,IronSteel,area,year] = DCCC0[Heat,tech,IronSteel,area,Yr(2000)]

    PEEB0[Heat,tech,IronSteel,area,year] = PEEB0[Heat,tech,IronSteel,area,Yr(2000)]
    PEEC0[Heat,tech,IronSteel,area,year] = PEEC0[Heat,tech,IronSteel,area,Yr(2000)]
    PCCA0[Heat,tech,IronSteel,area,year] = PCCA0[Heat,tech,IronSteel,area,Yr(2000)]
    PCCB0[Heat,tech,IronSteel,area,year] = PCCB0[Heat,tech,IronSteel,area,Yr(2000)]
    PCCC0[Heat,tech,IronSteel,area,year] = PCCC0[Heat,tech,IronSteel,area,Yr(2000)]
  end
  techs=Select(Tech,"Electric")
  for year in backfill_years, area in areas, tech in techs
    DEEB0[Motors,tech,IronSteel,area,year] = DEEB0[Motors,tech,IronSteel,area,Yr(2000)]
    DEEC0[Motors,tech,IronSteel,area,year] = DEEC0[Motors,tech,IronSteel,area,Yr(2000)]
    DCCA0[Motors,tech,IronSteel,area,year] = DCCA0[Motors,tech,IronSteel,area,Yr(2000)]
    DCCB0[Motors,tech,IronSteel,area,year] = DCCB0[Motors,tech,IronSteel,area,Yr(2000)]
    DCCC0[Motors,tech,IronSteel,area,year] = DCCC0[Motors,tech,IronSteel,area,Yr(2000)]

    PEEB0[Motors,tech,IronSteel,area,year] = PEEB0[Motors,tech,IronSteel,area,Yr(2000)]
    PEEC0[Motors,tech,IronSteel,area,year] = PEEC0[Motors,tech,IronSteel,area,Yr(2000)]
    PCCA0[Motors,tech,IronSteel,area,year] = PCCA0[Motors,tech,IronSteel,area,Yr(2000)]
    PCCB0[Motors,tech,IronSteel,area,year] = PCCB0[Motors,tech,IronSteel,area,Yr(2000)]
    PCCC0[Motors,tech,IronSteel,area,year] = PCCC0[Motors,tech,IronSteel,area,Yr(2000)]
  end




  WriteDisk(db,"$Input/DEESw",DEESw)
  WriteDisk(db,"$Input/DEEB0",DEEB0)
  WriteDisk(db,"$Input/DEEC0",DEEC0)
  WriteDisk(db,"$Input/DCCA0",DCCA0)
  WriteDisk(db,"$Input/DCCB0",DCCB0)
  WriteDisk(db,"$Input/DCCC0",DCCC0)
  WriteDisk(db,"$Input/PEESw",PEESw)
  WriteDisk(db,"$Input/PEEB0",PEEB0)
  WriteDisk(db,"$Input/PEEC0",PEEC0)
  WriteDisk(db,"$Input/PCCA0",PCCA0)
  WriteDisk(db,"$Input/PCCB0",PCCB0)
  WriteDisk(db,"$Input/PCCC0",PCCC0)



end

function CalibrationControl(db)
  @info "IronSteel_EfficiencyInputs.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
