#
# GHG_TransportationMacro_CA.jl - California transportaion GHG coefficients
# for enduse (POCX) and process (TrMEPX) emissions - Luke Davulis 1/8/16
#
using EnergyModel

module GHG_TransportationMacro_CA

using EnergyModel

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
    # BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

    Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
    AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
    Areas::Vector{Int} = collect(Select(Area))
    EC::SetArray = ReadDisk(db,"$Input/ECKey")
    ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
    ECs::Vector{Int} = collect(Select(EC))
    Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
    EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
    Enduses::Vector{Int} = collect(Select(Enduse))
    Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
    PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
    Polls::Vector{Int} = collect(Select(Poll))
    Tech::SetArray = ReadDisk(db,"$Input/TechKey")
    TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
    Techs::Vector{Int} = collect(Select(Tech))
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")
    YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
    Years::Vector{Int} = collect(Select(Year))

    PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
    TrMEPX::VariableArray{5} = ReadDisk(db,"$Input/TrMEPX") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Vehicle Miles)
    VDT::VariableArray{5} = ReadDisk(db,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
    xTrMEPol::VariableArray{5} = ReadDisk(db,"$Input/xTrMEPol") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)

    #
    # Scratch Variables
    #
    CAPoll::VariableArray{2} = zeros(Float32,length(Poll),length(Year)) # [Poll,Year] California Transportation Pollution
    RatioVDT::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Ratio of VDT
    VDTTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Intermediate Variable to Calculate Ratio of VDT
  end

  function TransPolicy(db)
    data = TControl(; db)
    (;Input) = data
    (;Area,EC,ECs,Enduses,Poll) = data
    (;Polls,Techs,Years) = data
    (;PolConv,TrMEPX,VDT,xTrMEPol) = data
    (;CAPoll,RatioVDT,VDTTotal) = data
    
    #
    # CO2 and HFC Process Emissions.  All emissions read in as MT eCO2
    # source: "California Emissions All Fuels v160108.xlsx" - Luke Davulis 1/8/16
    #
    
    CA = Select(Area,"CA")
    @. TrMEPX[Techs,ECs,Polls,CA,Years] = 0.0
    Passenger = Select(EC,"Passenger")
    polls = Select(Poll,["CO2","HFC"])
    Yr2000 = Yr(2000)
    Yr2013 = Yr(2013)
    years = collect(Yr2000:Yr2013)
    CAPoll[polls,years] .=[
    # 2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
    1.1960   1.0958   1.0828   1.0011   1.0142   1.0089   0.9830   1.0151   0.9424   0.8473   0.9414   0.8931   0.8216   0.8694 
    2.0407   2.1550   2.2498   2.4531   2.6365   2.8554   2.8999   2.9803   3.1673   3.3235   3.4264   3.4115   3.4826   3.5061 
    ]
    
    for year in years
      VDTTotal[year] = sum(VDT[enduse,tech,Passenger,CA,year] for enduse in Enduses, tech in Techs)
    end
    
    for tech in Techs, year in years
      @finite_math RatioVDT[tech,year] = VDT[1,tech,Passenger,CA,year] / VDTTotal[year]
    end
    
    for tech in Techs, poll in polls, year in years
      xTrMEPol[tech,Passenger,poll,CA,year] = (CAPoll[poll,year] * RatioVDT[tech,year])*1000000/PolConv[poll]
    end
    
    WriteDisk(db,"$Input/xTrMEPol",xTrMEPol)

    #
    # Process Emission Coefficient (TrMEPX) are Process Emissions (TrMEPol)
    # divided by Vehicle Distance Traveled (VDT).
    #
    
    polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
    @. TrMEPX[Techs,ECs,polls,CA,Years] = 0.0
    
    for year in Years, poll in polls, ec in ECs, tech in Techs
      VDTsum = sum(VDT[enduse,tech,ec,CA,year] for enduse in Enduses)
      @finite_math TrMEPX[tech,ec,poll,CA,year] = xTrMEPol[tech,ec,poll,CA,year]/VDTsum
    end
    
    #
    # Set coefficient equal to previous year only if it doesn't have a value
    #
    
    years = collect(Yr(2014):Final)
    for year in years,poll in polls, ec in ECs, tech in Techs
      if TrMEPX[tech,ec,poll,CA,year] == 0.0
        TrMEPX[tech,ec,poll,CA,year] = TrMEPX[tech,ec,poll,CA,year-1]
      end
    end
    
    WriteDisk(db,"$Input/TrMEPX",TrMEPX)

  end

  function PolicyControl(db)
    @info "GHG_TransportationMacro_CA.jl - PolicyControl"

    TransPolicy(db)

  end

  if abspath(PROGRAM_FILE) == @__FILE__
    PolicyControl(DB)
  end

end
