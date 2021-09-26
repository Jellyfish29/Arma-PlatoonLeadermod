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
    } forEach (_groups) - [_formationLeaderGroup];

    // draw Indicator and wait for mouseclick;
    pl_draw_formation_mouse = true;

    if (_firstCall) then {showCommandingMenu ""; sleep 0.4;};

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


pl_sync_wp = {
    _logic = player getvariable "BIS_HC_scope";
    _wp = _logic getvariable "WPover";
    if ((count _wp) == 1) exitWith {hint "Keep Mouse over Waypoint to plan Task!"};
    _group = _wp select 0;  
};




