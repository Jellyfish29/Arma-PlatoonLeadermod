// pl_get_highest_rank = {
//     params ["_group"];
//     _rank = 0;
//     _highestRank = 0;
//     {
//         if ((rankId _x) > _rank) then {
//             _highestRank = _x;
//         };
//     } forEach (units _group);
//     _highestRank;
// };

pl_add_group_to_hc = false;

// pl_join_hc_group = {
//     params ["_group"];
//     private ["_targetGroup"];

//     if (visibleMap) then {
//         _pos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//         _targetGroup = group (nearestObject[_pos, "Man"]);
//     }
//     else
//     {
//         _target = cursorTarget;
//         if (_target isKindOf "Man") then {
//             if (side _target == playerSide) then {
//                 _targetGroup = group (_target);
//             };
//         };
//     };

//     _group setVariable ["onTask", false];
//     sleep 0.25;

//     (units _group) join _targetGroup;
// };

// [hcSelected player select 0] spawn pl_join_hc_group;

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
    params ["_group", ["_type", "inf"]];

    _cIcon = _group getVariable ["pl_custom_icon", ""];
    _prefix = [_group] call pl_get_side_prefix;
    _group setVariable ["pl_show_info", true];
    player hcSetGroup [_group];
    if !(_cIcon isEqualTo "") then {
        _group addGroupIcon [_cIcon];
    }
    else
    {
        _group addGroupIcon [format ["%1_%2", _prefix, _type]]; 
    };
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
};

pl_spawn_cam = {
    [leader (hcSelected player select 0)] call pl_remote_camera_in;
};

pl_remote_camera_out = {

    player switchCamera (player getVariable ["pl_camera_mode", "INTERNAL"]);  
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
   if (pl_enable_voice_radio) then {

        private _answerVoiceLine = "";
        switch (_message) do { 
            case "confirm" : {_answerVoiceLine = selectRandom ["SentConfirmAttack", "SentConfirmOther", "SentSupportConfirm"]};
            case "suppress" : {_answerVoiceLine = selectRandom ["SentConfirmSuppress"]}; 
            case "contact" : {_answerVoiceLine = selectRandom ["SentEnemyContact", "SentOpenFireInCombat"]};
            case "kia" : {_answerVoiceLine = "SentUnitKilled"}; 
            case "destroyed" : {_answerVoiceLine = "SentObjectDestroyedUnknown"}; 
            case "damaged" : {_answerVoiceLine = "SentDammageCritical"}; 
            case "atk_complete" : {_answerVoiceLine = "SentClear"}; 
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

_playerIcon = format ["%1_%2", [group player] call pl_get_side_prefix, "hq"];
(group player) setVariable ["pl_custom_icon", _playerIcon];



