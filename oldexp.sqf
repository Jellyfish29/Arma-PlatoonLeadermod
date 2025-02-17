pl_defend_position_vehicle = {
    params ["_group", "_watchPos", "_cords", "_markerName", "_watchDir"];

    private _vic = vehicle (leader _group);

    if (_group getVariable ["pl_has_cargo", false] or _group getVariable ["pl_vic_attached", false])

    private _markerChangeName = format ["defenceChangePos%1", _group];
    private _vicHealthState = getDammage _vic;
    private _changePosition = [];

    _vic doMove _cords;
    _vic setDestination [_cords,"VEHICLE PLANNED" , true];

    waitUntil {sleep 0.5; unitReady _vic or _vic distance2d _cords < 15 or !(_group getVariable ["onTask", false]) or !alive _vic};

    if (!(_group getVariable ["onTask", true]) or !alive _vic) exitWith {deleteMarker _markerName};
    _pos = [_vic, _watchDir] call pl_get_turn_vehicle;
    _vic doMove _pos;

    waitUntil {sleep 0.5; unitReady _vic or !(_group getVariable ["onTask", false]) or !alive _vic};

    if (!(_group getVariable ["onTask", true]) or !alive _vic) exitWith {deleteMarker _markerName};

    sleep 1;

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

    if (_group getVariable ["pl_is_dismounted", false]) then {

    };

    private _posChangeTimer = 0;
    private _allowPosChange = true;

    // while {_group getVariable ["onTask", false] and alive _vic} do {
    //     waitUntil {sleep 0.5; !(_group getVariable ["pl_hold_fire", false]) or !(_group getVariable ["onTask", false]) or !alive _vic};
    //     // _allTargets = nearestObjects [_watchPos, ["Man", "Car"], 350, true];
    //     private _enemyMen = (_watchPos nearEntities [["Man"], 700]) select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and ((leader _group) knowsAbout _x) > 0};
    //     private _enemyVics = (_watchPos nearEntities [["Car", "Tank"], 700]) select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and ((leader _group) knowsAbout _x) > 0};

        // if (time == _posChangeTimer) then {
        //     _posChangeTimer = 0;
        //     _vic doMove _cords;

        //     waitUntil {sleep 0.5; unitReady _vic or !(_group getVariable ["onTask", false]) or !alive _vic};

        //     _pos = [_vic, _watchDir] call pl_get_turn_vehicle;
        //     _vic doMove _pos;

        //     waitUntil {sleep 0.5; unitReady _vic or !(_group getVariable ["onTask", false]) or !alive _vic};

        //     _markerName setMarkerPos (getPos _vic);
        // };

        // if ((getDammage _vic) > _vicHealthState  and _allowPosChange and canMove _vic) then {//(_vic getDammage < _vicHealthState / 2 and _allowPosChange)
        //     [_vic, "SmokeLauncher"] call BIS_fnc_fire;
        //     _searchPos = (getPos _vic) getPos [[80, 120] call BIS_fnc_randomInt, _watchDir - 180];
        //     _changePosition = _searchPos findEmptyPosition [0, 40, typeOf _vic];
        //     if (!([_changePosition] call pl_is_forest) and !([_changePosition] call pl_is_city)) then {
        //         doStop _vic;
        //         _allowPosChange = false;

        //         sleep 0.5;

        //         {_x enableAI "PATH";} forEach (units _group);
        //         _vic engineOn true;

        //         pl_draw_delay_array pushback [_cords, _changePosition];
        //         createMarker [_markerChangeName, _changePosition];
        //         _markerChangeName setMarkerPos _changePosition;
        //         _markerChangeName setMarkerType "marker_position_eny";
        //         _markerChangeName setMarkerColor pl_side_color;
        //         _markerChangeName setMarkerDir _watchDir;


        //         _vic doMove _changePosition;

        //         waitUntil {sleep 0.5; unitReady _vic or !(_group getVariable ["onTask", false]) or !alive _vic};

        //         _pos = [_vic, _watchDir] call pl_get_turn_vehicle;
        //         _vic doMove _pos;

        //         sleep 0.5;

        //         waitUntil {sleep 0.5; unitReady _vic or !(_group getVariable ["onTask", false]) or !alive _vic};

        //         if (!(_group getVariable ["onTask", true]) or !alive _vic) exitWith {deleteMarker _markerName; deleteMarker _markerChangeName; pl_draw_delay_array = pl_draw_delay_array - [[_cords, _changePosition]];};

        //         _markerName setMarkerPos (getPos _vic);
        //         pl_draw_delay_array = pl_draw_delay_array - [[_cords, _changePosition]];
        //         deleteMarker _markerChangeName;

        //         {_x disableAI "PATH";} forEach (units _group);

        //         _posChangeTimer = time + 30;

        //         waitUntil {time >= _posChangeTimer or !(_group getVariable ["onTask", false]) or !alive _vic};

        //         {_x enableAI "PATH";} forEach (units _group);
        //         _vic doMove _cords;

        //         waitUntil {sleep 0.5; unitReady _vic or _vic distance2d _cords < 15 or !(_group getVariable ["onTask", false]) or !alive _vic};

        //         if (!(_group getVariable ["onTask", true]) or !alive _vic) exitWith {deleteMarker _markerName; deleteMarker _markerChangeName;};
        //         _pos = [_vic, _watchDir] call pl_get_turn_vehicle;
        //         _vic doMove _pos;

        //         waitUntil {sleep 0.5; unitReady _vic or !(_group getVariable ["onTask", false]) or !alive _vic};

        //         if (!(_group getVariable ["onTask", true]) or !alive _vic) exitWith {deleteMarker _markerName; deleteMarker _markerChangeName;};


        //         _markerName setMarkerPos (getPos _vic);
        //         _vicHealthState = getDammage _vic;
        //         _allowPosChange = true;
        //         {_x disableAI "PATH";} forEach (units _group);
        //     };
        // };

    //     if !(_enemyVics isEqualTo [] and !(_enemyMen isEqualTo [])) then {

    //         if (_vic isKindOf "Tank") then {
    //             [_vic] call pl_load_he;
    //         };
    //             {
    //                 _unit = _x;
    //                 _target = selectRandom _enemyMen;
    //                 _targetPos = getPosASL _target;
    //                 if ([_unit, _targetPos] call pl_friendly_check) then {sleep 1; continue};
    //                 _vis = lineIntersectsSurfaces [eyePos _unit, _targetPos, _unit, vehicle _unit, true, 1]; 
    //                 if !(_vis isEqualTo []) then {
    //                     _targetPos = (_vis select 0) select 0;
    //                 };

    //                 if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_unit, _targetPos] call pl_friendly_check) and !(_group getVariable ["pl_hold_fire", false])) then {
    //                      _unit doSuppressiveFire _targetPos;
    //                 };
    //             } forEach (units _group);

    //         _time = time + 15;
    //         waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true]) or !alive _vic or (getDammage _vic) > _vicHealthState};
    //         [_vic] call pl_load_ap;
    //     };
    //     sleep 1;
    // };

    waitUntil {!(_group getVariable ["onTask", false]) or !alive _vic};

    deleteMarker _markerName;
    deleteMarker _markerChangeName;
    {
        _x setVariable ["pl_damage_reduction", false];
        _x setUnitTrait ["camouflageCoef", 1, true];
    } forEach _crew;
};

// pl_take_position = {
//     params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
//     private ["_markerName", "_markerAreaName", "_isStatic", "_staticMarkerName", "_cords", "_watchDir", "_watchPos", "_offSet", "_moveDir", "_medic", "_medicPos", "_icon"];
//     // _group = hcSelected player select 0;

//     if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};
//     if (visibleMap) then {
//         hintSilent "";

//         _message = "Select DEFENCE position on MAP <br /><br />
//         <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />";
//         hint parseText _message;

//         _markerName = format ["defence%1%2", _group, random 1];
//         createMarker [_markerName, [0,0,0]];
//         _markerName setMarkerType "marker_sfp";
//         _markerName setMarkerColor pl_side_color;
//         // _markerName setMarkerShadow false;

//         pl_take_position_size = 30;
//         _markerAreaName = format ["%1defArea%2", _group, random 2];
//         createMarker [_markerAreaName, [0,0,0]];
//         _markerAreaName setMarkerShape "RECTANGLE";
//         _markerAreaName setMarkerBrush "SolidBorder";
//         _markerAreaName setMarkerColor pl_side_color;
//         _markerAreaName setMarkerAlpha 0.25;
//         _markerAreaName setMarkerSize [pl_take_position_size, 2];

//         private _rangelimiterCenter = getPos (leader _group);
//         if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};
//         private _rangelimiter = 200;
//         _markerBorderName = str (random 2);
//         createMarker [_markerBorderName, _rangelimiterCenter];
//         _markerBorderName setMarkerShape "ELLIPSE";
//         _markerBorderName setMarkerBrush "Border";
//         _markerBorderName setMarkerColor "colorOrange";
//         _markerBorderName setMarkerAlpha 0.8;
//         _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

//         onMapSingleClick {
//             pl_defence_cords = _pos;
//             pl_mapClicked = true;
//             if (_shift) then {pl_cancel_strike = true};
//             if (_alt) then {pl_deploy_static = true};
//             hintSilent "";
//             onMapSingleClick "";
//         };

//         // while {!pl_mapClicked} do {
//         //     _watchDir = getPos (leader _group) getDir ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
//         //     _markerAreaName setMarkerPos ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
//         //     _markerAreaName setMarkerDir _watchDir;
//         //     _markerName setMarkerPos ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition);
//         //     _markerName setMarkerDir _watchDir;
//         //     sleep 0.01;
//         // };


//         _maxLine_size = 100;
//         _minLine_size = 10;
        

//         player enableSimulation false;

//         while {!pl_mapClicked} do {
//             _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//             if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
//                 _watchDir = _rangelimiterCenter getDir _mPos;
//                 _markerAreaName setMarkerPos _mPos;
//                 _markerAreaName setMarkerDir _watchDir;
//                 _markerName setMarkerPos _mPos;
//                 _markerName setMarkerDir _watchDir;
//             };
//             if (inputAction "MoveForward" > 0) then {pl_take_position_size = pl_take_position_size + 5; sleep 0.05};
//             if (inputAction "MoveBack" > 0) then {pl_take_position_size = pl_take_position_size - 5; sleep 0.05};
//             _markerAreaName setMarkerSize [pl_take_position_size, 2];
//             if (pl_take_position_size >= _maxLine_size) then {pl_take_position_size = _maxLine_size};
//             if (pl_take_position_size <= _minLine_size) then {pl_take_position_size = _minLine_size};
//         };
//         sleep 0.01;

//         player enableSimulation true;


//         pl_mapClicked = false;
//         deleteMarker _markerBorderName;
//         if (pl_cancel_strike) exitWith { 
//             deleteMarker _markerName; 
//             deleteMarker _markerAreaName;
//             pl_cancel_strike = false;
//         };
//         _message = "Select Position FACING <br /><br />
//         <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
//         <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>DEPLOY static weapon</t> <br />";
//         hint parseText _message;

//         _cords = getMarkerPos _markerName;

//         _markerAreaName setMarkerPos _cords;
//         _markerName setMarkerPos _cords;

//         sleep 0.1;
//         // _cords = pl_defence_cords;


//         onMapSingleClick {
//             pl_mortar_cords = _pos;
//             pl_mapClicked = true;
//             if (_shift) then {pl_cancel_strike = true};
//             if (_alt) then {pl_deploy_static = true};
//             hintSilent "";
//             onMapSingleClick "";
//         };

//         while {!pl_mapClicked} do {
//             _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
//             _markerName setMarkerDir _watchDir;
//             _markerAreaName setMarkerDir _watchDir;
//             sleep 0.01;
//         };
//         pl_mapClicked = false;

//         deleteMarker _markerAreaName;

//         _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";

//         // Wait until planed Task Wp Reached then continue Code if pl_reset called cancel execution
//         if (count _taskPlanWp != 0) then {

//             // add Arrow indicator
//             pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

//             waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false]) or (_group getVariable ["pl_disembark_finished", false])};
//             _group setVariable ["pl_disembark_finished", nil];

//             // remove Arrow indicator
//             pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

//             if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
//             _group setVariable ["pl_task_planed", false];
//         };

//         if (pl_cancel_strike) exitWith {
//             pl_cancel_strike = false;
//             deleteMarker _markerName;
//             deleteMarker _markerAreaName;
//           };

//         // Whyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy?????????????????
//         // if (pl_enable_beep_sound) then {playSound "beep"};
//         [_group, "confirm", 1] call pl_voice_radio_answer;
//         [_group] call pl_reset;

//         sleep 0.5;

//         [_group] call pl_reset;

//         sleep 0.5;

//         _group setVariable ["onTask", true];
//         _group setVariable ["setSpecial", true];
//         _group setVariable ["specialIcon", _icon];
//         _group setVariable ["pl_in_position", true];

//         _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _cords;
//         _leaderDir = _watchDir - 90;
//         _leaderPos = [6*(sin _leaderDir), 6*(cos _leaderDir), 0] vectorAdd _cords;
//         _medicDir = _watchDir - 180;
//         _medicPos = [15*(sin _medicDir), 15*(cos _medicDir), 0] vectorAdd _cords;
//         if (pl_deploy_static) then {
//             _isStatic = [_group, _markerName, _watchPos, _leaderPos] call pl_reworked_bis_unpack;
//             pl_deploy_static = false;
//             if !(_isStatic#0) then {
//                 hint "No Static Weapon!";
//             };
//         }
//         else
//         {
//             _isStatic = [false, []];
//             pl_denfence_draw_array pushBack [_markerName, (leader _group)];
//         };
//         sleep 0.1;

//         _medic = {
//             if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) exitWith {_x};
//         } forEach (units _group);


//         leader _group groupRadio "SentCmdHide";
//         leader _group playActionNow "GestureCover"; 

//         if (_isStatic#0) then {
//             _staticMarkerName = format ["static%1", _group];
//             createMarker [_staticMarkerName, _cords];
//             _staticMarkerName setMarkerType "marker_afp";
//             _staticMarkerName setMarkerColor pl_side_color;
//             _staticMarkerName setMarkerDir _watchDir;
//             (leader _group) addWeapon "Binocular";
//             if (pl_enable_beep_sound) then {playSound "beep"};
//             // leader _group sideChat format ["Roger, %1 will deploy static Weapon at designated coordinates, over",(groupId _group)];
//             _offSet = 9;
//         }
//         else
//         {
//             if (pl_enable_beep_sound) then {playSound "beep"};
//             // leader _group sideChat format ["Roger, %1 will defend the Position, over",(groupId _group)];
//             _offSet = 0;
//         };

//         private _units = [];
//         private _mgGunners = [];
//         private _atSoldiers = [];
//         private _atEscord = objNull;
//         private _medic = objNull;


//         // classify units
//         {
//             if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
//             if ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun" and secondaryWeapon _x == "") then {
//                 _units pushBackUnique _x;
//             };
//             if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
//                 _mgGunners pushBackUnique _x;
//             };
//             if (secondaryWeapon _x != "") then {
//                 _atSoldiers pushBackUnique _x;
//             };
//         } forEach (units _group);

//         {_units pushBack _x} forEach _atSoldiers;
//         {_units pushBack _x} forEach _mgGunners;

//         reverse _units;

//         _lineSpacing = (pl_take_position_size / (count (units _group))) * 2;
//         _startPos = [(_lineSpacing / 2) *(sin (_watchDir + 90)), (_lineSpacing / 2) *(cos (_watchDir + 90)), 0] vectorAdd _cords;
//         private _posArray = [];
//         for "_i" from 0 to ((count (units _group))- 1) do {
//             if ((_i % 2) != 0) then {
//                 _offSet = _offSet + _lineSpacing;
//                 _moveDir = _watchDir - 90;
//             }
//             else
//             {
//                 _moveDir = _watchDir + 90;
//             };
//             _movePos = _startPos getPos [_offSet, _moveDir];
//             _posArray pushBack _movePos;
//         };
//         _posArray = [_posArray, [], {[_x, _watchDir, 1] call pl_fof_check}, "DESCEND"] call BIS_fnc_sortBy;
//         for "_j" from 0 to (count _units) - 1 do {
//             _unit = _units select _j;
//             _movePos = _posArray select _j;

//             if !(_unit in (_isStatic#1)) then {
//                 private _isLeader = false;
//                 if (_unit == (leader _group)) then {
//                     _movePos = _cords;
//                     _isLeader = true;
//                 };
//                 if (!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) then {
//                     if (_unit == _medic) then {
//                         _movePos = _medicPos;
//                     };
//                 };

//                 [_unit, _movePos, _watchDir, _isLeader, _markerName, _group] spawn {
//                     params ["_unit", "_pos", "_watchDir", "_isLeader", "_markerName", "_group"];
//                     _unit disableAI "AUTOCOMBAT";
//                     _unit disableAI "AUTOTARGET";
//                     _unit disableAI "TARGET";
//                     // _unit disableAI "FSM";
//                     _unit doMove _pos;
//                     _unit setDestination [_pos, "FORMATION PLANNED", false];
//                     sleep 1;
//                     waitUntil {sleep 0.5; (!alive _unit) or !(_group getVariable ["onTask", true]) or [_unit, _pos] call pl_position_reached_check};
//                     _unit enableAI "AUTOCOMBAT";
//                     _unit enableAI "AUTOTARGET";
//                     _unit enableAI "TARGET";
//                     // _unit enableAI "FSM";
//                     if (_group getVariable ["onTask", true]) then {
//                         if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun" or secondaryWeapon _unit != "") then {
//                             [_unit, _pos, _watchDir, 0, false] spawn pl_find_cover;
//                         } else {
//                             [_unit, _pos, _watchDir, 7, true] spawn pl_find_cover;
//                         };
//                     };
//                     if (_isLeader) then {
//                         pl_denfence_draw_array = pl_denfence_draw_array - [[_markerName, _unit]];
//                     };
//                 };
//             };
//         };
//         // Cancel Task
        
//         if (!(isNil "_medic") and pl_enabled_medical) then {

//             waitUntil {sleep 0.5; _group getVariable ["pl_healing_active", false] or !(_group getVariable ["onTask", true])};

//             _medic setVariable ["pl_is_ccp_medic", true];
//             while {(_group getVariable ["onTask", true])} do {
//                 _time = time + 10;
//                 waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", true])};
//                 {
//                     if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
//                         _medic setUnitPos "MIDDLE";
//                         _medic enableAI "PATH";
//                         _h1 = [_group, _medic, objNull, _x, _medicPos, 40, "onTask"] spawn pl_ccp_revive_action;
//                         waitUntil {sleep 0.5; scriptDone _h1 or !(_group getVariable ["onTask", true])};
//                         [_x, getPos _x, getDir _x, 7, false] spawn pl_find_cover;
//                         sleep 1;
//                         waitUntil {sleep 0.5; unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
//                         [_medic, _medicPos, getDir _medic, 10, false] spawn pl_find_cover;
//                     };
//                     // if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and !(lifeState _x isEqualTo "INCAPACITATED")) then {
//                     //     _medic setUnitPos "MIDDLE";
//                     //     _medic enableAI "PATH";
//                     //     _h1 = [_medic, _x, _medicPos, "onTask"] spawn pl_medic_heal;
//                     //     waitUntil {sleep 0.5; scriptDone _h1 or !(_group getVariable ["onTask", true])};
//                     //     sleep 1;
//                     //     waitUntil {sleep 0.5; unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
//                     //     [_medic, _medicPos, getDir _medic, 10, false] spawn pl_find_cover;
//                     // };
//                 } forEach (units _group);
//             };
//             _medic setVariable ["pl_is_ccp_medic", false];
//         }
//         else
//         {
//             waitUntil {sleep 0.5; !(_group getVariable ["onTask", true])};
//         };
//         if (_isStatic#0) then {
//             _weapon = {
//                 if ((vehicle _x) != _x) exitWith {vehicle _x};
//                 objNull
//             } forEach (units _group);
//             if !(isNull _weapon) then {
//                 [_group, _weapon] call pl_reworked_bis_pack;
//             };
//             deleteMarker _staticMarkerName;
//             (leader _group) removeWeapon "Binocular";
//         };
//         deleteMarker _markerName;
//         deleteMarker _markerAreaName;
//     };
// };

pl_full_cover = {
    params ["_group"];
    private ["_crew", "_isTransport"];

    // Whyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy?????????????????
    // if (pl_enable_beep_sound) then {playSound "beep"};
    if (vehicle (leader _group) != leader _group) exitWith {Hint "Infantry ONLY Task"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", '\A3\3den\data\Attributes\Stance\down_ca.paa'];
    


    _crew = [];
    _isTransport = false;
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry only Task"};

    _enemyTargets = ((getPos (leader _group)) nearEntities [["Man", "Car", "Tank"], 300]) select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and ((leader _group) knowsAbout _x) > 0};

    if !(_enemyTargets isEqualTo []) then {
        {
            [_x, getPos _x, getDir _x, 7, false, false] spawn pl_find_cover;
            _x setVariable ["pl_damage_reduction", true];
            _x setUnitTrait ["camouflageCoef", 0.5, true];
        } forEach (units _group);
    } else {
        _center = getPos (leader _group); 
        _units = (units _group) - [leader _group];
        private _posArray = [];
        for "_di" from 0 to 360 step (360 / (count (units _group))) do {
            _movePos = _center getPos [8, _di];
            _posArray pushBack _movePos;
        };

        private _i = 0;
        {
            [_x, _posArray#_i] spawn {
                params ["_unit", "_movePos"];

                _unit doMove _movePos;

                sleep 0.5;

                waitUntil {sleep 0.5; unitReady _unit or !alive _unit or !((group _unit) getVariable ["onTask", true])};

                [_unit, getPos _unit, (getPos (leader (group _unit))) getDir _movePos, 2, false, false] spawn pl_find_cover;
            };
            _i = _i + 1;
        } forEach _units;

        (leader _group) playActionNow "gestureFreeze";
        leader _group groupRadio "SentCmdHide";

        sleep 1;

        [(leader _group), getPos (leader _group), getDir (leader _group), 2, false, false] spawn pl_find_cover;
    };

    waitUntil {sleep 0.5; !(_group getVariable ["onTask", true])};

    {
        _x setVariable ["pl_damage_reduction", false];
        _x setUnitTrait ["camouflageCoef", 1, true];
        _x enableAI "PATH";
    } forEach (units _group);

};

// pl_getOut_vehicle = {
//     params ["_group", "_convoyId", "_moveInConvoy", ["_atPosition", false]];
//     private ["_vic", "_commander", "_markerName", "_cargo", "_cargoGroups", "_vicTransport", "_transportedVic", "_inLandConvoy", "_convoyLeader", "_convoyArray", "_convoyPosition", "_watchPos", "_landigPad", "_distanceBack", "_landCords"];

//     _leader = leader _group;

//     if (vehicle _leader != _leader) then {
//         _vic = vehicle _leader;
//         _vicTransport = false;
//         if !(isNull (isVehicleCargo _vic)) then {
//             _transportedVic = _vic;
//             _vic = isVehicleCargo _vic;
//             _vicTransport = true;
//         };

//         if !(isNil {_vic getVariable "pl_on_transport"}) exitWith {
//             if ((count (missionNamespace getVariable _convoyId)) > 1) then {
//                 player hcRemoveGroup _group;
//             };
//             if ((missionNamespace getVariable (_convoyId + "time")) > time) then {
//                 if (pl_enable_beep_sound) then {playSound "beep"};
//                 hint format ["%1 is already on a mission!", groupId (group (driver _vic))];
//             };
//         };

//         _vic setVariable ["pl_on_transport", true];
//         _cargo = fullCrew _vic;
//         _commander = driver _vic;
//         {
//             if (_x select 1 isEqualTo "commander") then {
//                 _commander = (_x select 0);
//             };
//         } forEach _cargo;

//         for "_i" from count waypoints (group _commander) - 1 to 0 step -1 do{
//             deleteWaypoint [(group _commander), _i];
//         };
//         _cargo = fullCrew [_vic, "cargo", false];

//         if (visibleMap and !_atPosition) then {
//             // Unload at selected Map Position
//             // For Land Vehicles and Air Transport

//             ///// Transport Set up /////

//             hintSilent "Select DESTINATION on MAP";
//             onMapSingleClick {
//                 pl_mapClicked = true;
//                 pl_lz_cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//                 pl_lz_marker_cords = pl_lz_cords;
//                 // if (_shift) then {pl_cancel_strike = true};
//                 hintSilent "";
//                 onMapSingleClick "";
//             };
//             waitUntil {pl_mapClicked};


//             sleep 0.1;
//             pl_mapClicked = false;
//             _cords = pl_lz_cords;

//             // (group (driver _vic)) setVariable ["onTask", true];
//             if (!(_moveInConvoy) and (count _cargo) > 0) then {
//                 (group (driver _vic)) setVariable ["setSpecial", true];
//                 (group (driver _vic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
//             };

//             if ((_cords distance2D (_vic getVariable "pl_rtb_pos")) > 200) then {
//                 // if (pl_enable_beep_sound) then {playSound "beep"};
//                 // _commander sideChat "Roger, Moving to Insertion Point, over";
//             }
//             else
//             {
//                 _commander sideChat format ["%1: RTB", groupId (group _commander)];
//                 if (pl_enable_map_radio) then {[group _commander, "...RTB", 25] call pl_map_radio_callout};
//             };

//             _convoyArray = [];
//             _inLandConvoy = false;

//             _wp = (group _commander) addWaypoint [_cords, 0];
//             _wp setWaypointType "TR UNLOAD";
//             {_x disableAI "PATH"} forEach (units _group);
//             // More then One Tranport == Convoy
//             if ((count (missionNamespace getVariable _convoyId)) > 1) then {
//                 if (_group isEqualTo ((missionNamespace getVariable _convoyId) select 0)) then {
//                     _c = [(missionNamespace getVariable _convoyId), [], {(leader _x) distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy;
//                     missionNamespace setVariable [_convoyId, _c];

//                     if !(_vic isKindOf "Air") then {
//                         private _blacklistr1 = [];
//                         private _r2 = [_cords, 100,[]] call BIS_fnc_nearestRoad;
//                         {
//                             private _r1 = [(getPos (leader _x)), 100] call BIS_fnc_nearestRoad;
//                             if (_r1 in _blacklistr1) then {
//                                 private _roads = getPos (leader _x) nearRoads 100;
//                                 _roads = [_roads, [], {(getPos _x) distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy;  
//                                 _r1 = {
//                                     if !(_x in _blacklistr1) exitWith {_x};
//                                 } forEach _roads;
//                             };
//                             _blacklistr1 pushback _r1;
//                             // player sideChat (str _r1);
//                             _pathCost = [_r1, _r2] call pl_convoy_parth_find;
//                             _x setVariable ["pl_path_cost", _pathCost];
//                             _x setVariable ["r1", _r1];
//                         } forEach (missionNamespace getVariable _convoyId);
//                         hint "Setting up Convoy...";
//                         if (pl_enable_beep_sound) then {playSound "beep"};
//                     }
//                     else
//                     {
//                         hint "Setting up Flight...";
//                         if (pl_enable_beep_sound) then {playSound "beep"};
//                     };
//                 };
//                 sleep 5;
//                 hintSilent "";
//                 pl_set_up_convoy = true;

//                 _c = [(missionNamespace getVariable _convoyId), [], {_x getVariable ["pl_path_cost", 2000]}, "ASCEND"] call BIS_fnc_sortBy;  
//                  missionNamespace setVariable [_convoyId, _c];
//                 pl_draw_convoy_array pushBack (missionNamespace getVariable _convoyId);
//                 pl_draw_convoy_array = pl_draw_convoy_array arrayIntersect pl_draw_convoy_array;
//                 _convoyLeader = (missionNamespace getVariable _convoyId) select 0;
//                 _convoyArray = (missionNamespace getVariable _convoyId);
//                 if (_group == _convoyLeader) then {
//                     // private _convoyLeaderGroupId = groupId _convoyLeader;
//                     // _convoyLeader setGroupId [format ["%1 (Convoy Leader)", _convoyLeaderGroupId]];
//                     _leaderIsTransport = false;
//                     if (_convoyLeader getVariable ["setSpecial", false]) then {
//                         _leaderIsTransport = true;
//                     };
//                 };
//                 _convoyLeader setVariable ["onTask", true];
//                 _convoyLeader setVariable ["setSpecial", true];
//                 _convoyLeader setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa"];
//                 group (_commander) setVariable ["pl_draw_convoy", true];

//                 if (_group != _convoyLeader and _group != (group player)) then {
//                     player hcRemoveGroup _group;
//                 };

//                 // Air Convoy
//                 if (_vic isKindOf "Air") then {
//                     waitUntil {time >= (missionNamespace getVariable (_convoyId + "time")) and (group _commander) == ((missionNamespace getVariable _convoyId) select (missionNamespace getVariable (_convoyId + "pos")))};
//                     if ((group _commander) != _convoyLeader) then {
//                         _dir = [_cords, _vic getVariable "pl_rtb_pos"] call BIS_fnc_dirTo;
//                         _moveDir = [(_dir - 90)] call pl_angle_switcher;
//                         _cords =  [25*(sin _moveDir),25*(cos _moveDir), 0] vectorAdd [pl_lz_cords select 0, pl_lz_cords select 1, 0];

//                         pl_lz_cords = _cords;
//                     };
//                     _t = time + 10;
//                     missionNamespace setVariable [_convoyId + "time", _t];
//                     _p  = (missionNamespace getVariable (_convoyId + "pos"));
//                     _p = _p + 1;
//                     missionNamespace setVariable [_convoyId + "pos", _p];
//                 }
//                 else
//                 // Land Convoy
//                 {
//                     player hcSetGroup [_convoyLeader];
//                     {
//                         _x disableAI "AUTOCOMBAT";
//                     } forEach units (group _commander);
//                     _vic limitSpeed 51;
//                     // _vic forceFollowRoad true;
//                     // _vic setConvoySeparation 20;
//                     group _commander setBehaviour "SAFE"; // SAFE
//                     _inLandConvoy = true;
//                     waitUntil {(time >= (missionNamespace getVariable (_convoyId + "time")) and (group _commander) == ((missionNamespace getVariable _convoyId) select (missionNamespace getVariable (_convoyId + "pos")))) or !(_convoyLeader getVariable ["onTask", true])};

//                     // private _points = pl_convoy_path_marker apply {getMarkerPos _x};
//                     // _vic setDriveOnPath _points;

//                     _convoyPosition = (missionNamespace getVariable (_convoyId + "pos"));
//                     _t = time + 2;
//                     missionNamespace setVariable [_convoyId + "time", _t];
//                     _p  = (missionNamespace getVariable (_convoyId + "pos"));
//                     _p = _p + 1;
//                     missionNamespace setVariable [_convoyId + "pos", _p];
//                 };
//             }
//             else
//             {
//                 _inLandConvoy = false;
//             };

//             {_x enableAI "PATH"} forEach (units _group);
//             if (_vic isKindOf "Air") then {
//                 _vic flyInHeight 60;
//                 _landCords = _cords findEmptyPosition [0, 100, "Land_HelipadEmpty_F"];
//                 if (_landCords isEqualTo []) then {_landCords = _cords};
//                 _landigPad = "Land_HelipadEmpty_F" createVehicle _landCords;
//                 _landigPad setDir (_vic getDir _landCords);

//                 // _m = createMarker [str (random 2), _landCords];
//                 // _m setMarkerType "mil_dot";
//             };

//             // Create Destination Marker
//             private _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa";
//             if (_moveInConvoy) then {_icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa"};
//             // pl_draw_planed_task_array pushBack [_wp, _icon];

//             if ((group driver (_vic)) == (group player)) then {
//                 (driver _vic) commandMove _cords;
//             };
//             // Setup the cargo of Transport Vehicle
//             _cargo = fullCrew [_vic, "cargo", false];
//             _cargoGroups = [];
//             {
//                 _cargoGroups pushBack (group (_x select 0));
//             } forEach _cargo;
//             _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

//             /// Transport Execution ///

//             // If Infantry is Transported
//             if !(_vicTransport) then {
//                 if (_vic isKindOf "Air") then {
//                     {
//                         _x disableAI "AUTOCOMBAT";
//                         _x disableAI "TARGET";
//                         _x disableAI "AUTOTARGET";
//                     } forEach (units (group _commander));
//                     (group _commander) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
//                     [_vic, 0] call pl_door_animation;
//                     sleep 40;
//                     // waitUntil {!alive _vic or (unitReady _vic)};
//                     waitUntil {sleep 0.1; (isTouchingGround _vic) or !alive _vic};
//                     // for "_i" from count waypoints _group - 1 to 0 step -1 do {
//                     //     deleteWaypoint [_group, _i];
//                     // };
//                     [_vic, 1] call pl_door_animation;
//                     {
//                         // {
//                         //     _unit = _x;
//                         //     [_unit] orderGetIn false;
//                         //     [_unit] allowGetIn false;
//                         //     unassignVehicle _unit;
//                         // } forEach (units _x);
//                         _x leaveVehicle _vic;
//                         // player hcSetGroup [_x];
//                         // _x setVariable ["pl_show_info", true];
//                         if !(_x getVariable ["pl_show_info", false]) then {
//                             [_x] call pl_show_group_icon;
//                         };
//                         if (_x != (group player)) then {
//                             if ((_vic distance2D (_vic getVariable "pl_rtb_pos")) > 300) then {
//                                 // [_x, _vic] spawn pl_airassualt_security;
//                             }
//                             else
//                             {
//                                 _x addWaypoint [getPos _vic, 10];
//                             };
//                         };

//                     } forEach _cargoGroups;
// //                 }
// //                 else
//                 {
                    // sleep 0.2;
                    // // Land Convoy Loop
                    // if (_inLandConvoy) then {
                    //     if (_moveInConvoy) then {
                    //         _wp setWaypointType "MOVE";
                    //     };

                    //     _vic setVariable ["pl_speed_limit", "CON"];
                    //     // _vic forceFollowRoad true;
                    //     _vic setConvoySeparation 1;

                    //     while {
                    //     (alive (vehicle (leader _convoyLeader))) and
                    //     // !(unitReady (driver (vehicle (leader _convoyLeader)))) and
                    //     ((leader _convoyLeader) distance2D waypointPosition[_convoyLeader, currentWaypoint _convoyLeader] > 60) and
                    //     (_convoyLeader getVariable ["onTask", true])
                    //     } do {
                    //         private _convoyLeaderSpeed = (vehicle (leader _convoyLeader)) getVariable "pl_speed_limit";
                    //         switch (_convoyLeaderSpeed) do { 
                    //             case "CON" : {_convoyLeaderSpeed = 35}; 
                    //             case "MAX" : {_convoyLeaderSpeed = 60}; 
                    //             default {_convoyLeaderSpeed = parseNumber _convoyLeaderSpeed}; 
                    //         };
                    //         private _convoyLeaderVic = vehicle (leader _convoyLeader);
                    //         if ((group _commander) == _convoyLeader) then {
                    //             _distance = _vic distance2d vehicle (leader (_convoyArray select 1));
                    //             _vic forceSpeed -1;
                    //             _vic limitSpeed _convoyLeaderSpeed;
                    //             if (_distance < 60) then {
                    //                 _vic limitSpeed _convoyLeaderSpeed;
                    //             };
                    //             if (_distance > 70) then {
                    //                 _vic limitSpeed (_convoyLeaderSpeed - (_convoyLeaderSpeed / 2));
                    //             };
                    //             if (_distance > 90) then {
                    //                 _vic forceSpeed 0;
                    //             };
                    //             if ((speed _vic) == 0) then {
                    //                 _timeout = time + 7;
                    //                 waitUntil {(speed _vic) > 0 or time >= _timeout};
                    //                 if ((speed _vic) == 0) then {
                    //                     [_vic, _group, _cords] call pl_vehicle_convoy_unstuck;
                    //                 };
                    //             };
//                             }
//                             else
//                             {
//                                 _leaderBehavior = behaviour (leader _convoyLeader);
//                                 _group setBehaviour _leaderBehavior;
//                                 _distance = _vic distance2d vehicle (leader (_convoyArray select _convoyPosition - 1));
//                                 _vic forceSpeed -1;
//                                 _vic limitSpeed _convoyLeaderSpeed;
//                                 if (_distance > 60) then {
//                                     _vic limitSpeed (_convoyLeaderSpeed + 8);
//                                 };
//                                 if (_distance < 60) then {
//                                     _vic limitSpeed _convoyLeaderSpeed;
//                                 };
//                                 if (_distance < 40) then {
//                                     _vic limitSpeed (_convoyLeaderSpeed - (_convoyLeaderSpeed / 2));
//                                 };
//                                 if (_distance < 25) then {
//                                     _vic forceSpeed 0;
//                                     _vic limitSpeed 0;
//                                 };
//                                 if ((speed (vehicle (leader (_convoyArray select (_convoyPosition - 1))))) < 2) then {
//                                     _vic forceSpeed 0;
//                                     _vic limitSpeed 0;
//                                 };
//                                 _distanceBack = 0;
//                                 if (_convoyPosition < ((count (_convoyArray)) - 1)) then {
//                                     _distanceBack = _vic distance2d vehicle (leader (_convoyArray select _convoyPosition + 1));
//                                     if (_distanceBack < 40) then {
//                                         _convoyLeaderVic limitSpeed _convoyLeaderSpeed;
//                                     };
//                                     if (_distanceBack > 60) then {
//                                         _vic limitSpeed ((_convoyLeaderSpeed - (_convoyLeaderSpeed / 2)) - 10);
//                                         _convoyLeaderVic limitSpeed (_convoyLeaderSpeed / 2);
//                                     };
//                                     if (_distanceBack > 100) then {
//                                         _vic forceSpeed 0;
//                                         _convoyLeaderVic limitSpeed ((_convoyLeaderSpeed / 2) - 8);
//                                     };
//                                 };
//                                 if ((speed _vic) == 0) then {
//                                     _timeout = time + 7;
//                                     waitUntil {(speed _vic) > 0 or time >= _timeout};
//                                     if ((speed _vic) == 0) then {
//                                         [_vic, _group, _cords] call pl_vehicle_convoy_unstuck; 
//                                     };
//                                 };
//                             };
//                             sleep 0.5;
//                         };
//                         sleep 0.5;
//                         _vic forceSpeed -1;
//                         _vic limitSpeed 50;
//                         _vic setVariable ["pl_speed_limit", "50"];
//                         _vic forceFollowRoad false;
//                         // Land Convoy Arriving
//                         // if moveInConvoy do not unload Cargo

//                         if !(_moveInConvoy) then {
//                             if (_vic getVariable ["pl_on_transport", false]) then {
//                                 {
//                                     {
//                                         if ((assignedVehicleRole _x) select 0 isEqualTo "Cargo") then {
//                                             unassignVehicle _x;
//                                             doGetOut _x;
//                                         };
//                                     } forEach (units _x);
//                                     [(units _x)] allowGetIn false;
//                                     if (_x == (group player)) then {
            //                             doStop driver (vehicle (player));
            //                             sleep 0.1;
            //                             driver (vehicle (player)) doFollow player;
            //                         };
            //                         // player hcSetGroup [_x];
            //                         if !(_x getVariable ["pl_show_info", false]) then {
            //                             [_x] call pl_show_group_icon;
            //                         };
            //                         _x leaveVehicle _vic;
            //                     } forEach _cargoGroups;
            //                 };
            //             };
            //             {
            //                 player hcSetGroup [_x];
            //             } forEach _convoyArray;
            //             _wp setWaypointPosition [getPos _vic, 0];

            //             // remnove wp task icon
            //             pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];

            //             _convoyLeader setVariable ["onTask", false];
            //             _convoyLeader setVariable ["setSpecial", false];
            //             // if (_group == _convoyLeader) then {
            //                 // _convoyLeader setGroupId [_convoyLeaderGroupId];
            //             _cVic = vehicle (leader _convoyLeader);
            //             // _cCargo = fullCrew [_cvic, "cargo", false];
            //             // if ((count _cCargo) > 0) then {
            //             //     _convoyLeader setVariable ["setSpecial", true];
            //             //     _convoyLeader setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
            //             // };
            //             // };
            //             // check if convoyLeader has cargo --> set icon

            //             group (_commander) setVariable ["pl_draw_convoy", false];
            //             group (_commander) setBehaviour "AWARE";

            //             {
            //                 _x enableAI "AUTOCOMBAT";
            //             } forEach units (group _commander);
            //             pl_draw_convoy_array = pl_draw_convoy_array - [_convoyArray];
            //         }
            //         // Single Vehicle
            //         else
            //         {
            //             waitUntil {((leader _group) distance2D waypointPosition[(group _commander), currentWaypoint (group _commander)] < 30) or (!alive _vic)};
            //             // remnove wp task icon
            //             pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];

            //             deleteWaypoint [_group, _wp#1];
            //             doStop _vic;

            //             sleep 0.5;
            //             if (_vic getVariable ["pl_on_transport", false]) then {
            //                 {
            //                     _unit = _x select 0;
            //                     _unit enableAI "AUTOCOMBAT";
            //                     if (_x select 1 isEqualTo "cargo") then {
            //                         unassignVehicle _unit;
            //                         doGetOut _unit;
            //                         (group _unit) leaveVehicle _vic;
            //                         [_unit] allowGetIn false;
            //                     };
            //                 } forEach _cargo;
            //             };
            //         };
            //         if (!_moveInConvoy and _vic getVariable ["pl_on_transport", false]) then {
            //             {
            //                 // _x setVariable ["pl_show_info", true];
            //                 if !(_x getVariable ["pl_show_info", false]) then {
            //                     [_x] call pl_show_group_icon;
            //                 };
            //                 _x leaveVehicle _vic;
            //                 // _x addWaypoint [getPos _vic, 10];
            //                 player hcSetGroup [_x];
            //             } forEach _cargoGroups;
            //         };
            //         // Single Land Tarnsport ariving
            //     };
            // }
            // // If Vehicle is Transported
            // else
            // {
            //     {
            //         _x disableAI "AUTOCOMBAT";
            //         _x disableAI "TARGET";
            //         _x disableAI "AUTOTARGET";
            //     } forEach (units (group _commander));
            //     (group _commander) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
            //     [_vic, 0] call pl_door_animation;
            //     sleep 40;

//                 // Air Vehicle in Vehicle Tranport Ariving
//                 waitUntil {sleep 0.1; (isTouchingGround _vic) or !alive _vic};
//                 // player hcSetGroup [_group];
//                 {
//                     player hcsetGroup [(group (_x select 0))];
//                 } forEach fullCrew[vehicle (leader (_group)), "cargo", false];
//                 [_vic, 1] call pl_door_animation;
//                 sleep 5;
//                 for "_i" from count waypoints _group - 1 to 0 step -1 do {
//                     deleteWaypoint [_group, _i];
//                 };
//                 _wp = (group _commander) addWaypoint [getPos _vic, 0];
//                 _wp setWaypointType  "VEHICLEINVEHICLEUNLOAD";
//                 // player hcRemoveGroup (group _commander);
//                 sleep 2;
//                 waitUntil {isNull (isVehicleCargo _transportedVic) or (!alive _vic)};
//                 // _group setVariable ["pl_show_info", true];
//                 if !(_group getVariable ["pl_show_info", false]) then {
//                     [_group] call pl_show_group_icon;
//                 };
//                 // _group leaveVehicle _vic;
//             };

//             // if !(_moveInConvoy) then {
//             //     waitUntil {((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
//             //     // if (pl_enable_beep_sound) then {playSound "beep"};
//             //     // _commander sideChat format ["%1 finished unloading, over", groupId _group];
//             //     player hcSetGroup [_group];
//             //     sleep 2;
//             //     (group _commander) setVariable ["setSpecial", false];
//             //     (group _commander) setVariable ["pl_has_cargo", false];
//             // };
//             // _vic setVariable ["pl_on_transport", nil];
//             // sleep 10;

// //             // Air Tranport Ariving
//             if (_vic isKindOf "Air") then {
//                 deleteVehicle _landigPad;
//                 _rtbCords = _vic getVariable "pl_rtb_pos";
//                 [_vic, 0] call pl_door_animation;
//                 if ((_vic distance2D _rtbCords) < 300) exitWith {_vic engineOn false};
//                 (group _commander) addWaypoint [_rtbCords, 0];
//                 {
//                     _x disableAI "AUTOCOMBAT";
//                 } forEach (crew _vic);
//                 sleep 2;
//                 if (pl_enable_beep_sound) then {playSound "beep"};
//                 _commander sideChat format ["%1: RTB", groupId (group _commander)];
//                 if (pl_enable_map_radio) then {[group _commander, "...RTB", 25] call pl_map_radio_callout};
//                 waitUntil {sleep 0.1; (unitReady _vic) or (!alive _vic)};
//                 {
//                     _x enableAI "AUTOCOMBAT";
//                 } forEach (crew _vic);
//                 sleep 1;
//                 // doStop _vic;
//                 {
//                     _x enableAI "AUTOCOMBAT";
//                     _x disableAI "TARGET";
//                     _x enableAI "AUTOTARGET";
//                 } forEach (units (group _commander));
//                 group (_commander) setVariable ["pl_draw_convoy", false];
//                 pl_draw_convoy_array = pl_draw_convoy_array - [_convoyArray];
//                 _vic land "LAND";
//             // };
//         }
//         else
//         {
//             // Unload at Current Position when map closed
//             _vic = vehicle (leader _group);
//             _driver = driver _vic;
//             _vicGroup = group _driver;
//             doStop _vic;
//             _cargo = fullCrew [_vic, "cargo", false];
//             _cargoGroups = [];
//             {
//                 _unit = _x select 0;
//                 if !(_unit in (units _vicGroup)) then {
//                     unassignVehicle _unit;
//                     doGetOut _unit;
//                     [_unit] allowGetIn false;
//                     _cargoGroups pushBack (group (_x select 0));
//                 };
//             } forEach _cargo;
//             _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;
//             {
//                 // _x leaveVehicle _vic;
//                 // _x setVariable ["pl_show_info", true];
//                 // player hcSetGroup [_x];
//                 if !(_x getVariable ["pl_show_info", false]) then {
//                     [_x] call pl_show_group_icon;
//                 };
//                 _x leaveVehicle _vic;
//                 // _x addWaypoint [getPos _vic, 10];
//             } forEach _cargoGroups;

//             if (pl_enable_beep_sound) then {playSound "beep"};
//             // _commander sideChat format ["Roger, %1 beginning unloading, over", groupId _group];
//             waitUntil {sleep 0.1; ((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
//             // {
//             //     {
//             //         doStop _x;
//             //         _x doFollow leader _x;
//             //     } forEach (units _x);
//             // } forEach _cargoGroups;
//             // if (pl_enable_beep_sound) then {playSound "beep"};
//             // _commander sideChat format ["%1 finished unloading, over", groupId _group];
//             _vic setVariable ["pl_on_transport", nil];
//             // (group _commander) setVariable ["setSpecial", false];
//             (group _commander) setVariable ["pl_has_cargo", false];
//             _vic doFollow _vic;
//         };
//     };
// };

// pl_spawn_getOut_vehicle = {
//     params [["_moveInConvoy", false]];
//     if (pl_enable_beep_sound) then {playSound "beep"};
//     private _convoyArray = [];
//     {
//         if (vehicle (leader _x) != leader _x) then {
//             _vic = vehicle (leader _x);
//             _vic engineOn true;
//             _group = group (driver _vic);
//             _convoyArray pushBack _group;
//         };
//     } forEach hcSelected player;

//     _convoyArray = _convoyArray arrayIntersect _convoyArray;
//     if (_moveInConvoy and ((count _convoyArray) < 2)) exitWith {
        
//         (leader (hcSelected player select 0)) sidechat "Not enough Vehicle to form a Convoy";
//     };
//     _convoyId = str (random 2);
//     c_test_id = _convoyId;
//     missionNamespace setVariable [_convoyId, _convoyArray];
//     missionNamespace setVariable [_convoyId + "pos", 0];
//     missionNamespace setVariable [_convoyId + "time", 0];
//     {
//         [_x, _convoyId, _moveInConvoy] spawn pl_getOut_vehicle;
//         // sleep 0.1;
//     } forEach hcSelected player;  
// };

pl_advance = {
    params ["_group"];
    private ["_cords", "_awp"];

    _group = (hcSelected player) select 0;

    // if Map at mousclick else at cursor position
    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };

    // exit if vehicle
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    // reset _group before execution
    // Whyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy?????????????????
    if (pl_enable_beep_sound) then {playSound "beep"};
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    // limit to speed (no sprinting)
    (leader _group) limitSpeed 15;

    // disable combatmode 
    {
        _x disableAI "AUTOCOMBAT";
        // _x disableAI "FSM";
        // _x disableAI "COVER";
        // _x disableAI "SUPPRESSION";
    } forEach (units _group);
    _group setBehaviour "AWARE";

    // set wp
    _awp = _group addWaypoint [_cords, 0];

    if ((_cords distance2D (getPos (leader _group))) < 150 ) then {
        _atkDir = (leader _group) getDir _cords;
        _offset = -20;
        _increment = 4;
        {   
            _pos = [_offset * (sin (_atkDir - 90)), _offset * (cos (_atkDir - 90)), 0] vectorAdd _cords;
            _offset = _offset + _increment;
            if (_x == leader _group) then {_pos = _cords};
            _pos = _pos findEmptyPosition [0, 50, typeOf _x];
            
            // _m = createMarker [str (random 1), _pos];
            // _m setMarkerType "mil_dot";

            [_x, _pos] spawn {
                params ["_unit", "_pos"];
                _unit limitSpeed 15;
                _unit doMove _pos;
                _unit setDestination [_pos, "FORMATION PLANNED", false];
                _reachable = [_unit, _pos, 20] call pl_not_reachable_escape;
            };
        } forEach (units _group);
    };

    // set Variables
    // _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\walk_ca.paa";
    _icon = '\A3\3den\data\Attributes\SpeedMode\normal_ca.paa';
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    // add Task Icon to wp
    pl_draw_planed_task_array pushBack [_awp, _icon];

    // waitUntil waypoint reached or task canceled
    sleep 1;
    waitUntil {sleep 0.5;if (_group isEqualTo grpNull) exitWith {true}; unitReady (leader _group) or !(_group getVariable ["onTask", true])};

    // remove Task Icon from wp and delete wp
    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_awp,  _icon]];
    deleteWaypoint [_group, _awp#1];

    // reset advance behaviour
    (leader _group) limitSpeed 5000;
    {
        // _x enableAI "COVER";
        // _x enableAI "SUPPRESSION";
        // _x enableAI "FSM";
        _x enableAI "AUTOCOMBAT";
        _x forceSpeed -1;
        _x limitSpeed 5000;
        _x setDestination [getPos _x, "DoNotPlan", true];
        doStop _x;
        _x doFollow (leader _group);
    } forEach (units _group);
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
};

pl_reworked_bis_unpack = {
    
        // Author: 
        //     Dean "Rocket" Hall, reworked by Killzone_Kid

        // Description:
        //     This function will move given support team to the given position
        //     The weapon crew will unpack carried weapon and start watching given position
        //     Requires three personnel in the team: Team Leader, Gunner and Asst. Gunner
        //     This function is MP compatible
        //     When weapon is unpacked, scripted EH "StaticWeaponUnpacked" is called with the following params: [group, leader, gunner, assistant, weapon]

        // Parameters:
        //     0: GROUP or OBJECT - the support team group or a unit from this group 
        //     1: ARRAY, STRING or OBJECT - weapon placement position, object position or marker
        //     2: ARRAY, STRING or OBJECT - target position, object position to watch or marker
        //     3: (Optional) ARRAY, STRING or OBJECT - position, object or marker group leader should move to
            
        // Returns:
        //     NOTHING
        
        // NOTE:
        //     If a unit flees, all bets are off and the function will exit leaving units on their own
        //     To guarantee weapon assembly, make sure the group has maximum courage (_group allowFleeing 0)
        
        // Example1:
        //     [leader1, "weapon_mrk", "target_mrk"] call BIS_fnc_unpackStaticWeapon;
            
        // Example2:
        //     group1 allowFleeing 0;
        //     [group1, "weapon_mrk", tank1, "leader_mrk"] call BIS_fnc_unpackStaticWeapon;
    

    params [
        ["_group", grpNull, [grpNull, objNull]], 
        ["_weaponPos", [0,0,0], [[], "", objNull], 3],
        ["_targetPos", [0,0,0], [[], "", objNull], 3],
        ["_leaderPos", [0,0,0], [[], "", objNull], 3]
    ];

    private _leader = leader _group;
    if (!local _leader) exitWith {_this remoteExecCall ["BIS_fnc_unpackStaticWeapon", _leader]};

    private _err_badGroup = 
    {
        ["Bad group! The group should exist and consist of minimum a Leader, Gunner and Asst. Gunner"] call BIS_fnc_error;
        nil
    };

    private _err_badPosition = 
    {
        ["Bad position! Position should exist and could be array, marker or object"] call BIS_fnc_error;
        nil
    };

    if (_group isEqualType objNull) then {_group = group _group};
    if (isNull _group) exitWith _err_badGroup;

    if (_weaponPos isEqualType "") then {_weaponPos = getMarkerPos _weaponPos};
    if (_weaponPos isEqualType objNull) then {_weaponPos = getPosATL _weaponPos};
    if (_weaponPos isEqualTo [0,0,0]) exitWith _err_badPosition;

    if (_targetPos isEqualType "") then {_targetPos = getMarkerPos _targetPos};
    if (_targetPos isEqualType objNull) then {_targetPos = getPosATL _targetPos};
    if (_targetPos isEqualTo [0,0,0]) exitWith _err_badPosition;

    if (_leaderPos isEqualType "") then {_leaderPos = getMarkerPos _leaderPos};
    if (_leaderPos isEqualType objNull) then {_leaderPos = getPosATL _leaderPos};

    private _cfg = configFile >> "CfgVehicles";
    private _supportUnits = ((units _group) - [_leader]); // changed by jellyfish from (units _group - [_leader]) select {getText (_cfg >> typeOf _x >> "vehicleClass") == "MenSupport"};
    if ((count _supportUnits) < 2) exitWith {[false, []]};
    private _gunner = 
    {
        if (unitBackpack _x isKindOf "Weapon_Bag_Base") exitWith {_x};
        
        objNull
    } forEach _supportUnits;

    if (isNull _gunner) exitWith {[false, []]}; // changed by Jellyfish

    _group setVariable ["pl_static_bag_gun", backpack _gunner];

    private _cfgBase = configFile >> "CfgVehicles" >> backpack _gunner >> "assembleInfo" >> "base";
    private _compatibleBases = if (isText _cfgBase) then {[getText _cfgBase]} else {getArray _cfgBase};
    if (_compatibleBases isEqualTo [""]) then {_compatibleBases = []};
    private _assistant = 
    {   
        // private _xx = _x;
        
        // if ({unitBackpack _xx isKindOf _x} count _compatibleBases > 0) exitWith {_xx};
        
        // objNull
        _cfgBaseAssistant = configFile >> "CfgVehicles" >> backpack _x >> "assembleInfo" >> "base";
        _compatibleBasesAssistant = if (isText _cfgBaseAssistant) then {[getText _cfgBaseAssistant]} else {getArray _cfgBaseAssistant};
        if ((backpack _x) in _compatibleBases || { (backpack _gunner) in _compatibleBasesAssistant}) exitWith {_x};
        objNull
    }
    forEach (_supportUnits - [_gunner]);

    if (isNull _assistant) exitWith {[false, []]}; // changed by Jellyfish

    _group setVariable ["pl_static_bag_base", backpack _assistant];

    player hcRemoveGroup _group;
    
    // -- calculate optimal positions for weapon crew
    private _targetDir = _weaponPos getDir _targetPos;
    private _assistantPos = _weaponPos getPos [1.5, _targetDir + 90]; _assistantPos set [2, _weaponPos select 2]; // -- keep z
    private _gunnerPos = _weaponPos getPos [1.5, _targetDir - 90]; _gunnerPos set [2, _weaponPos select 2]; // -- keep z

    if (_gunner distance2D _gunnerPos > _gunner distance2D _assistantPos) then
    {
        // -- swap
        private _tmp = _gunnerPos; _gunnerPos = _assistantPos; _assistantPos = _tmp;
    }; 

    _gunner addEventHandler ["WeaponAssembled", format [
        '
            params ["_gunner", "_weapon"];
            
            _gunner removeEventHandler ["WeaponAssembled", _thisEventHandler];
            
            _weapon setDir (_weapon getDir %3);
            _weapon setPosATL getPosATL _gunner;

        
            [_gunner] allowGetIn true;
            _gunner assignAsGunner _weapon;
            _gunner moveInGunner _weapon;
            _gunner doWatch %3;
            
            _leader = "%1" call BIS_fnc_objectFromNetId;
            _assistant = "%2" call BIS_fnc_objectFromNetId;
            
            _group = group _gunner;
            _group addVehicle _weapon;
            _group setVariable ["pl_group_static", _weapon];

            
            [_group, "StaticWeaponUnpacked", [_group, _leader, _gunner, _assistant, _weapon]] call BIS_fnc_callScriptedEventHandler;
        ', 
                    
        _leader call BIS_fnc_netId,
        _assistant call BIS_fnc_netId,
        _targetPos
    ]]; 

    ((units _group) - [_gunner]) allowGetIn false;

    // -- leader logic
    [_leader, _leaderPos, _targetPos] spawn
    {
        params ["_leader", "_leaderPos", "_targetPos"];
        
        waitUntil {isNull (_leader getVariable ["BIS_staticWeaponLeaderScript", scriptNull])};
        _leader setVariable ["BIS_staticWeaponLeaderScript", _thisScript];
        
        if !(_leaderPos isEqualTo [0,0,0]) then
        {
            _leader doWatch _targetPos;
            _leader doMove _leaderPos;
            
            waitUntil {unitReady _leader};  
        };
        
        if (fleeing _leader) exitWith {};
        
        doStop _leader;
        
        _leader setUnitPos "MIDDLE";
        _leader doWatch _targetPos;

        waitUntil {stance _leader isEqualTo "CROUCH" || !alive _leader};
        
        _leader selectWeapon binocular _leader;
        // _markerName = format ["defence%1", (group _leader)];
        // _leader disableAI "PATH";
        // pl_denfence_draw_array = pl_denfence_draw_array - [[_markerName, _leader]];
    };

    // -- assistant logic
    private _assistantReady = [_assistant, _assistantPos, _targetPos] spawn
    {
        params ["_assistant", "_assistantPos", "_targetPos"];
        
        _assistant doWatch _targetPos;
        _assistant doMove _assistantPos;

        sleep 1;
        
        waitUntil {unitReady _assistant};
        
        if (fleeing _assistant) exitWith {};
        
        doStop _assistant;
        
        _assistant setUnitPos "MIDDLE";
        _assistant doWatch _targetPos;
        
        waitUntil {stance _assistant isEqualTo "CROUCH" || !alive _assistant};
    };

    // -- gunner logic
    
    [_gunner, _gunnerPos, _targetPos, _assistant, _assistantReady, _group] spawn
    {
        params ["_gunner", "_gunnerPos", "_targetPos", "_assistant", "_assistantReady", "_group"];
            
        _gunner doWatch _targetPos;
        _gunner doMove _gunnerPos;

        sleep 1;

        waitUntil {unitReady _gunner};
        
        if (!alive _gunner || fleeing _gunner) exitWith {_gunner removeAllEventHandlers "WeaponAssembled"; player hcSetGroup [_group];};
        
        doStop _gunner;
        
        _gunner setUnitPos "MIDDLE";
        _gunner doWatch _targetPos;
        
        waitUntil {stance _gunner isEqualTo "CROUCH" || !alive _gunner};
        waitUntil {scriptDone _assistantReady};
        
        if (!alive _assistant || fleeing _assistant) exitWith {_gunner removeAllEventHandlers "WeaponAssembled"; player hcSetGroup [_group];};
        
        // -- unpack weapon
        _weaponBase = unitBackpack _assistant;
        _gunner action ["PutBag", _assistant];
        _gunner action ["Assemble", _weaponBase];
        sleep 2;
        _weapon = vehicle _gunner;
        [] call pl_show_fire_support_menu;        
        _pos = getPosASL _weapon;
        _pos = [_pos#0, _pos#1, _pos#2 + 1.5];
        _weapon setPosASL _pos;
        _weapon setVectorUp surfaceNormal position _weapon;

        _icon = getText (configfile >> 'CfgVehicles' >> typeof _weapon >> 'icon');

        _group setVariable ["specialIcon", _icon];

        sleep 1;
        player hcSetGroup [_group];



    };
    [true, [_leader, _gunner, _assistant]]
};



    // Author: 
    //     Dean "Rocket" Hall, reworked by Killzone_Kid

    // Description:
    //     This function will make weapon team pack a static weapon
    //     The weapon crew will pack carried weapon (or given weapon if different) and follow leader
    //     Requires three personnel in the team: Team Leader, Gunner and Asst. Gunner
    //     This function is MP compatible
    //     When weapon is packed, scripted EH "StaticWeaponPacked" is called with the following params: [group, leader, gunner, assistant, weaponBag, tripodBag]

    // Parameters:
    //     0: GROUP or OBJECT - the support team group or a unit from this group
    //     1: (Optional) OBJECT - weapon to pack. If nil, current group weapon is packed
    //     2: (Optional) ARRAY, STRING or OBJECT - position, object or marker the group leader should move to after weapon is packed. By default the group will
    //        resume on to the next assigned waypoint. If this param is provided, group will not go to the next waypoint and will move to given position instead
        
    // Returns:
    //     NOTHING
    
    // NOTE:
    //     If a unit flees, all bets are off and the function will exit leaving units on their own
    //     To guarantee weapon disassembly, make sure the group has maximum courage (_group allowFleeing 0)
    
    // Example1:
    //     [leader1] call BIS_fnc_packStaticWeapon;
        
    // Example2:
    //     group1 allowFleeing 0;
    //     [group1, nil, "leaderpos_marker"] call BIS_fnc_packStaticWeapon;


pl_reworked_bis_pack = {
    params [
        ["_group", grpNull, [grpNull, objNull]], 
        ["_weapon", objNull, [objNull]],
        ["_leaderPos", [0,0,0], [[], "", objNull], 3]
    ];

    private _leader = leader _group;
    if (!local _leader) exitWith {_this remoteExecCall ["BIS_fnc_packStaticWeapon", _leader]};

    private _err_badGroup = 
    {
        ["Bad group! The group should exist and consist of minimum a Leader, Gunner and Asst. Gunner"] call BIS_fnc_error;
        nil
    };

    private _err_badPosition = 
    {
        ["Bad position! Position should exist and could be array, marker or object"] call BIS_fnc_error;
        nil
    };

    private _err_badWeapon = 
    {
        ["Bad static weapon! Static weapon should exist and not be packed or broken"] call BIS_fnc_errora        nil
    };

    if (_group isEqualType objNull) then {_group = group _group};
    if (isNull _group) exitWith _err_badGroup;

    if (_leaderPos isEqualType "") then {_leaderPos = getMarkerPos _leaderPos};
    if (_leaderPos isEqualType objNull) then {_leaderPos = getPosATL _leaderPos};

    private _cfg = configFile >> "CfgVehicles";
    private _supportUnits = (units _group - [_leader]); // changed by Jellyfish from select {getText (_cfg >> typeOf _x >> "vehicleClass") == "MenSupport"};

    private _gunnerBackpackClass = "";
    private _gunner = gunner _weapon;

    if (isNull _gunner) exitWith {_err_badGroup};

    private _cfgBase = configFile >> "CfgVehicles" >> _gunnerBackpackClass >> "assembleInfo" >> "base";
    private _compatibleBases = if (isText _cfgBase) then {[getText _cfgBase]} else {getArray _cfgBase};
    private _assistant = 
    {   
        if (isNull (unitBackpack _x)) exitWith {_x};
        objNull;
    }
    forEach (_supportUnits - [_gunner, _leader]);

    if (isNull _assistant) exitWith {_err_badGroup};

    private _isWeaponGunner = false;

    if (isNull _weapon) then 
    {
        _weapon = assignedVehicle _gunner;
        _isWeaponGunner = objectParent _gunner isEqualTo _weapon;
    };

    if (!alive _weapon || !(_weapon isKindOf "StaticWeapon") || !isNull objectParent _weapon) exitWith _err_badWeapon;

    player hcRemoveGroup _group;

    _gunner addEventHandler ["WeaponDisassembled", format [
        '
            params ["_gunner", "_weaponBag", "_baseBag"];
            
            _gunner removeEventHandler ["WeaponDisassembled", _thisEventHandler];
            
            _leader = "%1" call BIS_fnc_objectFromNetId;
            _assistant = "%2" call BIS_fnc_objectFromNetId;
            
            _gunner action ["TakeBag", _weaponBag];
            _assistant action ["TakeBag", _baseBag];
                
            _gunner setUnitPos "AUTO";
            _gunner doWatch objNull;
            _gunner doFollow _leader;
            
            _assistant setUnitPos "AUTO";
            _assistant doWatch objNull;
            _assistant doFollow _leader;

            [] call pl_show_fire_support_menu;
            
            _group = group _gunner;
            [_group, "StaticWeaponPacked", [_group, _leader, _gunner, _assistant, _weaponBag, _baseBag]] call BIS_fnc_callScriptedEventHandler;
        ',
        _leader call BIS_fnc_netId,
        _assistant call BIS_fnc_netId
    ]];

    if (_isWeaponGunner) then {moveOut _gunner};
    _group leaveVehicle assignedVehicle _gunner;
    unassignVehicle _gunner;

    private _weaponPos = getPosATL _weapon;
    private _assistantPos = _weapon getRelPos [1, 135]; _assistantPos set [2, _weaponPos select 2]; // -- keep z
    private _gunnerPos = _weapon getRelPos [1, -135]; _gunnerPos set [2, _weaponPos select 2]; // -- keep z

    if (_gunner distance2D _gunnerPos > _gunner distance2D _assistantPos) then
    {
        // -- swap
        private _tmp = _gunnerPos; _gunnerPos = _assistantPos; _assistantPos = _tmp;
    }; 

    // -- leader logic
    [_leader, _leaderPos] spawn 
    {
        params ["_leader", "_leaderPos"];

        waitUntil {isNull (_leader getVariable ["BIS_staticWeaponLeaderScript", scriptNull])};
        _leader setVariable ["BIS_staticWeaponLeaderScript", _thisScript];
        
        _weapons = [primaryWeapon _leader, handgunWeapon _leader, secondaryWeapon _leader];

        if (!(currentWeapon _leader in _weapons) || currentWeapon _leader isEqualTo "") then
        {
            {
                if !(_x isEqualTo "") exitWith {_leader selectWeapon _x};
            }
            forEach _weapons;
        };
        
        _leader setUnitPos "AUTO";
        _leader doWatch objNull;
        
        if (_leaderPos isEqualTo [0,0,0]) exitWith {_leader doFollow _leader};
        
        _leader doMove _leaderPos;
            
        waitUntil {unitReady _leader};
            
        doStop _leader;
    };

    // -- assistant logic
    private _assistantReady = [_assistant, _assistantPos, _weapon, _isWeaponGunner] spawn
    {
        params ["_assistant", "_assistantPos", "_weapon", "_isWeaponGunner"];
        
        if (!_isWeaponGunner) then
        {
            _assistant setUnitPos "AUTO";
            _assistant doWatch _weapon;
            _assistant doMove _assistantPos;
            
            waitUntil {unitReady _assistant};
        };
        
        doStop _assistant;
        _assistant doWatch _weapon;
        
        if (fleeing _assistant) exitWith {};
    };

    // -- gunner logic
    [_gunner, _gunnerPos, _weapon, _assistant, _assistantReady, _isWeaponGunner, _group] spawn
    {
        params ["_gunner", "_gunnerPos", "_weapon", "_assistant", "_assistantReady", "_isWeaponGunner", "_group"];
            
        if (!_isWeaponGunner) then
        {
            _gunner setUnitPos "AUTO";
            _gunner doWatch _weapon;
            _gunner doMove _gunnerPos;
            
            waitUntil {unitReady _gunner};
        };
        
        if (!alive _gunner || fleeing _gunner) exitWith {_gunner removeAllEventHandlers "WeaponDisassembled"; player hcSetGroup [_group]};
        
        doStop _gunner;
        _gunner doWatch _weapon;
        
        waitUntil {scriptDone _assistantReady};


        if (!alive _assistant || fleeing _assistant) exitWith {_gunner removeAllEventHandlers "WeaponDisassembled"; player hcSetGroup [_group]};
        
        // -- pack weapon
        _gunner action ["Disassemble", _weapon];

        sleep 2;

        player hcSetGroup [_group];
    };
};

// pl_mine_cls = ["APERSMineDispenser_Mag", "APERSBoundingMine_Range_Mag", "APERSMine_Range_Mag", "ATMine_Range_Mag", "SLAMDirectionalMine_Range_Mag", "ClaymoreDirectionalMine_Remote_Mag", "DemoCharge_Remote_Mag", "SatchelCharge_Remote_Mag", "ClaymoreDirectionalMine_Remote_Mag"];
// "APERSTripMine_Wire_Mag"

// pl_get_group_mines = {
//     params ["_group"];
//     private ["_groupMines"];

//     _groupMines = [];

//     {
//         _unit = _x;
//         _mines = (magazines _unit) select {_x in pl_mine_cls};
//         {
//             _groupMines pushBack [_x, _unit];
//         } forEach _mines;
//     } forEach (units _group);
//     _groupMines
// };

// pl_create_mine_menu = {
//     private ["_group", "_idx", "_mine", "_unit"];
//     _group = (hcSelected player) select 0; 
//     _groupMines = [_group] call pl_get_group_mines;
//     pl_test = _groupMines;

//     _menuStr = "pl_mine_menu = [['Available Mines', true],";
//     pl_mine_idx = -1;
//     _idx = 0;
//     {
//         _mine = _x select 0;
//         _unit = _x select 1;
//         _mineName = getText (configFile >> "CfgMagazines" >> _mine >> "displayName");
//         _unitName = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName");
//         _menuStr = _menuStr + format ["['%1 (%2)', [%3 + 2], '', -5, [['expression', 'pl_mine_idx = %3']], '1', '1'],", _mineName, _unitName, _idx];
//         _idx = _idx + 1;
//     } forEach _groupMines;
//     _menuStr = _menuStr + "['', [], '', -5, [['expression', '']], '0', '0']]";
//     call compile _menuStr;

//     showCommandingMenu "#USER:pl_mine_menu";

//     _time = time + 20;
//     waitUntil {pl_mine_idx != -1 or commandingMenu == ""};
//     if (pl_mine_idx == -1) exitWith {};
//     _mineUnit = _groupMines select pl_mine_idx;
//     [_mineUnit#0, _group, _mineUnit#1] call pl_place_mine;
//     pl_mine_idx = -1;
// };

// pl_get_closest_mine = {
//     params ["_unit"];

//     _mines = allMines;
//     _mine = ([_mines, [], { _unit distance2D _x }, "ASCEND"] call BIS_fnc_sortBy) select 0;
//     _mine
// };

// pl_place_mine = {
//     params ["_mine", "_group", "_unit"];
//     private ["_cords", "_mineDir"];


//     if (visibleMap) then {
//         hintSilent "";
//         hint "Select MINE position on MAP (SHIFT + LMB to cancel)";

//         onMapSingleClick {
//             pl_mine_cords = _pos;
//             pl_mapClicked = true;
//             pl_show_draw_mine_dir = true;
//             if (_shift) then {pl_cancel_strike = true};
//             hintSilent "";
//             onMapSingleClick "";
//         };

//         while {!pl_mapClicked} do {sleep 0.1;};
//         pl_mapClicked = false;
//         if (pl_cancel_strike) exitWith {};

//         _cords = pl_mine_cords;

//         hint "Select MINE facing on MAP (SHIFT + LMB to cancel)";

//         onMapSingleClick {
//             pl_mapClicked = true;
//             if (_shift) then {pl_cancel_strike = true};
//             hintSilent "";
//             onMapSingleClick "";
//         };

//         while {!pl_mapClicked} do {
//             _mineDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
//             sleep 0.1;
//         };
//         pl_mapClicked = false;
//         pl_show_draw_mine_dir = false;
//     }
//     else
//     {
//         _cords = screenToWorld [0.5, 0.5];
//         _mineDir = getDir player;
//     };

//     if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

//     // kompleter scheiß, weil _unit einfach randam sein Value aendert
//     missionNamespace setVariable ["mine_unit", _unit];
//     if ((_unit distance2D _cords) > 75) exitWith {hint "Group needs to be within 75 Meters of position!"};
//     if (_unit getVariable ["pl_mining_task", false]) exitWith {hint "Unit is already placing a mine!"};
    
//     [_group] call pl_reset;
//     sleep 0.2;
//     _unit = missionNamespace getVariable "mine_unit";

//     _group setVariable ["onTask", true];
//     _group setVariable ["setSpecial", true];
//     _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"];
//     _unit setVariable ["pl_mining_task", true];
//     _mineVic = (_mine splitString "_") select 0;
//     [_group, _unit, _mine, _mineVic, _cords, _mineDir] spawn {
//         params ["_group", "_unit", "_mine", "_mineVic", "_cords", "_mineDir"];

//         _unit disableAI "AUTOCOMBAT";
//         _unit doMove _cords;

//         waitUntil {unitReady _unit or !(_group getVariable ["onTask", true])};

//         _unit enableAI "AUTOCOMBAT";
//         _muzzles = getArray (configFile >> "CfgWeapons" >> "Put" >> "muzzles");

//         _muzzle = {
//             _mags = getArray (configFile >> "CfgWeapons" >> "Put" >> _x >> "magazines");
//             if (_mine in _mags) exitWith {_x};
//             objNull
//         } forEach _muzzles;

//         // _unit playActionNow "PutDown";
//         _unit fire [_muzzle, _muzzle, _mine];
//         sleep 1.5;
//         _mines = allMines;
//         _mine = ([_mines, [], { _unit distance2D _x }, "ASCEND"] call BIS_fnc_sortBy) select 0;
//         // playerSide reveal _mine;
//         player addOwnedMine _mine;
//         _mine setDir _mineDir;

//         sleep 1;
//         _unit setVariable ["pl_mining_task", nil];
//         [_group] call pl_reset;
//     };
//     {
//         _x disableAI "AUTOCOMBAT";
//         [_x, (getPos _x), 0, 10, false] spawn pl_find_cover;
//     } forEach (units _group) - [_unit];
// };


    // _markers = [];
    // _markerTargets = [];
    // {
    //     if !(_x in pl_marker_targets) then {
    //         if (alive _x and (side _x) != civilian) then {
    //             if (_x isKindOf "Man" or _x isKindOf "Tank" or _x isKindOf "Car" or _x isKindOf "Truck") then {
    //                 _pos = [[[getPos _x, 10]],[]] call BIS_fnc_randomPos;
    //                 private _markerName = str _x;
    //                 _markerSize = 0.15;
    //                 _marker = createMarker [_markerName, _pos];
    //                 _markerName setMarkerType "o_unknown";
    //                 // if (_x isKindOf "Tank") then {
    //                 //     _markerName setMarkerType "o_armor";
    //                 //     _markerSize = 0.4;
    //                 // };
    //                 // if (_x isKindOf "Car") then {
    //                 //     _markerName setMarkerType "o_motor_inf";
    //                 //     _markerSize = 0.4;
    //                 // };
    //                 _unitText = getText (configFile >> "CfgVehicles" >> typeOf _x >> "textSingular");

    //                 switch (_unitText) do {
    //                     case "truck" : {_markerName setMarkerType "o_support"; _markerSize = 0.3};
    //                     case "car" : {_markerName setMarkerType "o_motor_inf"; _markerSize = 0.3}; 
    //                     case "tank" : {_markerName setMarkerType "o_armor"; _markerSize = 0.3}; 
    //                     case "specop" : {_markerName setMarkerType "o_recon"}; 
    //                     case "APC" : {_markerName setMarkerType "o_mech_inf"; _markerSize = 0.3};
    //                     default {_markerName setMarkerType "o_inf";};
    //                 };

    //                 _markerName setMarkerColor "colorOpfor";
    //                 _markerName setMarkerSize [_markerSize, _markerSize];
    //                 // _markerName setMarkerText str (parseText _markerText);
    //                 _markers pushBack _markerName;
    //                 _markerTargets pushBack _x;
    //                 pl_marker_targets pushBack _x;
    //             };
    //         };
    //     };
    // } forEach _targets;

    // // waitUntil {time >= _time};
    // sleep 20;
    // {
    //     deleteMarker _x;
    // } forEach _markers;
    // pl_marker_targets = pl_marker_targets - _markerTargets; 

    
// pl_find_cover = {
//     params ["_unit", "_watchPos", "_watchDir", "_radius", "_moveBehind", ["_fullCover", false], ["_inArea", ""], ["_fofScan", false]];
//     private ["_valid"];

//     _covers = nearestTerrainObjects [getPos _unit, pl_valid_covers, _radius, true, true];
//     // _unit enableAI "AUTOCOMBAT";
//     _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _watchPos;
//     if ((count _covers) > 0) then {
//         {
//             _valid = true;
//             if !(_inArea isEqualTo "") then {
//                 if !(_x inArea _inArea) then {
//                     _valid = false;
//                 };
//             };

//             if (!(_x in pl_covers) and _valid) exitWith {
//                 pl_covers pushBack _x;
//                 _coverPos = getPos _x;
//                 _unit doMove _coverPos;
//                 _unit setDestination [_coverPos, "LEADER DIRECT", true];
//                 sleep 0.5;
//                 waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or unitReady _unit};
//                 if ((group _unit) getVariable ["onTask", true]) then {
//                     if (_moveBehind) then {
//                         _coverPos =  (getPos _unit) getPos [0.5, _watchDir - 180];
//                         _unit doMove _coverPos;
//                         _unit setDestination [_coverPos, "LEADER DIRECT", true];
//                         sleep 0.5;
//                         waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or unitReady _unit};
//                     };
//                     if ((group _unit) getVariable ["onTask", true]) then {
//                         _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
//                         _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
//                         _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
//                         if (_visP isEqualTo []) then {
//                             _unit setUnitPos "DOWN";
//                         } 
//                         else
//                         {
//                             _unit setUnitPos "MIDDLE";
//                         };

//                         if (_fullCover) then {
//                             _unit setUnitPos "DOWN";
//                         };

//                         // doStop _unit;
//                         _unit doWatch _watchPos;
//                         _unit disableAI "PATH";
//                     };
//                     [_x] spawn {
//                         params ["_cover"];
//                         sleep 5;
//                         pl_covers deleteAt (pl_covers find _cover);
//                     };
//                 };
//             };
//         } forEach _covers;

//         if ((unitPos _unit) == "Auto" and ((group _unit) getVariable ["onTask", false])) then {
//             _unit setUnitPos "DOWN";
//             // doStop _unit;
//             _unit doWatch _watchPos;
//             _unit disableAI "PATH";
//         };
//     }
//     else
//     {
//         _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
//         _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
//         _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
//         if (_visP isEqualTo []) then {
//             _unit setUnitPos "DOWN";
//         } 
//         else
//         {
//             _unit setUnitPos "MIDDLE";
//         };
//         // doStop _unit;
//         _unit doWatch _watchPos;
//         _unit disableAI "PATH";
//     };
//     if (_fofScan) then {
//         private _c = 0;
//         _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
//         for "_i" from 10 to 260 step 50 do {
//             _checkPos = [(getPos _unit) getPos [_i, _watchDir], 1] call pl_convert_to_heigth_ASL;

//             _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
//             if (_visP isEqualTo []) then {
//                 _c = _c + 1;
//             };
//         };
//         if (_c >= 5) then {
//             _unit setUnitPos "DOWN";
//         } else {
//             _unit setUnitPos "MIDDLE";
//         };
//     };
// };

pl_assault_position = {
    params ["_group", ["_taskPlanWp", []]];
    private ["_mPos", "_leftPos", "_rightPos", "_markerPhaselineName", "_cords", "_limiter", "_targets", "_markerName", "_wp", "_icon", "_formation", "_attackMode", "_fastAtk", "_tacticalAtk"];

    pl_sweep_area_size = 35;

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};

    if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader _group] call pl_open_tac_forced;
        };
    };

    _markerName = format ["%1sweeper", _group];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor pl_side_color;
    _markerName setMarkerAlpha 0.35;
    _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];

    _arrowMarkerName = format ["%1arrow", _group];
    createMarker [_arrowMarkerName, [0,0,0]];
    _arrowMarkerName setMarkerType "marker_std_atk";
    _arrowMarkerName setMarkerDir 0;
    _arrowMarkerName setMarkerColor pl_side_color;
    _arrowMarkerName setMarkerSize [1.2, 1.2];

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

    _markerPhaselineName = format ["%1atk_phase", _group];
    createMarker [_markerPhaselineName, [0,0,0]];
    _markerPhaselineName setMarkerShape "RECTANGLE";
    _markerPhaselineName setMarkerBrush "Solid";
    _markerPhaselineName setMarkerColor pl_side_color;
    _markerPhaselineName setMarkerAlpha 0.7;
    _markerPhaselineName setMarkerSize [pl_sweep_area_size, 0.5];

    _message = "Select Assault Location <br /><br />
        <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>In Foramtion</t> <br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CQB</t> <br />
        <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>FAST</t> <br />
        <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />";
    hint parseText _message;
    onMapSingleClick {
        pl_sweep_cords = _pos;
        // if (_shift) then {pl_cancel_strike = true};
        pl_attack_mode = "normal";
        if (_shift) then {pl_attack_mode = "tactical"};
        if (_alt) then {pl_attack_mode = "fast"};
        pl_mapClicked = true;
        hintSilent "";
        onMapSingleClick "";
    };

    private _rangelimiterCenter = getPos (leader _group);
    if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};

    player enableSimulation false;

    while {!pl_mapClicked} do {
        // sleep 0.1;
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };

        if (inputAction "MoveForward" > 0) then {pl_sweep_area_size = pl_sweep_area_size + 5; sleep 0.05};
        if (inputAction "MoveBack" > 0) then {pl_sweep_area_size = pl_sweep_area_size - 5; sleep 0.05};
        _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
        if (pl_sweep_area_size >= 120) then {pl_sweep_area_size = 120};
        if (pl_sweep_area_size <= 5) then {pl_sweep_area_size = 5};

        if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
            _markerName setMarkerPos _mPos;

            if (_mPos distance2D (leader _group) > pl_sweep_area_size + 20) then {
                _phaseDir = _mPos getDir _rangelimiterCenter;
                _phasePos = _mPos getPos [pl_sweep_area_size + 10, _phaseDir];
                _markerPhaselineName setMarkerPos _phasePos;
                _markerPhaselineName setMarkerDir _phaseDir;
                _markerPhaselineName setMarkerSize [pl_sweep_area_size + 10, 0.5];

                _arrowPos = _phasePos getPos [15, _phaseDir];
                _arrowDir = _phaseDir - 180;
                _arrowDis = (_rangelimiterCenter distance2D _mPos) / 2;

                _arrowMarkerName setMarkerPos _arrowPos;
                _arrowMarkerName setMarkerDir _arrowDir;
                _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
            } else {
                _arrowMarkerName setMarkerSize [0,0];
                _markerPhaselineName setMarkerSize [0,0];
            };
        };


    };

    player enableSimulation true;

    pl_mapClicked = false;
    deleteMarker _markerBorderName;
    _cords = getMarkerPos _markerName;
    _markerName setMarkerPos _cords;
    _markerName setMarkerBrush "Border";

    _rightPos = _cords getPos [pl_sweep_area_size, 90];
    _leftPos = _cords getPos [pl_sweep_area_size, 270];
    pl_draw_text_array pushBack ["ENY", _leftPos, 0.02, pl_side_color_rgb];
    pl_draw_text_array pushBack ["ENY", _rightPos, 0.02, pl_side_color_rgb];

    _attackMode = pl_attack_mode;
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa";

    if (count _taskPlanWp != 0) then {

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        if (vehicle (leader _group) != leader _group) then {
            if ((leader _group) == commander (vehicle (leader _group)) or (leader _group) == driver (vehicle (leader _group)) or (leader _group) == gunner (vehicle (leader _group))) then {
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
    };

    if (pl_cancel_strike) exitWith {
        pl_cancel_strike = false;
        deleteMarker _markerName;
        deleteMarker _markerPhaselineName;
        pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
     };


    _arrowDir = (leader _group) getDir _cords;
    _arrowDis = ((leader _group) distance2D _cords) / 2;
    _arrowPos = [_arrowDis * (sin _arrowDir), _arrowDis * (cos _arrowDir), 0] vectorAdd (getPos (leader _group));

    switch (_attackMode) do { 
        case "tactical" : {pl_draw_text_array pushBack ["CLEAR", _cords, 0.025, pl_side_color_rgb];}; 
        case "fast" : {pl_draw_text_array pushBack ["SEIZE", _cords, 0.025, pl_side_color_rgb];}; 
        default {pl_draw_text_array pushBack ["SECURE", _cords, 0.025, pl_side_color_rgb];}; 
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
    _group setVariable ["pl_is_attacking", true];

    (leader _group) limitSpeed 15;

    _markerName setMarkerPos _cords;

    {
        _x disableAI "AUTOCOMBAT";
        _x setVariable ["pl_damage_reduction", true];
    } forEach (units _group);

    _wp = _group addWaypoint [_cords, 0];

    // pl_draw_planed_task_array pushBack [_wp, _icon];

    _fastAtk = false;
    _tacticalAtk = false;
    _machinegunner = objNull;

    _formation = formation _group;  
    _group setBehaviour "AWARE";
    _attackMode = "tactical";

    switch (_attackMode) do { 
        case "normal" : {
            (leader _group) limitSpeed 12;
            {
                _x disableAI "AUTOCOMBAT";
                // _x disableAI "FSM";
            } forEach (units _group);
            // (leader _group) setDestination [_cords, "LEADER DIRECT", true];
            _group setFormation "LINE";
            if (_group getVariable ["pl_pos_taken", false]) then {

            };
        }; 
        case "tactical" : {_tacticalAtk = true;}; 
        case "fast" : {_fastAtk = true; _group setSpeedMode "FULL";};
        default {leader _group limitSpeed 12;}; 
    };

    // _group setCombatMode "RED";
    // _group setVariable ["pl_combat_mode", true];

    // fast attack setup
    if (_fastAtk) then {
        _atkDir = (leader _group) getDir _cords;
        _offset = pl_sweep_area_size - (pl_sweep_area_size * 1.5);
        _increment = pl_sweep_area_size / (count (units _group));
        {   
            _rPos = [pl_sweep_area_size * (sin (_atkDir - 180)), pl_sweep_area_size * (cos (_atkDir - 180)), 0] vectorAdd _cords;
            _pos = [_offset * (sin (_atkDir - 90)), _offset * (cos (_atkDir - 90)), 0] vectorAdd _rPos;
            _pos = _pos findEmptyPosition [0, 15, typeOf _x];
            _offset = _offset + _increment;
            _x setUnitPos "UP";
            // _group setCombatMode "RED";
            // _group setVariable ["pl_combat_mode", true];
            [_x, _pos, _cords, _atkDir, 45] spawn pl_bounding_move;
        } forEach (units _group);
    };

    if (_tacticalAtk) then {
        {
            _pos = _cords findEmptyPosition [0, pl_sweep_area_size, typeOf _x];

            [_x, _pos] spawn {
                params ["_unit", "_pos"];
                _unit limitSpeed 12;
                _unit disableAI "AUTOCOMBAT";
                // _unit forceSpeed 12;
                _unit doMove _pos;
                _unit setDestination [_pos, "FORMATION PLANNED", false];
                _reachable = [_unit, _pos, 20] call pl_not_reachable_escape;
                // _unit forceSpeed 12;
                // waitUntil {sleep 0.5; !(alive _unit) or (unitReady _unit) or (_unit getVariable["pl_wia", false] or !((group _unit) getVariable ["onTask", true]))};
                // doStop _unit;
            };
        } forEach (units _group);
    };


    _area = pl_sweep_area_size;
    
    // waitUntil {sleep 0.5; (((leader _group) distance _cords) < (pl_sweep_area_size + 10)) or !(_group getVariable ["onTask", true])};

    // _vics = nearestObjects [_cords, ["Car", "Truck", "Tank"], _area, true];
    _vics = _cords nearEntities [["Car", "Tank", "Truck"], _area];

    private _atkTriggerDistance = 10;
    // if ((count _vics) > 0) then {
    //     _atkTriggerDistance = 40; 
    // };

    // waitUntil {sleep 0.5; (({(_x distance _cords) < (_area + _atkTriggerDistance)} count (units _group)) > 0) or !(_group getVariable ["onTask", true])};
    while {(({(_x distance _cords) < (_area + _atkTriggerDistance)} count (units _group)) == 0) and (_group getVariable ["onTask", true])} do {

        if (_cords distance2D (leader _group) > pl_sweep_area_size + 20) then {
            _phaseDir = (leader _group) getDir _cords;
            _markerPhaselineName setMarkerDir _phaseDir;

            _arrowPos = (getMarkerPos _markerPhaselineName) getPos [15, _phaseDir - 180];
            _arrowDis = ((leader _group) distance2D _cords) / 2;

            _arrowMarkerName setMarkerPos _arrowPos;
            _arrowMarkerName setMarkerDir _phaseDir;
            _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
        } else {
            _arrowMarkerName setMarkerSize [0,0];
            _markerPhaselineName setMarkerSize [0,0];
        };
        sleep 0.1;
    };

    // leader _group limitSpeed 200;
    // _group setSpeedMode "NORMAL";

    if (!(_group getVariable ["onTask", true])) exitWith {
        deleteMarker _markerName;
        deleteMarker _markerPhaselineName;
        pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
        switch (_attackMode) do { 
            case "tactical" : {pl_draw_text_array = pl_draw_text_array - [["CLEAR", _cords, 0.025, pl_side_color_rgb]]}; 
            case "fast" : {pl_draw_text_array = pl_draw_text_array - [["SEIZE", _cords, 0.025, pl_side_color_rgb]]}; 
            default {pl_draw_text_array = pl_draw_text_array - [["SECURE", _cords, 0.025, pl_side_color_rgb]]}; 
        };
        deleteMarker _arrowMarkerName;
        _group setVariable ["pl_is_attacking", false];
        // pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
        {
            _x setVariable ["pl_damage_reduction", false];
        } forEach (units _group);
    };

    _targets = [];
    _allMen = _cords nearObjects ["Man", _area];


    _targetBuildings = [];
    {
        _targets pushBack _x;
        if ([getPos _x] call pl_is_indoor) then {
            _targetBuildings pushBackUnique (nearestBuilding (getPos _x));

            // _m = createMarker [str (random 1), (getPos _x)];
            // _m setMarkerType "mil_dot";

        };
    } forEach (_allMen select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

    _targetBuildings = [_targetBuildings, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;

    missionNamespace setVariable [format ["targetBuildings_%1", _group], _targetBuildings];


    {
        _targets pushBack _x;
    } forEach (_vics select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

    _targets = [_targets, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;



    [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
    sleep 0.1;
    for "_i" from count waypoints _group - 1 to 0 step -1 do {
        deleteWaypoint [_group, _i];
    };

    private _breakingPoint = round (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) / 2);
    
    if ((count _targets) == 0) then {
        private _n = 0;
        private _pos = [_cords, 1, _area, 0, 0, 0, 0] call BIS_fnc_findSafePos;;
        {
            if (_n % 2 == 0) then {
                _pos = [_cords, 1, _area, 0, 0, 0, 0] call BIS_fnc_findSafePos;
            };
            _x doMove _pos;
            _x setDestination [_pos, "FORMATION PLANNED", false];
            _n = _n + 1;
        } forEach (units _group);
        (leader _group) doMove _cords;
        // _group setCombatMode "RED";
        // _group setVariable ["pl_combat_mode", true];
        _time = time + 20 + _area;
        waitUntil {sleep 0.5; !(_group getVariable ["onTask", true]) or (time > _time) or (leader _group) distance2D _cords < 5};
        _group setCombatMode "YELLOW";
        _group setVariable ["pl_combat_mode", false];
        if (_group getVariable ["onTask", true]) then {
            {
                [_x, _cords, 30] spawn pl_find_cover_allways;
            } forEach (units _group);
        };
        _minDelay = time + 20;
        waitUntil {sleep 0.5; !(_group getVariable ["onTask", true]) or (time > _minDelay)};
    }
    else
    {
        sleep 0.2;
        missionNamespace setVariable [format ["targets_%1", _group], _targets];
        private _time = time + 180;

        private _n = 1;
        private _buddy = objNull;
        {
            _x enableAI "AUTOCOMBAT";
            _x enableAI "FSM";
            _x forceSpeed 12;
            [_x, _group, _area, _cords, _attackMode] spawn {
                params ["_unit", "_group", "_area", "_cords", "_attackMode"];
                private ["_movePos", "_target"];

                while {sleep 0.5; (count (missionNamespace getVariable format ["targets_%1", _group])) > 0} do {
                    if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                        _target = {
                            _attacker = _x getVariable ["pl_at_enaged_by", objNull];
                            if (!(_x isKindOf "Man") and alive _x and (isNull _attacker or _attacker == _unit)) exitWith {_x};
                            objNull
                        } forEach (missionNamespace getVariable format ["targets_%1", _group]);
                        if !(isNull _target) then {
                            _target setVariable ["pl_at_enaged_by", _unit];
                            _checkPosArray = [];
                            private _atkDir = _unit getDir _target;
                            private _lineStartPos = (getPos _unit) getPos [(_area + 100)  / 2, _atkDir - 90];
                            _lineStartPos = _lineStartPos getPos [8, _atkDir];
                            private _lineOffsetHorizon = 0;
                            private _lineOffsetVertical = (_target distance2D _unit) / 60;
                            _targetDir = getDir _target;
                            for "_i" from 0 to 60 do {
                                for "_j" from 0 to 60 do { 
                                    _checkPos = _lineStartPos getPos [_lineOffsetHorizon, _atkDir + 90];
                                    _lineOffsetHorizon = _lineOffsetHorizon + ((_area + 100) / 60);

                                    _checkPos = [_checkPos, 1.5] call pl_convert_to_heigth_ASL;

                                    // _m = createMarker [str (random 1), _checkPos];
                                    // _m setMarkerType "mil_dot";
                                    // _m setMarkerSize [0.2, 0.2];

                                    _vis = lineIntersectsSurfaces [_checkPos, aimPos _target, _target, vehicle _target, true, 1, "VIEW"];
                                    if (_vis isEqualTo []) then {
                                            _pointDir = _target getDir _checkPos;
                                            if (_pointDir >= (_targetDir - 75) and _pointDir <= (_targetDir + 75)) then {
                                                // _m setMarkerColor "colorORANGE";
                                            } else {
                                                if (_target distance2D _checkPos >= 30) then {
                                                    _checkPosArray pushBack _checkPos;
                                                    // _m setMarkerColor "colorRED";
                                                };
                                            };
                                        };
                                    };
                                _lineStartPos = _lineStartPos getPos [_lineOffsetVertical, _atkDir];
                                _lineOffsetHorizon = 0;
                            };
                            _lineOffsetVertical = 0;

                            if (count _checkPosArray > 0 and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {

                                switch (_attackMode) do { 
                                    case "tactical" : {_movePos = ([_checkPosArray, [], {_target distance2D _x}, "DESCEND"] call BIS_fnc_sortBy) select 0;}; 
                                    case "normal" : {_movePos = ([_checkPosArray, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;}; 
                                    default {_movePos = ([_checkPosArray, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;}; 
                                };

                                _unit doMove _movePos;
                                _unit setDestination [_movePos, "FORMATION PLANNED", false];
                                pl_at_attack_array pushBack [_unit, _target, objNull];

                                _unit forceSpeed 3;
                                // _unit disableAI "TARGET";
                                _unit disableAI "AUTOTARGET";
                                _unit disableAI "AUTOCOMBAT";
                                _unit setBehaviourStrong "AWARE";
                                _unit setUnitTrait ["camouflageCoef", 0, true];
                                _unit disableAi "AIMINGERROR";
                                _unit setVariable ["pl_engaging", true];
                                _unit setVariable ['pl_is_at', true];

                                // _m = createMarker [str (random 1), _movePos];
                                // _m setMarkerType "mil_dot";
                                // _m setMarkerColor "colorGreen";
                                // _m setMarkerSize [0.7, 0.7];

                                _time = time + ((_unit distance _movePos) / 1.6 + 20);
                                sleep 0.5;
                                waitUntil {sleep 0.5; (time >= _time or unitReady _unit or !alive _unit or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true]) or !alive _target or (count (crew _target) == 0))};
                                _unit reveal [_target, 4];
                                // _unit enableAI "TARGET";
                                doStop _unit;
                                _unit doTarget _target;
                                waitUntil {sleep 0.5; !(_group getVariable ["pl_hold_fire", false]) or !alive _unit or _unit getVariable["pl_wia", false] or !alive _target};
                                _unit doFire _target;
                                _time = 6;
                                waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", false]) or !alive _target};
                                // pl_at_attack_array = pl_at_attack_array - [[_unit, _movePos]];
                                if (alive _target) then {_unit setVariable ['pl_is_at', false]; pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]]; continue};
                                if !(alive _target or !alive _unit or _unit getVariable ["pl_wia", false]) then {_target setVariable ["pl_at_enaged_by", nil]};
                                pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]];
                                _unit setVariable ['pl_is_at', false];
                                _unit setUnitTrait ["camouflageCoef", 1, true];
                                _unit enableAi "AIMINGERROR";
                                _unit setVariable ["pl_engaging", false];
                                _unit enableAI "AUTOTARGET";
                                _unit setBehaviour "AWARE";
                                _group setVariable ["pl_grp_active_at_soldier", nil];
                            } else {
                                _target setVariable ["pl_at_enaged_by", nil];
                            };
                            sleep 1;
                        };
                    };

                    // CQC Building clear
                    // if (_attackMode == "tactical" and count (missionNamespace getVariable format ["targetBuildings_%1", _group]) > 0) then {

                    //     _atkBuilding = (missionNamespace getVariable format ["targetBuildings_%1", _group])#0;
                    //     _target = selectRandom ((missionNamespace getVariable format ["targets_%1", _group]) select {_atkBuilding == nearestBuilding _x});

                    //     // _m = createMarker [str (random 1), getPos _target];
                    //     // _m setMarkerType "mil_dot";
                    //     // _m setMarkerColor "colorGreen";
                    //     // _m setMarkerSize [0.7, 0.7];

                    // } else {
                    // OpenArea Clear
                    // _target = selectRandom (missionNamespace getVariable format ["targets_%1", _group]);
                    _target = (missionNamespace getVariable format ["targets_%1", _group])#([0,1] call BIS_fnc_randomInt);
                    // };
                    if !(isNil "_target") then {
                        if (alive _target and (_target isKindOf "Man")) then {
                            _pos = getPosATL _target;
                            _movePos = _pos vectorAdd [0.5 - (random 1), 0.5 - (random 1), 0];
                            _unit limitSpeed 15;
                            _unit doMove _movePos;
                            _unit setDestination [_movePos, "FORMATION PLANNED", false];
                            _unit lookAt _target;
                            _unit doTarget _target;
                            _reachable = [_unit, _movePos, 20] call pl_not_reachable_escape;
                            _unreachableTimeOut = time + 35;

                            while {(alive _unit) and (alive _target) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true]) and _reachable and (_unreachableTimeOut >= time)} do {
                                _unit forceSpeed 3;

                                sleep 1;
                            };
                            if (time >= _unreachableTimeOut) then {
                                _target enableAI "PATH";
                                _target doMove ((getPos _target) findEmptyPosition [10, 100, typeOf _target]);
                            };
                            if (!alive  _target) then {(missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target)};
                        }
                        else
                        {
                            doStop _unit;
                            if (alive _unit) exitWith {};
                        }
                    };

                    if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};
                };
            };
            sleep 0.1;
        } forEach (units _group);

        waitUntil {sleep 0.5; ({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) <= _breakingPoint or time > _time or !(_group getVariable ["onTask", true]) or ({!alive _x} count (missionNamespace getVariable format ["targets_%1", _group]) == count (missionNamespace getVariable format ["targets_%1", _group]))};
    };


    missionNamespace setVariable [format ["targets_%1", _group], nil];
    _group setFormation _formation;
    _group setVariable ["pl_is_attacking", false];

    // remove Icon form wp
    // pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    {
        _x setVariable ["pl_damage_reduction", false];
        _x limitSpeed 5000;
        _x forceSpeed -1;
    } forEach (units _group);
    _group setCombatMode "YELLOW";
    _group setVariable ["pl_combat_mode", false];
    _group enableAttack false;
    // sleep 8;
    deleteMarker _markerName;
    deleteMarker _arrowMarkerName;
    deleteMarker _markerPhaselineName;
    pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
    pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
    switch (_attackMode) do { 
        case "tactical" : {pl_draw_text_array = pl_draw_text_array - [["CLEAR", _cords, 0.025, pl_side_color_rgb]]}; 
        case "fast" : {pl_draw_text_array = pl_draw_text_array - [["SEIZE", _cords, 0.025, pl_side_color_rgb]]}; 
        default {pl_draw_text_array = pl_draw_text_array - [["SECURE", _cords, 0.025, pl_side_color_rgb]]}; 
    };
    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
        sleep 1;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        if (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) > _breakingPoint) then {
            if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault complete", (groupId _group)]};
            if (pl_enable_map_radio) then {[_group, "...Assault Complete!", 20] call pl_map_radio_callout};
            [_group, "atk_complete", 1] call pl_voice_radio_answer;
            if (_tacticalAtk) then {
                {
                    [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
                } forEach (units _group);
            };
        } else {
            if (pl_enable_beep_sound) then {playSound "radioina"};
            if (pl_enable_map_radio) then {[_group, "...Assault failed!", 20] call pl_map_radio_callout};
            if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault failed", (groupId _group)]};
            // [_group] spawn pl_disengage;
            {
                [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
            } forEach (units _group);
        };
    };
};




pl_mouse_marker_dic = createHashMap;
pl_mouse_marker = [];

pl_create_mouse_marker = {
    params ["_relPos", "_type", "_size", ["_color", pl_side_color_rgb]];

    pl_mouse_marker = [_relPos, _type, _color, _size];

    while {!pl_mapClicked} do {sleep 0.1};
    pl_mouse_marker = [];
};


pl_marker_dic = createHashMap;
pl_create_marker = {
    params ["_pos", "_type", "_size", "_dir", ["_color", pl_side_color_rgb]];

    _key = str (random 2) + (str _pos);

    pl_marker_dic set [_key, [_type, _color, _size, _pos, _dir]];

    _key
};

pl_delete_marker = {
    params ["_key"];

    pl_marker_dic deleteAt _key;
};







pl_draw_marker = {
    params ["_display"];

    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;

        {
            _icon = _y#0;
            _color = _y#1;
            _size = _y#2;
            _pos = _y#3;
            _dir = _y#4;

            _display drawIcon [
                _icon,
                _color,
                _pos,
                _size,
                _size,
                _dir,
                '',
                2
            ];
        } forEach pl_marker_dic;
    "]; // "  
};


[findDisplay 12 displayCtrl 51] call pl_draw_marker;


[getpos player, "plmod\gfx\pl_position", 40, getdir player] call pl_create_marker;

[getpos player, "plmod\gfx\pl_position", 40] spawn pl_create_mouse_marker;


pl_draw_mouse_marker = {
    params ["_display"];

    _display ctrlAddEventHandler ["Draw","

        if !(pl_mouse_marker isEqualTo []) then {
            _display = _this#0;

            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            if !(visibleMap) then {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            _icon = pl_mouse_marker#1;
            _color = pl_mouse_marker#2;
            _size = pl_mouse_marker#3;

            _dir = (pl_mouse_marker#0) getdir _mPos;

            _display drawIcon [
                _icon,
                _color,
                _mPos,
                _size,
                _size,
                _dir,
                '',
                2
            ];
        };
    "]; // "  
};


[findDisplay 12 displayCtrl 51] call pl_draw_mouse_marker;

dyn_place_player = {
    params ["_pos", "_dest"];
    private ["_startPos", "_infGroups", "_vehicles", "_roads", "_road", "_roadsPos", "_dir", "_roadPos"];
    _startPos = getMarkerPos "spawn_start";
    deleteMarker "spawn_start";
    _infGroups = [];
    _vehicles = nearestObjects [_startPos,["LandVehicle"],200];
    {
        if(((_startPos distance2D (leader _x)) < 300) and !(vehicle (leader _x) in _vehicles)) then {
            _infGroups pushBack _x;
        }
    } forEach (allGroups select {side _x isEqualTo playerSide});

    // _roads = _pos nearRoads 300;
    

    _road = [_pos, 300] call BIS_fnc_nearestRoad;
    _usedRoads = [];
    // reverse _vehicles;

    _roadsPos = [];
    _roadBlackList = [];
    for "_i" from 0 to (count _vehicles) - 1 step 1 do {
        // _road = ((roadsConnectedTo _road) - [_road]) select 0;
        // if !(_road in _roadBlackList) then {
        //     _roadBlackList pushBack _road;
        //     _roadPos = getPos _road;
        //     _near = roadsConnectedTo _road;
        //     _near = [_near, [], {(getPos _x) distance2D _dest}, "DESCEND"] call BIS_fnc_sortBy;
        //     _dir = (getPos (_near#0)) getDir (getPos _road);
        //     _roadsPos pushBack [_roadPos, _dir];
        // } else {

        // };
        _road = ([roadsConnectedTo _road, [], {(getpos _x) distance2D _dest}, "DESCEND"] call BIS_fnc_sortBy)#0;

        if (isNil "_road" or isNull _road) then {
            _roadPos = [[[_pos, 150]], ["water"]] call BIS_fnc_randomPos;
            _roadPos = _roadPos findEmptyPosition [0, 50, typeOf (_vehicles#_i)];
            _dir = _pos getDir _dest;
        } else {
            _roadPos = getPos _road;
            _info = getRoadInfo _road;    
            _endings = [_info#6, _info#7];
            _endings = [_endings, [], {_x distance2D _dest}, "ASCEND"] call BIS_fnc_sortBy;
            _dir = (_endings#1) getDir (_endings#0);
        };

        if !((_vehicles#_i) setVehiclePosition [_roadPos, [], 0, "NONE"]) then {
            _roadPos = [[[_pos, 150]], ["water"]] call BIS_fnc_randomPos;
            _roadPos = _roadPos findEmptyPosition [0, 50, typeOf (_vehicles#_i)];
            _dir = _pos getDir _dest;
            (_vehicles#_i) setVehiclePosition [_roadPos, [], 0, "NONE"];
        };

        (_vehicles#_i) setdir _dir;

        sleep 0.1;

    };

    // _roadsPos = [_roadsPos, [], {(_x#0) distance2D _dest}, "ASCEND"] call BIS_fnc_sortBy;

    // for "_i" from 0 to (count _vehicles) - 1 step 1 do {
    //     (_vehicles#_i) setPos ((_roadsPos#_i)#0);
    //     (_vehicles#_i) setdir ((_roadsPos#_i)#1);
    // };
};

pl_disengage = {
    params [["_group", (hcSelected player) select 0], ["_retreatPos", []]];
    private ["_retreatPos", "_enemyDir"];

    private _markerDirName = format ["delayDir%1%2", _group, random 1];
    private _playerCalled = false;

    if (visibleMap or !(isNull findDisplay 2000) and _retreatPos isEqualTo []) then {
        if (visibleMap) then {
            _retreatPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _retreatPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _playerCalled = true;
    };
    private _retreatDir = (getPos (leader _group)) getdir _retreatPos;
// else {
    //     private _allyUnits = allUnits+vehicles select {side _x == playerSide};
    //     _allyUnits = _allyUnits - (units _group);
    //     private _ally = ([_allyUnits, [], {_x distance2D (leader _group)}, "ASCEND"] call BIS_fnc_sortBy)#0;

    //     private _retreatDistance = 150;
    //     if (((leader _group) distance2D _ally) <= 100) then {
    //         _retreatDistance = ((leader _group) distance2D _ally) + 50;
    //     };

    //     if (vehicle (leader _group) != leader _group) then { _retreatDistance = _retreatDistance + 100};

    //     if ([getpos (leader _group)] call pl_is_city) then {_retreatDistance = _retreatDistance / 2};

    //     private _enemy = (leader _group) findNearestEnemy getPos (leader _group);
    //     if (isNull _enemy) then {_enemyDir = getDir (leader _group)} else {_enemyDir = (leader _group) getDir _enemy};
    //     private _allyDir = (leader _group) getDir _ally;

    //     if (_retreatDir == -1) then {_retreatDir = _enemyDir - 180};

    //     _retreatPos = (getPos (leader _group)) getPos [_retreatDistance, _retreatDir];

    //     // createMarker [_markerDirName, _retreatPos];
    //     // _markerDirName setMarkerPos _retreatPos;
    //     // _markerDirName setMarkerType "marker_position_eny";
    //     // _markerDirName setMarkerColor pl_side_color;
    //     // _markerDirName setMarkerDir _enemyDir;
    // };

    // _retreatPos findEmptyPosition [0, 50, typeOf (vehicle (leader _group))];
    
    pl_draw_disengage_array pushBack [_group, _retreatPos];

    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 1;

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
        _group setCombatMode "BLUE";
        _group setVariable ["pl_combat_mode", true];
        _group setSpeedMode "FULL";
        [_group] spawn pl_forget_targets;
        [leader _group, "SmokeShellMuzzle"] call BIS_fnc_fire;

        if (count _injured > 0) then {

            private _dragScripts = []; 
            private _restUnits = _units - _injured - [leader _group];
            private _draggers = [];

            for "_i" from 0 to (count _injured) - 1 do {
                if ((count _restUnits) - 1 >= _i) then {
                    _unit = _injured#_i;
                    _dragger = ([_restUnits, [], {_x distance2D _unit}, "ASCEND"] call BIS_fnc_sortBy)#0;
                    _draggers pushBack _dragger;
                    [_dragger, "SmokeShellMuzzle"] call BIS_fnc_fire;
                    // _injured deleteAt (_injured find _unit);
                    _restUnits deleteAt (_restUnits find _dragger);
                    _script = [_dragger, _unit, _retreatPos, true] spawn pl_injured_drag;
                    _dragScripts pushBack _script;

                    [_dragger, _script, _retreatDir] spawn {
                        params ["_dragger", "_script", "_retreatDir"];

                        waitUntil {sleep 0.5; scriptDone _script or !alive _dragger};

                        if ([_retreatPos] call pl_is_forest or [_retreatPos] call pl_is_city) then {
                            [_unit, 3, _retreatDir] spawn pl_find_cover;
                        } else {
                            [_unit, 10, _retreatDir] spawn pl_find_cover;
                        };
                    };
                };
            };

            {
                [_x, _retreatPos, _retreatDir] spawn {
                    params ["_unit", "_retreatPos", "_retreatDir"];

                    _unit disableAI "AUTOCOMBAT";
                    _unit disableAI "AUTOTARGET";
                    _unit disableAI "TARGET";
                    _unit setUnitTrait ["camouflageCoef", 0.7, true];
                    _unit setVariable ["pl_damage_reduction", true];
                    _unit doMove _retreatPos;
                    // _unit setDestination [_retreatPos, "LEADER DIRECT", true];
                    sleep 1;
                    private _counter = 0;
                    while {alive _unit and ((group _unit) getVariable ["onTask", true])} do {
                        sleep 0.5;
                        _check = [_unit, _retreatPos, _counter] call pl_position_reached_check;
                        if (_check#0) exitWith {};
                        _counter = _check#1;
                    };

                    if ([_retreatPos] call pl_is_forest or [_retreatPos] call pl_is_city) then {
                        [_unit, 3, _retreatDir - 180] spawn pl_find_cover;
                    } else {
                        [_unit, 10, _retreatDir - 180] spawn pl_find_cover;
                    };
                };
            } forEach _restUnits + [leader _group];

            waitUntil {sleep 0.5; (({!(scriptDone _x)} count _dragScripts) <= 0 and ({_x distance2D _retreatPos < 15} count _units) > 0) or ({alive _x} count _units) <= 0 or !(_group getVariable ["onTask", false])};

        } else {

            {
                [_x, _retreatPos, _retreatDir] spawn {
                    params ["_unit", "_retreatPos", "_retreatDir"];

                    _unit disableAI "AUTOCOMBAT";
                    _unit disableAI "AUTOTARGET";
                    _unit disableAI "TARGET";
                    _unit setUnitTrait ["camouflageCoef", 0.7, true];
                    _unit setVariable ["pl_damage_reduction", true];
                    _unit doMove _retreatPos;
                    // _unit setDestination [_retreatPos, "LEADER DIRECT", true];
                    sleep 1;
                    private _counter = 0;
                    while {alive _unit and ((group _unit) getVariable ["onTask", true])} do {
                        sleep 0.5;
                        _check = [_unit, _retreatPos, _counter] call pl_position_reached_check;
                        if (_check#0) exitWith {};
                        _counter = _check#1;
                    };

                    if ([_defPos] call pl_is_forest or [_defPos] call pl_is_city) then {
                        [_unit, 20, _retreatDir - 180] spawn pl_find_cover;
                    } else {
                        [_unit, 15, _retreatDir - 180] spawn pl_find_cover;
                    };
                };
                
            } forEach _units;

            waitUntil {sleep 0.5; ({_x distance2D _retreatPos < 15} count _units) > 0 or ({alive _x} count _units) <= 0 or !(_group getVariable ["onTask", false])};

        };
        _group setCombatMode "YELLOW";
        _group setVariable ["pl_combat_mode", false];


    } else {
        private _vic = vehicle (leader _group);
        [_vic, "SmokeLauncher"] call BIS_fnc_fire;

        _vic doMove _retreatPos;
        _vic setDestination [_retreatPos,"VEHICLE PLANNED" , true];
        waitUntil {sleep 0.5, unitReady _vic or !alive _vic};
        _pos = [(vehicle (leader _group)), _retreatDir - 180] call pl_get_turn_vehicle;
        (vehicle (leader _group)) doMove _pos;
    };

    // sleep 1;
    // if (_group getVariable ["onTask", false] and ({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) >= 2) then {
    //     if !(_playerCalled) then {
    //         [_group, [], _retreatPos, _retreatDir - 180] spawn pl_defend_position;
    //     } else {
    //         [_group] spawn pl_reset;
    //         sleep 0.5;
    //         // {
    //         //     [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
    //         // } forEach (units _group);
    //         if (vehicle (leader _group) == (leader _group)) then {
    //             {
    //                 if (_x getUnitTrait "Medic" and alive _x and !(_x getVariable ["pl_wia", false])) exitWith {[_group] spawn pl_heal_group};
    //             } forEach (units _group);
    //         } else {
    //             _pos = [(vehicle (leader _group)), _retreatDir - 180] call pl_get_turn_vehicle;
    //             (vehicle (leader _group)) doMove _pos;
    //         };
    //     };
    // };
    pl_draw_disengage_array =  pl_draw_disengage_array - [[_group, _retreatPos]];
    deleteMarker _markerDirName;
};

pl_repair = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_group", "_engVic", "_vicPos", "_validEng", "_cords", "_repairTarget", "_toRepairVic", "_markerName", "_markerName2", "_vicGroup", "_smokeGroup", "_vicGroupId", "_icon", "_wp", "_repairTime"];

    if (vehicle (leader _group) != leader _group) then {
        _engVic = vehicle (leader _group);
        _vicType = typeOf _engVic;

        if (!(_engVic getVariable ["pl_is_repair_vehicle", false]) and !(_group getVariable ["pl_is_repair_group", false])) exitWith {hint "Requires Repair Vehicle!"};

        _repairCargo = _engVic getVariable ["pl_repair_supplies", 0];

        if (_repairCargo <= 0) exitWith {hint "No more Supplies left!"};

        if (visibleMap or !(isNull findDisplay 2000)) then {
            pl_show_dead_vehicles = true;
            pl_show_dead_vehicles_pos = getPos _engVic;
            pl_show_damaged_vehicles = true;
            pl_show_vehicles_pos = getPos _engVic;
            hint "Select on MAP";
            onMapSingleClick {
                pl_repair_cords = _pos;
                pl_mapClicked = true;
                pl_show_dead_vehicles = false;
                pl_show_damaged_vehicles = false;
                hint "";
                onMapSingleClick "";
            };
            while {!pl_mapClicked} do {
                if (visibleMap) then {
                    pl_repair_cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    pl_repair_cords = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };
                sleep 0.1;
            };

            pl_mapClicked = false;
            _cords = pl_repair_cords;
            private _distance = 30;
            {
                if ((_cords distance2D (_x #0)) < _distance) then {
                    _repairTarget = _x,
                    _distance = (_cords distance2D (_x #0));
                };
            } forEach pl_destroyed_vics_data;

            if !(isNil "_repairTarget") then {

                _toRepairVic = _repairTarget #1;
                _markerName = _repairTarget #2;
                _vicGroupId = _repairTarget #3;
                _smokeGroup = _repairTarget #4;
                _markerName2 = _repairTarget #5;
            }
            else
            {
                _vics = nearestObjects [_cords, ["Car", "Tank", "Truck"], 30];
                _distance = 30;
                {
                    if ((((_cords distance2D _x) < _distance) and ((getDammage _x) > 0 or !(canMove _x)) and alive _x and (side _x) == playerSide) or ((count (crew _x)) <= 0 and ((getDammage _x) > 0 or !(canMove _x)) and alive _x)) then {
                        _repairTarget = _x,
                        _distance = (_cords distance2D _x);
                    };
                } forEach _vics;
            };

            if (isNil "_repairTarget") exitWith {
                if (pl_enable_chat_radio) then {leader _group sideChat "No damaged Vehicles found"};
                if (pl_enable_map_radio) then {[_group, "...No damaged Vehicles found", 20] call pl_map_radio_callout};
                if (pl_enable_beep_sound) then {playSound "beep"};
            };

            _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa";

            if (count _taskPlanWp != 0) then {

                // add Arrow indicator
                pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

                waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};

                // remove Arrow indicator
                pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

                if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
                _group setVariable ["pl_task_planed", false];
                _group setVariable ["pl_execute_plan", nil];
            };

            if (pl_cancel_strike) exitWith {pl_cancel_strike = false;};


            // if (pl_enable_beep_sound) then {playSound "beep"};
            [_group, "confirm", 1] call pl_voice_radio_answer;
            [_group] call pl_reset;

            sleep 0.5;

            [_group] call pl_reset;

            sleep 0.5;

            _group setVariable ["onTask", true];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", _icon];
            _group setVariable ["pl_is_support", true];

            for "_i" from count waypoints _group - 1 to 0 step -1 do{
                deleteWaypoint [_group, _i];
            };
            if ((typeName _repairTarget) isEqualTo "ARRAY") then {
                _wp = _group addWaypoint [_repairTarget #0, 0];
                _repairTime = time + 90;
            }
            else
            {
                _wp = _group addWaypoint [getPos _repairTarget, 0];
                _repairTime = time + 45;
            };
            // [_group, "maint"] call pl_change_group_icon;
            // add Task Icon to wp
            pl_draw_planed_task_array pushBack [_wp, _icon];
            // if (pl_enable_beep_sound) then {playSound "beep"};
            // leader _group sideChat format ["%1 is moving to damaged vehicle, over", (groupId _group)];
            sleep 4;
            waitUntil {sleep 0.5; !alive _engVic or (unitReady _engVic) or !(_group getVariable ["onTask", true])};
            sleep 2;

            // remove Task Icon from wp and delete wp
            pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];

            // _repairTime = time + 90;
            {
                _x disableAI "PATH";
            } forEach crew _engVic;
            waitUntil {sleep 0.5; time >= _repairTime or !(_group getVariable ["onTask", true])};
            {
                _x enableAI "PATH";
            } forEach crew _engVic;
            sleep 1;
            if ((alive _engVic) and (_group getVariable "onTask") and ({ alive _x } count units _group > 0) and (time >= _repairTime)) then {
                if ((typeName _repairTarget) isEqualTo "ARRAY") then {
                    _idx = pl_destroyed_vics_data find _repairTarget;
                    0 = pl_destroyed_vics_data deleteAt _idx;
                    deleteMarker _markerName;
                    deleteMarker _markerName2;
                    _toRepairVic setDamage 0;
                    _toRepairVic setFuel 1;
                    _toRepairVic setVehicleAmmo 1;
                    _toRepairVic setCaptive false;
                    _toRepairVic allowDamage true;
                    _toRepairVic setVehicleLock "DEFAULT";
                    {
                        deleteVehicle ((_x getVariable "effectEmitter") select 0);  
                        // deleteVehicle ((_x getVariable "effectLight") select 0);
                    } forEach (units _smokeGroup);
                    sleep 0.1;
                    _unitText = getText (configFile >> "CfgVehicles" >> typeOf _toRepairVic>> "textSingular");
                    if (_toRepairVic isKindOf "Tank" or _unitText isEqualTo "APC") then {
                        _vicGroup = createVehicleCrew _toRepairVic;
                        sleep 0.1;
                        _vicGroup setGroupId [_vicGroupId];
                        sleep  0.1;
                        [_vicGroup] spawn pl_set_up_ai;
                        sleep 4;
                        player hcSetGroup [_vicGroup];
                        [_vicGroup] spawn pl_reset;
                        sleep 1;
                        if (pl_enable_beep_sound) then {playSound "radioina"};
                        if (pl_enable_chat_radio) then {(leader _vicGroup) sideChat format ["%1 is back up and fully operational", (groupId _vicGroup)]};
                        if (pl_enable_map_radio) then {[_vicGroup, "...We are back up!", 20] call pl_map_radio_callout};
                    } else {
                        if (pl_enable_beep_sound) then {playSound "radioina"};
                        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Repairs Completeted", (groupId _group)]};
                        if (pl_enable_map_radio) then {[_group, "...Repairs Completeted", 20] call pl_map_radio_callout};
                    };

                    _group setVariable ["onTask", false];
                    _group setVariable ["setSpecial", false];
                    // _group setVariable ["MARTA_customIcon", nil];
                    _repairCargo = _repairCargo - 2;
                }
                else
                {
                    _repairTarget setDamage 0;
                    _repairTarget setFuel 1;
                    _group setVariable ["onTask", false];
                    _group setVariable ["setSpecial", false];
                    // _group setVariable ["MARTA_customIcon", nil];
                    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Repairs Completeted", (groupId _group)]};
                    if (pl_enable_map_radio) then {[_group, "...Repairs Completeted", 20] call pl_map_radio_callout};
                    _repairCargo = _repairCargo - 1;
                };
                
                _engVic setVariable ["pl_repair_supplies", _repairCargo];
                _group setVariable ["pl_is_support", false];
            };
        };
    }; 
};

pl_cas = {
    params ["_key"];
    private ["_sortiesCost", "_cords", "_dir", "_support", "_casType", "_plane", "_cs", "_markerName"];

    switch (_key) do { 
        case 1 : {_sortiesCost = 1}; 
        case 2 : {_sortiesCost = 2};
        case 3 : {_sortiesCost = 4}; 
        case 4 : {_sortiesCost = 5}; 
        default {_sortiesCost = 1}; 
    };

    if (visibleMap) then {

        if (pl_sorties < _sortiesCost) exitWith {hint "Not enough Sorties Left"};

        hintSilent "";
        // hint "Select STRIKE location on MAP (SHIFT + LMB to cancel)";
        _message = "Select STRIKE Location <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;

        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;

        onMapSingleClick {
            pl_cas_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {sleep 0.1;};
        pl_mapClicked = false;
        // hint "Select APPROACH Vector for Strike (SHIFT + LMB to cancel)";
        _message = "Select APPROACH Vector <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;

        sleep 0.1;
        _cords = pl_cas_cords;
        _markerName = format ["cas%1", _key];
        createMarker [_markerName, _cords];
        _markerName setMarkerType "mil_arrow2";
        _markerName setMarkerColor "colorRED";
        if (pl_cancel_strike) exitWith {};

        onMapSingleClick {
            pl_cas_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _dir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _markerName setMarkerDir _dir;
        };
        pl_mapClicked = false;

    }
    else
    {
        _cords =  screenToWorld [0.5,0.5];
        _dir = player getDir _cords;
        _markerName = format ["cas%1", _key];
        createMarker [_markerName, _cords];
        _markerName setMarkerType "mil_arrow2";
        _markerName setMarkerColor "colorRED";
        _markerName setMarkerDir _dir;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};
    pl_sorties = pl_sorties - _sortiesCost;

    switch (_key) do { 
        case 1 : {pl_gun_enabled = 0, _casType = 0, _plane = pl_cas_plane_1, _cs = 'Viper 1'};
        case 2 : {pl_gun_rocket_enabled = 0, _casType = 2, _plane = pl_cas_plane_1, _cs = 'Viper 4'};
        case 3 : {pl_cluster_enabled = 0,  _casType = 3, _plane = pl_cas_plane_3, _cs = 'Black Knight 2'}; 
        case 4 : {pl_jdam_enabled = 0,  _casType = 3, _plane = pl_cas_plane_2, _cs = 'Stroke 3'};
        default {sleep 0.1}; 
    };
    sleep 1;
    _group = createGroup [playerSide, true];
    _support = _group createUnit ["ModuleCAS_F", _cords, [],0 , ""];
    
    _support setVariable ["vehicle", _plane];
    _support setVariable ["type", _casType];

    if (pl_enable_beep_sound) then {playSound "beep"};
    [playerSide, "HQ"] sideChat "Strike Aircraft on the Way!";
    sleep 1;
    _support setDir _dir;
    sleep 5;
    _vicGroup = group (driver (_support getVariable "plane"));
    if (isNil "_vicGroup") exitWith {
        deleteVehicle _support;
        hint "Defined Plane Class not supported!";
        deleteMarker _markerName;
    };
    _vicGroup setGroupId [_cs];
    _vicGroup setVariable ["pl_not_addalbe", true];
    waitUntil {sleep 0.5; _support isEqualTo objNull};
    deleteMarker _markerName;
    sleep 8;
    switch (_key) do {
        case 1 : {
        pl_cas_gun_cd = time + 120;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        // [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 2 MINUTES, over", _cs];
        waitUntil {sleep 1; time > pl_cas_gun_cd};
        pl_gun_enabled = 1;
     }; 
        case 2 : {
        pl_cas_gun_rocket_cd = time + 240;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        // [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 4 MINUTES, over", _cs];
        waitUntil {sleep 1; time > pl_cas_gun_rocket_cd};
        pl_gun_rocket_enabled = 1;
     }; 
        case 3 : {
        pl_cas_cluster_cd = time + 480;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        // [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 8 MINUTES, over", _cs];
        waitUntil {sleep 1; time > pl_cas_cluster_cd};
        pl_cluster_enabled = 1;
    };
        case 4 : {
        pl_cas_jdam_cd = time + 720;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        // [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 12 MINUTES, over", _cs];
        waitUntil {sleep 1; time > pl_cas_jdam_cd};
        pl_jdam_enabled = 1;
    };
        default {pl_cas_cd = time + 240;}; 
    };
    if (pl_enable_beep_sound) then {playSound "beep"};
    [playerSide, "HQ"] sideChat format ["%1, is back on Station", _cs];
};

// pl_arty_mission = "SUP";

// pl_fire_on_map_arty = {
//     private ["_mpos", "_cords", "_ammoTypes", "_ammoType", "_eh", "_markerName", "_centerMarkerName", "_eta", "_battery", "_guns", "_volleys", "_isHc", "_ammoTypestr", "_ammoType"];

//     // if (pl_arty_ammo < pl_arty_rounds) exitWith {
//     //     // if (pl_enable_beep_sound) then {playSound "beep"};
//     //     hint "Not enough ammunition left!";
//     // };

//     _markerName = createMarker [str (random 4), [0,0,0]];
//     _markerName setMarkerColor pl_side_color;
//     _markerName setMarkerShape "ELLIPSE";
//     _markerName setMarkerBrush "Border";
//     // _markerName setMarkerAlpha 1;
//     _markerName setMarkerSize [pl_arty_dispersion, pl_arty_dispersion];

//     switch (pl_arty_round_type) do { 
//         case 1 : {_ammoTypestr = "HE"}; 
//         case 2 : {_ammoTypestr = "SMK"}; 
//         case 3 : {_ammoTypestr = "IL"};
//         case 4 : {_ammoTypestr = "GUI"};
//         case 5 : {_ammoTypestr = "MINE"};
//         case 6 : {_ammoTypestr = "CLT"};
//         default {_ammoTypestr = "HE"}; 
//     };

//     _markerName setMarkerAlpha 0.4;
//     _centerMarkerName = createMarker [str (random 4), [0,0,0]];
//     _centerMarkerName setMarkerType "mil_destroy";
//     _centerMarkerName setMarkerText format ["%1 %4 / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, _ammoTypestr];
//     _centerMarkerName setMarkerColor pl_side_color;

//     if (visibleMap or !(isNull findDisplay 2000)) then {

//         _message = "Select STRIKE Location <br /><br />
//         <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
//         hint parseText _message;

//         pl_cancel_strike = false;
//         onMapSingleClick {
//             pl_arty_cords = _pos;
//             pl_mapClicked = true;
//             if (_shift) then {pl_cancel_strike = true};
//             hint "";
//             onMapSingleClick "";
//         };
//         while {!pl_mapClicked} do {
//             if (visibleMap) then {
//                 _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//             } else {
//                 _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
//             };
//             _markerName setMarkerPos _mPos;
//             _centerMarkerName setMarkerPos _mPos;
//         };
//         pl_mapClicked = false;
//     }
//     else
//     {
//         pl_arty_cords = screenToWorld [0.5,0.5];
//         _markerName setMarkerPos pl_arty_cords;
//         _centerMarkerName setMarkerPos pl_arty_cords;
//     };


//     _cords = pl_arty_cords;
//     _battery = pl_arty_groups#pl_active_arty_group_idx;

//     _isHc = false;
//     if (hcLeader _battery == player) then {
//         _isHc = true;
//         player hcRemoveGroup _battery;
//         if (_battery getVariable "setSpecial") then {
//             _battery setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"];
//         };
//     };

//     _guns = _battery getVariable ["pl_active_arty_guns", []];
//     if (_guns isEqualTo []) exitWith {Hint "No active Guns"};

//     _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf (_guns#0) >> "Turrets" >> "MainTurret" >> "magazines")) select 0;
//     _eta = (_guns#0) getArtilleryETA [_cords, _ammoType];
//     if (_eta == -1) exitWith {
//         hint "Not in Range";
//         deleteMarker _markerName;
//         deleteMarker _centerMarkerName;
//     };

//     _eta = _eta + 5;

//     // [_eta, _centerMarkerName, _ammoTypestr] spawn {
//     //     params ["_eta", "_centerMarkerName", "_ammoTypestr"];
//     //     _time = time +_eta;
//     //     while {time < _time} do {
//     //         _centerMarkerName setMarkerText format ["%1 %5 / %2 m / %3 s ETA: %4s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, round (_time - time), _ammoTypestr];
//     //         sleep 1;
//     //     };
//     //     _centerMarkerName setMarkerText format ["%1 %4 / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, _ammoTypestr];;
//     // };

//     if (pl_enable_beep_sound) then {playSound "beep"};
//     if (pl_enable_chat_radio) then {(gunner (_guns#0)) sideChat format ["...Fire Mission Confimed ETA: %1s", round _eta]};
//     if (pl_enable_map_radio) then {[group (gunner (_guns#0)), format ["...Fire Mission Confimed ETA: %1s", round _eta], 25] call pl_map_radio_callout};

//     _volleys = round (pl_arty_rounds / (count _guns));
//     _dispersion = pl_arty_dispersion;
//     _delay = pl_arty_delay;
//     _missionType = pl_arty_mission;

//     _weapon = (getArray (configfile >> "CfgVehicles" >> typeOf (_guns#0) >> "Turrets" >> "MainTurret" >> "weapons"))#0;
//     // _allMagazines = getArray (configfile >> "CfgWeapons" >> _weapon >> "Magazines");
//     _allMagazines = magazines (_guns#0) + [currentMagazine (_guns#0)];

//     // player sideChat (str _allMagazines);

//     _ammoType = "";

//     switch (pl_arty_round_type) do { 
//         case 1 : {_ammoTypes = _allMagazines select {["he", _x] call BIS_fnc_inString}}; 
//         case 2 : {_ammoTypes = (_allMagazines select {["smoke", _x] call BIS_fnc_inString}) + (_allMagazines select {["smk", _x] call BIS_fnc_inString})}; 
//         case 3 : {_ammoTypes = _allMagazines select {["illum", _x] call BIS_fnc_inString}};
//         case 4 : {_ammoTypes = _allMagazines select {["guid", _x] call BIS_fnc_inString}};
//         case 5 : {_ammoTypes = _allMagazines select {["mine", _x] call BIS_fnc_inString}};
//         case 6 : {_ammoTypes = (_allMagazines select {["cluster", _x] call BIS_fnc_inString}) + _allMagazines select {["icm", _x] call BIS_fnc_inString}};
//         default {_ammoType = (currentMagazine (_guns#0))}; 
//     };

//     if ((count _ammoTypes) > 0) then {
//         _ammoType = ([_ammoTypes, [], {parseNumber _x}, "DESCEND"] call BIS_fnc_sortBy)#0;
//     };

//     if (_ammoType isEqualTo "") exitWith {format ["Battery cant Fire %1 Rounds", _ammoTypestr]};

//     // private _availableMagazinesLeader = magazinesAmmo [_guns#0, true];
//     // {
//     //     private _availableMagazines = magazinesAmmo [_x, true];

//     //     for "_i" from 0 to (count _availableMagazinesLeader) - 1 do{
//     //         if (((_availableMagazinesLeader#_i)#0) isEqualTo ((_availableMagazines#_i)#0)) then {
//     //             (_availableMagazinesLeader#_i) set [1, ((_availableMagazinesLeader#_i)#1) + ((_availableMagazines#_i)#1)]
//     //         };
//     //     }
//     // } forEach (_guns - [_guns#0]);

//     // private _ammoAmount = 0;

//     // player sideChat (str _availableMagazinesLeader);
//     // {
//     //     if (_ammoType isEqualTo (_x#0)) then {
//     //         _ammoAmount = _x#1;
//     //     };
//     // } forEach _all;

//     _allAmmo = [_guns] call pl_get_arty_ammo;

//     private _ammoAmount = _allAmmo get _ammoType;

//     if (_ammoAmount <= 0) exitWith {hint "No Ammo Left"};

//     sleep 1;

//     if !(_ammoType isEqualTo (currentMagazine (_guns#0))) then {
//         // Force Reolad Hack
//         {

//             // player sideChat _ammoType;
//             // player sideChat (currentMagazine _x);

//             // _x doArtilleryFire [_cords, _ammoType, 1];

//             _x loadMagazine [[0], _weapon, _ammoType];
//             _x setWeaponReloadingTime [gunner _x, _weapon, 0];
//             // sleep 1;
//         } forEach _guns;

//         sleep 1;

//         if (((weaponState [_guns#0, [0]])#6) > 0) then {

//                 _reloadMarker = createMarker [str (random 4), getPos (_guns#0)];
//                 _reloadMarker setMarkerType "mil_circle";
//                 _reloadMarker setMarkerText format ["%1 %", round ((1 - ((weaponState [_guns#0, [0]])#6)) * 100)];
//                 _reloadMarker setMarkerColor pl_side_color;

//             waitUntil {sleep 1; _reloadMarker setMarkerText format ["Reload: %1 %", round ((1 - ((weaponState [_guns#0, [0]])#6)) * 100)];; ((weaponState [_guns#0, [0]])#6) <= 0};

//             deleteMarker _reloadMarker;

//             sleep 5;
//         };

//     };

//     [_eta, _centerMarkerName, _ammoTypestr] spawn {
//         params ["_eta", "_centerMarkerName", "_ammoTypestr"];
//         _time = time +_eta;
//         while {time < _time} do {
//             _centerMarkerName setMarkerText format ["%1 %5 / %2 m / %3 s ETA: %4s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, round (_time - time), _ammoTypestr];
//             sleep 1;
//         };
//         _centerMarkerName setMarkerText format ["%1 %4 / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, _ammoTypestr];;
//     };

//     switch (_missionType) do { 
//         case "SUP" : {

//             for "_i" from 1 to _volleys do {
//                 {
//                     _firePos = [[[_cords, _dispersion + 20]],[]] call BIS_fnc_randomPos;
//                     _x setVariable ["pl_waiting_for_fired", true];
//                     _x doArtilleryFire [_firePos, _ammoType, 1];
//                     _eh = _x addEventHandler ["Fired", {
//                         params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
//                         _unit setVariable ["pl_waiting_for_fired", false];
//                     }];
//                     // sleep 1;
//                 } forEach _guns;


//                 _MaxDelay = time + 40;
//                 _minDelay = time + _delay;
//                 waitUntil {({_x getVariable ["pl_waiting_for_fired", true]} count _guns == 0 and time >= _minDelay) or time >= _MaxDelay};
//                 _centerMarkerName setMarkerColor "colorOrange";
//                 // waitUntil {time >= _minDelay or time >= _MaxDelay};

//                 // pl_arty_ammo = pl_arty_ammo - 1;
//             };

//             {
//                 // _x addMagazineTurret [_ammoType, [-1]];
//                 _x removeEventHandler ["Fired", _eh];
//                 // _x setVehicleAmmo 1;
//             } forEach _guns;
//         }; 
//         case "ANI" : {
//             {
//                 _firePos = [[[_cords, 30]],[]] call BIS_fnc_randomPos;
//                 _x doArtilleryFire [_firePos, _ammoType, _volleys];
//                 sleep 1;
//             } forEach _guns;
//             _centerMarkerName setMarkerColor "colorOrange";
//         }; 
//         case "BLK" : {
            
//         }; 
//         default {}; 
//     };
    

//     if (_isHc) then {
//         player hcSetGroup [_battery];
//         if (_battery getVariable "setSpecial") then {
//             _battery setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"];
//         };
//     };

//     sleep (_eta + 20);
//     deleteMarker _markerName;
//     deleteMarker _centerMarkerName;


// };

// pl_show_on_map_arty_menu = {
// call compile format ["
// pl_on_map_arty_menu = [
//     ['Artillery',true],
//     ['Call Artillery Strike', [2], '', -5, [['expression', '[] spawn pl_fire_on_map_arty']], '1', '1'],
//     ['', [], '', -5, [['expression', '']], '1', '0'],
//     ['Choose Battery:   %5', [3], '', -5, [['expression', '[] spawn pl_show_battery_menu']], '1', '1'],
//     ['', [], '', -5, [['expression', '']], '1', '0'],
//     ['Mission:     %7', [4], '#USER:pl_arty_mission_menu', -5, [['expression', '']], '1', '1'],
//     ['Type:          %6', [5], '#USER:pl_arty_round_type_menu_on_map', -5, [['expression', '']], '1', '1'],
//     ['Rounds:        %1', [6], '#USER:pl_arty_round_menu_on_map', -5, [['expression', '']], '1', '1'],
//     ['Dispersion:    %2 m', [7], '#USER:pl_arty_dispersion_menu_on_map', -5, [['expression', '']], '1', '1'],
//     ['Min Delay:     %3 s', [8], '#USER:pl_arty_delay_menu_on_map', -5, [['expression', '']], '1', '1'],
//     ['', [], '', -5, [['expression', '']], '1', '0']
// ];", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, pl_arty_enabled, groupId (pl_arty_groups#pl_active_arty_group_idx), [pl_arty_round_type] call pl_get_type_str, pl_arty_mission];
// showCommandingMenu "#USER:pl_on_map_arty_menu";
// };


// pl_arty_mission_menu = 
// [
//     ['Fire Mission',true],
//     ['SUPPRESS', [2], '', -5, [['expression', 'pl_arty_mission = "SUP"; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
//     ['ANIHILATE', [3], '', -5, [['expression', 'pl_arty_mission = "ANI"; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
//     ['BLOCK', [4], '', -5, [['expression', 'pl_arty_mission = "BLK"; [] spawn pl_show_on_map_arty_menu']], '1', '1']
// ];

// pl_get_type_str = {
//     params ["_type"];

//     private _return = "";
//     switch (_type) do { 
//           case 1 : {_return = "HE"}; 
//           case 2 : {_return = "SMOKE"}; 
//           case 3 : {_return = "ILLUM"};
//           case 4 : {_return = "GUIDED"};
//           case 5 : {_return = "MINE"};
//           case 6 : {_return = "CLUSTER"};
//           default {};
//       };
//     _return
// };

// pl_get_arty_ammo = {
//     params ["_guns"];

//     private _availableMagazinesLeader = magazinesAmmo [_guns#0, true];
//     {
//         private _availableMagazines = magazinesAmmo [_x, true];

//         for "_i" from 0 to (count _availableMagazinesLeader) - 1 do {
//             if (((_availableMagazinesLeader#_i)#0) isEqualTo ((_availableMagazines#_i)#0)) then {
//                 (_availableMagazinesLeader#_i) set [1, ((_availableMagazinesLeader#_i)#1) + ((_availableMagazines#_i)#1)]
//             };
//         }
//     } forEach (_guns - [_guns#0]);

//     private _allAmmoCount = createHashMap;

//     {
//         if !((_x#0) in _allAmmoCount) then {
//             _allAmmoCount set [_x#0, _x#1];
//         } else {
//             _a = _allAmmoCount get (_x#0);
//             _allAmmoCount set [_x#0, _a + (_x#1)];
//         };
//     } forEach _availableMagazinesLeader;

//     _allAmmoCount
// };

// pl_get_arty_type_to_name = {
//     params ["_typeName"];

//         private _r = {
//             if ([_x#0, _typeName] call BIS_fnc_inString) exitWith {_x#1};
//             ""
//         } forEach [["he", "HE"], ["smoke", "SMOKE"], ["smk", "SMOKE"], ["il", "ILLUM"], ["illum", "ILLUM"], ["guid", "GUIDED"], ["gui", "GUIDED"], ["cluster", "CLUSTER"], ["icm", "CLUSTER"], ["mine", "MINE"]];
//     _r
// };

// pl_arty_round_type_menu_on_map = 
// [
//     ['Type',true],
//     ['HE', [2], '', -5, [['expression', 'pl_arty_round_type = 1; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
//     ['SMOKE', [3], '', -5, [['expression', 'pl_arty_round_type = 2; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
//     ['ILLUM', [4], '', -5, [['expression', 'pl_arty_round_type = 3; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
//     ['GUIDED', [5], '', -5, [['expression', 'pl_arty_round_type = 4; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
//     ['MINE', [6], '', -5, [['expression', 'pl_arty_round_type = 5; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
//     ['CLUSTER', [7], '', -5, [['expression', 'pl_arty_round_type = 6; [] spawn pl_show_on_map_arty_menu']], '1', '1']
// ];

// // pl_show_battery_ammo_status = {
// //     private ["_menuScript"];
// //     _menuScript = "pl_arty_round_type_menu_on_map = [['Artillery Batteries',true],";
// //     player sideChat (str count _ammo);

// //     _n = 0;
// //     {
// //         _text = format ["%1 (%2)", [_x#0] call pl_get_arty_type_to_name, _x#1];
// //         _menuScript = _menuScript + format ["[parseText '%1', [%2], '', -5, [['expression', 'pl_arty_round_type = %3; [] spawn pl_show_on_map_arty_menu']], '1', '1'],", _text, _n + 2, _n];
// //         _n = _n + 1;
// //     } forEach _ammo;
// //     _menuScript = _menuScript + "['', [], '', -5, [['expression', '']], '0', '0']]";

// //     call compile _menuScript;
// //     showCommandingMenu "#USER:pl_arty_round_type_menu_on_map";
// // };
// // "gm_mlrs_110mm_launcher"
// // magazines[] = {"gm_36Rnd_mlrs_110mm_he_dm21","gm_36Rnd_mlrs_110mm_icm_dm602","gm_36Rnd_mlrs_110mm_mine_dm711","gm_36Rnd_mlrs_110mm_smoke_dm15"};

// // _allMagazines = getArray (configfile >> "CfgWeapons" >> "gm_mlrs_110mm_launcher" >> "Magazines");


// _weapon = (getArray (configfile >> "CfgVehicles" >> typeOf this >> "Turrets" >> "MainTurret" >> "weapons"))#0;
// _allMagazines = getArray (configfile >> "CfgWeapons" >> _weapon >> "Magazines");

// {
//     this removeMagazines _x;
// } forEach _allMagazines;

// this addMagazine ["gm_36Rnd_mlrs_110mm_he_dm21", 36]; 
// this addMagazine ["gm_36Rnd_mlrs_110mm_icm_dm602", 36]; 
// this addMagazine ["gm_36Rnd_mlrs_110mm_mine_dm711", 36];

// // getText (configFile >> "CfgAmmo" >> "gm_1Rnd_155mm_he_dm21" >> "displayName");

//     // ["gm_1Rnd_155mm_he_dm21","gm_1Rnd_155mm_he_dm111","gm_1Rnd_155mm_icm_dm602","gm_1Rnd_155mm_smoke_dm105","gm_1Rnd_155mm_illum_dm106","gm_1Rnd_155mm_he_m107","gm_1Rnd_155mm_he_m795","gm_1Rnd_155mm_smoke_m116","gm_1Rnd_155mm_smoke_m110","gm_1Rnd_155mm_illum_m485","gm_10Rnd_155mm_he_dm21","gm_10Rnd_155mm_he_dm111","gm_10Rnd_155mm_icm_dm602","gm_10Rnd_155mm_smoke_dm105","gm_10Rnd_155mm_illum_dm106","gm_10Rnd_155mm_he_m107","gm_10Rnd_155mm_he_m795","gm_10Rnd_155mm_smoke_m116","gm_10Rnd_155mm_smoke_m110","gm_10Rnd_155mm_illum_m485","gm_20Rnd_155mm_he_dm21","gm_20Rnd_155mm_he_dm111","gm_20Rnd_155mm_icm_dm602","gm_20Rnd_155mm_smoke_dm105","gm_20Rnd_155mm_illum_dm106","gm_20Rnd_155mm_he_m107","gm_20Rnd_155mm_he_m795","gm_20Rnd_155mm_smoke_m116","gm_20Rnd_155mm_smoke_m110","gm_20Rnd_155mm_illum_m485","gm_4Rnd_155mm_he_dm21","gm_4Rnd_155mm_he_dm111","gm_4Rnd_155mm_icm_dm602","gm_4Rnd_155mm_smoke_dm105","gm_4Rnd_155mm_illum_dm106","gm_4Rnd_155mm_he_m107","gm_4Rnd_155mm_he_m795","gm_4Rnd_155mm_smoke_m116","gm_4Rnd_155mm_smoke_m110","gm_4Rnd_155mm_illum_m485"]

// // [["gm_20Rnd_155mm_he_dm21",60],["gm_4Rnd_155mm_smoke_dm105",12],["gm_4Rnd_155mm_illum_dm106",12],["gm_1Rnd_155mm_he_dm21",3],["gm_1Rnd_155mm_he_dm111",3],
// // ["gm_1Rnd_155mm_icm_dm602",3],["gm_1Rnd_155mm_smoke_dm105",3],["gm_1Rnd_155mm_illum_dm106",3],["gm_1Rnd_155mm_he_m107",3],["gm_1Rnd_155mm_he_m795",3],
// // ["gm_1Rnd_155mm_smoke_m116",3],["gm_1Rnd_155mm_smoke_m110",3],["gm_1Rnd_155mm_illum_m485",3],["gm_10Rnd_155mm_he_dm21",30],["gm_10Rnd_155mm_he_dm111",30],["gm_10Rnd_155mm_icm_dm602",30],
// // ["gm_10Rnd_155mm_smoke_dm105",30],["gm_10Rnd_155mm_illum_dm106",30],["gm_10Rnd_155mm_he_m107",30],["gm_10Rnd_155mm_he_m795",30],["gm_10Rnd_155mm_smoke_m116",30],
// // ["gm_10Rnd_155mm_smoke_m110",30],["gm_10Rnd_155mm_illum_m485",30],["gm_20Rnd_155mm_he_dm21",60],["gm_20Rnd_155mm_he_dm111",60],["gm_20Rnd_155mm_icm_dm602",60],
// // ["gm_20Rnd_155mm_smoke_dm105",60],["gm_20Rnd_155mm_illum_dm106",60],["gm_20Rnd_155mm_he_m107",60],["gm_20Rnd_155mm_he_m795",60],["gm_20Rnd_155mm_smoke_m116",60],
// // ["gm_20Rnd_155mm_smoke_m110",60],["gm_20Rnd_155mm_illum_m485",60],["gm_4Rnd_155mm_he_dm21",12],["gm_4Rnd_155mm_he_dm111",12],["gm_4Rnd_155mm_icm_dm602",12],
// // ["gm_4Rnd_155mm_smoke_dm105",12],["gm_4Rnd_155mm_illum_dm106",12],["gm_4Rnd_155mm_he_m107",12],["gm_4Rnd_155mm_he_m795",4],["gm_4Rnd_155mm_smoke_m116",12],
// // ["gm_4Rnd_155mm_smoke_m110",12],["gm_4Rnd_155mm_illum_m485",12]]

// // this addMagazine ["gm_20Rnd_155mm_he_dm21", 20];
// // this addMagazine ["gm_20Rnd_155mm_he_dm21", 20];
// // this addMagazine ["gm_20Rnd_155mm_smoke_m116", 20];

// // [["gm_20Rnd_155mm_he_dm21",40],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_he_dm21",10],["gm_20Rnd_155mm_smoke_m116",10]];

// // [["gm_20Rnd_155mm_he_dm21",40],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_he_dm21",10],["gm_20Rnd_155mm_smoke_m116",10]]

// // [["gm_36Rnd_mlrs_110mm_he_dm21",72],["gm_36Rnd_mlrs_110mm_he_dm21",10],["gm_36Rnd_mlrs_110mm_icm_dm602",10],["gm_36Rnd_mlrs_110mm_mine_dm711",10],["gm_36Rnd_mlrs_110mm_smoke_dm15",10]]

// // this addMagazine ["gm_36Rnd_mlrs_110mm_he_dm21", 36];
// // this addMagazine ["gm_36Rnd_mlrs_110mm_icm_dm602", 36];
// // this addMagazine ["gm_36Rnd_mlrs_110mm_mine_dm711", 36];
// // [["gm_20Rnd_155mm_he_dm21",40],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_he_dm21",40],["gm_20Rnd_155mm_he_dm21",40],["gm_20Rnd_155mm_smoke_m116",40]]
// // [["gm_20Rnd_155mm_he_dm21",120],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_smoke_m116",40]]

// // [["gm_20Rnd_155mm_he_dm21",120],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_smoke_m116",36]]
// // [["gm_20Rnd_155mm_he_dm21",120],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_smoke_m116",40]] apply {[[_x#0] call pl_get_arty_type_to_name, _x#1]};

// pl_support_status = {
//     _gunCd = "ON STATION";
//     _gunColor = "#66ff33";
//     _gunRocketCd = "ON STATION";
//     _gunRocketColor = "#66ff33";
//     _clusterCd = "ON STATION";
//     _clusterColor = "#66ff33";
//     _jdamCd = "ON STATION";
//     _jdamColor = "#66ff33";
//     _sadPlaneCd = "ON STATION";
//     _sadPlaneColor = "#66ff33";
//     _sadHeloCd = "ON STATION";
//     _sadHeloColor = "#66ff33";
//     _sadUavCd = "ON STATION";
//     _sadUavColor = "#66ff33";
//     _sadMedevacCd = "ON STATION";
//     _sadMedevacColor = "#66ff33";
//     _time = time + 8;
//     while {time < _time} do {
//         if (time < pl_cas_cd) then {
//             _gunCd = format ["%1s", round (pl_cas_cd - time)];
//             _gunColor = '#b20000';
//         };
//         if (time < pl_cas_cd) then {
//             _gunRocketCd = format ["%1s", round (pl_cas_cd - time)];
//             _gunRocketColor = '#b20000';
//         };
//         if (time < pl_cas_cd) then {
//             _clusterCd = format ["%1s", round (pl_cas_cd - time)];
//             _clusterColor = '#b20000';
//         };
//         if (time < pl_cas_cd) then {
//             _jdamCd = format ["%1s", round (pl_cas_cd - time)];
//             _jdamColor = '#b20000';
//         };
//         if (time < pl_cas_cd) then {
//             _sadPlaneCd = format ["%1s", round (pl_cas_cd - time)];
//             _sadPlaneColor = '#b20000';
//         };
//         if (time < pl_cas_cd) then {
//             _sadHeloCd = format ["%1s", round (pl_cas_cd - time)];
//             _sadHeloColor = '#b20000';
//         };
//         if (time < pl_uav_sad_cd) then {
//             _sadUavCd = format ["%1s", round (pl_uav_sad_cd - time)];
//             _sadUavColor = '#b20000';
//         };
//         if (time < pl_medevac_sad_cd) then {
//             _sadMedevacCd = format ["%1s", round (pl_medevac_sad_cd - time)];
//             _sadMedevacColor = '#b20000';
//         };
//         _batteryRounds = [(pl_arty_groups#pl_active_arty_group_idx) getVariable ["pl_active_arty_guns", []]] call pl_get_arty_ammo;

//         _batteryRoundsFinal = createHashMap;
//         {
//             _batteryRoundsFinal set [[_x] call pl_get_arty_type_to_name, _y];
//         } forEach _batteryRounds;
//         // _batteryRounds = _batteryRounds apply {[_x] call pl_get_arty_type_to_name};
//          _message = format ["
//             <t color='#004c99' size='1.3' align='center' underline='1'>CAS</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Sorties:</t><t color='#00ff00' size='0.8' align='right'>%10</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Viper 1 (Gun Run)</t><t color='%1' size='0.8' align='right'>%2</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Viper 4 (Attack Run)</t><t color='%3' size='0.8' align='right'>%4</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Black Knight 1-2 (Cluster)</t><t color='%5' size='0.8' align='right'>%6</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Stroke 3 (JDAM)</t><t color='%7' size='0.8' align='right'>%8</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Reaper 1 (SAD Plane)</t><t color='%11' size='0.8' align='right'>%12</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Black Jack 4 (SAD HELO)</t><t color='%13' size='0.8' align='right'>%14</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Sentry 3 (UAV Recon)</t><t color='%15' size='0.8' align='right'>%16</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Angel 6 (MEDEVAC)</t><t color='%17' size='0.8' align='right'>%18</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Harvester 2 (Supply)</t><t color='%17' size='0.8' align='right'>%18</t>
//             <br /><br />
//             <t color='#004c99' size='1.3' align='center' underline='1'>Artillery</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Available Rounds</t><t color='#ffffff' size='0.8' align='right'>%9x</t>
//             <br /><br />
//             <t color='#ffffff' size='0.8' align='left'>Available Rounds %19:</t><t color='#ffffff' size='0.8' align='right'></t>
//             <t color='#ffffff' size='0.8' align='left'>%20</t><t color='#ffffff' size='0.8' align='right'></t>
//         ", _gunColor, _gunCd, _gunRocketColor, _gunRocketCd, _clusterColor, _clusterCd, _jdamColor, _jdamCd,  pl_arty_ammo, pl_sorties, _sadPlaneColor, _sadPlaneCd, _sadHeloColor, _sadHeloCd, _sadUavColor, _sadUavCd, _sadMedevacColor, _sadMedevacCd, groupId (pl_arty_groups#pl_active_arty_group_idx), _batteryRoundsFinal];

//         hintSilent parseText _message;
//         sleep 1;
//     };
//     hintSilent "";
// };

// // _off = [(pl_arty_groups#pl_active_arty_group_idx) getVariable ["pl_active_arty_guns", []]] call pl_get_arty_ammo;
// // _off2 = _off apply {[[_x#0] call pl_get_arty_type_to_name, _x#1]};
// // player sideChat (str _off2);


// v1 addEventHandler ["HandleDamage", {
//     params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

//     if (["mine", _projectile] call BIS_fnc_inString) then {

//         if !(_unit getVariable ["pl_mine_called_out", false]) then {
//             if (pl_enable_beep_sound) then {playSound "radioina"};
//             if (pl_enable_chat_radio) then {(leader (group (driver _unit))) sideChat format ["...We Just Hit a Mine", (groupId (group (driver _unit)))]};
//             if (pl_enable_map_radio) then {[(group (driver _unit)), "...We Just Hit a Mine", 20] call pl_map_radio_callout};

//             _mineArea = createMarker [str (random 3), getPos _unit];
//             _mineArea setMarkerShape "RECTANGLE";
//             _mineArea setMarkerBrush "Cross";
//             _mineArea setMarkerColor "colorORANGE";
//             _mineArea setMarkerAlpha 0.5;
//             _mineArea setMarkerSize [25, 25];
//             _mineArea setMarkerDir (getDir _unit);
//             pl_engineering_markers pushBack _mineArea;

//             _mines = allMines select {(_x distance2D _unit) < 20};

//             {
//                 _m = createMarker [str (random 3), getPos _x];
//                 _m setMarkerType "mil_triangle";
//                 _m setMarkerSize [0.4, 0.4];
//                 _m setMarkerColor "ColorRed";
//                 _m setMarkerShadow false;
//                 pl_engineering_markers pushBack _m;
//                 playerSide revealMine _x;
//             } forEach _mines;

//             _unit setVariable ["pl_mine_called_out", true];

//             [_unit] spawn {
//                 params ["_unit"];

//                 sleep 5;

//                 _unit setVariable ["pl_mine_called_out", nil];
//             }
//         };

//     };
//     _damage
// }];


// {
//     _x setVariable ["pl_assigned_group", group (driver _x)];  
// } forEach vehicles;

// if (count (((getPos (leader _grp)) nearEntities [["Man"], 500]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0}) > 0) then {
//     if ((random 1) > 0.4) then {
//         [_grp] spawn pl_opfor_attack_closest_enemy;
//         _time = time + 10 + (random 1);
//     } else {
//         [_grp] spawn pl_opfor_flanking_move;
//         _time = time + 25 + (random 1);
//     };
// };


    // while {_run} do {
    //  _run = _unit setWeaponZeroing [primaryweapon _unit, _ugl, _n];
    //  _n = _n + 1;
    //  _zeroValue = _unit currentZeroing [primaryweapon _unit, _ugl];
    //  if ((_zeroTable#((count _zeroTable) - 1)) isEqualTo _zeroValue) exitWith {};
    //  _zeroTable pushBackUnique _zeroValue;
    // };

    // player sideChat (str _zeroTable);

    // _zero = {
    //  if (_distance < (_x#0)) exitWith {_x#1};
    //  _x#1
    // } forEach _zeroTable;

    // player sideChat (str _zero);

    // _unit selectWeapon [primaryweapon _unit, _ugl, weaponState _unit select 2];
    // _unit reveal _target;
    // _unit doTarget _target;

// pl_bounding_move_team = {
//     params ["_team", "_movePosArray", "_wpPos", "_group", "_unitPos"];

//     for "_i" from 0 to (count _team) - 1 do {
//         _unit = _team#_i;
//         _movePos = _movePosArray#_i;
//         if ((_unit distance2D _movePos) > 4) then {
//             if (currentCommand _unit isNotEqualTo "MOVE" or (speed _unit) == 0) then {
//                 doStop _unit;
//                 [_unit, true] call pl_enable_force_move;
//                 _unit setHit ["legs", 0];
//                 _unit setUnitPos "UP";
//                 _unit doMove _movePos;
//                 _unit setDestination [_movePos, "LEADER DIRECT", true];
//             };
//         }
//         else
//         {
//          if ((_unit getVariable ["pl_bounding_set_time", 0]) == 0) then {
//              [_unit, _wpPos, _unitPos] call pl_bounding_set;
//          };
//         };
//     };
//     if (({currentCommand _x isEqualTo "MOVE"} count (_team select {alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")})) == 0 or ({(_x distance2D _wpPos) < 15} count _team > 0) or (waypoints _group isEqualTo []) or ({time > (_x getVariable ["pl_bounding_set_time", time])} count _team > 0)) exitWith {true};
//     false
// };

// pl_bounding_set = {
//  params ["_unit", "_wpPos", "_unitPos"]; 

//     doStop _unit;
//     [_unit, false] call pl_enable_force_move;
//     if (_unitPos isEqualTo "COVER") then {
//         [_unit, 15, _unit getDir _wpPos] spawn pl_find_cover;
//     } else {
//         _unit disableAI "PATH";
//         _unit setUnitPos _unitPos;
//     };

//      _unit setVariable ["pl_bounding_set_time", time + 7];
// };

// pl_get_move_pos_array = { 
//     params ["_team", "_wpPos", "_dirOffset", "_distanceOffset", "_MoveDistance"];
//     _teamLeaderPos = getPos (_team#0);
//     _moveDir = _teamLeaderPos getDir _wpPos;
//     _teamLeaderMovePos = _teamLeaderPos getPos [_MoveDistance, _moveDir + (_dirOffset * 0.05)];
//     _return = [_teamLeaderMovePos];
//     for "_i" from 1 to (count _team) - 1 do {
//         _p = _teamLeaderMovePos getPos [_distanceOffset * _i + ([-2, 2] call BIS_fnc_randomInt), _moveDir + _dirOffset];
//         _return pushBack _p;
//     };
//     _return;
// };

// pl_bounding_squad = {
//     params ["_mode", ["_group", hcSelected player select 0], ["_cords", []]];
//     private ["_cords", "_icon", "_group", "_team1", "_team2", "_MoveDistance", "_distanceOffset", "_movePosArrayTeam1", "_movePosArrayTeam2", "_unitPos", "_speed"];

//     // if !(visibleMap) exitWith {hint "Open Map for bounding OW"};

//     if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

//     private _drawSpecial = false;

//     if (_cords isEqualTo []) then {
//         if (visibleMap or !(isNull findDisplay 2000)) then {
//             if (visibleMap) then {
//                 _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//             } else {
//                 _cords = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
//             };
//         }
//         else
//         {
//             _cords = screenToWorld [0.5,0.5];
//         };
        
//         _moveDir = (leader _group) getDir _cords;

//         // if (pl_enable_beep_sound) then {playSound "beep"};
//         _drawSpecial = true;
//         [_group, "confirm", 1] call pl_voice_radio_answer;
//         [_group] call pl_reset;

//         sleep 0.5;

//         [_group] call pl_reset;

//         sleep 0.5;
        
//         switch (_mode) do { 
//             case "team" : {_icon = "\Plmod\gfx\team_bounding.paa";}; 
//             case "buddy" : {_icon = "\Plmod\gfx\buddy_bounding.paa";}; 
//             default {_icon = "\Plmod\gfx\team_bounding.paa";}; 
//         };
        
//         _group setVariable ["setSpecial", true];
//         _group setVariable ["specialIcon", _icon];
//     };

//     _wp = _group addWaypoint [_cords, 0];

//     if (_drawSpecial) then {
//         pl_draw_planed_task_array pushBack [_wp, _icon];
//     };

//     _units = (units _group);
//     _team1 = [];
//     _team2 = [];

//     _ii = 0;
//     {
//         if (_ii % 2 == 0) then {
//             _team1 pushBack _x;
//         }
//         else
//         {
//             _team2 pushBack _x;
//         };
//         _ii = _ii + 1;
//     } forEach (_units select {alive _x and !(_x getVariable ["pl_wia", false])});

//     {
//         doStop _x;
//         _x disableAI "PATH";
//         _x disableAI "AUTOCOMBAT";
//         _x setUnitPosWeak "Middle";
//         _x setVariable ["pl_damage_reduction", true];
//         _x setHit ["legs", 0];
//         _x setVariable ["pl_bounding_set_time", nil];
//     } forEach _units;

//     _group setBehaviour "AWARE";

//     // _mode = "buddy";

//     switch (_mode) do { 
//         case "team" : {_MoveDistance = 25; _distanceOffset = 4; _unitPos = "DOWN"; _speed = 5000}; 
//         case "buddy" : {_MoveDistance = 40; _distanceOffset = 11; _unitPos = "MIDDLE"; _speed = 12}; 
//         default {_MoveDistance = 25; _distanceOffset = 4; _unitPos = "DOWN", _speed = 5000, _mode = "team"}; 
//     };

//     {
//          _x limitSpeed _speed;
//     } forEach _team1;

//     _movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, 4, 4] call pl_get_move_pos_array;
//     for "_i" from 0 to (count _team2) - 1 do {
//      [_team2#_i, 5, (_team2#_i) getdir (waypointPosition _wp), false, _movePosArrayTeam2#_i] spawn pl_find_cover;
//     };

//     // _MoveDistance = 25;
//     while {({(_x distance2D (waypointPosition _wp)) < 15} count _units == 0) and !(waypoints _group isEqualTo [])} do {

//         (_team1#0) groupRadio "SentConfirmMove";
//         _movePosArrayTeam1 = [_team1, waypointPosition _wp, -90, _distanceOffset, _MoveDistance] call pl_get_move_pos_array;
//         {_x setVariable ["pl_bounding_set_time", nil]} forEach _team1;
//         waitUntil {sleep 0.5; [_team1, _movePosArrayTeam1, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team};
//         if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo [])) exitWith {};
//         if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {[_group] call pl_reset};

//         {
//              if ((_x getVariable ["pl_bounding_set_time", 0]) == 0) then {
//                  _x setPos ([-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd (getPos _x));
//              [_x, waypointPosition _wp, _unitPos] call pl_bounding_set;
//          };
//         } forEach _team1;

//         (_team1#0) groupRadio "sentCovering";
//         _targets = (_team1#0) targets [true, 400, [], 0, waypointPosition _wp];
//         // if (count _targets > 0 and _mode isEqualTo "team") then {{[_x, getPosASL (selectRandom _targets)] call pl_quick_suppress} forEach _team1};
//         if (count _targets > 0) then {{[_x, getPosASL (selectRandom _targets)] call pl_quick_suppress} forEach _team1};

//         sleep 1;

//         (_team2#0) groupRadio "SentConfirmMove";
//         switch (_mode) do { 
//             case "team" : {_MoveDistance = 50; _movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call pl_get_move_pos_array}; 
//             case "buddy" : {_MoveDistance = 30; _movePosArrayTeam2 = _movePosArrayTeam1}; 
//             default {_movePosArrayTeam2 = [_team2, waypointPosition _wp, 90, _distanceOffset, _MoveDistance] call pl_get_move_pos_array}; 
//         };
//         {_x setVariable ["pl_bounding_set_time", nil]} forEach _team2;
//         waitUntil {sleep 0.5; [_team2, _movePosArrayTeam2, waypointPosition _wp, _group, _unitPos] call pl_bounding_move_team};

//         if (({(_x distance2D (waypointPosition _wp)) < 15} count _units > 0) or (waypoints _group isEqualTo [])) exitWith {};
//         if (count (_team1 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2 or count (_team2 select {alive _x and !(_x getVariable ["pl_wia", false])}) < 2) exitWith {[_group] call pl_reset};

//         {
//              if ((_x getVariable ["pl_bounding_set_time", 0]) == 0) then {
//                  _x setPos ([-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd (getPos _x));
//              [_x, waypointPosition _wp, _unitPos] call pl_bounding_set;
//          };
//         } forEach _team2;
        
//         (_team2#0) groupRadio "sentCovering";
//         _targets = (_team2#0) targets [true, 400, [], 0, waypointPosition _wp];
//         if (count _targets > 0 and _mode isEqualTo "team") then {{[_x, getPosASL (selectRandom _targets)] call pl_quick_suppress} forEach _team2};

//         sleep 1;
//     };

//     {
//         doStop _x;
//         _x setVariable ["pl_damage_reduction", false];
//         _x setUnitPos "Auto";
//         _x enableAI "PATH";
//         _x enableAI "AUTOCOMBAT";
//         _x enableAI "COVER";
//         _x enableAI "AUTOTARGET";
//         _x enableAI "TARGET";
//         _x enableAI "SUPPRESSION";
//         _x enableAI "WEAPONAIM";
//         _x setUnitCombatMode "YELLOW";
//         _x doFollow (leader _group);
//         _x limitSpeed 5000;
//         _x forceSpeed -1;
//         _x setVariable ["pl_bounding_set_time", nil];
//     } forEach _units;
    

//     if (_drawSpecial) then {
//         pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
//         _group setVariable ["setSpecial", false];
//     };

//     [_team1,_team2]
// };


// pl_assault_position = {
//     params ["_group", ["_taskPlanWp", []], ["_cords", []]];
//     private ["_mPos", "_movePosArrayCover", "_movePosArrayManuver", "_leftPos", "_rightPos", "_markerPhaselineName", "_cords", "_limiter", "_targets", "_markerName", "_wp", "_icon", "_coverTeam","_manuverTeam", "_formation", "_fastAtk", "_tacticalAtk", "_breakingPoint", "_startPos", "_area", "_vicGroup"];

//     pl_sweep_area_size = 35;

//     if ((vehicle (leader _group) != leader _group and !(_group getVariable ["pl_has_cargo", false] or _group getVariable ["pl_vic_attached", false])) and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};


//     _markerName = format ["%1sweeper", _group];
//     createMarker [_markerName, [0,0,0]];
//     _markerName setMarkerShape "ELLIPSE";
//     _markerName setMarkerBrush "SolidBorder";
//     _markerName setMarkerColor pl_side_color;
//     _markerName setMarkerAlpha 0.35;
//     _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];

//     _arrowMarkerName = format ["%1arrow", _group];
//     createMarker [_arrowMarkerName, [0,0,0]];
//     _arrowMarkerName setMarkerType "marker_std_atk";
//     _arrowMarkerName setMarkerDir 0;
//     _arrowMarkerName setMarkerColor pl_side_color;
//     _arrowMarkerName setMarkerSize [1.2, 1.2];

//     _markerPhaselineName = format ["%1atk_phase", _group];
//     createMarker [_markerPhaselineName, [0,0,0]];
//     _markerPhaselineName setMarkerShape "RECTANGLE";
//     _markerPhaselineName setMarkerBrush "Solid";
//     _markerPhaselineName setMarkerColor pl_side_color;
//     _markerPhaselineName setMarkerAlpha 0.7;
//     _markerPhaselineName setMarkerSize [pl_sweep_area_size, 0.5];

//     if (_cords isEqualTo []) then {

//         if !(visibleMap) then {
//             if (isNull findDisplay 2000) then {
//                 [leader _group] call pl_open_tac_forced;
//             };
//         };
//         private _rangelimiterCenter = getPos (leader _group);
//         if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};
//         private _rangelimiter = 200;
//         _markerBorderName = str (random 2);
//         createMarker [_markerBorderName, _rangelimiterCenter];
//         _markerBorderName setMarkerShape "ELLIPSE";
//         _markerBorderName setMarkerBrush "Border";
//         _markerBorderName setMarkerColor "colorOrange";
//         _markerBorderName setMarkerAlpha 0.8;
//         _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

//         _message = "Select Assault Location <br /><br />
//             <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>SELECT Position</t> <br />
//             <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
//             <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />";
//         hint parseText _message;
//         onMapSingleClick {
//             pl_sweep_cords = _pos;
//             if (_shift) then {pl_cancel_strike = true};
//             pl_mapClicked = true;
//             hintSilent "";
//             onMapSingleClick "";
//         };

//         private _rangelimiterCenter = getPos (leader _group);
//         if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};

//         player enableSimulation false;

//         while {!pl_mapClicked} do {
//             // sleep 0.1;
//             if (visibleMap) then {
//                 _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//             } else {
//                 _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
//             };

//             if (inputAction "MoveForward" > 0) then {pl_sweep_area_size = pl_sweep_area_size + 5; sleep 0.05};
//             if (inputAction "MoveBack" > 0) then {pl_sweep_area_size = pl_sweep_area_size - 5; sleep 0.05};
//             _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
//             if (pl_sweep_area_size >= 120) then {pl_sweep_area_size = 120};
//             if (pl_sweep_area_size <= 5) then {pl_sweep_area_size = 5};

//             if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
//                 _markerName setMarkerPos _mPos;

//                 if (_mPos distance2D (leader _group) > pl_sweep_area_size + 35) then {
//                     _phaseDir = _mPos getDir _rangelimiterCenter;
//                     _phasePos = _mPos getPos [pl_sweep_area_size + 35, _phaseDir];
//                     _markerPhaselineName setMarkerPos _phasePos;
//                     _markerPhaselineName setMarkerDir _phaseDir;
//                     _markerPhaselineName setMarkerSize [pl_sweep_area_size + 10, 0.5];

//                     _arrowPos = _phasePos getPos [-15, _phaseDir];
//                     _arrowDir = _phaseDir - 180;
//                     _arrowDis = (_rangelimiterCenter distance2D _mPos) / 2;

//                     _arrowMarkerName setMarkerPos _arrowPos;
//                     _arrowMarkerName setMarkerDir _arrowDir;
//                     _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
//                 } else {
//                     _arrowMarkerName setMarkerSize [0,0];
//                     _markerPhaselineName setMarkerSize [0,0];
//                 };
//             };


//         };

//         player enableSimulation true;

//         pl_mapClicked = false;
//         deleteMarker _markerBorderName;
//         _cords = getMarkerPos _markerName;
//         _markerName setMarkerPos _cords;
//         _markerName setMarkerBrush "Border";
//         _area = pl_sweep_area_size;
//     } else {
//         _area = (((leader _group) distance2D _cords) / 2) + 30;
//         _markerName setMarkerPos _cords;
//         _markerName setMarkerBrush "Border";
//     };

//     _rightPos = _cords getPos [pl_sweep_area_size, 90];
//     _leftPos = _cords getPos [pl_sweep_area_size, 270];
//     pl_draw_text_array pushBack ["ENY", _leftPos, 0.02, pl_side_color_rgb];
//     pl_draw_text_array pushBack ["ENY", _rightPos, 0.02, pl_side_color_rgb];

//     _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa";

//     if (count _taskPlanWp != 0) then {

//         // add Arrow indicator
//         pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

//         if (vehicle (leader _group) != leader _group) then {
//             if !(_group getVariable ["pl_unload_task_planed", false]) then {
//                 // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false])};
//                 waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
//             } else {
//                 // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
//                 waitUntil {sleep 0.5; ((_group getVariable ["pl_execute_plan", false]) and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
//             };
//         } else {
//             // waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 or !(_group getVariable ["pl_task_planed", false])};
//             waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
//         };
//         _group setVariable ["pl_disembark_finished", nil];

//         // remove Arrow indicator
//         pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

//         if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
//         _group setVariable ["pl_task_planed", false];
//         _group setVariable ["pl_unload_task_planed", false];
//         _group setVariable ["pl_execute_plan", nil];
//     };

//     if (pl_cancel_strike) exitWith {
//         pl_cancel_strike = false;
//         deleteMarker _markerName;
//         deleteMarker _markerPhaselineName;
//         deleteMarker _arrowMarkerName;
//         pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
//         pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
//      };


//     _arrowDir = (leader _group) getDir _cords;
//     _arrowDis = ((leader _group) distance2D _cords) / 2;
//     _arrowPos = [_arrowDis * (sin _arrowDir), _arrowDis * (cos _arrowDir), 0] vectorAdd (getPos (leader _group));

//     pl_draw_text_array pushBack ["SEIZE", _cords, 0.025, pl_side_color_rgb]; 

//     [_group, "attack", 1] call pl_voice_radio_answer;

//     [_group] call pl_reset;

//     sleep 0.5;

//     [_group] call pl_reset;

//     sleep 0.5;

//     _group setVariable ["onTask", true];
//     _group setVariable ["setSpecial", true];
//     _group setVariable ["specialIcon", _icon];
//     _group setVariable ["pl_is_attacking", true];

//     _startPos = getPos (leader _group);

//     (leader _group) limitSpeed 15;

//     _markerName setMarkerPos _cords;

//     sleep 2;

//     private _machinegunner = objNull;
//     private _medic = objNull;

//     _group setBehaviour "AWARE";
//     (leader _group) limitSpeed 12;

//     private _atkTriggerDistance = 15;
//     private _approachPos = _cords getPos [_area + 10, _cords getDir _startPos];
//     private _endPos = _cords getPos [_area, _approachPos getDir _cords];

//     private _startUnitCount = {alive _x and !((lifeState _x) isEqualto "INCAPACITATED")} count (units _group);
//     _breakingPoint = round (_startUnitCount * 0.66);
//     if (_breakingPoint >= ({alive _x and !((lifeState _x) isEqualto "INCAPACITATED")} count (units _group))) then {_breakingPoint = -1};

//     private _mode = ["team", "buddy"] selectRandomWeighted [3, 1];

//     if ([_startPos] call pl_is_forest) then {_mode = "team"};
//     if ([_startPos] call pl_is_city) then {_mode = "buddy"};



//     [_approachPos, _cords, _area,  _group, _markerPhaselineName, _arrowMarkerName] spawn {
//      params ["_approachPos", "_cords", "_area",  "_group", "_markerPhaselineName", "_arrowMarkerName"];

//      while {(({(_x distance _approachPos) < 25} count (units _group)) == 0) and (_group getVariable ["onTask", true])} do {

//          if (_cords distance2D (leader _group) > _area + 20) then {
//              _phaseDir = (leader _group) getDir _cords;
//              _markerPhaselineName setMarkerDir _phaseDir;

//              _arrowPos = (getMarkerPos _markerPhaselineName) getPos [- 15, _phaseDir - 180];
//              _arrowDis = ((leader _group) distance2D _cords) / 2;

//              _arrowMarkerName setMarkerPos _arrowPos;
//              _arrowMarkerName setMarkerDir _phaseDir;
//              _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
//          } else {
//              _arrowMarkerName setMarkerSize [0,0];
//              _markerPhaselineName setMarkerSize [0,0];
//          };
//          sleep 0.1;
//      };
//  };

//  private _teams = [];

//     // APPROACH //

//     _mode = "team";

//     if (_startPos distance2d _approachPos > 30 and (_taskPlanWp isEqualTo [])) then {
//      if (vehicle (leader _group) == leader _group) then {

//          _teams = [_mode, _group, _approachPos] call pl_bounding_squad;

//      } else {
//          [vehicle (leader _group), _approachPos, 5] call pl_vic_advance_to_pos_static;
//      };
//  } else {
//      if (_startPos distance2d _approachPos > 10) then {
//          if (vehicle (leader _group) != leader _group) then {
//              [vehicle (leader _group), _approachPos, 5] call pl_vic_advance_to_pos_static;
//          };
//      };
//  };

//     // waitUntil {sleep 0.5; (({(_x distance _cords) < (_area + _atkTriggerDistance)} count (units _group)) > 0) or !(_group getVariable ["onTask", true])};


//     if (!(_group getVariable ["onTask", true])) exitWith {
//         deleteMarker _markerName;
//         deleteMarker _markerPhaselineName;
//         pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
//         pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
//         pl_draw_text_array = pl_draw_text_array - [["SEIZE", _cords, 0.025, pl_side_color_rgb]]; 
//         deleteMarker _arrowMarkerName;
//         _group setVariable ["pl_is_attacking", false];
//         {
//             _x setVariable ["pl_damage_reduction", false];
//         } forEach (units _group);
//     };


//     if (_group getVariable ["pl_has_cargo", false] or _group getVariable ["pl_vic_attached", false]) then {

//         private _infGroup = grpNull;
//         _medic = objNull;
//         private _vic = vehicle (leader _group);
//         _vicGroup = _group;

//         [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
//         sleep 0.1;
//         for "_i" from count waypoints _group - 1 to 0 step -1 do {
//             deleteWaypoint [_group, _i];
//         };
        
//         _vicGroup setVariable ["pl_on_march", false];

//         if (_group getVariable ["pl_has_cargo", false]) then {

//             private _cargo = (crew _vic) - (units _group);

//             private _cargoGroups = [];
//             {
//                 _unit = _x;

//                 if !(_unit in (units (group player))) then {
//                     _cargoGroups pushBack (group _unit);
//                 };

//                 _unit disableAI "AUTOCOMBAT";
//                 _unit setCombatBehaviour "AWARE";
//                 _unit setVariable ["pl_damage_reduction", true];
//                 _unit setHit ["legs", 0];
//                 unassignVehicle _unit;
//                 doGetOut _unit;
//                 [_unit] allowGetIn false;

//             } forEach _cargo;

//             private _limit = 0;
//             {
//                 if ((count (units _x)) > _limit) then {
//                     _limit = count (units _x);
//                     _infGroup = _x;
//                 };
//                 [_x] spawn pl_reset;
//             } forEach _cargoGroups;

//             if !(_infGroup getVariable ["pl_show_info", false]) then {
//                 [_infGroup] call pl_show_group_icon;
//             };

//             _infGroup leaveVehicle _vic;

//             _vic setVariable ["pl_on_transport", nil];
//             _group setVariable ["pl_has_cargo", false];

//             waitUntil {sleep 0.5; (({vehicle _x != _x} count (units _infGroup)) == 0) or (!alive _vic)};
//             sleep 2;
//             waitUntil {sleep 0.5; ({unitReady _x} count (units _infGroup)) == (count (units _infGroup))};
//         } else {
//             _infGroup = _group getVariable ["pl_attached_infGrp", grpNull];
//             _group setVariable ["pl_vic_attached", false];
//             _group setVariable ["pl_attached_infGrp", nil];

//             {
//                 _x disableAI "AUTOCOMBAT";
//                 _x setCombatBehaviour "AWARE";
//                 _x setVariable ["pl_damage_reduction", true];
//             } forEach (units _infGroup);
//         };

//         sleep 1;

//         [_infGroup] call pl_reset;

//         sleep 0.5;

//         [_infGroup] call pl_reset;

//         sleep 0.5;

//         _infGroup setVariable ["onTask", true];
//         _infGroup setVariable ["setSpecial", true];
//         _infGroup setVariable ["specialIcon", _icon];
//         _infGroup setVariable ["pl_is_attacking", true];

//         _startPos = getPos (leader _infGroup);

//         (leader _infGroup) limitSpeed 15;

//         _vicGroup = _group;
//         _group = _infGroup;

//         [_vicGroup] spawn pl_reset;

//         sleep 0.5;

//         [_vicGroup, _infGroup] spawn pl_attach_vic;

//         _breakingPoint = round (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) * 0.66);
//      if (_breakingPoint >= ({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group))) then {_breakingPoint = -1};

//     };

//     // ATTACK //

//     {
//      _unit = _x;
//         if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
//         if (((primaryweapon _unit call BIS_fnc_itemtype) select 1) == "MachineGun") then {_machinegunner = _unit};
//     } forEach (units _group);



//     _targets = [];
//     _allMen = _cords nearObjects ["Man", _area];
//     _vics = _cords nearEntities [["Car", "Tank", "Truck"], _area];
//     _targetBuildings = [];

//     {
//         _targets pushBack _x;
//         if ([getPos _x] call pl_is_indoor) then {
//             _targetBuildings pushBackUnique (nearestBuilding (getPos _x));

//             // _m = createMarker [str (random 1), (getPos _x)];
//             // _m setMarkerType "mil_dot";

//         };
//     } forEach (_allMen select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

//     _targetBuildings = [_targetBuildings, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;

//     missionNamespace setVariable [format ["targetBuildings_%1", _group], _targetBuildings];

//     {
//         _targets pushBack _x;
//     } forEach (_vics select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

//     _targets = [_targets, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;

//     // private _breakingPoint = round (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) * 0.66);
//     // hint str _breakingPoint;
    
//     private _taskTime = time + 240;

//     if ((count _targets) == 0) then {

//         // {
//         //     _x doFollow (leader _group);
//         // } forEach (units _group);

//         // (leader _group) doMove _cords;
//         _time = time + 5;
//         waitUntil {sleep 0.5; !(_group getVariable ["onTask", true]) or (time > _time) or (leader _group) distance2D _cords < 10};
//     }
//     else
//     {

//         [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
//         sleep 0.1;
//         for "_i" from count waypoints _group - 1 to 0 step -1 do {
//             deleteWaypoint [_group, _i];
//         };


//         if (_teams isEqualto []) then {
//          private _team1 = [];
//          private _team2 = [];
//          _ii = 0;
//          {
//              if (_ii % 2 == 0) then {
//                  _team1 pushBack _x;
//              }
//              else
//              {
//                  _team2 pushBack _x;
//              };
//              _ii = _ii + 1;
//          } forEach ((units _group) select {alive _x and !(_x getVariable ["pl_wia", false])});

//          _teams = [_team1, _team2];
//         };

//         sleep 0.2;
//         missionNamespace setVariable [format ["targets_%1", _group], _targets];

//         if (({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _startUnitCount) then {
//          [leader _group, _approachPos] call pl_throw_smoke_at_pos;
//         };
        
//         if (_machinegunner in (_teams#0)) then {
//          _coverTeam = _teams#0;
//          _manuverTeam = _teams#1;
//         } else {
//          _coverTeam = _teams#1;
//          _manuverTeam = _teams#0;
//      };

//         {
//             // waitUntil {sleep 0.5; unitReady _x or !alive _x};

//             _x enableAI "AUTOCOMBAT";
//             _x enableAI "FSM";
//             _x forceSpeed 12;

//             if (_x == _medic and (_group getVariable ["pl_healing_active", false])) then {
//                 [_x, 15, _x getDir _cords] spawn pl_find_cover;
//                 [_group, _x, _startPos] spawn pl_defence_ccp;
//                 // _x setVariable ["pl_engaging", true];
//                 _breakingPoint = _breakingPoint - 1;
//             } else {

//                 [_x, _group, _area, _cords, _medic, _machinegunner, _coverTeam, _manuverTeam] spawn {
//                     params ["_unit", "_group", "_area", "_cords", "_medic", "_machinegunner", "_coverTeam", "_manuverTeam"];
//                     private ["_movePos", "_target"];

//                     while {sleep 0.5; (count (missionNamespace getVariable format ["targets_%1", _group])) > 0} do {

//                      if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};

//                         if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
//                             _target = {
//                                 _attacker = _x getVariable ["pl_at_enaged_by", objNull];
//                                 if (!(_x isKindOf "Man") and alive _x and (isNull _attacker or _attacker == _unit)) exitWith {_x};
//                                 objNull
//                             } forEach (missionNamespace getVariable format ["targets_%1", _group]);
//                             if !(isNull _target) then {
//                                 _target setVariable ["pl_at_enaged_by", _unit];
//                                 _checkPosArray = [];
//                                 private _atkDir = _unit getDir _target;
//                                 private _lineStartPos = (getPos _unit) getPos [(_area + 100)  / 2, _atkDir - 90];
//                                 _lineStartPos = _lineStartPos getPos [8, _atkDir];
//                                 private _lineOffsetHorizon = 0;
//                                 private _lineOffsetVertical = (_target distance2D _unit) / 60;
//                                 _targetDir = getDir _target;
//                                 for "_i" from 0 to 60 do {
//                                     for "_j" from 0 to 60 do { 
//                                         _checkPos = _lineStartPos getPos [_lineOffsetHorizon, _atkDir + 90];
//                                         _lineOffsetHorizon = _lineOffsetHorizon + ((_area + 100) / 60);

//                                         _checkPos = [_checkPos, 1.579] call pl_convert_to_heigth_ASL;

//                                         // _m = createMarker [str (random 1), _checkPos];
//                                         // _m setMarkerType "mil_dot";
//                                         // _m setMarkerSize [0.2, 0.2];

//                                         _vis = lineIntersectsSurfaces [_checkPos, AGLToASL (unitAimPosition _target), _target, vehicle _target, true, 1, "VIEW"];
//                                         // _vis2 = [_target, "VIEW", _target] checkVisibility [_checkPos, AGLToASL (unitAimPosition _target)];
//                                         if (_vis isEqualTo []) then {
//                                                 _pointDir = _target getDir _checkPos;
//                                                 if (_pointDir >= (_targetDir - 50) and _pointDir <= (_targetDir + 50)) then {
//                                                     // _m setMarkerColor "colorORANGE";
//                                                 } else {
//                                                     if (_target distance2D _checkPos >= 30) then {
//                                                         _checkPosArray pushBack _checkPos;
//                                                         // _m setMarkerColor "colorRED";
//                                                     };
//                                                 };
//                                             };
//                                         };
//                                     _lineStartPos = _lineStartPos getPos [_lineOffsetVertical, _atkDir];
//                                     _lineOffsetHorizon = 0;
//                                 };
//                                 _lineOffsetVertical = 0;

//                                 if (count _checkPosArray > 0 and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {


//                                     // _movePos = ([_checkPosArray, [], {_target distance2D _x}, "DESCEND"] call BIS_fnc_sortBy) select 0;
//                                     _movePos = ([_checkPosArray, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;
//                                     _unit doMove _movePos;
//                                     _unit setDestination [_movePos, "FORMATION PLANNED", false];
//                                     pl_at_attack_array pushBack [_unit, _target, objNull];

//                                     _unit forceSpeed 3;
//                                     _unit disableAI "AUTOCOMBAT";
//                                     _unit setUnitTrait ["camouflageCoef", 0, true];
//                                     _unit disableAi "AIMINGERROR";
//                                     _unit setVariable ["pl_engaging", true];
//                                     _unit setVariable ['pl_is_at', true];

//                                     _unit reveal [_target, 2];
//                                     _unit doTarget _target;

//                                     _time = time + ((_unit distance _movePos) / 1.6 + 10);
//                                     sleep 0.5;
//                                     waitUntil {sleep 0.5; (time >= _time or (_unit distance2D _movePos) < 6 or !alive _unit or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true]) or !alive _target or (count (crew _target) == 0))};

//                                     _time = time + 15;
//                                     waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", false]) or !alive _target or (count (crew _target) == 0)};
//                                     // pl_at_attack_array = pl_at_attack_array - [[_unit, _movePos]];
//                                     if (alive _target) then {_unit setVariable ['pl_is_at', false]; pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]]; continue};
//                                     if !(alive _target or !alive _unit or _unit getVariable ["pl_wia", false]) then {_target setVariable ["pl_at_enaged_by", nil]};
//                                     pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]];
//                                     _unit setVariable ['pl_is_at', false];
//                                     _unit setUnitTrait ["camouflageCoef", 1, true];
//                                     _unit enableAi "AIMINGERROR";
//                                     _unit setVariable ["pl_engaging", false];
//                                     _unit enableAI "AUTOTARGET";
//                                     _unit setBehaviour "AWARE";
//                                     _unit setUnitCombatMode "YELLOW";
//                                     _group setVariable ["pl_grp_active_at_soldier", nil];
//                                 } else {
//                                     _target setVariable ["pl_at_enaged_by", nil];
//                                 };
//                                 sleep 1;
//                             };
//                         };

//                         // _target = (missionNamespace getVariable format ["targets_%1", _group])#([0,1] call BIS_fnc_randomInt);
//                         _target = (missionNamespace getVariable format ["targets_%1", _group])#0;

//                         if (!(alive _target) or captive _target) then {
//                          (missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target);
//                          continue;
//                         };

//                         if !(isNil "_target") then {
//                             if (alive _target and !(captive _target) and (_target isKindOf "Man")) then {
//                                 _pos = getPosATL _target;
//                                 _movePos = _pos vectorAdd [0.5 - (random 1), 0.5 - (random 1), 0];
//                                 // _unit limitSpeed 15;
//                                 _unit setVariable ["pl_engaging", true];

//                                 private _unreachableTimeOut = time + 15;
//                                 if (_unit in _coverTeam) then {
//                                  doStop _unit;
//                                  sleep 0.2;

//                                  _idx = _coverTeam find _unit;


//                                  [_unit, 8, _unit getDir _target, true, (getPos _unit) getPos [16, _unit getDir _target]] call pl_find_cover;

//                                  _ugled = [_unit, _target] call pl_fire_ugl_at_target;

//                                  waitUntil {sleep 0.5; time >= _unreachableTimeOut or !((group _unit) getVariable ["onTask", false]) or !alive _unit};
//                                  continue;

//                              } else {

//                                  _unit setDestination [_movePos, "FORMATION PLANNED", false];
//                                  _unit doMove _movePos;

//                                  _reachable = [_unit, _movePos, 20] call pl_not_reachable_escape;
//                                  _unreachableTimeOut = time + 20;
//                                  while {(alive _unit) and (alive _target) and !(captive _target) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true]) and (_unreachableTimeOut >= time)} do { // and _reachable
//                                      // _unit forceSpeed 3;

//                                      _unit forceSpeed ([_unit, _target] call pl_get_assault_speed);

//                                      if ((_target getVariable ["pl_naded", false]) and alive _target) then {
//                                          _target setVariable ["pl_naded", nil];
//                                      };

//                                      _sleepTime = time + 3;
//                                      waitUntil {sleep 0.5; time >= _sleepTime or !(alive _unit) or !((group _unit) getVariable ["onTask", false])};

//                                      if (((_unit weaponState 'HandGrenadeMuzzle')#4) > 0) then {
//                                          if ((_unit distance2D _target) < 30 and alive _target and !(_target getVariable ["pl_naded", false]) and time > (_target getVariable ["pl_nade_cd", 0])) then {

//                                              // player sideChat "Nade";

//                                              // _unit forceSpeed 0;
//                                              // _unit doTarget _target;

//                                              sleep 0.5;

//                                              _naded = [_unit, _target] call pl_throw_granade_at_target;
//                                              if (_naded) then {
//                                                  // player sideChat "Nade2";
//                                                  _target setVariable ["pl_naded", true];
//                                              };
//                                              // _unit forceSpeed -1;
//                                          }; 
//                                      };
//                                  };
//                                  if (time >= _unreachableTimeOut) then {
//                                      _target enableAI "PATH";
//                                      _target doMove ((getPos _target) findEmptyPosition [10, 100, typeOf _target]);
//                                  };
//                              };

//                                 if (!(alive _target) or (captive _target)) then {(missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target)};
//                             };
//                         } else {
//                             // [_unit, 15, _unit getDir _cords] spawn pl_find_cover;
//                             waitUntil {sleep 0.5; ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true]))};
//                         };

//                         if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};
//                     };
//                 };
//             };
//             sleep 0.15;
//         } forEach (units _group);

//         waitUntil {sleep 0.5; (({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _breakingPoint) or (time > _taskTime) or !(_group getVariable ["onTask", true]) or ({!alive _x or (captive _x)} count (missionNamespace getVariable format ["targets_%1", _group]) == count (missionNamespace getVariable format ["targets_%1", _group]))};
//     };

//     missionNamespace setVariable [format ["targets_%1", _group], nil];
//     _group setVariable ["pl_is_attacking", false];

//     // remove Icon form wp
//     // pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
//     {
//         _x setVariable ["pl_damage_reduction", false];
//         _x limitSpeed 5000;
//         _x forceSpeed -1;
//     } forEach (units _group);
//     _group setCombatMode "YELLOW";
//     _group setVariable ["pl_combat_mode", false];
//     _group enableAttack false;
//     // sleep 8;
//     deleteMarker _markerName;
//     deleteMarker _arrowMarkerName;
//     deleteMarker _markerPhaselineName;
//     pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
//     pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];

//     pl_draw_text_array = pl_draw_text_array - [["SEIZE", _cords, 0.025, pl_side_color_rgb]]; 

//     if (_group getVariable ["onTask", true]) then {
//         [_group] call pl_reset;
//         sleep 1;
//         // if (pl_enable_beep_sound) then {playSound "beep"};
//         if (({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _breakingPoint or time > (_taskTime + 1)) then {
//             if (pl_enable_beep_sound) then {playSound "radioina"};
//             if (pl_enable_map_radio) then {[_group, "...Assault failed!", 20] call pl_map_radio_callout};
//             if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault failed", (groupId _group)]};

//             // if (_group getVariable ["pl_sop_atk_disenage", false]) then {
//                 [_group, _startPos, true] spawn pl_disengage;
//             // } else {
//             //     [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
//             // } forEach (units _group);
//         } else {
//             if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault complete", (groupId _group)]};
//             if (pl_enable_map_radio) then {[_group, "...Assault Complete!", 20] call pl_map_radio_callout};
//             [_group, "atk_complete", 1] call pl_voice_radio_answer;
//             // {
//             //     [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
//             // } forEach (units _group);
//             [_group, [], _cords, _startPos getDir _cords, false, false, _area / 2] spawn pl_defend_position;

//         };
//     };
// };

pl_get_assault_speed = {
 [_unit, _target];

 _distance = _unit distance2D _target;
 _unit setHit ["legs", 0];

 if (_distance <= 20) exitWith {_unit disableAI "AIMINGERROR"; 2};
 _unit enableAI "AIMINGERROR";
 if (_distance < 50) exitWith {3};
 -1  
};


// pl_position_reached_check = {
//     params ["_unit", "_movePos", "_counter"];

//     // player sideChat (str _counter);

//     if ((_unit distance2D _movePos) > 4 and ((group _unit) getVariable ["onTask", false]) and alive _unit and !((lifeState _unit) isEqualto "INCAPACITATED")) then {
//         if ((((currentCommand _unit) isNotEqualTo "MOVE") or ((speed _unit) == 0))) then {

//             _movePos = [-(_counter / 2) + (random _counter), -(_counter / 2) + (random _counter), 0] vectorAdd _movePos;

//             [_unit, _movePos] spawn {
//                 params ["_unit", "_movePos"];
//                 _unit setHit ["legs", 0];
//                 _unit switchMove "";
//                 _unit setUnitPos "AUTO";
//                 doStop _unit;
//                 _unit setPos ([-0.5 + (random 1), -0.5 + (random 1), 0] vectorAdd (getPos _unit));

//                 sleep 0.5;

//                 if ((group _unit) getVariable ["onTask", false]) then {
//                     _unit doMove _movePos;
//                     _unit setDestination [_movePos, "LEADER DIRECT", true];
//                 };
//             };
//             _counter = _counter + 1;
//         };
//     };

//     if ((_unit distance2D _movePos) < 4 or _counter >= 10) exitWith {[true, _counter, _movePos]};

//     [false, _counter, _movePos]
// };

// pl_throw_granade_at_target = {
//  params ["_unit", "_target"];

//  private _safetyDistance = 15;
//  if ([getpos _target] call pl_is_indoor) then {
//      _safetyDistance = 5;
//  };

//  if ((_unit distance2D _target) > 30) exitWith {_target setVariable ["pl_nade_cd", time + 10]; false};
//  if ((_unit distance2D _target) < _safetyDistance) exitWith {_target setVariable ["pl_nade_cd", time + 10]; false};

//  if ([_unit, getPos _target, _safetyDistance] call pl_friendly_check_excact) exitWith {false};

//  _unit setVariable ["pl_hg_target", _target];
//  _unit forceSpeed 0;
//  _unit doWatch _target;
//  _unit doTarget _target;
//  _eh = _unit addEventHandler ["FiredMan", {
//          params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

//          if (_muzzle isEqualto 'HandGrenadeMuzzle') then {
//              [_unit, _projectile] spawn {
//                  params ["_unit", "_projectile"];

//                  _target = _unit getVariable ["pl_hg_target", objNull];

//                  _vel = [_unit, getPos _target, 30] call pl_THROW_VEL;

//                  _projectile setVelocity _vel;

//                  sleep 3;
//                  // waitUntil{ (vectorMagnitude velocity _projectile) < 0.02 };


//                  _projectile setPosASL ((getPosASLVisual _target) vectorAdd [1 - (random 2), 1 - (random 2), 1]);
//                  // _projectile setPosASL (getPosATLVisual _target);

//                  // _m = createMarker [str (random 2), getPosASLVisual _target];
//                  // _m setMarkerType "mil_dot";
//                  _unit setVariable ["pl_hg_target", nil];
//              };
//              _unit removeEventHandler [_thisEvent, _thisEventHandler];
                
//          };
//      }];
//  _target setVariable ["pl_nade_cd", time + 8];
//  sleep 1;
//  _fired = [_unit, 'HandGrenadeMuzzle'] call BIS_fnc_fire;
//  _unit forceSpeed -1;
//  _fired
// };

// // [cursorTarget, target_1] spawn pl_throw_granade_at_target;

// pl_throw_smoke_at_pos = {
//  params ["_unit", "_smokePos"];

//  if ((_unit distance2D _smokePos) > 50) exitWith {false}; 

//  _unit forceSpeed 0;
//  _unit setVariable ["pl_smoke_pos", _smokePos];

//  _eh = _unit addEventHandler ["FiredMan", {
//          params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

//          if (_muzzle isEqualto "SmokeShellMuzzle") then {
//              [_unit, _projectile] spawn {
//                  params ["_unit", "_projectile"];

//                  _smokePos = _unit getVariable ["pl_smoke_pos", getpos _unit];

//                  _vel = [_unit, _smokePos, 50] call pl_THROW_VEL;

//                  _projectile setVelocity _vel;

//                  // sleep 2;
//                  waitUntil{ (vectorMagnitude velocity _projectile) < 0.02 };

//                  _projectile setPos (_unit getVariable ["pl_smoke_pos", getpos _unit]);

//                  _unit setVariable ["pl_smoke_pos", nil];

//              };
//              _unit removeEventHandler [_thisEvent, _thisEventHandler];
                
//          };
//      }];
//  sleep 0.5;
//  _fired = [_unit, "SmokeShellMuzzle"] call BIS_fnc_fire;
//  _unit forceSpeed -1;
//  _fired
// };

// pl_fire_ugl_at_target = {
//  params ["_unit", "_target"];

//  if ((_unit distance2D _target) > 300) exitWith {false};
//  if ((_unit distance2D _target) < 30) exitWith {false};

//  if ([_unit, getPos _target, 35] call pl_friendly_check_excact) exitWith {false};

//  _ugl = (getArray (configfile >> "CfgWeapons" >> primaryWeapon _unit >> "muzzles") - ["SAFE", "this"]) param [0, ""];

//  if (_ugl isEqualto "") exitWith {false};

//  _unit forceSpeed 0;
//  _unit doTarget _target;
//  _unit setVariable ["pl_ugl_data", [_ugl, getPosASL _target]];
//  _eh = _unit addEventHandler ["FiredMan", {
//      params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

//      _uglData = _unit getVariable "pl_ugl_data";

//      if (_muzzle isEqualto (_uglData#0)) then {

//          _vel = [_unit, (_uglData#1) getPos [4, (_uglData#1) getDir _unit], 300] call pl_THROW_VEL;

//          _projectile setVelocity _vel;

//          _unit removeEventHandler [_thisEvent, _thisEventHandler];
//      };


//  }];

//  sleep 1;

//  _unit selectWeapon _ugl;
//     _unit forceWeaponFire [_ugl, weaponState _unit select 2];

//     _unit forceSpeed -1;
//     _unit doWatch objNull;
//     true

// };


// pl_THROW_VEL = {
//  _unit = _this select 0;
//  _targetpos = _this select 1;
//  _maxdist = if ((count _this) > 2) then {_this select 2} else {30};
//  _alpha = 45;
//  _range = _targetpos distance _unit;
//  if (_maxDist == 300) then {
//      _alpha = 20;
//      if (_range > 80) then {_alpha = 30};
//      if (_range > 150) then {_alpha = 45};
//  };
//  if (_range > _maxDist) then {_range = _maxdist};
//  _v0 = sqrt(_range * 9.81 / sin (2 * _alpha));
//  _v0x = cos _alpha * _v0;
//  _v0z = sin _alpha * _v0;
//  _throwDir = [_unit,_targetpos] call BIS_fnc_dirTo;
//  _flyDirSin = sin _throwDir;
//  _flyDirCos = cos _throwDir;
//  _vel = [_flyDirSin * _v0x,_flyDirCos * _v0x, _v0z];
//  _vel
// };

// // [cursorTarget, target_1] spawn pl_fire_ugl_at_target;

// pl_friendly_check_excact = {
//     params ["_unit", "_pos", "_area"];
    
//     _allies = (_pos nearEntities [["Man", "Car", "Tank"], _area]) select {side _x == side _unit};
//     // player sideChat str _allies;
//     if !(_allies isEqualTo []) exitWith {true};
//     false
// };


addMissionEventHandler ["Draw3D", {
     
    if (pl_enable_3d_icons and hcShownBar) then { 


        {
            _group = _x;
            _pos3D = ASLToAGL getPosASLVisual (vehicle (leader _group));
            private _alpha = 0.6;
            _distance = round ((leader _group) distance2D player);

            if (_distance < 600) then {

                if (_group in (hcSelected player)) then {

                    _alpha = 1;

                    if (vehicle (leader _group) == (leader _group)) then {
                        {
                            _pos3DUnit = ASLToAGL getPosASLVisual _x;
                            _icon = getText (configfile >> 'CfgVehicles' >> typeof (vehicle _x) >> 'icon');

                            drawIcon3D [
                                    _icon, //texture)
                                    [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, 0.85], //color
                                    [0,0,1] vectorAdd _pos3DUnit, //pos
                                    0.55, //width
                                    0.55, //height,
                                    0, //angle,
                                    "", //text,
                                    true, //shadow,
                                    0, //textSize,
                                    'EtelkaMonospacePro', //font
                                    "center", //textAlign,
                                    false, //drawSideArrows,
                                    0, //offsetX,
                                    0 //offsetY
                                ];
                        } forEach (units _group);
                    };
                };

                // if (_group getVariable ["inContact", false]) then {
                //     _iconPos3D = [0, 0, 2] vectorAdd _pos3D;
                //     drawIcon3D [
                //         '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa', //texture)
                //         [0.7,0,0,0.7], //color
                //         _iconPos3D, //pos
                //         0.4, //width
                //         0.4, //height,
                //         0, //angle,
                //         "", //text,
                //         false, //shadow,
                //         0, //textSize,
                //         'EtelkaMonospacePro', //font
                //         "center", //textAlign,
                //         false, //drawSideArrows,
                //         0, //offsetX,
                //         0 //offsetY
                //     ];
                // };

                // show distance to player
                drawIcon3D [
                    "", //texture)
                    [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _alpha], //color
                    [0,0,5 + _distance * 0.06] vectorAdd _pos3D, //pos
                    0.6, //width
                    0.6, //height,
                    0, //angle,
                    format ["%1: %2m",groupid _group, _distance], //text,
                    false, //shadow,
                    0.02, //textSize,
                    'EtelkaMonospacePro', //font
                    "center", //textAlign,
                    false, //drawSideArrows,
                    0, //offsetX,
                    0 //offsetY
                ];

                if ((_group getVariable ["onTask", false]) or (_group getVariable ["pl_task_planed", false])) then {

                    _iconPos3DTask = [0, 0, 6] vectorAdd (_group getVariable ["pl_task_pos", _pos3D]);
                    _icon = _group getVariable ["specialIcon", ""];

                    drawIcon3D [
                        _icon, //texture)
                        [0.9,0.9,0,_alpha], //color
                        _iconPos3DTask, //pos
                        0.6, //width
                        0.6, //height,
                        0, //angle,
                        format ["%1m", round (player distance2D _iconPos3DTask)], //text,
                        false, //shadow,
                        0.02, //textSize,
                        'EtelkaMonospacePro', //font
                        "center", //textAlign,
                        false, //drawSideArrows,
                        0, //offsetX,
                        0 //offsetY
                    ];

                    drawLine3D [
                        _iconPos3DTask,
                        _group getVariable "pl_task_pos",
                        [0.9,0.9,0,_alpha]
                    ];

                    private _grpLinePos = [0,0,2] vectorAdd _pos3D;
                    if !((_group getVariable ["pl_grp_task_plan_wp", []]) isEqualTo []) then {
                        _grpLinePos = [0,0,4] vectorAdd (waypointPosition (_group getVariable ["pl_grp_task_plan_wp", []]));
                    };

                    if ((_grpLinePos distance2D _iconPos3DTask) > 15) then {
                        drawLine3D [
                            _grpLinePos,
                            _iconPos3DTask,
                            [0.9,0.9,0,_alpha]
                        ];
                    };
                };

                // show WP
                if (count (waypoints _group) > 0) then {

                    _wps = waypoints _group;

                    if (count _wps >= 2) then {

                        for "_i" from (currentWaypoint _group) to (count _wps) -2 do {
                            drawLine3D [
                                [0,0,4] vectorAdd (waypointPosition (_wps#_i)),
                                [0,0,4] vectorAdd (waypointPosition (_wps#(_i + 1))),
                                [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _alpha]
                            ];

                            drawLine3D [
                                waypointPosition (_wps#_i),
                                [0,0,4] vectorAdd (waypointPosition (_wps#(_i))),
                                [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _alpha]
                            ];

                            drawIcon3D [
                                '\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa', //texture)
                                [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _alpha], //color
                                [0,0,4] vectorAdd (waypointPosition (_wps#_i)), //pos
                                0.6, //width
                                0.6, //height,
                                0, //angle,
                                "", //text,
                                false, //shadow,
                                0, //textSize,
                                'EtelkaMonospacePro', //font
                                "center", //textAlign,
                                false, //drawSideArrows,
                                0, //offsetX,
                                0 //offsetY
                            ];

                        };
                    };

                    drawLine3D [
                        waypointPosition (_wps#((count _wps) - 1)),
                        [0,0,4] vectorAdd (waypointPosition (_wps#((count _wps) - 1))),
                        [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _alpha]
                    ];

                    drawIcon3D [
                            '\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa', //texture)
                            [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _alpha], //color
                            [0,0,4] vectorAdd (waypointPosition (_wps#((count _wps) - 1))), //pos
                            0.6, //width
                            0.6, //height,
                            0, //angle,
                            "", //text,
                            false, //shadow,
                            0, //textSize,
                            'EtelkaMonospacePro', //font
                            "center", //textAlign,
                            false, //drawSideArrows,
                            0, //offsetX,
                            0 //offsetY
                        ];

                    if ((currentWaypoint _group) < (count _wps)) then {
                        drawLine3D [
                            getPos (leader _group),
                            [0,0,4] vectorAdd (waypointPosition (_wps#(currentWaypoint _group))),
                            [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _alpha]
                        ];
                    };
                };

            };

        } forEach (allGroups select {hcLeader _x isEqualTo player});

        {
            _opfGrp = (pl_marta_dic get _x)#0;

            _opfDistance = ([((leader _opfGrp) distance2D player) / 50, 0] call BIS_fnc_cutDecimals) * 50;

            if (_opfDistance <= 1500) then {

                _opfMarker =((pl_marta_dic get _x)#1)#0;
                _opfColor = [leader _opfGrp, 0.5] call pl_get_side_color_rgb;
                _opfPos3D = [0,0,_opfDistance * 0.025] vectorAdd (getmarkerPos [_opfMarker, false]);

                drawIcon3D [
                    format ['\Plmod\gfx\marta\%1.paa', markerType _opfMarker], //texture)
                    _opfColor, //color
                    _opfPos3D, //pos
                    0.6, //width
                    0.6, //height,
                    0, //angle,
                    format ["%1m", _opfDistance], //text,
                    false, //shadow,
                    0.02, //textSize,
                    'EtelkaMonospacePro', //font
                    "right", //textAlign,
                    false, //drawSideArrows,
                    0, //offsetX,
                    0 //offsetY
                ];

                drawLine3D [
                    _opfPos3D,
                    getmarkerPos [_opfMarker, false],
                    _opfColor
                ];
            };
        } forEach (keys pl_marta_dic);


        {
            private _p1 = _x#0;
            private _p2 = _x#1;

            if !((typeName _p1) isEqualTo "ARRAY") then {
                _p1 = getPosATL _p1;
            };

            if !((typeName _p2) isEqualTo "ARRAY") then {
                _p2 = getPosATL _p2;
            };

            drawLine3D [
                _p1,
                _p2,
                [0.9,0.9,0,1]
            ];

        } forEach pl_draw_3dline_array;


        {

            _targetPos3D = _x#0;
            _spGrp  = _x#1;
            _spDistance = round (_targetPos3D distance2D player);

            drawIcon3D [
                '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa', //texture)
                [0.92,0.24,0.07,1], //color
                [0,0,3] vectorAdd _targetPos3D, //pos
                0.6, //width
                0.6, //height,
                0, //angle,
                format ["%1m", _spDistance], //text,
                false, //shadow,
                0.02, //textSize,
                'EtelkaMonospacePro', //font
                "center", //textAlign,
                false, //drawSideArrows,
                0, //offsetX,
                0 //offsetY
            ];

            drawLine3D [
                [0,0,3] vectorAdd _targetPos3D,
                [0,0,2] vectorAdd (getPosATLVisual (leader _spGrp)),
                [1,0.0,0.0,1]
            ];
        } forEach pl_suppression_poses;

    };
}];

pl_get_side_color_rgb = {
    params ["_unit", ["_alpha", 0.7]];

    private _sideColorRGB = [0,0.3,0.6,_alpha];

    switch (side _unit) do { 
        case west : {_sideColorRGB = [0,0.3,0.6,_alpha]}; 
        case east : {_sideColorRGB = [0.5,0,0,_alpha]};
        case resistance : {__sideColorRGB = [0,0.5,0,_alpha]};
        default {_sideColorRGB = [0.5,0,0,_alpha]}; 
    };

    _sideColorRGB
};


while {!pl_mapClicked} do {
                // sleep 0.1;
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };

                if (inputAction "MoveForward" > 0) then {pl_sweep_area_size = pl_sweep_area_size + 2; sleep 0.05};
                if (inputAction "MoveBack" > 0) then {pl_sweep_area_size = pl_sweep_area_size - 2; sleep 0.05};
                if (inputAction "TurnLeft" > 0) then {pl_phase_line_distance = pl_phase_line_distance + 2; sleep 0.05};
                if (inputAction "TurnRight" > 0) then {pl_phase_line_distance = pl_phase_line_distance - 2; sleep 0.05};
                if (inputAction "LeanRight" > 0) then {pl_phase_line_dir = pl_phase_line_dir + 2; sleep 0.05};
                if (inputAction "LeanLeft" > 0) then {pl_phase_line_dir = pl_phase_line_dir - 2; sleep 0.05};
                _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
                if (pl_sweep_area_size >= 120) then {pl_sweep_area_size = 120};
                if (pl_sweep_area_size <= 5) then {pl_sweep_area_size = 5};
                if (pl_phase_line_distance >= 100) then {pl_phase_line_distance = 100};
                if (pl_phase_line_distance <= 0) then {pl_phase_line_distance = 0};

                if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
                    _markerName setMarkerPos _mPos;

                    if (_mPos distance2D (leader _group) > pl_sweep_area_size + 15) then {
                        _phaseDir = (_mPos getDir _rangelimiterCenter) + pl_phase_line_dir;
                        _phasePos = _mPos getPos [pl_sweep_area_size + pl_phase_line_distance, _phaseDir];
                        _markerPhaselineName setMarkerPos _phasePos;
                        _markerPhaselineName setMarkerDir _phaseDir;
                        _markerPhaselineName setMarkerSize [pl_sweep_area_size - 10, 0.5];

                        _arrowPos = _phasePos getPos [-15, _phaseDir];
                        _arrowDir = _phaseDir - 180;
                        _arrowDis = (_rangelimiterCenter distance2D _mPos) / 2;

                        _arrowMarkerName setMarkerPos _arrowPos;
                        _arrowMarkerName setMarkerDir _arrowDir;
                        _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
                    } else {
                        _arrowMarkerName setMarkerSize [0,0];
                        _markerPhaselineName setMarkerSize [0,0];
                    };

                    if (pl_sweep_area_size >= 50) then {
                        _markerPhaselineName setMarkerColor "colorOrange";
                    } else {
                        _markerPhaselineName setMarkerColor pl_side_color;
                    };
                };


            };

pl_draw_3dline_array = [];

pl_3d_interface = {

    private _eventHandlers3D = [];

    while {true} do {

        
        if (pl_enable_3d_icons and hcShownBar) then {
            {
                _group = _x;
                // _pos3D = getPosATLVisual (vehicle (leader _group));
                private _alpha = 0.6;
                _distance = round ((leader _group) distance2D player);

                if (_distance < 600) then {

                    if (pl_enable_map_radio) then {
                        _radioText = _group getVariable ['pl_radio_text',''];
                        if !(_radioText isEqualTo '') then {
                            _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                                drawIcon3D [
                                    '\A3\modules_f_curator\data\portraitRadioChannelCreate_ca.paa', //texture)
                                    [0.9,0.9,0,0.8], //color
                                    [0,0, 3 + (_thisArgs#1) * 0.03] vectorAdd (getPosATLVisual (_thisArgs#0)), //pos
                                    0.7, //width
                                    0.7, //height,
                                    0, //angle,
                                    _thisArgs#2, //text,
                                    true, //shadow,
                                    0.02, //textSize,
                                    'EtelkaMonospacePro', //font
                                    "right", //textAlign,
                                    false, //drawSideArrows,
                                    0, //offsetX,
                                    0 //offsetY
                                ];
                            }, [vehicle (leader _group), _distance, _radioText]];
                        };
                    };

                    if (_group in (hcSelected player)) then {

                        _alpha = 1;

                        if (vehicle (leader _group) == (leader _group)) then {
                            {
                                _unit = _x;
                                // _pos3DUnit = [0,0,1] vectorAdd (getPosATLVisual _x);
                                _icon = getText (configfile >> 'CfgVehicles' >> typeof (vehicle _x) >> 'icon');

                                _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                                    drawIcon3D [
                                        _thisArgs#0, //texture)
                                        _thisArgs#2, //color
                                        [0,0,1] vectorAdd (getPosATLVisual (_thisArgs#1)), //pos
                                        0.55, //width
                                        0.55, //height,
                                        0, //angle,
                                        "", //text,
                                        true, //shadow,
                                        0, //textSize,
                                        'EtelkaMonospacePro', //font
                                        "center", //textAlign,
                                        false, //drawSideArrows,
                                        0, //offsetX,
                                        0 //offsetY
                                    ];
                                }, [_icon, _unit, [_unit] call pl_get_unit_color]];
                            } forEach (units _group);
                        };
                    };

                    if (_group getVariable ["inContact", false]) then {

                        _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                            drawIcon3D [
                                '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa', //texture)
                                [0.7,0,0,0.7], //color
                                [0, 0, 2] vectorAdd (getPosATLVisual (_thisArgs#0)), //pos
                                0.4, //width
                                0.4, //height,
                                0, //angle,
                                "", //text,
                                false, //shadow,
                                0, //textSize,
                                'EtelkaMonospacePro', //font
                                "center", //textAlign,
                                false, //drawSideArrows,
                                0, //offsetX,
                                0 //offsetY
                            ];
                        }, [leader _group]];
                    };

                    // show distance to player  
                    _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                        drawIcon3D [
                            "", //texture)
                            [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2], //color
                            [0,0,5 + (_thisArgs#0) * 0.06] vectorAdd (getPosATLVisual (leader (_thisArgs#1))), //pos
                            0.6, //width
                            0.6, //height,
                            0, //angle,
                            format ["%1: %2m",groupid (_thisArgs#1), _thisArgs#0], //text,
                            false, //shadow,
                            0.02, //textSize,
                            'EtelkaMonospacePro', //font
                            "center", //textAlign,
                            false, //drawSideArrows,
                            0, //offsetX,
                            0 //offsetY
                        ];
                    }, [_distance, _group, _alpha]];

                    if ((_group getVariable ["onTask", false]) or (_group getVariable ["pl_task_planed", false])) then {

                        _iconPos3DTask = [0, 0, 6] vectorAdd (_group getVariable ["pl_task_pos", [0,0,0]]);
                        _icon = _group getVariable ["specialIcon", ""];

                        _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {

                            drawIcon3D [
                                _thisArgs#0, //texture)
                                [0.9,0.9,0, _thisArgs#3], //color
                                _thisArgs#1, //pos
                                0.6, //width
                                0.6, //height,
                                0, //angle,
                                format ["%1m", round (player distance2D (_thisArgs#1))], //text,
                                false, //shadow,
                                0.02, //textSize,
                                'EtelkaMonospacePro', //font
                                "center", //textAlign,
                                false, //drawSideArrows,
                                0, //offsetX,
                                0 //offsetY
                            ];

                            drawLine3D [
                                _thisArgs#1,
                                (_thisArgs#2) getVariable "pl_task_pos",
                                [0.9,0.9,0,_thisArgs#3]
                            ];

                            if !(((_thisArgs#2) getVariable ["pl_grp_task_plan_wp", []]) isEqualTo []) then {

                                drawLine3D [
                                    [0,0,4] vectorAdd (waypointPosition ((_thisArgs#2) getVariable ["pl_grp_task_plan_wp", []])),
                                    _thisArgs#1,
                                    [0.9,0.9,0,_thisArgs#3]
                                ];

                            } else {

                                drawLine3D [
                                    [0,0,2] vectorAdd (getPosATLVisual (leader (_thisArgs#2))),
                                    _thisArgs#1,
                                    [0.9,0.9,0,_thisArgs#3]
                                ];
                            };

                        }, [_icon, _iconPos3DTask, _group, _alpha]];
                    };

                    // show WP
                    if (count (waypoints _group) > 0) then {

                        _wps = waypoints _group;

                        if (count _wps >= 2) then {

                            for "_i" from (currentWaypoint _group) to (count _wps) -2 do {

                                _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                                    drawLine3D [
                                        _thisArgs#0,
                                        _thisArgs#1,
                                        [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2]
                                    ];

                                    drawLine3D [
                                        _thisArgs#3,
                                        _thisArgs#0,
                                        [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2]
                                    ];

                                    drawIcon3D [
                                        '\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa', //texture)
                                        [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2], //color
                                        _thisArgs#0, //pos
                                        0.6, //width
                                        0.6, //height,
                                        0, //angle,
                                        "", //text,
                                        false, //shadow,
                                        0, //textSize,
                                        'EtelkaMonospacePro', //font
                                        "center", //textAlign,
                                        false, //drawSideArrows,
                                        0, //offsetX,
                                        0 //offsetY
                                    ];
                                }, [[0,0,4] vectorAdd (waypointPosition (_wps#_i)), [0,0,4] vectorAdd (waypointPosition (_wps#(_i + 1))), _alpha, waypointPosition (_wps#_i)]];
                            };
                        };

                        _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {

                            drawLine3D [
                                _thisArgs#0,
                                _thisArgs#1,
                                [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2]
                            ];

                            drawIcon3D [
                                    '\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa', //texture)
                                    [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2], //color
                                    _thisArgs#1, //pos
                                    0.6, //width
                                    0.6, //height,
                                    0, //angle,
                                    "", //text,
                                    false, //shadow,
                                    0, //textSize,
                                    'EtelkaMonospacePro', //font
                                    "center", //textAlign,
                                    false, //drawSideArrows,
                                    0, //offsetX,
                                    0 //offsetY
                                ];
                            }, [waypointPosition (_wps#((count _wps) - 1)), [0,0,4] vectorAdd (waypointPosition (_wps#((count _wps) - 1))), _alpha]];

                        if ((currentWaypoint _group) < (count _wps)) then {
                            _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                                drawLine3D [
                                    getPos (leader (_thisArgs#0)),
                                    _thisArgs#1,
                                    [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2]
                                ];
                            }, [_group, [0,0,4] vectorAdd (waypointPosition (_wps#(currentWaypoint _group))), _alpha]];
                        };
                    };

                };

            } forEach (allGroups select {hcLeader _x isEqualTo player});

            {
                _opfGrp = (pl_marta_dic get _x)#0;

                _opfDistance = ([((leader _opfGrp) distance2D player) / 50, 0] call BIS_fnc_cutDecimals) * 50;

                if (_opfDistance <= 1500) then {

                    _opfMarker =((pl_marta_dic get _x)#1)#0;

                    _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                        drawIcon3D [
                            _thisArgs#0, //texture)
                            _thisArgs#1, //color
                            _thisArgs#2, //pos
                            0.6, //width
                            0.6, //height,
                            0, //angle,
                            _thisArgs#3, //text,
                            false, //shadow,
                            0.02, //textSize,
                            'EtelkaMonospacePro', //font
                            "right", //textAlign,
                            false, //drawSideArrows,
                            0, //offsetX,
                            0 //offsetY
                        ];

                        drawLine3D [
                            _thisArgs#2,
                            _thisArgs#4,
                            _thisArgs#1
                        ];
                    },[
                        format ['\Plmod\gfx\marta\%1.paa', markerType _opfMarker],
                        [leader _opfGrp, 0.5] call pl_get_side_color_rgb,
                        [0,0,_opfDistance * 0.025] vectorAdd (getmarkerPos [_opfMarker, false]),
                        format ["%1m", _opfDistance],
                        getmarkerPos [_opfMarker, false]]];
                };
            } forEach (keys pl_marta_dic);


            {
                _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                    drawLine3D [
                        getPosATL (_thisArgs#0),
                        getPosATL (_thisArgs#1),
                        [0.9,0.9,0,1]
                    ];
                },[_x#0, _x#1]];

            } forEach pl_draw_3dline_array;


            {

                _targetPos3D = _x#0;
                _spGrp  = _x#1;
                _spDistance = round (_targetPos3D distance2D player);

                _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {

                    drawIcon3D [
                        '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa', //texture)
                        [0.92,0.24,0.07,1], //color
                        _thisArgs#0, //pos
                        0.6, //width
                        0.6, //height,
                        0, //angle,
                        _thisArgs#1, //text,
                        false, //shadow,
                        0.02, //textSize,
                        'EtelkaMonospacePro', //font
                        "center", //textAlign,
                        false, //drawSideArrows,
                        0, //offsetX,
                        0 //offsetY
                    ];

                    drawLine3D [
                        _thisArgs#0,
                        _thisArgs#2,
                        [1,0.0,0.0,1]
                    ];
                }, [[0,0,3] vectorAdd _targetPos3D, format ["%1m", _spDistance], [0,0,2] vectorAdd (getPosATLVisual (leader _spGrp))]];
            } forEach pl_suppression_poses;

        };

        sleep 2.5;

        {
            removeMissionEventHandler ["Draw3D", _x];
        } forEach _eventHandlers3D

    };
};

pl_get_side_color_rgb = {
    params ["_unit", ["_alpha", 0.7]];

    private _sideColorRGB = [0,0.3,0.6,_alpha];

    switch (side _unit) do { 
        case west : {_sideColorRGB = [0,0.3,0.6,_alpha]}; 
        case east : {_sideColorRGB = [0.5,0,0,_alpha]};
        case resistance : {__sideColorRGB = [0,0.5,0,_alpha]};
        default {_sideColorRGB = [0.5,0,0,_alpha]}; 
    };

    _sideColorRGB
};

[] spawn pl_3d_interface;



pl_ooooooooooof = {

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


        // vor taskplan
        _group setVariable ["pl_task_pos", _cords];
        _group setVariable ["specialIcon", _icon];

        // in _taskplan
        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

};


// Spawn statt call?

pl_vic_turn_in_place = {
    params ["_vic", "_targetPos"];

    if !([_vic] call pl_canMove) exitWith {};

    if (_vic getRelDir _targetPos <= 2.5) exitWith {}; 

    _vic engineOn false;
    _vic engineOn true;
    _vic disableBrakes true;
    private _degreesToRotate = _vic getRelDir _targetPos;
    private _posOrneg = 1; // This drives whether unit rotates clockwise or counter-clockwise
    private _increment = 0.4;
    _degreesToRotate = _vic getRelDir _targetPos;
    _posOrneg = 1;
    if (_degreesToRotate > 180) then
    {
        _posOrneg = -1;
    };

    _vicDir = (getDirVisual _vic);

    // _vic setDir _vicDir;

    (group (driver _vic)) setVariable ["pl_on_march", true];



    _turnScript = [_vic, _vicDir, _degreesToRotate, group (driver _vic)] spawn {
        params ["_vic", "_vicDir", "_degreesToRotate", "_vicGroup"];

        if (_degreesToRotate > 180) then
        {
            // systemChat format ["from %1 to %2 -0.5",(getDirVisual _vic), (getDirVisual _vic) - _degreesToRotate];
            for "_t" from _vicDir to _vicDir - _degreesToRotate step -0.5 do {
                _vic setDir _t;

                sleep 0.01;

                if (!([_vic] call pl_canMove) or !(_vicGroup getVariable ["pl_on_march", false])) exitWith {};
            };
        } else {
        // systemChat format ["from %1 to %2 +0.5",_vicDir, _vicDir + _degreesToRotate];
            for "_t" from _vicDir to _vicDir + _degreesToRotate step 0.5 do {
                _vic setDir _t;

                sleep 0.01;

                if (!([_vic] call pl_canMove) or !(_vicGroup getVariable ["pl_on_march", false])) exitWith {};
            };
        };

        
    };

    waitUntil {scriptDone _turnScript};

    sleep 0.5;

    _vic disableBrakes false;
    if ((group (driver _vic)) getVariable ["pl_on_march", false]) then {
        _vic setDir (_vic getDir _targetPos);
        (group (driver _vic)) setVariable ["pl_on_march", nil];
    };
};


pl_tow_vehicle = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_cords", "_engVic"];

    if (vehicle (leader _group) != leader _group) then {
        _engVic = vehicle (leader _group);
        _vicType = typeOf _engVic;
    } else {
        if (_group getVariable ["pl_is_repair_group", false]) then {
            _engVic = {
                if (_x getUnitTrait "engineer") exitWith {_x};
                objNull;
            } forEach (units _group);
        };
        _engVic setVariable ["pl_is_repair_vehicle", true];
    };

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
        waitUntil {sleep 0.1; inputAction "Action" <= 0};

        // _cursorPosIndicator = createVehicle ["Sign_Arrow_Direction_Yellow_F", screenToWorld [0.5,0.5], [], 0, "none"];
        _cursorPosIndicator = createVehicle ["Sign_Arrow_Large_Yellow_F", [-1000, -1000, 0], [], 0, "none"];

        _leader = leader _group;
        pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

        while {inputAction "Action" <= 0} do {
            _viewDistance = _cursorPosIndicator distance2D player;
            if (cursorObject isKindOf "Car" or cursorObject isKindOf "Tank" or cursorObject isKindOf "Truck") then {
                _cursorPosIndicator setPosATL ([0, 0, ((boundingBox cursorObject)#1)#2] vectorAdd (getPosATLVisual cursorObject));
                _cursorPosIndicator setObjectScale (_viewDistance * 0.05);
            };

            if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

            sleep 0.025
        };

        if (pl_cancel_strike) exitWith {deleteVehicle _cursorPosIndicator; pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]]};

        _cords = getPosATL _cursorPosIndicator;

        pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

        deleteVehicle _cursorPosIndicator;

        pl_vics = [cursorObject];
        _cords = getPos cursorObject;

        if (_group getVariable ["pl_on_march", false]) then {
            _taskPlanWp = (waypoints _group) select ((count waypoints _group) - 1);
            _group setVariable ["pl_task_planed", true];
            _taskPlanWp setWaypointStatements ["true", "(group this) setVariable ['pl_execute_plan', true]"];
        };
    };

    pl_vics = [pl_vics, [], {_x distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy;
    _targetVic = pl_vics#0;



    _rearPosTargetvic = (getPos _targetVic) getPos [-5, getDirVisual _targetVic];

    systemChat str (typeOf _targetVic);

    _m = createMarker [str (random 1), _rearPosTargetvic];
    _m setMarkerType "mil_dot";

    [_engVic, _rearPosTargetvic, 4, 0.5, true] call pl_vic_advance_to_pos_static;

    _rope = ropeCreate [_engVic, [0,0,-1], _targetVic, [0,0,-1]];

    _targetVic awake true;
    _targetVic disableBrakes true;
    _targetVic setVelocityModelSpace [0, -0.5 , 0];

    // sleep 1;

    [_engVic, (getPos _targetVic) getPos [-80, getDirVisual _targetVic], 4, 0.5, true] call pl_vic_reverse_to_pos;


    _engVic ropeDetach _rope;
    _targetVic ropeDetach _rope;
    _targetVic disableBrakes false;
    ropeDestroy _rope

};


pl_vic_turn_in_place = {
    params ["_vic", "_targetPos"];

    if !([_vic] call pl_canMove) exitWith {};

    if (_vic getRelDir _targetPos <= 2.5) exitWith {}; 

    // _vic engineOn false;
    // _vic engineOn true;
    _sound = playSound3d ["a3\sounds_f_tank\vehicles\armor\lt_01\lt_01_engine_ext_burst01.wss", _vic];
    if (_vic isKindOf "Tank") then {
        _sound2 = playSound3d ["a3\sounds_f\vehicles\armor\treads\ext_treads_hard_01.wss", _vic];
    };
    _vic disableBrakes true;
    private _degreesToRotate = _vic getRelDir _targetPos;
    private _posOrneg = 1; // This drives whether unit rotates clockwise or counter-clockwise
    private _increment = 0.4;
    _degreesToRotate = _vic getRelDir _targetPos;
    _posOrneg = 1;
    if (_degreesToRotate > 180) then
    {
        _posOrneg = -1;
    };

    (group (driver _vic)) setVariable ["pl_on_march", true];

    _s1 = [_vic, _posOrneg, _increment, _targetPos] spawn {
        params ["_vic", "_posOrneg", "_increment", "_targetPos"];
        while {(_vic getRelDir _targetPos) >= 1.2 and ((group (driver _vic)) getVariable ["pl_on_march", false])} do {
            _vic setDir (getDir _vic + (_increment * _posOrneg));
            if (_vic isKindOf "Car" or _vic isKindOf "Truck") then {
                _vic setVelocityModelSpace [0,-2,0];
            };
            sleep 0.01;
            if !([_vic] call pl_canMove) exitWith {};
        };
    };
    waitUntil {sleep 0.1; scriptDone _s1};
    _vic setDir (_vic getDir _targetPos);
    _vic disableBrakes false;
    if ((group (driver _vic)) getVariable ["pl_on_march", false]) then {
        _vic setDir (_vic getDir _targetPos);
        (group (driver _vic)) setVariable ["pl_on_march", nil];
    };

};

pl_vic_advance_to_pos_static = {
    params ["_vic", "_pos", ["_speed", 4], ["_acs", 0.5], ["_exitOnObstacle", false]];

    if !([_vic] call pl_canMove) exitWith {};

    [_vic, _pos] call pl_vic_turn_in_place;
    // _vic setDir (_vic getDir _pos);

    private _startPos = getPos _vic;
    private _distancetoTravel = (_startPos distance2d _pos) - 1;
    (group (driver _vic)) setVariable ["pl_on_march", true];
    _vic disableBrakes true;
    _vic engineOn false;
    _vic engineOn true;
    _n = _speed;
    while {_vic distance2D _startPos < _distancetoTravel and alive _vic and ((group (driver _vic)) getVariable ["pl_on_march", false])} do {

        _vic disableBrakes true;
        if (count (((getPos _vic) getPos [8, getdir _vic]) nearEntities [["Car", "Tank", "Truck"], 7]) <= 0) then {
            if (_n > 0) then {_n = _n - _acs};
            _vic setVelocityModelSpace [0, (_speed - _n),0];
        } else {
            _n = _speed;
            _vic disableBrakes false;
            if (_exitOnObstacle) then {break};
        };
        // if (time % 2 == 0) then {_vic setDir (_vic getDir _pos)};
        sleep 0.5;
        if !([_vic] call pl_canMove) exitWith {};
    };
    _vic disableBrakes false;
    (group (driver _vic)) setVariable ["pl_on_march", nil];
};
