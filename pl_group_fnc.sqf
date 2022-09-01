addMissionEventHandler ["GroupIconClick", {
    params [
        "_is3D", "_group", "_waypointId",
        "_mouseButton", "_posX", "_posY",
        "_shift", "_control", "_alt"];
    private ["_vic", "_vicGroup"];

    if (side _group == playerSide) then {
        // if (pl_enable_beep_sound) then {playSound "radioin"};
        // if ((vehicle (leader _group)) != (leader _group)) then {
        //     _vic = vehicle (leader _group);
        //     // player sideChat str _vic;
        //     _vicGroup = group (driver _vic);
        //     // player sideChat str _vicGroup;
        //     [_vicGroup] spawn {
        //         params ["_vicGroup"];
        //         sleep 0.35;
        //         player hcSelectGroup [_vicGroup];
        //     };
        // };
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

addMissionEventHandler ["HCGroupSelectionChanged", {
    params ["_group", "_isSelected"];

    if (_isSelected) then {
        // if (pl_enable_beep_sound) then {playSound "beep"};
        if (pl_enable_beep_sound) then {playSound "radioina"};
    } else {
        if (pl_enable_beep_sound) then {playSound "radioutc"};
    };
}];


pl_vehicle_destroyed_report_cd = 0;

addMissionEventHandler ["EntityKilled",{
    params ["_killed", "_killer", "_instigator", "_useEffects"];
    if ((side group _killed) isEqualto playerside) then {
        if (vehicle _killed == _killed) then {
            _leader = leader (group _killed);
            _unitMos = getText (configFile >> "CfgVehicles" >> typeOf _killed >> "displayName");
            _unitName = name _killed;
            _killed setVariable ["pl_wia", false];
            [_killed] spawn pl_draw_kia;
            _group = group _killed;
            if (pl_enable_map_radio) then {[_group, format ["...%1 KIA", _unitMos], 15] call pl_map_radio_callout};
            [_group, "kia", random 2] call pl_voice_radio_answer;
            _mags = _group getVariable "magCountAllDefault";
            _mag = _group getVariable "magCountSoloDefault";
            _mags = _mags - _mag;
            _group setVariable ["magCountAllDefault", _mags];

            // // reinforcements
            // _type = typeOf _killed;
            // _loadout = _killed getVariable "pl_loadout";
            // _killedUnits = _group getVariable "pl_killed_units";
            // _killedUnits pushBack [_type, _loadout];
            // _group setVariable ["pl_killed_units", _killedUnits];

            // if (pl_enable_beep_sound) then {playSound "beep"};
            // _leader sideChat format ["%1: %2 K.I.A", groupId _group, _unitMos];
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
            if !((getNumber (configFile >> "CfgVehicles" >> typeOf (vehicle _killer) >> "artilleryScanner")) == 1) then {
                [_killed, _killer, (group _killed)] spawn pl_enemy_destroyed_report;
            };
        };
    };
}];

pl_set_unit_pos = {
    params ["_group", "_stance"];

    {
        _x setUnitPos _stance;
    } forEach (units _group);
};


pl_add_group_to_hc = false;

pl_split_hc_group = {
    params ["_group"];
    {
        if (_x != (leader _group)) then {
            _newGroup = createGroup [playerSide, true];
            [_x] joinSilent _newGroup;
            player hcSetGroup [_newGroup];
        };
    } forEach (units _group);
};

// [hcSelected player select 0] spawn pl_split_hc_group;

pl_merge_hc_groups = {
    private ["_groupLen", "_largestGroup", "_groups"];
    _groupLen = 0;
    _largestGroup = grpNull;
    _groups = [];
    {
        _x setVariable ["onTask", false];
        _groups pushBack _x;
        _len = count (units _x);
        if (_len > _groupLen) then {
            _largestGroup = _x;
            _groupLen = _len;  
        };
    } forEach hcSelected player;
    sleep 0.25;
    {
        if !(_x getVariable ["pl_not_addalbe", false]) then {
            (units _x) joinSilent _largestGroup;
        };
    } forEach _groups;
    sleep 0.1;
    [_largestGroup] call pl_reset;
};

pl_add_to_hc = {
    if !(pl_add_group_to_hc) then {
        pl_add_group_to_hc = true;
        while {pl_add_group_to_hc} do {
            hintSilent "SELECT GROUP TO ADD";
            sleep 1;
        };
        hintSilent "";
    }
    else
    {
        pl_add_group_to_hc = false;
    };
};

pl_add_to_hc_execute = {
    params ["_group"];

    _group setVariable ["onTask", false];
    sleep 0.25;

    player hcSetGroup [_group];
    [_group] spawn pl_set_up_ai;
    pl_add_group_to_hc = false;
};

pl_remove_from_hc = {
    params ["_group"];
    player hcRemoveGroup _group;
};

pl_spawn_remove_hc = {
    {
        [_x] spawn pl_remove_from_hc;
    } forEach hcSelected player;  
};

pl_create_hc_group = {
    private ["_group"];

    _group = createGroup [playerSide, true];
    {
        [_x] join _group;
    } forEach (groupSelectedUnits player);
    player hcSetGroup [_group];
    [_group] spawn pl_set_up_ai;
};

// [] call pl_create_hc_group;

// [] call pl_merge_hc_groups;
pl_get_side_prefix = {
    params ["_group"];
    private ["_prefix"];
    _side = side _group;

    switch (_side) do { 
        case west : {_prefix = "b"}; 
        case east : {_prefix = "o"};
        case independent : {_prefix = "n"}; 
        default {_prefix = "b"}; 
    };
    _prefix
};

pl_change_group_icon = {
    params ["_group", "_type"];
    private ["_prefix"];

    _prefix = [_group] call pl_get_side_prefix;
    _typeStr = format ["%1_%2", _prefix, _type];
    _group setVariable ["pl_custom_icon", _typeStr];
    clearGroupIcons _group;
    _group addGroupIcon [_typeStr];      
};

pl_hide_group_icon = {
    params ["_group"];

    _group setVariable ["pl_show_info", false];
    player hcRemoveGroup _group;
    clearGroupIcons _group;
};

pl_show_group_icon = {
    params ["_group", ["_type", "inf"], ["_setHc", true]];

    _cIcon = _group getVariable ["pl_custom_icon", ""];
    _prefix = [_group] call pl_get_side_prefix;
    _group setVariable ["pl_show_info", true];
    if !(_cIcon isEqualTo "") then {
        _group addGroupIcon [_cIcon];
    } else {
        _group addGroupIcon [format ["%1_%2", _prefix, _type]]; 
    };
    if (_setHc) then {
        player hcSetGroup [_group];
    };
};

pl_change_inf_icons = {
    params ["_group"];

    if (_group == (group player)) exitWith {};

    private _size = "s";
    if ((count (units _group)) < 6) then {_size = "t"};

    _icon = format ["f_%1_inf_pl", _size];

    private _engineers = 0;
    private _medics = 0;
    {
        if (_x getUnitTrait "explosiveSpecialist" or _x getUnitTrait "engineer") then {
            _engineers = _engineers + 1;
        };
        if (_x getUnitTrait "medic") then {
            _medics = _medics + 1;
        };
    } forEach (units _group);

    if (_engineers >= 2) then {_icon = format ["f_%1_eng_pl", _size]};
    if (_medics >= 2) then {
        _icon = format ["f_%1_med_pl", _size];
        _group setVariable ["pl_set_as_medical", true];
    };

    [_group, _icon] call pl_change_group_icon;
};

pl_hc_mech_inf_icon_changer = {
    params ["_group"];
    private ["_tester", "_unitText", "_unitSide", "_sideLetter", "_groupIcon"];

    private _tester = vehicle (leader _group);

    private _unitText = getText (configFile >> "CfgVehicles" >> typeOf _tester >> "textSingular");

    switch (playerSide) do { 
        case west : {_sideLetter = "b"}; 
        case east : {_sideLetter = "o"};
        case resistance : {_sideLetter = "n"};
        default {_sideLetter = "b"}; 
    };

    private _type = typeOf _tester;

    private _change = false; 
    if (["m113", _type] call BIS_fnc_inString) then {_change = true};
    if (["m2a2", _type] call BIS_fnc_inString) then {_change = true};
    if (["m2a3", _type] call BIS_fnc_inString) then {_change = true};
    if (["ifv", _type] call BIS_fnc_inString) then {_change = true};
    if (["apc", _type] call BIS_fnc_inString) then {_change = true};

    if ((_unitText isEqualTo "APC" or _change) and !(_tester isKindOf "Car")) then { 
        _group setVariable ["MARTA_customIcon", [format ["%1_mech_inf", _sideLetter]]];
    };

};

pl_delete_group = {
    params ["_group"];

    {
        deleteVehicle _x;
    } forEach (units _group);
    deleteGroup _group;
};

pl_select_group = {
    // select hcGroup form player cursorTraget

    _target = cursorTarget;
    _group = group _target;
    player hcSelectGroup [_group];
    sleep 2;
};


pl_remote_camera_in = {
    params ["_leader"];

    player setVariable ["pl_camera_mode", cameraView];
    _leader switchCamera "GROUP";
    openMap [false, false];
    // [getPos _leader] spawn pl_open_tac_forced;

};

pl_spawn_cam = {
    [leader (hcSelected player select 0)] call pl_remote_camera_in;
};

pl_remote_camera_out = {

    player switchCamera (player getVariable ["pl_camera_mode", "INTERNAL"]);
    // [] spawn pl_open_tac_map;
};

pl_add_all_groups = {
    {
        _x setVariable ["pl_show_info", true];
        player hcSetGroup [_x];
    } forEach (allGroups select {side (leader _x) == playerSide});
};

pl_hard_unstuck = {
    params ["_group"];

    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _pos = getPos _vic findEmptyPosition [35, 60, typeOf _vic];
        _vic setVehiclePosition [_pos, [], 0, "NONE"];
    }
    else
    {
        {
            _pos = getPos _x findEmptyPosition [35, 300, typeOf _x];
            _x setVehiclePosition [_pos, [], 0, "NONE"];
            _x switchMove "";
        } forEach (units _group);
    };
};

pl_enable_voice_radio = true;
pl_voice_radio_answer = {
    params ["_group", "_message", ["_delay", 1]];
   //Confrim Oeder: SentConfirmAttack, SentConfirmOther,SentSupportConfirm
   //Confirm Suppress: SentConfirmSuppress
   // Contact: SentEnemyContact, SentOpenFireInCombat, SentOpenFire
   // Destroyed Enemy: SentObjectDestroyedUnknown
   // own KIA: SentUnitKilled
   // vic damaged: SentDammageCritical
   // Attack completed: SentClear
   // panic: SentEndangered
   if (pl_enable_voice_radio) then {

        private _answerVoiceLine = "";
        switch (_message) do { 
            case "confirm" : {_answerVoiceLine = selectRandom ["SentConfirmAttack", "SentConfirmOther", "SentSupportConfirm"]};
            case "suppress" : {_answerVoiceLine = selectRandom ["SentConfirmSuppress"]}; 
            case "contact" : {_answerVoiceLine = selectRandom ["SentEnemyContact", "SentOpenFireInCombat"]};
            case "kia" : {_answerVoiceLine = selectRandom ["SentUnitKilled", "SentUnitKilled", "SentEndangered"]}; 
            case "destroyed" : {_answerVoiceLine = "SentObjectDestroyedUnknown"}; 
            case "damaged" : {_answerVoiceLine = selectRandom ["SentDammageCritical", "SentEndangered"]}; 
            case "atk_complete" : {_answerVoiceLine = "SentClear"};
            case "attack" : {_answerVoiceLine = "SentNotifyAttack"};
            case "wia" : {_answerVoiceLine = "SentHealthCritical"};
            default {_answerVoiceLine = ""};
        };

        [_group, _answerVoiceLine, _delay] spawn {
            params ["_group", "_answerVoiceLine", "_delay"];
            sleep _delay;
            // playsound "radionoise3";
            // playsound "radioina";
            // sleep 0.5;
            (leader _group) sideRadio _answerVoiceLine;
            // sleep 1.5;
            // playsound "radiout";
        };

   };
};

// pl_stringReplace = {
//     params["_str", "_find", "_replace"];
    
//     private _return = "";
//     private _len = count _find;    
//     private _pos = _str find _find;

//     while {(_pos != -1) && (count _str > 0)} do {
//         _return = _return + (_str select [0, _pos]) + _replace;
        
//         _str = (_str select [_pos+_len]);
//         _pos = _str find _find;
//     };    
//     _return + _str;
// };



pl_change_to_vic_symbols = {
    params ["_group", ["_force", false]];

    sleep 1;

    if (vehicle (leader _group) != leader _group) then {
        private _vic = vehicle (leader _group);

        if (_group == group player and !_force) exitWith {};
        if (_vic isKindOf "Air" and !_force) exitWith {};
        if ((getNumber (configFile >> "CfgVehicles" >> typeOf _vic >> "artilleryScanner")) == 1 and !_force) exitwith {};
        if ((((assignedVehicleRole (leader _group)) select 0) isEqualTo "cargo" or ((assignedVehicleRole (leader _group)) select 0) isEqualTo "turret") and (leader _group) != commander _vic and (leader _group) != gunner _vic and !_force) exitWith {};

        private _unitText = getText (configFile >> "CfgVehicles" >> typeOf _vic >> "textSingular");
        private _status = "f";
        private _symbolType = "b_inf";

        switch (_unitText) do {
            case "truck" : {
                _symbolType = format ["%1_%2_truck_pl", pl_side_prefix, _status];
                if (getNumber ( configFile >> "CfgVehicles" >> typeOf _vic >> "attendant" ) isEqualTo 1) then {_symbolType = format ["%1_%2_truck_med_pl", pl_side_prefix, _status]} else {
                if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 8) then {_symbolType = format ["%1_%2_truck_sup_pl", pl_side_prefix, _status]} else {
                if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportAmmo")) > 0) then {_symbolType = format ["%1_%2_truck_sup_pl", pl_side_prefix, _status]} else {
                if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair")) > 0) then {_symbolType = format ["%1_%2_truck_rep_pl", pl_side_prefix, _status]}}}};
            };
            case "car" : {
                _symbolType = format ["%1_%2_truck_pl", pl_side_prefix, _status];
                if (getNumber ( configFile >> "CfgVehicles" >> typeOf _vic >> "attendant" ) isEqualTo 1) then {_symbolType = format ["%1_%2_truck_med_pl", pl_side_prefix, _status]} else {
                if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 8) then {_symbolType = format ["%1_%2_truck_sup_pl", pl_side_prefix, _status]} else {
                if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportAmmo")) > 0) then {_symbolType = format ["%1_%2_truck_sup_pl", pl_side_prefix, _status]} else {
                if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair")) > 0) then {_symbolType = format ["%1_%2_truck_rep_pl", pl_side_prefix, _status]}}}};
            };
            case "MRAP" : {
                _symbolType = format ["%1_%2_truck_pl", pl_side_prefix, _status];
                if (getNumber ( configFile >> "CfgVehicles" >> typeOf _vic >> "attendant" ) isEqualTo 1) then {_symbolType = format ["%1_%2_truck_med_pl", pl_side_prefix, _status]};
            };
            case "alpha victor (MRAP)" : {
                _symbolType = format ["%1_%2_truck_pl", pl_side_prefix, _status];
                if (getNumber ( configFile >> "CfgVehicles" >> typeOf _vic >> "attendant" ) isEqualTo 1) then {_symbolType = format ["%1_%2_truck_med_pl", pl_side_prefix, _status]};
            }; 
            case "tank" : {
                _symbolType = format ["%1_%2_tank_pl", pl_side_prefix, _status];
                if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) >= 6 and !(["mbt", typeOf _vic] call BIS_fnc_inString)) then {
                    if ([_vic] call pl_is_ifv) then {
                        _symbolType = format ["%1_%2_ifvtr_pl", pl_side_prefix, _status];
                    } else {
                        _symbolType = format ["%1_%2_apctr_pl", pl_side_prefix, _status];
                    };
                } else {
                if (getNumber ( configFile >> "CfgVehicles" >> typeOf _vic >> "attendant" ) isEqualTo 1) then {_symbolType = format ["%1_%2_tank_med_pl", pl_side_prefix, _status]} else {
                if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair")) > 0) then {_symbolType = format ["%1_%2_tank_rep_pl", pl_side_prefix, _status]} else {
                if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportAmmo")) > 0) then {_symbolType = format ["%1_%2_tank_sup_pl", pl_side_prefix, _status]}}}};
            };
            case "APC" : {
                if ([_vic] call pl_is_ifv) then {
                    _symbolType = format ["%1_%2_ifvtr_pl", pl_side_prefix, _status];
                    if (_vic isKindOf "Car") then {_symbolType = format ["%1_%2_ifvwe_pl", pl_side_prefix, _status]};
                } else {
                    _symbolType = format ["%1_%2_apctr_pl", pl_side_prefix, _status];
                    if (_vic isKindOf "Car") then {_symbolType = format ["%1_%2_apcwe_pl", pl_side_prefix, _status]};
                };
            };
            default {_symbolType = format ["%1_%2_truck_pl", pl_side_prefix, _status]};
        };

        // if (_unitText == "tank" and !(["apctr", _symbolType] call BIS_fnc_inString) and !(["ifvtr", _symbolType] call BIS_fnc_inString)) then {
        //     if ([_vic] call pl_is_apc) then {_symbolType = format ["%1_%2_apctr_pl", pl_side_prefix, _status]};
        // };

        _group setVariable ["pl_custom_icon", _symbolType];
        clearGroupIcons _group;
        _group addGroupIcon [_symbolType];   
    };
};



{
    [_x] spawn pl_change_to_vic_symbols;
} forEach (allGroups select {side _x == playerSide});


_playerIcon = format ["%1_%2", [group player] call pl_get_side_prefix, "hq"];
(group player) setVariable ["pl_custom_icon", _playerIcon];


