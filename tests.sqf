pl_defend_position = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_watchDir", "_cords", "_watchPos", "_markerAreaName", "_markerDirName", "_buildings", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon", "_unitWatchDir", "_vPosCounter"];
    
    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};

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

        pl_garrison_area_size = 25;
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

            waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false])};

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
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
        _vPosCounter = 0;
        {
            _allPos pushBack _x;
            _watchPos = [10*(sin _watchDir), 10*(cos _watchDir), 1.2] vectorAdd _x;
            _standingPos = [0, 0, 1.2] vectorAdd _x;
            _standingPos = ATLToASL _standingPos;
            _watchPos = ATLToASL _watchPos;

            // _helper1 = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
            // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
            // _helper1 setposASL _watchPos;

            // _helper2 = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
            // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
            // _helper2 setposATL _standingPos;

            _cansee = [objNull, "FIRE"] checkVisibility [_standingPos, _watchPos];
            if (_cansee > 0.5) then {
                _bPos deleteAt (_bPos find _x);
                _validPos pushBack _x;
                _vPosCounter = _vPosCounter + 1;
            };
            // _vis = lineIntersects [_standingPos, _watchPos];
            // if !(_vis) then {
            //     _validPos pushBack _x;
            //     _vPosCounter = _vPosCounter + 1;
            // };
            // _vis = lineIntersectsSurfaces [_standingPos, _watchPos, objNull, objNull, true, 1, "VIEW", "FIRE"];
            // if (_vis isEqualTo []) then {
            //     _validPos pushBack _x;
            //     _vPosCounter = _vPosCounter + 1;
            // };
        } forEach _bPos;
        if (_vPosCounter <= 2) then {
            for "_i" from 0 to 1 do {
                _validPos pushBack (selectRandom _bPos);
            };
        };
    } forEach _validBuildings;

    // deploy packed static weapons if no buildings
    _isStatic = [false, []];
    if (_validBuildings isEqualTo [] and !(pl_360_area)) then {
        _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _cords;
        _leaderDir = _watchDir - 90;
        _leaderPos = [6*(sin _leaderDir), 6*(cos _leaderDir), 0] vectorAdd _cords;
        (leader _group) addWeapon "Binocular";
        _isStatic = [_group, _cords, _watchPos, _leaderPos] call pl_reworked_bis_unpack;
    };


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
    _posOffsetStep = pl_garrison_area_size / (round ((count _units) / 2));
    private _posOffset = 0; //+ _posOffsetStep;
    private _maxOffset = _posOffsetStep * (round ((count _units) / 2));

    // find static weapons
    private _weapons = nearestObjects [_cords, ["StaticWeapon"], pl_garrison_area_size, true];
    _avaiableWeapons = _weapons select { simulationEnabled _x && { !isObjectHidden _x } && { locked _x != 2 } && { (_x emptyPositions "Gunner") > 0 } };
    _weapons = + _avaiableWeapons;


    for "_i" from 0 to (count _units) - 1 step 1 do {
        private _cover = false;
        private _covers = nearestTerrainObjects [_cords, pl_valid_covers, pl_garrison_area_size, true, true];
        // private _blacklist = nearestTerrainObjects [_cords, [], (pl_garrison_area_size - 8), true, true];
        // _covers = _covers - _blacklist;
        _covers = [_covers, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        _unitWatchDir = _watchDir;
        private _moveToStatic = false;
        if !(_avaiableWeapons isEqualTo []) then {
            _weapon = selectRandom _avaiableWeapons;
            _weapon setDir _watchDir;
            (_units#_i) assignAsGunner _weapon;
            [_units#_i] orderGetIn true;
            _group addVehicle _weapon;
            _avaiableWeapons deleteAt (_avaiableWeapons find _weapon);
            _moveToStatic = true;
        };

        // move to optimal Pos first
        if (_i < (count _validPos)) then {
            _pos = _validPos#_i;
            _unit = _units#_i;
        }
        else
        {
            _cover = true;
            _unit = _units#_i;
            // if 360 Option move to 360 Positions
            if (pl_360_area) then {
                _diff = 360/ (count _units);
                _degree = 1 + _i*_diff;
                _pos = [pl_garrison_area_size*(sin _degree), pl_garrison_area_size*(cos _degree), 0] vectorAdd _cords;
                _watchDir = _degree;
                _unitWatchDir = _degree;
            }
            // if no more covers avaible move to left or right side of best cover
            else
            {
                // deploy along a line
                if (_validBuildings isEqualTo []) then {
                    _dirOffset = 90;
                    if (_i % 2 == 0) then {_dirOffset = -90};
                    _pos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _cords;
                    if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};

                    if (_i == (count _units) - 2 or _i == (count _units) - 3) then {
                        _unitWatchDir = _watchDir + _dirOffset;
                    };

                    // last unit in group backwards position watch back if Medic active the nunit is medic
                    if (!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) then {
                        if (_unit == _medic) then {
                            _pos = [(pl_garrison_area_size * 0.5) *(sin (_watchDir - 180)), (pl_garrison_area_size * 0.5) *(cos (_watchDir - 180)), 0] vectorAdd _cords;
                            _unitWatchDir = _watchDir - 180;
                        };
                    }
                    else
                    {
                        if (_unit == (_units#((count _units) - 1))) then {
                            _pos = [(pl_garrison_area_size * 0.5) *(sin (_watchDir - 180)), (pl_garrison_area_size * 0.5) *(cos (_watchDir - 180)), 0] vectorAdd _cords;
                            _unitWatchDir = _watchDir - 180;
                        };
                    };
                }
                else
                {
                    if !(_covers isEqualTo []) then {
                        _pos = getPos (selectRandom _covers);
                    }
                    else
                    {
                        _pos = _cords findEmptyPosition [0, pl_garrison_area_size, typeOf _x];
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
        // if (([objNull, "VIEW"] checkVisibility [_pos, _checkPos]) == 1) then {
        //     _unitPos = "DOWN";
        // };

        _pos = ASLToATL _pos;

        if !(_moveToStatic and !(_unit in (_isStatic#1))) then {
            [_unit, _pos, _watchPos, _unitWatchDir, _unitPos, _cover, _markerAreaName] spawn {
                params ["_unit", "_pos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_markerAreaName"];
                _unit disableAI "AUTOCOMBAT";
                _unit disableAI "TARGET";
                _unit disableAI "AUTOTARGET";
                _unit doMove _pos;
                // _unit setDestination [_pos, "LEADER DIRECT", false];
                _unit setDestination [_pos, "LEADER PLANNED", true];
                if !([_unit, _pos, pl_garrison_area_size] call pl_not_reachable_escape) then {_cover = true};

                sleep 0.2;

                waitUntil {(unitReady _unit) or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
                _unit enableAI "AUTOCOMBAT";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                if ((group _unit) getVariable ["onTask", true]) then {
                    if !(_cover) then {
                        _unit doWatch _watchPos;
                        doStop _unit;
                        _unit setUnitPosWeak _unitPos;
                        _unit disableAI "PATH";
                    }
                    else
                    {
                        [_unit, _watchPos, _unitWatchDir, 17, true, false, _markerAreaName] spawn pl_find_cover;
                    };
                };
            };
        };
    };

    // hint (str _allPos);

    if (!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) then {
        _medic setVariable ["pl_is_ccp_medic", true];
        while {(_group getVariable ["onTask", true])} do {
            _time = time + 10;
            waitUntil {time > _time or !(_group getVariable ["onTask", true])};
            {
                if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                    _medic setUnitPos "MIDDLE";
                    _medic enableAI "PATH";
                    _h1 = [_group, _medic, nil, _x, getPos _medic, 40, "onTask"] spawn pl_ccp_revive_action;
                    waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                    [_x, getPos _x, getDir _x, 7, false] spawn pl_find_cover;
                    sleep 1;
                    waitUntil {unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                    [_medic, getPos _medic, getDir _medic, 10, false] spawn pl_find_cover;
                };
                if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and !(lifeState _x isEqualTo "INCAPACITATED")) then {
                    _medic setUnitPos "MIDDLE";
                    _medic enableAI "PATH";
                    _h1 = [_medic, _x, getPos _medic, "onTask"] spawn pl_medic_heal;
                    waitUntil {scriptDone _h1 or !(_group getVariable ["onTask", true])};
                    sleep 1;
                    waitUntil {unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                    [_medic, getPos _medic, getDir _medic, 10, false] spawn pl_find_cover;
                };
            } forEach (units _group);
        };
        _medic setVariable ["pl_is_ccp_medic", false];
    }
    else
    {
        waitUntil {!(_group getVariable ["onTask", true])};
    };
    deleteMarker _markerAreaName;
    deleteMarker _markerDirName;

    if (_isStatic#0) then {
        _weapon = {
            if ((vehicle _x) != _x) exitWith {vehicle _x};
            objNull
        } forEach (units _group);
        if !(isNull _weapon) then {
            [_group, _weapon] call pl_reworked_bis_pack;
        };
        (leader _group) removeWeapon "Binocular";
    };

    {
        _group leaveVehicle _x;
    } forEach _weapons;

    {
        pl_draw_building_array = pl_draw_building_array - [[_group, _x]];
    } forEach _validBuildings;
};