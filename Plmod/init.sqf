
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
execVM "Plmod\pl_special_task_fnc.sqf";


addMissionEventHandler ["GroupIconClick", {
    params [
        "_is3D", "_group", "_waypointId",
        "_mouseButton", "_posX", "_posY",
        "_shift", "_control", "_alt"];

    if (side _group == playerSide) then {
        if (pl_add_group_to_hc) then {
            [_group ] spawn pl_add_to_hc_execute;
            [_group] spawn pl_set_up_ai;
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
    _killed setVariable ["pl_wia", false];
    [_killed] spawn pl_draw_kia;
    _group = group _killed;
    _mags = _group getVariable "magCountAllDefault";
    _mag = _group getVariable "magCountSoloDefault";
    _mags = _mags - _mag;
    _group setVariable ["magCountAllDefault", _mags];

    _leader sideChat format ["%1 is K.I.A, over", _unitMos];
}];



// 
// pl_medic_cls_names = ["B_medic_F", "O_medic_F", "I_medic_F", "I_E_medic_F"];
// 

// ["Ai Skill", "SLIDER",   ["Ai Skill slider",   "Ai Skill Level for Player Side"], "My Category", [0, 1, 1, 2], {pl_ai_skill = _this; [_this] call pl_set_ai_skill_option}] call CBA_fnc_addSetting;
// ["Radio Range", "EDITBOX",   ["Radio Range",   "Set the maximum range for ai info sharing"], "My Category", ["700"], {pl_radio_range = _this}] call CBA_fnc_addSetting;



