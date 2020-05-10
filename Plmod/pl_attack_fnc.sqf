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

    waitUntil {(((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 11) or !(_group getVariable "onTask")};

    (leader _group) limitSpeed 5000;
    {
        _x enableAI "AUTOCOMBAT";
    } forEach (units _group);
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];

    leader _group sideChat "We Advanced to assigned Position, Over";

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
    leader _group sideChat "Roger beginning Assault, Over";

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

    waitUntil {(((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 30) or ((count units _group) <= _groupStrength - 3) or !(_group getVariable "onTask")};
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
                _gunner = crew _vic select 1;
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
                _gunner = crew _vic select 1;
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
