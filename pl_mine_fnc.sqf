pl_engineering_markers = [];

pl_mine_clearing = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];

    if (vehicle (leader _group) != leader _group and ((vehicle (leader _group)) getVariable ["pl_is_mine_vic",false]) and !(_group getVariable ["pl_unload_task_planed", false])) then {
        [_group, _taskPlanWp] spawn pl_mine_clearing_vic;
    } else {
        [_group, _taskPlanWp] spawn pl_mine_clearing_inf;
    };
};

pl_mine_clearing_inf = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_cords", "_engineer", "_mines", "_watchdir", "_mPos", "_startPos"];

    // _group = (hcSelected player) select 0;

    _group setVariable ["pl_is_task_selected", true];

    _engineer = {
        if ("MineDetector" in (items _x) and "ToolKit" in (items _x)) exitWith {_x};
        // if ("MineDetector" in (items _x)) exitWith {_x};
        objNull
    } forEach (units _group);

    // if (isNull _engineer) exitWith {hint "No mineclearing equipment"};

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader _group] call pl_open_tac_forced;
        };
    };

    pl_mine_sweep_area_size = 35;
    pl_mine_sweep_area_lane_width = 20;

    _markerName = format ["%1mineSweepe%2", _group, random 3];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "RECTANGLE";
    _markerName setMarkerBrush "SolidBorder";;
    _markerName setMarkerColor "colorGreen";
    _markerName setMarkerAlpha 0.5;
    _markerName setMarkerSize [pl_mine_sweep_area_size, pl_mine_sweep_area_size * 0.33];

    private _rangelimiter = 200;

    _markerBorderName = str (random 2);
    private _borderMarkerPos = getPos (leader _group);
    if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
    createMarker [_markerBorderName, _borderMarkerPos];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorORANGE";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    _markerNameLaunchPos = format ["%1_mclc_launch%2", _group, random 3];
    createMarker [_markerNameLaunchPos, [0,0,0]];
    _markerNameLaunchPos setMarkerColor "colorGreen";
    _markerNameLaunchPos setMarkerType "mil_start";
    _markerNameLaunchPos setMarkerSize [0.5, 0.5];

    _message = "Select Search Area <br /><br />
    <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>
    <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />";
    hint parseText _message;
    onMapSingleClick {
        pl_sweep_cords = _pos;
        if (_shift) then {pl_cancel_strike = true};
        pl_mapClicked = true;
        hintSilent "";
        onMapSingleClick "";
    };

    player enableSimulation false;

    

    while {!pl_mapClicked} do {
        // sleep 0.1;
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
            _markerName setMarkerPos _mPos;
        };
        if (inputAction "MoveForward" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size + 5; sleep 0.05};
        if (inputAction "MoveBack" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size - 5; sleep 0.05};
        if (inputAction "TurnLeft" > 0) then {pl_mine_sweep_area_lane_width = pl_mine_sweep_area_lane_width + 5; sleep 0.05};
        if (inputAction "TurnRight" > 0) then {pl_mine_sweep_area_lane_width = pl_mine_sweep_area_lane_width - 5; sleep 0.05};
        _markerName setMarkerSize [pl_mine_sweep_area_size, pl_mine_sweep_area_lane_width / 2];
        if (pl_mine_sweep_area_size >= 200) then {pl_mine_sweep_area_size = 200};
        if (pl_mine_sweep_area_size <= 20) then {pl_mine_sweep_area_size = 20};
        if (pl_mine_sweep_area_lane_width >= 200) then {pl_mine_sweep_area_lane_width = 200};
        if (pl_mine_sweep_area_lane_width <= 10) then {pl_mine_sweep_area_lane_width = 10};
    };

    // player enableSimulation true;
    pl_mapClicked = false;
    _cords = getMarkerPos _markerName;

    onMapSingleClick {
        pl_mapClicked = true;
        if (_shift) then {pl_cancel_strike = true};
        onMapSingleClick "";
    };

    // player enableSimulation false;

    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _watchDir = _cords getdir _mPos;
        _markerName setMarkerDir (_watchDir + 90);
        if (inputAction "MoveForward" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size + 5; sleep 0.05};
        if (inputAction "MoveBack" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size - 5; sleep 0.05};
        if (inputAction "TurnLeft" > 0) then {pl_mine_sweep_area_lane_width = pl_mine_sweep_area_lane_width + 5; sleep 0.05};
        if (inputAction "TurnRight" > 0) then {pl_mine_sweep_area_lane_width = pl_mine_sweep_area_lane_width - 5; sleep 0.05};
        _markerName setMarkerSize [pl_mine_sweep_area_size, pl_mine_sweep_area_lane_width / 2];
        if (pl_mine_sweep_area_size >= 200) then {pl_mine_sweep_area_size = 200};
        if (pl_mine_sweep_area_size <= 20) then {pl_mine_sweep_area_size = 20};
        if (pl_mine_sweep_area_lane_width >= 200) then {pl_mine_sweep_area_lane_width = 200};
        if (pl_mine_sweep_area_lane_width <= 10) then {pl_mine_sweep_area_lane_width = 10};

        _startPos = _cords getPos [pl_mine_sweep_area_size, _watchDir - 180];
        _markerNameLaunchPos setMarkerPos _startPos;
        _markerNameLaunchPos setMarkerDir _watchDir;

        if (pl_mine_sweep_area_lane_width > 30) then {
            _markerNameLaunchPos setMarkerSize [0,0];
        } else {
            _markerNameLaunchPos setMarkerSize [0.5,0.5];
        };
    };

    player enableSimulation true;

    pl_mapClicked = false;
    _markerName setMarkerAlpha 0.3;
    deleteMarker _markerBorderName;

    private _createLane = false;
    if (pl_mine_sweep_area_lane_width <= 50) then {
        _createLane = true;
    } else {
        deleteMarker _markerNameLaunchPos;
    };
    private _areaSize = pl_mine_sweep_area_size;
    private _laneWidth = pl_mine_sweep_area_lane_width;

    private _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa";

    _group setVariable ["pl_task_pos", _cords];
    _group setVariable ["specialIcon", _icon];

    if (count _taskPlanWp != 0) then {

        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        if (vehicle (leader _group) != leader _group) then {
            if !(_group getVariable ["pl_unload_task_planed", false]) then {
                waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false])};
            } else {
                waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
            };
        } else {
            waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 or !(_group getVariable ["pl_task_planed", false])};
        };
        _group setVariable ["pl_disembark_finished", nil];

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_unload_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; deleteMarker _markerNameLaunchPos; _group setVariable ["pl_is_task_selected", nil];};

    private _markerPointsLeft = [];
    private _markerPointsRight = [];
    private _markerFlags = [];

    if (_createLane) then {

        _startPos = _cords getPos [_areaSize, _watchDir - 180];
        private _starPosLeft = _startPos getPos [_laneWidth / 2, _watchDir + 90];
        private _starPosRight = _startPos getPos [_laneWidth / 2, _watchDir - 90];

        for "_i" from 0 to (round ((_areaSize * 2) / 30)) do {
            _lp = _starPosLeft getPos [30 * _i, _watchDir];
            _rp = _starPosRight getPos [30 * _i, _watchDir];
            _markerPointsLeft pushBack _lp;
            _markerPointsRight pushBack _rp;

            _lf = createVehicle ["FlagMarker_01_F", _lp, [], 0, "CAN_COLLIDE"];
            _lf setDir ([0, 360] call BIS_fnc_randomInt);
            hideObject _lf;
            _rf = createVehicle ["FlagMarker_01_F", _rp, [], 0, "CAN_COLLIDE"];
            _rf setDir ([0, 360] call BIS_fnc_randomInt);
            hideObject _rf;

            _markerFlags pushBack _lf;
            _markerFlags pushBack _rf;
        };

        // {
        //     _m = createMarker [str (random 5), _x];
        //     _m setMarkerType "mil_dot";
        // } forEach (_markerPointsRight + _markerPointsLeft);
    };

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"];
    private _escort = {
        if (_x != (leader _group) and _x != _engineer) exitWith {_x};
        objNull
    } forEach (units _group);

    {
        [_x, 15, getDir _x] spawn pl_find_cover;
    } forEach (units _group) - [_engineer] - [_escort];

    _engineer disableAI "AUTOCOMBAT";
    _engineer disableAI "TARGET";
    _engineer disableAI "AUTOTARGET";
    _escort disableAI "AUTOCOMBAT";
    _group setBehaviour "AWARE";
    {
        _x setVariable ["pl_is_at", true];
        _x setVariable ["pl_engaging", true];
        _x setUnitTrait ["camouflageCoef", 0.5, true];
        _x setVariable ["pl_damage_reduction", true];
        _x setUnitPosWeak "MIDDLE";
        _x setCombatBehaviour "CARELESS";
    } forEach [_engineer, _escort];
    pl_at_attack_array pushBack [_engineer, _cords, _escort];

    private _watchPos = _cords getPos [500, _watchDir];
    _mines = allMines select {(getpos _x) inArea _markerName};

    if (_createLane) then {
        _mines = _markerFlags + _mines; 
    };

    _mines = ([_mines, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy);

    waitUntil {sleep 0.5; unitReady _engineer or !alive _engineer};

    if (count _mines > 0) then {
        while {count _mines > 0} do {

            _mine = _mines#0;
            _pos = getPosATL _mine;
            _engineer doMove _pos;
            _escort doMove _pos;

            sleep 0.5;
            _time = time + 5 + (_engineer distance2d _pos);

            waitUntil {sleep 0.5; ((_engineer distance2D _pos) < 2) or time > _time or !(_group getVariable ["onTask", true])};

            if !(_group getVariable ["onTask", true]) exitWith {};
            // if ((_engineer distance2D _pos) > 2) then {continue};

            if !(isObjectHidden _mine) then {
                _cm = createMarker [str (random 3), getPos _mine];
                _cm setMarkerType "mil_triangle";
                _cm setMarkerSize [0.4, 0.4];
                _cm setMarkerDir -180;
                _cm setMarkerShadow false;
                pl_engineering_markers pushBack _cm;

                if (time > _time) then {
                    _cm setMarkerColor "colorBLUE";
                } else {
                    _cm setMarkerColor "colorGreen";
                    _engineer action ["Deactivate", _engineer, _mine];
                };
            } else {
                _mine hideObject false;
            };
            _mines deleteAt (_mines find _mine);

            sleep 2;
        };
    } else {
        private _time = time + ([60, 120] call BIS_fnc_randomInt);
        private _time2 = 0;
        while {_time > time and (_group getVariable ["onTask", false])} do {

            _engineer doMove ([[[_cords, 30]], ["water"]] call BIS_fnc_randomPos);
            _escort doFollow _engineer;
            _time2 = time + 6;

            waituntil {time >= _time2 or !(_group getVariable ["onTask", false])};

            sleep 0.5;
        };
    };

    deleteMarker _markerNameLaunchPos;

    if (_group getVariable ["onTask", true]) then {
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Mine Sweep complete", groupId _group]};
        if (pl_enable_map_radio) then {[_group, "...Mine Sweep Complete", 20] call pl_map_radio_callout};
        [_group] call pl_reset;
        _markerName setMarkerBrush "Cross";
        _markerName setMarkerColor "colorGreen";
        _markerName setMarkerText "CLR";
        pl_engineering_markers pushBack _markerName;

        if (_createLane) then {

            _endPos = _startPos getPos [_areaSize * 2, _watchDir];

            _markerLeftPos1 = _startPos getPos [7, _watchDir + 90];
            _markerLeftPos2 = _markerLeftPos1 getPos [5, _watchDir - 45];
            _markerLeftPos4 = _endPos getPos [7, _watchDir + 90];
            _markerLeftPos3 = _markerLeftPos4 getpos [5, _watchDir - 135];

            _markerLeft = createMarker [str (random 3), [0,0,0]];
            _markerLeft setMarkerShape "POLYLINE";
            _markerLeft setMarkerPolyline [_markerLeftPos1#0, _markerLeftPos1#1, _markerLeftPos2#0, _markerLeftPos2#1, _markerLeftPos3#0, _markerLeftPos3#1, _markerLeftPos4#0, _markerLeftPos4#1];
            _markerLeft setMarkerColor "colorGreen";

            _markerRightPos1 = _startPos getPos [7, _watchDir - 90];
            _markerRightPos2 = _markerRightPos1 getPos [5, _watchDir + 45];
            _markerRightPos4 = _endPos getPos [7, _watchDir - 90];
            _markerRightPos3 = _markerRightPos4 getpos [5, _watchDir + 135];

            _markerRight = createMarker [str (random 3), [0,0,0]];
            _markerRight setMarkerShape "POLYLINE";
            _markerRight setMarkerPolyline [_markerRightPos1#0, _markerRightPos1#1, _markerRightPos2#0, _markerRightPos2#1, _markerRightPos3#0, _markerRightPos3#1, _markerRightPos4#0, _markerRightPos4#1];
            _markerRight setMarkerColor "colorGreen";

            // pl_engineering_markers pushBack _markerLeft;
            // pl_engineering_markers pushBack _markerRight;

            pl_deployed_bridges pushBack [_cords, [_startPos, _endPos]];
            
        };
    } else {
        deleteMarker _markerName;  
    };
    pl_at_attack_array = pl_at_attack_array - [[_engineer, _cords, _escort]];
    _engineer forceSpeed -1;
    _escort forceSpeed -1;
};

pl_mine_clearing_vic = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_cords", "_engineer", "_mines", "_watchdir", "_mPos", "_startPos", "_endPos"];

    // _group = (hcSelected player) select 0;

    _engVic = vehicle (leader _group);

    if !(_engVic getVariable ["pl_is_eng_vic_plow", false]) exitWith {hint "Requires Egineering Vehicle with Mine Plow"};

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader _group] call pl_open_tac_forced;
        };
    };

    _group setVariable ["pl_is_task_selected", true];

    pl_mine_sweep_area_size = 35;
    pl_mine_sweep_area_lane_width = 10;

    _markerName = format ["%1mineSweepe%2", _group, random 3];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "RECTANGLE";
    _markerName setMarkerBrush "SolidBorder";;
    _markerName setMarkerColor "colorGreen";
    _markerName setMarkerAlpha 0.5;
    _markerName setMarkerSize [pl_mine_sweep_area_size, pl_mine_sweep_area_size * 0.33];

    private _rangelimiter = 200;

    _markerBorderName = str (random 2);
    private _borderMarkerPos = getPos (leader _group);
    if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
    createMarker [_markerBorderName, _borderMarkerPos];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorORANGE";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    _markerNameLaunchPos = format ["%1_mclc_launch%2", _group, random 3];
    createMarker [_markerNameLaunchPos, [0,0,0]];
    _markerNameLaunchPos setMarkerColor "colorGreen";
    _markerNameLaunchPos setMarkerType "mil_start";
    _markerNameLaunchPos setMarkerSize [0.5, 0.5];

    _message = "Select Search Area <br /><br />
    <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>
    <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />";
    hint parseText _message;
    onMapSingleClick {
        pl_sweep_cords = _pos;
        if (_shift) then {pl_cancel_strike = true};
        pl_mapClicked = true;
        hintSilent "";
        onMapSingleClick "";
    };

    player enableSimulation false;

    

    while {!pl_mapClicked} do {
        // sleep 0.1;
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
            _markerName setMarkerPos _mPos;
        };
        if (inputAction "MoveForward" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size + 5; sleep 0.05};
        if (inputAction "MoveBack" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size - 5; sleep 0.05};
        _markerName setMarkerSize [pl_mine_sweep_area_size, pl_mine_sweep_area_lane_width / 2];
        if (pl_mine_sweep_area_size >= 200) then {pl_mine_sweep_area_size = 200};
        if (pl_mine_sweep_area_size <= 20) then {pl_mine_sweep_area_size = 20};
    };

    // player enableSimulation true;
    pl_mapClicked = false;
    _cords = getMarkerPos _markerName;

    onMapSingleClick {
        pl_mapClicked = true;
        if (_shift) then {pl_cancel_strike = true};
        // if (_alt) then {pl_mine_type = "APERSBoundingMine"};
        onMapSingleClick "";
    };

    // player enableSimulation false;

    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _watchDir = _cords getdir _mPos;
        _markerName setMarkerDir (_watchDir + 90);
        if (inputAction "MoveForward" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size + 5; sleep 0.05};
        if (inputAction "MoveBack" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size - 5; sleep 0.05};
        _markerName setMarkerSize [pl_mine_sweep_area_size, pl_mine_sweep_area_lane_width / 2];
        if (pl_mine_sweep_area_size >= 200) then {pl_mine_sweep_area_size = 200};
        if (pl_mine_sweep_area_size <= 20) then {pl_mine_sweep_area_size = 20};

        _startPos = _cords getPos [pl_mine_sweep_area_size, _watchDir - 180];
        _markerNameLaunchPos setMarkerPos _startPos;
        _markerNameLaunchPos setMarkerDir _watchDir;
    };

    player enableSimulation true;

    pl_mapClicked = false;
    _markerName setMarkerAlpha 0.3;
    deleteMarker _markerBorderName;

    private _areaSize = pl_mine_sweep_area_size;
    private _laneWidth = pl_mine_sweep_area_lane_width;

    private _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa";

    _group setVariable ["pl_task_pos", _cords];
    _group setVariable ["specialIcon", _icon];

    if (count _taskPlanWp != 0) then {

        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        if (vehicle (leader _group) != leader _group) then {
            if !(_group getVariable ["pl_unload_task_planed", false]) then {
                waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false])};
            } else {
                waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
            };
        } else {
            waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 or !(_group getVariable ["pl_task_planed", false])};
        };
        _group setVariable ["pl_disembark_finished", nil];

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_unload_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; deleteMarker _markerNameLaunchPos; _group setVariable ["pl_is_task_selected", nil];};

    private _lanePath = [];
    private _markerFlags = [];

    _startPos = _cords getPos [_areaSize, _watchDir - 180];
    _endPos = _cords getPos [_areaSize, _watchDir];
    private _starPosLeft = _startPos getPos [_laneWidth / 2, _watchDir + 90];
    private _starPosRight = _startPos getPos [_laneWidth / 2, _watchDir - 90];

    for "_i" from 0 to (round ((_areaSize * 2) / 20)) do {

        _lp = _starPosLeft getPos [20 * _i, _watchDir];
        _rp = _starPosRight getPos [20 * _i, _watchDir];
        _pp = _startPos getPos [20 * _i, _watchDir];
        _lanePath pushBack _pp;

        _lf = createVehicle ["FlagMarker_01_F", _lp, [], 0, "CAN_COLLIDE"];
        _lf setDir ([0, 360] call BIS_fnc_randomInt);
        hideObject _lf;
        _rf = createVehicle ["FlagMarker_01_F", _rp, [], 0, "CAN_COLLIDE"];
        _rf setDir ([0, 360] call BIS_fnc_randomInt);
        hideObject _rf;

        _markerFlags pushBack _lf;
        _markerFlags pushBack _rf;
    };


    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"];

    private _watchPos = _cords getPos [500, _watchDir];
    _mines = allMines select {(getpos _x) inArea _markerName};
    _mines = _markerFlags + _mines; 
    _mines = ([_mines, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy);

    if !(_group getVariable ["onTask", false]) exitWith {deleteMarker _markerName; deleteMarker _markerNameLaunchPos};
    // _engVic setVehiclePosition [_startPos, [], 0, "CAN_COLLIDE"];
    _engVic animateSource ["MovePlow", 1];
    _engVic animateSource ["dozer_blade_elev_source", 1];

    [_engVic, _lanePath, 2] spawn pl_move_on_path;

    sleep 0.5;

    if !(_group getVariable ["onTask", false]) exitWith {deleteMarker _markerName};
    // waitUntil {sleep 0.1;!(_group getVariable ["onTask", false]) or (_engVic distance2D _startPos) > 6};

    private _i = 0;

    while {(count _mines) > 0 and (_engVic distance2D _endPos) >= 5 and (_group getVariable ["onTask", false]) and alive _engVic} do {

        {
            if (_x distance2D _engVic <= 15) then {

                if !(isObjectHidden _x) then {
                    _cm = createMarker [str (random 5), getPos _x];
                    _cm setMarkerType "mil_triangle";
                    _cm setMarkerSize [0.4, 0.4];
                    _cm setMarkerDir -180;
                    _cm setMarkerShadow false;
                    _cm setMarkerColor "colorGreen";
                    pl_engineering_markers pushBack _cm;

                    _engVic allowDamage false;
                    _x setDamage 1;

                } else {
                    _x hideObject false;
                };
                _mines deleteAt (_mines find _x);
            };
        } forEach _mines;

        sleep 0.05;
        _engVic allowDamage true;
    };

    // waitUntil {sleep 0.5; (count _mines) <= 0 or (_engVic distance2D _endPos) <= 5 or !(_group getVariable ["onTask", false])};

    deleteMarker _markerNameLaunchPos;

    if (_group getVariable ["onTask", true]) then {

        _engVic animateSource ["MovePlow", 0];
        _engVic animateSource ["dozer_blade_elev_source", 0];

        [_group] call pl_reset;

        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Mine Sweep complete", groupId _group]};
        if (pl_enable_map_radio) then {[_group, "...Mine Sweep Complete", 20] call pl_map_radio_callout};
        [_group] call pl_reset;
        _markerName setMarkerBrush "Cross";
        _markerName setMarkerColor "colorGreen";
        _markerName setMarkerText "CLR";
        pl_engineering_markers pushBack _markerName;

        _endPos = _startPos getPos [_areaSize * 2, _watchDir];

        _markerLeftPos1 = _startPos getPos [7, _watchDir + 90];
        _markerLeftPos2 = _markerLeftPos1 getPos [5, _watchDir - 45];
        _markerLeftPos4 = _endPos getPos [7, _watchDir + 90];
        _markerLeftPos3 = _markerLeftPos4 getpos [5, _watchDir - 135];

        _markerLeft = createMarker [str (random 3), [0,0,0]];
        _markerLeft setMarkerShape "POLYLINE";
        _markerLeft setMarkerPolyline [_markerLeftPos1#0, _markerLeftPos1#1, _markerLeftPos2#0, _markerLeftPos2#1, _markerLeftPos3#0, _markerLeftPos3#1, _markerLeftPos4#0, _markerLeftPos4#1];
        _markerLeft setMarkerColor "colorGreen";

        _markerRightPos1 = _startPos getPos [7, _watchDir - 90];
        _markerRightPos2 = _markerRightPos1 getPos [5, _watchDir + 45];
        _markerRightPos4 = _endPos getPos [7, _watchDir - 90];
        _markerRightPos3 = _markerRightPos4 getpos [5, _watchDir + 135];

        _markerRight = createMarker [str (random 3), [0,0,0]];
        _markerRight setMarkerShape "POLYLINE";
        _markerRight setMarkerPolyline [_markerRightPos1#0, _markerRightPos1#1, _markerRightPos2#0, _markerRightPos2#1, _markerRightPos3#0, _markerRightPos3#1, _markerRightPos4#0, _markerRightPos4#1];
        _markerRight setMarkerColor "colorGreen";

        // pl_engineering_markers pushBack _markerLeft;
        // pl_engineering_markers pushBack _markerRight;

        pl_deployed_bridges pushBack [_cords, [_startPos, _endPos]];

    } else {
        deleteMarker _markerName;  
    };
};

pl_mc_lc = {
    // _motor = "Land_RotorCoversBag_01_F" createVehicle [0,0,0];
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_cords", "_watchDir", "_mPos", "_launchPos", "_markerNameLaunchPos"];

    if (vehicle (leader _group) == (leader _group)) exitWith {hint "Vehicle Only Task!"};

    private _engVic = vehicle (leader _group);

    if ((!(_engVic isKindOf "Tank") or !(_engVic getVariable ["pl_is_repair_vehicle", false])) and !(_engVic getVariable ["pl_is_mc_lc_vehicle", false])) exitWith {hint "Requires Engineering Tank"};

    private _ammo = _engVic getVariable ["pl_line_charges", 0];

    if (_ammo <= 0) exitWith {hint "No Line Charges Left"};


    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader _group] call pl_open_tac_forced;
        };
    };

    _group setVariable ["pl_is_task_selected", true];

    private _markerName = format ["%1mineSweepe%2", _group, random 3];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "RECTANGLE";
    _markerName setMarkerBrush "SolidBorder";;
    _markerName setMarkerColor "colorGreen";
    _markerName setMarkerAlpha 0.5;
    _markerName setMarkerSize [40, 40 * 0.25];

    private _rangelimiter = 100;

    private _markerBorderName = str (random 2);
    private _borderMarkerPos = getPos (leader _group);
    if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
    createMarker [_markerBorderName, _borderMarkerPos];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorORANGE";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    _markerNameLaunchPos = format ["%1_mclc_launch%2", _group, random 3];
    createMarker [_markerNameLaunchPos, [0,0,0]];
    _markerNameLaunchPos setMarkerColor "colorGreen";
    _markerNameLaunchPos setMarkerType "mil_start";
    _markerNameLaunchPos setMarkerSize [0.5, 0.5];

    _message = "Select Search Area <br /><br />
    <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
    hint parseText _message;
    onMapSingleClick {
        pl_sweep_cords = _pos;
        if (_shift) then {pl_cancel_strike = true};
        pl_mapClicked = true;
        hintSilent "";
        onMapSingleClick "";
    };

    player enableSimulation false;

    while {!pl_mapClicked} do {
        // sleep 0.1;
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
            _markerName setMarkerPos _mPos;
        };
    };

    // player enableSimulation true;
    pl_mapClicked = false;
    _cords = getMarkerPos _markerName;

    onMapSingleClick {
        pl_mapClicked = true;
        if (_shift) then {pl_cancel_strike = true};
        // if (_alt) then {pl_mine_type = "APERSBoundingMine"};
        onMapSingleClick "";
    };

    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _watchDir = _cords getdir _mPos;
        _markerName setMarkerDir (_watchDir + 90);
        _launchPos = _cords getPos [50, _watchDir - 180];
        _markerNameLaunchPos setMarkerPos _launchPos;

    };

    player enableSimulation true;

    pl_mapClicked = false;
    _markerName setMarkerAlpha 0.3;
    deleteMarker _markerBorderName;

    if (pl_cancel_strike) exitwith {pl_cancel_strike = false; deleteMarker _markerName; deleteMarker _markerNameLaunchPos; _group setVariable ["pl_is_task_selected", nil];};

    private _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa";

    _group setVariable ["pl_task_pos", _cords];
    _group setVariable ["specialIcon", _icon];

    if (count _taskPlanWp != 0) then {

        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; deleteMarker _markerNameLaunchPos; _group setVariable ["pl_is_task_selected", nil];};

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"];


    [_engVic, _launchPos] call pl_vic_advance_to_pos_static;

    sleep 0.5;

    [_engVic, _cords] call pl_vic_turn_in_place;

    _time = time + 6;

    waitUntil {sleep 0.5; time >= _time or !alive _engVic or !(_group getVariable ["onTask", false])};

    deleteMarker _markerNameLaunchPos;
    if (!(_group getVariable ["onTask", false]) or !alive _engVic) exitWith {deleteMarker _markerName;};

    _motor = "Land_Sleeping_bag_folded_F" createVehicle [0,0,0];
    _motor attachTo [_engVic, [0,0,1]];
    _target = (getPos _engVic) getPos [300, getDir _engVic];

    _vel = [_engVic, _target, 60] call pl_THROW_VEL;

    detach _motor;
    _rope = ropeCreate [_engVic, [0,0,0], _motor, [0,0,0], 200];

    _motor setVelocity _vel;
    _smoke = "#particlesource" createVehicle [0,0,0];
    _smoke setParticleClass "missile1";
    _smoke attachTo [_motor,[0,0,0.5]];
    playSound3D ["A3\Sounds_F\weapons\Rockets\missile_1.wss", _engVic];

    [_group] call pl_reset;
    _ammo = _ammo - 1;

    _engVic setVariable ["pl_line_charges", _ammo];

    sleep 2;

    // eng_vic_1 ropeDetach _rope;
    deleteVehicle _smoke;

    sleep 5;

    _engVic allowDamage false;

    {
        _x allowDamage false;
    } forEach (units _group);

    while { ropeLength _rope > 20} do
    {
       _ends = ropeEndPosition _rope;
      if (((_ends select 1) distance2d _engVic) > 15) then {
          _charge = createMine ["SatchelCharge_F", _ends select 1, [], 0];
          _charge setDamage 1;
          [_ends select 1, 25] spawn pl_clear_obstacles;
      };
        ropeCut [_rope,ropeLength _rope-10];
        sleep 0.0002;
    };
    ropeDestroy _rope;
    deleteVehicle _motor;

    sleep 0.5;

    _engVic allowDamage true;
    {
        _x allowDamage true;
    } forEach (units _group);

    _markerName setMarkerBrush "Cross";
    _markerName setMarkerColor "colorGreen";
    _markerName setMarkerText "CLR";

    // _endPos = _launchPos getPos [80, _watchDir];

    // _markerLeftPos1 = _launchPos getPos [10, _watchDir + 90];
    // _markerLeftPos2 = _markerLeftPos1 getPos [5, _watchDir - 45];
    // _markerLeftPos4 = _endPos getPos [10, _watchDir + 90];
    // _markerLeftPos3 = _markerLeftPos4 getpos [5, _watchDir - 135];

    // _markerLeft = createMarker [str (random 3), [0,0,0]];
    // _markerLeft setMarkerShape "POLYLINE";
    // _markerLeft setMarkerPolyline [_markerLeftPos1#0, _markerLeftPos1#1, _markerLeftPos2#0, _markerLeftPos2#1, _markerLeftPos3#0, _markerLeftPos3#1, _markerLeftPos4#0, _markerLeftPos4#1];
    // _markerLeft setMarkerColor "colorGreen";

    // _markerRightPos1 = _launchPos getPos [10, _watchDir - 90];
    // _markerRightPos2 = _markerRightPos1 getPos [5, _watchDir + 45];
    // _markerRightPos4 = _endPos getPos [10, _watchDir - 90];
    // _markerRightPos3 = _markerRightPos4 getpos [5, _watchDir + 135];

    // _markerRight = createMarker [str (random 3), [0,0,0]];
    // _markerRight setMarkerShape "POLYLINE";
    // _markerRight setMarkerPolyline [_markerRightPos1#0, _markerRightPos1#1, _markerRightPos2#0, _markerRightPos2#1, _markerRightPos3#0, _markerRightPos3#1, _markerRightPos4#0, _markerRightPos4#1];
    // _markerRight setMarkerColor "colorGreen";

    //         // pl_engineering_markers pushBack _markerLeft;
    //         // pl_engineering_markers pushBack _markerRight;

    // pl_deployed_bridges pushBack [_cords, [_launchPos, _endPos]];
    pl_engineering_markers pushBack _markerName;
};


pl_lay_mine_field_switch = {
    params ["_mineType", ["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];

    if (vehicle (leader _group) != leader _group and ((vehicle (leader _group)) getVariable ["pl_is_mine_vic",false]) and !(_group getVariable ["pl_unload_task_planed", false])) then {
        [_mineType, _group, _taskPlanWp] spawn pl_lay_mine_field_vic;
    } else {
        [_mineType, _group, _taskPlanWp] spawn pl_lay_mine_field;
    };
};

pl_mine_field_size = 16;
pl_Mine_field_cords = [0,0,0];
pl_mine_spacing = 4;

pl_lay_mine_field = {
    params ["_mineTypeNum", ["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_mPos", "_group", "_exSpecialist", "_cords", "_areaMarker", "_watchDir", "_mineMarkers", "_neededMines", "_minePositions", "_usedMines", "_mineType", "_origPos", "_availableMines", "_text"];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry Only Task!"};


    _exSpecialist = {
        if (_x getUnitTrait "explosiveSpecialist" and alive _x and lifeState _x isNotEqualto "INCAPACITATED") exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _exSpecialist) exitWith {hint "No Explosive Specialist in Group!"};

    _availableMines = 0;
    {
        _mines = _x getVariable ["pl_virtual_mines", 0];
        _availableMines = _availableMines + _mines;
    } forEach (units _group);

    if (_availableMines <= 0) exitWith {hint "No Mines Left!"};

    _group setVariable ["pl_is_task_selected", true];

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader _group] call pl_open_tac_forced;
        };
    };

    switch (_mineTypeNum) do { 
        case 1 : {_mineType = "ATMine"}; 
        case 2 : {_mineType = "APERSBoundingMine"}; 
        default {_mineType = "ATMine"}; 
    };


    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: %2 Mines Available",groupId _group, _availableMines]};
    if (pl_enable_map_radio) then {[_group, format ["...%1 Mines Available",_availableMines], 15] call pl_map_radio_callout};

    hintSilent "";
    pl_mine_field_size = 16;
    _maxFieldSize = pl_mine_spacing * 20;
    _mineFieldSize = pl_mine_spacing * 2;

    _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br /> <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
    hint parseText _message;

    _areaMarker = format ["%1mineField%2", _group, random 2];
    createMarker [_areaMarker, [0,0,0]];
    _areaMarker setMarkerShape "RECTANGLE";
    // _areaMarker setMarkerBrush "Cross";
    _areaMarker setMarkerBrush "SolidBorder";
    _areaMarker setMarkerColor "colorGreen";
    _areaMarker setMarkerAlpha 0.8;
    _areaMarker setMarkerSize [pl_mine_field_size, 1];
    pl_engineering_markers pushBack _areaMarker;

    private _rangelimiter = 60;

    _markerBorderName = str (random 2);
    private _borderMarkerPos = getPos (leader _group);
    if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
    createMarker [_markerBorderName, _borderMarkerPos];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorOrange";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    onMapSingleClick {
        pl_Mine_field_cords = _pos;
        pl_mapClicked = true;
        if (_shift) then {pl_cancel_strike = true};
        hintSilent "";
        onMapSingleClick "";
    };

    player enableSimulation false;

    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _watchDir = getPos (leader _group) getDir _mPos;
        if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
            _areaMarker setMarkerPos _mPos;
            _areaMarker setMarkerDir _watchDir;
        };
        if (inputAction "MoveForward" > 0) then {pl_mine_field_size = pl_mine_field_size + _mineFieldSize; sleep 0.05};
        if (inputAction "MoveBack" > 0) then {pl_mine_field_size = pl_mine_field_size - _mineFieldSize; sleep 0.05};
        _areaMarker setMarkerSize [pl_mine_field_size, 4];
        if (pl_mine_field_size >= _maxFieldSize) then {pl_mine_field_size = _maxFieldSize};
        if (pl_mine_field_size <= _mineFieldSize) then {pl_mine_field_size = _mineFieldSize};
        _neededMines = pl_mine_field_size / (pl_mine_spacing / 2);
        if (_neededMines > _availableMines) then {
            pl_mine_field_size = pl_mine_field_size - 8;
            hint "Not enough Mines Left for larger Area";
        };
        sleep 0.01;
    };

    player enableSimulation true;

    pl_mapClicked = false;
    if (pl_cancel_strike) exitWith { 
        deleteMarker _areaMarker;
        deleteMarker _markerBorderName;
        pl_cancel_strike = false;
        _group setVariable ["pl_is_task_selected", nil];
    };
    _message = "Select Heading <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
                <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>APERS Mines</t> <br />
                <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
    hint parseText _message;

    sleep 0.1;
    _cords = getMarkerPos _areaMarker;

    deleteMarker _markerBorderName;

    onMapSingleClick {
        pl_mapClicked = true;
        onMapSingleClick "";
    };

    player enableSimulation false;

    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _watchDir = _cords getDir _mPos;
        _areaMarker setMarkerDir _watchDir;
        if (inputAction "MoveForward" > 0) then {pl_mine_field_size = pl_mine_field_size + _mineFieldSize; sleep 0.05};
        if (inputAction "MoveBack" > 0) then {pl_mine_field_size = pl_mine_field_size - _mineFieldSize; sleep 0.05};
        _areaMarker setMarkerSize [pl_mine_field_size, 4];
        if (pl_mine_field_size >= _maxFieldSize) then {pl_mine_field_size = _maxFieldSize};
        if (pl_mine_field_size <= _mineFieldSize) then {pl_mine_field_size = _mineFieldSize};
        _neededMines = pl_mine_field_size / (pl_mine_spacing / 2);
        if (_neededMines > _availableMines) then {
            pl_mine_field_size = pl_mine_field_size - 8;
            hint "Not enough Mines Left for larger Area";
        };
        sleep 0.01;
    };

    player enableSimulation true;

    _areaMarker setMarkerAlpha 0.5;
    hintSilent "";
    pl_mapClicked = false;

    if (pl_cancel_strike) exitWith { 
        deleteMarker _areaMarker; 
        pl_cancel_strike = false;
        _group setVariable ["pl_is_task_selected", nil];
    };

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa";

    _group setVariable ["pl_task_pos", _cords];
    _group setVariable ["specialIcon", _icon];

    if (count _taskPlanWp != 0) then {

        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        if (vehicle (leader _group) != leader _group) then {
            if !(_group getVariable ["pl_unload_task_planed", false]) then {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
            } else {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; ((_group getVariable ["pl_execute_plan", false]) and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
            };
        } else {
            waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) <= 15 or !(_group getVariable ["pl_task_planed", false])};
            // waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
        };
        _group setVariable ["pl_disembark_finished", nil];

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        if !(_group getVariable ["pl_multi_task_planed", false]) then {
            _group setVariable ["pl_task_planed", false];
            _group setVariable ["pl_unload_task_planed", false];
            _group setVariable ["pl_execute_plan", nil];
        };
    };

    if (pl_cancel_strike) exitWith { 
        deleteMarker _areaMarker; 
        pl_cancel_strike = false;
        _group setVariable ["pl_is_task_selected", nil];
    };


    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    
    _mineMarkers = [];
    _minePositions = [];
    _mineFieldSize = 0 + pl_mine_field_size;
    _neededMines = pl_mine_field_size / (pl_mine_spacing / 2);

    _mineTypeTxt = "AT";
    if (_mineType isEqualTo "APERSBoundingMine") then {_mineTypeTxt = "AP"};

    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Laying %2 %3 Mines with %4m Spacing",groupId _group, _neededMines, _mineTypeTxt, pl_mine_spacing]};
    if (pl_enable_map_radio) then {[_group, format ["...Laying %1 %2 Mines with %3m Spacing", _neededMines, _mineTypeTxt, pl_mine_spacing], 20] call pl_map_radio_callout};

    _usedMines = 0; 
    _offSet = pl_mine_field_size * 2;
    _startPos = [((_offSet / 2) - (pl_mine_spacing / 2)) *(sin (_watchDir - 90)), ((_offSet / 2) - (pl_mine_spacing / 2)) *(cos (_watchDir - 90)), 0] vectorAdd _cords;

    // debug
    // _m = createMarker [str (random 1), _startPos];
    // _m setMarkerType "mil_dot";

    for "_i" from 1 to _neededMines do {
        _offSet = _offSet - pl_mine_spacing;
        _mPos =  [_offSet *(sin (_watchDir + 90)), _offSet *(cos (_watchDir + 90)), 0] vectorAdd _startPos;
        _minePositions pushBack _mPos;
    };

    // private _escort = {
    //     if (_x != (leader _group) and _x != _exSpecialist and alive _x and lifeState _x isNotEqualto "INCAPACITATED") exitWith {_x};
    //     objNull
    // } forEach (units _group);
    _escort = objNull;

    {
        [_x, 0, getDir _x] spawn pl_find_cover;
    } forEach (units _group) - [_exSpecialist] - [_escort];

    _exSpecialist disableAI "AUTOCOMBAT";
    _exSpecialist disableAI "TARGET";
    _exSpecialist disableAI "AUTOTARGET";
    _escort disableAI "AUTOCOMBAT";
    _group setBehaviour "AWARE";
    {
        _x setVariable ["pl_is_at", true];
        _x setVariable ["pl_engaging", true];
        _x setUnitTrait ["camouflageCoef", 0.5, true];
        _x setVariable ["pl_damage_reduction", true];
        // doStop _x;
    } forEach [_exSpecialist, _escort];
    pl_at_attack_array pushBack [_exSpecialist, _cords, _escort];

    reverse _minePositions;

    waitUntil {sleep 0.5; unitReady _exSpecialist or !alive _exSpecialist};

    {
        _exSpecialist doMove _x;
        // _exSpecialist setDestination [_x, "LEADER PLANNED", true];
        _escort doFollow _exSpecialist;
        sleep 1;
        waitUntil {sleep 0.5; (!alive _exSpecialist) or (_exSpecialist distance2d _x) <= 3 or !(_group getVariable ["onTask", true])};

        if !(_group getVariable ["onTask", true] and alive _exSpecialist and !(_exSpecialist getVariable ["pl_wia", false])) exitWith {};

        _exSpecialist setUnitPos "Middle";
        sleep 0.5;
        _exSpecialist playAction "PutDown";
        // sleep 2.5;
        _time = time + 4;
        waitUntil {sleep 0.5; time >= _time or (!alive _exSpecialist) or !(_group getVariable ["onTask", true])};
        _mine = createMine [_mineType, _x, [], 0];
        _mine setDir _watchDir;
        _usedMines = _usedMines + 1;
        _exSpecialist setUnitPos "Auto";

        _cm = createMarker [str (random 3), getPos _mine];
        _cm setMarkerType "mil_dot";
        _cm setMarkerSize [0.4, 0.4];
        _cm setMarkerColor "colorGreen";
        _cm setMarkerShadow false;
        pl_engineering_markers pushBack _cm;

    } forEach _minePositions;

    if (_usedMines <= 0) exitWith {deleteMarker _areaMarker};


    for "_i" from 1 to _usedMines do {
        {
            _unitsMines = _x getVariable ["pl_virtual_mines", 0];
            if (_unitsMines > 0) exitWith {
                _x setVariable ["pl_virtual_mines", _unitsMines - 1];
            };
        } forEach (units _group);
    };

    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
    };

    pl_at_attack_array = pl_at_attack_array - [[_exSpecialist, _cords, _escort]];
};

pl_lay_mine_field_vic = {
    params [["_mineTypeNum", 1], ["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_mPos", "_group", "_cords", "_areaMarker", "_watchDir", "_mineMarkers", "_neededMines", "_minePositions", "_usedMines", "_mineType", "_origPos", "_availableMines", "_text", "_startPos", "_endPos"];

    if (vehicle (leader _group) == leader _group) exitWith {hint "Vehicle Only Task!"};

    private _engVic = vehicle (leader _group);

    if !(_engVic getVariable ["pl_is_mine_vic",false]) exitWith {hint "Requires Egineering Vehicle"};

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader _group] call pl_open_tac_forced;
        };
    };;

    _availableMines = _engVic getVariable ["pl_virtual_mines", 0];

    if (_availableMines <= 0) exitWith {hint "No Mines Left!"};

    _group setVariable ["pl_is_task_selected", true];

    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: %2 Mines Available",groupId _group, _availableMines]};
    if (pl_enable_map_radio) then {[_group, format ["...%1 Mines Available",_availableMines], 15] call pl_map_radio_callout};

    hintSilent "";
    pl_mine_field_size = 16;
    _maxFieldSize = pl_mine_spacing * 40;
    _mineFieldSize = pl_mine_spacing * 2;

    switch (_mineTypeNum) do { 
        case 1 : {_mineType = "ATMine"}; 
        case 2 : {_mineType = "APERSBoundingMine"}; 
        default {_mineType = "ATMine"}; 
    };


    _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br /> <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
    hint parseText _message;

    _areaMarker = format ["%1mineField%2", _group, random 2];
    createMarker [_areaMarker, [0,0,0]];
    _areaMarker setMarkerShape "RECTANGLE";
    // _areaMarker setMarkerBrush "Cross";
    _areaMarker setMarkerBrush "SolidBorder";
    _areaMarker setMarkerColor "colorGreen";
    _areaMarker setMarkerAlpha 0.8;
    _areaMarker setMarkerSize [pl_mine_field_size, 1];
    pl_engineering_markers pushBack _areaMarker;

    private _rangelimiter = 60;

    _markerBorderName = str (random 2);
    private _borderMarkerPos = getPos (leader _group);
    if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
    createMarker [_markerBorderName, _borderMarkerPos];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorOrange";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    onMapSingleClick {
        pl_Mine_field_cords = _pos;
        pl_mapClicked = true;
        if (_shift) then {pl_cancel_strike = true};
        hintSilent "";
        onMapSingleClick "";
    };

    player enableSimulation false;

    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _watchDir = getPos (leader _group) getDir _mPos;
        if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
            _areaMarker setMarkerPos _mPos;
            _areaMarker setMarkerDir _watchDir;
        };
        if (inputAction "MoveForward" > 0) then {pl_mine_field_size = pl_mine_field_size + _mineFieldSize; sleep 0.05};
        if (inputAction "MoveBack" > 0) then {pl_mine_field_size = pl_mine_field_size - _mineFieldSize; sleep 0.05};
        _areaMarker setMarkerSize [pl_mine_field_size, 4];
        if (pl_mine_field_size >= _maxFieldSize) then {pl_mine_field_size = _maxFieldSize};
        if (pl_mine_field_size <= _mineFieldSize) then {pl_mine_field_size = _mineFieldSize};
        _neededMines = pl_mine_field_size / (pl_mine_spacing / 2);
        if (_neededMines > _availableMines) then {
            pl_mine_field_size = pl_mine_field_size - 8;
            hintSilent "Not enough Mines Left for larger Area";
        };
        sleep 0.01;
    };

    player enableSimulation true;

    pl_mapClicked = false;
    if (pl_cancel_strike) exitWith { 
        deleteMarker _areaMarker;
        deleteMarker _markerBorderName;
        pl_cancel_strike = false;
        _group setVariable ["pl_is_task_selected", nil];
    };
    _message = "Select Heading <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
                <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>APERS Mines</t> <br />
                <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
    hint parseText _message;

    sleep 0.1;
    _cords = getMarkerPos _areaMarker;

    deleteMarker _markerBorderName;

    onMapSingleClick {
        pl_mapClicked = true;
        onMapSingleClick "";
    };

    player enableSimulation false;

    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _watchDir = _cords getDir _mPos;
        _areaMarker setMarkerDir _watchDir;
        if (inputAction "MoveForward" > 0) then {pl_mine_field_size = pl_mine_field_size + _mineFieldSize; sleep 0.05};
        if (inputAction "MoveBack" > 0) then {pl_mine_field_size = pl_mine_field_size - _mineFieldSize; sleep 0.05};
        _areaMarker setMarkerSize [pl_mine_field_size, 4];
        if (pl_mine_field_size >= _maxFieldSize) then {pl_mine_field_size = _maxFieldSize};
        if (pl_mine_field_size <= _mineFieldSize) then {pl_mine_field_size = _mineFieldSize};
        _neededMines = pl_mine_field_size / (pl_mine_spacing / 2);
        if (_neededMines > _availableMines) then {
            pl_mine_field_size = pl_mine_field_size - 8;
            hint "Not enough Mines Left for larger Area";
        };
        sleep 0.01;
    };

    player enableSimulation true;

    _areaMarker setMarkerAlpha 0.5;
    hintSilent "";
    pl_mapClicked = false;

    if (pl_cancel_strike) exitWith { 
        deleteMarker _areaMarker; 
        pl_cancel_strike = false;
        _group setVariable ["pl_is_task_selected", nil];
    };

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa";

    _group setVariable ["pl_task_pos", _cords];
    _group setVariable ["specialIcon", _icon];

    if (count _taskPlanWp != 0) then {

        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];
    };

    if (pl_cancel_strike) exitWith { 
        deleteMarker _areaMarker; 
        pl_cancel_strike = false;
    };


    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    
    _mineMarkers = [];
    _minePositions = [];
    _mineFieldSize = pl_mine_field_size;
    _neededMines = pl_mine_field_size / (pl_mine_spacing / 2);
    private _mineSpacing = pl_mine_spacing;

    _mineTypeTxt = "AT";
    if (_mineType isEqualTo "APERSBoundingMine") then {_mineTypeTxt = "AP"};

    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Laying %2 %3 Mines with %4m Spacing",groupId _group, _neededMines, _mineTypeTxt, pl_mine_spacing]};
    if (pl_enable_map_radio) then {[_group, format ["...Laying %1 %2 Mines with %3m Spacing", _neededMines, _mineTypeTxt, pl_mine_spacing], 20] call pl_map_radio_callout};

    _usedMines = 0; 
    _offSet = pl_mine_field_size * 2;
    _startPos = [((_offSet / 2) - (pl_mine_spacing / 2)) *(sin (_watchDir - 90)), ((_offSet / 2) - (pl_mine_spacing / 2)) *(cos (_watchDir - 90)), 0] vectorAdd _cords;

    for "_i" from 1 to _neededMines do {
        _offSet = _offSet - pl_mine_spacing;
        _mPos =  [_offSet *(sin (_watchDir + 90)), _offSet *(cos (_watchDir + 90)), 0] vectorAdd _startPos;
        _minePositions pushBack _mPos;
    };

    // _minePositions = [_minePositions, [], {_x distance2D _engVic}, "ASCEND"] call BIS_fnc_sortBy;

    _pos1 = _minePositions#0;
    _pos2 = _minePositions#(_neededMines - 1);

    if ((_pos1 distance2D _engVic) < (_pos2 distance2D _engVic)) then {
        _startPos = _pos1;
        _endPos = _pos2 getPos [15, _pos1 getDir _pos2];
    } else {
        _startPos = _pos2;
        _endPos = _pos1 getPos [15, _pos2 getDir _pos1];
        reverse _minePositions;
    };

    [_engVic, _startPos, 6] call pl_vic_advance_to_pos_static;

    sleep 0.25;

    if !(_group getVariable ["onTask", false]) exitWith {deleteMarker _areaMarker};

    [_engVic, _endPos, 3] spawn pl_vic_advance_to_pos_static;

    sleep 0.5;

    if !(_group getVariable ["onTask", false]) exitWith {deleteMarker _areaMarker};
    // waitUntil {sleep 0.1;!(_group getVariable ["onTask", false]) or (_engVic distance2D _startPos) > 6};

    private _i = 0;

    while {(_group getVariable ["pl_on_march", false]) and (_group getVariable ["onTask", false]) and alive _engVic} do {

        if (_i > (count _minePositions) - 1) exitWith {};

        _distance = _startPos distance2D _engVic;
        if ((round (_distance % _mineSpacing)) == 0) then {

            [_minePositions#_i, _mineType, _engVic, _watchDir] spawn {
                params ["_minePos", "_mineType", "_engVic", "_watchDir"];

                waitUntil {sleep 0.25; _engVic distance2D _minePos > 6};
                _mine = createMine [_mineType, _minePos, [], 0];
                _mine setDir _watchDir;

                _cm = createMarker [str (random 3), getPos _mine];
                _cm setMarkerType "mil_dot";
                _cm setMarkerSize [0.4, 0.4];
                _cm setMarkerColor "colorGreen";
                _cm setMarkerShadow false;
                pl_engineering_markers pushBack _cm;
            };

            _availableMines = _engVic getVariable ["pl_virtual_mines", 0];
            _engVic setVariable ["pl_virtual_mines", _availableMines - 1];
            _i = _i + 1;
            waitUntil {sleep 0.01; (round (_engVic distance2D _startPos)) % _mineSpacing != 0};
        };

        sleep 0.05;
    };

    

    waitUntil {sleep 0.5; !(_group getVariable ["pl_on_march", false]) or !(_group getVariable ["onTask", false])};

    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
    };
};

pl_place_dir_mine = {
    params ["_mineType", ["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_mineDir","_mPos", "_cords", "_exSpecialist", "_availableMines", "_markerName", "_markerBorderName", "_rangelimiter"];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry Only Task!"};

    if ((_group getVariable ["pl_in_position", false]) and _mineType != 2) exitWith {hint "Group only has APERS Mines Available"};

    if (_group getVariable ["pl_in_position", false]) then {
        _exSpecialist = {
            if (_x != (leader _group) and secondaryWeapon _x == "") exitWith {_x};
            objNull
        } forEach (units _group);
    } else {
        _exSpecialist = {
            if (_x getUnitTrait "explosiveSpecialist" and ((_x getVariable ["pl_virtual_mines", 0]) > 0) and alive _x and lifeState _x isNotEqualto "INCAPACITATED") exitWith {_x};
            objNull
        } forEach (units _group);
    };

    if (isNull _exSpecialist) exitWith {hint "No Explosive Specialist in Group!"};

    if (_group getVariable ["pl_in_position", false]) then {
        _availableMines = _group getVariable ["pl_virtual_mines", 0];
    } else {
        _availableMines = _exSpecialist getVariable ["pl_virtual_mines", 0];
    };

    if (_availableMines <= 0) exitWith {hint "No Mines Available"};

    _group setVariable ["pl_is_task_selected", true];

    _markerName = "";

    if (visibleMap or !(isNull findDisplay 2000)) then {
        hintSilent "";
        hint "Select MINE position on MAP (SHIFT + LMB to cancel)";

        private _markerType = "marker_ap_dir_mine";
        if (_mineType == 1) then {_markerType = "marker_at_dir_mine"};

        _markerName = createMarker [str (random 5), [0,0,0]];
        _markerName setMarkerType _markerType;
        _markerName setMarkerColor "colorGreen";
        _markerName setMarkerSize [0.4, 0.4];

        player enableSimulation false;

        onMapSingleClick {
            pl_mine_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        private _rangeLimiterPos = getpos (leader _group);
        if (_taskPlanWp isNotEqualto []) then {
            _rangeLimiterPos = waypointPosition _taskPlanWp;
        };

        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            if (_mPos distance2D _rangeLimiterPos <= 150) then {
                _markerName setMarkerPos _mPos;
            };
        };

        player enableSimulation true;

        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {
            pl_show_obstacles = false;
            pl_mapClicked = false;
        };

        _cords = getMarkerPos _markerName;
        pl_show_obstacles = false;
        pl_mapClicked = false;

        onMapSingleClick {
            pl_mine_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        player enableSimulation false;

        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            
            _mineDir = _cords getDir _mPos;
            _markerName setmarkerDir _mineDir;
            
        };

        player enableSimulation true;

        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {
            pl_mapClicked = false;
        };

    }
    else
    {
        waitUntil {sleep 0.1; inputAction "Action" <= 0};

        _cursorPosIndicator = createVehicle ["Sign_Arrow_Large_Yellow_F", getPos player, [], 0, "none"];

        systemChat str (getPos _cursorPosIndicator);

        _leader = leader _group;
        pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

        while {inputAction "Action" <= 0} do {
            _viewDistance = _cursorPosIndicator distance2D player;

            _cursorPosIndicator setPosATL ([0,0,_viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
            _cursorPosIndicator setObjectScale (_viewDistance * 0.05);

            if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

            sleep 0.025
        };

        if (pl_cancel_strike) exitWith {deleteVehicle _cursorPosIndicator; pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]]};

        _cords = getPosATL _cursorPosIndicator;

        pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

        deleteVehicle _cursorPosIndicator;

    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; _group setVariable ["pl_is_task_selected", nil];};
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa";

    _group setVariable ["pl_task_pos", _cords];
    _group setVariable ["specialIcon", _icon];
    
    if (count _taskPlanWp != 0) then {

        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        if (vehicle (leader _group) != leader _group) then {
            if !(_group getVariable ["pl_unload_task_planed", false]) then {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
            } else {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; ((_group getVariable ["pl_execute_plan", false]) and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
            };
        } else {
            waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) <= 15 or !(_group getVariable ["pl_task_planed", false])};
            // waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
        };
        _group setVariable ["pl_disembark_finished", nil];

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        if !(_group getVariable ["pl_multi_task_planed", false]) then {
            _group setVariable ["pl_task_planed", false];
            _group setVariable ["pl_unload_task_planed", false];
            _group setVariable ["pl_execute_plan", nil];
        };
    };

    if (pl_cancel_strike) exitWith {deleteMarker _markerName; pl_cancel_strike = false; _group setVariable ["pl_is_task_selected", nil];};

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;

    if !(_group getVariable ["pl_in_position", false]) then {
        [_group] call pl_reset;

        sleep 0.5;

        [_group] call pl_reset;

        sleep 0.5;

        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", _icon];
    };

    // private _escort = {
    //     if (_x != (leader _group) and _x != _exSpecialist and alive _x and lifeState _x isNotEqualto "INCAPACITATED") exitWith {_x};
    //     objNull
    // } forEach (units _group);
    _escort = objNull;

    if !(_group getVariable ["pl_in_position", false]) then {
        {
            [_x, 0, getDir _x] spawn pl_find_cover;
        } forEach (units _group) - [_exSpecialist] - [_escort];
    };

    _exSpecialist enableAI "PATH";
    _exSpecialist setUnitPos "AUTO";
    _exSpecialist disableAI "AUTOCOMBAT";
    _exSpecialist disableAI "TARGET";
    _exSpecialist disableAI "AUTOTARGET";
    _exSpecialist disableAI "SUPPRESSION";
    _escort disableAI "AUTOCOMBAT";
    _group setBehaviourStrong "AWARE";
    {
        _x setVariable ["pl_is_at", true];
        _x setVariable ["pl_engaging", true];
        _x setUnitTrait ["camouflageCoef", 0.5, true];
        _x setVariable ["pl_damage_reduction", true];
        _x setUnitPosWeak "MIDDLE";
        // doStop _x;
    } forEach [_exSpecialist, _escort];
    pl_at_attack_array pushBack [_exSpecialist, _cords, _escort];

    // waitUntil {sleep 0.5; unitReady _exSpecialist or !alive _exSpecialist};

    _exSpecialist doMove _cords;
    _exSpecialist setDestination [_cords, "LEADER PLANNED", true];
    _escort doFollow _exSpecialist;

    sleep 1;
    waitUntil {sleep 0.5; (!alive _exSpecialist) or (_exSpecialist distance2D _cords) <= 6 or !(_group getVariable ["onTask", true])};

    _charges = _group getVariable ["pl_placed_charges", []];
    if (_group getVariable ["onTask", true] and alive _exSpecialist and !(_exSpecialist getVariable ["pl_wia", false])) then {
        // doStop _exSpecialist;
        // doStop _escort;
        _exSpecialist disableAI "PATH";
        _escort disableAI "PATH";
        _exSpecialist setUnitPos "Middle";
        _exSpecialist playAction "PutDown";
        sleep 3;
        
        if (alive _exSpecialist) then {

            switch (_mineType) do { 
                case 1 : {
                    [_cords, _mineDir] spawn pl_directional_at_mine;
                }; //AT
                case 2 : {
                    [_cords, _mineDir] spawn pl_directional_ap_mine;
                }; //APERS
                case 3 : {
                    private _mine = createMine ["APERSMineDispenser_F", _cords, [], 0];
                    _mine setDir _mineDir;


                    private _areaMarker = createMarker [str (random 5), _cords getPos [17, _mineDir]];
                    _areaMarker setMarkerShape "RECTANGLE";
                    // _areaMarker setMarkerBrush "Cross";
                    _areaMarker setMarkerBrush "SolidBorder";
                    _areaMarker setMarkerColor "colorYellow";
                    _areaMarker setMarkerAlpha 0.8;
                    _areaMarker setMarkerSize [17, 17];
                    _areaMarker setMarkerDir _mineDir;
                    pl_engineering_markers pushBack _areaMarker;

                    private _mStartPos = (_cords getPos [17, _mineDir]) getPos [14, _mineDir - 90];
                    for "_i" from 0 to 2 do {
                        _m = createMarker [str (random 5), _mStartPos getpos [14 * _i, _mineDir + 90]];
                        _m setMarkerType "marker_ap_dir_mine";
                        _m setMarkerColor "colorGreen";
                        _m setMarkerSize [0.3, 0.3];
                        _m setMarkerDir _mineDir;
                        pl_engineering_markers pushBack _m;
                    };


                    [_exSpecialist, _mine, _areaMarker] spawn {
                        params ["_exSpecialist", "_mine", "_areaMarker"];

                        _exSpecialist addOwnedMine _mine;

                        sleep 8;

                        waitUntil {sleep 1; {side _x == playerside} count ((getPos _mine) nearEntities [["Man"], 20]) <= 0};

                        _areaMarker setMarkerColor "colorGreen";
                        _exSpecialist action ["TouchOff", _exSpecialist];
                    };
                }; //APERS dispenser
                default {}; 
            };
            

            _exSpecialist setUnitPos "Auto";
            _exSpecialist enableAI "AUTOCOMBAT";
            _exSpecialist setVariable ["pl_virtual_mines", (_exSpecialist getVariable "pl_virtual_mines") - 1];
        };
    };


    pl_at_attack_array = pl_at_attack_array - [[_exSpecialist, _cords, _escort]];
    deleteMarker _markerName;
    if (_group getVariable ["onTask", true] and !(_group getVariable ["pl_in_position", false])) then {
        [_group] call pl_reset;
    };

    if (_group getVariable ["pl_in_position", false]) then {
        [_exSpecialist] spawn pl_move_back_to_def_pos;
        _exSpecialist setVariable ["pl_is_at", false];
    };

    
};

pl_groups_with_charges = [];

pl_place_charge = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_mPos", "_cords", "_exSpecialist", "_availableMines", "_markerName", "_markerBorderName", "_rangelimiter"];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry Only Task!"};

    _exSpecialist = {
        if (_x getUnitTrait "explosiveSpecialist" and ((_x getVariable ["pl_virtual_mines", 0]) > 0)) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _exSpecialist) exitWith {hint "No Explosive Specialist in Group!"};

    _availableMines = _exSpecialist getVariable ["pl_virtual_mines", 0];

    _group setVariable ["pl_is_task_selected", true];

    _markerName = "";

    if (visibleMap or !(isNull findDisplay 2000)) then {
        hintSilent "";
        hint "Select MINE position on MAP (SHIFT + LMB to cancel)";
        pl_show_obstacles = true;
        pl_show_obstacles_pos = getPos (leader _group);

        _markerName = createMarker ["pl_charge_range_marker", [0,0,0]];
        _markerName setMarkerColor "colorOrange";
        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "Border";
        _markerName setMarkerSize [25, 25];

        _rangelimiter = 60;

        _markerBorderName = str (random 2);
        private _borderMarkerPos = getPos (leader _group);
        if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
        createMarker [_markerBorderName, _borderMarkerPos];
        _markerBorderName setMarkerShape "ELLIPSE";
        _markerBorderName setMarkerBrush "Border";
        _markerBorderName setMarkerColor "colorOrange";
        _markerBorderName setMarkerAlpha 0.8;
        _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

        onMapSingleClick {
            pl_mine_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
                _markerName setMarkerPos _mPos;
            };
        };
        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {
            pl_show_obstacles = false;
            pl_mapClicked = false;
        };

        _cords = getMarkerPos _markerName;
        deleteMarker _markerBorderName;
        pl_show_obstacles = false;
        pl_mapClicked = false;
    }
    else
    {
        waitUntil {sleep 0.1; inputAction "Action" <= 0};

        _cursorPosIndicator = createVehicle ["Sign_Arrow_Large_Yellow_F", getPos player, [], 0, "none"];

        systemChat str (getPos _cursorPosIndicator);

        _leader = leader _group;
        pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

        while {inputAction "Action" <= 0} do {
            _viewDistance = _cursorPosIndicator distance2D player;

            _cursorPosIndicator setPosATL ([0,0,_viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
            _cursorPosIndicator setObjectScale (_viewDistance * 0.05);

            if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

            sleep 0.025
        };

        if (pl_cancel_strike) exitWith {deleteVehicle _cursorPosIndicator; pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]]};

        _cords = getPosATL _cursorPosIndicator;

        pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

        deleteVehicle _cursorPosIndicator;

    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; deleteMarker _markerBorderName; _group setVariable ["pl_is_task_selected", nil];};
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa";

    _group setVariable ["pl_task_pos", _cords];
    _group setVariable ["specialIcon", _icon];
    
    if (count _taskPlanWp != 0) then {

        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        if (vehicle (leader _group) != leader _group) then {
            if !(_group getVariable ["pl_unload_task_planed", false]) then {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
            } else {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; ((_group getVariable ["pl_execute_plan", false]) and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
            };
        } else {
            waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) <= 15 or !(_group getVariable ["pl_task_planed", false])};
            // waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
        };
        _group setVariable ["pl_disembark_finished", nil];

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        if !(_group getVariable ["pl_multi_task_planed", false]) then {
            _group setVariable ["pl_task_planed", false];
            _group setVariable ["pl_unload_task_planed", false];
            _group setVariable ["pl_execute_plan", nil];
        };
    };

    if (pl_cancel_strike) exitWith {deleteMarker _markerName; pl_cancel_strike = false; _group setVariable ["pl_is_task_selected", nil];};

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    // private _escort = {
    //     if (_x != (leader _group) and _x != _exSpecialist) exitWith {_x};
    //     objNull
    // } forEach (units _group);
    _escort = objNull;

    {
        [_x, 0, getDir _x] spawn pl_find_cover;
    } forEach (units _group) - [_exSpecialist] - [_escort];

    _exSpecialist disableAI "AUTOCOMBAT";
    _exSpecialist disableAI "TARGET";
    _exSpecialist disableAI "AUTOTARGET";
    _escort disableAI "AUTOCOMBAT";
    _group setBehaviour "AWARE";
    {
        _x setVariable ["pl_is_at", true];
        _x setVariable ["pl_engaging", true];
        _x setUnitTrait ["camouflageCoef", 0.5, true];
        _x setVariable ["pl_damage_reduction", true];
        _x setUnitPosWeak "MIDDLE";
        // doStop _x;
    } forEach [_exSpecialist, _escort];
    pl_at_attack_array pushBack [_exSpecialist, _cords, _escort];

    // waitUntil {sleep 0.5; unitReady _exSpecialist or !alive _exSpecialist};
    sleep 1;

    _exSpecialist doMove _cords;
    _exSpecialist setDestination [_cords, "LEADER PLANNED", true];
    _escort doFollow _exSpecialist;

    sleep 1;
    waitUntil {sleep 0.5; (!alive _exSpecialist) or (_exSpecialist distance2d _cords) <= 5 or !(_group getVariable ["onTask", true])};
    // waitUntil {sleep 0.5; (!alive _exSpecialist) or unitReady _exSpecialist or !(_group getVariable ["onTask", true])};

    _charges = _group getVariable ["pl_placed_charges", []];
    if (_group getVariable ["onTask", true] and alive _exSpecialist and !(_exSpecialist getVariable ["pl_wia", false])) then {
        _exSpecialist setUnitPos "Middle";
        _exSpecialist playAction "PutDown";
        _exSpecialist disableAI "PATH";
        _escort disableAI "PATH";
        sleep 3;
        _charge = createMine ["DemoCharge_F", _cords, [], 0];
        _charges pushBack _charge;
        _exSpecialist setUnitPos "Auto";
        _exSpecialist enableAI "AUTOCOMBAT";
        _exSpecialist enableAI "PATH";
        _escort enableAI "PATH";
        _exSpecialist setVariable ["pl_virtual_mines", (_exSpecialist getVariable "pl_virtual_mines") - 1];
        _group setVariable ["pl_placed_charges", _charges];
        pl_groups_with_charges pushBackUnique _group;
    };

    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
    };
    pl_at_attack_array = pl_at_attack_array - [[_exSpecialist, _cords, _escort]];
    deleteMarker _markerName;

};

pl_detonate_charges = {
    params ["_group"];

    _charges = _group getVariable ["pl_placed_charges", []];

    if (_charges isEqualTo []) exitWith {hint "Group has no placed Charges"};
    if (pl_enable_beep_sound) then {playSound "beep"};

    {
        _charge = _x;
        // remove Vehicle wrec
        {
            if (!(canMove _x) or ({alive _x} count (crew _x)) <= 0) then {
                [_x] spawn {
                    params ["_vic"];
                    _vic setDamage 1;
                    sleep 5;
                    deleteVehicle _vic;
                };
            };
        } forEach (vehicles select {(_x distance2D _charge) < 25});
        {
             deleteVehicle _x;
        } forEach (allDead select {(_x distance2D _charge) < 25});
        // remove Fences
        {
            deleteVehicle _x;
            _x setDamage 1;
        } forEach (((getPos _charge) nearObjects 25) select {["fence", typeOf _x] call BIS_fnc_inString or ["barrier", typeOf _x] call BIS_fnc_inString or ["wall", typeOf _x] call BIS_fnc_inString or ["sand", typeOf _x] call BIS_fnc_inString});
        // remove Bunkers
        {
            deleteVehicle _x;;
        } forEach (((getPos _charge) nearObjects 25) select {["bunker", typeOf _x] call BIS_fnc_inString});
        // remove wire
        {
            deleteVehicle _x;
        } forEach (((getPos _charge) nearObjects 25) select {["wire", typeOf _x] call BIS_fnc_inString});
        // kill trees
        [_charge] spawn {
            params ["_charge"];
            {
                _x setDamage 1;
                sleep 0.1;
            } forEach (nearestTerrainObjects [getPos _charge, ["TREE", "SMALL TREE", "BUSH"], 20, false, true]);
        };

        _charge setDamage 1;
        sleep 0.25;
    } forEach _charges;

    _group setVariable ["pl_placed_charges", nil];
    pl_groups_with_charges = pl_groups_with_charges - [_group];
};


pl_destroy_bridge = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_mPos", "_cords", "_exSpecialist", "_bridges", "_bridgeMarkers", "_wp", "_charge"];

    _exSpecialist = {
        if (_x getUnitTrait "explosiveSpecialist" and ((_x getVariable ["pl_virtual_mines", 0]) > 0)) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _exSpecialist) exitWith {hint format ["%1 has no Engineer!", groupId _group]};

    _group setVariable ["pl_is_task_selected", true];

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader _group] call pl_open_tac_forced;
        };
    };

    _markerName = createMarker ["pl_charge_range_marker2", [0,0,0]];
    _markerName setMarkerColor "colorOrange";
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Border";
    _markerName setMarkerSize [30, 30];

    private _rangelimiter = 60;

    private _markerBorderName = str (random 2);
    private _borderMarkerPos = getPos (leader _group);
    if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
    createMarker [_markerBorderName, _borderMarkerPos];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorOrange";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    hint "Select on MAP";
    onMapSingleClick {
        pl_repair_cords = _pos;
        pl_mapClicked = true;
        if (_shift) then {pl_cancel_strike = true};
        hint "";
        onMapSingleClick "";
    };

    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
            _markerName setMarkerPos _mPos;
        };
    };

    pl_mapClicked = false;
    _cords = getMarkerPos _markerName;
    deleteMarker _markerName;
    deleteMarker _markerBorderName;

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; _group setVariable ["pl_is_task_selected", nil];};

    _roads = _cords nearRoads 30;
    _bridges = [];
    _bridgeMarkers = [];

    {
        _info = getRoadInfo _x;
        if (_info#8) then {
            if ((getDammage _x) < 1) then {
                _bridges pushBackUnique _x;
            };
        };
    } forEach _roads;

    if ((count _bridges) <= 0) exitWith {hint format ["No Bridges in Area", groupId _group]};

    _group setVariable ["pl_task_pos", _cords];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"];

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa";
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    private _escort = {
        if (_x != (leader _group) and _x != _exSpecialist) exitWith {_x};
        objNull
    } forEach (units _group);

    {
        [_x, 15, getDir _x] spawn pl_find_cover;
    } forEach (units _group) - [_exSpecialist] - [_escort];

    _exSpecialist disableAI "AUTOCOMBAT";
    _exSpecialist disableAI "TARGET";
    _exSpecialist disableAI "AUTOTARGET";
    _escort disableAI "AUTOCOMBAT";
    _group setBehaviour "AWARE";
    {
        _x setVariable ["pl_is_at", true];
        _x setVariable ["pl_engaging", true];
        _x setUnitTrait ["camouflageCoef", 0.5, true];
        _x setVariable ["pl_damage_reduction", true];
        _x setUnitPosWeak "MIDDLE";
    } forEach [_exSpecialist, _escort];
    pl_at_attack_array pushBack [_exSpecialist, _cords, _escort];

    _roads = _roads - _bridges;
    _movePos = getPos (([_roads, [], {_exSpecialist distance _x }, "ASCEND"] call BIS_fnc_sortBy)#0);
    _exSpecialist doMove _movePos;
    _escort doFollow _exSpecialist;

    sleep 1;
    waitUntil {sleep 0.5; (!alive _exSpecialist) or (unitReady _exSpecialist) or !(_group getVariable ["onTask", true])};

    sleep 5;

    _charges = _group getVariable ["pl_placed_charges", []];
    if (_group getVariable ["onTask", true] and alive _exSpecialist and !(_exSpecialist getVariable ["pl_wia", false])) then {
        _exSpecialist setUnitPos "Middle";
        _exSpecialist playAction "PutDown";
        sleep 3;
        _bPos = getPosATL (_bridges#0);
        _charge = createMine ["SatchelCharge_F", ASLToATL _bPos, [], 0];
        _charges pushBack _charge;
        _exSpecialist setUnitPos "Auto";
        _exSpecialist enableAI "AUTOCOMBAT";
        _exSpecialist setVariable ["pl_virtual_mines", (_exSpecialist getVariable "pl_virtual_mines") - 1];
        _group setVariable ["pl_placed_charges", _charges];
        pl_groups_with_charges pushBackUnique _group;

        sleep 2;
        [_group] call pl_reset;
        pl_at_attack_array = pl_at_attack_array - [[_exSpecialist, _cords, _escort]];
    };

    sleep 15;

    _charge setDamage 1;
    pl_groups_with_charges = pl_groups_with_charges - [_group];

    {
        _x setDamage 1;
    } forEach _bridges;

    if (pl_enable_beep_sound) then {playSound "radioina"};
    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Bridge Destroyed", (groupId _group)]};
    if (pl_enable_map_radio) then {[_group, "...Bridge Destroyed", 20] call pl_map_radio_callout};
};

pl_marked_mines = [];

pl_continous_mine_detection = {
    params ["_engGroup"];

    while {!(isnull _engGroup) and ({alive _x} count (units _engGroup)) > 0} do {


        _detectedMines = allMines select {(_x distance2D (vehicle (leader _engGroup))) < 40 and !(_x in pl_marked_mines)};


        {
            if ((random 1) > 0.75 or _x mineDetectedBy playerSide) then {
                playerSide revealMine _x;
                pl_marked_mines pushBack _x;
                _cm = createMarker [str (random 3), getPos _x];
                _cm setMarkerType "mil_triangle";
                _cm setMarkerSize [0.4, 0.4];
                _cm setMarkerDir -180;
                _cm setMarkerShadow false;
                _cm setMarkerColor "colorRED";
                pl_engineering_markers pushBack _cm;
            };
        } forEach _detectedMines;


        sleep 15;

    };
};

pl_directional_at_mine = {
    params ["_minePos", "_mineDir"];

    private _mine = createMine ["SLAMDirectionalMine", _minePos, [], 0];
    _mine setDir _mineDir;

    private _triggerPos = _minePos getPos [25, _mineDir];

    private _mineMarker = createMarker [str (random 5), _minePos];
    _mineMarker setMarkerType "marker_at_dir_mine";
    _mineMarker setMarkerColor "colorGreen";
    _mineMarker setMarkerSize [0.4, 0.4];
    _mineMarker setMarkerDir _mineDir;


    private _mineMarkerArea = createMarker [str (random 5), _triggerPos];
    _mineMarkerArea setMarkerShape "RECTANGLE";
    _mineMarkerArea setMarkerBrush "SolidBorder";
    _mineMarkerArea setMarkerColor "colorGreen";
    _mineMarkerArea setMarkerSize [20, 20];
    _mineMarkerArea setMarkerAlpha 0.8;
    _mineMarkerArea setMarkerDir _mineDir;
 
    private _targets = [];

    while {mineActive _mine} do {

        _targets = (_triggerPos nearEntities [["Tank", "Car"], 20]) select {alive _x};

        if (_targets isNotEqualTo []) then {
            [getPosASLVisual _mine, "R_TBG32V_F", _targets#0, 50, true, [0,0,0.25], 2, "", false] spawn BIS_fnc_EXP_camp_guidedProjectile;
            // [getPosASLVisual _mine, "M_NLAW_AT_F", _targets#0, 90, true, [0,0,0.25], 2, "", false] spawn BIS_fnc_EXP_camp_guidedProjectile;
            _mine setDamage 1;
            sleep 0.2;
            deleteVehicle _mine;
            break;
        };

        sleep 1;
    };

    deleteMarker _mineMarker;
    deleteMarker _mineMarkerArea;

};


pl_directional_ap_mine = {
    params ["_minePos", "_mineDir"];

    private _mine = createMine ["Claymore_F", _minePos, [], 0];
    _mine setDir _mineDir;

    private _triggerPos = _minePos getPos [10, _mineDir];

    private _mineMarker = createMarker [str (random 5), _minePos];
    _mineMarker setMarkerType "marker_ap_dir_mine";
    _mineMarker setMarkerColor "colorGreen";
    _mineMarker setMarkerSize [0.4, 0.4];
    _mineMarker setMarkerDir _mineDir;

    private _mineMarkerArea = createMarker [str (random 5), _triggerPos];
    _mineMarkerArea setMarkerShape "RECTANGLE";
    _mineMarkerArea setMarkerBrush "SolidBorder";
    _mineMarkerArea setMarkerColor "colorYellow";
    _mineMarkerArea setMarkerSize [10, 10];
    _mineMarkerArea setMarkerAlpha 0.8;
    _mineMarkerArea setMarkerDir _mineDir;
 
    private _targets = [];

    sleep 15;

    waitUntil {sleep 1; {alive _x and side _x == playerside} count (_triggerPos nearEntities [["Man"], 20]) <= 0};

    _mineMarkerArea setMarkerColor "colorGreen";

    while {mineActive _mine} do {

        _targets = (_triggerPos nearEntities [["Man"], 12]) select {alive _x};

        if (_targets isNotEqualTo []) then {
            _mine setDamage 1;
        };

        sleep 1;
    };

    deleteMarker _mineMarker;
    deleteMarker _mineMarkerArea;

};