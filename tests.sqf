[] spawn {
 
    while {true} do {

        private _markers = [];

        {
            _fightingPos = _x;
            _joinValues = _y;

            if (pl_debug) then {
                _m =  createMarker [str (random 5), _x];
                _m setMarkerShape "ELLIPSE";
                _m setMarkerBrush "Border";
                _m setMarkerColor "colorOrange";
                _m setMarkerAlpha 0.8;
                _m setMarkerSize [pl_opfor_retreat_zone_size, pl_opfor_retreat_zone_size];
                
                _m2 = createMarker [str (random 5), _x];
                _m2 setMarkerType "mil_dot";
                _m2 setMarkerSize [1,1];
                _m2 setMarkerColor "colorOrange";
                _m2 setMarkerText (format ["%1  /  %2", _joinValues#0, _joinValues#1]);

                _markers pushback _m;
                _markers pushback _m2;
            };

            if ((_joinValues#0) >= (_joinValues#1)) then {

                {
                    _grp setvariable ["pl_opfor_retreat", true];
                } forEach (allGroups select {side _x != playerSide and side _x != civilian and ((leader _x) distance2D _fightingPos) <= pl_opfor_retreat_zone_size});

                pl_opfor_retreat_zones deleteAt _x;
            };


        } forEach pl_opfor_retreat_zones;

        sleep 2;

        {
            deleteMarker _x;
        } forEach _markers;
    };
};

pl_opfor_tactical_retreat_road = objNull;

pl_opfor_tactical_retreat = {
    params ["_grp", "_timeout"];

    _grp setvariable ["pl_opfor_retreat", true];

    if (isNull pl_opfor_tactical_retreat_road) then {

        private _opforSide = side _grp;
        private _enyCentroid = [allGroups select {(side _x) isEqualTo playerSide}] call pl_find_centroid_of_groups;

        pl_opfor_tactical_retreat_road = [(getPos (leader _grp)) getPos [worldSize * 0.05, _enyCentroid getDir (leader _grp)], 1500] call BIS_fnc_nearestRoad;
    };

    private _retreatPos = getPos pl_opfor_tactical_retreat_road;

    if (_retreatPos isEqualTo [0,0,0]) exitWith {};

    _retreatPos = [[[_retreatPos, 150]], ["water"]] call BIS_fnc_randomPos;

    _m = createMarker [str (random 1), _retreatPos];
    _m setMarkerType "mil_marker";
    _m setMarkerSize [1.5, 1.5];

    [_grp] call pl_opfor_reset;

    {
        _x disableAI "AUTOCOMBAT";
        _x disableAI "FIREWEAPON";
    } forEach (units _grp);


    if (vehicle (leader _grp) != leader _grp) then {
        _vic = vehicle (leader _grp);
        _vic limitSpeed 70;
        _vic forceSpeed -1;
        _grp setBehaviour "AWARE";
    } else {
        _grp setBehaviour "AWARE";
    };

    [_grp, getPos (leader _grp), _retreatPos, ((leader _grp) distance2D _retreatPos) / 3] call pl_opfor_add_wp_path;

    // sleep ([240, 500] call BIS_fnc_randomInt);
    sleep _timeout;

    if (isNil "_grp") exitWith {};

    [_grp] call pl_opfor_reset;

    {
        _x enableAI "AUTOCOMBAT";
        _x enableAI "FIREWEAPON";
    } forEach (units _grp);

    _grp setBehaviour "AWARE";
    _grp setvariable ["pl_opfor_retreat", false];

};