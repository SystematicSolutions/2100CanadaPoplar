# test

import EnergyModel as M

ECE = M.Engine.ECapacityExpansion

import EnergyModel: ReadDisk, WriteDisk, Select, HisTime, ITime, MaxTime, First, Future, Final, finite_inverse, finite_divide, finite_power, finite_exp, finite_log, @finite_math, @autoinfiltrate

CTime = 2048
year = CTime - ITime + 1; current = year;
prior = max(year-1, 1); next = min(year+1, Final);
db = M.DB


data = ECE.Data(; db=M.DB, year=year, current=current, prior=prior, next=next, CTime = CTime);

(; Year, Yrv, Area, Node, GenCo, Plant, Power, UnCode) = data;
(; UnOnLine, HDPDP1, HDPDPSM, UnGC, UnGCPrior, UnGCCR, Power, UnCode) = data;
(; Unit, TimeP, Month, UnArea, UnGenCo, UnNode, UnPlant) = data;
(; IPGCPr, HDRQ, NdArFr, PjNSw, BuildFr, BFraction, CUCMlt) = data;
(; IPGCRM, HDFGC, PjNSw, PwrFra) = data;

area = Select(Area,"ON")
node = Select(Node,"ON")
genco = Select(GenCo,"ON")
power = Select(Power)


IPGCRM[power,node,genco,area]
HDRQ[node]
HDFGC[node]
NdArFr[node,area]
PjNSw[node,genco,area]
BuildFr[area]
PwrFra[power,genco]

(; HDInflow,HDFlowFr,HDOutflow,HDXLoad,HDXLoadMax,USMT) = data;

HDInflow
HDFlowFr
HDOutflow
HDXLoad
USMT
Final
HorizonYear=Int(min(current+USMT[1],Final))

HDInflow[node]
HDOutflow[node]


Yrv[Final]
##

HDPDP1[1]
HDPDPSM[1]

unit = 999
timep=Select(TimeP)
month=Select(Month)
area=Select(Area,UnArea[unit])
genco=Select(GenCo,UnGenCo[unit])
node=Select(Node,UnNode[unit])
plant=Select(Plant,UnPlant[unit])
UnPlant[unit]
UnArea[unit]

UnGC[unit]
UnGCPrior[unit]
UnGCCR[unit]



# ECE.InitializeCapacityExpansion(data)

# ECE.CgCtrl(data)
# ECE.CgInitiation(data)
# ECE.CgConstruction(data)

# ECE.Ctrl(data)
# ECE.FirmCapacityFromPowerContracts(data)
# ECE.CapacityRequirementsForecast(data)
# ECE.FirmCapacityFromExistingUnits(data)
# ECE.FirmCogenerationCapacitySoldToGrid(data)
# ECE.FirmCapacityAvailable(data)
# ECE.CapacityAlreadyDeveloped(data)
# ECE.CapitalCostMultiplierFromDepletion(data)
# ECE.CapitalCostMultiplierFromETC(data)
# ECE.CapacityCapitalCost(data)
# ECE.FuelPrices(data)
# ECE.ProjectCosts(data)
# ECE.CapacityUnderConstructionMultiplier(data)
# ECE.BuildFractionBasedOnClearingPrice(data)
# ECE.CapacityNeededBasedOnClearingPrice(data)
# ECE.CapacityNeededForReserveMargin(data)
# ECE.BuildNewCapacity(data)
# ECE.Initiation(data)
  # ECE.NewCapacityInitiated(data)
#     ECE.AwardNewCapacityByCost(data,1,1,1)
#     ECE.AwardNewCapacityByPortfolio(data,1)
  # ECE.OtherCapacity(data)
  # ECE.IntermittentPowerExpansion(data)
    # ECE.BuildIntermittentPower(data,1,1,1,1)
  # ECE.RnRPS(data)
    # ECE.BuildCapacityInsideArea(data,1)
    ECE.BuildCapacityInAnyArea(data,1)
#   ECE.RnFIT(data)
# ECE.UnitInitiation(data)
  # unit = ECE.GetUtilityUnits(data)
#   ECE.CreateNewUnit(data,1,1,1,1)
#     ECE.TrackingForUnit(data,1,1,1,1)
#     ECE.AssignLabelsToUnit(data,1,1,1,1,1)
#     ECE.CreateUnitAndFacilityName(data,1,1,1,1,1)
#     ECE.CreateUnitCode(data,1,1,1,1,1)
#     ECE.UnitOnlineDate(data,1,1)
#     ECE.ExchangeRates(data,1,1)
#     ECE.InflationRates(data,1,1)
#     ECE.RetirementYear(data,1,1:3)
#     ECE.CapitalAndOMCosts(data,1,1,1)
#     ECE.FuelTypeAndHeatRate(data,1,1,1)
#     ECE.OutageRates(data,1,1,1)
#     ECE.StorageParameters(data,1,1,1)
#     ECE.ReserveRequirements(data,1,1,1)
#     ECE.EmissionParameters(data,1,1,1)
#     # ECE.MaxUnitError(data)
#   ECE.UnitOnlineDate(data,1,1)

#   unit = round.(Int, ECE.GetUtilityUnits(data))
#   ECE.UnitConstruction(data,unit)

#   ECE.ConstructionTotals(data)


ECE.Ctrl(data)


nothing
