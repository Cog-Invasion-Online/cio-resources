from src.coginvasion.cog.ai.AIGlobal import STATE_SCRIPT
from direct.interval.IntervalGlobal import Sequence, Wait,Func

seq = Sequence(
    Func(self.target.setNPCState, STATE_SCRIPT),
    Func(self.target.d_setChat, "Toontastic! How in the world did you find me?"),
    Wait(3.5),
    Func(self.target.d_setChat, "Let me out of this cage!"),
    Func(self.finishScript)
)
seq.start()
