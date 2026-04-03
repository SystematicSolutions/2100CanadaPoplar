#
# TCalDB.jl - Input Database creation file
#

Base.@kwdef struct TCalDB <: HDF5GroupDatabase
  db::String=DB
  ########################
  #
  # Define Sets
  #
  Enduse = ReadSetFromCSV("EnduseTrans","Key")
  EC = ReadSetFromCSV("ECTrans","Key")
  Area = ReadSetFromCSV("Area","Key")
  Year = ReadSetFromCSV("Year","Key")
  tv = ReadSetFromCSV("tv","Key")
  Tech = ReadSetFromCSV("TechTrans","Key")
  Hour = ReadSetFromCSV("Hour","Key")
  Day = ReadSetFromCSV("Day","Key")
  Month = ReadSetFromCSV("Month","Key")
  CTech = ReadSetFromCSV("CTechTrans","Key")
  Fuel = ReadSetFromCSV("Fuel","Key")
  FuelEP = ReadSetFromCSV("FuelEP","Key")
  Poll = ReadSetFromCSV("Poll","Key")
  ########################
  #
  # Define Variables on Database
  #
  #! format: off
  CERSM = CreateVariableInHDF5(db, "TCalDB/CERSM", (:Enduse, :EC, :Area, :Year),"Capital Energy Requirement Multiplier (Btu/Btu)","Btu/Btu")
  CgCUF = CreateVariableInHDF5(db, "TCalDB/CgCUF", (:Tech, :EC, :Area, :Year),"Cogeneration Capacity Utilization Factor (\$/\$)","\$/\$")
  CgLSF = CreateVariableInHDF5(db, "TCalDB/CgLSF", (:Tech, :EC, :Hour, :Day, :Month, :Area),"Cogeneration Load Shape (MW/MW)","MW/MW")
  CgLSFSold = CreateVariableInHDF5(db, "TCalDB/CgLSFSold", (:EC, :Hour, :Day, :Month, :Area),"Cogeneration Sold to Grid Load Shape (MW/MW)","MW/MW")
  CgMSM0 = CreateVariableInHDF5(db, "TCalDB/CgMSM0", (:Tech, :EC, :Area, :Year),"Cogeneration Market Share Non-Price Factor (\$/\$)","\$/\$")
  CgMSMI = CreateVariableInHDF5(db, "TCalDB/CgMSMI", (:Tech, :EC, :Area),"Cogeneration Market Share Income Factor (\$/\$)","\$/\$")
  CgVF = CreateVariableInHDF5(db, "TCalDB/CgVF", (:Tech, :EC, :Area),"Cogeneration Variance Factor (\$/\$)","\$/\$")
  CHR = CreateVariableInHDF5(db, "TCalDB/CHR", (:EC, :Area),"Cooling to Heating Ratio (Btu/Btu)","Btu/Btu")
  CMSM0 = CreateVariableInHDF5(db, "TCalDB/CMSM0", (:Enduse, :Tech, :CTech, :EC, :Area, :Year),"Conversion Market Share Multiplier (\$/\$)","\$/\$")
  CMSMI = CreateVariableInHDF5(db, "TCalDB/CMSMI", (:Enduse, :Tech, :CTech, :EC, :Area),"Conversion Market Share Multiplier (\$/\$)","\$/\$")
  CUF = CreateVariableInHDF5(db, "TCalDB/CUF", (:Enduse, :Tech, :EC, :Area, :Year),"Capital Utilization Fraction (\$/Yr/\$/Yr)","\$/Yr/\$/Yr")
  CVF = CreateVariableInHDF5(db, "TCalDB/CVF", (:Enduse, :Tech, :CTech, :EC, :Area, :Year),"Conversion Market Share Variance Factor (DLESS)","DLESS")
  DEMM = CreateVariableInHDF5(db, "TCalDB/DEMM", (:Enduse, :Tech, :EC, :Area, :Year),"Max. Device Eff. Multiplier (Btu/Btu)","Btu/Btu")
  DmFracMSM0 = CreateVariableInHDF5(db, "TCalDB/DmFracMSM0", (:Enduse, :Fuel, :Tech, :EC, :Area, :Year),"Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu)","Btu/Btu")
  DSt0 = CreateVariableInHDF5(db, "TCalDB/DSt0", (:Enduse, :EC, :Area, :Year),"Device Saturation Fixed Utility (\$/\$)","\$/\$")
  DStI = CreateVariableInHDF5(db, "TCalDB/DStI", (:Enduse, :EC, :Area),"Device Saturation Income Utility (\$/\$)","\$/\$")
  DStM = CreateVariableInHDF5(db, "TCalDB/DStM", (:Enduse, :EC, :Area),"Max. Device Saturation (Btu/Btu)","Btu/Btu")
  DStP = CreateVariableInHDF5(db, "TCalDB/DStP", (:Enduse, :EC, :Area),"Device Saturation Price Utility (\$/\$)","\$/\$")
  DUF = CreateVariableInHDF5(db, "TCalDB/DUF", (:Enduse, :EC, :Day, :Month, :Area),"Daily Use Factor (Therm/Therm)","Therm/Therm")
  FsFracMSM0 = CreateVariableInHDF5(db, "TCalDB/FsFracMSM0", (:Fuel, :Tech, :EC, :Area, :Year),"Feedstock Fuel/Tech Fraction Non-Price Factor (Btu/Btu)","Btu/Btu")
  FsPEE = CreateVariableInHDF5(db, "TCalDB/FsPEE", (:Tech, :EC, :Area, :Year),"Feedstock Process Efficiency (\$/mmBtu)","\$/mmBtu")
  LSF = CreateVariableInHDF5(db, "TCalDB/LSF", (:Enduse, :EC, :Hour, :Day, :Month, :Area),"Load Shape Factor (DLESS)","DLESS")
  MMSM0 = CreateVariableInHDF5(db, "TCalDB/MMSM0", (:Enduse, :Tech, :EC, :Area, :Year),"Non-price Factors. (\$/\$)","\$/\$")
  MMSMI = CreateVariableInHDF5(db, "TCalDB/MMSMI", (:Enduse, :Tech, :EC, :Area),"Market Share Mult. from Income (\$/\$)","\$/\$")
  MVF = CreateVariableInHDF5(db, "TCalDB/MVF", (:Enduse, :Tech, :EC, :Area, :Year),"Market Share Variance Factor (\$/\$)","\$/\$")
  PEM = CreateVariableInHDF5(db, "TCalDB/PEM", (:Enduse, :Tech, :EC, :Area),"Maximum Process Efficiency (\$/mmBtu)","\$/mmBtu")
  PEMM = CreateVariableInHDF5(db, "TCalDB/PEMM", (:Enduse, :Tech, :EC, :Area, :Year),"Pro. Eff. Max. Multi (\$/Btu/(\$/Btu))","\$/Btu/(\$/Btu")
  POCF = CreateVariableInHDF5(db, "TCalDB/POCF", (:Enduse, :Tech, :EC, :Area),"Process Operating Cost Fraction (\$/Yr/\$)","\$/Yr/\$")
  Polute = CreateVariableInHDF5(db, "TCalDB/Polute", (:Enduse, :FuelEP, :Tech, :EC, :Poll, :Area, :Year),"Pollution (Tonnes/Yr)","Tonnes/Yr")
  RDMSM = CreateVariableInHDF5(db, "TCalDB/RDMSM", (:Enduse, :Tech, :EC, :Area, :Year),"Device Retrofit Market Share Multiplier (1/Yr)","1/Yr")
  RPMSM = CreateVariableInHDF5(db, "TCalDB/RPMSM", (:Enduse, :Tech, :EC, :Area, :Year),"Process Retrofit Market Share Multiplier (1/Yr)","1/Yr")
  xCgMSF = CreateVariableInHDF5(db, "TCalDB/xCgMSF", (:Tech, :EC, :Area, :Year),"Cogen Market Share (\$/\$)","\$/\$")
  xMMSF = CreateVariableInHDF5(db, "TCalDB/xMMSF", (:Enduse, :Tech, :EC, :Area, :Year),"Historical Market Share Fraction by Device (Fraction)","Fraction")
end # struct TCalDB
