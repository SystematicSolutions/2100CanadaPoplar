rem
rem  ServeDocs.cmd
rem
     @echo off
rem
rem  Show the EnergyModel documentation
rem
     cd ..
     julia --project=docs -e "import Pkg; Pkg.instantiate(); Pkg.develop(Pkg.PackageSpec(path=\".\"))"
     julia --project=docs -e "using EnergyModel, LiveServer; LiveServer.servedocs(; launch_browser=true)"
rem
rem
rem
pause
