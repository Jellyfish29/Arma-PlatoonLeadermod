pl_follow_active = false;
pl_follow_array = [];
pl_draw_formation_mouse = false;
pl_draw_vic_advance_wp_array = [];
pl_draw_sync_wp_array = [];


pl_march = {
    params ["_group"];
    private ["_cords", "_f"], "_mwp";

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };

    if (vehicle (leader _group) != (leader _group)) exitWith {[_group, _cords] spawn pl_vic_advance};

    if (isNil {_group getVariable "pl_on_march"}) then {
        [_group] call pl_reset;
        sleep 0.2;

        // if (pl_enable_beep_sound) then {playSound "beep"};
        [_group, "confirm", 1] call pl_voice_radio_answer;


        // _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\3den\data\Attributes\SpeedMode\normal_ca.paa"];
        _group setVariable ["pl_on_march", true];

        {
            _x disableAI "AUTOCOMBAT";
        } forEach (units _group);
        (leader _group) limitSpeed 14;
        // _group setFormation "FILE";
        _group setBehaviour "AWARE";
        // if ((vehicle (leader _group)) != (leader _group)) then {
            

        // };

        _mwp = _group addWaypoint [_cords, 0];
        _group setVariable ["pl_mwp", _mwp];

        sleep 1;
        waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition (_group getVariable ["pl_mwp", (currentWaypoint _group)]))) < 11) or (isNil {_group getVariable ["pl_on_march", nil]})};
        _group setVariable ["pl_on_march", nil];
        _group setVariable ["setSpecial", false];
        {
            _x enableAI "AUTOCOMBAT";
        } forEach (units _group);
        (leader _group) limitSpeed 5000;

        // if (_group getVariable ["onTask", true] and !(_group getVariable ["pl_task_planed", false])) then {[_group] call pl_reset;};
        
    }
    else
    {
        _mwp = _group addWaypoint [_cords, 0];
        _group setVariable ["pl_mwp", _mwp];
    };
};


pl_vic_advance = {
    params ["_group", "_cords"];

    [_group] spawn pl_reset;

    sleep 0.3;

    private _vic = vehicle (leader _group);

    _vic doMove _cords;
    _vic setDestination [_cords,"VEHICLE PLANNED" , true];

    pl_draw_vic_advance_wp_array pushBack [_vic, _cords];

    sleep 0.5;
    waitUntil {sleep 0.5, unitReady _vic or !alive _vic};
    pl_draw_vic_advance_wp_array = pl_draw_vic_advance_wp_array - [[_vic, _cords]];
};


pl_bounding_squad = {
    params ["_mode", ["_ai", false]];
    private ["_cords", "_icon", "_group", "_team1", "_team2", "_MoveDistance", "_distanceOffset", "_movePosArrayTeam1", "_movePosArrayTeam2", "_unitPos"];

    // if !(visibleMap) exitWith {hint "Open Map for bounding OW"};

    _group = hcSelected player select 0;

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };
    
    _moveDir = (leader _group) getDir _cords;

    // if (pl_enable_beep_sound) then {playSound "beep"};
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
    _wp = _group addWaypoint [_cords, 0];
    pl_draw_planed_task_array pushBack [_wp, _icon];

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
    } forEach _units;

    _group setBehaviour "AWARE";

    // _mode = "buddy";

    _get_move_pos_array = { 
        params ["_team", "_wpPos", "_dirOffset", "_distanceOffset", "_MoveDistance"];
        _teamLeaderPos = getPos (_team#0);
        _moveDir = _teamLeaderPos getDir _wpPos;
        _teamLeaderMovePos = _teamLeaderPos getPos [_MoveDistance, _moveDir + (_dirOffset * 0.05)];
        _return = [_teamLeaderMovePos];
        for "_i" from 1 to (count _team) - 1 do {
            _p = _teamLeaderMovePos getPos [_distanceOffset * _i, _moveDir + _dirOffset];
            _return pushBack _p;
        };
        _return;
    };

    switch (_mode) do { 
        case "team" : {_MoveDistance = 25; _distanceOffset = 4; _unitPos = "DOWN"}; 
        case "buddy" : {_MoveDistance = 2; _distanceOffset = 11; _unitPos = "MIDDLE"}; 
        default {_MoveDistance = 25; _distanceOffset = 4; _unitPos = "DOWN"}; 
    };

    {
        _x setUnitPos "DOWN";
    } forEach _team2;

    _MoveDistance = 25;
    while {({(_x distance2D (waypointPosition _wp)) < 15} count _units == 0) and !(waypoints _group isEqualTo [])} do {

        (_team1#0) groupRadio "SentConfirmMove";
        _movePosArrayTeam1 = [_team1, waypointPosition _wp, -90, _distanceOffset, _MoveDistance] call _get_move_pos_array;
        waitUntil {sleep 0.5; [_team1, _movePosArrayTeam1, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team};
        if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo [])) exitWith {};
        if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {[_group] call pl_reset};

        (_team1#0) groupRadio "sentCovering";
        _targets = (_team1#0) targets [true, 400, [], 0, waypointPosition _wp];
        if (count _targets > 0 and _mode isEqualTo "team") then {{[_x, getPosASL (selectRandom _targets)] call pl_quick_suppress} forEach _team1};

        sleep 1;

        (_team2#0) groupRadio "SentConfirmMove";
        switch (_mode) do { 
            case "team" : {_MoveDistance = 50; _movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call _get_move_pos_array}; 
            case "buddy" : {_MoveDistance = 30; _movePosArrayTeam2 = _movePosArrayTeam1}; 
            default {_movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call _get_move_pos_array}; 
        };
        waitUntil {sleep 0.5; [_team2, _movePosArrayTeam2, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team};

        if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo [])) exitWith {};
        if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {[_group] call pl_reset};
        
        (_team2#0) groupRadio "sentCovering";
        _targets = (_team2#0) targets [true, 400, [], 0, waypointPosition _wp];
        if (count _targets > 0 and _mode isEqualTo "team") then {{[_x, getPosASL (selectRandom _targets)] call pl_quick_suppress} forEach _team2};

        sleep 1;
    };

    {
        doStop _x;
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
    } forEach _units;
    
    _group setVariable ["setSpecial", false];
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
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
                        // (vehicle _leader) limitSpeed (speed player) + 5;
                        if ((speed (vehicle _leader)) < 1) then {
                            _newPos = [((getPos _leader) select 0) + ((_posOffset select 0) * 15), ((getPos _leader) select 1) + ((_posOffset select 1) * 15)];
                            (vehicle _leader) doMove _newPos;
                            (vehicle _leader) setDestination [_newPos,"VEHICLE PLANNED" , true];
                        };
                        if ((speed player) < 1) then {
                            _newPos = [((getPos player) select 0) + (_relPos select 0), ((getPos player) select 1) + (_relPos select 1)];
                            (vehicle _leader) doMove _newPos;
                            (vehicle _leader) setDestination [_newPos,"VEHICLE PLANNED" , true];
                        };
                    }
                    else
                    {
                        _newPos = [((getPos player) select 0) + (_relPos select 0), ((getPos player) select 1) + (_relPos select 1)];
                        _leader limitSpeed 15;
                        _leader doMove _newPos;
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
    params [["_groups", hcSelected player], ["_firstCall", false]];
    private ["_cords", "_wpPos", "_pos1", "_pos2", "_syncWps", "_infIncluded"];

    if !(visibleMap) exitWith {hint "Open Map to order Formation Move"};

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

    _formationLeaderGroup setBehaviourStrong "COMBAT";
    // draw Indicator and wait for mouseclick;
    pl_draw_formation_mouse = true;

    if (_firstCall) then {showCommandingMenu ""; sleep 0.4};

    waitUntil {inputAction "defaultAction" > 0 or inputAction "zoomTemp" > 0};

    sleep 0.05;

    pl_draw_formation_move_mouse_array = [];

    if (inputAction "zoomTemp" > 0) exitWith {pl_draw_formation_mouse = false;};

    if (_infIncluded) then {
        {
            if (vehicle (leader _x) != leader _x) then {
                (vehicle (leader _x)) limitSpeed 23;
                (vehicle (leader _x)) setVariable ["pl_speed_limit", "CON"];
            };
        } forEach _groups;
    };

    _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;

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
        _gWp = _x addWaypoint [_newPos, 0];
        _gWp synchronizeWaypoint _syncWps;
        _syncWps pushBack _gWp;
    } forEach _groups - [_formationLeaderGroup];

    _syncWps = [_syncWps, [], {(waypointPosition _x) distance2D (waypointPosition _lWp)}, "ASCEND"] call BIS_fnc_sortBy;

    // pl_draw_sync_wp_array pushBack _syncWps;

    if (inputAction "curatorGroupMod" > 0) exitWith {sleep 0.4; [_groups] spawn pl_move_as_formation};
    pl_draw_formation_mouse = false;
};


pl_rush = {

    params ["_group"];
    private ["_targets", "_cords"];

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
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

        pl_draw_planed_task_array pushBack [_wp, _icon];

        {
            _unit = _x;
            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            // _unit disableAI "FSM";
            _movePos = _cords findEmptyPosition [0, 20, typeOf _unit];
            _unit doMove _movePos;
            _unit setDestination [_movePos, "LEADER DIRECT", true];
            private _startPos = getPos _unit;
            private _dir = _cords getDir _startPos;

            private _targets = _x targetsQuery [objNull, sideUnknown, "", [], 0];
            private _count = count _targets;
                
            for [{private _i = 0}, {_i < _count}, {_i = _i + 1}] do {
                private _y = _targets select _i;
                _x forgetTarget (_y select 1);
            };
            
            [_unit, _group, _cords, _dir] spawn {
                params ["_unit", "_group", "_cords", "_dir"];
                waitUntil{sleep 0.5; ((_unit distance2D _cords) < 8) or !(_group getVariable ["onTask", true])};
                _unit enableAI "AUTOCOMBAT";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                // _unit doFollow (leader _group);
                [_unit, getPos _unit, _dir, 25, false] spawn pl_find_cover;
            };

        } forEach (units _group);

        waitUntil {sleep 0.5; (({_x checkAIFeature "PATH"} count (units _group)) <= 0) or !(_group getVariable ["onTask", true])};
        
        sleep 1;

        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
        _group setVariable ["pl_combat_mode", false];
        _group setSpeedMode "NORMAL";
        _group setCombatMode "YELLOW";
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
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