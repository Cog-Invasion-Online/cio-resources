cd "D:\OTHER\lachb\Documents\cio\game\resources\phase_14\etc\testlongfloor"
"D:\OTHER\lachb\Documents\cio\cio-panda3d\built_x64\bin\p3csg.exe" -threads 8 "D:\OTHER\lachb\Documents\cio\game\resources\phase_14\etc\testlongfloor\testlongfloor.map"
"D:\OTHER\lachb\Documents\cio\cio-panda3d\built_x64\bin\p3bsp.exe" -threads 8 "D:\OTHER\lachb\Documents\cio\game\resources\phase_14\etc\testlongfloor\testlongfloor.map"
"D:\OTHER\lachb\Documents\cio\cio-panda3d\built_x64\bin\p3vis.exe" -full  -threads 8 "D:\OTHER\lachb\Documents\cio\game\resources\phase_14\etc\testlongfloor\testlongfloor.map"
"D:\OTHER\lachb\Documents\cio\cio-panda3d\built_x64\bin\p3rad.exe" -final -extra -mfincludefile "D:\\OTHER\\lachb\\Documents\\cio\\game\\resources\\phase_14\\etc\\rad_mfinclude.txt" -threads 8 "D:\OTHER\lachb\Documents\cio\game\resources\phase_14\etc\testlongfloor\testlongfloor.map"
pause
