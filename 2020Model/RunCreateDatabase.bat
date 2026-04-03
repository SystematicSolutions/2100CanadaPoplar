rem
rem  RunCreateDatabase.bat
rem
     Call UnZip DB %1
     
     Call RunJulia RunCreateDatabase.jl
     
     RD /s/q %1
     MD %1
     Call Zip Results %1\database *.hdf5
     Call UnZip RefDB %1
     
rem
rem  Pause till the user hits a key to exit
rem
rem  pause
