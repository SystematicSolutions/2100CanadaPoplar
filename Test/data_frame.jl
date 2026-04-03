using EnergyModel
import EnergyModel: Select

using HDF5
using DataFrames

path = "C:/2020GIT/2020CanadaRedwood/2020Model/StartBase/database.hdf5"
file = h5open(path, "r")

SB_TInput = read(file, "TInput")


close(file)


