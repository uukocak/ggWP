@echo off
if [%1]==[clean] goto :clean
if [%1]==[run] goto :run
goto compileNlink

:clean
@echo off
del *.exe > nul
del gui.obj > nul
del gui.map > nul
del linklog.txt > nul
del complog.txt > nul
if [%2]==[txt] del *.txt > nul
goto :EOF

:run
del *.exe > nul
del gui.obj > nul
del gui.map > nul
del linklog.txt > nul
del complog.txt > nul
ml /c /Cp gui.asm > complog.txt
cls
echo ASSEMBLY DONE
link gui.obj,,,,, > linklog.txt
echo LINKING DONE
gui.exe
goto :EOF

:compileNlink
@echo off
del *.exe > nul
del gui.obj > nul
del gui.map > nul
del linklog.txt > nul
del complog.txt > nul
ml /c /Cp gui.asm > complog.txt
cls
echo ASSEMBLY DONE
link gui.obj,,,,, > linklog.txt
echo LINKING DONE
goto :EOF

:EOF
