
pl_follow_active = false;
pl_follow_array = [];
pl_draw_formation_mouse = false;

addMissionEventHandler ["GroupIconClick", {
    params [
        "_is3D", "_group", "_waypointId",
        "_mouseButton", "_posX", "_posY",
        "_shift", "_control", "_alt"];
    private ["_vic", "_vicGroup"];

    if (side _group == playerSide) then {
        // if (pl_enable_beep_sound) then {playSound "radioin"};
        // if ((vehicle (leader _group)) != (leader _group)) then {
        //     _vic = vehicle (leader _group);
        //     // player sideChat str _vic;
        //     _vicGroup = group (driver _vic);
        //     // player sideChat str _vicGroup;
        //     [_vicGroup] spawn {
        //         params ["_vicGroup"];
        //         sleep 0.35;
        //         player hcSelectGroup [_vicGroup];
        //     };
        // };
        if (pl_add_group_to_hc) then {
            if (_group getVariable ["pl_not_addalbe", false]) exitWith {pl_add_group_to_hc = false; hint "Group cant be added!"};
            [_group ] spawn pl_add_to_hc_execute;
            [_group] spawn pl_set_up_ai;
        };
        if (missionNamespace getVariable ["pl_select_formation_leader", false]) then {
            missionNamespace setVariable ["pl_formation_leader", _group];
            missionNamespace setVariable ["pl_select_formation_leader", false];
            if (_shift) then {
                missionNamespace setVariable ["pl_formation_cancel", true];
            }
            else 
            {
                missionNamespace setVariable ["pl_formation_cancel", false]
            };
        };
        if (missionNamespace getVariable ["pl_transfer_medic_enabled", false]) then {
            missionNamespace setVariable ["pl_transfer_medic_enabled", false];
            missionNamespace setVariable ["pl_transfer_medic_group", _group];
        };
    };
}];

addMissionEventHandler ["HCGroupSelectionChanged", {
    params ["_group", "_isSelected"];

    if (_isSelected) then {
        // if (pl_enable_beep_sound) then {playSound "beep"};
        if (pl_enable_beep_sound) then {playSound "radioina"};
    } else {
        if (pl_enable_beep_sound) then {playSound "radioutc"};
    };
}];


pl_vehicle_destroyed_report_cd = 0;

addMissionEventHandler ["EntityKilled",{
    params ["_killed", "_killer", "_instigator", "_useEffects"];
    if ((side group _killed) isEqualto playerside) then {
        if (vehicle _killed == _killed) then {
            _leader = leader (group _killed);
            _unitMos = getText (configFile >> "CfgVehicles" >> typeOf _killed >> "displayName");
            _unitName = name _killed;
            _killed setVariable ["pl_wia", false];
            [_killed] spawn pl_draw_kia;
            _group = group _killed;
            if (pl_enable_map_radio) then {[_group, format ["...%1 KIA", _unitMos], 15] call pl_map_radio_callout};
            [_group, "kia", random 2] call pl_voice_radio_answer;
            _mags = _group getVariable "magCountAllDefault";
            _mag = _group getVariable "magCountSoloDefault";
            _mags = _mags - _mag;
            _group setVariable ["magCountAllDefault", _mags];

            // // reinforcements
            // _type = typeOf _killed;
            // _loadout = _killed getVariable "pl_loadout";
            // _killedUnits = _group getVariable "pl_killed_units";
            // _killedUnits pushBack [_type, _loadout];
            // _group setVariable ["pl_killed_units", _killedUnits];

            // if (pl_enable_beep_sound) then {playSound "beep"};
            // _leader sideChat format ["%1: %2 K.I.A", groupId _group, _unitMos];
        };

        // else
        // {
        //     if (time >= pl_vehicle_destroyed_report_cd) then {
        //         _vic = vehicle _killed;
        //         _vicName = getText (configFile >> "CfgVehicles" >> typeOf _vic >> "displayName");
        //         player sideChat format ["%1 was destroyed", _vicName];
        //         pl_vehicle_destroyed_report_cd = time + 3;
        //     };
        // };
    }
    else
    {
        if (_killed isEqualTo (leader (group _killed))) then {
            if !((getNumber (configFile >> "CfgVehicles" >> typeOf (vehicle _killer) >> "artilleryScanner")) == 1) then {
                [_killed, _killer, (group _killed)] spawn pl_enemy_destroyed_report;
            };
        };
    };
}];


pl_reset = {
    params ["_group", ["_isNotWp", true]];
    // resets and stops Group

    // reset individual units variables
    [_group] spawn {
        params ["_group"];
        _group setVariable ["pl_stop_event", true];
        sleep 2;
        _group setVariable ["pl_stop_event", nil];
    };
    {
        _unit = _x;
        // if ((currentCommand _unit) isEqualTo "SUPPORT") then {
        //     [_unit] spawn pl_hard_reset;
        // };
        if !(_group getVariable ["pl_on_hold", false]) then {_unit enableAI "PATH"};
        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "COVER";
        _unit enableAI "ANIM";
        _unit enableAI "FSM";
        _unit enableAI "AIMINGERROR";
        _unit enableAI "WEAPONAIM";
        _unit setUnitPos "AUTO";
        _unit setUnitTrait ["camouflageCoef", 1, true];
        _unit setVariable ["pl_engaging", false];
        _unit setVariable ["pl_damage_reduction", false];
        _unit setVariable ['pl_is_at', nil];
        _unit setVariable ['pl_is_ccp_medic', false];
        _unit setVariable ["pl_def_pos", nil];
        // sleep 0.5;
        _unit limitSpeed 5000;
        _unit forceSpeed -1;
        _unit doWatch objNull;
        if (vehicle _unit == _unit) then {
            _unit doFollow (leader _group);
        };
    } forEach (units _group);
    
    // rejoin group hack
    _leader = leader _group;
    (units _group) joinSilent _group;
    _group selectLeader _leader;

    // if player group select player as leader
    if (_group isEqualTo (group player)) then {
        _group selectLeader player;
    };

    if (_group getVariable ["pl_is_bounding", false]) then {
        _group setVariable ["pl_is_bounding", false];
    };

    // reset Healing
    // _group setVariable ["pl_healing_active", nil];

    // if group is not leading a formation reset Task
    if !(!(_isNotWp) and (_group getVariable ["pl_formation_leader", false])) then {

        _group setVariable ["onTask", false];

        // if group is not transporting Infantry reset special Icon
        if !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa") then {
            if !(_group getVariable ["pl_on_hold", false]) then {
                _group setVariable ["setSpecial", false];
            };
        };
    };

    // reenable map info
    // _group setVariable ["pl_show_info", true];
    // reset convoc indicator
    _group setVariable ["pl_draw_convoy", false];

    // cancel planed Task
    _group setVariable ["pl_task_planed", false];

    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _vic forceSpeed -1;
        _vic call pl_load_ap;
        if (_vic getVariable ["pl_on_transport", false]) then {
            _vic setVariable ["pl_on_transport", nil];
            // _group setVariable ["setSpecial", true];
            // _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
        };

        // cancel planend tasks for loaded inf groups
        _cargo = fullCrew [_vic, "cargo", false];
        _cargoGroups = [];
        {
            _unit = _x select 0;
            if !(_unit in (units _group)) then {
                _cargoGroups pushBack (group (_x select 0));
            };
        } forEach _cargo;

        {
            // [_x] spawn pl_reset;
            _x setVariable ["pl_task_planed", false];
            _x setVariable ["pl_unload_task_planed", false];
            [_x, (currentWaypoint _x)] setWaypointType "MOVE";
            [_x, (currentWaypoint _x)] setWaypointPosition [getPosASL (leader _x), -1];
            sleep 0.1;
            deleteWaypoint [_x, (currentWaypoint _x)];
            for "_i" from count waypoints _x - 1 to 0 step -1 do {
                deleteWaypoint [_x, _i];
            };
        } forEach _cargoGroups;

        if ((count _cargo) == 0) then {
            _group setVariable ["pl_has_cargo", false];
        };
    };

    // stop suppression

    if (_group getVariable ["pl_is_suppressing", false]) then {_group setVariable ["pl_is_suppressing", false]};
    _group setVariable ["pl_fof_set", false];

    // only delete Waypoints when not called from Move or MoveAdd
    if (_isNotWp) then {
        _group setSpeedMode "NORMAL";
        _group setBehaviour "AWARE";
        [_group, (currentWaypoint _group)] setWaypointType "MOVE";
        [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
        sleep 0.1;
        deleteWaypoint [_group, (currentWaypoint _group)];
        for "_i" from count waypoints _group - 1 to 0 step -1 do {
            deleteWaypoint [_group, _i];
        };
    };
    _group setVariable ["pl_on_march", nil];
};

pl_spawn_reset = {
    {
        [_x] spawn {
            params ["_group"];
            [_group] spawn pl_reset;
            sleep 0.5;
            [_group] spawn pl_reset;
        };
    } forEach hcSelected player;
};

pl_hold = {
    // disables pathfinding on group

    params ["_group"];
    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;

    // set Variable
    _group setVariable ["pl_on_hold", true];

    // if not already having special set, set special
    if !(_group getVariable ["setSpecial", false]) then {
        _group setVariable ["setSpecial", true];
        // if not on Transportmission
        if !((vehicle (leader _group)) getVariable ["pl_on_transport", false]) then {
            _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa"];
        };
    };

    // disable "PATH" for each unit
    {
        _x disableAI "PATH";   
    } forEach (units _group);  
};

pl_spawn_hold = {
    {
        [_x] spawn pl_hold;
    } forEach hcSelected player;
};

pl_execute = {
    params ["_group"];
    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    _group setVariable ["pl_on_hold", false];

    // if icon == "wait" disable icon
    if ((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa") then {
        _group setVariable ["setSpecial", false];
    };

    // if group not on task and not on transport mission disable icon
    if (!(_group getVariable "onTask") and !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa")) then {
        _group setVariable ["setSpecial", false];
    };

    // if on transport mission set land icon
    if ((vehicle (leader _group)) getVariable ["pl_on_transport", false]) then {
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
    };

    // reeanable "PATH"
    {
        _x enableAI "PATH";
        // _x doFollow (leader _group);
    } forEach (units _group);

    // (units _group) joinSilent _group;
};

pl_spawn_execute = {
    {
        [_x] spawn pl_execute;
    } forEach hcSelected player;
};

pl_draw_planed_task_array = [];

pl_task_planer = {
    // plan Task to be executed when reaching a Waypoint

    params ["_taskType"];
    private ["_group", "_wp", "_icon"];

    // get _wp and _group
    _logic = player getvariable "BIS_HC_scope";
    _wp = _logic getvariable "WPover";
    if ((count _wp) == 1) exitWith {hint "Keep Mouse over Waypoint to plan Task!"};
    _group = _wp select 0;
    
    // if Task already planed exit
    if (_group getVariable ["pl_task_planed", false]) exitWith {hint format ["%1 already has a Task planed", groupId _group]};

    // if already on active Task exit
    if (_group getVariable ["onTask", false] and !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa")) exitWith {hint format ["%1 already has a Task", groupId _group]};

    // delete following wps
    for "_i" from count waypoints _group - 1 to (_wp select 1) + 1 step -1 do {
            deleteWaypoint [_group, _i];
    };

    // set Variable
    _group setVariable ["pl_task_planed", true];

    // call task to be executed
    switch (_taskType) do { 
        case "assault" : {[_group, _wp] spawn pl_assault_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa"};
        case "defend" : {[_group, _wp] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "defPos" : {[_group, _wp] spawn pl_take_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "resupply" : {[_group, _wp] spawn pl_supply_point; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"};
        case "recover" : {[_group, _wp] spawn pl_repair; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"};
        case "maintenance" : {[_group, _wp] spawn pl_maintenance_point; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"};
        case "mine" : {[_group, _wp] spawn pl_lay_mine_field; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "charge" : {[_group, _wp] spawn pl_place_charge; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"};
        case "unload" : {[_group, _wp] spawn pl_unload_at_position_planed; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"};
        default {}; 
    };

    // add indicator
    pl_draw_planed_task_array pushBack [_wp, _icon];

    // waituntil wp reached then delete indicator
    [_wp, _group, _icon] spawn {
        params ["_wp", "_group", "_icon"];
        waitUntil {sleep 1; !(_group getVariable ["pl_task_planed", true])};
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    };
};

pl_draw_unload_inf_task_plan_icon_array = [];

pl_unload_inf_follow_up_plan = {
    params ["_group", "_cords"];
    
    waitUntil {inputAction 'zoomTemp' <= 0};

    sleep 0.2;

    missionNamespace setVariable ["pl_unload_inf_group_array", [_group, _cords]];
    showCommandingMenu '#USER:pl_task_plan_menu_unloaded_inf';

    sleep 0.2;

    waitUntil {!(commandingMenu == '#USER:pl_task_plan_menu_unloaded_inf')};

    sleep 0.2;

    if !(_group getVariable ["pl_task_planed", false]) then {
        pl_draw_unload_inf_task_plan_icon_array pushBack [_group, _cords];
    };

};

pl_task_planer_unload_inf = {
    // plan Task to be executed when reaching a Waypoint
    params ["_taskType"];
    private ["_group", "_wp", "_icon"];

    // get _wp and _group
    _group = (missionNamespace getVariable "pl_unload_inf_group_array")#0;
    _cords = (missionNamespace getVariable "pl_unload_inf_group_array")#1;
    _wp = _group addWaypoint [_cords, 0];

    sleep 0.2;

    // set Variable
    _group setVariable ["pl_task_planed", true];
    _group setVariable ["pl_unload_task_planed", true];

    // call task to be executed
    switch (_taskType) do { 
        case "assault" : {[_group, _wp] spawn pl_assault_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa"};
        case "defend" : {[_group, _wp] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "defPos" : {[_group, _wp] spawn pl_take_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "mine" : {[_group, _wp] spawn pl_lay_mine_field; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "charge" : {[_group, _wp] spawn pl_place_charge; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"};
        default {}; 
    };

    // add indicator
    pl_draw_planed_task_array pushBack [_wp, _icon];

    // waituntil wp reached then delete indicator
    [_wp, _group, _icon] spawn {
        params ["_wp", "_group", "_icon"];
        waitUntil {!(_group getVariable ["pl_task_planed", true])};
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    };
};

pl_cancel_planed_task = {
    // cancels planed Task

    _logic = player getvariable "BIS_HC_scope";
    _wp = _logic getvariable "WPover";
    if ((count _wp) == 1) exitWith {hint "Keep Mouse over Waypoint to plan cancel Task!"};
    _group = _wp select 0;
    _group setVariable ["pl_task_planed", false];


    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _cargo = fullCrew [_vic, "cargo", false];
        _cargoGroups = [];
        {
            _unit = _x select 0;
            if !(_unit in (units _group)) then {
                _cargoGroups pushBack (group (_x select 0));
            };
        } forEach _cargo;

        {
            _x setVariable ["pl_task_planed", false];
            _x setVariable ["pl_unload_task_planed", false];
            [_x, (currentWaypoint _x)] setWaypointType "MOVE";
            [_x, (currentWaypoint _x)] setWaypointPosition [getPosASL (leader _x), -1];
            sleep 0.1;
            deleteWaypoint [_x, (currentWaypoint _x)];
            for "_i" from count waypoints _x - 1 to 0 step -1 do {
                deleteWaypoint [_x, _i];
            };
        } forEach _cargoGroups;
    };
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
    // order group to watch direction and vehicles to turn in direction

    params ["_group", ["_dir", ""]];
    private ["_watchDir", "_watchPos", _groupPos];


    if (_dir isEqualTo "") then {
        if (pl_enable_beep_sound) then {playSound "beep"};
        // [_group, "confirm", 1] call pl_voice_radio_answer;
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        _groupPos = getPos (leader _group);
        _watchDir = [_cords, _groupPos] call BIS_fnc_dirTo;
    }
    else
    {
        _watchDir = parseNumber _dir;
    };

    _leader = leader _group;
        if (_leader == vehicle _leader) then {
        _group setFormDir _watchDir;
        _watchDir = [(_watchDir - 180)] call pl_angle_switcher;
        _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _groupPos;
        {
            _x doWatch _watchPos;
        } forEach (units _group);
    }
    else
    {
        _vic = vehicle _leader;
        _pos = [_vic, (_watchDir - 180)] call pl_get_turn_vehicle;
        _vic doMove _pos;
    };
};


pl_get_turn_vehicle = {
    params ["_vic", "_turnDir"];

    private _pos = [];
    private _min = 20;      // Minimum range
    private _i = 0;         // iterations

    while {_pos isEqualTo []} do {
        _pos = (_vic getPos [_min, _turnDir]) findEmptyPosition [0, 2.2, typeOf _vic];

        // water
        if !(_pos isEqualTo []) then {if (surfaceIsWater _pos) then {_pos = []};};

        // update
        _min = _min + 15;
        _i = _i + 1;
        if (_i > 6) exitWith {_pos = _vic modelToWorldVisual [0, -100, 0]};
    };
    _pos
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

pl_hold_fire = {
    params ["_group"];

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;

    _group setCombatMode "GREEN";
    _group setVariable ["pl_hold_fire", true];
    _group setVariable ["pl_combat_mode", true];
};

pl_open_fire = {
    params ["_group"];

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;

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
            sleep 0.5;
            [_x] call pl_reset;
            sleep 0.5;

            _x setVariable ["onTask", true];
            _x setVariable ["setSpecial", true];
            _x setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa"];
            // if (pl_enable_beep_sound) then {playSound "beep"};
            [_group, "confirm", 1] call pl_voice_radio_answer;
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
        sleep 0.5;
        [_group] call pl_reset;
        sleep 0.5;

        // if (pl_enable_beep_sound) then {playSound "beep"};
        [_group, "confirm", 1] call pl_voice_radio_answer;


        // _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\3den\data\Attributes\SpeedMode\normal_ca.paa"];
        _group setVariable ["pl_on_march", true];

        {
            _x disableAI "AUTOCOMBAT";
        } forEach (units _group);
        (leader _group) limitSpeed 14;
        _f = formation _group;
        // _group setFormation "FILE";
        _group setBehaviour "AWARE";
        // if ((vehicle (leader _group)) != (leader _group)) then {
            

        // };

        _mwp = _group addWaypoint [_cords, 0];
        _group setVariable ["pl_mwp", _mwp];

        sleep 1;
        waitUntil {(((leader _group) distance2D (waypointPosition (_group getVariable ["pl_mwp", (currentWaypoint _group)]))) < 11) or (isNil {_group getVariable ["pl_on_march", nil]})};
        _group setFormation _f;
        _group setVariable ["pl_on_march", nil];
        _group setVariable ["setSpecial", false];
        {
            _x enableAI "AUTOCOMBAT";
            _x enableAI "FSM";
        } forEach (units _group);
        (leader _group) limitSpeed 5000;

        // if (_group getVariable ["onTask", true] and !(_group getVariable ["pl_task_planed", false])) then {[_group] call pl_reset;};
        
    }
    else
    {
        _mwp = _group addWaypoint [_cords, 0];
        _group setVariable ["pl_mwp", _mwp];
    };
};
// {[_x] spawn pl_march}forEach (hcSelected player)



pl_draw_sync_wp_array = [];

pl_move_as_formation = {
    params [["_groups", hcSelected player], ["_firstCall", false]];
    private ["_cords", "_wpPos", "_pos1", "_pos2", "_syncWps", "_infIncluded"];

    if !(visibleMap) exitWith {hint "Open Map to order Formation Move"};

    _infIncluded = {
        if (vehicle (leader _x) == leader _x) exitWith {true};
        false
    } forEach _groups;

    // choose formationleader -> first group in array every Position will be calculated relatic to leader
    _formationLeaderGroup = _groups#0;

    // get WP Position of FormationLeader or current position if no waypoint and add to indicator array
    _wpsL = waypoints _formationLeaderGroup;
    if !(_wpsL isEqualTo []) then {
        _wpPos = waypointPosition (_wpsL select ((count _wpsL) - 1)); //getPos (leader _formationLeaderGroup);
    }
    else
    {
        _wpPos = getPos (leader _formationLeaderGroup)
    };
    if (isNil "_wpPos") then {_wpPos = getPos (leader _formationLeaderGroup)};
    pl_draw_formation_move_mouse_array = [[vehicle (leader _formationLeaderGroup), [0,0], _wpPos]];

    // calc relativ position to formationleader for every other group and add to indicator array
    {
        _wps1 = waypoints _x;
        if !(_wps1 isEqualTo []) then {
            _pos1 = waypointPosition (_wps1 select ((count _wps1) - 1)); //getPos (leader _x);
        }
        else
        {
            _pos1 = getPos (leader _x);
        };
        _wps2 = waypoints _formationLeaderGroup;
        if !(_wps2 isEqualTo []) then {
            _pos2 = waypointPosition (_wps2 select ((count _wps2) - 1)); //getPos (leader _formationLeaderGroup);
        }
        else
        {
            _pos2 = getPos (leader _formationLeaderGroup);
        };
        _relPos = [(_pos1 select 0) - (_pos2 select 0), (_pos1 select 1) - (_pos2 select 1)];
        pl_draw_formation_move_mouse_array pushBack [vehicle (leader _x), _relPos, _pos1];
    } forEach (_groups) - [_formationLeaderGroup];

    // draw Indicator and wait for mouseclick;
    pl_draw_formation_mouse = true;

    if (_firstCall) then {showCommandingMenu ""; sleep 0.4};

    waitUntil {inputAction "defaultAction" > 0 or inputAction "zoomTemp" > 0};

    sleep 0.05;

    pl_draw_formation_move_mouse_array = [];

    if (inputAction "zoomTemp" > 0) exitWith {pl_draw_formation_mouse = false;};

    if (_infIncluded) then {
        {
            if (vehicle (leader _x) != leader _x) then {
                (vehicle (leader _x)) limitSpeed 23;
                (vehicle (leader _x)) setVariable ["pl_speed_limit", "CON"];
            };
        } forEach _groups;
    };

    _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;

    // calc new Move position relativ ro mouseposition and add Waypoints
    _syncWps = [];

    // 1. set position or wpPosition of Formationleader as absolute
    _wps2 = waypoints _formationLeaderGroup;
    if !(_wps2 isEqualTo []) then {
        _pos2 = waypointPosition (_wps2 select ((count _wps2) - 1)); //getPos (leader _formationLeaderGroup);
    }
    else
    {
        _pos2 = getPos (leader _formationLeaderGroup);
    };

    // 2. add wp for formationleader;
    _lWp = _formationLeaderGroup addWaypoint [_cords, 0];
    _formationLeaderGroup setVariable ["pl_wait_wp", _lWp];
    _syncWps = [_lWp];
    // _syncWps pushBack _lWp;

    // 3. calc waypoint for other groups relativ to Formationleader and add WP
    {
        _wps1 = waypoints _x;
        if !(_wps1 isEqualTo []) then {
            _pos1 = waypointPosition (_wps1 select ((count _wps1) - 1)); //getPos (leader _x);
        }
        else
        {
            _pos1 = getPos (leader _x);
        };
        _relPos = [(_pos1 select 0) - (_pos2 select 0), (_pos1 select 1) - (_pos2 select 1)];
        _newPos = _relPos vectorAdd _cords;
        _gWp = _x addWaypoint [_newPos, 0];
        _gWp synchronizeWaypoint _syncWps;
        _syncWps pushBack _gWp;
    } forEach _groups - [_formationLeaderGroup];

    _syncWps = [_syncWps, [], {(waypointPosition _x) distance2D (waypointPosition _lWp)}, "ASCEND"] call BIS_fnc_sortBy;

    // pl_draw_sync_wp_array pushBack _syncWps;

    if (inputAction "curatorGroupMod" > 0) exitWith {sleep 0.4; [_groups] spawn pl_move_as_formation};
    pl_draw_formation_mouse = false;
};


pl_sync_wp = {
    _logic = player getvariable "BIS_HC_scope";
    _wp = _logic getvariable "WPover";
    if ((count _wp) == 1) exitWith {hint "Keep Mouse over Waypoint to plan Task!"};
    _group = _wp select 0;  
};




