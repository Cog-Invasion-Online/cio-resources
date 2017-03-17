@echo off
echo Compiling winter.mf...
cd winter
multify -c -f ..\winter.mf winter phase_3.5 phase_4 phase_6
echo Done!
PAUSE