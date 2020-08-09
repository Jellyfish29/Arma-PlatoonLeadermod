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
            _newGroup = createGroup [west, true];
            [_x] joinSilent _newGroup;
            player hcSetGroup [_newGroup]
        };
    } forEach (units _group);
};

// [hcSelected player select 0] spawn pl_split_hc_group;

pl_merge_hc_groups = {
    private ["_groupLen", "_largestGroup", "_groups"];
    _groupLen = 0;
    _largestGroup = 0;
    _groups = [];
    {
        _x setVariable ["onTask", false];
        _groups pushBack _x;
        _len = count (units _x);
        if (_len > _groupLen) then {
            _largestGroup = _x;   
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

