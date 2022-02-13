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

pl_bounding_move_team = {
    params ["_team", "_movePosArray", "_wpPos", "_group", "_unitPos"];

    for "_i" from 0 to (count _team) - 1 do {
        _unit = _team#_i;
        _movePos = _movePosArray#_i;
        if ((_unit distance2D _movePos) > 3) then {
            if (currentCommand _unit isNotEqualTo "MOVE" or (speed _unit) == 0) then {
                doStop _unit;
                [_unit, true] call pl_enable_force_move;
                _unit setUnitPos "UP";
                _unit doMove _movePos;
            };
        }
        else
        {
            doStop _unit;
            [_unit, false] call pl_enable_force_move;
            _unit disableAI "PATH";
            _unit setUnitPos _unitPos;
        };
    };
    if (({currentCommand _x isEqualTo "MOVE"} count (_team select {alive _x and !(_x getVariable ["pl_wia", false])})) == 0 or ({(_x distance2D _wpPos) < 15} count _team > 0) or (waypoints _group isEqualTo [])) exitWith {true};
    false
};

pl_quick_suppress = {
    params ["_unit", "_targetPos"];

    _vis = lineIntersectsSurfaces [eyePos _unit, _targetPos, _unit, vehicle _unit, true, 1];

    if !(_vis isEqualTo []) then {
        _targetPos = (_vis select 0) select 0;
    };
    
    if ((_targetPos distance2D _unit) > 25 and !([_targetPos] call pl_friendly_check)) then {
        _unit doSuppressiveFire _targetPos;
    };

};

pl_enable_force_move = {
    params ["_unit", "_state"];
    if (_state) then {
        _unit enableAI "PATH";
        _unit disableAI "COVER";
        _unit disableAI "AUTOTARGET";
        _unit disableAI "TARGET";
        _unit disableAI "SUPPRESSION";
        _unit disableAI "WEAPONAIM";
        _unit setUnitCombatMode "BLUE";
    }
    else
    {
        _unit enableAI "COVER";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "WEAPONAIM";
        _unit setUnitCombatMode "YELLOW";
    };
};

pl_position_reached_check = {
    params ["_unit", "_movePos", ["_randomise", true]];
    private ["_counter"];

    _counter = _unit getVariable ["pl_reached_counter", 0];
    if ((_unit distance2D _movePos) > 2) then {
        if (currentCommand _unit isNotEqualTo "MOVE" or (speed _unit) == 0) then {
            _counter = _counter + 1;
            doStop _unit;
            _unit setUnitPosWeak "UP";
            if (_randomise) then {
                _movePos = [-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd _movePos;
            };
            _unit doMove _movePos;
        };
    };

    if (((_unit distance2D _movePos) < 2 and currentCommand _unit isNotEqualTo "MOVE") or _counter >= 8) exitWith {true};
    _unit setVariable ["pl_reached_counter", _counter];
    false
};


pl_is_forest = {
    params ["_pos"];

    _trees = nearestTerrainObjects [_pos, ["Tree"], 50, false, true];

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
    _pos = AGLToASL _pos;
    if (lineIntersects [_pos, _pos vectorAdd [0, 0, 10]]) exitWith {true};
    false
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