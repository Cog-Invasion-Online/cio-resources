"""

  Filename: tool_compression.py
  Created by: Maverick Liberty (March 28, 2019)

"""

import tarfile
import glob
import argparse
import sys

phases = ['winter.mf']

for multifile in glob.glob("phase_*"):
    if multifile[-1:].isdigit():
        phases.append(multifile + ".mf")

def compress(filename):
    tf = tarfile.open(nameWithTarSuffix(filename), mode="w:gz")
    tf.add(filename)
    tf.close()
    print "Compressed {0}!".format(filename)

def decompress(filename):
    """ This is expecting a phase filename with the .mf extension """
    tf = tarfile.open(nameWithTarSuffix(filename), mode="r")
    tf.extract(filename)
    print "Decompressed {0}!".format(filename)

def nameWithTarSuffix(filename):
    return filename[:-3] + ".tar.gz"

def possiblyCorrectName(filename):
    if not ".mf" in filename:
        if ".tar.gz" in filename:
            filename = filename[:-7]
        filename = filename + ".mf"
    return filename

parser = argparse.ArgumentParser(description = "Work with tar.gz files")
parser.add_argument("--filename", default = "phase_3.mf", help = "The file to be operated on.")
parser.add_argument("--mode", default = "compress", help = "Compress or decompress")
args = parser.parse_args()

filename = args.filename.lower()
mode = args.mode.lower()

if not (filename == "all" or filename == "*"):
    filename = possiblyCorrectName(filename)
    
    if not filename in phases:
        print "{0} is not a valid phase file!".format(filename)
        sys.exit()
    else:
        phases = [filename]

for phase in phases:
    if mode == "compress":
        compress(phase)
    else:
        decompress(phase)
