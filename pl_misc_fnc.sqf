#include "\a3\editor_f\Data\Scripts\dikCodes.h"
pl_follow_active = false;
pl_follow_array = [];


pl_reset = {
    params ["_group", ["_isNotWp", true]];

    // _group setVariable ['pl_hold_fire', false];
    
    {
        _unit = _x;
        if ((currentCommand _unit) isEqualTo "SUPPORT") then {
            [_unit] spawn pl_hard_reset;
        };
        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "PATH";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "COVER";
        _unit enableAI "ANIM";
        _unit enableAI "FSM";
        _unit setUnitPos "AUTO";
        // sleep 0.5;
        _unit limitSpeed 5000;
        _unit forceSpeed -1;
        _unit doWatch objNull;
        if (vehicle _unit == _unit) then {
            _unit doFollow (leader _group);
        };
    } forEach (units _group);
    
    _leader = leader _group;
    (units _group) joinSilent _group;
    _group selectLeader _leader;
    if (_group isEqualTo (group player)) then {
        _group selectLeader player;
        // {
        //     _x commandFollow player;
        // } forEach (units _group);
    };

    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _vic forceSpeed -1;
        // _vic setVariable ["pl_on_transport", nil];
    };

    if !(!(_isNotWp) and (_group getVariable ["pl_formation_leader", false])) then {
        _group setVariable ["onTask", false];
        if !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa") then {
            _group setVariable ["setSpecial", false];
        };
    };
    _group setVariable ["pl_show_info", true];
    _group setVariable ["pl_draw_convoy", false];
    // _group setCombatMode "YELLOW";

    if (_isNotWp) then {
        _group setSpeedMode "NORMAL";
        _group setBehaviour "AWARE";
        [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
        sleep 0.1;
        deleteWaypoint [_group, (currentWaypoint _group)];
        for "_i" from count waypoints _group - 1 to 0 step -1 do {
            deleteWaypoint [_group, _i];
        };
    };
};

pl_execute = {
    params ["_group"];
    playSound "beep";

    {
        _x enableAI "PATH";
        // _x doFollow (leader _group);
    } forEach (units _group);

    // (units _group) joinSilent _group;
};

pl_spawn_reset = {
    {
        [_x] spawn pl_reset;
    } forEach hcSelected player;
};

pl_hold = {
    params ["_group"];
    playSound "beep";
    {
        // doStop _x;
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
    // leader _group sideChat "Roger Watching Direction, Over";
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

pl_hold_fire = {
    params ["_group"];

    playSound "beep";

    _group setCombatMode "GREEN";
    _group setVariable ["pl_hold_fire", true];
    _group setVariable ["pl_combat_mode", true];
};

pl_open_fire = {
    params ["_group"];

    playSound "beep";

    _group setCombatMode "YELLOW";
    _group setVariable ["pl_hold_fire", false];
    _group setVariable ["pl_combat_mode", false];
};

pl_follow = {
    params ["_arrayId"];
    private ["_formDir", "_posOffset", "_pGroup", "_pSpeed", "_pBehaviour"];
    pl_follow_array append hcSelected player;
    pl_follow_active = true;
    _formDir = getDir player;
    {
        if (_x != (group player)) then {
            [_x] call pl_reset;

            sleep 0.2;

            _x setVariable ["onTask", true];
            _x setVariable ["setSpecial", true];
            _x setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa"];
            playSound "beep";
            // leader _x sideChat format ["%1 is forming up on %2, over",(groupId _x), (groupId (group player))];
            _pos1 = getPos (leader _x);
            _pos2 = getPos player;
            _relPos = [(_pos1 select 0) - (_pos2 select 0), (_pos1 select 1) - (_pos2 select 1)];
            _x setVariable ["pl_rel_pos", _relPos];
            {
                _x disableAI "AUTOCOMBAT";
            } forEach (units _x);
            _x setFormDir _formDir;
        };
    } forEach pl_follow_array;
    _pGroup = (group player);
    _pGroup setVariable ["onTask", true];
    _pGroup setVariable ["setSpecial", true];
    _pGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\whiteboard_ca.paa"];
    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _pGroup);
    pl_follow_array = pl_follow_array - [_pGroup];

    if (pl_follow_active) then {
        while {pl_follow_active} do {
            _pos1 = getPos player;
            sleep 2;
            _pos2 = getPos player;
            _posOffset = [(_pos2 select 0) - (_pos1 select 0), (_pos2 select 1) - (_pos1 select 1)];
            _pBehaviour = behaviour player;
            // _pSpeed = speed player + 1;
            // if (_pSpeed < 12) then {
            //     _pSpeed = 12;
            // };
            {
                _x setBehaviour _pBehaviour;
                if (!(_x getVariable "onTask") or ((count (waypoints _x) > 0))) then {
                    pl_follow_array = pl_follow_array - [_x];
                    _x setVariable ["onTask", false];
                    _x setVariable ["setSpecial", false];
                    {
                        _x enableAI "AUTOCOMBAT";
                    } forEach (units _x);
                }
                else
                {
                    _leader = leader _x;
                    _relPos = _x getVariable "pl_rel_pos";
                    if (vehicle _leader != _leader) then {
                        (vehicle _leader) limitSpeed 18;
                        if ((speed (vehicle _leader)) < 1) then {
                            _newPos = [((getPos _leader) select 0) + ((_posOffset select 0) * 15), ((getPos _leader) select 1) + ((_posOffset select 1) * 15)];
                            driver (vehicle _leader) doMove _newPos;
                        };
                        if ((speed player) < 1) then {
                            _newPos = [((getPos player) select 0) + (_relPos select 0), ((getPos player) select 1) + (_relPos select 1)];
                            driver (vehicle _leader) doMove _newPos;
                        };
                    }
                    else
                    {
                        _newPos = [((getPos player) select 0) + (_relPos select 0), ((getPos player) select 1) + (_relPos select 1)];
                        _leader limitSpeed 15;
                        _leader doMove _newPos;
                        {
                            if (_x != _leader) then {
                                _x doFollow _leader;
                            };
                        } forEach (units _x);
                    };
                };
            } forEach pl_follow_array;
            if ((count pl_follow_array) == 0) exitWith {pl_follow_active = false};
            if !((group player) getVariable "onTask") exitWith {pl_follow_active = false};
        };
        {
            _x setVariable ["onTask", false];
            _x setVariable ["setSpecial", false];
            {
                _x enableAI "AUTOCOMBAT";
            } forEach (units _x);
        } forEach pl_follow_array;
        _pGroup setVariable ["onTask", false];
        _pGroup setVariable ["setSpecial", false];
    };
};



pl_follow_array_other = [];
pl_follow_array_other_setup = [];

pl_follow_other = {
    params ["_group"];
    private ["_leadGroup", "_formDir", "_posOffset", "_pGroup", "_pSpeed", "_pBehaviour"];

    if !(visibleMap) exitWith {hint "Opne Map"};
    if (_group getVariable ["pl_formation_leader", false]) exitWith {hint format ["%1 is already leading a Formation", groupId _group]};

    _message = "Select Group to follow <br /><br />
    <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />";
    hint parseText _message;

    pl_follow_array_other_setup = pl_follow_array_other_setup + [_group];

    missionNamespace setVariable ["pl_select_formation_leader", true];
    waitUntil {!(missionNamespace getVariable ["pl_select_formation_leader", true])};

    pl_follow_array_other_setup = pl_follow_array_other_setup - [_group];

    hintSilent "";
    _leadGroup =  missionNamespace getVariable "pl_formation_leader";
    if (_leadGroup isEqualTo (group player)) exitWith {hint "Select 'Form on Commander' instead"};
    if (_leadGroup getVariable ["pl_following_formation", false]) exitWith {hint format ["%1 is already following a Formation", groupId _leadGroup]};
    if (missionNamespace getVariable ["pl_formation_cancel", false]) exitWith {};
    if (_group isEqualTo _leadGroup) exitWith {};


    [_group] call pl_reset;

    sleep 0.2;

    _formDir = getDir (leader _leadGroup);
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa"];
    _group setVariable ["pl_following_formation", true];
    playSound "beep";

    _pos1 = getPos (leader _group);
    _pos2 = getPos (leader _leadGroup);
    _relPos = [(_pos1 select 0) - (_pos2 select 0), (_pos1 select 1) - (_pos2 select 1)];
    _group setVariable ["pl_rel_pos", _relPos];
    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);
     _group setFormDir _formDir;
    
    if !(_leadGroup getVariable ["pl_formation_leader", false]) then {
        [_leadGroup] call pl_reset;

        sleep 0.2;

        _leadGroup setVariable ["onTask", true];
        _leadGroup setVariable ["setSpecial", true];
        _leadGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\whiteboard_ca.paa"];
        _leadGroup setVariable ["pl_formation_leader", true];
    };

    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _leadGroup);

    pl_follow_array_other = pl_follow_array_other + [[_leadGroup, _group]];

    while {(_leadGroup getVariable ["onTask", true]) and (_group getVariable ["onTask", true])} do {
        _pos1 = getPos (leader _leadGroup);
        sleep 2;
        _pos2 = getPos (leader _leadGroup);
        _posOffset = [(_pos2 select 0) - (_pos1 select 0), (_pos2 select 1) - (_pos1 select 1)];

        _pBehaviour = behaviour (leader _leadGroup);
        _group setBehaviour _pBehaviour;

        _pSpeed = speedMode _leadGroup;
        _group setSpeedMode _pSpeed;

        private _leader = leader _group;
        _relPos = _group getVariable "pl_rel_pos";
        if (vehicle _leader != _leader) then {
            (vehicle _leader) limitSpeed 18;
            if ((speed (vehicle _leader)) < 1) then {
                _newPos = [((getPos _leader) select 0) + ((_posOffset select 0) * 15), ((getPos _leader) select 1) + ((_posOffset select 1) * 15)];
                driver (vehicle _leader) doMove _newPos;
            };
            if ((speed (leader _leadGroup)) < 1) then {
                _newPos = [((getPos (leader _leadGroup)) select 0) + (_relPos select 0), ((getPos (leader _leadGroup)) select 1) + (_relPos select 1)];
                driver (vehicle _leader) doMove _newPos;
            };
        }
        else
        {
            _newPos = [((getPos (leader _leadGroup)) select 0) + (_relPos select 0), ((getPos (leader _leadGroup)) select 1) + (_relPos select 1)];
            _leader limitSpeed 15;
            _leader doMove _newPos;
            {
                if (_x != _leader) then {
                    _x doFollow _leader;
                };
            } forEach (units _group);
        };
    };
    pl_follow_array_other = pl_follow_array_other - [[_leadGroup, _group]];
    _group setVariable ["pl_following_formation", false];
    [_group] call pl_reset;
    sleep 0.2;
    if !(_leadGroup getVariable ["onTask", true]) then {
        _leadGroup setVariable ["pl_formation_leader", false];
    };
};

pl_march = {
    params ["_group"];
    private ["_cords", "_f"], "_mwp";

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };


    if (isNil {_group getVariable "pl_on_march"}) then {
        [_group] call pl_reset;
        sleep 0.2;

        playSound "beep";

        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa"];
        _group setVariable ["pl_on_march", true];

        {
            _x disableAI "AUTOCOMBAT";
        } forEach (units _group);
        (leader _group) limitSpeed 14;
        _f = formation _group;
        _group setFormation "STAG COLUMN";
        _group setBehaviour "AWARE";
        if ((vehicle (leader _group)) != (leader _group)) then {
            _group setBehaviour "SAFE";
            // if (((count (hcSelected player)) > 1) and (_group isEqualTo ((hcSelected player) select 0))) then {
            //     [true] call pl_spawn_getOut_vehicle;
            // };
        };

        _mwp = _group addWaypoint [_cords, 0];
        _group setVariable ["pl_mwp", _mwp];

        sleep 3;
        waitUntil {!(_group getVariable ["onTask", true]) or (((leader _group) distance2D (waypointPosition (_group getVariable ["pl_mwp", (currentWaypoint _group)]))) < 11)};
        _group setFormation _f;
        _group setVariable ["pl_on_march", nil];

        if (_group getVariable ["onTask", true]) then {[_group] call pl_reset;};
        
    }
    else
    {
        _mwp = _group addWaypoint [_cords, 0];
        _group setVariable ["pl_mwp", _mwp];
    };
};
// {[_x] spawn pl_march}forEach (hcSelected player)





["Platoon Leader","Select HC Group", "Selects the HCGroup of the Unit the player aims at", {_this spawn pl_select_group}, "", [DIK_T, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","hcSquadIn_key", "Remote View Leader of HC Group", {_this spawn pl_spawn_cam }, "", [DIK_HOME, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","hcSquadOut_key", "Release Remote View", {_this spawn pl_remote_camera_out}, "", [DIK_END, [false, false, false]]] call CBA_fnc_addKeybind;