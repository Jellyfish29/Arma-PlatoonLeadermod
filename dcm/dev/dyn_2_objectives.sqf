dyn2_SIDE_mission_spawner = {
	params ["_locPos", "_playerStart", "_objslimit", ["_blackList", []]];

	// Secondary

	private _sideMissionTypes = ["road", "destroy_vic", "destroy_chache", "mortar", "hill", "position", "_defend", "ambush", "help_civ", "HVT", "crash", "help_ally"];
	private _sideMissionType = selectRandom _sideMissionTypes;
	private	_selectedMissionTypes = [];
	private _success = false;
	private _defDir = _locPos getDir _playerStart;


	_sideMissionTypes = _sideMissionTypes - _blackList;

	// if ((random 1) > 0.5) then {
	// 	0 = [_locPos, _playerStart] call dyn2_SIDE_defend;
	// };

	// [_playerStart, _playerStart] call dyn2_SIDE_capture_HVT;

	private _sideMissionCount = 0;

	while {_sideMissionCount < _objslimit and count _sideMissionTypes > 0} do {

		_success = false;
		_sideMissionType = selectRandom _sideMissionTypes;
		switch (_sideMissionType) do {

			case "road" : {_success = [_locPos, _playerStart] call dyn2_SIDE_clear_road}; 
			case "destroy_vic" : {_success = [_locPos, _playerStart] call dyn2_SIDE_destroy_vehicle};
			case "destroy_chache" : {_success = [_locPos, _playerStart] call dyn2_SIDE_destroy_chache};
			case "hill" : {_success = [_locPos, _playerStart] call dyn2_SIDE_capture_hill};
			case "position" : {_success = [_locPos, _playerStart] call dyn2_SIDE_destroy_position};
			case "mortar" : {_success = [_locPos, _playerStart] call dyn2_SIDE_destroy_mortar};
			case "defend" : {_success = [_locPos, _playerStart] call dyn2_SIDE_defend};
			case "ambush" : { _success = [_locPos, _playerStart] call dyn2_SIDE_ambush_convoy};
			case "help_civ" : { _success = [_locPos, _playerStart] call dyn2_SIDE_free_civilians};
			case "HVT" : { _success = [_locPos, _playerStart] call dyn2_SIDE_capture_HVT};
			case "crash" : { _success = [_locPos, _playerStart] call dyn2_SIDE_secure_crash_site};
			case "help_ally" : { _success = [_locPos, _playerStart] call dyn2_help_allies_qrf};
			default {}; 
		};

		if (_success) then {
			_sideMissionTypes deleteAt (_sideMissionTypes find _sideMissionType);
			_selectedMissionTypes pushBack _sideMissionType;
			_sideMissionCount = _sideMissionCount + 1;
		};
	};

	// [_locPos, _playerStart] call dyn2_SIDE_free_civilians;

	if (!("hill" in _selectedMissionTypes) and !("hill" in _blacklist)) then {
    	private _hillPos = [_locPos getpos [500, _defDir], 1000, _defDir] call dyn2_find_highest_point;
    	[_hillPos, _defDir, dyn2_standart_fire_team] call dyn2_spawn_squad;
	};
};

dyn2_town_assault = {
	params ["_loc"];

    // _m = createMarker [str (random 1), getPos _loc];
    // _m setMarkerType "mil_circle";
    // _m setMarkerColor "colorOPFOR";

	private _locPos = getPos _loc;
    // _playerStart = [[[_locPos, 3500]], [[_locPos, 2500], "water"]] call BIS_fnc_randomPos;

    private _playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];

	while {surfaceIsWater _playerStart} do {
		_playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];
	};

	private _playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];

	while {surfaceIsWater _playerStart} do {
		_playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];
	};
	_startRoad = [_playerStart, 800] call BIS_fnc_nearestRoad;
	private _defDir = _locPos getDir _playerStart;
	private _allBuildings = nearestObjects [getPos _loc, ["house"], 400];
	private _allRoads = _locPos nearRoads 300;
	private _allGrps = [];
	private _validBuildings = [];

	// Valid Buildings
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 4 and !(isHidden _x)) then {
            _validBuildings pushBack _x;
        };
    } forEach _allBuildings;


	// outer defense

	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_building =  ([_allBuildings, [], {(getpos _x) distance2D _playerStart}, "ASCEND"] call BIS_fnc_sortBy)#0;
		_allBuildings deleteAt (_allBuildings find _building);
		_allGrps pushBack ([getPos _building, _defDir, dyn2_standart_squad, true] call dyn2_spawn_squad);
	};

	// Random Garrison
	for "_i" from 0 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_building = selectRandom _validBuildings;
		_validBuildings deleteAt (_validBuildings find _building);
		_grp = [getPos _building, _defDir, dyn2_standart_fire_team, true] call dyn2_spawn_squad;
		_allGrps pushBack _grp;
		[_building, _grp, _defDir] call dyn2_garrison_building;
	};

	// Patroll
	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_allGrps pushBack ([[[[_locPos, 400]], [[_locPos, 50], "water"]] call BIS_fnc_randomPos] call dyn2_spawn_patroll);
	};

	// Random Road Vehicle
	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        
        _allGrps pushBack (([getPos _road, _roadDir] call dyn2_spawn_vehicle)#0);
	};

	// Vehicle Patroll
	private _allRoads = _locPos nearRoads 800;
	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        _car = createVehicle [selectRandom dyn2_standart_combat_vehicles, getPos _road, [], 0, "NONE"];
        _carGrp = createVehicleCrew _car;
        _carGrp setBehaviour "SAFE";
        _allGrps pushBack _carGrp;
        // _carGrp enableDynamicSimulation true;
        // _car enableDynamicSimulation true;

        _allRoads = _allRoads call BIS_fnc_arrayShuffle;
        _targetRoad = {
            if ((getPos _x) distance2d (getPos _road) > 600) exitWith {_x};
            objNull
        } forEach _allRoads;
        _allRoads deleteAt (_allRoads find _targetRoad);

        _wp = _carGrp addWaypoint [getPos _targetRoad, -1];
        // _wp = _carGrp addWaypoint [_targetRoad2, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp setWaypointType "CYCLE";
	};

	// Roadbloack
	private _lastRoad = selectRandom _allRoads;
	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_allRoads = _allRoads call BIS_fnc_arrayShuffle;
		_road = {
			if ((getpos _x) distance2D _lastRoad > 100) exitWith {_x};
			objNull
		} forEach _allRoads;

		if !(isNull _road) then {
			_lastRoad = _road;
			_allRoads deleteAt (_allRoads find _road);
			_allGrps pushBack ([_road] call dyn2_spawn_road_block);
		};
	};

	// Secondary

	[_locPos, _playerStart, 1 + dyn2_strength + ([1, 3] call BIS_fnc_randomInt)] call dyn2_SIDE_mission_spawner;

	[getPos _startRoad, _locPos] spawn dyn2_place_player;

	[_locPos] spawn dyn2_OPF_continous_opfor_mission_spawner;

	// [_locPos, _playerStart] spawn dyn2_SIDE_destroy_position;

	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 2000];
	_civilTowns = _civilTowns - [_loc];

	{
	  	[_x, 10 - dyn2_strength, [10, 15] call BIS_fnc_randomInt, [1, 2] call BIS_fnc_randomInt, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;
	[_loc, 12 - dyn2_strength, [10, 15] call BIS_fnc_randomInt, [1, 2] call BIS_fnc_randomInt, 500] spawn dyn2_cvivilian_presence;

    [_locPos, _playerStart, _allBuildings] spawn pl_draw_scenario;

	[_locPos, _playerStart] call dyn2_AO_destruction;

	[_locPos, _playerStart] call dyn2_random_fires;

	[_locPos, _playerStart] call dyn2_spawn_allied_positions;


    _endTrg = createTrigger ["EmptyDetector", (getPos _loc), true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [600, 600, _defDir, false, 30];
    _endTrg setTriggerTimeout [120, 150, 200, false];

    _locationName = text _loc;

    [west, format ["task_%1", _loc], ["Offensive", format ["Retake %1", _locationName], ""], getPos _loc, "CREATED", 1, true, "attack", false] call BIS_fnc_taskCreate;

    [_endTrg, _loc] spawn {
    	params ["_endTrg", "_loc"]; 
    	waitUntil {sleep 2; triggerActivated _endTrg};
    	[format ["task_%1", _loc], "SUCCEEDED", true] call BIS_fnc_taskSetState;
	};
};

dyn2_small_town_assault = {
	params ["_loc"];

	private _locPos = getPos _loc;
	// private _playerStart = [[[_locPos, 2500]], [[_locPos, 2000], "water"]] call BIS_fnc_randomPos;

	private _playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];

	while {surfaceIsWater _playerStart} do {
		_playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];
	};

	private _startRoad = [_playerStart, 1500] call BIS_fnc_nearestRoad;
	private _defDir = _locPos getDir _playerStart;

	private _allBuildings = nearestObjects [getPos _loc, ["house"], 400];
	private _allRoads = _locPos nearRoads 400;
	private _allGrps = [];

	// outer defense

	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_building =  ([_allBuildings, [], {(getpos _x) distance2D _playerStart}, "ASCEND"] call BIS_fnc_sortBy)#0;
		_allBuildings deleteAt (_allBuildings find _building);
		_allGrps pushBack ([getPos _building, _defDir, dyn2_standart_squad, true] call dyn2_spawn_squad);
	};

	// Random Field Vehicle
    private _forwardPos = _locPos getPos [300, _defDir];
	for "_i" from 1 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
		_spawnPos = [[[_forwardPos, 500]], [ "water"]] call BIS_fnc_randomPos;
		_spawnPos = [_spawnPos, 1, 400, 1, 0, 2, 0] call BIS_fnc_findSafePos;
        _allGrps pushBack (([_spawnPos, _defDir, selectRandom dyn2_standart_combat_vehicles, selectRandom [true, false], true] call dyn2_spawn_covered_vehicle)#0);
	};

	// Random Road Vehicle
	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        
        _allGrps pushBack (([getPos _road, _roadDir] call dyn2_spawn_vehicle)#0);
	};

	// Vehicle Patroll
	private _allRoads = _locPos nearRoads 800;
	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        _car = createVehicle [selectRandom dyn2_standart_combat_vehicles, getPos _road, [], 0, "NONE"];
        _carGrp = createVehicleCrew _car;
        _carGrp setBehaviour "SAFE";
        _allGrps pushBack _carGrp;
        // _carGrp enableDynamicSimulation true;
        // _car enableDynamicSimulation true;

        _allRoads = _allRoads call BIS_fnc_arrayShuffle;
        _targetRoad = {
            if ((getPos _x) distance2d (getPos _road) > 600) exitWith {_x};
            objNull
        } forEach _allRoads;
        _allRoads deleteAt (_allRoads find _targetRoad);

        _wp = _carGrp addWaypoint [getPos _targetRoad, -1];
        // _wp = _carGrp addWaypoint [_targetRoad2, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp setWaypointType "CYCLE";
	};

	// Secondary

	[_locPos, _playerStart, 1 + dyn2_strength + ([1, 3] call BIS_fnc_randomInt)] call dyn2_SIDE_mission_spawner;
	[_locPos] spawn dyn2_OPF_continous_opfor_mission_spawner;

	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 2000];
	_civilTowns = _civilTowns - [_loc];

{
	  	[_x, 10 - dyn2_strength, [10, 15] call BIS_fnc_randomInt, [1, 2] call BIS_fnc_randomInt, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;
	[_loc, 12 - dyn2_strength, [10, 15] call BIS_fnc_randomInt, [1, 2] call BIS_fnc_randomInt, 500] spawn dyn2_cvivilian_presence;


	[getPos _startRoad, _locPos] spawn dyn2_place_player;

	[_locPos, _playerStart, []] spawn pl_draw_scenario;

	[_locPos, _playerStart] call dyn2_AO_destruction;

	[_locPos, _playerStart] call dyn2_random_fires;

	[_locPos, _playerStart] call dyn2_spawn_allied_positions;

	_endTrg = createTrigger ["EmptyDetector", (getPos _loc), true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [600, 600, _defDir, false, 30];
    _endTrg setTriggerTimeout [120, 150, 200, false];

    _locationName = text _loc;

    [west, format ["task_%1", _loc], ["Offensive", format ["Retake %1", _locationName], ""], getPos _loc, "CREATED", 1, true, "attack", false] call BIS_fnc_taskCreate;

    [_endTrg, _loc] spawn {
    	params ["_endTrg", "_loc"]; 
    	waitUntil {sleep 2; triggerActivated _endTrg};
    	[format ["task_%1", _loc], "SUCCEEDED", true] call BIS_fnc_taskSetState;
	};
};


dyn2_field_assault = {
	params ["_blacklist"];
	private ["_locPos"];
	
	private _valid = false;

	while {!_valid} do {

		_locPos = [[[dyn2_map_center, worldSize / 2]], ["water"]] call BIS_fnc_randomPos;

		_valid = {
            if (_locPos inArea _x) exitWith {false};
            true
        } forEach _blacklist;

	};

	// private _playerStart = [[[_locPos, 2500]], [[_locPos, 2000], "water"]] call BIS_fnc_randomPos;

	private _playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];

	while {surfaceIsWater _playerStart} do {
		_playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];
	};

	private _startRoad = [_playerStart, 800] call BIS_fnc_nearestRoad;
	private _defDir = _locPos getDir _playerStart;
	private _allRoads = _locPos nearRoads 1000;
	private _allGrps = [];

	// _success = [_locPos, _playerStart] call dyn2_SIDE_secure_crash_site;

	[_locPos, _playerStart, 1 + dyn2_strength + ([1, 2] call BIS_fnc_randomInt), ["position"]] call dyn2_SIDE_mission_spawner;

	[_locPos] spawn dyn2_OPF_continous_opfor_mission_spawner;

	// Ambiance

	[_locPos, 600, "OBJ", "colorOPFOR"] call dyn2_draw_mil_symbol_objectiv_free;

	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 2000];

	{
	  	[_x, 10 - dyn2_strength, [10, 15] call BIS_fnc_randomInt, [1, 2] call BIS_fnc_randomInt, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;

	_success = [_locPos, _playerStart, true] call dyn2_SIDE_destroy_position;


	[getPos _startRoad, _locPos] spawn dyn2_place_player;

	[_locPos, _playerStart, []] spawn pl_draw_scenario;

	[_locPos, _playerStart] call dyn2_AO_destruction;

	[_locPos, _playerStart] call dyn2_random_fires;

	[_locPos, _playerStart] call dyn2_spawn_allied_positions;


	// Random Field Vehicle
    private _forwardPos = _locPos getPos [300, _defDir];
	for "_i" from 1 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
		_spawnPos = [[[_forwardPos, 500]], [ "water"]] call BIS_fnc_randomPos;
		_spawnPos = [_spawnPos, 1, 400, 1, 0, 2, 0] call BIS_fnc_findSafePos;
        _allGrps pushBack (([_spawnPos, _defDir, selectRandom dyn2_standart_combat_vehicles, selectRandom [true, false], true] call dyn2_spawn_covered_vehicle)#0);
	};

	// Random Road Vehicle
	for "_i" from 1 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        
        _allGrps pushBack (([getPos _road, _roadDir] call dyn2_spawn_vehicle)#0);
	};

	// Vehicle Patroll
	for "_i" from 1 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        _car = createVehicle [selectRandom dyn2_standart_combat_vehicles, getPos _road, [], 0, "NONE"];
        _carGrp = createVehicleCrew _car;
        _carGrp setBehaviour "SAFE";
        _allGrps pushBack _carGrp;
        // _carGrp enableDynamicSimulation true;
        // _car enableDynamicSimulation true;

        _allRoads = _allRoads call BIS_fnc_arrayShuffle;
        _targetRoad = {
            if ((getPos _x) distance2d (getPos _road) > 600) exitWith {_x};
            objNull
        } forEach _allRoads;
        _allRoads deleteAt (_allRoads find _targetRoad);

        _wp = _carGrp addWaypoint [getPos _targetRoad, -1];
        // _wp = _carGrp addWaypoint [_targetRoad2, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp setWaypointType "CYCLE";
	};

};

dyn2_air_field_assault = {
	params ["_locPos"];

	// private _locPos = getPos _loc;
	// private _playerStart = [[[_locPos, 3000]], [[_locPos, 2000], "water"]] call BIS_fnc_randomPos;
	private _playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];

	while {surfaceIsWater _playerStart} do {
		_playerStart = _locPos getPos [[2000, 3000] call BIS_fnc_randomInt, random 360];
	};

	private _startRoad = [_playerStart, 1500] call BIS_fnc_nearestRoad;
	private _defDir = _locPos getDir _playerStart;

	// _m = createMarker [str (random 5), _playerStart];
	// _m setMarkerType "mil_marker";
	// _m setMarkerColor "colorBlue";

	// _m = createMarker [str (random 5), getpos _startRoad];
	// _m setMarkerType "mil_marker";
	// _m setMarkerColor "colorGreen";

	private _allBuildings = nearestObjects [_locPos, ["house"], 800];
	private _allRoads = _locPos nearRoads 800;
	private _allGrps = [];

	// Random Infantry
	for "_i" from 1 to dyn2_strength + 1 do {
		_building = selectRandom _allBuildings;
		_allBuildings deleteAt (_allBuildings find _building);
		_allGrps pushBack ([getPos _building, _defDir] call dyn2_spawn_squad);
	};

	private _allPlanes = [];

	// Parked Planes
	_planeType = selectRandom [dyn2_standart_transport_heli, dyn2_standart_transport_plane];
	for "_i" from 0 to dyn2_strength do {
		_planePos = _locPos getPos [25 * _i, _defDir];
		_allPlanes pushBack (([_planePos, _defDir + 90, _planeType, false] call dyn2_spawn_vehicle)#1);
	};
	_allGrps pushBack ([_locPos getPos [50, _defDir], _defDir] call dyn2_spawn_squad);

	// Patrols
	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_allGrps pushBack ([[[[_locPos, 500]], [[_locPos, 50], "water"]] call BIS_fnc_randomPos] call dyn2_spawn_patroll);
	};

	
	// Random Field Vehicle
    private _forwardPos = _locPos getPos [300, _defDir];
	for "_i" from 1 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
		_spawnPos = [[[_forwardPos, 500]], [ "water"]] call BIS_fnc_randomPos;
		_spawnPos = [_spawnPos, 1, 400, 1, 0, 2, 0] call BIS_fnc_findSafePos;
        _allGrps pushBack (([_spawnPos, _defDir, selectRandom dyn2_standart_combat_vehicles, selectRandom [true, false], true] call dyn2_spawn_covered_vehicle)#0);
	};

	// Random Road Vehicle
	for "_i" from 1 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        
        _allGrps pushBack (([getPos _road, _roadDir] call dyn2_spawn_vehicle)#0);
	};

	// Vehicle Patroll
	for "_i" from 1 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        _car = createVehicle [selectRandom dyn2_standart_combat_vehicles, getPos _road, [], 0, "NONE"];
        _carGrp = createVehicleCrew _car;
        _carGrp setBehaviour "SAFE";
        _allGrps pushBack _carGrp;
        // _carGrp enableDynamicSimulation true;
        // _car enableDynamicSimulation true;

        _allRoads = _allRoads call BIS_fnc_arrayShuffle;
        _targetRoad = {
            if ((getPos _x) distance2d (getPos _road) > 600) exitWith {_x};
            objNull
        } forEach _allRoads;
        _allRoads deleteAt (_allRoads find _targetRoad);

        _wp = _carGrp addWaypoint [getPos _targetRoad, -1];
        // _wp = _carGrp addWaypoint [_targetRoad2, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp setWaypointType "CYCLE";
	};

	private _allBuildings = nearestTerrainObjects [_locPos, ["BUILDING", "HOUSE", "Ruin"], 500, true];

    private _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 6 and !(isHidden _x)) then {
            _validBuildings pushBack _x;
        };
    } forEach _allBuildings;

    if !(_validBuildings isEqualTo []) then {
        [getpos (([_validBuildings, [], {(getpos _x) distance2D _locPos}, "ASCEND"] call BIS_fnc_sortBy)#0), _defDir] call dyn2_spawn_squad;
        if (((random 1) > 0.5) and (count _validBuildings) > 1) then {
            [getpos (([_validBuildings, [], {(getpos _x) distance2D _locPos}, "ASCEND"] call BIS_fnc_sortBy)#1), _defDir] call dyn2_spawn_squad;
        };
    };

	// intinital reinforcement insertion

	[_locPos, _playerStart] spawn {
		params ["_locPos", "_playerStart"];

		// sleep 5;

		sleep ([60, 180] call BIS_fnc_randomInt);

		[_locPos getpos [1000, _playerStart getDir _locPos], _locPos] call dyn2_OPF_heli_insertion;

	};


	// Sidemission
	[_locPos, _playerStart, 1 + dyn2_strength + ([0, 2] call BIS_fnc_randomInt), ["destroy_vic"]] call dyn2_SIDE_mission_spawner;

	_success = [_locPos, _playerStart] call dyn2_SIDE_destroy_mortar;

	[_locPos] spawn dyn2_OPF_continous_opfor_mission_spawner;
	// _success = [_locPos, _playerStart] call dyn2_SIDE_clear_road;

	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 2000];

	{
	  	[_x, 10 - dyn2_strength, [10, 15] call BIS_fnc_randomInt, [1, 2] call BIS_fnc_randomInt, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;

	[getPos _startRoad, _locPos] spawn dyn2_place_player;

	[_locPos, 800, format ["%1 Air Assault", toUpper dyn2_opfor_fation]] call dyn2_draw_mil_symbol_objectiv_free;

	[_locPos, _playerStart] call dyn2_AO_destruction;

	[_locPos, _playerStart] call dyn2_random_fires;

	[_locPos, _playerStart] call dyn2_spawn_allied_positions;

	[_locPos, [2, 4] call BIS_fnc_randomInt, [dyn2_standart_transport_heli, dyn2_standart_transport_plane], [dyn2_standart_soldier], false, 300] spawn dyn2_destroyed_mil_vic;

	// _arrowMarker = createMarker [str (random 5), _locPos getPos [1500, _defDir]];
    // _arrowMarker setMarkerType "marker_std_atk";
    // _arrowMarker setMarkerSize [1, 1];
    // _arrowMarker setMarkerColor dyn2_side_color;
    // _arrowMarker setMarkerDir (_defDir - 180);
    // _arrowMarker setMarkerText (format ["%1 Incursion", toUpper dyn2_opfor_fation]);

    // _natoMarker = createMarker [str (random 5), _locPos getPos [3000, _defDir]];
    // _natoMarker setMarkerType "flag_NATO";
    // _natoMarker setMarkerSize [1.3, 1.3];

    [west, format ["task_%1", _allPlanes], ["Offensive", format ["Destroy Enemy %1", "Aircraft"], ""], getPos (_allPlanes#1), "CREATED", 1, true, "destroy", false] call BIS_fnc_taskCreate;

    [_allPlanes, _locPos] spawn {
    	params ["_allPlanes", "_objCenter"];

    	waitUntil {sleep 2; ({alive _x} count _allPlanes) <= 0};

    	[format ["task_%1", _allPlanes], "SUCCEEDED", true] call BIS_fnc_taskSetState;

	};

	_endTrg = createTrigger ["EmptyDetector", _locPos, true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [600, 600, _defDir, false, 30];
    _endTrg setTriggerTimeout [120, 150, 200, false];

    [west, format ["task_%1", _locPos], ["Offensive", format ["Retake %1", "Air Field"], ""], _locPos getPos [100, _defDir - 180], "CREATED", 1, true, "attack", false] call BIS_fnc_taskCreate;

    [_endTrg, _locPos] spawn {
    	params ["_endTrg", "_locPos"]; 
    	waitUntil {sleep 2; triggerActivated _endTrg};
    	[format ["task_%1", _locPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;
	};
};

dyn2_defence = {
	params ["_loc"];

	private _msr = [];
	private _locPos = getPos _loc;
	private _locRoad = [_locPos, 1500] call BIS_fnc_nearestRoad;
	private _opforStart = [[[_locPos, 4000]], [[_locPos, 1800], "water"]] call BIS_fnc_randomPos;
	private _opforstartRoad = [_opforStart, 1000] call BIS_fnc_nearestRoad;

	while {_msr isEqualTo []} do {
		_msr = [_opforstartRoad , _locRoad] call dyn2_convoy_parth_find;
		if (_msr isNotEqualTo []) exitWith {};

		_opforStart = [[[_locPos, 4000]], [[_locPos, 3000], "water"]] call BIS_fnc_randomPos;
		_opforstartRoad = [_opforStart, 1500] call BIS_fnc_nearestRoad;
	};

	private _convoyMSRPath = _msr apply {getPos _x};
	pl_draw_convoy_path_array = pl_draw_convoy_path_array + [_convoyMSRPath];
	_opforStart = getPos _opforstartRoad;


	private _defDir = _locPos getDir _opforStart;
	private _playerStart = _locPos getPos [[800, 1200] call BIS_fnc_randomInt, _opforStart getDir _locPos];
	private _startRoad = [_playerStart, 800] call BIS_fnc_nearestRoad;

	_endTrg = createTrigger ["EmptyDetector", _locPos, true];
    _endTrg setTriggerActivation ["EAST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [600, 600, _defDir, false, 30];
    _endTrg setTriggerTimeout [120, 150, 200, false];

    // _m = createMarker [str (random 5), _opforStart];
    // _m setMarkerType "mil_marker";

    _locationName = text _loc;
    private _waves = dyn2_strength + 2 + ([0,2] call BIS_fnc_randomInt);

	[getPos _startRoad, _locPos] spawn dyn2_place_player;

	private _midPoint = _locPos getPos [(_opforStart distance2d _locPos) * 0.4, _defDir]; 

	// Side Missions
	// [_opforStart] spawn dyn2_OPF_continous_opfor_mission_spawner;

	[_midPoint, _locPos, 2, ["road", "destroy_chache", "hill", "position", "_defend", "ambush", "mortar", "destroy_vic"]] call dyn2_SIDE_mission_spawner;

	0 = [_opforStart, _locPos, true] spawn dyn2_SIDE_destroy_mortar;

	// Draw Scenario
	[_midPoint, _locPos, []] spawn pl_draw_scenario;

	[_locPos, 800, "OBJ", "colorBLUFOR"] call dyn2_draw_mil_symbol_objectiv_free;

	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 2000];

	{
	  	[_x, 10 - dyn2_strength, [10, 15] call BIS_fnc_randomInt, [1, 2] call BIS_fnc_randomInt, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;

	[_midPoint, _locPos] spawn dyn2_AO_destruction;

	[_midPoint, _locPos] spawn dyn2_random_fires;

	[_opforStart, _playerStart] spawn dyn2_spawn_allied_positions;


	// sleep 10;

	_timeOut = ([1200, 1500] call BIS_fnc_randomInt);
	// _timeOut = 2;
	_minAdd = (_timeOut + (random [-60, 0, 60])) / 60 * 1.6 / 100;
	_arrivalTime = [daytime + _minAdd, "HH:MM"] call BIS_fnc_timeToString;

	[side player, "HQ"] sideChat (format ["Enemy Main Attack expected at %1", _arrivalTime]);
	sleep 1;
	[side player, "HQ"] sideChat (format ["Clear %1 and prepare the defense", _locationName]);

	[west, format ["task_%1", _loc], [format ["Attack expected at %1", _arrivalTime], format ["Defend At %1", _locationName], ""], getPos _loc, "CREATED", 1, true, "defend", false] call BIS_fnc_taskCreate;

    // [_endTrg, _loc] spawn {
    // 	params ["_endTrg", "_loc"]; 
    // 	waitUntil {sleep 2; triggerActivated _endTrg};
    // 	[format ["task_%1", _loc], "FAILED", true] call BIS_fnc_taskSetState;
    // 	hint "Defeat : (";
	// };

	sleep 5;

	pl_opfor_all_objectives pushBack _locPos;
	private _convoyMSRPath = _msr apply {getPos _x};
	pl_draw_convoy_path_array = pl_draw_convoy_path_array + [_convoyMSRPath];
	_msrMarkerPos = ([_msr, [], {(getpos _x) distance2D _midPoint}, "ASCEND"] call BIS_fnc_sortBy)#0;
	private _msrMarker = createMarker [str (random 5), _msrMarkerPos];
	_msrMarker setMarkerType "mil_triangle";
	_msrMarker setMarkerColor "colorOPFOR";
	_msrMarker setMarkerText "MSR";
	_msrMarker setMarkerSize [0.5, 0.5];

	_msr2 = [_startRoad , _locRoad] call dyn2_convoy_parth_find;

	_convoyMSRPath2 = _msr2 apply {getPos _x};
	pl_draw_convoy_path_array = pl_draw_convoy_path_array + [_convoyMSRPath2];

	// _timeOut = 60;

	sleep (_timeOut * 0.5);

	0 = [_opforStart, _locPos, _opforStart] call dyn2_OPF_recon_patrol;

	sleep (_timeOut * 0.5);

	[side player, "HQ"] sideChat "Enemy assault force detected";

	for "_i" from 0 to _waves do {

        for "_j" from 0 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
            0 = [_opforStart, _locPos, true, _opforStart] call dyn2_OPF_catk;
        	sleep 2;
        };

        // 0 = [_opforStart, _locPos, false, _opforStart] call dyn2_OPF_catk;

        if ((random 1) > 0.8) then {
       		0 = [_opforStart, _locPos, _opforStart] call dyn2_OPF_armor_attack;
       	} else {
       		0 = [_opforStart, _locPos, _opforStart, "O_APC_Tracked_02_cannon_F"] call dyn2_OPF_armor_attack;
       };
        _artySuccess = [[3, 6] call BIS_fnc_randomInt, _locPos] spawn dyn2_OPF_fire_mission;

        // 10 - 15 min
        sleep ([600, 900] call BIS_fnc_randomInt);

        [side player, "HQ"] sideChat "New enemy assault detected";

	};

	sleep ([600, 900] call BIS_fnc_randomInt);

	if !(triggerActivated _endTrg) then {
		[format ["task_%1", _loc], "SUCCEEDED", true] call BIS_fnc_taskSetState;
		hint "Victory : )";
	};
};


dyn2_air_assault_attack = {
	params ["_loc"];

	private _locPos = getPos _loc;
	private _playerStart = [[[_locPos, worldsize * 0.4]], [[_locPos, worldsize * 0.3]]] call BIS_fnc_randomPos;
	private _defDir = _locPos getDir _playerStart;
	private _LzPos = [_locPos getpos [2000, _defDir], 0, 1000, 20, 0, 0.1, 0, [_locPos getpos [2000, _defDir], [0,0,0]]] call BIS_fnc_findSafePos;

	private _allBuildings = nearestObjects [getPos _loc, ["house"], 400];
	private _allRoads = _locPos nearRoads 1500;
	private _allGrps = [];

	_m = createMarker [str (random 1), _lzPos];
	_m setMarkerType "mil_marker";

	// [_playerAirStart, _locPos] spawn {
	// 	params ["_playerAirStart", "_locPos"]

	// };

	sleep 1;
	setDate [date#0, date#1, date#2, selectRandom ([[21, 23] call BIS_fnc_randomInt, [0, 4] call BIS_fnc_randomInt]), [0, 60] call BIS_fnc_randomInt];

	[_playerStart, _lzPos] spawn dyn2_place_player_air_assault;

	0 = [_locPos, _playerStart, true] spawn dyn2_SIDE_destroy_vehicle;

	0 = [_locPos, _playerStart, true] spawn dyn2_SIDE_destroy_chache;

	// outer defense

	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		// _building =  ([_allBuildings, [], {(getpos _x) distance2D _playerStart}, "ASCEND"] call BIS_fnc_sortBy)#0;
		_building = selectRandom _allBuildings;
		_allBuildings deleteAt (_allBuildings find _building);
		_allGrps pushBack ([getPos _building, _defDir, dyn2_standart_squad, true] call dyn2_spawn_squad);
	};

	// Random Road Vehicle
	for "_i" from 1 to dyn2_strength + 1 + ([1, 2] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        
        _allGrps pushBack (([getPos _road, _roadDir] call dyn2_spawn_vehicle)#0);
	};
	
	// Random Patrolls
	for "_i" from 1 to dyn2_strength + 1 + ([1, 3] call BIS_fnc_randomInt) do {
		_route = [[[[_locPos, 2000]], [[_locPos, 800], "water"]] call BIS_fnc_randomPos, [[[_locPos, 2000]], [[_locPos, 800], "water"]] call BIS_fnc_randomPos,[[[_locPos, 2000]], [[_locPos, 800], "water"]] call BIS_fnc_randomPos];
		_allGrps pushBack ([[[[_locPos, 2000]], [[_locPos, 800], "water"]] call BIS_fnc_randomPos, _route] call dyn2_spawn_patroll);
	};


	// Vehicle Patroll
	private _allRoads = _locPos nearRoads 400;
	for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
		_road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        _car = createVehicle [selectRandom dyn2_standart_combat_vehicles, getPos _road, [], 0, "NONE"];
        _carGrp = createVehicleCrew _car;
        _carGrp setBehaviour "SAFE";
        _allGrps pushBack _carGrp;
        // _carGrp enableDynamicSimulation true;
        // _car enableDynamicSimulation true;

        _allRoads = _allRoads call BIS_fnc_arrayShuffle;
        _targetRoad = {
            if ((getPos _x) distance2d (getPos _road) > 600) exitWith {_x};
            objNull
        } forEach _allRoads;
        _allRoads deleteAt (_allRoads find _targetRoad);

        _wp = _carGrp addWaypoint [getPos _targetRoad, -1];
        // _wp = _carGrp addWaypoint [_targetRoad2, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp setWaypointType "CYCLE";
	};

	// Secondary

	[_locPos, _playerStart, dyn2_strength + 1, ["position", "_defend", "ambush", "mortar", "destroy_vic", "destroy_chache", "crash", "help_ally"]] call dyn2_SIDE_mission_spawner;
	[_locPos] spawn dyn2_OPF_continous_opfor_mission_spawner;

	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 3000];
	_civilTowns = _civilTowns - [_loc];

	{
	  	[_x, 10 - dyn2_strength, [20, 30] call BIS_fnc_randomInt, [1, 3] call BIS_fnc_randomInt, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;
	[_loc, 12 - dyn2_strength, [20, 30] call BIS_fnc_randomInt, [1, 3] call BIS_fnc_randomInt, 700] spawn dyn2_cvivilian_presence;


	// [getPos _startRoad, _locPos] spawn dyn2_place_player;

	// [_locPos, _playerStart, []] spawn pl_draw_scenario;

	[_locPos, 1500, format ["OBJ", ""], "colorBLUFOR"] call dyn2_draw_mil_symbol_objectiv_free;

	// [_locPos, _playerStart] call dyn2_AO_destruction;

	// [_locPos, _playerStart] call dyn2_random_fires;

	_endTrg = createTrigger ["EmptyDetector", (getPos _loc), true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [600, 600, _defDir, false, 30];
    _endTrg setTriggerTimeout [120, 150, 200, false];

    _locationName = text _loc;

    // [west, format ["task_%1", _loc], ["Offensive", format ["Retake %1", _locationName], ""], getPos _loc, "CREATED", 1, true, "attack", false] call BIS_fnc_taskCreate;

    // [_endTrg, _loc] spawn {
    // 	params ["_endTrg", "_loc"]; 
    // 	waitUntil {sleep 2; triggerActivated _endTrg};
    // 	[format ["task_%1", _loc], "SUCCEEDED", true] call BIS_fnc_taskSetState;
	// };



};


dyn2_air_assault_defend = {
	params ["_loc"];

	private _locPos = getPos _loc;
	private _opforStart = [[[_locPos, 4000]], [[_locPos, 1800], "water"]] call BIS_fnc_randomPos;
	private _opforstartRoad = [_opforStart, 1000] call BIS_fnc_nearestRoad;
	private _LzPos = [_locPos getpos [600, _opforStart getDir _locPos], 0, 1000, 20, 0, 0.1, 0, [_locPos getpos [600, _opforStart getDir _locPos], [0,0,0]]] call BIS_fnc_findSafePos;
	private _playerStart = _lzPos getpos [8000, _opforStart getDir _locPos];
	private _defDir = _locPos getDir _playerStart;

	private _allBuildings = nearestObjects [getPos _loc, ["house"], 400];
	private _allRoads = _locPos nearRoads 1500;
	private _allGrps = [];

	_m = createMarker [str (random 1), _lzPos];
	_m setMarkerType "mil_marker";

	[_playerStart, _lzPos] spawn dyn2_place_player_air_assault;

	_endTrg = createTrigger ["EmptyDetector", _locPos, true];
    _endTrg setTriggerActivation ["EAST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [600, 600, _defDir, false, 30];
    _endTrg setTriggerTimeout [120, 150, 200, false];

    // _m = createMarker [str (random 5), _opforStart];
    // _m setMarkerType "mil_marker";

    _locationName = text _loc;
    private _waves = dyn2_strength + ([1,2] call BIS_fnc_randomInt);

	private _midPoint = _locPos getPos [(_opforStart distance2d _locPos) * 0.4, _defDir]; 

	// Side Missions
	// [_opforStart] spawn dyn2_OPF_continous_opfor_mission_spawner;

	// [_midPoint, _locPos, 2, ["road", "destroy_chache", "hill", "position", "_defend", "ambush", "mortar", "destroy_vic"]] call dyn2_SIDE_mission_spawner;

	0 = [_opforStart, _locPos, true] spawn dyn2_SIDE_destroy_mortar;

	// Draw Scenario
	[_midPoint, _locPos, []] spawn pl_draw_scenario;

	[_locPos, 800, "OBJ", "colorBLUFOR"] call dyn2_draw_mil_symbol_objectiv_free;

	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 2000];

	{
	  	[_x, 10 - dyn2_strength, [10, 15] call BIS_fnc_randomInt, [1, 2] call BIS_fnc_randomInt, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;

	[_midPoint, _locPos] spawn dyn2_AO_destruction;

	[_midPoint, _locPos] spawn dyn2_random_fires;

	// [_opforStart, _playerStart] spawn dyn2_spawn_allied_positions;


	// sleep 10;

	_timeOut = ([1200, 1500] call BIS_fnc_randomInt);
	// _timeOut = 2;
	_minAdd = (_timeOut + (random [-60, 0, 60])) / 60 * 1.6 / 100;
	_arrivalTime = [daytime + _minAdd, "HH:MM"] call BIS_fnc_timeToString;

	[side player, "HQ"] sideChat (format ["Enemy Main Attack expected at %1", _arrivalTime]);
	sleep 1;
	[side player, "HQ"] sideChat (format ["Clear %1 and prepare the defense", _locationName]);

	[west, format ["task_%1", _loc], [format ["Attack expected at %1", _arrivalTime], format ["Defend At %1", _locationName], ""], getPos _loc, "CREATED", 1, true, "defend", false] call BIS_fnc_taskCreate;

    // [_endTrg, _loc] spawn {
    // 	params ["_endTrg", "_loc"]; 
    // 	waitUntil {sleep 2; triggerActivated _endTrg};
    // 	[format ["task_%1", _loc], "FAILED", true] call BIS_fnc_taskSetState;
    // 	hint "Defeat : (";
	// };

	sleep 5;

	sleep (_timeOut * 0.5);

	0 = [_opforStart, _locPos, _opforStart] call dyn2_OPF_recon_patrol;

	sleep (_timeOut * 0.5);

	[side player, "HQ"] sideChat "Enemy assault force detected";

	for "_i" from 0 to _waves do {

        for "_j" from 0 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
            0 = [_opforStart, _locPos, selectRandom [true, false], _opforStart] call dyn2_OPF_catk;
        	sleep 2;
        };

        // if ((random 1) > 0.8) then {
       	// 	0 = [_opforStart, _locPos, _opforStart] call dyn2_OPF_armor_attack;
       	// };
        _artySuccess = [[3, 6] call BIS_fnc_randomInt, _locPos] spawn dyn2_OPF_fire_mission;

        // 10 - 15 min
        sleep ([700, 1000] call BIS_fnc_randomInt);

        [side player, "HQ"] sideChat "New enemy assault detected";

	};

	sleep ([600, 900] call BIS_fnc_randomInt);

	if !(triggerActivated _endTrg) then {
		[format ["task_%1", _loc], "SUCCEEDED", true] call BIS_fnc_taskSetState;
		hint "Victory : )";
	};
};
