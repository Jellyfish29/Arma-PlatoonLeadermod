dyn2_opfor_mission_spawner = {
	params ["_locPos", "_missionPos"];

	private _missionType = selectRandom ["catk", "catk", "recon", "recon", "armor"];
	private _success = false; 
	switch (_missionType) do { 
		case "catk" : {_success = [_locPos, _missionPos] call dyn2_OPF_catk};
		case "recon" : {_success = [_locPos, _missionPos] call dyn2_OPF_recon_patrol}; 
		case "armor" : {_success = [_locPos, _missionPos] call dyn2_OPF_armor_attack}; 
		default {_success = [_locPos, _missionPos] call dyn2_OPF_catk}; 
	};

	_artySuccess = [[6, 12] call BIS_fnc_randomInt, _missionPos] spawn dyn2_OPF_fire_mission;
};

dyn2_OPF_catk = {
	params ["_locPos", "_atkPos"];

	private _atkDir = _locPos getDir _atkPos;
	private _rearPos = _atkPos getPos [[1000, 1500] call BIS_fnc_randomInt, _atkDir - 180];

	for "_i" from 1 to dyn2_strength + 1 do {
		_spawnPos = [[[_rearPos, 100]], [[[allGroups select {(side _x) == playerSide}] call dyn2_find_centroid_of_groups, 800], "water"]] call BIS_fnc_randomPos;
		_grp = [_spawnPos, _atkDir] call dyn2_spawn_squad;
		if ((random 1) > 0.5) then {
			private _road = [_spawnPos, 800] call dyn2_nearestRoad;
			private _info = getRoadInfo _road;    
		    private _endings = [_info#6, _info#7];
			_endings = [_endings, [], {_x distance2D _atkPos}, "ASCEND"] call BIS_fnc_sortBy;
		    private _roadDir = (_endings#1) getDir (_endings#0);
		    private _rPos = ASLToATL (_endings#0);

		    _vicR = [_rPos, _roadDir, dyn2_standart_IFV] call dyn2_spawn_vehicle;
		    _vicGrp = _vicR#0;
		    _vic = _vicR#1;
		    {
                _x moveInCargo _vic;
            } forEach (units _grp);
            _grp addVehicle _vic;
            _vicGrp addWaypoint [_atkPos, 40];
            _grp enableDynamicSimulation false;
            _vicGrp enableDynamicSimulation false;
            // _vicGrp setBehaviour "SAFE";
		} else {
			_grp addWaypoint [_atkPos, 40];
			_grp enableDynamicSimulation false;
		};
	};

	true
};

dyn2_OPF_recon_patrol = {

	params ["_locPos", "_atkPos"];


	private _atkDir = _locPos getDir _atkPos;
	private _rearPos = _atkPos getPos [[1300, 1800] call BIS_fnc_randomInt, _atkDir - 180];

	for "_i" from 1 to dyn2_strength + 1 + ([0, 1] call BIS_fnc_randomInt) do {
		_spawnPos = [[[_rearPos, 100]], [[[allGroups select {(side _x) == playerSide}] call dyn2_find_centroid_of_groups, 800], "water"]] call BIS_fnc_randomPos;
		_grp = [_spawnPos, _atkDir, dyn2_standart_recon_team] call dyn2_spawn_squad;

		private _road = [_spawnPos, 800] call dyn2_nearestRoad;
		private _info = getRoadInfo _road;    
	    private _endings = [_info#6, _info#7];
		_endings = [_endings, [], {_x distance2D _atkPos}, "ASCEND"] call BIS_fnc_sortBy;
	    private _roadDir = (_endings#1) getDir (_endings#0);
	    private _rPos = ASLToATL (_endings#0);

	    _vicR = [_rPos, _roadDir, selectRandom dyn2_standart_light_armed_transport] call dyn2_spawn_vehicle;
	    _vicGrp = _vicR#0;
	    _vic = _vicR#1;

	    (leader _grp) moveInAny _vic;
    	{
            _x moveInAny _vic;
        } forEach (units _grp);
        _grp addVehicle _vic;

        {
        	if (vehicle _x == _x) then {deleteVehicle _x};
        } forEach (units _grp);

        _wp = _vicGrp addWaypoint [_atkPos, 40];
        _wp setWaypointType "SAD";
        _vicGrp enableDynamicSimulation false;
            // _vicGrp setBehaviour "SAFE";
		_grp addWaypoint [_atkPos, 40];
		_grp enableDynamicSimulation false;
	};

	true
};

dyn2_OPF_armor_attack = {
	params ["_locPos", "_atkPos"];

	private _atkDir = _locPos getDir _atkPos;
	private _rearPos = _atkPos getPos [[1000, 1500] call BIS_fnc_randomInt, _atkDir - 180];

	_spawnPos = [[[_rearPos, 100]], [[[allGroups select {(side _x) == playerSide}] call dyn2_find_centroid_of_groups, 800], "water"]] call BIS_fnc_randomPos;

	private _road = [_spawnPos, 800] call dyn2_nearestRoad;
	private _info = getRoadInfo _road;    
    private _endings = [_info#6, _info#7];
	_endings = [_endings, [], {_x distance2D _atkPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _roadDir = (_endings#1) getDir (_endings#0);
    private _rPos = ASLToATL (_endings#0);

	_vicR = [_rPos, _roadDir, dyn2_standart_MBT] call dyn2_spawn_vehicle;

	_vicGrp = _vicR#0;
    _vic = _vicR#1;

    _vicGrp addWaypoint [_atkPos, 40];
    _vicGrp enableDynamicSimulation false;

    true

};

dyn2_OPF_heli_insertion = {
	params ["_locPos", "_atkPos"];

	private _approachdir = _locPos getDir _atkPos;
	private _spawnPos = _atkPos getPos [[2500, 3000] call BIS_fnc_randomInt, _approachdir - ([160, 200] call BIS_fnc_randomInt)];

	for "_i" from 1 to dyn2_strength + 1 + ([0, 1] call BIS_fnc_randomInt) do {

		private _heliGroup = createGroup dyn2_opfor_side;
		_heliGroup setBehaviour "CARELESS";

		_p = [_spawnPos getPos [60 * _i, _approachdir - 180], _approachdir, dyn2_standart_attack_heli, _heliGroup] call BIS_fnc_spawnVehicle;
    	_heli = _p#0;

    	[_heli, 70, getPos _heli, "ATL"] call BIS_fnc_setHeight;
	    _heli forceSpeed 300;
	    _heli flyInHeight 70;

	    {
	        _x setSkill 1;
	    } forEach crew (_heli);

	    _grp = [[0,0,0], 0] call dyn2_spawn_squad;

	   	(leader _grp) moveInAny _heli;
    	{
            _x moveInAny _heli;
        } forEach (units _grp);
        _grp addVehicle _heli;

        {
        	if (vehicle _x == _x) then {deleteVehicle _x};
        } forEach (units _grp);

	    // _landPos = [_atkPos, 1, 150, 15, 0, 10, 0, [], _atkPos] call BIS_fnc_findSafePos;
	    _sadWp = _heliGroup addWaypoint [_atkPos, 50];
    	_sadWp setWaypointType "TR UNLOAD";

    	[_heli, _heliGroup, _spawnPos, _grp] spawn {
    		params ["_heli", "_heliGroup", "_spawnPos", "_grp"];

    		waitUntil {sleep 1; (isTouchingGround _heli) or !alive _heli};

    		if (alive _heli) then {
    			_grp leaveVehicle _heli;
    		};

    		_time = time + 60;
        	waitUntil {sleep 0.5; ({_x in _heli} count (units _grp)) <= 0 or time >= _time or !alive _heli};

        	if (alive _heli) then {
        		_heli flyInHeight 100;
		        _heli forceSpeed 300;
		        _evacWp = _heliGroup addWaypoint [_spawnPos, 0];

		        waitUntil {sleep 0.5; (_heli distance2D _spawnPos ) <= 500 or !alive _heli};

		        if ((_heli distance2D _spawnPos ) <= 500) then {
		        	{
			            _heli deleteVehicleCrew _x;
			        } forEach (crew _heli);
			        deleteVehicle _heli;
			        deleteGroup _heliGroup;
		        };
        	};
    	};

	};
	
};

dyn2_OPF_fire_mission = {
	params ["_shells", ["_staticPos", []], ["_smoke", false]];

    if (dyn2_opfor_arty isEqualTo []) exitWith {false};

    [_shells, _staticPos, _smoke] spawn {
    	params ["_shells", "_staticPos", "_smoke"];
    	private ["_eh", "_cords", "_ammoType", "_gunArray"];

	    _gunArray = dyn2_opfor_arty;

	    if (_staticPos isEqualTo []) then {
	        _target = selectRandom (allUnits select {side _x == playerSide});
	        _cords = getPos _target;
	    }
	    else
	    {
	        _cords = _staticPos;
	    };
	    for "_i" from 1 to _shells do {
	        {
	            if (isNull _x) exitWith {};
	            _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select 0;
	            if (_smoke) then {
	                _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines") select {["smoke", _x] call BIS_fnc_inString})#0;
	            };
	            if (isNil "_ammoType") exitWith {};
	            _firePos = [[[_cords, 350]], [[position player, 100]]] call BIS_fnc_randomPos;
	            // player sidechat str (_firePos inRangeOfArtillery [[_x], _ammoType]);
	            _x commandArtilleryFire [_firePos, _ammoType, 1];
	            _x setVariable ["dyn_waiting_for_fired", true];
	            _eh = _x addEventHandler ["Fired", {
	                params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
	                _unit setVariable ["dyn_waiting_for_fired", false];
	            }];
	            // sleep 1;
	        } forEach _gunArray;
	        sleep 1;
	        _time = time + 10;
	        waitUntil {({_x getVariable ["dyn2_waiting_for_fired", true]} count _gunArray) == 0 or time >= _time};
	        sleep 1;
	    };

	    sleep 20;

	    {
	        _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select 0;
	        _x addMagazineTurret [_ammoType, [-1]];
	        if !(isNil "_eh") then {
	            _x removeEventHandler ["Fired", _eh];
	        };
	        _x setVehicleAmmo 1;
	    } forEach _gunArray;
	};
	true
};

dyn2_OPF_supply_convoy = {
	
};

dyn2_OPF_retreat = {
	
};

// [10, getpos player] spawn dyn2_OPF_fire_mission;


// [[400, 400], [2000, 2000]] call dyn2_OPF_heli_insertion;