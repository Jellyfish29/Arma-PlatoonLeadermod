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
    [_group] call pl_reset;

    sleep 0.2;
    if (pl_enable_beep_sound) then {playSound "beep"};

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
    waitUntil {if (_group isEqualTo grpNull) exitWith {true}; unitReady (leader _group) or !(_group getVariable ["onTask", true])};

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
    _markerName setMarkerColor "colorRED";
    _markerName setMarkerAlpha 0.2;

    private _rangelimiter = 500;
    if (vehicle (leader _group) != (leader _group)) then { _rangelimiter = 1000};

    _markerBorderName = str (random 2);
    createMarker [_markerBorderName, getPos (leader _group)];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorRED";
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
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};

    
    _continous = pl_supppress_continuous;
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa";
    _leader = leader _group;

    if (_continous) then {_group setVariable ["pl_is_suppressing", true]};

    _targetsPos = [];

    // check if enemy in Area
    _allTargets = nearestObjects [_cords, ["Man", "Car", "Truck", "Tank"], _area, true];
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
                _allMen = nearestObjects [_cords, ["Man"], _area, true];
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
                                if (random 1 >= 0.5) then {
                                    _unit doSuppressiveFire _target;
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

    waitUntil {(({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) <= 0 and !(_group getVariable ["pl_is_suppressing", false])) or !alive (leader _group)};

    if (leader _group != vehicle (leader _group)) then {
        [vehicle (leader _group)] call pl_load_ap;
    };

    deleteMarker _markerName;

    pl_draw_suppression_array = pl_draw_suppression_array - [[_cords, _leader, _continous, _icon]];
};

pl_friendly_check = {
    params ["_pos"];
    _entities = _pos nearEntities ["Man", 15];
    private _return = false;
    {
        if ((side _x) isEqualTo playerSide) exitWith {_return = true};
    } forEach _entities;
    _return
};

// pl_tank_hunt = {
//     private ["_cords", "_movePos", "_moveCords"];
    
//     _group = (hcSelected player) select 0;

//     if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

//     pl_tankHunt_area_size = 50;

//     _markerName = format ["%1tankHunt", _group];
//     createMarker [_markerName, [0,0,0]];
//     _markerName setMarkerShape "ELLIPSE";
//     _markerName setMarkerBrush "SolidBorder";
//     _markerName setMarkerColor "colorRED";
//     _markerName setMarkerAlpha 0.2;
//     _markerName setMarkerSize [pl_tankHunt_area_size, pl_tankHunt_area_size];
//     if (visibleMap) then {
//         _message = "Select Targets Position <br /><br />
//             <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>30 Seconds</t> <br />
//             <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />
//             <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>Cancel</t> <br />";
//         hint parseText _message;
//         onMapSingleClick {
//             pl_tank_hunt_cords = _pos;
//             if (_shift) then {pl_cancel_strike = true};
//             pl_mapClicked = true;
//             hintSilent "";
//             onMapSingleClick "";
//         };
//         while {!pl_mapClicked} do {
//             // sleep 0.1;
//             _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//             _markerName setMarkerPos _mPos;
//             if (inputAction "MoveForward" > 0) then {pl_tankHunt_area_size = pl_tankHunt_area_size + 10; sleep 0.1};
//             if (inputAction "MoveBack" > 0) then {pl_tankHunt_area_size = pl_tankHunt_area_size - 10; sleep 0.1};
//             _markerName setMarkerSize [pl_tankHunt_area_size, pl_tankHunt_area_size];
//             if (pl_tankHunt_area_size >= 120) then {pl_tankHunt_area_size = 120};
//             if (pl_tankHunt_area_size <= 20) then {pl_tankHunt_area_size = 20};
//         };
//         pl_mapClicked = false;
//         _cords = pl_tank_hunt_cords;
//         pl_draw_tank_hunt_array pushBack _cords;

//         onMapSingleClick {
//             pl_tank_hunt_cords_2 = _pos;
//             if (_shift) then {pl_cancel_strike = true};
//             pl_mapClicked = true;
//             hintSilent "";
//             onMapSingleClick "";
//         };
//         while {!pl_mapClicked} do {};
//         _moveCords = pl_tank_hunt_cords_2;
//         pl_draw_tank_hunt_array = pl_draw_tank_hunt_array - [_cords];
//     }
//     else
//     {
//         _cords = screenToWorld [0.5,0.5];
//     };

//     if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};

//     // Only within 800 m Range
//     if ((_cords distance2D (leader _group)) > 800) exitWith {hint "Targets need to be within 1000m of group!"};

//     // get AT Soldier
//     _antitank = {
//         if ((secondaryWeapon _x) != "") exitWith {_x};
//         objNull;
//     } forEach (units _group);
//     _missile = (getArray (configFile >> "CfgWeapons" >> (secondaryWeapon _antitank) >> "magazines")) select 0;
//     _escort = selectRandom ((units _group) - [_antitank, leader _group]);

//     // If no At exit
//     if (isNull _antitank) exitWith {leader _group sideChat format["%1: No AT Weapons", groupId _group]};

//     // If no At Ammo left exit
//     if ((secondaryWeaponMagazine _antitank) isEqualTo []) exitWith {leader _group sideChat format["%1: Out of AT Weapons", groupId _group]};

//     [_group] call pl_reset;

//     sleep 0.2;

//     if (pl_enable_beep_sound) then {playSound "beep"};

//     _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa";
//     _group setVariable ["onTask", true];
//     _group setVariable ["setSpecial", true];
//     _group setVariable ["specialIcon", _icon];
//     _group setVariable ["pl_combat_mode", true];
//     _group setCombatMode "RED";

//     pl_draw_suppression_array pushBack [_cords, _antitank, true, _icon];
//     ATLToASL _moveCords;
    

//     _antitank disableAI "AUTOCOMBAT";
//     _escort disableAI "AUTOCOMBAT";

//     {
//         [_x, getPos _antitank, 0, 10, false] spawn pl_find_cover;
//     } forEach ((units _group) - [_antitank, _escort]);


//     _escort doFollow _antitank;
//     _antitank doMove _moveCords;
//     _escort doFollow _antitank;
//     waitUntil {unitReady _antitank or !(_group getVariable ["onTask", true])};
//     while {_group getVariable ["onTask", false] and alive _antitank} do {
//         _vics = nearestObjects [_cords, ["Car", "Truck", "Tank"], pl_tankHunt_area_size, true];

//         // check for closed Object from target blocking view --> antitank movePos
//         _vics = [_vics, [], {(getPos _x) distance2D (leader _group)}, "DESCEND"] call BIS_fnc_sortBy;
//         {
//             _vic = _x;
//             _antitank reveal [_vic, 4];
//             _antitank doTarget _vic;
//             _antitank doFire _vic;
//             _time = time + 60;
//             _escort doFollow _antitank;
//             waitUntil {time > _time or !alive _vic or !alive _antitank or !(_group getVariable ["onTask", true])};
//         } forEach _vics;
//         _antitank doFollow (leader _group);
//         _escort doFollow (leader _group);
//         sleep 1;
//         if ((secondaryWeaponMagazine _antitank) isEqualTo []) exitWith {leader _group sideChat format["%1: Out of AT Weapons", groupId _group]};
//     };

//     [_group] call pl_reset;
//     _group setVariable ["pl_combat_mode", false];
//     _group setCombatMode "YELLOW";
//     pl_draw_suppression_array = pl_draw_suppression_array - [[_cords, _antitank, true, _icon]];
    
//     deleteMarker _markerName;
// };

pl_bounding_squad = {
    private ["_cords", "_group", "_moveDir", "_movePos", "_tactic", "_offSet", "_groupLen", "_units", "_team1", "_team2", "_moveRange", "_wp"];

    if !(visibleMap) exitWith {hint "Open Map for bounding OW"};

    _group = hcSelected player select 0;

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};
    hint "Select location on MAP (LMB = MOVE, SHIFT + LMB = CANCEL)";
    _message = "Select location <br /><br />
    <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>MOVE</t> <br />
    <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />";
    hint parseText _message;
    onMapSingleClick {
        pl_bounding_cords = _pos;
        pl_mapClicked = true;
        pl_bounding_mode = "move";
        // if (_alt) then {pl_bounding_mode = "attack"};
        if (_shift) then {pl_cancel_strike = true};
        hintSilent "";
        onMapSingleClick "";
    };
    while {!pl_mapClicked} do {sleep 0.2;};
    pl_mapClicked = false;

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};
        
    _cords = pl_bounding_cords;

    // if (visibleMap) then {
    //     _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    // }
    // else
    // {
    //     _cords = screenToWorld [0.5,0.5];
    // };
    
    _moveDir = (leader _group) getDir _cords;

    [_group] call pl_reset;
    sleep 0.2;

    if (pl_enable_beep_sound) then {playSound "beep"};
    
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\help_ca.paa";
    // _group setVariable ["onTask", true];
    _group setVariable ["pl_is_bounding", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    _wp = _group addWaypoint [_cords, 0];
    pl_draw_planed_task_array pushBack [_wp, _icon];
    // pl_bounding_draw_array pushBack [_group, _cords];

    _groupLen = (count (units _group)) - 1;

    _units = (units _group);
    _team1 = [];
    _team2 = [];

    // _tactic = pl_bounding_mode;

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
        _unit disableAI "AUTOCOMBAT";
        _unit doMove _movePos;
        // _unit disableAI "TARGET";
        // _unit disableAI "AUTOTARGET";
        // _unit disableAI "SUPPRESSION";
        // _unit disableAI "COVER";
        _unit setDestination [_movePos, "FORMATION PLANNED", false];
        _reachable = [_unit, _movePos, 20] call pl_not_reachable_escape;
        sleep 0.5;

        waitUntil {(unitReady _unit) or ((_unit distance2D _movePos) < 1.5) or (!alive _unit) or ( _unit getVariable["pl_wia", false]) or !((group _unit) getVariable ["pl_is_bounding", true])};
        _unit enableAI "AUTOCOMBAT";
        if ((group _unit) getVariable ["pl_is_bounding", true]) then {
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

    waitUntil {sleep 0.1; (({_x getVariable ["pl_bounding_set", false]} count _units) == (count _units)) or !(_group getVariable ["pl_is_bounding", true])};

    sleep 1.5;

    _get_move_range_fn = {
        params ["_team", "_wp"];
        _return = {
            if ((_x distance2D (waypointPosition _wp)) < 70) exitWith {30};
            60
        } forEach _team;
        // player sideChat str _return;
        _return
    };

    _moveRange = 30;
    while {_group getVariable ["pl_is_bounding", true]} do {
        _moveDir = (leader _group) getDir (waypointPosition _wp);
        _movePos = [_moveRange*(sin _moveDir), _moveRange*(cos _moveDir), 0] vectorAdd (getPos (_team1#0));
        _offSet = 0;
        (_team1#0) groupRadio "SentConfirmMove";
        {
            if (_x getVariable ["pl_wia", false] or !alive _x) then {_team1 = _team1 - [_x]};
            _x setUnitPos "UP";
            _x enableAI "PATH";
            _pos = [_offSet*(sin (_moveDir - 90)), _offSet*(cos (_moveDir - 90)), 0] vectorAdd _movePos;
            _pos = _pos findEmptyPosition [0, 15, typeOf _x];
            _offSet = _offSet + 6;
            [_x, _pos, _cords, _moveDir, 1.5, "pl_bounding_set"] spawn pl_bounding_move;
        } forEach _team1;
        waitUntil {sleep 0.1; !(_group getVariable ["pl_is_bounding", true]) or (({!(_x getVariable ["pl_bounding_set", false])} count _team1) < 1)};

        if !(_group getVariable ["pl_is_bounding", true]) exitWith {};
        (_team1#0) groupRadio "sentCovering";
        sleep 2;
        _moveRange = [(_team1 + _team2), _wp] call _get_move_range_fn;
        _movePos = [_moveRange*(sin _moveDir), _moveRange*(cos _moveDir), 0] vectorAdd (getPos (_team2#0));
        _offSet = 0;
        (_team2#0) groupRadio "SentConfirmMove";
        {
            if (_x getVariable ["pl_wia", false] or !alive _x) then {_team2 = _team2 - [_x]};
            _x setUnitPos "UP";
            _x enableAI "PATH";
            _pos = [_offSet*(sin (_moveDir + 90)), _offSet*(cos (_moveDir + 90)), 0] vectorAdd _movePos;
            _pos = _pos findEmptyPosition [0, 15, typeOf _x];
            _offSet = _offSet + 6;
            [_x, _pos, _cords, _moveDir, 1.5, "pl_bounding_set"] spawn pl_bounding_move;
        } forEach _team2;
        waitUntil {sleep 0.1; !(_group getVariable ["pl_is_bounding", true]) or (({!(_x getVariable ["pl_bounding_set", false])} count _team2) < 1)};

        if (!(_group getVariable ["pl_is_bounding", true]) or _moveRange == 30) exitWith {};
        (_team2#0) groupRadio "sentCovering";
        sleep 2;
    };

    // pl_bounding_draw_array = pl_bounding_draw_array - [[_group, _cords]];

    // [_group] call pl_reset;
    _wp setWaypointPosition [getPos (leader _group), 0];
    _group setVariable ["pl_is_bounding", nil];
    _group setVariable ["setSpecial", false];
    {
        _x setVariable ["pl_bounding_set", nil];
        _x setUnitPos "Auto";
        _x enableAI "PATH";
        _x doFollow (leader _group);
    } forEach _units;

    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    // if !(_group getVariable ["onTask", true]) exitWith {};

    // if (_tactic isEqualTo "attack") then { 
    //     [_group, _cords] spawn pl_attack
    // }
    // else
    // {
    // [_group] spawn pl_take_cover; 
    // };
};

pl_bounding_move = {
    params ["_unit", "_pos", "_cords", "_moveDir", ["_atkRange", 1.5], ["_waitVar", "onTask"]];
    _unit disableAI "AUTOCOMBAT";
    _unit disableAI "SUPPRESSION";
    _unit disableAI "COVER";
    _unit disableAI "TARGET";
    _unit disableAI "AUTOTARGET";
    // _unit disableAI "FSM";
    _unit setVariable ["pl_bounding_set", false];
    _unit doMove _pos;
    _unit setDestination [_pos, "FORMATION PLANNED", false];
    _reachable = [_unit, _pos, 20] call pl_not_reachable_escape;
    sleep 0.5;

    waitUntil {!(alive _unit) or (unitReady _unit) or ((_unit distance2D _pos) < _atkRange) or (_unit getVariable["pl_wia", false] or !((group _unit) getVariable [_waitVar, true]))};

    _unit enableAI "AUTOCOMBAT";
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    _unit enableAI "SUPPRESSION";
    _unit enableAI "COVER";
    _unit enableAI "FSM";
    _unit setUnitPos "UP";
    sleep 0.1;
    if ((group _unit) getVariable [_waitVar, true] and (_atkRange == 1.5)) then {
        _unit setVariable ["pl_bounding_set", true];
        [_unit, _cords, _moveDir, 3, false] spawn pl_find_cover;
    };
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
    _markerName setMarkerColor "colorYellow";
    _markerName setMarkerAlpha 0.2;
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
            if (pl_sweep_area_size >= 80) then {pl_sweep_area_size = 80};
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

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false])};

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
    _arrowMarkerName setMarkerType "mil_Arrow";
    // _arrowMarkerName setMarkerAlpha 0.8;
    // _arrowMarkerName setMarkerSize [1.3, 1.3];
    _arrowMarkerName setMarkerDir _arrowDir;
    _arrowText = "";
    _arrowColor = "colorYellow";
    switch (_attackMode) do { 
        case "tactical" : {_arrowText = "CQB"; _arrowColor = "colorGreen"}; 
        case "fast" : {_arrowText = "FST"; _arrowColor = "colorRed"}; 
        default {_arrowText = ""; _arrowColor = "colorYellow"}; 
    };
    _arrowMarkerName setMarkerColor _arrowColor;
    _arrowMarkerName setMarkerText _arrowText;

    [_group] call pl_reset;
    sleep 0.2;
    
    if (pl_enable_beep_sound) then {playSound "beep"};

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
                // waitUntil {!(alive _unit) or (unitReady _unit) or (_unit getVariable["pl_wia", false] or !((group _unit) getVariable ["onTask", true]))};
                // doStop _unit;
            };
        } forEach (units _group);
    };


    _area = pl_sweep_area_size;
    
    // waitUntil {(((leader _group) distance _cords) < (pl_sweep_area_size + 10)) or !(_group getVariable ["onTask", true])};

    _vics = nearestObjects [_cords, ["Car", "Truck", "Tank"], _area, true];

    private _atkTriggerDistance = 10;
    if ((count _vics) > 0) then {
        _atkTriggerDistance = 40; 
    };

    waitUntil {(({(_x distance _cords) < (_area + _atkTriggerDistance)} count (units _group)) > 0) or !(_group getVariable ["onTask", true])};

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


    {
        _targets pushBack _x;
    } forEach (_allMen select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

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
        waitUntil {!(_group getVariable ["onTask", true]) or (time > _time)};
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
            [_x, _group, _area, _cords] spawn {
                params ["_unit", "_group", "_area", "_cords"];
                private ["_movePos", "_target"];

                while {(count (missionNamespace getVariable format ["targets_%1", _group])) > 0} do {
                    if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                        _target = {
                            if !(_x isKindOf "Man") exitWith {_x},;
                            objNull
                        } forEach (missionNamespace getVariable format ["targets_%1", _group]);
                        if !(isNull _target) then {
                            private _posArray = [];
                            _targetPos = getPosASL _target;
                            for "_i" from 0 to 360 step 2 do {
                                _p = [_area * (sin _i), _area * (cos _i), 0] vectorAdd _targetPos;

                                _p = ASLToATL _p;
                                _p = [_p#0, _p#1, 1.5];
                                _p = ATLToASL _p;
                                // _helper1 = createVehicle ["Sign_Sphere25cm_F", _p, [], 0, "none"];
                                // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                                // _helper1 setposASL _p;

                                _vis = lineIntersectsSurfaces [_p, aimPos _target, _target, vehicle _target, true, 1, "FIRE"];
                                if (_vis isEqualTo []) then {
                                    // _m = createMarker [str (random 1), _p];
                                    // _m setMarkerType "mil_dot";
                                    _posArray pushBack _p;
                                };
                            };
                            _unit setUnitTrait ["camouflageCoef", 0.2, true];
                            _movePos = ([_posArray, [], {_target distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;
                            _unit doMove _movePos;
                            _unit disableAi "AIMINGERROR";
                            sleep 1;

                            waitUntil {unitReady _unit or !alive _unit or !alive _target or (count (crew _target) == 0) or !((group _unit) getVariable ["onTask", true])};

                            _unit reveal [_target, 4];
                            _unit doTarget _target;
                            _unit doFire _target;
                            while {(alive _unit) and (alive _target) and (count (crew _target) > 0) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true]) and !((secondaryWeaponMagazine _unit) isEqualTo [])} do {
                                sleep 0.1;
                            };
                            _unit setUnitTrait ["camouflageCoef", 1, true];
                            _unit enableAi "AIMINGERROR";
                            if (!alive _target or (count (crew _target) <= 0)) then {(missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target)};
                        };
                    };

                    _target = selectRandom (missionNamespace getVariable format ["targets_%1", _group]);
                    if !(isNil "_target") then {
                        if (alive _target and (_target isKindOf "Man")) then {
                            _pos = getPosATL _target;
                            _movePos = _pos vectorAdd [0.5 - (random 1), 0.5 - (random 1), 0];
                            _unit limitSpeed 15;
                            _unit doMove _movePos;
                            _unit setDestination [_movePos, "FORMATION PLANNED", false];
                            _reachable = [_unit, _movePos, 20] call pl_not_reachable_escape;
                            _unreachableTimeOut = time + 35;

                            while {(alive _unit) and (alive _target) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true]) and _reachable and (_unreachableTimeOut >= time)} do {
                                // _enemy = _unit findNearestEnemy _unit;
                                // if ((_unit distance2D _enemy) < 7) then {
                                //     _unit doTarget _enemy;
                                //     _unit doFire _enemy;
                                // };
                                sleep 0.5;
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
        } forEach (units _group);

        waitUntil {time > _time or !(_group getVariable ["onTask", true]) or ({!alive _x} count (missionNamespace getVariable format ["targets_%1", _group]) == count (missionNamespace getVariable format ["targets_%1", _group]))};
    };


    deleteMarker _markerName;
    deleteMarker _arrowMarkerName;
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
    sleep 1;
    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
        sleep 1;
        if (pl_enable_beep_sound) then {playSound "beep"};
        if (pl_enable_chat_radio) then ((leader _group) sideChat format ["%1 Assault complete", (groupId _group)]);
        if (pl_enable_map_radio) then ([_group, "...Assault Complete!", 20] call pl_map_radio_callout);
        if (_tacticalAtk or _fastAtk) then {
            {
                [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
            } forEach (units _group);
        };
    };
};

pl_field_of_fire = {
    private ["_markerName", "_cords", "_targets", "_pos", "_units", "_leader", "_area"];

    _group = (hcSelected player) select 0;

    if ((_group getVariable ["pl_fof_set", false])) exitWith {_group setVariable ["pl_fof_set", false]};

    pl_suppress_area_size = 100;
    pl_supppress_continuous = false;

    _markerName = format ["%1fof%2", _group, random 1];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor "colorORANGE";
    _markerName setMarkerAlpha 0.2;
    _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];

    private _rangelimiter = 300;
    if (vehicle (leader _group) != (leader _group)) then { _rangelimiter = 700};

    _markerBorderName = str (random 2);
    createMarker [_markerBorderName, getPos (leader _group)];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorORANGE";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    if (visibleMap) then {
        _message = "Select Position <br /><br />
            <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>30 Seconds</t> <br />
            <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>Cancel</t> <br />";
        hint parseText _message;
        onMapSingleClick {
            pl_suppress_cords = _pos;
            if (_shift) then {pl_cancel_strike = true};
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
            if (inputAction "MoveForward" > 0) then {pl_suppress_area_size = pl_suppress_area_size + 10; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_suppress_area_size = pl_suppress_area_size - 10; sleep 0.05};
            _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];
            if (pl_suppress_area_size >= 180) then {pl_suppress_area_size = 180};
            if (pl_suppress_area_size <= 20) then {pl_suppress_area_size = 20};
        };

        player enableSimulation true;

        pl_mapClicked = false;
        _cords = getMarkerPos _markerName;
        _area = pl_suppress_area_size;
        deleteMarker _markerBorderName;
        // _markerName setMarkerPos _cords; 
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};

    _group setVariable ["pl_fof_set", true];
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\rifle_ca.paa";
    _leader = leader _group;
    pl_draw_suppression_array pushBack [_cords, _leader, false, _icon];

    while {_group getVariable ["pl_fof_set", false]} do {
        _allMen = nearestObjects [_cords, ["Man"], _area, true];
        private _infTargets = [];
        {
            _infTargets pushBack _x;
        } forEach (_allMen select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

        _allVics = nearestObjects [_cords, ["Car", "Truck", "Tank"], _area, true];
        private _vicTargets = [];
        {
            _vicTargets pushBack _x;
        } forEach (_allVics select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

        if (vehicle (leader _group) != (leader _group)) then {
            _vic = vehicle (leader _group);
            private _target = objNull;
            if !(_vicTargets isEqualTo []) then {
                _vicTargets = [_vicTargets, [], {_x distance2D _vic}, "ASCEND"] call BIS_fnc_sortBy;
                _target = _vicTargets#0;
            }
            else
            {
                if !(_infTargets isEqualTo []) then {
                    _infTargets = [_infTargets, [], {_x distance2D _vic}, "ASCEND"] call BIS_fnc_sortBy;
                    _target =_infTargets#0;
                };
            };
            if !(isNull _target) then {
                {
                    _x reveal [_target, 3];
                    _x doTarget _target;
                    _x doFire _target;
                } forEach (units _group);
            };
        }
        else
        {
            {
                private _target = objNull;
                _unit = _x;
                if !(_infTargets isEqualTo []) then {
                    _infTargets = [_infTargets, [], {_x distance2D _unit}, "ASCEND"] call BIS_fnc_sortBy;
                    _target =_infTargets#([0, 3] call BIS_fnc_randomInt);
                };
                if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                    if !(_vicTargets isEqualTo []) then {
                        _vicTargets = [_vicTargets, [], {_x distance2D _unit}, "ASCEND"] call BIS_fnc_sortBy;
                        _target = _vicTargets#0;
                    }
                };
                if !(isNull _target) then {
                    if (_target distance2D _unit <= 450) then {
                        if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                            _pos = getPosASL _target;
                            _vis = lineIntersectsSurfaces [eyePos _unit, _pos, _unit, vehicle _unit, true, 1];
                            if !(_vis isEqualTo []) then {
                                _pos = (_vis select 0) select 0;
                            };
                            _unit doSuppressiveFire _pos;
                        }
                        else
                        {
                            _unit reveal [_target, 4];
                            if (random 1 >= 0.3) then {
                                _unit doTarget _target;
                                _unit doFire _target;
                            } 
                            else
                            {
                                _unit doSuppressiveFire _target;
                            };
                        };
                    };
                };
            } forEach (units _group);
        };    

        _time = time + 10;
        waitUntil {time >= _time or !(_group getVariable ["pl_fof_set", false])};
    };

    {
      _x doWatch objNull;
    } forEach (units _group);

    deleteMarker _markerName;

    pl_draw_suppression_array = pl_draw_suppression_array - [[_cords, _leader, false, _icon]];

};



