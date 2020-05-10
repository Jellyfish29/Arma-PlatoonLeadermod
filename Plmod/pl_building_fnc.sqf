
pl_move_building = {
    params ["_unit", "_secondFloor", "_firstFloor", "_building"];
    _currentPos = 0;
    _secondFloorLen = count _secondFloor;
    _firstFloorLen = count _firstFloor;


    while {_currentPos < _firstFloorLen} do {
        _unit doMove (_firstFloor select _currentPos);
        waitUntil {( unitReady _unit ) || !( alive _unit ) || !((group _unit) getVariable "onTask") || ((count (waypoints (group _unit))) > 0)};
        _unit enableAI "AUTOCOMBAT";
        _currentPos = _currentPos + 1;
    };
    _currentPos = 0;
    while {_currentPos < _secondFloorLen} do {
        _unit doMove (_secondFloor select _currentPos);
        waitUntil {( unitReady _unit ) || !( alive _unit ) || !((group _unit) getVariable "onTask") || ((count (waypoints (group _unit))) > 0)};
        _currentPos = _currentPos + 1;
    };
    _unit limitSpeed 5000;
    [_unit, _building] spawn pl_guard_building;
};

pl_guard_building = {
    params ["_unit", "_building"];

    _pos = (getPos _building) findEmptyPosition [0, 70];
    _unit doMove _pos;
    waitUntil {( unitReady _unit ) || !( alive _unit ) || !((group _unit) getVariable "onTask") || ((count (waypoints (group _unit))) > 0)};
    _unit enableAI "AUTOCOMBAT";
    _unit limitSpeed 5000;

    waitUntil {sleep 5; true};
    if !(_unit == leader (group _unit)) then {
        _unit setUnitPos "MIDDLE";
        doStop _unit;
    };

    waitUntil {((count (waypoints (group _unit))) > 0) or !((group _unit) getVariable "onTask")};
    _unit doFollow leader (group _unit);
    _unit setUnitPos "AUTO";
    (group _unit) setVariable ["setSpecial", false];
    (group _unit) setVariable ["onTask", false];
};

pl_clear_building = {
    params ["_group", "_building"];

    _group setVariable ["onTask", false];
    sleep 0.25;

    for "_i" from count waypoints _group - 1 to 0 step -1 do
    {
        deleteWaypoint [_group, _i];
    };

    leader _group sideChat "Roger, clearing Building";
    _allPos = [_building] call BIS_fnc_buildingPositions;
    _medianZ = 0;
    {
        _medianZ = _medianZ + (_x select 2);
    } forEach _allPos;
    _medianZ = _medianZ / (count _allPos);

    _firstFloor = [];
    _secondFloor = [];

    {
        if ((_x select 2) < _medianZ) then {
            _firstFloor pushBack _x;
        }
        else
        {
            _secondFloor pushBack _x;
        };
    } forEach _allPos;

    {
        doStop _x;
    } forEach (units _group);

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"];
    _unitLimiter = 0;
    {
        _x limitSpeed 9;
        _x disableAI "AUTOCOMBAT";
        if (_unitLimiter < 4) then {
            [_x, _secondFloor, _firstFloor, _building] spawn pl_move_building;
            _unitLimiter = _unitLimiter + 1
        }
        else
        {
            [_x, _building] spawn pl_guard_building;
        };
        sleep 2;
    } forEach (units _group);
};

pl_move_to_garrison = {
    params ["_unit", "_pos"];
    _unit disableAI "AUTOCOMBAT";
    _unit doMove _pos;
    waitUntil {(unitReady _unit) or !(alive _unit)};
    doStop _unit;
    _unit enableAI "AUTOCOMBAT";
    waitUntil {(count (waypoints (group _unit))) > 0 or !((group _unit) getVariable "onTask")};
    _unit doFollow leader (group _unit);
    (group _unit) setVariable ["setSpecial", false];
    (group _unit) setVariable ["onTask", false];
};

pl_garrison_building = {
    params ["_group","_building"];

    _group setVariable ["onTask", false];
    sleep 0.25;

    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };
    leader _group sideChat "Roger, occupying Building";
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
};



pl_spawn_building_search = {
    _target = cursorTarget;
    if (visibleMap) then {
        _target = nearestBuilding ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
    };

    [hcSelected player select 0, _target] spawn pl_clear_building;
};

pl_spawn_building_garrison = {
    _target = cursorTarget;
    if (visibleMap) then {
        _target = nearestBuilding ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
    };

    [hcSelected player select 0, _target] spawn pl_garrison_building;
};


// [] call pl_spawn_building_garrison;