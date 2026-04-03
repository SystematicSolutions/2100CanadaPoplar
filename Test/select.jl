# Select Unit*
# Select Unit If UnNation eq "CN"
# Select Unit If (UnArea ne "YT") and (UnArea ne "NT") and (UnArea ne "NU")
# Select Unit If UnPlant ne "Coal"
# Select Unit If UnCogen eq 0
# Select Unit If xUnFlFr(Unit,NaturalGas,2050) gt 0.25
unit = Select(Unit)
unit = unit ∩ Select(UnNation, "CN") # this works because UnNation is the same size as Unit
unit = unit ∩ Select(UnArea, !=("YT")) ∩ Select(UnArea, !=("NT")) ∩ Select(UnArea, !=("NU"))
unit = unit ∩ Select(UnPlant, !=("Coal"))
unit = unit ∩ Select(UnCogen, 0)
unit = unit ∩ Select(xUnFlFr[:, Select(Fuel, "Natural Gas"), Select(Year, "2050")], >(0.25)) # TODO: I have to change one line in the Core folder for this to work

# Select Tech If (TechKey ne "Geothermal") and (TechKey ne "HeatPump") or (TechKey eq "FuelCell")
# Select Tech If ElecMap eq 1
# Select Tech If xMMSF ne -99
tech = Select(TechKey, !=("Geothermal")) ∩ Select(TechKey, !=("HeatPump")) ∩ Select(TechKey, !=("FuelCell"))
tech = tech ∩ Select(ElecMap, 1)
tech = tech ∩ Select(xMMSF, !=(-99.0)) # TODO: Same one line change required here for this to work

# Select Area If ANMap eq 1
# Select Area If DisposedSwitch eq 1
nation = Select(Nation, "Canada")
area = Select(ANMap[:, nation], 1) # this will not work if `nation = Select(Nation, ["Canada", "United States"])`

# Select Fuel If (xFsFrac gt 0) and (FsFPRef gt 0)
tech = ...
ec = ...
area = ...
year = ...
es = ...
fuel = Select(xFsFrac[:, tech, ec, area, year], >(0.0)) ∩ Select(FsFPRef[:, es, area], >(0.0)) # all of tech, ec, area, year, es have to be exactly one element selected

# Select EC If ECKey eq "LightOilMining"
ec = Select(EC, "Light Oil Mining")

# Select ECC If (ECCKey eq "ConventionalGasProduction") or (ECCKey eq "SweetGasProcessing") or (ECCKey eq "UnconventionalGasProduction") or (ECCKey eq "SourGasProcessing") or (ECCKey eq "LNGProduction") or (ECCKey eq "GasMining") or (ECCKey eq "GasProduction")
ecc = Select(ECCKey, "ConventionalGasProduction") ∪ Select(ECCKey, "SweetGasProcessing") ∪ Select(ECCKey, "UnconventionalGasProduction") ∪ Select(ECCKey, "SourGasProcessing") ∪ Select(ECCKey, "LNGProduction") ∪ Select(ECCKey, "GasMining") ∪ Select(ECCKey, "GasProduction")
ecc = Select(ECCKey, ["ConventionalGasProduction", "SweetGasProcessing", "UnconventionalGasProduction", "SourGasProcessing", "LNGProduction", "GasMining", "GasProduction"]) # This is the same thing as a short hand for union

# Select Unit If ((UnOnLine le CTime) and (UnRetire gt CTime) and (UnCogen eq 0))
unit = Select(UOnline, <(CTime)) ∩ Select(UnRetire, >(CTime)) ∩ Select(UnCogen, 0)
# Select Node if NodeKey eq UnNode
node = [i for (i, (k, u)) in enumerate(zip(NodeKey, UnNode)) if k == u] # Maybe we can think of a simpler way to represent this
