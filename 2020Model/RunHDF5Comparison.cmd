rem
rem  RunHDF5Comparison.cmd
rem
rem 
     julia --threads 25 --project DatabaseCompare.jl "Base" "C:\2020CanadaTanoak_Jeff\2020Model\Base\database.hdf5" "BasePromula" "C:\2020CanadaTanoak_Jeff\2020Model\BasePromula\database.hdf5"
     Pause