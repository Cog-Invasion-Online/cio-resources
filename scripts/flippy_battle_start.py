from direct.interval.IntervalGlobal import Sequence, Func
from src.coginvasion.cog.ai.AIGlobal import STATE_IDLE
from src.mod import ModGlobals
    
flippy = self.script.bspLoader.getPyEntityByTargetName("flippy")

if not flippy:
    self.finishScript()
else:
    seq = Sequence()
    seq.append(Func(flippy.setNPCState, STATE_IDLE))
    seq.append(Func(flippy.setFollowTarget, flippy.air.doId2do.get(ModGlobals.LocalAvatarID)))
    seq.append(Func(self.finishScript))
    seq.start()
