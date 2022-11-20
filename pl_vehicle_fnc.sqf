
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
pl_convoy_speed = 35;
pl_convoy_max_distance = 3500;


pl_getIn_vehicle = {
    params [["_group", hcSelected player select 0], ["_taskPlanWp", []], ["_vic", objNull]];
    private ["_vics", "_targetVic", "_groupLen", "_group", "_cords"];

    // _group = hcSelected player select 0;
    _groupLen = count (units _group);

    if (isNull _vic) then {
        if (visibleMap or !(isNull findDisplay 2000)) then {
            if (_taskPlanWp isEqualTo []) then {
                pl_show_vehicles_pos = getPos (leader _group);
            } else {
                pl_show_vehicles_pos = waypointPosition _taskPlanWp;
            };
            pl_show_vehicles = true;
            hint "Select TRANSPORT on Map";
            onMapSingleClick {
                pl_mapClicked = true;
                pl_vic_pos = _pos;
                pl_vics = nearestObjects [_pos, ["Car", "Truck", "Tank", "Air"], 50, true];
                hintSilent "";
                onMapSingleClick "";
            };
            while {!pl_mapClicked} do {sleep 0.1};
            pl_show_vehicles = false;
            pl_mapClicked = false;
            _cords = pl_vic_pos;
        }
        else
        {
            pl_vics = [cursorTarget];
            _cords = getPos cursorTarget;
        };
    } else {
        _cords = getPos _vic;
        pl_vics = [_vic];
    };

    pl_vics = [pl_vics, [], {_x distance2D _cords}, "DESCEND"] call BIS_fnc_sortBy;
    {
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


        [group (driver _targetVic)] call pl_hold;

        if (count _taskPlanWp != 0) then {

            private _wPos = waypointPosition _taskPlanWp;

            waitUntil {(_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};

            // deleteWaypoint [_group, _taskPlanWp#1];

            if !(_group getVariable ["pl_task_planed", false]) then {
                pl_cancel_strike = true;
                [group (driver _targetVic)] call pl_execute;
            }; // deleteMarker
            _group setVariable ["pl_task_planed", false];
            _group setVariable ["pl_execute_plan", nil];
        };

        if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

        _targetVic lockCargo false;

        // Request Airlift
        if ((_targetVic distance2D (leader _group)) > 200 and _targetVic isKindOf "Air") then {
            {
                _x disableAI "AUTOCOMBAT";
                _x disableAI "TARGET";
                _x disableAI "AUTOTARGET";
            } forEach (units (group (driver _targetVic)));
            _landCords = (getPos (leader _group)) findEmptyPosition [0, 100, "Land_HelipadEmpty_F"];
            if (_landCords isEqualTo []) then {_landCords = getPos (leader _group)};
            _landigPad = "Land_HelipadEmpty_F" createVehicle _landCords;
            _landigPad setDir (_targetVic getDir _landCords);
            group (driver _targetVic) addWaypoint [_landCords, 0];
            _targetVic flyInHeight 60;
            (group (driver _targetVic)) setVariable ["setSpecial", true];
            (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\takeoff_ca.paa"];
            if (pl_enable_beep_sound) then {playSound "beep"};
            driver _targetVic sideChat format ["%1: Moving to LZ", groupId (group (driver _targetVic))];
            if (pl_enable_map_radio) then {[group (driver _targetVic), "...Moving to LZ", 25] call pl_map_radio_callout};
            sleep 20;
            waitUntil {sleep 0.1; unitReady _targetVic or !alive _targetVic};
            if (pl_enable_beep_sound) then {playSound "beep"};
            driver _targetVic sideChat format ["%1: Beginning landing", groupId (group (driver _targetVic))];
            if (pl_enable_map_radio) then {[group (driver _targetVic), "...Beginning Landing", 25] call pl_map_radio_callout};
            _targetVic land "GET IN";
            // _targetVic land "LAND";
            sleep 10;
            waitUntil {sleep 0.1; (isTouchingGround _targetVic) or !alive _targetVic};
            sleep 1;
            deleteVehicle _landigPad;
        };


    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

        if (_group getVariable ["pl_healing_active", false]) then {_group setVariable ["pl_healing_active", false]};

        // Vehicle Transport
        if ((vehicle (leader _group)) != leader _group) then {
            _vic = vehicle (leader _group);
            if ((_targetVic canVehicleCargo _vic) select 0) then {
                _targetVic animateDoor ["Door_1_source", 1];
                _vicName = getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName");
                if (pl_enable_beep_sound) then {playSound "beep"};
                if (pl_enable_chat_radio) then {leader _group sideChat format ["%1: Getting in %2", (groupId _group), _vicName]};
                if (pl_enable_map_radio) then {[_group, format ["...Getting in %1", _vicName], 15] call pl_map_radio_callout};
                // _group setVariable ["pl_show_info", false];

                [_group] call pl_hide_group_icon;
                // (group (driver _targetVic)) setVariable ["setSpecial", true];
                // (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
                
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
            if (pl_enable_chat_radio) then {leader _group sideChat format ["%1: Getting in %2", (groupId _group), _vicName]};
            if (pl_enable_map_radio) then {[_group, format ["...Getting in %1", _vicName], 15] call pl_map_radio_callout};


            // (group (driver _targetVic)) setVariable ["setSpecial", true];
            // (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
            // _group setVariable ["setSpecial", true];
            // _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
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
            [group (driver _targetVic)] call pl_execute;
            if !(_group getVariable "onTask") then {
                {
                    unassignVehicle _x;
                    doGetOut _x;
                } forEach (units _group);
                [units _group] allowGetIn false;
                // (group (driver _targetVic)) setVariable ["setSpecial", false];

            }
            else
            {
                _group setVariable ["onTask", false];
                (group (driver _targetVic)) setVariable ["pl_has_cargo", true];
                _group setVariable ["pl_disembark_finished", false];
                [_group] call pl_hide_group_icon;
                [_group, _targetVic] spawn pl_rearm_in_transport;
            };
        };
    }
    else
    {
        // if (pl_enable_beep_sound) then {playSound "beep"};
        hint "No avaiable Transport";
    };
};

pl_eject_cargo = {
    params ["_vicGroup", "_vehicle"];

    private _cargo = (crew _vehicle) - (units _vicGroup);
    private _cargoGroups = [];
    {
        _cargoGroups pushBack (group _x);
    } forEach _cargo;

    _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

    {
        _cGroup = _x;
        // moveOut (leader _cGroup);
        if !(_cGroup getVariable ["pl_show_info", false]) then {
            [_cGroup, "inf", false] call pl_show_group_icon;
        };
        _cGroup leaveVehicle _vic;
        {
            _cargoPers pushBack _x;
            unassignVehicle _x;
            doGetOut _x;
            [_x] allowGetIn false;
            // doStop _x;
            if (_x != (leader _cGroup)) then {
                _x doFollow (leader _cGroup);
            } else {
                _x doMove ((getpos _vic) getPos [10, (getdir _vic) - 180]);
                _x setDestination [(getpos _vic) getPos [10, (getdir _vic) - 180], "LEADER DIRECT", true];
            };
            // _x disableAI "AUTOCOMBAT";
            if ((lifeState _x) isEqualTo "INCAPACITATED") then {
                [_x, _vehicle] call pl_crew_eject;
            };
        } forEach (units _cGroup);
        // _cGroup setBehaviourStrong "AWARE";
    } forEach _cargoGroups;  
};

pl_dismount_cargo = {
    params [["_group", (hcSelected player) select 0]];

    // if (pl_enable_beep_sound) then {playSound "beep"};
    if (_group getVariable ["pl_is_dismounted", false]) exitWith {_group setVariable ["pl_is_dismounted", nil]};

    _group setVariable ["pl_is_dismounted", true];

    _vic = vehicle (leader _group);
    _driver = driver _vic;
    _vicGroup = group _driver;
    doStop _vic;
    _vic limitSpeed 12;
    _cargo = fullCrew [_vic, "cargo", false];
    if (_cargo isEqualTo []) exitWith {hint "No Cargo to Unload"};
    private _dismounts = [];
    {
        _unit = _x select 0;
        if (_unit in (units _vicGroup)) then {
            _unit = _x select 0;
            doGetOut _unit;
            [_unit] allowGetIn false;
            _dismounts pushback _unit;
        };
    } forEach _cargo;

    // _group setFormation "STAG COLUMN";
    _vic lockCargo true;

    waitUntil {sleep 0.5; !(_group getVariable ["pl_is_dismounted", false])};
    _vic limitSpeed 50;

    _group setVariable ["pl_is_dismounted", nil];
    _vic lockCargo false;
    _vic limitSpeed 50;

    {
        _x assignAsCargo _vic;
        [_x] allowGetIn true;
        [_x] orderGetIn true;
    } forEach _dismounts;
};

// [] spawn pl_dismount_cargo;

pl_unload_at_position_planed = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_wpPos"];

    if (vehicle (leader _group) == leader _group) exitWith {hint "Vehicle Only Task!"};

    _vic = vehicle (leader _group);
    _driver = driver _vic;
    _vicGroup = group _driver;
    _crew = crew _vic;
    private _cargo = _crew - (units _vicGroup);
    // _cargo = fullCrew [_vic, "cargo", false];

    // if (count _cargo == 0) exitWith {hint "No Cargo to Unload"}
    private _attached = _vicGroup getVariable ["pl_attached_infGrp", grpNull];
    if !(isNull _attached) exitWith {[_vicGroup, _attached, _taskPlanWp] spawn pl_detach_inf_planed};

    private _cargoGroups = [];
    {
        _unit = _x;
        if (!(_unit in (units _vicGroup)) and !(_unit in (units (group player)))) then {
            _cargoGroups pushBack (group _unit);
        };
    } forEach _cargo;

    _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

    if (_cargoGroups isEqualTo []) exitWith {[_vicGroup] call pl_dismount_cargo};

    if (count _taskPlanWp != 0) then {

        private _cargoGroup = _cargoGroups#0;
        _wpPos = waypointPosition _taskPlanWp;
        _wpPos = +_wpPos;

        pl_draw_unload_inf_task_plan_icon_array pushBack [_cargoGroup, _wpPos];

        waitUntil {(_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};

        // deleteWaypoint [_group, _taskPlanWp#1];

        if !(_group getVariable ["pl_task_planed", false]) then {
            pl_cancel_strike = true;
            pl_draw_unload_inf_task_plan_icon_array = pl_draw_unload_inf_task_plan_icon_array - [[_cargoGroup, _wpPos]];
        }; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];

    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    doStop _vic;

    private _cargoPers = [];
    {
        _cGroup = _x;
        // moveOut (leader _cGroup);
        if !(_cGroup getVariable ["pl_show_info", false]) then {
            [_cGroup, "inf", false] call pl_show_group_icon;
        };
        _cGroup leaveVehicle _vic;
        {
            _cargoPers pushBack _x;
            unassignVehicle _x;
            doGetOut _x;
            [_x] allowGetIn false;
            // doStop _x;
            if (_x != (leader _cGroup)) then {
                _x doFollow (leader _cGroup);
            } else {
                _x doMove ((getpos _vic) getPos [10, (getdir _vic) - 180]);
                _x setDestination [(getpos _vic) getPos [10, (getdir _vic) - 180], "LEADER DIRECT", true];
            };
            _x disableAI "AUTOCOMBAT";

            if ((lifeState _x) isEqualTo "INCAPACITATED") then {
                [_x, _vic] call pl_crew_eject;
            };
        } forEach (units _cGroup);
        _cGroup setBehaviourStrong "AWARE";

        

    } forEach _cargoGroups;

    [_group, "confirm", 1] call pl_voice_radio_answer;

    waitUntil {sleep 0.5; (({vehicle _x != _x} count _cargoPers) == 0) or (!alive _vic)};

    {
        player hcSetGroup [_x];
    } forEach _cargoGroups;

    // if (pl_enable_beep_sound) then {playSound "beep"};

    _vic setVariable ["pl_on_transport", nil];
    _vicGroup setVariable ["pl_has_cargo", false];
    sleep 2;
    _time = time + 30;
    waitUntil {sleep 0.5; ({unitReady _x} count _cargoPers) == (count _cargoPers) or time >= _time};
    sleep 2;
    {
        _x setVariable ["pl_disembark_finished", true];
        {
            _x enableAI "AUTOCOMBAT";
        } forEach (units _x);
    } forEach _cargoGroups;

    [_cargoGroups] spawn {
        params ["_cargoGroups"],
        sleep 5;
        {
            _x setVariable ["pl_disembark_finished", nil];
            
        } forEach _cargoGroups;
    };
    // waitUntil {sleep 0.5; ({unitReady _x} count _cargoPers) == (count _cargoPers)};
    [_group] spawn pl_reset;
};

pl_unload_at_combat = {
    params ["_group"];

    if (vehicle (leader _group) == leader _group) exitWith {};

    _vic = vehicle (leader _group);
    _driver = driver _vic;
    _vicGroup = group _driver;
    _crew = crew _vic;
    private _cargo = _crew - (units _vicGroup);
    
    private _attached = _vicGroup getVariable ["pl_attached_infGrp", grpNull];
    if !(isNull _attached) exitWith {[_vicGroup, _attached, _taskPlanWp] spawn pl_detach_inf_planed};

    private _cargoGroups = [];
    {
        _unit = _x;
        if (!(_unit in (units _vicGroup)) and !(_unit in (units (group player)))) then {
            _cargoGroups pushBack (group _unit);
        };
    } forEach _cargo;

    _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

    if (_cargoGroups isEqualTo []) exitWith {};

    doStop _vic;

    private _cargoPers = [];
    {
        _cGroup = _x;
        // moveOut (leader _cGroup);
        if !(_cGroup getVariable ["pl_show_info", false]) then {
            [_cGroup, "inf", false] call pl_show_group_icon;
        };
        _cGroup leaveVehicle _vic;
        {
            _cargoPers pushBack _x;
            unassignVehicle _x;
            doGetOut _x;
            [_x] allowGetIn false;
            // doStop _x;
            if (_x != (leader _cGroup)) then {
                _x doFollow (leader _cGroup);
            } else {
                _x doMove ((getpos _vic) getPos [10, (getdir _vic) - 180]);
                _x setDestination [(getpos _vic) getPos [10, (getdir _vic) - 180], "LEADER DIRECT", true];
            };
            _x disableAI "AUTOCOMBAT";

            if ((lifeState _x) isEqualTo "INCAPACITATED") then {
                [_x, _vic] call pl_crew_eject;
            };
        } forEach (units _cGroup);
        _cGroup setBehaviourStrong "AWARE";

    } forEach _cargoGroups;

    waitUntil {sleep 0.5; (({vehicle _x != _x} count _cargoPers) == 0) or (!alive _vic)};

    {
        player hcSetGroup [_x];
    } forEach _cargoGroups;

    _vic setVariable ["pl_on_transport", nil];
    _vicGroup setVariable ["pl_has_cargo", false];
    sleep 2;
    _time = time + 30;
    waitUntil {sleep 0.5; ({unitReady _x} count _cargoPers) == (count _cargoPers) or time >= _time};
    sleep 2;

    {
        [_x, [], getPos _vic, getDir _vic, false, false, 35] spawn pl_defend_position;
    } forEach _cargoGroups;

    [_group] spawn pl_reset;
};

pl_convoy = {
    private ["_mPos"];

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader (_groups#0)] call pl_open_tac_forced;
        };
    };

    private _allgroups = hcSelected player;
    // private _groups = +_allGroups select {((assignedVehicleRole (leader _x))#0) != "cargo"};
    private _groups = +_allGroups;

    private _markerRPName = format ["convoyrp%1%2",random 2];
    createMarker [_markerRPName, [0,0,0]];
    _markerRPName setMarkerPos [0,0,0];
    _markerRPName setMarkerType "marker_rp";
    

    private _rangelimiterCenter = getPos (leader (_groups#0));
    private _rangelimiter = pl_convoy_max_distance;
    private _markerBorderName = str (random 2);
    createMarker [_markerBorderName, _rangelimiterCenter];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorOrange";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    hintSilent "Select DESTINATION on MAP";
    onMapSingleClick {
        pl_mapClicked = true;
        pl_lz_cords = _pos;
        pl_lz_marker_cords = _pos;
        // if (_shift) then {pl_cancel_strike = true};
        hintSilent "";
        onMapSingleClick "";
    };
    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };

        _road = [_mPos, 50] call BIS_fnc_nearestRoad;
        if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
            if (!(isNull _road) and (getMarkerPos _markerBorderName) distance2D _road < _rangelimiter) then {
                _markerRPName setMarkerPos _road;
                _markerRPName setMarkerColor "colorGreen";
            } else {
                _markerRPName setMarkerPos _mPos;
                _markerRPName setMarkerColor "ColorRed";
            };
        };
    };

    sleep 0.1;
    pl_mapClicked = false;

    deleteMarker _markerBorderName;
    if (getMarkerColor _markerRPName == "colorRED") exitWith {
        hint "Select Valid Destionation Road";
        deleteMarker _markerRPName;
    };

    _markerRPName setMarkerColor pl_side_color;
    private _cords = getMarkerPos _markerRPName;
    private _r2 = [_cords, 100,[]] call BIS_fnc_nearestRoad;

    {
        // [_x] spawn {
        //     (_this#0) spawn pl_reset;
        //     sleep 0.5;
        //     (_this#0) spawn pl_reset;
        // };
        _r1 = [getPos (vehicle (leader _x)) , 50,[]] call BIS_fnc_nearestRoad;
        if (isNull _r1 or (vehicle (leader _x)) == (leader _x)) then {
            _groups deleteAt (_groups find _x)
        } else {
            _path = [_r1, _r2] call pl_convoy_parth_find;
            _x setVariable ["pl_convoy_path", _path];
        };
    } forEach _groups; 

    _groups = ([_groups, [], {count (_x getVariable "pl_convoy_path")}, "ASCEND"] call BIS_fnc_sortBy);

    // sleep 1;
    _convoyLeaderGroup = _groups#0;
    _convoyLeader = vehicle (leader _convoyLeaderGroup);
    _groups = ([_groups, [], {_convoyLeader distance2d (leader _x)}, "ASCEND"] call BIS_fnc_sortBy);

    if ((_convoyLeaderGroup getVariable ["pl_convoy_path", []]) isEqualTo []) exitWith {
        deleteMarker _markerName;
        if (pl_enable_map_radio) then {[_convoyLeaderGroup, "... Destination Unreachable!", 25] call pl_map_radio_callout};
    };

    private _convoy = +_groups;
    reverse _convoy;
    pl_draw_convoy_array pushBack _convoy;
    [_convoyLeaderGroup, "confirm", 1] call pl_voice_radio_answer;
    _convoyLeaderGroup setVariable ["setSpecial", true];
    _convoyLeaderGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa"];
    if (pl_enable_map_radio) then {[_convoyLeaderGroup, "... Convoy is OSCAR MIKE!", 25] call pl_map_radio_callout};
    private _drawPath = (_convoyLeaderGroup getVariable "pl_convoy_path") apply {getpOs _x};
    pl_draw_convoy_path_array pushback _drawPath;


    {
        if !(_x == _convoyLeaderGroup) then {
            player hcRemoveGroup _x;
        };
        _x setVariable ["pl_draw_convoy", true];
    } forEach _groups;

    private _bridges = [];
    private _destroyedBridges = [];

    {
        _info = getRoadInfo _x;
        if (_info#8) then {
            if ((getDammage _x) < 1) then {
                _bridges pushBackUnique _x;
            } else {
                _destroyedBridges pushBackUnique _x;
            };
        };
    } forEach (_convoyLeaderGroup getVariable "pl_convoy_path");

    // if !(_destroyedBridges isEqualTo []) exitWith {};

    private _ppMarkers = [];
    private _passigPoints = [[0,0,0]];
    _noPPn = 0;
    for "_p" from  0 to count (_convoyLeaderGroup getVariable "pl_convoy_path") - 1 do {
        private _r = (_convoyLeaderGroup getVariable "pl_convoy_path")#_p;

        private _nearBridge = false;
        if !(_bridges isEqualTo []) then {
            _nearBridge = {
                if ((_x distance2D _r) < 50) exitWith {true};
                false
            } forEach _bridges;
        };

        if !(_nearBridge) then {
            if (count (roadsConnectedTo _r) > 2) then {
                _valid = {
                    if (_x distance2D _r < 50) exitWith {false};
                    true
                } forEach _passigPoints;
                if (_valid) then {
                    _passigPoints pushBackUnique (getPosATL _r);
                    _noPPn = 0;

                    // _ppM = createMarker [str (random 1), getPosATL _r];
                    // _ppM setMarkerType "marker_pp";
                    // _ppM setMarkerColor pl_side_color;
                    // _ppM setMarkerSize [0.7, 0.7];
                    // _ppMarkers pushback _ppM;
                };
            } else {
                if (_p > 0) then {
                    if (((getRoadInfo _r)#0) != (getRoadInfo ((_convoyLeaderGroup getVariable "pl_convoy_path")#(_p - 1)))#0) then {
                        _valid = {
                            if (_x distance2D _r < 50) exitWith {false};
                            true
                        } forEach _passigPoints;
                        if (_valid) then {
                            _passigPoints pushBackUnique (getPosATL _r);
                            _noPPn = 0;

                            // _ppM = createMarker [str (random 1), getPosATL _r];
                            // _ppM setMarkerType "marker_pp";
                            // _ppM setMarkerColor pl_side_color;
                            // _ppM setMarkerSize [0.7, 0.7];
                            // _ppMarkers pushback _ppM;
                        };
                    } else {
                        if (_p > 1 and _p < (count (_convoyLeaderGroup getVariable "pl_convoy_path") - 2)) then {
                            _dir1 = ((_convoyLeaderGroup getVariable "pl_convoy_path")#(_p - 1)) getDir _r;
                            _dir2 = _r getDir ((_convoyLeaderGroup getVariable "pl_convoy_path")#(_p + 1));
                            _dirs = [_dir1, _dir2];
                            // _test = [(_convoyLeaderGroup getVariable "pl_convoy_path")#(_p - 2), _r, (_convoyLeaderGroup getVariable "pl_convoy_path")#(_p + 2)];
                            // _test = [_p - 1, _p, _p + 1];
                            // player sideChat str _test;
                            _dirs sort false;
                            if ((_dirs#0) - (_dirs#1) > 50) then {
                                _valid = {
                                    if (_x distance2D _r < 80) exitWith {false};
                                    true
                                } forEach _passigPoints;
                                if (_valid) then {
                                    _passigPoints pushBackUnique (getPosATL _r);
                                    _noPPn = 0;

                                    // _ppM = createMarker [str (random 1), getPosATL _r];
                                    // _ppM setMarkerType "marker_pp";
                                    // _ppM setMarkerColor pl_side_color;
                                    // _ppM setMarkerSize [0.7, 0.7];
                                    // _ppMarkers pushback _ppM;
                                };
                            } else {
                                _noPPn = _noPPn + 1;
                                if (_noPPn > 20) then {
                                    _noPPn = 0;
                                    _passigPoints pushBackUnique (getPosATL _r);

                                    // _ppM = createMarker [str (random 1), getPosATL _r];
                                    // _ppM setMarkerType "mil_marker";
                                    // _ppM setMarkerColor pl_side_color;
                                    // _ppM setMarkerSize [0.7, 0.7];
                                    // _ppMarkers pushback _ppM;
                                };
                            };
                        };
                    };
                };
            };
        };
    };
    _passigPoints deleteAt 0;
    _passigPoints pushback getposATL _r2;

    for "_i" from 0 to (count _groups) - 1 do {
        // doStop (vehicle (leader _x));

        private _group = _groups#_i;
        private _vic = vehicle (leader _group);
        _vic limitSpeed pl_convoy_speed;
        _vic setVariable ["pl_speed_limit", "CON"];
        _group setVariable ["onTask", true];
        
        // _vic setConvoySeparation 5;
        // _vic forceFollowRoad true;
        _group setVariable ["pl_pp_idx", 0];

        {
            _x disableAI "AUTOCOMBAT";
        } forEach (units _group);
        _group setBehaviourStrong "SAFE";
        [getPos _vic, 3] call pl_clear_obstacles;
        _vic doMove (_passigPoints#0);
        _vic setDestination [(_passigPoints#0),"VEHICLE PLANNED" , true];

        // _vic setDriveOnPath (_group getVariable "pl_convoy_path");

        if (_vic != _convoyLeader) then {

            // player hcRemoveGroup _group;

            [_group ,_vic, _convoyLeader, _groups, _i, _convoyLeaderGroup, _r2, _passigPoints] spawn {
                params ["_group" , "_vic", "_convoyLeader", "_groups", "_i", "_convoyLeaderGroup", "_r2", "_passigPoints"];
                private ["_ppidx", "_time"];

                // _vic setDriveOnPath (_group getVariable "pl_convoy_path");

                _ppidx = 0;
                private _forward = vehicle (leader (_groups#(_i - 1)));
                private _startReset = false;
                while {(_convoyLeaderGroup getVariable ["onTask", true]) and ((_groups#(_i - 1)) getVariable ["onTask", true])} do {

                    if (!alive _vic or ({alive _x and (lifeState _x) != "INCAPACITATED"} count (units _group)) <= 0) exitWith {};
                    if (!(alive _convoyLeader) or !(alive _forward)) exitWith {};

                    _ppidx = _group getVariable "pl_pp_idx";
                    if (_vic distance2D (_passigPoints#_ppidx) < 35) then {
                        _ppidx = _ppidx + 1;
                        _group setVariable ["pl_pp_idx", _ppidx];
                        _vic doMove (_passigPoints#_ppidx);
                        _vic setDestination [(_passigPoints#_ppidx),"VEHICLE PLANNED" , true];
                    };

                    private _convoyLeaderSpeedStr = vehicle (leader (_convoyLeaderGroup)) getVariable ["pl_speed_limit", "50"];
                    private _convoyLeaderSpeed = pl_convoy_speed;
                    switch (_convoyLeaderSpeedStr) do { 
                        case "CON" : {_convoyLeaderSpeed = pl_convoy_speed}; 
                        case "MAX" : {_convoyLeaderSpeed = 60}; 
                        default {_convoyLeaderSpeed = parseNumber _convoyLeaderSpeedStr}; 
                    };
                    if ([getPOs _vic] call pl_is_city or [getPOs _vic] call pl_is_forest) then {
                        if (_convoyLeaderSpeedStr == "CON") then {
                            _convoyLeaderSpeed = pl_convoy_speed / 2 + 5;
                        };
                    };
                    _vic forceSpeed -1;
                    _vic limitSpeed _convoyLeaderSpeed;
                    _distance = _vic distance2D _forward;
                    if (_distance > 60) then {
                        _vic limitSpeed (_convoyLeaderSpeed + 5 + (_distance - 60));
                    };
                    if (_distance < 60) then {
                        _vic limitSpeed _convoyLeaderSpeed;
                    };
                    if (_distance < 40) then {
                        _vic limitSpeed (_convoyLeaderSpeed * 0.5);
                    };
                    if (_distance < 20) then {
                        _vic forceSpeed 0;
                        _vic limitSpeed 0;
                    };
                    if (_distance > 150) then {
                        _vic limitSpeed 1000;
                    };
                    if ((speed _vic) <= 3) then {
                        _time = time + 20;
                        if !(_startReset) then {
                            _time = time + 3;
                            _startReset = true;
                        };
                        waitUntil {sleep 0.5; ((speed _vic > 5 or time > _time) and (speed _forward) >= 5 and (_vic distance2d _forward) >= 50) or !(_group getVariable ["onTask", true]) or !(_convoyLeaderGroup getVariable ["onTask", true])};
                        if ((speed _vic) < 5 and (speed _forward) >= 5 and (_vic distance2d _forward) >= 48 and (_group getVariable ["onTask", true]) and (_convoyLeaderGroup getVariable ["onTask", true])) then {
                            doStop _vic:
                            sleep 0.3;
                            [getPos _vic, 20] call pl_clear_obstacles;
                            _group setBehaviourStrong "SAFE";
                            _group setVariable ["pl_draw_convoy", true];
                            // _vic setVariable ["pl_phasing", true];
                            _pp = (_passigPoints#_ppidx);
                            _r0 = [getpos _vic, 100,[]] call BIS_fnc_nearestRoad;
                            _r1 = ([roadsConnectedTo _r0, [], {_pp distance2d _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                            _vic setVehiclePosition [getPos _r1, [], 0, "NONE"];
                            _vic setDir  (_r0 getDir _r1);
                            sleep 0.1;
                            if (_distance > 300) exitWith {
                                sleep 0.2;
                                [_group] call pl_reset;
                            };
                            _vic limitSpeed pl_convoy_speed;
                            _vic setVariable ["pl_speed_limit", "CON"];
                            _vic doMove _pp;
                            _vic setDestination [_pp,"VEHICLE PLANNED" , true];
                        };
                    };
                    sleep 1;
                };
                player hcsetGroup [_group];
                // if ((_vic distance2D _forward) > 60) then {
                //     _vic doMove getPOs _forward;
                //     _vic setDestination [getPos _forward,"VEHICLE PLANNED" , true];
                //     waitUntil {sleep 0.5; _vic distance2D _forward < 60 or !(_group getVariable ["onTask", false])};
                // };
                [_group] call pl_reset;
                _group setVariable ["pl_draw_convoy", nil];
                _vic limitSpeed 50;
                _vic setVariable ["pl_speed_limit", "50"];
                
            };
        } else {
            [_group ,_vic, _convoyLeader, _groups, _i, _convoyLeaderGroup, _r2, _passigPoints, _ppMarkers] spawn {
                params ["_group" , "_vic", "_convoyLeader", "_groups", "_i", "_convoyLeaderGroup", "_r2", "_passigPoints", "_ppMarkers"];
                private ["_ppidx"];

                private _dest = getPos ((_convoyLeaderGroup getVariable "pl_convoy_path")#((count (_convoyLeaderGroup getVariable "pl_convoy_path")) - 1));

                while {(_convoyLeaderGroup getVariable ["onTask", true]) and (vehicle (leader _convoyLeaderGroup)) distance2D _dest > 40} do {

                    if !(alive _vic) exitWith {};

                    private _convoyLeaderSpeedStr = vehicle (leader (_convoyLeaderGroup)) getVariable ["pl_speed_limit", "50"];
                    private _convoyLeaderSpeed = pl_convoy_speed;
                    switch (_convoyLeaderSpeedStr) do { 
                        case "CON" : {_convoyLeaderSpeed = pl_convoy_speed}; 
                        case "MAX" : {_convoyLeaderSpeed = 60}; 
                        default {_convoyLeaderSpeed = parseNumber _convoyLeaderSpeedStr}; 
                    };
                    if ([getPOs _vic] call pl_is_city or [getPOs _vic] call pl_is_forest) then {
                        if (_convoyLeaderSpeedStr == "CON") then {
                            _convoyLeaderSpeed = pl_convoy_speed / 2 + 5;
                        };
                    };
                    _vic forceSpeed -1;
                    _vic limitSpeed _convoyLeaderSpeed;

                    _ppidx = _group getVariable "pl_pp_idx";
                    if (_vic distance2D (_passigPoints#_ppidx) < 35) then {
                        _ppidx = _ppidx + 1;
                        _convoyLeaderGroup setVariable ["pl_pp_idx", _ppidx];
                        _vic doMove (_passigPoints#_ppidx);
                        _vic setDestination [(_passigPoints#_ppidx),"VEHICLE PLANNED" , true];
                    };

                    if ((speed _vic) <= 3) then {
                        _time = time + 6;
                        waitUntil {sleep 0.5; speed _vic > 5 or time > _time or !(_group getVariable ["onTask", true])};
                        if ((speed _vic) <= 3 and (_group getVariable ["onTask", true])) then {
                            // [_group] call pl_reset;
                            doStop _vic;
                            [getPos _vic, 20] call pl_clear_obstacles;
                            sleep 0.3;
                            _group setBehaviourStrong "SAFE";
                            _group setVariable ["pl_draw_convoy", true];
                            _pp = (_passigPoints#_ppidx);
                            _r0 = [getpos _vic, 100,[]] call BIS_fnc_nearestRoad;
                            _r1 = ([roadsConnectedTo _r0, [], {_pp distance2d _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                            _vic setVehiclePosition [getPos _r1, [], 0, "NONE"];
                            _vic setDir  (_r0 getDir _r1);
                            sleep 0.1;
                            _vic limitSpeed pl_convoy_speed;
                            _vic setVariable ["pl_speed_limit", "CON"];
                            _vic doMove _pp;
                            _vic setDestination [_pp,"VEHICLE PLANNED" , true];

                        }; 
                    };
                    sleep 1;
                };

                [_convoyLeaderGroup] call pl_reset;

                _vic limitSpeed 50;
                _vic setVariable ["pl_speed_limit", "50"];
                _convoyLeaderGroup setVariable ["pl_draw_convoy", nil];
            };
        };
        _time = time + 1.5;
        waituntil {(time >= _time and speed _vic > 13) or !((_convoyLeaderGroup) getVariable ["onTask", true])};
    };

    // sleep 2;
    waituntil {sleep 1; !(_convoyLeaderGroup getVariable ["onTask", true])};
    // if (speed _convoyLeader <= 0) then {if (pl_enable_map_radio) then {[_convoyLeaderGroup, "... Destination unreachable!", 25] call pl_map_radio_callout}};

    pl_draw_convoy_array = pl_draw_convoy_array - [_convoy];
    pl_draw_convoy_path_array = pl_draw_convoy_path_array - [_drawPath];
    deleteMarker _markerRPName;
    {deleteMarker _x} forEach _ppMarkers;
};

pl_line_up_on_road = {
    private ["_mPos"];

    private _allgroups = hcSelected player;
    

    private _markerRPName = format ["convoyrp%1%2",random 2];
    createMarker [_markerRPName, [0,0,0]];
    _markerRPName setMarkerPos [0,0,0];
    _markerRPName setMarkerType "mil_dot";
    _markerRPName setMarkerSize [1.3, 1.3];
    

    private _rangelimiterCenter = getPos (leader (_allgroups#0));
    private _rangelimiter = 300;
    private _markerBorderName = str (random 2);
    createMarker [_markerBorderName, _rangelimiterCenter];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorOrange";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    hintSilent "Select ROAD";
    onMapSingleClick {
        pl_mapClicked = true;
        pl_lz_cords = _pos;
        pl_lz_marker_cords = _pos;
        // if (_shift) then {pl_cancel_strike = true};
        hintSilent "";
        onMapSingleClick "";
    };
    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };

        _road = [_mPos, 50] call BIS_fnc_nearestRoad;
        if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
            if (!(isNull _road) and (getMarkerPos _markerBorderName) distance2D _road < _rangelimiter) then {
                _markerRPName setMarkerPos _road;
                _markerRPName setMarkerColor "colorGreen";
            } else {
                _markerRPName setMarkerPos _mPos;
                _markerRPName setMarkerColor "ColorRed";
            };
        };
    };

    sleep 0.1;
    pl_mapClicked = false;

    deleteMarker _markerBorderName;
    if (getMarkerColor _markerRPName == "colorRED") exitWith {
        hint "Select ROAD";
        deleteMarker _markerRPName;
    };

    private _cords = getMarkerPos _markerRPName;
    deleteMarker _markerRPName;
    private _road = [_cords, 75,[]] call BIS_fnc_nearestRoad;

    private _groups = [];
    {
        if ((((leader _x) distance2D (getPos _road)) < 300 )and ((vehicle (leader _x)) != (leader _x))) then {
            _groups pushBack _x;
            _x setVariable ["onTask", true];
        };
    } forEach _allGroups;

    _groupsCount = count _groups;
    _groups = [_groups, [], {(leader _x) distance2D _road}, "ASCEND"] call BIS_fnc_sortBy;
    private _facing = leader (_groups#(_groupsCount - 1)) getDir (getpos _road);
    private _checkPos = (getPos _road) getPos [500, _facing];


    private _roadPositions = [];
    for  "_i" from 0 to _groupsCount - 1 do {
        _road = ((roadsConnectedTo _road) - [_road]) select 0;
        _roadPos = getPos _road;
        _info = getRoadInfo _road;    
        _endings = [_info#6, _info#7];
        _endings = [_endings, [], {_x distance2D _checkPos}, "ASCEND"] call BIS_fnc_sortBy;
        _roadDir = (_endings#1) getDir (_endings#0);
        _roadPositions pushBack [_roadPos , _roadDir]
    };

    {
        _roadPos = _x#0;
        _roadDir = _x#1;
        _group = ([_groups, [], {(leader _x) distance2D _roadPos}, "ASCEND"] call BIS_fnc_sortBy)#0;
        _groups deleteAt (_groups find _group);
        // [vehicle (leader _group), _group, _roadPos, _roadDir, _groups] spawn {
            // params ["_vic", "_group", "_roadPos", "_roadDir", "_groups"];
            _vic = vehicle (leader _group);
            _vic doMove _roadPos;
            _vic setDestination [_roadPos,"VEHICLE PLANNED" , true];
            pl_draw_vic_advance_wp_array pushBack [_vic, _roadPos];
            _vic limitSpeed 20;
            _group setBehaviourStrong "CARELESS";

            sleep 2;
            _time = time + 7;
             waitUntil {sleep 0.5; unitReady _vic or !alive _vic or _vic distance2d _roadPos < 50 or !(_group getVariable ["onTask", false]) or time >= _time};

            pl_draw_vic_advance_wp_array = pl_draw_vic_advance_wp_array - [[_vic, _roadPos]];
            _vic setDir _roadDir;
            _group setBehaviour "AWARE";
            _vic limitSpeed 50;
             if !(_group getVariable ["onTask", false]) exitWith {};

            // _turnPos = [_vic, _roadDir] call pl_get_turn_vehicle;
            // _vic doMove _turnPos;
            // _vic setDestination [_turnPos,"VEHICLE PLANNED" , true];
        // };
        // sleep 2;
    } forEach _roadPositions;
};

pl_detach_inf_planed = {
    params ["_group", "_attached", "_taskPlanWp"];

    if (count _taskPlanWp != 0) then {

        _wpPos = waypointPosition _taskPlanWp;
        _wpPos = +_wpPos;

        pl_draw_unload_inf_task_plan_icon_array pushBack [_attached, _wpPos];

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 20) or !(_group getVariable ["pl_task_planed", false])};

        deleteWaypoint [_group, _taskPlanWp#1];

        if !(_group getVariable ["pl_task_planed", false]) then {
            pl_cancel_strike = true;
            pl_draw_unload_inf_task_plan_icon_array = pl_draw_unload_inf_task_plan_icon_array - [[_attached, _wpPos]];
        }; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_vic_attached", false];
        _attached setVariable ["pl_disembark_finished", true];
    };
};



pl_convoy_path_marker = [];

pl_convoy_parth_find = {
    params ["_start", "_goal"];

    if (isNull _start or isNull _goal) exitWith {[]};

    private _dummyGroup = createGroup [sideLogic, true];
    private _closedSet = [];
    private _openSet = [_start];
    private _current = _start;
    private _nodeCount = 0;
    private _allRoads = [];
    private _n = 0;
    private _returnPath = [];
    private _time = time + 4;
    while {!(_openSet isEqualTo []) and time < _time} do {
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
                // _returnPath pushback getPos _parent;
                _allRoads pushBackUnique _parent;
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
                if (isNil "_gScoreIsBest") exitWith {};
                if (_gScoreIsBest) then {
                    _dummyGroup setVariable ["NF_neighborParent_" + str _x, _current];
                    _dummyGroup setVariable ["NF_neighborG_" + str _x, _gScore];
                };
            };
        } forEach _neighbors;
    };
    if (time > _time) exitWith {[]};
    reverse _allRoads;
    // _returnPath deleteRange [0, 3];
    _allRoads
};

pl_door_animation = {
    params ["_vic", "_mode"];
    _vic animateDoor ["Door_rear_source", _mode];
    _vic animateDoor ["Door_1_source", _mode];
    _vic animateDoor ["Door_L", _mode];
    _vic animateDoor ["Door_R", _mode];

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
    params [["_group", hcSelected player select 0], ["_taskPlanWp", []]];
    private ["_targetVic", "_groupLen"];

    if (visibleMap or !(isNull findDisplay 2000)) then {
        pl_show_vehicles_pos = getPos (leader _group);
        if !(_taskPlanWp isEqualTo []) then {pl_show_vehicles_pos = waypointPosition _taskPlanWp};
        pl_show_vehicles = true;
        onMapSingleClick {
            pl_mapClicked = true;
            pl_vics = nearestObjects [_pos, ["Car", "Truck", "Tank", "Air"], 10, true];
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

    private _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa";

    if (count _taskPlanWp != 0) then {

        private _wPos = waypointPosition _taskPlanWp;
        private _cords = getPos _targetVic;

        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];
        
        waitUntil {(_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};

        // deleteWaypoint [_group, _taskPlanWp#1];

        if !(_group getVariable ["pl_task_planed", false]) then {
            pl_cancel_strike = true;
            [group (driver _targetVic)] call pl_execute;
        }; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];

        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

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
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Crewing %2", groupId _group, getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName")]};
        if (pl_enable_map_radio) then {[_group, format ["Crewing %1", getText (configFile >> "CfgVehicles" >> typeOf _targetVic >> "displayName")], 25] call pl_map_radio_callout};

        [_group] spawn {
            params ["_group"];

            waitUntil {sleep 0.5; !(isNull objectParent (leader _group))};

            [_group, true] spawn pl_change_to_vic_symbols;
        };
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

    [_group] spawn {
        params ["_group"];

        waitUntil {sleep 0.5; !(isNull objectParent (leader _group))};

        [_group, true] spawn pl_change_to_vic_symbols;
    };    
};
    
pl_left_vehicles = [];

pl_leave_vehicle = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_vic"];

    _vic = {
        if (vehicle _x != _x) exitWith {vehicle _x};
        objNull
    } forEach (units _group);

    if (isNull _vic) exitWith {hint "Group is not crewing a Vehicle!"};

    if (count _taskPlanWp != 0) then {

        _wpPos = waypointPosition _taskPlanWp;
        _wpPos = +_wpPos;

        pl_draw_unload_inf_task_plan_icon_array pushBack [_group, _wpPos];

        waitUntil {(_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};


        // deleteWaypoint [_group, _taskPlanWp#1];

        if !(_group getVariable ["pl_task_planed", false]) then {
            pl_cancel_strike = true;
            pl_draw_unload_inf_task_plan_icon_array = pl_draw_unload_inf_task_plan_icon_array - [[_group, _wpPos]];
        }; // deleteMarker

        if !(_group getVariable ["pl_unload_task_planed", false]) then {
            _group setVariable ["pl_task_planed", false];
            _group setVariable ["pl_execute_plan", nil];
        };
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    _cargo = fullCrew [_vic, "cargo", false];
    _cargo = (crew _vic) - (units _group);
    _cargoGroups = [];

    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);

    {
        _unit = _x;
        if !(_unit in (units _group)) then {
            _cargoGroups pushBackUnique (group _unit);
        };
    } forEach _cargo;
    
    {
        unassignVehicle _x;
        doGetOut _x;
        [_x] allowGetIn false;
        doStop _x;
        _x doFollow (leader _x);
        if ((lifeState _x) isEqualTo "INCAPACITATED") then {
            [_x, _vic] call pl_crew_eject;
        };
    } forEach (crew _vic);

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
    _group setVariable ["pl_has_cargo", false];
    // _group setVariable ["setSpecial", false];
    // _group setVariable ["onTask", false];


    // _vic setVariable ["pl_on_transport", nil];
    // _group setVariable ["pl_has_cargo", false];
    waitUntil {sleep 0.5; vehicle (leader _group) == (leader _group)};
    [_group] call pl_change_inf_icons;
    sleep 2;
    _time = time + 30;
    waitUntil {sleep 0.5; ({unitReady _x} count (units _group)) == (count (units _group)) or time >= _time};
    sleep 2;

    {
        _x enableAI "AUTOCOMBAT";
    } forEach (units _group);

    _group setVariable ["pl_disembark_finished", true];

    sleep 5;

    _group setVariable ["pl_disembark_finished", nil]; 
};

pl_spawn_leave_vehicle = {
    {
        [_x] spawn pl_leave_vehicle;
    } forEach hcSelected player;  
};

pl_follow_array_other_setup = [];
pl_follow_array_other = [];

pl_attach_inf = {
    params [["_group", (hcSelected player) select 0], ["_vic", objNull]];
    private ["_group", "_vic", "_vicGroup", "_attachForm", "_leader"];

    // _group = (hcSelected player) select 0;

    // if (_group getVariable ["pl_vic_attached", false]) exitWith {
    //     if (_group getVariable ["pl_change_kampfweise", false]) then {
    //         _group setVariable ["pl_change_kampfweise", nil];
    //         [_group] spawn pl_change_kampfweise;
    //     } else {
    //         _group setVariable ["pl_vic_attached", false]; _group setVariable ["pl_attached_infGrp", nil];
    //     };
    // };

    // if (vehicle (leader _group) != leader _group) exitWith {_group setVariable ["pl_change_kampfweise", true]; [_group] spawn pl_change_kampfweise;};

    if (_group getVariable ["pl_vic_attached", false]) exitWith {_group setVariable ["pl_vic_attached", false]; _group setVariable ["pl_attached_infGrp", nil];};


    if (isNull _vic) then {

        pl_attach_form = false;
      
        if (visibleMap or !(isNull findDisplay 2000)) then {
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
                _cords = _pos;
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
    } else {
        pl_attach_form = "Line";
    };

    _vicGroup = group (driver _vic);
    _attachForm = pl_attach_form;

    if (_vicGroup getVariable ["pl_vic_attached", false]) exitWith {Hint "Vehicle already has Infantry attached"};


    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;
    [_vicGroup] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;
    [_vicGroup] call pl_reset;

    sleep 0.5;

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\map\markers\nato\n_mech_inf.paa"];
    _vicGroup setVariable ["pl_vic_attached", true];
    _vicGroup setVariable ["pl_attached_infGrp", _group];
    // _vicGroup setVariable ["setSpecial", true];
    // _vicGroup setVariable ["specialIcon", "\A3\ui_f\data\map\markers\nato\n_mech_inf.paa"];
    // _group setVariable ["specialIcon", "\A3\3den\data\Attributes\Formation\line_ca.paa"];

    pl_follow_array_other = pl_follow_array_other + [[_vicGroup, _group]];
    _vic setVariable ["pl_speed_limit", "CON"];

    _attachForm = "LINE";
    switch (_attachForm) do { 
        case "File" : {_group setFormation "FILE"}; 
        case "Diamond" : {_group setFormation "DIAMOND"}; 
        default {_group setFormation "LINE"}; 
    };

    _vicGroup setFormation _attachForm;

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

    _attachDir = (leader _group) getDir _vic;
    _turnPos = [_vic, _attachDir] call pl_get_turn_vehicle;
    _vic doMove _turnPos;

    waitUntil {sleep 0.5; unitReady _vic or !(_group getVariable ["onTask", false]) or !alive _vic and unitReady (leader _group)};

    player hcRemoveGroup _group;

    while {(alive _vic) and (_group getVariable ["onTask", false]) and (_vicGroup getVariable ["pl_vic_attached", false])} do {

        _group setFormDir (getDir _vic);
        // _group setFormation (formation _vicGroup);
        if (speed _vic > 0) then {
            _group setBehaviour "AWARE";
            _leader = leader _group;
            _leader limitSpeed 14;
            _leaderPos = [5*(sin ((getDir _vic) - 180)), 5*(cos ((getDir _vic) - 180)), 0] vectorAdd getPos _vic;
            _leader doMove _leaderPos;
            {
                _x doFollow _leader;
            } forEach ((units _group) - [_leader]);
        };

        if ((_leader distance2D _vic) > 22) then {_vic forceSpeed 0} else {_vic forceSpeed -1; _vic limitSpeed 12};
        _vic setVariable ["pl_speed_limit", "CON"];

        // sleep 2;
        _time = time + 2;
        waitUntil {sleep 0.1; time >= _time or !(_group getVariable ["onTask", true]) or !(alive _vic)};
    };

    _vicGroup setVariable ["pl_vic_attached", nil];
    _vicGroup setVariable ["pl_attached_infGrp", nil];
    player hcSetGroup [_group];

    pl_follow_array_other = pl_follow_array_other - [[_vicGroup, _group]];
    [_group] call pl_reset;
    _vic forceSpeed -1;
    _vic limitSpeed 50;
    _vic setVariable ["pl_speed_limit", "50"];
};

pl_change_kampfweise = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];

    if (vehicle (leader _group) == leader _group) exitWith {hint "Vehicle Only Task"};

    if (count _taskPlanWp != 0) then {

        if (vehicle (leader _group) != leader _group) then {
            if !(_group getVariable ["pl_unload_task_planed", false]) then {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
            } else {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; ((_group getVariable ["pl_execute_plan", false]) and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
            };
        } else {
            // waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 or !(_group getVariable ["pl_task_planed", false])};
            waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
        };
        _group setVariable ["pl_disembark_finished", nil];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_unload_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];
    };

    private _vic = vehicle (leader _group);
    private _driver = driver _vic;
    private _vicGroup = group _driver;
    private _crew = crew _vic;
    private _cargo = _crew - (units _vicGroup);
    // dismount
    if !(_group getVariable ["pl_vic_attached", false]) then {

        // _cargo = fullCrew [_vic, "cargo", false];

        // if (count _cargo == 0) exitWith {hint "No Cargo to Unload"}
        private _attached = _vicGroup getVariable ["pl_attached_infGrp", grpNull];
        if !(isNull _attached) exitWith {[_vicGroup, _attached, _taskPlanWp] spawn pl_detach_inf_planed};

        private _cargoGroups = [];
        {
            _unit = _x;
            if (!(_unit in (units _vicGroup)) and !(_unit in (units (group player)))) then {
                _cargoGroups pushBack (group _unit);
            };
        } forEach _cargo;

        if (_cargoGroups isEqualTo []) exitWith {hint "No Mounted Infantry"};

        _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

        // unload

        doStop _vic;

        private _cargoPers = [];
        {
            _cGroup = _x;
            // moveOut (leader _cGroup);
            if !(_cGroup getVariable ["pl_show_info", false]) then {
                [_cGroup, "inf", false] call pl_show_group_icon;
            };
            _cGroup leaveVehicle _vic;
            {
                _cargoPers pushBack _x;
                unassignVehicle _x;
                doGetOut _x;
                [_x] allowGetIn false;
                // doStop _x;
                if (_x != (leader _cGroup)) then {
                    _x doFollow (leader _cGroup);
                } else {
                    _x doMove ((getpos _vic) getPos [10, (getdir _vic) - 180]);
                    _x setDestination [(getpos _vic) getPos [10, (getdir _vic) - 180], "LEADER DIRECT", true];
                };
                _x disableAI "AUTOCOMBAT";
            } forEach (units _cGroup);
            _cGroup setBehaviourStrong "AWARE";
         } forEach _cargoGroups;

         waitUntil {sleep 0.5; (({vehicle _x != _x} count _cargoPers) == 0) or (!alive _vic)};

        // attach

        sleep 1;

        [_cargoGroups#0, _vic] spawn pl_attach_inf;

    // mount
    } else {

        //detach

        _group setVariable ["pl_vic_attached", false];
        private _infGroup = _group getVariable ["pl_attached_infGrp", grpNull];

        sleep 2;
        //load

        [_infGroup, [], _vic] spawn pl_getIn_vehicle;
    };
};

pl_air_insertion = {
    private ["_cords", "_lzPos", "_helipad", "_rtbPos", "_mPos"];

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader (_groups#0)] call pl_open_tac_forced;
        };
    };

    private _allGroups = hcSelected player;

    private _groups = [];
    {
        if (vehicle (leader _x) isKindOf "AIR" and _x getVariable ["pl_has_cargo", false]) then {_groups pushBack _x};
    } forEach _allGroups;

    if (_groups isEqualTo []) exitWith {hint "No Loaded Air Units Selected!"};

    private _pps = [];
    private _ppMarkers = [];
    pl_confirm_lz = false;

    while {!pl_confirm_lz} do {

        onMapSingleClick {
            pl_air_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_confirm_lz = true};
            hintSilent "";
            onMapSingleClick "";
        };

        _ppM = createMarker [str (random 1), [0,0,0]];
        _ppM setMarkerType "marker_pp";
        _ppM setMarkerColor pl_side_color;
        _ppM setMarkerSize [0.7, 0.7];
        _ppMarkers pushback _ppM;

        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            _ppM setMarkerPos _mPos;
        };

        sleep 0.5;
        pl_mapClicked = false;

        _cords = pl_air_cords;
        if (pl_confirm_lz) then {
            _ppM setMarkerType "marker_rp";
            _ppM setMarkerSize [1, 1];
        } else {
            _pps pushback _cords;
        };
    };

    _groups = ([_groups, [], {(_pps#0) distance2d (leader _x)}, "ASCEND"] call BIS_fnc_sortBy);

    private _convoyLeaderGroup = _groups#0;
    private _convoyLeader = vehicle (leader _convoyLeaderGroup);
    _convoyLeaderGroup setVariable ["setSpecial", true];
    _convoyLeaderGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];

    private _convoy = +_groups;
    reverse _convoy;
    pl_draw_convoy_array pushBack _convoy;
    private _drawPath = [getPos _convoyLeader] + _pps + [_cords]; 
    pl_draw_convoy_path_array pushback _drawPath;

    private _approachDir = (_pps#((count _pps) - 1)) getDir _cords;
    private _posOffset = 0;
    private _posOffsetStep = 40;

    for "_i" from 0 to (count _groups) - 1 do {
        
        _group = _groups#_i;
        player hcRemoveGroup _group;
        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
        _group setVariable ["pl_draw_convoy", true];

        _vic = vehicle (leader _group);
        [_vic, 0] call pl_door_animation;
        _landigPadBase = "Land_HelipadEmpty_F" createVehicle (getPos _vic);
        _vic flyInHeight 40;
        _landigPadBase setDir (getDir _vic);
        _rtbPos = getPos _landigPadBase;

        _dirOffset = 90;
        if (_i % 2 == 0) then {_dirOffset = -90};
        _lzPos = _cords getPos [_posOffset, _approachDir + _dirOffset];
        if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
        [_lzPos, 40] call pl_clear_obstacles;
        sleep 0.2;
        _lzPos = _lzPos findEmptyPosition [0, 60, typeOf _vic];
        _landigPadLz = "Land_HelipadEmpty_F" createVehicle _lzPos;
        _landigPadLz setDir _approachDir;

        _m = createMarker [str (random 1), _lzPos];
        _m setMarkerType "mil_dot";
        _m setMarkerSize [0.7, 0.7];

        {
            _group addWaypoint [_x, 0];
        } forEach _pps;
        _lzWp = _group addWaypoint [_lzPos, 0];
        _lzWp setWaypointType "TR UNLOAD";

        [_vic, _group, _rtbPos, _landigPadLz, _lzPos, _pps] spawn {
            params ["_vic", "_group", "_rtbPos", "_landigPadLz", "_lzPos", "_pps"];

            waitUntil{sleep 0.5; !alive _vic or (_vic distance2d _lzPos) < 200};

            _cargo = fullCrew [_vic, "cargo", false];
            private _cargoGroups = [];
            {
                _cargoGroups pushBack (group (_x select 0));
            } forEach _cargo;
            _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

            waitUntil {sleep 0.5; (isTouchingGround _vic) or !alive _vic};

            [_vic, 1] call pl_door_animation;
            {
                _x leaveVehicle _vic;
                if !(_x getVariable ["pl_show_info", false]) then {[_x] call pl_show_group_icon;};
                if (_x != (group player)) then {_x addWaypoint [(getPos _vic) getPos [20, (getDir _vic) - 180], 0]};
            } forEach _cargoGroups;

            waitUntil {((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};

            deleteVehicle _landigPadLz;
            [_vic, 0] call pl_door_animation;

            if ((_vic distance2D _rtbPos) < 300) exitWith {_vic engineOn false};

            _rPPs = +_pps;
            reverse _rPPs;

            {
                _group addWaypoint [_x, 0];
            } forEach _rPPs;
            _group addWaypoint [_rtbPos, 0];

            waitUntil {sleep 0.5; ((unitReady _vic) and _vic distance2d _rtbPos < 200) or (!alive _vic)};
            _vic land "LAND";
            _group setVariable ["onTask", false];
            _group setVariable ["setSpecial", false];
        };
        sleep 5;
    };
    sleep 40;
    waitUntil {sleep 0.5; !(alive _convoyLeader) or !(_convoyLeaderGroup getVariable ["onTask", true])};

    pl_draw_convoy_array = pl_draw_convoy_array - [_convoy];
    pl_draw_convoy_path_array = pl_draw_convoy_path_array - [_drawPath];
    {deleteMarker _x} forEach _ppMarkers;
};

// pl_vehicle_convoy_unstuck = {
//     params ["_vic", "_group", "_cords"];
//     _vic setVehiclePosition [getPosVisual _vic, [], 0, "CAN_COLLIDE"];
//     {
//         _x setDamage 1;
//     } forEach (nearestTerrainObjects [getPos _vic, ["TREE", "SMALL TREE", "BUSH"], 8, false, true]);
//     _leader = leader _group;
//     (units _group) joinSilent _group;
//     _group selectLeader _leader;

//     if ((currentWaypoint _group) >= count (waypoints _group)) then {
//         _group addWaypoint [_cords, 2];
//     } else {
//         [_group, (currentWaypoint _group)] setWaypointPosition [_cords, -1];
//         _vic doMove _cords;
//     };

//     _road = [getPos _vic, 10] call BIS_fnc_nearestRoad;
//     if !(isNull _road) then {
//         _info = getRoadInfo _road;    
//         _endings = [_info#6, _info#7];
//         _endings = [_endings, [], {_x distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy;
//         _vPos = _endings#0;
//         _roadDir = (_endings#1) getDir (_endings#0);
//         _vic setDir _roadDir;
//     };
// };

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
        // _vicGroup setVariable ["setSpecial", true];
        // _vicGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
        _vicGroup setVariable ["pl_has_cargo", true];
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
        // _vicGroup setVariable ["setSpecial", false];
        _vicGroup setVariable ["pl_has_cargo", false];
    };
    if (({(group (_x#0)) isEqualTo _group} count _cargo) > 0) then {
        [_vicGroup, _cargo, _group] spawn {
            params ["_vicGroup", "_cargo", "_group"];
            waitUntil {sleep 1; (({(group (_x#0)) isEqualTo _group} count (fullCrew [(vehicle ((units _vicGroup)#0)), "cargo", false])) == 0)};
            // _vicGroup setVariable ["setSpecial", false];
            _vicGroup setVariable ["pl_has_cargo", false];
        };
    };
}];






