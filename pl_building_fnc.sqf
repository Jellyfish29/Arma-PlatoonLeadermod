pl_draw_building_array = [];
pl_building_search_cords = [0,0,0];
pl_mapClicked = false;

pl_move_building = {
    params ["_unit", "_buildPosArray", "_building"];

    _currentPos = 0;
    for "_i" from 0 to (count(_buildPosArray) - 1) do {
        _pos = _buildPosArray select _i;
        _unit doMove _pos;
        _unit moveTo _pos;
        waitUntil {(unitReady _unit) or (!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])};
        if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};
        doStop _unit;
    };
    if (alive _unit and (group _unit) getVariable ["onTask", true]) then {
        _unit enableAI "AUTOCOMBAT";
        _unit limitSpeed 5000;
        _unit setVariable ["pl_damage_reduction", false];
        [_unit, _building] spawn pl_guard_building;
    };
};

pl_nearest_pos = {
    params ["_targets", "_buildPos"];
    private ["_returnPos", "_d", "_r"];

    _returnPos = [];
    {
        _d = 1000;
        _t = _x;
        {
            _p = _x;
            _b = (_t distance2D _p);
            if (_b < _d) then {
                _r = _p;
                _d = _b;
            };
        } forEach _buildPos;
        _returnPos pushBack _r;
        // player sideChat str _r;
    } forEach _targets;
    _returnPos = [_returnPos, [], {_x#2}, "ASCEND"] call BIS_fnc_sortBy;
    _returnPos
};

pl_clear_building = {
    private ["_group", "_building", "_targetPos"];
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

        [_group] call pl_reset;
        sleep 0.2;

        playSound "beep";
        leader _group sideChat format ["%1 is clearing the Building, over",(groupId _group)];
        _allPos = [_building] call BIS_fnc_buildingPositions;

        pl_draw_building_array pushBack [_group, _building];



        _targetPos = [];
        _targets = (getPos _building) nearObjects ["Man", 50];
        {
            if (alive _x) then {
                _targetPos pushBack (getPosATL _x);
                _x setSkill 0.1;
                _x disableAI "PATH";
            };
        } forEach (_targets select {!(side _x isEqualTo playerSide)});

        _movePos = [_targetPos, _allPos] call pl_nearest_pos;

        if ((count _movePos) == 0) then {_movePos = _allPos};

        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"];
        _unitLimiter = 0;
        {
            _x limitSpeed 12;
            if (_unitLimiter < 4) then {
                _unitLimiter =  _unitLimiter + 1;
                _x disableAI "AUTOCOMBAT";
                _x setVariable ["pl_damage_reduction", true];
                [_x, _movePos, _building] spawn pl_move_building;
            }
            else
            {
                [_x, _building] spawn pl_guard_building;
            };
        } forEach (units _group);
        waitUntil {({ alive _x } count units _group == 0) or !(_group getVariable ["onTask", true])};
        pl_draw_building_array = pl_draw_building_array - [[_group, _building]];
    };
};

pl_guard_building = {
    params ["_unit", "_building"];

    _pos = [[[(getPos _building), 10]],[]] call BIS_fnc_randomPos;
    _pos = _pos findEmptyPosition [0, 10];
    _unit doMove _pos;
    _unit moveTo _pos;

    sleep 2;
    waitUntil {sleep 0.1; (unitReady _unit) or (!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])};
    if !((group _unit) getVariable ["onTask", true]) exitWith {};
    _unit disableAI "PATH";
    _unit setUnitPos "MIDDLE";
};


pl_move_to_garrison = {
    params ["_unit", "_pos"];
    _unit disableAI "AUTOCOMBAT";
    _unit doMove _pos;
    _unit moveTo _pos;
    waitUntil {(unitReady _unit) or !(alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])};
    if ((group _unit) getVariable ["onTask", true]) then {
        doStop _unit;
        _unit disableAI "PATH";
        _unit enableAI "AUTOCOMBAT";
    };
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
        
        [_group] call pl_reset;
        sleep 0.2;

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
        waitUntil {({ alive _x } count units _group == 0) or !(_group getVariable ["onTask", true])};
        pl_draw_building_array = pl_draw_building_array - [[_group, _building]];
    };
};



