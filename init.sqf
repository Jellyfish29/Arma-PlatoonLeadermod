
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
execVM "Plmod\pl_3d_icon_fnc.sqf";
execVM "Plmod\pl_disable_hc_elements.sqf";

// setGroupIconsVisible [true,true]; 

addMissionEventHandler ["GroupIconClick", {
    params [
        "_is3D", "_group", "_waypointId",
        "_mouseButton", "_posX", "_posY",
        "_shift", "_control", "_alt"];
    private ["_vic", "_vicGroup"];

    if (side _group == playerSide) then {
        playsound "beep";
        if ((vehicle (leader _group)) != (leader _group)) then {
            _vic = vehicle (leader _group);
            // player sideChat str _vic;
            _vicGroup = group (driver _vic);
            // player sideChat str _vicGroup;
            [_vicGroup] spawn {
                params ["_vicGroup"];
                sleep 0.35;
                player hcSelectGroup [_vicGroup];
            };
        };
        if (pl_add_group_to_hc) then {
            if (_group getVariable ["pl_not_addalbe", false]) exitWith {pl_add_group_to_hc = false; hint "Group cant be added!"};
            [_group ] spawn pl_add_to_hc_execute;
            [_group] spawn pl_set_up_ai;
        };
        if (missionNamespace getVariable ["pl_select_formation_leader", false]) then {
            missionNamespace setVariable ["pl_formation_leader", _group];
            missionNamespace setVariable ["pl_select_formation_leader", false];
            if (_shift) then {
                missionNamespace setVariable ["pl_formation_cancel", true];
            }
            else 
            {
                missionNamespace setVariable ["pl_formation_cancel", false]
            };
        };
        if (missionNamespace getVariable ["pl_transfer_medic_enabled", false]) then {
            missionNamespace setVariable ["pl_transfer_medic_enabled", false];
            missionNamespace setVariable ["pl_transfer_medic_group", _group];
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

            playSound "beep";
            _leader sideChat format ["%1: %2 K.I.A", groupId (group _killed), _unitMos];
        };
        // else
        // {
        //     if (time >= pl_vehicle_destroyed_report_cd) then {
        //         _vic = vehicle _killed;
        //         _vicName = getText (configFile >> "CfgVehicles" >> typeOf _vic >> "displayName");
        //         player sideChat format ["%1 was destroyed", _vicName];
        //         pl_vehicle_destroyed_report_cd = time + 3;
        //     };
        // };
    }
    else
    {
        if (_killed isEqualTo (leader (group _killed))) then {
            [_killed, _killer, (group _killed)] spawn pl_enemy_destroyed_report;
        };
    };
}];

pl_vehicle_group_check = {
    private ["_vicArray"];
    {       
        _vicArray = [];
        {
            if (vehicle _x != _x) then {
                0 = _vicArray pushBackUnique (vehicle _x);
            };
        } forEach (units _x);

        if ((count _vicArray) > 1) exitWith {hint "There are Groups with more then ONE vehicle! Grouped up Vehicles are not recomended to use with High Command as it will lead to uncontrollable and unintended AI behaviour."};

    } forEach (allGroups select {side _x isEqualto playerSide});  
};

[] call pl_vehicle_group_check;





