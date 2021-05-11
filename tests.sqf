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
            if (inputAction "MoveForward" > 0) then {pl_suppress_area_size = pl_suppress_area_size + 5; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_suppress_area_size = pl_suppress_area_size - 5; sleep 0.05};
            _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];
            if (pl_suppress_area_size >= 180) then {pl_suppress_area_size = 180};
            if (pl_suppress_area_size <= 5) then {pl_suppress_area_size = 5};
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

    deleteMarker _markerName;

    pl_draw_suppression_array = pl_draw_suppression_array - [[_cords, _leader, false, _icon]];

};