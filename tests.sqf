pl_draw_unit_group_lines2 = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _grp = _x;
                if (vehicle (leader _grp) == leader _grp) then {
                    _unitsLeft = units _grp;
                    {
                        _pos1 = getPos _x;
                        _unitsLeft deleteAt (_unitsLeft find _x);
                        _u2 = [_unitsLeft, _pos1] call BIS_fnc_nearestPosition;
                        _pos2 = getPos _u2;
                        _display drawLine [
                            _pos1,
                            _pos2,
                            [0,0.4,0.6,0.5]
                        ];
                    } forEach units _grp;
                };
            } forEach allGroups select {hcLeader _x isEqualTo player};
    "]; // "
};

[] call pl_draw_unit_group_lines2;