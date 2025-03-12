pl_covers = [];
pl_defence_cords = [0,0,0];
pl_mapClicked = false;
pl_denfence_draw_array = [];
pl_draw_building_array = [];
pl_show_vic_defense1_array = [];
pl_show_vic_defense2_array = [];
pl_building_search_cords = [0,0,0];
pl_garrison_area_size = 20; 
pl_mapClicked = false;
pl_360_area = false;
pl_show_covers = false;
pl_show_covers_pos = [0,0,0];
pl_show_watchpos_selector = false;
pl_at_attack_array = [];
pl_valid_covers = ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "BUILDING", "HIDE", "FENCE", "WALL"];
pl_valid_walls = ["Land_City_8mD_F", "Land_City2_8mD_F", "Land_Stone_8mD_F", "Land_Mil_ConcreteWall_F", "Land_Mound01_8m_F", "Land_Mound02_8m_F", "Land_City_Gate_F", "Land_Stone_Gate_F"];
pl_building_type_blk_lst = ["Land_i_Addon_04_V1_F", "Land_Slum_House03_F", "Land_i_Addon_03_V1_F", "Land_i_Addon_02_V1_F", "Land_i_Addon_01_V1_F", "Land_Slum_House01_F", "Land_Metal_Shed_F"];

// // _helper = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
// // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
// // _helper setposASL _checkPos;


pl_setUnitPos = {
    params ["_unit", "_watchDir", "_watchPos"];
    _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
    _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
    _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
    if (_visP isEqualTo []) then {_unit setUnitPos "DOWN"} else {_unit setUnitPos "MIDDLE"};
    doStop _unit;
    _unit doWatch _watchPos;
    _unit disableAI "PATH";
};

pl_find_cover = {
    params ["_unit", ["_radius", 15], ["_watchDir", 0], ["_fofScan", false], ["_cords", []], ["_waitVar", "onTask"]];
    private ["_valid"];

    _unit enableAI "PATH";

    if (_cords isEqualTo []) then {
        _cords = getPos _unit
    };
    _watchPos = _cords getPos [1000, _watchDir];
    private _covers = (nearestTerrainObjects [_cords, pl_valid_covers, _radius, true, true]); //select {!(isObjectHidden _x)};

    if (_radius > 0) then {

    if ((count _covers) > 0) then {
            private _bestCover = _covers#0;
            if !(_bestCover in pl_covers) then {
                pl_covers pushBack _bestCover;
                _coverPos = getPos _bestCover;
                _unit doMove _coverPos;
                _unit setDestination [_coverPos, "LEADER DIRECT", true];
                sleep 0.5;

                waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable [_waitVar, true]) or (_unit distance2D _coverPos) <= 1};

                if ((group _unit) getVariable [_waitVar, true]) then {
                    [_unit, _watchDir, _watchPos] call pl_setUnitPos;
                    pl_covers deleteAt (pl_covers find _bestCover);
                };
             } else {
                [_unit, _watchDir, _watchPos] call pl_setUnitPos;
            };
        }
        else
        {
            [_unit, _watchDir, _watchPos] call pl_setUnitPos;
        };

    } else {
        [_unit, _watchDir, _watchPos] call pl_setUnitPos;
    };

    if (_fofScan) then {

        private _c = 0;
        private _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
        for "_i" from 10 to 260 step 50 do {
            _checkPos = [(getPos _unit) getPos [_i, _watchDir], 1] call pl_convert_to_heigth_ASL;
            _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "FIRE"];
            if (_visP isEqualTo []) then {_c = _c + 1;};
        };
        if (_c >= 3) then {
            _unit setUnitPos "DOWN";
            _unit setUnitPosWeak "DOWN";
        } else {
            _c = 0;
            private _crouchPos = [getPos _unit, 0.7] call pl_convert_to_heigth_ASL;
            _checkPos = [(getPos _unit) getPos [4, _watchDir], 1.5] call pl_convert_to_heigth_ASL;
            _visP = lineIntersectsSurfaces [_crouchPos, _checkPos, _unit, vehicle _unit, true, 1, "FIRE"];
            if (_visP isEqualTo []) then {
                _unit setUnitPos "MIDDLE";
                _unit setUnitPosWeak "MIDDLE";
            } else {
                _unit setUnitPos "UP";
                _unit setUnitPosWeak "UP";
            };
        };
    };

    if (([secondaryWeapon _unit] call BIS_fnc_itemtype) select 1 in ["MissileLauncher", "RocketLauncher"]) then {
        if (unitPos _unit == "down") then {
            _unit setUnitPos "MIDDLE";
            _unit setUnitPosWeak "MIDDLE";
        };
    };
};


pl_find_cover_allways = {
    params ["_unit", "_center", "_radius"];
    private ["_movePos"];

    _covers = nearestTerrainObjects [_center, pl_valid_covers, _radius, true, true];
    _movePos = [];
    if ((count _covers) > 0) then {
        {
            if !(_x in pl_covers) exitWith {
                pl_covers pushBack _x;
                _movePos = getPos _x;
            };
        } forEach _covers;
    };
    if (_movePos isEqualTo []) then {
        _movePos = [[[_center, _radius]],[]] call BIS_fnc_randomPos;
    };
    sleep 0.5;
    _unit doMove _movePos;
    sleep 0.5;
    _reachable = [_unit, _movePos, 20] call pl_not_reachable_escape;
    waitUntil {sleep 0.5; (unitReady _unit) or (!alive _unit) or ((group _unit) getVariable ["onTask", false])};
    if (!((group _unit) getVariable ["onTask", true]) and !((group _unit) getVariable ["pl_on_march", false])) then {
        // doStop _unit;
        _unit setUnitPos "MIDDLE";
        _unit disableAI "PATH";
    };
    sleep 10;
    pl_covers = []
};


pl_deploy_static = false;

pl_garrison = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_mPos", "_building", "_buildingOld", "_buildingMarker"];

    _group setVariable ["pl_is_task_selected", true];
  
    // private _group = (hcSelected player) select 0;

    if (visibleMap or !(isNull findDisplay 2000)) then {
        private _rangelimiterCenter = getPos (leader _group);
        if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};
        private _rangelimiter = 100;
        _markerBorderName = str (random 2);
        createMarker [_markerBorderName, _rangelimiterCenter];
        _markerBorderName setMarkerShape "ELLIPSE";
        _markerBorderName setMarkerBrush "Border";
        _markerBorderName setMarkerColor "colorOrange";
        _markerBorderName setMarkerAlpha 0.8;
        _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

        pl_garrison_area_size = 25;
        pl_360_area = false;
        _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
                     <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
        hintSilent "";
        hint parseText _message;

        onMapSingleClick {
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        player enableSimulation false;

        _buildingMarker = "";
        _buildingOld = objNull;
        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };

            if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
                _building = nearestBuilding _mPos;
                if (_building != _buildingOld) then {
                    deleteMarker _buildingMarker;
                    _buildingMarker = [_building] call BIS_fnc_boundingBoxMarker;
                    _buildingMarker setMarkerColor pl_side_color;
                };
                _buildingOld = _building;
            };

            sleep 0.1;
        };

        player enableSimulation true;

        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {
            deleteMarker _buildingMarker;
            deleteMarker _markerBorderName;
        };
        deleteMarker _markerBorderName;
        if (_buildingMarker == "") exitWith {};
        _buildingMarker setMarkerAlpha 0.5;
    } else {

        waitUntil {sleep 0.1; inputAction "Action" <= 0};

        _cursorPosIndicator = createVehicle ["Sign_Arrow_Large_Yellow_F", [-1000, -1000, 0], [], 0, "none"];

        _leader = leader _group;
        pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

        while {inputAction "Action" <= 0} do {
            _viewDistance = _cursorPosIndicator distance2D player;
            if (cursorObject isKindOf "house") then {
                _cursorPosIndicator setPosATL ([0, 0, ((boundingBox cursorTarget)#1)#2] vectorAdd (getPosATL cursorObject));
                _cursorPosIndicator setObjectScale (_viewDistance * 0.05);
                _building = cursorObject;
            };

            if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

            sleep 0.025
        };

        pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];
        deleteVehicle _cursorPosIndicator;
        if (pl_cancel_strike) exitWith {};

        _buildingMarker = [_building] call BIS_fnc_boundingBoxMarker;

        if (_group getVariable ["pl_on_march", false]) then {
            _taskPlanWp = (waypoints _group) select ((count waypoints _group) - 1);
            _group setVariable ["pl_task_planed", true];
            _taskPlanWp setWaypointStatements ["true", "(group this) setVariable ['pl_execute_plan', true]"];
        };

    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; _group setVariable ["pl_is_task_selected", nil];};

    private _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa";
    private _cords = getPos _building;

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
            // waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 or !(_group getVariable ["pl_task_planed", false])};
            waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
        };
        _group setVariable ["pl_disembark_finished", nil];

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_unload_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    pl_draw_building_array pushBack [_group, _building];

    [_group] spawn pl_reset;
    sleep 0.5;
    [_group] spawn pl_reset;
    sleep 1;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    _buildingPositions = [_building] call BIS_fnc_buildingPositions;
    _units = units _group;

    if ((count _buildingPositions) < (count _units)) then {
        for "_j" from 0 to (count _units) do {
            _buildingPositions pushback ([[[getPos _building, 50]], [[getPos _building, 25]]] call BIS_fnc_randomPos);
        };
    };

    _nearestEnemy = (leader _group) findNearestEnemy (getPos _building);

    if !(isNull _nearestEnemy) then {
        _buildingPositions = [_buildingPositions, [], {_nearestEnemy distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;
    };

    for "_i" from 0 to (count _units) - 1 do {

        private _unit = _units#_i;
        private _pos = selectRandom _buildingPositions;
        _buildingPositions deleteAt (_buildingPositions find _pos);
        private _cover = false;
        if (_i > ((count ([_building] call BIS_fnc_buildingPositions)) - 1)) then {
            _cover = true;
        };

        [_unit, _pos, _cover] spawn {
            params ["_unit", "_pos", "_cover"];

            waitUntil {sleep 0.5; unitReady _unit or !alive _unit};

            // _m = createMarker [str (random 1), _pos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];

            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            _unit setHit ["legs", 0];
            // _unit disableAI "FSM";
            _unit doMove _pos;
            _unit setDestination [_pos, "LEADER DIRECT", true];
            sleep 1;
            private _counter = 0;
            // while {alive _unit and ((group _unit) getVariable ["onTask", true])} do {
            //     sleep 0.5;
            //     _dest = [_unit, _pos, _counter] call pl_position_reached_check;
            //     if (_dest#0) exitWith {};
            //     _pos = _dest#1;
            //     _counter = _dest#2;
            //     _time = time + 3;
            //     waitUntil{sleep 0.5; time >= _time or !((group _unit) getVariable ["onTask", true])};
            // };
            waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
            doStop _unit;
            _unit disableAI "PATH";
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "TARGET";
            if (_cover) then {
                [_unit, 15, getDir _unit] spawn pl_find_cover;
            };
            // _unit enableAI "FSM";
        };
    };

    waitUntil {sleep 1; !(_group getVariable ["onTask", true])};

    deleteMarker _buildingMarker;
    pl_draw_building_array = pl_draw_building_array - [[_group, _building]];
};

pl_360 = {
    params ["_group", ["_center"], []];

    if (_center isEqualTo []) then {
        _center = getPos (leader _group);
    };
    _units = (units _group) - [leader _group];
    private _posArray = [];
    for "_di" from 0 to 360 step (360 / (count (units _group))) do {
        _movePos = _center getPos [8, _di];
        _posArray pushBack _movePos;
    };

    private _i = 0;
    {
        [_x, _posArray#_i, _group] spawn {
            params ["_unit", "_movePos", "_group"];

            _unit doMove _movePos;

            sleep 0.5;

            waitUntil {sleep 0.5; unitReady _unit or !alive _unit};

            // _unit setUnitPos "MIDDLE"

            doStop _unit;
            _unit doWatch ((getPos (leader _group)) getPos [50, (leader _group) getDir _unit]);
        };
        _i = _i + 1;
    } forEach _units;
};

pl_get_360 = {
    params ["_group", ["_center", []], ["_size", 16]];
    private ["_movePos"];

    if (_center isEqualTo []) then {
        _center = getPos (leader _group);
    };
    private _units = (units _group) - [leader _group];
    private _unitCount = (count (units _group)) - 1;
    private _posArray = [_center];
    for "_di" from 0 to 360 step (round (360 / _unitCount)) do {
        _movePos = _center getPos [_size, _di];
        _posArray pushBack _movePos;

        // _m = createMarker [str (random 1), _movePos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerSize [0.5, 0.5];

    };

    _posArray
};


pl_disengage = {
    params [["_group", (hcSelected player) select 0], ["_retreatPos", []], ["_takePosition", false], ["_facing", 1000]];


    if (_retreatPos isEqualTo []) then {
        if ((visibleMap or !(isNull findDisplay 2000)) and _retreatPos isEqualTo []) then {
            if (visibleMap) then {
                _retreatPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _retreatPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
        } else {
            _retreatPos = screenToWorld [0.5, 0.5]
        };
    };

    if !(canMove (vehicle (leader _group))) exitWith {};

    private _startPos = getPos (leader _group);

    if (_facing == 1000) then {
        _facing = _retreatPos getDir _startPos;
    };

    _markerPos = _startPos getPos [(_startPos distance2D _retreatPos) / 2, _startPos getDir _retreatPos];

    private _markerWithdrawName = format ["%1withdraw", _group];
    createMarker [_markerWithdrawName, _markerPos];
    _markerWithdrawName setMarkerType "marker_withdraw";
    _markerWithdrawName setMarkerColor pl_side_color;
    _markerWithdrawName setMarkerDir (_startPos getDir _retreatPos);
    // _markerWithdrawName setMarkerSize [(_startPos distance2D _retreatPos) * 0.02, 1.5];

    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa"];
    _group setVariable ["pl_task_pos", _retreatPos];

    pl_draw_disengage_array pushBack [_group, _retreatPos];
    [_group, "disengage", 1] call pl_voice_radio_answer;

    if (vehicle (leader _group) == leader _group) then {

        if (_group getVariable ["pl_inf_attached", false]) then {
            _vicGroup = _group getVariable ["pl_attached_vicGrp", grpNull];
            [vehicle (leader _vicGroup), "SmokeLauncher"] call BIS_fnc_fire;
        };

        [_group, getpos (leader _group)] spawn pl_group_throw_smoke;

        sleep 0.25;

        [_group, getpos (leader _group)] spawn pl_group_throw_smoke;

        [_group] call pl_forget_group;

        


        if !(_takePosition) then {


            private _units = units _group;
            private _posArray = [];

            for "_di" from 0 to 360 step (360 / (count _units)) do {
                _movePos = _retreatPos getPos [7, _di];
                _posArray pushBack _movePos;
            };

            private _injured = _units select {(lifeState _x) isEqualTo "INCAPACITATED"};
            private _moveScripts = [];

            for "_i" from 0 to (count _units) - 1 do {

                _unit = _units#_i;
                _movePos = _posArray#_i;

                // _m = createMarker[str (random 1), _movePos];
                // _m setMarkerType "mil_dot"; 

                _moveScript = [_unit, _movePos, _injured] spawn {
                    params ["_unit", "_movePos", "_injured"];

                    // if (count _injured > 0 and !((lifeState _unit) isEqualTo "INCAPACITATED")) then {

                    //     _nearInjured = ([_injured, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;

                    //     if ((_unit distance2D _nearInjured) < 10) then {
                    //         _injured deleteAt (_injured find _nearInjured);
                    //         [_unit, "SmokeShellMuzzle"] call BIS_fnc_fire;
                    
                    
                    //         sleep 1;
                    //         _script = [_unit, _nearInjured, _movePos, true] spawn pl_injured_drag;

                    //         waitUntil {scriptDone _script};
                    //     } else {
                    //         _unit disableAI "AUTOCOMBAT";
                    //         _unit disableAI "AUTOTARGET";
                    //         _unit disableAI "TARGET";
                    //         _unit setUnitTrait ["camouflageCoef", 0.7, true];
                    //         _unit setVariable ["pl_damage_reduction", true];
                    //         _unit doMove _movePos;
                    //         // _unit setDestination [_movePos, "LEADER DIRECT", true];
                    //         sleep 1;
                    //         private _counter = 0;
                    //         while {alive _unit and !((lifeState _unit) isEqualTo "INCAPACITATED") and ((group _unit) getVariable ["onTask", false])} do {
                    //             sleep 0.5;
                    //             _check = [_unit, _movePos, _counter] call pl_position_reached_check;
                    //             if (_check#0) exitWith {};
                    //             _counter = _check#1;
                    //         };

                    //         _unit enableAI "AUTOCOMBAT";
                    //         _unit enableAI "AUTOTARGET";
                    //         _unit enableAI "TARGET";
                    //     };

                    // } else {

                        _unit disableAI "AUTOCOMBAT";
                        _unit disableAI "AUTOTARGET";
                        _unit disableAI "TARGET";
                        _unit setUnitTrait ["camouflageCoef", 0.7, true];
                        _unit setVariable ["pl_damage_reduction", true];
                        _unit setHit ["legs", 0];
                        _unit forceSpeed 20;
                        _unit doMove _movePos;
                        // _unit setDestination [_movePos, "LEADER DIRECT", true];
                        sleep 1;
                        private _counter = 0;
                        while {alive _unit and !((lifeState _unit) isEqualTo "INCAPACITATED") and ((group _unit) getVariable ["onTask", false])} do {
                            sleep 0.5;
                            _check = [_unit, _movePos, _counter] call pl_position_reached_check;
                            if (_check#0) exitWith {};
                            _counter = _check#1;
                        };

                        _unit enableAI "AUTOCOMBAT";
                        _unit enableAI "AUTOTARGET";
                        _unit enableAI "TARGET";
                    // };

                    [_unit, 5, getDir _unit] spawn pl_find_cover;
                };

                _moveScripts pushback _moveScript;
            };

            pl_test_array = _moveScripts;

            waitUntil {sleep 0.5; ({scriptDone _x} count _moveScripts) == (count _moveScripts) or !(_group getVariable "onTask")};

            // [_group] call pl_reset;

        } else {

            [_group, [], _retreatPos, _facing, false, true, 30] spawn pl_defend_position;

            sleep 5;

            private _time = time + 45;
            waitUntil {sleep 0.5; ((leader _group) distance2D _retreatPos) < 20 or !(_group getVariable ["onTask", false]) or time >= _time};


            _markerDirName = format ["defenceAreaDir%1", _group];
            _markerDirName setMarkerType "marker_position";

        };

        pl_draw_disengage_array =  pl_draw_disengage_array - [[_group, _retreatPos]];
        deleteMarker _markerWithdrawName;

    } else {

        _vic = vehicle (leader _group);

        if !(canMove _vic) exitWith {};

        _vic limitSpeed 5000;
        _vic engineOn true;
        _vDir = getDir _vic;
        // if (_takePosition) then {[_vic, "SmokeLauncher"] call BIS_fnc_fire};
        [_vic, "SmokeLauncher"] call BIS_fnc_fire;

        [_vic, _retreatPos] call pl_vic_reverse_to_pos;

        pl_draw_disengage_array =  pl_draw_disengage_array - [[_group, _retreatPos]];
        deleteMarker _markerWithdrawName;
        [_group] call pl_reset;

        if (_takePosition) then {

            [_group, [], getPos _vic, getDir _vic, false, false] spawn pl_defend_position;
         };

    };
};


pl_defend_position = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []] , ["_cords", []], ["_watchDir", 0], ["_sfp", false], ["_retreat", false], ["_area", 35], ["_auto360", false]];
    private ["_mPos", "_buildingWallPosArray", "_buildingMarkers", "_watchPos", "_defenceWatchPos", "_markerAreaName", "_markerDirName", "_covers", "_buildings", "_allPos", "_validPos", "_units", "_unit", "_defendMode", "_icon", "_unitWatchDir", "_vPosCounter", "_defenceAreaSize", "_mgPosArray", "_losPos", "_mgOffset", "_atEscord", "_dirMarkerType", "_unitPos"];

    if (_group getVariable ["pl_is_task_selected", false]) exitWith {};
    _group setVariable ["pl_is_task_selected", true];
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";
    _buildings = [];
    private _markerDirName = "";
    pl_defend_mode = 0;

    if (_cords isEqualTo []) then {

        // if !(visibleMap) then {
        //     if (isNull findDisplay 2000) then {
        //         [leader _group] call pl_open_tac_forced;
        //     };
        // };

        hintSilent "";

        private _dirMarkerType = "marker_position";
        if (_sfp) then {_dirMarkerType = "marker_sfp"};
        if (_retreat) then {_dirMarkerType = "marker_position_eny"};

        _markerDirName = format ["defenceAreaDir%1%2", _group, random 2];
        createMarker [_markerDirName, pl_defence_cords];
        _markerDirName setMarkerPos pl_defence_cords;
        _markerDirName setMarkerType _dirMarkerType;
        _markerDirName setMarkerColor pl_side_color;


        // on Map Command
        if (visibleMap or !(isNull findDisplay 2000)) then {

            _markerAreaName = format ["%1garrison%2", _group, random 2];
            createMarker [_markerAreaName, [0,0,0]];
            _markerAreaName setMarkerShape "ELLIPSE";
            _markerAreaName setMarkerBrush "SolidBorder";
            _markerAreaName setMarkerColor pl_side_color;
            _markerAreaName setMarkerAlpha 0.35;
            _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];

            private _rangelimiterCenter = getPos (leader _group);
            if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};
            private _rangelimiter = 200;
            _markerBorderName = str (random 2);
            createMarker [_markerBorderName, _rangelimiterCenter];
            _markerBorderName setMarkerShape "ELLIPSE";
            _markerBorderName setMarkerBrush "Border";
            _markerBorderName setMarkerColor "colorOrange";
            _markerBorderName setMarkerAlpha 0.8;
            _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

            pl_garrison_area_size = _area;
            pl_defend_mode = 0;

            if (vehicle (leader _group) != (leader _group)) then {pl_show_vic_defense1_array pushback (vehicle (leader _group))};

            pl_360_area = false;
            private _staticStr = "NO";
            private _staticColor = '#ff0000';
            if ([_group] call pl_get_has_static and (_group getVariable ["pl_allow_static", false])) then {_staticStr = "YES"; _staticColor = '#00ff00'};
            _message = format ["Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br /><t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t><br /><t size='0.8' align='left'>-> A/D</t><t size='0.8' align='right'>Switch Modes</t><br /><t size='0.8' align='left'>-> Deploy Static Weapon</t><t size='0.8' align='right'>%2</t>", _staticColor, _staticStr];
            hint parseText _message;

            onMapSingleClick {
                pl_defence_cords = _pos;
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
                if (inputAction "MoveForward" > 0) then {pl_garrison_area_size = pl_garrison_area_size + 5; sleep 0.05};
                if (inputAction "MoveBack" > 0) then {pl_garrison_area_size = pl_garrison_area_size - 5; sleep 0.05};
                if (inputAction "TurnLeft" > 0) then {pl_defend_mode = pl_defend_mode + 1; sleep 0.3};
                if (inputAction "TurnRight" > 0) then {pl_defend_mode = pl_defend_mode - 1; sleep 0.3};
                if (pl_garrison_area_size >= 110) then {pl_garrison_area_size = 110};
                if (pl_garrison_area_size <= 10) then {pl_garrison_area_size = 10};
                if (pl_defend_mode > 2) then {pl_defend_mode = 0};
                if (pl_defend_mode < 0) then {pl_defend_mode = 2};

                //mode 0 : Form Line use Buildings and walls if avaiable
                //mode 1 : Form 360 use Buildings and walls if avaiable
                //mode 2 : Form Line dont use Buildings

                _buildings = nearestTerrainObjects [_mPos, ["BUILDING", "RUIN", "HOUSE"], pl_garrison_area_size, true];

                switch (pl_defend_mode) do { 
                    case 0 : {
                        _markerAreaName setMarkerShape "ELLIPSE";
                        _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];
                        _markerDirName setMarkerType _dirMarkerType;
                        pl_show_covers = true;
                        pl_show_covers_pos = _mPos;
                    }; 
                    case 1 : {
                        _markerDirName setMarkerType "mil_circle";
                        _markerAreaName setMarkerShape "ELLIPSE";
                        _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];
                        pl_show_covers = true;
                    }; 
                    case 2 : {
                        _markerDirName setMarkerType _dirMarkerType;
                        _markerAreaName setMarkerShape "RECTANGLE";
                        _markerAreaName setMarkerSize [pl_garrison_area_size, 2];
                        pl_show_covers = false;
                    };
                    default {_markerDirName setMarkerType _dirMarkerType;}; 
                };

                if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
                    _watchDir = _rangelimiterCenter getDir _mPos;
                    _markerAreaName setMarkerPos _mPos;
                    _markerDirName setMarkerPos _mPos;
                    _markerDirName setMarkerDir _watchDir;
                    _markerAreaName setMarkerDir _watchDir;
                };
            };

            pl_show_covers = false;

            player enableSimulation true;

            pl_mapClicked = false;
            if (pl_cancel_strike) exitWith {deleteMarker _markerBorderName; deleteMarker _markerDirName; deleteMarker _markerAreaName};

            sleep 0.1;
            deleteMarker _markerBorderName;
            _cords = getMarkerPos _markerAreaName;
            _markerDirName setMarkerPos _cords;
            // _cords = pl_defence_cords;
            _defenceAreaSize = pl_garrison_area_size;

            if (vehicle (leader _group) != (leader _group)) then {
                pl_show_vic_defense1_array = pl_show_vic_defense1_array - [vehicle (leader _group)];
                 pl_show_vic_defense2_array pushback [vehicle (leader _group), _cords];
            };

            if (pl_defend_mode != 1) then {

                _message = "Select Defence FACING <br /><br />
                <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />";
                hint parseText _message;
                

                onMapSingleClick {
                    pl_defenceWatchPos = _pos;
                    pl_mapClicked = true;
                    if (_shift) then {pl_cancel_strike = true};
                    if (_alt) then {pl_360_area = true};
                    hintSilent "";
                    onMapSingleClick "";
                };
                // pl_show_watchpos_selector = true;

                while {!pl_mapClicked} do {
                    if (visibleMap) then {
                        _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                    } else {
                        _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                    };
                    _watchDir = _cords getDir _mPos;
                    _markerDirName setMarkerDir _watchDir;
                    _markerAreaName setMarkerDir _watchDir;
                    _defenceWatchPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                };
                pl_mapClicked = false;

                if (vehicle (leader _group) != (leader _group)) then {pl_show_vic_defense2_array = pl_show_vic_defense2_array - [[vehicle (leader _group), _cords]]};
            };
            // pl_show_watchpos_selector = false;
            deletemarker _markerAreaName;

        // 3d World Command 
        } else {

            waitUntil {sleep 0.1; inputAction "Action" <= 0};

            // _cursorPosIndicator = createVehicle ["Sign_Arrow_Direction_Yellow_F", screenToWorld [0.5,0.5], [], 0, "none"];
            _cursorPosIndicator = createVehicle ["Sign_Arrow_Large_Yellow_F", [-1000, -1000, 0], [], 0, "none"];

            _leader = leader _group;
            pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

            while {inputAction "Action" <= 0} do {
                _viewDistance = _cursorPosIndicator distance2D player;
                if (cursorTarget isKindOf "house") then {
                    _cursorPosIndicator setPosATL ([0, 0, ((boundingBox cursorTarget)#1)#2] vectorAdd (screenToWorld [0.5,0.5]));
                } else {
                    _cursorPosIndicator setPosATL ([0,0,_viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
                };
                _cursorPosIndicator setObjectScale (_viewDistance * 0.05);

                if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

                sleep 0.025
            };

            if (pl_cancel_strike) exitWith {deleteVehicle _cursorPosIndicator; pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]]};

            _cords = getPosATL _cursorPosIndicator;

            pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

            deleteVehicle _cursorPosIndicator;

            _cursorPosIndicator = createVehicle ["Sign_Arrow_Direction_Yellow_F", _cords, [], 0, "none"];

            _leader = leader _group;
            pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];


            waitUntil {sleep 0.1; inputAction "Action" <= 0};

            _cursorPosIndicatorDir = createVehicle ["Sign_Sphere25cm_F", screenToWorld [0.5,0.5], [], 0, "none"];

            pl_draw_3dline_array pushback [_cursorPosIndicator, _cursorPosIndicatorDir];

            while {inputAction "Action" <= 0} do {
                _viewDistance = _cursorPosIndicatorDir distance2D player;
                _cursorPosIndicatorDir setPosATL ([0, 0, _viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
                _cursorPosIndicator setDir (_cords getDir _cursorPosIndicatorDir);
                _cursorPosIndicatorDir setObjectScale (_viewDistance * 0.07);
                _cursorPosIndicator setObjectScale ((_cursorPosIndicator distance2D player) * 0.07);

                if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

                sleep 0.025
            };

            pl_draw_3dline_array = pl_draw_3dline_array - [[_cursorPosIndicator, _cursorPosIndicatorDir]];
            pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];
            
            _defenceAreaSize = pl_garrison_area_size;
            _watchDir = getDir _cursorPosIndicator;
            _markerDirName setMarkerPos _cords;
            _markerDirName setMarkerDir _watchDir;
            deleteVehicle _cursorPosIndicator;
            deleteVehicle _cursorPosIndicatorDir;

            if (_group getVariable ["pl_on_march", false]) then {
                _taskPlanWp = (waypoints _group) select ((count waypoints _group) - 1);
                _group setVariable ["pl_task_planed", true];
                _taskPlanWp setWaypointStatements ["true", "(group this) setVariable ['pl_execute_plan', true]"];
            };

            _buildings = nearestTerrainObjects [_cords, ["BUILDING", "RUIN", "HOUSE"], _defenceAreaSize, true];

        };

        if (pl_cancel_strike) exitWith {deleteMarker _markerDirName; pl_show_vic_defense1_array = []; pl_show_vic_defense2_array = []};

        // _defenceWatchPos = pl_defenceWatchPos;


        _defenceAreaSize = pl_garrison_area_size;
        _defendMode = pl_defend_mode;

        if (_sfp) then {
            [_group, _cords] spawn pl_suppressive_fire_position;
        };

        _group setVariable ["pl_task_pos", _cords];
        _group setVariable ["specialIcon", _icon];
        

        // systemChat str (_group getVariable "pl_task_pos");

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
                // waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
            };
            _group setVariable ["pl_disembark_finished", nil];

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
            _group setVariable ["pl_task_planed", false];
            _group setVariable ["pl_unload_task_planed", false];
            _group setVariable ["pl_execute_plan", nil];
            _group setVariable ["pl_grp_task_plan_wp", nil];
        };

        // if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

        
    } else {

        pl_garrison_area_size = _area;
        _defenceAreaSize = pl_garrison_area_size;
        _buildings = nearestTerrainObjects [_cords, ["BUILDING", "RUIN", "HOUSE"], _defenceAreaSize, true];

        _markerDirName = format ["delayDir%1", _group];
        createMarker [_markerDirName, _cords];
        _markerDirName setMarkerPos _cords;
        private _dirMarkerType = "marker_position";
        if (_auto360) then {_dirMarkerType = "mil_circle"};
        if (_sfp) then {_dirMarkerType = "marker_sfp"};
        if (_retreat) then {_dirMarkerType = "marker_position_eny"};
        _markerDirName setMarkerType _dirMarkerType;
        _markerDirName setMarkerColor pl_side_color;
        _markerDirName setMarkerDir _watchDir;

        _group setVariable ["pl_task_pos", _cords];
        _group setVariable ["specialIcon", _icon];

        _defendMode = pl_defend_mode;
    };

    

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; _group setVariable ["pl_is_task_selected", nil]};

    if !(_auto360) then {
        [_group, "confirm", 1] call pl_voice_radio_answer;
    } else {
        _defendMode = 1;
    };

    [_group] spawn pl_reset;

    sleep 0.5;

    [_group] spawn pl_reset;

    sleep 1;


    _defenceWatchPos = _cords getPos [250, _watchDir];
    _defenceWatchPos = ASLToATL _defenceWatchPos;
    _defenceWatchPos = [_defenceWatchPos#0, _defenceWatchPos#1, 2];
    _defenceWatchPos = ATLToASL _defenceWatchPos;


    _watchPos = _cords getPos [1000, _watchDir];
    [_watchPos, 1] call pl_convert_to_heigth_ASL;

    
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 2 and !(typeOf _x in pl_building_type_blk_lst)) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    (leader _group) playActionNow "GestureCover";
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _group setVariable ["pl_combat_mode", true];
    _group setVariable ["pl_in_position_marker", _markerDirName];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false]) and !(_group getVariable ["pl_is_dismounted", false])) exitWith {[_group, _watchPos, _cords, _markerDirName, _watchDir, _sfp, _retreat] spawn pl_defend_position_vehicle};

    _group setVariable ["pl_in_position", true];


    _validPos = [];
    private _winPos = [];
    private _sideRoadPos = [];
    _allPos = [];

    private _debugMarkers = [];
    private _debugHelpers = [];

    if (_defendMode != 2) then {
        {
            private _building = _x;
            // pl_draw_building_array pushBack [_group, _building];
            private _bPos = [_building] call BIS_fnc_buildingPositions; 
            _vPosCounter = 0;
            {
                _bP = _x;
                _allPos pushBack _bP;
                private _window = false;

                // _samplePosASL = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 1.04152];
                _samplePosASL = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 1.5];

                _buildingDir = getDir _building;
                for "_d" from 0 to 361 step 4 do {
                    _counterPos = _samplePosASL vectorAdd [6 * (sin (_buildingDir + _d)), 6 * (cos (_buildingDir + _d)), 0];

                    if !((lineIntersects [_counterPos, _counterPos vectorAdd [0, 0, 20]])) then {
                        _helper2 = objNull;
                        // _helper2 = createVehicle ["Sign_Sphere25cm_F", _counterPos, [], 0, "none"];
                        // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                        // _helper2 setposASL _counterPos;
                        // _debugHelpers pushback _helper2;

                        // _m = createMarker [str (random 1), _counterPos];
                        // _m setMarkerType "mil_dot";
                        // _m setMarkerSize [0.3, 0.3];
                        // _m setMarkerColor "colorRED";
                        // _debugMarkers pushback _m;

                        _interSectsWin = lineIntersectsWith [_samplePosASL, _counterPos, objNull, objNull, true];
                        _checkDir = _samplePosASL getDir _counterPos;
                        if (!(lineIntersects [_samplePosASL, _counterPos, _helper2, objNull]) and (_checkDir > (_watchDir - 45) and _checkDir < (_watchDir + 45))) then {
                            // _window = true
                            _bPos deleteAt (_bPos find _bP);
                            _validPos pushBackUnique _bP;
                            _winPos pushBackUnique _bP;
                            _vPosCounter = _vPosCounter + 1;

                            // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];

                            // _helper1 = createVehicle ["Sign_Sphere25cm_F", _samplePosASL, [], 0, "none"];
                            // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                            // _helper1 setposASL _samplePosASL;
                            // _debugHelpers pushback _helper1;

                            // _m = createMarker [str (random 1), _samplePosASL];
                            // _m setMarkerType "mil_dot";
                            // _m setMarkerSize [1, 1];
                            // _m setMarkerColor "colorBlue";
                            // _debugMarkers pushback _m
                        };
                    };
                };

                _skyPos = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 30];
                _interSectsRoof = lineIntersectsWith [_samplePosASL, _skyPos];
                if (_interSectsRoof isEqualTo []) then {
                    _bPos deleteAt (_bPos find _bP);
                    _validPos pushBackUnique _bP;
                    _vPosCounter = _vPosCounter + 1;
                };
            } forEach _bPos;

            if (_vPosCounter == 0) then {
                _validBuildings deleteAt (_validBuildings find _building);
                // if (_winPos isNotEqualTo []) then {
                //     _validPos pushBack (([_winPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0);
                // } else {
                //     _validPos pushBack (([_bPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0);
                // };
                // _winPos = [_winPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
            };

        } forEach _validBuildings;
    };
    // deploy packed static weapons if no buildings
    private _isStatic = [false, []];

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _units = [];
    if (vehicle (leader _group) == leader _group) then {_units pushBack (leader _group)};
    private _mgGunners = [];
    private _atSoldiers = [];
    private _missileAtSoldiers = [];
    private _atEscord = objNull;
    private _medic = objNull;


    // classify units
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun" and secondaryWeapon _x == "" and _x != _medic and _x != (leader _group) and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _units pushBackUnique _x;
        };
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun" and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _mgGunners pushBackUnique _x;
        };
        if (([secondaryWeapon _x] call BIS_fnc_itemtype) select 1 in ["MissileLauncher", "RocketLauncher"]) then {
            _atSoldiers pushBackUnique _x;
        };
    } forEach ((units _group) select {vehicle _x == _x});

    if (count _atSoldiers > 0 and count _units > 3) then {
        _atEscord = {
            if (_x != (leader _group) and _x != _medic) exitWith {_x};
            objNull
        } forEach _units;
    };

    {_units pushBackUnique _x} forEach _atSoldiers;
    {_units pushBackUnique _x} forEach _mgGunners;
    if !(isNull _medic) then {_units pushBack _medic};

    if (_group == (group player)) then {
        _units = _units - [player];
    };

    if (_group getVariable ["pl_sop_def_suppress", false]) then {
        [_group, _defenceWatchPos, _medic] spawn pl_defence_suppression;
    };
    if (_group getVariable ["pl_sop_def_resupply", false]) then {
        [_group, _cords, _medic] spawn pl_defence_rearm;
    };
    if (_group getVariable ["pl_sop_is_jtac", false]) then {
        [_group, _cords, _watchDir] spawn pl_defense_jtac;
    };


    if (count _units > 2 and _group != (group player) and (_group getVariable ["pl_sop_def_disenage", false])) then {
        [_group, _cords, _watchDir] call pl_def_killed_disengage;
    };


    _posOffsetStep = _defenceAreaSize / (round ((count _units) / 2));
    private _posOffset = 0; //+ _posOffsetStep;
    private _maxOffset = _posOffsetStep * (round ((count _units) / 2));

    // find static weapons
    private _weapons = nearestObjects [_cords, ["StaticWeapon"], _defenceAreaSize, true];
    _avaiableWeapons = _weapons select { simulationEnabled _x && { !isObjectHidden _x } && { locked _x != 2 } && { (_x emptyPositions "Gunner") > 0 } };
    _weapons = + _avaiableWeapons;
    _coverCount = 0;
    private _ccpPos = [];
    private _safePos = [];
    _buildingMarkers = [];
    _buildingWallPosArray = [];

    // Find Valid Positions in and around uildings , behind Walls and beside roads 
    if (!(_buildings isEqualTo []) and _defendMode != 2) then {

        _buildings = [_buildings, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _covers = [];
        
        {
            _buildingCenter = getPos _x;
            _coverSearchPos = _buildingCenter getPos [10, _watchDir];
            _c = nearestTerrainObjects [_coverSearchPos, pl_valid_covers, 15, true, true];
            _covers = _covers + _c;

            _m = [_x] call BIS_fnc_boundingBoxMarker;
            if (_x in _validBuildings) then {
                _m setMarkerColor pl_side_color;
                _m setMarkerAlpha 0.3;
            };
            _buildingMarkers pushBack _m;
            _mPos = getMarkerPos _m;
            _mDir = markerdir _m;
            _mSize = getMarkerSize _m;
            _a2 = ((_mSize#0) * 1) * ((_mSize#0) * 1);
            _b2 = ((_mSize#1) * 1) * ((_mSize#1) * 1);
            _c2 = _a2 + _b2;
            _d = sqrt _c2;

            private _corners = [];
            for "_di" from 45 to 315 step 90 do {
                _corners pushback (_mPos getPos [_d,_mDir + _di]);
            };

            _corners = [_corners, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy;

            {
                if !([_x] call pl_is_indoor) then {
                    _buildingWallPosArray pushback _x;
                };
            } forEach [(_corners#0), (_corners#1)];

            _safePos pushback (((_corners#0) getPos [((_corners#0) distance2D (_corners#1)) / 2, (_corners#0) getDir (_corners#1)]) getPos [2.5, _watchDir - 180]);

        } forEach _buildings;

        _buildingWallPosArray = [_buildingWallPosArray, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _covers = [_covers, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        if (_safePos isNotEqualTo []) then {
            _ccpPos = ([_safePos, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0;
        };


        // {
        //     _m = createMarker [str (random 1), _x];
        //     _m setMarkerType "mil_dot";
        //     _m setMarkerSize [0.5, 0.5];
        // } forEach _buildingWallPosArray;

    };

        private _walls = nearestTerrainObjects [_cords, ["WALL", "RUIN", "FENCE", "ROCK", "ROCKs", "HIDE"], _defenceAreaSize, true];
        private _trueWalls = nearestTerrainObjects [_cords, ["WALL", "RUIN", "FENCE"], _defenceAreaSize, true];
        _walls = _walls + (nearestObjects [_cords, ["Strategic"], _defenceAreaSize]);
        private _validWallPos = [];
        private _validPrefWallPos = [];



        {
            if !(isObjectHidden _x) then {

                _leftPos = (getPos _x) getPos [1.5, getDir _x];
                _rightPos = (getPos _x) getPos [1.5, (getDir _x) - 180];

                _visLeftPos = ATLtoASL [_leftPos#0, _leftPos#1, (_leftPos#2) + 1.6];
                _visrightPos = ATLtoASL [_rightPos#0, _rightPos#1, (_rightPos#2) + 1.6];
                
                _helper1 = objNull;
                // _helper1 = createVehicle ["Sign_Sphere25cm_F", _visRightPos, [], 0, "none"];
                // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                // _helper1 setposASL _visLeftPos ;
                // _debugHelpers pushback _helper1;

                _helper2 = objNull;
                // _helper2 = createVehicle ["Sign_Sphere25cm_F", _visLeftPos, [], 0, "none"];
                // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];
                // _helper2 setposASL _visRightPos ;
                // _debugHelpers pushback _helper2;

                if (_defendMode == 1) then {_watchPos = _cords getPos [1000, _cords getDir _x]};

                if (lineIntersectsObjs [_visLeftPos, _visRightPos, _helper2, _helper1] isEqualTo []) then {
                    _validPrefWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                    // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                } else {
                    if (_x in _trueWalls) then {
                        _validWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                    };
                    // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(1,1,0,1)'];
                };
            };
        } forEach _walls;

        _validWallPos = [_validWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _validPrefWallPos = [_validPrefWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        private _roads = _cords nearRoads _defenceAreaSize;
        if ((count _roads) >= 2) then {
            _roads = [_roads, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
            private _roadDir = (getpos (_roads#1)) getDir (getpos (_roads#0));

            if (_roadDir > (_watchDir - 55) and _roadDir < (_watchDir + 55)) then {

                _roads = [_roads, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
                private _road = _roads#0;
                {
                    _info = getRoadInfo _road;    
                    _endings = [_info#6, _info#7];
                    _endings = [_endings, [], {_x distance2D player}, "ASCEND"] call BIS_fnc_sortBy;
                    _roadWidth = _info#1;
                    _rPos = ASLToATL (_endings#0);
                    _sideRoadPos pushBack (_rPos getPos [(_roadWidth / 2) + 1, _roadDir + _x]);

                    // _m = createMarker [str (random 1), _rPos getPos [_roadWidth / 2, _roadDir + _x]];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerSize [0.5, 0.5];
                    // _m setMarkerColor "colorOPFOR";
                    // _debugMarkers pushback _m;

                } forEach [90, -90];
            };
        };

        _validPos = _validPos + _validPrefWallPos; 
        _validPos = _validPos + _buildingWallPosArray;
        _validPos = _validPos + _sideRoadPos;
        _validPos = _validPos + _validWallPos;

    // Find save position for the medic to stage
    if (_ccpPos isEqualTo []) then {

        private _rearPos = _cords getPos [_defenceAreaSize * 0.8, _watchDir - 180];
        private _lineStartPos = _rearPos getPos [_defenceAreaSize / 2, _watchDir - 90];
        private _posCandidates = [];
        private _ccpPosOffset = 0;
        for "_l" from 0 to 20 do {
            _cPos = _lineStartPos getPos [_ccpPosOffset, _watchDir + 90];
            _ccpPosOffset = _ccpPosOffset + (_defenceAreaSize / 20);
            if !([_cPos] call pl_is_indoor) then {
                _posCandidates pushBack _cPos;
            };
        };
        _posCandidates = [_posCandidates, [], {_x distance2D _cords}, "DESCEND"] call BIS_fnc_sortBy;
        _ccpPos = ([_posCandidates, [], {[objNull, "VIEW", objNull] checkVisibility [_x, [_x getPos [50, _watchDir], 0.5] call pl_convert_to_heigth_ASL]}, "DESCEND"] call BIS_fnc_sortBy)#0;

    };

    // create an array of positions in a line with LOS scan to detirmen the positions with the best LOS towards the targetarea. These positions will be used by MG und AT gunners and static weapons

    private _losOffset = 3;
    private _maxLos = 0;
    private _validLosPos = [];
    private _accuracy = 16;
    private _losStartLine = _cords getPos [1, _watchDir];


    if (_validPos isNotEqualTo [] and _defendMode != 2) then {
        _losStartLine = ([_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0;
    };

    for "_j" from 0 to _accuracy do {
        if (_j % 2 == 0) then {
            _losPos = (_losStartLine getPos [-0.5, _watchDir]) getPos [3 - _losOffset, _watchDir + 90];
            // _losPos = _losStartLine getPos [3 - _losOffset, _watchDir + 90];
            // _losPos = _losStartLine getPos [_losOffset, _watchDir + 90];
        }
        else
        {
            _losPos = (_losStartLine getPos [-0.5, _watchDir]) getPos [3 - _losOffset, _watchDir - 90];
            // _losPos = _losStartLine getPos [3 - _losOffset, _watchDir - 90];
            // _losPos = _losStartLine getPos [_losOffset, _watchDir - 90];
        };
        _losOffset = _losOffset + (_defenceAreaSize / _accuracy);

        _losPos = [_losPos, 1.75] call pl_convert_to_heigth_ASL;

        

        private _losCount = 0;
        for "_l" from 10 to 600 step 50 do {

            _checkPos = _losPos getPos [_l, _watchDir];
            _checkPos = [_checkPos, 1.75] call pl_convert_to_heigth_ASL;
            _vis = lineIntersectsSurfaces [_losPos, _checkPos, objNull, objNull, true, 1, "FIRE"];

            if !(_vis isEqualTo []) exitWith {};

            // _m = createMarker [str (random 1), _checkPos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerColor "colorOrange";
            // _m setMarkerSize [0.5, 0.5];
            // _debugMarkers pushback _m;

            _losCount = _losCount + 1;
        };

        if !(isOnRoad [_losPos#0, _losPos#1, 0]) then {

            // systemChat (str _losPos);



            _validLosPos pushback [_losPos, _losCount];
        };
    };


    _validLosPos = [_validLosPos, [], {_x#1}, "DESCEND"] call BIS_fnc_sortBy;
    _winPos = [_winPos, [], {_x#2}, "DESCEND"] call BIS_fnc_sortBy;

    {
        if (((_x#2) > 6) and !([_x] call pl_is_indoor)) then {
            _validLosPos = [[_x, 10]] + _validLosPos;
        };
    } forEach _winPos;


    if (_group getVariable ["pl_allow_static", false]) then {
        _isStatic = [_units, _group, (_validLosPos#0)#0, _watchPos, _cords] call pl_static_unpack;

        if (_isStatic#0) then {
            _validLosPos deleteAt (_validLosPos find (_validLosPos#0));
            _units deleteAt (_units find ((_isStatic#1)#0));
        };
    };
    

    private _mgPos = [];

    if (_group getVariable ["pl_inf_attached", false]) then {
        _vicGroup = _group getVariable ["pl_attached_vicGrp", grpNull];
        _vicPos = ((_validLosPos#0)#0) getPos [25, _watchDir - 180];

        _vicGroup setVariable ["pl_in_position", true];

        if (((vehicle (leader _vicGroup)) distance2D _vicPos) > 75) then {
            (vehicle (leader _vicGroup)) doMove _vicPos;
            (vehicle (leader _vicGroup)) setDestination [_vicPos, "VEHICLE PLANNED", true];
            // [vehicle (leader _vicGroup), _vicPos, 3.5] spawn pl_vic_advance_to_pos_static;
        };
    };

    for "_i" from 0 to (count (_mgGunners + _atSoldiers)) - 1 do {
        _mgPos pushback ((_validLosPos#_i)#0);

        if (((_validLosPos#_i)#0) in _validPos) then {
            _validPos deleteAt (_validPos find ((_validLosPos#_i)#0));
        };
        _validLosPos deleteAt (_validLosPos find (_validLosPos#_i));
    };

    private _mgIdx = 0;
    private _losIdx = 0;
    private _debugMColor = "colorBlack";
    private _defPos = [];
    private _pos360 = [];

    // if (_defendMode == 1 and (_buildings isEqualTo [])) then {
    //     _validPos = [_group, _cords, pl_garrison_area_size] call pl_get_360;
    // };
    if (_defendMode == 1) then {
        if ((count _units) > 1) then {
            _pos360 = [_group, _cords, pl_garrison_area_size] call pl_get_360;
        } else {
            _pos360 = [_cords];
        };
    };

    sleep 0.5;


    // itterate over all units in group an choosing the bes possible position

    for "_i" from 0 to (count _units) - 1 step 1 do {

        private _cover = 0;
        private _isValidPos = false;
        _unit = _units#_i;
        _unitWatchDir = _watchDir;

        // move to optimal Pos first
        if (_i < (count _validPos) and _defendMode != 2) then {
            _defPos = _validPos#_i;
            _isValidPos = true;
            
            // if 360 choose valid position within 8m of 360 position
            if (_defendMode == 1) then {
                _defpos = ([_validPos, [], {_x distance2D (_pos360#_i)}, "ASCEND"] call BIS_fnc_sortBy)#0;
                if (_defpos distance2D (_pos360#_i) >= 8) then {
                    _defPos = _pos360#_i;
                } else {
                    _validPos deleteAt (_validPos find _defpos);
                };
            };

            _debugMColor = "colorBlack";
        }
        else
        {
            _cover = 5;
            // if no valid pos avaible move to left or right side of best cover deploy along a line
            if (_validPos isEqualTo [] or _defendMode == 2) then {
                _dirOffset = 90;
                if (_i % 2 == 0) then {_dirOffset = -90};
                _defPos = _cords getPos [_posOffset, _watchDir + _dirOffset];
                if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
                _debugMColor = "colorBlue";

                // dont stay on road
                if (isOnRoad [_defPos#0, _defPos#1, 0]) then {
                    if (_losIdx > (count _validLosPos) - 1) then {_losIdx = 1};
                    _defPos = (_validLosPos#_losIdx)#0;
                    _losIdx = _losIdx + 2;
                    _debugMColor = "colorOrange";
                };
            }
            else
            {
                // if all pos spend deploy along line
                if (_losIdx > (count _validLosPos) - 1) then {_losIdx = 1};
                _defPos = (_validLosPos#_losIdx)#0;
                _losIdx = _losIdx + 4;
                _debugMColor = "colorOrange";
            };

            // if 360 move to 360 pos
            if (_defendMode == 1) then {
                _defPos = _pos360#_i;
                _debugMColor = "colorBlue";
            };
        };

        // select best Medic Pos
        if ((!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) and _defendMode != 1) then {
            if (_unit == _medic) then {
                _defPos = _ccpPos;
                _debugMColor = "colorGreen";
                _cover = 5;
            };
        };

        // select Best Mg Pos
        if ((([secondaryWeapon _unit] call BIS_fnc_itemtype) select 1) in ["MissileLauncher", "RocketLauncher"]) then {
            _defPos = (_mgPos#_mgIdx);
            _mgIdx = _mgIdx + 1;
            _debugMColor = "colorRed";
            _cover = 2;
            _unit setVariable ["pl_sec_defPos", (_validLosPos#(round ((count _validLosPos) / 2)))#0];
        };

        if ((([primaryweapon _unit] call BIS_fnc_itemtype) select 1 == "MachineGun") and _defendMode != 1) then {
            _defPos = (_mgPos#_mgIdx);
            _mgIdx = _mgIdx + 1;
            _debugMColor = "colorRed";
            _cover = 2;
        };

        // no good positions escape
        if (isNil "_defPos") then {
            if !(_covers isEqualTo []) then {
                _defPos = getpos (selectRandom _covers);
                _debugMColor = "colorYellow";
            } else {
                _defPos = _cords findEmptyPosition [0, _defenceAreaSize];
                _debugMColor = "colorYellow";
            };
            _debugMColor = "colorGrey";
        };

        _defPos = ATLToASL _defPos;
        _unitPos = "UP";
        if ((!([_defPos] call pl_is_indoor) and !_isValidPos) or _defendMode == 1) then {
            _cover = 10;
        };

        _defPos = ASLToATL _defPos;

        if (_defendMode == 1) then {
            _watchDir = _cords getDir _defPos;
            _unitWatchDir = _watchDir;
        };

        // _m = createMarker [str (random 1), _defPos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerSize [0.5, 0.5];
        // _m setMarkerColor _debugMColor;
        // _debugMarkers pushback _m;

        // _helper = createVehicle ["Sign_Sphere25cm_F", _defPos, [], 0, "none"];
        // _helper setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];
        // _debugHelpers pushback _helper;

        // unit moveTo logic
        [_unit, _defPos, _watchPos, _unitWatchDir, _unitPos, _cover, _cords, _defenceAreaSize, _defenceWatchPos, _watchDir, _atEscord, _medic, _ccpPos, _markerDirName] spawn {
            params ["_unit", "_defPos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_cords", "_defenceAreaSize", "_defenceWatchPos", "_defenceDir", "_atEscord", "_medic", "_ccpPos", ["_markerDirName", ""]];
            private ["_check"];

            if (!(alive _unit) or isNil "_defPos") exitWith {};

            _unit setHit ["legs", 0];
            _unit setVariable ["pl_def_pos", _defPos];
            _unit setVariable ["pl_def_pos_sec", []];
            _unit setVariable ["pl_engaging", true];
            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            _unit disableAI "SUPPRESSION";
            _unit setUnitTrait ["camouflageCoef", 0.7, true];
            _unit setVariable ["pl_damage_reduction", true];
            // _unit forceSpeed 20;
            _unit doMove _defPos;
            sleep 1;
            private _counter = 0;
            private _posNotReached = false;

            // while {alive _unit and ((group _unit) getVariable ["onTask", false]) and (_unit distance _defPos) > 0.25 and !(unitReady _unit)} do {
            //     _time = time + 2;
            //     waitUntil {sleep 0.25; time > _time or !((group _unit) getVariable ["onTask", false]) or (_unit distance _defPos) < 2};
            //     _check = [_unit, _defPos, _counter] call pl_position_reached_check;
            //     if (_check#0) exitWith {_posNotReached = _check#3};
            //     _counter = _check#1;
            // };

            // if (_posNotReached) then {
            //     _unit domove _defPos;
            // };

            waitUntil {!alive _unit or !((group _unit) getVariable ["onTask", false]) or unitReady _unit};

            if (_unit distance2D _defPos > 2) then {
                _unit doMove _defPos;
                while {alive _unit and ((group _unit) getVariable ["onTask", false]) and (_unit distance _defPos) > 0.25 and !(unitReady _unit)} do {
                    _time = time + 2;
                    waitUntil {sleep 0.25; time > _time or !((group _unit) getVariable ["onTask", false]) or (_unit distance _defPos) < 2};
                    _check = [_unit, _defPos, _counter] call pl_position_reached_check;
                    if (_check#0) exitWith {_posNotReached = _check#3};
                    _counter = _check#1;
                };

                if (_posNotReached) then {
                    _unit domove _defPos;
                };

            };

            // sleep 0.25;
            _unit forceSpeed -1;
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "TARGET";
            _unit enableAI "SUPPRESSION";
            _unit setUnitPos "AUTO";

            if !((group _unit) getVariable ["onTask", true]) exitWith {};

            if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                if ((group _unit) getVariable ["pl_sop_def_ATEngagement", false]) then {
                    [_unit, group _unit, _cords, _defenceAreaSize, _defenceDir, _defPos, _atEscord] spawn pl_at_defence;
                    [_unit, _defPos, [], _ccpPos] spawn pl_at_defence_change_firing_pos;

                };
                sleep 0.1;
            };

            if (_unit == _medic) then {
                [(group _unit), _unit, _ccpPos, _defenceAreaSize * 2] spawn pl_defence_ccp;
            };
            if (_unit == (leader (group _unit)) and _markerDirName != "" and _unit != player) then {
                _markerDirName setMarkerPos (getPos _unit);
            };

            if ([_defPos] call pl_is_forest or [_defPos] call pl_is_city) then {
                [_unit, round (_cover * 0.5), _unitWatchDir, true] spawn pl_find_cover;
            } else {
                [_unit, _cover, _unitWatchDir, true] spawn pl_find_cover;
            };

            sleep 2;
            _unit setVariable ["pl_in_position", true];
        };
    };

    _breakingPoint = round (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) * 0.5);
    if (_breakingPoint >= ({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group))) then {_breakingPoint = -1};

    waitUntil {sleep 0.5; !(_group getVariable ["onTask", true]) or (({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _breakingPoint)};

    // if unit takes cassaulties they fall bag and take new position
    if ((({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _breakingPoint) and !_retreat and (_group getVariable ["pl_sop_def_disenage", false])) then {
        _group setVariable ["pl_in_position", nil];
        if (pl_enable_beep_sound) then {playSound "radioina"};
        if (pl_enable_map_radio) then {[_group, "...Falling Back!", 20] call pl_map_radio_callout};
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Falling Back", (groupId _group)]};

        private _retreatDistance = 150;
        if ([_cords] call pl_is_forest) then {_retreatDistance = 100} else {
        if ([_cords] call pl_is_city) then {_retreatDistance = 75}
        };

        _retreatPos = _cords getPos [_retreatDistance, _watchDir - 180];

        [_group, _retreatPos, true] spawn pl_disengage;
    };

    {
        pl_draw_building_array = pl_draw_building_array - [[_group, _x]];
    } forEach _validBuildings;

    if (_group getVariable ["pl_inf_attached", false]) then {
        _vicGroup = _group getVariable ["pl_attached_vicGrp", grpNull];
        _vicGroup setVariable ["pl_in_position", false];
    };


    waitUntil {sleep 0.5; !(_group getVariable ["onTask", true])};



    // deleteMarker _markerAreaName;
    deleteMarker _markerDirName;
    {deleteMarker _x} forEach _buildingMarkers;
    {deleteMarker _x} forEach _debugMarkers;
    {deleteVehicle _x} forEach _debugHelpers;

    if (_isStatic#0) then {
        _weapon = _group getVariable ["pl_group_static", objNull];
        if !(isNull _weapon) then {
            [_group, _weapon, _isStatic#1] call pl_static_pack;
        };
        (leader _group) removeWeapon "Binocular";
    };

    {
        _group leaveVehicle _x;
    } forEach _weapons;
};

pl_def_killed_disengage = { 
    params ["_group", "_cords", "_watchDir"];

    _group setVariable ["pl_def_kill_buffer", 0];
    _group setVariable ["pl_def_cords", _cords];
    _group setVariable ["pl_def_watchDir", _watchDir];

    // {
    //     _x addEventHandler ["Killed", {
    //         params ["_unit", "_killer", "_instigator", "_useEffects"];

    //         // if (vehicle _killer != _killer) then {
    //             [group _unit, _unit] call pl_on_kill_disengage;
   
    //         // };
    //     }];
    // } forEach (units _group);
};

// retreats group if 2 units KIA/WIA within 15 seconds of eachother;
pl_on_kill_disengage = {
    params ["_group", "_unit"];

    if ((_group getVariable ["pl_def_kill_retreat_cd", 0]) > time) exitWith {};

    if ((_group getVariable ["pl_def_kill_buffer", 0]) >= 1) then {

        private _cords = _group getVariable ["pl_def_cords", getPos _unit];
        private _watchDir = _group getVariable ["pl_def_watchDir", getdir _unit];

        if (pl_enable_beep_sound) then {playSound "radioina"};
        if (pl_enable_map_radio) then {[_group, "...Falling Back!", 20] call pl_map_radio_callout};
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Falling Back", (groupId _group)]};

        private _retreatDistance = 100;
        // if ([_cords] call pl_is_forest) then {_retreatDistance = 100} else {
        // if ([_cords] call pl_is_city) then {_retreatDistance = 75}
        // };

        _group setVariable ["pl_def_kill_buffer", 0];
        _group setVariable ["pl_def_kill_buffer_time", 0];
        _group setVariable ["pl_def_kill_retreat_cd", time + 60];
        _retreatPos = _cords getPos [_retreatDistance, _watchDir - 180];
        [_group, _retreatPos, true] spawn pl_disengage;

    } else {
        _group setVariable ["pl_def_kill_buffer", 1];
        _group setVariable ["pl_def_kill_buffer_time", time + 15];

        [_group] spawn {
            params ["_group"];

            sleep 1;

            waitUntil {sleep 1; time >= (_group getVariable ["pl_def_kill_buffer_time", time])};

            _group setVariable ["pl_def_kill_buffer_time", 0];
            _group setVariable ["pl_def_kill_buffer", 0];
        };
    };
};

// (!((group cursorTarget) getVariable ["onTask", false]) and !((group cursorTarget) getVariable ["pl_on_march", false]))
pl_at_defence_change_firing_pos= {
    params ["_unit", "_defPos", "_validLosPos", "_ccpPos"];

    _unit setVariable ["pl_at_reverse_pos", _ccpPos];
    _unit setVariable ["pl_defPos", _defPos];

    private _changeEw = _unit addEventHandler ["Fired", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

        if (([_weapon] call BIS_fnc_itemtype) select 1 in ["MissileLauncher", "RocketLauncher"] and ((getPosATL _unit)#2) < 2) then {

            [_unit, _weapon, _projectile, _magazine, _muzzle] spawn {
                params ["_unit", "_weapon", "_projectile", "_magazine", "_muzzle"];

                private _disposable = true;
                _missileCount = {toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit;
                // _missileCount = _missileCount + 1;

                // systemchat str (_missileCount);

                // if ((([secondaryWeapon _unit] call BIS_fnc_itemtype) select 1) == "MissileLauncher") then {
                    waitUntil {sleep 0.1; (speed _projectile) <= 0 or isNull _projectile};
                // } else {
                    // sleep 0.1;
                // };

                // sleep 0.1;

                _unit selectWeapon (primaryweapon _unit);

                [group _unit, getPos _unit] call pl_group_throw_smoke;
                [_unit] call pl_forget_unit;
                _unit setUnitCombatMode "BLUE";
                _unit enableAI "PATH";
                _unit disableAI "TARGET";
                _unit disableAI "AUTOTARGET";
                _unit disableAI "WEAPONAIM";
                _unit disableAI "FIREWEAPON";
                _unit setUnitPos "DOWN";
                _unit disableAI "AUTOCOMBAT";
                _unit setBehaviourStrong "AWARE";
                _unit disableAI "FSM";
                _unit forceSpeed 100;
                // _unit setVariable ['pl_is_at', true];
                private _chgPos = _unit getVariable ["pl_at_reverse_pos", getPos _unit];
                _unit doMove _chgPos;
                _unit setDestination [_chgPos, "LEADER DIRECT", true];
                _unit setUnitTrait ["camouflageCoef", 0.1, false];
                sleep 0.5;

                _loadedAmmo = _unit ammo _muzzle;
                // systemChat (str _loadedAmmo);

                if ((secondaryWeapon _unit) isNotEqualTo "") then {
                    _unit removeWeapon _weapon;
                    _unit switchMove "";
                    _disposable = false;
                    // sleep 0.1;
                    // _unit addWeapon _weapon;
                };

                // private _newMissileCount = ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit);
                private _time = time + 35;

                waitUntil {sleep 0.5; time >= _time or unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or (_unit distance2D _chgPos) <= 1 or lifeState _unit isEqualTo "INCAPACITATED" or _unit checkAIFeature "FIREWEAPON"};

                _newMissileCount = {toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit;

                // systemchat str (_newMissileCount);
                [_unit] call pl_forget_unit;
                _unit addWeapon _weapon;
                if (!_disposable and _newMissileCount < _missileCount) then {
                    _unit addMagazines [_magazine, 1];
                };
                _unit setUnitPos "AUTO";
                _unit setUnitCombatMode "YELLOW";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                _unit enableAI "WEAPONAIM";
                _unit enableAI "FIREWEAPON";
                _unit setUnitTrait ["camouflageCoef", 0.5, false];
                _unit enableAI "FSM";
                _unit forceSpeed -1;

                sleep 0.1;
                private _defPos = _unit getVariable ["pl_sec_defPos", getPos _unit];
                _unit doMove _defPos;

                _unit setVariable ["pl_sec_defPos", _unit getVariable ["pl_defPos", _defPos]];
                _unit setVariable ["pl_defPos", _defPos];

                waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or (_unit distance2D _defPos) <= 1 or lifeState _unit isEqualTo "INCAPACITATED"};

                // _unit setVariable ['pl_is_at', false];
                [_unit, 2, getDir _unit, true] spawn pl_find_cover;
            };

        };

    }];

    waitUntil {sleep 1; !((group _unit) getVariable ["onTask", true])};

    _unit removeEventHandler ["Fired", _changeEw];

};



pl_at_defence = {
    params ["_atSoldier", "_group", "_defencePos", "_defenceAreaSize", "_defenceDir", "_startPos", "_atEscord"];
    private ["_checkPosArray", "_watchPos", "_targets", "_debugMarkers", "_rifle"];

    _atEscord = objNull;

    sleep 0.5;

    _time = time + 10;
    waitUntil {sleep 0.5;  time >= _time or !(_group getVariable ["onTask", false])};
    if !(_group getVariable ["onTask", false]) exitWith {};

    _watchPos = (getPos _atSoldier) getPos [100, _defenceDir];

    private _weaponInfo = _atSoldier weaponsInfo [secondaryWeapon _atSoldier];
    private _weaponIndex = (_weaponInfo#0)#0;
    private _muzzleName = (_weaponInfo#0)#3;
    private _firemode = (_weaponInfo#0)#4;
    _rifle = primaryweapon _atSoldier;

    _defenceAreaSize = _defenceAreaSize + 50;


    while {sleep 0.5; alive _atSoldier and _group getVariable ["onTask", false]} do {

        // _group enableAttack true;

        if ((_atSoldier getVariable ["pl_wia", false]) or (((secondaryWeaponMagazine _atSoldier) isEqualTo []) and ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _atSoldier >> "magazines") apply {toUpper _x})} count magazines _atSoldier) <= 0)) then {
            _group setVariable ["pl_grp_active_at_soldier", nil];
            waitUntil {sleep 0.5; !(_atSoldier getVariable ["pl_wia", false]) and !((secondaryWeaponMagazine _atSoldier) isEqualTo [])};
        };

        if !((_group getVariable ["pl_grp_active_at_soldier", objNull]) == _atSoldier) then {
            waitUntil {sleep 0.5; !(_atSoldier getVariable ["pl_wia", false]) and !((secondaryWeaponMagazine _atSoldier) isEqualTo []) and (isNull (_group getVariable ["pl_grp_active_at_soldier", objNull]))};
        };

        _targets = (_watchPos nearEntities [["Car", "Tank", "Truck"], 300]) select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and speed _x <= 3 and alive _x and (count (crew _x) > 0) and (_atSoldier knowsAbout _x) >= 0.3};

        if (count _targets > 0 and !((secondaryWeaponMagazine _atSoldier) isEqualTo []) and _atSoldier checkAIFeature "FIREWEAPON") then {
            _targets = [_targets, [], {_x distance2D (getPos _atSoldier)}, "ASCEND"] call BIS_fnc_sortBy;
            _target = _targets#0;

            _debugMarkers = [];
            _checkPosArray = [];
            // _atkDir = _atSoldier getDir _target;

            _atkDir = _defencePos getDir _target;
            _lineStartPos = _startPos getPos [_defenceAreaSize, _atkDir - 90];
            _lineStartPos = _lineStartPos getPos [15, _atkDir];
            _lineOffset = 0;
            // for "_i" from 0 to (_defenceAreaSize / 2) do {
            for "_i" from 0 to 20 do {
                for "_j" from 0 to (_defenceAreaSize * 2) do { 
                    _checkPos = _lineStartPos getPos [_lineOffset, _atkDir + 90];
                    _lineOffset = _lineOffset + 1;

                    _checkPos = [_checkPos, 0.5] call pl_convert_to_heigth_ASL;

                    // _m = createMarker [str (random 1), _checkPos];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerSize [0.2, 0.2];
                    // _debugMarkers pushBack _m;

                    _vis = lineIntersectsSurfaces [_checkPos, AGLToASL (unitAimPosition _target), _target, vehicle _target, true, 1, "VIEW"];
                    // _vis2 = [_target, "VIEW", _target] checkVisibility [_checkPos, AGLToASL (unitAimPosition _target)];
                    if (_vis isEqualTo []) then {
                        _checkPosArray pushBack _checkPos;
                        // _m setMarkerColor "colorRED";
                    };
                };
                _lineStartPos = _lineStartPos getPos [1, _atkDir];
                _lineOffset = 0;
            };

            if (count _checkPosArray > 0 and !((secondaryWeaponMagazine _atSoldier) isEqualTo []) and _atSoldier checkAIFeature "FIREWEAPON") then {

                _target setVariable ["pl_at_enaged", true];

                [(group (driver _target)), true] call Pl_marta;

                // _group enableAttack true;

                _movePos = ([_checkPosArray, [], {_atSoldier distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;

                if (_movePos distance2D _atSoldier <= 80) then {

                    doStop _atSoldier;
                    _atSoldier enableAI "PATH";
                    _atSoldier setUnitPosWeak "Middle";
                    _atSoldier setUnitCombatMode "RED";
                    _atSoldier enableAI "FIREWEAPON";
                    _atSoldier enableAI "TARGET";
                    // _atSoldier enableAI "AUTOTARGET";
                    _atSoldier enableAI "WEAPONAIM";
                    _atSoldier enableAI "FIREWEAPON";
                    // _atSoldier disableAI "TARGET";
                    // _atSoldier disableAI "AUTOTARGET";
                    _atSoldier disableAI "AUTOCOMBAT";
                    // _atSoldier disableAI "FSM";
                    _atSoldier setBehaviourStrong "AWARE";
                    _atSoldier setUnitTrait ["camouflageCoef", 0.1, true];
                    _atSoldier setVariable ["pl_damage_reduction", true];
                    _atSoldier setVariable ['pl_is_at', true];
                    _atSoldier setVariable ["pl_engaging", true];

                    _atSoldier enableAI "PATH";
                    _atSoldier disableAI "AIMINGERROR";
                    _atSoldier disableAI "SUPPRESSION";


                    _group setVariable ["pl_grp_active_at_soldier", _atSoldier];
                    pl_at_attack_array pushBack [_atSoldier, _target, _atEscord];


                    _movePos = _movePos getpos [5, _movePos getdir _target];
                    _atSoldier setHit ["legs", 0];

                    _atSoldier reveal [_target, 4];
                    _atSoldier doTarget objNull;
                    _atSoldier doWatch _target;
                    _atSoldier doMove _movePos;

                    // _m = createMarker [str (random 1), _movePos];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerColor "colorGreen";
                    // _m setMarkerSize [0.7, 0.7];
                    // _debugMarkers pushBack _m;


                    _time = time + (((_atSoldier distance _movePos) / 1.6) + 10);
                    
                    // _atSoldier commandTarget _target;
                    // _atSoldier commandFire _target;

                    waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", false]) or !alive _target or ((secondaryWeaponMagazine _atSoldier) isEqualTo []) or ((secondaryWeapon _atSoldier) isEqualTo "")};

                    if (time >= _time) then {
                        _atSoldier doMove _defencePos;
                    };
                    // _atSoldier enableAI "FSM";
                    // pl_at_attack_array = pl_at_attack_array - [[_atSoldier, _movePos]];
                };
            };

            pl_at_attack_array = pl_at_attack_array - [[_atSoldier, _target, _atEscord]];
            _atSoldier setVariable ['pl_is_at', false];
            _atEscord setVariable ['pl_is_at', false];
        };
        _timeOut = time + 5;
        waitUntil {sleep 0.5; time >= _timeOut or !((group _atSoldier) getVariable ["onTask", false])};
    };

    _group enableAttack false;
    _group setVariable ["pl_grp_active_at_soldier", nil];
    if !(isNil "_target") then {pl_at_attack_array = pl_at_attack_array - [[_atSoldier, _target, _atEscord]]}; 
};


pl_defence_suppression = {
    params ["_group", "_watchPos", "_medic"];
    private ["_targetsPos", "_firers", "_target", "_allPos"];

    private  _time = time + 20;
    waitUntil {sleep 0.5;  time >= time or !(_group getVariable ["onTask", true]) };
    if !(_group getVariable ["onTask", true]) exitWith {};
    _allPos = [];

    private _allTargets = [];

    while {_group getVariable ["onTask", false]} do {
        waitUntil {sleep 0.5; !(_group getVariable ["pl_hold_fire", false]) and !(_group getVariable ["pl_is_suppressing", false]) and (isNull (_group getVariable ["pl_grp_active_at_soldier", objNull]))};
        // _allTargets = nearestObjects [_watchPos, ["Man", "Car"], 350, true];
        _enemyTargets = (_watchPos nearEntities [["Man", "Car"], 275]) select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and ((leader _group) knowsAbout _x) >= 0.2};
        if (count _enemyTargets > 0) then {
            _firers = [];

            if (_group getVariable ["pl_inf_attached", false]) then {
                _vicGroup = _group getVariable ["pl_attached_vicGrp", grpNull];
                _firers pushBack (gunner (vehicle (leader _vicGroup)));
            };

            {
                if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                    _firers pushBackUnique _x;
                    _x setUnitTrait ["camouflageCoef", 0.5, false];
                    _x setVariable ["pl_damage_reduction", true];
                } else {
                    if ((random 1) > 0.5) then {_firers pushBackUnique _x;}
                };
            } forEach ((units _group) select {!(_x checkAIFeature "PATH") and _x != _medic and !(([secondaryWeapon _x] call BIS_fnc_itemtype) select 1 in ["MissileLauncher", "RocketLauncher"])});
            {
                _unit = _x;
                _target = selectRandom _enemyTargets;
                if (vehicle _unit != _unit) then {
                    _target = ([_enemyTargets, [], {([_group] call pl_find_centroid_of_group) distance2D _x}, "DESCEND"] call BIS_fnc_sortBy)#0;
                };
                _targetPos = getPosASL _target;
                _targetPos = [_targetpos, _unit] call pl_get_suppress_target_pos;
                if ((random 1) > 0.8) then {
                    [_x, selectRandom _enemyTargets] spawn pl_fire_ugl_at_target;
                };
                if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !(_group getVariable ["pl_hold_fire", false]) and _targetPos isNotEqualTo [0,0,0]) then {
                    if (((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") or vehicle _unit != _unit) then { 
                        if !([_unit, _targetPos] call pl_friendly_check_strict) then {
                        // if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_unit, _targetPos] call pl_friendly_check_strict) and (_unit distance2D _targetPos) > _targetDistance * 0.15) then {
                            _unit doWatch _targetPos;
                            _unit doSuppressiveFire _targetPos;
                            _allTargets pushback (getPosATLVisual _target);
                        };
                    } else {
                        if !([_unit, _targetPos] call pl_friendly_check) then {
                        // if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_unit, _targetPos] call pl_friendly_check) and (_unit distance2D _targetPos) > _targetDistance * 0.15) then {
                            _unit doWatch _targetPos;
                            _unit doSuppressiveFire _targetPos;
                            _allTargets pushback (getPosATLVisual _target);
                        };
                    };
                };
            } forEach _firers;

            if !(_allTargets isEqualto []) then {
                _allPos = [_allTargets] call pl_find_centroid_of_points;

                pl_suppression_poses pushback [_allPos, _group];
            };

            _time = time + 25;
            waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true])};

            
        };
        _time = time + 5;
        waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true])};

        if !(_allPos isEqualto []) then {
            pl_suppression_poses = pl_suppression_poses - [[_allPos, _group]];
        };
    };
};



pl_defence_rearm = {
    params ["_group", "_defencePos", "_medic"];
    private ["_ammoCargo"]; 

    private  _time = time + 20;
    waitUntil {sleep 0.5;  time >= time or !(_group getVariable ["onTask", true]) };
    if !(_group getVariable ["onTask", true]) exitWith {};

    while {sleep 0.5; _group getVariable ["onTask", true] and (count (units _group)) > 3} do {

        // _supplyPoints = (nearestObjects [_defencePos, ["Car", "Tank"], 255, true]) select {(_x getVariable ["pl_is_rearm_point", false]) and (_x getVariable ["pl_supplies", 0]) > 0};
        private _supplyPoints = (_defencePos nearEntities [["Car", "Tank"], 255]) select {(_x getVariable ["pl_is_rearm_point", false]) and (_x getVariable ["pl_supplies", 0]) > 0};
        private _attachedVic = objNull;

        if (_group getVariable ["pl_inf_attached", false]) then {
            _vicGroup = _group getVariable ["pl_attached_vicGrp", grpNull];
            _attachedVic = vehicle (leader _vicGroup);

            if ((_attachedVic getVariable ["pl_supplies", 0]) > 0) then {
                _supplyPoints = [_attachedVic];
            };
        };

        if (count _supplyPoints > 0) then {
            _supplyPoint = ([_supplyPoints, [], {_defencePos distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;
            _ammoCargo = _supplyPoint getVariable ["pl_supplies", 0];

            if ((([_group] call pl_get_ammo_group_state)#0) isEqualTo "Red" or (([_group] call pl_get_at_status)#0) or (([_group] call pl_get_mg_status)#0)) then {
                _supplySoldier = {
                    if (_x != (leader _group) and ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun") and (secondaryWeapon _x == "") and !(_x checkAIFeature "PATH") and !(getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1)) exitWith {_x};
                    objNull
                } foreach (units _group);

                if (isNull _supplySoldier) then {_supplySoldier = selectRandom ((units _group) select {_x != (leader _group)})};

                if (_supplyPoint != _attachedVic) then {

                    if !(isNull _supplySoldier) then {

                        _supplyPos = (getPos _supplyPoint) getPos [10, (getdir _supplyPoint) - 180];
                        _startPos = _supplySoldier getVariable ["pl_def_pos", _defencePos];
                        _supplySoldier enableAI "PATH";
                        _supplySoldier setBehaviourStrong "AWARE";
                        _supplySoldier setUnitCombatMode "BLUE";
                        _supplySoldier disableAI "TARGET";
                        _supplySoldier disableAI "AUTOTARGET";
                        _supplySoldier disableAI "COVER";
                        _supplySoldier disableAI "AUTOCOMBAT";
                        _supplySoldier setUnitPos "AUTO";
                        _supplySoldier setVariable ["pl_is_ccp_medic", true];
                        _supplySoldier setVariable ["pl_engaging", true];
                        _supplySoldier setHit ["legs", 0];

                        pl_supply_draw_array pushBack [_defencePos, _supplyPos, [0.9,0.7,0.1,0.8]];
                        _supplySoldier doMove _supplyPos;
                        [_supplySoldier, _supplyPos] call pl_force_move_on_task;
                        // _supplySoldier setDestination [_supplyPos, "LEADER DIRECT", true];


                        sleep 0.2;

                        // _timeOut = time + 80;
                        // waitUntil {sleep 0.5; ((_supplySoldier distance2D _supplyPos) < 5) or (!alive _supplySoldier) or !((group _supplySoldier) getVariable ["onTask", true]) or time > _timeOut};

                        if !((group _supplySoldier) getVariable ["onTask", true]) exitWith {pl_supply_draw_array = pl_supply_draw_array - [[_defencePos, _supplyPos, [0.9,0.7,0.1,0.8]]]};

                        // if (time > _timeOut) then {continue};
                        doStop _supplySoldier;
                        _time = time + 10;
                        waitUntil {sleep 1; time >= _time or !((group _supplySoldier) getVariable ["onTask", true])};

                        _supplySoldier setHit ["legs", 0];
                        _supplySoldier doMove _startPos;
                        [_supplySoldier, _startPos] call pl_force_move_on_task;
                        // _supplySoldier setDestination [_startPos, "LEADER DIRECT", true];

                        // waitUntil {sleep 0.5; unitReady _supplySoldier or ((_supplySoldier distance2D _startPos) < 6) or (!alive _supplySoldier) or !((group _supplySoldier) getVariable ["onTask", true])};

                        pl_supply_draw_array = pl_supply_draw_array - [[_defencePos, _supplyPos, [0.9,0.7,0.1,0.8]]];

                        _supplySoldier setVariable ["pl_is_ccp_medic", false];
                        _supplySoldier enableAI "TARGET";
                        _supplySoldier enableAI "AUTOTARGET";
                        _supplySoldier enableAI "COVER";
                        _supplySoldier enableAI "AUTOCOMBAT";
                        _supplySoldier setVariable ["pl_engaging", false];
                        _supplySoldier setUnitCombatMode "YELLOW";

                        if (alive _supplySoldier and ((group _supplySoldier) getVariable ["onTask", true]) and (_supplySoldier distance2D _startPos) < 15) then {
                            [_supplySoldier, 15,  getDir _supplySoldier] spawn pl_find_cover;

                            {
                                if (_ammoCargo > 0) then {
                                    _loadout = _x getVariable "pl_loadout";
                                    if !((getUnitLoadout _x) isEqualTo _loadout) then {
                                        _x setUnitLoadout [_loadout, true];
                                        _ammoCargo = _ammoCargo - 1;
                                    };
                                    sleep 2;
                                };
                            } forEach (units _group);
                            _supplyPoint setVariable ["pl_supplies", _ammoCargo];
                        } else {
                            _supplySoldier doFollow (leader _group);
                        };
                    };
                } else {
                    {
                        if (_ammoCargo > 0) then {
                            _loadout = _x getVariable "pl_loadout";
                            if !((getUnitLoadout _x) isEqualTo _loadout) then {
                                _x setUnitLoadout [_loadout, true];
                                _ammoCargo = _ammoCargo - 1;
                            };
                            sleep 2;
                        };
                    } forEach (units _group);
                    _supplyPoint setVariable ["pl_supplies", _ammoCargo];
                };
            };
        };

        _time = time + 10;
        waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", false])};

    };
};

pl_defence_ccp = {
    params ["_group", "_medic", "_ccpPos", ["_area", 50]];

    private  _time = time + 10;
    waitUntil {sleep 0.5;  time >= time or !(_group getVariable ["onTask", true]) };
    if !(_group getVariable ["onTask", true]) exitWith {};

    _medic setVariable ["pl_is_ccp_medic", true];

    while {(_group getVariable ["onTask", true]) and alive _medic and !(_medic getVariable ["pl_wia", false])} do {

        waitUntil {sleep 0.5; _group getVariable ["pl_healing_active", false] or !(_group getVariable ["onTask", true])};

        // if (_medic distance2D _ccpPos) > 5 then {
        //     doStop _medic;
        //     _medic doMove _ccpPos;
        // };

        _time = time + 5;
        waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true])};
        {
            if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet") and ((_x distance2D _medic) <= (_area * 2))) then {
                // _medic setUnitPosWeak "MIDDLE";
                _medic enableAI "PATH";
                _h1 = [_group, _medic, objNull, _x, _ccpPos, 20, "onTask", 0, true] spawn pl_ccp_revive_action;
                waitUntil {sleep 0.5; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                sleep 1;
                [_x] spawn pl_move_back_to_def_pos;
            };
        } forEach (units _group);

        if (_medic distance2D (_medic getVariable ["pl_def_pos", getpos _medic]) > 10) then {
            [_medic] call pl_move_back_to_def_pos;
        };
    };
    _medic setVariable ["pl_is_ccp_medic", false];
};

pl_move_back_to_def_pos = {
    params ["_unit"];

    private _time = time + 5;
    waitUntil {sleep 0.5; time >= _time or !((group _unit) getVariable ["onTask", true]) };
    if !((group _unit) getVariable ["onTask", true]) exitWith {};

    _movePos = _unit getVariable ["pl_def_pos", []];

    if !(_movePos isEqualTo []) then {
        _unit switchmove "";
        doStop _unit;
        _unit enableAI "PATH";
        _unit disableAI "AUTOCOMBAT";
        _unit disableAI "AUTOTARGET";
        _unit disableAI "TARGET";
        _unit doMove _movePos;
        // _unit setDestination [_movePos, "LEADER DIRECT", true];
        waitUntil {sleep 0.5; (_unit distance2D _movePos) < 4 or !(alive _unit) or !((group _unit) getVariable ["onTask", true])};
        // private _counter = 0;
        // while {alive _unit and ((group _unit) getVariable ["onTask", true])} do {
        //     sleep 0.5;
        //     _dest = [_unit, _movePos, _counter] call pl_position_reached_check;
        //     if (_dest#0) exitWith {};
        //     _movePos = _dest#1;
        //     _counter = _dest#2;
        // };
        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        sleep 0.5;
        [_unit, 0,  getDir _unit] spawn pl_find_cover;
    } else {
        _unit doFollow (leader (group _unit));
    };
};



pl_defend_position_vehicle = {
    params ["_group", "_watchPos", "_cords", "_markerName", "_watchDir", "_sfp", "_retreat"];
    private ["_tankFireposChangeEH", "_getMissileincPosChangeEH", "_getHitposChagneEH"];

    private _vic = vehicle (leader _group);

    // _vic doMove _cords;
    // _vic setDestination [_cords,"VEHICLE PLANNED" , true];
    private _breakingPoint = (1 - (getDammage _vic)) * 0.8;

    sleep 1;

    [_vic, _cords] call pl_advance_to_pos_switch;

    // waitUntil {sleep 0.5; unitReady _vic or _vic distance2d _cords < 15 or !(_group getVariable ["onTask", false]) or !alive _vic};

    if (!(_group getVariable ["onTask", true]) or !alive _vic) exitWith {deleteMarker _markerName};
    // _pos = [_vic, _watchDir] call pl_get_turn_vehicle;
    // _vic doMove _pos;

    [_vic, (getPos _vic) getPos [100, _watchDir]] call pl_vic_turn_in_place;

    sleep 0.5;

    // waitUntil {sleep 0.5; unitReady _vic or !(_group getVariable ["onTask", false]) or !alive _vic};

    if (!(_group getVariable ["onTask", true]) or !alive _vic) exitWith {deleteMarker _markerName};

    sleep 0.5;

    _group setVariable ["pl_in_position", true];

    if (_group getVariable ["pl_has_cargo", false] or _group getVariable ["pl_vic_attached", false]) then {

        private _infGroup = grpNull;
        if (_group getVariable ["pl_has_cargo", false]) then {

            private _cargo = (crew _vic) - (units _group);

            private _cargoGroups = [];
            {
                _unit = _x;

                if !(_unit in (units (group player))) then {
                    _cargoGroups pushBack (group _unit);
                };

            } forEach _cargo;

            private _limit = 0;
            {
                if ((count (units _x)) > _limit) then {
                    _limit = count (units _x);
                    _infGroup = _x;
                };
                // [_x] spawn pl_reset;
            } forEach _cargoGroups;

            if !(_infGroup getVariable ["pl_show_info", false]) then {
                [_infGroup] call pl_show_group_icon;
            };


            if !(isNull _infGroup) then {
                [_infGroup, _cargo, _vic, 90, 4] call pl_combat_dismount;
            };

            _vic setVariable ["pl_on_transport", nil];
            _group setVariable ["pl_has_cargo", false];

            waitUntil {sleep 0.5; (({vehicle _x != _x} count (units _infGroup)) == 0) or (!alive _vic) or !(_group getVariable ["onTask", false])};
            sleep 0.5;
            _timeOut = time + 7;
            waitUntil {sleep 0.5; time >= _timeOut or ({unitReady _x or (lifeState _x isEqualTo "INCAPACITATED") or !alive _x} count (units _infGroup)) == (count (units _infGroup)) or !(_group getVariable ["onTask", false])};

            // {
            //     player hcSetGroup [_x];
            // } forEach _cargoGroups;

        } else {
            _infGroup = _group getVariable ["pl_attached_infGrp", grpNull];
            _infGroup setVariable ["pl_task_planed", true];
            _group setVariable ["pl_vic_attached", false];
            _group setVariable ["pl_attached_infGrp", nil];

            // [units _infGroup, _cords, _watchDir, 45, false] spawn pl_get_to_cover_positions;
            sleep 0.5;
            [_infGroup, units _infGroup, _vic, 90, 4] call pl_combat_dismount;
            sleep 0.5;
            _timeOut = time + 15;
             waitUntil {sleep 0.5; time >= _timeOut or ({(_x getVariable ["pl_in_position", false]) or (lifeState _x isEqualTo "INCAPACITATED") or !alive _x} count (units _infGroup)) == (count (units _infGroup)) or !(_group getVariable ["onTask", false])};
        };

        sleep 0.1;

        deleteMarker _markerName;
        private _defPos = (getPos _vic) getPos [-5, _watchDir];

        if (_group getVariable ["onTask", false]) then {

            // [_infGroup, [], _defPos , _watchDir] spawn pl_defend_position;

            _infGroup setVariable ["onTask", true];
            _infGroup setVariable ["pl_task_pos", _cords];
            _infGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"];
            _infGroup setVariable ["setSpecial", true];
            _infGroup setVariable ["pl_task_planed", false];

            sleep 0.1;

            // [_group, _infGroup] spawn pl_attach_vic;

            if (_infGroup getVariable ["pl_sop_def_suppress", false]) then {
                [_infGroup, _cords getPos [250, _watchDir], objNull] spawn pl_defence_suppression;
            };

            {
                _unit = _x;
                if (_unit checkAIFeature "PATH") then {
                    [_unit, 0, _watchDir] spawn pl_find_cover;
                };
                _unit setUnitTrait ["camouflageCoef", 0.7, true];
                _unit setVariable ["pl_damage_reduction", true];
                _unit setVariable ["pl_def_pos", getPos _unit];
                _unit setVariable ["pl_def_pos_sec", []];
                _unit setVariable ["pl_engaging", true];
                if (getNumber ( configFile >> "CfgVehicles" >> typeOf _unit >> "attendant" ) isEqualTo 1) then {
                    [(group _unit), _unit, getpos _unit, 50] spawn pl_defence_ccp;
                };
                if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                    if ((group _unit) getVariable ["pl_sop_def_ATEngagement", false]) then {
                        [_unit, group _unit, _cords, 50, _watchDir, getPos _unit, objNull] spawn pl_at_defence;
                    };
                    sleep 0.1;
                };

            } forEach (units _infGroup);
        };

    } else {
        _markerName setMarkerPos (getPos _vic);
        private _crew = [];
        {
            _x setVariable ["pl_damage_reduction", true];
            _x setUnitTrait ["camouflageCoef", 0.5, true];
            _x disableAI "PATH";
            _crew pushBackUnique _x;
        } forEach (units _group);
        {
            _x setVariable ["pl_damage_reduction", true];
            _crew pushBackUnique _x;
        } forEach (crew _vic);


        _vic setVariable ["pl_tank_defpos_1", _cords];


        _getMissileincPosChangeEH = _vic addEventHandler ["IncomingMissile", {
            params ["_target", "_ammo", "_vehicle", "_instigator", "_missile"];

            _unit = _target;

            if !(_unit getVariable ["pl_tank_def_move", false]) then {

                _unit setVariable ["pl_tank_def_move", true];

                _unit doTarget _vehicle;

                [_unit] spawn {
                    params ["_unit"];

                    _startPos = _unit getVariable ["pl_tank_defpos_1", getPosASLVisual _unit];

                    sleep 0.5;

                    [_unit, _unit getPos [-20, getDirVisual _unit] , 10, 0.5] call pl_vic_reverse_to_pos;

                    _time = time + 10;

                    waitUntil {sleep 0.5; time >= _time or !(group (driver _unit) getVariable ["onTask", false]) or !(alive _unit)};

                    if !(group (driver _unit) getVariable ["onTask", false]) exitWith {};

                    [_unit, _startPos , 10, 1.5] call pl_vic_advance_to_pos_static;

                    _time = time + 2;

                    waitUntil {sleep 0.5; time >= _time or !(group (driver _unit) getVariable ["onTask", false]) or !(alive _unit)};

                    _unit setVariable ["pl_tank_def_move", nil];
                };

            };
        }];

        _getHitposChagneEH = _vic addEventHandler ["Hit", {
            params ["_unit", "_source", "_damage", "_instigator"];


            if !(_unit getVariable ["pl_tank_def_move", false]) then {

                _unit setVariable ["pl_tank_def_move", true];

                _unit doTarget _source;

                [_unit] spawn {
                    params ["_unit"];

                    _startPos = _unit getVariable ["pl_tank_defpos_1", getPosASLVisual _unit];

                    sleep 0.5;

                    [_unit, _unit getPos [-20, getDirVisual _unit] , 10, 0.5] call pl_vic_reverse_to_pos;

                    _time = time + 10;

                    waitUntil {sleep 0.5; time >= _time or !(group (driver _unit) getVariable ["onTask", false]) or !(alive _unit)};

                    if !(group (driver _unit) getVariable ["onTask", false]) exitWith {};

                    [_unit, _startPos , 10, 1.5] call pl_vic_advance_to_pos_static;

                    _time = time + 2;

                    waitUntil {sleep 0.5; time >= _time or !(group (driver _unit) getVariable ["onTask", false]) or !(alive _unit)};

                    _unit setVariable ["pl_tank_def_move", nil];
                };

            };
        }];



        if (_vic isKindOf "Tank" and ([_vic] call pl_is_tank)) then {

            _tankFireposChangeEH = _vic addEventHandler ["Fired", {
                params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

                if ((["CANNON", toUpper _weapon] call BIS_fnc_inString or ["120", _weapon] call BIS_fnc_inString or ["105", _weapon] call BIS_fnc_inString or ["125", _weapon] call BIS_fnc_inString) and !(_unit getVariable ["pl_tank_def_move", false])) then {

                    // _unit removeEventHandler [_thisEvent, _thisEventHandler];

                    _unit setVariable ["pl_tank_def_move", true];

                    [_unit] spawn {
                        params ["_unit"];

                        _startPos = _unit getVariable ["pl_tank_defpos_1", getPosASLVisual _unit];

                        sleep 0.5;

                        [_unit, _unit getPos [-20, getDirVisual _unit] , 8, 0.5] call pl_vic_reverse_to_pos;

                        if !(group (driver _unit) getVariable ["onTask", false]) exitWith {};

                        _time = time + 4;

                        waitUntil {sleep 0.5; time >= _time or !(group (driver _unit) getVariable ["onTask", false]) or !(alive _unit)};

                        if !(group (driver _unit) getVariable ["onTask", false]) exitWith {};

                        [_unit, _startPos , 6, 0.5] call pl_vic_advance_to_pos_static;

                        _time = time + 2;

                        waitUntil {sleep 0.5; time >= _time or !(group (driver _unit) getVariable ["onTask", false]) or !(alive _unit)};

                        _unit setVariable ["pl_tank_def_move", nil];

                    };

                };

            }];

        };


        // waitUntil {sleep 0.5; !(_group getVariable ["onTask", false]) or !alive _vic or (1 - (getDammage _vic)) <= _breakingPoint};

        private _vicWatchPos = (getPos _vic) getPos [600, _watchDir]; 

        // _m = createMarker [str (random 1), _vicWatchPos];
        // _m setMarkerShape "ELLIPSE";
        // _m setMarkerBrush "SolidBorder";
        // _m setMarkerSize [800, 800];

        while {sleep 0.5; (_group getVariable ["onTask", false]) and alive _vic and (1 - (getDammage _vic)) > _breakingPoint} do {
            _vicTargets = _vicWatchPos nearEntities [["Car", "Truck", "Tank"], 800] select {alive _x and (side _x) != playerSide and (_group knowsAbout _x) > 0};

            if !(_vicTargets isEqualTo []) then {

                _vicTargets = ([_vicTargets, [], {_x distance2D _vic}, "ASCEND"] call BIS_fnc_sortBy);
                _weapon = [_vic] call pl_get_weapon;
                _turretPath = _vic unitTurret (gunner _vic);

                {
                    _vic doTarget _x;
                    _vic doFire _x;
                    _timeOut = time + 8;
                    waitUntil {sleep 0.1; !(_group getVariable ["onTask", false]) or ((_vic aimedAtTarget [_x, _weapon]) > 0.5 and ((weaponState [_vic, _turretPath, _weapon])#5 <= 0.2)) or time >= _timeOut};
                    if (_group getVariable ["onTask", true] and time < _timeOut) then {
                        [_vic , _weapon] call BIS_fnc_Fire;
                        // _fired = _vic fireAtTarget [_x, _weapon];
                        sleep 0.5;
                    }
                } forEach _vicTargets;

            };

            _time = time + 20;
            waitUntil {sleep 0.5; !(_group getVariable ["onTask", false]) or !alive _vic or (1 - (getDammage _vic)) <= _breakingPoint or time >= _time};
        };

        if (_vic isKindOf "Tank" and ([_vic] call pl_is_tank)) then {
            _vic removeEventHandler ["Fired", _tankFireposChangeEH];
        };

        _vic removeEventHandler ["Hit", _getHitposChagneEH];
        _vic removeEventHandler ["IncomingMissile", _getMissileincPosChangeEH]; 
        _vic setVariable ["pl_tank_def_move", nil];
        _vic setVariable ["pl_tank_defpos_1", nil];

        deleteMarker _markerName;
        {
            _x setVariable ["pl_damage_reduction", false];
            _x setUnitTrait ["camouflageCoef", 1, true];
        } forEach _crew;

        if ((1 - (getDammage _vic)) <= _breakingPoint and !_retreat) then {
            _group setVariable ["pl_in_position", nil];
            if (pl_enable_beep_sound) then {playSound "radioina"};
            if (pl_enable_map_radio) then {[_group, "...Falling Back!", 20] call pl_map_radio_callout};
            if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Falling Back", (groupId _group)]};

            private _retreatDistance = 100;
            if ([_cords] call pl_is_city) then {_retreatDistance = 45};

            _retreatPos = _cords getPos [_retreatDistance, _watchDir - 180];

            sleep 1;

            [_group, _retreatPos, true] spawn pl_disengage;
        };
    };
};


// "AmovPknlMstpSrasWrflDnon_AmovPknlMevaSrasWrflDr"
