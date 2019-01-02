from panda3d.core import *
from panda3d.bsp import *

inp_file = raw_input("Input file: ")
out_file = raw_input("Output file: ")
mat_file = raw_input("Material file: ")

loader = Loader.getGlobalPtr()
node = loader.loadSync(inp_file)
np = NodePath(node)
np.setAttrib(BSPMaterialAttrib.make(BSPMaterial.getFromFile(mat_file)))
np.clearModelNodes()
np.flattenStrong()
np.writeBamFile(out_file)
