from direct.interval.IntervalGlobal import Sequence, Func, Wait
    
flippy = self.script.bspLoader.getPyEntityByTargetName("flippy")

if not flippy:
    self.finishScript()
else:
    seq = Sequence()
    seq.append(Func(flippy.setBlockAIChat, True))
    seq.append(Func(flippy.d_setChat, "We did it! There he goes!"))
    seq.append(Wait(3.5))
    seq.append(Func(flippy.d_setChat, "Sayonara!"))
    seq.append(Func(flippy.setBlockAIChat, False))
    seq.append(Func(self.finishScript))
    seq.start()
