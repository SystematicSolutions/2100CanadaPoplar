#
# CarbonTax_OBARemoval.jl - OBA removal for all markets
#

using EnergyModel

module CarbonTax_OBARemoval

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
    db::String
    Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
    ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
    FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
    Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
    Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
    PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
    Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
    Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
    Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")

    Areas::Vector{Int} = collect(Select(Area))
    ECCs::Vector{Int} = collect(Select(ECC))
    FuelEPs::Vector{Int} = collect(Select(FuelEP))
    Plants::Vector{Int} = collect(Select(Plant))
    Polls::Vector{Int} = collect(Select(Poll))
    Units::Vector{Int} = collect(Select(Unit))

    AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket")
    ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket")
    OBAFraction::VariableArray{3} = ReadDisk(db,"SInput/OBAFraction") # [ECC,Area,Year]
    PCovMarket::VariableArray{3} = ReadDisk(db,"SInput/PCovMarket")
    PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket")
    UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation")
    UnPGratis::VariableArray{3} = ReadDisk(db,"EGOutput/UnPGratis")
    xGoalPol::VariableArray{2} = ReadDisk(db,"SInput/xGoalPol")
    xGPNew::VariableArray{5} = ReadDisk(db,"EGInput/xGPNew")
    xPGratis::VariableArray{5} = ReadDisk(db,"SInput/xPGratis")
    xPolCap::VariableArray{5} = ReadDisk(db,"SInput/xPolCap")
    xUnGP::VariableArray{4} = ReadDisk(db,"EGInput/xUnGP")

end

function DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
    areas = findall(AreaMarket[:,market,YrFinal] .== 1)
    eccs  = findall(ECCMarket[:,market,YrFinal] .== 1)
    pcovs = findall(PCovMarket[:,market,YrFinal] .== 1)
    polls = findall(PollMarket[:,market,YrFinal] .== 1)
    years = collect(Current:YrFinal)
    return areas,eccs,pcovs,polls,years
end

function ElecPolicy(db)
    data = EControl(; db)
    (; Area,Areas,ECC,ECCs,FuelEP,FuelEPs,Plant,Plants,Poll,Polls,Unit,Units,Nation) = data
    (; AreaMarket,ECCMarket,PCovMarket,PollMarket,OBAFraction) = data
    (; UnNation,xUnGP,xGPNew,UnPGratis,xPolCap,xPGratis,xGoalPol) = data

    markets = union(collect(121:159),200)
    YrFinal = Yr(2050)
    Current = Yr(2025)

    for market in markets
    
        areas,eccs,pcovs,polls,years = DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

        #
        # 1) Zero OBAFraction (persisted input that drives OBA)
        #
        for year in years, area in areas, ecc in eccs
            OBAFraction[ecc,area,year] = 0.0
        end

        #
        # 2) Zero dependent persisted variables
        #
        units = Select(UnNation,==("CN"))
        for year in years, poll in polls, unit in units, fuelep in FuelEPs
            xUnGP[unit,fuelep,poll,year] = 0.0
        end
        CO2 = Select(Poll,"CO2")
        for year in years, area in areas, plant in Plants, fuelep in FuelEPs
            xGPNew[fuelep,plant,CO2,area,year] = 0.0
        end
        for year in years, poll in polls, unit in units
            UnPGratis[unit,poll,year] = 0.0
        end
        for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
            xPolCap[ecc,poll,pcov,area,year] = 0.0
            xPGratis[ecc,poll,pcov,area,year] = 0.0
        end
        for year in years
            xGoalPol[market,year] = 0.0
        end
    end
    
    #
    # Persist all changes
    #
    WriteDisk(db,"SInput/OBAFraction",OBAFraction)
    WriteDisk(db,"EGInput/xUnGP",xUnGP)
    WriteDisk(db,"EGInput/xGPNew",xGPNew)
    WriteDisk(db,"EGOutput/UnPGratis",UnPGratis)
    WriteDisk(db,"SInput/xPolCap",xPolCap)
    WriteDisk(db,"SInput/xPGratis",xPGratis)
    WriteDisk(db,"SInput/xGoalPol",xGoalPol)
end

function PolicyControl(db)
    @info "CarbonTax_OBARemoval.jl - PolicyControl"
    ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
    PolicyControl(DB)
end

end
