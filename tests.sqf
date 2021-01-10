pl_not_reachable_escape = {
    params ["_unit", "_pos", "_area"];

    sleep 2;

    if ((currentCommand _unit) isEqualTo "MOVE" and (speed _unit) == 0) exitWith {
        _movePos = [[[_pos, _area * 1.1]],["water"]] call BIS_fnc_randomPos;
        _movePos = _movePos findEmptyPosition [0, 10, typeOf _unit];
        doStop _unit;
        _unit doMove _movePos;
        _unit setDestination [_movePos, "LEADER PLANNED", true];
        false
    };
    true
};


pl_assault_position = {
    params ["_group", ["_taskPlanWp", []]];
    private ["_cords", "_limiter", "_targets", "_markerName", "_wp", "_icon", "_formation", "_attackMode", "_fastAtk", "_tacticalAtk"];

    pl_sweep_area_size = 35;

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

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
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>TACTICAL</t> <br />
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
        while {!pl_mapClicked} do {
            // sleep 0.1;
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerName setMarkerPos _mPos;
            if (inputAction "MoveForward" > 0) then {pl_sweep_area_size = pl_sweep_area_size + 5; sleep 0.1};
            if (inputAction "MoveBack" > 0) then {pl_sweep_area_size = pl_sweep_area_size - 5; sleep 0.1};
            _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
            if (pl_sweep_area_size >= 80) then {pl_sweep_area_size = 80};
            if (pl_sweep_area_size <= 5) then {pl_sweep_area_size = 5};

        };
        pl_mapClicked = false;
        _cords = pl_sweep_cords;
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

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11) or !(_group getVariable ["pl_task_planed", false])};

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
        case "tactical" : {_arrowText = "T"; _arrowColor = "colorGreen"}; 
        case "fast" : {_arrowText = "F"; _arrowColor = "colorRed"}; 
        default {_arrowText = ""; _arrowColor = "colorYellow"}; 
    };
    _arrowMarkerName setMarkerColor _arrowColor;
    _arrowMarkerName setMarkerText _arrowText;

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

    _fastAtk = false;
    _tacticalAtk = false;
    switch (_attackMode) do { 
        case "normal" : {
            (leader _group) limitSpeed 12;
            {
                _x disableAI "AUTOCOMBAT";
                // _x disableAI "FSM";
            } forEach (units _group);
            // (leader _group) setDestination [_cords, "LEADER DIRECT", true];
        }; 
        case "tactical" : {_tacticalAtk = true;}; 
        case "fast" : {_fastAtk = true; _group setSpeedMode "FULL";};
        default {leader _group limitSpeed 12;}; 
    };

    _formation = formation _group;
    _group setFormation "LINE";
    _group setBehaviour "AWARE";
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
    waitUntil {(({(_x distance _cords) < (_area + 10)} count (units _group)) > 0) or !(_group getVariable ["onTask", true])};

    // leader _group limitSpeed 200;
    // _group setSpeedMode "NORMAL";

    if (!(_group getVariable ["onTask", true])) exitWith {
        deleteMarker _markerName;
        deleteMarker _arrowMarkerName;
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

        {
            _x enableAI "AUTOCOMBAT";
            _x enableAI "FSM";
            _x forceSpeed 12;
            [_x, _group] spawn {
                params ["_unit", "_group"];
                private ["_movePos", "_target"];

                while {(count (missionNamespace getVariable format ["targets_%1", _group])) > 0} do {
                    _target = selectRandom (missionNamespace getVariable format ["targets_%1", _group]);
                    if (alive _target) then {
                        _pos = getPosATL _target;
                        _movePos = _pos vectorAdd [0.5 - random 1, 0.5 - random 1, 0];
                        _unit limitSpeed 15;
                        _unit doMove _movePos;
                        _unit setDestination [_movePos, "FORMATION PLANNED", false];
                        _reachable = [_unit, _movePos, 20] call pl_not_reachable_escape;


                        while {(alive _unit) and (alive _target) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true]) and _reachable} do {
                            // _enemy = _unit findNearestEnemy _unit;
                            // if ((_unit distance2D _enemy) < 7) then {
                            //     _unit doTarget _enemy;
                            //     _unit doFire _enemy;
                            // };
                            sleep 0.5;
                        };
                        if (!alive  _target) then {(missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target)};
                    };
                    if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};
                };
            };
        } forEach (units _group);

        waitUntil {!(_group getVariable ["onTask", true]) or ({!alive _x} count (missionNamespace getVariable format ["targets_%1", _group]) == count (missionNamespace getVariable format ["targets_%1", _group]))};
    };


    deleteMarker _markerName;
    deleteMarker _arrowMarkerName;
    missionNamespace setVariable [format ["targets_%1", _group], nil];
    _group setFormation _formation;

    // remove Icon form wp
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    {
        _x setVariable ["pl_damage_reduction", false];
        _x limitSpeed 5000;
        _x forceSpeed -1;
    } forEach (units _group);
    _group setCombatMode "YELLOW";
    _group setVariable ["pl_combat_mode", false];
    sleep 1;
    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
        playsound "beep";
        (leader _group) sideChat format ["%1 Assault complete", (groupId _group)];
        if (_tacticalAtk or _fastAtk) then {
            {
                [_x, getPos _x, getDir _x, 15, true] spawn pl_find_cover;
            } forEach (units _group);
        };
    };
};