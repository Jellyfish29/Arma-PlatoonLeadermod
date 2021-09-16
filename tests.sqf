pl_hc_mech_inf_icon_changer = {
    params ["_group"];
    private ["_tester", "_unitText", "_unitSide", "_sideLetter", "_groupIcon"];

    _tester = vehicle (leader _group);

    _unitText = getText (configFile >> "CfgVehicles" >> typeOf _tester >> "textSingular");

    switch (playerSide) do { 
        case west : {_sideLetter = "b"}; 
        case east : {_sideLetter = "o"};
        default {_sideLetter = "n"}; 
    };

    if (_unitText isEqualTo "APC" and !(_tester isKindOf "Car")) then { 
        _group setVariable ["MARTA_customIcon", [format ["%1_mech_inf", _sideLetter]]];
    };

};

{
    [_x] call pl_hc_mech_inf_icon_changer;
} forEach (allGroups select {side _x == playerSide});