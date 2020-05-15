pl_sandbags = [];
pl_covers = [];
pl_mapClicked = false;

pl_retreat = {

    params ["_group"];
    private ["_targets", "_cords"];

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };
    _group setVariable ["onTask", false];
    sleep 0.25;

    _leader = leader _group;
    if (_leader == vehicle _leader) then {
        // leader _group sideChat "Roger Falling Back, Over";
        [leader _group, "SmokeShellMuzzle"] call BIS_fnc_fire;

        {
            _unit = _x;
            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            _unit doMove _cords;

            private _targets = _x targetsQuery [objNull, sideUnknown, "", [], 0];
            private _count = count _targets;
                
            for [{private _i = 0}, {_i < _count}, {_i = _i + 1}] do {
                private _y = _targets select _i;
            _x forgetTarget (_y select 1);
            };
        } forEach (units _group);

        for "_i" from count waypoints _group - 1 to 0 step -1 do
            {
                deleteWaypoint [_group, _i];
            };

        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa"];
        _group addWaypoint [_cords, 0];
        _group setBehaviour "AWARE";
        _group setSpeedMode "FULL";
        _group setCombatMode "BLUE";

        _time = time + 45;
        waitUntil {(((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 15) or (time >= _time) or !(_group getVariable "onTask")};
        
        {
            _x enableAI "AUTOCOMBAT";
            _x enableAI "AUTOTARGET";
            _x enableAI "TARGET";
            _x doFollow (leader _group)
        } forEach (units _group);

        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
        _group setSpeedMode "NORMAL";
        _group setCombatMode "YELLOW";
        // leader _group sideChat "We reached Fall Back Position, Over";
    }
    else
    {
        for "_i" from count waypoints _group - 1 to 0 step -1 do
            {
                deleteWaypoint [_group, _i];
        };
        _group addWaypoint [_cords, 0];
        _group setVariable ["setSpecial", true];
        _group setVariable ["onTask", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa"];
        _vic = vehicle _leader;
        [_vic, "SmokeLauncher"] call BIS_fnc_fire;
        _time = time + 45;
        waitUntil {(((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 25) or (time >= _time) or !(_group getVariable "onTask")};
        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
    };
};

pl_spawn_retreat = {
    {
        [_x] spawn pl_retreat;
    } forEach hcSelected player;
};

// call pl_spawn_retreat;

pl_move_to_360 = {

    params ["_unit", "_posArray"];
    private ["_pos", "_watchPos"];
    _pos = _posArray select 0;
    _watchPos = _posArray select 1;
    if (vehicle _unit != _unit) exitWith {};
    sleep 0.1;
    doStop _unit;
    _unit setUnitPos "MIDDLE";
    sleep 0.2;
    _unit moveTo _pos;
    _time = time + 100;
    waitUntil {sleep 1; (time > _time || !alive _unit || moveToCompleted _unit || currentCommand _unit != "STOP")};
    _unit doWatch _watchPos;
    _time = time + 600;
    waitUntil {sleep 2; (time > _time || !alive _unit || currentCommand _unit != "STOP")};
    _unit doWatch objNull;
    _unit setUnitPos "AUTO";
};

pl_360 = {
    params ["_group", "_pos"];
    private ["_radius"];
    _count = count (units _group);
    _radius = 10;
    _diff = 360/_count;
    _movePos = [];
    for "_i" from 0 to (_count - 1) do {
        _degree = 1 + _i*_diff;
        _newPos = [_radius*(sin _degree), _radius*(cos _degree), 0] vectorAdd _pos;
        _watchPos = [100*(sin _degree), 100*(cos _degree), 0] vectorAdd _pos;
        _movePos pushBack [_newPos, _watchPos];
    };

    for "_i" from 0 to (_count - 1) do {
        [(units _group) select _i, _movePos select _i] spawn pl_move_to_360;
    };
};

pl_360_at_mappos = {
    params ["_group"];

    _group setVariable ["onTask", false];
    sleep 0.25;

    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };
    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"];
    [_group, getPos (leader _group)] spawn pl_360;
    waitUntil {(count (waypoints _group) > 0) or !(_group getVariable "onTask")};
    {
        _x enableAI "PATH";
        _x doFollow (leader _group);
        _x commandFollow (leader _group);
        _x enableAI "AUTOCOMBAT";
    } forEach (units _group);
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
};

pl_spawn_360 = {
    {
        [_x] spawn pl_360_at_mappos;
    } forEach hcSelected player;
};


pl_digin = {
    params ["_unit", "_dir", "_watchDir"];

    _unit setUnitPos "MIDDLE";
    sleep 5;
    _coverPos = [1*(sin 0), 1*(cos 0), 0] vectorAdd (getPos _unit);
    _movePos = [2*(sin 0), 2*(cos 0), 0] vectorAdd (getPos _unit);
    _sandBg = createVehicle ["Land_BagFence_Short_F", _coverPos, [], 0,"NONE"];
    _sandBg setDir _dir;
    _sandBg setVectorUp surfaceNormal position _sandBg;
    pl_sandbags pushBack [_sandBg, (group _unit)];
    (group _unit) setBehaviour "COMBAT";
    _unit doMove _movePos;
    waitUntil {(unitReady _unit)};
    _unit enableAI "AUTOCOMBAT";
    _unit doWatch _watchDir;
    doStop _unit;
};



pl_find_cover = {
    params ["_unit", "_watchPos", "_watchDir", "_radius", "_moveBehind"];

    _covers = nearestTerrainObjects [getPos _unit, [], _radius, true, true];
    _unit enableAI "AUTOCOMBAT";
    _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _watchPos;
    if ((count _covers) > 0) then {
        {
            if !(_x in pl_covers) exitWith {
                pl_covers pushBack _x;
                _unit doMove (getPos _x);
                waitUntil {(unitReady _unit) or !(alive _unit)};
                _unit setUnitPos "MIDDLE";
                sleep 1;
                if (_moveBehind) then {
                    _moveDir = [(_watchDir - 180)] call pl_angle_switcher;
                    _coverPos =  [2*(sin _moveDir), 2*(cos _moveDir), 0] vectorAdd (getPos _unit);
                    _unit doMove _coverPos;
                    sleep 1;
                    waitUntil {(unitReady _unit) or !(alive _unit)};
                    doStop _unit;
                    _unit doWatch _watchPos;
                _unit disableAI "PATH";
                }
                else
                {
                    doStop _unit;
                    _unit doWatch _watchPos;
                };
            };
        } forEach _covers;
        if (unitPos _unit == "AUTO") then {
            _unit setUnitPos "DOWN";
            _unit doWatch _watchPos;
            doStop _unit;
            _unit disableAI "PATH";
        };
    }
    else
    {
        _unit setUnitPos "DOWN";
        _unit doWatch _watchPos;
        doStop _unit;
        _unit disableAI "PATH";
    };

};

pl_take_cover = {
    params ["_group"];

    _group setVariable ["onTask", false];
    sleep 0.25;

    _dir = getDir leader _group;
    _watchPos = getPos leader _group;
    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"];
    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };

    {
        [_x, _watchPos, _dir, 15, false] spawn pl_find_cover;
    } forEach (units _group);

    waitUntil {(count (waypoints _group) > 0) or !(_group getVariable "onTask")};
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
    {
        _x enableAI "PATH";
        _x doFollow (leader _group);
        _x setUnitPos "AUTO";
        _x doWatch objNull;

    } forEach (units _group);
};

pl_spawn_take_cover = {
    {
        [_x] spawn pl_take_cover;
    } forEach hcSelected player;  
};


pl_defend_position = {
    params ["_group", "_digIn"];
    private["_cords", "_watchDir"];

    _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    
    _group setVariable ["onTask", false];
    sleep 0.25;

    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };

    onMapSingleClick {
        pl_cords2 = _pos;
        pl_mapClicked = true;
        onMapSingleClick "";
    };
    _makerName = groupId _group;
    createMarker [_makerName, _cords];
    _makerName setMarkerType "marker_sfp";
    _makerName setMarkerColor "colorBLUFOR";
    while {!pl_mapClicked} do {
        _markerDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
        _makerName setMarkerDir _markerDir;
        sleep 0.1;
    };
    pl_mapClicked = false;
    _watchDir = [_cords, pl_cords2] call BIS_fnc_dirTo;
    leader _group limitSpeed 12;
    _group setFormation "LINE";
    _group addWaypoint [_cords, 0];

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"];
    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);
    _group setBehaviour "AWARE";
    waitUntil {
    if (_group isEqualTo grpNull) exitWith {};
    (((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 5) or !(_group getVariable "onTask")};

    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };
    _group setFormDir _watchDir;
    _time = time + 10;
    waitUntil {
    if (_group isEqualTo grpNull) exitWith {};
    (time >= _time) or !(_group getVariable "onTask")};
    if (_group getVariable "onTask") then {
        leader _group groupRadio "SentCmdHide";
        if (_digIn) then {
            {
                [_x, _watchDir, pl_cords2] spawn pl_digin;
            } forEach (units _group);
        }
        else
        {
            pl_covers = [];
            {
                [_x, pl_cords2, _watchDir, 7, true] spawn pl_find_cover;
                sleep 0.5;
            } forEach (units _group);
        };
    };

    waitUntil {
    if (_group isEqualTo grpNull) exitWith {};
    (count (waypoints _group) > 0) or !(_group getVariable "onTask")};
    deleteMarker _makerName;
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
    leader _group limitSpeed 5000;
    {
        _x enableAI "PATH";
        _x doFollow (leader _group);
        _x setUnitPos "AUTO";
        _x doWatch objNull;

    } forEach (units _group);

    if (_digIn) then {
        sleep 10;
        {
            if (_x  select 1 == _group) then {
                deleteVehicle (_x select 0);
            };
        } forEach pl_sandbags;
    };
};


// [hcSelected player select 0, false] spawn pl_defend_position;

