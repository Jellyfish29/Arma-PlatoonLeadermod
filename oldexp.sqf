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
        ["Bad static weapon! Static weapon should exist and not be packed or broken"] call BIS_fnc_error;
        nil
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