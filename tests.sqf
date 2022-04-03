pl_opfor_defend_position = {
    params ["_grp"];
    private ["_mPos", "_medicPos", "_buildingWallPosArray", "_buildingMarkers", "_watchPos", "_defenceWatchPos", "_markerAreaName", "_markerDirName", "_covers", "_buildings", "_doorPos", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon", "_unitWatchDir", "_vPosCounter", "_defenceAreaSize", "_mgPosArray", "_losPos", "_mgOffset", "_atEscord"];

    [_grp] spawn pl_opfor_reset;

    sleep 0.5;

    _grp setvariable ["pl_opf_in_pos", true];

    private _targets = (((getPos (leader _grp)) nearEntities [["Man"], 600]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0});
    if (count _targets > 0) then {
        private _target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
        _units = units _grp;
        _cords = getPos (([_units, [], {_target distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0);
    } else {
        _cords = getPos (leader _grp);
    };

    _defenceAreaSize = 20;
    _buildings = nearestTerrainObjects [_cords, ["BUILDING", "RUIN", "HOUSE"], _defenceAreaSize, true];


    _defenceWatchPos = _cords getPos [250, _watchDir];
    _defenceWatchPos = ASLToATL _defenceWatchPos;
    _defenceWatchPos = [_defenceWatchPos#0, _defenceWatchPos#1, 2];
    _defenceWatchPos = ATLToASL _defenceWatchPos;


    _watchPos = _cords getPos [1000, _watchDir];
    [_watchPos, 1] call pl_convert_to_heigth_ASL;

    
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 2) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    _validPos = [];
    private _sideRoadPos = [];
    _allPos = [];
    {
        private _building = _x;
        _bPos = [_building] call BIS_fnc_buildingPositions;
        _vPosCounter = 0;
        {
            _bP = _x;
            _allPos pushBack _bP;
            private _window = false;

            _samplePosASL = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 1.04152];

            _buildingDir = getDir _building;
            for "_d" from 0 to 361 step 90 do {
                _counterPos = _samplePosASL vectorAdd [3 * (sin (_buildingDir + _d)), 3 * (cos (_buildingDir + _d)), 0];

                if !((lineIntersects [_counterPos, _counterPos vectorAdd [0, 0, 20]])) then {

                    _interSectsWin = lineIntersectsWith [_samplePosASL, _counterPos, objNull, objNull, true];
                    _checkDir = _buildingDir + _d;
                    if ((({_x == _building} count _interSectsWin) == 0) and (_checkDir > (_watchDir - 25) and _checkDir < (_watchDir + 25))) exitWith {
                        // _window = true
                        _bPos deleteAt (_bPos find _bP);
                        _validPos pushBack _bP;
                        _vPosCounter = _vPosCounter + 1;
                    };
                };
            };

            _skyPos = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 30];
            _interSectsRoof = lineIntersectsWith [_samplePosASL, _skyPos];
            if (_interSectsRoof isEqualTo []) then {
                _bPos deleteAt (_bPos find _bP);
                _validPos pushBackUnique _bP;
                _vPosCounter = _vPosCounter + 1;
            };
        } forEach _bPos;

        if (_vPosCounter == 0) then {
            // _validPos pushBack (selectRandom _bPos);
            _validBuildings deleteAt ( _validBuildings find _building);
        };
    } forEach _validBuildings;

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _units = [(leader _grp)];
    private _mgGunners = [];
    private _atSoldiers = [];
    private _atEscord = objNull;
    private _medic = objNull;

    // classify units
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun" and secondaryWeapon _x == "" and _x != _medic and _x != (leader _grp) and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _units pushBackUnique _x;
        };
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun" and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _mgGunners pushBackUnique _x;
        };
        if (secondaryWeapon _x != "" and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _atSoldiers pushBackUnique _x;
        };
    } forEach (units _grp);

    if (count _atSoldiers > 0 and count _units > 3) then {
        _atEscord = {
            if (_x != (leader _grp) and _x != _medic) exitWith {_x};
            objNull
        } forEach _units;
    };
    {_units pushBack _x} forEach _atSoldiers;
    {_units pushBack _x} forEach _mgGunners;
    _units pushBack _medic;

    [_grp, _defenceWatchPos, _medic] spawn pl_opfor_defence_suppression;

    _posOffsetStep = _defenceAreaSize / (round ((count _units) / 2));
    private _posOffset = 0; //+ _posOffsetStep;
    private _maxOffset = _posOffsetStep * (round ((count _units) / 2));
    _coverCount = 0;
    _medicPos = [];
    private _safePos = [];
    _buildingMarkers = [];

    if !(_buildings isEqualTo []) then {

        _buildings = [_buildings, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _covers = [];
        _buildingWallPosArray = [];
        {
            _buildingCenter = getPos _x;
            _coverSearchPos = _buildingCenter getPos [10, _watchDir];
            _c = nearestTerrainObjects [_coverSearchPos, pl_valid_covers, 15, true, true];
            _covers = _covers + _c;

            _m = [_x] call BIS_fnc_boundingBoxMarker;
            if (_x in _validBuildings) then {
                _m setMarkerColor pl_side_color;
                _m setMarkerAlpha 0.3;
            };
            _buildingMarkers pushBack _m;
            _mPos = getMarkerPos _m;
            _mDir = markerdir _m;
            _mSize = getMarkerSize _m;
            _a2 = ((_mSize#0) * 1) * ((_mSize#0) * 1);
            _b2 = ((_mSize#1) * 1) * ((_mSize#1) * 1);
            _c2 = _a2 + _b2;
            _d = sqrt _c2;

            private _corners = [];
            for "_di" from 45 to 315 step 90 do {
                _corners pushback (_mPos getPos [_d,_mDir + _di]);
            };

            _corners = [_corners, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy;

            {
                if !([_x] call pl_is_indoor) then {
                    _buildingWallPosArray pushback _x;
                };
            } forEach [(_corners#0), (_corners#1)];

            _safePos pushback (((_corners#0) getPos [((_corners#0) distance2D (_corners#1)) / 2, (_corners#0) getDir (_corners#1)]) getPos [2.5, _watchDir - 180]);

        } forEach _buildings;

        _buildingWallPosArray = [_buildingWallPosArray, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _covers = [_covers, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _medicPos = ([_safePos, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0;


        // {
        //     _m = createMarker [str (random 1), _x];
        //     _m setMarkerType "mil_dot";
        //     _m setMarkerSize [0.5, 0.5];
        // } forEach _buildingWallPosArray;

        private _walls = nearestTerrainObjects [_cords, ["WALL", "RUIN"], _defenceAreaSize, true];
        private _validWallPos = [];
        private _validPrefWallPos = [];

        {
            if !(isObjectHidden _x) then {

                _leftPos = (getPos _x) getPos [1.5, getDir _x];
                _rightPos = (getPos _x) getPos [1.5, (getDir _x) - 180];

                if ((typeof _x) in pl_valid_walls) then {
                    _validPrefWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                } else {
                    _validWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                };
            };
        } forEach _walls;

        _validWallPos = [_validWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _validPrefWallPos = [_validPrefWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        private _roads = _cords nearRoads _defenceAreaSize;
        if ((count _roads) >= 2) then {
            _roads = [_roads, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
            private _roadDir = (getpos (_roads#1)) getDir (getpos (_roads#0));

            if (_roadDir > (_watchDir - 35) and _roadDir < (_watchDir + 35)) then {

                _roads = [_roads, [], {_x distance2D (_buildings#0)}, "ASCEND"] call BIS_fnc_sortBy;
                private _road = _roads#0;
                {
                    _info = getRoadInfo _road;    
                    _endings = [_info#6, _info#7];
                    _endings = [_endings, [], {_x distance2D player}, "ASCEND"] call BIS_fnc_sortBy;
                    _roadWidth = _info#1;
                    _rPos = ASLToATL (_endings#0);
                    _sideRoadPos pushBack (_rPos getPos [(_roadWidth / 2) + 1, _roadDir + _x]);

                    // _m = createMarker [str (random 1), _rPos getPos [_roadWidth / 2, _roadDir + _x]];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerSize [0.5, 0.5];

                } forEach [90, -90];
            };
        };

        _validPos = _validPos + _validPrefWallPos;
        _validPos = _validPos + _validWallPos;
        _validPos = _validPos + _buildingWallPosArray;
        _validPos = _validPos + _sideRoadPos;

    } else {
        _covers = [];
    };

    // private _validLosPos = [];

    private _losOffset = 2;
    private _maxLos = 0;
    private _losStartLine = _cords getPos [2, _watchDir];
    private _validLosPos = [];
    private _accuracy = 30;
    if ([_losStartLine] call pl_is_city) then {
        _accuracy = 10;
    };

    for "_j" from 0 to _accuracy do {
        if (_j % 2 == 0) then {
            _losPos = (_losStartLine getPos [2, _watchDir]) getPos [_losOffset, _watchDir + 90];
        }
        else
        {
            _losPos = (_losStartLine getPos [2, _watchDir]) getPos [_losOffset, _watchDir - 90];
        };
        _losOffset = _losOffset + (_defenceAreaSize / _accuracy);

        _losPos = [_losPos, 1] call pl_convert_to_heigth_ASL;

        private _losCount = 0;
        for "_l" from 10 to 510 step 50 do {

            _checkPos = _losPos getPos [_l, _watchDir];
            _checkPos = [_checkPos, 1] call pl_convert_to_heigth_ASL;
            _vis = lineIntersectsSurfaces [_losPos, _checkPos, objNull, objNull, true, 1, "VIEW"];

            if !(_vis isEqualTo []) exitWith {};

            _losCount = _losCount + 1;
        };
        if (isNull (roadAt _losPos)) then {
            _validLosPos pushback [_losPos, _losCount];
        };
    };

    _validLosPos = [_validLosPos, [], {_x#1}, "DESCEND"] call BIS_fnc_sortBy;

    private _mgPos = [];

    for "_i" from 0 to count (_mgGunners) - 1 do {
        _mgPos pushback ((_validLosPos#_i)#0);
        _validLosPos deleteAt (_validLosPos find (_validLosPos#_i));
    };

    private _mgIdx = 0;
    private _losIdx = 0;
    private _debugMColor = "colorBlack";
    private _defPos = [];

    for "_i" from 0 to (count _units) - 1 step 1 do {
        private _cover = false;

        _unitWatchDir = _watchDir;

        // move to optimal Pos first
        if (_i < (count _validPos)) then {
            _defPos = _validPos#_i;
            _unit = _units#_i;
            _debugMColor = "colorBlue";
        }
        else
        {
            _cover = true;
            _unit = _units#_i;
            // if no more covers avaible move to left or right side of best cover
                // deploy along a line
            if (_buildings isEqualTo []) then {
                _dirOffset = 90;
                if (_i % 2 == 0) then {_dirOffset = -90};
                _defPos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _cords;
                if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
                _debugMColor = "colorBlue";
            }
            else
            {
                if (_losIdx > (count _validLosPos) - 1) then {_losIdx = 1};
                _defPos = (_validLosPos#_losIdx)#0;
                _losIdx = _losIdx + 2;
                _debugMColor = "colorOrange";
            };
        };

        // select Best Mg Pos
        if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
            _defPos = (_mgPos#_mgIdx);
            _mgIdx = _mgIdx + 1;
            _debugMColor = "colorRed";
        };

        // if (_unit == (leader _grp) and !(_buildings isEqualTo []) and (_defPos distance2D _cords) > 20) then {
        //     _defPos = _cords findEmptyPosition [0, 25, typeOf _unit];
        //     _cover = true;
        //     _debugMColor = "colorYellow";
        // };

        if (_defPos isEqualTo []) then {
            _defPos = selectRandom _covers;
            _debugMColor = "colorGrey";
        };

        _defPos = ATLToASL _defPos;
        private _unitPos = "UP";
        if !([_defPos] call pl_is_indoor) then {
            // _unitPos = "MIDDLE";
            _cover = true;
        };
        _checkPos = [10*(sin _watchDir), 10*(cos _watchDir), 1] vectorAdd _defPos;
        _crouchPos = [0, 0, 1] vectorAdd _defPos;
        _vis = lineIntersectsSurfaces [_crouchPos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "MIDDLE";
            // _watchPos = _checkPos;
        };
        _checkPos = [10*(sin _watchDir), 10*(cos _watchDir), 0.2] vectorAdd _defPos;
        _vis = lineIntersectsSurfaces [_defPos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "DOWN";
            // _watchPos = _checkPos;
        };

        _defPos = ASLToATL _defPos;

        // _m = createMarker [str (random 1), _defPos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerSize [0.5, 0.5];
        // _m setMarkerColor _debugMColor;

        // _helper = createVehicle ["Sign_Sphere25cm_F", _defPos, [], 0, "none"];
        // _helper setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];

        [_unit, _defPos, _watchPos, _unitWatchDir, _unitPos, _cover, _cords, _defenceAreaSize, _defenceWatchPos, _watchDir, _atEscord, _medic] spawn {
            params ["_unit", "_defPos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_cords", "_defenceAreaSize", "_defenceWatchPos", "_defenceDir", "_atEscord", "_medic"];

            // _m = createMarker [str (random 1), _defPos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];


            _unit setVariable ["pl_def_pos", _defPos, true];
            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            // _unit disableAI "FSM";
            _unit doMove _defPos;
            _unit setDestination [_defPos, "LEADER DIRECT", true];
            sleep 1;
            private _counter = 0;
            // while {alive _unit and ((group _unit) getVariable ["pl_opf_in_pos", true])} do {
            //     sleep 0.5;
            //     _dest = [_unit, _defPos, _counter] call pl_position_reached_check;
            //     if (_dest#0) exitWith {};
            //     _defPos = _dest#1;
            //     _counter = _dest#2;
            // };
            waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["pl_opf_in_pos", true])};
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "TARGET";
            // _unit enableAI "FSM";
            if !(_cover) then {
                doStop _unit;
                _unit disableAI "PATH";
                _unit doWatch _watchPos;
                _unit setUnitPos _unitPos;
            }
            else
            {
                if ([_defPos] call pl_is_forest or [_defPos] call pl_is_city) then {
                    [_unit, _watchPos, _unitWatchDir, 3, false] spawn pl_opfor_find_cover;
                } else {
                    [_unit, _watchPos, _unitWatchDir, 10, false] spawn pl_opfor_find_cover;
                };
            };
            if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                [_unit, _watchPos, _unitWatchDir, 0, false, false, "", true] spawn pl_opfor_find_cover;
                // _m setMarkerColor "colorRed";
            };
        };
    };
};

pl_opfor_defence_suppression = {
    params ["_grp", "_watchPos", "_medic"];
    private ["_targetsPos", "_firers"];

    private  _time = time + 20;
    waitUntil {sleep 0.5;  time >= time or !(_grp getVariable ["pl_opf_in_pos", true]) };
    if !(_grp getVariable ["pl_opf_in_pos", true]) exitWith {};

    while {_grp getVariable ["pl_opf_in_pos", false]} do {
        // _allTargets = nearestObjects [_watchPos, ["Man", "Car"], 350, true];
        _enemyTargets = (_watchPos nearEntities [["Man", "Car"], 275]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0};
        if (count _enemyTargets > 0) then {
            _firers = [];
            {
                if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                    _firers pushBackUnique _x;
                    _x setUnitTrait ["camouflageCoef", 0.5, false];
                    _x setVariable ["pl_damage_reduction", true];
                } else {
                    if ((random 1) > 0.4) then {_firers pushBackUnique _x;}
                };
            } forEach ((units _grp) select {!(_x checkAIFeature "PATH") and _x != _medic});
            {
                _unit = _x;
                _target = selectRandom _enemyTargets;
                _targetPos = getPosASL _target;
                _vis = lineIntersectsSurfaces [eyePos _unit, _targetPos, _unit, vehicle _unit, true, 1]; 
                if !(_vis isEqualTo []) then {
                    _targetPos = (_vis select 0) select 0;
                };

                if ((_targetPos distance2D _unit) > 20) then {
                     _unit doSuppressiveFire _targetPos;
                };
            } forEach _firers;

            _time = time + 10;
            waitUntil {sleep 0.5; time > _time or !(_grp getVariable ["pl_opf_in_pos", true])};
        };
        sleep 2;
    };
};

// pl_debug = true;
// pl_active_opfor_vic_grps = [];
// {
//     (group (driver _x)) execFSM "pl_opfor_cmd_vic_2.fsm";
//     pl_active_opfor_vic_grps pushback (group (driver _x));
// } forEach (vehicles select {side _x == east});

// {
//     if !(_x in pl_active_opfor_vic_grps) then {
//         _x execFSM "pl_opfor_cmd_inf_2.fsm";
//     };
// } forEach (allGroups select {side _x == east});

