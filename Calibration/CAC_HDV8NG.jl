#
# This file exogenously modifies the British Columbia HDV8 natural gas emission factors for CO, NOX, PM10, PM2.5, VOC and NH3 to their relative HDV8 Diesel Emission Factors emission factors in the projection period
# T:\CACs\2018 Update\HDV NG Adjustment
# AK 20/10/01
#
using EnergyModel

module CAC_HDV8NG

  import ...EnergyModel: ReadDisk,WriteDisk,Select
  import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
  import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
  import ...EnergyModel: DB

  const VariableArray{N} = Array{Float32,N} where {N}
  const SetArray = Vector{String}

  Base.@kwdef struct TControl
    db::String

    CalDB::String = "TCalDB"
    Input::String = "TInput"
    Outpt::String = "TOutput"
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
    FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
    FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
    FuelEPs::Vector{Int} = collect(Select(FuelEP))
    Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
    NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
    Nations::Vector{Int} = collect(Select(Nation))
    Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
    PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
    Polls::Vector{Int} = collect(Select(Poll))
    Tech::SetArray = ReadDisk(db,"$Input/TechKey")
    TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
    Techs::Vector{Int} = collect(Select(Tech))
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")
    YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
    Years::Vector{Int} = collect(Select(Year))

    ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
    POCX::VariableArray{7} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Pollution coefficient (Tonnes/TBtu)
    TrMEPX::VariableArray{5} = ReadDisk(db,"$Input/TrMEPX") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Vehicle Miles)

    # Scratch Variables
    DDD::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Variable for Displaying Outputs
  end

  function TransPolicy(db)
    data = TControl(; db)
    (;Input) = data
    (;EC,FuelEP) = data
    (;Nation,Poll,Tech) = data
    (;ANMap,POCX,TrMEPX) = data
    
    # *
    # ************************
    # *HDV8 Natural Gas Emission Factor Reduction for CO, NOX, PM10, PM2.5, VOC and NH3 to their relative HDV8 Diesel Emission Factors
    # *************************
    # *
    
    CN = Select(Nation,"CN")
    areas = findall(ANMap[:,CN] .== 1) 
    
    Freight = Select(EC,"Freight")
    HDV8NaturalGas = Select(Tech,"HDV8NaturalGas")
    HDV8Diesel = Select(Tech,"HDV8Diesel")
    NaturalGas = Select(FuelEP,"NaturalGas")
    Diesel = Select(FuelEP,"Diesel")
    years = collect(Future:Final)
    
    COX = Select(Poll,"COX")
    @. POCX[1,NaturalGas,HDV8NaturalGas,Freight,COX,areas,years] = POCX[1,Diesel,HDV8Diesel,Freight,COX,areas,years] * 16
    
    NOX = Select(Poll,"NOX")
    @. POCX[1,NaturalGas,HDV8NaturalGas,Freight,NOX,areas,years] = POCX[1,Diesel,HDV8Diesel,Freight,NOX,areas,years] * 0.1
    
    PM10 = Select(Poll,"PM10")
    @. POCX[1,NaturalGas,HDV8NaturalGas,Freight,PM10,areas,years] = POCX[1,Diesel,HDV8Diesel,Freight,PM10,areas,years]
    
    PM25 = Select(Poll,"PM25")
    @. POCX[1,NaturalGas,HDV8NaturalGas,Freight,PM25,areas,years] = POCX[1,Diesel,HDV8Diesel,Freight,PM25,areas,years]
    
    PMT = Select(Poll,"PMT")
    @. POCX[1,NaturalGas,HDV8NaturalGas,Freight,PMT,areas,years] = POCX[1,Diesel,HDV8Diesel,Freight,PMT,areas,years]
    
    VOC = Select(Poll,"VOC")
    @. POCX[1,NaturalGas,HDV8NaturalGas,Freight,VOC,areas,years] = POCX[1,Diesel,HDV8Diesel,Freight,VOC,areas,years]
    
    NH3 = Select(Poll,"NH3")
    @. POCX[1,NaturalGas,HDV8NaturalGas,Freight,NH3,areas,years] = POCX[1,Diesel,HDV8Diesel,Freight,NH3,areas,years] * 0.00000013
    
    WriteDisk(db,"$Input/POCX",POCX)
    
    polls = Select(Poll,["COX","NOX","PM10","PM25","PMT","VOC","NH3"])
    @. TrMEPX[HDV8NaturalGas,Freight,polls,areas,years] = TrMEPX[HDV8Diesel,Freight,polls,areas,years]
    
    WriteDisk(db,"$Input/TrMEPX",TrMEPX)
    
    

  end

  function CalibrationControl(db)
    @info "CAC_HDV8NG.jl - CalibrationControl"

    TransPolicy(db)

  end

  abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)

end
