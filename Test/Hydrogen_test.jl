import JuliaCompare as J
import EnergyModel as M 
import PromulaDBA as P
using DataFrames, DataFramesMeta, CSV

red25a = J.loc("C:/2020CanadaRedwood/2020Model/Ref25A", "Red25A")
pine = J.loc("C:/2020CanadaPine/2020Model/Ref25A", "Pine25A")
ref25a = [red25a, pine]

red25 = J.loc("C:/2020CanadaRedwood/2020Model/Ref25", "Red25")
pine25 = J.loc("C:/2020CanadaPine/2020Model/Ref25", "Pine25")
ref25 = [red25, pine25]

sec = 'I'
fltr = J.fltr()

H2Exports = J.var("H2Exports", ref25; fltr, sec, diff = true)
@rsubset H2Exports :Red25_minus_Pine25 != 0
@rsubset! H2Exports :Nation == "CN" :Year in string.(2020:2050)
J.plot_lines(H2Exports, ref25; title = "Hydrogen Exports from Canada in Ref25", units = "TBtu")

push!(fltr, :Year => string.(2020:2030))
H2Production_red = J.var("SpOutput/H2Production", ref25; fltr, sec, diff = true)
H2Production_pine = J.var("SpOutput/H2Production", ref25; fltr, sec, diff = true)
J.plot_sets(H2Production_red; col = "Red25", dim = "Area", title = "Redwood Ref25A Hydrogen Production by Area", units = "TBtu")
J.plot_sets(H2Production_pine; col = "Pine25", dim = "Area", title = "Pine Ref25A Hydrogen Production by Area", units = "TBtu")

H2Dem = J.var("H2Dem", ref25; fltr, sec, diff = true)
J.plot_sets(H2Dem; col = "Red25", dim = "Area", title = "Redwood Ref25A Hydrogen Demand by Area", units = "TBtu")
J.plot_sets(H2Dem; col = "Pine25", dim = "Area", title = "Pine Ref25A Hydrogen Demand by Area", units = "TBtu")

H2ExportsEst = J.var("H2ExportsEst", ref25; fltr, sec, diff = true)
@rsubset H2ExportsEst :Red25 != 0
NH3Exports = J.var("NH3Exports", ref25; fltr, sec, diff = true)
@rsubset NH3Exports :Red25 != 0

push!(fltr, :Nation => "CN")
H2ENPNExports = J.var("H2ENPNExports", ref25; fltr, sec, diff = true)

push!(fltr, :Year => "2025")
push!(fltr, :Area => "AB")
J.var("H2Dem", ref25; fltr, sec, diff = true)
J.var("SpOutput/H2Production", ref25; fltr, sec, diff = true)
J.var("H2ProdTarget", ref25; fltr, sec, diff = true)
J.var("H2ProdTargetN", ref25; fltr, sec, diff = true) # ProdTargetN much higher than H2DemNation
J.var("H2DemNation", ref25; fltr, sec, diff = true)

#   @. H2ProdTargetN = (H2DemNation*(1+H2DemGR*max(1.0,H2CD/2))-H2ImportsEst)+H2ExportsEst
J.var("H2ImportsEst", ref25; fltr, sec, diff = true) # 0
J.var("H2ExportsEst", ref25; fltr, sec, diff = true) # 0
J.var("H2DemGR", ref25; fltr, sec, diff = true) # .49
J.var("H2CD", ref25; fltr, sec, diff = true) # 1
# @. @finite_math H2DemGR = (H2DemNation/H2DemSm-1)/H2SmT
H2DemNation = J.var("H2DemNation", ref25; fltr, sec, diff = true) # 35
H2DemSm = J.var("H2DemSm", ref25; fltr, sec, diff = true) # 17
H2SmT = J.var("H2SmT", ref25; fltr, sec, diff = true) # 2
(H2DemNation[1,:Pine25]/H2DemSm[1,:Pine25]-1)/H2SmT[1,:Pine25]

push!(fltr, :Year => string.(2020:2050))
H2DemNation = J.var("H2DemNation", red25; fltr, sec) # 35
H2DemSm = J.var("H2DemSm", red25; fltr, sec) # 17
H2DemGR = J.var("H2DemGR", red25; fltr, sec) # 
H2ProdTargetN = J.var("H2ProdTargetN", red25; fltr, sec) # 
H2ProdNation = J.var("H2ProdNation", red25; fltr, sec) # 
H2Exports = J.var("H2Exports", red25; fltr, sec) # 
H2Imports = J.var("H2Imports", red25; fltr, sec) # 
H2SmT = J.var("H2SmT", red25; fltr, sec) # 
NH3H2Yield = J.var("NH3H2Yield", red25; fltr, sec) # 
H2CapTotal = J.var("H2CapTotal", red25; fltr, sec) # 
df = J.join_vars(H2DemNation,H2DemSm,H2DemGR,H2ProdTargetN)
df = J.join_vars(df,H2ProdNation,H2Exports,H2Imports)
import EnergyModel: ReadDisk
 ReadDisk(red25.HDF5_path,"SpInput/NH3H2Yield")

# @. @finite_math H2DemSm = H2DemSmPrior+(H2DemNation-H2DemSmPrior)/H2SmT
# @. @finite_math H2DemGR = (H2DemNation/H2DemSm-1)/H2SmT
# @. H2ProdTargetN = (H2DemNation*(1+H2DemGR*max(1.0,H2CD/2))-H2ImportsEst)+H2ExportsEst
H2SmT = 1
for r in 2:11
    df[r,:H2DemSm] = df[r-1,:H2DemSm]+(df[r,:H2DemNation]-df[r-1,:H2DemSm])/H2SmT
    df[r,:H2DemGR] = (df[r,:H2DemNation]/df[r,:H2DemSm]-1)/H2SmT
    df[r,:H2ProdTargetN] = df[r,:H2DemNation]*(1+df[r,:H2DemGR])
end
df

pwd()
include("Policy/Ind_H2_NoSmooth.jl")
include("Policy/Ammonia_Exports.jl")
include("Policy/Ind_H2_FeedstocksAP.jl")
include("Policy/Ind_H2_DemandsAP.jl")

import EnergyModel: DB;
Ind_H2_NoSmooth.PolicyControl(DB)
Ammonia_Exports.PolicyControl(DB)
Ind_H2_FeedstocksAP.PolicyControl(DB)
Ind_H2_DemandsAP.PolicyControl(DB)

J.var("NH3H2Yield", ref25)
