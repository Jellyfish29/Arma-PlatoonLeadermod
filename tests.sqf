pl_march = {
    params [["_group", (hcSelected player)#0], ["_doBounding", false]];
    private ["_cords", "_f"], "_mwp";

    if (visibleMap or !(isNull findDisplay 2000)) then {
        if (visibleMap) then {
            _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _cords = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };

    // if (vehicle (leader _group) != (leader _group)) exitWith {[_group, _cords] spawn pl_vic_advance};

    if (!(_group getVariable ["pl_on_march", false])) then {


        if (_group getVariable ["onTask", false]) then {

            [_group] call pl_reset;
            sleep 0.2;
            [_group] call pl_reset;
            sleep 0.2;
            player hcSelectGroup [_group];
            
        } else {
            if !(_group getVariable ["pl_on_hold", false]) then {
                {
                    _x enableAI "PATH";
                    _x setUnitPos "AUTO";
                    _x forceSpeed -1;
                } forEach (units _group);
            };
        };

        
        _mwp = _group addWaypoint [_cords, 0];
        _mwp setWaypointType "MOVE";
        _group setVariable ["pl_mwp", _mwp];

        if ((vehicle player) != player) then {
            if (effectiveCommander (vehicle player) == player) then {
                driver (vehicle player) commandMove _cords;
            };
        };

        // _mwp setWaypointStatements ["true", "if ((vehicle player) != player) then {if (effectiveCommander (vehicle player) == player) then {driver (vehicle player) commandMove (waypointPosition ((waypoints (group player)) select ((currentWaypoint (group player) + 1))));};};"];

        // if (_doBounding and (vehicle (leader _group)) == (leader _group)) then {
        //     _mwp setWaypointCompletionRadius 25;
        // };

        // waitUntil {sleep 0.1; (leader _group) checkAIFeature "AUTOCOMBAT"};
        _group setVariable ["pl_on_march", true];
        sleep 1;
        {
            _x disableAI "AUTOCOMBAT";
            _x disableAI "SUPPRESSION";
            _x setHit ["legs", 0];
        } forEach (units _group);
        (leader _group) limitSpeed 14;
        // _group setFormation "FILE";
        _group setBehaviourStrong "AWARE";

        if (_doBounding and (vehicle (leader _group)) == (leader _group)) then {
            ["team", _group, _mwp] spawn pl_bounding_squad;
        };

        sleep 1;
        waitUntil {sleep 0.5; isNull _group or (((leader _group) distance2D (waypointPosition (_group getVariable ["pl_mwp", (currentWaypoint _group)]))) <= 10) or (isNil {_group getVariable ["pl_on_march", nil]})};
        _group setVariable ["pl_on_march", nil];

        // (_group getVariable ["pl_mwp", (waypoints _group) select (currentWaypoint _group)]) setWaypointPosition [getPos (leader _group), -1];
        // _group setVariable ["setSpecial", false];
        // {
        //     _x enableAI "AUTOCOMBAT";
        // } forEach (units _group);
        // (leader _group) limitSpeed 5000;
        
    }
    else
    {

        _mwp = _group addWaypoint [_cords, 0];
        _mwp setWaypointType "MOVE";
        if (_doBounding and (vehicle (leader _group)) == (leader _group)) then {
            ["team", _group, _mwp] spawn pl_bounding_squad;
        };

        // _mwp setWaypointStatements ["true", "(group this) setVariable ['pl_last_wp_pos', getPos this]; if ((vehicle player) != player) then {if (effectiveCommander (vehicle player) == player) then {driver (vehicle player) commandMove (waypointPosition ((waypoints (group player)) select ((currentWaypoint (group player) + 1))));};};"];
        // if (_group getVariable ["onTask", false]) then {
        //     [_group, false] spawn pl_reset;
        //     player hcSelectGroup [_group];
        //     sleep 0.1;
        //     [_group, false] spawn pl_reset;
        //     player hcSelectGroup [_group];
        //     sleep 0.1; 
        // };
        _group setVariable ["pl_mwp", _mwp];
    };
};

pl_bounding_move_team = {
    params ["_team", "_movePosArray", "_wpPos", "_group"];

    for "_i" from 0 to (count _team) - 1 do {
        _unit = _team#_i;
        _movePos = _movePosArray#_i;
        // _movePos = [_movePos, 8] call pl_find_cover_postion;
        // _movePos = _movePos findEmptyPosition [0, 20, typeOf _unit];
        if ((_unit distance2D _movePos) > 4) then {
            if (currentCommand _unit isNotEqualTo "MOVE" or (speed _unit) == 0) then {
                doStop _unit;
                [_unit, true, true] call pl_enable_force_move;

                _unit setHit ["legs", 0];
                _unit setUnitPos "UP";
                _unit doMove _movePos;
                _unit setDestination [_movePos, "LEADER PLANNED", true];
            };
        }
        else
        {
            if ((_unit getVariable ["pl_bounding_set_time", 0]) == 0) then {
                [_unit, _wpPos] call pl_bounding_set;
            };
        };
    };
    if (({currentCommand _x isEqualTo "MOVE"} count (_team select {alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")})) == 0 or ({(_x distance2D _wpPos) < 15} count _team > 0) or (waypoints _group isEqualTo [])) exitWith {true};
    if ({time > (_x getVariable ["pl_bounding_set_time", time])} count _team > 0) exitWith {
        for "_i" from 0 to (count _team) - 1 do {
            _unit = _team#_i;
            _movePos = _movePosArray#_i;
            if ((_unit distance2D _movePos) > 4) then {
                _unit setPos ([-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd (getPos _unit));
                [_unit, _wpPos] call pl_bounding_set;
            };
        };
        true
    };
    false
};

pl_bounding_set = {
    params ["_unit", "_wpPos"]; 

    doStop _unit;
    [_unit, false] call pl_enable_force_move;
    // [_unit, _unit getDir _wpPos, _wpPos] call pl_setUnitPos;
    _unit setVariable ["pl_bounding_set_time", time + 7];
    [_unit, 0, getDir _unit, true, [], "pl_on_march"] call pl_find_cover;
    [_unit] call pl_quick_suppress_unit;
};

pl_get_move_pos_array = { 
    params ["_team", "_wpPos", "_dirOffset", "_distanceOffset", "_MoveDistance"];
    _teamLeaderPos = getPos (_team#0);
    _moveDir = _teamLeaderPos getDir _wpPos;
    _teamLeaderMovePos = _teamLeaderPos getPos [_MoveDistance, _moveDir + (_dirOffset * 0.05)];
    _return = [_teamLeaderMovePos];
    for "_i" from 1 to (count _team) - 1 do {
        _p = _teamLeaderMovePos getPos [_distanceOffset * _i + ([-1, 1] call BIS_fnc_randomInt), _moveDir + _dirOffset];
        _p = [_p, 4] call pl_find_cover_postion;
        _return pushBack _p;
    };
    _return;
};

pl_bounding_switch = {
    params [["_mode", "team"]];
    if (count (hcSelected player) == 1) then {
        [_mode] spawn pl_bounding_squad;
    } else {
        [] spawn pl_vehicle_team_overwatch;
    };
};

pl_bounding_squad = {
    params ["_mode", ["_group", hcSelected player select 0], ["_wp", []]];
    private ["_cords", "_icon", "_group", "_team1", "_team2", "_MoveDistance", "_distanceOffset", "_movePosArrayTeam1", "_movePosArrayTeam2", "_unitPos", "_speed"];

    // if !(visibleMap) exitWith {hint "Open Map for bounding OW"};

    waitUntil {sleep 1; (currentWaypoint _group) == (_wp#1) or !(_group getVariable ["pl_on_march", false])};

    if !(_group getVariable ["pl_on_march", false]) exitWith {};

    sleep 0.1;

    private _units = units _group;
    _units = (units _group);
    _team1 = [];
    _team2 = [];

    _ii = 0;
    {
        if (_ii % 2 == 0) then {
            _team1 pushBack _x;
        }
        else
        {
            _team2 pushBack _x;
        };
        _ii = _ii + 1;
    } forEach (_units select {alive _x and !(_x getVariable ["pl_wia", false])});

    {
        doStop _x;
        _x disableAI "PATH";
        _x disableAI "AUTOCOMBAT";
        _x setUnitPosWeak "Middle";
        _x setVariable ["pl_damage_reduction", true];
        _x setHit ["legs", 0];
        _x setVariable ["pl_bounding_set_time", nil];
    } forEach _units;

    _group setBehaviourStrong "AWARE";

    switch (_mode) do { 
        case "team" : {_MoveDistance = 25; _distanceOffset = 6; _unitPos = "DOWN"; _speed = 5000}; 
        case "buddy" : {_MoveDistance = 40; _distanceOffset = 8; _unitPos = "MIDDLE"; _speed = 12}; 
        default {_MoveDistance = 25; _distanceOffset = 6; _unitPos = "DOWN", _speed = 5000, _mode = "team"}; 
    };

    // {
    //     _x limitSpeed _speed;
    // } forEach _team1;

    // _movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, 4, 4] call pl_get_move_pos_array;
    // _movePosArrayTeam1 = [_team1, waypointPosition _wp, -90, 4, 4] call pl_get_move_pos_array;

    // waitUntil {sleep 0.5; ([_team2, _movePosArrayTeam2, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team and [_team1, _movePosArrayTeam1, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team) or !(_group getVariable ["pl_on_march", false])};

    // _MoveDistance = 25;

    _movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, 6, 4] call pl_get_move_pos_array;
    _movePosArrayTeam1 = [_team1, waypointPosition _wp, -90, 6, 4] call pl_get_move_pos_array;

    waitUntil {sleep 0.5; [_team2, _movePosArrayTeam2, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team and [_team1, _movePosArrayTeam1, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team or !(_group getVariable ["pl_on_march", false])};

    private _currenAtctiveTeam = _team1; 
    while {({(_x distance2D (waypointPosition _wp)) < 15} count _units == 0) and !(waypoints _group isEqualTo []) and (_group getVariable ["pl_on_march", false])} do {

        _currenAtctiveTeam = _team1;

        ((_team1 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) playActionNow "GestureAdvance";
        ((_team1 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) groupRadio "SentConfirmMove";

        ((_team2 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) playActionNow "GestureCover";
        ((_team2 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) groupRadio "sentCovering";;

        _movePosArrayTeam1 = [_team1, waypointPosition _wp, -90, _distanceOffset, _MoveDistance] call pl_get_move_pos_array;
        {_x setVariable ["pl_bounding_set_time", nil]} forEach _team1;
        waitUntil {sleep 0.5; [_team1, _movePosArrayTeam1, waypointPosition _wp, _group] call pl_bounding_move_team};

        if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo []) or !(_group getVariable ["pl_on_march", false])) exitWith {};

        if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {
            if (pl_enable_beep_sound) then {playSound "radioina"};
            if (pl_enable_map_radio) then {[_group, "...Falling Back!", 20] call pl_map_radio_callout};
            if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Falling Back", (groupId _group)]};
            _retreatPos = (getPos (leader _group)) getPos [40, (waypointPosition _wp) getDir (leader _group)];
            [_group, _retreatPos, true] spawn pl_disengage;
        };

        sleep 0.5;

        _currenAtctiveTeam = _team2;

        ((_team2 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) playActionNow "GestureAdvance";
        ((_team2 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) groupRadio "SentConfirmMove";

        ((_team1 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) playActionNow "GestureCover";
        ((_team1 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) groupRadio "sentCovering";

        switch (_mode) do { 
            case "team" : {
                _MoveDistance = ((_team1#0) getPos [20, _team1#0 getDir (waypointPosition _wp)]) distance2D (_team2#0);
                _movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call pl_get_move_pos_array
            }; 
            case "buddy" : {_MoveDistance = 30; _movePosArrayTeam2 = _movePosArrayTeam1}; 
            default {_movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call pl_get_move_pos_array}; 
        };
        {_x setVariable ["pl_bounding_set_time", nil]} forEach _team2;
        waitUntil {sleep 0.5; [_team2, _movePosArrayTeam2, waypointPosition _wp, _group] call pl_bounding_move_team};

        if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo []) or !(_group getVariable ["pl_on_march", false])) exitWith {};

        if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {
                
            if (pl_enable_beep_sound) then {playSound "radioina"};
            if (pl_enable_map_radio) then {[_group, "...Falling Back!", 20] call pl_map_radio_callout};
            if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Falling Back", (groupId _group)]};
            _retreatPos = (getPos (leader _group)) getPos [40, (waypointPosition _wp) getDir (leader _group)];
            [_group, _retreatPos, true] spawn pl_disengage;
        };

        _MoveDistance = ((_team2#0) getPos [20, _team2#0 getDir (waypointPosition _wp)]) distance2D (_team1#0);

        sleep 0.5;
    };

    // systemChat (str (count (waypoints _group)));
    // systemChat (str (_wp#1));

    sleep 0.1;

    // if (_group getVariable ["pl_on_march", false]) then {
        if ((count (waypoints _group) - 1) > ((_wp#1))) then {
            _group setCurrentWaypoint ((waypoints _group)#((_wp#1) + 1));

            // {
            //     [_x] call pl_bounding_set;
            // } forEach _currenAtctiveTeam;
        } else {
            if (_group getVariable ["pl_task_planed", false]) then {
                _group setVariable ["pl_execute_plan", true];
            } else {
                [_group] call pl_reset;
            };

            // (leader _group) doMove (waypointPosition _wp);
        };
    // };
};


// count (waypoints (group player)) >= ((_wp#1) - 2)

pl_enable_force_move = {
    params ["_unit", "_state", ["_light", false]];
    if (_state) then {
        _unit forceSpeed 20;
        _unit setUnitPos "UP";
        _unit enableAI "PATH";
        _unit disableAI "COVER";
        _unit disableAI "SUPPRESSION";
        _unit setBehaviourStrong "AWARE";
        _unit disableAI "FIREWEAPON";
        // _unit setUnitCombatMode "WHITE";
        // if !(_light) then {
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            _unit disableAI "WEAPONAIM";
            _unit setUnitCombatMode "BLUE";
        // };
    }
    else
    {
        _unit forceSpeed -1;
        _unit enableAI "COVER";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "WEAPONAIM";
        _unit enableAI "FIREWEAPON";
        _unit setUnitCombatMode "YELLOW";
    };
};

pl_quick_suppress_unit = {
    params ["_unit"];

    private _target = selectRandom (((getPos _unit) nearEntities [["Man", "Car"], 500]) select {(side _x) != playerSide and (side _x) != civilian and (_unit knowsAbout _x) > 0.1});

    if (isNil "_target") exitWith {};

    [_target, _unit] spawn {
        params ["_target", "_unit"];

        sleep 1.5;

        private _targetPos = getPosASL _target;
        _targetPos = [_targetPos, _unit] call pl_get_suppress_target_pos;

        // _m = createMarker [str (random 1), _targetPos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerSize [0.5, 0.5];

        // _helper1 = createVehicle ["Sign_Sphere25cm_F", _targetpos, [], 0, "none"];
        // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
        // _helper1 setposASL _targetpos;

        if ((_targetPos distance2D _unit) > pl_suppression_min_distance and ([_unit, _targetPos] call pl_friendly_check)) then {

            _unit doWatch _targetPos;
            _unit doSuppressiveFire _targetPos;
        };
    };
};