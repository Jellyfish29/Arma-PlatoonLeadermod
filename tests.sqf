pl_suppression_min_distance = 5;

pl_get_suppress_target_pos = {
    params ["_initialTargetPos", "_unit"];

    private _vis = lineIntersectsSurfaces [eyePos _unit, _initialTargetPos, _unit, vehicle _unit, true, 1, "FIRE"];
    private _supDistance = _unit distance2D _initialTargetPos;
    // if no surface intersection return initial pos
    private _targetPos = _initialTargetPos;
    private _allHelpers = [];

    // surface intersection
    if !(_vis isEqualTo []) then {
        _targetPos = (_vis select 0) select 0;

        _helper1 = createVehicle ["Sign_Sphere25cm_F", _targetpos, [], 0, "none"];
        _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
        _helper1 setposASL _targetpos;
        _allHelpers pushback _helper1;

        // intersection with terrain
        if (isNull (_vis#0#2)) then {

            // increase targetpos hight by 0.2 40 times and check again;
            for "_i" from 0 to (_supDistance * 0.2) step (_supDistance * 0.01) do {
                _vis = lineIntersectsSurfaces [eyePos _unit, [_initialTargetPos#0, _initialTargetPos#1, (_initialTargetPos#2) + _i], _unit, vehicle _unit, true, 1, "VIEW"];
                if (_vis isEqualTo []) then {
                    _targetPos = [_initialTargetPos#0, _initialTargetPos#1, (_initialTargetPos#2) + _i];
                    break;
                } else {
                    if !(isNull (_vis#0#2)) then {
                        _targetPos = _vis#0#0;
                        break;
                    };
                    _helper3 = createVehicle ["Sign_Sphere25cm_F", (_vis#0#0), [], 0, "none"];
                    _helper3 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                    _helper3 setposASL (_vis#0#0);
                    _allHelpers pushback _helper3;
                };

                _helper4 = createVehicle ["Sign_Sphere25cm_F", [_initialTargetPos#0, _initialTargetPos#1, (_initialTargetPos#2) + _i], [], 0, "none"];
                _helper4 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                _helper4 setposASL (_vis#0#0);
                _allHelpers pushback _helper4;
            };

            _helper2 = createVehicle ["Sign_Sphere25cm_F", _targetpos, [], 0, "none"];
            _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];
            _helper2 setposASL _targetpos;
            _allHelpers pushback _helper2;

        } else {
            // if surface is not terrain return surface pos
            _targetPos = _vis#0#0;
        };
    };

    [_allHelpers] spawn {
        sleep 30;

        {
            deleteVehicle _x;
        } forEach (_this#0);

    };

    _targetPos
};


pl_suppressive_fire_position = {
    params [["_group", (hcSelected player) select 0], ["_sfpPos", []], ["_cords", []]];
    private ["_markerName", "_targets", "_pos", "_units", "_leader", "_area", "_mPos", "_markerPosName", "_leaderPos"];

    // _group = (hcSelected player) select 0;
    _group setVariable ["pl_is_task_selected", true];

    // if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0 and (_group getVariable ["pl_is_suppressing", false])) exitWith {_group setVariable ["pl_is_suppressing", false]};

    // if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0) exitWith {};

    if ((_group getVariable ["pl_is_suppressing", false])) exitWith {_group setVariable ["pl_is_suppressing", false]};

    pl_suppress_area_size = 25;

    _markerName = format ["%1suppress%2", _group, random 1];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor "colorOrange";
    _markerName setMarkerAlpha 0.2;
    _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];

    if (_cords isEqualTo []) then {

        if (visibleMap or !(isNull findDisplay 2000)) then {
            _leaderPos = getPos (leader _group);
            if !(_sfpPos isEqualTo []) then {
                _leaderPos = _sfpPos;
            };
            private _rangelimiter = 1500;
            if (vehicle (leader _group) != (leader _group)) then { _rangelimiter = 2000};

            _markerBorderName = str (random 2);
            createMarker [_markerBorderName, _leaderPos];
            _markerBorderName setMarkerShape "ELLIPSE";
            _markerBorderName setMarkerBrush "Border";
            _markerBorderName setMarkerColor "colorOrange";
            _markerBorderName setMarkerAlpha 0.8;
            _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];
            
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

            if !(_sfpPos isEqualTo []) then {
                pl_show_watchpos_selector = true;
            };

            while {!pl_mapClicked} do {
                // sleep 0.1;
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };
                if ((_mPos distance2D _leaderPos) <= _rangelimiter) then {
                    _markerName setMarkerPos _mPos;
                };
                // _markerName setMarkerPos _mPos;
                if (inputAction "MoveForward" > 0) then {pl_suppress_area_size = pl_suppress_area_size + 5; sleep 0.05};
                if (inputAction "MoveBack" > 0) then {pl_suppress_area_size = pl_suppress_area_size - 5; sleep 0.05};
                _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];
                if (pl_suppress_area_size >= 150) then {pl_suppress_area_size = 150};
                if (pl_suppress_area_size <= 10) then {pl_suppress_area_size = 10};
            };

            pl_show_watchpos_selector = false;

            player enableSimulation true;

            pl_mapClicked = false;
            _cords = getMarkerPos _markerName;
            _area = pl_suppress_area_size;
            deleteMarker _markerBorderName;
        }
        else
        {
            _cursorPosIndicator = createVehicle ["Sign_Circle_F", [-1000, -1000, 0], [], 0, "none"];
            _cursorPosIndicator2 = createVehicle ["Sign_Sphere25cm_F", [-1000, -1000, 0], [], 0, "none"];
            _cursorPosIndicator setObjectScale 1.5;

            _leader = leader _group;
            pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

            while {inputAction "Action" <= 0} do {
                _viewDistance = _cursorPosIndicator distance2D player;
                // _cursorPosIndicator setPosATL ([0,0,_viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
                _cursorPosIndicator setPosATL (screenToWorld [0.5,0.5]);
                _cursorPosIndicator2 setPosATL (screenToWorld [0.5,0.5]);
                _cursorPosIndicator2 setObjectScale (_viewDistance * 0.025);
                _cursorPosIndicator setDir (_leader getDir _cursorPosIndicator);

                if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

                sleep 0.025
            };

            pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

            deleteVehicle _cursorPosIndicator;
            deleteVehicle _cursorPosIndicator2;

            if (pl_cancel_strike) exitWith {};

            _cords = getPosATL _cursorPosIndicator;

            _area = pl_suppress_area_size;

            _markerName setMarkerPos _cords;
        };
    } else {
        _markerName setMarkerPos _cords;
        _area = pl_suppress_area_size;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; _group setVariable ["pl_is_task_selected", nil];};

    if !(_sfpPos isEqualTo []) then {

        pl_at_targets_indicator pushBack [_sfpPos, _cords];

        waitUntil {sleep 0.5; !(_group getVariable ["pl_task_planed", false])};

        sleep 2;
        if (vehicle (leader _group) == (leader _group)) then {

            waitUntil {(({_x getVariable ["pl_in_position", false]} count (units _group)) == count (units _group)) or !(_group getVariable ["onTask", false])};
            if !(_group getVariable ["onTask", false]) exitWith {pl_cancel_strike = true};
        } else {
            waitUntil {(_group getVariable ["pl_in_position", false]) or !(_group getVariable ["onTask", false])};
            if !(_group getVariable ["onTask", false]) exitWith {pl_cancel_strike = true};
        };
        pl_at_targets_indicator = pl_at_targets_indicator - [[_sfpPos, _cords]];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; _group setVariable ["pl_is_task_selected", nil];};

    if (_group getVariable ["pl_in_position", false]) then {
        _markerPosName = format ["defenceAreaDir%1", _group];
        _markerPosName setMarkerType "marker_sfp";
    } else {
        _markerPosName  = format ["afp%1", _group];
        createMarker [_markerPosName , getPos (vehicle (leader _group))];
        _markerPosName setMarkerDir ((leader _group) getDir _cords);
        _markerPosName  setMarkerType "marker_afp";
        _markerPosName  setMarkerColor pl_side_color;
    };   

    
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa";
    _leader = leader _group;
    pl_draw_suppression_array pushBack [_cords, _leader, false, _icon];
    [_group, "suppress", 1] call pl_voice_radio_answer;
    

    _group setVariable ["pl_is_suppressing", true];
    pl_suppression_poses pushback [_cords, _group];
    // check if enemy in Area
    // _allTargets = nearestObjects [_cords, ["Man", "Car", "Truck", "Tank"], _area, true];
    _getTargets = {
        params ["_cords", "_area"];
        private _targetsPos = [];
        private _allTargets = _cords nearEntities [["Man", "Car", "Truck", "Tank"], _area];
        {
            _targetsPos pushBack (getPosATL _x);
        } forEach (_allTargets select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

        // if no enemy target buildings;
        private _buildings = nearestObjects [_cords, ["house"], _area];
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
        private _return = ATLToASL (selectRandom _targetsPos);
        _return
    };

    private _units = (units _group);

    if (_group getVariable ["pl_inf_attached", false]) then {
        _vicGroup = _group getVariable ["pl_attached_vicGrp", grpNull];
        _units = _units + (units _vicGroup);
    };

    _vicTargets = _cords nearEntities [["Car", "Truck", "Tank"], _area] select {alive _x and (side _x) != playerSide and (_group knowsAbout _x) > 0};

    if (leader _group != vehicle (leader _group)) then {
        if (([vehicle (leader _group)] call pl_has_cannon )and (_vicTargets isEqualTo [])) then {
            [vehicle (leader _group)] call pl_load_he;
        };
    };

    private _allHelpers = [];

    {
        _x setVariable ["pl_current_unitPos", unitPos _x];

        if ((unitPos _x) isEqualto "Down") then {
            _x setUnitPos "Middle";
        };
    } forEach _units;

    sleep 0.3;

    while {(_group getVariable ["pl_is_suppressing", true]) and !(isNull _group)} do {
        {
            _unit = _x;
            if (_unit != (vehicle _unit) or (((primaryweapon _unit call BIS_fnc_itemtype) select 1) == "MachineGun") or (random 1) > 0) then {
                if (_unit != (vehicle _unit) and (_unit) == gunner (vehicle _unit)) then {
                    _vic = vehicle _unit;
                    _vicTargets = _cords nearEntities [["Car", "Truck", "Tank"], _area] select {alive _x and (side _x) != playerSide and (_group knowsAbout _x) > 0};

                    if (!(_vicTargets isEqualTo []) and ([_vic] call pl_has_cannon)) then {

                        _vicTargets = ([_vicTargets, [], {_x distance2D _vic}, "ASCEND"] call BIS_fnc_sortBy);
                        _weapon = [_vic] call pl_get_weapon;
                        _turretPath = _vic unitTurret _unit;

                        {
                            _vic doTarget _x;
                            _vic doFire _x;
                            _timeOut = time + 8;
                            waitUntil {sleep 0.1; !(_group getVariable ["pl_is_suppressing", false]) or ((_vic aimedAtTarget [_x, _weapon]) > 0.5 and ((weaponState [_vic, _turretPath, _weapon])#5 <= 0.2)) or time >= _timeOut};
                            if (_group getVariable ["pl_is_suppressing", true] and time < _timeOut) then {
                                [_vic , _weapon] call BIS_fnc_Fire;
                                // _fired = _vic fireAtTarget [_x, _weapon];
                                sleep 0.5;
                            }

                        } forEach _vicTargets;

                    };
                };


                _pos = [_cords, _area] call _getTargets;
                _targetPos = [_pos , _unit] call pl_get_suppress_target_pos;

                if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_unit, _targetPos] call pl_friendly_check)) then {

                    _unit doWatch _targetPos;
                    _unit doSuppressiveFire _targetPos;

                };
            };
        } forEach _units ;
        _time = time + 15;
        waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["pl_is_suppressing", false])};
        if ((([_group] call pl_get_ammo_group_state)#0) == "Red") exitWith {};

    };

    sleep 0.5;

    // waitUntil {sleep 0.5; (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) <= 0 and !(_group getVariable ["pl_is_suppressing", false])) or !alive (leader _group)};

    if (leader _group != vehicle (leader _group)) then {
        [vehicle (leader _group)] call pl_load_ap;
    };

    {
        _x setUnitPos (_x getVariable ["pl_current_unitPos", "Middle"]);
        _x setVariable ["pl_current_unitPos", nil];
    } forEach (units _group);

    {
      deleteVehicle _x;
    } forEach _allHelpers;

    pl_suppression_poses = pl_suppression_poses - [[_cords, _group]];
    deleteMarker _markerName;
    if (_group getVariable ["pl_in_position", false]) then {
        _markerPosName = format ["defenceAreaDir%1", _group];
        _markerPosName setMarkerType "marker_position";
    } else {
        deleteMarker _markerPosName;
    };

    pl_draw_suppression_array = pl_draw_suppression_array - [[_cords, _leader, false, _icon]];
};
