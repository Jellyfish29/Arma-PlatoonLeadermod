pl_suppressive_fire_position = {
    private ["_markerName", "_cords", "_targets", "_pos", "_units", "_leader"];

    _group = (hcSelected player) select 0;

    if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0 and (_group getVariable ["pl_is_suppressing", false])) exitWith {_group setVariable ["pl_is_suppressing", false]};

    if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0) exitWith {};


    pl_suppress_area_size = 25;
    pl_supppress_continuous = false;

    _markerName = format ["%1suppress%2", _group, random 1];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor "colorRED";
    _markerName setMarkerAlpha 0.2;
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
            _markerName setMarkerPos _mPos;
            if (inputAction "MoveForward" > 0) then {pl_suppress_area_size = pl_suppress_area_size + 5; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_suppress_area_size = pl_suppress_area_size - 5; sleep 0.05};
            _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];
            if (pl_suppress_area_size >= 80) then {pl_suppress_area_size = 80};
            if (pl_suppress_area_size <= 5) then {pl_suppress_area_size = 5};
        };

        player enableSimulation true;

        pl_mapClicked = false;
        _cords = pl_suppress_cords;
        _markerName setMarkerPos _cords; 
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
    _allTargets = nearestObjects [_cords, ["Man", "Car", "Truck", "Tank"], pl_suppress_area_size, true];
    {
        _targetsPos pushBack (getPosATL _x);
    } forEach (_allTargets select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

    // if no enemy target buildings;
    _buildings = nearestObjects [_cords, ["house"], pl_suppress_area_size];
    if !((count _buildings) == 0) then {
        {
            _bPos = [0,0,2] vectorAdd (getPosATL _x);
            _targetsPos pushBack _bPos;
        } forEach _buildings;
    };

    // add Random Possitions
    private _posAmount = 2;
    if (_targetsPos isEqualTo []) then {_posAmount = 6};
    for "_i" from 0 to _posAmount do {
        _rPos = [[[_cords, pl_suppress_area_size]], nil] call BIS_fnc_randomPos;
        _targetsPos pushBack _rPos;
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

    {
        if (_group getVariable ["pl_is_attacking", false]) then {
        };
        _unit = _x;
        _pos = selectRandom _targetsPos;
        _pos = ATLToASL _pos;
        _vis = lineIntersectsSurfaces [eyePos _unit, _pos, _unit, vehicle _unit, true, 1];

        if !(_vis isEqualTo []) then {
            _pos = (_vis select 0) select 0;
        };

        if ((_pos distance2D _unit) > 15 and !([_pos] call pl_friendly_check)) then {

            _unit doSuppressiveFire _pos;

            if (_continous) then {
                [_unit, _targetsPos, _group] spawn {
                    params ["_unit", "_targetsPos", "_group"];

                    while {(_group getVariable ["pl_is_suppressing", true])} do {

                        if !((currentCommand _unit) isEqualTo "Suppress") then {
                            _pos = selectRandom _targetsPos;
                            _pos = ATLToASL _pos;
                            _vis = lineIntersectsSurfaces [eyePos _unit, _pos, _unit, vehicle _unit, true, 1];
                            if !(_vis isEqualTo []) then {
                                _pos = (_vis select 0) select 0;
                            };
                            _unit doSuppressiveFire _pos;
                        };
                        sleep 1;
                    };
                };
            };
        };

    } forEach _units;

    sleep 2;

    waitUntil {(({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) <= 0 and !(_group getVariable ["pl_is_suppressing", false])) or !alive (leader _group)};

    deleteMarker _markerName;

    pl_draw_suppression_array = pl_draw_suppression_array - [[_cords, _leader, _continous, _icon]];
};