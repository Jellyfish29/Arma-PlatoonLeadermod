pl_change_inf_icons = {
    params ["_group"];

    private _size = "s";
    if ((count (units _group)) < 6) then {_size = "t"};

    _icon = format ["f_%1_inf_pl", _size];

    private _engineers = 0;
    {
        if (_x getUnitTrait "explosiveSpecialist" or _x getUnitTrait "engineer") then {
            _engineers = _engineers + 1;
        };
    } forEach (units _group);

    if (_engineers >= 2) then {_icon = format ["f_%1_eng_pl", _size]};

    [_group, _icon] call pl_change_group_icon;
};



{
    if ((vehicle (leader _x)) == (leader _x)) then {
        [_x] call pl_change_inf_icons;
    };
} forEach (allGroups select {side _x == playerSide});