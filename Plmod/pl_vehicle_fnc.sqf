pl_show_vehicles = false;
pl_show_vehicles_pos = [0,0,0];
pl_vics = [];
pl_mapClicked = false;

pl_getIn_vehicle = {
    private ["_vics", "_targetVic", "_groupLen"];

    _group = hcSelected player select 0;
    _groupLen = count (units _group);

    if (visibleMap) then {
        pl_show_vehicles_pos = getPos (leader _group);
        pl_show_vehicles = true;
        onMapSingleClick {
            pl_mapClicked = true;
            _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            pl_vics = nearestObjects [_cords, ["Car", "Truck", "Tank"], 10, true];
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {sleep 0.1};
        pl_show_vehicles = false;
        pl_mapClicked = false;
    }
    else
    {
        pl_vics = [cursorTarget];
    };
    {
        if (vehicle (leader _group) == leader _group) then {
            _cargoCap = getNumber (configFile >> "CfgVehicles" >> typeOf _x >> "transportSoldier");
            if (_cargoCap >= _groupLen) then {
                _targetVic = _x;
            };
        }
        else
        {
            _vic = vehicle (leader _group);
            _crewCap = [typeOf _vic, true] call BIS_fnc_crewCount;
            _cargoCap = _crewCap - (count (crew _vic));
            _groupLen = 0;
            {
                if (vehicle _x == _x) then {
                    _groupLen = _groupLen + 1;
                };
            } forEach (units _group);
            if (_cargoCap >= _groupLen) then {
                _targetVic = _x;
            };
        };
    } forEach pl_vics;
    if !(isNil "_targetVic") then {

        _group setVariable ["onTask", false];
        sleep 0.25;

        _targetVic setUnloadInCombat [false, false];

        for "_i" from count waypoints _group - 1 to 0 step -1 do
        {
            deleteWaypoint [_group, _i];
        };
        // {
        //     _x disableAI "AUTOCOMBAT";
        //     _x setBehaviour "AWARE";
        // } forEach (crew _targetVic);
        _vicName = getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName");
        leader _group sideChat format ["Getting in %1, over", _vicName];
        _group setVariable ["setSpecial", true];
        _group setVariable ["onTask", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
        {
            // _x disableAI "AUTOCOMBAT";
            // _x setBehaviour "AWARE";
            if !(_x in (crew _targetVic)) then {
                _x assignAsCargo _targetVic;
                [_x] orderGetIn true;
            };
        } forEach (units _group);
    }
    else
    {
        leader _group sideChat "Negativ, there is no avaiable Transport, Over";
    };
};


pl_getOut_vehicle = {
    params ["_group"];
    private ["_vic"];

    _leader = leader _group;

    if (vehicle _leader != _leader) then {
        _vic = vehicle _leader;
        _cargo = fullCrew _vic;
        _commander = driver _vic;
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
        waitUntil {((speed _vic) == 0)};
        {
            _unit = _x select 0;
            _unit enableAI "AUTOCOMBAT";
            if (_x select 1 isEqualTo "cargo") then {
                unassignVehicle _unit;
                doGetOut _unit;
            };
        } forEach _cargo;
        _time = time + 10;
        waitUntil {time >= _time};
        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
        _vic doFollow _vic;
    };
};

pl_spawn_getOut_vehicle = {
    {
        [_x] spawn pl_getOut_vehicle; 
    } forEach hcSelected player;  
};

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

pl_crew_vehicle = {
    private ["_group", "_vics", "_targetVic", "_crew", "_crewCap", "_groupLen"];
    _group = hcSelected player select 0;
    _groupLen = count (units _group);


    if (visibleMap) then {
        pl_show_vehicles_pos = getPos (leader _group);
        pl_show_vehicles = true;
        onMapSingleClick {
            pl_mapClicked = true;
            _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            pl_vics = nearestObjects [_cords, ["Car", "Truck", "Tank"], 10, true];
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {sleep 0.1};
        pl_show_vehicles = false;
        pl_mapClicked = false;
    }
    else
    {
        pl_vics = [cursorTarget];
    };
    {
        _crewCap = [typeOf _x, true] call BIS_fnc_crewCount;
        if (_crewCap >= _groupLen) then {
            _targetVic = _x;
        };
        if (vehicle (leader _group) == _x) then {
            _targetVic = _x;
        };
    } forEach pl_vics;
    if !(isNil "_targetVic") then {

        _targetVic setUnloadInCombat [false, false];

        if (_targetVic emptyPositions "Driver" > 0) then {
            _vicName = getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName");
            leader _group sideChat format ["Getting in %1, over", _vicName];
            _group setVariable ["onTask", false];
            sleep 0.25;
            _crew = [];

            if ((_targetVic emptyPositions "Gunner" > 0) and (_targetVic emptyPositions "Commander" == 0)) then {
                (leader _group) assignAsDriver _targetVic;
                _crew pushBack (leader _group);
                {
                    if !(_x in _crew) exitWith {
                        _x assignAsGunner _targetVic;
                        _crew pushBack _x;
                    };
                } forEach (units _group);
            };

            if (_targetVic emptyPositions "Commander" > 0) then {
                (leader _group) assignAsCommander _targetVic;
                _crew pushBack (leader _group);
                {
                    if !(_x in _crew) exitWith {
                        _x assignAsGunner _targetVic;
                        _crew pushBack _x;
                    };
                } forEach (units _group);
                {
                    if !(_x in _crew) exitWith {
                        _x assignAsDriver _targetVic;
                        _crew pushBack _x;
                    };
                } forEach (units _group);
            }
            else
            { 
                (leader _group) assignAsDriver _targetVic;
                _crew pushBack (leader _group);
            };
            {
                if !(_x in _crew) then {
                    _x assignAsCargo _targetVic;
                };
                [_x] orderGetIn true;
            } forEach (units _group);
        }
        else
        {
            _cargoCap = _crewCap - (count (crew _targetVic));  
            if (_cargoCap >= _groupLen) then {
                {
                    if !(_x in (crew _targetVic)) then {
                        _x assignAsCargo _targetVic;
                        [_x] orderGetIn true;
                    };
                } forEach (units _group);
            }
            else
            {
                leader _group sideChat "Negativ, there aren't enough avaiable seats, Over";
            };
        };
    }
    else
    {
        leader _group sideChat "Negativ, there is no avaiable Transport, Over";
    };
};



pl_leave_vehicle = {
    params ["_group"];
    private ["_vic"];

    if ((leader _group) != vehicle (leader _group)) then {
        _vic = vehicle (leader _group);
        _group leaveVehicle _vic;
        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
    };
};

pl_spawn_leave_vehicle = {
    {
        [_x] spawn pl_leave_vehicle;
    } forEach hcSelected player;  
};


// [15] spawn pl_spawn_vic_speed;

