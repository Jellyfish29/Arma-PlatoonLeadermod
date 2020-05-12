pl_getIn_vehicle = {
    params ["_group"];
    private ["_vics", "_targetVic"];

    _groupLen = count (units _group);

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        _vics = nearestObjects [_cords, ["Car", "Truck", "Tank"], 25, true];
    }
    else
    {
        _vics = [cursorTarget];
    };
    _group setVariable ["onTask", false];
    sleep 0.25;

    {
        _cargoCap = getNumber (configFile >> "CfgVehicles" >> typeOf _x >> "transportSoldier");
        if (_cargoCap >= _groupLen) then {
            _targetVic = _x;
        };
    } forEach _vics;
    if !(isNil "_targetVic") then {

        _targetVic setUnloadInCombat [false, false];

        for "_i" from count waypoints _group - 1 to 0 step -1 do
        {
            deleteWaypoint [_group, _i];
        };
        {
            _x disableAI "AUTOCOMBAT";
            _x setBehaviour "AWARE";
        } forEach (crew _targetVic);
        // leader _group sideChat format ["Getting in %1, over", _targetVic];
        _group setVariable ["setSpecial", true];
        _group setVariable ["onTask", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
        {
            _x disableAI "AUTOCOMBAT";
            _x setBehaviour "AWARE";
            _x assignAsCargo _targetVic;
            [_x] orderGetIn true;
        } forEach (units _group);
    }
    else
    {
        leader _group sideChat "Negativ, there is no avaiable Transport, Over"
    };
};


pl_getOut_vehicle = {
    params ["_group"];
    private ["_vic"];

    _leader = leader _group;

    if (vehicle _leader != _leader) then {
        _vic = vehicle _leader;
        _cargo = fullCrew _vic;
        _commander = 0;
            {
                if (_x select 1 isEqualTo "commander") then {
                    _commander = (_x select 0);
                };
            } forEach _cargo;
        if (visibleMap) then {
            _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            (group _commander) addWaypoint [_cords, 0];
            // _leader sideChat "Moving to Drop off point, Over";
            sleep 5;
            waitUntil {((_vic distance2D waypointPosition[(group _commander), currentWaypoint (group _commander)]) < 40) or !(_group getVariable "onTask")};
            sleep 1;
            // _leader sideChat "Reached Position, Disembarking, Over";
        }
        else
        {
            doStop _vic;
        };
        waitUntil {((speed _vic) == 0);};
        {
            _unit = _x select 0;
            _unit enableAI "AUTOCOMBAT";
            if (_x select 1 isEqualTo "cargo") then {
                unassignVehicle _unit;
                doGetOut _unit;
            };
        } forEach _cargo;
        waitUntil{(count fullCrew[ _vic, "cargo"] == 0)};
        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
        _vic doFollow _vic;
    };
};

// [hcSelected player select 0] spawn pl_getOut_vehicle;

pl_vehicle_speed_limit = {
    Params ["_group", "_speed"];

    _leader = leader _group;
    if (vehicle _leader != _leader) then {
        _vic = vehicle _leader;
        _vic limitSpeed _speed;
    };
};

pl_spawn_vic_speed = {
    params ["_speed"];
    {  
       [_x, _speed] spawn pl_vehicle_speed_limit; 
    } forEach hcSelected player;
};



// [15] spawn pl_spawn_vic_speed;

