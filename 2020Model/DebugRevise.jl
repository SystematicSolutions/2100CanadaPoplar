# import Revise
import EnergyModel as M
mod = M.Engine.ElectricPrice
data = mod.Data(; db=M.DB, year=1990, prior=1989, next=1991)
mod.Revenue(data)

nothing
