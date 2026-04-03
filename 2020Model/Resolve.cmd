rem
rem  Resolve.cmd
rem  Note: Dheepak recommends not using this file - Jeff Amlin 8/21/23
rem
     @echo off
rem  Resolve all dependencies required for Small Julia (this only needs to be done once but no harm in running it every time)
rem
     cd ..
     julia -e "import InteractiveUtils; println(InteractiveUtils.versioninfo())"
     Echo Resolving dependencies ...
     julia --project -e "using Pkg; Pkg.resolve()"
     Echo %Date% ;%Time%; End Pkg for Small Model >> log/RunAll_Report.log
rem
rem  Pause till the user hits a key to exit
rem
     pause
