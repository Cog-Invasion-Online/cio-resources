def __runOut(self):
    
    def __awaitMovement(self, task):
        from src.coginvasion.cog.ai.AIGlobal import STATE_IDLE
        
        if self.target.isDead():
            return task.done

        if len(self.target.getMotor().getWaypoints()) == 0:
            self.target.setNPCState(STATE_IDLE)
            return task.done

        return task.cont
    
    from panda3d.core import Vec3

    moveLocal = Vec3(0, 168 / 16.0, 0)

    move = self.target.getQuat().xform(moveLocal)
    pos = self.target.getPos() + move

    self.target.headsUp(pos)
    self.target.makeIdealYaw(pos)

    self.target.planPath(pos)
    self.target.getMotor().startMotor()

    self.addScriptTask(__awaitMovement)
    
from src.coginvasion.cog.ai.AIGlobal import STATE_SCRIPT
    
self.target.setNPCState(STATE_SCRIPT)

from direct.interval.IntervalGlobal import Sequence, Wait, Func
seq = Sequence()
seq.append(Wait(1.0))
seq.append(Func(__runOut, self))
seq.start()
