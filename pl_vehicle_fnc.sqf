
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
pl_convoy_path_marker = [];


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
            _cargoCap = _x emptyPositions "cargo"; 
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
            driver _targetVic sideChat format ["%1: Moving to to rendez-vous location", groupId (group (driver _targetVic))];
            sleep 20;
            waitUntil {sleep 0.1; unitReady _targetVic or !alive _targetVic};
            playSound "beep";
            driver _targetVic sideChat format ["%1: Beginning landing", groupId (group (driver _targetVic))];
            _targetVic land "GET IN";
            sleep 10;
            waitUntil {sleep 0.1; (isTouchingGround _targetVic) or !alive _targetVic};
            sleep 1;
        };

        [_group] call pl_reset;
        sleep 0.2;

        // Vehicle Transport
        if ((vehicle (leader _group)) != leader _group) then {
            _vic = vehicle (leader _group);
            if ((_targetVic canVehicleCargo _vic) select 0) then {
                _targetVic animateDoor ["Door_1_source", 1];
                _vicName = getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName");
                playSound "beep";
                leader _group sideChat format ["%1: Getting in %2", (groupId _group), _vicName];
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
                hint "No avaiable Transport";
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
            leader _group sideChat format ["%1: Getting in %2", (groupId _group), _vicName];
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
                _group setVariable ["onTask", false];
                _group setVariable ["setSpecial", false];
                _group setVariable ["pl_show_info", false];
                if !(_targetVic isKindOf "Air") then {
                    player hcRemoveGroup _group;
                };
            };
        };
    }
    else
    {
        // playSound "beep";
        hint "No avaiable Transport";
    };
};


pl_getOut_vehicle = {
    params ["_group", "_convoyId", "_moveInConvoy"];
    private ["_vic", "_commander", "_markerName", "_cargo", "_cargoGroups", "_vicTransport", "_transportedVic", "_inLandConvoy", "_convoyLeader", "_convoyArray", "_convoyPosition", "_watchPos"];

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
            if ((count (missionNamespace getVariable _convoyId)) > 1) then {
                player hcRemoveGroup _group;
            };
            if ((missionNamespace getVariable (_convoyId + "time")) > time) then {
                playSound "beep";
                hint format ["%1 is already on a mission!", groupId (group (driver _vic))];
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
                // if (_shift) then {pl_cancel_strike = true};
                hintSilent "";
                onMapSingleClick "";
            };
            waitUntil {pl_mapClicked};

            // if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

            sleep 0.1;
            pl_mapClicked = false;
            _cords = pl_lz_cords;

            if ((_cords distance2D (_vic getVariable "pl_rtb_pos")) > 200) then {
                // playSound "beep";
                // _commander sideChat "Roger, Moving to Insertion Point, over";
            }
            else
            {
                _commander sideChat format ["%1: RTB", groupId (group _commander)];
            };

            _convoyArray = [];
            _inLandConvoy = false;

            // More then One Tranport == Convoy
            if ((count (missionNamespace getVariable _convoyId)) > 1) then {
                if (_group isEqualTo ((missionNamespace getVariable _convoyId) select 0)) then {
                    _c = [(missionNamespace getVariable _convoyId), [], {(leader _x) distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy;
                    missionNamespace setVariable [_convoyId, _c];

                    private _blacklistr1 = [];
                    private _r2 = [_cords, 100,[]] call BIS_fnc_nearestRoad;
                    {
                        private _r1 = [(getPos (leader _x)), 100] call BIS_fnc_nearestRoad;
                        if (_r1 in _blacklistr1) then {
                            private _roads = getPos (leader _x) nearRoads 100;
                            _roads = [_roads, [], {(getPos _x) distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy;  
                            _r1 = {
                                if !(_x in _blacklistr1) exitWith {_x};
                            } forEach _roads;
                        };
                        _blacklistr1 pushback _r1;
                        // player sideChat (str _r1);
                        _pathCost = [_r1, _r2] call pl_convoy_parth_find;
                        _x setVariable ["pl_path_cost", _pathCost];
                        _x setVariable ["r1", _r1];
                    } forEach (missionNamespace getVariable _convoyId);
                    hint "Setting up Convoy...";
                    playSound "beep";
                };
                sleep 5;
                hintSilent "";
                pl_set_up_convoy = true;

                _c = [(missionNamespace getVariable _convoyId), [], {_x getVariable ["pl_path_cost", 2000]}, "ASCEND"] call BIS_fnc_sortBy;  
                 missionNamespace setVariable [_convoyId, _c];
                pl_draw_convoy_array pushBack (missionNamespace getVariable _convoyId);
                pl_draw_convoy_array = pl_draw_convoy_array arrayIntersect pl_draw_convoy_array;
                _convoyLeader = (missionNamespace getVariable _convoyId) select 0;
                _convoyArray = (missionNamespace getVariable _convoyId);
                _convoyLeader setVariable ["onTask", true];
                _convoyLeader setVariable ["setSpecial", true];
                _convoyLeader setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa"];
                group (_commander) setVariable ["pl_draw_convoy", true];

                if (_group != _convoyLeader and _group != (group player)) then {
                    player hcRemoveGroup _group;
                };

                // Air Convoy
                if (_vic isKindOf "Air") then {
                    waitUntil {time >= (missionNamespace getVariable (_convoyId + "time")) and (group _commander) == ((missionNamespace getVariable _convoyId) select (missionNamespace getVariable (_convoyId + "pos")))};
                    if ((group _commander) != _convoyLeader) then {
                        _dir = [_cords, _vic getVariable "pl_rtb_pos"] call BIS_fnc_dirTo;
                        _moveDir = [(_dir - 90)] call pl_angle_switcher;
                        _cords =  [45*(sin _moveDir),45*(cos _moveDir), 0] vectorAdd [pl_lz_cords select 0, pl_lz_cords select 1, 0];
                        pl_lz_cords = _cords;
                    };
                    _t = time + 10;
                    missionNamespace setVariable [_convoyId + "time", _t];
                    _p  = (missionNamespace getVariable (_convoyId + "pos"));
                    _p = _p + 1;
                    missionNamespace setVariable [_convoyId + "pos", _p];
                }
                else
                // Land Convoy
                {
                    player hcSetGroup [_convoyLeader];
                    {
                        _x disableAI "AUTOCOMBAT";
                    } forEach units (group _commander);
                    _vic limitSpeed 50;
                    // _vic forceFollowRoad true;
                    // _vic setConvoySeparation 20;
                    group _commander setBehaviour "SAFE"; // SAFE
                    _inLandConvoy = true;
                    waitUntil {(time >= (missionNamespace getVariable (_convoyId + "time")) and (group _commander) == ((missionNamespace getVariable _convoyId) select (missionNamespace getVariable (_convoyId + "pos")))) or !(_convoyLeader getVariable ["onTask", true])};

                    // private _points = pl_convoy_path_marker apply {getMarkerPos _x};
                    // _vic setDriveOnPath _points;

                    _convoyPosition = (missionNamespace getVariable (_convoyId + "pos"));
                    _t = time + 4;
                    missionNamespace setVariable [_convoyId + "time", _t];
                    _p  = (missionNamespace getVariable (_convoyId + "pos"));
                    _p = _p + 1;
                    missionNamespace setVariable [_convoyId + "pos", _p];
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
            _markerName setMarkerType "mil_marker";
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
                    sleep 0.2;
                    // Land Convoy Loop
                    if (_inLandConvoy) then {
                        if (_moveInConvoy) then {
                            _wp setWaypointType "MOVE";
                        };
                        while {
                        (alive (vehicle (leader _convoyLeader))) and
                        // !(unitReady (driver (vehicle (leader _convoyLeader)))) and
                        ((leader _convoyLeader) distance2D waypointPosition[_convoyLeader, currentWaypoint _convoyLeader] > 60) and
                        (_convoyLeader getVariable ["onTask", true])
                        } do {
                            if ((group _commander) != _convoyLeader) then {
                                if ((speed (vehicle (leader (_convoyArray select _convoyPosition - 1)))) < 4) then {
                                    _vic forceSpeed 0;
                                };
                                _distance = _vic distance2d vehicle (leader (_convoyArray select _convoyPosition - 1));
                                if (_distance > 60) then {
                                    _vic forceSpeed -1;
                                    _vic limitSpeed 55;
                                };
                                if (_distance < 60) then {
                                    _vic forceSpeed -1;
                                    _vic limitSpeed 30;
                                };
                                if (_distance < 30) then {
                                    _vic forceSpeed -1;
                                    _vic limitSpeed 20;
                                };
                                if (_distance < 20) then {
                                    _vic forceSpeed 0;
                                };
                            }
                            else
                            {
                                _distance = _vic distance2d vehicle (leader (_convoyArray select 1));
                                if (_distance < 70) then {
                                    _vic forceSpeed -1;
                                    _vic limitSpeed 50;
                                };
                                if (_distance > 70) then {
                                    _vic forceSpeed -1;
                                    _vic limitSpeed 25;
                                };
                                if (_distance > 90) then {
                                    _vic forceSpeed 0;
                                };
                            };
                            sleep 1;
                        };
                        _vic forceSpeed -1;
                        _vic limitSpeed 50;
                        // Land Convoy Arriving
                        // if moveInConvoy do not unload Cargo
                        {
                            deleteMarker _x;
                        } forEach pl_convoy_path_marker;
                        if !(_moveInConvoy) then {
                            {
                                {
                                    if ((assignedVehicleRole _x) select 0 isEqualTo "Cargo") then {
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
                        };
                        {
                            player hcSetGroup [_x];
                        } forEach _convoyArray;
                        _wp setWaypointPosition [getPos _vic, 0];
                        // if !(_convoyLeader getVariable "onTask" and _convoyLeader == (group _commander)) then {
                        //     _wp = (group _commander) addWaypoint [getPos _vic, 0];
                        //     _wp setWaypointType "TR UNLOAD";
                        // };
                        _convoyLeader setVariable ["onTask", false];
                        _convoyLeader setVariable ["setSpecial", false];
                        _cVic = vehicle (leader _convoyLeader);
                        // if (_cVic getVariable ["pl_on_transport", false]) then {
                        //     _convoyLeader setVariable ["setSpecial", true];
                        //     _convoyLeader setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"]
                        // };
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
                    if !(_moveInConvoy) then {
                        {
                            _x setVariable ["pl_show_info", true];
                            // _x addWaypoint [getPos _vic, 10];
                            player hcSetGroup [_x];
                        } forEach _cargoGroups;
                    };
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

            if !(_moveInConvoy) then {
                waitUntil {sleep 0.1; ((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
                // playSound "beep";
                // _commander sideChat format ["%1 finished unloading, over", groupId _group];
                player hcSetGroup [_group];
                sleep 2;
                (group _commander) setVariable ["setSpecial", false];
            };
            _vic setVariable ["pl_on_transport", nil];
            deleteMarker _markerName;
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
                playSound "beep";
                _commander sideChat format ["%1: RTB", groupId (group _commander)];
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
            // _commander sideChat format ["Roger, %1 beginning unloading, over", groupId _group];
            waitUntil {sleep 0.1; ((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
            playSound "beep";
            // _commander sideChat format ["%1 finished unloading, over", groupId _group];
            _vic setVariable ["pl_on_transport", nil];
            (group _commander) setVariable ["setSpecial", false];
            _vic doFollow _vic;
        };
    };
};

pl_spawn_getOut_vehicle = {
    params [["_moveInConvoy", false]];
    playSound "beep";
    private _convoyArray = [];
    {
        if (vehicle (leader _x) != leader _x) then {
            _vic = vehicle (leader _x);
            _group = group (driver _vic);
            _convoyArray pushBack _group;
        };
    } forEach hcSelected player;

    _convoyArray = _convoyArray arrayIntersect _convoyArray;
    if (_moveInConvoy and ((count _convoyArray) < 2)) exitWith {
        
        (leader (hcSelected player select 0)) sidechat "Not enough Vehicle to form a Convoy";
    };
    _convoyId = str (random 2);
    c_test_id = _convoyId;
    missionNamespace setVariable [_convoyId, _convoyArray];
    missionNamespace setVariable [_convoyId + "pos", 0];
    missionNamespace setVariable [_convoyId + "time", 0];
    {
        [_x, _convoyId, _moveInConvoy] spawn pl_getOut_vehicle;
        // sleep 0.1;
    } forEach hcSelected player;  
};

pl_convoy_path_marker = [];

pl_convoy_parth_find = {
    params ["_start", "_goal"];
    private _dummyGroup = createGroup sideLogic;
    private _closedSet = [];
    private _openSet = [_start];
    private _current = _start;
    private _nodeCount = 0;
    private _allRoads = [];
    while {!(_openSet isEqualTo [])} do {
        private _closest = objNull;
        {
            if (_goal distance _x < _goal distance _closest) then {
                _closest = _x;
            };
            nil
        } count _openSet;
        _current = _closest;
        _nodeCount = _nodeCount + 1;
        if (_current == _goal) exitWith {
            private _parent = _dummyGroup getVariable ("NF_neighborParent_" + str _current);
            while {!(isNil "_parent")} do {
                _allRoads pushBack _parent;
                // private _marker = createMarker [str _parent, getPos _parent];
                // _marker setMarkerShape "ICON";
                // _marker setMarkerColor "colorBLUFOR";
                // _marker setMarkerType "MIL_DOT";
                // _marker setMarkerSize [0.3, 0.3];
                _parent = _dummyGroup getVariable ("NF_neighborParent_" + str _parent);
                // pl_convoy_path_marker pushBack _marker;
            };
        };
        _openSet = _openSet - [_current];
        _closedSet pushBack _current;
        private _neighbors = (getPos _current) nearRoads 15; // This includes current
        _neighbors append (roadsConnectedTo _current);
        {
            if (!(_x in _closedSet)) then {
                private _currentG = _dummyGroup getVariable ["NF_neighborG_" + str _current, 0];
                private _gScore = _currentG + 1;
                private _gScoreIsBest = false;
                if (!(_x in _openSet)) then {
                    _gScoreIsBest = true;
                    _openSet pushBack _x;
                } else {
                    private _neighborG = _dummyGroup getVariable ("NF_neighborG_" + str _x);
                    _gScoreIsBest = _gScore < _neighborG;
                };
                if (_gScoreIsBest) then {
                    _dummyGroup setVariable ["NF_neighborParent_" + str _x, _current];
                    _dummyGroup setVariable ["NF_neighborG_" + str _x, _gScore];
                };
            };
        } forEach _neighbors;
    };
    count _allRoads
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

    playsound "beep";

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
            leader _group sideChat format ["%1: Getting in %2", (groupId _group), _vicName];

            pl_left_vehicles = pl_left_vehicles - [[_group getVariable ["pl_group_left_vehicle", objNull], _group]];

            [_group] call pl_reset;
            sleep 0.2;

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
                // playSound "beep";
                hint "Not enough avaiable seats!";
            };
        };
    }
    else
    {
        // playSound "beep";
        hint "No avaiable Transport!";
    };
};

pl_left_vehicles = [];

pl_leave_vehicle = {
    params ["_group"];
    private ["_vic"];

    if ((leader _group) != vehicle (leader _group)) then {
        _vic = vehicle (leader _group);
        if ((driver _vic) in (units _group)) then {
            pl_left_vehicles pushBack [_vic, _group];
            _group setVariable ["pl_group_left_vehicle", _vic];
        };
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
    private _hcs = allMissionObjects "HighCommandSubordinate" select 0;
    if (isNil{_hcs}) exitWith {};
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


player addEventHandler ["GetInMan", {
    params ["_vehicle", "_role", "_unit", "_turret"];
    private ["_group"];
    _group = group player;
    _vicGroup = group (driver (vehicle player));
    _vicGroup setVariable ["setSpecial", true];
    _vicGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
    player setVariable ["pl_player_vicGroup", _vicGroup];
    if (_vicGroup != (group player)) then {
        _group setVariable ["pl_show_info", false];
        player hcRemoveGroup _group;
    };
}];

player addEventHandler ["GetOutMan", {
    params ["_vehicle", "_role", "_unit", "_turret"];
    private ["_group"];
    _group = group player;
    _vicGroup = player getVariable ["pl_player_vicGroup", (group player)];
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
    _group setVariable ["pl_show_info", true];
    player hcSetGroup [_group];

    _cargo = fullCrew [(vehicle ((units _vicGroup)#0)), "cargo", false];
    if ((count _cargo == 0)) exitWith {
        _vicGroup setVariable ["setSpecial", false];
    };
    if (({(group (_x#0)) isEqualTo _group} count _cargo) > 0) then {
        [_vicGroup, _cargo, _group] spawn {
            params ["_vicGroup", "_cargo", "_group"];
            waitUntil {sleep 1; (({(group (_x#0)) isEqualTo _group} count (fullCrew [(vehicle ((units _vicGroup)#0)), "cargo", false])) == 0)};
            _vicGroup setVariable ["setSpecial", false];
        };
    };
}];



