#
# RCalDB.jl - Input Database creation file
#

Base.@kwdef struct RCalDB <: HDF5GroupDatabase
  db::String=DB
  ########################
  #
  # Define Sets
  #
  Enduse = ReadSetFromCSV("EnduseRes","Key")
  EC = ReadSetFromCSV("ECRes","Key")
  Area = ReadSetFromCSV("Area","Key")
  Year = ReadSetFromCSV("Year","Key")
  tv = ReadSetFromCSV("tv","Key")
  Tech = ReadSetFromCSV("TechRes","Key")
  Hour = ReadSetFromCSV("Hour","Key")
  Day = ReadSetFromCSV("Day","Key")
  Month = ReadSetFromCSV("Month","Key")
  CTech = ReadSetFromCSV("CTechRes","Key")
  Fuel = ReadSetFromCSV("Fuel","Key")
  FuelEP = ReadSetFromCSV("FuelEP","Key")
  Poll = ReadSetFromCSV("Poll","Key")
  ########################
  #
  # Define Variables on Database
  #
  #! format: off
  CERSM = CreateVariableInHDF5(db, "RCalDB/CERSM", (:Enduse, :EC, :Area, :Year),"Capital Energy Requirement Multiplier (Btu/Btu)","Btu/Btu")
  CgCUF = CreateVariableInHDF5(db, "RCalDB/CgCUF", (:Tech, :EC, :Area, :Year),"Cogeneration Capacity Utilization Factor (\$/\$)","\$/\$")
  CgLSF = CreateVariableInHDF5(db, "RCalDB/CgLSF", (:Tech, :EC, :Hour, :Day, :Month, :Area),"Cogeneration Load Shape (MW/MW)","MW/MW")
  CgLSFSold = CreateVariableInHDF5(db, "RCalDB/CgLSFSold", (:EC, :Hour, :Day, :Month, :Area),"Cogeneration Sold to Grid Load Shape (MW/MW)","MW/MW")
  CgMSM0 = CreateVariableInHDF5(db, "RCalDB/CgMSM0", (:Tech, :EC, :Area, :Year),"Cogeneration Market Share Non-Price Factor (\$/\$)","\$/\$")
  CgMSMI = CreateVariableInHDF5(db, "RCalDB/CgMSMI", (:Tech, :EC, :Area),"Cogeneration Market Share Income Factor (\$/\$)","\$/\$")
  CgVF = CreateVariableInHDF5(db, "RCalDB/CgVF", (:Tech, :EC, :Area),"Cogeneration Variance Factor (\$/\$)","\$/\$")
  CHR = CreateVariableInHDF5(db, "RCalDB/CHR", (:EC, :Area),"Cooling to Heating Ratio (Btu/Btu)","Btu/Btu")
  CMSM0 = CreateVariableInHDF5(db, "RCalDB/CMSM0", (:Enduse, :Tech, :CTech, :EC, :Area, :Year),"Conversion Market Share Multiplier (\$/\$)","\$/\$")
  CMSMI = CreateVariableInHDF5(db, "RCalDB/CMSMI", (:Enduse, :Tech, :CTech, :EC, :Area),"Conversion Market Share Multiplier (\$/\$)","\$/\$")
  CUF = CreateVariableInHDF5(db, "RCalDB/CUF", (:Enduse, :Tech, :EC, :Area, :Year),"Capital Utilization Fraction (\$/Yr/\$/Yr)","\$/Yr/\$/Yr")
  CVF = CreateVariableInHDF5(db, "RCalDB/CVF", (:Enduse, :Tech, :CTech, :EC, :Area, :Year),"Conversion Market Share Variance Factor (DLESS)","DLESS")
  DEMM = CreateVariableInHDF5(db, "RCalDB/DEMM", (:Enduse, :Tech, :EC, :Area, :Year),"Max. Device Eff. Multiplier (Btu/Btu)","Btu/Btu")
  DmFracMSM0 = CreateVariableInHDF5(db, "RCalDB/DmFracMSM0", (:Enduse, :Fuel, :Tech, :EC, :Area, :Year),"Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu)","Btu/Btu")
  DSt0 = CreateVariableInHDF5(db, "RCalDB/DSt0", (:Enduse, :EC, :Area, :Year),"Device Saturation Fixed Utility (\$/\$)","\$/\$")
  DStI = CreateVariableInHDF5(db, "RCalDB/DStI", (:Enduse, :EC, :Area),"Device Saturation Income Utility (\$/\$)","\$/\$")
  DStM = CreateVariableInHDF5(db, "RCalDB/DStM", (:Enduse, :EC, :Area),"Max. Device Saturation (Btu/Btu)","Btu/Btu")
  DStP = CreateVariableInHDF5(db, "RCalDB/DStP", (:Enduse, :EC, :Area),"Device Saturation Price Utility (\$/\$)","\$/\$")
  DUF = CreateVariableInHDF5(db, "RCalDB/DUF", (:Enduse, :EC, :Day, :Month, :Area),"Daily Use Factor (Therm/Therm)","Therm/Therm")
  FsFracMSM0 = CreateVariableInHDF5(db, "RCalDB/FsFracMSM0", (:Fuel, :Tech, :EC, :Area, :Year),"Feedstock Fuel/Tech Fraction Non-Price Factor (Btu/Btu)","Btu/Btu")
  FsPEE = CreateVariableInHDF5(db, "RCalDB/FsPEE", (:Tech, :EC, :Area, :Year),"Feedstock Process Efficiency (\$/mmBtu)","\$/mmBtu")
  LSF = CreateVariableInHDF5(db, "RCalDB/LSF", (:Enduse, :EC, :Hour, :Day, :Month, :Area),"Load Shape Factor (DLESS)","DLESS")
  MMSM0 = CreateVariableInHDF5(db, "RCalDB/MMSM0", (:Enduse, :Tech, :EC, :Area, :Year),"Non-price Factors. (\$/\$)","\$/\$")
  MMSMI = CreateVariableInHDF5(db, "RCalDB/MMSMI", (:Enduse, :Tech, :EC, :Area),"Market Share Mult. from Income (\$/\$)","\$/\$")
  MVF = CreateVariableInHDF5(db, "RCalDB/MVF", (:Enduse, :Tech, :EC, :Area, :Year),"Market Share Variance Factor (\$/\$)","\$/\$")
  PEM = CreateVariableInHDF5(db, "RCalDB/PEM", (:Enduse, :EC, :Area),"Maximum Process Efficiency (\$/mmBtu)","\$/mmBtu")
  PEMM = CreateVariableInHDF5(db, "RCalDB/PEMM", (:Enduse, :Tech, :EC, :Area, :Year),"Pro. Eff. Max. Multi (\$/Btu/(\$/Btu))","\$/Btu/(\$/Btu")
  POCF = CreateVariableInHDF5(db, "RCalDB/POCF", (:Enduse, :Tech, :EC, :Area),"Process Operating Cost Fraction (\$/Yr/\$)","\$/Yr/\$")
  Polute = CreateVariableInHDF5(db, "RCalDB/Polute", (:Enduse, :FuelEP, :EC, :Poll, :Area, :Year),"Pollution (Tonnes/Yr)","Tonnes/Yr")
  RDMSM = CreateVariableInHDF5(db, "RCalDB/RDMSM", (:Enduse, :Tech, :EC, :Area, :Year),"Device Retrofit Market Share Multiplier (1/Yr)","1/Yr")
  RPMSM = CreateVariableInHDF5(db, "RCalDB/RPMSM", (:Enduse, :Tech, :EC, :Area, :Year),"Process Retrofit Market Share Multiplier (1/Yr)","1/Yr")
  xCgMSF = CreateVariableInHDF5(db, "RCalDB/xCgMSF", (:Tech, :EC, :Area, :Year),"Cogen Market Share (\$/\$)","\$/\$")
  xMMSF = CreateVariableInHDF5(db, "RCalDB/xMMSF", (:Enduse, :Tech, :EC, :Area, :Year),"Historical Market Share Fraction by Device (Fraction)","Fraction")
end # struct RCalDB
