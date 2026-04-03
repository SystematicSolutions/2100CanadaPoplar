#
# E2020_Constants.jl
#

# const False::Float32 = 0 # Boolean Variable
# const True::Float32 = 1 # Boolean Variable

# CalSw = 0 CALIB local? "Loadcurve Calibration Switch", "switch")

#
# Time Variables
#
const xHisTime = 2023
const xITime = 1985
const MaxTime = 2050
const ShortAdj = 5
const ITime = xITime
const Zero = ITime-ITime+1
const STime = xITime+1
const First = Zero+1
const HisTime = xHisTime
const Last = xHisTime-ITime+1
const Future = Last+1
const Final = MaxTime-ITime+1
const SFTime = xHisTime
const Short = SFTime-ITime+1

const Period::Float32 = 1.0 # Solution Interval for Simulation
const DT::Float32 = Period  # Solution Interval for Simulation
const Infinity::Float32 = 1e37
