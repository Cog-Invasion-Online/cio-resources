"""
COG INVASION ONLINE
Copyright (c) CIO Team. All rights reserved.

@file revamp_models.py
@author Brian Lach
@date September 13, 2017

@desc This script goes through every Toontown model in the phase files and recomputes vertex normals + other
      data that will make the models suitable for applying lights and shaders to them.

"""

from panda3d.core import *

print "Revamping models, this might take several minutes..."

from direct.showbase.Loader import Loader

loader = Loader(None)
id_alloc = UniqueIdAllocator(0, 9999999)
cbm = CullBinManager.getGlobalPtr()
cbm.addBin('ground', CullBinManager.BTUnsorted, 18)
cbm.addBin('shadow', CullBinManager.BTBackToFront, 19)

egg_trans = "..\\..\\Panda3D-CI\\bin\\egg-trans.exe "
bam2egg = "..\\..\\Panda3D-CI\\bin\\bam2egg.exe "
egg2bam = "..\\..\Panda3D-CI\\bin\\egg2bam.exe "
eggopt = "..\\..\Panda3D-CI\\bin\\egg-optchar.exe "

do_bam2egg = True
do_egg2bam = True
do_trans = True
do_optchar = True
fix_eggfile = True
fix_textures = True
fix_revampbam = True

import os
import glob2
import random

def get_random_name():
    return "unknown{0}".format(id_alloc.allocate())

def get_new_name(name):
    return "{0}{1}".format(name, id_alloc.allocate())

def get_revamp_egg(path):
    path = "revamp\\egg\\" + path
    path = path.replace(".bam", ".egg")
    path = path.replace("non_revamp\\", "")
    #print path
    return path

def get_revamp_bam(path):
    path = "revamp\\bam\\" + path
    path = path.replace("non_revamp\\", "")
    #print path
    return path

def is_character(node):
    return node.find("**/+Character").isEmpty() == False

def is_animation(node):
    return node.find("**/+AnimBundleNode").isEmpty() == False

def get_character(node):
    return node.find("**/+Character")

phases = [3, 3.5, 4, 5, 5.5, 6, 7, 8, 9, 10, 11, 12, 13]
#phases = [3.5]

######################################################################################
# Revamp textures:

if (fix_textures):
    print "Fixing grayscale textures..."

    orig_textures = []

    for phase in phases:
        orig_textures += glob2.glob("phase_{0}/maps/**/*.jpg".format(phase))
        orig_textures += glob2.glob("phase_{0}/maps/**/*.png".format(phase))

    for tex in orig_textures:
        tex = tex.replace("\\", "/")
        fn = Filename(tex)
        fnout = Filename("revamp/rgb/" + tex)
        image = PNMImage(fn)
        if (image.getColorType() == PNMImageHeader.CT_grayscale):
            print "Processing " + tex + "..."
            # Toontown has textures in a one-component grayscale format.
            # This doesn't seem to work well in Panda's shader generator.
            # Convert to rgb format.
            image.makeRgb()
            if (not os.path.exists(fnout.getDirname())):
                os.makedirs(fnout.getDirname())
            image.write(fnout)

######################################################################################
# Revamp models:

flr_bitmask = BitMask32(2)
wall_bitmask = BitMask32(1)

orig_models = []

for phase in phases:
    orig_models += glob2.glob("non_revamp\\phase_{0}\\models\\**\\*.bam".format(phase))

for mdl in orig_models:
    
    orig_mdl_filename = Filename(mdl.replace("\\", "/"))
    node = loader.loadModel(orig_mdl_filename)
    if (is_animation(node)):
        node.removeNode()
        continue

    print "Processing " + mdl + "..."

    out_filename = Filename(get_revamp_bam(mdl).replace("\\", "/"))
    if (not os.path.exists(out_filename.getDirname())):
        os.makedirs(out_filename.getDirname())

    os.system("copy {0} {1}".format(mdl, get_revamp_bam(mdl)))

    joint2geometry = {}
    #wall_colls = []
    #flr_colls = []
    #floor_bins = []
    #shadow_bins = []
    
    #decal_shadow_bins = []
    #decal_floor_bins = []

    #is_changed = False
    #for np in node.findAllMatches("**"):
    #    if (len(np.getName()) == 0 or np.getName().isspace()):
    #        np.setName(get_random_name())
    #        print "Found node with no name, giving it {0}".format(np.getName())
    #        is_changed = True

    #if (is_changed):
    #    node.writeBamFile(get_revamp_bam(mdl))

    if (is_character(node)):
        char = get_character(node)

        is_changed = False

        for child in char.getChildren():
            if (char.node().findJoint(child.getName())):
                # This is an exposed joint. Any nodes underneath this joint must be flagged for a reparent.
                joint2geometry[child.getName()] = []
                for joint_child in child.getChildren():
                    if (len(joint_child.getName()) == 0):
                        joint_child.setName(get_random_name())
                    elif (joint_child.getName() == char.getName()):
                        print "Node underneath character has identical name: " + joint_child.getName()
                        joint_child.setName(joint_child.getName() + "_geom")
                    print "child of {0}: {1}".format(child.getName(), joint_child.getName())
                    joint2geometry[child.getName()].append(joint_child.getName())
                    is_changed = True
            #elif (child.node().getType() == CollisionNode.getClassType()):
            #    if (child.node().getCollideMask() == flr_bitmask):
            #        flr_colls.append(child.getName())
            #        print "Found a floor collision:", child.getName()
            #    elif (child.node().getCollideMask() == wall_bitmask):
            #        wall_colls.append(child.getName())
            #        print "Found a wall collision:", child.getName()
        
        # Avoid unnecessarily writing to disk if we haven't made any changes.
        # Optimization to speed up the process.
        if (is_changed):
            node.writeBamFile(get_revamp_bam(mdl))
            
    #else:
    #    
    #    for child in node.findAllMatches("**/+GeomNode"):
    #        if (child.node().getNumGeoms() == 0):
    #            continue
    #        gs = child.node().getGeomState(0)
    #        if (gs.hasAttrib(CullBinAttrib.getClassType())):
    #            cba = gs.getAttrib(CullBinAttrib.getClassType())
    #            if (child.hasEffect(DecalEffect.getClassType())):
    #                parent = child.getParent()
    #                if (cba.getBinName() == 'ground'):
    #                    print "Found decal floor bin"
    #                    print "Parent:", parent.getName()
    #                    decal_floor_bins.append(parent.getName())
    #                elif (cba.getBinName() == 'shadow'):
    #                    print "Found decal shadow bin"
    #                    print "Parent:", parent.getName()
    #                    decal_shadow_bins.append(parent.getName())
    #            else:
    #                if (cba.getBinName() == 'ground'):
    #                    print "Found regular floor bin"
    #                    print "Node:", child.getName()
    #                    floor_bins.append(child.getName())
    #                elif (cba.getBinName() == 'shadow'):
    #                    print "Found regular shadow bin"
    #                    print "Node:", child.getName()
    #                    shadow_bins.append(child.getName())

    if (do_bam2egg):
        os.system("{0} -o {1} {2}".format(bam2egg, get_revamp_egg(mdl), get_revamp_bam(mdl)))
        
    if (do_trans and not is_character(node)):
        os.system("{0} -o {1} -nv 180 -tbnall -tbnauto {2}".format(egg_trans, get_revamp_egg(mdl), get_revamp_egg(mdl)))

    if (do_optchar and is_character(node)):

        expose_list = []
        flag_list = []
        char = get_character(node)
        for child in char.findAllMatches("**"):
            # Any node underneath the character in the bam file needs to be exposed in the egg file.
            name = child.getName()
            if len(name) == 0:
                continue
            if char.node().findJoint(name):
                # This exposed node is actually a joint.
                expose_list.append(name)
            else:
                # It's regular old geometry
                flag_list.append(name)
            
        cmd = eggopt
        cmd += "-o {0} ".format(get_revamp_egg(mdl))
        cmd += "-nv 180 -tbnall -tbnauto -keepall -dart default "
        for exp in expose_list:
            cmd += "-expose " + exp + " "
        for flg in flag_list:
            cmd += "-flag " + flg + " "
        
        cmd += get_revamp_egg(mdl)
        os.system(cmd)

    if (fix_eggfile):
        revampfile = open(get_revamp_egg(mdl), 'r+')
        newfile = ""

        is_changed = False

        for line in revampfile.readlines():
            # There are certain occurances in the generated egg files that need to be changed.
            newline = line.replace("../", "")
            newline = newline.replace("luminance", "rgb")
            newline = newline.replace(" linear ", " linear_mipmap_linear ")
            newline = newline.replace("rgb_alpha", "rgba")
            # Irritating thing that bam2egg does.
            newline = newline.replace(".egg", "")
            if (newline != line):
                is_changed = True
            newfile += newline

        if (is_changed):
            revampfile.seek(0)
            revampfile.truncate()
            revampfile.write(newfile)
            revampfile.flush()

        revampfile.close()

    if (do_egg2bam):
        os.system("{0} -o {1} -ps keep {2}".format(egg2bam, get_revamp_bam(mdl), get_revamp_egg(mdl)))

    if (fix_revampbam and is_character(node)):
        revamp = loader.loadModel(get_revamp_bam(mdl))
        is_changed = False

        for tex in revamp.findAllTextures():
            if (tex.getFormat() == Texture.F_luminance):
                tex.setFormat(Texture.F_rgb)
                is_changed = True

        char = get_character(revamp)

        for child in char.getChildren():
            if (joint2geometry.has_key(child.getName())):
                for geom in joint2geometry[child.getName()]:
                    print "{0}: wrtReparentTo : {1}".format(geom, child.getName())
                    geomnp = revamp.find("**/" + geom)
                    if (not geomnp.isEmpty()):
                        geomnp.wrtReparentTo(child)
                        is_changed = True
        
        
        #for flr_coll in flr_colls:
        #    cnp = revamp.find("**/" + flr_coll)
        #    if (not cnp.isEmpty()):
        #        cnp.node().setCollideMask(flr_bitmask)
        #        cnp.hide()
        #        print "Applied floor bitmask to:", flr_coll
        #        is_changed = True
            
        #for wall_coll in wall_colls:
        #    cnp = revamp.find("**/" + wall_coll)
        #    if (not cnp.isEmpty()):
        #        cnp.node().setCollideMask(wall_bitmask)
        #        cnp.hide()
        #        print "Applied wall bitmask to:", wall_coll
        #        is_changed = True
            
        
        #for flr in floor_bins:
        #    np = revamp.find("**/" + flr)
        #    if (not np.isEmpty() and np.node().getType() == GeomNode.getClassType()):
        #        print "Applying ground bin to non-decal node"
        #        for i in xrange(np.node().getNumGeoms()):
        #            gs = np.node().getGeomState(i)
        #            gs.setAttrib(CullBinAttrib.make('ground', 18))
                    
        #for decal_flr in decal_floor_bins:
        #    parent = revamp.find("**/" + decal_flr)
        #    child = parent.find("+GeomNode")
        #    if (not child.isEmpty() and child.hasEffect(DecalEffect.getClassType())):
        #        print "Applying ground bin to decal node"
        #        for i in xrange(child.node().getNumGeoms()):
        #            gs = child.node().getGeomState(i)
        #            gs.setAttrib(CullBinAttrib.make('ground', 18))
                    
        #for sh in shadow_bins:
        #    np = revamp.find("**/" + sh)
        #    if (not np.isEmpty() and np.node().getType() == GeomNode.getClassType()):
        #        print "Applying shadow bin to non-decal node"
        #        for i in xrange(np.node().getNumGeoms()):
        #            gs = np.node().getGeomState(i)
        #            gs.setAttrib(CullBinAttrib.make('shadow', 19))
                    
        #for decal_sh in decal_shadow_bins:
        #    parent = revamp.find("**/" + decal_sh)
        #    child = parent.find("+GeomNode")
        #    if (not child.isEmpty() and child.hasEffect(DecalEffect.getClassType())):
        #        print "Applying shadow bin to decal node"
        #        for i in xrange(child.node().getNumGeoms()):
        #            gs = child.node().getGeomState(i)
        #            gs.setAttrib(CullBinAttrib.make('shadow', 19))
                        
        
        if (is_changed):
            #revamp.ls()
            revamp.writeBamFile(get_revamp_bam(mdl))

        revamp.removeNode()

    node.removeNode()

print "Done!"