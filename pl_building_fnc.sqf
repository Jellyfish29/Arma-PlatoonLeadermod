pl_draw_building_array = [];
pl_building_search_cords = [0,0,0];
pl_garrison_area_size = 25; 
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
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

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

    _pos = [[[(getPos _building), 40]],[]] call BIS_fnc_randomPos;
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
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

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
        // leader _group sideChat format ["Roger %1 is moving into Building, over",(groupId _group)];
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

pl_garrison_area_building = {
    params ["_group", ["_taskPlanWp", []]];
    private ["_watchDir", "_cords", "_watchPos", "_markerAreaName", "_markerDirName", "_buildings", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon"];

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};
    if (visibleMap) then {
        hintSilent "";

        _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />";
        hint parseText _message;

        _markerAreaName = format ["%1garrison", _group];
        createMarker [_markerAreaName, [0,0,0]];
        _markerAreaName setMarkerShape "ELLIPSE";
        _markerAreaName setMarkerBrush "Vertical";
        _markerAreaName setMarkerColor "colorYellow";
        _markerAreaName setMarkerAlpha 0.5;
        _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];

        onMapSingleClick {
            pl_defence_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            if (_alt) then {pl_deploy_static = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerAreaName setMarkerPos _mPos;
        };

        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {pl_cancel_strike = false};
        _message = "Select Defence FACING <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />";
        hint parseText _message;

        sleep 0.1;
        _cords = pl_defence_cords;
        _markerDirName = format ["defence%1", _group];
        createMarker [_markerDirName, _cords];
        _markerDirName setMarkerType "marker_afp";
        _markerDirName setMarkerColor "colorBLUFOR";

        onMapSingleClick {
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _markerDirName setMarkerDir _watchDir;
        };
        pl_mapClicked = false;
        _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa";

        if (count _taskPlanWp != 0) then {

            // add Arrow indicator
            pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

            waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11) or !(_group getVariable ["pl_task_planed", false])};

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true};
            _group setVariable ["pl_task_planed", false];
        };

        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

        _buildings = nearestObjects [_cords, ["house"], pl_garrison_area_size];

        if ((count _buildings == 0)) exitWith {hint "No buildings in Area!"; deleteMarker _markerAreaName; deleteMarker _markerDirName;};

        [_group] call pl_reset;

        sleep 0.2;

        playSound "beep";

        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", _icon];


        _validPos = [];
        _allPos = [];
        {
            _building = _x;
            pl_draw_building_array pushBack [_group, _building];
            _bPos = [_building] call BIS_fnc_buildingPositions;
            {
                _allPos pushBack _x;
                _watchPos = [10*(sin _watchDir), 10*(cos _watchDir), 1.7] vectorAdd _x;
                _standingPos = [0, 0, 1.7] vectorAdd _x;
                _standingPos = ATLToASL _standingPos;
                _watchPos = ATLToASL _watchPos;

                // _helper = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
                // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
                // _helper setposASL _standingPos;

                _cansee = [objNull, "VIEW"] checkVisibility [_standingPos, _watchPos];
                if (_cansee == 1) then {
                    _validPos pushBack _x;
                };
            } forEach _bPos;
        } forEach _buildings;


        // {
        //     _helper = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
        //     _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
        //     _helper setposATL _x;
        // } forEach _validPos;

        _watchPos = [500*(sin _watchDir), 500*(cos _watchDir), 0] vectorAdd _cords;

        _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _allPos = _allPos - _validPos;
        _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        _units = units _group;
        for "_i" from 0 to (count _units) - 1 step 1 do {
            private _cover = false;
            if (_i < (count _validPos)) then {
                _pos = _validPos#_i;
                _unit = _units#_i;
            }
            else
            {
                if (_i < (count _allPos)) then {
                    _pos = _allPos#_i;
                    _unit = _units#_i;
                }
                else
                {
                    _cover = true;
                    _unit = _units#_i;
                };
            };
            _pos = ATLToASL _pos;
            private _unitPos = "UP";
            _checkPos = [7*(sin _watchDir), 7*(cos _watchDir), 1.7] vectorAdd _pos;
            _crouchPos = [0, 0, 0.6] vectorAdd _pos;
            if (([objNull, "VIEW"] checkVisibility [_crouchPos, _checkPos]) == 1) then {
                _unitPos = "MIDDLE";
            };
            if (([objNull, "VIEW"] checkVisibility [_pos, _checkPos]) == 1) then {
                _unitPos = "DOWN";
            };

            _pos = ASLToATL _pos;
            if (_cover) then {
                _b = (nearestObjects [_cords, ["house"], pl_garrison_area_size]) select 0;
                _pos = [[[(position _b), 30]],[]] call BIS_fnc_randomPos;
                _pos = _pos findEmptyPosition [0, 20];
                // player sideChat str _pos;
            };
            [_unit, _pos, _watchPos, _watchDir, _unitPos, _cover] spawn {
                params ["_unit", "_pos", "_watchPos", "_watchDir", "_unitPos", "_cover"];
                _unit disableAI "AUTOCOMBAT";
                _unit disableAI "TARGET";
                _unit doMove _pos;
                _unit moveTo _pos;
                sleep 1;
                waitUntil {(unitReady _unit) or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
                if !(_cover) then {
                    _unit doWatch _watchPos;
                    doStop _unit;
                    _unit setUnitPos _unitPos;
                    _unit disableAI "PATH";
                    _unit enableAI "AUTOCOMBAT";
                    _unit enableAI "TARGET";
                }
                else
                {
                    // player sideChat "off";
                    [_unit, _watchPos, _watchDir, 8, true] spawn pl_find_cover;
                };
            };
        };

        // hint (str _allPos);

        waitUntil {!(_group getVariable ["onTask", true])};

        deleteMarker _markerAreaName;
        deleteMarker _markerDirName;

        {
            pl_draw_building_array = pl_draw_building_array - [[_group, _x]];
        } forEach _buildings;
    };
};



