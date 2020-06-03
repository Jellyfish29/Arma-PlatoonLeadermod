
pl_show_vehicles = false;
pl_show_vehicles_pos = [0,0,0];
pl_vics = [];
pl_mapClicked = false;
pl_getOut_cd = 0;
pl_lz_cords = [0,0,0];
pl_lz_marker_cords = [0,0,0];
pl_convoy_pos = 0;
pl_convoy_array = [];
pl_draw_convoy_array = [];

pl_getIn_vehicle = {
    private ["_vics", "_targetVic", "_groupLen", "_group"];

    _group = hcSelected player select 0;
    _groupLen = count (units _group);

    if (visibleMap) then {
        pl_show_vehicles_pos = getPos (leader _group);
        pl_show_vehicles = true;
        hint "Select TRANSPORT on Map";
        onMapSingleClick {
            pl_mapClicked = true;
            _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            pl_vics = nearestObjects [_cords, ["Car", "Truck", "Tank", "Air"], 10, true];
            hintSilent "";
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

        // Request Airlift
        if ((_targetVic distance2D (leader _group)) > 200 and _targetVic isKindOf "Air") then {
            {
                _x disableAI "AUTOCOMBAT";
                _x disableAI "TARGET";
                _x disableAI "AUTOTARGET";
            } forEach (units (group (driver _targetVic)));
            group (driver _targetVic) addWaypoint [getPos (leader _group), 0];
            (group (driver _targetVic)) setVariable ["setSpecial", true];
            (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\takeoff_ca.paa"];
            playSound "beep";
            driver _targetVic sideChat format ["Roger, %1 is Oscar Mike to rendez-vous location, over", groupId (group (driver _targetVic))];
            sleep 20;
            waitUntil {sleep 0.1; unitReady _targetVic or !alive _targetVic};
            playSound "beep";
            driver _targetVic sideChat format ["%1 is beginning landing procedure clear LZ, over", groupId (group (driver _targetVic))];
            _targetVic land "GET IN";
            sleep 10;
            waitUntil {sleep 0.1; (isTouchingGround _targetVic) or !alive _targetVic};
            sleep 1;
        };

        _group setVariable ["onTask", false];
        sleep 0.25;

        // Vehicle Transport
        if ((vehicle (leader _group)) != leader _group) then {
            _vic = vehicle (leader _group);
            if ((_targetVic canVehicleCargo _vic) select 0) then {
                _targetVic animateDoor ["Door_1_source", 1];
                _vicName = getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName");
                playSound "beep";
                leader _group sideChat format ["Getting in %1, over", _vicName];
                _group setVariable ["pl_show_info", false];
                (group (driver _targetVic)) setVariable ["setSpecial", true];
                (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
                
                _wp = _group addWaypoint [getPosASL _targetVic, 0];
                _wp setWaypointType "VEHICLEINVEHICLEGETIN";
                // player hcRemoveGroup _group;
                {
                    player hcRemoveGroup (group (_x select 0));
                } forEach fullCrew[_vic, "cargo", false];
                // player hcSetGroup [(group (driver _targetVic))];
            }
            else
            {
                playSound "beep";
                leader _group sideChat "Negativ, there is no avaiable Transport, Over";
            };
        }
        // Infantry Tranport
        else
        {
            if (_targetVic isKindOf "Air") then {
                [_targetVic, 1] call pl_door_animation;
            };

            _targetVic setUnloadInCombat [false, false];

            for "_i" from count waypoints _group - 1 to 0 step -1 do {
                deleteWaypoint [_group, _i];
            };
            _vicName = getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName");
            leader _group sideChat format ["Getting in %1, over", _vicName];
            (group (driver _targetVic)) setVariable ["setSpecial", true];
            (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
            {
                if !(_x in (crew _targetVic)) then {
                    _x assignAsCargo _targetVic;
                    [_x] allowGetIn true;
                    [_x] orderGetIn true;
                }
                else
                {
                    [_x] allowGetIn true;
                    [_x] orderGetIn true;
                }; 
            } forEach (units _group);
            _group setVariable ["onTask", true];
            waitUntil {sleep 0.1; ({_x in _targetVic} count (units _group) > 0) or !(_group getVariable ["onTask", true])};
            if !(_group getVariable "onTask") then {
                {
                    unassignVehicle _x;
                } forEach (units _group);
                (group (driver _targetVic)) setVariable ["setSpecial", false];
            }
            else
            {
                player hcRemoveGroup _group;
                _group setVariable ["onTask", false];
                _group setVariable ["setSpecial", false];
                _group setVariable ["pl_show_info", false];
            };
        };
    }
    else
    {
        playSound "beep";
        leader _group sideChat "Negativ, there is no avaiable Transport, Over";
    };
};



/*
Get Out Structure

if Group in Vehicle
    get vehicle -> _vic
    get vehicle commander -> _commander
    check if vehicle transport vehicle
        _vicTranport = true

    if Map visible
        Select destination with mapclick

        if _vic == Air
            open doors
            setup RTB
            if take off colldown
                get new wp pos
                waitUntil cooldown over
        create "TR Unload" Waypoint for _vic
        create LZ Marker

        if not _vicTransport
            get all Groups in _vic -> cargoGroups
            if _vic == Air
                waitUntil touching ground again
                    Open Doors
                    Spawn 360° for _cargoGroups
                    show info again for _cargoGroups
            if _vic == ground
                waitUntil Waypoint reached
                    show info again for _cargoGroups
                    addWaypoints near _vic for _cargoGroups

        if _vicTransport
            waitUntil touching ground again
                Open Doors
                create "Unload Vehicle" Waypoint at _vic Position
                waitUntil Cargo unloaded

        waitUntil all Cargo unlaoded
            message all unloaded
            Reset Variables
            Deelte Marker
            if _vic == Air
                close Doors
                RTB
    if not map visible
        get all Groups in _vic -> _cargoGroups
        leaveVehicle for _cargoGroups
        show info again for _cargoGroups
        addWaypoint near _vic for _cargoGroups
        message unloading
        waitUntil all Cargo unlaoded
            message finished unloading
            Reset Variables
*/

pl_getOut_vehicle = {
    params ["_group"];
    private ["_vic", "_commander", "_markerName", "_cargo", "_cargoGroups", "_vicTransport", "_transportedVic", "_inLandConvoy", "_convoyLeader", "_convoyArray", "_convoyPosition"];

    _leader = leader _group;

    if (vehicle _leader != _leader) then {
        _vic = vehicle _leader;
        _vicTransport = false;
        if !(isNull (isVehicleCargo _vic)) then {
            _transportedVic = _vic;
            _vic = isVehicleCargo _vic;
            _vicTransport = true;
        };

        if !(isNil {_vic getVariable "pl_on_transport"}) exitWith {
            if ((count pl_convoy_array) > 1) then {
                player hcRemoveGroup _group;
            };
            if (pl_getOut_cd > time) then {
                playSound "beep";
                driver _vic sideChat "Negativ, %1 is already on a mission, over";
            };
        };

        _vic setVariable ["pl_on_transport", true];
        _cargo = fullCrew _vic;
        _commander = driver _vic;
        {
            if (_x select 1 isEqualTo "commander") then {
                _commander = (_x select 0);
            };
        } forEach _cargo;

        for "_i" from count waypoints (group _commander) - 1 to 0 step -1 do{
            deleteWaypoint [(group _commander), _i];
        };
        _cargo = fullCrew [_vic, "cargo", false];

        if (visibleMap) then {
            // Unload at selected Map Position
            // For Land Vehicles and Air Transport

            ///// Transport Set up /////

            hintSilent "Select DESTINATION on MAP";
            onMapSingleClick {
                pl_mapClicked = true;
                pl_lz_cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                pl_lz_marker_cords = pl_lz_cords;
                hintSilent "";
                onMapSingleClick "";
            };
            waitUntil {pl_mapClicked};
            sleep 0.1;
            pl_mapClicked = false;
            _cords = pl_lz_cords;

            if ((_cords distance2D (_vic getVariable "pl_rtb_pos")) > 200) then {
                playSound "beep";
                _commander sideChat "Roger, Moving to Insertion Point, over";
            }
            else
            {
                _commander sideChat format ["%1 is RTB, over", groupId (group _commander)];
            };

            _convoyArray = [];
            _inLandConvoy = false;

            // More then One Tranport == Convoy
            if ((count pl_convoy_array) > 1) then {
                pl_convoy_array = [pl_convoy_array, [], { pl_lz_cords distance2D (leader _x) }, "ASCEND"] call BIS_fnc_sortBy;  
                pl_draw_convoy_array pushBack pl_convoy_array;
                pl_draw_convoy_array = pl_draw_convoy_array arrayIntersect pl_draw_convoy_array;
                _convoyLeader = pl_convoy_array select 0;
                _convoyArray = pl_convoy_array;
                _convoyLeader setVariable ["onTask", true];
                group (_commander) setVariable ["pl_draw_convoy", true];

                if (_group != _convoyLeader and _group != (group player)) then {
                    player hcRemoveGroup _group;
                };

                // Air Convoy
                if (_vic isKindOf "Air") then {
                    waitUntil {time >= pl_getOut_cd and (group _commander) == (pl_convoy_array select pl_convoy_pos)};
                    if ((group _commander) != _convoyLeader) then {
                        _dir = [_cords, _vic getVariable "pl_rtb_pos"] call BIS_fnc_dirTo;
                        _moveDir = [(_dir - 90)] call pl_angle_switcher;
                        _cords =  [45*(sin _moveDir),45*(cos _moveDir), 0] vectorAdd [pl_lz_cords select 0, pl_lz_cords select 1, 0];
                        pl_lz_cords = _cords;
                    };
                    pl_getOut_cd = time + 10;
                    pl_convoy_pos = pl_convoy_pos + 1;
                }
                else
                // Land Convoy
                {
                    player hcSetGroup [_convoyLeader];
                    {
                        _x disableAI "AUTOCOMBAT";
                    } forEach units (group _commander);
                    _vic limitSpeed 50;
                    group _commander setBehaviour "SAFE"; // SAFE
                    _inLandConvoy = true;
                    waitUntil {time >= pl_getOut_cd and (group _commander) == (pl_convoy_array select pl_convoy_pos)};
                    _convoyPosition = pl_convoy_pos;
                    pl_getOut_cd = time + 4;
                    pl_convoy_pos = pl_convoy_pos + 1;
                };
            }
            else
            {
                _inLandConvoy = false;
            };

            _wp = (group _commander) addWaypoint [_cords, 0];
            _wp setWaypointType "TR UNLOAD";
            // Create Destination Marker
            if ((group driver (_vic)) == (group player)) then {
                (driver _vic) commandMove _cords;
            };
            _markerName = format ["lzmarker%1", (groupId _group)];
            createMarker [_markerName, pl_lz_marker_cords];
            _markerName setMarkerType "hd_end";
            _markerName setMarkerColor "colorBLUFOR";
            // Setup the cargo of Transport Vehicle
            _cargo = fullCrew [_vic, "cargo", false];
            _cargoGroups = [];
            {
                _cargoGroups pushBack (group (_x select 0));
            } forEach _cargo;
            _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

            /// Transport Execution ///

            // If Infantry is Transported
            if !(_vicTransport) then {
                if (_vic isKindOf "Air") then {
                    {
                        _x disableAI "AUTOCOMBAT";
                        _x disableAI "TARGET";
                        _x disableAI "AUTOTARGET";
                    } forEach (units (group _commander));
                    (group _commander) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
                    [_vic, 0] call pl_door_animation;
                    sleep 40;
                    // waitUntil {!alive _vic or (unitReady _vic)};
                    waitUntil {sleep 0.1; (isTouchingGround _vic) or !alive _vic};
                    // for "_i" from count waypoints _group - 1 to 0 step -1 do {
                    //     deleteWaypoint [_group, _i];
                    // };
                    [_vic, 1] call pl_door_animation;
                    {
                        _x leaveVehicle _vic;
                        player hcSetGroup [_x];
                        _x setVariable ["pl_show_info", true];
                        if (_x != (group player)) then {
                            if ((_vic distance2D (_vic getVariable "pl_rtb_pos")) > 300) then {
                                [_x, _vic] spawn pl_airassualt_security;
                            }
                            else
                            {
                                _x addWaypoint [getPos _vic, 10];
                            };
                        };
                    } forEach _cargoGroups;
                }
                else
                {
                    sleep 2;
                    // Land Convoy Loop
                    if (_inLandConvoy) then {
                        while {
                        (alive (vehicle (leader _convoyLeader))) and
                        // !(unitReady (driver (vehicle (leader _convoyLeader)))) and
                        ((leader _convoyLeader) distance2D waypointPosition[_convoyLeader, currentWaypoint _convoyLeader] > 60) and
                        (_convoyLeader getVariable "onTask")
                        } do {
                            if ((group _commander) != _convoyLeader) then {
                                _distance = _vic distance2d vehicle (leader (_convoyArray select _convoyPosition - 1));
                                if (_distance > 60) then {
                                    _vic limitSpeed 60;
                                };
                                if (_distance < 60) then {
                                    _vic limitSpeed 50;
                                };
                                if (_distance < 25) then {
                                    _vic limitSpeed 20;
                                };
                                if (_distance < 5) then {
                                    _vic limitSpeed 0;
                                };
                            };
                        sleep 1;
                        };
                        // Land Convoy Arriving
                        {
                            {
                                if ((assignedVehicleRole (leader (group _x))) select 0 isEqualTo "Cargo") then {
                                    unassignVehicle _x;
                                    doGetOut _x;
                                };
                            } forEach (units _x);
                            if (_x == (group player)) then {
                                doStop driver (vehicle (player));
                                sleep 0.1;
                                driver (vehicle (player)) doFollow player;
                            };
                            player hcSetGroup [_x];
                        } forEach _cargoGroups;
                        {
                            player hcSetGroup [_x];
                        } forEach _convoyArray;
                        _wp setWaypointPosition [getPos _vic, 0];
                        // if !(_convoyLeader getVariable "onTask" and _convoyLeader == (group _commander)) then {
                        //     _wp = (group _commander) addWaypoint [getPos _vic, 0];
                        //     _wp setWaypointType "TR UNLOAD";
                        // };
                        _convoyLeader setVariable ["onTask", false];
                        group (_commander) setVariable ["pl_draw_convoy", false];
                        group (_commander) setBehaviour "AWARE";
                        {
                            _x enableAI "AUTOCOMBAT";
                        } forEach units (group _commander);
                        pl_draw_convoy_array = pl_draw_convoy_array - [_convoyArray];
                    }
                    // Single Vehicle
                    else
                    {
                        waitUntil {sleep 0.1; ((leader _group) distance2D waypointPosition[(group _commander), currentWaypoint (group _commander)] < 30) or (!alive _vic)};
                        {
                            _unit = _x select 0;
                            _unit enableAI "AUTOCOMBAT";
                            if (_x select 1 isEqualTo "cargo") then {
                                unassignVehicle _unit;
                                doGetOut _unit;
                            };
                        } forEach _cargo;
                    };
                    {
                        _x setVariable ["pl_show_info", true];
                        // _x addWaypoint [getPos _vic, 10];
                        player hcSetGroup [_x];
                    } forEach _cargoGroups;
                    // Single Land Tarnsport ariving
                };
            }
            // If Vehicle is Transported
            else
            {
                {
                    _x disableAI "AUTOCOMBAT";
                    _x disableAI "TARGET";
                    _x disableAI "AUTOTARGET";
                } forEach (units (group _commander));
                (group _commander) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
                [_vic, 0] call pl_door_animation;
                sleep 40;

                // Air Vehicle in Vehicle Tranport Ariving
                waitUntil {sleep 0.1; (isTouchingGround _vic) or !alive _vic};
                // player hcSetGroup [_group];
                {
                    player hcsetGroup [(group (_x select 0))];
                } forEach fullCrew[vehicle (leader (_group)), "cargo", false];
                [_vic, 1] call pl_door_animation;
                sleep 5;
                for "_i" from count waypoints _group - 1 to 0 step -1 do {
                    deleteWaypoint [_group, _i];
                };
                _wp = (group _commander) addWaypoint [getPos _vic, 0];
                _wp setWaypointType  "VEHICLEINVEHICLEUNLOAD";
                // player hcRemoveGroup (group _commander);
                sleep 2;
                waitUntil {sleep 0.1; isNull (isVehicleCargo _transportedVic) or (!alive _vic)};
                _group setVariable ["pl_show_info", true];
            };

            if !(_inLandConvoy) then {
                waitUntil {sleep 0.1; ((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
                playSound "beep";
                _commander sideChat format ["%1 finished unloading, over", groupId _group];
                player hcSetGroup [_group];
            };
            sleep 2;
            (group _commander) setVariable ["setSpecial", false];
            deleteMarker _markerName;
            _vic setVariable ["pl_on_transport", nil];
            sleep 10;

            // Air Tranport Ariving
            if (_vic isKindOf "Air") then {
                _rtbCords = _vic getVariable "pl_rtb_pos";
                [_vic, 0] call pl_door_animation;
                if ((_vic distance2D _rtbCords) < 300) exitWith {_vic engineOn false};
                (group _commander) addWaypoint [_rtbCords, 0];
                {
                    _x disableAI "AUTOCOMBAT";
                } forEach (crew _vic);
                sleep 2;
                _commander sideChat format ["%1 is RTB, over", groupId (group _commander)];
                waitUntil {sleep 0.1; (unitReady _vic) or (!alive _vic)};
                {
                    _x enableAI "AUTOCOMBAT";
                } forEach (crew _vic);
                sleep 1;
                // doStop _vic;
                {
                    _x enableAI "AUTOCOMBAT";
                    _x disableAI "TARGET";
                    _x enableAI "AUTOTARGET";
                } forEach (units (group _commander));
                group (_commander) setVariable ["pl_draw_convoy", false];
                pl_draw_convoy_array = pl_draw_convoy_array - [_convoyArray];
                _vic land "LAND";
            };
        }
        else
        {
            // Unload at Current Position when map closed
            _cargoGroups = [];
            doStop _vic;
            for "_i" from count waypoints (group _commander) - 1 to 0 step -1 do{
                deleteWaypoint [(group _commander), _i];
            };
            {
                _unit = _x select 0;
                unassignVehicle _unit;
                doGetOut _unit;
                _cargoGroups pushBack (group (_x select 0));
            } forEach _cargo;
            _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;
            {
                // _x leaveVehicle _vic;
                _x setVariable ["pl_show_info", true];
                player hcSetGroup [_x];
                // _x addWaypoint [getPos _vic, 10];
            } forEach _cargoGroups;

            playSound "beep";
            _commander sideChat format ["Roger, %1 beginning unloading, over", groupId _group];
            waitUntil {sleep 0.1; ((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
            playSound "beep";
            _commander sideChat format ["%1 finished unloading, over", groupId _group];
            _vic setVariable ["pl_on_transport", nil];
            (group _commander) setVariable ["setSpecial", false];
            _vic doFollow _vic;
        };
    };
};

pl_door_animation = {
    params ["_vic", "_mode"];
    _vic animateDoor ["Door_rear_source", _mode];
    _vic animateDoor ["Door_1_source", _mode];
    _vic animateDoor ["Door_L", _mode];
    _vic animateDoor ["Door_R", _mode];

};

pl_airassualt_security = {
    params ["_group", "_vic"];
    _moveDir = [((getDir _vic) - 180)] call pl_angle_switcher;
    _coverPos =  [65*(sin _moveDir), 65*(cos _moveDir), 0] vectorAdd (getPos (_vic));
    _group addWaypoint [_coverPos, 7];
    waitUntil {sleep 0.1; {_x in _vic} count (units _group) ==  0};
    sleep 1;
    [_group, 20] spawn pl_360_at_mappos;
};

pl_spawn_getOut_vehicle = {
    pl_convoy_array = [];
    {
        if (vehicle (leader _x) != leader _x) then {
            _vic = vehicle (leader _x);
            _group = group (driver _vic);
            pl_convoy_array pushBack _group;
        };
    } forEach hcSelected player;

    pl_convoy_array = pl_convoy_array arrayIntersect pl_convoy_array;
    pl_convoy_pos = 0;
    {
        [_x] spawn pl_getOut_vehicle;
        sleep 0.1;
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
            pl_vics = nearestObjects [_cords, ["Car", "Truck", "Tank", "Air"], 10, true];
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

        _crew = [];
        if (_targetVic emptyPositions "Driver" > 0) then {
            _vicName = getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName");
            playSound "beep";
            leader _group sideChat format ["Getting in %1, over", _vicName];

            _group setVariable ["onTask", false];
            sleep 0.25;

            if ((_targetVic emptyPositions "Gunner" > 0) and (_targetVic emptyPositions "Commander" == 0)) then {
                if (_group != (group player)) then {
                    (leader _group) assignAsDriver _targetVic;
                    _crew pushBack (leader _group);
                }
                else
                {
                    _unit = (units _group) select {_x != player} select 0;
                    _unit assignAsDriver _targetVic;
                    _crew pushBack _unit;
                };
                {
                    if !(_x in _crew) exitWith {
                        _x assignAsGunner _targetVic;
                        _crew pushBack _x;
                    };
                } forEach ((units _group) select {_x != player});
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
                [_x] allowGetIn true;
                [_x] orderGetIn true;
            } forEach (units _group);
        }
        else
        {
            {
                if (_x in (crew _targetVic)) then {
                    _crew pushBack _x;
                };
            } forEach (units _group);
            _groupLen = _groupLen - count _crew;
            _cargoCap = _crewCap - (count (crew _targetVic));  
            if (_cargoCap >= _groupLen) then {
                {
                    if !(_x in (crew _targetVic)) then {
                        _x assignAsCargo _targetVic;
                        [_x] allowGetIn true;
                        [_x] orderGetIn true;
                    };
                    // else
                    // {
                    //     [_x] allowGetIn true;
                    //     [_x] orderGetIn true;
                    // }; 
                } forEach (units _group);
            }
            else
            {
                playSound "beep";
                leader _group sideChat "Negativ, there aren't enough avaiable seats, Over";
            };
        };
    }
    else
    {
        playSound "beep";
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

pl_viv_trans_set_up = {
    params ["_group"];
    _vic = vehicle (leader _group);
    _targetVic = isVehicleCargo _vic;
    _group setVariable ["pl_show_info", false];
    (group (driver _targetVic)) setVariable ["setSpecial", true];
    (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
    {
        player hcRemoveGroup (group (_x select 0));
    } forEach fullCrew[_vic, "cargo", false];
};

pl_inf_trans_set_up = {
    params ["_group"];
    _targetVic = vehicle (leader _group);
    (group (driver _targetVic)) setVariable ["setSpecial", true];
    (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    _group setVariable ["pl_show_info", false];
};

sleep 1;
{
    _leader = leader _x;
    _hcs = allMissionObjects "HighCommandSubordinate" select 0;
    if ((_hcs in (synchronizedObjects _leader)) and (vehicle _leader != _leader)) then {
        if (((assignedVehicleRole _leader) select 0) isEqualTo "cargo") then {
            [_x] call pl_inf_trans_set_up;
            [_x, true] spawn pl_contact_report;
        };
        if !(isNull (isVehicleCargo (vehicle _leader))) then {
            [_x] call pl_viv_trans_set_up;
            [_x, true] spawn pl_contact_report;

        };

    };
} forEach (allGroups select {side _x isEqualTo playerSide});

