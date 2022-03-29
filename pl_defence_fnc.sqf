pl_covers = [];
pl_defence_cords = [0,0,0];
pl_mapClicked = false;
pl_denfence_draw_array = [];
pl_draw_building_array = [];
pl_building_search_cords = [0,0,0];
pl_garrison_area_size = 20; 
pl_mapClicked = false;
pl_360_area = false;
pl_show_watchpos_selector = false;
pl_at_attack_array = [];
pl_valid_covers = ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "BUILDING"];
pl_valid_walls = ["Land_City_8mD_F", "Land_City2_8mD_F", "Land_Stone_8mD_F", "Land_Mil_ConcreteWall_F", "Land_Mound01_8m_F", "Land_Mound02_8m_F", "Land_City_Gate_F", "Land_Stone_Gate_F"];

// // _helper = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
// // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
// // _helper setposASL _checkPos;

pl_find_cover = {
    params ["_unit", "_watchPos", "_watchDir", "_radius", "_moveBehind", ["_fullCover", false], ["_inArea", ""], ["_fofScan", false]];
    private ["_valid"];

    _covers = nearestTerrainObjects [getPos _unit, pl_valid_covers, _radius, true, true];
    // _unit enableAI "AUTOCOMBAT";
    _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _watchPos;
    if ((count _covers) > 0) then {
        {
            _valid = true;
            if !(_inArea isEqualTo "") then {
                if !(_x inArea _inArea) then {
                    _valid = false;
                };
            };

            if (!(_x in pl_covers) and _valid) exitWith {
                pl_covers pushBack _x;
                _coverPos = getPos _x;
                _unit doMove _coverPos;
                sleep 0.5;
                waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or unitReady _unit};
                if ((group _unit) getVariable ["onTask", true]) then {
                    if (_moveBehind) then {
                        _coverPos =  (getPos _unit) getPos [0.5, _watchDir - 180];
                        _unit doMove _coverPos;
                        sleep 0.5;
                        waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or unitReady _unit};
                    };
                    if ((group _unit) getVariable ["onTask", true]) then {
                        _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
                        _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
                        _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
                        if (_visP isEqualTo []) then {
                            _unit setUnitPos "DOWN";
                        } 
                        else
                        {
                            _unit setUnitPos "MIDDLE";
                        };

                        if (_fullCover) then {
                            _unit setUnitPos "DOWN";
                        };

                        doStop _unit;
                        _unit doWatch _watchPos;
                        _unit disableAI "PATH";
                    };
                    [_x] spawn {
                        params ["_cover"];
                        sleep 5;
                        pl_covers deleteAt (pl_covers find _cover);
                    };
                };
            };
        } forEach _covers;

        if ((unitPos _unit) == "Auto" and ((group _unit) getVariable ["onTask", false])) then {
            _unit setUnitPos "DOWN";
            doStop _unit;
            _unit doWatch _watchPos;
            _unit disableAI "PATH";
        };
    }
    else
    {
        _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
        _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
        _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
        if (_visP isEqualTo []) then {
            _unit setUnitPos "DOWN";
        } 
        else
        {
            _unit setUnitPos "MIDDLE";
        };
        doStop _unit;
        _unit doWatch _watchPos;
        _unit disableAI "PATH";
    };
    if (_fofScan) then {
        private _c = 0;
        _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
        for "_i" from 10 to 260 step 50 do {
            _checkPos = [(getPos _unit) getPos [_i, _watchDir], 1] call pl_convert_to_heigth_ASL;

            _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
            if (_visP isEqualTo []) then {
                _c = _c + 1;
            };
        };
        if (_c >= 5) then {
            _unit setUnitPos "DOWN";
        } else {
            _unit setUnitPos "MIDDLE";
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
    waitUntil {sleep 0.5; (unitReady _unit) or (!alive _unit) or ((group _unit) getVariable ["onTask", false]) or (count (waypoints (group _unit)) > 0)};
    if (!((group _unit) getVariable ["onTask", true]) and (count (waypoints (group _unit)) <= 0)) then {
        doStop _unit;
        _unit setUnitPos "MIDDLE";
        _unit disableAI "PATH";
    };
    sleep 10;
    pl_covers = []
};


pl_deploy_static = false;

pl_garrison = {
    private ["_mPos", "_building", "_buildingOld", "_buildingMarker"];
  
    private _group = (hcSelected player) select 0;

    if (visibleMap) then {
        hintSilent "";

        

        private _rangelimiterCenter = getPos (leader _group);
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
        if (pl_cancel_strike) exitWith {};
        deleteMarker _markerBorderName;
        if (_buildingMarker == "") exitWith {};
        _buildingMarker setMarkerAlpha 0.5;
    } else {
        _building = cursorTarget;
        if (isNull _building) exitWith {};
    };

    pl_draw_building_array pushBack [_group, _building];

    [_group] spawn pl_reset;
    sleep 0.5;
    [_group] spawn pl_reset;
    sleep 0.5;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"];

    _buildingPositions = [_building] call BIS_fnc_buildingPositions;
    _units = units _group;

    if ((count _buildingPositions) < (count _units)) then {
        for "_j" from 0 to ((count _buildingPositions) - (count _units)) do {
            _buildingPositions pushback [[[getPos _building, 60]], [objNull, _buildingMarker, [getPos _building, 15]]] call BIS_fnc_randomPos;
        };
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

            // _m = createMarker [str (random 1), _pos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];

            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            // _unit disableAI "FSM";
            _unit doMove _pos;
            _unit setDestination [_pos, "LEADER DIRECT", true];
            sleep 1;
            private _counter = 0;
            while {alive _unit and ((group _unit) getVariable ["onTask", true])} do {
                sleep 0.5;
                _dest = [_unit, _pos, _counter] call pl_position_reached_check;
                if (_dest#0) exitWith {};
                _pos = _dest#1;
                _counter = _dest#2;
                _time = time + 3;
                waitUntil{sleep 0.5; time >= _time or !((group _unit) getVariable ["onTask", true])};
            };
            // waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
            doStop _unit;
            _unit disableAI "PATH";
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "TARGET";
            if (_cover) then {
                [_unit, getPos _unit, getDir _unit, 15, false, false] spawn pl_find_cover;
            };
            // _unit enableAI "FSM";
        };
    };

    waitUntil {sleep 1; !(_group getVariable ["onTask", true])};

    deleteMarker _buildingMarker;
    pl_draw_building_array = pl_draw_building_array - [[_group, _building]];
};

pl_360 = {
    params ["_group"];

    _center = getPos (leader _group); 
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
            // [_unit, getPos _unit, (getPos (leader (group _unit))) getDir _movePos, 2, false, false] spawn pl_find_cover;
        };
        _i = _i + 1;
    } forEach _units;
};

pl_disengage = {
    params [["_group", (hcSelected player) select 0]];

    private _enemy = (leader _group) findNearestEnemy getPos (leader _group);

    if (isNull _enemy) exitWith {hint "Group not in Combat"};

    private _allyUnits = allUnits+vehicles select {side _x == playerSide};
    _allyUnits = _allyUnits - (units _group);
    private _ally = ([_allyUnits, [], {_x distance2D (leader _group)}, "ASCEND"] call BIS_fnc_sortBy)#0;

    private _retreatDistance = 200;
    if (((leader _group) distance2D _ally) < 250) then {
        _retreatDistance = ((leader _group) distance2D _ally) + 80;
    };

    if (vehicle (leader _group) != leader _group) then { _retreatDistance = _retreatDistance + 100};

    if ([getpos (leader _group)] call pl_is_city) then {_retreatDistance = _retreatDistance / 2};

    private _enemyDir = (leader _group) getDir _enemy;
    private _allyDir = (leader _group) getDir _ally;
    private _retreatPos = (getPos (leader _group)) getPos [_retreatDistance, _enemyDir - 180];

    _retreatPos findEmptyPosition [0, 25, typeOf (vehicle (leader _group))];

    private _markerDirName = format ["delayDir%1%2", _group, random 1];
    createMarker [_markerDirName, _retreatPos];
    _markerDirName setMarkerPos _retreatPos;
    _markerDirName setMarkerType "marker_position_eny";
    _markerDirName setMarkerColor pl_side_color;
    _markerDirName setMarkerDir _enemyDir;

    pl_draw_disengage_array pushBack [_group, _retreatPos];

    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa";
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    {
        _x setUnitTrait ["camouflageCoef", 0.5, true];
        _x setVariable ["pl_damage_reduction", true];
    } forEach (units _group);

    if (vehicle (leader _group) == leader _group) then {

        private _units = (units _group) select {alive _x};
        private _injured = _units select {lifeState _x isEqualTo "INCAPACITATED" or (_x getVariable ["pl_wia", false])};

        if (count _injured > 0) then {

            (leader _group) disableAI "AUTOCOMBAT";
            (leader _group) disableAI "TARGET";
            (leader _group) disableAI "AUTOTARGET";
            (leader _group) setCombatBehaviour "AWARE";
            (leader _group) doMove _retreatPos;
            (leader _group) setDestination [_retreatPos,"LEADER DIRECT", true];
            [leader _group, "SmokeShellMuzzle"] call BIS_fnc_fire;

            private _dragScripts = []; 
            private _restUnits = _units - _injured - [leader _group];
            private _draggers = [];

            for "_i" from 0 to (count _injured) - 1 do {
                if ((count _restUnits) - 1 >= _i) then {
                    _unit = _injured#_i;
                    _dragger = ([_restUnits, [], {_x distance2D _unit}, "ASCEND"] call BIS_fnc_sortBy)#0;
                    _draggers pushBack _dragger;
                    [_dragger, "SmokeShellMuzzle"] call BIS_fnc_fire;
                    _injured deleteAt (_injured find _unit);
                    _restUnits deleteAt (_restUnits find _dragger);
                    _dragScripts pushBack ([_dragger, _unit, _retreatPos, true] spawn pl_injured_drag);
                };
            };

            private _ii = 0;
            {
                if (_ii <= (count _draggers) - 1) then {
                    _x disableAI "AUTOCOMBAT";
                    _x setCombatBehaviour "AWARE";
                    doStop _x;
                    _x doFollow (_draggers#_ii);
                    [_x, _draggers#_ii] spawn {
                        params ["_unit", "_escortTarget"];
                        while {(group _unit) getVariable ["onTask", false]} do {

                            if (!(alive _escortTarget) or (_escortTarget getVariable ["pl_wia", false])) exitWith {_x doFollow (leader (group _unit))};

                            sleep 0.5;
                        };
                    };
                    _ii = _ii + 1;
                } else {
                    _x disableAI "AUTOCOMBAT";
                    _x setCombatBehaviour "AWARE";
                    _x disableAI "AUTOTARGET";
                    _x doFollow (leader _group);
                };
            } forEach _restUnits;

            waitUntil {sleep 0.5; ({!(scriptDone _x)} count _dragScripts) <= 0 or ({alive _x} count _units) <= 0};

        } else {
            _group setCombatMode "BLUE";
            _group setVariable ["pl_combat_mode", true];
            _group setSpeedMode "FULL";
            [leader _group, "SmokeShellMuzzle"] call BIS_fnc_fire;

            {
                _x disableAI "AUTOCOMBAT";
                _x disableAI "TARGET";
                _x disableAI "AUTOTARGET";
                _x setCombatBehaviour "AWARE";
                _x doMove _retreatPos;
                _x setDestination [_retreatPos,"LEADER DIRECT", true];
            } forEach _units;

            waitUntil {sleep 0.5; ({_x distance2D _retreatPos < 10} count _units) > 0 or !(_group getVariable ["onTask", false])};

            _group setCombatMode "YELLOW";
            _group setVariable ["pl_combat_mode", false];
        };


    } else {
        private _vic = vehicle (leader _group);
        [_vic, "SmokeLauncher"] call BIS_fnc_fire;

        _vic doMove _retreatPos;
        _vic setDestination [_retreatPos,"VEHICLE PLANNED" , true];
        waitUntil {sleep 0.5, unitReady _vic or !alive _vic};
    };

    sleep 1;
    if (_group getVariable ["onTask", false]) then {
        [_group, [], _retreatPos, _enemyDir] spawn pl_defend_position;
    };
    pl_draw_disengage_array =  pl_draw_disengage_array - [[_group, _retreatPos]];
    deleteMarker _markerDirName;
};

pl_defend_position = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []] , ["_cords", []], ["_watchDir", 0]];
    private ["_mPos", "_medicPos", "_buildingWallPosArray", "_buildingMarkers", "_watchPos", "_defenceWatchPos", "_markerAreaName", "_markerDirName", "_covers", "_buildings", "_doorPos", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon", "_unitWatchDir", "_vPosCounter", "_defenceAreaSize", "_mgPosArray", "_losPos", "_mgOffset", "_atEscord"];



    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";
    _buildings = [];
    private _markerDirName = "";

    if (_cords isEqualTo []) then {

        if !(visibleMap) then {
            if (isNull findDisplay 2000) then {
                [leader _group] call pl_open_tac_forced;
            };
        };

        hintSilent "";

        _markerAreaName = format ["%1garrison%2", _group, random 2];
        createMarker [_markerAreaName, [0,0,0]];
        _markerAreaName setMarkerShape "ELLIPSE";
        _markerAreaName setMarkerBrush "SolidBorder";
        _markerAreaName setMarkerColor pl_side_color;
        _markerAreaName setMarkerAlpha 0.35;
        _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];

        _markerAreaName setMarkerPos pl_defence_cords;
        _markerDirName = format ["defenceAreaDir%1%2", _group, random 2];
        createMarker [_markerDirName, pl_defence_cords];
        _markerDirName setMarkerPos pl_defence_cords;
        _markerDirName setMarkerType "marker_position";
        _markerDirName setMarkerColor pl_side_color;


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

        pl_garrison_area_size = 25;
        pl_360_area = false;
        _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
                     <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
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
            if (pl_garrison_area_size >= 55) then {pl_garrison_area_size = 55};
            if (pl_garrison_area_size <= 10) then {pl_garrison_area_size = 10};

            _buildings = nearestTerrainObjects [_mPos, ["BUILDING", "RUIN", "HOUSE"], pl_garrison_area_size, true];

            if !(_buildings isEqualTo []) then {
                _markerAreaName setMarkerShape "ELLIPSE";
                _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];
            } else {
                _markerAreaName setMarkerShape "RECTANGLE";
                _markerAreaName setMarkerSize [pl_garrison_area_size, 2];
            };   
            if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
                _watchDir = _rangelimiterCenter getDir _mPos;
                _markerAreaName setMarkerPos _mPos;
                _markerDirName setMarkerPos _mPos;
                _markerDirName setMarkerDir _watchDir;
                _markerAreaName setMarkerDir _watchDir;
            };
        };

        player enableSimulation true;

        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {};

        _message = "Select Defence FACING <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
        <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>360° Security</t>";
        hint parseText _message;
        
        sleep 0.1;
        deleteMarker _markerBorderName;
        _cords = getMarkerPos _markerAreaName;
        _markerDirName setMarkerPos _cords;
        // _cords = pl_defence_cords;
        _defenceAreaSize = pl_garrison_area_size;

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
        // pl_show_watchpos_selector = false;

        if (pl_cancel_strike) exitWith {};

        // _defenceWatchPos = pl_defenceWatchPos;
        deletemarker _markerAreaName;

        if (pl_360_area) then {
            _markerDirName setMarkerType "mil_circle";
            _markerDirName setMarkerSize [0.5, 0.5];
        };

        if (count _taskPlanWp != 0) then {

            // player sideChat str (_group getVariable ["pl_disembark_finished", false]);

            // add Arrow indicator
            pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

            if (vehicle (leader _group) != leader _group) then {
                if ((leader _group) == commander (vehicle (leader _group)) or (leader _group) == driver (vehicle (leader _group)) or (leader _group) == driver (vehicle (leader _group))) then {
                    waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false]) or (_group getVariable ["pl_disembark_finished", false])};
                } else {
                    waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false]) or (_group getVariable ["pl_disembark_finished", false])};
                };
            } else {
                waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false]) or (_group getVariable ["pl_disembark_finished", false])};
            };
            _group setVariable ["pl_disembark_finished", nil];

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
            _group setVariable ["pl_task_planed", false];
        };

        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

        _defenceAreaSize = pl_garrison_area_size;
    } else {
        _defenceAreaSize = pl_garrison_area_size;
        _buildings = nearestTerrainObjects [_cords, ["BUILDING", "RUIN", "HOUSE"], _defenceAreaSize, true];

        _markerDirName = format ["delayDir%1", _group];
        createMarker [_markerDirName, _cords];
        _markerDirName setMarkerPos _cords;
        _markerDirName setMarkerType "marker_position";
        _markerDirName setMarkerColor pl_side_color;
        _markerDirName setMarkerDir _watchDir;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

    
    // if ((count _validBuildings == 0)) exitWith {hint "No buildings in Area!"; deleteMarker _markerAreaName; deleteMarker _markerDirName;};


    // if (pl_enable_beep_sound) then {playSound "beep"};

    // player sideRadio "SentCmdHide";
    [_group, "confirm", 1] call pl_voice_radio_answer;

//  Whyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy?????????????????
    [_group] spawn pl_reset;

    sleep 0.5;

    [_group] spawn pl_reset;

    sleep 0.5;

    _defenceWatchPos = _cords getPos [250, _watchDir];
    _defenceWatchPos = ASLToATL _defenceWatchPos;
    _defenceWatchPos = [_defenceWatchPos#0, _defenceWatchPos#1, 2];
    _defenceWatchPos = ATLToASL _defenceWatchPos;


    _watchPos = _cords getPos [1000, _watchDir];
    [_watchPos, 1] call pl_convert_to_heigth_ASL;

    
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 2) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    // if (pl_360_area) then {_icon = "\A3\ui_f\data\map\markers\military\circle_CA.paa"};
    // if ((count _validBuildings) > 0) then {_icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _group setVariable ["pl_combat_mode", true];
    _group setVariable ["pl_in_position", true];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {[_group, _watchPos, _cords, _markerDirName, _watchDir] spawn pl_defend_position_vehicle};



    _validPos = [];
    private _sideRoadPos = [];
    _allPos = [];
    {
        private _building = _x;
        // pl_draw_building_array pushBack [_group, _building];
        _bPos = [_building] call BIS_fnc_buildingPositions;
        _vPosCounter = 0;
        {
            _bP = _x;
            _allPos pushBack _bP;
            private _window = false;

            _samplePosASL = ATLtoASL [_bp#0, _bp#1, (_bp#2) + 1.04152];

            _buildingDir = getDir _building;
            for "_d" from 0 to 361 step 90 do {
                _counterPos = _samplePosASL vectorAdd [3 * (sin (_buildingDir + _d)), 3 * (cos (_buildingDir + _d)), 0];

                if !((lineIntersects [_counterPos, _counterPos vectorAdd [0, 0, 20]])) then {
                    // _helper2 = createVehicle ["Sign_Sphere25cm_F", _counterPos, [], 0, "none"];
                    // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                    // _helper2 setposASL _counterPos;

                    // _m = createMarker [str (random 1), _counterPos];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerSize [0.3, 0.3];
                    // _m setMarkerColor "colorRED";

                    _interSectsWin = lineIntersectsWith [_samplePosASL, _counterPos, objNull, objNull, true];
                    _checkDir = _buildingDir + _d;
                    if ((({_x == _building} count _interSectsWin) == 0) and (_checkDir > (_watchDir - 25) and _checkDir < (_watchDir + 25))) exitWith {
                        // _window = true
                        _bPos deleteAt (_bPos find _bP);
                        _validPos pushBack _bP;
                        _vPosCounter = _vPosCounter + 1;

                        // _helper1 = createVehicle ["Sign_Sphere25cm_F", _samplePosASL, [], 0, "none"];
                        // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                        // _helper1 setposASL _samplePosASL;

                        // _m = createMarker [str (random 1), _samplePosASL];
                        // _m setMarkerType "mil_dot";
                        // _m setMarkerSize [0.3, 0.3];
                        // _m setMarkerColor "colorBlue";
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
            // _validPos pushBack (selectRandom _bPos);
            _validBuildings deleteAt ( _validBuildings find _building);
        };
    } forEach _validBuildings;

    // deploy packed static weapons if no buildings
    private _isStatic = [false, []];
    // if (_validBuildings isEqualTo [] and !(pl_360_area)) then {
    //     _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _cords;
    //     _leaderDir = _watchDir - 90;
    //     _leaderPos = [6*(sin _leaderDir), 6*(cos _leaderDir), 0] vectorAdd _cords;
    //     (leader _group) addWeapon "Binocular";
    //     _isStatic = [_group, _cords, _watchPos, _leaderPos] call pl_reworked_bis_unpack;
    // };

    // _watchPos = [500*(sin _watchDir), 500*(cos _watchDir), 0] vectorAdd _cords;

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _units = [(leader _group)];
    private _mgGunners = [];
    private _atSoldiers = [];
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
        if (secondaryWeapon _x != "" and alive _x and !(_x getVariable ["pl_wia", false])) then {
            _atSoldiers pushBackUnique _x;
        };
    } forEach (units _group);

    if (count _atSoldiers > 0 and count _units > 3) then {
        _atEscord = {
            if (_x != (leader _group) and _x != _medic) exitWith {_x};
            objNull
        } forEach _units;
    };
    {_units pushBack _x} forEach _atSoldiers;
    {_units pushBack _x} forEach _mgGunners;
    _units pushBack _medic;

    [_group, _defenceWatchPos, _medic] spawn pl_defence_suppression;
    [_group, _cords, _medic] spawn pl_defence_rearm;

    _posOffsetStep = _defenceAreaSize / (round ((count _units) / 2));
    private _posOffset = 0; //+ _posOffsetStep;
    private _maxOffset = _posOffsetStep * (round ((count _units) / 2));

    // find static weapons
    private _weapons = nearestObjects [_cords, ["StaticWeapon"], _defenceAreaSize, true];
    _avaiableWeapons = _weapons select { simulationEnabled _x && { !isObjectHidden _x } && { locked _x != 2 } && { (_x emptyPositions "Gunner") > 0 } };
    _weapons = + _avaiableWeapons;
    _coverCount = 0;
    _medicPos = [];
    private _safePos = [];
    _buildingMarkers = [];

    if !(_buildings isEqualTo []) then {

        _buildings = [_buildings, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _covers = [];
        _buildingWallPosArray = [];
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
        _medicPos = ([_safePos, [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0;


        // {
        //     _m = createMarker [str (random 1), _x];
        //     _m setMarkerType "mil_dot";
        //     _m setMarkerSize [0.5, 0.5];
        // } forEach _buildingWallPosArray;

        private _walls = nearestTerrainObjects [_cords, ["WALL", "RUIN"], _defenceAreaSize, true];
        private _validWallPos = [];
        private _validPrefWallPos = [];

        {
            if !(isObjectHidden _x) then {

                _leftPos = (getPos _x) getPos [1.5, getDir _x];
                _rightPos = (getPos _x) getPos [1.5, (getDir _x) - 180];

                if ((typeof _x) in pl_valid_walls) then {
                    _validPrefWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                } else {
                    _validWallPos pushBack (([[_leftPos, _rightPos], [], {_x distance2D _watchPos}, "DESCEND"] call BIS_fnc_sortBy)#0);
                };
            };
        } forEach _walls;

        _validWallPos = [_validWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        _validPrefWallPos = [_validPrefWallPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        private _roads = _cords nearRoads _defenceAreaSize;
        if ((count _roads) >= 2) then {
            _roads = [_roads, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
            private _roadDir = (getpos (_roads#1)) getDir (getpos (_roads#0));

            if (_roadDir > (_watchDir - 35) and _roadDir < (_watchDir + 35)) then {

                _roads = [_roads, [], {_x distance2D (_buildings#0)}, "ASCEND"] call BIS_fnc_sortBy;
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

                } forEach [90, -90];
            };
        };

        _validPos = _validPos + _validPrefWallPos;
        _validPos = _validPos + _validWallPos;
        _validPos = _validPos + _buildingWallPosArray;
        _validPos = _validPos + _sideRoadPos;

    } else {
        _covers = [];
    };

    // private _validLosPos = [];

    private _losOffset = 2;
    private _maxLos = 0;
    private _losStartLine = _cords getPos [2, _watchDir];
    private _validLosPos = [];
    private _accuracy = 30;
    if ([_losStartLine] call pl_is_city) then {
        _accuracy = 10;
    };

    for "_j" from 0 to _accuracy do {
        if (_j % 2 == 0) then {
            _losPos = (_losStartLine getPos [2, _watchDir]) getPos [_losOffset, _watchDir + 90];
        }
        else
        {
            _losPos = (_losStartLine getPos [2, _watchDir]) getPos [_losOffset, _watchDir - 90];
        };
        _losOffset = _losOffset + (_defenceAreaSize / _accuracy);

        _losPos = [_losPos, 1] call pl_convert_to_heigth_ASL;

        private _losCount = 0;
        for "_l" from 10 to 510 step 50 do {

            _checkPos = _losPos getPos [_l, _watchDir];
            _checkPos = [_checkPos, 1] call pl_convert_to_heigth_ASL;
            _vis = lineIntersectsSurfaces [_losPos, _checkPos, objNull, objNull, true, 1, "VIEW"];

            if !(_vis isEqualTo []) exitWith {};

            _losCount = _losCount + 1;
        };
        if (isNull (roadAt _losPos)) then {
            _validLosPos pushback [_losPos, _losCount];
        };
    };

    _validLosPos = [_validLosPos, [], {_x#1}, "DESCEND"] call BIS_fnc_sortBy;

    _isStatic = [_group, (_validLosPos#0)#0, _watchPos, _cords] call pl_static_unpack;
    
    if (_isStatic#0) then {
        _validLosPos deleteAt (_validLosPos find (_validLosPos#0));
        // _posOffset  8;
        // (leader _group) addWeapon "Binocular";

        _units deleteAt (_units find ((_isStatic#1)#0));
    };

    private _mgPos = [];

    for "_i" from 0 to count (_mgGunners) - 1 do {
        _mgPos pushback ((_validLosPos#_i)#0);
        _validLosPos deleteAt (_validLosPos find (_validLosPos#_i));
    };

    private _mgIdx = 0;
    private _losIdx = 0;
    private _debugMColor = "colorBlack";
    private _defPos = [];

    for "_i" from 0 to (count _units) - 1 step 1 do {
        private _cover = false;

        _unitWatchDir = _watchDir;

        // move to optimal Pos first
        if (_i < (count _validPos)) then {
            _defPos = _validPos#_i;
            _unit = _units#_i;
            _debugMColor = "colorBlue";
        }
        else
        {
            _cover = true;
            _unit = _units#_i;
            // if no more covers avaible move to left or right side of best cover
                // deploy along a line
            if (_buildings isEqualTo []) then {
                _dirOffset = 90;
                if (_i % 2 == 0) then {_dirOffset = -90};
                _defPos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _cords;
                if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
                _debugMColor = "colorBlue";
            }
            else
            {
                if (_losIdx > (count _validLosPos) - 1) then {_losIdx = 1};
                _defPos = (_validLosPos#_losIdx)#0;
                _losIdx = _losIdx + 2;
                _debugMColor = "colorOrange";
            };
        };

        // seelct best Medic Pos
        if (!(isNil "_medic") and pl_enabled_medical) then {
            if (_unit == _medic) then {
                _debugMColor = "colorGreen";
                _rearPos = _cords getPos [_defenceAreaSize * 0.7, _watchDir - 180];
                _lineStartPos = _rearPos getPos [_defenceAreaSize / 2, _watchDir - 90];
                _unitWatchDir = _watchDir - 180;
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
                if (_medicPos isEqualTo []) then {
                    _defPos = ([_posCandidates, [], {[objNull, "VIEW", objNull] checkVisibility [_x, [_x getPos [50, _watchDir], 0.5] call pl_convert_to_heigth_ASL]}, "DESCEND"] call BIS_fnc_sortBy)#0;
                } else {
                    _defPos = _medicPos;
                    _cover = true;
                };
            };
        };

        // select Best Mg Pos
        if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
            _defPos = (_mgPos#_mgIdx);
            _mgIdx = _mgIdx + 1;
            _debugMColor = "colorRed";
        };

        // if (_unit == (leader _group) and !(_buildings isEqualTo []) and (_defPos distance2D _cords) > 20) then {
        //     _defPos = _cords findEmptyPosition [0, 25, typeOf _unit];
        //     _cover = true;
        //     _debugMColor = "colorYellow";
        // };

        if (_defPos isEqualTo []) then {
            _defPos = selectRandom _covers;
            _debugMColor = "colorGrey";
        };

        _defPos = ATLToASL _defPos;
        private _unitPos = "UP";
        if !([_defPos] call pl_is_indoor) then {
            // _unitPos = "MIDDLE";
            _cover = true;
        };
        _checkPos = [10*(sin _watchDir), 10*(cos _watchDir), 1] vectorAdd _defPos;
        _crouchPos = [0, 0, 1] vectorAdd _defPos;
        _vis = lineIntersectsSurfaces [_crouchPos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "MIDDLE";
            // _watchPos = _checkPos;
        };
        _checkPos = [10*(sin _watchDir), 10*(cos _watchDir), 0.2] vectorAdd _defPos;
        _vis = lineIntersectsSurfaces [_defPos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "DOWN";
            // _watchPos = _checkPos;
        };

        _defPos = ASLToATL _defPos;

        // _m = createMarker [str (random 1), _defPos];
        // _m setMarkerType "mil_dot";
        // _m setMarkerSize [0.5, 0.5];
        // _m setMarkerColor _debugMColor;

        // _helper = createVehicle ["Sign_Sphere25cm_F", _defPos, [], 0, "none"];
        // _helper setObjectTexture [0,'#(argb,8,8,3)color(0,1,0,1)'];

        [_unit, _defPos, _watchPos, _unitWatchDir, _unitPos, _cover, _cords, _defenceAreaSize, _defenceWatchPos, _watchDir, _atEscord, _medic, _markerDirName] spawn {
            params ["_unit", "_defPos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_cords", "_defenceAreaSize", "_defenceWatchPos", "_defenceDir", "_atEscord", "_medic", ["_markerDirName", ""]];

            // _m = createMarker [str (random 1), _defPos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];


            _unit setVariable ["pl_def_pos", _defPos, true];
            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            _unit setUnitTrait ["camouflageCoef", 0.7, true];
            _unit setVariable ["pl_damage_reduction", true];
            // _unit disableAI "FSM";
            _unit doMove _defPos;
            _unit setDestination [_defPos, "LEADER DIRECT", true];
            sleep 1;
            private _counter = 0;
            // while {alive _unit and ((group _unit) getVariable ["onTask", true])} do {
            //     sleep 0.5;
            //     _dest = [_unit, _defPos, _counter] call pl_position_reached_check;
            //     if (_dest#0) exitWith {};
            //     _defPos = _dest#1;
            //     _counter = _dest#2;
            // };
            waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "TARGET";
            // _unit enableAI "FSM";
            if !(_cover) then {
                doStop _unit;
                _unit disableAI "PATH";
                _unit doWatch _watchPos;
                _unit setUnitPos _unitPos;
            }
            else
            {
                if ([_defPos] call pl_is_forest or [_defPos] call pl_is_city) then {
                    [_unit, _watchPos, _unitWatchDir, 3, false] spawn pl_find_cover;
                } else {
                    [_unit, _watchPos, _unitWatchDir, 10, false] spawn pl_find_cover;
                };
            };
            if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                [_unit, group _unit, _cords, _defenceAreaSize, _defenceDir, _defPos, _atEscord] spawn pl_at_defence;
                sleep 0.1;
                // _m setMarkerColor "colorOrange";
            };
            if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                [_unit, _watchPos, _unitWatchDir, 0, false, false, "", true] spawn pl_find_cover;
                // _m setMarkerColor "colorRed";
            };
            if (_unit == _medic) then {
                [(group _unit), _unit, _defPos] spawn pl_defence_ccp;
                // _m setMarkerColor "colorGreen";
            };
            if (_unit == (leader (group _unit)) and _markerDirName != "") then {
                _markerDirName setMarkerPos (getPos _unit);
            };
        };
    };

    // hint (str _allPos);

    private _breakingPoint = round (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) / 2);

    waitUntil {sleep 0.5; !(_group getVariable ["onTask", true]) or ({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) <= _breakingPoint};

    // deleteMarker _markerAreaName;
    deleteMarker _markerDirName;
    {deleteMarker _x} forEach _buildingMarkers;

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

    if (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) <= _breakingPoint) then {
        if (pl_enable_beep_sound) then {playSound "radioina"};
        if (pl_enable_map_radio) then {[_group, "...Falling Back!", 20] call pl_map_radio_callout};
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Falling Back", (groupId _group)]};
        [_group] spawn pl_disengage;
    };

    // {
        // pl_draw_building_array = pl_draw_building_array - [[_group, _x]];
    // } forEach _validBuildings;
};

pl_at_defence = {
    params ["_atSoldier", "_group", "_defencePos", "_defenceAreaSize", "_defenceDir", "_startPos", "_atEscord"];
    private ["_checkPosArray", "_watchPos", "_targets", "_debugMarkers"];

    _time = time + 20;
    waitUntil {sleep 0.5;  time >= time or !(_group getVariable ["onTask", true]) };
    if !(_group getVariable ["onTask", true]) exitWith {};

    _watchPos = (getPos _atSoldier) getPos [50, _defenceDir];

    while {alive _atSoldier and _group getVariable ["onTask", true]} do {

        if ((_atSoldier getVariable ["pl_wia", false]) or (((secondaryWeaponMagazine _atSoldier) isEqualTo []) and ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _atSoldier >> "magazines") apply {toUpper _x})} count magazines _atSoldier) <= 0)) then {
            _group setVariable ["pl_grp_active_at_soldier", nil];
            waitUntil {sleep 0.5; !(_atSoldier getVariable ["pl_wia", false]) and !((secondaryWeaponMagazine _atSoldier) isEqualTo [])};
        };

        if !((_group getVariable ["pl_grp_active_at_soldier", objNull]) == _atSoldier) then {
            waitUntil {sleep 0.5; !(_atSoldier getVariable ["pl_wia", false]) and !((secondaryWeaponMagazine _atSoldier) isEqualTo []) and (isNull (_group getVariable ["pl_grp_active_at_soldier", objNull]))};
        };

        // _vics = nearestObjects [_watchPos, ["Car", "Tank"], 300, true];
        _vics = _watchPos nearEntities [["Car", "Tank"], 150];

        _targets = [];
        {
            // if (speed _x <= 3 and alive _x and (count (crew _x) > 0) and (_atSoldier knowsAbout _x) >= 0.5 and !((getPos _x) call pl_is_city) or _x getVariable ["pl_at_enaged", false] ) then {
            if (speed _x <= 3 and alive _x and (count (crew _x) > 0) and (_atSoldier knowsAbout _x) >= 0.5 and (!([getPos _x] call pl_is_city) or _x distance2D _atSoldier <= 100)) then {
                _targets pushBack _x;
            };
        } forEach (_vics select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

        if (count _targets > 0 and !((secondaryWeaponMagazine _atSoldier) isEqualTo [])) then {
            _targets = [_targets, [], {_x distance2D (getPos _atSoldier)}, "ASCEND"] call BIS_fnc_sortBy;
            _target = _targets#0;

            _defenceAreaSize = _defenceAreaSize + 50;
            _debugMarkers = [];
            _checkPosArray = [];
            _atkDir = _atSoldier getDir _target;
            _lineStartPos = (getPos _atSoldier) getPos [_defenceAreaSize / 2, _atkDir - 90];
            _lineStartPos = _lineStartPos getPos [8, _atkDir];
            _lineOffset = 0;
            for "_i" from 0 to 80 do {
                for "_j" from 0 to 30 do { 
                    _checkPos = _lineStartPos getPos [_lineOffset, _atkDir + 90];
                    _lineOffset = _lineOffset + (_defenceAreaSize / 30);

                    _checkPos = [_checkPos, 1.5] call pl_convert_to_heigth_ASL;

                    // _m = createMarker [str (random 1), _checkPos];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerSize [0.2, 0.2];
                    // _debugMarkers pushBack _m;

                    _vis = lineIntersectsSurfaces [_checkPos, aimPos _target, _target, vehicle _target, true, 1, "VIEW"];
                    if (_vis isEqualTo []) then {
                            _checkPosArray pushBack _checkPos;
                            // _m setMarkerColor "colorRED";
                        };
                    };
                _lineStartPos = _lineStartPos getPos [1.5, _atkDir];
                _lineOffset = 0;
            };

            if (count _checkPosArray > 0 and !((secondaryWeaponMagazine _atSoldier) isEqualTo [])) then {

                _target setVariable ["pl_at_enaged", true];

                [(group (driver _target)), true] call Pl_marta;

                {
                    doStop _x;
                    _x enableAI "PATH";
                    _x setUnitPos "MIDDLE";
                    _x disableAI "TARGET";
                    _x disableAI "AUTOTARGET";
                    _x setBehaviourStrong "AWARE";
                    _x setUnitTrait ["camouflageCoef", 0.1, true];
                    _x setVariable ["pl_damage_reduction", true];
                    _x setVariable ['pl_is_at', true];
                    _x setVariable ["pl_engaging", true];
                } forEach [_atSoldier, _atEscord];
                _atSoldier disableAI "AIMINGERROR";

                _group setVariable ["pl_grp_active_at_soldier", _atSoldier];
                pl_at_attack_array pushBack [_atSoldier, _target, _atEscord];

                _movePos = ([_checkPosArray, [], {_atSoldier distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;
                _atSoldier doMove _movePos;
                _atSoldier setDestination [_movePos, "LEADER DIRECT", true];
                _atEscord doFollow _atSoldier;

                // _m = createMarker [str (random 1), _movePos];
                // _m setMarkerType "mil_dot";
                // _m setMarkerColor "colorGreen";
                // _m setMarkerSize [0.7, 0.7];
                // _debugMarkers pushBack _m;

                if ((_movePos distance2D _defencePos) < 200) then {

                    _time = time + ((_atSoldier distance _movePos) / 1.6 + 20);
                    sleep 0.5;
                    waitUntil {sleep 0.5; (time > _time or unitReady _atSoldier or !alive _atSoldier or (_atSoldier getVariable ["pl_wia", false]) or !((group _atSoldier) getVariable ["onTask", true]) or !alive _target or (count (crew _target) == 0)) or (([_targets, [], {_x distance2D (getPos _atSoldier)}, "ASCEND"] call BIS_fnc_sortBy)#0) != _target};
                    _atSoldier setUnitPos "AUTO";
                    _atSoldier reveal [_target, 2];
                    _atSoldier doTarget _target;
                    waitUntil {sleep 0.5; !(_group getVariable ["pl_hold_fire", false]) or !alive _atSoldier or _atSoldier getVariable["pl_wia", false] or !alive _target};
                    _atSoldier doFire _target;
                    _time = 6;
                    waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", false]) or !alive _target};
                    // pl_at_attack_array = pl_at_attack_array - [[_atSoldier, _movePos]];
                };
            };


            pl_at_attack_array = pl_at_attack_array - [[_atSoldier, _target, _atEscord]];
            _atSoldier setVariable ['pl_is_at', false];
            _atEscord setVariable ['pl_is_at', false];
            _atSoldier doTarget objNull;

            if (!alive _target or (count (crew _target) == 0)) then {
                {

                    [_x, _defencePos, _defenceDir, _watchPos] spawn {
                        params ["_unit", "_defencePos", "_defenceDir", "_watchPos"];

                        _movePos = _unit getVariable ["pl_def_pos", _defencePos];
                        _unit doMove _movePos;
                        _unit setDestination [_movePos, "LEADER DIRECT", true];

                        sleep 0.5;

                        waitUntil {sleep 0.5; unitReady _unit or _unit getVariable ['pl_is_at', false] or !((group _unit) getVariable ["onTask", false]) or !alive _unit};

                        if !(_unit getVariable ['pl_is_at', false]) then {
                            _unit enableAI "TARGET";
                            _unit enableAI "AUTOTARGET";
                            _unit enableAI "AIMINGERROR";
                            _unit setBehaviour "AWARE";
                            _unit setUnitTrait ["camouflageCoef", 0.7, true];
                            // _unit setVariable ["pl_damage_reduction", false];
                            _unit setVariable ['pl_is_at', false];
                            _unit setVariable ["pl_engaging", false];
                            [_unit, _watchPos, _defenceDir, 0, false] spawn pl_find_cover;
                        };
                    };
                } forEach [_atSoldier, _atEscord];
            };
        } else {
            {
                if ((_x distance2D _defencePos) > 200) then {
                    doStop _x;
                    _x doFollow (leader _group);
                };
            } forEach [_atSoldier, _atEscord];;
        };
        sleep 1;
    };
    _group setVariable ["pl_grp_active_at_soldier", nil];
    if !(isNil "_target") then {pl_at_attack_array = pl_at_attack_array - [[_atSoldier, _target, _atEscord]]}; 
};


pl_defence_suppression = {
    params ["_group", "_watchPos", "_medic"];
    private ["_targetsPos", "_firers"];

    private  _time = time + 20;
    waitUntil {sleep 0.5;  time >= time or !(_group getVariable ["onTask", true]) };
    if !(_group getVariable ["onTask", true]) exitWith {};

    while {_group getVariable ["onTask", false]} do {
        waitUntil {sleep 0.5; !(_group getVariable ["pl_hold_fire", false])};
        // _allTargets = nearestObjects [_watchPos, ["Man", "Car"], 350, true];
        _enemyTargets = (_watchPos nearEntities [["Man", "Car"], 275]) select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and ((leader _group) knowsAbout _x) > 0};
        if (count _enemyTargets > 0) then {
            _firers = [];
            {
                if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                    _firers pushBackUnique _x;
                    _x setUnitTrait ["camouflageCoef", 0.5, false];
                    _x setVariable ["pl_damage_reduction", true];
                } else {
                    if ((random 1) > 0.4) then {_firers pushBackUnique _x;}
                };
            } forEach ((units _group) select {!(_x checkAIFeature "PATH") and _x != _medic});
            {
                _unit = _x;
                _target = selectRandom _enemyTargets;
                _targetPos = getPosASL _target;
                if ([_unit, _targetPos] call pl_friendly_check) then {sleep 1; continue};
                _vis = lineIntersectsSurfaces [eyePos _unit, _targetPos, _unit, vehicle _unit, true, 1]; 
                if !(_vis isEqualTo []) then {
                    _targetPos = (_vis select 0) select 0;
                };

                if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_unit, _targetPos] call pl_friendly_check) and !(_group getVariable ["pl_hold_fire", false])) then {
                     _unit doSuppressiveFire _targetPos;
                };
            } forEach _firers;

            _time = time + 10;
            waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true])};
        };
        sleep 2;
    };
};



pl_defence_rearm = {
    params ["_group", "_defencePos", "_medic"];
    private ["_ammoCargo"]; 

    private  _time = time + 20;
    waitUntil {sleep 0.5;  time >= time or !(_group getVariable ["onTask", true]) };
    if !(_group getVariable ["onTask", true]) exitWith {};

    while {_group getVariable ["onTask", true] and (count (units _group)) > 3} do {

        // _supplyPoints = (nearestObjects [_defencePos, ["Car", "Tank"], 255, true]) select {(_x getVariable ["pl_is_rearm_point", false]) and (_x getVariable ["pl_supplies", 0]) > 0};
        _supplyPoints = (_defencePos nearEntities [["Car", "Tank"], 255]) select {(_x getVariable ["pl_is_rearm_point", false]) and (_x getVariable ["pl_supplies", 0]) > 0};

        if (count _supplyPoints > 0) then {
            _supplyPoint = ([_supplyPoints, [], {_defencePos distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;
            _ammoCargo = _supplyPoint getVariable ["pl_supplies", 0];

            if ((([_group] call pl_get_ammo_group_state)#0) isEqualTo "Red" or (([_group] call pl_get_at_status)#0) or (([_group] call pl_get_mg_status)#0)) then {
                _supplySoldier = {
                    if (_x != (leader _group) and ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun") and (secondaryWeapon _x == "") and !(_x checkAIFeature "PATH") and !(getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1)) exitWith {_x};
                    objNull
                } foreach (units _group);

                if !(isNull _supplySoldier) then {

                    _supplyPos = getPos _supplyPoint;
                    _startPos = _supplySoldier getVariable ["pl_def_pos", _defencePos];
                    _supplySoldier enableAI "PATH";
                    _supplySoldier setBehaviourStrong "AWARE";
                    _supplySoldier disableAI "TARGET";
                    _supplySoldier disableAI "AUTOTARGET";
                    _supplySoldier disableAI "COVER";
                    _supplySoldier disableAI "AUTOCOMBAT";
                    _supplySoldier setUnitPos "AUTO";
                    _supplySoldier setVariable ["pl_is_ccp_medic", true];
                    _supplySoldier setVariable ["pl_engaging", true];
                    _supplySoldier doMove _supplyPos;
                    _supplySoldier setDestination [_supplyPos, "LEADER DIRECT", true];

                    pl_supply_draw_array pushBack [_defencePos, _supplyPos, [0.9,0.7,0.1,0.8]];

                    sleep 1;

                    waitUntil {sleep 0.5; unitReady _supplySoldier or ((_supplySoldier distance2D _supplyPos) < 3) or (!alive _supplySoldier) or !((group _supplySoldier) getVariable ["onTask", true])};

                    if !((group _supplySoldier) getVariable ["onTask", true]) exitWith {pl_supply_draw_array = pl_supply_draw_array - [[_defencePos, _supplyPos, [0.9,0.7,0.1,0.8]]]};

                    doStop _supplySoldier;
                    sleep 2;
                    _supplySoldier doWatch _startPos;
                    _supplySoldier playActionNow "GestureFollow";
                    sleep 8;
                    _supplySoldier playActionNow "GestureGo";
                    sleep 2;

                    _supplySoldier doMove _startPos;
                    _supplySoldier setDestination [_startPos, "LEADER DIRECT", true];

                    sleep 1;

                    waitUntil {sleep 0.5; unitReady _supplySoldier or ((_supplySoldier distance2D _startPos) < 6) or (!alive _supplySoldier) or !((group _supplySoldier) getVariable ["onTask", true])};

                    pl_supply_draw_array = pl_supply_draw_array - [[_defencePos, _supplyPos, [0.9,0.7,0.1,0.8]]];

                    _supplySoldier setVariable ["pl_is_ccp_medic", false];
                    _supplySoldier enableAI "TARGET";
                    _supplySoldier enableAI "AUTOTARGET";
                    _supplySoldier enableAI "COVER";
                    _supplySoldier enableAI "AUTOCOMBAT";
                    _supplySoldier setVariable ["pl_engaging", false];

                    if (alive _supplySoldier and ((group _supplySoldier) getVariable ["onTask", true]) and (_supplySoldier distance2D _startPos) < 8) then {
                        [_supplySoldier, getPos _supplySoldier, getDir _supplySoldier, 15, false] spawn pl_find_cover;

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
            };
        };

        sleep 10;

    };
};

pl_defence_ccp = {
    params ["_group", "_medic", "_ccpPos"];

    private  _time = time + 10;
    waitUntil {sleep 0.5;  time >= time or !(_group getVariable ["onTask", true]) };
    if !(_group getVariable ["onTask", true]) exitWith {};

    _medic setVariable ["pl_is_ccp_medic", true];

    while {(_group getVariable ["onTask", true]) and alive _medic and !(_medic getVariable ["pl_wia", false])} do {

        // waitUntil {sleep 0.5; _group getVariable ["pl_healing_active", false] or !(_group getVariable ["onTask", true])};

        // if (_medic distance2D _ccpPos) > 5 then {
        //     doStop _medic;
        //     _medic doMove _ccpPos;
        // };

        _time = time + 5;
        waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true])};
        {
            if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                _medic setUnitPosWeak "MIDDLE";
                _medic enableAI "PATH";
                _h1 = [_group, _medic, objNull, _x, _ccpPos, 30, "onTask"] spawn pl_ccp_revive_action;
                waitUntil {sleep 0.5; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                sleep 1;
                [_x, getPos _x, getDir _x, 7, false] spawn pl_find_cover;
            };
        } forEach (units _group);
    };
    _medic setVariable ["pl_is_ccp_medic", false];
};

pl_move_back_to_def_pos = {
    params ["_unit"];

    private _time = time + 10;
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
        _unit setDestination [_movePos, "LEADER DIRECT", true];
        private _counter = 0;
        while {alive _unit and ((group _unit) getVariable ["onTask", true])} do {
            sleep 0.5;
            _dest = [_unit, _movePos, _counter] call pl_position_reached_check;
            if (_dest#0) exitWith {};
            _movePos = _dest#1;
            _counter = _dest#2;
        };
        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        [_unit, (getPos _unit) getPos [100, getDir _unit], getDir _unit, 0, false] spawn pl_find_cover;
    } else {
        _unit doFollow (leader (group _unit));
    };
};



pl_defend_position_vehicle = {
    params ["_group", "_watchPos", "_cords", "_markerName", "_watchDir"];

    private _vic = vehicle (leader _group);


    _vic doMove _cords;
    _vic setDestination [_cords,"VEHICLE PLANNED" , true];

    waitUntil {sleep 0.5; unitReady _vic or _vic distance2d _cords < 15 or !(_group getVariable ["onTask", false]) or !alive _vic};

    if (!(_group getVariable ["onTask", true]) or !alive _vic) exitWith {deleteMarker _markerName};
    _pos = [_vic, _watchDir] call pl_get_turn_vehicle;
    _vic doMove _pos;

    waitUntil {sleep 0.5; unitReady _vic or !(_group getVariable ["onTask", false]) or !alive _vic};

    if (!(_group getVariable ["onTask", true]) or !alive _vic) exitWith {deleteMarker _markerName};

    sleep 1;


    if (_group getVariable ["pl_has_cargo", false] or _group getVariable ["pl_vic_attached", false]) then {

        private _infGroup = grpNull;
        if (_group getVariable ["pl_has_cargo", false]) then {
            private _cargoGroups = [];
            {
                _unit = _x select 0;
                if (!(_unit in (units _group)) and !(_unit in (units (group player)))) then {
                    _cargoGroups pushBack (group (_x select 0));
                };
            } forEach (fullCrew [_vic, "cargo", false]);
            private _limit = 0;
            {
                if ((count (units _x)) > _limit) then {
                    _limit = count (units _x);
                    _infGroup = _x;
                };
            } forEach _cargoGroups;

            {
                _unit = _x select 0;
                if !(_unit in (units _group)) then {
                    unassignVehicle _unit;
                    doGetOut _unit;
                    [_unit] allowGetIn false;
                    // doStop _unit;
                };
            } forEach (fullCrew [_vic, "cargo", false]);

            if !(_infGroup getVariable ["pl_show_info", false]) then {
                [_infGroup] call pl_show_group_icon;
            };
            _infGroup leaveVehicle _vic;

            _vic setVariable ["pl_on_transport", nil];
            _group setVariable ["pl_has_cargo", false];

            waitUntil {sleep 0.5; (({vehicle _x != _x} count (units _infGroup)) == 0) or (!alive _vic)};

        } else {
            _infGroup = _group getVariable ["pl_attached_infGrp", grpNull];
            _group setVariable ["pl_vic_attached", false];
            _group setVariable ["pl_attached_infGrp", nil];
        };

        sleep 2;
        waitUntil {sleep 0.5; ({unitReady _x} count (units _infGroup)) == (count (units _infGroup))};
        sleep 1;
        private _defPos = (getPos _vic) getPos [12, _watchDir];
        [_infGroup, [], _defPos , _watchDir] spawn pl_defend_position;

        sleep 2;

        _markerName setMarkerPos _defPos;

        waitUntil {sleep 0.5; !(_infGroup getVariable ["onTask", false])};

        deleteMarker _markerName;

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

        waitUntil {!(_group getVariable ["onTask", false]) or !alive _vic};

        deleteMarker _markerName;
        {
            _x setVariable ["pl_damage_reduction", false];
            _x setUnitTrait ["camouflageCoef", 1, true];
        } forEach _crew;
    };
};
