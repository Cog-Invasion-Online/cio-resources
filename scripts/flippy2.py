from src.coginvasion.avatar.Activities import ACT_VICTORY_DANCE, ACT_JUMP, ACT_TOON_BOW, ACT_TOON_PRESENT, ACT_NONE, ACT_PRESS_BUTTON
from direct.interval.IntervalGlobal import Sequence, Wait, Func, LerpPosInterval, LerpQuatInterval, Parallel
from src.coginvasion.cog.ai.AIGlobal import STATE_IDLE
from panda3d.core import Point3

leavePos = Point3(87, 1709, 0)
leavePos /= 16.0

buttonPos = Point3(59, 1000, 0)
buttonPos /= 16.0

elevPos = Point3(240, 860, 0)
elevPos /= 16.0

elevMiddle = Point3(192, 992, 0)
elevMiddle /= 16.0

musicEnt = self.script.bspLoader.getPyEntityByTargetName("music_when_find_flippy")
buttonEnt = self.script.bspLoader.getPyEntityByTargetName("button_nigga")
elevSound = self.script.bspLoader.getPyEntityByTargetName("elevator_ambience")
arriveSound = self.script.bspLoader.getPyEntityByTargetName("elevator_arrive_sound")

doors = ["elev_door_inner_left", "elev_door_inner_right", "elev_door_outer_right", "elev_door_outer_left"]

def openDoors(script, doors):
    for doorName in doors:
        door = script.bspLoader.getPyEntityByTargetName(doorName)
        door.Open()
        
def closeDoors(script, doors):
    for doorName in doors:
        door = script.bspLoader.getPyEntityByTargetName(doorName)
        door.Close()

def __flippyWatchPlayer(self, task):
    from src.mod import ModGlobals
    self.target.headsUp(base.air.doId2do.get(ModGlobals.LocalAvatarID))
    return task.cont

seq = Sequence(
    Func(self.target.b_setActivity, ACT_NONE),
    Func(self.target.headsUp, leavePos),
    LerpPosInterval(self.target, 0.75, leavePos),
    Func(self.target.b_setActivity, ACT_VICTORY_DANCE),
    Wait(self.target.getActivityDuration(ACT_VICTORY_DANCE)),
    Func(self.target.b_setActivity, ACT_JUMP),
    Func(self.target.d_setChat, "Hooray! I'm finally free!"),
    Wait(self.target.getActivityDuration(ACT_JUMP)),
    Func(self.target.d_setChat, "I am forever in your debt."),
    Func(self.target.b_setActivity, ACT_TOON_BOW),
    Wait(self.target.getActivityDuration(ACT_TOON_BOW)),
    Func(self.target.b_setActivity, ACT_NONE),
    Func(musicEnt.FadeOut),
    Func(self.target.d_setChat, "Listen, there's no time to waste."),
    Wait(1.0),
    LerpQuatInterval(self.target, 0.5, hpr = (180, 0, 0)),
    Parallel(
        LerpPosInterval(self.target, 4.5, buttonPos),
        Sequence(Wait(1.5), Func(self.target.d_setChat, "We have to get out of here before the Cogs find us. Follow me."))
    ),
    Func(self.addScriptTask, __flippyWatchPlayer),
    Func(self.target.b_setActivity, ACT_TOON_PRESENT),
    Wait(0.5),
    Func(self.target.d_setChat, "This elevator leads to the exit."),
    Wait(2.5),
    Func(self.target.d_setChat, "I know a secret way out."),
    Wait(3.0),
    Func(self.removeScriptTask, __flippyWatchPlayer),
    Func(self.target.b_setActivity, ACT_NONE),
    LerpQuatInterval(self.target, duration = 0.5, hpr = (180, 0, 0)),
    Func(self.target.b_setActivity, ACT_PRESS_BUTTON),
    Wait((62 - 38) / 24.0), # Button press animation frame time
    Func(buttonEnt.Press),
    Wait(1.0),
    Func(elevSound.FadeIn, 2.0),
    Wait(1.0),
    Func(self.target.b_setActivity, ACT_NONE),
    Func(self.addScriptTask, __flippyWatchPlayer),
    Wait(1.25),
    Func(elevSound.Stop),
    Func(arriveSound.Play),
    Wait(0.75),
    Func(openDoors, self.script, doors),
    Wait(0.5),
    LerpQuatInterval(self.target, 0.5, hpr = (225, 0, 0)),
    Wait(0.2),
    Func(self.target.d_setChat, "Come on!"),
    Wait(2.0),
    Func(self.removeScriptTask, __flippyWatchPlayer),
    Func(self.target.headsUp, elevMiddle),
    LerpPosInterval(self.target, 0.9, elevMiddle),
    Func(self.target.headsUp, elevPos),
    LerpPosInterval(self.target, 0.9, elevPos),
    LerpQuatInterval(self.target, 0.5, (0, 0, 0)),
    Func(self.finishScript)
)
seq.start()
