pl_bounding_cords = [0,0,0];
pl_bounding_speed = "full";
pl_bounding_draw_array = [];

pl_advance = {

    params ["_group"];
    private ["_cords"];

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };
    _group setVariable ["onTask", false];
    sleep 0.25;


    (leader _group) limitSpeed 15;

    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);

    for "_i" from count waypoints _group - 1 to 0 step -1 do
        {
            deleteWaypoint [_group, _i];
        };

    _group addWaypoint [_cords, 0];
    _group setBehaviour "AWARE";

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\walk_ca.paa"];

    waitUntil {sleep 0.1; if (_group isEqualTo grpNull) exitWith {true}; (((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 11) or !(_group getVariable ["onTask", true])};

    (leader _group) limitSpeed 5000;
    {
        _x enableAI "AUTOCOMBAT";
    } forEach (units _group);
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];

    // leader _group sideChat "We Advanced to assigned Position, Over";

};

pl_attack= {

    params ["_group"];
    private ["_cords"];

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };

    _group setVariable ["onTask", false];
    sleep 0.25;

    _groupStrength = count (units _group);
    // leader _group sideChat "Roger beginning Assault, Over";

    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);
    _group setBehaviour "AWARE";
    leader _group limitSpeed 12;

    for "_i" from count waypoints _group - 1 to 0 step -1 do
        {
            deleteWaypoint [_group, _i];
        };

    _atkwp =_group addWaypoint [_cords, 0];
    _atkwp setWaypointType "SAD";

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa"];

    waitUntil {sleep 0.1; if (_group isEqualTo grpNull) exitWith {true}; (((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 30) or ((count units _group) <= _groupStrength - 3) or !(_group getVariable ["onTask", true])};
    {
        _x enableAI "AUTOCOMBAT";
    } forEach (units _group);
    leader _group limitSpeed 5000;
    waitUntil {!(_atkwp in (waypoints _group))};
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
};


pl_spawn_advance = {
    {
        [_x] spawn pl_advance;
    } forEach hcSelected player;
};

pl_spawn_attack = {
    {
        [_x] spawn pl_attack;
    } forEach hcSelected player;
};

pl_suppressive_fire = {
    params ["_units"];
    private ["_pos", "_time", "_target", "_leader", "_alt", "_aimPos"];

    _target = cursorTarget;
    _leader = leader (group (_units select 0));
    if (isNull _target) then {
        if (visibleMap) then {
            _pos = (findDisplay 12 displayCtrl 51) posScreenToWorld getMousePosition;
            _targetHouse = nearestTerrainObjects [_pos, ["BUILDING", "HOUSE", "BUNKER", "FORTRESS"], 10, true, true];
            if (count _targetHouse == 0) then {
                _pos = AGLToASL _pos;
                if (vehicle _leader != _leader) then {
                     _vic = vehicle _leader;
                     _leader = crew _vic select 1;
                     _aimPos = aimPos _leader
                }
                else
                {
                    _aimPos = getPosASL _leader;
                };
                _cansee = [objNull, "FIRE"] checkVisibility [getPosASL _leader, _pos];
                _alt = 0;
                while {_cansee < 0.8} do {
                    _pos = [_pos select 0, _pos select 1, (_pos select 2) + 2];
                    _cansee = [objNull, "FIRE"] checkVisibility [_aimPos, _pos];
                    _alt = _alt + 1;
                    if (_alt > 10) exitWith{};
                };
                _target = _pos;  
            }
            else
            {
                _target = _targetHouse select 0;
            };
        }
        else
        {
            _pos = screenToWorld [0.5,0.5];
            _pos = AGLToASL _pos;
            if (vehicle _leader != _leader) then {
                 _vic = vehicle _leader;
                 _leader = crew _vic select 1;
                 _aimPos = aimPos _leader
            }
            else
            {
                _aimPos = getPosASL _leader;
            };
            _cansee = [objNull, "FIRE"] checkVisibility [getPosASL _leader, _pos];
            _alt = 0;
            while {_cansee < 0.8} do {
                _pos = [_pos select 0, _pos select 1, (_pos select 2) + 2];
                _cansee = [objNull, "FIRE"] checkVisibility [_aimPos, _pos];
                _alt = _alt + 1;
                if (_alt > 10) exitWith{};
            };
            _target = _pos;
        };
        {
            if (vehicle _x != _x) exitWith {
                _vic = vehicle _x;
                _gunner = {
                    if (((assignedVehicleRole _x) select 0) isEqualTo "Turret") exitWith {_x};
                    objNull
                } forEach (crew _vic);
                _gunner doSuppressiveFire _target;
                sleep 3;
                // for "_i" from 0 to 6 do {
                //     [_vic, "HE"] call BIS_fnc_fire;
                //     sleep 0.5;
                // };
            };
            _x doSuppressiveFire _target;
        } forEach _units;
    }
    else
    {
        {
            if (vehicle _x != _x) exitWith {
                _vic = vehicle _x;
                _gunner = {
                    if (((assignedVehicleRole _x) select 0) isEqualTo "Turret") exitWith {_x};
                    objNull
                } forEach (crew _vic);
                _gunner doSuppressiveFire _target;
                sleep 3;
                // for "_i" from 0 to 6 do {
                //     [_vic, "HE"] call BIS_fnc_fire;
                //     sleep 0.5;
                // };
            };
            _x doSuppressiveFire _target;
        } forEach _units;
    };
};



pl_spawn_suppression = {
    {  
        [units _x] spawn pl_suppressive_fire;
    } forEach hcSelected player;
};

// [] call pl_spawn_suppression

pl_bounding_squad = {
    private ["_cords", "_group", "_moveDir", "_movePos", "_tactic", "_offSet", "_groupLen", "_units", "_team1", "_team2", "_moveRange"];

    if !(visibleMap) exitWith {hint "Open Map for bounding OW"};

    _group = hcSelected player select 0;
    hint "Select location on MAP (LMB = Fast, SHIFT + LMB = SLOW)";
    onMapSingleClick {
        pl_bounding_cords = _pos;
        pl_mapClicked = true;
        pl_bounding_speed = "full";
        if (_shift) then {pl_bounding_speed = "limited"};
        hintSilent "";
        onMapSingleClick "";
    };
    while {!pl_mapClicked} do {sleep 0.5;};
    pl_mapClicked = false;
    _cords = pl_bounding_cords;
    _moveDir = (leader _group) getDir _cords;

    _group setVariable ["onTask", false];
    sleep 0.25;
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\help_ca.paa"];

    pl_bounding_draw_array pushBack [_group, _cords];

    _groupLen = (count (units _group)) - 1;

    _units = (units _group);
    _team1 = [];
    _team2 = [];

    _tactic = pl_bounding_speed;
    switch (pl_bounding_speed) do { 
        case "full" : {_group setSpeedMode "FULL"};
        case "limited" : {_group setSpeedMode "LIMITED"}; 
        default {_group setSpeedMode "NORMAL"}; 
    };

    for "_i" from 0 to _groupLen do {
        (_units#_i) setVariable ["pl_bounding_set", false];
        if (_i % 2 == 0) then {
            _team1 pushBack _units#_i;
        }
        else
        {
            _team2 pushBack _units#_i;
        }
    };
    _leaderPos = getPos (leader _group);
    _offSet = 10;
    {
        _movePos = [_offSet*(sin (_moveDir - 90)), _offSet*(cos (_moveDir - 90)), 0] vectorAdd _leaderPos;
        _x doMove _movePos;
        _x disableAI "AUTOCOMBAT";
        _x disableAI "TARGET";
        // _x disableAI "AUTOTARGET"
        _offSet = _offSet + 6;
    } forEach _team1;
    _offSet = 10;
    {
        _movePos = [_offSet*(sin (_moveDir + 90)), _offSet*(cos (_moveDir + 90)), 0] vectorAdd _leaderPos;
        _x doMove _movePos;
        _x disableAI "AUTOCOMBAT";
        _x disableAI "TARGET";
        // _x disableAI "AUTOTARGET"
        _offSet = _offSet + 6;
    } forEach _team2;

    waitUntil {sleep 0.1; ({unitReady _x} count _units) == (count _units)};

    {
        _x enableAI "AUTOCOMBAT";
        _x enableAI "TARGET";
        _x enableAI "AUTOTARGET";
        [_x, _cords, _moveDir, 3, false] spawn pl_find_cover;
    } forEach _units;

    sleep 4;

    _moveRange = 30;
    while {_group getVariable ["onTask", true]} do {
        _movePos = [_moveRange*(sin _moveDir), _moveRange*(cos _moveDir), 0] vectorAdd (getPos (_team1#0));
        _offSet = 0;
        {
            if ((_x distance2D _cords) < 20) exitWith {_group setVariable ["onTask", false]};
            _x setUnitPos "UP";
            _x enableAI "PATH";
            _pos = [_offSet*(sin (_moveDir - 90)), _offSet*(cos (_moveDir - 90)), 0] vectorAdd _movePos;
            _offSet = _offSet + 6;
            [_x, _pos, _cords, _moveDir, _tactic] spawn pl_bounding_move;
        } forEach _team1;
        waitUntil {sleep 0.1; !(_group getVariable ["onTask", true]) or (({(!(_x getVariable ["pl_bounding_set", false]) and !(_x getVariable ["pl_wia", false]))} count _team1) < 1)};
        if !(_group getVariable ["onTask", true]) exitWith {};
        sleep 3;
        _moveRange = 60;
        _movePos = [_moveRange*(sin _moveDir), _moveRange*(cos _moveDir), 0] vectorAdd (getPos (_team2#0));
        _offSet = 0;
        {
            if ((_x distance2D _cords) < 20) exitWith {_group setVariable ["onTask", false]};
            _x setUnitPos "UP";
            _x enableAI "PATH";
            _pos = [_offSet*(sin (_moveDir + 90)), _offSet*(cos (_moveDir + 90)), 0] vectorAdd _movePos;
            _offSet = _offSet + 6;
            [_x, _pos, _cords, _moveDir, _tactic] spawn pl_bounding_move;
        } forEach _team2;
        waitUntil {sleep 0.1; !(_group getVariable ["onTask", true]) or (({(!(_x getVariable ["pl_bounding_set", false]) and !(_x getVariable ["pl_wia", false]))} count _team2) < 1)};
        if !(_group getVariable ["onTask", true]) exitWith {};
        sleep 3;
    };
    pl_bounding_draw_array = pl_bounding_draw_array - [[_group, _cords]];
    _group setVariable ["setSpecial", false];
    [_group] spawn pl_reset;
    {
        _x setVariable ["pl_bounding_set", nil];
        _x doFollow (leader _group);
    } forEach _units;
};

pl_bounding_move = {
    params ["_unit", "_pos", "_cords", "_moveDir", "_tactic"];
    _unit disableAI "AUTOCOMBAT";
    _unit disableAI "SUPPRESSION";
    _unit disableAI "COVER";
    if (_tactic isEqualTo "full") then {
        _unit disableAI "TARGET";
        _unit disableAI "AUTOTARGET";
    };
    _unit setVariable ["pl_bounding_set", false];
    _unit doMove _pos;
    sleep 2;
    waitUntil {sleep 0.1; (!alive _unit) or (unitReady _unit)};
    _unit enableAI "AUTOCOMBAT";
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    _unit enableAI "SUPPRESSION";
    _unit enableAI "COVER";
    _unit setVariable ["pl_bounding_set", true];
    [_unit, _cords, _moveDir, 3, false] spawn pl_find_cover;
};


pl_bounding_platoon = {
    
};