pl_follow_active = false;
pl_follow_array = [];
pl_draw_formation_mouse = false;
pl_draw_vic_advance_wp_array = [];
pl_draw_sync_wp_array = [];

pl_set_waypoint = {
    params ["_group"];
    private ["_cords"];

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

    [_group] call pl_reset;
    sleep 0.2;

    _group setVariable ["pl_on_march", true];
    _mwp = _group addWaypoint [_cords, 0];
    _group setVariable ["pl_mwp", _mwp];
    
    if (vehicle (leader _group) != (leader _group)) then {
        vehicle (leader _group) doMove _cords;
        vehicle (leader _group) setDestination [_cords,"VEHICLE PLANNED" , true];
    };

    if ((vehicle player) != player) then {
        if (effectiveCommander (vehicle player) == player) then {
            driver (vehicle player) commandMove _cords;
            vehicle (player) setDestination [_cords,"VEHICLE PLANNED" , true];

        };
    };

    sleep 1;
    waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition (_group getVariable ["pl_mwp", (currentWaypoint _group)]))) < 11) or (isNil {_group getVariable ["pl_on_march", nil]})};
    _group setVariable ["pl_on_march", nil];
};

// {if ((count (waypoints _x)) == 0) then {
//     [_x, false] spawn pl_reset}
// } forEach (hcSelected player);
//  playSound 'beep';
//   if (count (hcSelected player) > 1 and (!pl_draw_formation_mouse)) then {
//     [hcSelected player, true] spawn pl_move_as_formation
// };
// if (count (hcSelected player) <= 1) then {['MOVE',_pos,_is3D,hcselected player,true] call BIS_HC_path_menu;
// driver (vehicle player) commandMove (waypointPosition ((waypoints (group player)) select (currentWaypoint (group player))));

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
            sleep 0.25
            [_group] call pl_reset;
            // [_group] call pl_reset;
            // sleep 1;
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

        waitUntil {sleep 0.1; (leader _group) checkAIFeature "AUTOCOMBAT"};
        _group setVariable ["pl_on_march", true];
        {
            _x disableAI "AUTOCOMBAT";
            _x setHit ["legs", 0];
        } forEach (units _group);
        (leader _group) limitSpeed 14;
        // _group setFormation "FILE";
        _group setBehaviourStrong "AWARE";

        if (_doBounding and (vehicle (leader _group)) == (leader _group)) then {
            [_group] spawn pl_bounding_move_simple;
        };

        sleep 1;
        waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition (_group getVariable ["pl_mwp", (currentWaypoint _group)]))) <= 10) or (isNil {_group getVariable ["pl_on_march", nil]})};
        _group setVariable ["pl_on_march", nil];
        // _group setVariable ["setSpecial", false];
        // {
        //     _x enableAI "AUTOCOMBAT";
        // } forEach (units _group);
        // (leader _group) limitSpeed 5000;
        
    }
    else
    {

        _mwp = _group addWaypoint [_cords, 0];

        // if (_doBounding and (vehicle (leader _group)) == (leader _group)) then {
        //     _mwp setWaypointCompletionRadius 20;
        // };

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

pl_bounding_move_simple = {
    params ["_group"];    

    private _units = (units _group);
    private _team1 = [];
    private _team2 = [];

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
    } forEach (_units select {alive _x});

    {
        _x disableAI "AUTOCOMBAT";
        _x setVariable ["pl_damage_reduction", true];
        _x limitSpeed 1000;
    } forEach _units;
    _group setBehaviourStrong "AWARE";

    private _wpPos = waypointPosition ((waypoints _group)#((currentWaypoint _group)));
    private _timeout = time;

    private _fncTakeCoverAction = {
        params ["_unit"];

        // doStop _unit;
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit forceSpeed -1;
        _unit disableAI "PATH";
        // _unit setUnitPos (selectRandom ["Middle", "Down"]);
        [_unit, getDir _unit, _unit getPos [500, getdir _unit]] call pl_setUnitPos;
        // [_unit, 8, getDir _unit, true, [], "pl_on_march"] call pl_find_cover;
        sleep 0.2;
        [_unit] call pl_quick_suppress_unit;
    };

    private _fncAdvanceAction = {
        params ["_unit", "_wpPos", "_idx"];

        _unit enableAI "PATH";
        _unit setUnitPos "AUTO";
        _unit disableAI "AUTOTARGET";
        _unit disableAI "TARGET";
        _unit forceSpeed 20;
        _unit setHit ["legs", 0];
        doStop _unit;
        sleep 0.1;
        if (_unit != (leader _unit)) then {
            private _movePos = _wpPos getPos [8 * _idx, (_unit getDir _wpPos) + 90];
            _unit domove _movePos;

            // _m = createMarker [str (random 1), _movePos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];

        } else {
            _unit doMove _wpPos;
        };
    };

    private _idx = 0;
    while {(_group getVariable ["pl_on_march", false])} do {

        _wpPos = waypointPosition ((waypoints _group)#((currentWaypoint _group)));

        _idx = 0;
        {
            [_x, _wpPos, _idx] spawn _fncAdvanceAction;
            _idx = _idx + 1;
        } forEach (_team1 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"});

        ((_team1 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) playActionNow "GestureAdvance";
        ((_team1 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) groupRadio "SentConfirmMove";

        {
            [_x] spawn _fncTakeCoverAction;
        } forEach _team2;

        ((_team2 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) playActionNow "GestureCover";
        ((_team2 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) groupRadio "sentCovering";;

        _timeout = time + 8;

        waitUntil {sleep 0.5; time >= _timeOut or (_group getVariable ["pl_stop_event", false]) or !(_group getVariable ["pl_on_march", false])};

        if ((_group getVariable ["pl_stop_event", false]) or !(_group getVariable ["pl_on_march", false])) exitWith {};


        _wpPos = waypointPosition ((waypoints _group)#((currentWaypoint _group)));
        // _movePos = [[[_wpPos, 8]], ["water"]] call BIS_fnc_randomPos;

        _idx = 0;
        {
            [_x, _wpPos, _idx] spawn _fncAdvanceAction;
            _idx = _idx + 1;
        } forEach (_team2 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"});

        ((_team2 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) playActionNow "GestureAdvance";
        ((_team2 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) groupRadio "SentConfirmMove";

        {
            [_x] spawn _fncTakeCoverAction;
        } forEach _team1;

        ((_team1 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) playActionNow "GestureCover";
        ((_team1 select {alive _x and lifeState _x isNotEqualto "INCAPACITATED"})#0) groupRadio "sentCovering";;

        _timeout = time + 8;

        waitUntil {sleep 0.5; time >= _timeOut or (_group getVariable ["pl_stop_event", false]) or !(_group getVariable ["pl_on_march", false])};

        if ((_group getVariable ["pl_stop_event", false]) or !(_group getVariable ["pl_on_march", false])) exitWith {};
    };

    {
        _x enableAI "AUTOCOMBAT";
        _x enableAI "PATH";
        _x enableAI "AUTOTARGET";
        _x enableAI "TARGET";
        _x setUnitPos "AUTO";
        _x forceSpeed -1;
        _x doFollow (leader _group);
        _x setVariable ["pl_damage_reduction", false];
    } forEach _units;

    systemChat "end";
};

pl_move_team_to_array = {
    params ["_team", "_movePosArray", "_cords", "_group", ["_targets", []]];

    for "_i" from 0 to (count _team) - 1 do {
        _unit = _team#_i;
        _movePos = _movePosArray#_i;
        // _movePos = _movePos findEmptyPosition [0, 20, typeOf _unit];
        _movePos = [_movePos, 8] call pl_find_cover_postion;
        if ((_unit distance2D _movePos) > 4) then {
            if (currentCommand _unit isNotEqualTo "MOVE" or (speed _unit) == 0) then {
                doStop _unit;
                if (_targets isEqualto []) then {
                    [_unit, true] call pl_enable_force_move;
                } else {
                    [_unit, true, true] call pl_enable_force_move;
                };


                _unit setHit ["legs", 0];
                _unit setUnitPos "UP";
                _unit doMove _movePos;
                // _unit setDestination [_movePos, "LEADER DIRECT", true];

            };
        }
        else
        {
            if ((_unit getVariable ["pl_bounding_set_time", 0]) == 0) then {
                [_unit, _cords] call pl_bounding_set;
            };
        };
    };
    if (({currentCommand _x isEqualTo "MOVE"} count (_team select {alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")})) == 0 or ({(_x distance2D _cords) < 15} count _team > 0) or !(_group getVariable ["onTask", false])) exitWith {true};
    if ({time > (_x getVariable ["pl_bounding_set_time", time])} count _team > 0) exitWith {
        for "_i" from 0 to (count _team) - 1 do {
            _unit = _team#_i;
            _movePos = _movePosArray#_i;
            if ((_unit distance2D _movePos) > 4) then {
                _unit setPos ([-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd (getPos _unit));
                [_unit, _cords] call pl_bounding_set;
            };
        };
        true
    };
    false
};


pl_bounding_move_team = {
    params ["_team", "_movePosArray", "_wpPos", "_group", "_targets"];

    for "_i" from 0 to (count _team) - 1 do {
        _unit = _team#_i;
        _movePos = _movePosArray#_i;
        // _movePos = [_movePos, 8] call pl_find_cover_postion;
        // _movePos = _movePos findEmptyPosition [0, 20, typeOf _unit];
        if ((_unit distance2D _movePos) > 4) then {
            if (currentCommand _unit isNotEqualTo "MOVE" or (speed _unit) == 0) then {
                doStop _unit;
                if (_targets isEqualto []) then {
                    [_unit, true] call pl_enable_force_move;
                } else {
                    [_unit, true, true] call pl_enable_force_move;
                };

                _unit setHit ["legs", 0];
                _unit setUnitPos "UP";
                _unit doMove _movePos;
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
                // _unit setPos ([-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd (getPos _unit));
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
    [_unit, _unit getDir _wpPos, _wpPos] call pl_setUnitPos;
    _unit setVariable ["pl_bounding_set_time", time + 7];
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
    params ["_mode", ["_group", hcSelected player select 0], ["_cords", []]];
    private ["_cords", "_icon", "_group", "_team1", "_team2", "_MoveDistance", "_distanceOffset", "_movePosArrayTeam1", "_movePosArrayTeam2", "_unitPos", "_speed"];

    // if !(visibleMap) exitWith {hint "Open Map for bounding OW"};

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    private _drawSpecial = false;

    if (_cords isEqualTo []) then {
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
        
        _moveDir = (leader _group) getDir _cords;

        // if (pl_enable_beep_sound) then {playSound "beep"};
        _drawSpecial = true;
        [_group, "confirm", 1] call pl_voice_radio_answer;
        [_group] call pl_reset;

        sleep 0.5;

        [_group] call pl_reset;

        sleep 0.5;
        
        switch (_mode) do { 
            case "team" : {_icon = "\Plmod\gfx\team_bounding.paa";}; 
            case "buddy" : {_icon = "\Plmod\gfx\buddy_bounding.paa";}; 
            default {_icon = "\Plmod\gfx\team_bounding.paa";}; 
        };
        
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", _icon];
    };

    _wp = _group addWaypoint [_cords, 0];

    if (_drawSpecial) then {
        pl_draw_planed_task_array pushBack [_wp, _icon];
    };

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

    _group setBehaviour "AWARE";

    // _mode = "buddy";

    switch (_mode) do { 
        case "team" : {_MoveDistance = 25; _distanceOffset = 4; _unitPos = "DOWN"; _speed = 5000}; 
        case "buddy" : {_MoveDistance = 40; _distanceOffset = 8; _unitPos = "MIDDLE"; _speed = 12}; 
        default {_MoveDistance = 25; _distanceOffset = 4; _unitPos = "DOWN", _speed = 5000, _mode = "team"}; 
    };

    // {
    //     _x limitSpeed _speed;
    // } forEach _team1;

    _movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, 4, 4] call pl_get_move_pos_array;
    _movePosArrayTeam1 = [_team1, waypointPosition _wp, -90, 4, 4] call pl_get_move_pos_array;

    waitUntil {sleep 0.5; [_team2, _movePosArrayTeam2, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team and [_team1, _movePosArrayTeam1, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team};

    // {
    //     [_x, _x getDir _cords, _cords] call pl_setUnitPos;
    // } forEach _team2;

    // _MoveDistance = 25;
    while {({(_x distance2D (waypointPosition _wp)) < 15} count _units == 0) and !(waypoints _group isEqualTo [])} do {

        (_team1#0) groupRadio "SentConfirmMove";
        _movePosArrayTeam1 = [_team1, waypointPosition _wp, -90, _distanceOffset, _MoveDistance] call pl_get_move_pos_array;
        {_x setVariable ["pl_bounding_set_time", nil]} forEach _team1;
        _targets = (_team1#0) targets [true, (_team1#0) distance2d (_movePosArrayTeam1#0) , [], 0, _movePosArrayTeam1#0];
        waitUntil {sleep 0.5; [_team1, _movePosArrayTeam1, waypointPosition _wp, _group, _targets] call pl_bounding_move_team};
        if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo [])) exitWith {};
        if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {[_group] call pl_reset};

        // {
        //     if ((_x getVariable ["pl_bounding_set_time", 0]) == 0) then {
        //         _x setPos ([-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd (getPos _x));
        //         [_x, waypointPosition _wp, _unitPos] call pl_bounding_set;
        //     };
        // } forEach _team1;

        (_team1#0) groupRadio "sentCovering";
        _targets = (_team1#0) targets [true, (_team1#0) distance2d (waypointPosition _wp) , [], 0, waypointPosition _wp];
        // if (count _targets > 0 and _mode isEqualTo "team") then {{[_x, getPosASL (selectRandom _targets)] call pl_quick_suppress} forEach _team1};
        if (count _targets > 0) then {{[_x, selectRandom _targets, true] call pl_quick_suppress; [_x, selectRandom _targets] spawn pl_fire_ugl_at_target} forEach _team1};

        sleep 1;

        (_team2#0) groupRadio "SentConfirmMove";
        switch (_mode) do { 
            case "team" : {_MoveDistance = 50; _movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call pl_get_move_pos_array}; 
            case "buddy" : {_MoveDistance = 30; _movePosArrayTeam2 = _movePosArrayTeam1}; 
            default {_movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call pl_get_move_pos_array}; 
        };
        {_x setVariable ["pl_bounding_set_time", nil]} forEach _team2;
        _targets = (_team1#0) targets [true, (_team1#0) distance2d (_movePosArrayTeam1#0) , [], 0, _movePosArrayTeam1#0];
        waitUntil {sleep 0.5; [_team2, _movePosArrayTeam2, waypointPosition _wp, _group, _targets] call pl_bounding_move_team};

        if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo [])) exitWith {};
        if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {[_group] call pl_reset};

        // {
        //     if ((_x getVariable ["pl_bounding_set_time", 0]) == 0) then {
        //         _x setPos ([-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd (getPos _x));
        //         [_x, waypointPosition _wp, _unitPos] call pl_bounding_set;
        //     };
        // } forEach _team2;
        
        (_team2#0) groupRadio "sentCovering";
        _targets = (_team2#0) targets [true, (_team2#0) distance2d (waypointPosition _wp), [], 0, waypointPosition _wp];
        if (count _targets > 0 and _mode isEqualTo "team") then {{[_x, selectRandom _targets, true] call pl_quick_suppress; [_x, selectRandom _targets] spawn pl_fire_ugl_at_target} forEach _team2};

        sleep 1;
    };

    {
        doStop _x;
        _x setVariable ["pl_damage_reduction", false];
        _x setUnitPos "Auto";
        _x enableAI "PATH";
        _x enableAI "AUTOCOMBAT";
        _x enableAI "COVER";
        _x enableAI "AUTOTARGET";
        _x enableAI "TARGET";
        _x enableAI "SUPPRESSION";
        _x enableAI "WEAPONAIM";
        _x setUnitCombatMode "YELLOW";
        _x doFollow (leader _group);
        _x limitSpeed 5000;
        _x forceSpeed -1;
        _x setVariable ["pl_bounding_set_time", nil];
    } forEach _units;
    

    if (_drawSpecial) then {
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
        _group setVariable ["setSpecial", false];
    };

    [_team1,_team2]
};




pl_vehicle_team_overwatch = {
    private ["_cords", "_moveDir"];
    
    private _groups = hcSelected player;

    private _vics = [];

    {
        if (vehicle (leader _x) != (leader _x)) then {
            if ([vehicle (leader _x)] call pl_canMove) then {
                _vics pushBackUnique (vehicle (leader _x));
            };
        };
    } forEach _groups;

    if ((count _vics) != 2) exitWith {hint "Select only TWO functional Vehicles or ONE Infantry Group!"};

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
    

    _vics = [_vics, [], {_cords distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;

    _vic_1 = _vics#0;
    _vicGroup_1 = group (driver _vic_1);
    _vic_2 = _vics#1;
    _vicGroup_2 = group (driver _vic_2);

    [_vicGroup_1, "confirm", 1] call pl_voice_radio_answer;

    [_vicGroup_1] call pl_reset;
    [_vicGroup_2] call pl_reset;

    sleep 0.5;

    [_vicGroup_1] call pl_reset;
    [_vicGroup_2] call pl_reset;

    sleep 0.5;

    _fnc_get_speed = {  
        params ["_vic"];

        if ((group (driver _vic)) getVariable ["pl_vic_attached", false]) exitWith {3};

        private _r = 6;
        switch (_vic getVariable ["pl_speed_limit", "50"]) do { 
            case "15" : {_r = 3}; 
            case "30" : {_r = 6};
            case "50" : {_r = 10};
            case "CON" : {_r = 3};
            default {_r = 6}; 
        };
        _r
    };

    {   
        _x setVariable ["onTask", true];
        _x setVariable ["setSpecial", true];
        _x setVariable ["specialIcon", "\Plmod\gfx\team_bounding.paa"];
        
    } forEach _groups;

    // pl_follow_array_other = pl_follow_array_other + [[_vicGroup_1, _vicGroup_2]];

    // pl_draw_disengage_array pushBack [_vicGroup_1, _cords];

    private _moveDistanceRaw = 50;
    private _moveDistance = _moveDistanceRaw;

    _distanceToCords = _vic_1 distance2D _cords;
    private _intervals = round (_distanceToCords / (_moveDistance * 2));
    private _cordsDir = _vic_1 getDir _cords;

    _rightPos = (getPos _vic_1) getPos [30, _cordsDir + 90];
    _leftPos = (getPos _vic_1) getPos [30, _cordsDir - 90];

    _movePos = ([[_leftPos, _rightPos], [], {_vic_2 distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;

    private _reverse = false;
    _relDir = _vic_1 getRelDir _cords;
    if (_relDir >= 90 and _relDir <= 270) then {_reverse = true};

    _wp1 = _vicGroup_1 addWaypoint [_cords, 0];
    _wp2 = _vicGroup_2 addWaypoint [_cords getpos [30, _vic_1 getDir _movePos], 0];

    doStop _vic_1;
    doStop _vic_2;

    {
        _x disableAI "PATH";
    } forEach ((units _vicGroup_1) + (units _vicGroup_2));

    if !(_reverse) then {
        [_vic_1, (getpos _vic_1) getPos [50, _cordsDir]] spawn pl_vic_turn_in_place;
        if (_vic_2 distance2D _movePos > 5) then {
            [_vic_2, _movePos, [_vic_2] call _fnc_get_speed] call pl_vic_advance_to_pos_static;
        };
        [_vic_2, (getpos _vic_2) getPos [50, _cordsDir]] call pl_vic_turn_in_place;
    } else {
        [_vic_1, (getpos _vic_1) getPos [-50, _cordsDir]] spawn pl_vic_turn_in_place;
        if (_vic_2 distance2D _movePos > 5) then {
            [_vic_2, _movePos, [_vic_2] call _fnc_get_speed] call pl_vic_reverse_to_pos;
        };
        [_vic_2, (getpos _vic_2) getPos [-50, _cordsDir]] call pl_vic_turn_in_place;
    };

    for "_i" from 0 to _intervals - 1 do {

        if (_moveDistance > (_vic_1 distance2D _cords)) then {_moveDistance = _vic_1 distance2D _cords};    

        if !(_reverse) then {
            [_vic_1, (getpos _vic_1) getPos [_moveDistance, _vic_1 getDir _cords], [_vic_1] call _fnc_get_speed, 1] call pl_vic_advance_to_pos_static;
        } else {
            [_vic_1, (getpos _vic_1) getPos [_moveDistance, _vic_1 getDir _cords], [_vic_1] call _fnc_get_speed, 1] call pl_vic_reverse_to_pos;
        };

        sleep 0.5;

        _moveDistance = _moveDistanceRaw * 2;

        if (!(_vicGroup_1 getVariable ["onTask", false]) or !(_vicGroup_2 getVariable ["onTask", false])) exitWith {};

        if (_moveDistance > (_vic_2 distance2D _cords)) then {_moveDistance = _vic_2 distance2D _cords}; 

        if !(_reverse) then {
            [_vic_2, (getpos _vic_2) getPos [_moveDistance, _vic_1 getDir _cords], [_vic_2] call _fnc_get_speed, 1] call pl_vic_advance_to_pos_static;
        } else {
            [_vic_2, (getpos _vic_2) getPos [_moveDistance, _vic_1 getDir _cords], [_vic_2] call _fnc_get_speed, 1] call pl_vic_reverse_to_pos;
        };

        if (!(_vicGroup_1 getVariable ["onTask", false]) or !(_vicGroup_2 getVariable ["onTask", false])) exitWith {};
    };

    _vics = [_vics, [], {_cords distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;

    _vic_1 = _vics#0;
    _vic_2 = _vics#1;

    _rightPos = (getPos _vic_1) getPos [30, _cordsDir + 90];
    _leftPos = (getPos _vic_1) getPos [30, _cordsDir - 90];

    _movePos = ([[_leftPos, _rightPos], [], {_vic_2 distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;

    if !(_reverse) then {
        if (_vic_2 distance2D _movePos > 5) then {
            [_vic_2, _movePos, [_vic_2] call _fnc_get_speed] call pl_vic_advance_to_pos_static;
        };
        [_vic_2, (getpos _vic_2) getPos [50, _cordsDir]] call pl_vic_turn_in_place;
    } else {
        if (_vic_2 distance2D _movePos > 5) then {
            [_vic_2, _movePos, [_vic_2] call _fnc_get_speed] call pl_vic_reverse_to_pos;
        };
        [_vic_2, (getpos _vic_2) getPos [-50, _cordsDir]] call pl_vic_turn_in_place;
    };

    // pl_follow_array_other = pl_follow_array_other - [[_vicGroup_1, _vicGroup_2]];
    // pl_draw_disengage_array =  pl_draw_disengage_array - [[_vicGroup_1, _cords]];

    {   
        [_x] spawn pl_reset;
    } forEach _groups;


};


pl_follow = {
    params ["_arrayId"];
    private ["_formDir", "_posOffset", "_pGroup", "_pSpeed", "_pBehaviour"];
    pl_follow_array append hcSelected player;
    pl_follow_active = true;
    _formDir = getDir player;
    {
        if (_x != (group player)) then {
            [_x] call pl_reset;
            sleep 0.5;
            [_x] call pl_reset;
            sleep 0.5;

            _x setVariable ["onTask", true];
            _x setVariable ["setSpecial", true];
            _x setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa"];
            // if (pl_enable_beep_sound) then {playSound "beep"};
            [_x, "confirm", 1] call pl_voice_radio_answer;
            // leader _x sideChat format ["%1 is forming up on %2, over",(groupId _x), (groupId (group player))];
            _pos1 = getPos (leader _x);
            _pos2 = getPos player;
            _relPos = [(_pos1 select 0) - (_pos2 select 0), (_pos1 select 1) - (_pos2 select 1)];
            _x setVariable ["pl_rel_pos", _relPos];
            {
                _x disableAI "AUTOCOMBAT";
            } forEach (units _x);
            _x setFormDir _formDir;
        };
    } forEach pl_follow_array;
    _pGroup = (group player);
    _pGroup setVariable ["onTask", true];
    _pGroup setVariable ["setSpecial", true];
    _pGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\whiteboard_ca.paa"];
    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _pGroup);
    pl_follow_array = pl_follow_array - [_pGroup];

    if (pl_follow_active) then {
        while {pl_follow_active} do {
            _pos1 = getPos player;
            sleep 0.5;
            _pos2 = getPos player;
            _posOffset = [(_pos2 select 0) - (_pos1 select 0), (_pos2 select 1) - (_pos1 select 1)];
            _pBehaviour = behaviour player;
            // _pSpeed = speed player + 1;
            // if (_pSpeed < 12) then {
            //     _pSpeed = 12;
            // };
            {
                _x setBehaviour _pBehaviour;
                if (!(_x getVariable "onTask") or ((count (waypoints _x) > 0))) then {
                    pl_follow_array = pl_follow_array - [_x];
                    _x setVariable ["onTask", false];
                    _x setVariable ["setSpecial", false];
                    {
                        _x enableAI "AUTOCOMBAT";
                    } forEach (units _x);
                }
                else
                {
                    _leader = leader _x;
                    _relPos = _x getVariable "pl_rel_pos";
                    if (vehicle _leader != _leader) then {
                        (vehicle _leader) limitSpeed (speed player) + 5;
                        if ((speed (vehicle _leader)) > 1) then {
                            _newPos = [((getPos _leader) select 0) + ((_posOffset select 0) * 15), ((getPos _leader) select 1) + ((_posOffset select 1) * 15)];
                            (vehicle _leader) doMove _newPos;
                            (vehicle _leader) setDestination [_newPos, "VEHICLE PLANNED" , false];
                        };
                        if ((speed player) > 1) then {
                            _newPos = [((getPos player) select 0) + (_relPos select 0), ((getPos player) select 1) + (_relPos select 1)];
                            (vehicle _leader) doMove _newPos;
                            (vehicle _leader) setDestination [_newPos, "VEHICLE PLANNED" , false];
                        };
                    }
                    else
                    {
                        _newPos = [((getPos player) select 0) + (_relPos select 0), ((getPos player) select 1) + (_relPos select 1)];
                        _leader limitSpeed 15;
                        _leader doMove _newPos;
                        (vehicle _leader) setDestination [_newPos, "VEHICLE PLANNED" , false];
                        {
                            if (_x != _leader) then {
                                _x doFollow _leader;
                            };
                        } forEach (units _x);
                    };
                };
            } forEach pl_follow_array;
            if ((count pl_follow_array) == 0) exitWith {pl_follow_active = false};
            if !((group player) getVariable "onTask") exitWith {pl_follow_active = false};
        };
        {
            _x setVariable ["onTask", false];
            _x setVariable ["setSpecial", false];
            {
                _x enableAI "AUTOCOMBAT";
            } forEach (units _x);
        } forEach pl_follow_array;
        pl_follow_array = [];
        _pGroup setVariable ["onTask", false];
        _pGroup setVariable ["setSpecial", false];
    };
};


pl_move_as_formation = {
    params [["_groups", hcSelected player], ["_firstCall", false], ["_lastWps", []]];
    private ["_cords", "_wpPos", "_pos1", "_pos2", "_syncWps", "_infIncluded"];

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader _group] call pl_open_tac_forced;
        };
    };

    _infIncluded = {
        if (vehicle (leader _x) == leader _x) exitWith {true};
        false
    } forEach _groups;

    // choose formationleader -> first group in array every Position will be calculated relatic to leader
    _formationLeaderGroup = _groups#0;

    // get WP Position of FormationLeader or current position if no waypoint and add to indicator array
    _wpsL = waypoints _formationLeaderGroup;
    if !(_wpsL isEqualTo []) then {
        _wpPos = waypointPosition (_wpsL select ((count _wpsL) - 1)); //getPos (leader _formationLeaderGroup);
    }
    else
    {
        _wpPos = getPos (leader _formationLeaderGroup)
    };
    if (isNil "_wpPos") then {_wpPos = getPos (leader _formationLeaderGroup)};
    pl_draw_formation_move_mouse_array = [[vehicle (leader _formationLeaderGroup), [0,0], _wpPos]];

    // calc relativ position to formationleader for every other group and add to indicator array
    {
        _wps1 = waypoints _x;
        if !(_wps1 isEqualTo []) then {
            _pos1 = waypointPosition (_wps1 select ((count _wps1) - 1)); //getPos (leader _x);
        }
        else
        {
            _pos1 = getPos (leader _x);
        };
        _wps2 = waypoints _formationLeaderGroup;
        if !(_wps2 isEqualTo []) then {
            _pos2 = waypointPosition (_wps2 select ((count _wps2) - 1)); //getPos (leader _formationLeaderGroup);
        }
        else
        {
            _pos2 = getPos (leader _formationLeaderGroup);
        };
        _relPos = [(_pos1 select 0) - (_pos2 select 0), (_pos1 select 1) - (_pos2 select 1)];
        pl_draw_formation_move_mouse_array pushBack [vehicle (leader _x), _relPos, _pos1];
        // _x setBehaviourStrong "COMBAT";
    } forEach (_groups) - [_formationLeaderGroup];

    // _formationLeaderGroup setBehaviourStrong "COMBAT";
    // draw Indicator and wait for mouseclick;

    if (_firstCall) then {
        showCommandingMenu "";
        {
            if ((count (waypoints _x)) == 0 and !(_x getVariable ["pl_on_hold", false])) then {[_x, false] spawn pl_reset};
        } forEach _groups;
        sleep 0.5;
     };
    pl_draw_formation_mouse = true;

    waitUntil {inputAction "defaultAction" > 0 or inputAction "zoomTemp" > 0};

    sleep 0.05;

    pl_draw_formation_move_mouse_array = [];

    if (inputAction "zoomTemp" > 0) exitWith {
        pl_draw_formation_mouse = false;
        if !(_lastWps isEqualTo []) then {
            {
                _x setWaypointStatements ["true", "(vehicle (leader this)) limitSpeed 50; (vehicle (leader this)) setVariable ['pl_speed_limit', '50'];"];
            } forEach _lastWps;
        };
    };

    // if (_infIncluded) then {
        {
            if (vehicle (leader _x) != leader _x) then {
                (vehicle (leader _x)) limitSpeed 30;
                (vehicle (leader _x)) setVariable ["pl_speed_limit", "CON"];
            };
        } forEach _groups;
    // };

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    } else {
        _cords = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
    };

    // calc new Move position relativ ro mouseposition and add Waypoints
    _syncWps = [];

    // 1. set position or wpPosition of Formationleader as absolute
    _wps2 = waypoints _formationLeaderGroup;
    if !(_wps2 isEqualTo []) then {
        _pos2 = waypointPosition (_wps2 select ((count _wps2) - 1)); //getPos (leader _formationLeaderGroup);
    }
    else
    {
        _pos2 = getPos (leader _formationLeaderGroup);
    };

    // 2. add wp for formationleader;
    _lWp = _formationLeaderGroup addWaypoint [_cords, 0];
    _formationLeaderGroup setVariable ["pl_wait_wp", _lWp];
    _syncWps = [_lWp];
    _lwp setWaypointStatements ["true", "(group this) setVariable ['pl_last_wp_pos', getPos this]"];
    // _syncWps pushBack _lWp;

    // 3. calc waypoint for other groups relativ to Formationleader and add WP
    {
        _wps1 = waypoints _x;
        if !(_wps1 isEqualTo []) then {
            _pos1 = waypointPosition (_wps1 select ((count _wps1) - 1)); //getPos (leader _x);
        }
        else
        {
            _pos1 = getPos (leader _x);
        };
        _relPos = [(_pos1 select 0) - (_pos2 select 0), (_pos1 select 1) - (_pos2 select 1)];
        _newPos = _relPos vectorAdd _cords;
        // _newPos = [_newPos#0, _newPos#1];
        _gWp = _x addWaypoint [_newPos, 0];
        _gwp setWaypointStatements ["true", "(group this) setVariable ['pl_last_wp_pos', getPos this]"];
        // _gWp synchronizeWaypoint _syncWps;
        _syncWps pushBack _gWp;
    } forEach _groups - [_formationLeaderGroup];

    _syncWps = [_syncWps, [], {(waypointPosition _x) distance2D (waypointPosition _lWp)}, "ASCEND"] call BIS_fnc_sortBy;

    // pl_draw_sync_wp_array pushBack _syncWps;

    if (inputAction "curatorGroupMod" > 0) exitWith {sleep 0.4; [_groups, false, _syncWps] spawn pl_move_as_formation};
    pl_draw_formation_mouse = false;
};




pl_onMapSingleClick_column = {

    onMapSingleClick {

        pl_draw_convoy_path_array = pl_draw_convoy_path_array - [pl_column_passigPoints];

        private _rangelimiterCenter = pl_column_passigPoints#((count pl_column_passigPoints) - 1);

        if (_shift) then {pl_cancel_strike = true; pl_mapClicked = true};
        if (inputAction "curatorGroupMod" <= 0) then {
            pl_mapClicked = true;
        } else {
            if ((_pos distance2D _rangelimiterCenter) <= 150) then {
                pl_column_passigPoints pushBack _pos;
            };
            pl_draw_convoy_path_array pushback pl_column_passigPoints;
            [] spawn pl_onMapSingleClick_column;
        };
        hintSilent "";
        onMapSingleClick "";

        // _m = createMarker [str (random 2), _pos];
        // _m setMarkerType "mil_dot";
    };
};



pl_move_as_column = {
    private ["_mPos"];

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader (_groups#0)] call pl_open_tac_forced;
        };
    };

    private _allgroups = hcSelected player;
    private _groups = +_allGroups;
    pl_column_passigPoints = [[_groups] call pl_find_centroid_of_groups];

    private _rangelimiter = 150;
    private _rangelimiterCenter = pl_column_passigPoints#0;
    _markerBorderName = str (random 2);
    createMarker [_markerBorderName, _rangelimiterCenter];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorOrange";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];


    player enableSimulation false;

    
    [] spawn pl_onMapSingleClick_column;


    while {!pl_mapClicked} do {
        _markerBorderName setMarkerPos (pl_column_passigPoints#((count pl_column_passigPoints) - 1));
        sleep 0.1;
    };

    player enableSimulation true;

    pl_mapClicked = false;

    deleteMarker _markerBorderName;

    pl_draw_convoy_path_array = pl_draw_convoy_path_array - [pl_column_passigPoints];

    pl_column_passigPoints deleteAt 0;
    _passigPoints = +pl_column_passigPoints;

    _start = _passigPoints#0;

    _groups = ([_groups, [], {(leader _x) distance2D _start}, "ASCEND"] call BIS_fnc_sortBy);
    _convoyLeaderGroup = _groups#0;
    _convoyLeader = vehicle (leader _convoyLeaderGroup);

    _passigPoints insert [0, [getPos _convoyLeader]];


    sleep 0.1;
    private _convoy = +_groups;
    reverse _convoy;
    pl_draw_convoy_array pushBack _convoy;
    private _convoyPath = +_passigPoints;
    _convoyPath insert [0, [getPos _convoyLeader]];
    pl_draw_convoy_path_array pushback _passigPoints;

    {
        // if !(_x == _convoyLeaderGroup) then {
        //     player hcRemoveGroup _x;
        // };
        [_x] call pl_reset;
        _x setVariable ["pl_draw_convoy", true];
    } forEach _groups;

    for "_i" from 0 to (count _groups) - 1 do {
        // doStop (vehicle (leader _x));

        private _group = _groups#_i;
        private _vic = vehicle (leader _group);
        _vic limitSpeed pl_convoy_speed;
        _vic setVariable ["pl_speed_limit", "CON"];
        _group setVariable ["onTask", true];

        _conWp = _group addWaypoint [(_passigPoints#((count _passigPoints) - 1)) getPos [15 * _i, (_passigPoints#((count _passigPoints) - 1)) getDir (_passigPoints#((count _passigPoints) - 2))], 0];
        _group setVariable ["pl_conWp", _conWp];
        // _vic setConvoySeparation 5;
        // _vic forceFollowRoad true;
        _group setVariable ["pl_pp_idx", 0];

        {
            _x disableAI "AUTOCOMBAT";
        } forEach (units _group);
        // _group setBehaviourStrong "SAFE";
        [getPos _vic, 3] call pl_clear_obstacles;
        _vic doMove (_passigPoints#0);
        _vic setDestination [(_passigPoints#0),"VEHICLE PLANNED" , true];

        // _vic setDriveOnPath (_group getVariable "pl_convoy_path");

        if (_vic != _convoyLeader) then {

            // player hcRemoveGroup _group;

            [_group ,_vic, _convoyLeader, _groups, _i, _convoyLeaderGroup, _passigPoints] spawn {
                params ["_group" , "_vic", "_convoyLeader", "_groups", "_i", "_convoyLeaderGroup", "_passigPoints"];
                private ["_ppidx", "_time"];

                // _vic setDriveOnPath (_group getVariable "pl_convoy_path");

                _ppidx = 0;
                private _forward = vehicle (leader (_groups#(_i - 1)));
                private _startReset = false;
                while {(_convoyLeaderGroup getVariable ["onTask", true]) and ((_groups#(_i - 1)) getVariable ["onTask", true])} do {

                    if (!alive _vic or ({alive _x and (lifeState _x) != "INCAPACITATED"} count (units _group)) <= 0) exitWith {};
                    if (!(alive _convoyLeader) or !(alive _forward)) exitWith {};

                    _ppidx = _group getVariable "pl_pp_idx";
                    if (_vic distance2D (_passigPoints#_ppidx) < 35) then {
                        _ppidx = _ppidx + 1;
                        _group setVariable ["pl_pp_idx", _ppidx];
                        _vic doMove (_passigPoints#_ppidx);
                        _vic setDestination [(_passigPoints#_ppidx),"VEHICLE PLANNED" , true];
                    };

                    private _convoyLeaderSpeedStr = vehicle (leader (_convoyLeaderGroup)) getVariable ["pl_speed_limit", "50"];
                    private _convoyLeaderSpeed = pl_convoy_speed;
                    switch (_convoyLeaderSpeedStr) do { 
                        case "CON" : {_convoyLeaderSpeed = pl_convoy_speed}; 
                        case "MAX" : {_convoyLeaderSpeed = 60}; 
                        default {_convoyLeaderSpeed = parseNumber _convoyLeaderSpeedStr}; 
                    };
                    if ([getPOs _vic] call pl_is_city or [getPOs _vic] call pl_is_forest) then {
                        if (_convoyLeaderSpeedStr == "CON") then {
                            _convoyLeaderSpeed = pl_convoy_speed / 2 + 5;
                        };
                    };
                    _vic forceSpeed -1;
                    _vic limitSpeed _convoyLeaderSpeed;
                    private _distance = _vic distance2D _forward;
                    private _forwardPP = _passigPoints#((_groups#(_i - 1)) getVariable "pl_pp_idx");
                    if (_distance > 60) then {
                        _vic limitSpeed (_convoyLeaderSpeed + 5 + (_distance - 60));
                    };
                    if (_distance < 60) then {
                        _vic limitSpeed _convoyLeaderSpeed;
                    };
                    if (_distance < 40) then {
                        _vic limitSpeed (_convoyLeaderSpeed * 0.5);
                    };
                    if (_distance < 20 or (_vic distance2d _forwardPP) < (_forward distance2d _forwardPP)) then {
                        _vic forceSpeed 0;
                        _vic limitSpeed 0;
                    };
                    if (_distance > 150 and (_vic distance2d _forwardPP) >= (_forward distance2d _forwardPP)) then {
                        _vic limitSpeed 1000;
                    };
                    if ((speed _vic) <= 3) then {
                        _time = time + 20;
                        if !(_startReset) then {
                            _time = time + 3;
                            _startReset = true;
                        };
                        waitUntil {sleep 0.5; ((speed _vic > 5 or time > _time) and (speed _forward) >= 5 and (_vic distance2d _forward) >= 50) or !(_group getVariable ["onTask", true]) or !(_convoyLeaderGroup getVariable ["onTask", true])};
                        if ((speed _vic) < 5 and (speed _forward) >= 5 and (_vic distance2d _forward) >= 48 and (_group getVariable ["onTask", true]) and (_convoyLeaderGroup getVariable ["onTask", true])) then {
                            doStop _vic:
                            sleep 0.3;
                            [getPos _vic, 20] call pl_clear_obstacles;
                            // _group setBehaviourStrong "SAFE";
                            _group setVariable ["pl_draw_convoy", true];
                            // _vic setVariable ["pl_phasing", true];
                            _pp = (_passigPoints#_ppidx);
                            _r0 = [getpos _vic, 100,[]] call BIS_fnc_nearestRoad;
                            _r1 = ([roadsConnectedTo _r0, [], {_pp distance2d _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                            // _vic setVehiclePosition [getPos _r1, [], 0, "NONE"];
                            // _vic setDir  (_r0 getDir _r1);
                            sleep 0.1;
                            if (_distance > 300) exitWith {
                                sleep 0.2;
                                [_group] call pl_reset;
                            };
                            _vic limitSpeed pl_convoy_speed;
                            _vic setVariable ["pl_speed_limit", "CON"];
                            _vic doMove _pp;
                            _vic setDestination [_pp,"VEHICLE PLANNED" , true];
                        };
                    };
                    sleep 1;
                };
                player hcsetGroup [_group];
                // if ((_vic distance2D _forward) > 60) then {
                //     _vic doMove getPOs _forward;
                //     _vic setDestination [getPos _forward,"VEHICLE PLANNED" , true];
                //     waitUntil {sleep 0.5; _vic distance2D _forward < 60 or !(_group getVariable ["onTask", false])};
                // };
                // [_group] call pl_reset;
                _group setVariable ["pl_draw_convoy", nil];
                _vic limitSpeed 50;
                _vic setVariable ["pl_speed_limit", "50"];
                doStop _vic;
                _vic doMove (waypointPosition (_group getVariable "pl_conWp"));
                
            };
        } else {
            [_group ,_vic, _convoyLeader, _groups, _i, _convoyLeaderGroup, _passigPoints] spawn {
                params ["_group" , "_vic", "_convoyLeader", "_groups", "_i", "_convoyLeaderGroup", "_passigPoints"];
                private ["_ppidx"];

                private _dest = _passigPoints#((count _passigPoints) - 1);

                while {(_convoyLeaderGroup getVariable ["onTask", true]) and (vehicle (leader _convoyLeaderGroup)) distance2D _dest > 40} do {

                    if !(alive _vic) exitWith {};

                    private _convoyLeaderSpeedStr = vehicle (leader (_convoyLeaderGroup)) getVariable ["pl_speed_limit", "50"];
                    private _convoyLeaderSpeed = pl_convoy_speed;
                    switch (_convoyLeaderSpeedStr) do { 
                        case "CON" : {_convoyLeaderSpeed = pl_convoy_speed}; 
                        case "MAX" : {_convoyLeaderSpeed = 60}; 
                        default {_convoyLeaderSpeed = parseNumber _convoyLeaderSpeedStr}; 
                    };
                    if ([getPOs _vic] call pl_is_city or [getPOs _vic] call pl_is_forest) then {
                        if (_convoyLeaderSpeedStr == "CON") then {
                            _convoyLeaderSpeed = pl_convoy_speed / 2 + 5;
                        };
                    };
                    _vic forceSpeed -1;
                    _vic limitSpeed _convoyLeaderSpeed;

                    _ppidx = _group getVariable "pl_pp_idx";
                    if (_vic distance2D (_passigPoints#_ppidx) < 35) then {
                        _ppidx = _ppidx + 1;
                        _convoyLeaderGroup setVariable ["pl_pp_idx", _ppidx];
                        _vic doMove (_passigPoints#_ppidx);
                        _vic setDestination [(_passigPoints#_ppidx),"VEHICLE PLANNED" , true];
                    };

                    if ((speed _vic) <= 3) then {
                        _time = time + 6;
                        waitUntil {sleep 0.5; speed _vic > 5 or time > _time or !(_group getVariable ["onTask", true])};
                        if ((speed _vic) <= 3 and (_group getVariable ["onTask", true])) then {
                            // [_group] call pl_reset;
                            doStop _vic;
                            [getPos _vic, 20] call pl_clear_obstacles;
                            sleep 0.3;
                            // _group setBehaviourStrong "SAFE";
                            _group setVariable ["pl_draw_convoy", true];
                            _pp = (_passigPoints#_ppidx);
                            _r0 = [getpos _vic, 100,[]] call BIS_fnc_nearestRoad;
                            _r1 = ([roadsConnectedTo _r0, [], {_pp distance2d _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                            // _vic setVehiclePosition [getPos _r1, [], 0, "NONE"];
                            // _vic setDir  (_r0 getDir _r1);
                            sleep 0.1;
                            _vic limitSpeed pl_convoy_speed;
                            _vic setVariable ["pl_speed_limit", "CON"];
                            _vic doMove _pp;
                            _vic setDestination [_pp,"VEHICLE PLANNED" , true];

                        }; 
                    };
                    sleep 1;
                };

                // [_convoyLeaderGroup] call pl_reset;

                _convoyLeaderGroup setVariable ["onTask", false];
                _vic limitSpeed 50;
                _vic setVariable ["pl_speed_limit", "50"];
                _convoyLeaderGroup setVariable ["pl_draw_convoy", nil];
            };
        };
        _time = time + 1.5;
        waituntil {(time >= _time and speed _vic > 6) or !((_convoyLeaderGroup) getVariable ["onTask", true])};
    };

    // sleep 2;
    waituntil {sleep 1; !(_convoyLeaderGroup getVariable ["onTask", true])};
    // if (speed _convoyLeader <= 0) then {if (pl_enable_map_radio) then {[_convoyLeaderGroup, "... Destination unreachable!", 25] call pl_map_radio_callout}};

    pl_draw_convoy_array = pl_draw_convoy_array - [_convoy];
    pl_draw_convoy_path_array = pl_draw_convoy_path_array - [_passigPoints];
};


pl_rush = {

    params ["_group"];
    private ["_targets", "_cords"];

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
    
    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _leader = leader _group;
    if (_leader == vehicle _leader) then {
        // leader _group sideChat "Roger Falling Back, Over";
        // [leader _group, "SmokeShellMuzzle"] call BIS_fnc_fire;
        _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa";
        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", _icon];
        _wp = _group addWaypoint [_cords, 0];
        _group setBehaviourStrong "AWARE";
        _group setSpeedMode "FULL";
        _group setCombatMode "BLUE";
        _group setVariable ["pl_combat_mode", true];

        // pl_draw_planed_task_array pushBack [_wp, _icon];

        {
            _unit = _x;
            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            // _unit disableAI "FSM";
            _movePos = _cords findEmptyPosition [0, 20, typeOf _unit];
            _unit doMove _movePos;
            // _unit setDestination [_movePos, "LEADER DIRECT", true];
            private _startPos = getPos _unit;
            private _dir = _cords getDir _startPos;

            // private _targets = _x targetsQuery [objNull, sideUnknown, "", [], 0];
            // private _count = count _targets;
                
            // for [{private _i = 0}, {_i < _count}, {_i = _i + 1}] do {
            //     private _y = _targets select _i;
            //     _x forgetTarget (_y select 1);
            // };
            [_group, 30] spawn pl_forget_targets;
            
            [_unit, _group, _cords, _dir] spawn {
                params ["_unit", "_group", "_cords", "_dir"];
                waitUntil{sleep 0.5; ((_unit distance2D _cords) < 8) or !(_group getVariable ["onTask", true])};
                _unit enableAI "AUTOCOMBAT";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                // _unit doFollow (leader _group);
                [_unit, 25, _dir] spawn pl_find_cover;
            };

        } forEach (units _group);

        waitUntil {sleep 0.5; (({_x checkAIFeature "PATH"} count (units _group)) <= 0) or !(_group getVariable ["onTask", true])};
        
        sleep 1;

        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
        _group setVariable ["pl_combat_mode", false];
        _group setSpeedMode "NORMAL";
        _group setCombatMode "YELLOW";
        // pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
        // leader _group sideChat "We reached Fall Back Position, Over";
    }
    else
    {
        _group addWaypoint [_cords, 0];
        _group setVariable ["setSpecial", true];
        _group setVariable ["onTask", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa"];
        _vic = vehicle _leader;
        _vic limitSpeed 5000;
        _vDir = (getDir _vic) - 180;
        [_vic, "SmokeLauncher"] call BIS_fnc_fire;
        _time = time + 45;
        waitUntil {sleep 0.5; (((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 25) or (time >= _time) or !(_group getVariable ["onTask", true])};

        sleep 2;
        [_group, str _vDir] call pl_watch_dir;
        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
        _vicSpeedLimit = _vic getVariable ["pl_speed_limit", "50"];
        if !(_vicSpeedLimit isEqualTo "MAX") then {
            _vic limitSpeed (parseNumber _vicSpeedLimit);
        };
    };
};

pl_cross_bridge = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_cords", "_engineer", "_bridges", "_bridgeMarkers", "_mPos"];

    _group setVariable ["pl_is_task_selected", true];

    if (visibleMap or !(isNull findDisplay 2000)) then {

        _markerName = createMarker ["pl_charge_range_marker2", [0,0,0]];
        _markerName setMarkerColor "colorOrange";
        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "Border";
        _markerName setMarkerSize [30, 30];

        private _rangelimiter = 150;

        private _markerBorderName = str (random 2);
        private _borderMarkerPos = getPos (leader _group);
        if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
        createMarker [_markerBorderName, _borderMarkerPos];
        _markerBorderName setMarkerShape "ELLIPSE";
        _markerBorderName setMarkerBrush "Border";
        _markerBorderName setMarkerColor "colorOrange";
        _markerBorderName setMarkerAlpha 0.8;
        _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

        hint "Select on MAP";
        onMapSingleClick {
            pl_repair_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hint "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
                _markerName setMarkerPos _mPos;
            };
        };

        pl_mapClicked = false;
        _cords = getMarkerPos _markerName;
        deleteMarker _markerName;
        deleteMarker _markerBorderName;
    }
    else
    {
        waitUntil {sleep 0.1; inputAction "Action" <= 0};

        // _cursorPosIndicator = createVehicle ["Sign_Arrow_Direction_Yellow_F", screenToWorld [0.5,0.5], [], 0, "none"];
        _cursorPosIndicator = createVehicle ["Sign_Arrow_Large_Yellow_F", [-1000, -1000, 0], [], 0, "none"];

        _leader = leader _group;
        pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

        while {inputAction "Action" <= 0} do {
            _viewDistance = _cursorPosIndicator distance2D player;
            _cursorPosIndicator setPosATL ([0,0,_viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
            _cursorPosIndicator setObjectScale (_viewDistance * 0.05);

            if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

            sleep 0.025
        };

        if (pl_cancel_strike) exitWith {deleteVehicle _cursorPosIndicator; pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]]};

        _cords = getPosATL _cursorPosIndicator;

        pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

        deleteVehicle _cursorPosIndicator;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; _group setVariable ["pl_is_task_selected", nil];};

    _roads = _cords nearRoads 30;
    _bridges = [];
    _bridgeMarkers = [];

    {
        _info = getRoadInfo _x;
        if (_info#8) then {
            if ((getDammage _x) < 1) then {
                _bridges pushBackUnique _x;
            };
        };
    } forEach _roads;

    private _allEndings = [];
    private _deployed = false;

    {
        if ((_x#0) distance2D _cords < 30) then {
            _allEndings = _allEndings + (_x#1);
            _deployed = true;
        };

    } forEach pl_deployed_bridges;

    {
        _info = getRoadInfo _x;
        _endings = [_info#6, _info#7];
        _allEndings = _allEndings + _endings;

        // {
            // _m = createMarker [str (random 4), _x];
            // _m setMarkerType "mil_dot";
        // } forEach _endings;
    } forEach _bridges;

    if (_allEndings isEqualTo []) exitWith {hint "No Bridge in Area"};

    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["onTask", true];


    _closest = ([_allEndings, [], {_x distance2D (leader _group)}, "ASCEND"] call BIS_fnc_sortBy)#0;
    _furthest = ([_allEndings, [], {_x distance2D (leader _group)}, "DESCEND"] call BIS_fnc_sortBy)#0;
    
    _group setVariable ["pl_task_pos", _closest];
    _group setVariable ["specialIcon", '\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'];

    if (vehicle (leader _group) == (leader _group)) then {
        _group setVariable ["pl_on_march", true];
        _group addWaypoint [_furthest getPos [35, _closest getDir _furthest], 0];
        {
            if ((_x distance2D _closest) < (_x distance2d _furthest)) then {
                [_x, _group, _closest, _furthest, _closest getDir _furthest, _deployed] spawn {
                    params ["_unit", "_group", "_closest", "_furthest", "_dir", "_deployed"];

                    doStop _unit;
                    _unit doMove _closest;
                    _unit setCombatBehaviour "AWARE";

                    waitUntil {sleep 0.5; (_unit distance2D _closest) < 4 or !alive _unit or !(_group getVariable ["onTask", false])};
                    if (_deployed) then {_unit setVehiclePosition [_closest, [], 0, "CAN_COLLIDE"]};
                    _movePos = _furthest getPos [15, _dir];

                    if (alive _unit and (_group getVariable ["onTask", false])) then {
                        _unit setCombatBehaviour "CARELESS";
                        _unit disableAI "ANIM";
                        _unit setDir (_unit getdir _movePos);
                        _unit switchMove "AmovPercMrunSrasWrflDf_ldst";
                        waitUntil {sleep 0.5; (_unit distance2D _movePos) < 10 or !alive _unit or !(_group getVariable ["onTask", false])};
                        _unit enableAI "ALL";
                        _unit switchMove "";
                        _unit setCombatBehaviour "AWARE";
                        _unit doFollow (leader _group);
                        // if (_unit == (leader _group)) then {
                            _unit doMove (_movePos getPos [20, _dir]);
                        // };
                    };
                };
            };
        } forEach units _group;

    } else {

        _vic = vehicle (leader _group);

        _dir = _closest getDir _furthest;
        

        // _m = createMarker [str (random 4), _closest];
        // _m setMarkerType "mil_dot";

        _movePos2 = _furthest getPos [40, _dir];
        _group addWaypoint [_movePos2, 0];
        // doStop _vic;

        {
            _x disableAI "PATH";
        } forEach (units _group);
        

        _group setBehaviourStrong "CARELESS";

        if (_deployed) then {
            [_vic, _closest, 4] call pl_vic_advance_to_pos_static;
            if (_group getVariable ["onTask", true] and alive _vic) then {
                _vic setVehiclePosition [_closest, [], 0, "CAN_COLLIDE"];
            };
        } else {
            // _movePos = _closest getPos [15, _dir - 180];
            // _vic doMove _movePos;
            // sleep 1;
            // waitUntil {sleep 0.5; (_vic distance2D _movePos) < 15 or !alive _vic or !(_group getVariable ["onTask", true])};
            [_vic, _closest, 4] call pl_vic_advance_to_pos_static;
        };

        if (_group getVariable ["onTask", true] and alive _vic) then {
            
            [_vic, _movePos2, 2] call pl_vic_advance_to_pos_static;
            // _movePos3 = _movePos2 findEmptyPosition [5, 40, typeOf _vic];
            // _vic doMove _movePos3;
        };

        {
            _x enableAI "PATH";
        } forEach (units _group);

        _group setBehaviourStrong "AWARE";
        _group setVariable ["onTask", false];

        sleep 2;

        _vic doMove (waypointPosition ((waypoints _group) select (currentWaypoint _group)));

        // _vic setDir _dir;
        // _vic disableBrakes true;
        // while {_vic distance2D _movePos2 >= 10 and alive _vic and (_group getVariable ["onTask", false])} do {
        //     _vic setVelocityModelSpace [0,6,0];
        //     // _vic setDir _dir;
        //     sleep 0.5;
        // };
        // _vic disableBrakes false;
    };
};

pl_vic_advance_to_pos_static = {
    params ["_vic", "_pos", ["_speed", 4], ["_acs", 0.5]];

    if !([_vic] call pl_canMove) exitWith {};

    [_vic, _pos] call pl_vic_turn_in_place;
    // _vic setDir (_vic getDir _pos);

    private _startPos = getPos _vic;
    private _distancetoTravel = (_startPos distance2d _pos) - 1;
    (group (driver _vic)) setVariable ["pl_on_march", true];
    _vic disableBrakes true;
    _vic engineOn false;
    _vic engineOn true;
    _n = _speed;
    while {_vic distance2D _startPos < _distancetoTravel and alive _vic and ((group (driver _vic)) getVariable ["pl_on_march", false])} do {

        _vic disableBrakes true;
        if (count (((getPos _vic) getPos [8, getdir _vic]) nearEntities [["Car", "Tank", "Truck"], 7]) <= 0) then {
            if (_n > 0) then {_n = _n - _acs};
            _vic setVelocityModelSpace [0, (_speed - _n),0];
        } else {
            _n = _speed;
            _vic disableBrakes false;
        };
        // if (time % 2 == 0) then {_vic setDir (_vic getDir _pos)};
        sleep 0.5;
        if !([_vic] call pl_canMove) exitWith {};
    };
    _vic disableBrakes false;
    (group (driver _vic)) setVariable ["pl_on_march", nil];
};

pl_vic_reverse_to_pos = {
    params ["_vic", "_pos", ["_speed", 6], ["_acs", 0.5]];

    if !([_vic] call pl_canMove) exitWith {};

    [_vic, _vic getPos [50, _pos getDir _vic]] call pl_vic_turn_in_place;
    // _vic setDir (_pos getDir _vic);

    if (_speed > 8) then {_speed = 8};

    private _startPos = getPos _vic;
    private _distancetoTravel = (_startPos distance2d _pos) - 1;
    (group (driver _vic)) setVariable ["pl_on_march", true];
    _vic disableBrakes true;
    _vic engineOn false;
    _vic engineOn true;
    _n = _speed;
    while {_vic distance2D _startPos < _distancetoTravel and alive _vic and ((group (driver _vic)) getVariable ["pl_on_march", false])} do {

        _vic disableBrakes true;
        if (count (((getPos _vic) getPos [-8, getdir _vic]) nearEntities [["Car", "Tank", "Truck"], 7]) <= 0) then {
            if (_n > 0) then {_n = _n - _acs};
            _vic setVelocityModelSpace [0, - (_speed - _n),0];
        } else {
            _n = _speed;
            _vic disableBrakes false;
        };
        sleep 0.5;
        if !([_vic] call pl_canMove) exitWith {};
    };
    _vic disableBrakes false;
    (group (driver _vic)) setVariable ["pl_on_march", nil];
};


pl_vic_advance_to_pos = {
    private ["_vic", "_pos"];


    _group = (hcSelected player)#0;

    if (vehicle (leader _group) == leader _group) exitWith {hint "Vehicle Only Task"};

    _vic = vehicle (leader _group);

    if !([_vic] call pl_canMove) exitWith {hint "Vehicle cant move!"};

    if (visibleMap or !(isNull findDisplay 2000)) then {

        if (visibleMap) then {
            _pos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _pos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        
    } else {
        waitUntil {sleep 0.1; inputAction "Action" <= 0};

        // _cursorPosIndicator = createVehicle ["Sign_Arrow_Direction_Yellow_F", screenToWorld [0.5,0.5], [], 0, "none"];
        _cursorPosIndicator = createVehicle ["Sign_Arrow_Large_Yellow_F", [-1000, -1000, 0], [], 0, "none"];

        _leader = leader _group;
        pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

        while {inputAction "Action" <= 0} do {
            _viewDistance = _cursorPosIndicator distance2D player;
            _cursorPosIndicator setPosATL ([0,0,_viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
            _cursorPosIndicator setObjectScale (_viewDistance * 0.05);

            if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

            sleep 0.025
        };

        if (pl_cancel_strike) exitWith {deleteVehicle _cursorPosIndicator; pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]]};

        _pos = getPosATL _cursorPosIndicator;

        pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

        deleteVehicle _cursorPosIndicator;
    };

    pl_draw_disengage_array pushBack [_group, _pos];

    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    // _wp = _group addWaypoint [_pos, 0];

    doStop _vic;

    {
        _x disableAI "PATH";
    } forEach (units _group);

    // if ((_vic distance2D _pos) > 75) then {_pos = (getPos _vic) getPos [70, _vic getDir _pos]};

    [_vic, _pos] call pl_vic_turn_in_place;
    // _vic setDir (_vic getDir _pos);

    private _startPos = getPos _vic;
    private _distancetoTravel = (_startPos distance2d _pos) - 1;
    (group (driver _vic)) setVariable ["pl_on_march", true];
    _vic disableBrakes true;
    _vic engineOn false;
    _vic engineOn true;
    _n = 4;
    while {_vic distance2D _startPos < _distancetoTravel and alive _vic and ((group (driver _vic)) getVariable ["pl_on_march", false])} do {

        _vic disableBrakes true;
        if (count (((getPos _vic) getPos [8, getdir _vic]) nearEntities [["Car", "Tank", "Truck"], 7]) <= 0) then {
            if (_n > 0) then {_n = _n - 0.5};
            _vic setVelocityModelSpace [0, 4 - _n,0];
        } else {
            _n = 4;
            _vic disableBrakes false;
        };
        sleep 0.5;
        if !([_vic] call pl_canMove) exitWith {};
    };
    _vic disableBrakes false;
    (group (driver _vic)) setVariable ["pl_on_march", nil];
    pl_draw_disengage_array =  pl_draw_disengage_array - [[_group, _pos]];

    {
        _x enableAI "PATH";
    } forEach (units _group);

    [_group] call pl_reset;
};

pl_vic_advance_to_pos_reverse = {
    private ["_vic", "_pos"];

    _group = (hcSelected player)#0;

    if (vehicle (leader _group) == leader _group) exitWith {hint "Vehicle Only Task"};

    _vic = vehicle (leader _group);

    if !([_vic] call pl_canMove) exitWith {hint "Vehicle cant move!"};

    if (visibleMap or !(isNull findDisplay 2000)) then {

        if (visibleMap) then {
            _pos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _pos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };

    } else {
        waitUntil {sleep 0.1; inputAction "Action" <= 0};

        // _cursorPosIndicator = createVehicle ["Sign_Arrow_Direction_Yellow_F", screenToWorld [0.5,0.5], [], 0, "none"];
        _cursorPosIndicator = createVehicle ["Sign_Arrow_Large_Yellow_F", [-1000, -1000, 0], [], 0, "none"];

        _leader = leader _group;
        pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

        while {inputAction "Action" <= 0} do {
            _viewDistance = _cursorPosIndicator distance2D player;
            _cursorPosIndicator setPosATL ([0,0,_viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
            _cursorPosIndicator setObjectScale (_viewDistance * 0.05);

            if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

            sleep 0.025
        };

        if (pl_cancel_strike) exitWith {deleteVehicle _cursorPosIndicator; pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]]};

        _pos = getPosATL _cursorPosIndicator;

        pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

        deleteVehicle _cursorPosIndicator;
    };

    // if ((_vic distance2D _pos) > 75) then {_pos = (getPos _vic) getPos [70, _vic getDir _pos]};#


    pl_draw_disengage_array pushBack [_group, _pos];

    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    // _wp = _group addWaypoint [_pos, 0];

    doStop _vic;

    {
        _x disableAI "PATH";
    } forEach (units _group);

    [_vic, (getPos _vic) getPos [50, _pos getDir _vic]] call pl_vic_turn_in_place;

    private _startPos = getPos _vic;
    private _distancetoTravel = (_startPos distance2d _pos) - 1;
    (group (driver _vic)) setVariable ["pl_on_march", true];
    _vic disableBrakes true;
    _vic engineOn false;
    _vic engineOn true;
    _n = 4;
    while {_vic distance2D _startPos < _distancetoTravel and alive _vic and ((group (driver _vic)) getVariable ["pl_on_march", false])} do {
        
        _vic disableBrakes true;
        if (count (((getPos _vic) getPos [-8, getdir _vic]) nearEntities [["Car", "Tank", "Truck"], 7]) <= 0) then {
            if (_n > 0) then {_n = _n - 0.5};
            _vic setVelocityModelSpace [0, -(4 - _n),0];
        } else {
            _n = 4;
            _vic disableBrakes false;
        };
        sleep 0.5;
        if !([_vic] call pl_canMove) exitWith {};
    };
    _vic disableBrakes false;
    (group (driver _vic)) setVariable ["pl_on_march", nil];
    pl_draw_disengage_array =  pl_draw_disengage_array - [[_group, _pos]];
    {
        _x enableAI "PATH";
    } forEach (units _group);

    [_group] call pl_reset;
};

pl_advance_to_pos_switch = {
    params ["_vic", "_pos", ["_speed", 4]];

    _relDir = _vic getRelDir _pos;
    if (_relDir >= 90 and _relDir <= 270) then {
        [_vic, _pos, _speed] call pl_vic_reverse_to_pos;
    } else {
        [_vic, _pos, _speed] call pl_vic_advance_to_pos_static;
    };  
};


pl_vic_turn_in_place = {
    params ["_vic", "_targetPos"];

    if !([_vic] call pl_canMove) exitWith {};

    if (_vic getRelDir _targetPos <= 2.5) exitWith {}; 

    // _vic engineOn false;
    // _vic engineOn true;
    _sound = playSound3d ["a3\sounds_f_tank\vehicles\armor\lt_01\lt_01_engine_ext_burst01.wss", _vic];
    if (_vic isKindOf "Tank") then {
        _sound2 = playSound3d ["a3\sounds_f\vehicles\armor\treads\ext_treads_hard_01.wss", _vic];
    };
    _vic disableBrakes true;
    private _degreesToRotate = _vic getRelDir _targetPos;
    private _posOrneg = 1; // This drives whether unit rotates clockwise or counter-clockwise
    private _increment = 0.4;
    _degreesToRotate = _vic getRelDir _targetPos;
    _posOrneg = 1;
    if (_degreesToRotate > 180) then
    {
        _posOrneg = -1;
    };

    (group (driver _vic)) setVariable ["pl_on_march", true];

    _s1 = [_vic, _posOrneg, _increment, _targetPos] spawn {
        params ["_vic", "_posOrneg", "_increment", "_targetPos"];
        while {(_vic getRelDir _targetPos) >= 1.2 and ((group (driver _vic)) getVariable ["pl_on_march", false])} do {
            _vic setDir (getDir _vic + (_increment * _posOrneg));
            if (_vic isKindOf "Car" or _vic isKindOf "Truck") then {
                _vic setVelocityModelSpace [0,-2,0];
            };
            sleep 0.01;
            if !([_vic] call pl_canMove) exitWith {};
        };
    };
    waitUntil {sleep 0.1; scriptDone _s1};
    _vic setDir (_vic getDir _targetPos);
    _vic disableBrakes false;
    if ((group (driver _vic)) getVariable ["pl_on_march", false]) then {
        _vic setDir (_vic getDir _targetPos);
        (group (driver _vic)) setVariable ["pl_on_march", nil];
    };

};

pl_unit_turn_in_place = {
    params ["_unit", "_targetPos"];

    private _degreesToRotate = _unit getRelDir _targetPos;
    private _posOrneg = 1; // This drives whether unit rotates clockwise or counter-clockwise
    private _increment = 2;

    while {(_unit getRelDir _targetPos) > 2} do {
        _degreesToRotate = _unit getRelDir _targetPos;
        _posOrneg = 1;
        if (_degreesToRotate > 180) then
        {
            _posOrneg = -1;
        };
        _unit setDir (getDir _unit + (_increment * _posOrneg));
        sleep 0.03;
    };
    _unit setDir (_unit getDir _targetPos);

};

pl_unit_move_exact_pos = {
    params ["_unit", "_pos"];

    _distanceToTravel = (_unit distance2D _pos) - 0.25;
    _startPos = getPos _unit;

    _unit setCombatBehaviour "CARELESS";
    _unit disableAI "ANIM";
    // [_unit, _pos] call pl_unit_turn_in_place;
    _unit setDir (_unit getDir _pos);
    _unit switchMove "AmovPercMrunSrasWrflDf";
    waitUntil {(_unit distance2D _startPos) >= _distancetoTravel or !alive _unit or !(_group getVariable ["onTask", false])};
    _unit enableAI "ALL";
    _unit switchMove "";
    _unit setCombatBehaviour "AWARE";
};

pl_move_on_path = {
    params ["_vic", "_path", ["_speed", 4]];

    group (driver _vic) setVariable ["onTask", true];
    {
        [_vic, _x] call pl_vic_turn_in_place;
        if !(group (driver _vic) getVariable ["onTask", false]) exitWith {};
        sleep 0.05;
        [_vic, _x, _speed] call pl_vic_advance_to_pos_static;
        if !(group (driver _vic) getVariable ["onTask", false]) exitWith {};

    } forEach _path;  
};

pl_get_to_cover_positions = {
    params ["_unitsRaw", "_cords", "_watchDir", ["_defenceAreaSize", 20], ["_allowGarrion", true], ["_losWatchPos", []], ["_force", true], ["_defendMode", 0]];

    _defenceWatchPos = _cords getPos [250, _watchDir];
    _defenceWatchPos = ASLToATL _defenceWatchPos;
    _defenceWatchPos = [_defenceWatchPos#0, _defenceWatchPos#1, 2];
    _defenceWatchPos = ATLToASL _defenceWatchPos;
    private _group = group ((_unitsRaw)#0);


    _watchPos = _cords getPos [1000, _watchDir];
    // _watchPos = _cords;
    [_watchPos, 1] call pl_convert_to_heigth_ASL;

    _buildings = nearestTerrainObjects [_cords, ["BUILDING", "RUIN", "HOUSE"], _defenceAreaSize, true];
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 2) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    _validPos = [];
    private _sideRoadPos = [];
    _allPos = [];

    if (_allowGarrion) then {
        {
            private _building = _x;
            // pl_draw_building_array pushBack [_group, _building];
            _bPos = [_building] call BIS_fnc_buildingPositions;
            _vPosCounter = 0;
            {
                _bP = _x;
                _allPos pushBack _bP;
                private _window = false;

                _samplePosASL = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 1.04152];

                _buildingDir = getDir _building;
                for "_d" from 0 to 361 step 45 do {
                    _counterPos = _samplePosASL vectorAdd [3 * (sin (_buildingDir + _d)), 3 * (cos (_buildingDir + _d)), 0];

                    if !((lineIntersects [_counterPos, _counterPos vectorAdd [0, 0, 20]])) then {
                        // _helper2 = createVehicle ["Sign_Sphere25cm_F", _counterPos, [], 0, "none"];
                        // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                        // _helper2 setposASL _counterPos;

                        // _m = createMarker [str (random 1), _counterPos];
                        // _m setMarkerType "mil_dot";
                        // _m setMarkerSize [0.3, 0.3];
                        // _m setMarkerColor "colorRED";

                        _interSectsWin = lineIntersectsWith [_samplePosASL, _counterPos, objNull, objNull, true];
                        _checkDir = _buildingDir + _d;
                        if ((({_x == _building} count _interSectsWin) == 0) and (_checkDir > (_watchDir - 25) and _checkDir < (_watchDir + 25))) exitWith {
                            // _window = true
                            _bPos deleteAt (_bPos find _bP);
                            _validPos pushBack _bP;
                            _vPosCounter = _vPosCounter + 1;

                            // _helper1 = createVehicle ["Sign_Sphere25cm_F", _samplePosASL, [], 0, "none"];
                            // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                            // _helper1 setposASL _samplePosASL;

                            // _m = createMarker [str (random 1), _samplePosASL];
                            // _m setMarkerType "mil_dot";
                            // _m setMarkerSize [0.3, 0.3];
                            // _m setMarkerColor "colorBlue";
                        };
                    };
                };

                _skyPos = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 30];
                _interSectsRoof = lineIntersectsWith [_samplePosASL, _skyPos];
                if (_interSectsRoof isEqualTo []) then {
                    _bPos deleteAt (_bPos find _bP);
                    _validPos pushBackUnique _bP;
                    _vPosCounter = _vPosCounter + 1;
                };
            } forEach _bPos;

            if (_vPosCounter == 0) then {
                // _validPos pushBack (selectRandom _bPos);
                _validBuildings deleteAt ( _validBuildings find _building);
            };
        } forEach _validBuildings;
    };

    private _isStatic = [false, []];

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _units = [];
    private _mgGunners = [];
    private _atSoldiers = [];
    private _missileAtSoldiers = [];
    private _atEscord = objNull;
    private _medic = objNull;


    // classify units
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun" and secondaryWeapon _x == "" and _x != _medic and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _units pushBackUnique _x;
        };
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun" and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _mgGunners pushBackUnique _x;
        };
        if (secondaryWeapon _x != "" and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _atSoldiers pushBackUnique _x;

            if (([secondaryWeapon _x] call BIS_fnc_itemtype) select 1 == "MissileLauncher") then {
                _missileAtSoldiers pushback _x;
            };
        };
    } forEach (_unitsRaw select {vehicle _x == _x});

    {_units pushBackUnique _x} forEach _atSoldiers;
    {_units pushBackUnique _x} forEach _mgGunners;
    if !(isNull _medic) then {_units pushBack _medic};
    

    _posOffsetStep = _defenceAreaSize / (round ((count _units) / 2));
    private _posOffset = 0; //+ _posOffsetStep;
    private _maxOffset = _posOffsetStep * (round ((count _units) / 2));

    // find static weapons
    private _weapons = nearestObjects [_cords, ["StaticWeapon"], _defenceAreaSize, true];
    _avaiableWeapons = _weapons select { simulationEnabled _x && { !isObjectHidden _x } && { locked _x != 2 } && { (_x emptyPositions "Gunner") > 0 } };
    _weapons = + _avaiableWeapons;
    _coverCount = 0;
    _ccpPos = [];
    private _safePos = [];
    _buildingMarkers = [];
    _buildingWallPosArray = [];

    if !(_buildings isEqualTo []) then {

        _buildings = [_buildings, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _covers = [];
        
        {
            _buildingCenter = getPos _x;
            _coverSearchPos = _buildingCenter getPos [10, _watchDir];
            _c = nearestTerrainObjects [_coverSearchPos, pl_valid_covers, 15, true, true];
            _covers = _covers + _c;

            _m = [_x] call BIS_fnc_boundingBoxMarker;
            if (_x in _validBuildings) then {
                _m setMarkerColor pl_side_color;
                _m setMarkerAlpha 0.3;
            };
            _buildingMarkers pushBack _m;
            _mPos = getMarkerPos _m;
            _mDir = markerdir _m;
            _mSize = getMarkerSize _m;
            _a2 = ((_mSize#0) * 1) * ((_mSize#0) * 1);
            _b2 = ((_mSize#1) * 1) * ((_mSize#1) * 1);
            _c2 = _a2 + _b2;
            _d = sqrt _c2;

            private _corners = [];
            for "_di" from 45 to 315 step 90 do {
                _corners pushback (_mPos getPos [_d,_mDir + _di]);
            };

            _corners = [_corners, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy;

            {
                if !([_x] call pl_is_indoor) then {
                    _buildingWallPosArray pushback _x;
                };
            } forEach [(_corners#0), (_corners#1)];

            _safePos pushback (((_corners#0) getPos [((_corners#0) distance2D (_corners#1)) / 2, (_corners#0) getDir (_corners#1)]) getPos [2.5, _watchDir - 180]);

        } forEach _buildings;

        _buildingWallPosArray = [_buildingWallPosArray, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _covers = [_covers, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _ccpPos = ([_safePos, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0;


        // {
        //     _m = createMarker [str (random 1), _x];
        //     _m setMarkerType "mil_dot";
        //     _m setMarkerSize [0.5, 0.5];
        // } forEach _buildingWallPosArray;

        private _walls = nearestTerrainObjects [_cords, ["WALL", "RUIN", "FENCE"], _defenceAreaSize, true];
        private _validWallPos = [];
        private _validPrefWallPos = [];

        {
            if !(isObjectHidden _x) then {

                _leftPos = (getPos _x) getPos [1.5, getDir _x];
                _rightPos = (getPos _x) getPos [1.5, (getDir _x) - 180];

                if ((typeof _x) in pl_valid_walls) then {
                    _validPrefWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                } else {
                    _validWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                };
            };
        } forEach _walls;

        _validWallPos = [_validWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _validPrefWallPos = [_validPrefWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        private _roads = _cords nearRoads _defenceAreaSize;
        if ((count _roads) >= 2) then {
            _roads = [_roads, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
            private _roadDir = (getpos (_roads#1)) getDir (getpos (_roads#0));

            if (_roadDir > (_watchDir - 35) and _roadDir < (_watchDir + 35)) then {

                _roads = [_roads, [], {_x distance2D (_buildings#0)}, "ASCEND"] call BIS_fnc_sortBy;
                private _road = _roads#0;
                {
                    _info = getRoadInfo _road;    
                    _endings = [_info#6, _info#7];
                    _endings = [_endings, [], {_x distance2D player}, "ASCEND"] call BIS_fnc_sortBy;
                    _roadWidth = _info#1;
                    _rPos = ASLToATL (_endings#0);
                    _sideRoadPos pushBack (_rPos getPos [(_roadWidth / 2) + 1, _roadDir + _x]);

                    // _m = createMarker [str (random 1), _rPos getPos [_roadWidth / 2, _roadDir + _x]];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerSize [0.5, 0.5];

                } forEach [90, -90];
            };
        };

        _validPos = _validPos + _buildingWallPosArray;
        _validPos = _validPos + _sideRoadPos;
        _validPos = _validPos + _validPrefWallPos; 
        _validPos = _validPos + _validWallPos;

    } else {
        _covers = nearestTerrainObjects [_cords, pl_valid_covers, _defenceAreaSize, true, true];
        _rearPos = _cords getPos [_defenceAreaSize * 0.5, _watchDir - 180];
        _lineStartPos = _rearPos getPos [_defenceAreaSize / 2, _watchDir - 90];
        private _posCandidates = [];
        private _ccpPosOffset = 0;
        for "_l" from 0 to 20 do {
            _cPos = _lineStartPos getPos [_ccpPosOffset, _watchDir + 90];
            _ccpPosOffset = _ccpPosOffset + (_defenceAreaSize / 20);
            if !([_cPos] call pl_is_indoor) then {
                _posCandidates pushBack _cPos;
            };
        };
        _posCandidates = [_posCandidates, [], {_x distance2D _cords}, "DESCEND"] call BIS_fnc_sortBy;
        _ccpPos = ([_posCandidates, [], {[objNull, "VIEW", objNull] checkVisibility [_x, [_x getPos [50, _watchDir], 0.5] call pl_convert_to_heigth_ASL]}, "DESCEND"] call BIS_fnc_sortBy)#0;
    };

    // private _validLosPos = [];

    private _losOffset = 2;
    private _maxLos = 0;
    private _validLosPos = [];
    private _accuracy = 30;
    private _losStartLine = _cords getPos [2, _watchDir];
    private _losPos = [];

    if !(_buildingWallPosArray isEqualTo []) then {
        _losStartLine = _buildingWallPosArray#0;
        _accuracy = 10;
    };

    // if ([_losStartLine] call pl_is_city) then {
    //     _accuracy = 10;
    // };

    for "_j" from 0 to _accuracy do {

        private _losDir = _watchDir;

        if (_j % 2 == 0) then {
            _losPos = (_losStartLine getPos [5, _watchDir]) getPos [_losOffset, _watchDir + 90];
            // if !(_losWatchPos isEqualto []) then {_losDir = _losPos getDir (_losWatchPos getPos [_losOffset, _watchDir + 90])};
        }
        else
        {
            _losPos = (_losStartLine getPos [5, _watchDir]) getPos [_losOffset, _watchDir - 90];
            // if !(_losWatchPos isEqualto []) then {_losDir = _losPos getDir (_losWatchPos getPos [_losOffset, _watchDir - 90])};
        };
        _losOffset = _losOffset + (_defenceAreaSize / _accuracy);

        _losPos = [_losPos, 1.75] call pl_convert_to_heigth_ASL;

        if !(_losWatchPos isEqualto []) then {_losDir = _losPos getDir _losWatchPos};

        private _losCount = 0;

        for "_l" from 10 to 400 step 10 do {

            _checkPos = _losPos getPos [_l, _losDir];
            _checkPos = [_checkPos, 1.75] call pl_convert_to_heigth_ASL;
            _vis = lineIntersectsSurfaces [_losPos, _checkPos, objNull, objNull, true, 1, "VIEW"];

            // if !(_losWatchPos isEqualto []) then {
            //     _helper1 = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
            //     _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
            //     _helper1 setposASL _checkPos;
            // };

            if !(_vis isEqualTo []) exitWith {};

            _losCount = _losCount + 1;
        };
        if !(isOnRoad ([_losPos, 0] call pl_convert_to_heigth_ASL)) then {
            _validLosPos pushback [_losPos, _losCount];
        };
    };

    _validLosPos = [_validLosPos, [], {_x#1}, "DESCEND"] call BIS_fnc_sortBy;

    if (_group getVariable ["pl_allow_static", false]) then {
        _isStatic = [_units, _group, (_validLosPos#0)#0, _watchPos, _cords] call pl_static_unpack;

        if (_isStatic#0) then {
            _validLosPos deleteAt (_validLosPos find (_validLosPos#0));
            // _posOffset  8;
            // (leader _group) addWeapon "Binocular";

            _units deleteAt (_units find ((_isStatic#1)#0));
        };
    };
    

    private _mgPos = [];

    for "_i" from 0 to count (_mgGunners + _missileAtSoldiers) - 1 do {
        _mgPos pushback ((_validLosPos#_i)#0);
        _validLosPos deleteAt (_validLosPos find (_validLosPos#_i));
    };

    private _mgIdx = 0;
    private _losIdx = 0;
    private _debugMColor = "colorBlack";
    private _defPos = [];


    // sleep 1;

    private _unit = objNull;


    for "_i" from 0 to (count _units) - 1 step 1 do {
        private _cover = false;
        private _unit = _units#_i;
        private _unitWatchDir = 0;

        switch (_defendMode) do { 
            case 0 : {
                _unitWatchDir = _watchDir;
                // move to optimal Pos first
                if (_i < (count _validPos)) then {
                    _defPos = _validPos#_i;
                    
                    _debugMColor = "colorBlue";
                }
                else
                {
                    _cover = true;
                    // if no more covers avaible move to left or right side of best cover
                        // deploy along a line
                    if (_buildings isEqualTo []) then {
                        _dirOffset = 90;
                        if (_i % 2 == 0) then {_dirOffset = -90};
                        // _defPos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _cords;
                        _defPos = _cords getPos [_posOffset, _watchDir + _dirOffset];
                        if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
                        _debugMColor = "colorBlue";
                    }
                    else
                    {
                        if (_losIdx > (count _validLosPos) - 1) then {_losIdx = 1};
                        _defPos = (_validLosPos#_losIdx)#0;
                        _losIdx = _losIdx + 2;
                        _debugMColor = "colorOrange";
                    };
                };

                // seelct best Medic Pos
                if (!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) then {
                    if (_unit == _medic) then {
                        _defPos = _ccpPos;
                    };
                };

                // select Best Mg Pos
                if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun" or ([secondaryWeapon _unit] call BIS_fnc_itemtype) select 1 == "MissileLauncher") then {
                    _defPos = (_mgPos#_mgIdx);
                    _mgIdx = _mgIdx + 1;
                    _debugMColor = "colorRed";
                };

                // if (_unit == (leader _group) and !(_buildings isEqualTo []) and (_defPos distance2D _cords) > 20) then {
                //     _defPos = _cords findEmptyPosition [0, 25, typeOf _unit];
                //     _cover = true;
                //     _debugMColor = "colorYellow";
                // };

                if (isNil "_defPos") then {
                    if !(_covers isEqualTo []) then {
                        _defPos = getpos (selectRandom _covers);
                    } else {
                        _defPos = _cords findEmptyPosition [0, _defenceAreaSize];
                    };
                    _debugMColor = "colorGrey";
                };
            }; 

            case 1 : {

                _unitWatchDir = (360 / (count _units)) * _i;
                _searchPos = _cords getPos [_defenceAreaSize * 0.9, _unitWatchDir];

                _defPos = [];
                if ((count _validPos) > 0) then {
                    _defPos = {
                        if ((_x distance2D _searchPos) < 15) exitWith {
                            _debugMColor = "colorBlue";
                            _validPos deleteAt (_validPos find _x);
                            _x
                         };
                        []
                    } forEach _validPos;

                };

                if (_defPos isEqualTo []) then {
                    _debugMColor = "colorOrange";
                    _defPos = _searchPos;
                    _cover = true;
                };

            }; 
            default {}; 
        };


        _defPos = ATLToASL _defPos;
        private _unitPos = "UP";
        if !([_defPos] call pl_is_indoor) then {
            _unitPos = "MIDDLE";
            _cover = true;
        };
        _checkPos = [10*(sin _watchDir), 10*(cos _watchDir), 1] vectorAdd _defPos;
        _crouchPos = [0, 0, 1] vectorAdd _defPos;
        _vis = lineIntersectsSurfaces [_crouchPos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "MIDDLE";
            // _watchPos = _checkPos;
        };
        _checkPos = [10*(sin _watchDir), 10*(cos _watchDir), 0.2] vectorAdd _defPos;
        _vis = lineIntersectsSurfaces [_defPos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "DOWN";
            // _watchPos = _checkPos;
        };

        _defPos = ASLToATL _defPos;        

        // _m = createMarker [str (random 1), _defPos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerSize [0.5, 0.5];
        // _m setMarkerColor _debugMColor;

        [_unit, _defPos, _watchPos, _unitWatchDir, _unitPos, _cover, _cords, _defenceWatchPos, _watchDir, _force] spawn {
            params ["_unit", "_defPos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_cords", "_defenceWatchPos", "_defenceDir", "_force"];
            private ["_check"];

            if (!(alive _unit) or isNil "_defPos") exitWith {};

            doStop _unit;
            // waitUntil {sleep 0.5; unitReady _unit or !alive _unit};
            sleep 0.1;

            _unit setHit ["legs", 0];
            _unit setVariable ["pl_def_pos", _defPos];
            _unit setVariable ["pl_def_pos_sec", []];
            _unit setVariable ["pl_engaging", true];
            if (_force) then {
                _unit disableAI "AUTOCOMBAT";
                _unit disableAI "AUTOTARGET";
                _unit disableAI "TARGET";
            };
            _unit setUnitTrait ["camouflageCoef", 0.7, true];
            _unit setVariable ["pl_damage_reduction", true];
            _unit doMove _defPos;
            // _unit setDestination [_defPos, "LEADER DIRECT", true];
            sleep 1;
            private _counter = 0;

            while {alive _unit and (lifeState _unit) isNotEqualTo "INCAPACITATED" and ((group _unit) getVariable ["onTask", false]) and (_unit distance2D _defPos) > 3.5} do {
                _time = time + 6;
                waitUntil {sleep 0.25; time > _time or !((group _unit) getVariable ["onTask", false]) or (_unit distance2D _defPos) < 4};
                _check = [_unit, _defPos, _counter] call pl_position_reached_check;
                if (_check#0) exitWith {};
                _counter = _check#1;
                _defPos = _check#2;
            };
            // waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
            // waitUntil {sleep 0.5; (_unit distance2D _defPos) < 3 or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
            sleep 0.5;
            if (!alive _unit or (lifeState _unit) isEqualTo "INCAPACITATED") exitWith {_unit setVariable ["pl_in_position", true]};
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "TARGET";
            _unit setUnitPos "AUTO";

            if !((group _unit) getVariable ["onTask", true]) exitWith {};

            if !(_cover) then {
                doStop _unit;
                _unit disableAI "PATH";
                _unit doWatch _watchPos;
                _unit setUnitPos _unitPos;
                
            }
            else
            {
                if ([_defPos] call pl_is_forest or [_defPos] call pl_is_city) then {
                    [_unit, 3, _unitWatchDir] call pl_find_cover;
                } else {
                    [_unit, 10, _unitWatchDir] call pl_find_cover;
                };
            };
            if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun" or ([secondaryWeapon _unit] call BIS_fnc_itemtype) select 1 == "MissileLauncher") then {
                [_unit, 0, _unitWatchDir, true] call pl_find_cover;
                // _m setMarkerColor "colorRed";
            };
            sleep 0.5;
            _unit setVariable ["pl_in_position", true];
        };

        {
            deleteMarker _x;
        } forEach _buildingMarkers;
    };
};

pl_get_fire_pos = {
    params ["_firer", "_target", ["_area", 100]];

    _checkPosArray = [];
    private _atkDir = _firer getDir _target;
    private _lineStartPos = (getPos _firer) getPos [(_area + 100)  / 2, _atkDir - 90];
    _lineStartPos = _lineStartPos getPos [8, _atkDir];
    private _lineOffsetHorizon = 0;
    private _lineOffsetVertical = (_target distance2D _firer) / 60;

    for "_i" from 0 to 60 do {
        for "_j" from 0 to 60 do { 
            _checkPos = _lineStartPos getPos [_lineOffsetHorizon, _atkDir + 90];
            _lineOffsetHorizon = _lineOffsetHorizon + ((_area + 100) / 60);

            _checkPos = [_checkPos, 2] call pl_convert_to_heigth_ASL;



            _vis = lineIntersectsSurfaces [_checkPos, AGLToASL (unitAimPosition _target), _target, vehicle _target, true, 1, "VIEW"];
            // _vis2 = [_target, "VIEW", _target] checkVisibility [_checkPos, AGLToASL (unitAimPosition _target)];
            if (_vis isEqualTo []) then {
                _checkPosArray pushBack _checkPos;
            };
            _lineStartPos = _lineStartPos getPos [_lineOffsetVertical, _atkDir];
            _lineOffsetHorizon = 0;
        };
    };
    _movePos = ([_checkPosArray, [], {_firer distance2D _x}, "DESCEND"] call BIS_fnc_sortBy) select 0;

    _m = createMarker [str (random 2), _movePos];
    _m setMarkerType "mil_dot";

    _movePos
};

pl_vehicle_move_as_group = {
  
    _allgroups = hcSelected player;
    private _vicGroups = [];
    private _allVehicles = [];

    {
        if (leader _x != vehicle (leader _x)) then {
            _vicGroups pushback _x;
            _allVehicles pushback (vehicle (leader _x));
            (vehicle (leader _x)) setVariable ["pl_vic_crew_callsign", groupId _x];
        };
    } forEach _allGroups;

    if (count _vicGroups < 2) exitWith {hint "Select more than one Vehicle"};

    _primeGroup = _vicGroups#0;
    {
        (units _x) joinSilent _primeGroup;
    } forEach _vicGroups;

};


