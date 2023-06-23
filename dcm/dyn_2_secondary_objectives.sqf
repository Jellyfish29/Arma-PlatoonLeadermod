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

dyn2_SIDE_secure_crash_site = {
    params ["_objCenter", "_playerStart"];

    if (dyn2_allied_help_active) exitwith {false};

    private _objDistance = _objCenter distance2D _playerStart;
    private _defDir = _objCenter getDir _playerStart;
    private _forwardPos = _objCenter getpos [_objDistance * 0.65, _defDir + ([-25, 25] call BIS_fnc_randomInt)];
    private _crashPos = [[[_forwardPos, 500]], [[_playerStart, 450], "water"]] call BIS_fnc_randomPos;
    _crashPos = [_crashPos, 1, 300, 2, 0, 20, 0, [], _crashPos] call BIS_fnc_findSafePos;
    private _allGrps = [];

    dyn2_SIDE_obj_pos pushback _crashPos;

    waitUntil {sleep 0.1; !(isNil "pl_cas_Heli_1")};

    _heli = createVehicle [pl_cas_Heli_1, _crashPos, [], 0, "CAN_COLLIDE"];
    _crewGrp = createVehicleCrew _heli;
    _crewGrp setCombatMode "BLUE";
    {
        _x allowDamage false;
        moveOut _x;
        _x setUnconscious true;
        _x disableAI "AUTOCOMBAT";
        _x disableAI "TARGET";
        _x disableAI "AUTOTARGET";
        _x setPos ([[[getpos _heli, 10]], [[getpos _heli, 5], "water"]] call BIS_fnc_randomPos);
    } forEach (crew _heli);
    _heli setDamage [1, false];
    private _smokeGroup = createGroup [civilian, true];
    private _smoke = _smokeGroup createUnit ["ModuleEffectsSmoke_F", getPosATLVisual _heli, [],0 , ""];

    [_crewGrp] spawn {
        params ["_crewGrp"];
        _crewGrp setVariable ["aiSetUp", true];

        sleep 20;
        waitUntil {sleep 0.5; !(isNil "pl_hide_group_icon")};

        [_crewGrp] call pl_hide_group_icon;

        {
            _x setVariable ["pl_wia", true];
            _x allowDamage true;
            _x disableAI "PATH";
            [_x] spawn {
                params ["_unit"];

                waitUntil {sleep 1; !alive _unit or !((lifeState _unit) isEqualTo "INCAPACITATED")};

                sleep 1;

                waitUntil {sleep 1; !alive _unit or pl_medevac_Heli_1 in (((getPos _unit) nearObjects ["Air", 100]) apply {typeof _x})};

                if (alive _unit) then {
                    _joinTargets = (getPos _unit) nearObjects ["Air", 100];

                    _unit enableAI "PATH";

                    {
                        if ((typeOf _x) isEqualTo pl_medevac_Heli_1) exitWith {
                            [_unit] joinSilent (group (driver _x));
                            _unit assignAsCargo _x;
                            [_unit] allowGetIn true;
                            [_unit] orderGetIn true;
                        };
                    } forEach _joinTargets;
                };
            };
        } forEach (units _crewGrp);
    }; 


    for "_i" from 1 to ([2, 4] call BIS_fnc_randomInt) do {
        0 = [[[[_crashPos, 700]], [[_crashPos, 450], "water"]] call BIS_fnc_randomPos] call dyn2_spawn_patroll;
    };

    // [_objCenter, _crashPos] call dyn2_OPF_recon_patrol;

    [west, format ["task_%1", _crashPos], ["Offensive", "Secure Crashsite", ""], _crashPos, "CREATED", 1, true, "defend", false] call BIS_fnc_taskCreate;

    _trg = createTrigger ["EmptyDetector", _crashPos, true];
    _trg setTriggerActivation ["ANYPLAYER", "PRESENT", false];
    _trg setTriggerStatements ["this", " ", " "];
    _trg setTriggerArea [100, 100, _crashPos getdir _objCenter, false, 30];

    [_crewGrp, _crashPos, units _crewGrp, _objCenter, _trg] spawn {
        params ["_crewGrp", "_crashPos", "_units", "_objCenter", "_trg"];

        waitUntil {sleep 2; triggerActivated _trg};

        [_objCenter, _crashPos] call dyn2_opfor_mission_spawner;

        sleep 1;

        [format ["task_%1", _crashPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;

        sleep 1;

        [west, format ["task2_%1", _crashPos], ["Offensive", "Evac Crew", ""], _crashPos, "ASSIGNED", 1, true, "heli", false] call BIS_fnc_taskCreate;

        {
            _x reveal [leader _alliedGrp, 4];
        } forEach (allUnits select {(_x distance2D _crashPos) < 800 and side _x != playerSide});

        waitUntil {sleep 2; {alive _x} count _units == 0 or {_x distance2D _crashPos > 600} count _units == count _units};

        if ({alive _x} count _units > 0) then {
            [format ["task2_%1", _crashPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;
            pl_sorties = pl_sorties + 10;
            pl_arty_ammo = pl_arty_ammo + 10;

            if ((random 1) > 0.6) then {
                [_objCenter, _crashPos] call dyn2_opfor_mission_spawner;
            };
        } else {
            [format ["task2_%1", _crashPos], "FAILED", true] call BIS_fnc_taskSetState;

            [_objCenter, _crashPos] call dyn2_opfor_mission_spawner;
        };
    };

    

    // _m = createMarker [str (random 1), _crashPos];
    // _m setMarkerType "mil_marker";
    // _m setMarkerColor "colorBLUFOR";

    dyn2_allied_help_active = true;
    true
};

dyn2_help_allies_qrf = {
    params ["_objCenter", "_playerStart"];

    if (dyn2_allied_help_active) exitwith {false};

    private _objDistance = _objCenter distance2D _playerStart;
    private _defDir = _objCenter getDir _playerStart;
    private _forwardPos = _objCenter getpos [_objDistance * 0.7, _defDir + ([-15, 15] call BIS_fnc_randomInt)];
    private _qrfPos = [[[_forwardPos, 500]], [[_playerStart, 550], "water"]] call BIS_fnc_randomPos;
    // _qrfPos = [_qrfPos, 1, 200, 0, 0, 20, 0, [], _qrfPos] call BIS_fnc_findSafePos;

    dyn2_SIDE_obj_pos pushback _qrfPos;

    _wreck = createVehicle [typeof (selectRandom (vehicles select {side _x == playerSide})), _qrfPos, [], 0, "NONE"];
    _wreck setDamage [1, false];
    _wreck setDir ([0, 360] call BIS_fnc_randomInt);
    private _smokeGroup = createGroup [civilian, true];
    private _smoke = _smokeGroup createUnit ["ModuleEffectsSmoke_F", getPosATLVisual _wreck, [],0 , "CAN_COLLIDE"];
    // [_smoke, _wreck] spawn {
    //     params ["_smoke", "_wreck"];
    //     sleep 6;
    //     _smoke setPosATL getPosATLVisual _wreck;
    // };

    _alliedGrp = createGroup [playerSide, true];


    private _wiaLimit = 0;
    private _unitCount = 0;
    {
        if (_unitCount == 6) exitWith {};
        _unit = _alliedGrp createUnit [typeof _x, _qrfPos, [], 10, "NONE"];
        _cover = [getPos _unit, _qrfPos getdir _objCenter, 60] call dyn2_get_cover_pos;
        _unit setPos (_cover#0);
        _unit setUnitPos (_cover#1);
        _unit setDir (_qrfPos getdir _objCenter);
        _unit setVariable ["pl_damage_reduction", true];
        doStop _unit;
        _unit disableAI "PATH";
        if (_wiaLimit < 2 and (random 1) > 0.75) then {
            _unit setUnconscious true;
            _unit setVariable ["pl_wia", true];
            _wiaLimit = _wiaLimit + 1;
        };
        _unitCount = _unitCount + 1;
        [_unit] spawn {
            params ["_unit"];

            waitUntil {sleep 1; !alive _unit or !((lifeState _unit) isEqualTo "INCAPACITATED")};

            sleep 1;

            waitUntil {sleep 1; !alive _unit or pl_medevac_Heli_1 in (((getPos _unit) nearObjects ["Air", 300]) apply {typeof _x})};

            if (alive _unit) then {
                _joinTargets = (getPos _unit) nearObjects ["Air", 300];

                _unit enableAI "PATH";

                {
                    if ((typeOf _x) isEqualTo pl_medevac_Heli_1) exitWith {
                        [_unit] joinSilent (group (driver _x));
                        _unit assignAsCargo _x;
                        [_unit] allowGetIn true;
                        [_unit] orderGetIn true;
                    };
                } forEach _joinTargets;
            };
        };
    } forEach (units (selectRandom (allGroups select {side _x == playerSide and (count (units _x) >= 6)})));

    _alliedGrp setVariable ["pl_not_addalbe", true];
    _alliedGrp setVariable ["aiSetUp", true];
    player hcRemoveGroup _alliedGrp;

    for "_i" from dyn2_strength to ([dyn2_strength, dyn2_strength + 1] call BIS_fnc_randomInt) do {
        0 = [[[[_qrfPos getpos [500, _qrfPos getdir _objCenter], 400]], [[_qrfPos, 350], "water"]] call BIS_fnc_randomPos] call dyn2_spawn_patroll;
    };

    [_objCenter, _qrfPos] call dyn2_OPF_catk;

    [west, format ["task_%1", _qrfPos], ["Offensive", "Help Allied Squad", ""], _qrfPos, "CREATED", 1, true, "defend", false] call BIS_fnc_taskCreate;

    _trg = createTrigger ["EmptyDetector", _qrfPos, true];
    _trg setTriggerActivation ["ANYPLAYER", "PRESENT", false];
    _trg setTriggerStatements ["this", " ", " "];
    _trg setTriggerArea [100, 100, _qrfPos getdir _objCenter, false, 30];

    [_objCenter, _qrfPos, _unitCount, _alliedGrp, _trg] spawn {
        params ["_objCenter", "_qrfPos", "_unitCount", "_alliedGrp", "_trg"];

        private _units = units _alliedGrp;

        waitUntil {sleep 2; triggerActivated _trg};

        [_objCenter, _qrfPos] call dyn2_opfor_mission_spawner;

        sleep 1;

        [format ["task_%1", _qrfPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;

        sleep 1;

        [west, format ["task2_%1", _qrfPos], ["Offensive", "Evac Crew", ""], _qrfPos, "ASSIGNED", 1, true, "heli", false] call BIS_fnc_taskCreate;

        {
            _x reveal [leader _alliedGrp, 4];
        } forEach (allUnits select {(_x distance2D _qrfPos) < 800 and side _x != playerSide});

        waitUntil {sleep 2; {alive _x} count _units == 0 or {_x distance2D _qrfPos > 600} count _units == count _units};

        if ({alive _x} count _units > 0) then {
            [format ["task2_%1", _qrfPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;
            pl_sorties = pl_sorties + 10;
            pl_arty_ammo = pl_arty_ammo + 10;

            if ((random 1) > 0.6) then {
                [_objCenter, _qrfPos] call dyn2_opfor_mission_spawner;
            };
        } else {
            [format ["task2_%1", _qrfPos], "FAILED", true] call BIS_fnc_taskSetState;

            [_objCenter, _qrfPos] call dyn2_opfor_mission_spawner;
        };



    };

    dyn2_allied_help_active = true;
    true
};

dyn2_defend_posistion = {
    params ["_objCenter", "_playerStart"];

    dyn2_allied_help_active = true;
    true
};

dyn2_SIDE_free_civilians = {
    params ["_objCenter", "_playerStart"];

    private _defDir = _objCenter getDir _playerStart;
    private _allBuildings = nearestObjects [_objCenter, ["house"], 250];
    private _allGrps = [];
    private _validBuildings = [];

    // Valid Buildings
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 4 and !(isHidden _x)) then {
            _validBuildings pushBack _x;
        };
    } forEach _allBuildings;

    if (_validBuildings isEqualTo []) exitWith {false};

    _ngoBuilding = selectRandom _validBuildings;

    dyn2_SIDE_obj_pos pushback (getPos _ngoBuilding);

    _ngoGrp = createGroup civilian;

    for "_i" from 1 to ([3, 4] call BIS_fnc_randomInt) do {
        0 = _ngoGrp createUnit [selectRandom dyn2_NGO_civilians, getPos _ngoBuilding, [], 10, "NONE"];
    };

    [_ngoBuilding, _ngoGrp, _defDir - 180 , true] call dyn2_garrison_building;

    _grp = [getPos _ngoBuilding, 0, dyn2_standart_fire_team] call dyn2_spawn_squad;

    // [_ngoBuilding, _grp, _defDir] call dyn2_garrison_building;
    // _allGrps pushBack _grp;

    // _allGrps pushBack ([getPos _ngoBuilding, _defDir] call dyn2_spawn_squad);


    _sign = createVehicle ["SignAd_Sponsor_01_IDAP_F", (getPos _ngoBuilding) findEmptyPosition [2, 50, "SignAd_Sponsor_01_IDAP_F"], [], 2, "CAN_COLLIDE"];
    _sign setdir (getDir _ngoBuilding);
    _box1 = createVehicle ["Land_PaperBox_01_open_boxes_F", (getPos _ngoBuilding) findEmptyPosition [2, 50, "SignAd_Sponsor_01_IDAP_F"], [], 2, "CAN_COLLIDE"];
    _box2 = createVehicle ["Land_PaperBox_01_open_water_F", (getPos _ngoBuilding) findEmptyPosition [2, 50, "SignAd_Sponsor_01_IDAP_F"], [], 2, "CAN_COLLIDE"];
    // _car = createVehicle ["C_IDAP_Van_02_vehicle_F", (getPos _ngoBuilding) findEmptyPosition [2, 75, "SignAd_Sponsor_01_IDAP_F"], [], 2, "CAN_COLLIDE"];


    _endTrg = createTrigger ["EmptyDetector", getPos _ngoBuilding, true];
    _endtrg setTriggerActivation ["ANYPLAYER", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [30, 30, _defDir, false, 30];
    _endTrg setTriggerTimeout [0, 5, 10, false];

    [west, format ["task_%1", _ngoGrp], ["Offensive", "Rescue Aid Workers", ""], getPos _ngoBuilding, "CREATED", 1, true, "help", false] call BIS_fnc_taskCreate;

    [_endTrg, _ngoGrp, _objCenter, getpos _ngoBuilding] spawn {
        params ["_endTrg", "_ngoGrp", "_objCenter", "_ngoPos"];

        private _units = units _ngoGrp;
        _units = +_units;

        waitUntil {sleep 1; triggerActivated _endTrg or ({alive _x} count (units _ngoGrp) <= 0)};

        if (({alive _x} count (units _ngoGrp) > 0)) then {
            [format ["task_%1", _ngoGrp], "SUCCEEDED", true] call BIS_fnc_taskSetState;

            sleep 1;

            if (pl_sorties < 4) then {pl_sorties = 4};

            [west, format ["task_%1", _ngoGrp], ["Offensive", "Evacuate Aid Workers", "Call in Medevag to Evacuate Aid Workers"], getPos (leader _ngoGrp), "ASSIGNED", 1, true, "heli", false] call BIS_fnc_taskCreate;

            waitUntil {sleep 1; ({alive _x} count (units _ngoGrp) <= 0) or (pl_medevac_Heli_1 in (((getPos (leader _ngoGrp)) nearObjects ["Air", 300]) apply {typeof _x}))};

            if ({alive _x} count (units _ngoGrp) > 0) then {

                {
                    _unit = _x;
                    _joinTargets = (getPos _unit) nearObjects ["Air", 350];

                    _unit enableAI "PATH";
                    _unit setUnitPos "AUTO";

                    {
                        if ((typeOf _x) isEqualTo pl_medevac_Heli_1) exitWith {
                            [_x, _unit] spawn {
                                params ["_heli", "_unit"];

                                waitUntil {sleep 1; isTouchingGround _heli or !alive _unit};

                                [_unit] joinSilent (group (driver _heli));
                                _unit assignAsCargo _heli;
                                [_unit] allowGetIn true;
                                [_unit] orderGetIn true;
                            };
                        };
                    } forEach _joinTargets;
                } forEach _units;

            };

            waitUntil {sleep 1; {alive _x} count _units == 0 or ({_x distance2D _ngoPos > 600} count _units) >= ({alive _x} count _units)};

            if ( {alive _x} count _units > 0) then {
                [format ["task_%1", _ngoGrp], "SUCCEEDED", true] call BIS_fnc_taskSetState;

                pl_arty_ammo = pl_arty_ammo + 10;
                pl_sorties = pl_sorties + 10;

                if ((random 1) > 0.6) then {
                    [_objCenter, _ngoPos] call dyn2_opfor_mission_spawner;
                };

            } else {
                [format ["task_%1", _ngoGrp], "FAILED", true] call BIS_fnc_taskSetState;

                if ((random 1) > 0.5) then {
                    [_objCenter, _ngoPos] call dyn2_opfor_mission_spawner;
                };
            };

        } else {
            [format ["task_%1", _ngoGrp], "FAILED", true] call BIS_fnc_taskSetState;
            if ((random 1) > 0.25) then {
                [_objCenter, _ngoPos] call dyn2_opfor_mission_spawner;
            };
        };

    };


    // "SignAd_Sponsor_01_IDAP_F"
    // "Land_PaperBox_01_open_boxes_F"
    // "Land_PaperBox_01_open_water_F"
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

dyn2_SIDE_capture_HVT = {
    params ["_objCenter", "_playerStart"];

    private _defDir = _objCenter getDir _playerStart;
    private _allBuildings = nearestObjects [_objCenter, ["house"], 1000];
    private _allGrps = [];
    private _validBuildings = [];
    // Valid Buildings
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 4 and !(isHidden _x) and _x distance2D _objCenter >= 300) then {
            _validBuildings pushBack _x;
        };
    } forEach _allBuildings;

    if (_validBuildings isEqualTo []) exitWith {false};

    _targetBuilding = selectRandom _validBuildings;

    private _HVTGrp = createGroup [east, true];

    private _HVT = _HVTGrp createUnit [dyn2_standart_HVT, getPos _targetBuilding, [], 10, "NONE"];

    for "_i" from 0 to 2 do {
        _unit = _HVTGrp createUnit [selectRandom dyn2_standart_PMCs, getPos _targetBuilding, [], 10, "NONE"];
        // _unit setCaptive true;
    };

    [_targetBuilding, _HVTGrp, _defDir, true] call dyn2_garrison_building;
    (units _HVTGrp) joinSilent createGroup east; 

    _HVTGrp = group _HVT;

    _HVTGrp setBehaviour "STEALTH";
    _HVTGrp setCombatMode "GREEN";

    for "_i" from 1 to ([2, 3] call BIS_fnc_randomInt) do {
        0 = [[[[getPos _targetBuilding, 800]], [[getPos _targetBuilding, 350], "water"]] call BIS_fnc_randomPos] call dyn2_spawn_patroll;
    };

    // _m = createMarker [str (random 1), getPos _targetBuilding];
    // _m setMarkerType "mil_circle";
    // _m setMarkerColor "colorOPFOR";

    _trg = createTrigger ["EmptyDetector", getPos _hvt, true];
    _trg setTriggerActivation ["WEST", "PRESENT", false];
    _trg setTriggerStatements ["this", " ", " "];
    _trg setTriggerArea [100, 100, _defDir, false, 30];
    _trg setTriggerTimeout [0, 5, 10, false];

    _taskPos = [[[getPos _targetBuilding, 300]], [[getPos _targetBuilding, 100], "water"]] call BIS_fnc_randomPos;
    [west, format ["task_%1", _HVT], ["Offensive", "Search and Capture HVT", ""], _taskPos, "CREATED", 1, true, "kill", false] call BIS_fnc_taskCreate;

    _areaMarker = createMarker [str (random 5), _taskPos];
    _areaMarker setMarkerShape "ELLIPSE";
    _areaMarker setMarkerBrush "FDiagonal";
    _areaMarker setMarkerColor "colorOPFOR";
    _areaMarker setMarkerAlpha 0.3;
    _areaMarker setMarkerSize [300, 300];

    [getPos _targetBuilding, _objCenter, _HVT, _HVTGrp, _trg, _playerStart] spawn {
        params ["_hvtPos", "_objCenter", "_HVT", "_HVTGrp", "_trg", "_playerStart"];

        _units = (units _HVTGrp) - [_hvt];

        waitUntil {sleep 1; !alive _HVT or triggerActivated _trg};

        if (alive _HVT) then {
            _hvt setCaptive true;

            waitUntil {sleep 1; !alive _HVT or ({!alive _x or captive _x} count _units == count _units)};

            if (alive _hvt) then {
                [format ["task_%1", _HVT], "SUCCEEDED", true] call BIS_fnc_taskSetState;
                _hvt setCaptive false;
                _powGroup = createGroup playerside;
                [_hvt] joinSilent _powGroup;
                _powGroup setGroupId ["HVT"];
                player hcSetGroup [_powGroup, "HVT"];
 
                if ((random 1) > 0.65) then {
                    [_objCenter, _hvtPos] call dyn2_opfor_mission_spawner;
                };

                private _exfilPos = _playerStart;
                _allBuildings = nearestObjects [_playerStart, ["house"], 500];

                if ((count _allBuildings) > 0) then {
                    _exfilPos = getPos (selectRandom _allBuildings);
                };

                [west, format ["task2_%1", _HVT], ["Offensive", "Exfil HVT", ""], _exfilPos, "ASSIGNED", 1, true, "truck", false] call BIS_fnc_taskCreate;

                waitUntil {sleep 2; !alive _HVT or (_hvt distance2D _exfilPos) <= 100};

                if (alive _hvt) then {
                    [format ["task2_%1", _HVT], "SUCCEEDED", true] call BIS_fnc_taskSetState;
                    deleteVehicle _hvt;

                    pl_sorties = pl_sorties + 8;
                } else {
                    [format ["task2_%1", _HVT], "FAILED", true] call BIS_fnc_taskSetState;
                };

            } else {
                [format ["task_%1", _HVT], "FAILED", true] call BIS_fnc_taskSetState;

                [_objCenter, _hvtPos] call dyn2_opfor_mission_spawner;
            };

        } else {
            [format ["task_%1", _HVT], "FAILED", true] call BIS_fnc_taskSetState;

            [_objCenter, _hvtPos] call dyn2_opfor_mission_spawner;
        };
    };

    true
};

dyn2_SIDE_destroy_CP = {
    params ["_objCenter", "_playerStart"];

    private _defDir = _objCenter getDir _playerStart;
    _rearPos = _objCenter getpos [300, _defDir - 180]; 
    private _cpPos = [_rearPos, 1, 600, 20, 0, 0, 0, _rearPos] call BIS_fnc_findSafePos;

    if (_cpPos isEqualTo _rearPos) exitWith {false};

    [_cpPos, _defDir, dyn2_standart_csat_CP, 0] call BIS_fnc_objectsMapper;

    // 0 = [_cpPos, _defDir] call dyn2_spawn_squad;

    private _cpGroup = createGroup east;

    for "_i" from 0 to ([7, 10] call BIS_fnc_randomInt) do {
        _o = _cpGroup createUnit [selectRandom [dyn2_standart_officer, dyn2_standart_soldier], _cpPos, [], 25, "NONE"];
        _o disableAI "PATH";
    };

    _cpGroup setBehaviour "SAFE";

    for "_i" from 1 to ([2, 3] call BIS_fnc_randomInt) do {
        0 = [[[[_cpPos, 200]], [[_cpPos, 70], "water"]] call BIS_fnc_randomPos] call dyn2_spawn_patroll;
    };

    0 = [_cpPos getPos [[40, 100] call BIS_fnc_randomInt, _defDir - 45 - 180 ], _defDir, selectRandom dyn2_standart_combat_vehicles, true, true] call dyn2_spawn_covered_vehicle;

    _taskPos = [[[_cpPos, 300]], [[_cpPos, 100], "water"]] call BIS_fnc_randomPos;
    [west, format ["task_%1", _cpPos], ["Offensive", "Search and Destroy FCP", ""], _taskPos, "CREATED", 1, true, "whiteboard", false] call BIS_fnc_taskCreate;

    _areaMarker = createMarker [str (random 5), _taskPos];
    _areaMarker setMarkerShape "ELLIPSE";
    _areaMarker setMarkerBrush "FDiagonal";
    _areaMarker setMarkerColor "colorOPFOR";
    _areaMarker setMarkerAlpha 0.3;
    _areaMarker setMarkerSize [300, 300];

    [_cpPos, _cpGroup] spawn {
        params ["_cpPos", "_cpGroup"];

        waitUntil {sleep 2; {!alive _x or captive _x} count (units _cpGroup) == count (units _cpGroup)};

        [format ["task_%1", _cpPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;
    };

    true
};

dyn2_SIDE_defend_CP = {
    params ["_objCenter", "_playerStart"];

    if (dyn2_allied_help_active) exitwith {false};

    private _objDistance = _objCenter distance2D _playerStart;
    private _defDir = _objCenter getDir _playerStart;
    private _forwardPos = _objCenter getpos [_objDistance * 0.85, _defDir + ([-10, 10] call BIS_fnc_randomInt)];
    // private _cpPos = [[[_forwardPos, 500]], [[_playerStart, 250], "water"]] call BIS_fnc_randomPos;
    _cpPos = [_forwardPos, 1, 350, 10, 0, 0, 0, [], _forwardPos] call BIS_fnc_findSafePos;

    if (_cpPos isEqualTo _forwardPos) exitWith {false};

    [_cpPos, _defDir, dyn2_standart_nato_CP, 0] call BIS_fnc_objectsMapper;

    _alliedGrp = createGroup [playerSide, true];

    private _wiaLimit = 0;
    {
        _unit = _alliedGrp createUnit [typeof _x, _cpPos, [], 20, "NONE"];
        _cover = [getPos _unit, _cpPos getdir _objCenter, 60] call dyn2_get_cover_pos;
        _unit setPos (_cover#0);
        _unit setUnitPos (_cover#1);
        _unit setDir (_cpPos getdir _objCenter);
        _unit setVariable ["pl_damage_reduction", true];
        doStop _unit;
        _unit disableAI "PATH";
        if (_wiaLimit < 2 and (random 1) > 0.75) then {
            _unit setUnconscious true;
            _unit setVariable ["pl_wia", true];
            _wiaLimit = _wiaLimit + 1;
        };
    } forEach (units (selectRandom (allGroups select {side _x == playerSide and (count (units _x) >= 6)})));

    [west, format ["task_%1", _cpPos], ["Offensive", "Defend FCP", ""], _cpPos, "CREATED", 1, true, "defend", false] call BIS_fnc_taskCreate;

    [_objCenter, _cpPos] call dyn2_OPF_catk;
    // [_objCenter, _cpPos] call dyn2_OPF_catk;

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

    [_cpPos, _objCenter, _trg, _alliedGrp, _areaMarker] spawn {
        params ["_cpPos", "_objCenter", "_trg", "_alliedGrp", "_areaMarker"];

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

        waitUntil {sleep 2; ({alive _x} count (units _alliedGrp)) <= 0 or triggerActivated _trg2};

        if (({alive _x} count (units _alliedGrp)) > 0) then {
            [format ["task_%1", _cpPos], "SUCCEEDED", true] call BIS_fnc_taskSetState;

            pl_sorties = pl_sorties + 6;
        } else {
            [format ["task_%1", _cpPos], "FAILED", true] call BIS_fnc_taskSetState;
        };

        deletemarker _areaMarker;
    };

    dyn2_allied_help_active = true;
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

