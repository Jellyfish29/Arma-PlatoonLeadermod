pl_get_suppress_target_pos = {
    params ["_initialTargetPos", "_unit"];

    private _vis = lineIntersectsSurfaces [eyePos _unit, _initialTargetPos, _unit, vehicle _unit, true, 1, "FIRE"];
    private _supDistance = _unit distance2D _initialTargetPos;
    
    // if no surface intersection return initial pos
    private _targetPos = _initialTargetPos;
    private _allHelpers = [];

    // surface intersection
    if !(_vis isEqualTo []) then {
        _targetPos = (_vis select 0) select 0;

        // _helper1 = createVehicle ["Sign_Sphere25cm_F", _targetpos, [], 0, "none"];
        // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
        // _helper1 setposASL _targetpos;
        // _allHelpers pushback _helper1;

        // intersection with terrain
        if (isNull (_vis#0#2)) then {

            // increase targetpos hight by 0.2 40 times and check again;
            for "_i" from 0 to (_supDistance * 0.2) step (_supDistance * 0.01) do {
                _vis = lineIntersectsSurfaces [eyePos _unit, [_initialTargetPos#0, _initialTargetPos#1, (_initialTargetPos#2) + _i], _unit, vehicle _unit, true, 1, "VIEW"];
                if (_vis isEqualTo []) then {
                    _targetPos = [_initialTargetPos#0, _initialTargetPos#1, (_initialTargetPos#2) + _i];
                    break;
                } else {
                    if !(isNull (_vis#0#2)) then {
                        _targetPos = _vis#0#0;
                        break;
                    };
                    // _helper3 = createVehicle ["Sign_Sphere25cm_F", (_vis#0#0), [], 0, "none"];
                    // _helper3 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                    // _helper3 setposASL (_vis#0#0);
                    // _allHelpers pushback _helper3;
                };

                // _helper4 = createVehicle ["Sign_Sphere25cm_F", [_initialTargetPos#0, _initialTargetPos#1, (_initialTargetPos#2) + _i], [], 0, "none"];
                // _helper4 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                // _helper4 setposASL (_vis#0#0);
                // _allHelpers pushback _helper4;
            };

            // _helper2 = createVehicle ["Sign_Sphere25cm_F", _targetpos, [], 0, "none"];
            // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];
            // _helper2 setposASL _targetpos;
            // _allHelpers pushback _helper2;

        } else {
            // if surface is not terrain and surface is within distance parameters return surface pos

            if ((_vis#0#2) isKindOf "Building") then {

	             if ((_vis#0#0) distance2d _initialTargetPos <= 80 and (_vis#0#0) distance2d _unit >= 60) then {
	                _targetPos = _vis#0#0;
	            } else {
	                _targetpos = [0,0,0];
	            	// _helper5 = createVehicle ["Sign_Sphere25cm_F", _vis#0#0, [], 0, "none"];
					// _helper5 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
					// _helper5 setposASL _targetpos;
					// _allHelpers pushback _helper5;
	            };
	        } else {
	        	if ((_vis#0#0) distance2d _unit >= 25) then {
	        		_targetPos = _vis#0#0;
	        	} else {
	        		_targetpos = [0,0,0];
	        	}
	    	};
        };
    };




    // [_allHelpers] spawn {
    //     sleep 30;

    //     {
    //         deleteVehicle _x;
    //     } forEach (_this#0);

    // };

    _targetPos
};

pl_defence_suppression = {
    params ["_group", "_watchPos", "_medic"];
    private ["_targetsPos", "_firers", "_target", "_allPos"];

    private  _time = time + 20;
    waitUntil {sleep 0.5;  time >= time or !(_group getVariable ["onTask", true]) };
    if !(_group getVariable ["onTask", true]) exitWith {};
    _allPos = [];

    private _allTargets = [];

    while {_group getVariable ["onTask", false]} do {
        waitUntil {sleep 0.5; !(_group getVariable ["pl_hold_fire", false]) and !(_group getVariable ["pl_is_suppressing", false]) and (isNull (_group getVariable ["pl_grp_active_at_soldier", objNull]))};
        // _allTargets = nearestObjects [_watchPos, ["Man", "Car"], 350, true];
        _enemyTargets = (_watchPos nearEntities [["Man", "Car"], 275]) select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and ((leader _group) knowsAbout _x) >= 0.2};
        if (count _enemyTargets > 0) then {
            _firers = [];

            if (_group getVariable ["pl_inf_attached", false]) then {
                _vicGroup = _group getVariable ["pl_attached_vicGrp", grpNull];
                _firers pushBack (gunner (vehicle (leader _vicGroup)));
            };

            {
                if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                    _firers pushBackUnique _x;
                    _x setUnitTrait ["camouflageCoef", 0.5, false];
                    _x setVariable ["pl_damage_reduction", true];
                } else {
                    if ((random 1) > 0.5) then {_firers pushBackUnique _x;}
                };
            } forEach ((units _group) select {!(_x checkAIFeature "PATH") and _x != _medic and !(([secondaryWeapon _x] call BIS_fnc_itemtype) select 1 in ["MissileLauncher", "RocketLauncher"])});
            {
                _unit = _x;
                _target = selectRandom _enemyTargets;
                if (vehicle _unit != _unit) then {
                    _target = ([_enemyTargets, [], {([_group] call pl_find_centroid_of_group) distance2D _x}, "DESCEND"] call BIS_fnc_sortBy)#0;
                };
                _targetPos = getPosASL _target;
                _targetPos = [_targetpos, _unit] call pl_get_suppress_target_pos;
                if ((random 1) > 0.8) then {
                    [_x, selectRandom _enemyTargets] spawn pl_fire_ugl_at_target;
                };
                if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !(_group getVariable ["pl_hold_fire", false]) and _targetPos isNotEqualTo [0,0,0]) then {
                    if (((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") or vehicle _unit != _unit) then { 
                        if !([_unit, _targetPos] call pl_friendly_check_strict) then {
                        // if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_unit, _targetPos] call pl_friendly_check_strict) and (_unit distance2D _targetPos) > _targetDistance * 0.15) then {
                            _unit doWatch _targetPos;
                            _unit doSuppressiveFire _targetPos;
                            _allTargets pushback (getPosATLVisual _target);
                        };
                    } else {
                        if !([_unit, _targetPos] call pl_friendly_check) then {
                        // if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_unit, _targetPos] call pl_friendly_check) and (_unit distance2D _targetPos) > _targetDistance * 0.15) then {
                            _unit doWatch _targetPos;
                            _unit doSuppressiveFire _targetPos;
                            _allTargets pushback (getPosATLVisual _target);
                        };
                    };
                };
            } forEach _firers;

            if !(_allTargets isEqualto []) then {
                _allPos = [_allTargets] call pl_find_centroid_of_points;

                pl_suppression_poses pushback [_allPos, _group];
            };

            _time = time + 25;
            waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true])};

            
        };
        _time = time + 5;
        waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true])};

        if !(_allPos isEqualto []) then {
            pl_suppression_poses = pl_suppression_poses - [[_allPos, _group]];
        };
    };
};