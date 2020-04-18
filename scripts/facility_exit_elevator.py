from src.coginvasion.cog.ai.AIGlobal import STATE_SCRIPT
from panda3d.core import Point3

def __awaitMovement(self, task):
    from src.coginvasion.cog.ai.AIGlobal import STATE_IDLE
    
    if self.target.isDead():
        return task.done

    if len(self.target.getMotor().getWaypoints()) == 0:
        self.target.setNPCState(STATE_IDLE)
        return task.done

    return task.cont

self.target.setNPCState(STATE_SCRIPT)

pos = Point3(192, 1024, 0)
pos /= 16.0

self.target.headsUp(pos)
self.target.makeIdealYaw(pos)

self.target.planPath(pos)
self.target.getMotor().startMotor()

self.addScriptTask(__awaitMovement)
