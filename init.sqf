
execVM "Plmod\pl_settings.sqf";
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
execVM "Plmod\pl_support_fnc.sqf";
execVM "Plmod\pl_repair_fnc.sqf";
execVM "Plmod\pl_static_fnc.sqf";
execVM "Plmod\pl_menus_fnc.sqf";


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


pl_vehicle_destroyed_report_cd = 0;

addMissionEventHandler ["EntityKilled",{
    params ["_killed", "_killer", "_instigator", "_useEffects"];
    if ((side group _killed) isEqualto playerside) then {
        if (vehicle _killed == _killed and _killed isKindOf "Man") then {
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
        }
        else
        {
            if (time >= pl_vehicle_destroyed_report_cd) then {
                _vic = vehicle _killed;
                _vicName = getText (configFile >> "CfgVehicles" >> typeOf _vic >> "displayName");
                player sideChat format ["%1 was destroyed", _vicName];
                pl_vehicle_destroyed_report_cd = time + 3;
            };
        };
    }
    else
    {
        if (_killed isEqualTo (leader (group _killed))) then {
            [_killed, _killer, (group _killed)] spawn pl_enemy_destroyed_report;
        };
    };
}];



// 
// pl_medic_cls_names = ["B_medic_F", "O_medic_F", "I_medic_F", "I_E_medic_F"];
// 





