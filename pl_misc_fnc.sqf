#include "\a3\editor_f\Data\Scripts\dikCodes.h"


pl_reset = {
    params ["_group"];

    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };

    _leader = leader _group;
    (units _group) joinSilent _group;
    _group selectLeader _leader;

    if (_group isEqualTo (group player)) then {
        _group selectLeader player;
    };
    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _vic setVariable ["pl_on_transport", nil];
    };
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    _group setVariable ["pl_show_info", true];
    _group addWaypoint [getPos (leader _group), 0];
    _group setVariable ["pl_draw_convoy", false];
    sleep 0.1;
    {
        _x enableAI "AUTOCOMBAT";
        _x enableAI "AUTOTARGET";
        _x enableAI "TARGET";
        _x enableAI "PATH";
        _x setUnitPos "AUTO";
        _x doMove (getPos _x);
        _x doFollow (leader _group);
        _x limitSpeed 5000;
    } forEach (units _group);

    _group setSpeedMode "NORMAL";
    _group setCombatMode "YELLOW";
    _group setBehaviour "AWARE";

    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };
};

pl_execute = {
    params ["_group"];

    {
        _x enableAI "PATH";
        _x doFollow (leader _group);
    } forEach (units _group);

    (units _group) joinSilent _group;
};

pl_spawn_reset = {
    {
        [_x] spawn pl_reset;
    } forEach hcSelected player;
};

pl_hold = {
    params ["_group"];
    {
        doStop _x;
        _x disableAI "PATH";   
    } forEach (units _group);  
};

pl_spawn_hold = {
    {
        [_x] spawn pl_hold;
    } forEach hcSelected player;
};


pl_spawn_execute = {
    {
        [_x] spawn pl_execute;
    } forEach hcSelected player;
};

pl_select_group = {
    _target = cursorTarget;
    _group = group _target;
    player hcSelectGroup [_group];
    sleep 2;
};


pl_remote_camera_in = {
    params ["_leader"];

    _leader switchCamera "GROUP";  
};

pl_spawn_cam = {
    [leader (hcSelected player select 0)] call pl_remote_camera_in;
};


pl_remote_camera_out = {

    player switchCamera "EXTERNAL";  
};

pl_angle_switcher = {
    params ["_a"];
    if (_a > 360) then {
        _a = _a - 360;
    }
    else
    {
        _a = _a + 360;
    };
    _a
};

pl_watch_dir = {
    params ["_group"];
    private ["_watchPos"];

    _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    _groupPos = getPos (leader _group);
    _watchDir = [_cords, _groupPos] call BIS_fnc_dirTo;
    _group setFormDir _watchDir;
    _watchDir = [(_watchDir - 180)] call pl_angle_switcher;
    _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _groupPos;
    {
        _x doWatch _watchPos;
    } forEach (units _group);

    playSound "beep";
    leader _group sideChat "Roger Watching Direction, Over";
};

pl_spawn_watch_dir = {
    {
        [_x] spawn pl_watch_dir;
    } forEach hcSelected player;  
};

pl_set_unit_pos = {
    params ["_group", "_stance"];

    {
        _x setUnitPos _stance;
    } forEach (units _group);
};

pl_spawn_set_unit_pos = {
    params ["_stance"];

    {
        [_x, _stance] spawn pl_spawn_set_unit_pos;
    } forEach hcSelected player;  
};





["Platoon Leader","select_key", "Select HC Group", {_this spawn pl_select_group}, "", [DIK_T, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","hcSquadIn_key", "Remote View Leader of HC Group", {_this spawn pl_spawn_cam }, "", [DIK_HOME, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","hcSquadOut_key", "Release Remote View", {_this spawn pl_remote_camera_out}, "", [DIK_END, [false, false, false]]] call CBA_fnc_addKeybind;