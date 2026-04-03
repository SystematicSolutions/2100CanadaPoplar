rem
rem  SaveDatabase.bat
rem  Save Julia HDF5 database by zipping into a newly created subdirectory
rem
rem  %1 - Scenario Name and subdirecotry name
rem
     RD /s/q %1
     MD %1
     Call Zip Results %1\database database.hdf5
     Call Zip Results %1\%1_TOMFiles.zip TOMDatabase_%1.db TOM_Outputs_%1.csv

rem  Copy database.hdf5 %1\database.hdf5
rem