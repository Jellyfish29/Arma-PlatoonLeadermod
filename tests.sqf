

pl_player_group_fast_cover = {

    _group = group player
    _group setVariable ["onTask", true];    
    private _units = (units _group) - [player];

    _units = [objNull] + _units;

    player playAction "GestureCover";

    if ((behaviour player) == "COMBAT") then {
        [_units, getPos player, 0, 15, true, [], false, 0] call pl_get_to_cover_positions;
    } else {
        [_units, getPos player, getDirVisual player, 15, true, [], false, 1] call pl_get_to_cover_positions;
    };  
};

[] call pl_player_group_fast_cover;
