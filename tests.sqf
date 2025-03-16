pl_get_to_cover_positions = {
    params ["_unitsRaw", "_cords", "_watchDir", ["_defenceAreaSize", 20], ["_allowGarrion", true], ["_losWatchPos", []], ["_force", true], ["_defendMode", 0], ["_isAtk", false]];
    
    _defenceWatchPos = _cords getPos [250, _watchDir];
    _defenceWatchPos = ASLToATL _defenceWatchPos;
    _defenceWatchPos = [_defenceWatchPos#0, _defenceWatchPos#1, 2];
    _defenceWatchPos = ATLToASL _defenceWatchPos;


    _watchPos = _cords getPos [1000, _watchDir];
    [_watchPos, 1] call pl_convert_to_heigth_ASL;

    _buildings = nearestTerrainObjects [_cords, ["BUILDING", "RUIN", "HOUSE"], _defenceAreaSize, true];
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 2 and !(typeOf _x in pl_building_type_blk_lst)) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    _validPos = [];
    private _winPos = [];
    private _sideRoadPos = [];
    _allPos = [];

    private _debugMarkers = [];
    private _debugHelpers = [];

    if (_defendMode != 2 and _allowGarrion) then {
        {
            private _building = _x;
            // pl_draw_building_array pushBack [_group, _building];
            private _bPos = [_building] call BIS_fnc_buildingPositions; 
            _vPosCounter = 0;
            {
                _bP = _x;
                _allPos pushBack _bP;
                private _window = false;

                // _samplePosASL = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 1.04152];
                _samplePosASL = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 1.5];

                _buildingDir = getDir _building;
                for "_d" from 0 to 361 step 4 do {
                    _counterPos = _samplePosASL vectorAdd [6 * (sin (_buildingDir + _d)), 6 * (cos (_buildingDir + _d)), 0];

                    if !((lineIntersects [_counterPos, _counterPos vectorAdd [0, 0, 20]])) then {
                        _helper2 = objNull;
                        // _helper2 = createVehicle ["Sign_Sphere25cm_F", _counterPos, [], 0, "none"];
                        // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                        // _helper2 setposASL _counterPos;
                        // _debugHelpers pushback _helper2;

                        // _m = createMarker [str (random 1), _counterPos];
                        // _m setMarkerType "mil_dot";
                        // _m setMarkerSize [0.3, 0.3];
                        // _m setMarkerColor "colorRED";
                        // _debugMarkers pushback _m;

                        _interSectsWin = lineIntersectsWith [_samplePosASL, _counterPos, objNull, objNull, true];
                        _checkDir = _samplePosASL getDir _counterPos;
                        if (!(lineIntersects [_samplePosASL, _counterPos, _helper2, objNull]) and (_checkDir > (_watchDir - 45) and _checkDir < (_watchDir + 45))) then {
                            // _window = true
                            _bPos deleteAt (_bPos find _bP);
                            _validPos pushBackUnique _bP;
                            _winPos pushBackUnique _bP;
                            _vPosCounter = _vPosCounter + 1;

                            // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];

                            // _helper1 = createVehicle ["Sign_Sphere25cm_F", _samplePosASL, [], 0, "none"];
                            // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                            // _helper1 setposASL _samplePosASL;
                            // _debugHelpers pushback _helper1;

                            // _m = createMarker [str (random 1), _samplePosASL];
                            // _m setMarkerType "mil_dot";
                            // _m setMarkerSize [1, 1];
                            // _m setMarkerColor "colorBlue";
                            // _debugMarkers pushback _m
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
                _validBuildings deleteAt (_validBuildings find _building);
                // if (_winPos isNotEqualTo []) then {
                //     _validPos pushBack (([_winPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0);
                // } else {
                //     _validPos pushBack (([_bPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0);
                // };
                // _winPos = [_winPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
            };

        } forEach _validBuildings;
    };
    // deploy packed static weapons if no buildings
    private _isStatic = [false, []];

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _units = [];
    private _mgGunners = [];
    private _atSoldiers = [];
    private _missileAtSoldiers = [];
    private _atEscord = objNull;
    private _medic = objNull;


    // classify units
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun" and secondaryWeapon _x == "" and _x != _medic and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _units pushBackUnique _x;
        };
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun" and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _mgGunners pushBackUnique _x;
        };
        if (([secondaryWeapon _x] call BIS_fnc_itemtype) select 1 in ["MissileLauncher", "RocketLauncher"]) then {
            _atSoldiers pushBackUnique _x;
        };
    } forEach _unitsRaw;

    {_units pushBackUnique _x} forEach _atSoldiers;
    {_units pushBackUnique _x} forEach _mgGunners;
    if !(isNull _medic) then {_units pushBack _medic};


    _posOffsetStep = _defenceAreaSize / (round ((count _units) / 2));
    private _posOffset = 0; //+ _posOffsetStep;
    private _maxOffset = _posOffsetStep * (round ((count _units) / 2));

    // find static weapons
    _coverCount = 0;
    private _ccpPos = [];
    private _safePos = [];
    _buildingMarkers = [];
    _buildingWallPosArray = [];

    // Find Valid Positions in and around uildings , behind Walls and beside roads 
    if (!(_buildings isEqualTo []) and _defendMode != 2) then {

        _buildings = [_buildings, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _covers = [];
        
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

        if (_safePos isNotEqualTo []) then {
            _ccpPos = ([_safePos, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0;
        };


        // {
        //     _m = createMarker [str (random 1), _x];
        //     _m setMarkerType "mil_dot";
        //     _m setMarkerSize [0.5, 0.5];
        // } forEach _buildingWallPosArray;

    };

    private _walls = nearestTerrainObjects [_cords, ["WALL", "RUIN", "FENCE", "ROCK", "ROCKs", "HIDE"], _defenceAreaSize, true];
    private _trueWalls = nearestTerrainObjects [_cords, ["WALL", "RUIN", "FENCE"], _defenceAreaSize, true];
    _walls = _walls + (nearestObjects [_cords, ["Strategic"], _defenceAreaSize]);
    private _validWallPos = [];
    private _validPrefWallPos = [];

    {
        if !(isObjectHidden _x) then {

            _leftPos = (getPos _x) getPos [1.5, getDir _x];
            _rightPos = (getPos _x) getPos [1.5, (getDir _x) - 180];

            _visLeftPos = ATLtoASL [_leftPos#0, _leftPos#1, (_leftPos#2) + 1.6];
            _visrightPos = ATLtoASL [_rightPos#0, _rightPos#1, (_rightPos#2) + 1.6];
            
            _helper1 = objNull;
            // _helper1 = createVehicle ["Sign_Sphere25cm_F", _visRightPos, [], 0, "none"];
            // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
            // _helper1 setposASL _visLeftPos ;
            // _debugHelpers pushback _helper1;

            _helper2 = objNull;
            // _helper2 = createVehicle ["Sign_Sphere25cm_F", _visLeftPos, [], 0, "none"];
            // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];
            // _helper2 setposASL _visRightPos ;
            // _debugHelpers pushback _helper2;

            if (_defendMode == 1) then {_watchPos = _cords getPos [1000, _cords getDir _x]};

            if (lineIntersectsObjs [_visLeftPos, _visRightPos, _helper2, _helper1] isEqualTo []) then {
                _validPrefWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
            } else {
                if (_x in _trueWalls) then {
                    _validWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                };
                // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(1,1,0,1)'];
            };
        };
    } forEach _walls;

    _validWallPos = [_validWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _validPrefWallPos = [_validPrefWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

    private _roads = _cords nearRoads _defenceAreaSize;
    if ((count _roads) >= 2) then {
        _roads = [_roads, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        private _roadDir = (getpos (_roads#1)) getDir (getpos (_roads#0));

        if (_roadDir > (_watchDir - 55) and _roadDir < (_watchDir + 55)) then {

            _roads = [_roads, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
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
                // _m setMarkerColor "colorOPFOR";
                // _debugMarkers pushback _m;

            } forEach [90, -90];
        };
    };

    _validPos = _validPos + _validPrefWallPos; 
    _validPos = _validPos + _buildingWallPosArray;
    _validPos = _validPos + _sideRoadPos;
    _validPos = _validPos + _validWallPos;

    // Find save position for the medic to stage
    if (_ccpPos isEqualTo []) then {

        private _rearPos = _cords getPos [_defenceAreaSize * 0.8, _watchDir - 180];
        private _lineStartPos = _rearPos getPos [_defenceAreaSize / 2, _watchDir - 90];
        private _posCandidates = [];
        private _ccpPosOffset = 0;
        for "_l" from 0 to 20 do {
            _cPos = _lineStartPos getPos [_ccpPosOffset, _watchDir + 90];
            _ccpPosOffset = _ccpPosOffset + (_defenceAreaSize / 20);
            if !([_cPos] call pl_is_indoor) then {
                _posCandidates pushBack _cPos;
            };
        };
        _posCandidates = [_posCandidates, [], {_x distance2D _cords}, "DESCEND"] call BIS_fnc_sortBy;
        _ccpPos = ([_posCandidates, [], {[objNull, "VIEW", objNull] checkVisibility [_x, [_x getPos [50, _watchDir], 0.5] call pl_convert_to_heigth_ASL]}, "DESCEND"] call BIS_fnc_sortBy)#0;

    };

    // create an array of positions in a line with LOS scan to detirmen the positions with the best LOS towards the targetarea. These positions will be used by MG und AT gunners and static weapons

    private _losOffset = 3;
    private _maxLos = 0;
    private _validLosPos = [];
    private _accuracy = 16;
    private _losStartLine = _cords getPos [1, _watchDir];
    private _losPos = [];


    if (_validPos isNotEqualTo [] and _defendMode != 2) then {
        _losStartLine = ([_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0;
    };

    for "_j" from 0 to _accuracy do {
        if (_j % 2 == 0) then {
            _losPos = (_losStartLine getPos [-0.5, _watchDir]) getPos [3 - _losOffset, _watchDir + 90];
            // _losPos = _losStartLine getPos [3 - _losOffset, _watchDir + 90];
            // _losPos = _losStartLine getPos [_losOffset, _watchDir + 90];
        }
        else
        {
            _losPos = (_losStartLine getPos [-0.5, _watchDir]) getPos [3 - _losOffset, _watchDir - 90];
            // _losPos = _losStartLine getPos [3 - _losOffset, _watchDir - 90];
            // _losPos = _losStartLine getPos [_losOffset, _watchDir - 90];
        };
        _losOffset = _losOffset + (_defenceAreaSize / _accuracy);

        _losPos = [_losPos, 1.75] call pl_convert_to_heigth_ASL;

        

        private _losCount = 0;
        for "_l" from 10 to 600 step 50 do {

            _checkPos = _losPos getPos [_l, _watchDir];
            _checkPos = [_checkPos, 1.75] call pl_convert_to_heigth_ASL;
            _vis = lineIntersectsSurfaces [_losPos, _checkPos, objNull, objNull, true, 1, "FIRE"];

            if !(_vis isEqualTo []) exitWith {};

            // _m = createMarker [str (random 1), _checkPos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerColor "colorOrange";
            // _m setMarkerSize [0.5, 0.5];
            // _debugMarkers pushback _m;

            _losCount = _losCount + 1;
        };

        if !(isOnRoad [_losPos#0, _losPos#1, 0]) then {

            // systemChat (str _losPos);



            _validLosPos pushback [_losPos, _losCount];
        };
    };


    _validLosPos = [_validLosPos, [], {_x#1}, "DESCEND"] call BIS_fnc_sortBy;
    _winPos = [_winPos, [], {_x#2}, "DESCEND"] call BIS_fnc_sortBy;

    {
        if (((_x#2) > 6) and !([_x] call pl_is_indoor)) then {
            _validLosPos = [[_x, 10]] + _validLosPos;
        };
    } forEach _winPos;


    if (_group getVariable ["pl_allow_static", false]) then {
        _isStatic = [_units, _group, (_validLosPos#0)#0, _watchPos, _cords] call pl_static_unpack;

        if (_isStatic#0) then {
            _validLosPos deleteAt (_validLosPos find (_validLosPos#0));
            _units deleteAt (_units find ((_isStatic#1)#0));
        };
    };
    

    private _mgPos = [];

    for "_i" from 0 to (count (_mgGunners + _atSoldiers)) - 1 do {
        _mgPos pushback ((_validLosPos#_i)#0);

        if (((_validLosPos#_i)#0) in _validPos) then {
            _validPos deleteAt (_validPos find ((_validLosPos#_i)#0));
        };
        _validLosPos deleteAt (_validLosPos find (_validLosPos#_i));
    };

    private _mgIdx = 0;
    private _losIdx = 0;
    private _debugMColor = "colorBlack";
    private _defPos = [];
    private _pos360 = [];

    // if (_defendMode == 1 and (_buildings isEqualTo [])) then {
    //     _validPos = [_group, _cords, pl_garrison_area_size] call pl_get_360;
    // };
    if (_defendMode == 1) then {
        if ((count _units) > 1) then {
            _pos360 = [_group, _cords, pl_garrison_area_size] call pl_get_360;
        } else {
            _pos360 = [_cords];
        };
    };

    sleep 0.5;


    // itterate over all units in group an choosing the bes possible position

    for "_i" from 0 to (count _units) - 1 step 1 do {

        private _cover = 0;
        private _isValidPos = false;
        _unit = _units#_i;
        _unitWatchDir = _watchDir;

        // move to optimal Pos first
        if (_i < (count _validPos) and _defendMode != 2) then {
            _defPos = _validPos#_i;
            _isValidPos = true;
            
            // if 360 choose valid position within 8m of 360 position
            if (_defendMode == 1) then {
                _defpos = ([_validPos, [], {_x distance2D (_pos360#_i)}, "ASCEND"] call BIS_fnc_sortBy)#0;
                if (_defpos distance2D (_pos360#_i) >= 8) then {
                    _defPos = _pos360#_i;
                } else {
                    _validPos deleteAt (_validPos find _defpos);
                };
            };

            _debugMColor = "colorBlack";
        }
        else
        {
            _cover = 5;
            // if no valid pos avaible move to left or right side of best cover deploy along a line
            if (_validPos isEqualTo [] or _defendMode == 2) then {
                _dirOffset = 90;
                if (_i % 2 == 0) then {_dirOffset = -90};
                _defPos = _cords getPos [_posOffset, _watchDir + _dirOffset];
                if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
                _debugMColor = "colorBlue";

                // dont stay on road
                if (isOnRoad [_defPos#0, _defPos#1, 0]) then {
                    if (_losIdx > (count _validLosPos) - 1) then {_losIdx = 1};
                    _defPos = (_validLosPos#_losIdx)#0;
                    _losIdx = _losIdx + 2;
                    _debugMColor = "colorOrange";
                };
            }
            else
            {
                // if all pos spend deploy along line
                if (_validLosPos isNotEqualTo []) then {
                    if (_losIdx > (count _validLosPos) - 2) then {_losIdx = 0};
                    _defPos = (_validLosPos#_losIdx)#0;
                    _losIdx = _losIdx + 2;
                    _debugMColor = "colorOrange";
                };
            };

            // if 360 move to 360 pos
            if (_defendMode == 1) then {
                _defPos = _pos360#_i;
                _debugMColor = "colorBlue";
            };
        };

        // select best Medic Pos
        if ((!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) and _defendMode != 1) then {
            if (_unit == _medic) then {
                _defPos = _ccpPos;
                _debugMColor = "colorGreen";
                _cover = 5;
            };
        };

        // select Best Mg Pos
        if ((([secondaryWeapon _unit] call BIS_fnc_itemtype) select 1) in ["MissileLauncher", "RocketLauncher"]) then {
            _defPos = (_mgPos#_mgIdx);
            _mgIdx = _mgIdx + 1;
            _debugMColor = "colorRed";
            _cover = 2;
            _unit setVariable ["pl_sec_defPos", (_validLosPos#(round ((count _validLosPos) / 2)))#0];
        };

        if ((([primaryweapon _unit] call BIS_fnc_itemtype) select 1 == "MachineGun") and _defendMode != 1) then {
            _defPos = (_mgPos#_mgIdx);
            _mgIdx = _mgIdx + 1;
            _debugMColor = "colorRed";
            _cover = 2;
        };

        // no good positions escape
        if (isNil "_defPos") then {
            if !(_covers isEqualTo []) then {
                _defPos = getpos (selectRandom _covers);
                _debugMColor = "colorYellow";
            } else {
                _defPos = [[[_cords, _defenceAreaSize / 2]], ["water"]] call BIS_fnc_randomPos;
                _debugMColor = "colorYellow";
            };
            // _debugMColor = "colorGrey";
        };

        _defPos = ATLToASL _defPos;
        _unitPos = "UP";
        if ((!([_defPos] call pl_is_indoor) and !_isValidPos) or _defendMode == 1) then {
            _cover = 10;
        };

        _defPos = ASLToATL _defPos;

        if (_defendMode == 1) then {
            _watchDir = _cords getDir _defPos;
            _unitWatchDir = _watchDir;
        };

        // _m = createMarker [str (random 1), _defPos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerSize [0.5, 0.5];
        // _m setMarkerColor _debugMColor;
        // _debugMarkers pushback _m;

        // _helper = createVehicle ["Sign_Sphere25cm_F", _defPos, [], 0, "none"];
        // _helper setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];
        // _debugHelpers pushback _helper;

        // unit moveTo logic
        [_unit, _defPos, _watchPos, _unitWatchDir, _unitPos, _cover, _cords, _defenceAreaSize, _defenceWatchPos, _watchDir, _atEscord, _medic, _ccpPos, _force, _isAtk] spawn {
            params ["_unit", "_defPos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_cords", "_defenceAreaSize", "_defenceWatchPos", "_defenceDir", "_atEscord", "_medic", "_ccpPos", "_force", "_isAtk"];
            private ["_check"];

            if (!(alive _unit) or isNil "_defPos") exitWith {};

            _unit setHit ["legs", 0];
            _unit setVariable ["pl_def_pos", _defPos];
            _unit setVariable ["pl_def_pos_sec", []];
            _unit setVariable ["pl_engaging", true];
            if (_force) then {
                _unit disableAI "AUTOCOMBAT";
                _unit disableAI "AUTOTARGET";
                _unit disableAI "TARGET";
                _unit disableAI "SUPPRESSION";
            };
            if (_isAtk) then {
                _unit forceSpeed 2;
            };
            _unit setUnitTrait ["camouflageCoef", 0.7, true];
            _unit setVariable ["pl_damage_reduction", true];
            // _unit forceSpeed 20;
            _unit doMove _defPos;
            sleep 1;
            private _counter = 0;
            private _posNotReached = false;

            // while {alive _unit and ((group _unit) getVariable ["onTask", false]) and (_unit distance _defPos) > 0.25 and !(unitReady _unit)} do {
            //     _time = time + 2;
            //     waitUntil {sleep 0.25; time > _time or !((group _unit) getVariable ["onTask", false]) or (_unit distance _defPos) < 2};
            //     _check = [_unit, _defPos, _counter] call pl_position_reached_check;
            //     if (_check#0) exitWith {_posNotReached = _check#3};
            //     _counter = _check#1;
            // };

            // if (_posNotReached) then {
            //     _unit domove _defPos;
            // };

            waitUntil {!alive _unit or !((group _unit) getVariable ["onTask", false]) or unitReady _unit};

            if (_unit distance2D _defPos > 2) then {
                _unit doMove _defPos;
                while {alive _unit and ((group _unit) getVariable ["onTask", false]) and (_unit distance _defPos) > 0.25 and !(unitReady _unit)} do {
                    _time = time + 2;
                    waitUntil {sleep 0.25; time > _time or !((group _unit) getVariable ["onTask", false]) or (_unit distance _defPos) < 2};
                    _check = [_unit, _defPos, _counter] call pl_position_reached_check;
                    if (_check#0) exitWith {_posNotReached = _check#3};
                    _counter = _check#1;
                };

                if (_posNotReached) then {
                    _unit domove _defPos;
                };

            };

            // sleep 0.25;
            _unit forceSpeed -1;
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "TARGET";
            _unit enableAI "SUPPRESSION";
            _unit setUnitPos "AUTO";

            if !((group _unit) getVariable ["onTask", true]) exitWith {};

            if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                if ((group _unit) getVariable ["pl_sop_def_ATEngagement", false]) then {
                    [_unit, group _unit, _cords, _defenceAreaSize, _defenceDir, _defPos, _atEscord] spawn pl_at_defence;
                    [_unit, _defPos, [], _ccpPos] spawn pl_at_defence_change_firing_pos;

                };
                sleep 0.1;
            } else {
                [_unit] spawn pl_defence_take_cover_eh;
            };

            if (_unit == _medic) then {
                [(group _unit), _unit, _ccpPos, _defenceAreaSize * 2] spawn pl_defence_ccp;
            };
           
            if ([_defPos] call pl_is_forest or [_defPos] call pl_is_city) then {
                [_unit, round (_cover * 0.5), _unitWatchDir, true] spawn pl_find_cover;
            } else {
                [_unit, _cover, _unitWatchDir, true] spawn pl_find_cover;
            };

            sleep 1;
            _unit setVariable ["pl_in_position", true];
        };
    };
};


pl_quick_suppress_unit_random_pos = {
    params ["_unit", "_cords", ["_area", 20]];

    private _targetPos = [[[_cords, _area]], nil] call BIS_fnc_randomPos;
    _targetPos = ATLtoASL _targetpos;
    _targetPos = _targetPos vectorAdd [0,0,1.5];

    [_targetPos, _unit] spawn {
        params ["_targetPos", "_unit"];

        sleep 1.5;

        _targetPos = [_targetPos, _unit] call pl_get_suppress_target_pos;

        // _m = createMarker [str (random 1), _targetPos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerSize [0.5, 0.5];

        // _helper1 = createVehicle ["Sign_Sphere25cm_F", _targetpos, [], 0, "none"];
        // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
        // _helper1 setposASL _targetpos;

        if ((_targetPos distance2D _unit) > pl_suppression_min_distance and ([_unit, _targetPos] call pl_friendly_check)) then {

            // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];

            _unit doWatch _targetPos;
            _unit doSuppressiveFire _targetPos;
        };
    };
};

 // and (_targetPos isNotEqualTo [0,0,0])

pl_quick_suppress = {
    params ["_unit", "_target", ["_light", false]];

    if (isNil "_target") exitWith {false};
    if !(alive _target) exitWith {false};
        
    [_target, _unit] spawn {
        params ["_target", "_unit"];

        sleep 1.5;

        private _targetPos = getPosASL _target;
        _targetPos = [_targetPos, _unit] call pl_get_suppress_target_pos;

        // _m = createMarker [str (random 1), _targetPos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerSize [0.5, 0.5];

        // _helper1 = createVehicle ["Sign_Sphere25cm_F", _targetpos, [], 0, "none"];
        // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
        // _helper1 setposASL _targetpos;

        if ((_targetPos distance2D _unit) > pl_suppression_min_distance and ([_unit, _targetPos] call pl_friendly_check) and _targetPos isNotEqualTo [0,0,0]) then {

            _unit doWatch _targetPos;
            _unit doSuppressiveFire _targetPos;
        };
    };
    true
};