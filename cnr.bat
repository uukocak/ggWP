@echo off
del *.exe
del gui.obj
del gui.map
del linklog.txt
del complog.txt
ml /c /Cp gui.asm > complog.txt
cls
echo ASSEMBLY DONE
link gui.obj,,,,, > linklog.txt
echo LINKING DONE
gui.exe
