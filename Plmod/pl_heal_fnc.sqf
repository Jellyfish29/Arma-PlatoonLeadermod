pl_heal_around_medic = {
    params ["_group"];
    private ["_medic"];
    _medicClsName = "B_medic_F";
    _medic = 0;


    _medic = ((units _group) select {(typeOf _x) isEqualto _medicClsName}) select 0;
    if !((str _medic) isEqualto "0") then {
        {
            _x disableAI "AUTOCOMBAT";
            doStop _x;
        } forEach (units _group);
        _healTargets = [];
        {
            if ((damage _x) > 0) then {
                _healTargets pushBack _x;
            };
        } forEach (units _group);
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"];
        {
            _medic doMove (position _x);
            doStop _x;
            waitUntil {(unitReady _medic)};
            _medic action ["HealSoldier", _x];
            waitUntil {(unitReady _medic)};
            _x doFollow (leader _group);
        } forEach _healTargets;
        _group setVariable ["setSpecial", false];
        {
            _x enableAI "AUTOCOMBAT";
            _x doFollow (leader _group);
        } forEach (units _group);
    }
    else
    {
        leader _group sideChat "Negativ, Our Medic is KIA";
    };
};

pl_spawn_heal = {
    {
        [_x] spawn pl_heal_around_medic
      } forEach hcSelected player;  
};

// [] call pl_spawn_heal;

pl_ccp = {
    params ["_group"];
    private ["_ccpUp", "_medic"];
    _medicClsName = "B_medic_F";
    _medic = ((units _group) select {(typeOf _x) isEqualto _medicClsName}) select 0;
    if !(isNil "_medic") then {
        leader _group sideChat "Setting up CCP, over";
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        {
            _x disableAI "AUTOCOMBAT";
        } forEach (units _group);
        _group setBehaviour "AWARE";

        for "_i" from count waypoints _group - 1 to 0 step -1 do
            {
                deleteWaypoint [_group, _i];
        };
        _group addWaypoint [_cords, 0];

        waitUntil {(((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 2)};

        for "_i" from count waypoints _group - 1 to 0 step -1 do
            {
                deleteWaypoint [_group, _i];
        };

        [_group, getPos (leader _group)] spawn pl_360;
        createMarker ["ccp_marker", _cords];
        "ccp_marker" setMarkerType "marker_CCP";
        "ccp_marker" setMarkerColor "colorBLUFOR";
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"];
        _ccpUp = true;
        sleep 3;

        while {_ccpUp} do {
            _targets = _cords nearObjects ["Man", 100];
            _healTargets = [];
            {
                if (((damage _x) > 0) and (alive _x)) then {
                    if (_x != _medic) then {
                        _healTargets pushBack _x;
                    }
                    else
                    {
                        _medic action ["HealSoldierSelf", _medic];
                    };
                };
            } forEach _targets;
            {
                _medic doMove (position _x);
                _x setUnitPos "MIDDLE";
                doStop _x;
                waitUntil {(unitReady _medic)};
                _medic action ["HealSoldier", _x];
                waitUntil {(unitReady _medic)};
                _x setUnitPos "AUTO";
                _x doFollow (leader (group _x));
            } forEach _healTargets;
            if (count (waypoints _group) > 0) then {
                deleteMarker "ccp_marker";
                _group setVariable ["setSpecial", false];
                {
                    _x enableAI "PATH";
                    _x doFollow (leader _group);
                    _x commandFollow (leader _group);
                    _x enableAI "AUTOCOMBAT";
                } forEach (units _group);
                _ccpUp = false;
            };
            sleep 1;
        };
    }
    else
    {
        leader _group sideChat "Negativ, Our Medic is Dead";
    };
};

// [hcSelected player select 0] spawn pl_ccp;
