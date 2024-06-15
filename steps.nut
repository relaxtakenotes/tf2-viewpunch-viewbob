local FL_FROZEN = 64;
local FL_ATCONTROLS = 128;
local FL_DUCKING = 2;
local FL_ONGROUND = 1;

local MOVETYPE_NOCLIP = 8;
local MOVETYPE_OBSERVER = 10;
local MOVETYPE_LADDER = 9;

function DetectFootstep()
{
    local flags = self.GetFlags();
    local onground = flags & FL_ONGROUND;

    _PreviousOnGround = _OnGround;
    _OnGround = onground;

    if (_OnGround && _OnGround != _PreviousOnGround) {
        self.ViewPunch(QAngle(2, 0, 0));
    }

    if (!_OnGround && _OnGround != _PreviousOnGround) {
        self.ViewPunch(QAngle(-2, 0, 0));
    }

	local step_time = NetProps.GetPropFloat(self, "m_flStepSoundTime");

	if (step_time > 20 || Time() - LastStepTime < 0.1) {
        //printf("%0.2f\n", Time() - LastStepTime);
        return -1;
    }

    local movetype = self.GetMoveType();
    local moving_along = self.GetAbsVelocity().Length2DSqr() > 0.001;
    local speed = self.GetAbsVelocity().Length();

    if (flags & (FL_FROZEN | FL_ATCONTROLS)) {
        //print("frozen or atcontrol\n");
        return -1;
    }

    if (movetype == MOVETYPE_NOCLIP || movetype == MOVETYPE_OBSERVER || movetype == MOVETYPE_LADDER) {
        //print("movetype wrong\n");
        return -1;
    }

    local moving_fast_enough = false;

    if (flags & FL_DUCKING) {
        moving_fast_enough = speed > 60;
    } else {
        moving_fast_enough = speed > 90;
    }

    if (!moving_fast_enough || !(onground && moving_along)) {
        //print("not fast enough or not moving along ground\n");
        return -1;
    }

    StepSide = StepSide * -1;

    local angle = QAngle();

/*

    if ply:KeyDown(IN_FORWARD) then
    	angle = angle + Angle(2, side, side)
    end

    if ply:KeyDown(IN_BACK) then
    	angle = angle + Angle(-2, side, side)
    end

    if ply:KeyDown(IN_MOVELEFT) then
    	angle = angle + Angle(side, side, -2)
    end

    if ply:KeyDown(IN_MOVERIGHT) then
    	angle = angle + Angle(side, side, 2)
    end

*/

    local buttons = NetProps.GetPropInt(self, "m_nButtons");

    if (buttons & Constants.FButtons.IN_FORWARD) {
        angle = angle + QAngle(2, StepSide, StepSide);
    }

    if (buttons & Constants.FButtons.IN_BACK) {
        angle = angle + QAngle(-2, StepSide, StepSide);
    }

    if (buttons & Constants.FButtons.IN_MOVELEFT) {
        angle = angle + QAngle(StepSide, StepSide, -2);
    }

    if (buttons & Constants.FButtons.IN_MOVERIGHT) {
        angle = angle + QAngle(StepSide, StepSide, 2);
    }

    if (buttons & Constants.FButtons.IN_JUMP) {
        angle = angle + QAngle(-3, 0, 0);
    }

    self.ViewPunch(angle * 0.15);

    //printf("%d stepped\n", self.entindex());

    LastStepTime = Time();

    return -1;
}

function InitPlayer(player)
{
    player.ValidateScriptScope();
    player.GetScriptScope()._OnGround <- true;
    player.GetScriptScope()._PreviousOnGround <- true;
    player.GetScriptScope().LastStepTime <- Time();
    player.GetScriptScope().StepSide <- -1;
    player.GetScriptScope().DetectFootstep <- DetectFootstep;
    AddThinkToEnt(player, "DetectFootstep");
}

::MaxPlayers <- MaxClients().tointeger();

for (local p = 1; p <= MaxPlayers ; p++)
{
	local player = PlayerInstanceFromIndex(p);
	if (player == null) continue;

	InitPlayer(player);
}

ClearGameEventCallbacks();

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid);
	if (!player)
		return;

	InitPlayer(player);
}

__CollectGameEventCallbacks(this);