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

pl_join_hc_group = {
    params ["_group"];
    private ["_targetGroup"];

    if (visibleMap) then {
        _pos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        _targetGroup = group (nearestObject[_pos, "Man"]);
    }
    else
    {
        _target = cursorTarget;
        if (_target isKindOf "Man") then {
            if (side _target == playerSide) then {
                _targetGroup = group (_target);
            };
        };
    };

    (units _group) join _targetGroup;
};

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
    private ["_groupLen", "_largestGroup"];
    _groupLen = 0;
    _largestGroup = 0;
    {
        _len = count (units _x);
        if (_len > _groupLen) then {
            _largestGroup = _x;   
        };
    } forEach hcSelected player;
    {
        (units _x) joinSilent _largestGroup; 
    } forEach hcSelected player;
    // _leader = ["_largestGroup"] call pl_get_highest_rank;
    // _largestGroup selectLeader _leader;
};

pl_add_to_hc = {
    if !(pl_add_group_to_hc) then {
        pl_add_group_to_hc = true;
        while {pl_add_group_to_hc} do {
            hintSilent "SELECT GROUP TO ADD";
            sleep 1;
        }
    }
    else
    {
        pl_add_group_to_hc = false;
    };
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

// [] call pl_merge_hc_groups;