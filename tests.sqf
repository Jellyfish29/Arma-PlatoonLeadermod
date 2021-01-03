pl_garrison_area_building = {
    params ["_group", ["_taskPlanWp", []]];
    private ["_watchDir", "_cords", "_watchPos", "_markerAreaName", "_markerDirName", "_buildings", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon"];

    _group = (hcSelected player) select 0;
    
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";

    _markerAreaName = format ["%1garrison%2", _group, random 2];
    createMarker [_markerAreaName, [0,0,0]];
    _markerAreaName setMarkerShape "ELLIPSE";
    _markerAreaName setMarkerBrush "SolidBorder";
    _markerAreaName setMarkerColor "colorYellow";
    _markerAreaName setMarkerAlpha 0.15;
    _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];

    if (visibleMap) then {
        hintSilent "";

        pl_garrison_area_size = 15;
        pl_360_area = false;
        _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br /> <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
        hint parseText _message;

        onMapSingleClick {
            pl_defence_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerAreaName setMarkerPos _mPos;
            if (inputAction "MoveForward" > 0) then {pl_garrison_area_size = pl_garrison_area_size + 5; sleep 0.1};
            if (inputAction "MoveBack" > 0) then {pl_garrison_area_size = pl_garrison_area_size - 5; sleep 0.1};
            _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];
            if (pl_garrison_area_size >= 55) then {pl_garrison_area_size = 55};
            if (pl_garrison_area_size <= 10) then {pl_garrison_area_size = 10};
        };

        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerAreaName};
        _message = "Select Defence FACING <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
        <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>360° Security</t>";
        hint parseText _message;

        sleep 0.1;
        _cords = pl_defence_cords;
        _markerDirName = format ["defenceAreaDir%1%2", _group, random 2];
        createMarker [_markerDirName, _cords];
        _markerDirName setMarkerPos _cords;
        _markerDirName setMarkerType "marker_afp";
        _markerDirName setMarkerColor "colorBLUFOR";

        onMapSingleClick {
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            if (_alt) then {pl_360_area = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _markerDirName setMarkerDir _watchDir;
        };
        pl_mapClicked = false;
        if (pl_360_area) then {
            _markerDirName setMarkerType "mil_circle";
            _markerDirName setMarkerSize [0.5, 0.5];
        };

        if (count _taskPlanWp != 0) then {

            // add Arrow indicator
            pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

            waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11) or !(_group getVariable ["pl_task_planed", false])};

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true};
            _group setVariable ["pl_task_planed", false];
        };

        // if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
        _watchDir = ((leader _group) getDir player) - 180;
        pl_garrison_area_size = 10;
        pl_360_area = true;
        _markerDirName = format ["defenceArea%1", _group];
        createMarker [_markerDirName, _cords];
        _markerDirName setMarkerType "mil_circle";
        _markerDirName setMarkerColor "colorBLUFOR";
        _markerAreaName setMarkerPos _cords;
        _markerDirName setMarkerSize [0.5, 0.5];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

    _buildings = nearestObjects [_cords, ["house"], pl_garrison_area_size];
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 2) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    // if ((count _validBuildings == 0)) exitWith {hint "No buildings in Area!"; deleteMarker _markerAreaName; deleteMarker _markerDirName;};

    [_group] call pl_reset;

    sleep 0.2;

    playSound "beep";

    if (pl_360_area) then {_icon = "\A3\ui_f\data\map\markers\military\circle_CA.paa"};
    if ((count _validBuildings) > 0) then {_icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _medic = {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) exitWith {_x};
    } forEach (units _group); 


    _validPos = [];
    _allPos = [];
    {
        _building = _x;
        pl_draw_building_array pushBack [_group, _building];
        _bPos = [_building] call BIS_fnc_buildingPositions;
        {
            _allPos pushBack _x;
            _watchPos = [10*(sin _watchDir), 10*(cos _watchDir), 1.7] vectorAdd _x;
            _standingPos = [0, 0, 1.7] vectorAdd _x;
            _standingPos = ATLToASL _standingPos;
            _watchPos = ATLToASL _watchPos;

            // _helper = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
            // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
            // _helper setposASL _standingPos;

            _cansee = [objNull, "VIEW"] checkVisibility [_standingPos, _watchPos];
            if (_cansee == 1) then {
                _validPos pushBack _x;
            };
        } forEach _bPos;
    } forEach _validBuildings;


    // {
    //     _helper = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
    //     _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
    //     _helper setposATL _x;
    // } forEach _validPos;

    _watchPos = [500*(sin _watchDir), 500*(cos _watchDir), 0] vectorAdd _cords;

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _units = units _group;
    _posOffsetStep = pl_garrison_area_size / (count _units);
    private _posOffset = 0 + _posOffsetStep;

    for "_i" from 0 to (count _units) - 1 step 1 do {
        private _cover = false;
        private _covers = nearestTerrainObjects [_cords, pl_valid_covers, pl_garrison_area_size, true, true];
        // private _blacklist = nearestTerrainObjects [_cords, [], (pl_garrison_area_size - 8), true, true];
        // _covers = _covers - _blacklist;
        _covers = [_covers, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        // move to optimal Pos first
        if (_i < (count _validPos)) then {
            _pos = _validPos#_i;
            _unit = _units#_i;
        }
        else
        {
            // move to not optimal Pos
            if (_i < (count _allPos)) then {
                _pos = _allPos#_i;
                _unit = _units#_i;
            }
            // no building pos move to cover
            else
            {
                _cover = true;
                _unit = _units#_i;
                // move to avaible cover
                if ((_i < count _covers) and !(pl_360_area)) then {
                    _pos = getPos (_covers#_i);
                    if (_i == (count _units) - 1) then {
                        _pos = getPos (_covers#((count _covers) - 1));
                        _watchDir = _watchDir - 180;
                    };
                }
                else
                {
                    // if 360 Option move to 360 Positions
                    if (pl_360_area) then {
                        _diff = 360/ (count _units);
                        _degree = 1 + _i*_diff;
                        _pos = [pl_garrison_area_size*(sin _degree), pl_garrison_area_size*(cos _degree), 0] vectorAdd _cords;
                        _watchDir = _degree;
                    }
                    // if no more covers avaible move to left or right side of best cover
                    else
                    {
                        _coverPos = _cords;
                        if ((count _covers) > 0) then {_coverPos = getPos (_covers#0)};
                        _dirOffset = 90;
                        if (_i % 2 == 0) then {_dirOffset = -90};
                        _pos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _coverPos;
                        _posOffset = _posOffset + _posOffsetStep;
                    };
                };
            };
        };
        _pos = ATLToASL _pos;
        private _unitPos = "UP";
        _checkPos = [7*(sin _watchDir), 7*(cos _watchDir), 1.7] vectorAdd _pos;
        _crouchPos = [0, 0, 0.6] vectorAdd _pos;
        if (([objNull, "VIEW"] checkVisibility [_crouchPos, _checkPos]) == 1) then {
            _unitPos = "MIDDLE";
        };
        if (([objNull, "VIEW"] checkVisibility [_pos, _checkPos]) == 1) then {
            _unitPos = "DOWN";
        };

        _pos = ASLToATL _pos;

        [_unit, _pos, _watchPos, _watchDir, _unitPos, _cover] spawn {
            params ["_unit", "_pos", "_watchPos", "_watchDir", "_unitPos", "_cover"];
            // _unit disableAI "AUTOCOMBAT";
            _unit disableAI "TARGET";
            _unit disableAI "AUTOTARGET";
            _unit doMove _pos;
            _unit setDestination [_pos, "FORMATION PLANNED", false];

            waitUntil {(unitReady _unit) or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
            if ((group _unit) getVariable ["onTask", true]) then {
                if !(_cover) then {
                    _unit doWatch _watchPos;
                    doStop _unit;
                    _unit setUnitPos _unitPos;
                    _unit disableAI "PATH";
                    // _unit enableAI "AUTOCOMBAT";
                    _unit enableAI "TARGET";
                    _unit enableAI "AUTOTARGET";
                }
                else
                {
                    // player sideChat "off";
                    [_unit, _watchPos, _watchDir, 5, true] spawn pl_find_cover;
                };
            };
        };
    };

    // hint (str _allPos);

    if (!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) then {
        _medic setVariable ["pl_is_ccp_medic", true];
        while {(_group getVariable ["onTask", true])} do {
            {
                if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                    _medic setUnitPos "MIDDLE";
                    _h1 = [_group, _medic, nil, _x, getPos _medic, 50, "onTask"] spawn pl_ccp_revive_action;
                    waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                    [_x, getPos _x, _watchDir, 7, false] spawn pl_find_cover;
                    sleep 1;
                    waitUntil {unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                    [_medic, getPos _medic, _watchDir, 10, false] spawn pl_find_cover;
                    // _medic setUnitPos "MIDDLE";
                };
            } forEach (units _group);
            _time = time + 10;
            waitUntil {time > _time or !(_group getVariable ["onTask", true])};
        };
        _medic setVariable ["pl_is_ccp_medic", false];
    }
    else
    {
        waitUntil {!(_group getVariable ["onTask", true])};
    };
    deleteMarker _markerAreaName;
    deleteMarker _markerDirName;

    {
        pl_draw_building_array = pl_draw_building_array - [[_group, _x]];
    } forEach _validBuildings;
};