@echo off
    SETLOCAL ENABLEDELAYEDEXPANSION
    if not exist adsdll mkdir adsdll
    if not exist tmpdll mkdir tmpdll
    set gmsldir=%CD%\adsdll\
    set tmpdir=%CD%\tmpdll\
    set prmdir=%CD%\prmdir

    echo.
    echo prm -gmSL=%tmpdir%  run  %1.SRC
    prm -gmSL=%tmpdir%  run  %1.SRC || Pause
    pushd %tmpdir%
    if exist *.c (
      dir *.c /b >adsdll.set
      for /f %%j in (adsdll.set) do (
        set FullName=%%j
        set JustName=!FullName:Dll.c=!
        echo Processing C for !JustName!
        echo cl -c !JustName!Dll.c -DMSCX64 -W4 -I%prmdir% /O2  /MP /favor:blend /nologo
             cl -c !JustName!Dll.c -DMSCX64 -W4 -I%prmdir% /O2  /MP /favor:blend /nologo
 
        echo link -dll -out:!JustName!.dll !JustName!Dll.obj %prmdir%\gmSLmain.obj %prmdir%\gmSLstart.obj /nologo
             link -dll -out:!JustName!.dll !JustName!Dll.obj %prmdir%\gmSLmain.obj %prmdir%\gmSLstart.obj /nologo
      )
    move /Y %tmpdir%\* %gmsldir% >nul 2>&1
    )
    popd

    endlocal
@echo on
