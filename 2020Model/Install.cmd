rem
rem  Install.cmd
rem

rem  Install all dependencies required for Small Julia (this only needs to be done once but no harm in running it every time)
rem
     cd ..
     julia -e "import InteractiveUtils; println(InteractiveUtils.versioninfo())"
     Echo Installing dependencies ...
     julia --project -e "using Pkg; Pkg.update(); Pkg.instantiate()"
     Echo %Date% ;%Time%; End Pkg for Small Model >> log/RunAll_Report.log
rem
rem  Pause till the user hits a key to exit
rem
     pause
