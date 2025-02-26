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

dyn2_pos_has_gradient = {
    params ["_pos", ["_gradLevel", 6]];

    private _return = false;

    for "_i" from 0 to 360 step 18 do {

        _grad = [_pos , _i] call BIS_fnc_terrainGradAngle;

        if (_grad >= _gradLevel) exitWith {_return = true};
    };
    _return
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

    waitUntil {(vehicles select {(hcLeader (group (driver _x))) == player}) isNotEqualTo []};

    dyn2_player_vic = vehicle player;

    private _vehicles = vehicles select {(hcLeader (group (driver _x))) == player};
    
    private _campaignDir = _pos getDir _dest;
    _road = [_pos, 300] call BIS_fnc_nearestRoad;
    private _startRoad = _road;
    private _sortBy = "DESCEND";

    private _roadPos = getPos _road;

    _forwardPos = (getPos _road) getPos [50, _campaignDir];

    _roadBlackList = [];
    for "_i" from 0 to (count _vehicles) - 1 step 1 do {

        // for "_j" from 0 to 1 do {
        private _connected = (roadsConnectedTo [_road, true]);
        {
            if (_x in _roadBlackList) then {_connected deleteAt (_connected find _x)};
        } forEach _connected;

        if ((count _connected) > 0) then {
            _road = ([_connected, [], {(getpos _x) distance2D _dest}, _sortBy] call BIS_fnc_sortBy)#0;
            _roadBlackList pushBack _road;
        } else {
            _road = _startRoad;
        };

        _roadPos = getPos _road;
        // };

        _info = getRoadInfo _road;    
        _endings = [_info#6, _info#7];
        _endings = [_endings, [], {_x distance2D _dest}, "ASCEND"] call BIS_fnc_sortBy;
        _dir = (_endings#1) getDir (_endings#0);

        // _m = createMarker [str (random 1), _roadPos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerText (str _i);

        (_vehicles#_i) setVehiclePosition [_roadPos, [], 0, "NONE"];

        (_vehicles#_i) setdir _dir;


        sleep 0.1;
    };

    {
        _grp = _x;
        if (vehicle (leader _grp) == (leader _grp)) then {

            _placePos = [[[_roadPos, 8]], ["water"]] call BIS_fnc_randomPos;
            {
                _x setVehiclePosition [_placePos, [], 5, "NONE"];
            } forEach (units _grp);
        };
    } forEach (allGroups select {(hcLeader _x) == player});

    sleep 0.2;

    [getPos player, 400, format ["%1 TAA", groupId (group player)], "colorBLUFOR"] call dyn2_draw_mil_symbol_objectiv_free;
};

dyn2_place_player_air_assault = {
    params ["_playerStart", "_lz"];

    sleep 15;

    private _infGrps = [];
    private _vicGroups = [];
    private _heliGroups = [];
    {
        _group = _x;
        if (vehicle (leader _group) != (leader _group)) then {
            _vic = vehicle (leader _group);
            if (group (driver _vic) != _group) then {
                _infGrps pushbackunique _group;
            } else {
                _vicGroups pushBackUnique _group;
            };
        } else {
            _infGrps pushbackunique _group;
        };
    } forEach (allGroups select {(side _x) == playerSide and (count (units _x) > 0)});

    private _offset = 100;
    {
        [_x, _playerStart, _lz, _offset, _heliGroups] spawn {
            params ["_group", "_playerStart", "_lz", "_offset", "_heliGroups"];

            if (vehicle (leader _group) != (leader _group)) then {
                _group leaveVehicle (vehicle (leader _group));
                {
                    moveOut _x;
                    [_x] orderGetIn false;
                    [_x] allowGetIn false;
                } forEach (units _group);
                sleep 1;
            };

            private _spawnPos = _playerStart getpos [_offset, _lz getDir _playerStart];
            
            private _heliCplt = [_spawnPos, _playerStart getDir _lz, pl_medevac_Heli_1, side _group] call BIS_fnc_spawnVehicle;
            private _heli = _heliCplt#0;
            private _heliGroup = _heliCplt#2;
            _heliGroups pushback _heliGroup;

            [_heli, 100] call BIS_fnc_setHeight;
            _heli forceSpeed 160;
            _heli flyInHeight 30;
            sleep 0.1;
            _heli setUnloadInCombat [false, false];

            sleep 1;
            // _heli doMove _lz;
            _group addVehicle _heli;
            {
                
                _x moveInCargo _heli;
                [_x] orderGetIn true;
                [_x] allowGetIn true;
            } forEach (units _group);
        };

        _offset = _offset + 100;


    } forEach _infGrps;



    sleep 3;

    [_heliGroups, _lz] spawn dyn2_player_air_insertion;

    sleep 3;

    {
        deleteVehicle (vehicle (leader _x));
        {
            deleteVehicle _x;
        } forEach (units _x);

        deleteGroup _x;
    } forEach _vicGroups;

};


dyn2_player_air_insertion = {
    params ["_groups", "_cords"];

    _groups = ([_groups, [], {_cords distance2d (leader _x)}, "ASCEND"] call BIS_fnc_sortBy);

    private _convoyLeaderGroup = _groups#0;
    private _convoyLeader = vehicle (leader _convoyLeaderGroup);
    private _pps = [(getPos _convoyLeader) getPos [1000, _convoyLeader getDir _cords]];
    _convoyLeaderGroup setVariable ["setSpecial", true];
    _convoyLeaderGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
    private _ppMarkers = [];

    private _convoy = +_groups;
    reverse _convoy;
    pl_draw_convoy_array pushBack _convoy;
    private _drawPath = [getPos _convoyLeader] + _pps + [_cords]; 
    pl_draw_convoy_path_array pushback _drawPath;

    private _approachDir = (_pps#((count _pps) - 1)) getDir _cords;
    private _posOffset = 0;
    private _posOffsetStep = 60;

    {
        deleteVehicle _x;
    } forEach (nearestTerrainObjects [_cords, [], 200, false, false]);


    for "_i" from 0 to (count _groups) - 1 do {
        
        _group = _groups#_i;
        // player hcRemoveGroup _group;
        // _group setVariable ["onTask", true];
        // _group setVariable ["setSpecial", true];
        // _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
        // _group setVariable ["pl_draw_convoy", true];

        _vic = vehicle (leader _group);
        _vic flyInHeight 30;
        _rtbPos = getPos _vic;

        _dirOffset = 90;
        if (_i % 2 == 0) then {_dirOffset = -90};
        _lzPos = _cords getPos [_posOffset, _approachDir + _dirOffset];
        if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
        // [_lzPos, 100] call pl_clear_obstacles;
        sleep 0.2;
        _lzPos = _lzPos findEmptyPosition [0, 200, typeOf _vic];
        // _vic doMove _lzPos;
        // private _landigPadLz = "Land_HelipadEmpty_F" createVehicle _lzPos;

        private _landigPadLz = createVehicle ["Land_HelipadEmpty_F", _lzPos, [], 10, "NONE"];
        _landigPadLz setDir _approachDir;

        private _lzMarker = createMarker [str (random 1), getPos _landigPadLz];
        _lzMarker setMarkerType "mil_circle";
        _lzMarker setMarkerSize [0.7, 0.7];
        _ppMarkers pushback _lzMarker;

        {
            _group addWaypoint [_x, 0];
        } forEach _pps;

        _lzWp = _group addWaypoint [_lzPos, 0];
        _lzWp setWaypointType "MOVE";


        [_vic, _group, _rtbPos, _landigPadLz, _lzPos, _pps, _lzWp] spawn {
            params ["_vic", "_group", "_rtbPos", "_landigPadLz", "_lzPos", "_pps", "_lzWp"];

            waitUntil{sleep 0.5; !alive _vic or (_vic distance2d _landigPadLz) < 200};

            private _success = _vic landAt [_landigPadLz, "Land"];
            if !(_success) then {_lzWp setWaypointType "TR UNLOAD"};
            _cargo = fullCrew [_vic, "cargo", false];
            private _cargoGroups = [];
            {
                _cargoGroups pushBack (group (_x select 0));
            } forEach _cargo;
            _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

            waitUntil {sleep 0.5; (isTouchingGround _vic) or !alive _vic};

            // (driver _vic) disableAI "PATH";
            _vic flyInHeight 0;
            [_vic, 1] call pl_door_animation;
            {
                _x leaveVehicle _vic;
                if !(_x getVariable ["pl_show_info", false]) then {[_x] call pl_show_group_icon;};
                if (_x != (group player)) then {_x addWaypoint [(getPos _vic) getPos [20, (getDir _vic) - 180], 0]};
            } forEach _cargoGroups;

            waitUntil {((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};

            (driver _vic) enableAI "PATH";
            _vic flyInHeight 40;
            deleteVehicle _landigPadLz;
            [_vic, 0] call pl_door_animation;

            if ((_vic distance2D _rtbPos) < 300) exitWith {_vic engineOn false};

            _rPPs = +_pps;
            reverse _rPPs;

            {
                _group addWaypoint [_x, 0];
            } forEach _rPPs;
            _group addWaypoint [_rtbPos, 0];
            _vic doMove _rtbPos;

            waitUntil {sleep 0.5; ((unitReady _vic) and _vic distance2d _rtbPos < 200) or (!alive _vic)};

            // _success = _vic landAt [_landigPadBase, "Land"];
            // if !(_success) then {_vic land "LAND";};
            // _group setVariable ["onTask", false];
            // _group setVariable ["setSpecial", false];
            {
                deleteVehicle _x;
            } forEach crew _vic;
            deleteVehicle _vic;
            deleteGroup _group;
        };
        sleep 5;
    };
    sleep 40;
    waitUntil {sleep 0.5; !(alive _convoyLeader) or !(_convoyLeaderGroup getVariable ["onTask", true])};

    pl_draw_convoy_array = pl_draw_convoy_array - [_convoy];
    pl_draw_convoy_path_array = pl_draw_convoy_path_array - [_drawPath];
    {deleteMarker _x} forEach _ppMarkers;

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
    params ["_blackList"];

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

    private _i = 0;
    {
        _afPos = _x#0;

        _valid = {
            if (_afPos inArea _x) exitWith {false};
            true
        } forEach _blackList;

        if !(_valid) then {_allAirfields deleteAt _i};

        _i = _i + 1

    } forEach _allAirfields;

    _allAirfields
};

dyn2_convoy_path_marker = [];

dyn2_convoy_parth_find = {
    params ["_start", "_goal"];

    if (isNull _start or isNull _goal) exitWith {[]};

    private _dummyGroup = createGroup [sideLogic, true];
    private _closedSet = [];
    private _openSet = [_start];
    private _current = _start;
    private _nodeCount = 0;
    private _allRoads = [];
    private _n = 0;
    private _returnPath = [];
    private _time = time + 4;
    while {!(_openSet isEqualTo []) and time < _time} do {
        private _closest = objNull;
        {
            if (_goal distance _x < _goal distance _closest) then {
                _closest = _x;
            };
            nil
        } count _openSet;
        _current = _closest;
        _nodeCount = _nodeCount + 1;
        if (_current == _goal) exitWith {
            private _parent = _dummyGroup getVariable ("NF_neighborParent_" + str _current);
            while {!(isNil "_parent")} do {
                _allRoads pushBack _parent;

                _returnPath pushback getPos _parent;
                _allRoads pushBackUnique _parent;
                _parent = _dummyGroup getVariable ("NF_neighborParent_" + str _parent);
                // if (dyn_debug) then {
                    // private _marker = createMarker [str (random 5), getPos _parent];
                    // _marker setMarkerShape "ICON";
                    // _marker setMarkerColor "colorBLUFOR";
                    // _marker setMarkerType "MIL_DOT";
                    // _marker setMarkerSize [0.3, 0.3];
                    // dyn2_convoy_path_marker pushBack _marker;
                // };
            };
        };
        _openSet = _openSet - [_current];
        _closedSet pushBack _current;
        private _neighbors = (getPos _current) nearRoads 20; // This includes current
        _neighbors append (roadsConnectedTo [_current, true]);
        {
            if (!(_x in _closedSet)) then {
                private _currentG = _dummyGroup getVariable ["NF_neighborG_" + str _current, 0];
                private _gScore = _currentG + 1;
                private _gScoreIsBest = false;
                if (!(_x in _openSet)) then {
                    _gScoreIsBest = true;
                    _openSet pushBack _x;
                } else {
                    private _neighborG = _dummyGroup getVariable ("NF_neighborG_" + str _x);
                    if (isNil "_neighborG") exitWith {};
                    _gScoreIsBest = _gScore < _neighborG;
                };
                if (isNil "_gScoreIsBest") exitWith {};
                if (_gScoreIsBest) then {
                    _dummyGroup setVariable ["NF_neighborParent_" + str _x, _current];
                    _dummyGroup setVariable ["NF_neighborG_" + str _x, _gScore];
                };
            };
        } forEach _neighbors;
    };
    if (time > _time) exitWith {[]};
    reverse _allRoads;
    // _returnPath deleteRange [0, 3];
    _allRoads
};

dyn2_clear_obstacles = {
    params ["_pos", "_radius"];
    
    {
        if (!(canMove _x) or ({alive _x} count (crew _x)) <= 0) then {
            deleteVehicle _x;
        };
    } forEach (vehicles select {(_x distance2D _pos) < _radius});

    {
         deleteVehicle _x;
    } forEach (allDead select {(_x distance2D _pos) < _radius});
    // remove Fences
    {
        deleteVehicle _x;
    } forEach ((_pos nearObjects _radius) select {["fence", typeOf _x] call BIS_fnc_inString or ["barrier", typeOf _x] call BIS_fnc_inString or ["wall", typeOf _x] call BIS_fnc_inString or ["sand", typeOf _x] call BIS_fnc_inString});
    // remove Bunkers
    {
        deleteVehicle _x;;
    } forEach ((_pos nearObjects _radius) select {["bunker", typeOf _x] call BIS_fnc_inString});
    // remove wire
    {
        deleteVehicle _x;
    } forEach ((_pos nearObjects _radius) select {["wire", typeOf _x] call BIS_fnc_inString});
    // kill trees
    {
        _x setDamage 1;
    } forEach (nearestTerrainObjects [_pos, ["TREE", "SMALL TREE", "BUSH"], _radius, false, true]);
};


dyn2_convoy_speed = 50;
dyn2_convoy = {
    params ["_groups", "_r2"];

    // private _r2 = [_dest, 100,[]] call BIS_fnc_nearestRoad;

    {
        // [_x] spawn {
        //     (_this#0) spawn pl_reset;
        //     sleep 0.5;
        //     (_this#0) spawn pl_reset;
        // };
        _r1 = [getPos (vehicle (leader _x)) , 50,[]] call BIS_fnc_nearestRoad;
        if (isNull _r1) then {
            _groups deleteAt (_groups find _x)
        } else {
            _path = [_r1, _r2] call dyn2_convoy_parth_find;
            _x setVariable ["dyn_convoy_path", _path];
        };
    } forEach _groups;

    _groups = ([_groups, [], {count (_x getVariable "dyn_convoy_path")}, "ASCEND"] call BIS_fnc_sortBy);

    // sleep 1;
    _convoyLeaderGroup = _groups#0;
    _convoyLeader = vehicle (leader _convoyLeaderGroup);
    _groups = ([_groups, [], {_convoyLeader distance2d (leader _x)}, "ASCEND"] call BIS_fnc_sortBy);

    if ((_convoyLeaderGroup getVariable ["dyn_convoy_path", []]) isEqualTo []) exitWith {
        {
            _x addWaypoint [_dest, 20];
            _x setBehaviour "SAFE";
        } forEach _groups;
    };

    private _bridges = [];
    private _destroyedBridges = [];

    {
        _info = getRoadInfo _x;
        if (_info#8) then {
            if ((getDammage _x) < 1) then {
                _bridges pushBackUnique _x;
            } else {
                _destroyedBridges pushBackUnique _x;
            };
        };
    } forEach (_convoyLeaderGroup getVariable "dyn_convoy_path");

    private _ppMarkers = [];
    private _passigPoints = [[0,0,0]];
    _noPPn = 0;
    for "_p" from 0 to count (_convoyLeaderGroup getVariable "dyn_convoy_path") - 1 do {
        private _r = (_convoyLeaderGroup getVariable "dyn_convoy_path")#_p;

        private _nearBridge = false;
        if !(_bridges isEqualTo []) then {
            _nearBridge = {
                if ((_x distance2D _r) < 50) exitWith {true};
                false
            } forEach _bridges;
        };

        if !(_nearBridge) then {
            if (count (roadsConnectedTo _r) > 2) then {
                _valid = {
                    if (_x distance2D _r < 50) exitWith {false};
                    true
                } forEach _passigPoints;
                if (_valid) then {
                    _passigPoints pushBackUnique (getPosATL _r);
                    _noPPn = 0;
                };
            } else {
                if (_p > 0) then {
                    if (((getRoadInfo _r)#0) != (getRoadInfo ((_convoyLeaderGroup getVariable "dyn_convoy_path")#(_p - 1)))#0) then {
                        _valid = {
                            if (_x distance2D _r < 50) exitWith {false};
                            true
                        } forEach _passigPoints;
                        if (_valid) then {
                            _passigPoints pushBackUnique (getPosATL _r);
                            _noPPn = 0;
                        };
                    } else {
                        if (_p > 1 and _p < (count (_convoyLeaderGroup getVariable "dyn_convoy_path") - 2)) then {
                            _dir1 = ((_convoyLeaderGroup getVariable "dyn_convoy_path")#(_p - 1)) getDir _r;
                            _dir2 = _r getDir ((_convoyLeaderGroup getVariable "dyn_convoy_path")#(_p + 1));
                            _dirs = [_dir1, _dir2];
                            _dirs sort false;
                            if ((_dirs#0) - (_dirs#1) > 50) then {
                                _valid = {
                                    if (_x distance2D _r < 80) exitWith {false};
                                    true
                                } forEach _passigPoints;
                                if (_valid) then {
                                    _passigPoints pushBackUnique (getPosATL _r);
                                    _noPPn = 0;
                                };
                            } else {
                                _noPPn = _noPPn + 1;
                                if (_noPPn > 20) then {
                                    _noPPn = 0;
                                    _passigPoints pushBackUnique (getPosATL _r);
                                };
                            };
                        };
                    };
                };
            };
        };
    };
    _passigPoints deleteAt 0;
    _passigPoints pushback getposATL _r2;

    for "_i" from 0 to (count _groups) - 1 do {
        // doStop (vehicle (leader _x));

        private _group = _groups#_i;
        private _vic = vehicle (leader _group);
        _vic limitSpeed dyn2_convoy_speed;
        _group setVariable ["dyn_in_convoy", true];
        
        // _vic setConvoySeparation 5;
        // _vic forceFollowRoad true;
        _group setVariable ["dyn_pp_idx", 0];

        {
            _x disableAI "AUTOCOMBAT";
        } forEach (units _group);
        _group setBehaviourStrong "CARELESS";
        _vic doMove (_passigPoints#0);
        _vic setDestination [(_passigPoints#0),"VEHICLE PLANNED" , true];

        // _vic setDriveOnPath (_group getVariable "dyn_convoy_path");

        if (_vic != _convoyLeader) then {

            // player hcRemoveGroup _group;

            [_group ,_vic, _convoyLeader, _groups, _i, _convoyLeaderGroup, _r2, _passigPoints] spawn {
                params ["_group" , "_vic", "_convoyLeader", "_groups", "_i", "_convoyLeaderGroup", "_r2", "_passigPoints"];
                private ["_ppidx"];

                // _vic setDriveOnPath (_group getVariable "dyn_convoy_path");

                sleep 2;
                _ppidx = 0;
                private _startReset = false;
                private _forward = vehicle (leader (_groups#(_i - 1)));
                while {(_convoyLeaderGroup getVariable ["dyn_in_convoy", false]) and ((_groups#(_i - 1)) getVariable ["dyn_in_convoy", true])} do {

                    if (!alive _vic or ({alive _x and (lifeState _x) != "INCAPACITATED"} count (units _group)) <= 0 or count (crew _vic) <= 0) exitWith {};
                    if (!(alive _convoyLeader) or !(alive _forward)) exitWith {};
                    if !(_group getVariable ["dyn_in_convoy", false]) exitWith {};
                    if (_group getVariable ["pl_stop_event", false]) exitWith {};

                    _ppidx = _group getVariable "dyn_pp_idx";
                    if (_vic distance2D (_passigPoints#_ppidx) < 35) then {
                        _ppidx = _ppidx + 1;
                        _group setVariable ["dyn_pp_idx", _ppidx];
                        _vic doMove (_passigPoints#_ppidx);
                        _vic setDestination [(_passigPoints#_ppidx),"VEHICLE PLANNED" , true];
                    };

                    private _convoyLeaderSpeedStr = vehicle (leader (_convoyLeaderGroup)) getVariable ["pl_speed_limit", "50"];
                    private _convoyLeaderSpeed = dyn2_convoy_speed;
                    if ([getPOs _vic] call pl_is_city or [getPOs _vic] call pl_is_forest) then {
                        _convoyLeaderSpeed = dyn2_convoy_speed / 2 + 5;
                    };
                    _vic forceSpeed -1;
                    _vic limitSpeed _convoyLeaderSpeed;
                    _distance = _vic distance2D _forward;
                    if (_distance > 60) then {
                        _vic limitSpeed (_convoyLeaderSpeed + 5 + (_distance - 60));
                    };
                    if (_distance < 60) then {
                        _vic limitSpeed _convoyLeaderSpeed;
                    };
                    if (_distance < 40) then {
                        _vic limitSpeed (_convoyLeaderSpeed * 0.5);
                    };
                    if (_distance < 20) then {
                        _vic forceSpeed 0;
                        _vic limitSpeed 0;
                    };
                    if (_distance > 40 and (speed _vic) < 8) then {
                        _vic limitSpeed 1000;
                    };
                    if ((speed _vic) <= 5) then {
                        [getPos _vic, 20] call dyn2_clear_obstacles;
                        _time = time + 10;
                        if !(_startReset) then {
                            _time = time + 5;
                            _startReset = true;
                        };
                        waitUntil {sleep 0.5; speed _vic > 5 or time > _time or !(_group getVariable ["dyn_in_convoy", true])};
                        if (((speed _vic) <= 3) and (_group getVariable ["dyn_in_convoy", true]) and (speed _forward) >= 5 and alive _vic) then {
                            doStop _vic;
                            sleep 0.3;
                            _group setBehaviour "CARELESS";
                            // _vic setVariable ["pl_phasing", true];
                            _r0 = [getpos _vic, 100,[]] call BIS_fnc_nearestRoad;
                            _r1 = ([roadsConnectedTo _r0, [], {(_passigPoints#_ppidx) distance2d _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                            _vic setVehiclePosition [getPos _r1, [], 0, "NONE"];
                            _vic setDir  (_r0 getDir _r1);
                            sleep 0.1;
                            _vic limitSpeed dyn2_convoy_speed;
                            _vic doMove (_passigPoints#_ppidx);
                            _vic setDestination [(_passigPoints#_ppidx),"VEHICLE PLANNED" , true];
                        }; 
                    };
                    sleep 1;
                };
                // _vic doMove getPos _vic;
                _group setVariable ["dyn_in_convoy", false];
                {
                    _x enableAI "AUTOCOMBAT";
                } forEach (units _group);
                _group setBehaviour "AWARE";
                _group addWaypoint [getPos _r2, 100];
                _vic doMove (getPos _r2);
                _vic limitSpeed -1;
            };
        } else {
            [_group ,_vic, _convoyLeader, _groups, _i, _convoyLeaderGroup, _r2, _passigPoints] spawn {
                params ["_group" , "_vic", "_convoyLeader", "_groups", "_i", "_convoyLeaderGroup", "_r2", "_passigPoints"];
                private ["_ppidx"];

                sleep 2;

                private _dest = getPos ((_convoyLeaderGroup getVariable "dyn_convoy_path")#((count (_convoyLeaderGroup getVariable "dyn_convoy_path")) - 1));

                while {(_convoyLeaderGroup getVariable ["dyn_in_convoy", false]) and (vehicle (leader _convoyLeaderGroup)) distance2D _dest > 40} do {

                    if (!alive _vic or count (crew _vic) <= 0) exitWith {};
                    if (_group getVariable ["pl_stop_event", false]) exitWith {};

                    private _convoyLeaderSpeedStr = vehicle (leader (_convoyLeaderGroup)) getVariable ["pl_speed_limit", "50"];
                    private _convoyLeaderSpeed = dyn2_convoy_speed;
                    if ([getPOs _vic] call pl_is_city or [getPOs _vic] call pl_is_forest) then {
                        _convoyLeaderSpeed = dyn2_convoy_speed / 2 + 5;
                    };
                    _vic forceSpeed -1;
                    _vic limitSpeed _convoyLeaderSpeed;

                    _ppidx = _group getVariable "dyn_pp_idx";
                    if (_vic distance2D (_passigPoints#_ppidx) < 35) then {
                        _ppidx = _ppidx + 1;
                        _convoyLeaderGroup setVariable ["dyn_pp_idx", _ppidx];
                        _vic doMove (_passigPoints#_ppidx);
                        _vic setDestination [(_passigPoints#_ppidx),"VEHICLE PLANNED" , true];
                    };

                    if ((speed _vic) <= 5) then {
                        [getPos _vic, 20] call dyn2_clear_obstacles;
                        _time = time + 10;
                        waitUntil {sleep 0.5; speed _vic > 5 or time > _time or !(_group getVariable ["dyn_in_convoy", true])};
                        if ((speed _vic) <= 3 and (_group getVariable ["dyn_in_convoy", true]) and alive _vic) then {
                            // [_group] call pl_reset;
                            [getPos _vic, 20] call pl_clear_obstacles;
                            doStop _vic;
                            sleep 0.3;
                            _group setBehaviourStrong "SAFE";
                            _r0 = [getpos _vic, 100,[]] call BIS_fnc_nearestRoad;
                            _r1 = ([roadsConnectedTo _r0, [], {(_passigPoints#_ppidx) distance2d _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                            _vic setVehiclePosition [getPos _r1, [], 0, "NONE"];
                            _vic setDir  (_r0 getDir _r1);
                            sleep 0.1;
                            _vic limitSpeed dyn2_convoy_speed;
                            _vic doMove (_passigPoints#_ppidx);
                            _vic setDestination [(_passigPoints#_ppidx),"VEHICLE PLANNED" , true];

                        }; 
                    };
                    sleep 1;
                };
                // _vic doMove getPos _vic;
                _convoyLeaderGroup setVariable ["dyn_in_convoy", false];
                {
                    _x enableAI "AUTOCOMBAT";
                } forEach (units _group);
                _group setBehaviour "AWARE";
                _convoyLeaderGroup addWaypoint [getPos _r2, 100];
                _vic doMove (getPos _r2);
                _vic limitSpeed -1;
            };
        };
        _time = time + 1.5;
        waituntil {(time >= _time and speed _vic > 13) or !((_convoyLeaderGroup) getVariable ["dyn_in_convoy", true])};
    };
};

dyn2_enter_evac_heli = {
    params ["_unit"];

    waitUntil {sleep 1; !(isNull pl_current_med_evac_heli)};

    private _heli = pl_current_med_evac_heli;

    waitUntil {sleep 1; !(alive _unit) or ((lifeState _unit) isNotEqualTo "INCAPACITATED") or (isNull pl_current_med_evac_heli)};

    waitUntil {sleep 1; !(alive _unit) or !(alive _heli) or !(canmove _heli) or ((fullCrew _heli) isEqualTo []) or (isTouchingGround _heli) or (isNull pl_current_med_evac_heli)};

    if ((alive _unit) and (alive _heli) and (canmove _heli) and ((fullCrew _heli) isNotEqualTo []) and (isTouchingGround _heli) and !(isNull pl_current_med_evac_heli)) then {

        if ((_unit distance2D _heli) < 500) then {

            _unit enableAI "PATH";
            _unit setUnitPos "AUTO";
            _unit setBehaviour "AWARE";
            _unit setDamage 0;
            _unit setHit ["legs", 0];
            _unit setCaptive false;
            [_unit] joinSilent (group (driver _heli));
            _unit assignAsCargo _heli;
            [_unit] allowGetIn true;
            [_unit] orderGetIn true;
        };
    } else {
        if (isNull pl_current_med_evac_heli or !(alive _heli) or !(canmove _heli) or ((fullCrew _heli) isEqualTo [])) then {
            sleep (random 2);
            [group _unit] call dyn2_manual_evac;
        };
    };
};

dyn2_evac_group = createGroup [playerside, false];
dyn2_evac_group setGroupId ["EVAC"];

dyn2_manual_evac = {
    params ["_group"];

    if (_group getVariable ["dyn2_marked_for_evac", false]) exitWith {};

    _group setVariable ["dyn2_marked_for_evac", true];

    _evacGroup = createGroup [playerside, _evac];

    {
        [_x] joinSilent _evacGroup;
        removeAllWeapons _x;
    } forEach (units _group);

    [_evacGroup] call pl_set_up_ai;
    _evacGroup setGroupId ["EVAC"];
    player hcSetGroup [_evacGroup, "EVAC"];
    [_evacGroup, "unknown"] call pl_change_group_icon;
};

// pl_current_med_evac_heli = objNull;
// pl_current_supply_heli = objNull;
// 0 = [getPos player, [9912.05,11998.1,0.00158787]] spawn dyn2_SIDE_capture_HVT;


