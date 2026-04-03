#
# PulpPaper_EfficiencyInputs.jl - Assign curve parameters and switches for
#                            selected industrial sectors and technologies
#
using EnergyModel

module PulpPaper_EfficiencyInputs

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


end


function ICalibration(db)
  data = ICalib(; db)
  (;EC,Enduse,Nation) = data
  (;Tech,Years) = data
  (;ANMap,DCCA0,DCCB0,DCCC0,DEEB0,DEEC0,DEESw,PCCA0,PCCB0) = data
  (;PCCC0,PCCCurveM,PEEB0,PEEC0,PEECurveM,PEESw) = data
  (;Input, Outpt) = data

  # *
  # * Default curve value
  # *
  @. PEECurveM = 1.0
  @. PCCCurveM = 1.0

  WriteDisk(db,"$Outpt/PCCCurveM",PCCCurveM)
  WriteDisk(db,"$Outpt/PEECurveM",PEECurveM)

  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  # *
  # * Pulp Paper Process Heat Natural Gas
  # *
  PulpPaperMills = Select(EC,"PulpPaperMills")
  Heat = Select(Enduse,"Heat")
  Gas = Select(Tech,"Gas")

  calendar_years = collect(2000:2050)

  # *
  # * DEE=DEEC0+DEEB0*ln(ECFP)
  # * DCC=DCCC0+exp((DEE-DCCB0)/DCCA0)
  # * Source: "20.09.10 Pulp-Paper Natural Gas Process Heat.xlsx", original data from Thou
  # * Ian 10/01/2020
  # *
  @. DEESw[Heat,Gas,PulpPaperMills,areas,Years]=10.0

  DEECoefficients = zeros(Float32,10,6)
  DEECoefficients[:,:] .= [
  # /             DEEB0     DEEC0    DCCA0    DCCB0  DCCC0
  2000-2005   0.020369  0.818119 0.010706 0.855571 5.668
  2005-2010   0.020535  0.818346 0.010787 0.855895 5.668
  2010-2015   0.020701  0.818577 0.010868 0.856221 5.668
  2015-2020   0.020869  0.818812 0.010949 0.856551 5.668
  2020-2025   0.021039  0.819051 0.011032 0.856883 5.668
  2025-2030   0.021210  0.819293 0.011115 0.857219 5.668
  2030-2035   0.021382  0.819540 0.011198 0.857557 5.668
  2035-2040   0.021556  0.819791 0.011282 0.857899 5.668
  2040-2045   0.021731  0.820045 0.011367 0.858243 5.668
  2045-2050   0.021908  0.820304 0.011453 0.858591 5.668
  ]

  # *
  # * PEE=PEEC0+PEEB0*ln(MCFU)
  # * PCC=PCCC0+exp((PEE-PCCB0)/PCCA0)
  # * Source: "20.09.10 Pulp-Paper Natural Gas Process Heat.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *

  @. PEESw[Heat,Gas,PulpPaperMills,areas,Years]=10.0
  PEECoefficients = zeros(Float32,10,6)

  PEECoefficients[:,:] .= [
  # /             PEEB0     PEEC0    PCCA0    PCCB0   PCCC0
  2000-2005   10.76453  92.82350 4.475210 129.5480  0.4328
  2005-2010   11.03917  92.65731 4.536551 129.9720  0.4328
  2010-2015   11.32282  92.48737 4.599136 130.4050  0.4328
  2015-2020   11.61575  92.31369 4.663000 130.8470  0.4328
  2020-2025   11.91826  92.13626 4.728176 131.2980  0.4328
  2025-2030   12.23062  91.95514 4.794701 131.7580  0.4328
  2030-2035   12.55311  91.77036 4.862610 132.2290  0.4328
  2035-2040   12.88601  91.58199 4.931943 132.7090  0.4328
  2040-2045   13.22959  91.39013 5.002738 133.2010  0.4328
  2045-2050   13.58411  91.19489 5.075037 133.7020  0.4328
  ]

  for year in calendar_years, area in areas
    gap = min((div((year - 2000) , 5)) + 1, 10)
    DEEB0[Heat,Gas,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,2]
    DEEC0[Heat,Gas,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,3]
    DCCA0[Heat,Gas,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,4]
    DCCB0[Heat,Gas,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,5]
    DCCC0[Heat,Gas,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,6]

    PEEB0[Heat,Gas,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,2]
    PEEC0[Heat,Gas,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,3]
    PCCA0[Heat,Gas,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,4]
    PCCB0[Heat,Gas,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,5]
    PCCC0[Heat,Gas,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,6]
  end

  # *
  # * Pulp Paper Process Heat Biomass
  # *
  Biomass = Select(Tech,"Biomass")
  # *
  # * DEE=DEEC0+DEEB0*ln(ECFP)
  # * DCC=DCCC0+exp((DEE-DCCB0)/DCCA0)
  # * Source: "20.09.10 Pulp-Paper Biomass Process Heat.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *

  @. DEESw[Heat,Biomass,PulpPaperMills,areas,Years]=10.0
  DEECoefficients[:,:] .= [
  # /             DEEB0     DEEC0    DCCA0    DCCB0  DCCC0
  2000-2005   0.022939  0.638977 0.010870 0.675555 5.668
  2005-2010   0.023299  0.639080 0.010999 0.675930 5.668
  2010-2015   0.023666  0.639187 0.011130 0.676310 5.668
  2015-2020   0.024040  0.639300 0.011263 0.676695 5.668
  2020-2025   0.024420  0.639419 0.011398 0.677086 5.668
  2025-2030   0.024808  0.639543 0.011535 0.677482 5.668
  2030-2035   0.025203  0.639673 0.011673 0.677884 5.668
  2035-2040   0.025605  0.639809 0.011813 0.678291 5.668
  2040-2045   0.026014  0.639951 0.011955 0.678704 5.668
  2045-2050   0.026431  0.640099 0.012099 0.679124 5.668
  ]
  # *
  # * PEE=PEEC0+PEEB0*ln(MCFU)
  # * PCC=PCCC0+exp((PEE-PCCB0)/PCCA0)
  # * Source: "20.09.10 Pulp-Paper Biomass Process Heat.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *
  @. PEESw[Heat,Biomass,PulpPaperMills,areas,Years]=10.0
  PEECoefficients[:,:] .= [
  # /             PEEB0     PEEC0    PCCA0    PCCB0   PCCC0
  2000-2005   8.361001  93.22109 3.886231 124.4896 0.4328
  2005-2010   8.516138  93.14095 3.926548 124.7801 0.4328
  2010-2015   8.675352  93.05913 3.967454 125.0751 0.4328
  2015-2020   8.838772  92.97560 4.008958 125.3747 0.4328
  2020-2025   9.006532  92.89030 4.051072 125.6791 0.4328
  2025-2030   9.178772  92.80320 4.093804 125.9882 0.4328
  2030-2035   9.355635  92.71424 4.137166 126.3021 0.4328
  2035-2040   9.537270  92.62338 4.181168 126.6210 0.4328
  2040-2045   9.723831  92.53058 4.225821 126.9449 0.4328
  2045-2050   9.915480  92.43579 4.271136 127.2740 0.4328
  ]

  for year in calendar_years, area in areas
    gap = min((div((year - 2000) , 5)) + 1, 10)
    DEEB0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,2]
    DEEC0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,3]
    DCCA0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,4]
    DCCB0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,5]
    DCCC0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,6]

    PEEB0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,2]
    PEEC0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,3]
    PCCA0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,4]
    PCCB0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,5]
    PCCC0[Heat,Biomass,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,6]
  end

  # *
  # * Pulp Paper Electric Drive
  # *
  Electric = Select(Tech,"Electric")
  Motors = Select(Enduse,"Motors")
  # *
  # * DEE=DEEC0+DEEB0/sqrt(ECFP)
  # * DCC=DCC0+exp((DEE-DCCB0)/DCCA0)
  # * Source: "20.09.10 Pulp-Paper Biomass Process Heat.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *
  @. DEESw[Motors,Electric,PulpPaperMills,areas,Years] = 11.0
  DEECoefficients[:,:] .= [
  # /             DEEB0     DEEC0    DCCA0    DCCB0  DCCC0
  2000-2005   -0.45532  0.996440 0.033241 0.846000 0.000
  2005-2010   -0.45900  0.998122 0.033241 0.846000 0.000
  2010-2015   -0.46278  0.999843 0.033241 0.846000 0.000
  2015-2020   -0.46664  1.001605 0.033241 0.846000 0.000
  2020-2025   -0.47060  1.003408 0.033241 0.846000 0.000
  2025-2030   -0.47465  1.005255 0.033241 0.846000 0.000
  2030-2035   -0.47881  1.007145 0.033241 0.846000 0.000
  2035-2040   -0.48306  1.009082 0.033241 0.846000 0.000
  2040-2045   -0.48742  1.011066 0.033241 0.846000 0.000
  2045-2050   -0.49189  1.013099 0.033241 0.846000 0.000
  ]

  # *
  # * PEE=PEEC0+PEEB0/sqrt(MCFU)
  # * PCC=exp((PEE-PCCC0)/PCCB0)
  # * Source: "20.09.10 Pulp-Paper Biomass Process Heat.xlsx", original data from Thuo
  # * Ian 10/01/2020
  # *
  @. PEESw[Motors,Electric,PulpPaperMills,areas,Years] = 11.0
  PEECoefficients[:,:] .= [
  # /             PEEB0     PEEC0    PCCA0    PCCB0   PCCC0
  2000-2005   -143.601  323.3588 -99.0000 11.89720 319.44
  2005-2010   -144.581  324.2146 -99.0000 11.96283 320.13
  2010-2015   -145.571  325.0791 -99.0000 12.02899 320.81
  2015-2020   -146.570  325.9526 -99.0000 12.09568 321.51
  2020-2025   -147.580  326.8352 -99.0000 12.16291 322.20
  2025-2030   -148.601  327.7269 -99.0000 12.23069 322.91
  2030-2035   -149.631  328.6278 -99.0000 12.29901 323.62
  2035-2040   -150.673  329.5382 -99.0000 12.36789 324.34
  2040-2045   -151.725  330.4581 -99.0000 12.43733 325.06
  2045-2050   -152.788  331.3876 -99.0000 12.50734 325.79
  ]
  # *
  # * Remove PCC from Motors for now (zeroing out PCC inputs) - Ian 10/07/20
  # *
  years = collect(Yr(2000):Yr(2050))
  @. PCCA0[Motors,Electric,PulpPaperMills,areas,years]=0.0
  @. PCCB0[Motors,Electric,PulpPaperMills,areas,years]=0.0
  @. PCCC0[Motors,Electric,PulpPaperMills,areas,years]=0.0

  for year in calendar_years, area in areas
    gap = min((div((year - 2000) , 5)) + 1, 10)
    DEEB0[Motors,Electric,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,2]
    DEEC0[Motors,Electric,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,3]
    DCCA0[Motors,Electric,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,4]
    DCCB0[Motors,Electric,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,5]
    DCCC0[Motors,Electric,PulpPaperMills,area,Yr(year)] = DEECoefficients[gap,6]

    PEEB0[Motors,Electric,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,2]
    PEEC0[Motors,Electric,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,3]
    PCCA0[Motors,Electric,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,4]
    PCCB0[Motors,Electric,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,5]
    PCCC0[Motors,Electric,PulpPaperMills,area,Yr(year)] = PEECoefficients[gap,6]
  end

  # *
  # * Set initialization year to 2000
  # *
  # *InitialDemandYear(EC,A)=2000
  # *
  # *Write Disk(InitialDemandYear)
  # *

  #
  backfill_years=collect(Zero:Yr(1999))
  techs=Select(Tech,["Gas","Biomass"])
  for year in backfill_years, area in areas, tech in techs
    DEEB0[Heat,tech,PulpPaperMills,area,year] = DEEB0[Heat,tech,PulpPaperMills,area,Yr(2000)]
    DEEC0[Heat,tech,PulpPaperMills,area,year] = DEEC0[Heat,tech,PulpPaperMills,area,Yr(2000)]
    DCCA0[Heat,tech,PulpPaperMills,area,year] = DCCA0[Heat,tech,PulpPaperMills,area,Yr(2000)]
    DCCB0[Heat,tech,PulpPaperMills,area,year] = DCCB0[Heat,tech,PulpPaperMills,area,Yr(2000)]
    DCCC0[Heat,tech,PulpPaperMills,area,year] = DCCC0[Heat,tech,PulpPaperMills,area,Yr(2000)]

    PEEB0[Heat,tech,PulpPaperMills,area,year] = PEEB0[Heat,tech,PulpPaperMills,area,Yr(2000)]
    PEEC0[Heat,tech,PulpPaperMills,area,year] = PEEC0[Heat,tech,PulpPaperMills,area,Yr(2000)]
    PCCA0[Heat,tech,PulpPaperMills,area,year] = PCCA0[Heat,tech,PulpPaperMills,area,Yr(2000)]
    PCCB0[Heat,tech,PulpPaperMills,area,year] = PCCB0[Heat,tech,PulpPaperMills,area,Yr(2000)]
    PCCC0[Heat,tech,PulpPaperMills,area,year] = PCCC0[Heat,tech,PulpPaperMills,area,Yr(2000)]
  end
  techs=Select(Tech,"Electric")
  for year in backfill_years, area in areas, tech in techs
    DEEB0[Motors,tech,PulpPaperMills,area,year] = DEEB0[Motors,tech,PulpPaperMills,area,Yr(2000)]
    DEEC0[Motors,tech,PulpPaperMills,area,year] = DEEC0[Motors,tech,PulpPaperMills,area,Yr(2000)]
    DCCA0[Motors,tech,PulpPaperMills,area,year] = DCCA0[Motors,tech,PulpPaperMills,area,Yr(2000)]
    DCCB0[Motors,tech,PulpPaperMills,area,year] = DCCB0[Motors,tech,PulpPaperMills,area,Yr(2000)]
    DCCC0[Motors,tech,PulpPaperMills,area,year] = DCCC0[Motors,tech,PulpPaperMills,area,Yr(2000)]

    PEEB0[Motors,tech,PulpPaperMills,area,year] = PEEB0[Motors,tech,PulpPaperMills,area,Yr(2000)]
    PEEC0[Motors,tech,PulpPaperMills,area,year] = PEEC0[Motors,tech,PulpPaperMills,area,Yr(2000)]
    PCCA0[Motors,tech,PulpPaperMills,area,year] = PCCA0[Motors,tech,PulpPaperMills,area,Yr(2000)]
    PCCB0[Motors,tech,PulpPaperMills,area,year] = PCCB0[Motors,tech,PulpPaperMills,area,Yr(2000)]
    PCCC0[Motors,tech,PulpPaperMills,area,year] = PCCC0[Motors,tech,PulpPaperMills,area,Yr(2000)]
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
  @info "PulpPaper_EfficiencyInputs.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
