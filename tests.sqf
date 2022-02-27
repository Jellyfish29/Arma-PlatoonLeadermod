
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


/*        [_group] call pl_reset;
        sleep 0.5;
        [_group] call pl_reset;
        sleep 0.5;*/
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
                if (pl_enable_map_radio) then {[group _commander, "...RTB", 25] call pl_map_radio_callout};
            };

            _convoyArray = [];
            _inLandConvoy = false;

            _wp = (group _commander) addWaypoint [_cords, 0];
            _wp setWaypointType "TR UNLOAD";
            {_x disableAI "PATH"} forEach (units _group);
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
                    _t = time + 2;
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

            {_x enableAI "PATH"} forEach (units _group);
            if (_vic isKindOf "Air") then {
                _vic flyInHeight 60;
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
                        // _vic forceFollowRoad true;
                        _vic setConvoySeparation 1;

                        while {
                        (alive (vehicle (leader _convoyLeader))) and
                        // !(unitReady (driver (vehicle (leader _convoyLeader)))) and
                        ((leader _convoyLeader) distance2D waypointPosition[_convoyLeader, currentWaypoint _convoyLeader] > 60) and
                        (_convoyLeader getVariable ["onTask", true])
                        } do {
                            private _convoyLeaderSpeed = (vehicle (leader _convoyLeader)) getVariable "pl_speed_limit";
                            switch (_convoyLeaderSpeed) do { 
                                case "CON" : {_convoyLeaderSpeed = 35}; 
                                case "MAX" : {_convoyLeaderSpeed = 60}; 
                                default {_convoyLeaderSpeed = parseNumber _convoyLeaderSpeed}; 
                            };
                            private _convoyLeaderVic = vehicle (leader _convoyLeader);
                            if ((group _commander) == _convoyLeader) then {
                                _distance = _vic distance2d vehicle (leader (_convoyArray select 1));
                                _vic forceSpeed -1;
                                _vic limitSpeed _convoyLeaderSpeed;
                                if (_distance < 60) then {
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
                                        [_vic, _group, _cords] call pl_vehicle_convoy_unstuck;
                                    };
                                };
                            }
                            else
                            {
                                _leaderBehavior = behaviour (leader _convoyLeader);
                                _group setBehaviour _leaderBehavior;
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
                                if (_distance < 25) then {
                                    _vic forceSpeed 0;
                                    _vic limitSpeed 0;
                                };
                                if ((speed (vehicle (leader (_convoyArray select (_convoyPosition - 1))))) < 2) then {
                                    _vic forceSpeed 0;
                                    _vic limitSpeed 0;
                                };
                                _distanceBack = 0;
                                if (_convoyPosition < ((count (_convoyArray)) - 1)) then {
                                    _distanceBack = _vic distance2d vehicle (leader (_convoyArray select _convoyPosition + 1));
                                    if (_distanceBack < 40) then {
                                        _convoyLeaderVic limitSpeed _convoyLeaderSpeed;
                                    };
                                    if (_distanceBack > 60) then {
                                        _vic limitSpeed ((_convoyLeaderSpeed - (_convoyLeaderSpeed / 2)) - 10);
                                        _convoyLeaderVic limitSpeed (_convoyLeaderSpeed / 2);
                                    };
                                    if (_distanceBack > 100) then {
                                        _vic forceSpeed 0;
                                        _convoyLeaderVic limitSpeed ((_convoyLeaderSpeed / 2) - 8);
                                    };
                                };
                                if ((speed _vic) == 0) then {
                                    _timeout = time + 7;
                                    waitUntil {(speed _vic) > 0 or time >= _timeout};
                                    if ((speed _vic) == 0) then {
                                        [_vic, _group, _cords] call pl_vehicle_convoy_unstuck; 
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
                        // _cCargo = fullCrew [_cvic, "cargo", false];
                        // if ((count _cCargo) > 0) then {
                        //     _convoyLeader setVariable ["setSpecial", true];
                        //     _convoyLeader setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
                        // };
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
                        doStop _vic;

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
                (group _commander) setVariable ["pl_has_cargo", false];
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
                if (pl_enable_map_radio) then {[group _commander, "...RTB", 25] call pl_map_radio_callout};
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
            // {
            //     {
            //         doStop _x;
            //         _x doFollow leader _x;
            //     } forEach (units _x);
            // } forEach _cargoGroups;
            // if (pl_enable_beep_sound) then {playSound "beep"};
            // _commander sideChat format ["%1 finished unloading, over", groupId _group];
            _vic setVariable ["pl_on_transport", nil];
            // (group _commander) setVariable ["setSpecial", false];
            (group _commander) setVariable ["pl_has_cargo", false];
            _vic doFollow _vic;
        };
    };
};



pl_vehicle_convoy_unstuck = {
    params ["_vic", "_group", "_cords"];
    _vic setVehiclePosition [getPosVisual _vic, [], 0, "CAN_COLLIDE"];
    {
        _x setDamage 1;
    } forEach (nearestTerrainObjects [getPos _vic, ["TREE", "SMALL TREE", "BUSH"], 8, false, true]);
    _leader = leader _group;
    (units _group) joinSilent _group;
    _group selectLeader _leader;

    if ((currentWaypoint _group) >= count (waypoints _group)) then {
        _group addWaypoint [_cords, 2];
    } else {
        [_group, (currentWaypoint _group)] setWaypointPosition [_cords, -1];
        _vic doMove _cords;
    };

    _road = [getPos _vic, 10] call BIS_fnc_nearestRoad;
    if !(isNull _road) then {
        _info = getRoadInfo _road;    
        _endings = [_info#6, _info#7];
        _endings = [_endings, [], {_x distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy;
        _vPos = _endings#0;
        _roadDir = (_endings#1) getDir (_endings#0);
        _vic setDir _roadDir;
    };
};
