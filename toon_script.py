from panda3d.core import *
loadPrcFileData('', 'load-display pandagl')

from direct.showbase.ShowBase import ShowBase
from direct.directnotify.DirectNotifyGlobal import directNotify
from direct.actor.Actor import Actor

class ToonBase(ShowBase):
    notify = directNotify.newCategory("ToonBase")
    
    def __init__(self):
        ShowBase.__init__(self)
        
        self.toons = []
        types = [("boy", "dgl"), ("boy", "dgm"), ("boy", "dgs"), ("girl", "dgl"), ("girl", "dgm"), ("girl", "dgs")]
        
        x = 0
        for data in types:
            toon = self.makeToon(*data)
            toon.setX(x)
            self.toons.append(toon)
            x += 5
        
    def makeToon(self, gender, torso):
        if gender == "boy":
            torso += "_shorts"
        elif gender == "girl":
            torso += "_skirt"
            
        toon = Actor(None, None, None, flattenable=0, setFinal=1)
        
        # head mdl + anim
        toon.loadModel('phase_3/models/char/tt_a_chr_dgm_skirt_head_1000.bam', 'head')
        toon.loadAnims({"neutral": "phase_3/models/char/tt_a_chr_dgm_skirt_head_neutral.bam"}, 'head')
        # torso mdl + anim
        toon.loadModel('phase_3/models/char/tt_a_chr_' + torso + '_torso_1000.bam', 'torso')
        toon.loadAnims({'neutral': 'phase_3/models/char/tt_a_chr_' + torso + '_torso_neutral.bam'}, 'torso')
        # legs mdl + anim
        toon.loadModel('phase_3/models/char/tt_a_chr_dgm_shorts_legs_1000.bam', 'legs')
        toon.loadAnims({'neutral': 'phase_3/models/char/tt_a_chr_dgm_shorts_legs_neutral.bam'}, 'legs')
        
        # attach parts
        toon.attach('head', 'torso', 'def_head')
        toon.attach('torso', 'legs', 'joint_hips')
        
        color = (0.347656, 0.820312, 0.953125, 1.0)
        toon.find('**/arms').setColor(color)
        toon.find('**/legs').setColor(color)
        toon.find('**/feet').setColor(color)
        toon.find('**/neck').setColor(color)
        toon.find('**/head').setColor(color)
        toon.find('**/head-front').setColor(color)
        toon.find('**/hands').setColor((1, 1, 1, 1))
        toon.find('**/shoes').removeNode()
        toon.find('**/boots_long').removeNode()
        toon.find('**/boots_short').removeNode()
        
        shirt = loader.loadTexture('phase_4/maps/4thJulyShirt2.jpg')
        sleeve = loader.loadTexture('phase_4/maps/4thJulySleeve2.jpg')
        if gender == "boy":
            bottom = loader.loadTexture('phase_4/maps/4thJulyShorts1.jpg')
        elif gender == "girl":
            bottom = loader.loadTexture('phase_4/maps/4thJulySkirt1.jpg')
            
        toon.find('**/torso-top').setTexture(shirt, 1)
        toon.find('**/sleeves').setTexture(sleeve, 1)
        toon.find('**/torso-bot').setTexture(bottom, 1)
        
        glasses = loader.loadModel('phase_4/models/accessories/tt_m_chr_avt_acc_msk_dorkGlasses.bam')
        glassesNode = toon.getPart('head').attachNewNode('glassesNode')
        glasses.reparentTo(glassesNode)
        glasses.setScale(0.27, 0.2, 0.35)
        glasses.setH(180)
        glasses.setZ(0.27)
        glasses.setY(0.2)
        
        shadow = loader.loadModel('phase_3/models/props/drop_shadow.bam')
        shadow.reparentTo(toon.find('**/joint_shadow'))
        shadow.setScale(0.4)
        shadow.flattenMedium()
        shadow.setBillboardAxis(4)
        shadow.setColor(0, 0, 0, 0.5, 1)
        
        toon.reparentTo(render)
        toon.loop('neutral')
        
        return toon
        
        
base = ToonBase()
base.run()
