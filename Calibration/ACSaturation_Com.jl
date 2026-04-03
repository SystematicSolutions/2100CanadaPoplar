#
# ACSaturation_Com.jl - Read in historical AC saturation rates
#
using EnergyModel

module ACSaturation_Com

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Area,Areas,ECs,Enduse,Enduses,Years) = data
  (;xDSt) = data

    enduse = Select(Enduse,"AC")
  areas = Select(Area,["NB","NL","NS","PE","QC","ON","MB","SK","AB","BC","NT","NU","YT"])
  years = collect(Yr(1985):Yr(2012))

  #*
  #* Commercial Air Conditioning Saturation Rates (fraction of floorspace cooled)
  #* Source: "CommInst_share of cooled floor space_by reg_Export.xlsx" from C.Miller 4/2015
  #*
  xDSt[enduse,1,areas,years] .= [
  #1985    1986     1987     1988     1989     1990     1991     1992     1993     1994     1995     1996     1997     1998     1999     2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012 
  0.51     0.51     0.51     0.51     0.51     0.51     0.52     0.54     0.55     0.57     0.59     0.60     0.62     0.63     0.65     0.66     0.68     0.70     0.71     0.73     0.74     0.75     0.76     0.77     0.77     0.78     0.78     0.79 
  0.51     0.51     0.51     0.51     0.51     0.51     0.52     0.54     0.55     0.57     0.59     0.60     0.62     0.63     0.65     0.66     0.68     0.70     0.71     0.73     0.74     0.75     0.76     0.77     0.77     0.78     0.78     0.79 
  0.51     0.51     0.51     0.51     0.51     0.51     0.52     0.54     0.55     0.57     0.59     0.60     0.62     0.63     0.65     0.66     0.68     0.70     0.71     0.73     0.74     0.75     0.76     0.77     0.77     0.78     0.78     0.79 
  0.51     0.51     0.51     0.51     0.51     0.51     0.52     0.54     0.55     0.57     0.59     0.60     0.62     0.63     0.65     0.66     0.68     0.70     0.71     0.73     0.74     0.75     0.76     0.77     0.77     0.78     0.78     0.79 
  0.60     0.60     0.60     0.60     0.60     0.60     0.62     0.64     0.66     0.68     0.70     0.72     0.73     0.75     0.77     0.79     0.81     0.83     0.85     0.86     0.88     0.89     0.90     0.91     0.92     0.92     0.93     0.93
  0.64     0.64     0.64     0.64     0.64     0.64     0.66     0.68     0.70     0.72     0.74     0.76     0.78     0.80     0.81     0.83     0.85     0.87     0.89     0.91     0.93     0.94     0.95     0.96     0.97     0.97     0.98     0.98 
  0.59     0.59     0.59     0.59     0.59     0.59     0.60     0.62     0.64     0.66     0.68     0.69     0.71     0.73     0.75     0.77     0.78     0.80     0.82     0.84     0.85     0.86     0.87     0.88     0.89     0.89     0.90     0.90 
  0.59     0.59     0.59     0.59     0.59     0.59     0.61     0.63     0.65     0.66     0.68     0.70     0.72     0.74     0.75     0.77     0.79     0.81     0.82     0.84     0.86     0.87     0.88     0.89     0.89     0.90     0.90     0.91 
  0.59     0.59     0.59     0.59     0.59     0.59     0.61     0.63     0.64     0.66     0.68     0.70     0.72     0.73     0.75     0.77     0.79     0.81     0.82     0.84     0.86     0.87     0.88     0.89     0.89     0.90     0.90     0.91 
  0.53     0.53     0.53     0.53     0.53     0.53     0.54     0.56     0.57     0.59     0.61     0.62     0.64     0.65     0.67     0.68     0.70     0.72     0.73     0.75     0.76     0.77     0.78     0.79     0.79     0.80     0.80     0.81 
  0.53     0.53     0.53     0.53     0.53     0.53     0.54     0.56     0.57     0.59     0.61     0.62     0.64     0.65     0.67     0.68     0.70     0.72     0.73     0.75     0.76     0.77     0.78     0.79     0.79     0.80     0.80     0.81 
  0.53     0.53     0.53     0.53     0.53     0.53     0.54     0.56     0.57     0.59     0.61     0.62     0.64     0.65     0.67     0.68     0.70     0.72     0.73     0.75     0.76     0.77     0.78     0.79     0.79     0.80     0.80     0.81 
  0.53     0.53     0.53     0.53     0.53     0.53     0.54     0.56     0.57     0.59     0.61     0.62     0.64     0.65     0.67     0.68     0.70     0.72     0.73     0.75     0.76     0.77     0.78     0.79     0.79     0.80     0.80     0.81 
  ]  

  #*
  #* Set all ECs equal to first one
  #*
  for year in years, area in areas, ec in ECs
    xDSt[enduse,ec,area,year] = xDSt[enduse,1,area,year]
  end

  for enduse in Enduses, ec in ECs, area in Areas, year in Years
    xDSt[enduse,ec,area,year] = max(xDSt[enduse,ec,area,year], 0.0001)
  end

  WriteDisk(db, "$Input/xDSt",xDSt)

end

function CalibrationControl(db)
  @info "ACSaturation_Com.jl - CalibrationControl"

  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
