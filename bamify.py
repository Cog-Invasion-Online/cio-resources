from panda3d.core import *
from panda3d.bsp import *

import os

def lbr():
    print("\n====================================================\n")

inp_file = raw_input("Input file: ")
out_file = raw_input("Output file: ")

lbr()

normalsStr = ""
normals = True
while (normalsStr not in ["y", "n"]):
    normalsStr = raw_input("Calculate vertex normals? [Y/N]: ").lower()
    if normalsStr == "y":
        normals = True
    elif normalsStr == "n":
        normals = False

print("Running egg-trans...")
cmd  = "..\\..\\cio-panda3d\\built_x64\\bin\\egg-trans -o {0} ".format(inp_file)
if normals:
    print("Also calculating vertex normals")
    cmd += "-nv 90 "
cmd += "-tbnall "
cmd += inp_file
os.system(cmd)
        
lbr()

loader = Loader.getGlobalPtr()
node = loader.loadSync(inp_file)
np = NodePath(node)

meshes = np.findAllMatches("**/+GeomNode")
for meshNp in meshes:
    mat_file = raw_input("Material file for mesh `{0}`: ".format(meshNp.getName()))
    mat = BSPMaterial.getFromFile(mat_file)
    meshNp.setAttrib(BSPMaterialAttrib.make(mat))
    if mat.hasTransparency():
        print meshNp.getName(), "has $translucent or $alpha"
        meshNp.setTransparency(TransparencyAttrib.MDual, 1)
    
lbr()
    
optimizeStr = ""
optimize = False
while (optimizeStr not in ["y", "n"]):
    optimizeStr = raw_input("Optimize model? (highly recommended) [Y/N]: ").lower()
    if optimizeStr == "y":
        optimize = True
    elif optimizeStr == "n":
        optimize = False
        
lbr()

if optimize:
    print("\nModel before optimization:")
    np.ls()
    
    np.flattenStrong()
    
    print("\nModel after optimization:")
    np.ls()
    print
    
lbr()

print("Writing {0}...".format(out_file))
np.writeBamFile(out_file)
