// pl_opfor_enhanced_ai = true;
// if !(pl_opfor_enhanced_ai) exitwith {};

pl_opfor_pow_pos = getPos player;
pl_opfor_retreat_zones = createHashMapFromArray [[[0,0,0], [0, 1000, 100000000]]];
pl_opfor_retreat_zone_size = 600;
pl_opfor_join_range = 150;
pl_opfor_cmd_objectives = [];
pl_opfor_cmd_idle_groups = [];
pl_opfor_retreat_time_adder = 120;
pl_opfor_all_objectives = [];
// pl_opfor_allow_ai_retreat = true;
// pl_opfor_allow_ai_surrender = true;

pl_opfor_ai_helper_debug = {
	params ["_grp"];

    private _debugMarker = createMarker [str (random 5), getPos (leader _grp)];
    _debugMarker setMarkerType "mil_dot";
    _debugMarker setMarkerSize [0.5, 0.5];

	while {pl_debug} do {
        _debugMarker setMarkerPos (getPos (leader _grp));
        _debugMarker setMarkerText (_grp getVariable ["pl_opfor_debug_marker_text", "None"]);
        sleep 0.5;
	};

};

// {
//     [_x] spawn pl_opfor_ai_helper_debug;
// } forEach (allGroups select {side _x == east});


pl_opfor_reset_execute = {
	params ["_grp"];

	_grp setvariable ["pl_opf_in_pos", false];


    [_grp] spawn {
        params ["_grp"];
        _grp setVariable ["pl_stop_event", true];
        sleep 2;
        _grp setVariable ["pl_stop_event", nil];
    };



	{
        _unit = _x;
        // if ((currentCommand _unit) isEqualTo "SUPPORT") then {
        //     [_unit] spawn pl_hard_reset;
        // };
        if !(_grp getVariable ["pl_on_hold", false]) then {_unit enableAI "PATH"};
        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "PATH";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "COVER";
        _unit enableAI "ANIM";
        _unit enableAI "FSM";
        _unit enableAI "AIMINGERROR";
        _unit enableAI "WEAPONAIM";
        _unit enableAI "FIREWEAPON";
        _unit setUnitPos "AUTO";
        _unit setUnitTrait ["camouflageCoef", 1, true];
        _unit setVariable ["pl_damage_reduction", false];
        _unit limitSpeed 5000;
        _unit forceSpeed -1;
        _unit doWatch objNull;
        _unit allowDamage true;
        _unit setHit ["legs", 0];
        // _unit setUnitTrait ["camouflageCoef", 1, true];
        // sleep 0.5;
        _unit doWatch objNull;
        _unit allowDamage true;
        if (vehicle _unit == _unit) then {
            _unit setPosASL (getPosASL _unit);
            _unit setDestination [getpos _unit, "LEADER DIRECT", false];
            _unit doFollow (leader _grp);
        };
    } forEach (units _grp);

    // private _leader = leader _grp;
    (units _grp) joinSilent _grp;
    // _grp selectLeader _leader;

    if !(alive (leader _grp)) then {
        _grp selectLeader (selectRandom ((units _grp) select {alive _x}));
    };

    _grp setCombatMode "YELLOW";
    _grp enableAttack false;

    if (vehicle (leader _grp) != leader _grp) then {
        _vic = vehicle (leader _grp);
        _vic forceSpeed -1;
        _vic disableBrakes false;
        _vic sendSimpleCommand "STOP";
    };

    if ((currentWaypoint _grp) < count (waypoints _grp)) then {
        [_grp, (currentWaypoint _grp)] setWaypointType "MOVE";
        [_grp, (currentWaypoint _grp)] setWaypointCompletionRadius 50;
        [_grp, (currentWaypoint _grp)] setWaypointPosition [getPosASL (leader _grp), -1];
        sleep 0.1;
        deleteWaypoint [_grp, (currentWaypoint _grp)];
        for "_i" from count waypoints _grp - 1 to 0 step -1 do {
            deleteWaypoint [_grp, _i];
        };
    };
};

pl_opfor_reset = {
    params ["_grp"];
    [_grp] call pl_opfor_reset_execute;
    [_grp] call pl_opfor_reset_execute;
    [_grp] call pl_opfor_reset_execute;

};

pl_opfor_auto_unstuck = {
    params ["_grp"];
    {
        [_x] spawn {
            params ["_unit"];
            while {alive _unit} do {
                if ((_unit distance2D leader (group _unit)) > 250) then {
                    // doStop _unit;
                    // _pos = (getPos _unit) findEmptyPosition [0, 100, typeOf _unit];
                    // _unit setPos _pos;
                    _unit setPos ((getPos _unit) vectorAdd [1 - (random 2), 1 - (random 2), 0]);
                    _unit doFollow leader (group _unit);
                    _unit switchMove "";
                    _unit enableAI "PATH";
                    _unit setUnitPos "AUTO";
                    _unit forceSpeed 20;
                    if ([getPos _unit] call pl_is_indoor) then {
                        // _b = nearestBuilding (getPos _unit);
                        // _unit disableCollisionWith _b;
                        // [_unit, _b] spawn {
                        //     sleep 15;
                        //     (_this#0) enableCollisionWith (_this#1);
                        // };
                        _pos = (getPos _unit) findEmptyPosition [0, 100, typeOf _unit];
                        _unit setPos _pos;
                    };
                    sleep 30;
                    _unit forceSpeed -1;
                };
                sleep 10;
            };
        };
    } forEach (units _grp);
};

pl_opfor_find_cover = {
    params ["_unit", ["_radius", 15], ["_watchDir", 0], ["_fofScan", false], ["_cords", []], ["_waitVar", "pl_opf_in_pos"]];
    private ["_valid"];

    _unit enableAI "PATH";

    if (_cords isEqualTo []) then {
        _cords = getPos _unit
    };
    _watchPos = _cords getPos [1000, _watchDir];
    private _covers = (nearestTerrainObjects [_cords, pl_valid_covers, _radius, true, true]); //select {!(isObjectHidden _x)};

    if ((count _covers) > 0) then {
        private _bestCover = _covers#0;
        if !(_bestCover in pl_covers) then {
            pl_covers pushBack _bestCover;
            _coverPos = getPos _bestCover;
            _unit doMove _coverPos;
            _unit setDestination [_coverPos, "LEADER DIRECT", true];
            sleep 0.5;

            waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable [_waitVar, true]) or (_unit distance2D _coverPos) <= 2};

            if ((group _unit) getVariable [_waitVar, true]) then {
                [_unit, _watchDir, _watchPos] call pl_opfor_setUnitPos;
                pl_covers deleteAt (pl_covers find _bestCover);
            };
         } else {
            [_unit, _watchDir, _watchPos] call pl_opfor_setUnitPos;
        };
    }
    else
    {
        [_unit, _watchDir, _watchPos] call pl_opfor_setUnitPos;
    };

    _fofScan = false;
    if (_fofScan) then {

        private _c = 0;
        private _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
        for "_i" from 10 to 210 step 50 do {
            _checkPos = [(getPos _unit) getPos [_i, _watchDir], 1] call pl_convert_to_heigth_ASL;
            _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "FIRE"];
            if (_visP isEqualTo []) then {
                _c = _c + 1;
            } else {
                break;
            };
        };
        if (_c >= 3) then {
            _unit setUnitPos "DOWN";
            _unit setUnitPosWeak "DOWN";
        } else {
            _c = 0;
            private _crouchPos = [getPos _unit, 0.7] call pl_convert_to_heigth_ASL;
            _checkPos = [(getPos _unit) getPos [4, _watchDir], 1.5] call pl_convert_to_heigth_ASL;
            _visP = lineIntersectsSurfaces [_crouchPos, _checkPos, _unit, vehicle _unit, true, 1, "FIRE"];
            if (_visP isEqualTo []) then {
                _unit setUnitPos "MIDDLE";
                _unit setUnitPosWeak "MIDDLE";
            } else {
                _unit setUnitPos "UP";
                _unit setUnitPosWeak "UP";
            };
        };
    };
};

pl_opfor_setUnitPos = {
    params ["_unit", "_watchDir", "_watchPos"];
    _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
    _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
    _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
    if (_visP isEqualTo []) then {_unit setUnitPos "DOWN"} else {_unit setUnitPos "MIDDLE"};
    doStop _unit;
    _unit doWatch _watchPos;
    // _unit disableAI "PATH";
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
            _x enableAI "PATH";
			if !(_x == leader _grp) then {
				_x doFollow (leader _grp);
			};
		} forEach (units _grp);
		_grp setBehaviourStrong "AWARE";
		// _grp setFormation "LINE";
		_grp setSpeedMode "NORMAL";
		_grp allowFleeing 0;
        _grp enableAttack false;
	};
};

pl_opfor_defend_position = {
    params ["_grp", ["_defendMode", 0]];
    private ["_cords", "_watchDir", "_buildingWallPosArray", "_buildingMarkers", "_watchPos", "_defenceWatchPos", "_markerAreaName", "_markerDirName", "_covers", "_buildings", "_allPos", "_validPos", "_units", "_unit", "_icon", "_unitWatchDir", "_vPosCounter", "_defenceAreaSize", "_mgPosArray", "_losPos", "_mgOffset", "_atEscord", "_dirMarkerType", "_unitPos"];

    if (vehicle (leader _grp) != (leader _grp)) exitWith {};
    if ((count ((units _grp) select {alive _x})) <= 1) exitwith {};

    [_grp] spawn pl_opfor_reset;

    sleep 1;

    _grp setVariable ["pl_opf_in_pos", true];

    (leader _grp) playActionNow "GestureCover";

    private _targets = (((getPos (leader _grp)) nearEntities [["Man", "Car", "Tank", "Truck"], 1500]) select {([side _grp, side _x] call BIS_fnc_sideIsEnemy) and ((leader _grp) knowsAbout _x) > 0});
    if (count _targets > 0) then {
        private _target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
        _units = units _grp;
        _cords = getPos (([_units, [], {_target distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0);
        _watchDir = (leader _grp) getDir _target;
    } else {
        _cords = getPos (leader _grp);
        _watchDir = getDir (leader _grp);
    };

    _defenceAreaSize = 30;
    _buildings = nearestTerrainObjects [_cords, ["BUILDING", "RUIN", "HOUSE"], _defenceAreaSize, true];

    _defenceWatchPos = _cords getPos [250, _watchDir];
    _defenceWatchPos = ASLToATL _defenceWatchPos;
    _defenceWatchPos = [_defenceWatchPos#0, _defenceWatchPos#1, 2];
    _defenceWatchPos = ATLToASL _defenceWatchPos;
    _watchPos = _cords getPos [1000, _watchDir];
    [_watchPos, 1] call pl_convert_to_heigth_ASL;


    // _markerBorderName = createMarker [str (random 5), _cords];
    // _markerBorderName setMarkerShape "ELLIPSE";
    // _markerBorderName setMarkerBrush "Border";
    // _markerBorderName setMarkerColor "colorOrange";
    // _markerBorderName setMarkerAlpha 0.8;
    // _markerBorderName setMarkerSize [_defenceAreaSize, _defenceAreaSize];

    // _markerDirName  = createMarker [str (random 5), _cords];
    // _markerDirName setMarkerPos _cords;
    // _markerDirName setMarkerType "marker_position";
    // _markerDirName setMarkerColor "colorOPFOR";
    // _markerDirName setMarkerDir _watchDir;
    
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 2) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    
    _validPos = [];
    private _winPos = [];
    private _sideRoadPos = [];
    _allPos = [];

    private _debugMarkers = [];
    private _debugHelpers = [];

    if (_defendMode != 2) then {
        {
            private _building = _x;
            // pl_draw_building_array pushBack [_grp, _building];
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
                    _counterPos = _samplePosASL vectorAdd [3 * (sin (_buildingDir + _d)), 3 * (cos (_buildingDir + _d)), 0];

                    if !((lineIntersects [_counterPos, _counterPos vectorAdd [0, 0, 20]])) then {
                        _helper2 = objNull;

                        _interSectsWin = lineIntersectsWith [_samplePosASL, _counterPos, objNull, objNull, true];
                        _checkDir = _samplePosASL getDir _counterPos;
                        if (!(lineIntersects [_samplePosASL, _counterPos, _helper2, objNull]) and (_checkDir > (_watchDir - 60) and _checkDir < (_watchDir + 60))) then {
                            // _window = true
                            _bPos deleteAt (_bPos find _bP);
                            _validPos pushBackUnique _bP;
                            _winPos pushBackUnique _bP;
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
                if (_winPos isNotEqualTo []) then {
                    _validPos pushBack (([_winPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0);
                } else {
                    _validPos pushBack (([_bPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0);
                };
                _winPos = [_winPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
            };

        } forEach _validBuildings;
    };

    // deploy packed static weapons if no buildings
    private _isStatic = [false, []];

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _units = [];
    if (vehicle (leader _grp) == leader _grp) then {_units pushBack (leader _grp)};
    private _mgGunners = [];
    private _atSoldiers = [];
    private _missileAtSoldiers = [];
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
        if (([secondaryWeapon _x] call BIS_fnc_itemtype) select 1 in ["MissileLauncher", "RocketLauncher"]) then {
            _atSoldiers pushBackUnique _x;
        };
    } forEach ((units _grp) select {vehicle _x == _x});

    if (count _atSoldiers > 0 and count _units > 3) then {
        _atEscord = {
            if (_x != (leader _grp) and _x != _medic) exitWith {_x};
            objNull
        } forEach _units;
    };

    {_units pushBackUnique _x} forEach _atSoldiers;
    {_units pushBackUnique _x} forEach _mgGunners;
    if !(isNull _medic) then {_units pushBack _medic};

    [_grp, _defenceWatchPos, _medic] spawn pl_opfor_defence_suppression;

    _posOffsetStep = _defenceAreaSize / (round ((count _units) / 2));
    private _posOffset = 0; //+ _posOffsetStep;
    private _maxOffset = _posOffsetStep * (round ((count _units) / 2));

    // find static weapons
    private _weapons = nearestObjects [_cords, ["StaticWeapon"], _defenceAreaSize, true];
    _avaiableWeapons = _weapons select { simulationEnabled _x && { !isObjectHidden _x } && { locked _x != 2 } && { (_x emptyPositions "Gunner") > 0 } };
    _weapons = + _avaiableWeapons;
    _coverCount = 0;
    private _ccpPos = [];
    private _safePos = [];
    _buildingMarkers = [];
    _buildingWallPosArray = [];

    // Find Valid Positions in and around buildings , behind Walls and beside roads 
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

    };

        private _walls = nearestTerrainObjects [_cords, ["WALL", "RUIN", "FENCE", "ROCK", "ROCKs", "HIDE"], _defenceAreaSize, true];
        private _trueWalls = nearestTerrainObjects [_cords, ["WALL", "RUIN", "FENCE"], _defenceAreaSize, true];
        _walls = _walls + (nearestObjects [_cords, ["Strategic"], _defenceAreaSize]);
        private _validWallPos = [];
        private _validPrefWallPos = [];



        {
            if !(isObjectHidden _x) then {

                _leftPos = (getPos _x) getPos [1, getDir _x];
                _rightPos = (getPos _x) getPos [1, (getDir _x) - 180];

                _visLeftPos = ATLtoASL [_leftPos#0, _leftPos#1, (_leftPos#2) + 1.6];
                _visrightPos = ATLtoASL [_rightPos#0, _rightPos#1, (_rightPos#2) + 1.6];
                
                _helper1 = objNull;


                _helper2 = objNull;

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

                } forEach [90, -90];
            };
        };

        _validPos = _validPos + _validPrefWallPos; 
        // _validPos = _validPos + _validWallPos;
        _validPos = _validPos + _buildingWallPosArray;
        _validPos = _validPos + _sideRoadPos;

    // Find save position for the medic to stage
    if (_ccpPos isEqualTo []) then {

        private _rearPos = _cords getPos [_defenceAreaSize * 0.5, _watchDir - 180];
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


    if (_validPos isNotEqualTo [] and _defendMode != 2) then {
        _losStartLine = ([_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0;
    };

    for "_j" from 0 to _accuracy do {
        if (_j % 2 == 0) then {
            _losPos = (_losStartLine getPos [-0.5, _watchDir]) getPos [3 - _losOffset, _watchDir + 90];
            // _losPos = _losStartLine getPos [_losOffset, _watchDir + 90];
        }
        else
        {
            _losPos = (_losStartLine getPos [-0.5, _watchDir]) getPos [3 - _losOffset, _watchDir - 90];
            // _losPos = _losStartLine getPos [_losOffset, _watchDir - 90];
        };
        _losOffset = _losOffset + (_defenceAreaSize / _accuracy);

        _losPos = [_losPos, 1.75] call pl_convert_to_heigth_ASL;

        

        private _losCount = 0;
        for "_l" from 10 to 600 step 20 do {

            _checkPos = _losPos getPos [_l, _watchDir];
            _checkPos = [_checkPos, 1.75] call pl_convert_to_heigth_ASL;
            _vis = lineIntersectsSurfaces [_losPos, _checkPos, objNull, objNull, true, 1, "VIEW"];

            if !(_vis isEqualTo []) exitWith {};

            _losCount = _losCount + 1;
        };

        if !(isOnRoad [_losPos#0, _losPos#1, 0]) then {

            _validLosPos pushback [_losPos, _losCount];
        };
    };


    _validLosPos = [_validLosPos, [], {_x#1}, "DESCEND"] call BIS_fnc_sortBy;
    _winPos = [_winPos, [], {_x#2}, "DESCEND"] call BIS_fnc_sortBy;

    {
        if (((_x#2) > 2) and !([_x] call pl_is_indoor)) then {
            _validLosPos = [[_x, 10]] + _validLosPos;
        };
    } forEach _winPos;


    if (_grp getVariable ["pl_allow_static", true]) then {
        _isStatic = [_units, _grp, (_validLosPos#0)#0, _watchPos, _cords] call pl_static_unpack;

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
    //     _validPos = [_grp, _cords, pl_garrison_area_size] call pl_get_360;
    // };
    if (_defendMode == 1) then {
        if ((count _units) > 1) then {
            _pos360 = [_grp, _cords, pl_garrison_area_size] call pl_get_360;
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
                if (_losIdx > (count _validLosPos) - 1) then {_losIdx = 1};
                _defPos = (_validLosPos#_losIdx)#0;
                _losIdx = _losIdx + 4;
                _debugMColor = "colorOrange";
            };

            // if 360 move to 360 pos
            if (_defendMode == 1) then {
                _defPos = _pos360#_i;
                _debugMColor = "colorBlue";
            };
        };

        // select best Medic Pos
        if ((!(isNil "_medic") and pl_enabled_medical and (_grp getVariable ["pl_healing_active", false])) and _defendMode != 1) then {
            if (_unit == _medic) then {
                _defPos = _ccpPos;
                _debugMColor = "colorGreen";
                _cover = 5;
            };
        };

        // select Best Mg Pos
        if (((([secondaryWeapon _unit] call BIS_fnc_itemtype) select 1) in ["MissileLauncher", "RocketLauncher"] or ([primaryweapon _unit] call BIS_fnc_itemtype) select 1 == "MachineGun") and _defendMode != 1) then {
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
                _defPos = _cords findEmptyPosition [0, _defenceAreaSize];
                _debugMColor = "colorYellow";
            };
            _debugMColor = "colorGrey";
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

        _defPos = ATLToASL _defPos;
        private _unitPos = "UP";
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
        // _debugMarkers pushback _m;

        // _helper = createVehicle ["Sign_Sphere25cm_F", _defPos, [], 0, "none"];
        // _helper setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];
        // _debugHelpers pushback _helper;

        // unit moveTo logic
        [_unit, _defPos, _watchPos, _unitWatchDir, _unitPos, _cover, _cords, _defenceAreaSize, _defenceWatchPos, _watchDir, _atEscord, _medic, _ccpPos] spawn {
            params ["_unit", "_defPos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_cords", "_defenceAreaSize", "_defenceWatchPos", "_defenceDir", "_atEscord", "_medic", "_ccpPos"];
            private ["_check"];

            if (!(alive _unit) or isNil "_defPos") exitWith {};

            if !(simulationEnabled _unit) then {
                _defPos set [2, 0];
                // _cover = [_defPos, _unitWatchDir, 5] call pl_opfor_get_cover_pos;
                _unit setPosATL _defPos;
                _unit setUnitPos _unitPos;
                _unit setDir _unitWatchDir;
                doStop _unit;
                _unit disableAI "PATH";
                _unit setUnitPos selectRandom ["UP", "MIDDLE"];
            } else {

                if (getSuppression _unit > 0.1) then {
                    _unit setUnitPos "DOWN";
                };

                _unit forceSpeed 20;
                _unit setHit ["legs", 0];
                _unit disableAI "AUTOCOMBAT";
                _unit disableAI "AUTOTARGET";
                _unit disableAI "TARGET";
                // _unit setUnitTrait ["camouflageCoef", 0.7, true];
                _unit doMove _defPos;
                _unit setDestination [_defPos, "LEADER DIRECT", true];

                waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["pl_opf_in_pos", false])};
                sleep 0.5;

                if (!((group _unit) getVariable ["pl_opf_in_pos", false]) or !(alive _unit)) exitWith {};

                _unit enableAI "AUTOCOMBAT";
                _unit enableAI "AUTOTARGET";
                _unit enableAI "TARGET";
                _unit setUnitPos "AUTO";
                _unit forceSpeed - 1;

                if ([_defPos] call pl_is_forest or [_defPos] call pl_is_city) then {
                    [_unit, round (_cover * 0.5), _unitWatchDir, true] spawn pl_opfor_find_cover;
                } else {
                    [_unit, _cover, _unitWatchDir, true] spawn pl_opfor_find_cover;
                };
            };
        };
    };
};



pl_opfor_defence_suppression = {
    params ["_grp", "_watchPos", "_medic"];
    private ["_targetsPos", "_targetDistance", "_firers", "_time"];

    private  _time = time + 10;
    waitUntil {sleep 0.5;  time >= time or !(_grp getVariable ["pl_opf_in_pos", true]) };
    if !(_grp getVariable ["pl_opf_in_pos", true]) exitWith {};

    while {_grp getVariable ["pl_opf_in_pos", false]} do {
        // _allTargets = nearestObjects [_watchPos, ["Man", "Car"], 350, true];
        _enemyTargets = (_watchPos nearEntities [["Man", "Car"], 400]) select {([side _grp, side _x] call BIS_fnc_sideIsEnemy) and ((leader _grp) knowsAbout _x) > 0};
        if (count _enemyTargets > 0) then {
            _firers = [];
            {
                if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                    _firers pushBackUnique _x;
                    // _x setUnitTrait ["camouflageCoef", 0.5, false];
                    // _x setVariable ["pl_damage_reduction", true];
                } else {
                    if ((random 1) > 0.7) then {_firers pushBackUnique _x;}
                };
            } forEach ((units _grp) select {!(_x checkAIFeature "PATH") and _x != _medic});
            {
                _unit = _x;
                _target = selectRandom _enemyTargets;
                _targetDistance = _unit distance2d _target;
                _targetPos = getPosASL _target;

                if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                    _targetPos = [_targetPos, _unit] call pl_get_suppress_target_pos;
                };
                // if (_unit distance2D _targetPos > 20 and ([_unit, _targetPos] call pl_friendly_check) and (_unit distance2D _targetPos) > _targetDistance * 0.3) then {
                if ((_targetPos distance2D _unit) > 5 and ([_unit, _targetPos] call pl_friendly_check)) then {


                    _unit doWatch _targetPos;
                    _unit doSuppressiveFire _targetPos;
                    // _m = createMarker [str (random 1), _targetPos];
		            // _m setMarkerType "mil_dot";
		            // _m setMarkerSize [0.5, 0.5];

                    // _helper1 = createVehicle ["Sign_Sphere25cm_F", _targetpos, [], 0, "none"];
                    // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                    // _helper1 setposASL _targetpos;
                };
              // _unit doSuppressiveFire _target;
            } forEach _firers;

            _time = time + 20;
            waitUntil {sleep 1; time > _time or !(_grp getVariable ["pl_opf_in_pos", true])};
        };
        sleep 20;
    };
};

pl_opfor_add_wp_path = {
    params ["_grp", "_start", "_dest", ["_wpInterval", 100]];
    private ["_wp"];

    private _destdistance = _start distance2D _dest;
    _wpInterval = _destdistance / 6;
    private _intervals = 6;
    // private _intervals = (round (_destdistance / _wpInterval)) - 1;
    private _lastPos = _start;
    private _wpPos = [];


    if (vehicle (leader _grp) == (leader _grp)) then {
        for "_i" from 1 to _intervals do {
            _wpPos = _lastPos getPos [_wpInterval, _start getDir _dest];
            if !(surfaceIsWater _wpPos) then {
                _wp = _grp addWaypoint [_wpPos, 5];
                _wp setWaypointType "MOVE";
                _wp setWaypointCompletionRadius 35;
                _lastPos = _wpPos;
            };
        };
    } else {
        _wp = _grp addWaypoint [_dest, 50];
        _wp setWaypointType "MOVE";
        _wp setWaypointCompletionRadius 50;
    };
};

pl_get_close_enemy = {
    params ["_grp", ["_forced", false]];

    private _knownUnits = [];

    if (_forced) then {
        _knownUnits = ((getPos (leader _grp)) nearEntities [["Man", "Car", "tank"], 2500]) select {(([side _grp, side _x] call BIS_fnc_sideIsEnemy) and alive _x and (lifeState _x) isNotEqualTo "INCAPACITATED")};
    } else {
        _knownUnits = ((getPos (leader _grp)) nearEntities [["Man", "Car", "tank"], 2500]) select {(([side _grp, side _x] call BIS_fnc_sideIsEnemy) and alive _x and (lifeState _x) isNotEqualTo "INCAPACITATED") and ((leader _grp) knowsAbout _x) > 0.2};
    };

    if ((count _knownUnits) <= 0) exitWith {objNull};

    _knownUnits = [_knownUnits, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy;
    private _targetPos = getPos (leader (group (_knownUnits#0)));

    private _closeToKnow = selectRandom (allUnits select {([side _grp, side _x] call BIS_fnc_sideIsEnemy) and ((getPos _x) distance2D _targetPos) <= 350});

    _closeToKnow
};

pl_opfor_flanking_move = {
    params ["_grp", ["_flankDistanceOverride", -1], ["_force", false]];
    private ["_fankPos", "_targetPos"];

    // private _knownUnits = ((getPos (leader _grp)) nearEntities [["Man", "Car", "tank"], 800]) select {(([side _grp, side _x] call BIS_fnc_sideIsEnemy) and alive _x and (lifeState _x) isNotEqualTo "INCAPACITATED") and ((leader _grp) knowsAbout _x) > 0};

    // if ((count _knownUnits) <= 0) exitWith {};

    private _targetUnit = [_grp, _force] call pl_get_close_enemy;

    if (isNull _targetUnit) exitWith {};


    [_grp] call pl_opfor_reset;

    sleep 0.5;

    [_grp] call pl_opfor_advance;

    sleep 0.5;

    // _knownUnits = [_knownUnits, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy;
    
    // _targetPos = getPos (leader (group (_knownUnits#0)));

    _targetPos = getPos _targetUnit;

    private _targetDir = (leader _grp) getDir _targetPos;
    private _flankDistance = ((leader _grp) distance2D _targetPos) * 0.7;
    if (_flankDistance > 400) then {_flankDistance = 400};
    if (_flankDistanceOverride > 0) then {_flankDistance = _flankDistanceOverride};
    _leftPos = (getPos (leader _grp)) getPos [_flankDistance, _targetDir + 90];
    _rightPos = (getPos (leader _grp)) getPos [_flankDistance, _targetDir - 90];

    _flankPos = ([[_leftPos, _rightPos], [], {count (_x nearEntities [["Man"], 350])}, "ASCEND"] call BIS_fnc_sortBy)#0;
    _flankPos2 = _flankPos getPos [_flankDistance, _targetDir];

    if ((surfaceIsWater _flankPos) or (surfaceIsWater _flankPos2)) exitWith {[_grp] spawn pl_opfor_attack_closest_enemy};

    [_grp, getPos (leader _grp), _flankPos] call pl_opfor_add_wp_path;
    [_grp, _flankPos, _flankPos2] call pl_opfor_add_wp_path;
    [_grp, _flankPos2, _targetPos] call pl_opfor_add_wp_path;

    sleep 1;

    if (vehicle (leader _grp) == (leader _grp)) then {

        if (((leader _grp) distance2D _targetPos) <= 600) then {
            [_grp] spawn pl_opfor_bounding_move_simple;
        };

    } else {
        _grp setBehaviourStrong "COMBAT";
    };
};

pl_opfor_attack_closest_enemy = {
    params ["_grp", ["_force", false], ["_targetPos", []], ["_doBounding", true]];
    private ["_targetsPos"];

    private _targetUnit = objNull;

    if (_targetPos isEqualTo []) then {

        private _targetUnit = [_grp, _force] call pl_get_close_enemy;
        _targetPos = getPos _targetUnit;

    };

    [_grp] call pl_opfor_reset;

    sleep 0.5;

    [_grp] call pl_opfor_advance;

    sleep 0.5;

    [_grp, getPos (leader _grp), _targetPos] call pl_opfor_add_wp_path;

    sleep 1;

    if (vehicle (leader _grp) == (leader _grp)) then {

        if (((leader _grp) distance2D _targetPos) <= 600 and _doBounding) then {
            [_grp] spawn pl_opfor_bounding_move_simple;
        };

    } else {
        _grp setBehaviourStrong "COMBAT";
    };
};

pl_opfor_bounding_move_simple = {
    params ["_grp"];    

    if (isNull _grp) exitWith {};

    private _units = (units _grp);
    private _team1 = [];
    private _team2 = [];

    _ii = 0;
    {
        if (_ii % 2 == 0) then {
            _team1 pushBack _x;
        }
        else
        {
            _team2 pushBack _x;
        };
        _ii = _ii + 1;
    } forEach (_units select {alive _x});

    [_grp] call pl_opfor_advance;

    private _movePos = waypointPosition ((waypoints _grp)#((currentWaypoint _grp)));
    private _timeout = time + 10 + (random 5);

    // if (([getPos (leader _grp)] call pl_get_closest_enemy_unit_distance) > 500) then {
    //  waitUntil {sleep 10; ([getPos (leader _grp), _grp] call pl_get_closest_enemy_unit_distance) <= 500 or (_grp getVariable ["pl_stop_event", false])};
    // };

    // if ((_grp getVariable ["pl_stop_event", false]) or (currentWaypoint _grp) >= count (waypoints _grp)) exitWith {};

    while {(currentWaypoint _grp) < count (waypoints _grp) and !(_grp getVariable ["pl_stop_event", false])} do {

        if (isNull _grp) exitWith {};

        _movePos = [[[_movePos, 25]], ["water"]] call BIS_fnc_randomPos;

        {
            _x enableAI "PATH";
            _x setUnitPos "AUTO";
            _x disableAI "AUTOTARGET";
            _x disableAI "TARGET";
            _x forceSpeed 20;
            doStop _x;
            sleep 0.1;
            if (_x != (leader _x)) then {
                _x domove _movePos;
            } else {
                _x doMove (waypointPosition ((waypoints _grp)#((currentWaypoint _grp))));
            };
        } forEach _team1;

        (_team1#0) playActionNow "GestureAdvance";

        {
            doStop _x;
            _x enableAI "AUTOTARGET";
            _x enableAI "TARGET";
            _x forceSpeed -1;
            // _x disableAI "PATH";
            _x setUnitPos (selectRandom ["Middle", "Down"]);

            if ((random 1) > 0.5 or ([primaryweapon _x] call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                [_x] call pl_opfor_quick_suppress_unit;
            };
        } forEach _team2;

        (_team2#0) playActionNow "GestureCover";

        _timeout = time + 8;

        waitUntil {sleep 1; time >= _timeOut or (_grp getVariable ["pl_stop_event", false]) or (currentWaypoint _grp) >= count (waypoints _grp)};

        if ((_grp getVariable ["pl_stop_event", false]) or (currentWaypoint _grp) >= count (waypoints _grp)) exitWith {};


        _movePos = waypointPosition ((waypoints _grp)#((currentWaypoint _grp)));
        _movePos = [[[_movePos, 25]], ["water"]] call BIS_fnc_randomPos;

        {
            _x enableAI "PATH";
            _x setUnitPos "AUTO";
            _x disableAI "AUTOTARGET";
            _x disableAI "TARGET";
            _x forceSpeed 20;
            doStop _x;
            sleep 0.1;
            if (_x != (leader _x)) then {
                _x domove _movePos;
            } else {
                _x doMove (waypointPosition ((waypoints _grp)#((currentWaypoint _grp))));
            };
        } forEach _team2;

        (_team2#0) playActionNow "GestureAdvance";

        {
            doStop _x;
            _x enableAI "AUTOTARGET";
            _x enableAI "TARGET";
            _x forceSpeed -1;
            // _x disableAI "PATH";
            _x setUnitPos (selectRandom ["Middle", "Down"]);

            if ((random 1) > 0.5 or ([primaryweapon _x] call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                [_x] call pl_opfor_quick_suppress_unit;
            };
        } forEach _team1;

        (_team1#0) playActionNow "GestureCover";

        _timeout = time + 8;

        waitUntil {sleep 1; time >= _timeOut or (_grp getVariable ["pl_stop_event", false]) or (currentWaypoint _grp) >= count (waypoints _grp)};

        if ((_grp getVariable ["pl_stop_event", false]) or (currentWaypoint _grp) >= count (waypoints _grp)) exitWith {};
    };
};

pl_opfor_assault = {
	params ["_grp"];

	[_grp] call pl_opfor_reset;

	sleep 0.5;

	_targets = (((getPos (leader _grp)) nearEntities [["Man"], 500]) select {([side _grp, side _x] call BIS_fnc_sideIsEnemy) and ((leader _grp) knowsAbout _x) > 0});
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
        _x disableAI "AUTOCOMBAT";
        _x lookAt _target;
	} forEach (units _grp);

    _grp setBehaviour "AWARE";
};


pl_opfor_auto_formation = {
    params ["_grp"];
    private ["_dest", "_distance"];

    _grp setFormation "LINE";
    while {sleep 0.5; {alive _x} count (units _grp) > 0} do {

        if ([getPos (leader _grp)] call pl_is_city) then {
            if (formation _grp != "VEE") then {
                _grp setFormation "VEE";
                // (leader _grp) forceSpeed 3;
            }; 
        } else {
        	(leader _grp) forceSpeed -1;
            if ((currentWaypoint _grp) < count (waypoints _grp)) then {
                _dest = waypointPosition ((waypoints _grp) select (count (waypoints _grp) - 1));
                _distance = _dest distance2D (leader _grp);
                if (_distance > 600 and (behaviour (leader _grp) != "COMBAT")) then {
                    if (formation _grp != "STAG COLUMN") then {
                        _grp setFormation "STAG COLUMN";
                    };
                } else {
                    if (formation _grp != "VEE") then {
                        _grp setFormation "VEE";
                    };
                };
            } else {
                if (formation _grp != "VEE") then {
                    _grp setFormation "VEE";
                };
            };
        };
        sleep 8;
    };   
};

pl_opfor_find_overwatch = {
	params ["_grp"];

	_units = allUnits select {([side _grp, side _x] call BIS_fnc_sideIsEnemy) and alive _x};
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

// Tactical Retreats


[] spawn {
    private _retreatMarker = "";
 
    while {pl_opfor_allow_ai_retreat} do {

        private _markers = [];

        {
            _fightingPos = _x;
            _joinValues = _y;

            if (pl_debug) then {
                _m =  createMarker [str (random 5), _x];
                _m setMarkerShape "ELLIPSE";
                _m setMarkerBrush "Border";
                _m setMarkerColor "colorOrange";
                _m setMarkerAlpha 0.8;
                _m setMarkerSize [pl_opfor_retreat_zone_size, pl_opfor_retreat_zone_size];
                
                _m2 = createMarker [str (random 5), _x];
                _m2 setMarkerType "mil_dot";
                _m2 setMarkerSize [1,1];
                _m2 setMarkerColor "colorOrange";
                _m2 setMarkerText (format ["%1  /  %2  /  %3", _joinValues#0, _joinValues#1, (_joinValues#2) - time]);

                _markers pushback _m;
                _markers pushback _m2;
            };

            if (time >= (_joinValues#2)) then {pl_opfor_retreat_zones deleteAt _x};

            if ((_joinValues#0) >= (_joinValues#1)) then {

                private _allGroups = allGroups select {([side _x, playerside] call BIS_fnc_sideIsEnemy) and ((leader _x) distance2D _fightingPos) <= pl_opfor_retreat_zone_size};
                {
                    _x setvariable ["pl_opfor_retreat", true];
                    // sleep (random 1);
                } forEach _allGroups;

                private _enyCentroid = [allGroups select {(side _x) == playerside and _fightingPos distance2d (leader _x) <= 1000}] call pl_find_centroid_of_groups;

                private _retreatPos = _fightingPos;

                if (_enyCentroid isNotEqualto []) then {
                    _retreatPos = _fightingPos getPos [250, _enyCentroid getDir _fightingPos];
                } else {
                    _retreatPos = _fightingPos getPos [250, (([allUnits select {side _x == playerSide}, [], {_x distance2D _fightingPos}, "ASCEND"] call BIS_fnc_sortBy)#0) getDir _fightingPos];
                };  

                _retreatMarker = createMarker [str (random 5), _retreatPos];
                _retreatMarker setMarkerType "marker_withdraw";
                _retreatMarker setMarkerSize [1.3, 1.3];
                _retreatMarker setMarkerColor "colorOpfor";
                _retreatMarker setMarkerDir (_enyCentroid getDir _fightingPos);

                [_retreatMarker] spawn {
                    params ["_retreatMarker"];

                    sleep 60;

                    deleteMarker _retreatMarker;

                };

                pl_opfor_retreat_zones deleteAt _x;
            };


        } forEach pl_opfor_retreat_zones;

        sleep 2;

        {
            deleteMarker _x;
        } forEach _markers;
    };
};

pl_opfor_join_grp = {
	params ["_grp", "_side", ["_joinRange", pl_opfor_join_range]];

    if !(pl_opfor_allow_ai_surrender) exitwith {false};
    if (count ((units _grp) select {alive _x}) <= 0) exitWith {false};

	private _targets = (((getPos (leader _grp)) nearEntities [["Man"], _joinRange]) select {side _x == _side and (vehicle (leader (group _x))) == (leader (group _x))});
	_targets = _targets - (units _grp);
	private _target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
    private _return = false;


	if !(isNil "_target") then {

        [_grp] call pl_opfor_create_retreat_zone;

		private _targetGrp = group _target;
        _targetGrp setVariable ["pl_is_join_target", true];
		{
			if (alive _x) then {
				[_x] joinSilent _targetGrp;
				_x enableAI "PATH";
                _x enableAI "WEAPONAIM";
                _x enableAI "FIREWEAPON";
                _x enableAI "TARGET";
                _x enableAI "AUTOTARGET";
				_x disableAI "AUTOCOMBAT";
				_x setBehaviour "AWARE";
				_x setUnitPos "AUTO";
                _x doMove (getPos (leader _targetGrp));
				_x doFollow (leader _targetGrp);
                _x setVariable ["pl_no_centoid", true];
                _x setUnitLoadout (_x getVariable ["pl_loadout", getUnitLoadout _x]);
                _x setCaptive false;
			};
		} forEach (units _grp);
        deleteGroup _grp;

        // retarded
        [_targetGrp] spawn {
            params ["_targetGrp"];
            // sleep 2;
            // [_targetGrp, (currentWaypoint _targetGrp)] setWaypointType "MOVE";
            // [_targetGrp, (currentWaypoint _targetGrp)] setWaypointPosition [getPosASL (leader _targetGrp), -1];
            // sleep 0.1;
            // deleteWaypoint [_targetGrp, (currentWaypoint _targetGrp)];
            sleep 2;
            _targetGrp setVariable ["pl_is_join_target", nil];
        };

        {
            [_x] joinSilent _targetGrp;
        } forEach (units _targetGrp);

        _return = true;
	};
	_return
};

pl_opfor_surrender = {
	params ["_grp"];

	sleep 2;

    [_grp] call pl_opfor_create_retreat_zone;

    
    // private _keyPos = [];
    // private _retreatLevelBreackpoint = 1000;
    // private _retreatLevel = 0;
    // private _retreatTime = time + 0;

    // {
    //     if (getPos (leader _grp) distance2D _x <= pl_opfor_retreat_zone_size) then {
    //         _keyPos = _x;
    //         _retreatLevel = _y#0;
    //         _retreatLevelBreackpoint = _y#1;
    //         _retreatTime = _y#2;
    //     };
    // } forEach pl_opfor_retreat_zones;

    // if (_keyPos isNotEqualto []) then {

    //     _retreatLevel = _retreatLevel + 1;

    //     pl_opfor_retreat_zones set [_keyPos, [_retreatLevel, _retreatLevelBreackpoint, _retreatTime]];

    // } else {
    //     _retreatLevelBreackpoint = count (allGroups select {side _x == (side _grp) and (leader _x) distance2D (getPos (leader _grp)) <= pl_opfor_retreat_zone_size and (({alive _x} count (units _x)) > 0) and (_x getVariable ["pl_opfor_vic_unitText", ""]) != "truck"});
    //     _retreatLevelBreackpoint = (round (_retreatLevelBreackpoint * pl_opfor_aggressivness)) + 1;
    //     if (_retreatLevelBreackpoint >= 2) then {
    //         pl_opfor_retreat_zones set [getPos (leader _grp), [1, _retreatLevelBreackpoint, time + (pl_opfor_retreat_time_adder * _retreatLevelBreackpoint)]];
    //     };
    // };

    if !(pl_opfor_allow_ai_surrender) exitwith {deleteGroup _grp};

    if (count ((units _grp) select {alive _x}) <= 0) exitWith {deleteGroup _grp};

	[_grp] spawn pl_opfor_reset;

    private _leader = leader _grp;

    _grp setvariable ["pl_has_surrendered", true];
	// _surrenderGrp = createGroup [side _grp , true];
    _grp selectLeader (selectRandom ((units _grp) select {alive _x}));

	{
		if (alive _x) then {
			_x setCaptive true;
            _x setVariable ["pl_loadout", getUnitLoadout _x];
			// removeAllWeapons _x;
            removeBackpack _x;
            if ((random 1) > 0.5) then {
                removeHeadgear _x;
            };
            if ((random 1) > 0.5) then {
                removeVest _x;
            };
            // if ((random 1) > 0.5) then {
                removeAllWeapons _x;
            // };
            if ((random 1) > 0.8) then {
                _x setHit ["legs", 0.5];
            };
			_x enableDynamicSimulation true;
            _x disableAI "AUTOCOMBAT";
            _x disableAI "WEAPONAIM";
            _x disableAI "FIREWEAPON";
            _x disableAI "TARGET";
            _x disableAI "AUTOTARGET";
            _x allowFleeing 1;
			// [_x] spawn {
			// 	sleep 5;
			// 	(_this#0) playActionNow selectRandom ["agonyStart", "surrender"];
			// };
		};
	} forEach (units _grp) ;

	_grp setBehaviour "AWARE";
    // allowFleeing
	// _grp setSpeedMode "LIMITED";

    sleep 2;

    private _opforSide = side _grp;
    private _enyCentroid = [allGroups select {([side _grp, side _x] call BIS_fnc_sideIsEnemy) and (leader _x) distance2D (leader _grp) <= 1000}] call pl_find_centroid_of_groups;
    private _retreatDistance = worldSize * 0.045;
    if (_retreatDistance < 500) then {_retreatDistance = 500};
    private _retreatPos = getPos (leader _grp);

    if (_enyCentroid isNotEqualto []) then {
        _retreatPos = (getPos (leader _grp)) getPos [_retreatDistance, _enyCentroid getDir (leader _grp)];
    } else {
        _retreatPos = (getPos (leader _grp)) getPos [_retreatDistance, (([allUnits select {side _x == playerSide}, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy)#0) getDir (leader _grp)];
    };  

    _retreatPos = [[[_retreatPos, 250]], ["water"]] call BIS_fnc_randomPos;

    {
     // _x forceSpeed 1;
         _x enableAI "PATH";
         _x switchMove "";
         _x setUnitPos "UP";
    } forEach (units _grp);

    [_grp, getPos (leader _grp), _retreatPos, 150] call pl_opfor_add_wp_path;


    [_grp] spawn {
        params ["_grp"];

    	waitUntil {sleep 5; !((((getPos (leader _grp)) nearEntities [["Man", "Tank", "Car"], 75]) select {([side _grp, side _x] call BIS_fnc_sideIsEnemy)}) isEqualto [])};

        [_grp] call pl_opfor_reset;

        {
            if (alive _x) then {
                _x playActionNow "surrender";
                _x disableAI "PATH";
                _x setUnitPos "DOWN";
                _x enableDynamicSimulation true;
                removeAllWeapons _x;
            };
        } forEach (units _grp) ;

        waitUntil {sleep 5; !((((getPos (leader _grp)) nearEntities [["Man", "Tank", "Car"], 25]) select {([side _grp, side _x] call BIS_fnc_sideIsEnemy)}) isEqualto [])};

        [_grp] call pl_opfor_reset;

        {
            _x forceSpeed 1;
            _x enableAI "PATH";
            _x switchMove "";
            _x setUnitPos "UP";
            _x doMove pl_opfor_pow_pos;
        } forEach (units _grp);
        [_grp, getPos (leader _grp), pl_opfor_pow_pos, 150] call pl_opfor_add_wp_path;
    };

    [_grp, _retreatPos, _opforSide] spawn {
        params ["_grp", "_retreatPos", "_opforSide"];

        private _timeOut = time + ([200, 500] call BIS_fnc_randomInt);
        // _timeOut = time + 2;
        waitUntil {sleep 5; time >= _timeOut or ((leader _grp) distance2D _retreatPos < 300)};

        // while {sleep 1; (count ((units _grp) select {alive _x})) > 0} do {
            // if ([_grp, _opforSide, 400] call pl_opfor_join_grp) exitWith {};

            // sleep 10;
        // };
        0 = [_grp, _opforSide, 800] call pl_opfor_join_grp;
    };
};


// look for or create a Retreat Zone; when enough groups have /died/joined/surrenderres all groups in zone will retreat
pl_opfor_create_retreat_zone = {
    params ["_grp"];

    private _keyPos = [];
    private _retreatLevelBreackpoint = 1000;
    private _retreatLevel = 0;
    private _retreatTime = time + 0;

    {
        if (getPos (leader _grp) distance2D _x <= pl_opfor_retreat_zone_size) then {
            _keyPos = _x;
            _retreatLevel = _y#0;
            _retreatLevelBreackpoint = _y#1;
            _retreatTime = _y#2;
        };
    } forEach pl_opfor_retreat_zones;

    if (_keyPos isNotEqualto []) then {

        _retreatLevel = _retreatLevel + 1;

        pl_opfor_retreat_zones set [_keyPos, [_retreatLevel, _retreatLevelBreackpoint, _retreatTime]];

    } else {
        _retreatLevelBreackpoint = count (allGroups select {side _x == (side _grp) and (leader _x) distance2D (getPos (leader _grp)) <= pl_opfor_retreat_zone_size and (({alive _x} count (units _x)) > 0) and (_x getVariable ["pl_opfor_vic_unitText", ""]) != "truck"});
        _retreatLevelBreackpoint = (round (_retreatLevelBreackpoint * pl_opfor_aggressivness)) + 1;
        if (_retreatLevelBreackpoint >= 2) then {
            pl_opfor_retreat_zones set [getPos (leader _grp), [1, _retreatLevelBreackpoint, time + (pl_opfor_retreat_time_adder * _retreatLevelBreackpoint)]];
        };
    };
};

pl_opfor_drop_cargo = {
	params ["_grp", "_vic", "_cargo", "_cargoGroups"];

	// [_grp] spawn pl_opfor_reset;

	// sleep 0.5;

    // (driver _vic) disableAI "PATH";
    doStop _vic;
    _vic forceSpeed 0;
	// {
    //     _unit = _x;
    //     if !(_unit in (units _grp)) then {
    //         unassignVehicle _unit;
    //         doGetOut _unit;
    //         [_unit] allowGetIn false;
    //     };
    // } forEach _cargo;

    [_grp, _cargo, _vic] spawn pl_opfor_combat_dismount;

    {
        _x leaveVehicle _vic;
    } forEach _cargoGroups;
    private _cargoPers = [];

};

pl_opfor_combat_dismount = {
    params ["_group", "_cargo", "_vic", ["_offsetValue", 45], ["_spacing", 5]];
    private ["_offset"];

    for "_i" from 1 to (count _cargo) do {

        _offset = _offsetValue;
        if (_i % 2 == 0) then {_offset = -_offsetValue};

        _movePos = (getPos _vic) getpos [_spacing * _i, ((getDir _vic) - 180) + _offset];

        // _m = createMarker [str (random 5), _movePos];
        // _m setMarkerType "mil_dot";

        [_cargo#(_i - 1), _movePos, getdir _vic] spawn {
            params ["_unit", "_movePos", "_watchDir"];

            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            _unit disableAI "AUTOCOMBAT";
            _unit setCombatBehaviour "AWARE";
            _unit setHit ["legs", 0];
            unassignVehicle _unit;
            doGetOut _unit;
            [_unit] allowGetIn false;

            waitUntil {sleep 0.1; (vehicle _unit) == _unit or ((group _unit) getVariable ["pl_stop_event", false])};
            
            if !(((group _unit) getVariable ["pl_stop_event", false])) then {

                _unit doMove _movePos;
                // _unit setDestination [_movePos, "LEADER DIRECT", true];

                sleep 0.5;

                waitUntil {sleep 0.1; unitReady _unit or ((group _unit) getVariable ["pl_stop_event", false])};

                if !(((group _unit) getVariable ["pl_stop_event", false])) then {
                    doStop _unit;
                    _unit setUnitPos "DOWN";
                    _unit enableAI "AUTOTARGET";
                    _unit enableAI "TARGET";
                    _unit doWatch (_movePos getPos [100, _watchDir]);
                    _unit setVariable ["pl_in_position", true];
                };
            };
        };
    };
};

pl_opfor_rush_to_unload = {
    params ["_grp", "_vic", ["_panic", true]];

    private _flankchance = 0.7;

    private _road = [getPosATL _vic, 50] call BIS_fnc_nearestRoad;
    if (!(isNull _road) and _panic) then {_flankchance = 0.1};

    if ((random 1) > _flankchance) then {
        [_grp, [80, 150] call BIS_fnc_randomInt] call pl_opfor_flanking_move;
    } else {
        [_grp] call pl_opfor_attack_closest_enemy;
    };

    if (_panic) then {
        _vic forceSpeed -1;
        _vic limitSpeed 1000;
    };
};

pl_opfor_retreat_road = objNull;

pl_opfor_vic_retreat = {
    params ["_grp", "_vic"];


    if (isNull pl_opfor_retreat_road) then {

        private _opforSide = side _grp;
        private _enyCentroid = [allGroups select {([side _grp, side _x] call BIS_fnc_sideIsEnemy)}] call pl_find_centroid_of_groups;
        private _retreatDistance = worldSize * 0.1;
        if (_retreatDistance < 1000) then {_retreatDistance = 1000};

        pl_opfor_retreat_road = [(getPos _vic) getPos [worldSize * 0.1, _enyCentroid getDir _vic], 1500] call BIS_fnc_nearestRoad;
    };

    private _retreatPos = getPos pl_opfor_retreat_road;

    // _m = createMarker [str (random 1), _retreatPos];
    // _m setMarkerType "mil_marker";
    // _m setMarkerSize [1.5, 1.5];

    [_grp] call pl_opfor_reset;

    // _vic doMove _retreatPos;
    _vic limitSpeed 70;
    _vic forceSpeed -1;

    
    // _grp addWaypoint [_retreatPos , 100];
    [_grp, getPos _vic, _retreatPos, (_vic distance2D _retreatPos) / 3] call pl_opfor_add_wp_path;

    {
        _x disableAI "AUTOCOMBAT";
        _x disableAI "FIREWEAPON";
    } forEach (units _grp);
    _grp setBehaviour "CARELESS";

    sleep ([160, 300] call BIS_fnc_randomInt);

    if (isNil "_grp") exitWith {};

    {
        _x enableAI "AUTOCOMBAT";
        _x enableAI "FIREWEAPON";
    } forEach (units _grp);

    _grp setBehaviour "AWARE";
};

// pl_opfor_tactical_retreat_pos = [];

pl_opfor_tactical_retreat = {
    params ["_grp", "_timeout"];

    _grp setvariable ["pl_opfor_retreat", false];

    private _enyCentroid = [allGroups select {([side _grp, side _x] call BIS_fnc_sideIsEnemy) and (leader _x) distance2D (leader _grp) <= 1000}] call pl_find_centroid_of_groups;
    private _retreatDistance = worldSize * 0.045;
    if (_retreatDistance < 500) then {_retreatDistance = 500};
    private _retreatPos = getPos (leader _grp);

    if (_enyCentroid isNotEqualto []) then {
        _retreatPos = (getPos (leader _grp)) getPos [_retreatDistance, _enyCentroid getDir (leader _grp)];
    } else {
        _retreatPos = (getPos (leader _grp)) getPos [_retreatDistance, (([allUnits select {side _x == playerSide}, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy)#0) getDir (getPos (leader _grp))];
    };  

    _retreatPos = [[[_retreatPos, 250]], ["water"]] call BIS_fnc_randomPos;

    if (_retreatPos isEqualTo [0,0]) exitWith {};
    // _m = createMarker [str (random 1), _retreatPos];
    // _m setMarkerType "mil_marker";
    // _m setMarkerSize [1.5, 1.5];

    [_grp] call pl_opfor_reset;

    {
        _x disableAI "AUTOCOMBAT";
        _x disableAI "FIREWEAPON";
        _x enableAI "PATH";
    } forEach (units _grp);


    if (vehicle (leader _grp) != leader _grp) then {
        _vic = vehicle (leader _grp);
        _vic limitSpeed 70;
        _vic forceSpeed -1;
        _grp setBehaviour "CARELESS";
    } else {
        _grp setBehaviour "AWARE";
    };

    [_grp, getPos (leader _grp), _retreatPos, ((leader _grp) distance2D _retreatPos) / 3] call pl_opfor_add_wp_path;

    // sleep ([240, 500] call BIS_fnc_randomInt);
    // sleep (_timeout - 2);

    // if (isNil "_grp") exitWith {};

    // [_grp] call pl_opfor_reset;

    _grp setvariable ["pl_opfor_retreat", false];

};

pl_opfor_support_inf = {
	params ["_vic", "_grp", "_allyGrp"];

     waitUntil {sleep 0.5; (({vehicle _x != _x} count (units _allyGrp)) <= 0) or !(alive _vic)};

    [_grp] spawn pl_opfor_reset;

    sleep 0.5;

    [_grp] spawn pl_opfor_reset;

    sleep 0.5;

	_vic limitSpeed 25;

    private _notMovedCounter = 0;

	while {alive _vic and ({alive _x} count (units _allyGrp)) > 0} do {

		if (_vic distance2D (leader _allyGrp) > 40) then {
            _vic forceSpeed -1;
			_vic doMove (getpos (leader _allyGrp));
			_vic setDestination [getpos (leader _allyGrp), "VEHICLE PLANNED", true];
            _notMovedCounter = 0;
		} else {
            doStop _vic;
            _vic forceSpeed 0;
			[_grp] call pl_opfor_vic_suppress;
            _notMovedCounter = _notMovedCounter + 1;
		};

        if (_notMovedCounter > 5) then {
            _vic forceSpeed -1;
            _movePos = (getpos (leader _allyGrp)) getPos [[40, 80] call BIS_fnc_randomInt, (_vic getDir (leader _allyGrp)) + ([-90, 90] call BIS_fnc_randomInt)];
            _vic doMove _movePos;
            _vic setDestination [_movePos, "VEHICLE PLANNED", true];
            _notMovedCounter = 0;
        };
		sleep 10;
	};

	[_grp] spawn pl_opfor_reset;
};

pl_opfor_vic_suppress = {
	params ["_grp"];
    private ["_targetsPos", "_targetDistance", "_unit"];

    private _targets = (((getPos (leader _grp)) nearEntities [["Man", "Car", "Tank"], 500]) select {([side _grp, side _x] call BIS_fnc_sideIsEnemy) and ((leader _grp) knowsAbout _x) > 0});

    private _getTargets = {
        params ["_cords", "_area"];
        private _targetsPos = [];
        private _allTargets = _cords nearEntities [["Man", "Car", "Truck", "Tank"], _area];
        {
            _targetsPos pushBack (getPosATL _x);
        } forEach (_allTargets select {[side _grp, side _x] call BIS_fnc_sideIsEnemy});

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

    if (([vehicle (leader _grp)] call pl_has_cannon )) then {
        [vehicle (leader _grp)] call pl_load_he;
    };

    if !(_targets isEqualto []) then {
	    {

            _unit = _x;

            _targetPos = [[getpos (selectRandom _targets), 80] call _getTargets, _unit] call pl_get_suppress_target_pos;

            // _m = createMarker [str (random 1), _targetPos];
            // _m setMarkerType "mil_marker";
            // _m setMarkerSize [0.5, 0.5];

            if ((_targetPos distance2D _unit) > 20 and ([_unit, _targetPos] call pl_friendly_check)) then {

                _unit doWatch _targetPos;
                _unit doSuppressiveFire _targetPos;
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
		sleep 30;
	};
};



pl_opfor_quick_suppress_unit = {
    params ["_unit"];

    private _target = selectRandom (((getPos _unit) nearEntities [["Man", "Car"], 500]) select {([side _grp, side _x] call BIS_fnc_sideIsEnemy) and (_unit knowsAbout _x) > 0.1});

    if (isNil "_target") exitWith {};

    private _targetPos = getPosASL _target;
    // _targetPos = [_targetPos, _unit] call pl_get_suppress_target_pos;

    // _m = createMarker [str (random 1), _targetPos];
    // _m setMarkerType "mil_dot";
    // _m setMarkerSize [0.5, 0.5];

    // _helper1 = createVehicle ["Sign_Sphere25cm_F", _targetpos, [], 0, "none"];
    // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
    // _helper1 setposASL _targetpos;

    if ((_targetPos distance2D _unit) > 20 and ([_unit, _targetPos] call pl_friendly_check)) then {

        _unit doWatch _targetPos;
        _unit doSuppressiveFire _targetPos;
    };
};

pl_opfor_get_idle_groups = {

    private _idleGrps = [];
    private _state = "";

    {
        _state = _x getVariable ["pl_opfor_debug_marker_text", "None"];

        // "vehicle combat idle", "In Combat Mobile"
        if (_state in ["Retreat Finished", "Taking Cover Idle Combat", "vehicle combat idle"]) then {
            _idleGrps pushBackUnique _x;
        };

    } forEach (allGroups select {side _x != playerSide and side _x != civilian });

    _idleGrps 
};



pl_opfor_obj_debug_markers = [];

pl_opfor_get_objective = {
    params ["_grp", ["_fromCmd", true]];

    private _debugMarker = "1";
    
    if (pl_debug) then {

        {
            deleteMarker _x;
        } forEach pl_opfor_obj_debug_markers;

    };

    private _objs = +pl_opfor_all_objectives;
    private _obj = [];
    private _state = "";

    {
        _state = _x getVariable ["pl_opfor_debug_marker_text", "None"];

        if (_state in ["Attacking Closest", "Flanking Closest", "Taking Cover ENY Close", "Taking Cover Casaulties/Suppressed", "Attacking"]) then {
            _objs pushBackUnique (getPos (leader _x));

            if (pl_debug) then {
                _debugMarker = createMarker [str (random 5), getPos (leader _x)];
                _debugMarker setMarkerType "mil_circle";
                _debugMarker setMarkerSize [1, 1];
                pl_opfor_obj_debug_markers pushback _debugMarker;
            };
        };

    } forEach (allGroups select {side _x != playerSide and side _x != civilian });

    private _potentialObjs = [];

    if (_objs isNotEqualto []) then {

        {
            if (([_x] call pl_get_closest_enemy_unit_distance) <= 500) then {
                _potentialObjs pushBackUnique _x;
            };
        } forEach _objs;

        if (_potentialObjs isNotEqualto [] and !_fromCmd) then {
            _obj = ([_potentialObjs, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy)#0;
        } else {
            _obj = ([_objs, [], {([_x] call pl_get_closest_enemy_unit_distance)}, "ASCEND"] call BIS_fnc_sortBy)#0;
        };

    } else {
        _obj = getPos player;
    };

    pl_opfor_all_objectives = +_objs;

    _obj

};


// pl_get_closest_enemy_unit_distance = {
//     params ["_pos", "_grp"];
//     private _unit = ([allUnits select {[side _grp, side _x] call BIS_fnc_sideIsEnemy}, [], {_x distance2D _pos}, "ASCEND"] call BIS_fnc_sortBy)#0;
//     _unit distance2d _pos
// };

pl_get_closest_enemy_unit_distance = {
    params ["_pos", "_grp"];
    private _unit = ([allUnits select {side _x == playerSide}, [], {_x distance2D _pos}, "ASCEND"] call BIS_fnc_sortBy)#0;
    _unit distance2d _pos
};


pl_opfor_cmd_move_to_objective = {
    params ["_grps", "_obj"];

    {
        _x setVariable ["pl_opfor_debug_marker_text", "Combat: Move commanded"];
        if ((leader _x) distance2D _obj > 1000) then {
            // check for potential closer obj
            _obj = [_x, false] call pl_opfor_get_objective;
        };
        _obj = [[[_obj, 150]], ["water"]] call BIS_fnc_randomPos;
        [_x, false, _obj, false] spawn pl_opfor_attack_closest_enemy;
    } forEach _grps;  

};


// pl_opfor_aggressivness = 0.6;
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

// execFSM "pl_opfor_cmd_commander.fsm"
