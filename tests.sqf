onGroupIconOverEnter {scriptname "HC: onGroupIconOverEnter";
    if !(hcshownbar) exitwith {};

    _is3D = _this select 0;
    _group = _this select 1;
    _wpID = _this select 2;
    _posx = _this select 3;
    _posy = _this select 4;
    _logic = player getvariable "BIS_HC_scope";

    if (_wpID < 0) then {
        _logic setvariable ["groupover",_group];
        _logic setvariable ["wpover",[grpnull]];
    } else {
        if (_group in hcallgroups player && !(_logic getvariable "LMB_hold")) then {
            _logic setvariable ["groupover",grpnull];
            _logic setvariable ["wpover",[_group,_wpID]];
        };
    };

};


pl_hc_icon_changer = {
    params ["_group"];
    private ["_tester", "_unitText", "_unitSide", "_sideLetter", "_groupIcon"];

    if (vehicle (leader _group) == leader _group) then {
        _tester = leader _group;
    }
    else
    {
        _tester = vehicle (leader _group);
    };

    _unitText = getText (configFile >> "CfgVehicles" >> typeOf _tester >> "textSingular");
    _vehicleClass = getText (configFile >> "CfgVehicles" >> typeOf _tester >> "VehicleClass");
    _unitSide = side _tester;

    if (_vehicleClass isEqualTo "Support") exitWith {};
    if (_tester isKindOf "Air") exitWith {};

    switch (_unitSide) do { 
        case west : {_sideLetter = "b"}; 
        case east : {_sideLetter = "o"};
        default {_sideLetter = "n"}; 
    };
        // case guer : {_sideLetter = "n"}; 

    switch (_unitText) do { 
        case "infantry" : {_groupIcon = format ["%1_inf", _sideLetter]};
        case "specop" : {_groupIcon = format ["%1_recon", _sideLetter]}; 
        case "APC" : {_groupIcon = format ["%1_mech_inf", _sideLetter]};
        case "tank" : {_groupIcon = format ["%1_armor", _sideLetter]};
        case "MRAP" : {_groupIcon = format ["%1_motor_inf", _sideLetter]};
        case "truck" : {_groupIcon = format ["%1_support", _sideLetter]};
        default {_groupIcon = format ["%1_inf", _sideLetter]}; 
    };
    _group removeGroupIcon 1;
    0 = _group addGroupIcon [_groupIcon, [0, 0]];

};
{
    [_x] call pl_hc_icon_changer;
} forEach (allGroups select {side _x == playerSide});



// {
//     _unitText = getText (configFile >> "CfgVehicles" >> typeOf _x >> "textSingular");
//     player sideChat _unitText;
// } forEach vehicles;