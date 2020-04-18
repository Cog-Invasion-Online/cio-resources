from direct.interval.IntervalGlobal import Sequence, Wait, Func, LerpQuatInterval
from src.coginvasion.attack.Attacks import ATTACK_GAG_WHOLECREAMPIE, ATTACK_SLAP

flashEnt = self.script.bspLoader.getPyEntityByTargetName("elevator_alarm_flash")
alarmEnt = self.script.bspLoader.getPyEntityByTargetName("elevator_alarm")
musicEnt = self.script.bspLoader.getPyEntityByTargetName("elevator_alarm_music")
elevSound = self.script.bspLoader.getPyEntityByTargetName("elevator_ambience")
arriveSound = self.script.bspLoader.getPyEntityByTargetName("elevator_arrive_sound")
camEffect = self.script.bspLoader.getPyEntityByTargetName("elevator_camera_effect")

def doAlarmAndFlash(flash, alarm):
    flash.Enable()
    alarm.Play()
    
def __flippyWatchPlayer(self, task):
    from src.mod import ModGlobals
    self.target.headsUp(base.air.doId2do.get(ModGlobals.LocalAvatarID))
    return task.cont
    
def __flippyGivePie(self, seq2, task):
    from src.mod import ModGlobals
    player = base.air.doId2do.get(ModGlobals.LocalAvatarID)
    if self.target.getDistance(player) <= 2.5:
        seq2.start()
        return task.done
    return task.cont
    
from src.mod.WaitForPlayerInterval import WaitForPlayerInterval
        
from src.mod import ModGlobals
player = base.air.doId2do.get(ModGlobals.LocalAvatarID)

seq2 = Sequence()
seq2.append(Func(player.b_setAttackIds, [ATTACK_GAG_WHOLECREAMPIE, ATTACK_SLAP]))
seq2.append(Func(player.b_setEquippedAttack, ATTACK_GAG_WHOLECREAMPIE))
seq2.append(Func(self.target.b_setEquippedAttack, -1))
seq2.append(Wait(1.0))
seq2.append(Func(self.target.d_setChat, "Here goes nothing!"))
seq2.append(Func(self.removeScriptTask, __flippyWatchPlayer))
seq2.append(LerpQuatInterval(self.target, 0.5, (0, 0, 0)))
seq2.append(Wait(1.0))
seq2.append(Func(self.script.dispatch.transitionToMap, "facility_battle_v2", "battle_transition"))

seq = Sequence()
seq.append(Func(self.addScriptTask, __flippyWatchPlayer))
seq.append(Wait(13.5))
seq.append(Func(doAlarmAndFlash, flashEnt, alarmEnt))
seq.append(Wait(0.5))
seq.append(Func(self.target.d_setChat, "Drat! That can't be good..."))
seq.append(Func(self.removeScriptTask, __flippyWatchPlayer))
seq.append(LerpQuatInterval(self.target, 0.5, (0, 0, 0)))
seq.append(Func(musicEnt.PlayMusic))
seq.append(Wait(1.0))
seq.append(Func(arriveSound.Play))
seq.append(Func(elevSound.Stop))
seq.append(Func(camEffect.Disable))
seq.append(Wait(1.5))
seq.append(Func(self.addScriptTask, __flippyWatchPlayer))
seq.append(Func(self.target.d_setChat, "Here, grab a pie. You're gonna need it..."))
seq.append(Func(self.target.b_setEquippedAttack, ATTACK_GAG_WHOLECREAMPIE))
seq.append(Func(self.addScriptTask, __flippyGivePie, [seq2]))
seq.start()
