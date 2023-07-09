
pl_reset = {
    params ["_group", ["_isNotWp", true]];
    // resets and stops Group

    if !(_group getVariable ["pl_not_addalbe", false]) then { 
        player hcRemoveGroup _group;
        player hcSetGroup [_group];
    };

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
        // _unit switchMove "";
        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "COVER";
        _unit enableAI "ANIM";
        _unit enableAI "FSM";
        _unit enableAI "AIMINGERROR";
        _unit enableAI "WEAPONAIM";
        _unit enableAI "anim";
        _unit setUnitPos "AUTO";
        _unit setUnitTrait ["camouflageCoef", 1, true];
        _unit setVariable ["pl_engaging", false];
        _unit setVariable ["pl_damage_reduction", false];
        _unit setVariable ['pl_is_at', nil];
        _unit setVariable ['pl_is_ccp_medic', false];
        _unit setVariable ["pl_def_pos", nil];
        _unit setVariable ["pl_in_position", nil];
        _unit setVariable ["pl_bounding_set_time", nil];
        // sleep 0.5;
        _unit limitSpeed 5000;
        _unit forceSpeed -1;
        _unit doWatch objNull;
        _unit allowDamage true;
        if (vehicle _unit == _unit) then {
            _unit setPosASL (getPosASL _unit);
            _unit setDestination [getpos _unit, "LEADER DIRECT", false];
            _unit doFollow (leader _group);
        };
    } forEach (units _group);

    _group allowFleeing 0;
    
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

    _group setVariable ["pl_in_position", nil];
    _group setVariable ["pl_disembark_finished", nil];
    _group setVariable ["onTask", false];
    _group setVariable ["pl_on_hold", false];
    _group setVariable ['pl_wp_reached', nil];
    // _group setVariable ["pl_task_pos", nil];
    _group setVariable ["pl_grp_task_plan_wp", nil];
    _group enableAttack false;
    // [_group] call pl_reset_sop;

    // if group is not leading a formation reset Task
    if !(!(_isNotWp) and (_group getVariable ["pl_formation_leader", false])) then {


        // if group is not transporting Infantry reset special Icon
        if !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa") then {
            if !(_group getVariable ["pl_on_hold", false]) then {
                _group setVariable ["setSpecial", false];
                _group setVariable ["specialIcon", ""];
            };
        };
    };

    // reenable map info
    // _group setVariable ["pl_show_info", true];
    // reset convoc indicator
    _group setVariable ["pl_draw_convoy", false];

    // cancel planed Task
    _group setVariable ["pl_task_planed", false];
    _group setVariable ["pl_execute_plan", nil];

    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _vic forceSpeed -1;
        _vic disableBrakes false;
        if ((_vic getVariable ["pl_speed_limit", ""]) isEqualTo "CON") then {
            _vic setVariable ["pl_speed_limit", "50"];
            _vic limitSpeed 50;
        };
        _vic call pl_load_ap;
        _vic setVariable ["pl_phasing", nil];
        if (_vic getVariable ["pl_on_transport", false]) then {
            _vic setVariable ["pl_on_transport", nil];
            // _group setVariable ["setSpecial", true];
            // _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
        };

        // cancel planend tasks for loaded inf groups
        _cargo = (crew _vic) - (units _group);
        _cargoGroups = [];
        {
            _unit = _x;
            if !(_unit in (units _group)) then {
                _cargoGroups pushBack (group _unit);
            };
        } forEach _cargo;

        {
            // [_x] spawn pl_reset;
            _x setVariable ["pl_task_planed", false];
            _x setVariable ["pl_unload_task_planed", false];
            _x setVariable ["pl_execute_plan", nil];
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

// AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
pl_spawn_reset = {
    {
        [_x] spawn {
            params ["_group"];
            [_group] call pl_reset;
            // sleep 0.25;
            [_group] call pl_reset;
            // sleep 0.25;
            [_group] call pl_reset;
        };
    } forEach hcSelected player;
};

pl_hold = {
    // disables pathfinding on group

    params ["_group"];
    // if (pl_enable_beep_sound) then {playSound "beep"};
    // [_group, "confirm", 1] call pl_voice_radio_answer;

    // set Variable
    _group setVariable ["pl_on_hold", true];

    if (_group getVariable ["onTask", false]) then {
        [_group] spawn pl_reset;
        sleep 0.5;
        [_group] spawn pl_reset;
        sleep 0.5;
    };

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
    // [_group, "confirm", 1] call pl_voice_radio_answer;
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
    [selectRandom (hcSelected player), "confirm", 1] call pl_voice_radio_answer;
    {
        [_x] spawn pl_execute;
    } forEach hcSelected player;
};

pl_watch_dir = {
    // order group to watch direction and vehicles to turn in direction

    params ["_group", ["_dir", ""]];
    private ["_mPos", "_watchDir", "_watchPos", "_groupPos"];


    if (_dir isEqualTo "") then {
        // if (pl_enable_beep_sound) then {playSound "beep"};
        // [_group, "confirm", 1] call pl_voice_radio_answer;
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _groupPos = getPos (leader _group);
        _watchDir = _groupPos getDir _mPos;
    }
    else
    {
        _watchDir = parseNumber _dir;
    };

    _leader = leader _group;
    if (_leader == vehicle _leader) then {
        _group setFormDir _watchDir;
    }
    else
    {
        _vic = vehicle _leader;
        _pos = [_vic, _watchDir] call pl_get_turn_vehicle;
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


// {[_x] spawn pl_march}forEach (hcSelected player)







