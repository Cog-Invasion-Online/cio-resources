@echo off
title Cog Invasion Phase File Compressor/Decompressor

set /p file=What phase file do you want compressed or decompressed?
set /p mode=Do you want to compress or decompress?
..\..\cio-panda3d\built_x64\python\ppython.exe -B tool_compression.py --mode %mode% --filename %file%

echo Done!
pause >nul
exit
