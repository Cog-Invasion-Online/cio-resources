from direct.interval.IntervalGlobal import Sequence, Func, Wait
    
flippy = self.script.bspLoader.getPyEntityByTargetName("flippy")

if not flippy:
    self.finishScript()
else:
    seq = Sequence()
    seq.append(Func(flippy.setBlockAIChat, True))
    seq.append(Wait(7.5))
    seq.append(Func(flippy.d_setChat, "Looks like the VP is being powered by those generators behind the doors."))
    seq.append(Wait(4))
    seq.append(Func(flippy.d_setChat, "The doors are locked. We need to get the codes to the doors and shut him down!"))
    seq.append(Wait(5))
    seq.append(Func(flippy.d_setChat, "I'll help keep up the fight while you look for the codes."))
    seq.append(Func(flippy.setBlockAIChat, False))
    seq.append(Func(self.finishScript))
    seq.start()
