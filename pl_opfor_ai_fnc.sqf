// pl_opfor_enhanced_ai = true;
// if !(pl_opfor_enhanced_ai) exitwith {};

pl_opfor_pow_pos = getPos player;

pl_opfor_ai_helper_debug = {
	params ["_grp"];

    _color = '#(argb,8,8,3)color(1,1,1,1)';
	_leaderPos = getPosATLVisual (leader _grp) vectorAdd [0,0,2];
    _helper1 = createVehicle ["Sign_Sphere25cm_F", _leaderPos, [], 0, "none"];
    _helper1 setposATL _leaderPos;

	while {True} do {
	    switch (_grp getVariable ["pl_opf_task", "none"]) do { 
	    	case "none" : {_color = '#(argb,8,8,3)color(1,1,1,1)'}; 
	    	case "cover" : {_color = '#(argb,8,8,3)color(0,0,1,1)'};
	    	case "suppress" : {_color = '#(argb,8,8,3)color(1,0.5,0,1)'}; 
	    	case "advance" : {_color = '#(argb,8,8,3)color(0,1,0,1)'}; 
	    	case "assault" : {_color = '#(argb,8,8,3)color(1,0,0,1)'};
	    	case "overwatch" : {_color = '#(argb,8,8,3)color(1,0.5,0.2,1)'}; 
	    	default {_color = '#(argb,8,8,3)color(1,1,1,1)'}; 
	    };
		_leaderPos = getPosATLVisual (leader _grp) vectorAdd [0,0,2];
		_helper1 setposATL _leaderPos;
    	_helper1 setObjectTexture [0, _color];
		sleep 0.5;
	};
};


pl_opfor_reset = {
	params ["_grp"];

	_grp setvariable ["pl_opf_in_pos", false];
	{
        _unit = _x;
        // if ((currentCommand _unit) isEqualTo "SUPPORT") then {
        //     [_unit] spawn pl_hard_reset;
        // };
        if !(_grp getVariable ["pl_on_hold", false]) then {_unit enableAI "PATH"};
        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "COVER";
        _unit enableAI "ANIM";
        _unit enableAI "FSM";
        _unit enableAI "AIMINGERROR";
        _unit enableAI "WEAPONAIM";
        _unit setUnitPos "AUTO";
        _unit setUnitTrait ["camouflageCoef", 1, true];
        _unit setVariable ["pl_damage_reduction", false];
        // sleep 0.5;
        _unit doWatch objNull;
        _unit allowDamage true;
        if (vehicle _unit == _unit) then {
            _unit doFollow (leader _grp);
        };
    } forEach (units _grp);

    _leader = leader _grp;
    (units _grp) joinSilent _grp;
    _grp selectLeader _leader;

    [_grp, (currentWaypoint _grp)] setWaypointType "MOVE";
    [_grp, (currentWaypoint _grp)] setWaypointPosition [getPosASL (leader _grp), -1];
    sleep 0.1;
    deleteWaypoint [_grp, (currentWaypoint _grp)];
    for "_i" from count waypoints _grp - 1 to 0 step -1 do {
        deleteWaypoint [_grp, _i];
    };
};

pl_opfor_auto_unstuck = {
    params ["_grp"];
    {
        _unit = _x;
        if ((_unit distance2D leader (group _unit)) > 400) then {
            // doStop _unit;
            // _pos = (getPos _unit) findEmptyPosition [0, 100, typeOf _unit];
            // _unit setPos _pos;
            _unit setPos ((getPos _unit) vectorAdd [0.5 - (random 1), 0.5 - (random 1), 0]);
            _unit doFollow leader (group _unit);
            _unit switchMove "";
            _unit enableAI "PATH";
            _unit setUnitPos "AUTO";
            if ([getPos _unit] call pl_is_indoor) then {
                _b = nearestBuilding (getPos _unit);
                _unit disableCollisionWith _b;
                [_unit, _b] spawn {
                    sleep 15;
                    (_this#0) enableCollisionWith (_this#1);
                };
            };
        };
    } forEach (units _grp);
};

pl_opfor_find_cover = {
    params ["_unit", "_watchPos", "_watchDir", "_radius", "_moveBehind", ["_fullCover", false], ["_inArea", ""], ["_fofScan", false]];
    private ["_valid"];

    _covers = nearestTerrainObjects [getPos _unit, pl_valid_covers, _radius, true, true];
    _watchPos = (getPos _unit) getPos [1000, _watchDir];
    if ((count _covers) > 0) then {
        {

            if !(_x in pl_covers) exitWith {
                pl_covers pushBack _x;
                _coverPos = getPos _x;
                _unit doMove _coverPos;
                // [_unit, true] call pl_enable_force_move; 
                sleep 0.5;
                waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["pl_opf_task", "cover"] == "cover") or unitReady _unit};
                // [_unit, false] call pl_enable_force_move;
                if ((group _unit) getVariable ["pl_opf_task", "cover"] == "cover") then {
                    if ((group _unit) getVariable ["onTask", true]) then {
                        _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
                        _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
                        _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
                        if (_visP isEqualTo []) then {
                            _unit setUnitPos "DOWN";
                        } else {
                            _unit setUnitPos "MIDDLE";
                        };

                        doStop _unit;
                        _unit doWatch _watchPos;
                        _unit disableAI "PATH";
                    };
                    [_x] spawn {
                        params ["_cover"];
                        sleep 5;
                        pl_covers deleteAt (pl_covers find _cover);
                    };
                };
            };
        } forEach _covers;

        if ((unitPos _unit) == "Auto" and ((group _unit) getVariable ["pl_opf_task", "cover"] == "cover")) then {
            _unit setUnitPos "DOWN";
            doStop _unit;
            _unit doWatch _watchPos;
            _unit disableAI "PATH";
        };
    }
    else
    {
        _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
        _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
        _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
        if (_visP isEqualTo []) then {
            _unit setUnitPos "DOWN";
        } else {
            _unit setUnitPos "MIDDLE";
        };
        doStop _unit;
        _unit doWatch _watchPos;
        _unit disableAI "PATH";
    };
};

pl_opfor_get_cover_pos = {
    params ["_coverPos", "_watchDir", "_radius"];
    private ["_valid"];

    _covers = nearestTerrainObjects [getPos _unit, pl_valid_covers, _radius, true, true];
    _watchPos = (getPos _unit) getPos [1000, _watchDir];
    private _unitPos = "MIDDLE";
    if ((count _covers) > 0) then {
        {
            if !(_x in pl_covers) exitWith {
                pl_covers pushBack _x;
                _coverPos = (getPos _x) getPos [1.5, _watchDir - 180];
                _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
                _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
                _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
                if (_visP isEqualTo []) then {
                    _unitPos = "DOWN";
                } else {
                    _unitPos = "MIDDLE";
                };
                [_x] spawn {
                    params ["_cover"];
                    sleep 5;
                    pl_covers deleteAt (pl_covers find _cover);
                };
            };
        } forEach _covers;
    }
    else
    {
        _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
        _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
        _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
        if (_visP isEqualTo []) then {
            _unitPos = "DOWN";
        } else {
            _unitPos = "MIDDLE";
        };
    };
    [_coverPos, _unitPos]
};

pl_opfor_advance = {
	params ["_grp"];

    _grp setvariable ["pl_opfor_advance", true];

	if (behaviour (leader _grp) != "SAFE") then {
		{
			_x disableAI "AUTOCOMBAT";
			_x setCombatBehaviour "AWARE";
			_x setUnitPos "AUTO";
			if !(_x == leader _grp) then {
				_x doFollow (leader _grp);
			};
		} forEach (units _grp);
		_grp setBehaviour "AWARE";
		_grp setFormation "LINE";
		_grp setSpeedMode "NORMAL";
		_grp allowFleeing 0.2;
	};
};

pl_opfor_defend_position = {
    params ["_grp"];
    private ["_cords", "_watchDir", "_medicPos", "_buildingWallPosArray", "_buildingMarkers", "_watchPos", "_defenceWatchPos", "_markerAreaName", "_markerDirName", "_covers", "_buildings", "_doorPos", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon", "_unitWatchDir", "_vPosCounter", "_defenceAreaSize", "_mgPosArray", "_losPos", "_mgOffset", "_atEscord"];

    [_grp] spawn pl_opfor_reset;

    (leader _grp) playActionNow "GestureCover";

    // sleep 0.05;

    sleep 0.5;

    _grp setvariable ["pl_opf_in_pos", true];

    private _targets = (((getPos (leader _grp)) nearEntities [["Man", "Car", "Tank", "Truck"], 1500]) select {(side _x) == playerSide and ((leader _grp) knowsAbout _x) > 0});
    if (count _targets > 0) then {
        private _target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
        _units = units _grp;
        _cords = getPos (([_units, [], {_target distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0);
    	_watchDir = (leader _grp) getDir _target;
    } else {
        _cords = getPos (leader _grp);
        _watchDir = getDir (leader _grp);
    };

    _defenceAreaSize = 50;
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
                    if ((({_x == _building} count _interSectsWin) == 0) and (_checkDir > (_watchDir - 45) and _checkDir < (_watchDir + 45))) exitWith {
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
            _validPos pushBack (selectRandom _bPos);
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
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun" and secondaryWeapon _x == "" and  _x != (leader _grp) and alive _x) then {
            _units pushBackUnique _x;
        };
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun" and alive _x) then {
            _mgGunners pushBackUnique _x;
        };
        if (secondaryWeapon _x != "" and alive _x) then {
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

    _grp allowFleeing 0;
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
            // _buildingMarkers pushBack _m;
            _mPos = getMarkerPos _m;
            _mDir = markerdir _m;
            _mSize = getMarkerSize _m;
            _a2 = ((_mSize#0) * 1) * ((_mSize#0) * 1);
            _b2 = ((_mSize#1) * 1) * ((_mSize#1) * 1);
            _c2 = _a2 + _b2;
            _d = sqrt _c2;
            deleteMarker _m;

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
        _covers = nearestTerrainObjects [_cords, pl_valid_covers, _defenceAreaSize, true, true];
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

        _unit = _units#_i;
        _unitWatchDir = _watchDir;

        // move to optimal Pos first
        if (_i < (count _validPos)) then {
            _defPos = _validPos#_i;
            _debugMColor = "colorBlue";
        }
        else
        {
            _cover = true;
            if (_buildings isEqualTo []) then {
                _dirOffset = 90;
                if (_i % 2 == 0) then {_dirOffset = -90};
                _defPos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _cords;
                _defPos = ([_defPos, _watchDir, 25] call pl_opfor_get_cover_pos)#0;
                if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
                _debugMColor = "colorBlue";
            }
            else
            {
                if (_losIdx > (count _validLosPos) - 1) then {_losIdx = 1};
                _defPos = (_validLosPos#_losIdx)#0;
                _defPos = ([_defPos, _watchDir, 10] call pl_opfor_get_cover_pos)#0;
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

        if (isNil "_defPos") then {
            if !(_covers isEqualTo []) then {
                _defPos = getpos (selectRandom _covers);
                _defPos = ([_defPos, _watchDir, 25] call pl_opfor_get_cover_pos)#0;
            } else {
                _defPos = _cords findEmptyPosition [0, _defenceAreaSize];
                _defPos = ([_defPos, _watchDir, 25] call pl_opfor_get_cover_pos)#0;
            };
            _debugMColor = "colorGrey";
        };

        _defPos = ATLToASL _defPos;
        private _unitPos = "UP";
        if !([_defPos] call pl_is_indoor) then {
            _unitPos = "MIDDLE";
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

            if (!(alive _unit) or isNil "_defPos") exitWith {};
            if (vehicle _unit != _unit) exitWith {};

            waitUntil {sleep 0.5; unitReady _unit or !alive _unit};

            // _m = createMarker [str (random 1), _defPos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];

            if !(simulationEnabled _unit) then {
                _defPos set [2, 0];
                // _cover = [_defPos, _unitWatchDir, 5] call pl_opfor_get_cover_pos;
                _unit setPosATL _defPos;
                _unit setUnitPos _unitPos;
                _unit setDir _unitWatchDir;
                doStop _unit;
                _unit disableAI "PATH";
            } else {
                if !([getPos _unit] call pl_is_city) then {
    	            _unit setUnitPos (selectRandom ["DOWN", "MIDDLE"]);
    	            sleep (random 3);
    	        };

                // _unit setUnitPos "UP";
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
                // if !(_cover) then {
                    doStop _unit;
                    _unit disableAI "PATH";
                    _unit doWatch _watchPos;
                    _unit setUnitPos _unitPos;
                // }
                // else
                // {
                //     if ([_defPos] call pl_is_forest or [_defPos] call pl_is_city) then {
                //         [_unit, _watchPos, _unitWatchDir, 3, false] spawn pl_opfor_find_cover;
                //     } else {
                //         [_unit, _watchPos, _unitWatchDir, 10, false] spawn pl_opfor_find_cover;
                //     };
                // };
                // if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                //     [_unit, _watchPos, _unitWatchDir, 0, false, false, "", true] spawn pl_opfor_find_cover;
                //     // _m setMarkerColor "colorRed";
                // };
            };
        };
    };
};

pl_opfor_defence_suppression = {
    params ["_grp", "_watchPos", "_medic"];
    private ["_targetsPos", "_firers", "_time"];

    private  _time = time + 10;
    waitUntil {sleep 0.5;  time >= time or !(_grp getVariable ["pl_opf_in_pos", true]) };
    if !(_grp getVariable ["pl_opf_in_pos", true]) exitWith {};

    while {_grp getVariable ["pl_opf_in_pos", false]} do {
        // _allTargets = nearestObjects [_watchPos, ["Man", "Car"], 350, true];
        _enemyTargets = (_watchPos nearEntities [["Man", "Car"], 350]) select {(side _x) == playerSide and ((leader _grp) knowsAbout _x) > 0};
        if (count _enemyTargets > 0) then {
            _firers = [];
            {
                if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                    _firers pushBackUnique _x;
                    // _x setUnitTrait ["camouflageCoef", 0.5, false];
                    // _x setVariable ["pl_damage_reduction", true];
                } else {
                    if ((random 1) > 0.6) then {_firers pushBackUnique _x;}
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

              //   if ((_targetPos distance2D _unit) > 25) then {
              //        _unit doSuppressiveFire _targetPos;
              // //       _m = createMarker [str (random 1), _targetPos];
		      //       // _m setMarkerType "mil_dot";
		      //       // _m setMarkerSize [0.5, 0.5];
              //   };
              _unit doSuppressiveFire _target;
            } forEach _firers;

            _time = time + 10;
            waitUntil {sleep 1; time > _time or !(_grp getVariable ["pl_opf_in_pos", true])};
        };
        sleep 10;
    };
};


pl_opfor_flanking_move = {
	params ["_grp"];
	private ["_fankPos", "_targetPos"];

	[_grp] call pl_opfor_reset;

	sleep 0.5;

    [_grp] call pl_opfor_advance;

    sleep 0.5;

    _units = allUnits select {side _x == playerSide and alive _x and hcLeader (group _x) == player};
    _units = [_units, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy;
    _knownUnits = _units select {((leader _grp) knowsAbout _x) > 0.1};
    

    if !(_knownUnits isEqualto []) then {
        _targetPos = getPos (leader (group (_knownUnits#0)));
    } else {
        _targetPos = getPos (leader (group (_units#([0, (count _units) - 1] call BIS_fnc_randomInt))));
    };

    // if ((random 1) > 0.5) then {
    //     _targetPos = [_units] call pl_find_centroid_of_units;
    // };


	private _targetDir = (leader _grp) getDir _targetPos;
	private _flankDistance = ((leader _grp) distance2D _targetPos) * 0.7;
	_leftPos = (getPos (leader _grp)) getPos [_flankDistance, _targetDir + 90];
	_rightPos = (getPos (leader _grp)) getPos [_flankDistance, _targetDir - 90];

	_flankPos = ([[_leftPos, _rightPos], [], {count (_x nearEntities [["Man"], 350])}, "ASCEND"] call BIS_fnc_sortBy)#0;

	_grp addWaypoint [_flankPos, 0];
	_grp addWaypoint [_flankPos getPos [_flankDistance, _targetDir], 0];
	_grp addWaypoint [_targetPos, 0];
	{
		_x enableAI "PATH";
		_x disableAI "AUTOCOMBAT";
		_x disableAI "AUTOTARGET";
		_x disableAI "TARGET";
		_x disableAI "SUPPRESSION";
		_x setCombatBehaviour "AWARE";
		_x setUnitPos "AUTO";
		_x forceSpeed -1;
		if !(_x == leader _grp) then {
			_x doFollow (leader _grp);
		} else {
			_x doMove _flankPos;
			_x playActionNow "GestureAdvance";
		};
	} forEach (units _grp);
	_grp allowFleeing 0;
	_grp setBehaviour "AWARE";
	_grp setFormation "WEDGE";
	_grp setSpeedMode "FULL";
};

pl_opfor_attack_closest_enemy = {
	params ["_grp"];
	private ["_atkPos"];

	[_grp] call pl_opfor_reset;

	sleep 0.5;

    [_grp] call pl_opfor_advance;

    sleep 0.5;
	
	// [_grp] spawn {
	// params ["_grp"];


    _units = allUnits select {side _x == playerSide and alive _x and hcLeader (group _x) == player};
    _units = [_units, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy;
    _knownUnits = _units select {((leader _grp) knowsAbout _x) > 0.1};
    

    if !(_knownUnits isEqualto []) then {
    	_atkPos = getPos (leader (group (_knownUnits#0)));
    } else {
    	_atkPos = getPos (leader (group (_units#([0, (count _units) - 1] call BIS_fnc_randomInt))));
	};

    // if ((random 1) > 0.5) then {
    //     _atkPos = [_units] call pl_find_centroid_of_units;
    // };

    _wp = _grp addWaypoint [_atkPos, 20];
    _wp setWaypointType "MOVE";

	// {
	// 	_x disableAI "AUTOCOMBAT";
	// } forEach (units _grp);
	// _grp setBehaviour "AWARE";
	(leader _grp) doMove _atkPos;
	(leader _grp) playActionNow "GestureAdvance";
};

pl_opfor_assault = {
	params ["_grp"];

	[_grp] call pl_opfor_reset;

	sleep 0.5;

	_targets = (((getPos (leader _grp)) nearEntities [["Man"], 500]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0});
	_target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
	_targetGroupUnits = units (group _target);
	_targetPos = getPos _target;
	_grp allowFleeing 0.3;
	(leader _grp) playActionNow "GestureAttack";

	{
		_target = selectRandom _targetGroupUnits;
        _pos = getPosATL _target;
        _movePos = _pos vectorAdd [0.5 - (random 1), 0.5 - (random 1), 0];
        _x limitSpeed 15;
        _x doMove _movePos;
        _x setDestination [_movePos, "LEADER DIRECT", true];
        _x lookAt _target;
	} forEach (units _grp);
};


pl_opfor_auto_formation = {
    params ["_grp"];
    private ["_dest", "_distance"];

    _grp setFormation "LINE";
    while {sleep 0.5; {alive _x} count (units _grp) > 0} do {

        if ([getPos (leader _grp)] call pl_is_city) then {
            if (formation _grp != "VEE") then {
                _grp setFormation "VEE";
                (leader _grp) forceSpeed 3;
            }; 
        } else {
        	(leader _grp) forceSpeed -1;
            if ((currentWaypoint _grp) < count (waypoints _grp)) then {
                _dest = waypointPosition ((waypoints _grp) select (count (waypoints _grp) - 1));
                _distance = _dest distance2D (leader _grp);
                if (_distance > 100 and behaviour (leader _grp) != "COMBAT") then {
                    if (formation _grp != "STAG COLUMN") then {
                        _grp setFormation "STAG COLUMN";
                    };
                } else {
                    if (formation _grp != "LINE") then {
                        _grp setFormation "LINE";
                    };
                };
            } else {
                if (formation _grp != "LINE") then {
                    _grp setFormation "LINE";
                };
            };
        };
        sleep 8;
    };   
};

pl_opfor_find_overwatch = {
	params ["_grp"];

	_units = allUnits select {side _x == playerSide and alive _x};
	_units = [_units, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy;
	_knownUnits = _units select {((leader _grp) knowsAbout _x) > 0.5};
	if !(_knownUnits isEqualto []) exitWith {

		_atkPos = getPos (leader (group (_knownUnits#0)));
		_overwatchPos = [getPos (leader _grp), 500] call pl_find_highest_point;
		if (_overwatchPos distance2d _atkPos > 50) then {
			[_grp, _overwatchPos, _atkPos] spawn {
				params ["_grp", "_overwatchPos", "_atkPos"];

				[_grp] call pl_opfor_reset;
				sleep 0.2;

				// _grp allowFleeing 0;
				_grp addWaypoint [_overwatchPos, 0];
				{
					_x enableAI "PATH";
					_x disableAI "AUTOCOMBAT";
					_x disableAI "AUTOTARGET";
					_x disableAI "TARGET";
					_x disableAI "SUPPRESSION";
					_x setCombatBehaviour "AWARE";
					_x setUnitPos "AUTO";
					_x forceSpeed -1;
					if !(_x == leader _grp) then {
						_x doFollow (leader _grp);
					} else {
						_x doMove _overwatchPos;
						_x playActionNow "GestureAdvance";
					};
				} forEach (units _grp);
				_grp allowFleeing 0;
				_grp setBehaviour "AWARE";
				_grp setFormation "WEDGE";
				_grp setSpeedMode "FULL";
				// _grp setCombatMode "BLUE";

			};
		};
		[true, _overwatchPos, _atkPos]
	};
	[false, [0,0,0], [0,0,0]]
};

pl_opfor_join_grp = {
	params ["_grp", "_side"];

	private _targets = (((getPos (leader _grp)) nearEntities [["Man"], 300]) select {side _x == _side and ((group _x) getVariable ["pl_opf_task", "advance"]) != "flanking"});
	_targets = _targets - (units _grp);
	private _target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
	if !(isNil "_target") exitWith {
		private _targetGrp = group _target;
        _targetGrp setVariable ["pl_is_join_target", true];
		{
			if (alive _x) then {
				[_x] joinSilent _targetGrp;
				_x enableAI "PATH";
				_x disableAI "AUTOCOMBAT";
				_x setBehaviour "AWARE";
				_x setUnitPos "AUTO";
                _x doMove (getPos (leader _targetGrp));
				_x doFollow (leader _targetGrp);
                _x setVariable ["pl_no_centoid", true];
			};
		} forEach (units _grp);
        // deleteGroup _group;

        // retarded
        [_targetGrp] spawn {
            params ["_targetGrp"];
            sleep 2;
            [_targetGrp, (currentWaypoint _targetGrp)] setWaypointType "MOVE";
            [_targetGrp, (currentWaypoint _targetGrp)] setWaypointPosition [getPosASL (leader _targetGrp), -1];
            sleep 0.1;
            deleteWaypoint [_targetGrp, (currentWaypoint _targetGrp)];
            sleep 2;
            _targetGrp setVariable ["pl_is_join_target", nil];
        };

		true
	};
	false
};

pl_opfor_surrender = {
	params ["_grp"];

	sleep 5;

	[_grp] spawn pl_opfor_reset;

    _grp setvariable ["pl_has_surrendered", true];
	_surrenderGrp = createGroup [civilian , true];

	{
		if (alive _x) then {
			[_x] joinSilent _surrenderGrp;
			_x setCaptive true;
			removeAllWeapons _x;
			_x disableAI "PATH";
			_x setUnitPos "DOWN";
			_x enableDynamicSimulation true;
			// [_x] spawn {
			// 	sleep 5;
			// 	(_this#0) playActionNow selectRandom ["agonyStart", "surrender"];
			// };
		};
	} forEach (units _grp) ;
	_surrenderGrp setBehaviour "CARELESS";
	_surrenderGrp setSpeedMode "LIMITED";

	// sleep 80;

	waitUntil {sleep 5; !((((getPos (leader _surrenderGrp)) nearEntities [["Man", "Tank", "Car"], 120]) select {side _x == playerSide}) isEqualto [])};

	{

		if (alive _x) then {
			[_x] spawn {
				(_this#0) setUnitPos "MIDDLE";
				sleep 3;
				(_this#0) playActionNow "surrender";
			};
			sleep 0.5 + (random 2);
		};
	} forEach (units _surrenderGrp) ;

	waitUntil {sleep 5; !((((getPos (leader _surrenderGrp)) nearEntities [["Man", "Tank", "Car"], 10]) select {side _x == playerSide}) isEqualto [])};

	{
		_x forceSpeed 1;
		_x enableAI "PATH";
		_x switchMove "";
		_x setUnitPos "UP";
		_x doMove pl_opfor_pow_pos;
	} forEach (units _surrenderGrp);
	_surrenderGrp addWaypoint [pl_opfor_pow_pos , 100];
};



pl_opfor_drop_cargo = {
	params ["_grp", "_vic", "_cargo", "_cargoGroups"];

	// [_grp] spawn pl_opfor_reset;

	// sleep 0.5;

    // (driver _vic) disableAI "PATH";
    doStop _vic;
    _vic forceSpeed 0;
	{
        _unit = _x;
        if !(_unit in (units _grp)) then {
            unassignVehicle _unit;
            doGetOut _unit;
            [_unit] allowGetIn false;
        };
    } forEach _cargo;

    {
        _x leaveVehicle _vic;
    } forEach _cargoGroups;
    private _cargoPers = [];

    waitUntil {sleep 0.5; (({vehicle _x != _x} count _cargo) == 0) or (!alive _vic)};
    sleep 2;
    // {_x enableAI "PATH"} forEach (units _grp);
    _vic forceSpeed -1;
    [_vic, _grp, _cargoGroups#0] spawn pl_opfor_support_inf;
	// (driver _vic) enableAI "PATH";
};

pl_opfor_support_inf = {
	params ["_vic", "_grp", "_allyGrp"];

    [_grp] spawn pl_opfor_reset;

    sleep 0.5;

	_vic limitSpeed 15;

	while {alive _vic and ({alive _x} count (units _allyGrp)) > 0} do {

		if (_vic distance2D (leader _allyGrp) > 40) then {
            _vic forceSpeed -1;
			_vic doMove (getpos (leader _allyGrp));
			_vic setDestination [getpos (leader _allyGrp),"VEHICLE PLANNED" , true];
		} else {
            doStop _vic;
            _vic forceSpeed 0;
			[_grp] call pl_opfor_vic_suppress;
		};
		sleep 20;
	};

	_vic limitSpeed 15;
};

pl_opfor_vic_suppress = {
	params ["_grp"];

    private _targets = (((getPos (leader _grp)) nearEntities [["Man", "Car", "Tank"], 600]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0});
    if !(_targets isEqualto []) then {
    	private _target = _targets#0;
	    {
	        if !((currentCommand _x) isEqualTo "Suppress") then {
	            _targetPos = [[[getPos _target, 30]], []] call BIS_fnc_randomPos;
	            _targetPos = ATLToASL _targetPos;
	            _vis = lineIntersectsSurfaces [eyePos _x, _targetPos, _x, vehicle _x, true, 1];
	            if !(_vis isEqualTo []) then {
	                _targetPos = (_vis select 0) select 0;
	            };
	            if ((leader _grp) distance2D _targetPos > 20) then {
	            	_x doSuppressiveFire _targetPos;
	            };
	        };
	    } forEach (units _grp);
	};
};

pl_opfor_vic_suppress_cont = {
	params ["_grp"];

	private _vic = vehicle (leader _grp);
	while {alive _vic and (speed _vic) <= 5} do {
        waitUntil {sleep 1, (behaviour (leader _grp)) == "COMBAT"};
		[_grp] call pl_opfor_vic_suppress;
		sleep 60;
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
