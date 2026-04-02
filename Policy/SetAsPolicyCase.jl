#
# SetAsPolicyCase.jl
#

using EnergyModel

module SetAsPolicyCase

  import ...EnergyModel: ReadDisk,WriteDisk,Select
  import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
  import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
  import ...EnergyModel: DB

  const VariableArray{N} = Array{Float32,N} where {N}
  const SetArray = Vector{String}

  Base.@kwdef struct SControl
    db::String

    CalDB::String = "SCalDB"
    Input::String = "SInput"
    Outpt::String = "SOutput"
    
    BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
    BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
    RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case) 

    # Scratch Variables
  end

  function SupplyPolicy(db)
    data = SControl(; db)
    (; BaseSw,RefSwitch) = data
    
    # *
    # * Set this case As a Policy Case,
    # * not the Base Case or the Reference Case
    # *
    BaseSw = 0
    RefSwitch = 0
    WriteDisk(db,"SInput/BaseSw",[BaseSw])
    WriteDisk(db,"SInput/RefSwitch",[RefSwitch])
  end

  function PolicyControl(db)
    @info "SetAsPolicyCase.jl - PolicyControl"
    SupplyPolicy(db)
  end

  if abspath(PROGRAM_FILE) == @__FILE__
    PolicyControl(DB)
  end

end
