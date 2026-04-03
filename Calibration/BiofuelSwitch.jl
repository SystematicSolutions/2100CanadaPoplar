#
# BiofuelSwitch.jl - Sets Switch to Execute Biofuel Supply Sector
#
# The ENERGY 2100 model and all associated software are 
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc. 
# � 2016 Systematic Solutions, Inc.  All rights reserved.
#
using EnergyModel

module BiofuelSwitch

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  BiofuelSwitch::Float32 = ReadDisk(db,"SInput/BiofuelSwitch")[1] # [tv] Biofuel Switch (1=Biofuel Module)

  # Scratch Variables
end

function SCalibration(db)
  data = SControl(; db)
  (;BiofuelSwitch) = data

  BiofuelSwitch = 1

  WriteDisk(db,"SInput/BiofuelSwitch",BiofuelSwitch)

end

function CalibrationControl(db)
  @info "BiofuelSwitch.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
