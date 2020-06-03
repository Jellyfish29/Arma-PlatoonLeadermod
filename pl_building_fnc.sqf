pl_draw_building_array = [];
pl_building_search_cords = [0,0,0];
pl_mapClicked = false;

pl_move_building = {
    params ["_unit", "_buildPosArray", "_building", "_currentPos"];

    while {(_currentPos < (count _buildPosArray) - 1)} do {
        _unit doMove (_buildPosArray select _currentPos);
        sleep 2.5;
        waitUntil {sleep 0.1; (!alive _unit) or (_unit getVariable ["pl_wia", false]) or (unitReady _unit)};
        // waitUntil {(count ((_buildPosArray select (_currentPos + 1)) nearObjects ["Man", 2])) < 1};
        // _unit enableAI "AUTOCOMBAT";
        if ((!alive _unit) or (_unit getVariable "pl_wia") or !((group _unit) getVariable "onTask")) exitWith {};
        _currentPos = _currentPos + 1;
    };
    if (alive _unit) then {
        _unit enableAI "AUTOCOMBAT";
        _unit limitSpeed 5000;
        _unit setVariable ["pl_damage_reduction", false];
        [_unit, _building] spawn pl_guard_building;
    };
};

pl_clear_building = {
    private ["_group", "_building"];
    _group = hcSelected player select 0;

    if (visibleMap) then {
        hint "Select on MAP";
        onMapSingleClick {
            pl_building_search_cords = _pos;
            pl_mapClicked = true;
            hintSilent "";
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {sleep 0.1;};
        pl_mapClicked = false;
        _building = nearestBuilding pl_building_search_cords;
    }
    else
    {
        _building = cursorTarget;
    };
    
    if !(isNil "_building") then {
        _group setVariable ["onTask", false];
        sleep 0.25;

        for "_i" from count waypoints _group - 1 to 0 step -1 do
        {
            deleteWaypoint [_group, _i];
        };

        playSound "beep";
        leader _group sideChat format ["%1 is clearing the Building, over",(groupId _group)];
        _allPos = [_building] call BIS_fnc_buildingPositions;

        pl_draw_building_array pushBack [_group, _building];

        {
            if (alive _x and (side _x) != civilian and (_x distance2D _building) < 80) then {
                _group reveal [_x, 3];
            }; 
        } forEach (allUnits+vehicles select {side _x != playerSide});

        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"];
        _unitLimiter = 0;
        _searchParty = [];
        {
            _x limitSpeed 12;
            _x disableAI "AUTOCOMBAT";
            if (_unitLimiter < 4) then {
                _x setVariable ["pl_damage_reduction", true];
                _unitLimiter = _unitLimiter + 1;
                _searchParty pushBack _x;
            }
            else
            {
                [_x, _building] spawn pl_guard_building;
            };
        } forEach (units _group);
        for "_i" from 0 to (count(_searchParty) - 1) do {
            _unit = _searchParty select _i;
            [_unit, _allPos, _building, _i] spawn pl_move_building;
            sleep 0.5;
        };
        waitUntil {sleep 0.1; ({ alive _x } count units _group == 0) or !(_group getVariable ["onTask", true])};
        pl_draw_building_array = pl_draw_building_array - [[_group, _building]];
    };
};

pl_guard_building = {
    params ["_unit", "_building"];

    _pos = [[[(getPos _building), 10]],[]] call BIS_fnc_randomPos;
    _pos = _pos findEmptyPosition [0, 10];
    _unit doMove _pos;
    sleep 1;
    waitUntil { sleep 0.1;
    ( unitReady _unit ) or ( !alive _unit ) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true]) or ((count (waypoints (group _unit))) > 0)};
    _unit enableAI "AUTOCOMBAT";
    _unit limitSpeed 5000;

    sleep 5;
    if !(_unit == leader (group _unit)) then {
        _unit setUnitPos "MIDDLE";
        doStop _unit;
    };

    waitUntil {sleep 0.1; (!alive _unit) or ((count (waypoints (group _unit))) > 0) or !((group _unit) getVariable ["onTask", true])};
    if (alive _unit) then {
        _unit setVariable ["pl_damage_reduction", false];
        _unit doFollow leader (group _unit);
        _unit setUnitPos "AUTO";
        (group _unit) setVariable ["setSpecial", false];
        (group _unit) setVariable ["onTask", false];
    };
};


pl_move_to_garrison = {
    params ["_unit", "_pos"];
    _unit disableAI "AUTOCOMBAT";
    _unit doMove _pos;
    waitUntil {sleep 0.1; (unitReady _unit) or !(alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])};
    doStop _unit;
    _unit enableAI "AUTOCOMBAT";
    waitUntil {sleep 0.1; (count (waypoints (group _unit))) > 0 or !((group _unit) getVariable ["onTask", true])};
    _unit doFollow leader (group _unit);
    (group _unit) setVariable ["setSpecial", false];
    (group _unit) setVariable ["onTask", false];
};

pl_garrison_building = {
    private ["_group","_building"];
    _group = hcSelected player select 0;

    if (visibleMap) then {
        hint "Select on MAP";
        onMapSingleClick {
            pl_building_search_cords = _pos;
            pl_mapClicked = true;
            hintSilent "";
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {sleep 0.1;};
        pl_mapClicked = false;
        _building = nearestBuilding pl_building_search_cords;
    }
    else
    {
        _building = cursorTarget;
    };

    if !(isNil "_building") then {
        _group setVariable ["onTask", false];
        sleep 0.25;

        for "_i" from count waypoints _group - 1 to 0 step -1 do{
            deleteWaypoint [_group, _i];
        };
        pl_draw_building_array pushBack [_group, _building];
        playSound "beep";
        leader _group sideChat format ["Roger %1 is moving into Building, over",(groupId _group)];
        _allPos = [_building] call BIS_fnc_buildingPositions;
        _posCount = count _allPos;
        _unitCount = count (units _group);
        _group setVariable ["setSpecial", true];
        _group setVariable ["onTask", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"];
        for "_i" from 0 to _unitCount -1 do {
            if (_i < _posCount) then {
                [((units _group) select _i), (_allPos select (_posCount -1 -_i))] spawn pl_move_to_garrison;
            }
            else
            {
                [(units _group) select _i, _building] spawn pl_guard_building;
            }
        };
        waitUntil {sleep 0.1; ({ alive _x } count units _group == 0) or !(_group getVariable ["onTask", true])};
        pl_draw_building_array = pl_draw_building_array - [[_group, _building]];
    };
};
