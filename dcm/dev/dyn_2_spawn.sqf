dyn2_spawn_squad = {	
	params ["_spawnPos", ["_watchDir", 0], ["_infType", dyn2_standart_squad]];

    if ([_spawnPos] call dyn2_is_water) exitWith {grpNull};

	private _grp = [_spawnPos, dyn2_opfor_side, _infType] call BIS_fnc_spawnGroup;
	_grp setFormDir _watchDir;
    (leader _grp) setDir _watchDir;
    // _grp enableDynamicSimulation true;

	_grp
};

dyn2_spawn_vehicle = {
	params ["_spawnPos", ["_watchDir", 0], ["_vicType", selectRandom dyn2_standart_combat_vehicles], ["_crewed", true]];

    if ([_spawnPos] call dyn2_is_water) exitWith {[grpNull, objNull]};

	private _vic = createVehicle [_vicType, _spawnPos, [], 0, "NONE"];	
	_vic setDir _watchDir;
    private _grp = grpNull;
    if (_crewed) then {
    	_grp = createVehicleCrew _vic;
    	// _grp enableDynamicSimulation true;
    };

    [_grp, _vic]
};

dyn2_spawn_covered_vehicle = {
    params ["_spawnPos", ["_watchDir", 0], ["_vicType", selectRandom dyn2_standart_combat_vehicles], ["_crewed", true], ["_dismounted", false]];

    if ([_spawnPos] call dyn2_is_water) exitWith {[grpNull, objNull]};

    private _vic = createVehicle [_vicType, _spawnPos, [], 0, "NONE"];  
    _vic setDir _watchDir;
    private _grp = grpNull;
    if (_crewed) then {
        _grp = createVehicleCrew _vic;
        // _grp enableDynamicSimulation true;
    };

    private _net = createVehicle [selectRandom ["CamoNet_OPFOR_big_F", "CamoNet_BLUFOR_big_F", "CamoNet_INDP_big_F"], getPosATLVisual _vic, [], 0, "CAN_COLLIDE"];
    _net setDir ((getDir _vic) - 180);

    private _infGrp = grpNull;
    if (_dismounted) then {
        _infGrp = [_spawnPos, 0, dyn2_standart_fire_team] call dyn2_spawn_squad;

        if !(isNull _grp) then {
            [_infGrp, _grp] spawn {
                params ["_infGrp", "_grp"];

                sleep 15;

                (units _infGrp) joinSilent _grp;
            };
        } else {
            _grp = _infGrp;
        };
    };

    [_grp, _vic]
};


dyn2_spawn_patroll = {
	params ["_spawnPos", ["_route", []]];

	_grp = [_spawnPos, 0, dyn2_standart_fire_team] call dyn2_spawn_squad;

	if (_route isEqualTo []) then {
		for "_i" from 0 to 3 do {
        	_route pushback ([[[_spawnPos, 300]], [[_spawnPos, 100], "water"]] call BIS_fnc_randomPos);
		};
	};

	{
        _grp addWaypoint [_x, 20];
    } forEach _route;
    _wp = _grp addWaypoint [_spawnPos, 20];
    _wp setWaypointType "CYCLE";
    _grp setBehaviour "SAFE";

    _grp
};

dyn2_spawn_road_block = {
	params ["_road", ["_dirCheck", player], ["_infType", dyn2_standart_fire_team]];

	private _info = getRoadInfo _road;    
    private _endings = [_info#6, _info#7];
	_endings = [_endings, [], {_x distance2D _dirCheck}, "ASCEND"] call BIS_fnc_sortBy;
    private _roadWidth = _info#1;
    private _rPos = ASLToATL (_endings#0);
    private _roadDir = (_endings#1) getDir (_endings#0);

    _grp = [getPos _road, _roadDir, _infType] call dyn2_spawn_squad;

    // RazorWire
    if (random(1) > 0.5) then {
        _b = "Land_Razorwire_F" createVehicle (_rPos getPos [5, _roadDir]);
        _b setDir _roadDir;
    } else {
        _comp = selectRandom ["Land_CncBlock_D", "Land_TyreBarrier_01_line_x4_F"];
        _leftPos = (_rPos getPos [5, _roadDir]) getPos [_roadWidth * 0.25, _roadDir - 90];
        _b = createVehicle [_comp, _leftPos , [], 0, "CAN_COLLIDE"];
        _b setDir _roadDir - 180;

        _rightPos = (_rPos getPos [15, _roadDir]) getPos [_roadWidth * 0.25, _roadDir + 90];
        _b = createVehicle [_comp, _rightPos , [], 0, "CAN_COLLIDE"];
        _b setDir _roadDir - 180;
    };

    _grp

};

dyn2_spawn_mines = {
	params ["_startPos", "_length", "_dir", ["_mineSpacing", 4], ["_mineRows", 2], ["_rowSpacing", 5]];

	private _allMines = [];

	for "_j" from 1 to _mineRows do {
        _minesAmount = round (_length / _mineSpacing);
        _offset = 0;
        for "_i" from 0 to _minesAmount do {
            _minePos = _startPos getPos [_offset, _dir + 90];
            if (_i % 2 == 0) then {
                _minePos = _startPos getPos [_offset, _dir - 90];
                _offset = _offset + _mineSpacing;
            };

            _mine = createMine ["ATMine", _minePos, [], 0];
            _mine enableDynamicSimulation true;
            _allMines pushBack _mine;

            // debug
            // _m = createMarker [str (random 5), _minePos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];
        };
        _mineSpacing = _mineSpacing * 0.66;
        _startPos = _startPos getPos [_rowSpacing, _dir - 180];
    };
    _allMines
};
