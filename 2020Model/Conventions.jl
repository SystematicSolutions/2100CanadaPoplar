# SSI Julia Conventions

## General
# Mirror Promula codes as closely as possible.  Differences should only be due to differences 
# in syntax and structure which make it very difficult to mirror the Promula.  
# This includes retaining the “single equation” functions.  We will hotly debate 
# this topic in 2024, but for this first round we want to retain the functions.
# Everything we create in the model (variable, sets, functions) should be in title case, 
# aka upper camel case, where each word in the variable name is capital case including the 
# first word.  There is an exception for subsets (enduse = Select(Enduse)).  
# For now, the behind-the-scenes code (for example, Core.jl) are using lower case 
# for the entities which stay hidden from the model.  Constants are not an exception 
# and should be in title case.

# At the top of each file is the file name, for example:
#
# FileName.jl
#

## Spacing 
# There is not a space after a comma.

# Review the “struct” stuff at the beginning of a function
(; CalDB,Input,Outpt) = data      #if needed is the first line.

# The time and years sets and variables are on the next line(s).
# The sets, in alphabetical order, are on the next line(s).
# The variables, in alphabetical order, are on the next line(s).

## Line Lengths
# The lines should generally end at about column 72
# The lines should never go past column 95

## Scratch Variables 
# Dimensions of scratch variables are defined with the length(set)
     DmdTotal::VariableArray{2}=zeros(Float32,length(EC),length(Year)) # [EC,Year] Total Demand (TBtu/Yr)
#Not by the size(set,1) 
     Target::VariableArray{1} = zeros(Float32, size(Year,1)) # [Year] Policy Fuel Target (Btu/Btu)

# Question – Space before and after equal sign in an equation?
# Question – Sets as letters in the equations (area vs a)?
# Question – Year set as an exception (use y instead of year)?

# Question – Selecting years
Yr2030=2030-ITime+1
Yr2030=Select(Year, “2030”)
Yr2030=Yr(2030) where Yr is a function

# Question – format for selecting sets
    elec = Select(Tech,"Electric")
    on = Select(Area,"ON")
# or
    Electric = Select(Tech,"Electric")
    ON = Select(Area,"ON")
# or
    Other?

# We could define most these variables, however we want, at the top of the program, 
# which would eliminate the need to implement the selection throughout the code, 
# especially when it comes to year pointers.  Arash   24.05.03


## Imports
# The finite_math functions should be on a separate line.
# The DT variable is imported and on the first line.  DT is not defined in the struct.
# These should be placed at the top of all the Engine, Output, Input and Policy files.

#
########################
#
# Equations
#
# The equations should generally be “verbose” with “for” loops and each set delineated or,
# if possible, equations with no sets delineated with an @. in the equation.  The equations
# will generally have the spaces removed, will only have about 70-80 charcaters per line,
# and will use use as few lines as possible to improve readability.
# We want to avoid the following operators   “ .=  .* :  “
# Avoid += -= *= /=
#
# Please avoid this.  It requires additional analysis of the 
# dimensions of the variables.
#
xTotDemand[Fuels,ECCs,Areas,Years] = xEuDemand[Fuels,ECCs,Areas,Years]+
   xCgDemand[Fuels,ECCs,Areas,Years]+xFsDemand[Fuels,ECCs,Areas,Years]  
#   
# becomes (assumes all variables have the same dimensions)
#
@. xTotDemand = xEuDemand+xCgDemand+xFsDemand
#  xTotDemand = xEuDemand+xCgDemand+xFsDemand  ??


#
# Please avoid this.  It requires additional analysis of the 
# dimensions of the variables.
#   
Electric = Select(Fuel,"Electric")
xTotDemand[Electric,ECCs,Areas,Years] = xTotDemand[Electric,ECCs,Areas,Years]-
  xCgEC[ECCs,Areas,Years]*EEConv/1E6
#   
# becomes (since all variables do not have the same dimensions)
#
Electric = Select(Fuel,"Electric")  
for year in Years, area in Areas, ecc in ECCs
  xTotDemand[Electric,ecc,area,year] = xTotDemand[Electric,ecc,area,year]-
    xCgEC[ecc,area,year]*EEConv/1E6
end


#
#  Please avoid the square bracket at the beginning of the line.  
#
[EuDemandEC[fuel,ECs,Areas,Years] = sum(xDmd[eu,tech,ECs,Areas,Years] .*
  xDmFrac[eu,fuel,tech,ECs,Areas,Years] for eu in Enduses, tech in Techs) for fuel in Fuels]
#
# Becomes:
#
for year in Years, area in Areas, ec in ECs, fuel in Fuels
  EuDemandEC[fuel,ec,area,year] = sum(xDmd[eu,tech,ec,area,year]*
    xDmFrac[enduse,fuel,tech,ec,area,year] for enduse in Enduses, tech in Techs)
end

#
# Avoid the square bracket at the beginning of the RHS
# Avoid the year select inside the equation
#
PEDC[eccs,area,First:Future5] = [(xPE[ecc,area,year] * xInflation[area,year] / (1+FPSMF[fuel,es,area,year]) -
  (PPUC[area,year-1] - ExportsPE[area,year-1] + FPTaxF[fuel,es,area,year])) / xInflation[area,year] for ecc in eccs, year in First:Future5]
#
# Becomes (area, es, and eccs are already selected)
#
years = collect(First:Future5)
for year in years, ecc in eccs
  PEDC[ecc,area,year] = (xPE[ecc,area,year]*xInflation[area,year]/(1+FPSMF[fuel,es,area,year])-
    (PPUC[area,year-1]-ExportsPE[area,year-1]+FPTaxF[fuel,es,area,year]))/xInflation[area,year]
end




## Sets
# The set defintions are as follows.  Note the Set is defined with the “Key”, not the “DS”.
  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int}    = collect(Select(Area))

# In loops and summations, use for area in Areas.

# For single selection of a set use the lower case (area), as opposed to adding a prefix or suffix.  
# The exceptions are with a subset which has a meaning like areas in Canada or GHG pollutants.  
# In these cases title case is expected.  A suffix is preferred, but not required.  
# In fact, naming the subsets is not required (for example in the output files),
# but is an option to improve readability.
AreasCanada = Select(Area, (from = "ON", to = "NU"))
GHG = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])

#
#  The Yr functionshouldbe used directly
#
Yr2000 = Yr(2000)
Yr2013 = Yr(2013)
years = collect(Yr2000:Yr2013)
#
# Becomes
#
years = collect(Yr(2000):Yr(2013))


# The sets inside the equations are written out “enduse” for “Enduse” set.   
# The set list is as follows

Set Descriptors Set Keys        Set Iteration Variable  Set Iterator
EnduseDS        EnduseKey       Enduses enduse
                        
                        
## Variable lists and data struct
# There is a standard order for the sets in a variable.  I will not delineate it now, 
# but if you need to add a new variable, please follow the order of the existing variables.  
# This will be more important once we are developing new code in Julia.  
# There are some violations in the Promula code, but mirror the Promula code for 
# the translation.  These spaces after db, should be removed.

## Comments
# Each comment block should contain a # blank line before and after each comment block.  
# There should also be a blank line before the start of a comment block:

#
# ENERGY 2020 is a great model. 
# ECCC is the best government agency ever to exist.
# SSI is a cool place to work. 
#

## Follow Up
# In case of follow up, leave the following comment in the code so it could be traced back later:
# TODO

# Also, it is helpful if you include following approaches.
# Usual # TODO is used for any issue that requires immediate attention.
# If the issue is related to TIM, you should use # TODO TODOTIM. 
# Also, if the issue is something that could be addressed in the future use # TODO TODOLater.
# These distinctions are very helpful in identifying and addressing issues necessary to meet the deadlines.

## Time Variables
# Cardinal Numbers – current, prior, next, last, future, final, itime as cardinal numbers
# Dates  – CTime, PriorTime, NextTime, HisTime, ITime (2025, 2024, 2026, 2021, 1985)

## Logging
# You can use following commands to write logs.
@debug
# Will write to a log file. It will not show up on the screen. It is very safe to use since the information will not be displayed on the screen. 
@info
# This is useful to write information on the screen as well as the file. This is useful in case of tracking the code at high level.
@warn
# If you like to warn the user about an issue. Warn logs usually have more details.
@error
# Highest level of logging. Reseved to display error messages.
#
## Misc.
# The order of source code files, when in a list, should follow the Promula order in 
# files like “Compile.bat”.
# The indentations are two spaces. 
# We are still working on debugging messages, but for now, comment out your debugging 
# messages when you completed the debugging of the file.


#
## SSI Translation Hacks
# Scalars and Vectors 

# Scalars defined by “tv” which do not change values can defines as follows (this is the convention):
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  if BaseSw == 0.0
# Scalars defined by “tv” which change values inside a module must be define as a vector (this would be used only when giving BaseSw a value) :
  BaseSw::VariableArray{1} = ReadDisk(db, "SInput/BaseSw")
  BaseSw[1] == 0.0
# Scalars which are changed and only used locally can have their values passed between functions.

#   - Jeff Amlin 11/29/23  

# Accessing Databases of “Other” Cases

# From an older Promula version of SpOProd.src 
FText1=BCName::0+"\SOutput.dba"
Open SOutput FText1
        Read Disk (BaENPN)
        Open SOutput "SOutput.dba"

# In the struct (after the sets and before the variables), define the database name (this is the full path name for the database):
 BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB")   #  Base Case Name

# Define the variable as following:
BaENPN::VariableArray{2} = ReadDisk(BCNameDB, "SOutput/ENPN", year) #[Fuel,Nation,Year]  Base Case Price Normal ($/mmBtu)

# The case name is also available, if you need it:
BCName::String = ReadDisk(db, "MainDB/BCName") #  Base Case Name

# To access the databases from the other cases, replace BCName with RefName, OGRefName, InitialName, or Run1Name.
#   - Jeff Amlin 10/6/23  

#
########################
#
# Sum before division separation
#
# Promula:
FPCP(Fuel,EC,A)=sum(EU,Tech)(PCostTech(Tech,EC,A)*DmdFuelTech(EU,Fuel,Tech,EC,A))/
                                  sum(EU,Tech)(DmdFuelTech(EU,Fuel,Tech,EC,A))  
# Julia:
PCostTechSum[fuel,ec,area] = 0
DmdFuelTechSum[fuel,ec,area] = 0
for enduse in Select(Enduse), tech in Select(Tech)
var1=PCostTechSum[fuel,ec,area]+ (PCostTech[tech,ec,area]*DmdFuelTech[enduse,fuel,tech,ec,area]) 
var2=DmdFuelTechSum[fuel,ec,area] + DmdFuelTech[enduse,fuel,tech,ec,area]
end
@finite_math FPCP[fuel,ec,area] = var1 / var2
#
# From Jeff:
#
for fuel in Fuels, ec in ECCs, area in Areas 
@finite_math FPCP[fuel,ec,area] =
  sum(PCostTech[tech,ec,area]*DmdFuelTech[enduse,fuel,tech,ec,area] enduse in Enduses, tech in Techs)/
  sum(DmdFuelTech[enduse,fuel,tech,ec,area]) enduse in Enduses, tech in Techs)
end

Weighted averages use single letter indexes to shorten equation

For f in Fuels, ec in ECCs, a in Areas 
@finite_math FPCP[fuel,ec,area] = sum(PCostTech[t,ec,a]*DmdFuelTech[eu,f,t,ec,a] eu in Enduses, t in Techs)/
  Sum(DmdFuelTech[eu,f,t,ec,a]) eu in Enduses, t in Techs)
end



# Calculate maximum over one dimension
PCCov[fuel, ec, poll, area] = maximum(PCCovTemp[fuel, ec, poll, : , area])
# PCCovTemp[fuel, ec, poll, pcov, area]

# Could we build a macro/function?
PCCov[fuel,ec,poll,area] = @max(pcov,PCCovTemp[fuel,ec,poll,pcov,area])


# Select with Not equals
otherpolls = Select(Poll, !=("Carbon Dioxide"))

waste1 = Select(Waste, !=("YardAndGardenDry"))
waste2 = Select(Waste, !=("YardAndGardenWet"))
waste = intersect(waste1,waste2)


#
# Please avoid the following:
#
eccs = findall(x -> x == "SolidWaste"   ||
                    x == "Wastewater"   ||
                    x == "Incineration" ||
                    x == "LandUse"      ||
                    x == "RoadDust"     ||
                    x == "OpenSources"  ||
                    x == "ForestFires"  ||
                    x == "Biogenics",ECC)
#
# becomes
#
eccs = Select(ECC,["SolidWaste","Wastewater","Incineration","LandUse",
                   "RoadDust","OpenSources","ForestFires","Biogenics"])







#
########################
#
# GetUnitSets
#
# 1) should be define the same
#
function GetUnitSets(data::Data,unit)
  (; Area,ECC,GenCo,Node,Plant) = data
  (; UnArea,UnGenCo,UnNode,UnPlant,UnSector) = data
  #
  # This procedure selects the sets for a particular unit
  #
  EmptyString = ""
  # TestString = UnGenCo[unit]
  # @info "  EPollution.jl - GetUnitSets - Unit = $unit, UnGenCo = $TestString"
  if UnGenCo[unit] !== EmptyString
    genco = Select(GenCo,UnGenCo[unit])
    plant = Select(Plant,UnPlant[unit])
    node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])
    return genco,plant,node,area,ecc
  end
end # GetUnitSets

#
# 2) GetUnitSets should be called the same 
# 
genco,plant,node,area,ecc = GetUnitSets(data,unit)

#
# 3) GetUnitSets - do we check for failue?  Can we check to see if first set is empty?
#
function GetUnitSetsMG(data,unit)
  (; Area,ECC,GenCo,Node,Plant) = data
  (; UnArea,UnGenCo,UnNode,UnPlant,UnSector) = data
  #
  # This procedure selects the sets for a particular unit
  #
  if (UnGenCo[unit] != "Null") && (UnPlant[unit] != "Null") && (UnNode[unit] != "Null") && (UnArea[unit] != "Null") && (UnSector[unit] != "Null")
    genco = Select(GenCo,UnGenCo[unit])
    plant = Select(Plant,UnPlant[unit])
    node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])
    valid = true
  else
    genco=1
    plant=1
    node=1
    area=1
    ecc=1
    valid = false
  end
  return genco,plant,node,area,ecc,valid
end # GetUnitSets
#
  ec,ecc,area = GetUnitSets(data,unit)
  if ec != [] && area != []
    ec = ec[1]
    area = area[1]

#
# 4) GetUnitSets - othercurrent variants
#
  function  GetUnitSets(data::Data,unit)
    (; Area,GenCo,Node,Plant) = data
    (; UnArea,UnGenCo,UnNode,UnPlant) = data

    gencoindex = Select(GenCo,UnGenCo[unit])
    plantindex = Select(Plant,UnPlant[unit])
    nodeindex = Select(Node,UnNode[unit])
    areaindex = Select(Area,UnArea[unit])

    return gencoindex,plantindex,nodeindex,areaindex
  end
#
function GetUnitSets(data::Data,unit)
  (; Area,GenCo,Node,Plant) = data
  (; UnArea,UnGenCo,UnNode,UnPlant) = data

  plant = Select(Plant, UnPlant[unit])
  node = Select(Node, UnNode[unit])
  genco = Select(GenCo, UnGenCo[unit])
  area = Select(Area, UnArea[unit])

  return plant,node,genco,area

end
#
function GetUnitSets(data,unit)
  (; Area,ECC) = data
  (; UnArea,UnSector) = data
  #
  # This procedure selects the sets for a particular unit
  #
  if (UnArea[unit] !== "Null") && (UnSector[unit] !== "Null")
    # genco = Select(GenCo,UnGenCo[unit])
    # plant = Select(Plant,UnPlant[unit])
    # node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])
    return area,ecc
    # return genco,plant,node,area,ecc
  end
end
#
function GetUnitSets(data,unit)
  (; db) = data
  (; Area,GenCo,Node,Plant) = data
  (; UnArea,UnGenCo,UnNode,UnPlant) = data

  plant = Select(Plant,UnPlant[unit])
  node = Select(Node,UnNode[unit])
  genco = Select(GenCo,UnGenCo[unit])
  area = Select(Area,UnArea[unit])

  return plant,node,genco,area
end
#
function GetUnitSets(data,unit)
  (; Area,EC,ECC,UnArea,UnSector) = data;
  #
  # This procedure selects the sets for a particular unit
  #
  ec = findall(x -> x == UnSector[unit], EC)
  ecc = findall(x -> x == UnSector[unit], ECC)
  area = findall(x -> x == UnArea[unit], Area) 
  return ec,ecc,area
end
#
function GetUnitSets(data,unit)
  (; Area,EC,ECC,UnArea,UnSector) = data
  #
  # This procedure selects the sets for a particular unit
  #
  ec = findall(EC .== UnSector[unit])
  ecc = findall(ECC .== UnSector[unit])
  area = findall(Area .== UnArea[unit])
  return ec,ecc,area
end


#
########################
#
# Select ECC from EC or 
#
for ec in ECs
  ecc = Select(ECC,EC[ec])
#
# Does this work?
#
for ecc in ECCs
  ec = Select(EC,ECC[ecc])

#
# Do we need to test?
#
for ecc in ECCs
  ec = findall(ECCMap[:,ecc] .== 1.0)
  if ec != []
    ec = ec[1]














# Sorting
# If we have peak hydro demand dimensioned over node and time period and we want the order of time periods sorted by demand from high to low here’s how you do that in Promula:
Select Node(AB)
Sort Descending TimeA Using PHPDP0
TimeASort(TimeA)=PHPDP0(Node,TimeA)
Sort Descending TimeA Using TimeASort
# This goes order is used by assigning new variables that are ordered accordingly. First a non-sorted variable is used on the LHS (here TACount). So here, PtTA1 is the sorted version of PtTA0. 
TACount=1
Do TimeA
  PtTA1(TACount)=PtTA0(T)
  PHPDP1(N,TACount)=PHPDP0(N,T)
  HrTA1(TACount)=HrTA0(T)
  TACount=TACount+1
End Do TimeA
Select TimeA*
# In Julia, this can be done by leveraging the sortperm function. 
timea = Select(TimeA)
node = Select(Node, “AB”)
new_order = sortperm(PHPCP0[node, timea], rev = true)
# then new variables are assigned using the indices “new_order”
PtTA1[timea] = PtTA0[new_order]
PHPDP1[node, timea] = PHPDP0[node, new_order]
HrTA1[timea] = HrTA0[new_order]
# Another example, let’s say you have subset of units:
units = Select(UnNode, ==(NodeKey[node]))
and you want to order that subset by the units’ variable costs, UnVCostUS, then:
units = units[sortperm(UnVCostUS[units])]

# First, this code subsets variable costs to the subset of units we already have: 
UnVCostUS[units]
# Next, the function sortperm returns the indices of that subset of variable costs in the ascending order of marginal costs. If there are 3 units, sortperm will return 1, 2, 3 in some order. 
units[sortperm(…)]
# will return a permutation (reordering) of units. 
# This can be done, perhaps more parsimoniously, with the call:
sort!(units; by = u -> UnVCostUS[u])


#
# Subsets
# Here are definitions of some common subsets that exist in the code in different module.
# Demand:
  HeatpumpSubSet = ["Geothermal","HeatPump","DualHPump","FuelCell"]
  RetrofitEnduseSubSet = ["Heat","Ground","Air/Water","Carriage"]








# Suggestion box / Sandbox
# Here you can discuss possible changes or suggestions.
# Variable definitions – change format so sets are part of the function
# Add scratch variables at top of file or top of function
# Use “sum” instead of “+=”
@finite_math – have a different, shorter name @math? 
# Remove spaces in equations
# Combine @. with @finite_math?
# Replace “for age in Select(Age)” with “for age in Ages”
# Add separate lines for totals to simplify equations
# Sum function and weighted average function
# Reading scalar variables from the database into a Julia struct:
UnCounter::Int = ReadDisk(db, "EGInput/UnCounter", year) #[Year]  Number of Units
# Setting type to ‘Int’ does not allow the variable to be updated
UnCounter::VariableArray{1} = [ReadDisk(db, "EGInput/UnCounter", year)] #[Year]  Number of Units
# Setting type to ‘VariableArray{1}’ and enclosing the right side in brackets turns this scalar into a 1D array and allows the variable to be updated, e.g.:
UnCounterPrior[1] = 12
UnCounterPrior.= UnCounterPrior.+1
# Make sure to add brackets when writing back to disk: UnCounterPrior[1]

# Declaring and using a scratch variable of type string in a Julia struct:
NewNum::SetArray = [""] # New Unit Number
#This creates a string array of size 1.
NewNum ::SetArray = fill("",1) # New Unit Number
# Replace the second argument in fill() with the desired size.
# To update: NewNum[1]="abc"

# Local scalar variables which change between functions can be passed to each function.  See CnNumber and HDPDPM in ERetailPurchases.jl

# // Turn off hover hints in VS Code
"editor.hover.enabled": false,



# Later
# Could we build a macro/function?
PCCov[fuel,ec,poll,area] = @max(PCCovT[fuel,ec,poll,pcovs,area],pcovs)
  EuDemand[fuel,ecc,area] = @sum(EuDemF[enduses,fuel,ecc,area],enduses)

#
# In the Ecost.jl move the write out of the function and at the end of Costs function.\
#

# New Function.
julia> Yr(x::Int) = x - M.ITime + 1
Yr (generic function with 1 method)
julia> Yr2020 = Yr(2020)
36
julia> Yr(2002)
18
