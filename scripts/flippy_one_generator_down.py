from direct.interval.IntervalGlobal import Sequence, Func, Wait
    
flippy = self.script.bspLoader.getPyEntityByTargetName("flippy")

if not flippy:
    self.finishScript()
else:
    seq = Sequence()
    seq.append(Func(flippy.setBlockAIChat, True))
    seq.append(Func(flippy.d_setChat, "Toontastic! That's one generator down, two to go!"))
    seq.append(Wait(3))
    seq.append(Func(flippy.d_setChat, "I see you found a new Gag too. That'll come in handy!"))
    seq.append(Func(flippy.setBlockAIChat, False))
    seq.append(Func(self.finishScript))
    seq.start()
