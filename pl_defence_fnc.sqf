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
pl_valid_covers = ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "FENCE", "WALL"];

// // _helper = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
// // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
// // _helper setposASL _checkPos;

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
    if ((count _covers) > 0) then {
        {
            if !(_x in pl_covers) exitWith {
                pl_covers pushBack _x;
                _movePos = getPos _x;
            };
        } forEach _covers;
    }
    else
    {
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
    
    if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _leader = leader _group;
    if (_leader == vehicle _leader) then {
        // leader _group sideChat "Roger Falling Back, Over";
        // [leader _group, "SmokeShellMuzzle"] call BIS_fnc_fire;
        _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa";
        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", _icon];
        _wp = _group addWaypoint [_cords, 0];
        _group setBehaviour "AWARE";
        _group setSpeedMode "FULL";
        _group setCombatMode "BLUE";
        _group setVariable ["pl_combat_mode", true];

        pl_draw_planed_task_array pushBack [_wp, _icon];

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

        waitUntil {sleep 0.5; (((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 15) or !(_group getVariable ["onTask", true])};
        
        sleep 1;

        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
        _group setVariable ["pl_combat_mode", false];
        _group setSpeedMode "NORMAL";
        _group setCombatMode "YELLOW";
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
        // leader _group sideChat "We reached Fall Back Position, Over";
    }
    else
    {
        _group addWaypoint [_cords, 0];
        _group setVariable ["setSpecial", true];
        _group setVariable ["onTask", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa"];
        _vic = vehicle _leader;
        _vic limitSpeed 5000;
        _vDir = (getDir _vic) - 180;
        [_vic, "SmokeLauncher"] call BIS_fnc_fire;
        _time = time + 45;
        waitUntil {sleep 0.5; (((leader _group) distance2D waypointPosition[_group, currentWaypoint _group]) < 25) or (time >= _time) or !(_group getVariable ["onTask", true])};

        sleep 2;
        [_group, str _vDir] call pl_watch_dir;
        _group setVariable ["setSpecial", false];
        _group setVariable ["onTask", false];
        _vicSpeedLimit = _vic getVariable ["pl_speed_limit", "50"];
        if !(_vicSpeedLimit isEqualTo "MAX") then {
            _vic limitSpeed (parseNumber _vicSpeedLimit);
        };
    };
};

pl_deploy_static = false;

pl_take_position = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_markerName", "_markerAreaName", "_isStatic", "_staticMarkerName", "_cords", "_watchDir", "_watchPos", "_offSet", "_moveDir", "_medic", "_medicPos", "_icon"];
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
        _markerName setMarkerColor pl_side_color;
        // _markerName setMarkerShadow false;

        pl_take_position_size = 30;
        _markerAreaName = format ["%1defArea%2", _group, random 2];
        createMarker [_markerAreaName, [0,0,0]];
        _markerAreaName setMarkerShape "RECTANGLE";
        _markerAreaName setMarkerBrush "SolidBorder";
        _markerAreaName setMarkerColor pl_side_color;
        _markerAreaName setMarkerAlpha 0.25;
        _markerAreaName setMarkerSize [pl_take_position_size, 2];

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

        onMapSingleClick {
            pl_defence_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            if (_alt) then {pl_deploy_static = true};
            hintSilent "";
            onMapSingleClick "";
        };

        // while {!pl_mapClicked} do {
        //     _watchDir = getPos (leader _group) getDir ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
        //     _markerAreaName setMarkerPos ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
        //     _markerAreaName setMarkerDir _watchDir;
        //     _markerName setMarkerPos ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
        //     _markerName setMarkerDir _watchDir;
        //     sleep 0.01;
        // };


        _maxLine_size = 100;
        _minLine_size = 10;
        

        player enableSimulation false;

        while {!pl_mapClicked} do {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
                _watchDir = _rangelimiterCenter getDir _mPos;
                _markerAreaName setMarkerPos _mPos;
                _markerAreaName setMarkerDir _watchDir;
                _markerName setMarkerPos _mPos;
                _markerName setMarkerDir _watchDir;
            };
            if (inputAction "MoveForward" > 0) then {pl_take_position_size = pl_take_position_size + 5; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_take_position_size = pl_take_position_size - 5; sleep 0.05};
            _markerAreaName setMarkerSize [pl_take_position_size, 2];
            if (pl_take_position_size >= _maxLine_size) then {pl_take_position_size = _maxLine_size};
            if (pl_take_position_size <= _minLine_size) then {pl_take_position_size = _minLine_size};
        };
        sleep 0.01;

        player enableSimulation true;


        pl_mapClicked = false;
        deleteMarker _markerBorderName;
        if (pl_cancel_strike) exitWith { 
            deleteMarker _markerName; 
            deleteMarker _markerAreaName;
            pl_cancel_strike = false;
        };
        _message = "Select Position FACING <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
        <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>DEPLOY static weapon</t> <br />";
        hint parseText _message;

        _cords = getMarkerPos _markerName;

        _markerAreaName setMarkerPos _cords;
        _markerName setMarkerPos _cords;

        sleep 0.1;
        // _cords = pl_defence_cords;


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

        deleteMarker _markerAreaName;

        _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";

        // Wait until planed Task Wp Reached then continue Code if pl_reset called cancel execution
        if (count _taskPlanWp != 0) then {

            // add Arrow indicator
            pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

            waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false]) or (_group getVariable ["pl_disembark_finished", false])};
            _group setVariable ["pl_disembark_finished", nil];

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

        // Whyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy?????????????????
        // if (pl_enable_beep_sound) then {playSound "beep"};
        [_group, "confirm", 1] call pl_voice_radio_answer;
        [_group] call pl_reset;

        sleep 0.5;

        [_group] call pl_reset;

        sleep 0.5;

        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", _icon];
        _group setVariable ["pl_in_position", true];

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
        leader _group playActionNow "GestureCover"; 

        if (_isStatic#0) then {
            _staticMarkerName = format ["static%1", _group];
            createMarker [_staticMarkerName, _cords];
            _staticMarkerName setMarkerType "marker_afp";
            _staticMarkerName setMarkerColor pl_side_color;
            _staticMarkerName setMarkerDir _watchDir;
            (leader _group) addWeapon "Binocular";
            if (pl_enable_beep_sound) then {playSound "beep"};
            // leader _group sideChat format ["Roger, %1 will deploy static Weapon at designated coordinates, over",(groupId _group)];
            _offSet = 9;
        }
        else
        {
            if (pl_enable_beep_sound) then {playSound "beep"};
            // leader _group sideChat format ["Roger, %1 will defend the Position, over",(groupId _group)];
            _offSet = 0;
        };

        private _units = [];
        private _mgGunners = [];
        private _atSoldiers = [];
        private _atEscord = objNull;
        private _medic = objNull;


        // classify units
        {
            if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
            if ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun" and secondaryWeapon _x == "") then {
                _units pushBackUnique _x;
            };
            if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                _mgGunners pushBackUnique _x;
            };
            if (secondaryWeapon _x != "") then {
                _atSoldiers pushBackUnique _x;
            };
        } forEach (units _group);

        {_units pushBack _x} forEach _atSoldiers;
        {_units pushBack _x} forEach _mgGunners;

        reverse _units;

        _lineSpacing = (pl_take_position_size / (count (units _group))) * 2;
        _startPos = [(_lineSpacing / 2) *(sin (_watchDir + 90)), (_lineSpacing / 2) *(cos (_watchDir + 90)), 0] vectorAdd _cords;
        private _posArray = [];
        for "_i" from 0 to ((count (units _group))- 1) do {
            if ((_i % 2) != 0) then {
                _offSet = _offSet + _lineSpacing;
                _moveDir = _watchDir - 90;
            }
            else
            {
                _moveDir = _watchDir + 90;
            };
            _movePos = _startPos getPos [_offSet, _moveDir];
            _posArray pushBack _movePos;
        };
        _posArray = [_posArray, [], {[_x, _watchDir, 1] call pl_fof_check}, "DESCEND"] call BIS_fnc_sortBy;
        for "_j" from 0 to (count _units) - 1 do {
            _unit = _units select _j;
            _movePos = _posArray select _j;

            if !(_unit in (_isStatic#1)) then {
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
                    sleep 1;
                    waitUntil {sleep 0.5; (!alive _unit) or !(_group getVariable ["onTask", true]) or [_unit, _pos] call pl_position_reached_check};
                    _unit enableAI "AUTOCOMBAT";
                    _unit enableAI "AUTOTARGET";
                    _unit enableAI "TARGET";
                    // _unit enableAI "FSM";
                    if (_group getVariable ["onTask", true]) then {
                        if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun" or secondaryWeapon _unit != "") then {
                            [_unit, _pos, _watchDir, 0, false] spawn pl_find_cover;
                        } else {
                            [_unit, _pos, _watchDir, 7, true] spawn pl_find_cover;
                        };
                    };
                    if (_isLeader) then {
                        pl_denfence_draw_array = pl_denfence_draw_array - [[_markerName, _unit]];
                    };
                };
            };
        };
        // Cancel Task
        
        if (!(isNil "_medic") and pl_enabled_medical) then {

            waitUntil {sleep 0.5; _group getVariable ["pl_healing_active", false] or !(_group getVariable ["onTask", true])};

            _medic setVariable ["pl_is_ccp_medic", true];
            while {(_group getVariable ["onTask", true])} do {
                _time = time + 10;
                waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true])};
                {
                    if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                        _medic setUnitPos "MIDDLE";
                        _medic enableAI "PATH";
                        _h1 = [_group, _medic, objNull, _x, _medicPos, 40, "onTask"] spawn pl_ccp_revive_action;
                        waitUntil {sleep 0.5; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                        [_x, getPos _x, getDir _x, 7, false] spawn pl_find_cover;
                        sleep 1;
                        waitUntil {sleep 0.5; unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                        [_medic, _medicPos, getDir _medic, 10, false] spawn pl_find_cover;
                    };
                    // if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and !(lifeState _x isEqualTo "INCAPACITATED")) then {
                    //     _medic setUnitPos "MIDDLE";
                    //     _medic enableAI "PATH";
                    //     _h1 = [_medic, _x, _medicPos, "onTask"] spawn pl_medic_heal;
                    //     waitUntil {sleep 0.5; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                    //     sleep 1;
                    //     waitUntil {sleep 0.5; unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                    //     [_medic, _medicPos, getDir _medic, 10, false] spawn pl_find_cover;
                    // };
                } forEach (units _group);
            };
            _medic setVariable ["pl_is_ccp_medic", false];
        }
        else
        {
            waitUntil {sleep 0.5; !(_group getVariable ["onTask", true])};
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
    private ["_crew", "_isTransport"];

    // Whyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy?????????????????
    if (pl_enable_beep_sound) then {playSound "beep"};
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;
    leader _group groupRadio "SentCmdHide";


    _crew = [];
    _isTransport = false;
    if (vehicle (leader _group) != leader _group) then {
        // _group setCombatMode "GREEN";
        // _group setVariable ["pl_hold_fire", true];
        // _group setVariable ["pl_combat_mode", true];
        _vic = vehicle (leader _group);
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

        _vic setUnitTrait ["camouflageCoef", 0.5, true];
        // _vic setVariable ["pl_damage_reduction", true]
        if ((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa") then {
            _isTransport = true;
        };
    }
    else
    {
        {
            [_x, getPos _x, getDir _x, 7, false, false] spawn pl_find_cover;
            // _x setUnitPos "DOWN";
            // _x disableAI "PATH";
            _x setVariable ["pl_damage_reduction", true];
            _x setUnitTrait ["camouflageCoef", 0.5, true];
        } forEach (units _group);
    };

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", '\A3\3den\data\Attributes\Stance\down_ca.paa'];

    waitUntil {sleep 0.5; !(_group getVariable ["onTask", true])};

    {
        _x setVariable ["pl_damage_reduction", false];
        _x setUnitTrait ["camouflageCoef", 1, true];
        _x enableAI "PATH";
    } forEach (units _group);

    if (vehicle (leader _group) != leader _group) then {
        // _group setCombatMode "YELLOW";
        // _group setVariable ["pl_hold_fire", false];
        _vic = vehicle (leader _group);

        // hint str _crew;

        _group setVariable ["pl_combat_mode", false];
        {
            _x setVariable ["pl_damage_reduction", false];
            _x setUnitTrait ["camouflageCoef", 1, true];
        } forEach _crew;

        _vic setUnitTrait ["camouflageCoef", 1, true];
        // _vic setVariable ["pl_damage_reduction", false]
        sleep 0.2;
        if (_isTransport) then {
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", '\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa'];
        };
    };
};


pl_defend_position = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_watchDir", "_cords", "_watchPos", "_defenceWatchPos", "_markerAreaName", "_markerDirName", "_covers", "_buildings", "_doorPos", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon", "_unitWatchDir", "_vPosCounter", "_defenceAreaSize", "_mgPosArray", "_mgPos", "_mgOffset", "_atEscord"];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";


    if (visibleMap) then {
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
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
                _watchDir = _rangelimiterCenter getDir _mPos;
                _markerAreaName setMarkerPos _mPos;
                _markerDirName setMarkerPos _mPos;
                _markerDirName setMarkerDir _watchDir;
            };
            if (inputAction "MoveForward" > 0) then {pl_garrison_area_size = pl_garrison_area_size + 5; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_garrison_area_size = pl_garrison_area_size - 5; sleep 0.05};
            _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];
            if (pl_garrison_area_size >= 55) then {pl_garrison_area_size = 55};
            if (pl_garrison_area_size <= 10) then {pl_garrison_area_size = 10};
        };

        player enableSimulation true;

        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerAreaName};
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
            _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _markerDirName setMarkerDir _watchDir;
            _defenceWatchPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        };
        pl_mapClicked = false;
        // pl_show_watchpos_selector = false;

        // _defenceWatchPos = pl_defenceWatchPos;
        _defenceWatchPos = _cords getPos [250, _watchDir];
        _defenceWatchPos = ASLToATL _defenceWatchPos;
        _defenceWatchPos = [_defenceWatchPos#0, _defenceWatchPos#1, 2];
        _defenceWatchPos = ATLToASL _defenceWatchPos;

        deletemarker _markerAreaName;

        if (pl_360_area) then {
            _markerDirName setMarkerType "mil_circle";
            _markerDirName setMarkerSize [0.5, 0.5];
        };

        if (count _taskPlanWp != 0) then {

            // add Arrow indicator
            pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

            waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false]) or (_group getVariable ["pl_disembark_finished", false])};
            _group setVariable ["pl_disembark_finished", nil];

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
            _group setVariable ["pl_task_planed", false];
        };

        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
        _watchDir = ((leader _group) getDir player) - 180;
        _defenceAreaSize = 10;
        pl_360_area = true;
        _markerDirName = format ["defenceArea%1", _group];
        createMarker [_markerDirName, _cords];
        _markerDirName setMarkerType "mil_circle";
        _markerDirName setMarkerColor pl_side_color;
        _markerAreaName setMarkerPos _cords;
        _markerDirName setMarkerSize [0.5, 0.5];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};



    // if ((count _validBuildings == 0)) exitWith {hint "No buildings in Area!"; deleteMarker _markerAreaName; deleteMarker _markerDirName;};


    // if (pl_enable_beep_sound) then {playSound "beep"};

    // player sideRadio "SentCmdHide";
    [_group, "confirm", 1] call pl_voice_radio_answer;

    // Whyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy?????????????????
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _buildings = nearestObjects [_cords, ["House", "Strategic", "Ruins"], _defenceAreaSize, true];
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 4) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    // if (pl_360_area) then {_icon = "\A3\ui_f\data\map\markers\military\circle_CA.paa"};
    if ((count _validBuildings) > 0) then {_icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _group setVariable ["pl_combat_mode", true];
    _group setVariable ["pl_in_position", true];

    _validPos = [];
    _allPos = [];
    {
        _building = _x;
        pl_draw_building_array pushBack [_group, _building];
        _bPos = [_building] call BIS_fnc_buildingPositions;
        _vPosCounter = 0;
        {
            _bP = _x;
            _allPos pushBack _bP;
            _watchPos = [3*(sin _watchDir), 3*(cos _watchDir), 1] vectorAdd _bP;
            _watchPos = ATLToASL _watchPos;
            if !(lineIntersects [_watchPos, _watchPos vectorAdd [0, 0, 6]]) then {

                _standingPos = [0, 0, 1] vectorAdd _bP;
                _standingPos = ATLToASL _standingPos;

                // _helper1 = createVehicle ["Sign_Sphere25cm_F", _standingPos, [], 0, "none"];
                // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                // _helper1 setposASL _standingPos;

                // _helper2 = createVehicle ["Sign_Sphere25cm_F", _watchPos, [], 0, "none"];
                // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                // _helper2 setposASL _watchPos;

                _vis = lineIntersectsSurfaces [_standingPos, _watchPos, objNull, objNull, true, 1, "VIEW"];
                if (_vis isEqualTo []) then {

                    _bPos deleteAt (_bPos find _bP);
                    _validPos pushBack _bP;
                    _vPosCounter = _vPosCounter + 1;
                };
            };
        } forEach _bPos;

        if (_vPosCounter <= 2) then {
            _validPos pushBack (selectRandom _bPos);
        };
    } forEach _validBuildings;

    // deploy packed static weapons if no buildings
    _isStatic = [false, []];
    // if (_validBuildings isEqualTo [] and !(pl_360_area)) then {
    //     _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _cords;
    //     _leaderDir = _watchDir - 90;
    //     _leaderPos = [6*(sin _leaderDir), 6*(cos _leaderDir), 0] vectorAdd _cords;
    //     (leader _group) addWeapon "Binocular";
    //     _isStatic = [_group, _cords, _watchPos, _leaderPos] call pl_reworked_bis_unpack;
    // };

    _watchPos = [500*(sin _watchDir), 500*(cos _watchDir), 0] vectorAdd _cords;

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _units = [];
    private _mgGunners = [];
    private _atSoldiers = [];
    private _atEscord = objNull;
    private _medic = objNull;


    // classify units
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun" and secondaryWeapon _x == "" and _x != _medic) then {
            _units pushBackUnique _x;
        };
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
            _mgGunners pushBackUnique _x;
        };
        if (secondaryWeapon _x != "") then {
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


    for "_i" from 0 to (count _units) - 1 step 1 do {
        private _cover = false;
        if !(_buildings isEqualTo []) then {

            _covers = [];
            {
                _buildingCenter = getPos _x;
                _coverSearchPos = _buildingCenter getPos [10, _watchDir];
                _c = nearestTerrainObjects [_coverSearchPos, pl_valid_covers, 15, true, true];
                _covers = _covers + _c;
            } forEach _buildings;
            _covers = [_covers, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
        } else {
            _covers = [];
        };

        {
            // _box = 2 boundingBoxReal _x;
            // _boxCenter = getPosVisual _x;
            // _minPos = _boxCenter vectorAdd [(_box#0)#0, (_box#0)#1, 0];
            // _maxPos = _boxCenter vectorAdd [(_box#1)#0, (_box#1)#1, 0];

            // _m = createMarker [str (random 1), _minPos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];

            // _m = createMarker [str (random 1), _maxPos];
            // _m setMarkerType "mil_dot";
            // _m setMarkerSize [0.5, 0.5];

            // private _houseCornerPos = [];
            _corners = [_x] call BIS_fnc_boundingBoxCorner;

            {
                _m = createMarker [str (random 1), _x];
                _m setMarkerType "mil_dot";
                _m setMarkerSize [0.5, 0.5];
            } forEach _corners;



        } forEach _buildings;

        _unitWatchDir = _watchDir;
        private _moveToStatic = false;
        if !(_avaiableWeapons isEqualTo []) then {
            _weapon = selectRandom _avaiableWeapons;
            _weapon setDir _watchDir;
            (_units#_i) assignAsGunner _weapon;
            [_units#_i] orderGetIn true;
            _group addVehicle _weapon;
            _avaiableWeapons deleteAt (_avaiableWeapons find _weapon);
            _moveToStatic = true;
        };

        // move to optimal Pos first
        if (_i < (count _validPos)) then {
            _pos = _validPos#_i;
            _unit = _units#_i;
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
                _pos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _cords;
                if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
            }
            else
            {
                if (_coverCount < (count _covers)) then {
                    _pos = getPos (_covers#_coverCount);
                    _coverCount = _coverCount + 1;
                } else {
                    _offSet = ((((boundingBox (_buildings#0))#1)#0) + 4) + _posOffset;
                    _forwardPos = getPos (_buildings#0);
                    if (_i % 2 == 0) then {
                        _pos = _forwardPos getPos [_offSet, _watchDir + 90]
                    } else {
                        _pos = _forwardPos getPos [_offSet, _watchDir - 90];
                        _posOffset = _posOffset + _posOffsetStep;
                    };
                };


                // _m = createMarker [str (random 1), _pos];
                // _m setMarkerType "mil_dot";
                // _m setMarkerSize [0.5, 0.5];

            };
        };

        // seelct best Medic Pos
        if (!(isNil "_medic") and pl_enabled_medical) then {
            if (_unit == _medic) then {
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
                _pos = ([_posCandidates, [], {[objNull, "VIEW", objNull] checkVisibility [_x, [_x getPos [50, _watchDir], 0.5] call pl_convert_to_heigth_ASL]}, "DESCEND"] call BIS_fnc_sortBy)#0;


            };
        };

        // select Best Mg Pos
        if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {

            _cover = false;
            _mgOffset = 2;
            private _maxLos = 0;
            _mgStartLine = _cords getPos [2, _watchDir];
            if !(_buildings isEqualTo []) then {
                if !(_covers isEqualTo []) then {
                    _mgStartLine = getPos (_covers#0);
                } else {
                    _mgStartLine = (getPos (_buildings#0)) getPos [5, _watchDir];
                };
            };
            for "_j" from 0 to 30 do {
                if (_j % 2 == 0) then {
                    _mgPos = (_mgStartLine getPos [2, _watchDir]) getPos [_mgOffset, _watchDir + 90];
                }
                else
                {
                    _mgPos = (_mgStartLine getPos [2, _watchDir]) getPos [_mgOffset, _watchDir - 90];
                };
                _mgOffset = _mgOffset + (_defenceAreaSize / 30);

                _mgPos = [_mgPos, 1] call pl_convert_to_heigth_ASL;

                if !([_mgPos] call pl_is_indoor) then {
                    private _losCount = 0;
                    for "_l" from 10 to 510 step 50 do {

                        _checkPos = _mgPos getPos [_l, _watchDir];
                        _checkPos = [_checkPos, 1] call pl_convert_to_heigth_ASL;
                        _vis = lineIntersectsSurfaces [_mgPos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];

                        if !(_vis isEqualTo []) exitWith {};

                        _losCount = _losCount + 1;
                    };
                    if (_losCount > _maxLos) then {
                        _maxLos = _losCount;
                        _pos = _mgPos
                    };
                };
            };
        };

        if (_unit == (leader _group) and !(_buildings isEqualTo []) and (_unit distance2D _cords) > 15) then {
            _pos = _cords findEmptyPosition [0, 25, typeOf _unit];
        };


        _pos = ATLToASL _pos;
        private _unitPos = "UP";
        _checkPos = [7*(sin _watchDir), 7*(cos _watchDir), 1] vectorAdd _pos;
        _crouchPos = [0, 0, 1] vectorAdd _pos;
        _vis = lineIntersectsSurfaces [_crouchPos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "MIDDLE";
            _watchPos = _checkPos;
        };
        _checkPos = [7*(sin _watchDir), 7*(cos _watchDir), 0.2] vectorAdd _pos;
        _vis = lineIntersectsSurfaces [_pos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "DOWN";
            _watchPos = _checkPos;
        };

        _pos = ASLToATL _pos;

        if !(_moveToStatic and !(_unit in (_isStatic#1))) then {
            [_unit, _pos, _watchPos, _unitWatchDir, _unitPos, _cover, _cords, _defenceAreaSize, _defenceWatchPos, _watchDir, _atEscord, _medic] spawn {
                params ["_unit", "_pos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_cords", "_defenceAreaSize", "_defenceWatchPos", "_defenceDir", "_atEscord", "_medic"];

                // _m = createMarker [str (random 1), _pos];
                // _m setMarkerType "mil_dot";
                // _m setMarkerSize [0.5, 0.5];


                _unit setVariable ["pl_def_pos", _pos, true];
                _unit disableAI "AUTOCOMBAT";
                _unit disableAI "AUTOTARGET";
                _unit disableAI "TARGET";
                _unit setUnitTrait ["camouflageCoef", 0.7, true];
                _unit setVariable ["pl_damage_reduction", true];
                // _unit disableAI "FSM";
                _unit doMove _pos;
                _unit setDestination [_pos, "FORMATION PLANNED", false];
                sleep 1;
                waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or [_unit, _pos] call pl_position_reached_check};
                // waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
                _unit enableAI "AUTOCOMBAT";
                _unit enableAI "AUTOTARGET";
                _unit enableAI "TARGET";
                // _unit enableAI "FSM";
                if !(_cover) then {
                    doStop _unit;
                    _unit doWatch _watchPos;
                    _unit setUnitPos _unitPos;
                }
                else
                {
                    if ([_pos] call pl_is_forest) then {
                        [_unit, _watchPos, _unitWatchDir, 5, false] spawn pl_find_cover;
                    } else {
                        [_unit, _watchPos, _unitWatchDir, 10, false] spawn pl_find_cover;
                    };
                };
                if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                    [_unit, group _unit, _cords, _defenceAreaSize, _defenceDir, _pos, _atEscord] spawn pl_at_defence;
                    sleep 0.1;
                    // _m setMarkerColor "colorOrange";
                };
                if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                    [_unit, _watchPos, _unitWatchDir, 0, false, false, "", true] spawn pl_find_cover;
                    // _m setMarkerColor "colorRed";
                };
                if (_unit == _medic) then {
                    [(group _unit), _unit, _pos] spawn pl_defence_ccp;
                    // _m setMarkerColor "colorGreen";
                };
            };
        };
    };

    // hint (str _allPos);

    waitUntil {sleep 0.5; !(_group getVariable ["onTask", true])};

    deleteMarker _markerAreaName;
    deleteMarker _markerDirName;

    if (_isStatic#0) then {
        _weapon = {
            if ((vehicle _x) != _x) exitWith {vehicle _x};
            objNull
        } forEach (units _group);
        if !(isNull _weapon) then {
            [_group, _weapon] call pl_reworked_bis_pack;
        };
        (leader _group) removeWeapon "Binocular";
    };

    {
        _group leaveVehicle _x;
    } forEach _weapons;

    {
        pl_draw_building_array = pl_draw_building_array - [[_group, _x]];
    } forEach _validBuildings;
};

pl_at_defence = {
    params ["_atSoldier", "_group", "_defencePos", "_defenceAreaSize", "_defenceDir", "_startPos", "_atEscord"];
    private ["_checkPosArray", "_watchPos", "_targets", "_debugMarkers"];

    _time = time + 20;
    waitUntil {sleep 0.5;  time >= time or !(_group getVariable ["onTask", true]) };
    if !(_group getVariable ["onTask", true]) exitWith {};

    _watchPos = (getPos _atSoldier) getPos [150, _defenceDir];

    while {alive _atSoldier and _group getVariable ["onTask", true]} do {

        if ((_atSoldier getVariable ["pl_wia", false]) or (((secondaryWeaponMagazine _atSoldier) isEqualTo []) and ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _atSoldier >> "magazines") apply {toUpper _x})} count magazines _atSoldier) <= 0)) then {
            _group setVariable ["pl_grp_active_at_soldier", nil];
            waitUntil {sleep 0.5; !(_atSoldier getVariable ["pl_wia", false]) and !((secondaryWeaponMagazine _atSoldier) isEqualTo [])};
        };

        if !((_group getVariable ["pl_grp_active_at_soldier", objNull]) == _atSoldier) then {
            waitUntil {sleep 0.5; !(_atSoldier getVariable ["pl_wia", false]) and !((secondaryWeaponMagazine _atSoldier) isEqualTo []) and (isNull (_group getVariable ["pl_grp_active_at_soldier", objNull]))};
        };

        // _vics = nearestObjects [_watchPos, ["Car", "Tank"], 300, true];
        _vics = _watchPos nearEntities [["Car", "Tank"], 300];

        _targets = [];
        {
            if (speed _x <= 3 and alive _x and (count (crew _x) > 0) and (_atSoldier knowsAbout _x) >= 0.5 or _x getVariable ["pl_at_enaged", false]) then {
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
                // _atSoldier disableAI "AIMINGERROR";

                _group setVariable ["pl_grp_active_at_soldier", _atSoldier];
                pl_at_attack_array pushBack [_atSoldier, _target, _atEscord];

                _movePos = ([_checkPosArray, [], {_atSoldier distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;
                _atSoldier doMove _movePos;
                _atSoldier setDestination [_movePos, "FORMATION PLANNED", false];
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
                        _unit setDestination [_movePos, "FORMATION PLANNED", false];

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
        _allTargets = _watchPos nearEntities [["Man", "Car"], 350];
        _enemyTargets = _allTargets select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and ((leader _group) knowsAbout _x) > 0};
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
                _vis = lineIntersectsSurfaces [eyePos _unit, _targetPos, _unit, vehicle _unit, true, 1]; 
                if !(_vis isEqualTo []) then {
                    _targetPos = (_vis select 0) select 0;
                };

                if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_targetPos] call pl_friendly_check) and !(_group getVariable ["pl_hold_fire", false])) then {
                     _unit doSuppressiveFire _targetPos;
                };
            } forEach _firers;

            sleep 10;
        };
        sleep 1;
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
                    _supplySoldier setDestination [_supplyPos, "LEADER PLANNED", true];

                    pl_supply_draw_array pushBack [_defencePos, _supplyPos, [0.9,0.7,0.1,0.8]];

                    sleep 1;

                    waitUntil {sleep 0.5; unitReady _supplySoldier or ((_supplySoldier distance2D _supplyPos) < 3) or (!alive _supplySoldier) or !((group _supplySoldier) getVariable ["onTask", true])};

                    doStop _supplySoldier;
                    sleep 2;
                    _supplySoldier doWatch _startPos;
                    _supplySoldier playActionNow "GestureFollow";
                    sleep 8;
                    _supplySoldier playActionNow "GestureGo";
                    sleep 2;

                    _supplySoldier doMove _startPos;
                    // _supplySoldier setDestination [_startPos, "LEADER PLANNED", true];

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
        _unit setDestination [_movePos, "FORMATION PLANNED", false];
        waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or [_unit, _movePos] call pl_position_reached_check};
        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        [_unit, (getPos _unit) getPos [100, getDir _unit], getDir _unit, 0, false] spawn pl_find_cover;
    } else {
        _unit doFollow (leader (group _unit));
    };
};
