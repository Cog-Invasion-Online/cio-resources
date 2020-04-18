from direct.interval.IntervalGlobal import Sequence, Func, Wait
    
flippy = self.script.bspLoader.getPyEntityByTargetName("flippy")

if not flippy:
    self.finishScript()
else:
    seq = Sequence()
    seq.append(Func(flippy.setBlockAIChat, True))
    seq.append(Func(flippy.d_setChat, "Great! One generator to go."))
    seq.append(Wait(3))
    seq.append(Func(flippy.d_setChat, "Keep up the fight! We're almost there."))
    seq.append(Func(flippy.setBlockAIChat, False))
    seq.append(Func(self.finishScript))
    seq.start()
