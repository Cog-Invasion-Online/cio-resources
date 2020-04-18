from direct.interval.IntervalGlobal import Sequence, Wait, Func
boss = self.bspLoader.getPyEntityByTargetName("the_boss")
Sequence(Func(boss.d_setChat, "Damn, you've got a hell of a lot of nerve, Toon."), Wait(3.0),
         Func(boss.d_setChat, "I know, I know. You finally found Flippy."), Wait(3.0),
         Func(boss.d_setChat, "But that doesn't mean you're getting out of here with him... or alive"),
         Wait(3.5),
         Func(boss.Activate),
         Func(self.FinishScript)).start()
