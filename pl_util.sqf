// pl_substr = {
//     private ["_find", "_string", "_find_len", "_str", "_found", "_pos"];
//     _find = _this select 0;
//     _string = toArray (_this select 1);
//     _find_len = count toArray _find;
//     _str = [] + _string;
//     _str resize _find_len;
//     _found = false;
//     _pos = 0;
//     for "_i" from _find_len to count _string do {
//         if (toString _str == _find) exitWith {_found = true};
//         _str set [_find_len, _string select _i];
//         _str set [0, "x"];
//         _str = _str - ["x"];
//         _pos = _pos + 1;
//     };
//     if (!_found) then {
//         _pos = -1;
//     };
//     _pos
// };



// How much ammo a magazine has
// Params:
// 0: our tank object
// 1: magazine name
pl_has_ammo = {
    params ["_unit", "_mag"];
    private ["_ammo", "_mag", "_unit"];
    _ammo = 0;
    {
        if (_mag == _x select 0) exitWith {_ammo = _x select 1};
    } foreach (magazinesAmmo _unit);
    _ammo
};

// Loads a round into cannon
// Params:
// 0: our tank object
// 1: magazine name to load
pl_load_mag = {
    private ["_unit", "_mag", "_mag_ammo", "_all_mags"];
    _unit = _this select 0;
    _mag = _this select 1;
    _all_mags = magazinesAmmo _unit;
    _mag_ammo = [_unit, _mag] call pl_has_ammo;
    {
        _unit removeMagazine (_x select 0);
    } foreach _all_mags;
    _unit addMagazine [_mag, _mag_ammo];
    _all_mags = _all_mags - [[_mag, _mag_ammo]];
    {
        _unit addMagazine _x;
    } foreach _all_mags;
};

pl_load_he = {
    params ["_unit"];
    private ["_he_round"];
    _he_round = "";
    {
      if (["he", _x] call BIS_fnc_inString) then {_he_round = _x};
    } foreach (magazines _unit);
    if !(_he_round isEqualTo "") then {
        if ([_unit, _he_round] call pl_has_ammo > 0) then {
            [_unit, _he_round] call pl_load_mag;
        };
    };
};

pl_load_ap = {
    params ["_unit"];
    private ["_ap_round"];
    _ap_round = "";
    {
      if (["ap", _x] call BIS_fnc_inString) then {_ap_round = _x};
      if (["sabot", _x] call BIS_fnc_inString) then {_ap_round = _x};
    } foreach (magazines _unit);

    if !(_ap_round isEqualTo "") then {
        if ([_unit, _ap_round] call pl_has_ammo > 0) then {
            [_unit, _ap_round] call pl_load_mag;
        };
    };
};

pl_get_weapon = {
    params ["_vic"];

    private _type="";
    private _turrets = allTurrets _vic;
    private _turret = [];
    private _weapons = [];
    private _weapon = "";

    {
        _turret = _x;
        // _weapon = {
        //     if (((_x call BIS_fnc_itemType)select 1) isEqualTo "MissileLauncher") exitwith {_x};
        //     ""
        // } forEach (_vic weaponsTurret _turret);
        // if !(_weapon isEqualTo "") exitwith {};
        _weapon = {
            if (((_x call BIS_fnc_itemType)select 1) isEqualTo "Cannon") exitwith {_x};
            ""
        } forEach (_vic weaponsTurret _turret);
        if !(_weapon isEqualTo "") exitwith {};
    } forEach _turrets;

    // private _muzzles = getArray(configFile>>"cfgWeapons">>_weapon>>"muzzles");
    // private _muzzle = _weapon;

    _weapon
};


pl_quick_suppress = {
    params ["_unit", "_target", ["_light", false]];

    if (isNil "_target") exitWith {false};
    if !(alive _target) exitWith {false};
    private _targetpos = getPosASL _target;

    if (_light) then {
        _unit doSuppressiveFire _target;
    } else {

        _vis = lineIntersectsSurfaces [eyePos _unit, _targetPos, _unit, vehicle _unit, true, 1];

        if !(_vis isEqualTo []) then {
            _targetPos = (_vis select 0) select 0;
        };
        
        if ((_targetPos distance2D _unit) > pl_suppression_min_distance) then {
            if (((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") or vehicle _unit != _unit) then { 
                if !([_unit, _targetPos] call pl_friendly_check_strict) then {
                    _unit doSuppressiveFire _targetPos;
                }
            } else {
                if !([_unit, _targetPos] call pl_friendly_check) then {
                    _unit doSuppressiveFire _targetPos;
                };
            };
        };
    };
    true
};

pl_quick_suppress_unit = {
    params ["_unit"];

    private _target = selectRandom (((getPos _unit) nearEntities [["Man", "Car"], 500]) select {(side _x) != playerSide and (side _x) != civilian and (_unit knowsAbout _x) > 0.1});

    if (isNil "_target") exitWith {};

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
};


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

                 if ((_vis#0#0) distance2d _initialTargetPos <= 150 and (_vis#0#0) distance2d _unit >= 25) then {
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



pl_get_fire_position = {
    params ["_unit", "_target", "_maxDistance"];
    private ["_movePos"];

    _vis = lineIntersectsSurfaces [eyePos _unit, getPosASL _target, _unit, vehicle _unit, true, 1];

    if !(_vis isEqualTo []) then {
        if ((((_vis select 0) select 0) distance2D _unit) < _maxDistance) then {
            _movePos = (_vis select 0) select 0;
        };
    } else {
        _movePos = getPos _unit;
    };

    _m = createMarker [str (random 3), _movePos];
    _m setMarkerType "mil_dot";

    _movePos
};

pl_enable_force_move = {
    params ["_unit", "_state", ["_light", false]];
    if (_state) then {
        _unit forceSpeed 20;
        _unit setUnitPos "UP";
        _unit enableAI "PATH";
        _unit disableAI "COVER";
        _unit disableAI "SUPPRESSION";
        _unit setBehaviourStrong "AWARE";
        _unit disableAI "FIREWEAPON";
        // _unit setUnitCombatMode "WHITE";
        // if !(_light) then {
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            _unit disableAI "WEAPONAIM";
            _unit setUnitCombatMode "BLUE";
        // };
    }
    else
    {
        _unit forceSpeed -1;
        _unit enableAI "COVER";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "WEAPONAIM";
        _unit enableAI "FIREWEAPON";
        _unit setUnitCombatMode "YELLOW";
    };
};

pl_position_reached_check = {
    params ["_unit", "_movePos", "_counter"];

    // player sideChat (str _counter);
    private _end = false;
    if (_counter >= 10) exitWith {[true, _counter, _movePos, true]};

    if ((_unit distance _movePos) > 1.5 and ((group _unit) getVariable ["onTask", false]) and alive _unit and !((lifeState _unit) isEqualto "INCAPACITATED") and !((animationState _unit) in ["ladderrifleuploop", "laddercivilstatic"])) then {
        // if ((((currentCommand _unit) isNotEqualTo "MOVE") or ((speed _unit) == 0))) then {
        if (unitReady _unit or ((currentCommand _unit) isNotEqualTo "MOVE") or (speed _unit) == 0) then {

            _movePos = [-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd _movePos;

            // _m = createMarker [str (random 1), _movePos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];
            // _m setMarkerColor "colorOrange";

            [_unit, _movePos] spawn {
                params ["_unit", "_movePos"];
                _unit setHit ["legs", 0];
                _unit switchMove "";
                _unit setUnitPos "AUTO";
                // doStop _unit;
                // _unit setPos ([-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd (getPos _unit));

                sleep 0.5;

                if ((group _unit) getVariable ["onTask", false]) then {
                    _unit doMove _movePos;
                    _unit setDestination [_movePos, "LEADER DIRECT", true];
                };
            };
            _counter = _counter + 1;
        };
    };

    if ((_unit distance _movePos) < 0.5) exitWith {[true, _counter, _movePos, false]};

    [false, _counter, _movePos, false]
};

pl_force_move_on_task = {
    params ["_unit", "_movePos"];

    private _counter = 0;

    while {alive _unit and ((group _unit) getVariable ["onTask", false]) and (_unit distance2D _movePos) > 3.5} do {
        _time = time + 6;
        waitUntil {sleep 0.25; time > _time or !((group _unit) getVariable ["onTask", false]) or (_unit distance2D _movePos) < 4};
        _check = [_unit, _movePos, _counter] call pl_position_reached_check;
        if (_check#0) exitWith {};
        _counter = _check#1;
        _movePos = _check#2;
    };
};

pl_not_reachable_escape = {
    params ["_unit", "_pos", "_area"];

    sleep 2;

    if ((currentCommand _unit) isEqualTo "MOVE" and (speed _unit) == 0) exitWith {
        _unit setHit ["legs", 0];
        _movePos = [[[_pos, _area * 1.1]],["water"]] call BIS_fnc_randomPos;
        _movePos = _movePos findEmptyPosition [0, 10, typeOf _unit];
        // doStop _unit;
        _unit doMove _movePos;
        _unit setDestination [_movePos, "LEADER PLANNED", true];
        false
    };
    true
};


pl_find_cover_postion = {
    params ["_cords", ["_radius", 15]];
    private ["_valid"];

    private _covers = (nearestTerrainObjects [_cords, pl_valid_covers, _radius, true, true]); //select {!(isObjectHidden _x)};
    private _return = _cords;

    if ((count _covers) > 0) then {
        _return = getPos (_covers#0);
    };

    _return
};


pl_is_forest = {
    params ["_tpos"];

    _trees = nearestTerrainObjects [_tpos, ["Tree"], 50, false, true];

    if (count _trees > 25) exitWith {true};

    false
};

pl_convert_to_heigth_ASL = {
    params ["_pos", "_height"];

    _pos = ASLToATL _pos;
    _pos = [_pos#0, _pos#1, _height];
    _pos = ATLToASL _pos;

    _pos
};

pl_is_indoor = {
    params ["_pos"];
    // _pos = AGLToASL _pos;
    if (lineIntersects [_pos, _pos vectorAdd [0, 0, 30]]) exitWith {true};
    false
};

pl_is_city = {
    params ["_cpos"];
    _buildings = nearestTerrainObjects [_cPos, ["House"], 75, false, true];
    if (count _buildings >= 2) exitWith {true};
    false
};

pl_is_water = {
    params ["_pos"];
    private ["_isWater"];

    _isWater = {
        if (surfaceIsWater (_pos getPos [35, _x])) exitWith {true};
        false
    } forEach [0, 90, 180, 270]; 
    if (surfaceIsWater _pos) then {_isWater = true};
    _isWater 
};

pl_fof_check = {
    params ["_pos","_d", "_h"];
    private _c = 0;
    _startPos = [_pos, _h] call pl_convert_to_heigth_ASL;
    for "_i" from 0 to 300 step 25 do {

        _checkPos = [_pos getPos [_i, _d], _h] call pl_convert_to_heigth_ASL;

        _visP = lineIntersectsSurfaces [_startPos, _checkPos, objNull, objNull, true, 1, "VIEW"];

        if !(_visP isEqualTo []) exitWith {};
        _c = _c + 1;

        // _helper = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
        // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
        // _helper setposASL _checkPos;
    };
    _c
};

pl_get_near_inf_groups = {
    params {"_group", "_distance", ["_side", playerside]};

    private _allies = ((getPos (leader _group)) nearEntities [["Man"], _distance]) select {side (leader _group) == _side};
    private _nearGroups = [];

    {
        _nearGroups pushBackUnique (group _x);
    } forEach _allies;

    _nearGroups
};

pl_angle_switcher = {
    params ["_a"];
    if (_a > 360) then {
        _a = _a - 360;
    }
    else
    {
        _a = _a + 360;
    };
    _a
};

pl_nearestRoad = {
    params ["_center", "_radius", ["_blackList", []]];

    private _roads = _center nearRoads _radius;

    _validRoads = _roads select {!(((getRoadInfo _x)#0) in _blackList)};

    ([_validRoads, [], {(getpos _x) distance2D _center}, "ASCEND"] call BIS_fnc_sortBy)#0  
};

pl_find_highest_point = {
    params ["_center", "_radius", ["_uDir", 0]];

    private _scanStart = (_center getPos [_radius / 2, _uDir]) getPos [_radius / 2, _uDir + 90];
    private _widthOffSet = 0;
    private _heigthOffset = 0;
    private _maxZ = 0;
    private _r = _center;
    for "_i" from 0 to 100 do {
        _heigthOffset = 0;
        _scanPos = _scanStart getPos [_widthOffSet, _uDir - 180];
        for "_j" from 0 to 100 do {
            _checkPos = _scanPos getPos [_heigthOffset, _uDir - 90];
            _checkPos = ATLToASL _checkPos;

            // _m = createMarker [str (random 1), _checkPos];
   //       _m setMarkerType "mil_dot";
   //       _m setMarkerSize [0.3, 0.3];

            _z = _checkPos#2;
            if (_z > _maxZ) then {
                _r = _checkPos;
                _maxZ = _z;
            };
            _heigthOffset = _heigthOffset + (_radius / 100);
        };
        _widthOffSet = _widthOffSet + (_radius / 100);
    };

    // _m = createMarker [str (random 1), _r];
    // _m setMarkerColor "colorGreen";
    // _m setMarkerType "mil_dot";
    ASLToATL _r;
    _r
};

pl_THROW_VEL = {
    _unit = _this select 0;
    _targetpos = _this select 1;
    _maxdist = if ((count _this) > 2) then {_this select 2} else {30};
    _alpha = 45;
    _range = _targetpos distance _unit;
    if (_maxDist == 300) then {
        _alpha = 20;
        if (_range > 80) then {_alpha = 30};
        if (_range > 150) then {_alpha = 45};
    };
    if (_range > _maxDist) then {_range = _maxdist};
    _v0 = sqrt(_range * 9.81 / sin (2 * _alpha));
    _v0x = cos _alpha * _v0;
    _v0z = sin _alpha * _v0;
    _throwDir = [_unit,_targetpos] call BIS_fnc_dirTo;
    _flyDirSin = sin _throwDir;
    _flyDirCos = cos _throwDir;
    _vel = [_flyDirSin * _v0x,_flyDirCos * _v0x, _v0z];
    _vel
};

pl_friendly_check = {
    params ["_unit", "_pos"];

    // _m = createMarker [str (random 1), _pos];
    // _m setMarkerType "mil_dot";
    // _m setMarkerColor "colorGreen";
    
    _distance = _unit distance2D _pos; 
    _allies = (_pos nearEntities [["Man", "Car", "Tank"], 30 + (_distance * 0.25)]) select {side _x == side _unit};
    // player sideChat str _allies;
    if !(_allies isEqualTo []) exitWith {true};
    false
};

pl_friendly_check_strict = {
    params ["_unit", "_pos"];

    // _m = createMarker [str (random 1), _pos];
    // _m setMarkerType "mil_dot";
    // _m setMarkerColor "colorGreen";
    _size = 35;
    
    _distance = _unit distance2D _pos;
    _intervals = round (_distance / _size);
    _atkDir = _unit getDir _pos;
    _startPos = (getPos _unit) getPos [_size * 0.66, _atkDir];
    private _return = false;

    _debugMarkers = [];

    for "_i" from 1 to (_intervals + 1) do {
        _checkPos = _startPos getPos [_size * _i, _atkDir];
        _allies = (_checkPos nearEntities [["Man", "Car", "Tank"], _size]) select {side _x == side _unit and alive _x and !(captive _x)};

        // _m = createMarker [str (random 1), _checkPos];
        // _m setMarkerShape "ELLIPSE";
        // _m setMarkerBrush "SolidBorder";
        // _m setMarkerColor "colorGreen";
        // _m setMarkerSize [_size, _size];
        // _debugMarkers pushBack _m;

        if !(_allies isEqualTo []) exitWith {_return = true};

    };

    // [_debugMarkers] spawn {
    //     sleep 5;

    //     {
    //         deleteMarker _x;
    //     } forEach (_this#0);
    // };

    _return
};
// [cursorTarget, target_1] spawn pl_fire_ugl_at_target;

pl_friendly_check_excact = {
    params ["_unit", "_pos", "_area"];
    
    _allies = (_pos nearEntities [["Man", "Car", "Tank"], _area]) select {side _x == side _unit};
    // player sideChat str _allies;
    if !(_allies isEqualTo []) exitWith {true};
    false
};

pl_clear_obstacles = {
    params ["_pos", "_radius"];
    
    {
        if (!(canMove _x) or ({alive _x} count (crew _x)) <= 0) then {
            deleteVehicle _x;
        };
    } forEach (vehicles select {(_x distance2D _pos) < _radius});

    {
         deleteVehicle _x;
    } forEach (allDead select {(_x distance2D _pos) < _radius});
    // remove Fences
    {
        deleteVehicle _x;
    } forEach ((_pos nearObjects _radius) select {["fence", typeOf _x] call BIS_fnc_inString or ["barrier", typeOf _x] call BIS_fnc_inString or ["wall", typeOf _x] call BIS_fnc_inString or ["sand", typeOf _x] call BIS_fnc_inString});
    // remove Bunkers
    {
        deleteVehicle _x;;
    } forEach ((_pos nearObjects _radius) select {["bunker", typeOf _x] call BIS_fnc_inString});
    // remove wire
    {
        deleteVehicle _x;
    } forEach ((_pos nearObjects _radius) select {["wire", typeOf _x] call BIS_fnc_inString});
    // kill trees
    {
        _x setDamage 1;
    } forEach (nearestTerrainObjects [_pos, ["TREE", "SMALL TREE", "BUSH"], _radius, false, true]);
};

pl_is_apc = {
    params ["_vic"];
    // if (getText (configFile >> "CfgVehicles" >> typeOf _vic >> "textSingular") isEqualTo "APC") exitWith {true};

    _isAPCtr = {
        if ([toUpper _x, toUpper( typeOf _vic)] call BIS_fnc_inString) exitWith {true};
        false
    } forEach ["m113", "rhino", "M1126", "M1128", "M1130", "M1133", "M1135", "Boxer", "mtlb", "btr", "APC_Tracked_01_rcws", "APC_Wheeled_02_rcws"];
    _isAPCtr

};

pl_is_tank = {
    params ["_vic"];

    _isTank = {
        if ([toUpper _x, toUpper( typeOf _vic)] call BIS_fnc_inString) exitWith {true};
        false
    } forEach ["m1", "m1a1", "m1a2", "t55", "t62", "t64", "t72", "t80", "t90", "t14", "leopard", "challenger", "mbt", "tank", "m60", "m48", "m4"];
    _isTank
};


pl_get_caliber = {
    params ["_string"];

    if (isNil "_string") exitWith {0};
    private _caliber = "";
    private _numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];

    for "_i" from 0 to (count _string) - 1 do {
        private _c = _string select [_i, 2];
        if (_c == "mm") exitWith {
            for "_j" from (_i - 1) to 0  step -1 do {
                _num = _string select [_j, 1];
                if (_num in _numbers) then {
                    _caliber = _num + _caliber;
                };
            };
        };
    };
    if (_caliber == "" ) then {_caliber = "0"};
    parsenumber _caliber
};

pl_canMove = {
    params ["_vic"];

    if !(canMove _vic) exitWith {false};
    if (_vic getHitPointDamage "hitltrack" >= 0.95) exitWith {false};
    if (_vic getHitPointDamage "hitrtrack" >= 0.95) exitWith {false};
    if (_vic getHitPointDamage "hitengine" >= 0.95) exitWith {false};
    private _wheelCount = 0;

    {
        if (_vic getHitPointDamage _x >= 0.95) then {_wheelCount = _wheelCount + 1};
    } forEach ["hitlfwheel", "hitlf2wheel", "hitlbwheel", "hitlmwheel", "hitrbwheel", "hitrf2wheel", "hitrfwheel", "hitrmwheel"];

    if (_wheelCount > 2) exitWith {false};

    if (!alive (driver _vic) or ((lifeState (driver _vic)) isEqualto "INCAPACITATED")) exitWith {false};

    true
};



pl_has_cannon = {
    params ["_vic"];
    private _weapons = _vic weaponsTurret [0];

    if (_weapons isEqualTo []) exitWith {false};
    _return = {
        if (["CANNON", toUpper _x] call BIS_fnc_inString) exitWith {true};
        false
    } forEach _weapons;
    _return;
};

pl_is_ifv = {
    params ["_vic"];
    private _isIFVtr = false;
    if ([_vic] call pl_is_apc) exitWith {false};
    if (getText (configFile >> "CfgVehicles" >> typeOf _vic >> "textSingular") isEqualTo "IFV") exitWith {true};
    if (([_vic] call pl_has_cannon or ([(_vic weaponsTurret [0])#0] call pl_get_caliber) >= 20) and !(["mbt", typeOf _vic] call BIS_fnc_inString)) exitwith {true};
    _isIFVtr = {
        if ([toUpper _x, toUpper( typeOf _vic)] call BIS_fnc_inString) exitWith {true};
        false
    } forEach ["Puma", "m2a2", "bmp2", "bmp1", "ifv", "m2a1", "m2a3", "m2", "warrior", "marder", "cannon0", "bmp", "bmd"];
    _isIFVtr
};

pl_find_centroid_of_group = {
    params ["_group"];

    _units = (units _group) select {alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")};

    private _sumX = 0;
    private _sumY = 0;
    private _len = count _units;

    if (_len == 0) exitWith {getPos (leader _group)};

    {
        _sumX = _sumX + ((getPos _x)#0);
        _sumY = _sumY + ((getPos _x)#1);

    } forEach (_units select {(_x distance2D (leader _group)) < 250});

    // _m = createMarker [str (random 2), [_sumX / _len, _sumY / _len, (getPosASL (leader _group))#2]];
    // _m setMarkerType "mil_dot";

    [_sumX / _len, _sumY / _len, (getPosASL (leader _group))#2] 
};

// 0 = [group player] call pl_find_centroid_of_group;

pl_find_centroid_of_groups = {
    params ["_groups"];

    if (_groups isEqualTo []) exitWith {[]};

    private _sumX = 0;
    private _sumY = 0;
    private _len = count _groups;

    {
        _sumX = _sumX + ((getPos (leader _x))#0);
        _sumY = _sumY + ((getPos (leader _x))#1);

    } forEach _groups;

    [_sumX / _len, _sumY / _len, (getPosASL (leader (_groups#0)))#2] 
};

pl_find_centroid_of_units = {
    params ["_units"];

    private _sumX = 0;
    private _sumY = 0;
    private _len = count _units;

    {
        _sumX = _sumX + ((getPos _x)#0);
        _sumY = _sumY + ((getPos _x)#1);

    } forEach _units;

    // _m = createMarker [str (random 2), [_sumX / _len, _sumY / _len, (getPosASL (leader _group))#2]];
    // _m setMarkerType "mil_dot";

    [_sumX / _len, _sumY / _len, getPosASL (_units#0)#2] 
};

pl_find_centroid_of_points = {
    params ["_points"];

    private _sumX = 0;
    private _sumY = 0;
    private _len = count _points;

    {
        _sumX = _sumX + _X#0;
        _sumY = _sumY + _x#1;

    } forEach _points;

    [_sumX / _len, _sumY / _len, 0]
};

pl_countdown_on_map = {
    params ["_time", "_addedTime", "_placePos", "_group", ["_color", pl_side_color]];
    private _m = createMarker [str (random 3), _placePos];
    _m setMarkerType "mil_dot";
    _m setMarkerSize [0.01, 0.01];
    _m setMarkerColor _color;
    private _interval = _addedTime / 100;
    private _n = 0;
    while {_time > time and (_group getVariable ["onTask", false])} do {
        _n = _n + 1;
        _m setMarkerText (format ["%1%2", _n,"%"]);
        sleep _interval;
    };

    deleteMarker _m;
};

//
// PX_fnc_stringReplace :: Replace substrings
// Author: Colin J.D. Stewart
// Usage: ["xxx is awesome, I love xxx!", "xxx", "Arma"] call PX_fnc_stringReplace;
//

pl_stringReplace = {
    params ["_str", "_find", "_replace"];
    
    private _return = "";
    private _len = count _find;    
    private _pos = _str find _find;

    while {(_pos != -1) && (count _str > 0)} do {
        _return = _return + (_str select [0, _pos]) + _replace;
        
        _str = (_str select [_pos+_len]);
        _pos = _str find _find;
    };    
    _return + _str;
};

pl_get_grenade_type = {
    params ["_unit"];

    _loadOut = getUnitLoadout _unit;
    _uniform = _loadOut#3;
    _vest = _loadOut#4;
    _bag = _loadOut#5;

    _complete = [];
    if !(_uniform isEqualto []) then {_complete = _complete + (_uniform#1)};
    if !(_vest isEqualto []) then {_complete = _complete + (_vest#1)};
    if !(_bag isEqualto []) then {_complete = _complete + (_bag#1)};

    _grenadeType = "";

    _grenadeType = {
        if ((([_x#0] call BIS_fnc_itemType)#1) isEqualTo "Grenade") exitWith {_x#0};
        ""
    } forEach _complete;

    _grenadeType
};

pl_get_grenade_ammo = {
    params ["_unit"];

    _grenadeType = [_unit] call pl_get_grenade_type;
    if (_grenadeType isEqualto "") exitWith {0};
    {_x isEqualTo _grenadeType} count (magazines _unit)
};

pl_team_grenade_swap = {
    params ["_teamA", "_teamC"];
    {
        _unitA = _x;
        _grenadeTypeA = [_unitA] call pl_get_grenade_type;
        _ammoCountA = [_unitA] call pl_get_grenade_ammo;

        if (_ammoCountA <= 0) then {
            {
                _unitC = _x;
                _grenadeTypeC = [_unitC] call pl_get_grenade_type;
                _ammoCountC = [_unitC] call pl_get_grenade_ammo;

                if (_ammoCountC > 0) then {
                    _unitA addItem _grenadeTypeC;
                    _unitC removeItem _grenadeTypeC;
                };
            } forEach _teamC;
        };
    } forEach _teamA;
};

pl_get_grenade_muzzle = {
    // AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
    params ["_grenade"];
    _muzzleRaw = (format ["%1 in (getArray (_x >> 'Magazines'))", str _grenade]) configClasses (configfile >> "CfgWeapons" >> "Throw");

    _muzzleRawArray = ((str(_muzzleRaw#0)) splitString "/");
    _muzzle = _muzzleRawArray select ((count _muzzleRawArray) - 1);

    _muzzle
};

// _m = createMarker [str (random 1), [g1] call pl_find_centroid_of_group];
// _m setMarkerType "mil_marker";


pl_get_vistool_pos = {
    params [["_start", []], ["_range", 2000], ["_accuracy", 2], ["_heightOver", 2], ["_ignoreObj", objNull]];
    private ["_end", "_lastVis"];

    if (_start isEqualTo []) then {
        _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        _start = [_mPos#0, _mPos#1, _heightOver];
    } else {
        _start = [_start#0,_start#1,_heightOver];
    };

    _start = ATLToASL _start;
    private _polyPath = [];
    private _polyLinePath = [];
    private _j = 0;

    // for "_i" from 0 to 719 step 0.5 do {
    for "_i" from 0 to 359 step _accuracy do {
        _end = _start vectorAdd [(sin _i) * _range, (cos _i) * _range, 0];
        // _end = _start getPos [2000, _i] vectorAdd [0,0,5];
        _vis = (lineIntersectsSurfaces [_start, _end, _ignoreObj, _ignoreObj, true, 1, "GEOM", "FIRE"]);

        if !(_vis isEqualTo []) then {
            _lastVis = _vis;
            _j = 0;
            while {_j < 30} do {
                _end = _end vectorAdd [100, 100, 5];
                _vis = (lineIntersectsSurfaces [_start, _end, _ignoreObj, _ignoreObj, true, 1, "GEOM", "FIRE"]);
                if (_vis isEqualTo []) exitWith {
                    _polyPath pushBack (_lastVis#0#0);
                    _polyLinePath pushBack (_lastVis#0#0#0);
                    _polyLinePath pushBack (_lastVis#0#0#1);
                };
                _j = _j + 1;
                _lastVis = _vis;
            };

            if (_j >= 30) then {
                _polyPath pushBack (_vis#0#0);
                _polyLinePath pushBack (_vis#0#0#0);
                _polyLinePath pushBack (_vis#0#0#1);
            };
        } else {
            _polyPath pushBack _end;
            _polyLinePath pushBack _end#0;
            _polyLinePath pushBack _end#1;
        };
    };
    // sleep 0.2;
    [_polyPath, _polyLinePath]
};

// #ChatGpt
pl_isPointInPolygon = {
    params ["_point", "_polygon"];
    
    private _x = _point select 0;
    private _y = _point select 1;
    private _inside = false;
    
    private _n = count _polygon;
    private _j = _n - 1;
    
    for "_i" from 0 to (_n - 1) do {
        private _xi = (_polygon select _i) select 0;
        private _yi = (_polygon select _i) select 1;
        private _xj = (_polygon select _j) select 0;
        private _yj = (_polygon select _j) select 1;
        
        if ((_yi < _y && _yj >= _y) || (_yj < _y && _yi >= _y)) then {
            private _x_intersect = _xi + (_y - _yi) / (_yj - _yi) * (_xj - _xi);
            if (_x_intersect < _x) then {
                _inside = !_inside;
            };
        };
        _j = _i;
    };

    _inside
};


pl_vision_tool_enabled = false;

pl_vision_tool = {
    private ["_lineLMarker", "_linePath"];

    if (pl_vision_tool_enabled) exitwith {pl_vision_tool_enabled = false};

    pl_vision_tool_enabled = true;

    // while {pl_vision_tool_enabled} do {

    //  _linePath = [] call pl_get_intersects;
    //  _lineMarker = createMarker [str (random 3), [0,0,0]];
    //  _lineMarker setMarkerShape "POLYLINE";
    //  _lineMarker setMarkerPolyline _linePath;
    //  _lineMarker setMarkerColor "colorGreen";

    //  sleep 0.25;
    //  deleteMarker _lineMarker;


    // };
};

pl_get_laser_target = {
    params ["_side"];

    private _r = "";

    switch (_side) do { 
        case east : {_r = "LaserTargetE"}; 
        case west : {_r = "LaserTargetW"};
        case independent : {_r = "LaserTargetI"};  
        default {_r = "LaserTargetW"}; 
    };

    _r
};

