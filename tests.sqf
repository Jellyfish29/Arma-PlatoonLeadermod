addMissionEventHandler ["EntityKilled",{
    params ["_killed", "_killer", "_instigator", "_useEffects"];
    if (_killed isKindOf "Man" or _killed isKindOf "Air") exitWith {};

    // if ((side (group (driver _killed))) isEqualTo playerSide or _killed in _abandonedVics) then {

    if (_killed getVariable ["pl_has_cmd_fsm", false]) then {
        [_killed] spawn {
            (_this#0) setVariable ["pl_just_destroyed", true];
            sleep 10;
            (_this#0) setVariable ["pl_just_destroyed", nil];
        };
    };

}];


pl_debug = true;
pl_active_opfor_vic_grps = [];
{
    (group (driver _x)) execFSM "pl_opfor_cmd_vic_2.fsm";
    pl_active_opfor_vic_grps pushback (group (driver _x));
} forEach (vehicles select {side _x == east});

{
    if !(_x in pl_active_opfor_vic_grps) then {
        _x execFSM "pl_opfor_cmd_inf_2.fsm";
    };
} forEach (allGroups select {side _x == east});