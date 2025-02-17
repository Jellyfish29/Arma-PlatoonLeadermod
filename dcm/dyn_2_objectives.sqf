dyn2_SIDE_mission_spawner = {
	params ["_locPos", "_playerStart", "_objslimit", ["_blackList", []]];

	// Secondary

	// private _sideMissionTypes = ["road", "destroy_vic", "destroy_chache", "mortar", "hill", "position", "heli_crash", "allied_help", "civilian_help", "hvt", "attack_cp", "defend_cp", "_defend"];
	private _sideMissionTypes = ["road", "destroy_vic", "destroy_chache", "mortar", "hill", "position", "_defend"];
	private _sideMissionType = selectRandom _sideMissionTypes;
	private	_selectedMissionTypes = [];
	private _success = false;
	private _defDir = _locPos getDir _playerStart;


	_sideMissionTypes = _sideMissionTypes - _blackList;

	// [_locPos, _playerStart] call dyn2_SIDE_defend;

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
			default {}; 
		};

		if (_success) then {
			_sideMissionTypes deleteAt (_sideMissionTypes find _sideMissionType);
			_selectedMissionTypes pushBack _sideMissionType;
			_sideMissionCount = _sideMissionCount + 1;
		};
	};

	// [_locPos, _playerStart] call dyn2_SIDE_free_civilians;

	if !("hill" in _selectedMissionTypes) then {
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
    _playerStart = [[[_locPos, 2000]], [[_locPos, 1500], "water"]] call BIS_fnc_randomPos;
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

	_allGrps pushBack ([_locPos, _defDir] call dyn2_spawn_squad);

	// Random Infantry
	for "_i" from 1 to dyn2_strength + 1 do {
		_building = selectRandom _allBuildings;
		_allBuildings deleteAt (_allBuildings find _building);
		_allGrps pushBack ([getPos _building, _defDir] call dyn2_spawn_squad);
	};

	// Random Garrison
	for "_i" from 1 to dyn2_strength + 1 do {
		_building = selectRandom _validBuildings;
		_validBuildings deleteAt (_validBuildings find _building);
		_grp = [getPos _building, _defDir, dyn2_standart_fire_team] call dyn2_spawn_squad;
		_allGrps pushBack _grp;
		[_building, _grp, _defDir] call dyn2_garrison_building;
	};

	// Patroll
	for "_i" from 1 to dyn2_strength + 1 do {
		_allGrps pushBack ([[[[_locPos, 400]], [[_locPos, 50], "water"]] call BIS_fnc_randomPos] call dyn2_spawn_patroll);
	};

	// Random Road Vehicle
	for "_i" from 1 to dyn2_strength + 1 do {
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
	for "_i" from 1 to dyn2_strength + 1 do {
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
	for "_i" from 1 to dyn2_strength + 1 do {
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

	[_locPos, _playerStart, [1, 3] call BIS_fnc_randomInt] call dyn2_SIDE_mission_spawner;

	[getPos _startRoad, _locPos] spawn dyn2_place_player;

	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 1000];
	_civilTowns = _civilTowns - [_loc];

	{
	  	[_x, 10, 5, 2, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;
	[_loc, 25, 8, 6, 500] spawn dyn2_cvivilian_presence;

    [_locPos, _playerStart, _allBuildings] spawn pl_draw_scenario;



    _endTrg = createTrigger ["EmptyDetector", (getPos _loc), true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [600, 600, _defDir, false, 30];
    _endTrg setTriggerTimeout [240, 300, 400, false];

    _locationName = text _loc;

    [west, format ["task_%1", _loc], ["Offensive", format ["Capture %1", _locationName], ""], getPos _loc, "CREATED", 1, true, "attack", false] call BIS_fnc_taskCreate;

    [_endTrg, _loc] spawn {
    	params ["_endTrg", "_loc"]; 
    	waitUntil {sleep 2; triggerActivated _endTrg};
    	[format ["task_%1", _loc], "SUCCEEDED", true] call BIS_fnc_taskSetState;
	};
};

dyn2_small_town_assault = {
	params ["_loc"];

	private _locPos = getPos _loc;
	private _playerStart = [[[_locPos, 2300]], [[_locPos, 1600], "water"]] call BIS_fnc_randomPos;
	private _startRoad = [_playerStart, 1500] call BIS_fnc_nearestRoad;
	private _defDir = _locPos getDir _playerStart;

	private _allBuildings = nearestObjects [getPos _loc, ["house"], 400];
	private _allRoads = _locPos nearRoads 400;
	private _allGrps = [];

	// Random Infantry
	for "_i" from 1 to dyn2_strength + 1 do {
		_building = selectRandom _allBuildings;
		_allBuildings deleteAt (_allBuildings find _building);
		_allGrps pushBack ([getPos _building, _defDir] call dyn2_spawn_squad);
	};

	// Random Field Vehicle
    private _forwardPos = _locPos getPos [300, _defDir];
	for "_i" from 1 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
		_spawnPos = [[[_forwardPos, 500]], [ "water"]] call BIS_fnc_randomPos;
		_spawnPos = [_spawnPos, 1, 400, 1, 0, 2, 0] call BIS_fnc_findSafePos;
        _allGrps pushBack (([_spawnPos, _defDir, selectRandom dyn2_standart_combat_vehicles, selectRandom [true, false], true] call dyn2_spawn_covered_vehicle)#0);
	};

	// Random Road Vehicle
	for "_i" from 1 to dyn2_strength + 1 do {
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
	for "_i" from 1 to dyn2_strength + 1 do {
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


	[_locPos, _playerStart, [2, 4] call BIS_fnc_randomInt] call dyn2_SIDE_mission_spawner;
	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 1000];
	_civilTowns = _civilTowns - [_loc];

	{
	  	[_x, 12, 4, 2, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;

	[_loc, 10, 4, 1, 250] spawn dyn2_cvivilian_presence;

	[getPos _startRoad, _locPos] spawn dyn2_place_player;

	[_locPos, _playerStart, []] spawn pl_draw_scenario;

	_endTrg = createTrigger ["EmptyDetector", (getPos _loc), true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [600, 600, _defDir, false, 30];
    _endTrg setTriggerTimeout [240, 300, 400, false];

    _locationName = text _loc;

    [west, format ["task_%1", _loc], ["Offensive", format ["Capture %1", _locationName], ""], getPos _loc, "CREATED", 1, true, "attack", false] call BIS_fnc_taskCreate;

    [_endTrg, _loc] spawn {
    	params ["_endTrg", "_loc"]; 
    	waitUntil {sleep 2; triggerActivated _endTrg};
    	[format ["task_%1", _loc], "SUCCEEDED", true] call BIS_fnc_taskSetState;
	};
};


dyn2_field_assault = {

	private _locPos = [[[dyn2_map_center, worldSize / 2]], ["water"]] call BIS_fnc_randomPos;
	private _playerStart = [[[_locPos, 2300]], [[_locPos, 1800], "water"]] call BIS_fnc_randomPos;
	private _startRoad = [_playerStart, 800] call BIS_fnc_nearestRoad;
	private _defDir = _locPos getDir _playerStart;
	private _allRoads = _locPos nearRoads 1000;
	private _allGrps = [];

	[_locPos, _playerStart, [2, 4] call BIS_fnc_randomInt, ["_cp"]] call dyn2_SIDE_mission_spawner;
	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 1000];

	{
	  	[_x, 15, 5, 3, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;

	if ((random 1) > 0.5) then {
		_success = [_locPos, _playerStart, true] call dyn2_SIDE_destroy_position;
	} else {
		_success = [_locPos, _playerStart] call dyn2_SIDE_destroy_CP;
	};

	[getPos _startRoad, _locPos] spawn dyn2_place_player;

	[_locPos, _playerStart, []] spawn pl_draw_scenario;


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
	private _playerStart = [[[_locPos, 2300]], [[_locPos, 1600], "water"]] call BIS_fnc_randomPos;
	private _startRoad = [_playerStart, 1500] call BIS_fnc_nearestRoad;
	private _defDir = _locPos getDir _playerStart;

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
		if (_i == 0) then {_allGrps pushBack ([_planePos, _defDir] call dyn2_spawn_squad)};
	};

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


	// Sidemission
	[_locPos, _playerStart, [1, 3] call BIS_fnc_randomInt, ["destroy_vic"]] call dyn2_SIDE_mission_spawner;

	// Ambiance
	_civilTowns = nearestLocations [_locPos getpos [500, _defDir], ["NameCity", "NameVillage", "NameCityCapital"], 1000];

	{
	  	[_x, 15, 5, 3, 350] spawn dyn2_cvivilian_presence;
	} forEach _civilTowns;

	[getPos _startRoad, _locPos] spawn dyn2_place_player;

	[_locPos, 600, format ["%1 Air Assault", toUpper dyn2_opfor_fation]] call dyn2_draw_mil_symbol_objectiv_free;

	_arrowMarker = createMarker [str (random 5), _locPos getPos [1500, _defDir]];
    _arrowMarker setMarkerType "marker_std_atk";
    _arrowMarker setMarkerSize [1, 1];
    _arrowMarker setMarkerColor dyn2_side_color;
    _arrowMarker setMarkerDir (_defDir - 180);
    // _arrowMarker setMarkerText (format ["%1 Incursion", toUpper dyn2_opfor_fation]);

    _natoMarker = createMarker [str (random 5), _locPos getPos [3000, _defDir]];
    _natoMarker setMarkerType "flag_NATO";
    _natoMarker setMarkerSize [1.3, 1.3];


	_endTrg = createTrigger ["EmptyDetector", _locPos, true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [600, 600, _defDir, false, 30];
    _endTrg setTriggerTimeout [240, 300, 400, false];

    [west, format ["task_%1", _locPos], ["Offensive", format ["Retake %1", "Air Field"], ""], _locPos getPos [100, _defDir - 180], "CREATED", 1, true, "attack", false] call BIS_fnc_taskCreate;

    [_endTrg, _locPos] spawn {
    	params ["_endTrg", "_locPos"]; 
    	waitUntil {sleep 2; triggerActivated _endTrg};
    	[format ["task_%1", _locPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;
	};

	[west, format ["task_%1", _allPlanes], ["Offensive", format ["Destroy Enemy %1", "Aircraft"], ""], getPos (_allPlanes#1), "CREATED", 1, true, "destroy", false] call BIS_fnc_taskCreate;

    [_allPlanes, _locPos] spawn {
    	params ["_allPlanes", "_objCenter"];

    	waitUntil {sleep 2; {alive _x} count _allPlanes <= 0};

    	[format ["task_%1", _allPlanes], "SUCCEEDED", true] call BIS_fnc_taskSetState;

	};

};
