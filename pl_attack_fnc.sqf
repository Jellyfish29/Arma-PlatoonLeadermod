pl_bounding_cords = [0,0,0];
pl_bounding_mode = "full";
pl_bounding_draw_array = [];
pl_draw_tank_hunt_array = [];
pl_suppress_area_size = 20;
pl_suppress_cords = [0,0,0];
pl_supppress_continuous = false;
pl_draw_suppression_array = [];
pl_sweep_cords = [0,0,0];
pl_sweep_area_size = 35;
pl_attack_mode = "normal";

pl_advance = {
    params ["_group"];
    private ["_cords", "_awp"];

    _group = (hcSelected player) select 0;

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
    // Whyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy?????????????????
    if (pl_enable_beep_sound) then {playSound "beep"};
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    // limit to speed (no sprinting)
    (leader _group) limitSpeed 15;

    // disable combatmode 
    {
        _x disableAI "AUTOCOMBAT";
        // _x disableAI "FSM";
        // _x disableAI "COVER";
        // _x disableAI "SUPPRESSION";
    } forEach (units _group);
    _group setBehaviour "AWARE";

    // set wp
    _awp = _group addWaypoint [_cords, 0];

    if ((_cords distance2D (getPos (leader _group))) < 150 ) then {
        _atkDir = (leader _group) getDir _cords;
        _offset = -20;
        _increment = 4;
        {   
            _pos = [_offset * (sin (_atkDir - 90)), _offset * (cos (_atkDir - 90)), 0] vectorAdd _cords;
            _offset = _offset + _increment;
            if (_x == leader _group) then {_pos = _cords};
            _pos = _pos findEmptyPosition [0, 50, typeOf _x];
            
            // _m = createMarker [str (random 1), _pos];
            // _m setMarkerType "mil_dot";

            [_x, _pos] spawn {
                params ["_unit", "_pos"];
                _unit limitSpeed 15;
                _unit doMove _pos;
                _unit setDestination [_pos, "FORMATION PLANNED", false];
                _reachable = [_unit, _pos, 20] call pl_not_reachable_escape;
            };
        } forEach (units _group);
    };

    // set Variables
    // _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\walk_ca.paa";
    _icon = '\A3\3den\data\Attributes\SpeedMode\normal_ca.paa';
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    // add Task Icon to wp
    pl_draw_planed_task_array pushBack [_awp, _icon];

    // waitUntil waypoint reached or task canceled
    sleep 1;
    waitUntil {sleep 0.5;if (_group isEqualTo grpNull) exitWith {true}; unitReady (leader _group) or !(_group getVariable ["onTask", true])};

    // remove Task Icon from wp and delete wp
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_awp,  _icon]];
    deleteWaypoint [_group, _awp#1];

    // reset advance behaviour
    (leader _group) limitSpeed 5000;
    {
        // _x enableAI "COVER";
        // _x enableAI "SUPPRESSION";
        // _x enableAI "FSM";
        _x enableAI "AUTOCOMBAT";
        _x forceSpeed -1;
        _x limitSpeed 5000;
        _x setDestination [getPos _x, "DoNotPlan", true];
        doStop _x;
        _x doFollow (leader _group);
    } forEach (units _group);
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
};

pl_suppressive_fire_position = {
    private ["_markerName", "_cords", "_targets", "_pos", "_units", "_leader", "_area"];

    _group = (hcSelected player) select 0;

    if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0 and (_group getVariable ["pl_is_suppressing", false])) exitWith {_group setVariable ["pl_is_suppressing", false]};

    if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0) exitWith {};


    pl_suppress_area_size = 50;
    pl_supppress_continuous = false;

    _markerName = format ["%1suppress%2", _group, random 1];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor "colorOrange";
    _markerName setMarkerAlpha 0.2;

    private _rangelimiter = 500;
    if (vehicle (leader _group) != (leader _group)) then { _rangelimiter = 1000};

    _markerBorderName = str (random 2);
    createMarker [_markerBorderName, getPos (leader _group)];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorOrange";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];
    if (visibleMap) then {
        _message = "Select Position <br /><br />
            <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>30 Seconds</t> <br />
            <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>CONTINUOUS</t> <br />
            <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>Cancel</t> <br />";
        hint parseText _message;
        onMapSingleClick {
            pl_suppress_cords = _pos;
            if (_shift) then {pl_cancel_strike = true};
            if (_alt) then {pl_supppress_continuous = true};
            pl_mapClicked = true;
            hintSilent "";
            onMapSingleClick "";
        };

        player enableSimulation false;

        while {!pl_mapClicked} do {
            // sleep 0.1;
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            if ((_mPos distance2D (leader _group)) <= _rangelimiter) then {
                _markerName setMarkerPos _mPos;
            };
            // _markerName setMarkerPos _mPos;
            if (inputAction "MoveForward" > 0) then {pl_suppress_area_size = pl_suppress_area_size + 5; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_suppress_area_size = pl_suppress_area_size - 5; sleep 0.05};
            _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];
            if (pl_suppress_area_size >= 150) then {pl_suppress_area_size = 150};
            if (pl_suppress_area_size <= 10) then {pl_suppress_area_size = 10};
        };

        player enableSimulation true;

        pl_mapClicked = false;
        _cords = getMarkerPos _markerName;
        _area = pl_suppress_area_size;
        deleteMarker _markerBorderName;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
        _area = 25;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};

    
    _continous = pl_supppress_continuous;
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa";
    _leader = leader _group;

    if (_continous) then {_group setVariable ["pl_is_suppressing", true]};

    _targetsPos = [];

    // check if enemy in Area
    // _allTargets = nearestObjects [_cords, ["Man", "Car", "Truck", "Tank"], _area, true];
    _allTargets = _cords nearEntities [["Man", "Car", "Truck", "Tank"], _area];
    {
        _targetsPos pushBack (getPosATL _x);
    } forEach (_allTargets select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

    // if no enemy target buildings;
    _buildings = nearestObjects [_cords, ["house"], _area];
    if !((count _buildings) == 0) then {
        {
            _bPos = [0,0,2] vectorAdd (getPosATL _x);
            _targetsPos pushBack _bPos;
        } forEach _buildings;
    };

    // add Random Possitions
    if (_targetsPos isEqualTo []) then {
        for "_i" from 0 to 5 do {
            _rPos = [[[_cords, _area]], nil] call BIS_fnc_randomPos;
            _targetsPos pushBack _rPos;
        };
    };

    // adjust Position and Fire;
    _units = [];
    //if group is attacking only mg + 2 closest to mg
    if (_group getVariable ["pl_is_attacking", false]) then {
        {
            if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                _units pushBack _x;
            };
        } forEach (units _group);
        if ((count _units) > 0) then {
            _leader = _units#0;
            _closestUnits = [(units _group) - _units, [], { (_units#0) distance _x }, "ASCEND"] call BIS_fnc_sortBy;
            _units pushBack (_closestUnits#0);
            _units pushBack (_closestUnits#1);
        };
    }
    else
    {
        _units = (units _group);
    };

    
    pl_draw_suppression_array pushBack [_cords, _leader, _continous, _icon];

    if (leader _group != vehicle (leader _group)) then {
        [vehicle (leader _group)] call pl_load_he;
    };

    {
        _unit = _x;
        _pos = selectRandom _targetsPos;
        _pos = ATLToASL _pos;
        _vis = lineIntersectsSurfaces [eyePos _unit, _pos, _unit, vehicle _unit, true, 1];

        if !(_vis isEqualTo []) then {
            _pos = (_vis select 0) select 0;
        };

        if ((_pos distance2D _unit) > pl_suppression_min_distance and !([_pos] call pl_friendly_check)) then {

            _unit doSuppressiveFire _pos;

            if (_continous) then {
                // _allMen = nearestObjects [_cords, ["Man"], _area, true];
                _allMen = _cords nearEntities [["Man"], _area];
                private _infTargets = [];
                {
                    _infTargets pushBack _x;
                } forEach (_allMen select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

                [_unit, _targetsPos, _group, _infTargets] spawn {
                    params ["_unit", "_targetsPos", "_group", "_infTargets"];

                    while {(_group getVariable ["pl_is_suppressing", true])} do {

                        if ((leader _group != vehicle (leader _group)) or ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun")) then {
                            // if !((currentCommand _unit) isEqualTo "Suppress") then {
                                _pos = selectRandom _targetsPos;
                                _pos = ATLToASL _pos;
                                _vis = lineIntersectsSurfaces [eyePos _unit, _pos, _unit, vehicle _unit, true, 1];
                                if !(_vis isEqualTo []) then {
                                    _pos = (_vis select 0) select 0;
                                };
                                _unit doSuppressiveFire _pos;
                            // };
                        }
                        else
                        {
                            if !(_infTargets isEqualTo []) then {
                                _target = selectRandom _infTargets;
                                _unit reveal [_target, 2];
                                _unit doSuppressiveFire _target;
                            }
                            else
                            {
                                if ((random 1) >= 0.4) then {
                                    _pos = selectRandom _targetsPos;
                                    _pos = ATLToASL _pos;
                                    _vis = lineIntersectsSurfaces [eyePos _unit, _pos, _unit, vehicle _unit, true, 1];
                                    if !(_vis isEqualTo []) then {
                                        _pos = (_vis select 0) select 0;
                                    };
                                    _unit doSuppressiveFire _pos;
                                };
                            };
                        };
                        sleep 10;
                    };
                };
            };
        };

    } forEach _units;

    sleep 2;

    waitUntil {sleep 0.5; (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) <= 0 and !(_group getVariable ["pl_is_suppressing", false])) or !alive (leader _group)};

    if (leader _group != vehicle (leader _group)) then {
        [vehicle (leader _group)] call pl_load_ap;
    };

    deleteMarker _markerName;

    pl_draw_suppression_array = pl_draw_suppression_array - [[_cords, _leader, _continous, _icon]];
};

pl_friendly_check = {
    params ["_pos"];
    _entities = _pos nearEntities ["Man", 20];
    private _return = false;
    {
        if ((side _x) isEqualTo playerSide) exitWith {_return = true};
    } forEach _entities;
    _return
};


pl_bounding_squad = {
    params ["_mode", ["_ai", false]];
    private ["_cords", "_icon", "_group", "_team1", "_team2", "_MoveDistance", "_distanceOffset", "_movePosArrayTeam1", "_movePosArrayTeam2", "_unitPos"];

    // if !(visibleMap) exitWith {hint "Open Map for bounding OW"};

    _group = hcSelected player select 0;

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };
    
    _moveDir = (leader _group) getDir _cords;

    if (pl_enable_beep_sound) then {playSound "beep"};
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;
    
    switch (_mode) do { 
        case "team" : {_icon = "\Plmod\gfx\team_bounding.paa";}; 
        case "buddy" : {_icon = "\Plmod\gfx\buddy_bounding.paa";}; 
        default {_icon = "\Plmod\gfx\team_bounding.paa";}; 
    };
    
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _wp = _group addWaypoint [_cords, 0];
    pl_draw_planed_task_array pushBack [_wp, _icon];

    _units = (units _group);
    _team1 = [];
    _team2 = [];

    _ii = 0;
    {
        if (_ii % 2 == 0) then {
            _team1 pushBack _x;
        }
        else
        {
            _team2 pushBack _x;
        };
        _ii = _ii + 1;
    } forEach (_units select {alive _x and !(_x getVariable ["pl_wia", false])});

    {
        doStop _x;
        _x disableAI "PATH";
        _x disableAI "AUTOCOMBAT";
        _x setUnitPosWeak "Middle";
    } forEach _units;

    _group setBehaviour "AWARE";

    _get_move_pos_array = { 
        params ["_team", "_wpPos", "_dirOffset", "_distanceOffset", "_MoveDistance"];
        _teamLeaderPos = getPos (_team#0);
        _moveDir = _teamLeaderPos getDir _wpPos;
        _teamLeaderMovePos = _teamLeaderPos getPos [_MoveDistance, _moveDir + (_dirOffset * 0.15)];
        _return = [_teamLeaderMovePos];
        for "_i" from 1 to (count _team) - 1 do {
            _p = _teamLeaderMovePos getPos [_distanceOffset * _i, _moveDir + _dirOffset];
            _return pushBack _p;
        };
        _return;
    };

    switch (_mode) do { 
        case "team" : {_MoveDistance = 25; _distanceOffset = 4; _unitPos = "DOWN"}; 
        case "buddy" : {_MoveDistance = 2; _distanceOffset = 11; _unitPos = "MIDDLE"}; 
        default {_MoveDistance = 25; _distanceOffset = 4; _unitPos = "DOWN"}; 
    };

    _MoveDistance = 25;
    while {({(_x distance2D (waypointPosition _wp)) < 15} count _units == 0) and !(waypoints _group isEqualTo [])} do {

        (_team1#0) groupRadio "SentConfirmMove";
        _movePosArrayTeam1 = [_team1, waypointPosition _wp, -90, _distanceOffset, _MoveDistance] call _get_move_pos_array;
        waitUntil {sleep 0.5; [_team1, _movePosArrayTeam1, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team};
        if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo [])) exitWith {};
        if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {[_group] call pl_reset};

        (_team1#0) groupRadio "sentCovering";
        _targets = (_team1#0) targets [true, 400, [], 0, waypointPosition _wp];
        if (count _targets > 0 and _mode isEqualTo "team") then {{[_x, getPosASL (selectRandom _targets)] call pl_quick_suppress} forEach _team1};

        sleep 1;

        (_team2#0) groupRadio "SentConfirmMove";
        switch (_mode) do { 
            case "team" : {_MoveDistance = 50; _movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call _get_move_pos_array}; 
            case "buddy" : {_MoveDistance = 30; _movePosArrayTeam2 = _movePosArrayTeam1}; 
            default {_movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call _get_move_pos_array}; 
        };
        waitUntil {sleep 0.5; [_team2, _movePosArrayTeam2, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team};

        if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo [])) exitWith {};
        if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {[_group] call pl_reset};
        
        (_team2#0) groupRadio "sentCovering";
        _targets = (_team2#0) targets [true, 400, [], 0, waypointPosition _wp];
        if (count _targets > 0 and _mode isEqualTo "team") then {{[_x, getPosASL (selectRandom _targets)] call pl_quick_suppress} forEach _team2};

        sleep 1;
    };

    {
        doStop _x;
        _x setUnitPos "Auto";
        _x enableAI "PATH";
        _x enableAI "AUTOCOMBAT";
        _x enableAI "COVER";
        _x enableAI "AUTOTARGET";
        _x enableAI "TARGET";
        _x enableAI "SUPPRESSION";
        _x enableAI "WEAPONAIM";
        _x setUnitCombatMode "YELLOW";
        _x doFollow (leader _group);
    } forEach _units;
    
    _group setVariable ["setSpecial", false];
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
};

pl_assault_position = {
    params ["_group", ["_taskPlanWp", []]];
    private ["_cords", "_limiter", "_targets", "_markerName", "_wp", "_icon", "_formation", "_attackMode", "_fastAtk", "_tacticalAtk"];

    pl_sweep_area_size = 35;

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};

    _markerName = format ["%1sweeper%2", _group, random 1];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor pl_side_color;
    _markerName setMarkerAlpha 0.35;
    _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
    if (visibleMap) then {
        _message = "Select Assault Location <br /><br />
            <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>In Foramtion</t> <br />
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CQB</t> <br />
            <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>FAST</t> <br />
            <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />";
        hint parseText _message;
        onMapSingleClick {
            pl_sweep_cords = _pos;
            // if (_shift) then {pl_cancel_strike = true};
            pl_attack_mode = "normal";
            if (_shift) then {pl_attack_mode = "tactical"};
            if (_alt) then {pl_attack_mode = "fast"};
            pl_mapClicked = true;
            hintSilent "";
            onMapSingleClick "";
        };

        player enableSimulation false;

        while {!pl_mapClicked} do {
            // sleep 0.1;
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerName setMarkerPos _mPos;
            if (inputAction "MoveForward" > 0) then {pl_sweep_area_size = pl_sweep_area_size + 5; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_sweep_area_size = pl_sweep_area_size - 5; sleep 0.05};
            _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
            if (pl_sweep_area_size >= 120) then {pl_sweep_area_size = 120};
            if (pl_sweep_area_size <= 5) then {pl_sweep_area_size = 5};

        };

        player enableSimulation true;

        pl_mapClicked = false;
        _cords = pl_sweep_cords;
        _markerName setMarkerPos _cords;
    }
    else
    {
        _building = cursorTarget;
        if !(isNil "_building") then {
            _cords = getPos _building;
        }
        else
        {
            _cords = screenToWorld [0.5,0.5];
        };
    };

    _attackMode = pl_attack_mode;
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa";

    if (count _taskPlanWp != 0) then {

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false]) or (_group getVariable ["pl_disembark_finished", false])};
        _group setVariable ["pl_disembark_finished", nil];
        
        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};


    _arrowDir = (leader _group) getDir _cords;
    _arrowDis = ((leader _group) distance2D _cords) / 2;
    _arrowPos = [_arrowDis * (sin _arrowDir), _arrowDis * (cos _arrowDir), 0] vectorAdd (getPos (leader _group));


    _arrowMarkerName = format ["%1arrow%2", _group, random 1];
    createMarker [_arrowMarkerName, _arrowPos];
    _arrowMarkerName setMarkerType "marker_std_atk";
    _arrowMarkerName setMarkerDir _arrowDir;
    _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
    _arrowColor = pl_side_color;
    switch (_attackMode) do { 
        case "tactical" : {_arrowMarkerName setMarkerType "marker_cqb_atk";}; 
        case "fast" : {_arrowMarkerName setMarkerType "marker_fst_atk";}; 
        default {}; 
    };
    _arrowMarkerName setMarkerColor _arrowColor;

    if (pl_enable_beep_sound) then {playSound "beep"};
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _group setVariable ["pl_is_attacking", true];

    (leader _group) limitSpeed 15;

    _markerName setMarkerPos _cords;

    {
        _x disableAI "AUTOCOMBAT";
        _x setVariable ["pl_damage_reduction", true];
    } forEach (units _group);

    _wp = _group addWaypoint [_cords, 0];

    pl_draw_planed_task_array pushBack [_wp, _icon];

    _fastAtk = false;
    _tacticalAtk = false;
    _machinegunner = objNull;

    _formation = formation _group;  
    _group setBehaviour "AWARE";

    switch (_attackMode) do { 
        case "normal" : {
            (leader _group) limitSpeed 12;
            {
                _x disableAI "AUTOCOMBAT";
                // _x disableAI "FSM";
            } forEach (units _group);
            // (leader _group) setDestination [_cords, "LEADER DIRECT", true];
            _group setFormation "LINE";
            if (_group getVariable ["pl_pos_taken", false]) then {

            };
        }; 
        case "tactical" : {_tacticalAtk = true;}; 
        case "fast" : {_fastAtk = true; _group setSpeedMode "FULL";};
        default {leader _group limitSpeed 12;}; 
    };

    // _group setCombatMode "RED";
    // _group setVariable ["pl_combat_mode", true];

    // fast attack setup
    if (_fastAtk) then {
        _atkDir = (leader _group) getDir _cords;
        _offset = pl_sweep_area_size - (pl_sweep_area_size * 1.5);
        _increment = pl_sweep_area_size / (count (units _group));
        {   
            _rPos = [pl_sweep_area_size * (sin (_atkDir - 180)), pl_sweep_area_size * (cos (_atkDir - 180)), 0] vectorAdd _cords;
            _pos = [_offset * (sin (_atkDir - 90)), _offset * (cos (_atkDir - 90)), 0] vectorAdd _rPos;
            _pos = _pos findEmptyPosition [0, 15, typeOf _x];
            _offset = _offset + _increment;
            _x setUnitPos "UP";
            // _group setCombatMode "RED";
            // _group setVariable ["pl_combat_mode", true];
            [_x, _pos, _cords, _atkDir, 45] spawn pl_bounding_move;
        } forEach (units _group);
    };

    if (_tacticalAtk) then {
        {
            _pos = _cords findEmptyPosition [0, pl_sweep_area_size, typeOf _x];

            [_x, _pos] spawn {
                params ["_unit", "_pos"];
                _unit limitSpeed 12;
                _unit disableAI "AUTOCOMBAT";
                // _unit forceSpeed 12;
                _unit doMove _pos;
                _unit setDestination [_pos, "FORMATION PLANNED", false];
                _reachable = [_unit, _pos, 20] call pl_not_reachable_escape;
                // _unit forceSpeed 12;
                // waitUntil {sleep 0.5; !(alive _unit) or (unitReady _unit) or (_unit getVariable["pl_wia", false] or !((group _unit) getVariable ["onTask", true]))};
                // doStop _unit;
            };
        } forEach (units _group);
    };


    _area = pl_sweep_area_size;
    
    // waitUntil {sleep 0.5; (((leader _group) distance _cords) < (pl_sweep_area_size + 10)) or !(_group getVariable ["onTask", true])};

    // _vics = nearestObjects [_cords, ["Car", "Truck", "Tank"], _area, true];
    _vics = _cords nearEntities [["Car", "Tank", "Truck"], 300];

    private _atkTriggerDistance = 10;
    if ((count _vics) > 0) then {
        _atkTriggerDistance = 40; 
    };

    // waitUntil {sleep 0.5; (({(_x distance _cords) < (_area + _atkTriggerDistance)} count (units _group)) > 0) or !(_group getVariable ["onTask", true])};
    while {(({(_x distance _cords) < (_area + _atkTriggerDistance)} count (units _group)) == 0) and (_group getVariable ["onTask", true])} do {

        _arrowDir = (leader _group) getDir _cords;
        _arrowDis = ((leader _group) distance2D _cords) / 2;
        _arrowPos = [_arrowDis * (sin _arrowDir), _arrowDis * (cos _arrowDir), 0] vectorAdd (getPos (leader _group));

        _arrowMarkerName setMarkerPos _arrowPos;
        _arrowMarkerName setMarkerDir _arrowDir;
        _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
        sleep 0.1;
    };

    // leader _group limitSpeed 200;
    // _group setSpeedMode "NORMAL";

    if (!(_group getVariable ["onTask", true])) exitWith {
        deleteMarker _markerName;
        deleteMarker _arrowMarkerName;
        _group setVariable ["pl_is_attacking", false];
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
        {
            _x setVariable ["pl_damage_reduction", false];
        } forEach (units _group);
    };

    _targets = [];
    _allMen = _cords nearObjects ["Man", _area];


    _targetBuildings = [];
    {
        _targets pushBack _x;
        if ([getPos _x] call pl_is_indoor) then {
            _targetBuildings pushBackUnique (nearestBuilding (getPos _x));

            // _m = createMarker [str (random 1), (getPos _x)];
            // _m setMarkerType "mil_dot";

        };
    } forEach (_allMen select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

    _targetBuildings = [_targetBuildings, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;

    missionNamespace setVariable [format ["targetBuildings_%1", _group], _targetBuildings];


    {
        _targets pushBack _x;
    } forEach (_vics select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

    _targets = [_targets, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;



    [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
    sleep 0.1;
    for "_i" from count waypoints _group - 1 to 0 step -1 do {
        deleteWaypoint [_group, _i];
    };
    
    if ((count _targets) == 0) then {
        {
            _pos = [_cords, 1, _area, 0, 0, 0, 0] call BIS_fnc_findSafePos;
            _x doMove _pos;
            _x setDestination [_pos, "FORMATION PLANNED", false];
        } forEach (units _group);
        // _group setCombatMode "RED";
        // _group setVariable ["pl_combat_mode", true];
        _time = time + 20;
        waitUntil {sleep 0.5; !(_group getVariable ["onTask", true]) or (time > _time)};
        _group setCombatMode "YELLOW";
        _group setVariable ["pl_combat_mode", false];
    }
    else
    {
        sleep 0.2;
        missionNamespace setVariable [format ["targets_%1", _group], _targets];
        private _time = time + 120;

        {
            _x enableAI "AUTOCOMBAT";
            _x enableAI "FSM";
            _x forceSpeed 12;
            [_x, _group, _area, _cords, _attackMode] spawn {
                params ["_unit", "_group", "_area", "_cords", "_attackMode"];
                private ["_movePos", "_target"];

                while {(count (missionNamespace getVariable format ["targets_%1", _group])) > 0} do {
                    if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                        _target = {
                            _attacker = _x getVariable ["pl_at_enaged_by", objNull];
                            if (!(_x isKindOf "Man") and alive _x and (isNull _attacker or _attacker == _unit)) exitWith {_x};
                            objNull
                        } forEach (missionNamespace getVariable format ["targets_%1", _group]);
                        if !(isNull _target) then {
                            _target setVariable ["pl_at_enaged_by", _unit];
                            _checkPosArray = [];
                            private _atkDir = _unit getDir _target;
                            private _lineStartPos = (getPos _unit) getPos [(_area + 100)  / 2, _atkDir - 90];
                            _lineStartPos = _lineStartPos getPos [8, _atkDir];
                            private _lineOffsetHorizon = 0;
                            private _lineOffsetVertical = (_target distance2D _unit) / 60;
                            _targetDir = getDir _target;
                            for "_i" from 0 to 60 do {
                                for "_j" from 0 to 60 do { 
                                    _checkPos = _lineStartPos getPos [_lineOffsetHorizon, _atkDir + 90];
                                    _lineOffsetHorizon = _lineOffsetHorizon + ((_area + 100) / 60);

                                    _checkPos = [_checkPos, 1.5] call pl_convert_to_heigth_ASL;

                                    // _m = createMarker [str (random 1), _checkPos];
                                    // _m setMarkerType "mil_dot";
                                    // _m setMarkerSize [0.2, 0.2];

                                    _vis = lineIntersectsSurfaces [_checkPos, aimPos _target, _target, vehicle _target, true, 1, "VIEW"];
                                    if (_vis isEqualTo []) then {
                                            _pointDir = _target getDir _checkPos;
                                            if (_pointDir >= (_targetDir - 75) and _pointDir <= (_targetDir + 75)) then {
                                                // _m setMarkerColor "colorORANGE";
                                            } else {
                                                if (_target distance2D _checkPos >= 30) then {
                                                    _checkPosArray pushBack _checkPos;
                                                    // _m setMarkerColor "colorRED";
                                                };
                                            };
                                        };
                                    };
                                _lineStartPos = _lineStartPos getPos [_lineOffsetVertical, _atkDir];
                                _lineOffsetHorizon = 0;
                            };
                            _lineOffsetVertical = 0;

                            if (count _checkPosArray > 0 and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {

                                switch (_attackMode) do { 
                                    case "tactical" : {_movePos = ([_checkPosArray, [], {_target distance2D _x}, "DESCEND"] call BIS_fnc_sortBy) select 0;}; 
                                    case "normal" : {_movePos = ([_checkPosArray, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;}; 
                                    default {_movePos = ([_checkPosArray, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;}; 
                                };

                                _unit doMove _movePos;
                                _unit setDestination [_movePos, "FORMATION PLANNED", false];
                                pl_at_attack_array pushBack [_unit, _target, objNull];

                                _unit forceSpeed 3;
                                // _unit disableAI "TARGET";
                                _unit disableAI "AUTOTARGET";
                                _unit disableAI "AUTOCOMBAT";
                                _unit setBehaviourStrong "AWARE";
                                _unit setUnitTrait ["camouflageCoef", 0, true];
                                _unit disableAi "AIMINGERROR";
                                _unit setVariable ["pl_engaging", true];
                                _unit setVariable ['pl_is_at', true];

                                // _m = createMarker [str (random 1), _movePos];
                                // _m setMarkerType "mil_dot";
                                // _m setMarkerColor "colorGreen";
                                // _m setMarkerSize [0.7, 0.7];

                                _time = time + ((_unit distance _movePos) / 1.6 + 20);
                                sleep 0.5;
                                waitUntil {sleep 0.5; (time >= _time or unitReady _unit or !alive _unit or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true]) or !alive _target or (count (crew _target) == 0))};
                                _unit reveal [_target, 4];
                                // _unit enableAI "TARGET";
                                doStop _unit;
                                _unit doTarget _target;
                                waitUntil {sleep 0.5; !(_group getVariable ["pl_hold_fire", false]) or !alive _unit or _unit getVariable["pl_wia", false] or !alive _target};
                                _unit doFire _target;
                                _time = 6;
                                waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", false]) or !alive _target};
                                // pl_at_attack_array = pl_at_attack_array - [[_unit, _movePos]];
                                if (alive _target) then {_unit setVariable ['pl_is_at', false]; pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]]; continue};
                                if !(alive _target or !alive _unit or _unit getVariable ["pl_wia", false]) then {_target setVariable ["pl_at_enaged_by", nil]};
                                pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]];
                                _unit setVariable ['pl_is_at', false];
                                _unit setUnitTrait ["camouflageCoef", 1, true];
                                _unit enableAi "AIMINGERROR";
                                _unit setVariable ["pl_engaging", false];
                                _unit enableAI "AUTOTARGET";
                                _unit setBehaviour "AWARE";
                                _group setVariable ["pl_grp_active_at_soldier", nil];
                            } else {
                                _target setVariable ["pl_at_enaged_by", nil];
                            };
                            sleep 1;
                        };
                    };

                    // CQC Building clear
                    // if (_attackMode == "tactical" and count (missionNamespace getVariable format ["targetBuildings_%1", _group]) > 0) then {

                    //     _atkBuilding = (missionNamespace getVariable format ["targetBuildings_%1", _group])#0;
                    //     _target = selectRandom ((missionNamespace getVariable format ["targets_%1", _group]) select {_atkBuilding == nearestBuilding _x});

                    //     // _m = createMarker [str (random 1), getPos _target];
                    //     // _m setMarkerType "mil_dot";
                    //     // _m setMarkerColor "colorGreen";
                    //     // _m setMarkerSize [0.7, 0.7];

                    // } else {
                    // OpenArea Clear
                    _target = selectRandom (missionNamespace getVariable format ["targets_%1", _group]);
                    // };
                    if !(isNil "_target") then {
                        if (alive _target and (_target isKindOf "Man")) then {
                            _pos = getPosATL _target;
                            _movePos = _pos vectorAdd [0.5 - (random 1), 0.5 - (random 1), 0];
                            _unit limitSpeed 15;
                            _unit doMove _movePos;
                            _unit setDestination [_movePos, "FORMATION PLANNED", false];
                            _unit lookAt _target;
                            _unit doTarget _target;
                            _reachable = [_unit, _movePos, 20] call pl_not_reachable_escape;
                            _unreachableTimeOut = time + 35;

                            while {(alive _unit) and (alive _target) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true]) and _reachable and (_unreachableTimeOut >= time)} do {
                                _unit forceSpeed 3;

                                sleep 1;
                            };
                            if (_unreachableTimeOut <= time) then {
                                _target enableAI "PATH";
                                _target doMove ((getPos _target) findEmptyPosition [10, 100, typeOf _target]);
                            };
                            if (!alive  _target) then {(missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target)};
                        }
                        else
                        {
                            doStop _unit;
                            if (alive _unit) exitWith {};
                        }
                    };

                    if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};
                };
            };
            sleep 0.1;
        } forEach (units _group);

        waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true]) or ({!alive _x} count (missionNamespace getVariable format ["targets_%1", _group]) == count (missionNamespace getVariable format ["targets_%1", _group]))};
    };


    missionNamespace setVariable [format ["targets_%1", _group], nil];
    _group setFormation _formation;
    _group setVariable ["pl_is_attacking", false];

    // remove Icon form wp
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    {
        _x setVariable ["pl_damage_reduction", false];
        _x limitSpeed 5000;
        _x forceSpeed -1;
    } forEach (units _group);
    _group setCombatMode "YELLOW";
    _group setVariable ["pl_combat_mode", false];
    _group enableAttack false;
    // sleep 8;
    deleteMarker _markerName;
    deleteMarker _arrowMarkerName;
    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
        sleep 1;
        if (pl_enable_beep_sound) then {playSound "beep"};
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault complete", (groupId _group)]};
        if (pl_enable_map_radio) then {[_group, "...Assault Complete!", 20] call pl_map_radio_callout};
        if (_tacticalAtk) then {
            {
                [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
            } forEach (units _group);
        };
    };
};