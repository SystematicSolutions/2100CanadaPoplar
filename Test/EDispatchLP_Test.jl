import EnergyModel
import EnergyModel.Engine.EDispatchLP as ELP
import EnergyModel.Engine.EDispatch as ED
# import EnergyModel: ReadDisk
year = 40; prior = 39; next = 41
db = EnergyModel.DB
data = ED.Data(; db = EnergyModel.DB, year = year, prior = prior, next = next);
datalp = ELP.Data(; db = EnergyModel.DB, year = year, prior = prior, next = next);

month = 1; timep = 1;
ELP.ElectricDispatchLP(datalp, data, month, timep) # Note this function is defined in EDispatchLP.jl
