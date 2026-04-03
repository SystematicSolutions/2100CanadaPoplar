#
# EInput.jl - Input Database creation file
#

Base.@kwdef struct EInput <: HDF5GroupDatabase
  db::String=DB
  ########################
  #
  # Define Sets
  #
  GenCo = ReadSetFromCSV("GenCo","Key")
  Year = ReadSetFromCSV("Year","Key")
  tv = ReadSetFromCSV("tv","Key")
  Node = ReadSetFromCSV("Node","Key")
  ECC = ReadSetFromCSV("ECC","Key")
  Area = ReadSetFromCSV("Area","Key")
  TimeP = ReadSetFromCSV("TimeP","Key")
  Month = ReadSetFromCSV("Month","Key")
  Plant = ReadSetFromCSV("Plant","Key")
  Power = ReadSetFromCSV("Power","Key")
  PPSet = ReadSetFromCSV("PPSet","Key")
  Class = ReadSetFromCSV("Class","Key")
  ########################
  #
  # Define Variables on Database
  #
  #! format: off
  AGPVSw = CreateVariableInHDF5(db, "EInput/AGPVSw", (:GenCo, :Year),"Is Value of Gratis Permit passed on to Customers (1=Yes)","1=Yes")
  DRM = CreateVariableInHDF5(db, "EInput/DRM", (:Node, :Year),"Desired Reserve Margin (MW/MW)","MW/MW")
  ECCPrMap = CreateVariableInHDF5(db, "EInput/ECCPrMap", (:ECC, :Year),"Map between ECC and Sector for Electric Prices (Map)","Map")
  ExportsURFraction = CreateVariableInHDF5(db, "EInput/ExportsURFraction", (:Area, :Year),"Electric Exports Unit Revenues Flag (0=exclude)","0=exclude")
  GRefSwitch = CreateVariableInHDF5(db, "EInput/GRefSwitch", (:Year,),"Gratis Permits Refunded in Retail Prices Switch (1=Yes)","1=Yes")
  HDHours = CreateVariableInHDF5(db, "EInput/HDHours", (:TimeP, :Month),"Number of Hours in the Interval (Hours)","Hours")
  HDHrMn = CreateVariableInHDF5(db, "EInput/HDHrMn", (:TimeP, :Month),"Minimum Hour in the Interval (Hour)","Hour")
  HDHrPk = CreateVariableInHDF5(db, "EInput/HDHrPk", (:TimeP, :Month),"Peak Hour in the Interval (Hour)","Hour")
  MBD = CreateVariableInHDF5(db, "EInput/MBD", (:Year,),"Minimum Hours of Operation of Baseload Plants (Hours/Yr)","Hours/Yr")
  MILD = CreateVariableInHDF5(db, "EInput/MILD", (:Year,),"Minimum Hours of Operation for Intermediate Plants (Hours/Yr)","Hours/Yr")
  NPPL = CreateVariableInHDF5(db, "EInput/NPPL", (:Area, :Year),"Non-Power Cost Lifetime (Years)","Years")
  NPSwitch = CreateVariableInHDF5(db, "EInput/NPSwitch", (:Year,),"Non-Power Costs Explicitly in Retail Price Switch (1=Yes)","1=Yes")
  NPTime = CreateVariableInHDF5(db, "EInput/NPTime", (:tv,),"Non-Power Costs Endogenous Time (Year)","Year")
  PCFP = CreateVariableInHDF5(db, "EInput/PCFP", (:Plant, :Year),"Planning Plant Capacity Factor","NoUnit")
  PCFPR = CreateVariableInHDF5(db, "EInput/PCFPR", (:Power, :Year),"Planning Plant Capacity Factor","NoUnit")
  PPSetDS = ReadSetFromCSV("PPSet","DS")
  PPSetKey = ReadSetFromCSV("PPSet","Key")
  RECSwitch = CreateVariableInHDF5(db, "EInput/RECSwitch", (:Year,),"Renewable Energy Credit (REC) in Retail Price Switch (1=Yes)","REC")
  RofWSw = CreateVariableInHDF5(db, "EInput/RofWSw", (:Area,),"Rest-of World Switch (1=Rest-of-World Company)","1=Rest-of-World Company")
  SelfG = CreateVariableInHDF5(db, "EInput/SelfG", (:Area, :GenCo, :Year),"Minimum Fraction of GenCo Total Capacity purchased by Area (MW/MW)","MW/MW")
  SelfPlant = CreateVariableInHDF5(db, "EInput/SelfPlant", (:Plant, :Area, :GenCo, :Year),"Minimum Fraction of GenCo Plant Capacity purchased by Area (MW/MW)","MW/MW")
  SelfR = CreateVariableInHDF5(db, "EInput/SelfR", (:Area, :GenCo, :Year),"Minimum Fraction of LSE Load purchased from GenCo (MW/MW)","MW/MW")
  SICstFr = CreateVariableInHDF5(db, "EInput/SICstFr", (:Area, :GenCo, :Year),"Stranded Investment Cost Allocation Fraction (\$/\$)","\$/\$")
  xCapacity = CreateVariableInHDF5(db, "EInput/xCapacity", (:Area, :GenCo, :Plant, :TimeP, :Month, :Year),"Capacity for Exogenous Contracts (MW)","MW")
  xCapSw = CreateVariableInHDF5(db, "EInput/xCapSw", (:Area, :GenCo, :Plant, :Year),"Switch for Exogenous Contract (1=Contract)","1=Contract")
  xEnergy = CreateVariableInHDF5(db, "EInput/xEnergy", (:Area, :GenCo, :Plant, :Year),"Energy Limit on Exogenous Contracts (GWh/Yr)","GWh/Yr")
  xPE = CreateVariableInHDF5(db, "EInput/xPE", (:ECC, :Area, :Year),"Historical Electricity Prices by Ecc (Real Mills/kWh)","Real Mills/kWh")
  xPEClass = CreateVariableInHDF5(db, "EInput/xPEClass", (:Class, :Area, :Year),"Historical Distribution Charge (Real MILLS/kWh)","Real MILLS/kWh")
  xUCCost = CreateVariableInHDF5(db, "EInput/xUCCost", (:Area, :GenCo, :Plant, :Year),"Capacity Cost for Exogenous Contracts (Real US\$/KW)","Real US\$/KW")
  xUECost = CreateVariableInHDF5(db, "EInput/xUECost", (:Area, :GenCo, :Plant, :Year),"Energy Cost for Exogenous Contracts (Real US\$/MWh)","Real US\$/MWh")
end # struct EInput
