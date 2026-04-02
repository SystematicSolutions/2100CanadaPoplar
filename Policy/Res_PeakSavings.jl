#
# Res_PeakSavings.jl
#

using EnergyModel

module Res_PeakSavings

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
 db::String

 CalDB::String = "RCalDB"
 Input::String = "RInput"
 Outpt::String = "ROutput"
 BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

 Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
 AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
 Areas::Vector{Int} = collect(Select(Area))
 EC::SetArray = ReadDisk(db,"$Input/ECKey")
 ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
 ECs::Vector{Int} = collect(Select(EC))
 ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
 ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
 ECCs::Vector{Int} = collect(Select(ECC))
 Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
 EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
 Enduses::Vector{Int} = collect(Select(Enduse))
 Tech::SetArray = ReadDisk(db,"$Input/TechKey")
 TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
 Techs::Vector{Int} = collect(Select(Tech))
 Year::SetArray = ReadDisk(db,"MainDB/YearKey")
 YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
 Years::Vector{Int} = collect(Select(Year))

 DmdRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Demand (TBtu/Yr)
 ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
 SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets
 xPkSav::VariableArray{4} = ReadDisk(db,"$Input/xPkSav") # [Enduse,EC,Area,Year] Peak Savings from Programs (MW)
 xPkSavECC::VariableArray{3} = ReadDisk(db,"SInput/xPkSavECC") # [ECC,Area,Year] Peak Savings from Programs (MW)

 # Scratch variables
 DmFrac::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year))
 DmdTotal::VariableArray{2} = zeros(Float32,length(Area),length(Year))
 TotPkSav::VariableArray{2} = zeros(Float32,length(Area),length(Year))
end

function ResPolicy(db)
 data = RControl(; db)

 (; Input) = data
 (; Area,Areas,EC,ECs,ECC,ECCs,Enduse,Enduses,Tech,Techs,Year,Years) = data
 (; ECCMap,DmdRef,xPkSav,xPkSavECC,DmFrac,DmdTotal,SecMap,TotPkSav) = data

 # BC peak savings
 area = Select(Area, "BC")
 TotPkSav[area,Yr(2025)] = 46.4/1.05
 TotPkSav[area,Yr(2026)] = 52.7/1.05
 TotPkSav[area,Yr(2027)] = 58.8/1.05
 TotPkSav[area,Yr(2028)] = 64.2/1.05
 TotPkSav[area,Yr(2029)] = 68.1/1.05
 TotPkSav[area,Yr(2030)] = 68.3/1.05
 TotPkSav[area,Yr(2031)] = 67.4/1.05
 TotPkSav[area,Yr(2032)] = 66.8/1.05
 TotPkSav[area,Yr(2033)] = 67.1/1.05
 TotPkSav[area,Yr(2034)] = 67.2/1.05
 TotPkSav[area,Yr(2035)] = 64.0/1.07
 TotPkSav[area,Yr(2036)] = 61.3/1.08
 TotPkSav[area,Yr(2037)] = 61.4/1.08
 TotPkSav[area,Yr(2038)] = 61.7/1.08
 TotPkSav[area,Yr(2039)] = 61.7/1.02
 TotPkSav[area,Yr(2040)] = 60.6/1.02

 years = collect(Yr(2041):Final)
 for year in years
   TotPkSav[area,year] = 60.6/1.02
 end

 # QC peak savings
 area = Select(Area, "QC")
 TotPkSav[area,Yr(2024)] = 99.5
 TotPkSav[area,Yr(2025)] = 205.0
 TotPkSav[area,Yr(2026)] = 310.5
 TotPkSav[area,Yr(2027)] = 413.2
 TotPkSav[area,Yr(2028)] = 518.1
 TotPkSav[area,Yr(2029)] = 622.2
 TotPkSav[area,Yr(2030)] = 725.7
 TotPkSav[area,Yr(2031)] = 829.3
 TotPkSav[area,Yr(2032)] = 932.0
 TotPkSav[area,Yr(2033)] = 1033.2
 TotPkSav[area,Yr(2034)] = 1130.5*1.5
 TotPkSav[area,Yr(2035)] = 1222.7*1.5

 years = collect(Yr(2036):Final)
 for year in years
   TotPkSav[area,year] = 1222.7*1.5
 end

 # NS peak savings
 area = Select(Area, "NS")
 TotPkSav[area,Yr(2024)] = 0.00
 TotPkSav[area,Yr(2025)] = 0.00
 TotPkSav[area,Yr(2026)] = 12.1/1.2
 TotPkSav[area,Yr(2027)] = 36.3/1.2
 TotPkSav[area,Yr(2028)] = 48.6/1.2
 TotPkSav[area,Yr(2029)] = 61.0/1.13
 TotPkSav[area,Yr(2030)] = 73.5/1.12
 TotPkSav[area,Yr(2031)] = 86.0/1.11
 TotPkSav[area,Yr(2032)] = 98.6/1.1
 TotPkSav[area,Yr(2033)] = 111.0/1.1
 TotPkSav[area,Yr(2034)] = 123.5/1.1
 TotPkSav[area,Yr(2035)] = 123.5

 years = collect(Yr(2036):Final)
 for year in years
   TotPkSav[area,year] = 123.5*1.1
 end

 # Allocate demand reduction
 areas = Select(Area, ["NS","QC","BC"])
 years = collect(Yr(2024):Yr(2050))
 tech = Select(Tech, "Electric")

 for area in areas, year in years
   # Total across enduses
   DmdTotal[area,year] = sum(DmdRef[enduse,tech,ec,area,year]
                            for enduse in Enduses, ec in ECs)

   # Calculate fraction of electric tech's enduse demand per sector
   for enduse in Enduses, ec in ECs
     DmFrac[enduse,ec,area,year] = DmdRef[enduse,tech,ec,area,year] /
                                  DmdTotal[area,year]
     xPkSav[enduse,ec,area,year] = DmFrac[enduse,ec,area,year] *
                                  TotPkSav[area,year]
   end

   # Calculate ECC values
   for ec in ECs
    ecc = Select(ECC,EC[ec])
    xPkSavECC[ecc,area,year] = sum(xPkSav[enduse,ec,area,year] for enduse in Enduses)
   end
 end

 WriteDisk(db,"$Input/xPkSav",xPkSav)
 WriteDisk(db,"SInput/xPkSavECC",xPkSavECC)
end

function PolicyControl(db)
 @info "Res_PeakSavings.jl - PolicyControl"
 ResPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
 PolicyControl(DB)
end

end
