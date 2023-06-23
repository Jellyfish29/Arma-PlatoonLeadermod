dyn2_valid_covers = ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "BUILDING", "HIDE", "FENCE", "WALL"];
dyn2_covers = [];


dyn2_is_forest = {
    params ["_pos", ["_radius", 50]];

    _trees = nearestTerrainObjects [_pos, ["Tree"], _radius, false, true];

    if (count _trees > 25) exitWith {true};

    false
};

dyn2_is_town = {
    params ["_pos"];
    _buildings = nearestTerrainObjects [_pos, ["House"], 100, false, true];


    if (count _buildings >= 3) exitWith {true};
    false
};

dyn2_is_water = {
    params ["_pos"];
    private ["_isWater"];

    _isWater = {
        if (surfaceIsWater (_pos getPos [35, _x])) exitWith {true};
        false
    } forEach [0, 90, 180, 270]; 

    if (surfaceIsWater _pos) then {_isWater = true};
    _isWater 
};

dyn2_is_field = {
    params ["_pos", ["_radius", 50]];

    _objects = nearestTerrainObjects [_pos, [], _radius, false, true];

    if (count _objects <= 0) exitWith {true};

    false
};

dyn2_is_empty = {
    params ["_pos"];

    _objects = nearestTerrainObjects [_pos, [], 300, false, true];

    if (count _objects <= 0) exitWith {true};

    false
};

dyn2_is_indoor = {
    params ["_pos"];
    _pos = AGLToASL _pos;
    if (lineIntersects [_pos, _pos vectorAdd [0, 0, 10]]) exitWith {true};
    false
};

dyn2_nearestRoad = {
    params ["_center", "_radius", ["_blackList", []], ["_bridgeDistance", 25]];
    private ["_return"];

    private _roads = _center nearRoads _radius;
    private _bridges = [];
    private _validRoads = [];

    {
        _info = getRoadInfo _x;
        if (_info#8) then {
            _bridges pushBackUnique _x;
        };
    } forEach _roads;

    {
        _road = _x;
        _info = getRoadInfo _road;
        if (!((_info#0) in _blackList) and !(_info#2)) then {
            if (_bridges isEqualTo []) then {
                _validRoads pushBack _road;
            } else {
                {
                    if (((getpos _road) distance2D (getpos _x)) > _bridgeDistance) then {
                        _validRoads pushBack _road;
                    };
                } forEach _bridges;
            };
        };
    } forEach _roads;

    // _validRoads = _roads select {!(((getRoadInfo _x)#0) in _blackList) and !((getRoadInfo _x)#2) and !(_x#8)};
    _return = ([_validRoads, [], {(getpos _x) distance2D _center}, "ASCEND"] call BIS_fnc_sortBy)#0;
    if (isNil "_return") then {_return = objNull};

    _return
};

dyn2_hide_fences = {
    params ["_pos", "_radius"];
 
    _fences = nearestTerrainObjects [_pos, ["FENCE", "WALL"], _radius, false, true];

    for "_i" from 0 to (count _fences) - 1 do {
        if (_i % 3 == 0) then {
            hideObject (_fences#_i);
        };
    };
};

dyn2_convert_to_heigth_ASL = {
    params ["_pos", "_height"];

    _pos = ASLToATL _pos;
    _pos = [_pos#0, _pos#1, _height];
    _pos = ATLToASL _pos;

    _pos
};

dyn2_find_centroid_of_groups = {
    params ["_groups"];

    _groups = _groups select {(({alive _x} count (units _x)) > 0) and !isNull _x};
    private _sumX = 0;
    private _sumY = 0;
    private _len = count _groups;

    {
        // if (alive (leader _x)) then {
            _sumX = _sumX + ((getPos (leader _x))#0);
            _sumY = _sumY + ((getPos (leader _x))#1);

            // _m = createMarker [str (random 2), (getPos (leader _x))];
            // _m setMarkerType "mil_marker";
        // };

    } forEach _groups;

    [_sumX / _len, _sumY / _len, 0] 
};

dyn2_find_centroid_of_points = {
    params ["_points"];

    private _sumX = 0;
    private _sumY = 0;
    private _len = count _points;

    {
        _sumX = _sumX + _X#0;
        _sumY = _sumY + _x#1;

    } forEach _points;

    [_sumX / _len, _sumY / _len, 0]
};

dyn2_find_highest_point = {
    params ["_center", "_radius", ["_uDir", 0]];

    private _scanStart = (_center getPos [_radius / 2, _uDir]) getPos [_radius / 2, _uDir + 90];
    private _widthOffSet = 0;
    private _heigthOffset = 0;
    private _maxZ = 0;
    private _r = _center;
    for "_i" from 0 to 100 do {
        _heigthOffset = 0;
        _scanPos = _scanStart getPos [_widthOffSet, _uDir - 180];
        for "_j" from 0 to 100 do {
            _checkPos = _scanPos getPos [_heigthOffset, _uDir - 90];
            _checkPos = ATLToASL _checkPos;

            // _m = createMarker [str (random 1), _checkPos];
   //       _m setMarkerType "mil_dot";
   //       _m setMarkerSize [0.3, 0.3];

            _z = _checkPos#2;
            if (_z > _maxZ) then {
                _r = _checkPos;
                _maxZ = _z;
            };
            _heigthOffset = _heigthOffset + (_radius / 100);
        };
        _widthOffSet = _widthOffSet + (_radius / 100);
    };

    // _m = createMarker [str (random 1), _r];
    // _m setMarkerColor "colorGreen";
    // _m setMarkerType "mil_dot";
    ASLToATL _r;
    [_r#0, _r#1, 0]
    // [_r, 0] call dyn2_convert_to_heigth_ASL
};

dyn2_place_player = {
    params ["_pos", "_dest"];
    private ["_startPos", "_infGroups", "_vehicles", "_roads", "_road", "_roadsPos", "_dir", "_roadPos"];

    dyn2_player_vic = vehicle player;

    _startPos = getMarkerPos "dyn2_spawn";
    deleteMarker "dyn2_spawn";
    _vehicles = nearestObjects [_startPos,["LandVehicle"],200];
    
    private _campaignDir = _pos getDir _dest;
    _road = [_pos, 300] call BIS_fnc_nearestRoad;
    private _startRoad = _road;
    private _lastRoad = _road;
    private _sortBy = "DESCEND";
    _usedRoads = [];

    private _roadPos = [];

    _forwardPos = (getPos _road) getPos [50, _campaignDir];
    private _leftRight = -90;

    _roadsPos = [];
    _roadBlackList = [];
    private _lastRoadPos = [0,0,0];
    for "_i" from 0 to (count _vehicles) - 1 step 1 do {

        for "_j" from 0 to 1 do {
            private _connected = (roadsConnectedTo [_road, true]);
            {
                if (_x in _roadBlackList) then {_connected deleteAt (_connected find _x)};
            } forEach _connected;
            _road = ([_connected, [], {(getpos _x) distance2D _dest}, _sortBy] call BIS_fnc_sortBy)#0;
            _roadBlackList pushBack _road;

            _roadPos = getPos _road;
        };

        _info = getRoadInfo _road;    
        _endings = [_info#6, _info#7];
        _endings = [_endings, [], {_x distance2D _dest}, "ASCEND"] call BIS_fnc_sortBy;
        _dir = (_endings#1) getDir (_endings#0);

        _m = createMarker [str (random 1), _roadPos];
        _m setMarkerType "mil_dot";
        _m setMarkerText (str _i);

        (_vehicles#_i) setVehiclePosition [_roadPos, [], 0, "NONE"];

        (_vehicles#_i) setdir _dir;


        sleep 0.1;
    };
};

dyn2_get_cover_pos = {
    params ["_coverPos", "_watchDir", "_radius"];
    private ["_valid"];

    _covers = nearestTerrainObjects [_coverPos, dyn2_valid_covers, _radius, true, true];
    _watchPos = _coverPos getPos [1000, _watchDir];
    private _unitPos = "MIDDLE";
    if ((count _covers) > 0) then {
        {
            if !(_x in dyn2_covers) exitWith {
                dyn2_covers pushBack _x;
                _coverPos = (getPos _x) getPos [1.5, _watchDir - 180];
                _pronePos = [_coverPos, 0.2] call dyn2_convert_to_heigth_ASL;
                _checkPos = [_coverPos getPos [25, _watchDir], 1] call dyn2_convert_to_heigth_ASL;
                _visP = lineIntersectsSurfaces [_pronePos, _checkPos, objNull,  objNull, true, 1, "VIEW"];
                if (_visP isEqualTo []) then {
                    _unitPos = "DOWN";
                } else {
                    _unitPos = "MIDDLE";
                };
                [_x] spawn {
                    params ["_cover"];
                    sleep 5;
                    dyn2_covers deleteAt (dyn2_covers find _cover);
                };
            };
        } forEach _covers;
    }
    else
    {
        _pronePos = [_coverPos, 0.2] call dyn2_convert_to_heigth_ASL;
        _checkPos = [(_coverPos) getPos [25, _watchDir], 1] call dyn2_convert_to_heigth_ASL;
        _visP = lineIntersectsSurfaces [_pronePos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_visP isEqualTo []) then {
            _unitPos = "DOWN";
        } else {
            _unitPos = "MIDDLE";
        };
    };
    [_coverPos, _unitPos]
};

dyn2_garrison_building = {
    params ["_building", "_grp", "_dir", ["_insideOnly", false]];
    private ["_validPos", "_allPos", "_bPos", "_units", "_watchPos", "_pos", "_unit"];
    _validPos = [];
    _allPos = [];
    _bPos = [_building] call BIS_fnc_buildingPositions;
    _units = units _grp;
    {
        if !(_insideOnly and !([_x] call dyn2_is_indoor)) then {
            _allPos pushBack _x;
        };
        _watchPos = [10*(sin _dir), 10*(cos _dir), 1.7] vectorAdd _x;
        _standingPos = [0, 0, 1.7] vectorAdd _x;
        _standingPos = ATLToASL _standingPos;
        _watchPos = ATLToASL _watchPos;

        // _helper = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
        // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
        // _helper setposASL _standingPos;

        _cansee = [objNull, "VIEW"] checkVisibility [_standingPos, _watchPos];
        if (_cansee == 1) then {
            if !(_insideOnly and !([_x] call dyn2_is_indoor)) then {
                _validPos pushBack _x;
            };
        };
    } forEach _bPos;

    _watchPos = [500 * (sin _dir), 500 * (cos _dir), 0] vectorAdd (getPos _building);
    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

    for "_i" from 0 to (count _units) - 1 step 1 do {
        _unit = _units#_i;
        if (_i < (count _validPos)) then {
            _pos = _validPos#_i;
        }
        else
        {
            if (_i < (count _allPos)) then {
                _pos = _allPos#_i;
            } else {
                _pos = ([getPos _building,_dir, 50] call dyn2_get_cover_pos)#0;
            };
        };
        if (isNil "_pos") exitWith {};
        _pos = ATLToASL _pos;
        private _unitPos = "UP";
        _checkPos = [7*(sin _dir), 7*(cos _dir), 1.7] vectorAdd _pos;
        _crouchPos = [0, 0, 0.6] vectorAdd _pos;
        if (([objNull, "VIEW"] checkVisibility [_crouchPos, _checkPos]) == 1) then {
            _unitPos = "MIDDLE";
        };
        if (([objNull, "VIEW"] checkVisibility [_pos, _checkPos]) == 1) then {
            _unitPos = "DOWN";
        };

        _pos = ASLToATL _pos;

        _unit setPos _pos;
        _unit doWatch _watchPos;
        doStop _unit;
        _unit setUnitPos _unitPos;
        _unit disableAI "PATH";
    };
};

dyn2_find_doors = {
    params ["_building"];

    _doorsPos = [];

    {
        if (_x find "door" >= 0 and _x find "handle" < 0) then {
            _doorsPos pushBack (_building selectionPosition _x);
        };
    } forEach selectionNames _building;

    _doorsPos
};

dyn2_dig_trench_raw = {
    params ["_startPos", "_dir"];

    private _newHeightArray = [];
    private _dirtType = selectRandom ["Land_DirtPatch_05_F", "Land_DirtPatch_04_F", "Land_DirtPatch_03_F", "Land_DirtPatch_02_F"];
    private _startPos = _startPos getPos [20, _dir - 90];
    private _clutter = [];

    for "_i" from 0 to 9 do {
        _centerPos = _startPos getPos [4 * _i, _dir + 90];

        if !([_centerPos] call dyn_is_water) then {
            _dirt =  createVehicle [_dirtType, _centerPos, [], 2, "CAN_COLLIDE"];
            _dirt setDir ([0, 360] call BIS_fnc_randomInt);

            if (_i % 2 == 0) then {
                _cutter =  createVehicle ["Land_ClutterCutter_large_F", _centerPos, [], 0, "CAN_COLLIDE"];
                _cutter setDir _dir;
            };

            for "_x" from 0 to 1 step 1 do {
                for "_y" from 0 to 1 step 1 do {

                    _newPos = _centerPos vectorAdd [_x, _y, ((ATLtoASL _centerPos)#2) -1.8];
                    _newHeightArray pushBack _newPos;
                };
            };
        };


    };

    setTerrainHeight [_newHeightArray, true];
};


dyn2_get_all_airports = {

    private _allAirfields = [];
    if (count allAirports > 0) then {
         private _first = [getArray (configfile >> "CfgWorlds" >> worldname >> "ilsPosition"),getArray (configfile >> "CfgWorlds" >> worldname >> "ilsDirection")];
         _allAirfields pushbackunique _first;
         private _next = [];
         _sec = (configfile >> "CfgWorlds" >> worldname >> "SecondaryAirports");
         for "_i" from 0 to (count _sec - 1) do
         {
             _allAirfields pushbackunique [getarray ((_sec select _i) >> "ilsPosition"),getarray ((_sec select _i) >> "ilsDirection")];
         };
    };

    _allAirfields
};
