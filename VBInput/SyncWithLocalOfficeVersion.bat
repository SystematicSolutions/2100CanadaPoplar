::SyncWithLocalOfficeVersion.bat
@echo off
Set Root=%CD%
echo  SyncWithLocalOfficeVersion > SyncWithLocalOfficeVersion.log

if exist C:\Users\Owner\SSI Dropbox\2020ToolBox\ (Goto CopyFiles) else (Goto DoNotCopyFiles)
Goto DoNotCopyFiles

:CopyFiles
if exist "C:\Program Files (x86)\Microsoft Office\ThinAppXManifest.xml" (
  echo This is a 32 bit Office PC >> SyncWithLocalOfficeVersion.log
  echo Copy %Root%\32BitOfficeFiles\AccessTextConverter.exe %Root%\AccessTextConverter.exe >> SyncWithLocalOfficeVersion.log
  Copy %Root%\32BitOfficeFiles\AccessTextConverter.exe %Root%\AccessTextConverter.exe
  Goto FilesCopied
  ) else (
  echo This is a 64 bit Office PC >> SyncWithLocalOfficeVersion.log
  echo Copy %Root%\64BitOfficeFiles\AccessTextConverter.exe %Root%\AccessTextConverter.exe >> SyncWithLocalOfficeVersion.log
  Copy %Root%\64BitOfficeFiles\AccessTextConverter.exe %Root%\AccessTextConverter.exe
  Goto FilesCopied
  )

:DoNotCopyFiles
echo No Files copied >> SyncWithLocalOfficeVersion.log
Goto Done

:FilesCopied
:Done
)

