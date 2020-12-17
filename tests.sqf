pl_sweep_area = {
    params ["_group", ["_taskPlanWp", []]];
    private ["_cords", "_limiter", "_targets", "_markerName", "_wp", "_icon", "_formation", "_attackMode", "_fastAtk"];

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    _markerName = format ["%1sweeper", _group];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Vertical";
    _markerName setMarkerColor "colorYellow";
    _markerName setMarkerAlpha 0.5;
    _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
    if (visibleMap) then {
        _message = "Select Assault Location <br /><br />
            <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>TACTICAL</t> <br />
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>SLOW</t> <br />
            <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>FAST</t>";
        hint parseText _message;
        onMapSingleClick {
            pl_sweep_cords = _pos;
            // if (_shift) then {pl_cancel_strike = true};
            pl_attack_mode = "normal";
            if (_shift) then {pl_attack_mode = "slow"};
            if (_alt) then {pl_attack_mode = "fast"};
            pl_mapClicked = true;
            hintSilent "";
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {
            // sleep 0.1;
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerName setMarkerPos _mPos;
            if (inputAction "MoveForward" > 0) then {pl_sweep_area_size = pl_sweep_area_size + 5; sleep 0.2};
            if (inputAction "MoveBack" > 0) then {pl_sweep_area_size = pl_sweep_area_size - 5; sleep 0.2};
            _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
            if (pl_sweep_area_size >= 70) then {pl_sweep_area_size = 70};
            if (pl_sweep_area_size <= 10) then {pl_sweep_area_size = 10};

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

    // if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};

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
    switch (_attackMode) do { 
        case "normal" : {leader _group limitSpeed 12;}; 
        case "slow" : {_group setSpeedMode "LIMITED"}; 
        case "fast" : {_fastAtk = true; _group setSpeedMode "FULL";};
        default {leader _group limitSpeed 12;}; 
    };

    _formation = formation _group;
    _group setFormation "LINE";
    _group setBehaviour "AWARE";

    // fast attack setup
    if (_fastAtk) then {
        _atkDir = (leader _group) getDir _cords;
        {
            _pos = [[[_cords, 25]],[]] call BIS_fnc_randomPos;
            _x setUnitPos "UP";
            [_x, _pos, _cords, _atkDir, 45] spawn pl_bounding_move;
        } forEach (units _group);
    };

    
    waitUntil {sleep 0.1; (((leader _group) distance _cords) < (pl_sweep_area_size + 10)) or !(_group getVariable ["onTask", true])};

    leader _group limitSpeed 200;
    _group setSpeedMode "NORMAL";

    _targets = [];
    _allMen = _cords nearObjects ["Man", pl_sweep_area_size];
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
        missionNamespace setVariable [format ["targets_%1", _group], _targets];

        {
            _x enableAI "AUTOCOMBAT";
            _x forceSpeed 12;
            [_x, _group] spawn {
                params ["_unit", "_group"];
                private ["_movePos", "_target"];

                while {(count (missionNamespace getVariable format ["targets_%1", _group])) > 0} do {
                    _target = selectRandom (missionNamespace getVariable format ["targets_%1", _group]);
                    if (alive _target) then {
                        _pos = getPosATL _target;
                        _movePos = _pos vectorAdd [0.5 - random 1, 0.5 - random 1, 0];
                        _unit doMove _movePos;

                        while {(alive _unit) and (alive _target) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true])} do {
                            _enemy = _unit findNearestEnemy _unit;
                            if ((_unit distance2D _enemy) < 7) then {
                                _unit doTarget _enemy;
                                _unit doFire _enemy;
                            };
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
    missionNamespace setVariable [format ["targets_%1", _group], nil];
    _group setFormation _formation;

    // remove Icon form wp
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    {
        _x setVariable ["pl_damage_reduction", false];
    } forEach (units _group);
    sleep 1;
    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
        playsound "beep";
        (leader _group) sideChat format ["%1 Assault complete", (groupId _group)];
    };
};