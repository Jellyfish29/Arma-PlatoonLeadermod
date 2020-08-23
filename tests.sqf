pl_get_assault_speed = {
    params ["_unit", "_target"];

    private _distance = _unit distance2d _target;
    if (_distance > 20) exitWith {-1};
    if (_distance > 15) exitWith {3};
    if (_distance > 4) exitWith {2};
    1
};


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

        {
            _x enableAI "AUTOCOMBAT";
            _x forceSpeed 12;
            [_x, _targets] spawn {
                params ["_unit", "_targets"];

                private ["_markerName"];
                private _currentTarget = -1;
                while {(count _targets) > 0} do {
                    private _target = ([_targets, [], {_x distance2D _unit}, "ASCEND"] call BIS_fnc_sortBy) select 0;
                    if (isNil "_target") exitWith {};
                    if (alive _target) then {
                        // _unit reveal [_target, 3];
                        _pos = getPosATL _target;
                        // debug
                        // _markerName = createMarker [str _unit, _pos];
                        // _markerName setMarkerType "mil_dot";
                        // _markerName setMarkerText str _unit;
                        // _markerName setMarkerPos (getPos _target);

                        _unit disableAI "AUTOCOMBAT";
                        _unit disableAI "TARGET";
                        _unit disableAI "AUTOTARGET";

                        sleep 0.2;
                        _unit doMove _pos;
                        _unit moveTo _pos;
                        while {(alive _unit) and (alive _target) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true])} do {
                            _enemy = _unit findNearestEnemy _unit;
                            // _unit forceSpeed ([_unit, _enemy] call pl_get_assault_speed);
                            if ((_unit distance2D _enemy) < 7) then {
                                _unit doTarget _enemy;
                                _unit doFire _enemy;
                            };
                        };
                        doStop _unit;
                        if (!alive  _target) then {_targets deleteAt (_targets find _target)};
                    };
                    // waitUntil {(!alive _unit) or (!alive _target) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])};
                    // deleteMarker _markerName;
                    if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};
                };
                _unit enableAI "AUTOCOMBAT";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                _unit forceSpeed -1;
                // _unit sideChat "finished";
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