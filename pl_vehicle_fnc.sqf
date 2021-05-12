
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
            pl_vics = nearestObjects [_cords, ["Car", "Truck", "Tank", "Air"], 50, true];
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
        pl_vics = [pl_vics, [], {_x distance2D (leader _group)}, "ASCEND"] call BIS_fnc_sortBy;
        if (vehicle (leader _group) == leader _group) then {
            _cargoCap = (_x emptyPositions "cargo") + (_x emptyPositions "gunner") + (_x emptyPositions "commander");
            if (_cargoCap >= _groupLen) exitWith {
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
            if (_cargoCap >= _groupLen) exitWith {
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
            if (pl_enable_beep_sound) then {playSound "beep"};
            driver _targetVic sideChat format ["%1: Moving to LZ", groupId (group (driver _targetVic))];
            if (pl_enable_map_radio) then ([group (driver _targetVic), "...Moving to LZ", 25] call pl_map_radio_callout);
            sleep 20;
            waitUntil {sleep 0.1; unitReady _targetVic or !alive _targetVic};
            if (pl_enable_beep_sound) then {playSound "beep"};
            driver _targetVic sideChat format ["%1: Beginning landing", groupId (group (driver _targetVic))];
            if (pl_enable_map_radio) then ([group (driver _targetVic), "...Beginning Landing", 25] call pl_map_radio_callout);
            _targetVic land "GET IN";
            // _targetVic land "LAND";
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
                if (pl_enable_beep_sound) then {playSound "beep"};
                if (pl_enable_chat_radio) then (leader _group sideChat format ["%1: Getting in %2", (groupId _group), _vicName]);
                if (pl_enable_map_radio) then ([_group, format ["...Getting in %1", _vicName], 15] call pl_map_radio_callout);
                // _group setVariable ["pl_show_info", false];

                [_group] call pl_hide_group_icon;
                (group (driver _targetVic)) setVariable ["setSpecial", true];
                (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
                
                _wp = _group addWaypoint [getPosASL _targetVic, 0];
                _wp setWaypointType "VEHICLEINVEHICLEGETIN";
                // player hcRemoveGroup _group;
                {
                    [group (_x select 0)] call pl_hide_group_icon;;
                } forEach fullCrew[_vic, "cargo", false];
                // player hcSetGroup [(group (driver _targetVic))];
            }
            else
            {
                if (pl_enable_beep_sound) then {playSound "beep"};
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
            if (pl_enable_chat_radio) then (leader _group sideChat format ["%1: Getting in %2", (groupId _group), _vicName]);
            if (pl_enable_map_radio) then ([_group, format ["...Getting in %1", _vicName], 15] call pl_map_radio_callout);
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
            waitUntil {({_x in _targetVic} count (units _group) == count (units _group)) or !(_group getVariable ["onTask", true])};
            if !(_group getVariable "onTask") then {
                {
                    unassignVehicle _x;
                    doGetOut _x;
                } forEach (units _group);
                [units _group] allowGetIn false;
                (group (driver _targetVic)) setVariable ["setSpecial", false];

            }
            else
            {
                _group setVariable ["onTask", false];
                _group setVariable ["setSpecial", false];
                [_group] call pl_hide_group_icon;
                player hcRemoveGroup _group;
                // _group setVariable ["pl_show_info", false];
                // if !(_targetVic isKindOf "Air") then {
                // };
            };
        };
    }
    else
    {
        // if (pl_enable_beep_sound) then {playSound "beep"};
        hint "No avaiable Transport";
    };
};


pl_getOut_vehicle = {
    params ["_group", "_convoyId", "_moveInConvoy", ["_atPosition", false]];
    private ["_vic", "_commander", "_markerName", "_cargo", "_cargoGroups", "_vicTransport", "_transportedVic", "_inLandConvoy", "_convoyLeader", "_convoyArray", "_convoyPosition", "_watchPos", "_landigPad", "_distanceBack", "_landCords"];

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
                if (pl_enable_beep_sound) then {playSound "beep"};
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

        if (visibleMap and !_atPosition) then {
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


            sleep 0.1;
            pl_mapClicked = false;
            _cords = pl_lz_cords;

            // (group (driver _vic)) setVariable ["onTask", true];
            if (!(_moveInConvoy) and (count _cargo) > 0) then {
                (group (driver _vic)) setVariable ["setSpecial", true];
                (group (driver _vic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
            };

            if ((_cords distance2D (_vic getVariable "pl_rtb_pos")) > 200) then {
                // if (pl_enable_beep_sound) then {playSound "beep"};
                // _commander sideChat "Roger, Moving to Insertion Point, over";
            }
            else
            {
                _commander sideChat format ["%1: RTB", groupId (group _commander)];
                if (pl_enable_map_radio) then ([group _commander, "...RTB", 25] call pl_map_radio_callout);
            };

            _convoyArray = [];
            _inLandConvoy = false;

            // More then One Tranport == Convoy
            if ((count (missionNamespace getVariable _convoyId)) > 1) then {
                if (_group isEqualTo ((missionNamespace getVariable _convoyId) select 0)) then {
                    _c = [(missionNamespace getVariable _convoyId), [], {(leader _x) distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy;
                    missionNamespace setVariable [_convoyId, _c];

                    if !(_vic isKindOf "Air") then {
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
                        if (pl_enable_beep_sound) then {playSound "beep"};
                    }
                    else
                    {
                        hint "Setting up Flight...";
                        if (pl_enable_beep_sound) then {playSound "beep"};
                    };
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
                if (_group == _convoyLeader) then {
                    // private _convoyLeaderGroupId = groupId _convoyLeader;
                    // _convoyLeader setGroupId [format ["%1 (Convoy Leader)", _convoyLeaderGroupId]];
                    _leaderIsTransport = false;
                    if (_convoyLeader getVariable ["setSpecial", false]) then {
                        _leaderIsTransport = true;
                    };
                };
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
                        _cords =  [25*(sin _moveDir),25*(cos _moveDir), 0] vectorAdd [pl_lz_cords select 0, pl_lz_cords select 1, 0];

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
                    _vic limitSpeed 51;
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
            if (_vic isKindOf "Air") then {
                _landCords = _cords findEmptyPosition [0, 100, "Land_HelipadEmpty_F"];
                if (_landCords isEqualTo []) then {_landCords = _cords};
                _landigPad = "Land_HelipadEmpty_F" createVehicle _landCords;
                _landigPad setDir (_vic getDir _landCords);

                // _m = createMarker [str (random 2), _landCords];
                // _m setMarkerType "mil_dot";
            };

            // Create Destination Marker
            private _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa";
            if (_moveInConvoy) then {_icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa"};
            // pl_draw_planed_task_array pushBack [_wp, _icon];

            if ((group driver (_vic)) == (group player)) then {
                (driver _vic) commandMove _cords;
            };
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
                        // {
                        //     _unit = _x;
                        //     [_unit] orderGetIn false;
                        //     [_unit] allowGetIn false;
                        //     unassignVehicle _unit;
                        // } forEach (units _x);
                        _x leaveVehicle _vic;
                        // player hcSetGroup [_x];
                        // _x setVariable ["pl_show_info", true];
                        if !(_x getVariable ["pl_show_info", false]) then {
                            [_x] call pl_show_group_icon;
                        };
                        if (_x != (group player)) then {
                            if ((_vic distance2D (_vic getVariable "pl_rtb_pos")) > 300) then {
                                // [_x, _vic] spawn pl_airassualt_security;
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

                        _vic setVariable ["pl_speed_limit", "CON"];
                        [_group] call pl_vehicle_soft_unstuck;
                        // _vic forceFollowRoad true;

                        while {
                        (alive (vehicle (leader _convoyLeader))) and
                        // !(unitReady (driver (vehicle (leader _convoyLeader)))) and
                        ((leader _convoyLeader) distance2D waypointPosition[_convoyLeader, currentWaypoint _convoyLeader] > 60) and
                        (_convoyLeader getVariable ["onTask", true])
                        } do {
                            private _convoyLeaderSpeed = (vehicle (leader _convoyLeader)) getVariable "pl_speed_limit";
                            switch (_convoyLeaderSpeed) do { 
                                case "CON" : {_convoyLeaderSpeed = 50}; 
                                case "MAX" : {_convoyLeaderSpeed = 70}; 
                                default {_convoyLeaderSpeed = parseNumber _convoyLeaderSpeed}; 
                            };
                            private _convoyLeaderVic = vehicle (leader _convoyLeader);
                            if ((group _commander) == _convoyLeader) then {
                                _distance = _vic distance2d vehicle (leader (_convoyArray select 1));
                                _vic forceSpeed -1;
                                _vic limitSpeed _convoyLeaderSpeed;
                                if (_distance < 70) then {
                                    _vic limitSpeed _convoyLeaderSpeed;
                                };
                                if (_distance > 70) then {
                                    _vic limitSpeed (_convoyLeaderSpeed - (_convoyLeaderSpeed / 2));
                                };
                                if (_distance > 90) then {
                                    _vic forceSpeed 0;
                                };
                                if ((speed _vic) == 0) then {
                                    _timeout = time + 7;
                                    waitUntil {(speed _vic) > 0 or time >= _timeout};
                                    if ((speed _vic) == 0) then {
                                        [_group] call pl_vehicle_soft_unstuck;
                                    };
                                };
                            }
                            else
                            {
                                _leaderBehavior = behaviour (leader _convoyLeader);
                                _group setBehaviour _leaderBehavior;
                                if ((speed (vehicle (leader (_convoyArray select (_convoyPosition - 1))))) < 4) then {
                                    _vic forceSpeed 0;
                                };
                                _distance = _vic distance2d vehicle (leader (_convoyArray select _convoyPosition - 1));
                                _vic forceSpeed -1;
                                _vic limitSpeed _convoyLeaderSpeed;
                                if (_distance > 60) then {
                                    _vic limitSpeed (_convoyLeaderSpeed + 8);
                                };
                                if (_distance < 60) then {
                                    _vic limitSpeed _convoyLeaderSpeed;
                                };
                                if (_distance < 40) then {
                                    _vic limitSpeed (_convoyLeaderSpeed - (_convoyLeaderSpeed / 2));
                                };
                                if (_distance < 30) then {
                                    _vic forceSpeed 0;
                                    _vic limitSpeed 0;
                                };
                                _distanceBack = 0;
                                if (_convoyPosition < ((count (_convoyArray)) - 1)) then {
                                    _distanceBack = _vic distance2d vehicle (leader (_convoyArray select _convoyPosition + 1));
                                    if (_distanceBack > 90) then {
                                        _vic forceSpeed 0;
                                        _convoyLeaderVic limitSpeed ((_convoyLeaderSpeed / 2) - 8);
                                    },
                                };
                                if ((speed _vic) == 0) then {
                                    _timeout = time + 7;
                                    waitUntil {(speed _vic) > 0 or time >= _timeout};
                                    if ((speed _vic) == 0) then {
                                        [_group] call pl_vehicle_soft_unstuck;
                                    };
                                };
                            };
                            sleep 0.5;
                        };
                        sleep 0.5;
                        _vic forceSpeed -1;
                        _vic limitSpeed 50;
                        _vic setVariable ["pl_speed_limit", "50"];
                        _vic forceFollowRoad false;
                        // Land Convoy Arriving
                        // if moveInConvoy do not unload Cargo

                        if !(_moveInConvoy) then {
                            if (_vic getVariable ["pl_on_transport", false]) then {
                                {
                                    {
                                        if ((assignedVehicleRole _x) select 0 isEqualTo "Cargo") then {
                                            unassignVehicle _x;
                                            doGetOut _x;
                                        };
                                    } forEach (units _x);
                                    [(units _x)] allowGetIn false;
                                    if (_x == (group player)) then {
                                        doStop driver (vehicle (player));
                                        sleep 0.1;
                                        driver (vehicle (player)) doFollow player;
                                    };
                                    // player hcSetGroup [_x];
                                    if !(_x getVariable ["pl_show_info", false]) then {
                                        [_x] call pl_show_group_icon;
                                    };
                                    _x leaveVehicle _vic;
                                } forEach _cargoGroups;
                            };
                        };
                        {
                            player hcSetGroup [_x];
                        } forEach _convoyArray;
                        _wp setWaypointPosition [getPos _vic, 0];

                        // remnove wp task icon
                        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];

                        _convoyLeader setVariable ["onTask", false];
                        _convoyLeader setVariable ["setSpecial", false];
                        // if (_group == _convoyLeader) then {
                            // _convoyLeader setGroupId [_convoyLeaderGroupId];
                        _cVic = vehicle (leader _convoyLeader);
                        _cCargo = fullCrew [_cvic, "cargo", false];
                        if ((count _cCargo) > 0) then {
                            _convoyLeader setVariable ["setSpecial", true];
                            _convoyLeader setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
                        };
                        // };
                        // check if convoyLeader has cargo --> set icon

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
                        waitUntil {((leader _group) distance2D waypointPosition[(group _commander), currentWaypoint (group _commander)] < 30) or (!alive _vic)};
                        // remnove wp task icon
                        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];

                        deleteWaypoint [_group, _wp#1];

                        sleep 0.5;
                        if (_vic getVariable ["pl_on_transport", false]) then {
                            {
                                _unit = _x select 0;
                                _unit enableAI "AUTOCOMBAT";
                                if (_x select 1 isEqualTo "cargo") then {
                                    unassignVehicle _unit;
                                    doGetOut _unit;
                                    (group _unit) leaveVehicle _vic;
                                    [_unit] allowGetIn false;
                                };
                            } forEach _cargo;
                        };
                    };
                    if (!_moveInConvoy and _vic getVariable ["pl_on_transport", false]) then {
                        {
                            // _x setVariable ["pl_show_info", true];
                            if !(_x getVariable ["pl_show_info", false]) then {
                                [_x] call pl_show_group_icon;
                            };
                            _x leaveVehicle _vic;
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
                waitUntil {isNull (isVehicleCargo _transportedVic) or (!alive _vic)};
                // _group setVariable ["pl_show_info", true];
                if !(_group getVariable ["pl_show_info", false]) then {
                    [_group] call pl_show_group_icon;
                };
                // _group leaveVehicle _vic;
            };

            if !(_moveInConvoy) then {
                waitUntil {((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
                // if (pl_enable_beep_sound) then {playSound "beep"};
                // _commander sideChat format ["%1 finished unloading, over", groupId _group];
                player hcSetGroup [_group];
                sleep 2;
                (group _commander) setVariable ["setSpecial", false];
            };
            _vic setVariable ["pl_on_transport", nil];
            sleep 10;

            // Air Tranport Ariving
            if (_vic isKindOf "Air") then {
                deleteVehicle _landigPad;
                _rtbCords = _vic getVariable "pl_rtb_pos";
                [_vic, 0] call pl_door_animation;
                if ((_vic distance2D _rtbCords) < 300) exitWith {_vic engineOn false};
                (group _commander) addWaypoint [_rtbCords, 0];
                {
                    _x disableAI "AUTOCOMBAT";
                } forEach (crew _vic);
                sleep 2;
                if (pl_enable_beep_sound) then {playSound "beep"};
                _commander sideChat format ["%1: RTB", groupId (group _commander)];
                if (pl_enable_map_radio) then ([group _commander, "...RTB", 25] call pl_map_radio_callout);
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
            _vic = vehicle (leader _group);
            _driver = driver _vic;
            _vicGroup = group _driver;
            doStop _vic;
            _cargo = fullCrew [_vic, "cargo", false];
            _cargoGroups = [];
            {
                _unit = _x select 0;
                if !(_unit in (units _vicGroup)) then {
                    unassignVehicle _unit;
                    doGetOut _unit;
                    [_unit] allowGetIn false;
                    _cargoGroups pushBack (group (_x select 0));
                };
            } forEach _cargo;
            _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;
            {
                // _x leaveVehicle _vic;
                // _x setVariable ["pl_show_info", true];
                // player hcSetGroup [_x];
                if !(_x getVariable ["pl_show_info", false]) then {
                    [_x] call pl_show_group_icon;
                };
                _x leaveVehicle _vic;
                // _x addWaypoint [getPos _vic, 10];
            } forEach _cargoGroups;

            if (pl_enable_beep_sound) then {playSound "beep"};
            // _commander sideChat format ["Roger, %1 beginning unloading, over", groupId _group];
            waitUntil {sleep 0.1; ((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
            if (pl_enable_beep_sound) then {playSound "beep"};
            // _commander sideChat format ["%1 finished unloading, over", groupId _group];
            _vic setVariable ["pl_on_transport", nil];
            (group _commander) setVariable ["setSpecial", false];
            _vic doFollow _vic;
        };
    };
};

pl_dismount_cargo = {
    params [["_group", (hcSelected player) select 0]];

    if (pl_enable_beep_sound) then {playSound "beep"};

    _vic = vehicle (leader _group);
    _driver = driver _vic;
    _vicGroup = group _driver;
    doStop _vic;
    _cargo = fullCrew [_vic, "cargo", false];
    {
        _unit = _x select 0;
        if (_unit in (units _vicGroup)) then {
            _unit = _x select 0;
            doGetOut _unit;
            [_unit] allowGetIn false;
        };
    } forEach _cargo;

    {
        _x doFollow (leader _group);
    } forEach (units _group);
};

// [] spawn pl_dismount_cargo;

pl_unload_at_position_planed = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];

    if (vehicle (leader _group) == leader _group) exitWith {hint "Vehicle Only Task!"};

    _vic = vehicle (leader _group);
    _driver = driver _vic;
    _vicGroup = group _driver;
    _cargo = fullCrew [_vic, "cargo", false];

    _cargoGroups = [];
    {
        _unit = _x select 0;
        if !(_unit in (units _vicGroup)) then {
            _cargoGroups pushBack (group (_x select 0));
        };
    } forEach _cargo;

    _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

    if (_cargoGroups isEqualTo []) exitWith {hint "No Cargo to Unload"};

    if (count _taskPlanWp != 0) then {

        pl_draw_unload_inf_task_plan_icon_array pushBack [_cargoGroups#0, waypointPosition _taskPlanWp];

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 20) or !(_group getVariable ["pl_task_planed", false])};

        deleteWaypoint [_group, _taskPlanWp#1];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    doStop _vic;
    {
        _unit = _x select 0;
        if !(_unit in (units _vicGroup)) then {
            unassignVehicle _unit;
            doGetOut _unit;
            [_unit] allowGetIn false;
        };
    } forEach _cargo;

    {
        if !(_x getVariable ["pl_show_info", false]) then {
            [_x] call pl_show_group_icon;
        };
        _x leaveVehicle _vic;
    } forEach _cargoGroups;

    if (pl_enable_beep_sound) then {playSound "beep"};
    // _commander sideChat format ["Roger, %1 beginning unloading, over", groupId _group];
    waitUntil {sleep 0.1; ((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
    if (pl_enable_beep_sound) then {playSound "beep"};
    // _commander sideChat format ["%1 finished unloading, over", groupId _group];
    _vic setVariable ["pl_on_transport", nil];
    (group (driver _vic)) setVariable ["setSpecial", false];
    _vic doFollow _vic;
};

pl_spawn_getOut_vehicle = {
    params [["_moveInConvoy", false]];
    if (pl_enable_beep_sound) then {playSound "beep"};
    private _convoyArray = [];
    {
        if (vehicle (leader _x) != leader _x) then {
            _vic = vehicle (leader _x);
            _vic engineOn true;
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
};

pl_vehicle_speed_limit = {
    Params ["_group", "_speed"];
    private ["_strSpeed", "_vic"];

    _leader = leader _group;
    _vic = vehicle _leader;
    if (vehicle _leader != _leader) then {
        _vic limitSpeed _speed;
    };
    if (_speed > 50) then {_strSpeed = "MAX"} else {_strSpeed = str _speed};
    _vic setVariable ["pl_speed_limit", _strSpeed];
};

pl_spawn_vic_speed = {
    params ["_speed"];

    if (pl_enable_beep_sound) then {playSound "beep"};

    {  
       [_x, _speed] spawn pl_vehicle_speed_limit; 
    } forEach hcSelected player;
};

pl_crew_vehicle = {
    private ["_group", "_targetVic", "_groupLen"];
    _group = hcSelected player select 0;

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
    _targetVic = pl_vics select 0;
    if (isNil "_targetVic") exitWith {hint "No available vehicle!"};

    [_group] call pl_reset;

    sleep 0.2;

    _unitsInVic = {vehicle _x == _targetVic} count (units _group);
    _groupLen = (count (units _group)) - _unitsInVic;
    _occupiedSeats = count (fullCrew [_targetVic, "", false]);
    _avaibleSeats = (count (fullCrew [_targetVic, "", true])) - _occupiedSeats;
    if (_avaibleSeats >= _groupLen) then {
        pl_left_vehicles = pl_left_vehicles - [[_targetVic, _group]];
        _group addVehicle _targetVic;
        {
            [_x] allowGetIn true;
            [_x] orderGetIn true;
        } forEach (units _group);
        if (pl_enable_chat_radio) then ((leader _group) sideChat format ["%1: Crewing %2", groupId _group, getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName")]);
        if (pl_enable_map_radio) then ([_group, format ["Crewing %1", getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName")], 25] call pl_map_radio_callout);
    }
    else
    {
        hint "Not enough available seats!"
    };
};

pl_crew_vehicle_now = {
    params ["_group", "_targetVic"];

    pl_left_vehicles = pl_left_vehicles - [[_targetVic, _group]];
    _group addVehicle _targetVic;
    {
        [_x] allowGetIn true;
        [_x] orderGetIn true;
    } forEach (units _group);
};
    
pl_left_vehicles = [];

pl_leave_vehicle = {
    params ["_group"];
    private ["_vic"];

    _vic = {
        if (vehicle _x != _x) exitWith {vehicle _x};
        objNull
    } forEach (units _group);

    if (isNull _vic) exitWith {hint "Group is not crewing a Vehicle!"};

    _cargo = fullCrew [_vic, "cargo", false];
    _cargoGroups = [];
    {
        _unit = _x select 0;
        if !(_unit in (units _group)) then {
            _cargoGroups pushBackUnique (group (_x select 0));
        };
    } forEach _cargo;

    {
        if !(_x getVariable ["pl_show_info", false]) then {
            [_x] call pl_show_group_icon;
        };
        _x leaveVehicle _vic;
    } forEach _cargoGroups;

    if ((driver _vic) in (units _group)) then {
        pl_left_vehicles pushBack [_vic, _group];
        _group setVariable ["pl_group_left_vehicle", _vic];
    };
    _group leaveVehicle _vic;
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
};

pl_spawn_leave_vehicle = {
    {
        [_x] spawn pl_leave_vehicle;
    } forEach hcSelected player;  
};

pl_follow_array_other_setup = [];
pl_follow_array_other = [];

pl_attach_inf = {
    private ["_group", "_vic", "_vicGroup", "_attachForm", "_leader"];

    _group = (hcSelected player) select 0;

    if (vehicle (leader _group) != leader _group) exitWith {"Infantry Only Task!"};

    pl_attach_form = false;
  
    if (visibleMap) then {
        pl_follow_array_other_setup = pl_follow_array_other_setup + [_group];
        pl_show_vehicles_pos = getPos (leader _group);
        pl_show_vehicles = true;

        _message = "Select Vehicle <br /><br />
        <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>LINE Formation</t> <br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>FILE Formation</t> <br />
        <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>DIAMOND Formation</t> <br />";
        hint parseText _message;

        onMapSingleClick {
            pl_mapClicked = true;
            _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            pl_vics = nearestObjects [_cords, ["Car", "Truck", "Tank"], 10, true];
            if (_shift) then {pl_attach_form = "File"};
            if (_alt) then {pl_attach_form = "Diamond"};
            hintSilent "";
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {sleep 0.1};
        pl_show_vehicles = false;
        pl_mapClicked = false;
        pl_follow_array_other_setup = pl_follow_array_other_setup - [_group];
    }
    else
    {
        pl_vics = [cursorTarget];
    };

    _vic = pl_vics#0;
    _vicGroup = group (driver _vic);
    _attachForm = pl_attach_form;


    [_group] call pl_reset;
    [_vicGroup] call pl_reset;
    sleep 0.2;

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\map\markers\nato\n_mech_inf.paa"];
    // _group setVariable ["specialIcon", "\A3\3den\data\Attributes\Formation\line_ca.paa"];

    pl_follow_array_other = pl_follow_array_other + [[_vicGroup, _group]];
    _vic setVariable ["pl_speed_limit", "CON"];

    _attachForm = pl_attach_form;
    switch (_attachForm) do { 
        case "File" : {_group setFormation "FILE"}; 
        case "Diamond" : {_group setFormation "DIAMOND"}; 
        default {_group setFormation "LINE"}; 
    };

    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);

    _leader = leader _group;
    _leader limitSpeed 14;
    _leaderPos = [5*(sin ((getDir _vic) - 180)), 5*(cos ((getDir _vic) - 180)), 0] vectorAdd getPos _vic;
    _leader doMove _leaderPos;
    {
        _x doFollow _leader;
    } forEach ((units _group) - [_leader]);
    _group setFormDir (getDir _vic);

    while {_group getVariable ["onTask", true] and (alive _vic)} do {

        if (speed _vic > 0) then {
            _group setBehaviour "AWARE";
            _leader = leader _group;
            _leader limitSpeed 14;
            _leaderPos = [5*(sin ((getDir _vic) - 180)), 5*(cos ((getDir _vic) - 180)), 0] vectorAdd getPos _vic;
            _leader doMove _leaderPos;
            {
                _x doFollow _leader;
            } forEach ((units _group) - [_leader]);
            _group setFormDir (getDir _vic);
        };

        if ((_leader distance2D _vic) > 22) then {_vic forceSpeed 0} else {_vic forceSpeed -1; _vic limitSpeed 15};
        _vic setVariable ["pl_speed_limit", "CON"];

        // sleep 2;
        _time = time + 2;
        waitUntil {time >= _time or !(_group getVariable ["onTask", true]) or !(alive _vic)};
    };

    pl_follow_array_other = pl_follow_array_other - [[_vicGroup, _group]];
    if !(alive _vic) exitWith {[_group] call pl_reset};
    _vic forceSpeed -1;
    _vic limitSpeed 50;
    _vic setVariable ["pl_speed_limit", "50"];
};

// pl_viv_trans_set_up = {
//     params ["_group"];
//     _vic = vehicle (leader _group);
//     _targetVic = isVehicleCargo _vic;
//     _group setVariable ["pl_show_info", false];
//     (group (driver _targetVic)) setVariable ["setSpecial", true];
//     (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
//     {
//         player hcRemoveGroup (group (_x select 0));
//     } forEach fullCrew[_vic, "cargo", false];
// };

// pl_inf_trans_set_up = {
//     params ["_group"];
//     _targetVic = vehicle (leader _group);
//     (group (driver _targetVic)) setVariable ["setSpecial", true];
//     (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
//     _group setVariable ["onTask", false];
//     _group setVariable ["setSpecial", false];
//     _group setVariable ["pl_show_info", false];
// };



// sleep 3;
// {
//     _leader = leader _x;
//     private _hcs = allMissionObjects "HighCommandSubordinate" select 0;
//     if (isNil{_hcs}) exitWith {};
//     if ((_hcs in (synchronizedObjects _leader)) and (vehicle _leader != _leader)) then {
//         if (((assignedVehicleRole _leader) select 0) isEqualTo "cargo") then {
//             [_x] call pl_inf_trans_set_up;
//             [_x, true] spawn pl_contact_report;
//         };
//         if !(isNull (isVehicleCargo (vehicle _leader))) then {
//             [_x] call pl_viv_trans_set_up;
//             [_x, true] spawn pl_contact_report;

//         };

//     };
// } forEach (allGroups select {side _x isEqualTo playerSide});

player addEventHandler ["GetInMan", {
    params ["_unit", "_role", "_vehicle", "_turret"];
    private ["_group"];
    _group = group player;
    _vicGroup = group (driver (vehicle player));
    if (_vicGroup != (group player)) then {
        player setVariable ["pl_player_vicGroup", _vicGroup];
        _vicGroup setVariable ["setSpecial", true];
        _vicGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
        // _group setVariable ["pl_show_info", false];
        [_group] call pl_hide_group_icon;
        // player hcRemoveGroup _group;
    };
}];

player addEventHandler ["GetOutMan", {
    params ["_unit", "_role", "_vehicle", "_turret"];
    private ["_group"];
    _group = group player;
    _vicGroup = player getVariable ["pl_player_vicGroup", (group player)];
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
    // _group setVariable ["pl_show_info", true];
    if !(_group getVariable ["pl_show_info", false]) then {
        [_group, "hq"] call pl_show_group_icon;
    };
    // player hcSetGroup [_group];

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






