dyn2_allied_help_active = false;
dyn2_SIDE_obj_pos = [];

dyn2_SIDE_clear_road = {
	params ["_objCenter", "_playerStart"];

	private _allGrps = [];
	private _radius = [500, 1000] call BIS_fnc_randomInt;
	private _lastPos = [0,0,0];
    private _cpPositions = [];
    // for "_i" from 0 to 359 do {

    //     _checkPos = _objCenter getpos [_radius, _i];
    //     if (isOnRoad _checkPos and ((_checkPos distance2D _lastPos) > 50)) then {

    //     	_road = roadAt _checkPos;
    //         _info = getRoadInfo _road;

    //         if ((_info#0) in ["ROAD", "MAIN ROAD"]) then { 
    //             _lastPos = _checkPos;
    //             _cpPositions pushback [_road, _checkPos getPos [100, _i]];
    //         };
    //     };
    // }; 

    if (count _cpPositions <= 0) then {
    	private _lastPos = [0,0,0];
	    private _cpPositions = [];
	    for "_i" from 0 to 359 do {

	        _checkPos = _objCenter getpos [_radius, _i];
	        if (isOnRoad _checkPos and ((_checkPos distance2D _lastPos) > 50)) then {

	            _road = roadAt _checkPos;
	            _lastPos = _checkPos;
	            _cpPositions pushback [_road, _checkPos getPos [100, _i]];
	        };
	    }; 
    };

    if (count _cpPositions <= 0) exitWith {false};

    _cpPositions = [_cpPositions, [], {(getpos (_x#0)) distance2D _playerStart}, "ASCEND"] call BIS_fnc_sortBy;

    // {
 	//     _m = createMarker [str (random 5), getPos (_x#0)];
    //     _m setMarkerType "mil_dot";
    //     _m setMarkerSize [0.5, 0.5];
    // } forEach _cpPositions;

    private _road = (_cpPositions#0)#0;
    private _info = getRoadInfo _road;    
    private _endings = [_info#6, _info#7];
	_endings = [_endings, [], {_x distance2D _playerStart}, "ASCEND"] call BIS_fnc_sortBy;
    private _roadDir = (_endings#1) getDir (_endings#0);
    private _roadWidth = _info#1;
    private _rPos = ASLToATL (_endings#0);

    dyn2_SIDE_obj_pos pushback _rPos;

    _allGrps pushBack ([_road, _playerStart, dyn2_standart_squad] call dyn2_spawn_road_block);

    if ((random 1) > 0.5) then {
        _allGrps pushBack (([(getPos _road) getPos [4, _roadDir - 180], _roadDir] call dyn2_spawn_vehicle)#0);
    };
    _mines = [(getPos _road) getPos [20, _roadDir], 20, _roadDir, 2, 2] call dyn2_spawn_mines;

    private _patrollRoute = [];
    for "_i" from 0 to 359 step 45 do {
    	_patrollRoute pushback ((getPos _road) getpos [[100, 200] call BIS_fnc_randomInt, _i]);
    };

    for "_i" from 1 to dyn2_strength + ([1, 2] call BIS_fnc_randomInt) do {
    	_allGrps pushBack ([selectRandom _patrollRoute, _patrollRoute] call dyn2_spawn_patroll);
    };

    [west, format ["task_%1", _road], ["Offensive", "Clear Road", ""], getPos _road, "CREATED", 1, true, "mine", false] call BIS_fnc_taskCreate;

    [_allGrps, _road, _mines, _objCenter] spawn {
    	params ["_allGrps", "_road", "_mines", "_objCenter"];
    	waitUntil {sleep 2; ({mineActive _x} count _mines) == 0};
    	[format ["task_%1", _road], "SUCCEEDED", true] call BIS_fnc_taskSetState;
        pl_sorties = pl_sorties + 4;
        pl_arty_ammo = pl_arty_ammo + 6;

        if ((random 1) > 0.25) then {
            [_objCenter, getpos _road] call dyn2_opfor_mission_spawner;
        };
	};

	true
};

dyn2_SIDE_destroy_vehicle = {
	params ["_objCenter", "_playerStart"];

	private _allGrps = [];
	_forwardPos = _objCenter getpos [400, _objCenter getDir _playerStart]; 
	_vicType = selectRandom [dyn2_standart_aa, dyn2_standart_arty, dyn2_standart_MBT];
	_spawnPos = [[[_objCenter, 600]], [[_objCenter, 200], "water"]] call BIS_fnc_randomPos;
	_spawnPos = [_spawnPos, 1, 500, 2, 0, 4, 0] call BIS_fnc_findSafePos;

    dyn2_SIDE_obj_pos pushback _spawnPos;

	if (_spawnPos isEqualTo []) exitWith {false};

	_targetVic = createVehicle [_vicType, _spawnPos, [], 0, "NONE"];

    if ((random 1) > 0.5 and (_vicType == dyn2_standart_aa or _vicType == dyn2_standart_MBT)) then {
        _allGrps pushBack (createVehicleCrew _targetVic);
    };

    if (_vicType == dyn2_standart_MBT) then {
        _targetVic setDir (_objCenter getDir _playerStart);
    };

    _net = createVehicle ["CamoNet_OPFOR_F", (getPosATL _targetVic) getpos [10, (getdir _targetVic) - 180], [], 0, "CAN_COLLIDE"];
    _net setVectorUp surfaceNormal position _net;
    _net setDir ((getDir _targetVic) - 180);

	_allGrps pushBack ([_spawnPos getPos [25, getdir _targetVic], getDir _targetVic] call dyn2_spawn_squad);

	private _patrollRoute = [];
    for "_i" from 0 to 359 step 45 do {
    	_patrollRoute pushback ((getPos _targetVic) getpos [[100, 200] call BIS_fnc_randomInt, _i]);
    };

    for "_i" from 1 to dyn2_strength + ([0, 1] call BIS_fnc_randomInt) do {
    	_allGrps pushBack ([selectRandom _patrollRoute, _patrollRoute] call dyn2_spawn_patroll);
    };

    if ((random 1) > 0.5) then {
        _allGrps pushBack (([[[[_spawnPos, 100]], [[_spawnPos, 50], "water"]] call BIS_fnc_randomPos, _objCenter getDir _playerStart] call dyn2_spawn_vehicle)#0);
    };

    private _text = "";
    switch (_vicType) do { 
        case dyn2_standart_aa : {_text = "Air Denfense"}; 
        case dyn2_standart_arty : {_text = "Artillery"};
        case dyn2_standart_MBT : {_text = "MBT"}; 
        default {_text = ""}; 
    };


    [west, format ["task_%1", _targetVic], ["Offensive", format ["Destroy Enemy %1", _text], ""], getPos _targetVic, "CREATED", 1, true, "destroy", false] call BIS_fnc_taskCreate;

    [_targetVic, _objCenter] spawn {
    	params ["_targetVic", "_objCenter"];

    	waitUntil {sleep 2; !alive _targetVic};

    	[format ["task_%1", _targetVic], "SUCCEEDED", true] call BIS_fnc_taskSetState;

        pl_sorties = pl_sorties + 6;
        pl_arty_ammo = pl_arty_ammo + 6;

        if ((random 1) > 0.25) then {
            [_objCenter, getpos _targetVic] call dyn2_opfor_mission_spawner;
        };
	};

    true
};

dyn2_SIDE_destroy_position = {
	params ["_objCenter", "_playerStart", ["_excactPos", false]];

    private _defDir = _objCenter getDir _playerStart;
    private _forwardPos = _objCenter getpos [700, _defDir];
    private _posPos = [[[_forwardPos, 400]], ["water"]] call BIS_fnc_randomPos;
    // _posPos = [_posPos, 1, 300, 2, 0, 2, 0] call BIS_fnc_findSafePos;
    _posPos = [_posPos, 400, _defDir] call dyn2_find_highest_point;
    private _allGrps = [];

    if (_excactPos) then {
        _posPos = _objCenter;
    };

    dyn2_SIDE_obj_pos pushback _posPos;

    _allGrps pushBack ([_posPos, _defDir] call dyn2_spawn_squad);

    if ((random 1) > 0.3) then {
        _allGrps pushBack ([_posPos getPos [[50, 100] call BIS_fnc_randomInt, _defDir +  (selectRandom [90, -90])], _defDir] call dyn2_spawn_squad);
    };

    _allGrps pushBack (([_posPos getPos [[10, 60] call BIS_fnc_randomInt, _defDir + 45 - 180 ], _defDir, selectRandom dyn2_standart_combat_vehicles, true, false] call dyn2_spawn_covered_vehicle)#0);

    if ((random 1) > 0.5) then {
        _allGrps pushBack (([_posPos getPos [[10, 60] call BIS_fnc_randomInt, _defDir - 45 - 180 ], _defDir, selectRandom dyn2_standart_combat_vehicles, true, false] call dyn2_spawn_covered_vehicle)#0);
    };

    private _patrollRoute = [];
    for "_i" from 0 to 359 step 45 do {
        _patrollRoute pushback ((_posPos getPos [200, _defDir - 180]) getpos [[100, 200] call BIS_fnc_randomInt, _i]);
    };

    for "_i" from 1 to ([1, 2] call BIS_fnc_randomInt) do {
        _allGrps pushBack ([selectRandom _patrollRoute, _patrollRoute] call dyn2_spawn_patroll);
    };

    [west, format ["task_%1", _posPos], ["Offensive", "Seize Position", ""], _posPos, "CREATED", 1, true, "attack", false] call BIS_fnc_taskCreate;

    _endTrg = createTrigger ["EmptyDetector", _posPos, true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [200, 200, _defDir, false, 30];
    _endTrg setTriggerTimeout [0, 5, 10, false];

    [_posPos, _endTrg, _objCenter] spawn {
        params ["_posPos", "_endTrg", "_objCenter"];

        waitUntil {sleep 2; triggerActivated _endTrg};

        [format ["task_%1", _posPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;

        pl_sorties = pl_sorties + 4;
        pl_arty_ammo = pl_arty_ammo + 6;

        if ((random 1) > 0.25) then {
            [_objCenter, _posPos] call dyn2_opfor_mission_spawner;
        };
    };

    true
};

dyn2_SIDE_capture_hill = {
	params ["_objCenter", "_playerStart"];

    private _defDir = _objCenter getDir _playerStart;
    private _hillPos = [_objCenter getpos [700, _defDir], 1500, _defDir] call dyn2_find_highest_point;
    private _allGrps = [];

    dyn2_SIDE_obj_pos pushback _hillPos;

    // _spawnPos = [_hillPos, 1, 150, 1, 0, 10, 0] call BIS_fnc_findSafePos;

    // [_spawnPos, _defDir, dyn2_small_OP, 0] call BIS_fnc_objectsMapper;

    private _grp = [_hillPos, _defDir] call dyn2_spawn_squad;

    if ((random 1) > 0.5) then {
        (units ([_hillPos, _defDir, dyn2_standart_at_team] call dyn2_spawn_squad)) joinSilent _grp;
    };

    if ((random 1) > 0.5) then {
        (units ([_hillPos, _defDir, dyn2_standart_fire_team] call dyn2_spawn_squad)) joinSilent _grp;
    };

    // if ((random 1) > 0.5) then {
    //     _allGrps pushBack (([_hillPos, _defDir, selectRandom dyn2_standart_light_armed_transport, true, false] call dyn2_spawn_covered_vehicle)#0);
    // };


    _allGrps pushBack _grp;

    for "_i" from 1 to ([1, 2] call BIS_fnc_randomInt) do {
        _allGrps pushBack ([[[[_hillPos, 400]], [[_hillPos, 50], "water"]] call BIS_fnc_randomPos] call dyn2_spawn_patroll);
    };

    [west, format ["task_%1", _hillPos], ["Offensive", "Seize OP", ""], _hillPos, "CREATED", 1, true, "attack", false] call BIS_fnc_taskCreate;

    _endTrg = createTrigger ["EmptyDetector", _hillPos, true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [100, 100, _defDir, false, 30];
    _endTrg setTriggerTimeout [0, 5, 10, false];

    [_hillPos, _endTrg, _objCenter] spawn {
        params ["_hillPos", "_endTrg", "_objCenter"];

        waitUntil {sleep 2; triggerActivated _endTrg};

        [format ["task_%1", _hillPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;

        pl_sorties = pl_sorties + 4;
        pl_arty_ammo = pl_arty_ammo + 6;

        if ((random 1) > 0.25) then {
            [_objCenter, _hillPos] call dyn2_opfor_mission_spawner;
        };


    };

    true

};


dyn2_SIDE_destroy_chache = {
	params ["_objCenter", "_playerStart"];

    private _allBuildings = nearestObjects [_objCenter, ["house"], 600];

    private _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 8 and !(isHidden _x)) then {
            _validBuildings pushBack _x;
        };
    } forEach _allBuildings;

    if (_validBuildings isEqualTo []) exitWith {false};

    _targetBuilding = selectRandom _validBuildings;
    _buildingPos = [_targetBuilding] call BIS_fnc_buildingPositions;
    private _allCrates = [];
    private _allRoads = (getPos _targetBuilding) nearRoads 100;

    for "_i" from 0 to 2 do {
        _cPos = selectRandom _buildingPos;
        _buildingPos deleteAt (_buildingPos find _cPos);

        _allCrates pushback (createVehicle ["O_supplyCrate_F", _cPos, [], 0, "CAN_COLLIDE"]);
    };

    // Random Road Vehicle
    for "_i" from 1 to 2 do {
        _road = selectRandom _allRoads;
        _road = ([_allRoads, [], {(getpos _x) distance2D (getPos _targetBuilding)}, "ASCEND"] call BIS_fnc_sortBy)#0;
        if !(isNil "_road") then {
            _allRoads deleteAt (_allRoads find _road);
            _info = getRoadInfo _road;    
            _roadWidth = _info#1;
            _endings = [_info#6, _info#7];
            _roadDir = (_endings#1) getDir (_endings#0);
            _allRoads deleteAt (_allRoads find _road);
            
            _vic = ([getPos _road, _roadDir, selectRandom dyn2_standart_trasnport_vehicles, false] call dyn2_spawn_vehicle)#1;
            _allCrates pushback _vic;
        };
    };

    dyn2_SIDE_obj_pos pushback (getPos _targetBuilding);

    _grp = [getPos _targetBuilding, random 360] call dyn2_spawn_squad;

    [west, format ["task_%1", _targetBuilding], ["Offensive", "Destroy Supply Dump", ""], getPos _targetBuilding, "CREATED", 1, true, "destroy", false] call BIS_fnc_taskCreate;

    [_allCrates, _targetBuilding, _objCenter] spawn {
        params ["_allCrates", "_targetBuilding", "_objCenter"];

        waitUntil {sleep 2; (getDammage _targetBuilding) >= 0.9 or ({!isNUll _x or (getDammage _x) >= 1} count _allCrates) <= 0};

        [format ["task_%1", _targetBuilding], "SUCCEEDED", true] call BIS_fnc_taskSetState;

        pl_sorties = pl_sorties + 4;
        pl_arty_ammo = pl_arty_ammo + 6;

        if ((random 1) > 0.6) then {
            [_objCenter, getpos _targetBuilding] call dyn2_opfor_mission_spawner;
        };
    };

    true
};


dyn2_defend_posistion = {
    params ["_objCenter", "_playerStart"];

    dyn2_allied_help_active = true;
    true
};


dyn2_opfor_arty = [];

dyn2_SIDE_destroy_mortar = {
    params ["_objCenter", "_playerStart"];

    private _defDir = _objCenter getDir _playerStart;
    _rearPos = _objCenter getpos [400, _defDir - 180]; 
    private _spawnPos = [[[_rearPos, 500]], [[_objCenter, 200], "water"]] call BIS_fnc_randomPos;
    _spawnPos = [_spawnPos, 1, 500, 2, 0, 4, 0] call BIS_fnc_findSafePos;
    private _allGrps = [];

    dyn2_SIDE_obj_pos pushback _spawnPos;

    _allGrps pushBack ([_spawnPos getPos [25, _defDir], _defDir] call dyn2_spawn_squad);
    if ((random 1) > 0) then {
        _allGrps pushBack ([_spawnPos getPos [[60, 150] call BIS_fnc_randomInt, _defDir- 180], _defDir] call dyn2_spawn_squad);
    };
    if ((random 1) > 0) then {
        _allGrps pushBack (([_spawnPos getPos [[60, 150] call BIS_fnc_randomInt, _defDir + (selectRandom [90, -90])], _defDir] call dyn2_spawn_covered_vehicle)#0);
    };

    private _allArty = [];
    _lightArtyGrp = createGroup [dyn2_opfor_side, true];
    for "_i" from 0 to 1 do {
        _offsetDir = 90;
        if (_i == 1) then {_offsetDir = 70};
        _aPos = _spawnPos getPos [10 * _i, _defDir - _offsetDir];
        _arty = createVehicle [dyn2_standart_light_arty, _aPos, [], 0, "NONE"];
        _arty setdir _defDir;
        _grp = createVehicleCrew _arty;
        _grp setVariable ["pl_not_recon_able", true];
        (units _grp) joinSilent _lightArtyGrp;
        dyn2_opfor_arty pushBack _arty;
        _allArty pushback _arty;
        // dyn_opfor_grps pushBack _grp;

        // _sPos = (getPos _arty) getPos [1, _dir];
        // _sandBag = createVehicle ["land_gm_sandbags_01_round_01", _sPos, [], 0, "CAN_COLLIDE"];
        // _sandBag setDir (getDir _arty);
    };
    _allGrps pushBack _lightArtyGrp;

    [] spawn {

        sleep ([300, 800] call BIS_fnc_randomInt);

        _artySuccess = [[2, 6] call BIS_fnc_randomInt] spawn dyn2_OPF_fire_mission;

    };

    [west, format ["task_%1", _spawnPos], ["Offensive", "Destroy Enemy Mortar", ""], _spawnPos, "CREATED", 1, true, "destroy", false] call BIS_fnc_taskCreate;

    [_spawnPos, _objCenter, _allArty] spawn {
        params ["_spawnPos", "_objCenter", "_allArty"];

        waitUntil {sleep 1; ({(crew _x) isEqualTo []} count _allArty) == (count _allArty)};

        [format ["task_%1", _spawnPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;

        pl_sorties = pl_sorties + 6;
        pl_arty_ammo = pl_arty_ammo + 6;

        if ((random 1) > 0.25) then {
            [_objCenter, _spawnPos] call dyn2_opfor_mission_spawner;
        };
    };

    true
};



dyn2_SIDE_defend = {
    params ["_objCenter", "_playerStart"];

    if (dyn2_allied_help_active) exitwith {false};

    private _objDistance = _objCenter distance2D _playerStart;
    private _defDir = _objCenter getDir _playerStart;
    private _forwardPos = _objCenter getpos [_objDistance * 0.95, _defDir + ([-5, 5] call BIS_fnc_randomInt)];
    // private _cpPos = [[[_forwardPos, 500]], [[_playerStart, 250], "water"]] call BIS_fnc_randomPos;
    _cpPos = [_forwardPos, 1, 350, 10, 0, 0, 0, [], _forwardPos] call BIS_fnc_findSafePos;

    if (_cpPos isEqualTo _forwardPos) exitWith {false};

    [west, format ["task_%1", _cpPos], ["Offensive", "Defend Position", ""], _cpPos, "CREATED", 1, true, "defend", false] call BIS_fnc_taskCreate;

    [_objCenter, _cpPos] call dyn2_OPF_catk;
    [_objCenter, _cpPos] call dyn2_OPF_catk;

    _trg = createTrigger ["EmptyDetector", _cpPos, true];
    _trg setTriggerActivation ["EAST", "PRESENT", false];
    _trg setTriggerStatements ["this", " ", " "];
    _trg setTriggerArea [600, 600, _defDir, false, 30];
    _trg setTriggerTimeout [0, 5, 10, false];

    _areaMarker = createMarker [str (random 5), _cpPos];
    _areaMarker setMarkerShape "ELLIPSE";
    _areaMarker setMarkerBrush "FDiagonal";
    _areaMarker setMarkerColor "colorBLUFOR";
    _areaMarker setMarkerAlpha 0.4;
    _areaMarker setMarkerSize [700, 700];

    [_cpPos, _objCenter, _trg, _areaMarker] spawn {
        params ["_cpPos", "_objCenter", "_trg", "_areaMarker"];

        waitUntil {sleep 2; triggerActivated _trg};

        [_objCenter, _cpPos] call dyn2_OPF_catk;
        _artySuccess = [[6, 12] call BIS_fnc_randomInt, _missionPos] spawn dyn2_OPF_fire_mission;
        // [_objCenter, _cpPos] call dyn2_opfor_mission_spawner;

        _time = time + 500;

        _trg2 = createTrigger ["EmptyDetector", _cpPos, true];
        _trg2 setTriggerActivation ["EAST", "NOT PRESENT", false];
        _trg2 setTriggerStatements ["this", " ", " "];
        _trg2 setTriggerArea [700, 700, 0, false, 30];
        _trg2 setTriggerTimeout [0, 5, 10, false];

        waitUntil {sleep 2; triggerActivated _trg2};

        [format ["task_%1", _cpPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;

        pl_sorties = pl_sorties + 6;


        deletemarker _areaMarker;
    };

    dyn2_allied_help_active = true;
    true
};

dyn2_SIDE_secure_war_crime_evidence = {
    params ["_objCenter", "_playerStart"];
};

dyn2_SIDE_ambush_convoy = {
    params ["_objCenter", "_playerStart"];
};

