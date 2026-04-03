import EnergyModel
import EnergyModel.Engine.EPeakHydro as E
# import EnergyModel: ReadDisk
# year = 2020
# db = EnergyModel.DB
node = 3
data = EnergyModel.Engine.EPeakHydro.Data(; db = EnergyModel.DB, year = 2020, prior = 2019, next = 2021);
E.BuildAnnualLoadCurve(data)
E.CreateLoadCurveTimeA(data,2)
PeakUnitsIndex = E.GetPeakLoadUnits(data, node)
E.TotalCapacityAndEnergy(data, node, PeakUnitsIndex)
E.InitalizePeakHydro(data, node)
(;Loop1,Loop1P) = data;
while Loop1
  (Loop1, Loop1P) = E.AllocateHydroStartingWithPeak(data, node, Loop1P)
end # Loop1
E.CombineCapacityFromPeakAndBase(data, node)
E.NormalizeToTotalCapacityAndTotalEnergy(data, node)
E.AllocateToUnitsAndMapBackToMonthsAndTimePeriods(data, node, PeakUnitsIndex)

E.HydroControl(data)

(; Loop1P, Loop1) = data;
i = 1
while Loop1
  print("\n\nOuter loop: ", i, " and Loop1P is ", Loop1P)
  (Loop1, Loop1P) = E.AllocateHydroStartingWithPeak(data, node, Loop1P)
  print("\nLoop1P is ", Loop1P, " and Loop1 is: ", Loop1)
  i += 1
end
(; Loop2P, Loop2) = data;
print(Loop2P, Loop2)
while Loop2
  # print("\n\nOuter loop: ", i, " and Loop2P is ", Loop2P)
  (Loop2, Loop2P) = E.AllocateHydroStartingWithBaseload(data, node, Loop2P)
  print("\nLoop2P is ", Loop2P, " and Loop2 is: ", Loop2)
end
# PeakUnitsIndex = EnergyModel.Engine.EPeakHydro.GetPeakLoadUnits(data, 1)
````
data = EnergyModel.Engine.EFlows.Data(;
  db = EnergyModel.DB,
  year = 2020,
  prior = 2019,
  next = 2021)

(; LLGen, HDLLoad) = data
@show sum(LLGen) # 453124.47546678036
@show sum(HDLLoad)

EnergyModel.Engine.EFlows.GenerationFlows(data)

@show AreaSales[Select(Area, "Newfoundland")] # 26770.373046875
EnergyModel.Engine.EFlows.IntraCountrySales(data, 2, 9)
```
