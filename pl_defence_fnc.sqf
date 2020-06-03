
pl_covers = [];
pl_defence_cords = [0,0,0];
pl_mapClicked = false;
pl_denfence_draw_array = [];

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

        _time = time + 60;
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
        waitUntil {sleep 0.1; (((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 25) or (time >= _time) or !(_group getVariable ["onTask", true])};
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
    waitUntil {sleep 1; (time > _time || !alive _unit || moveToCompleted _unit || currentCommand _unit != "STOP") or !((group _unit) getVariable ["onTask", true])};
    _unit doWatch _watchPos;
    _time = time + 600;
    waitUntil {sleep 2; (time > _time || !alive _unit || currentCommand _unit != "STOP") or !((group _unit) getVariable ["onTask", true])};
    _unit doWatch objNull;
    _unit setUnitPos "AUTO";
};

pl_360 = {
    params ["_group", "_pos", "_radius"];
    // private ["_radius"];
    _count = count (units _group);
    // _radius = 10;
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
    params ["_group", "_radius"];

    _group setVariable ["onTask", false];
    sleep 0.25;

    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };
    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"];
    [_group, getPos (leader _group), _radius] spawn pl_360;
    waitUntil {sleep 0.1; (count (waypoints _group) > 0) or !(_group getVariable ["onTask", true])};
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
        [_x, 13] spawn pl_360_at_mappos;
    } forEach hcSelected player;
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
                waitUntil {sleep 0.1; (unitReady _unit) or (!alive _unit)};
                _unit setUnitPos "MIDDLE";
                sleep 1;
                if (_moveBehind) then {
                    _moveDir = [(_watchDir - 180)] call pl_angle_switcher;
                    _coverPos =  [2*(sin _moveDir), 2*(cos _moveDir), 0] vectorAdd (getPos _unit);
                    _unit doMove _coverPos;
                    sleep 1;
                    waitUntil {sleep 0.1; (unitReady _unit) or (!alive _unit)};
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
            // sleep 2;
            // _checkPos = [5*(sin _watchDir), 5*(cos _watchDir), ((getPosASL _unit)#2 + 1)] vectorAdd (getPosASL _unit);
            // _cansee = [objNull, "FIRE"] checkVisibility [(eyePos _unit), _checkPos];
            // _unit sideChat str _cansee;
            // if (_cansee < 0.5) then {
            //     _unit setUnitPos "MIDDLE";
            // };
            _unit doWatch _watchPos;
            doStop _unit;
            _unit disableAI "PATH";
        };
    }
    else
    {
        _unit setUnitPos "DOWN";
        // sleep 2;
        // _checkPos = [5*(sin _watchDir), 5*(cos _watchDir), ((getPosASL _unit)#2 + 1)] vectorAdd (getPosASL _unit);
        // _cansee = [objNull, "FIRE"] checkVisibility [(eyePos _unit), _checkPos];
        // _unit sideChat str _cansee;
        // if (_cansee < 0.5) then {
        //     _unit setUnitPos "MIDDLE";
        // };
        _unit doWatch _watchPos;
        doStop _unit;
        _unit disableAI "PATH";
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
        [_x, _watchPos, _dir, 20, false] spawn pl_find_cover;
    } forEach (units _group);
    // if (vehicle (leader _group) != leader _group) then {
    //     _vic = vehicle (leader _group);
    //     _vic setUnloadInCombat [true, false];
    // };

    waitUntil {sleep 0.1; (count (waypoints _group) > 0) or !(_group getVariable ["onTask", true])};
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
    private ["_group", "_markerName", "_isStatic", "_staticMarkerName", "_cords", "_watchDir", "_watchPos", "_offSet", "_moveDir", "_medic", "_medicPos"];
    _group = hcSelected player select 0;
    if (visibleMap) then {
        hintSilent "";
        hint "Select DEFENCE position on MAP (SHIFT + LMB to cancel)";

        onMapSingleClick {
            pl_defence_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {sleep 0.1;};
        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {pl_cancel_strike = false};
        hint "Select Weapon DIRECTION (SHIFT + LMB to cancel)";

        sleep 0.1;
        _cords = pl_defence_cords;
        _markerName = format ["defence%1", _group];
        createMarker [_markerName, _cords];
        _markerName setMarkerType "marker_sfp";
        _markerName setMarkerColor "colorBLUFOR";

        onMapSingleClick {
            pl_mortar_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _markerName setMarkerDir _watchDir;
            sleep 0.05;
        };
        pl_mapClicked = false;

        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};


        _group setVariable ["onTask", false];
        sleep 0.25;
        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"];

        _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _cords;
        _leaderDir = _watchDir - 90;
        _leaderPos = [6*(sin _leaderDir), 6*(cos _leaderDir), 0] vectorAdd _cords;
        _medicDir = _watchDir - 180;
        _medicPos = [15*(sin _medicDir), 15*(cos _medicDir), 0] vectorAdd _cords;
        _isStatic = [_group, _markerName, _watchPos, _leaderPos] call pl_reworked_bis_unpack;
        sleep 0.1;

        _medic = {
            if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) exitWith {_x};
        } forEach (units _group);

        pl_denfence_draw_array pushBack [_markerName, (leader _group)];
        for "_i" from count waypoints _group - 1 to 0 step -1 do{
            deleteWaypoint [_group, _i];
        };
        leader _group groupRadio "SentCmdHide";

        if (_isStatic#0) then {
            _staticMarkerName = format ["static%1", _group];
            createMarker [_staticMarkerName, _cords];
            _staticMarkerName setMarkerType "marker_afp";
            _staticMarkerName setMarkerColor "colorBLUFOR";
            _staticMarkerName setMarkerDir _watchDir;
            (leader _group) addWeapon "Binocular";
            playSound "beep";
            leader _group sideChat format ["Roger, %1 will deploy Heavy Weapon at designated coordinates, over",(groupId _group)];
            _offSet = 9;
        }
        else
        {
            playSound "beep";
            leader _group sideChat format ["Roger, %1 will defend the Position, over",(groupId _group)];
            _offSet = 0;
        };
        for "_i" from 0 to ((count (units _group))- 1) do {
            if ((_i % 2) == 0) then {
                _offSet = _offSet + 9;
                _moveDir = _watchDir - 90;
            }
            else
            {
                _moveDir = _watchDir + 90;
            };
            _movePos = [_offSet*(sin _moveDir), _offSet*(cos _moveDir), 0] vectorAdd _cords;
            _unit = (units _group) select _i;
            if !(_unit in _isStatic#1) then {
                private _isLeader = false;
                if (_unit == (leader _group)) then {
                    _movePos = _cords;
                    _isLeader = true;
                };
                if (!(isNil "_medic") and pl_enabled_medical) then {
                    if (_unit == _medic) then {
                        _movePos = _medicPos;
                    };
                };
                [_unit, _movePos, _watchDir, _isLeader, _markerName] spawn {
                    params ["_unit", "_pos", "_watchDir", "_isLeader", "_markerName"];
                    _unit disableAI "AUTOCOMBAT";
                    _unit disableAI "AUTOTARGET";
                    _unit disableAI "TARGET";
                    _unit doMove _pos;
                    waitUntil {sleep 0.1; (!alive _unit) or (unitReady _unit)};
                    _unit enableAI "AUTOCOMBAT";
                    _unit enableAI "AUTOTARGET";
                    _unit enableAI "TARGET";
                    [_unit, _pos, _watchDir, 7, true] spawn pl_find_cover;
                    if (_isLeader) then {
                        pl_denfence_draw_array = pl_denfence_draw_array - [[_markerName, _unit]];
                    };
                };
            };
        };
        // Cancel Task
        
        if (!(isNil "_medic") and pl_enabled_medical) then {
            _medic setVariable ["pl_is_ccp_medic", true];
            while {(_group getVariable ["onTask", true])} do {
                {
                    if (lifeState _x isEqualTo "INCAPACITATED" and !(_x getVariable "pl_beeing_treatet")) then {
                        _medic setUnitPos "MIDDLE";
                        _h1 = [_group, _medic, nil, _x, _medicPos, 50] spawn pl_ccp_revive_action;
                        waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                        [_x, getPos _x, _watchDir, 7, false] spawn pl_find_cover;
                        _medic setUnitPos "MIDDLE";
                    };
                } forEach (units _group);
                _time = time + 10;
                waitUntil {sleep 1; time > _time or !(_group getVariable ["onTask", true])};
            };
            _medic setVariable ["pl_is_ccp_medic", false];
        }
        else
        {
            waitUntil {sleep 0.1; !(_group getVariable ["onTask", true])};
        };
        if (_isStatic#0) then {
            _weapon = {
                if (vehicle _x != _x) exitWith {vehicle _x};
                objNull
            } forEach (units _group);
            if !(isNull _weapon) then {
                [_group, _weapon] call pl_reworked_bis_pack;
            };
            deleteMarker _staticMarkerName;
            (leader _group) removeWeapon "Binocular";
        };
        sleep 0.1;
        deleteMarker _markerName;

    };
};


// [hcSelected player select 0, false] spawn pl_defend_position;

