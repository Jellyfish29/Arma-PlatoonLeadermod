pl_rp_cords = [0,0,0];

pl_bounding_platoon = {
    private ["_group1", "_group2", "_rpCords", "_cords", "_moveDir", "_moveRange", "_movePos", "_tactic"];

    if (count (hcSelected player) != 2) exitWith {hint "Select two Squads"};
    if !(visibleMap) exitWith {hint "Open Map for bounding OW"};

    _group1 = hcSelected player select 0;
    _group2 = hcSelected player select 1;
    hintSilent "";
    hint "Select RP position on MAP (SHIFT + LMB to cancel)";

    onMapSingleClick {
        pl_rp_cords = _pos;
        pl_mapClicked = true;
        if (_shift) then {pl_cancel_strike = true};
        hintSilent "";
        onMapSingleClick "";
    };

    while {!pl_mapClicked} do {sleep 0.1;};
    pl_mapClicked = false;
    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};
    hint "Select location on MAP (LMB = Fast, SHIFT + LMB = SLOW)";

    sleep 0.1;
    _rpCords = pl_rp_cords;

    onMapSingleClick {
        pl_bounding_cords = _pos;
        pl_mapClicked = true;
        pl_bounding_speed = "full";
        if (_shift) then {pl_bounding_speed = "limited"};
        hintSilent "";
        onMapSingleClick "";
    };

    while {!pl_mapClicked} do {sleep 0.1};
    pl_mapClicked = false;
    _cords = pl_bounding_cords;
    _moveDir = _rpCords getDir _cords;
    _tactic = pl_bounding_speed;
    switch (pl_bounding_speed) do { 
        case "full" : {_group1 setSpeedMode "FULL"; _group2 setSpeedMode "FULL"};
        case "limited" : {_group1 setSpeedMode "LIMITED"; _group2 setSpeedMode "LIMITED"}; 
        default {_group1 setSpeedMode "NORMAL"; _group2 setSpeedMode "NORMAL"}; 
    };

    _group1 setVariable ["onTask", false];
    _group2 setVariable ["onTask", false];
    sleep 0.25;
    _group1 setVariable ["onTask", true];
    _group1 setVariable ["setSpecial", true];
    _group1 setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\help_ca.paa"];
    _group2 setVariable ["onTask", true];
    _group2 setVariable ["setSpecial", true];
    _group2 setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\help_ca.paa"];

    _groupMovePos1 = [45*(sin (_moveDir + 90)), 45*(cos (_moveDir + 90)), 0] vectorAdd _rpCords;
    _groupMovePos2 = [45*(sin (_moveDir - 90)), 45*(cos (_moveDir - 90)), 0] vectorAdd _rpCords;

    if (((leader _group1) distance2D _groupMovePos1) < ((leader _group1) distance2D _groupMovePos2)) then {
        _group1 addWaypoint [_groupMovePos1, 0];
        _group2 addWaypoint [_groupMovePos2, 0];
    }
    else
    {
        _group1 addWaypoint [_groupMovePos2, 0];
        _group2 addWaypoint [_groupMovePos1, 0];
    };
    waitUntil {((((leader _group1) distance2D waypointPosition[_group1, currentWaypoint _group1]) < 11) and (((leader _group2) distance2D waypointPosition[_group2, currentWaypoint _group2]) < 11)) or !(_group1 getVariable ["onTask", true]) or !(_group2 getVariable ["onTask", true])};
    sleep 3;
    _group1 setFormDir _moveDir;
    _group2 setFormDir _moveDir;
    sleep 3;

    _moveRange = 50;
    while {((_group1 getVariable ["onTask", true]) and (_group2 getVariable ["onTask", true]))} do {
        _movePos = [_moveRange*(sin _moveDir), _moveRange*(cos _moveDir), 0] vectorAdd (getPos (leader _group1));
        _group1 addWaypoint [_movePos, 0];
        [_group1, _tactic] spawn pl_bounding_platoon_set;
        if (((leader _group2) distance2D _cords) < 30) exitWith {[_group1] spawn pl_reset, [_group2] spawn pl_reset};
        sleep 2;
        waitUntil {sleep 0.1; unitReady (leader _group1) or !(_group1 getVariable ["onTask", true]) or !(_group2 getVariable ["onTask", true])};
        [_group1] spawn pl_bounding_platoon_unset;

        _moveRange = 100;
        _movePos = [_moveRange*(sin _moveDir), _moveRange*(cos _moveDir), 0] vectorAdd (getPos (leader _group2));
        _group2 addWaypoint [_movePos, 0];
        [_group2, _tactic] spawn pl_bounding_platoon_set;
        if (((leader _group1) distance2D _cords) < 30) exitWith {[_group1] spawn pl_reset, [_group2] spawn pl_reset};
        sleep 2;
        waitUntil {sleep 0.1; unitReady (leader _group2) or !(_group1 getVariable ["onTask", true]) or !(_group2 getVariable ["onTask", true])};
        [_group2] spawn pl_bounding_platoon_unset;
    };
    [_group1] spawn pl_reset;
    [_group2] spawn pl_reset;
};


pl_bounding_platoon_set = {
    params ["_group", "_tactic"];
    {
        _x disableAI "AUTOCOMBAT";
        if (_tactic isEqualTo "full") then {
            _x disableAI "TARGET";
            _x disableAI "AUTOTARGET";
        };
    } forEach (units _group);
};

pl_bounding_platoon_unset = {
    params ["_group"];
    {
        _x enableAI "AUTOCOMBAT";
        _x enableAI "TARGET";
        _x enableAI "AUTOTARGET";
    } forEach (units _group);
};








pl_reset = {
    params ["_group"];

    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };

    _leader = leader _group;
    (units _group) joinSilent _group;
    _group selectLeader _leader;

    if (_group isEqualTo (group player)) then {
        _group selectLeader player;
    };
    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _vic setVariable ["pl_on_transport", nil];
    };
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    _group setVariable ["pl_show_info", true];
    _group addWaypoint [getPos (leader _group), 0];
    _group setVariable ["pl_draw_convoy", false];
    sleep 0.1;
    {
        [_x] spawn {
            params ["_unit"];
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "TARGET";
            _unit enableAI "PATH";
            _unit enableAI "SUPPRESSION";
            _unit enableAI "COVER";
            _unit enableAI "ANIM";
            _unit setUnitPos "AUTO";
            _unit doMove (getPos (leader (group _unit)));
            sleep 0.5;
            _unit doFollow (leader (group _unit));
            _unit limitSpeed 5000;
        };
    } forEach (units _group);

    _group setSpeedMode "NORMAL";
    _group setCombatMode "YELLOW";
    _group setBehaviour "AWARE";

    for "_i" from count waypoints _group - 1 to 0 step -1 do{
        deleteWaypoint [_group, _i];
    };
};



_group = hcSelected player select 0;
_medic = {
            if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) exitWith {_x};
        } forEach (units _group);


hint currentCommand _medic;
