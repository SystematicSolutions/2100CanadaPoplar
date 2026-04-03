#
# CoreE2020.jl
#
# This file contains core functionality to make the ENERGY 2100 modeling work
#

import ...EnergyModel: ReadDisk, ModelPath, DataFolder, DatabaseName, OutputFolder
import ...EnergyModel: Logger.LoggerInitialize,CloseDatabase

#const Period::Float32 = 1.0 # Solution Interval for Simulation
#const DT::Float32 = Period  # Solution Interval for Simulation

#const ITime = 1985             # Year for initializing model
#const MaxTime = 2050                # Last year for a forecast
#const HisTime = 2019                # Last historical year
#const First = 2                     # First year
#const Future = HisTime - ITime + 1  # First forecast year index
#const Final = MaxTime - ITime + 1   # Final year of forecast index
#const BTime = ITime + 1
#const EndTime = MaxTime


# BTime = 1985.0
# EndTime = 1990.0
# SceName = "string"
# BCName = "string"
# RefName = "string"
# OGRefName = "string"
# InitialName = "string"
# Run1Name = "string"

Base.@kwdef struct Data
  db::String
  year::Int
  current::Int
  prior::Int
  next::Int
  CTime::Int

  BCName::String = ReadDisk(DB,"MainDB/BCName") #  Base Case Name
  BCNameDB::String = ReadDisk(DB,"MainDB/BCNameDB") #  Base Case Name
  BTime::Float32 = ReadDisk(DB,"SInput/BTime") #  Beginning Year for Simulation (Year)
  EndTime::Float32 = ReadDisk(DB,"SInput/EndTime") #  Ending Year for Simulation (Year)
  InitialName::String = ReadDisk(DB,"MainDB/InitialName") #  Initial Data Name
  InitialNameDB::String = ReadDisk(DB,"MainDB/InitialNameDB") #  Initial Data Name
  OGRefName::String = ReadDisk(DB,"MainDB/OGRefName") #  Oil and Gas Reference Case Name
  OGRefNameDB::String = ReadDisk(DB,"MainDB/OGRefNameDB") #  Oil and Gas Reference Case Name
  RefName::String = ReadDisk(DB,"MainDB/RefName") #  Reference Case Name
  RefNameDB::String = ReadDisk(DB,"MainDB/RefNameDB") #  Reference Case Name
  Run1Name::String = ReadDisk(DB,"MainDB/Run1Name") #  TIM Investments Case Name
  Run1NameDB::String = ReadDisk(DB,"MainDB/Run1NameDB") #  TIM Investments Case Name
  SceName::String = ReadDisk(DB,"SInput/SceName") #  Scenario Name
  SegSw::VariableArray{1} = ReadDisk(db,"MainDB/SegSw") #[Seg] Segment Execution Switch
  xSegSw::VariableArray{1} = ReadDisk(db,"MainDB/xSegSw") #[Seg] Segment Execution Switch
end

function StartScenario(StartName,SceName,BCName,RefName,OGRefName,InitialName,Run1Name)
  
  LoggerInitialize()
 
  @debug "$StartName, $SceName, $BCName, $RefName, $OGRefName, $InitialName, $Run1Name"  
  
  #
  # 2020Model Subdirectory (DB) contains the datbases where data is read and outputs are written
  #

  #
  # 2020Model/SceName is where the results will be stored after the run executes
  #
  ScenarioFolder = joinpath(ModelPath, "2020Model", SceName)
  ScenarioDatabase = joinpath(ScenarioFolder, "database.hdf5")
  @debug "ScenarioDatabase $ScenarioDatabase"
  
  WriteDisk(DB,"SInput/SceName", SceName)
  
  #
  # 2020Model/BCName are results from the Base Case
  #
  if BCName != SceName
    BaseFolder = joinpath(ModelPath, "2020Model", BCName)
    BCNameDB = joinpath(BaseFolder, "database.hdf5")
  else 
    BCNameDB = DB
  end
  WriteDisk(DB,"MainDB/BCName", BCName)
  WriteDisk(DB,"MainDB/BCNameDB", BCNameDB)
  @debug  "BCNameDB $BCNameDB"
  
  #
  # 2020Model/RefName are results from the Reference Case
  #
  if RefName != SceName 
    RefFolder = joinpath(ModelPath, "2020Model", RefName)
    RefNameDB = joinpath(RefFolder, "database.hdf5")
  else
    RefNameDB = DB
  end
  WriteDisk(DB,"MainDB/RefName", RefName)
  WriteDisk(DB,"MainDB/RefNameDB", RefNameDB)
  @debug  "RefNameDB $RefNameDB"
  
  #
  # 2020Model/OGRefName are results from the Oil and Gas Reference Case
  #
  if OGRefName != SceName 
    OGRefFolder = joinpath(ModelPath, "2020Model", OGRefName)
    OGRefNameDB = joinpath(OGRefFolder, "database.hdf5")
  else
    OGRefNameDB = DB
  end
  WriteDisk(DB,"MainDB/OGRefName", OGRefName)
  WriteDisk(DB,"MainDB/OGRefNameDB", OGRefNameDB)
  @debug  "OGRefNameDB $OGRefNameDB"
  
  #
  # 2020Model/InitialName are results from the Initial Case
  #
  if InitialName != SceName 
    InitialFolder = joinpath(ModelPath, "2020Model", InitialName)
    InitialNameDB = joinpath(InitialFolder, "database.hdf5")
  else
    InitialNameDB = DB
  end
  WriteDisk(DB,"MainDB/InitialName", InitialName)
  WriteDisk(DB,"MainDB/InitialNameDB", InitialNameDB)
  @debug  "InitialNameDB $InitialNameDB"
  
  #
  # 2020Model/Run1Name are results for TIM Investments
  #
  if Run1Name != SceName 
    Run1Folder = joinpath(ModelPath, "2020Model", Run1Name)
    Run1NameDB = joinpath(Run1Folder, "database.hdf5")
  else
    Run1NameDB = DB
  end
  WriteDisk(DB,"MainDB/Run1Name", Run1Name)
  WriteDisk(DB,"MainDB/Run1NameDB", Run1NameDB)
  @debug  "Run1NameDB $Run1NameDB"

  #
  # TODODesign Unzip Scenario databases
  #
  
end

function CreateDTAs(SceName,BCName,OutputType,EnergyModel)

  # LoggerInitialize()

  # TODODesign Unzip databases for $SceName

  @info "CoreE2020.jl - CreateDTAs Generate Outputs for $SceName"
  # 
  EnergyModel.GenerateOutputs(DatabaseName,SceName,OutputType)

  # TODODesign Saving Outputs and DBs

end




function RunScenario(BTimeStr,EndTimeStr,SceName,BCName,RefName,OGRefName,InitialName,Run1Name,dummy)
  
  LoggerInitialize()
 
  @info "$BTimeStr, $EndTimeStr, $SceName, $BCName, $RefName, $OGRefName, $InitialName, $Run1Name"  
  @debug "$BTimeStr, $EndTimeStr, $SceName, $BCName, $RefName, $OGRefName, $InitialName, $Run1Name"  

  Seg = ReadDisk(DB,"MainDB/SegDS")
  SegSw::VariableArray{1} = ReadDisk(DB,"MainDB/SegSw") #[Seg] Segment Execution Switch
  xSegSw::VariableArray{1} = ReadDisk(DB,"MainDB/xSegSw") #[Seg] Segment Execution Switch
  for seg in Seg
    SegSw=xSegSw
  end
  WriteDisk(DB,"MainDB/SegSw",SegSw)

  BTime = parse(Int,BTimeStr)
  EndTime = parse(Int,EndTimeStr)
  
  WriteDisk(DB,"SInput/BTime",BTime)
  WriteDisk(DB,"SInput/EndTime",EndTime)
  
  # 
  # Incorporate Policies from Policy.jl
  #
  @info "CoreE2020 - PolicyIncorporation"
  EnergyModel.PolicyIncorporation()

  #
  # Execute Model
  #
  EnergyModel.Run_E2020(DatabaseName, BTime, EndTime, SceName)
  
  CloseDatabase()
  
#
#  @info "RunOutputs.jl Generate Outputs for $SceName - $(EnergyModel.DB)"
#  TODODesign EnergyModel.GenerateOutputs(DatabaseName, SceName)
#
#  @info "RunOutputs.jl Saving Outputs and DBs for $SceName - $(EnergyModel.DB)"
#  TODODesign Saving Outputs and DBs
#

end

