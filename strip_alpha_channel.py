from panda3d.core import Filename, PNMImage

inpFile = raw_input("Input file: ")
outFile = raw_input("Output file: ")

fn = Filename.fromOsSpecific(inpFile)
fnout = Filename.fromOsSpecific(outFile)

image = PNMImage(fn)
image.removeAlpha()
image.write(fnout)
