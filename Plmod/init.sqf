
execVM "Plmod\pl_ai_fnc.sqf";
execVM "Plmod\pl_ammoBearerReload_fnc.sqf";
execVM "Plmod\pl_sitrep_fnc.sqf";
execVM "Plmod\pl_attack_fnc.sqf";
execVM "Plmod\pl_rearm_fnc.sqf";
execVM "Plmod\pl_map_icons.sqf";
execVM "Plmod\pl_building_fnc.sqf";
execVM "Plmod\pl_vehicle_fnc.sqf";
execVM "Plmod\pl_defence_fnc.sqf";
execVM "Plmod\pl_group_fnc.sqf";
execVM "Plmod\pl_heal_fnc.sqf";
execVM "Plmod\pl_misc_fnc.sqf";


addMissionEventHandler ["GroupIconClick", {
    params [
        "_is3D", "_group", "_waypointId",
        "_mouseButton", "_posX", "_posY",
        "_shift", "_control", "_alt"];

    if (side _group == playerSide) then {
        if (pl_add_group_to_hc) then {
            player hcSetGroup [_group];
            pl_add_group_to_hc = false;
        };
    };
}];



addMissionEventHandler ["EntityKilled",{
    params ["_killed", "_killer", "_instigator", "_useEffects"];
    if !((side group _killed) isEqualto playerside)exitwith{};
    if (vehicle _killed != _killed) exitWith{};
    _leader = leader (group _killed);
    _unitMos = getText (configFile >> "CfgVehicles" >> typeOf _killed >> "displayName");
    _unitName = name _killed;
    [_killed] spawn pl_draw_kia;

    _leader sideChat format ["%1 is K.I.A, over", _unitMos];
}];

