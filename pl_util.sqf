pl_substr = {
    private ["_find", "_string", "_find_len", "_str", "_found", "_pos"];
    _find = _this select 0;
    _string = toArray (_this select 1);
    _find_len = count toArray _find;
    _str = [] + _string;
    _str resize _find_len;
    _found = false;
    _pos = 0;
    for "_i" from _find_len to count _string do {
        if (toString _str == _find) exitWith {_found = true};
        _str set [_find_len, _string select _i];
        _str set [0, "x"];
        _str = _str - ["x"];
        _pos = _pos + 1;
    };
    if (!_found) then {
        _pos = -1;
    };
    _pos
};

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
      if ((["HE_", _x] call pl_substr) >= 0) then {_he_round = _x};
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
      if ((["AP", _x] call pl_substr) >= 0) then {_ap_round = _x};
      if ((["SABOT", _x] call pl_substr) >= 0) then {_ap_round = _x};
    } foreach (magazines _unit);

    if !(_ap_round isEqualTo "") then {
        if ([_unit, _ap_round] call pl_has_ammo > 0) then {
            [_unit, _ap_round] call pl_load_mag;
        };
    };
};