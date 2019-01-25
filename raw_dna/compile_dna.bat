@echo off

IF NOT EXIST "..\..\..\libpandadna" (goto missinglpd) ELSE (goto compile)

:missinglpd
echo You need to clone libpandadna into the main repository directory first (the folder that has 'game' and 'cio-panda3d' in it).
pause
exit

:compile
..\..\..\cio-panda3d\built_x64\python\ppython -B ../../../libpandadna/compiler/compile.py phase_3.5/dna/*.dna phase_4/dna/*.dna phase_5/dna/*dna phase_5.5/dna/*.dna phase_6/dna/*.dna phase_8/dna/*.dna phase_9/dna/*.dna phase_10/dna/*.dna phase_11/dna/*.dna phase_12/dna/*.dna phase_13/dna/*.dna
pause
