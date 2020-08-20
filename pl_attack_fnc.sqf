pl_bounding_cords = [0,0,0];
pl_bounding_mode = "full";
pl_bounding_draw_array = [];

pl_advance = {

    params ["_group"];
    private ["_cords", "_awp"];

    // if Map at mousclick else at cursor position
    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };

    // exit if vehicle
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    // reset _group before execution
    [_group] call pl_reset;

    sleep 0.2;
    playsound "beep";

    // limit to speed (no sprinting)
    (leader _group) limitSpeed 15;

    // disable combatmode 
    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);
    _group setBehaviour "AWARE";

    // set wp
    _awp = _group addWaypoint [_cords, 0];

    // set Variables
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\walk_ca.paa";
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    // add Task Icon to wp
    pl_draw_planed_task_array pushBack [_awp, _icon];

    // waitUntil waypoint reached or task canceled
    waitUntil {if (_group isEqualTo grpNull) exitWith {true}; (((leader _group) distance2D (waypointPosition _awp)) < 10) or !(_group getVariable ["onTask", true])};

    // remove Task Icon from wp and delete wp
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_awp,  _icon]];
    deleteWaypoint [_group, _awp#1];

    // reset advance behaviour
    (leader _group) limitSpeed 5000;
    {
        _x enableAI "AUTOCOMBAT";
    } forEach (units _group);
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
};

pl_attack_mode = "normal";

pl_attack = {

    params ["_group", ["_cords", [0,0,0]], ["_taskPlanWp", []]];
    private ["_atkwp", "_posArray", "_fastAtk", "_icon"];

    // exit if vehicle
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    // check if called from other Task (Bounding)
    if (_cords isEqualTo [0,0,0]) then {
        // if map at mouseclick position with speedmode selection
        if (visibleMap) then {
            
            // Hint       
            _message = "Select Assault Location <br /><br />
            <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>TACTICAL</t> <br />
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>SLOW</t> <br />
            <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>FAST</t>";
            hint parseText _message;

            // Mapclick logic
            onMapSingleClick {
                pl_bounding_cords = _pos;
                pl_mapClicked = true;
                pl_attack_mode = "normal";
                if (_shift) then {pl_attack_mode = "slow"};
                if (_alt) then {pl_attack_mode = "fast"};
                hintSilent "";
                onMapSingleClick "";
            };
            while {!pl_mapClicked} do {sleep 0.2;};
            pl_mapClicked = false;
            _cords = pl_bounding_cords;
        }
        else
        // 3d View
        {
            _cords = screenToWorld [0.5,0.5];
            pl_attack_mode = "normal";
        };
    };

    // set Task Icon
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa";

    // Check if task planed from Waypointmenu
    if (count _taskPlanWp != 0) then {

            // add Arrow indicator
            pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

            // wait till taskwp reached
            waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11) or !(_group getVariable ["pl_task_planed", false])};

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            // if task canceld end execution
            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true};
            _group setVariable ["pl_task_planed", false];
        };

    // if task canceld end execution
    if (pl_cancel_strike) exitWith {pl_cancel_strike = false;};

    // reset _group before execution
    [_group] call pl_reset;
    sleep 0.2;

    _groupStrength = count (units _group);
    playsound "beep";
    // leader _group sideChat "Roger beginning Assault, Over";

    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);
    _group setBehaviour "AWARE";

    // Speedmode switch
    _fastAtk = false;
    switch (pl_attack_mode) do { 
        case "normal" : {leader _group limitSpeed 12;}; 
        case "slow" : {_group setSpeedMode "LIMITED"}; 
        case "fast" : {_fastAtk = true; _group setSpeedMode "FULL";};
        default {leader _group limitSpeed 12;}; 
    };
    
    // add SAD wp
    _atkwp =_group addWaypoint [_cords, 0];
    _atkwp setWaypointType "SAD";

    // set Variables
    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", _icon];

    // add Task Icon to SAD Wp
    pl_draw_planed_task_array pushBack [_atkwp, _icon];

    // fast attack setup
    if (_fastAtk) then {
        _atkDir = (leader _group) getDir _cords;
        {
            _pos = [[[_cords, 25]],[]] call BIS_fnc_randomPos;
            _x setUnitPos "UP";
            [_x, _pos, _cords, _atkDir, 45] spawn pl_bounding_move;
        } forEach (units _group);
    };

    // waituntil wp reached or task canceled
    waitUntil {if (_group isEqualTo grpNull) exitWith {true}; (((leader _group) distance2D (waypointPosition _atkwp)) < 30) or ((count (units _group)) <= (_groupStrength - 4)) or !(_group getVariable ["onTask", true])};

    sleep 1;

    // remove Icon form wp
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_atkwp,  _icon]];

    // set attack behaviour
    _group setVariable ["pl_combat_mode", true];
    _group setCombatMode "RED";
    _group enableAttack true;

    {
        _x enableAI "AUTOCOMBAT";
    } forEach (units _group);
    leader _group limitSpeed 5000;

    // waituntil task canceled
    waitUntil {!(_atkwp in (waypoints _group)) or !(_group getVariable ["onTask", true])};

    // reset attack behaviour
    _group setVariable ["pl_combat_mode", false];
    _group setCombatMode "YELLOW";
    _group enableAttack false;

    // make units in group forget targets to cancel currentCommand "ATTACK"
    {
        _targets = _x targetsQuery [objNull, sideUnknown, "", [], 0];
        _count = count _targets;
            
        for [{private _i = 0}, {_i < _count}, {_i = _i + 1}] do {
            private _y = _targets select _i;
            _x forgetTarget (_y select 1);
        };
    } forEach (units _group);

    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
};


pl_spawn_advance = {
    {
        [_x] spawn pl_advance;
    } forEach hcSelected player;
};

pl_spawn_attack = {
    {
        [_x] spawn pl_attack;
    } forEach hcSelected player;
};

pl_suppressive_fire = {
    params ["_units"];
    private ["_pos", "_time", "_target", "_leader", "_alt", "_aimPos"];

    _target = cursorTarget;
    _leader = leader (group (_units select 0));
    if (isNull _target) then {
        if (visibleMap) then {
            _pos = (findDisplay 12 displayCtrl 51) posScreenToWorld getMousePosition;
            _targetHouse = nearestTerrainObjects [_pos, ["BUILDING", "HOUSE", "BUNKER", "FORTRESS"], 10, true, true];
            if (count _targetHouse == 0) then {
                _pos = AGLToASL _pos;
                if (vehicle _leader != _leader) then {
                     _vic = vehicle _leader;
                     _leader = crew _vic select 1;
                     _aimPos = aimPos _leader
                }
                else
                {
                    _aimPos = getPosASL _leader;
                };
                _cansee = [objNull, "FIRE"] checkVisibility [getPosASL _leader, _pos];
                _alt = 0;
                while {_cansee < 0.8} do {
                    _pos = [_pos select 0, _pos select 1, (_pos select 2) + 2];
                    _cansee = [objNull, "FIRE"] checkVisibility [_aimPos, _pos];
                    _alt = _alt + 1;
                    if (_alt > 10) exitWith{};
                };
                _target = _pos;  
            }
            else
            {
                _target = _targetHouse select 0;
            };
        }
        else
        {
            _pos = screenToWorld [0.5,0.5];
            _pos = AGLToASL _pos;
            if (vehicle _leader != _leader) then {
                 _vic = vehicle _leader;
                 _leader = crew _vic select 1;
                 _aimPos = aimPos _leader
            }
            else
            {
                _aimPos = getPosASL _leader;
            };
            _cansee = [objNull, "FIRE"] checkVisibility [getPosASL _leader, _pos];
            _alt = 0;
            while {_cansee < 0.8} do {
                _pos = [_pos select 0, _pos select 1, (_pos select 2) + 2];
                _cansee = [objNull, "FIRE"] checkVisibility [_aimPos, _pos];
                _alt = _alt + 1;
                if (_alt > 10) exitWith{};
            };
            _target = _pos;
        };
        {
            if (vehicle _x != _x) exitWith {
                _vic = vehicle _x;
                _gunner = {
                    if (((assignedVehicleRole _x) select 0) isEqualTo "Turret") exitWith {_x};
                    objNull
                } forEach (crew _vic);
                _gunner doSuppressiveFire _target;
                sleep 3;
                // for "_i" from 0 to 6 do {
                //     [_vic, "HE"] call BIS_fnc_fire;
                //     sleep 0.2;
                // };
            };
            _x doSuppressiveFire _target;
        } forEach _units;
    }
    else
    {
        {
            if (vehicle _x != _x) exitWith {
                _vic = vehicle _x;
                _gunner = {
                    if (((assignedVehicleRole _x) select 0) isEqualTo "Turret") exitWith {_x};
                    objNull
                } forEach (crew _vic);
                _gunner doSuppressiveFire _target;
                sleep 3;
                // for "_i" from 0 to 6 do {
                //     [_vic, "HE"] call BIS_fnc_fire;
                //     sleep 0.2;
                // };
            };
            _x doSuppressiveFire _target;
        } forEach _units;
    };
};

pl_spawn_proximity_supression = {
    player sideRadio "SentCmdSuppress";
    _allMen = (getPos player) nearObjects ["Man", 25];
    {
        [[_x]] spawn pl_suppressive_fire;
    } forEach (_allMen select {(side _x isEqualTo playerSide)});
};



pl_spawn_suppression = {
    playsound "beep";
    {  
        [units _x] spawn pl_suppressive_fire;
    } forEach hcSelected player;
};

// [] call pl_spawn_suppression

pl_bounding_squad = {
    private ["_cords", "_group", "_moveDir", "_movePos", "_tactic", "_offSet", "_groupLen", "_units", "_team1", "_team2", "_moveRange"];

    if !(visibleMap) exitWith {hint "Open Map for bounding OW"};

    _group = hcSelected player select 0;
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};
    // hint "Select location on MAP (LMB = MOVE, SHIFT + LMB = ATTACK)";
    _message = "Select location <br /><br />
    <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>MOVE</t> <br />
    <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>ATTACK</t> <br />
    <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />";
    hint parseText _message;
    onMapSingleClick {
        pl_bounding_cords = _pos;
        pl_mapClicked = true;
        pl_bounding_mode = "move";
        if (_alt) then {pl_bounding_mode = "attack"};
        if (_shift) then {pl_cancel_strike = true};
        hintSilent "";
        onMapSingleClick "";
    };
    while {!pl_mapClicked} do {sleep 0.2;};
    pl_mapClicked = false;

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};
        
    _cords = pl_bounding_cords;
    _moveDir = (leader _group) getDir _cords;

    [_group] call pl_reset;
    sleep 0.2;

    playsound "beep";
    
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\help_ca.paa"];

    pl_bounding_draw_array pushBack [_group, _cords];

    _groupLen = (count (units _group)) - 1;

    _units = (units _group);
    _team1 = [];
    _team2 = [];

    _tactic = pl_bounding_mode;

    _group setSpeedMode "FULL";

    for "_i" from 0 to _groupLen do {
        (_units#_i) setVariable ["pl_bounding_set", false];
        if (_i % 2 == 0) then {
            if !(_units#_i getVariable ["pl_wia", false]) then {
                _units#_i setVariable ["pl_bounding_set", false];
                _team1 pushBack _units#_i;
            };
        }
        else
        {
            if !(_units#_i getVariable ["pl_wia", false]) then {
                _units#_i setVariable ["pl_bounding_set", false];
                _team2 pushBack _units#_i;
            };
        }
    };
    _units = _team1 + _team2;
    _leaderPos = getPos (leader _group);
    _offSet = 10;

    _arrive_pos_fn = {
        params ["_unit", "_movePos", "_moveDir"];
        _unit doMove _movePos;
        _unit disableAI "AUTOCOMBAT";
        // _unit disableAI "TARGET";
        // _unit disableAI "AUTOTARGET";
        // _unit disableAI "SUPPRESSION";
        // _unit disableAI "COVER";
        sleep 1;
        waitUntil {(unitReady _unit) or ((_unit distance2D _movePos) < 1.5) or (!alive _unit) or ( _unit getVariable["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])};
        _unit enableAI "AUTOCOMBAT";
        if ((group _unit) getVariable ["onTask", true]) then {
            [_unit, _movePos, _moveDir, 3, false] spawn pl_find_cover;
            sleep 1;
            _unit setVariable ["pl_bounding_set", true];
        };
    };

    {
        _movePos = [_offSet*(sin (_moveDir - 90)), _offSet*(cos (_moveDir - 90)), 0] vectorAdd _leaderPos;
        _offSet = _offSet + 6;
        [_x, _movePos, _moveDir] spawn _arrive_pos_fn;
    } forEach _team1;
    _offSet = 10;
    {
        _movePos = [_offSet*(sin (_moveDir + 90)), _offSet*(cos (_moveDir + 90)), 0] vectorAdd _leaderPos;
        _offSet = _offSet + 6;
        [_x, _movePos, _moveDir] spawn _arrive_pos_fn;
    } forEach _team2;

    waitUntil {sleep 0.1; (({_x getVariable ["pl_bounding_set", false]} count _units) == (count _units)) or !(_group getVariable ["onTask", true])};

    sleep 1.5;

    _get_move_range_fn = {
        params ["_team", "_cords"];
        _return = {
            if ((_x distance2D _cords) < 70) exitWith {30};
            60
        } forEach _team;
        // player sideChat str _return;
        _return
    };

    _moveRange = 30;
    while {_group getVariable ["onTask", true]} do {
        _movePos = [_moveRange*(sin _moveDir), _moveRange*(cos _moveDir), 0] vectorAdd (getPos (_team1#0));
        _offSet = 0;
        (_team1#0) groupRadio "SentConfirmMove";
        {
            if (_x getVariable ["pl_wia", false] or !alive _x) then {_team1 = _team1 - [_x]};
            _x setUnitPos "UP";
            _x enableAI "PATH";
            _pos = [_offSet*(sin (_moveDir - 90)), _offSet*(cos (_moveDir - 90)), 0] vectorAdd _movePos;
            _offSet = _offSet + 6;
            [_x, _pos, _cords, _moveDir] spawn pl_bounding_move;
        } forEach _team1;
        waitUntil {sleep 0.1; !(_group getVariable ["onTask", true]) or (({!(_x getVariable ["pl_bounding_set", false])} count _team1) < 1)};

        if !(_group getVariable ["onTask", true]) exitWith {};
        (_team1#0) groupRadio "sentCovering";
        sleep 2;
        _moveRange = [(_team1 + _team2), _cords] call _get_move_range_fn;
        _movePos = [_moveRange*(sin _moveDir), _moveRange*(cos _moveDir), 0] vectorAdd (getPos (_team2#0));
        _offSet = 0;
        (_team2#0) groupRadio "SentConfirmMove";
        {
            if (_x getVariable ["pl_wia", false] or !alive _x) then {_team2 = _team2 - [_x]};
            _x setUnitPos "UP";
            _x enableAI "PATH";
            _pos = [_offSet*(sin (_moveDir + 90)), _offSet*(cos (_moveDir + 90)), 0] vectorAdd _movePos;
            _offSet = _offSet + 6;
            [_x, _pos, _cords, _moveDir] spawn pl_bounding_move;
        } forEach _team2;
        waitUntil {sleep 0.1; !(_group getVariable ["onTask", true]) or (({!(_x getVariable ["pl_bounding_set", false])} count _team2) < 1)};

        if (!(_group getVariable ["onTask", true]) or _moveRange == 30) exitWith {};
        (_team2#0) groupRadio "sentCovering";
        sleep 2;
    };

    pl_bounding_draw_array = pl_bounding_draw_array - [[_group, _cords]];

    // [_group] call pl_reset;
    {
        _x setVariable ["pl_bounding_set", nil];
    } forEach _units;

    if !(_group getVariable ["onTask", true]) exitWith {};

    if (_tactic isEqualTo "attack") then { 
        [_group, _cords] spawn pl_attack
    }
    else
    {
        [_group] spawn pl_take_cover; 
    };
};

pl_bounding_move = {
    params ["_unit", "_pos", "_cords", "_moveDir", ["_atkRange", 1.5]];
    _unit disableAI "AUTOCOMBAT";
    _unit disableAI "SUPPRESSION";
    _unit disableAI "COVER";
    _unit disableAI "TARGET";
    _unit disableAI "AUTOTARGET";
        // _unit disableAI "FSM";
    _unit setVariable ["pl_bounding_set", false];
    _unit doMove _pos;
    _unit moveTo _pos;
    sleep 2;
    waitUntil {(!alive _unit) or (unitReady _unit) or ((_unit distance2D _pos) < _atkRange) or (_unit getVariable["pl_wia", false] or !((group _unit) getVariable ["onTask", true]))};
    _unit enableAI "AUTOCOMBAT";
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    _unit enableAI "SUPPRESSION";
    _unit enableAI "COVER";
    // _unit enableAI "FSM";
    _unit setUnitPos "UP";
    sleep 0.1;
    if ((group _unit) getVariable ["onTask", true] and (_atkRange == 1.5)) then {
        _unit setVariable ["pl_bounding_set", true];
        [_unit, _cords, _moveDir, 3, false] spawn pl_find_cover;
    };
};


pl_sweep_cords = [0,0,0];
pl_sweep_area_size = 35;

pl_sweep_area = {
    params ["_group", ["_taskPlanWp", []]];
    private ["_cords", "_limiter", "_targets", "_markerName", "_wp", "_icon"];

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    _markerName = format ["%1sweeper", _group];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Vertical";
    _markerName setMarkerColor "colorYellow";
    _markerName setMarkerAlpha 0.5;
    _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
    if (visibleMap) then {
        _message = "Select Search Area <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;
        onMapSingleClick {
            pl_sweep_cords = _pos;
            if (_shift) then {pl_cancel_strike = true};
            pl_mapClicked = true;
            hintSilent "";
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {
            // sleep 0.1;
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerName setMarkerPos _mPos;
        };
        pl_mapClicked = false;
        _cords = pl_sweep_cords;
    }
    else
    {
        _building = cursorTarget;
        if !(isNil "_building") then {
            _cords = getPos _building;
        };
    };

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa";

    if (count _taskPlanWp != 0) then {

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11) or !(_group getVariable ["pl_task_planed", false])};

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};

    [_group] call pl_reset;
    sleep 0.2;
    
    playsound "beep";

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    (leader _group) limitSpeed 15;

    _markerName setMarkerPos _cords;

    {
        _x disableAI "AUTOCOMBAT";
        _x setVariable ["pl_damage_reduction", true];
    } forEach (units _group);

    _wp = _group addWaypoint [_cords, 0];

    pl_draw_planed_task_array pushBack [_wp, _icon];
    _group setBehaviour "AWARE";

    

    _targets = [];
    // _targets arrayIntersect _targets;

    // player sideChat str _targets;

    // debug
    // for "_i" from 0 to (count _targets) -1 step 1 do {
    //     _markerName = createMarker [str _i, getPos (_targets#_i)];
    //     _markerName setMarkerType "mil_dot";
    //     _markerName setMarkerText str _i;
    // };

    waitUntil {sleep 0.1; (((leader _group) distance _cords) < (pl_sweep_area_size + 10)) or !(_group getVariable ["onTask", true])};
    _allMen = _cords nearObjects ["Man", pl_sweep_area_size];
    {
        _targets pushBack _x;
    } forEach (_allMen select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});
    _targets = [_targets, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;
    // _group setSpeedMode "LIMITED";
    // _group setCombatMode "RED";
    // _group setVariable ["pl_combat_mode", true];

    // player sideChat str _targets;

    [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
    sleep 0.1;
    for "_i" from count waypoints _group - 1 to 0 step -1 do {
        deleteWaypoint [_group, _i];
    };
    
    if ((count _targets) == 0) then {
        {
            _pos = [_cords, 1, pl_sweep_area_size, 0, 0, 0, 0] call BIS_fnc_findSafePos;
            _x doMove _pos;
            _x moveTo _pos;
        } forEach (units _group);
        _group setCombatMode "RED";
        _group setVariable ["pl_combat_mode", true];
        _time = time + 20;
        waitUntil {!(_group getVariable ["onTask", true]) or (time > _time)};
        _group setCombatMode "YELLOW";
        _group setVariable ["pl_combat_mode", false];
    }
    else
    {
        sleep 0.2;

        _limiter = 1;
        _teamid = 0;
        {
            _x enableAI "AUTOCOMBAT";
            _x forceSpeed 12;
            [_x, _targets, _teamid] spawn {
                params ["_unit", "_targets", "_teamid"];

                private ["_markerName"];
                private _currentTarget = -1;
                while {(_currentTarget < (count _targets) - 1)} do {
                    _currentTarget = _currentTarget + 1;
                    _target = _targets select _currentTarget + _teamid;
                    if (alive _target) then {
                        // _unit reveal [_target, 3];
                        _pos = getPosATL _target;
                        // debug
                        // _markerName = createMarker [str _unit, _pos];
                        // _markerName setMarkerType "mil_dot";
                        // _markerName setMarkerText str _unit;
                        sleep 0.2;
                        while {(alive _unit) and (alive _target) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true])} do {
                            _unit doTarget _target;
                            _unit doFire _target;
                            if ((speed _unit) < 1) then {
                                _unit doMove _pos;
                                _unit moveTo _pos;
                            };

                            sleep 1;
                        };
                    };
                    // waitUntil {(!alive _unit) or (!alive _target) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])};
                    _teamid = 0;
                    // deleteMarker _markerName;
                    if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};
                };
                // _unit sideChat "finished";
            };
            _limiter = _limiter + 1;
            if (_limiter % 2 == 0) then {
                _teamid = _teamid + 1;
                if (_teamid > (count _targets) - 1) then {_teamid = 0};
            };
        } forEach (units _group);

        // make group forget Targets outside sweep area --> More aggressive behaviour
        [_group, _cords] spawn {
            params ["_group", "_cords"];
            while {_group getVariable ["onTask", true]} do {
                _targets = (leader _group) targetsQuery [objNull, sideUnknown, "", [], 0];
                {
                    if (((_x select 1) distance2D _cords) > pl_sweep_area_size + 15) then {
                        _group forgetTarget (_x#1);
                    };
                } forEach _targets;
                sleep 2;
            };
        };


        waitUntil {!(_group getVariable ["onTask", true]) or ({!alive _x} count _targets == count _targets)};
    };

    deleteMarker _markerName;
    // _group setVariable ["pl_combat_mode", false];
    // _group setCombatMode "YELLOW";
    // remove Icon form wp
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    {
        _x setVariable ["pl_damage_reduction", false];
    } forEach (units _group);
    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
        playsound "beep";
        (leader _group) sideChat format ["%1 Area sweep complete", (groupId _group)];
    };
};

// {[_x] spawn pl_sweep_area} forEach (hcSelected player);
