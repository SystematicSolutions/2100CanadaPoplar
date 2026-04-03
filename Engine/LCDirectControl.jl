#
# LCDirectControl.jl - Load Curve Calibration Control
#
# The ENERGY 2100 model and all associated software are 
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc. 
# copyright 2013 Systematic Solutions, Inc.  All rights reserved.
#
using EnergyModel

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct DataLCDirect
  db::String
  
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  SegKey::SetArray = ReadDisk(db,"MainDB/SegKey")
  Seg::SetArray = ReadDisk(db,"MainDB/SegKey")

  CalibLTime::VariableArray{1} = ReadDisk(db,"SInput/CalibLTime") #[Area] Last Year of Load Curve Calibration (Year)

end

function LCDirect(db)
   data = DataLCDirect(; db)
  (;db) = data
  (;Areas) = data
  (;CalibLTime) = data

  #
  # This procedure calibrated the load curves and is only called 
  # from LCalib.Run file.
  #

  #
  # Use RunTime instead of HisTime since Histime is a constant - Jeff Amlin 8/24/24
  #
  RunTime = maximum(CalibLTime[area] for area in Areas)
 
  True = 1
  False = 0
  CalSw = 0
  OPSw = 0

  while CalSw <= True
  
  # Select Seg(Supply) - do we need this in Julia? - Jeff Amlin 8/24/24
    SLoadCalib(db,RunTime,CalSw,OPSw)
   
  # Select Seg(Residential) - do we need this in Julia? - Jeff Amlin 8/24/24
    RControl.RLoadCalib(db,RunTime,CalSw)
    
  # Select Seg(Commercial)
    CControl.CLoadCalib(db,RunTime,CalSw)   
    
  # Select Seg(Industrial)
    IControl.ILoadCalib(db,RunTime,CalSw)  

  # Select Seg(Transportation)
    TControl.TLoadCalib(db,RunTime,CalSw) 
    
    OPSw = True
    CalSw = CalSw+True

    SLoadCalib(db,RunTime,CalSw,OPSw)

    OPSw = False
  end
end


