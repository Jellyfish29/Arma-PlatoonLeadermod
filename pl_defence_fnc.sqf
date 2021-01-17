
pl_covers = [];
pl_defence_cords = [0,0,0];
pl_mapClicked = false;
pl_denfence_draw_array = [];
pl_draw_building_array = [];
pl_building_search_cords = [0,0,0];
pl_garrison_area_size = 20; 
pl_mapClicked = false;
pl_360_area = false;
pl_valid_covers = ["TREE", "SMALL TREE", "BUSH", "FOREST BORDER", "FOREST TRIANGLE", "FOREST SQUARE", "FENCE", "WALL", "HIDE", "FOREST", "ROCK", "ROCKS"];


pl_not_reachable_escape = {
    params ["_unit", "_pos", "_area"];

    sleep 2;

    if ((currentCommand _unit) isEqualTo "MOVE" and (speed _unit) == 0) exitWith {
        _movePos = [[[_pos, _area * 1.1]],["water"]] call BIS_fnc_randomPos;
        _movePos = _movePos findEmptyPosition [0, 10, typeOf _unit];
        doStop _unit;
        _unit doMove _movePos;
        _unit setDestination [_movePos, "LEADER PLANNED", true];
        false
    };
    true
};


pl_rush = {

    params ["_group"];
    private ["_targets", "_cords"];

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };

    [_group] call pl_reset;

    sleep 0.2;

    playSound "beep";

    _leader = leader _group;
    if (_leader == vehicle _leader) then {
        // leader _group sideChat "Roger Falling Back, Over";
        // [leader _group, "SmokeShellMuzzle"] call BIS_fnc_fire;
        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa"];
        _group addWaypoint [_cords, 0];
        _group setBehaviour "AWARE";
        _group setSpeedMode "FULL";
        _group setCombatMode "BLUE";
        _group setVariable ["pl_combat_mode", true];

        {
            _unit = _x;
            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "AUTOTARGET";
            _unit disableAI "TARGET";
            // _unit disableAI "FSM";
            _unit doMove _cords;

            private _targets = _x targetsQuery [objNull, sideUnknown, "", [], 0];
            private _count = count _targets;
                
            for [{private _i = 0}, {_i < _count}, {_i = _i + 1}] do {
                private _y = _targets select _i;
                _x forgetTarget (_y select 1);
            };
            
            [_unit, _group, _cords] spawn {
                params ["_unit", "_group", "_cords"];
                waitUntil{sleep 0.1; ((_unit distance2D _cords) < 10) or !(_group getVariable ["onTask", true])};
                _unit enableAI "AUTOCOMBAT";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                _unit doFollow (leader _group);
            };

        } forEach (units _group);

        waitUntil {(((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 15) or !(_group getVariable ["onTask", true])};
        
        sleep 1;

        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
        _group setVariable ["pl_combat_mode", false];
        _group setSpeedMode "NORMAL";
        _group setCombatMode "YELLOW";
        // leader _group sideChat "We reached Fall Back Position, Over";
    }
    else
    {
        _group addWaypoint [_cords, 0];
        _group setVariable ["setSpecial", true];
        _group setVariable ["onTask", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa"];
        _vic = vehicle _leader;
        [_vic, "SmokeLauncher"] call BIS_fnc_fire;
        _time = time + 45;
        waitUntil {sleep 0.1; (((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 25) or (time >= _time) or !(_group getVariable ["onTask", true])};
        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
    };
};


pl_move_to_360 = {

    params ["_unit", "_posArray"];
    private ["_pos", "_watchPos"];
    _pos = _posArray select 0;
    _watchPos = _posArray select 1;
    if (vehicle _unit != _unit) exitWith {};
    sleep 0.1;
    doStop _unit;
    _unit setUnitPos "MIDDLE";
    sleep 0.2;
    _unit moveTo _pos;
    _time = time + 100;
    waitUntil {sleep 1; (time > _time || !alive _unit || moveToCompleted _unit || currentCommand _unit != "STOP") or !((group _unit) getVariable ["onTask", true])};
    _unit doWatch _watchPos;
    _time = time + 600;
    waitUntil {sleep 2; (time > _time || !alive _unit || currentCommand _unit != "STOP") or !((group _unit) getVariable ["onTask", true])};
    _unit doWatch objNull;
    _unit setUnitPos "AUTO";
};

pl_360 = {
    params ["_group", "_pos", "_radius"];
    // private ["_radius"];
    _count = count (units _group);
    // _radius = 10;
    _diff = 360/_count;
    _movePos = [];
    for "_i" from 0 to (_count - 1) do {
        _degree = 1 + _i*_diff;
        _newPos = [_radius*(sin _degree), _radius*(cos _degree), 0] vectorAdd _pos;
        _watchPos = [100*(sin _degree), 100*(cos _degree), 0] vectorAdd _pos;
        _movePos pushBack [_newPos, _watchPos];
    };

    for "_i" from 0 to (_count - 1) do {
        [(units _group) select _i, _movePos select _i] spawn pl_move_to_360;
    };
};

pl_360_at_mappos = {
    params ["_group", "_radius", ["_taskPlanWp", []]];

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    if (count _taskPlanWp != 0) then {
        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11) or !(_group getVariable ["pl_task_planed", false])};

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false;};

    [_group] call pl_reset;

    sleep 0.2;

    playSound "beep";
    
    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\map\markers\military\circle_CA.paa"];
    [_group, getPos (leader _group), _radius] spawn pl_360;
    waitUntil {sleep 0.1; (count (waypoints _group) > 0) or !(_group getVariable ["onTask", true])};
    sleep 1;
    {
        _x enableAI "PATH";
        _x doFollow (leader _group);
        _x commandFollow (leader _group);
        _x enableAI "AUTOCOMBAT";
    } forEach (units _group);
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
};


pl_find_cover = {
    params ["_unit", "_watchPos", "_watchDir", "_radius", "_moveBehind", ["_fullCover", false]];

    _covers = nearestTerrainObjects [getPos _unit, pl_valid_covers, _radius, true, true];
    // _unit enableAI "AUTOCOMBAT";
    _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _watchPos;
    if ((count _covers) > 0) then {
        {
            if !(_x in pl_covers) exitWith {
                pl_covers pushBack _x;
                _unit doMove (getPos _x);
                waitUntil {(unitReady _unit) or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
                if ((group _unit) getVariable ["onTask", true]) then {
                    if (_fullCover) then {
                        _unit setUnitPos "DOWN";
                    }
                    else
                    {
                        _unit setUnitPos "MIDDLE";
                    };
                    if (_moveBehind) then {
                        _moveDir = [(_watchDir - 180)] call pl_angle_switcher;
                        _coverPos =  [2*(sin _moveDir), 2*(cos _moveDir), 0] vectorAdd (getPos _unit);
                        _unit doMove _coverPos;
                        waitUntil {(unitReady _unit) or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
                        if ((group _unit) getVariable ["onTask", true]) then {
                            doStop _unit;
                            _unit doWatch _watchPos;
                            _unit disableAI "PATH";
                        };
                    }
                    else
                    {
                        doStop _unit;
                        _unit doWatch _watchPos;
                        _unit disableAI "PATH";
                    };
                    [_x] spawn {
                        params ["_cover"];
                        sleep 10;
                        pl_covers deleteAt (pl_covers find _cover);
                    };
                };
            };
        } forEach _covers;
        if ((unitPos _unit) == "Auto") then {
            _unit setUnitPos "DOWN";
            doStop _unit;
            _unit doWatch _watchPos;
            _unit disableAI "PATH";
        };
    }
    else
    {
        _unit setUnitPos "DOWN";
        if (_moveBehind) then {
            _checkPos = [20 *(sin _watchDir), 20 *(cos _watchDir), 0.25] vectorAdd (getPosASL _unit);

            // // _helper = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
            // // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
            // // _helper setposASL _checkPos;
            // // _cansee = [_helper, "VIEW"] checkVisibility [(eyePos _unit), _checkPos];

            _unitPos = [0, 0, 0.25] vectorAdd (getPosASL _unit);
            _cansee = [_unit, "FIRE"] checkVisibility [_unitPos, _checkPos];
            // _unit sideChat str _cansee;
            if (_cansee < 0.6) then {
                _unit setUnitPos "MIDDLE";
            };
        };
        doStop _unit;
        _unit doWatch _watchPos;
        _unit disableAI "PATH";
    };
};

pl_deploy_static = false;

pl_take_position = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_markerName", "_isStatic", "_staticMarkerName", "_cords", "_watchDir", "_watchPos", "_offSet", "_moveDir", "_medic", "_medicPos", "_icon"];
    // _group = hcSelected player select 0;

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};
    if (visibleMap) then {
        hintSilent "";

        _message = "Select DEFENCE position on MAP <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />";
        hint parseText _message;

        _markerName = format ["defence%1%2", _group, random 1];
        createMarker [_markerName, [0,0,0]];
        _markerName setMarkerType "marker_sfp";
        _markerName setMarkerColor "colorBLUFOR";

        _markerAreaName = format ["%1defArea%2", _group, random 2];
        createMarker [_markerAreaName, [0,0,0]];
        _markerAreaName setMarkerShape "RECTANGLE";
        _markerAreaName setMarkerBrush "SolidBorder";
        _markerAreaName setMarkerColor "colorYellow";
        _markerAreaName setMarkerAlpha 0.15;
        _markerAreaName setMarkerSize [35, 4];

        onMapSingleClick {
            pl_defence_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            if (_alt) then {pl_deploy_static = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _watchDir = getPos (leader _group) getDir ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
            _markerAreaName setMarkerPos ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
            _markerAreaName setMarkerDir _watchDir;
            _markerName setMarkerPos ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
            _markerName setMarkerDir _watchDir;
            sleep 0.01;
        };
        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith { 
            deleteMarker _markerName; 
            deleteMarker _markerAreaName; 
            pl_cancel_strike = false;
        };
        _message = "Select Position FACING <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
        <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>DEPLOY Static Weapon</t>";
        hint parseText _message;

        sleep 0.1;
        _cords = pl_defence_cords;

        _markerAreaName setMarkerPos _cords;
        _markerName setMarkerPos _cords;

        onMapSingleClick {
            pl_mortar_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            if (_alt) then {pl_deploy_static = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _markerName setMarkerDir _watchDir;
            _markerAreaName setMarkerDir _watchDir;
            sleep 0.01;
        };
        pl_mapClicked = false;

        _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";

        // Wait until planed Task Wp Reached then continue Code if pl_reset called cancel execution
        if (count _taskPlanWp != 0) then {

            // add Arrow indicator
            pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

            waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false])};

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
            _group setVariable ["pl_task_planed", false];
        };

        if (pl_cancel_strike) exitWith {
            pl_cancel_strike = false;
            deleteMarker _markerName;
            deleteMarker _markerAreaName;
          };

        [_group] call pl_reset;

        sleep 0.2;

        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", _icon];

        _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _cords;
        _leaderDir = _watchDir - 90;
        _leaderPos = [6*(sin _leaderDir), 6*(cos _leaderDir), 0] vectorAdd _cords;
        _medicDir = _watchDir - 180;
        _medicPos = [15*(sin _medicDir), 15*(cos _medicDir), 0] vectorAdd _cords;
        if (pl_deploy_static) then {
            _isStatic = [_group, _markerName, _watchPos, _leaderPos] call pl_reworked_bis_unpack;
            pl_deploy_static = false;
            if !(_isStatic#0) then {
                hint "No Static Weapon!";
            };
        }
        else
        {
            _isStatic = [false, []];
            pl_denfence_draw_array pushBack [_markerName, (leader _group)];
        };
        sleep 0.1;

        _medic = {
            if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) exitWith {_x};
        } forEach (units _group);


        leader _group groupRadio "SentCmdHide";

        if (_isStatic#0) then {
            _staticMarkerName = format ["static%1", _group];
            createMarker [_staticMarkerName, _cords];
            _staticMarkerName setMarkerType "marker_afp";
            _staticMarkerName setMarkerColor "colorBLUFOR";
            _staticMarkerName setMarkerDir _watchDir;
            (leader _group) addWeapon "Binocular";
            playSound "beep";
            // leader _group sideChat format ["Roger, %1 will deploy static Weapon at designated coordinates, over",(groupId _group)];
            _offSet = 9;
        }
        else
        {
            playSound "beep";
            // leader _group sideChat format ["Roger, %1 will defend the Position, over",(groupId _group)];
            _offSet = 0;
        };
        for "_i" from 0 to ((count (units _group))- 1) do {
            if ((_i % 2) == 0) then {
                _offSet = _offSet + 9;
                _moveDir = _watchDir - 90;
            }
            else
            {
                _moveDir = _watchDir + 90;
            };
            _movePos = [_offSet*(sin _moveDir), _offSet*(cos _moveDir), 0] vectorAdd _cords;
            _unit = (units _group) select _i;
            if !(_unit in _isStatic#1) then {
                private _isLeader = false;
                if (_unit == (leader _group)) then {
                    _movePos = _cords;
                    _isLeader = true;
                };
                if (!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) then {
                    if (_unit == _medic) then {
                        _movePos = _medicPos;
                    };
                };
                [_unit, _movePos, _watchDir, _isLeader, _markerName, _group] spawn {
                    params ["_unit", "_pos", "_watchDir", "_isLeader", "_markerName", "_group"];
                    _unit disableAI "AUTOCOMBAT";
                    _unit disableAI "AUTOTARGET";
                    _unit disableAI "TARGET";
                    // _unit disableAI "FSM";
                    _unit doMove _pos;
                    _unit setDestination [_pos, "FORMATION PLANNED", false];
                    _reachable = [_unit, _pos, 20] call pl_not_reachable_escape;
                    sleep 0.5;
                    waitUntil {(!alive _unit) or (unitReady _unit) or !(_group getVariable ["onTask", true])};
                    _unit enableAI "AUTOCOMBAT";
                    _unit enableAI "AUTOTARGET";
                    _unit enableAI "TARGET";
                    // _unit enableAI "FSM";
                    if (_group getVariable ["onTask", true]) then {
                        [_unit, _pos, _watchDir, 7, true] spawn pl_find_cover;
                    };
                    if (_isLeader) then {
                        pl_denfence_draw_array = pl_denfence_draw_array - [[_markerName, _unit]];
                    };
                };
            };
        };
        // Cancel Task
        
        if (!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) then {
            _medic setVariable ["pl_is_ccp_medic", true];
            while {(_group getVariable ["onTask", true])} do {
                _time = time + 10;
                waitUntil {time > _time or !(_group getVariable ["onTask", true])};
                {
                    if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                        _medic setUnitPos "MIDDLE";
                        _medic enableAI "PATH";
                        _h1 = [_group, _medic, nil, _x, _medicPos, 40, "onTask"] spawn pl_ccp_revive_action;
                        waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                        [_x, getPos _x, getDir _x, 7, false] spawn pl_find_cover;
                        sleep 1;
                        waitUntil {unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                        [_medic, _medicPos, getDir _medic, 10, false] spawn pl_find_cover;
                    };
                    if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and !(lifeState _x isEqualTo "INCAPACITATED")) then {
                        _medic setUnitPos "MIDDLE";
                        _medic enableAI "PATH";
                        _h1 = [_medic, _x, _medicPos, "onTask"] spawn pl_medic_heal;
                        waitUntil {scriptDone _h1 or !(_group getVariable ["onTask", true])};
                        sleep 1;
                        waitUntil {unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                        [_medic, _medicPos, getDir _medic, 10, false] spawn pl_find_cover;
                    };
                } forEach (units _group);
            };
            _medic setVariable ["pl_is_ccp_medic", false];
        }
        else
        {
            waitUntil {!(_group getVariable ["onTask", true])};
        };
        if (_isStatic#0) then {
            _weapon = {
                if ((vehicle _x) != _x) exitWith {vehicle _x};
                objNull
            } forEach (units _group);
            if !(isNull _weapon) then {
                [_group, _weapon] call pl_reworked_bis_pack;
            };
            deleteMarker _staticMarkerName;
            (leader _group) removeWeapon "Binocular";
        };
        deleteMarker _markerName;
        deleteMarker _markerAreaName;
    };
};

pl_full_cover = {
    params ["_group"];
    private ["_crew"];

    [_group] call pl_reset;

    sleep 0.2;
    playsound "beep";
    leader _group groupRadio "SentCmdHide";

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", '\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa'];

    _crew = [units _group];
    if (vehicle (leader _group) != leader _group) then {
        // _group setCombatMode "GREEN";
        // _group setVariable ["pl_hold_fire", true];
        // _group setVariable ["pl_combat_mode", true];
        _vic = vehicle (leader _group);
        {
            _x setVariable ["pl_damage_reduction", true];
            _x setUnitTrait ["camouflageCoef", 0.5, true];
            _x disableAI "PATH";
        } forEach (units _group);
        {
            _x setVariable ["pl_damage_reduction", true];
            _crew pushBackUnique _x;
        } forEach (crew _vic);

        _vic setUnitTrait ["camouflageCoef", 0.5, true];
        // _vic setVariable ["pl_damage_reduction", true]
    }
    else
    {
        {
            [_x, getPos _x, getDir _x, 5, false, true] spawn pl_find_cover;
            // _x setUnitPos "DOWN";
            // _x disableAI "PATH";
            _x setVariable ["pl_damage_reduction", true];
            _x setUnitTrait ["camouflageCoef", 0.5, true];
        } forEach (units _group);
    };

    waitUntil {!(_group getVariable ["onTask", true])};

    {
        _x setVariable ["pl_damage_reduction", false];
        _x setUnitTrait ["camouflageCoef", 1, true];
        _x enableAI "PATH";
    } forEach (units _group);

    if (vehicle (leader _group) != leader _group) then {
        // _group setCombatMode "YELLOW";
        // _group setVariable ["pl_hold_fire", false];
        _vic = vehicle (leader _group);
        _group setVariable ["pl_combat_mode", false];
        {
            _x setVariable ["pl_damage_reduction", false];
            _x setUnitTrait ["camouflageCoef", 1, true];
        } forEach _crew;

        _vic setUnitTrait ["camouflageCoef", 1, true];
        // _vic setVariable ["pl_damage_reduction", false]
    };
};

pl_defend_position = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_watchDir", "_cords", "_watchPos", "_markerAreaName", "_markerDirName", "_buildings", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon"];
    
    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";

    _markerAreaName = format ["%1garrison%2", _group, random 2];
    createMarker [_markerAreaName, [0,0,0]];
    _markerAreaName setMarkerShape "ELLIPSE";
    _markerAreaName setMarkerBrush "SolidBorder";
    _markerAreaName setMarkerColor "colorYellow";
    _markerAreaName setMarkerAlpha 0.15;
    _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];

    if (visibleMap) then {
        hintSilent "";

        pl_garrison_area_size = 25;
        pl_360_area = false;
        _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br /> <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
        hint parseText _message;

        onMapSingleClick {
            pl_defence_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerAreaName setMarkerPos _mPos;
            if (inputAction "MoveForward" > 0) then {pl_garrison_area_size = pl_garrison_area_size + 5; sleep 0.1};
            if (inputAction "MoveBack" > 0) then {pl_garrison_area_size = pl_garrison_area_size - 5; sleep 0.1};
            _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];
            if (pl_garrison_area_size >= 55) then {pl_garrison_area_size = 55};
            if (pl_garrison_area_size <= 10) then {pl_garrison_area_size = 10};
        };

        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerAreaName};
        _message = "Select Defence FACING <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
        <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>360° Security</t>";
        hint parseText _message;

        sleep 0.1;
        _cords = pl_defence_cords;
        _markerDirName = format ["defenceAreaDir%1%2", _group, random 2];
        createMarker [_markerDirName, _cords];
        _markerDirName setMarkerPos _cords;
        _markerDirName setMarkerType "marker_afp";
        _markerDirName setMarkerColor "colorBLUFOR";

        onMapSingleClick {
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            if (_alt) then {pl_360_area = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _markerDirName setMarkerDir _watchDir;
        };
        pl_mapClicked = false;
        if (pl_360_area) then {
            _markerDirName setMarkerType "mil_circle";
            _markerDirName setMarkerSize [0.5, 0.5];
        };

        if (count _taskPlanWp != 0) then {

            // add Arrow indicator
            pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

            waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false])};

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
            _group setVariable ["pl_task_planed", false];
        };

        // if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
        _watchDir = ((leader _group) getDir player) - 180;
        pl_garrison_area_size = 10;
        pl_360_area = true;
        _markerDirName = format ["defenceArea%1", _group];
        createMarker [_markerDirName, _cords];
        _markerDirName setMarkerType "mil_circle";
        _markerDirName setMarkerColor "colorBLUFOR";
        _markerAreaName setMarkerPos _cords;
        _markerDirName setMarkerSize [0.5, 0.5];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

    _buildings = nearestObjects [_cords, ["house"], pl_garrison_area_size];
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 2) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    // if ((count _validBuildings == 0)) exitWith {hint "No buildings in Area!"; deleteMarker _markerAreaName; deleteMarker _markerDirName;};

    [_group] call pl_reset;

    sleep 0.2;

    playSound "beep";

    if (pl_360_area) then {_icon = "\A3\ui_f\data\map\markers\military\circle_CA.paa"};
    if ((count _validBuildings) > 0) then {_icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _medic = {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) exitWith {_x};
    } forEach (units _group); 


    _validPos = [];
    _allPos = [];
    {
        _building = _x;
        pl_draw_building_array pushBack [_group, _building];
        _bPos = [_building] call BIS_fnc_buildingPositions;
        {
            _allPos pushBack _x;
            _watchPos = [10*(sin _watchDir), 10*(cos _watchDir), 1.7] vectorAdd _x;
            _standingPos = [0, 0, 1.7] vectorAdd _x;
            _standingPos = ATLToASL _standingPos;
            _watchPos = ATLToASL _watchPos;

            // _helper = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
            // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
            // _helper setposASL _standingPos;

            _cansee = [objNull, "VIEW"] checkVisibility [_standingPos, _watchPos];
            if (_cansee == 1) then {
                _validPos pushBack _x;
            };
        } forEach _bPos;
    } forEach _validBuildings;


    // {
    //     _helper = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
    //     _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
    //     _helper setposATL _x;
    // } forEach _validPos;

    _watchPos = [500*(sin _watchDir), 500*(cos _watchDir), 0] vectorAdd _cords;

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _units = units _group;
    _posOffsetStep = pl_garrison_area_size / (count _units);
    private _posOffset = 0 + _posOffsetStep;

    for "_i" from 0 to (count _units) - 1 step 1 do {
        private _cover = false;
        private _covers = nearestTerrainObjects [_cords, pl_valid_covers, pl_garrison_area_size, true, true];
        // private _blacklist = nearestTerrainObjects [_cords, [], (pl_garrison_area_size - 8), true, true];
        // _covers = _covers - _blacklist;
        _covers = [_covers, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        // move to optimal Pos first
        if (_i < (count _validPos)) then {
            _pos = _validPos#_i;
            _unit = _units#_i;
        }
        else
        {
            // move to not optimal Pos
            if (_i < (count _allPos)) then {
                _pos = _allPos#_i;
                _unit = _units#_i;
            }
            // no building pos move to cover
            else
            {
                _cover = true;
                _unit = _units#_i;
                // move to avaible cover
                if ((_i < count _covers) and !(pl_360_area)) then {
                    _pos = getPos (_covers#_i);
                    if (_i == (count _units) - 1) then {
                        _pos = getPos (_covers#((count _covers) - 1));
                        _watchDir = _watchDir - 180;
                    };
                }
                else
                {
                    // if 360 Option move to 360 Positions
                    if (pl_360_area) then {
                        _diff = 360/ (count _units);
                        _degree = 1 + _i*_diff;
                        _pos = [pl_garrison_area_size*(sin _degree), pl_garrison_area_size*(cos _degree), 0] vectorAdd _cords;
                        _watchDir = _degree;
                    }
                    // if no more covers avaible move to left or right side of best cover
                    else
                    {
                        _coverPos = _cords;
                        if ((count _covers) > 0) then {_coverPos = getPos (_covers#0)};
                        _dirOffset = 90;
                        if (_i % 2 == 0) then {_dirOffset = -90};
                        _pos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _coverPos;
                        _posOffset = _posOffset + _posOffsetStep;
                    };
                };
            };
        };
        _pos = ATLToASL _pos;
        private _unitPos = "UP";
        _checkPos = [7*(sin _watchDir), 7*(cos _watchDir), 1.7] vectorAdd _pos;
        _crouchPos = [0, 0, 0.6] vectorAdd _pos;
        if (([objNull, "VIEW"] checkVisibility [_crouchPos, _checkPos]) == 1) then {
            _unitPos = "MIDDLE";
        };
        if (([objNull, "VIEW"] checkVisibility [_pos, _checkPos]) == 1) then {
            _unitPos = "DOWN";
        };

        _pos = ASLToATL _pos;

        [_unit, _pos, _watchPos, _watchDir, _unitPos, _cover] spawn {
            params ["_unit", "_pos", "_watchPos", "_watchDir", "_unitPos", "_cover"];
            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "TARGET";
            _unit disableAI "AUTOTARGET";
            _unit doMove _pos;
            // _unit setDestination [_pos, "LEADER DIRECT", false];
            _unit setDestination [_pos, "LEADER PLANNED", true];
            if !([_unit, _pos, pl_garrison_area_size] call pl_not_reachable_escape) then {_cover = true};

            sleep 0.2;

            waitUntil {(unitReady _unit) or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "TARGET";
            _unit enableAI "AUTOTARGET";
            if ((group _unit) getVariable ["onTask", true]) then {
                if !(_cover) then {
                    _unit doWatch _watchPos;
                    doStop _unit;
                    _unit setUnitPos _unitPos;
                    _unit disableAI "PATH";
                }
                else
                {
                    [_unit, _watchPos, _watchDir, 5, true] spawn pl_find_cover;
                };
            };
        };
    };

    // hint (str _allPos);

    if (!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) then {
        // _medic setVariable ["pl_is_ccp_medic", true];
        while {(_group getVariable ["onTask", true])} do {
            _time = time + 10;
            waitUntil {time > _time or !(_group getVariable ["onTask", true])};
            {
                if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                    _medic setUnitPos "MIDDLE";
                    _medic enableAI "PATH";
                    _h1 = [_group, _medic, nil, _x, getPos _medic, 40, "onTask"] spawn pl_ccp_revive_action;
                    waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                    [_x, getPos _x, getDir _x, 7, false] spawn pl_find_cover;
                    sleep 1;
                    waitUntil {unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                    [_medic, getPos _medic, getDir _medic, 10, false] spawn pl_find_cover;
                };
                if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and !(lifeState _x isEqualTo "INCAPACITATED")) then {
                    _medic setUnitPos "MIDDLE";
                    _medic enableAI "PATH";
                    _h1 = [_medic, _x, getPos _medic, "onTask"] spawn pl_medic_heal;
                    waitUntil {scriptDone _h1 or !(_group getVariable ["onTask", true])};
                    sleep 1;
                    waitUntil {unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                    [_medic, getPos _medic, getDir _medic, 10, false] spawn pl_find_cover;
                };
            } forEach (units _group);
        };
        // _medic setVariable ["pl_is_ccp_medic", false];
    }
    else
    {
        waitUntil {!(_group getVariable ["onTask", true])};
    };
    deleteMarker _markerAreaName;
    deleteMarker _markerDirName;

    {
        pl_draw_building_array = pl_draw_building_array - [[_group, _x]];
    } forEach _validBuildings;
};




