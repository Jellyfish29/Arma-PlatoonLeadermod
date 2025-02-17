

pl_onMapSingleClick_column = {

    onMapSingleClick {

        pl_draw_convoy_path_array = pl_draw_convoy_path_array - [pl_column_passigPoints];

        private _rangelimiterCenter = pl_column_passigPoints#((count pl_column_passigPoints) - 1);

        if (_shift) then {pl_cancel_strike = true; pl_mapClicked = true};
        if (inputAction "curatorGroupMod" <= 0) then {
            pl_mapClicked = true;
        } else {
            if ((_pos distance2D _rangelimiterCenter) <= 200) then {
                pl_column_passigPoints pushBack _pos;
            };
            pl_draw_convoy_path_array pushback pl_column_passigPoints;
            [] spawn pl_onMapSingleClick_column;
        };
        hintSilent "";
        onMapSingleClick "";

        // _m = createMarker [str (random 2), _pos];
        // _m setMarkerType "mil_dot";
    };
};



pl_move_as_column = {
    private ["_mPos"];

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader (_groups#0)] call pl_open_tac_forced;
        };
    };

    private _allgroups = hcSelected player;
    private _groups = +_allGroups;
    pl_column_passigPoints = [[_groups] call pl_find_centroid_of_groups];

    private _rangelimiter = 200;
    private _rangelimiterCenter = pl_column_passigPoints#0;
    _markerBorderName = str (random 2);
    createMarker [_markerBorderName, _rangelimiterCenter];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorOrange";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];


    player enableSimulation false;

    
    [] spawn pl_onMapSingleClick_column;


    while {!pl_mapClicked} do {
        _markerBorderName setMarkerPos (pl_column_passigPoints#((count pl_column_passigPoints) - 1));
        sleep 0.1;
    };

    player enableSimulation true;

    pl_mapClicked = false;

    deleteMarker _markerBorderName;

    pl_draw_convoy_path_array = pl_draw_convoy_path_array - [pl_column_passigPoints];

    pl_column_passigPoints deleteAt 0;
    _passigPoints = +pl_column_passigPoints;

    _start = _passigPoints#0;

    _groups = ([_groups, [], {(leader _x) distance2D _start}, "ASCEND"] call BIS_fnc_sortBy);
    _convoyLeaderGroup = _groups#0;
    _convoyLeader = vehicle (leader _convoyLeaderGroup);

    _passigPoints insert [0, [getPos _convoyLeader]];


    sleep 0.1;
    private _convoy = +_groups;
    reverse _convoy;
    pl_draw_convoy_array pushBack _convoy;
    private _convoyPath = +_passigPoints;
    _convoyPath insert [0, [getPos _convoyLeader]];
    pl_draw_convoy_path_array pushback _passigPoints;

    {
        // if !(_x == _convoyLeaderGroup) then {
        //     player hcRemoveGroup _x;
        // };
        [_x] call pl_reset;
        _x setVariable ["pl_draw_convoy", true];
    } forEach _groups;

    for "_i" from 0 to (count _groups) - 1 do {
        // doStop (vehicle (leader _x));

        private _group = _groups#_i;
        private _vic = vehicle (leader _group);
        _vic limitSpeed pl_convoy_speed;
        _vic setVariable ["pl_speed_limit", "CON"];
        _group setVariable ["onTask", true];

        _conWp = _group addWaypoint [(_passigPoints#((count _passigPoints) - 1)) getPos [15 * _i, (_passigPoints#((count _passigPoints) - 1)) getDir (_passigPoints#((count _passigPoints) - 2))], 0];
        _group setVariable ["pl_conWp", _conWp];
        // _vic setConvoySeparation 5;
        // _vic forceFollowRoad true;
        _group setVariable ["pl_pp_idx", 0];

        // _group setBehaviourStrong "SAFE";
        [getPos _vic, 3] call pl_clear_obstacles;
        _vic doMove (_passigPoints#0);
        _vic setDestination [(_passigPoints#0),"VEHICLE PLANNED" , true];

        {
            _x disableAI "AUTOCOMBAT";
        } forEach (units _group);

        // _vic setDriveOnPath (_group getVariable "pl_convoy_path");

        if (_vic != _convoyLeader) then {

            // player hcRemoveGroup _group;

            [_group ,_vic, _convoyLeader, _groups, _i, _convoyLeaderGroup, _passigPoints] spawn {
                params ["_group" , "_vic", "_convoyLeader", "_groups", "_i", "_convoyLeaderGroup", "_passigPoints"];
                private ["_ppidx", "_time"];

                // _vic setDriveOnPath (_group getVariable "pl_convoy_path");

                _ppidx = 0;
                private _forward = vehicle (leader (_groups#(_i - 1)));
                private _startReset = false;
                while {(_convoyLeaderGroup getVariable ["onTask", true]) and ((_groups#(_i - 1)) getVariable ["onTask", true]) and alive _forward} do {

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
                    private _distance = _vic distance2D _forward;
                    private _forwardPP = _passigPoints#((_groups#(_i - 1)) getVariable "pl_pp_idx");
                    if (_distance > 60) then {
                        _vic limitSpeed (_convoyLeaderSpeed + 5 + (_distance - 60));
                    };
                    if (_distance < 60) then {
                        _vic limitSpeed _convoyLeaderSpeed;
                    };
                    if (_distance < 40) then {
                        _vic limitSpeed (_convoyLeaderSpeed * 0.5);
                    };
                    if (_distance < 20 or (_vic distance2d _forwardPP) < (_forward distance2d _forwardPP)) then {
                        _vic forceSpeed 0;
                        _vic limitSpeed 0;
                    };
                    if (_distance > 150 and (_vic distance2d _forwardPP) >= (_forward distance2d _forwardPP)) then {
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
                            // _group setBehaviourStrong "SAFE";
                            _group setVariable ["pl_draw_convoy", true];
                            // _vic setVariable ["pl_phasing", true];
                            _pp = (_passigPoints#_ppidx);
                            _r0 = [getpos _vic, 100,[]] call BIS_fnc_nearestRoad;
                            _r1 = ([roadsConnectedTo _r0, [], {_pp distance2d _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                            // _vic setVehiclePosition [getPos _r1, [], 0, "NONE"];
                            // _vic setDir  (_r0 getDir _r1);
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
                // [_group] call pl_reset;
                _group setVariable ["pl_draw_convoy", nil];
                _vic limitSpeed 50;
                _vic setVariable ["pl_speed_limit", "50"];
                doStop _vic;
                _vic doMove (waypointPosition (_group getVariable "pl_conWp"));
                
            };
        } else {
            [_group ,_vic, _convoyLeader, _groups, _i, _convoyLeaderGroup, _passigPoints] spawn {
                params ["_group" , "_vic", "_convoyLeader", "_groups", "_i", "_convoyLeaderGroup", "_passigPoints"];
                private ["_ppidx"];

                private _dest = _passigPoints#((count _passigPoints) - 1);

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
                            // _group setBehaviourStrong "SAFE";
                            _group setVariable ["pl_draw_convoy", true];
                            _pp = (_passigPoints#_ppidx);
                            _r0 = [getpos _vic, 100,[]] call BIS_fnc_nearestRoad;
                            _r1 = ([roadsConnectedTo _r0, [], {_pp distance2d _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                            // _vic setVehiclePosition [getPos _r1, [], 0, "NONE"];
                            // _vic setDir  (_r0 getDir _r1);
                            sleep 0.1;
                            _vic limitSpeed pl_convoy_speed;
                            _vic setVariable ["pl_speed_limit", "CON"];
                            _vic doMove _pp;
                            _vic setDestination [_pp,"VEHICLE PLANNED" , true];

                        }; 
                    };
                    sleep 1;
                };

                // [_convoyLeaderGroup] call pl_reset;

                _convoyLeaderGroup setVariable ["onTask", false];
                _vic limitSpeed 50;
                _vic setVariable ["pl_speed_limit", "50"];
                _convoyLeaderGroup setVariable ["pl_draw_convoy", nil];
            };
        };
        _time = time + 1.5;
        waituntil {(time >= _time and speed _vic > 6) or !((_convoyLeaderGroup) getVariable ["onTask", true])};
    };

    // sleep 2;
    waituntil {sleep 1; !(_convoyLeaderGroup getVariable ["onTask", true])};
    // if (speed _convoyLeader <= 0) then {if (pl_enable_map_radio) then {[_convoyLeaderGroup, "... Destination unreachable!", 25] call pl_map_radio_callout}};

    pl_draw_convoy_array = pl_draw_convoy_array - [_convoy];
    pl_draw_convoy_path_array = pl_draw_convoy_path_array - [_passigPoints];
};
