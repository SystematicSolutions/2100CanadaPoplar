#
# Com_DataCenter.jl
#
using EnergyModel

module Com_DataCenter

import ...EnergyModel: ReadDisk,WriteDisk,Select, Yr
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final, Zero, Last
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CData
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DSt::VariableArray{4} = ReadDisk(db,"$Outpt/DSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)

  # Scratch Variables
  Change::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Adjustment Factor

end

function ComPolicy(db)
  data = CData(; db)
  (;Input,Outpt) = data
  (;Areas,Area,EC,Enduse,Nation,Years) = data
  (;ANMap,DSt,xDSt) = data
  (;Change) = data

  #
  # Selecting all CN Areas for now 
  #
  CN = Select(Nation,"CN")
  areas = Select(Area,["BC","AB","SK", "ON","QC"])
  ec = Select(EC,"Information")
  
  #
  # Assume increase in electric demands are servers/computers, not from heating/cooling/lighting
  #
  enduse = Select(Enduse,"OthNSub")

  #
  # Change is dimensioned by Area and Year. Assume a simple increase for now, which can be adjusted or made 
  # more specific by area or year - Ian 10/10/25
  Change[Areas,Years].= 1.0

  #
  # Reductions in demand read in in TJ and converted to TBtu
  #
  years = collect(Yr(2024):Final)
  Change[areas,years] = [
  #   2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034 2035 2036 2037 2038 2039 2040 2041 2042 2043 2044 2045 2046 2047 2048 2049 2050

       1.9  2.9  4.0  5.2  6.2  7.3  8.4  8.5  8.5  8.5  8.5  8.4  8.5  8.5  8.5  8.6  8.6  8.6  8.7  8.7  8.8  8.7  8.8  8.9  8.8  8.9  9.0 #BC
       9.7 18.6 28.2 37.5 46.6 55.4 63.9 69.4 74.8 79.9 85.1 90.0 95.0 99.8 104.6 109.4 114.1 118.7 123.1 127.5 131.4 135.4 139.3 143.1 147.1 150.9 154.5 #AB
      16.9 34.0 52.0 70.7 90.7 112.3 135.4 138.6 141.9 145.2 148.4 151.7 155.0 158.3 161.7 165.0 168.5 171.9 175.3 178.7 182.3 186.0 189.6 193.4 197.2 201.1 204.9 #SK
       7.1 13.8 20.7 27.9 35.4 43.2 51.3 60.7 70.3 80.1 90.1 100.2 110.6 121.3 132.2 143.2 154.7 157.9 161.2 164.5 167.9 171.4 174.9 178.5 182.2 185.8 189.5 #ON
       5.9 11.6 17.6 24.0 30.8 38.4 46.3 49.5 52.8 56.3 59.8 63.5 67.4 71.5 75.9 80.4 85.2 89.2 93.5 98.0 102.8 107.7 112.8 118.2 123.9 129.7 135.7] #QC

  # 
  # Apply Change to both DSt and xDSt
  #
  years = collect(Yr(2024):Final)
  for area in areas, year in years
    DSt[enduse,ec,area,year] = DSt[enduse,ec,area,year] * Change[area,year]
    xDSt[enduse,ec,area,year] = xDSt[enduse,ec,area,year] * Change[area,year]
  end

  WriteDisk(db,"$Input/xDSt",xDSt)
  WriteDisk(db,"$Outpt/DSt",DSt)

end

function PolicyControl(db)
  @info "Com_DataCenter.jl - PolicyControl"

  ComPolicy(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
