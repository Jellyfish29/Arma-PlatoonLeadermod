// pl_lay_mine_field_switch = {
//     params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];

//     if (vehicle (leader _group) != leader _group and ((vehicle (leader _group)) getVariable ["pl_is_mine_vic",false]) and !(_group getVariable ["pl_unload_task_planed", false])) then {
//         [_group, _taskPlanWp] spawn pl_lay_mine_field_vic;
//     } else {
//         [_group, _taskPlanWp] spawn pl_lay_mine_field;
//     };
// };


// pl_lay_mine_field_vic = {
//     params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
//     private ["_mPos", "_group", "_cords", "_areaMarker", "_watchDir", "_mineMarkers", "_neededMines", "_minePositions", "_usedMines", "_mineType", "_origPos", "_availableMines", "_text", "_startPos", "_endPos"];

//     if (vehicle (leader _group) == leader _group) exitWith {hint "Vehicle Only Task!"};

//     private _engVic = vehicle (leader _group);

//     if !(_engVic getVariable ["pl_is_mine_vic",false]) exitWith {hint "Requires Egineering Vehicle"};

//     if !(visibleMap) then {
//         if (isNull findDisplay 2000) then {
//             [leader _group] call pl_open_tac_forced;
//         };
//     };;

//     _availableMines = _engVic getVariable ["pl_virtual_mines", 0];;

//     if (_availableMines <= 0) exitWith {hint "No Mines Left!"};

//     if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: %2 Mines Available",groupId _group, _availableMines]};
//     if (pl_enable_map_radio) then {[_group, format ["...%1 Mines Available",_availableMines], 15] call pl_map_radio_callout};

//     hintSilent "";
//     pl_mine_field_size = 16;
//     pl_mine_type = "ATMine";
//     _maxFieldSize = pl_mine_spacing * 40;
//     _mineFieldSize = pl_mine_spacing * 2;

//     _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br /> <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
//     hint parseText _message;

//     _areaMarker = format ["%1mineField%2", _group, random 2];
//     createMarker [_areaMarker, [0,0,0]];
//     _areaMarker setMarkerShape "RECTANGLE";
//     // _areaMarker setMarkerBrush "Cross";
//     _areaMarker setMarkerBrush "SolidBorder";
//     _areaMarker setMarkerColor "colorGreen";
//     _areaMarker setMarkerAlpha 0.8;
//     _areaMarker setMarkerSize [pl_mine_field_size, 1];
//     pl_engineering_markers pushBack _areaMarker;

//     private _rangelimiter = 60;

//     _markerBorderName = str (random 2);
//     private _borderMarkerPos = getPos (leader _group);
//     if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
//     createMarker [_markerBorderName, _borderMarkerPos];
//     _markerBorderName setMarkerShape "ELLIPSE";
//     _markerBorderName setMarkerBrush "Border";
//     _markerBorderName setMarkerColor "colorOrange";
//     _markerBorderName setMarkerAlpha 0.8;
//     _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

//     onMapSingleClick {
//         pl_Mine_field_cords = _pos;
//         pl_mapClicked = true;
//         if (_shift) then {pl_cancel_strike = true};
//         hintSilent "";
//         onMapSingleClick "";
//     };

//     player enableSimulation false;

//     while {!pl_mapClicked} do {
//         if (visibleMap) then {
//             _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//         } else {
//             _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
//         };
//         _watchDir = getPos (leader _group) getDir _mPos;
//         if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
//             _areaMarker setMarkerPos _mPos;
//             _areaMarker setMarkerDir _watchDir;
//         };
//         if (inputAction "MoveForward" > 0) then {pl_mine_field_size = pl_mine_field_size + _mineFieldSize; sleep 0.05};
//         if (inputAction "MoveBack" > 0) then {pl_mine_field_size = pl_mine_field_size - _mineFieldSize; sleep 0.05};
//         _areaMarker setMarkerSize [pl_mine_field_size, 4];
//         if (pl_mine_field_size >= _maxFieldSize) then {pl_mine_field_size = _maxFieldSize};
//         if (pl_mine_field_size <= _mineFieldSize) then {pl_mine_field_size = _mineFieldSize};
//         _neededMines = pl_mine_field_size / (pl_mine_spacing / 2);
//         if (_neededMines > _availableMines) then {
//             pl_mine_field_size = pl_mine_field_size - 8;
//             hintSilent "Not enough Mines Left for larger Area";
//         };
//         sleep 0.01;
//     };

//     player enableSimulation true;

//     pl_mapClicked = false;
//     if (pl_cancel_strike) exitWith { 
//         deleteMarker _areaMarker;
//         deleteMarker _markerBorderName;
//         pl_cancel_strike = false;
//     };
//     _message = "Select Heading <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
//                 <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>APERS Mines</t> <br />
//                 <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
//     hint parseText _message;

//     sleep 0.1;
//     _cords = getMarkerPos _areaMarker;

//     deleteMarker _markerBorderName;

//     onMapSingleClick {
//         pl_mapClicked = true;
//         if (_shift) then {pl_cancel_strike = true};
//         if (_alt) then {pl_mine_type = "APERSBoundingMine"};
//         onMapSingleClick "";
//     };

//     player enableSimulation false;

//     while {!pl_mapClicked} do {
//         if (visibleMap) then {
//             _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//         } else {
//             _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
//         };
//         _watchDir = _cords getDir _mPos;
//         _areaMarker setMarkerDir _watchDir;
//         if (inputAction "MoveForward" > 0) then {pl_mine_field_size = pl_mine_field_size + _mineFieldSize; sleep 0.05};
//         if (inputAction "MoveBack" > 0) then {pl_mine_field_size = pl_mine_field_size - _mineFieldSize; sleep 0.05};
//         _areaMarker setMarkerSize [pl_mine_field_size, 4];
//         if (pl_mine_field_size >= _maxFieldSize) then {pl_mine_field_size = _maxFieldSize};
//         if (pl_mine_field_size <= _mineFieldSize) then {pl_mine_field_size = _mineFieldSize};
//         _neededMines = pl_mine_field_size / (pl_mine_spacing / 2);
//         if (_neededMines > _availableMines) then {
//             pl_mine_field_size = pl_mine_field_size - 8;
//             hint "Not enough Mines Left for larger Area";
//         };
//         sleep 0.01;
//     };

//     player enableSimulation true;

//     _mineType = pl_mine_type;
//     _areaMarker setMarkerAlpha 0.5;
//     hintSilent "";
//     pl_mapClicked = false;

//     if (pl_cancel_strike) exitWith { 
//         deleteMarker _areaMarker; 
//         pl_cancel_strike = false;
//     };

//     _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa";

//     if (count _taskPlanWp != 0) then {

//         // add Arrow indicator
//         pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

//         waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};

//         // remove Arrow indicator
//         pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

//         if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
//         _group setVariable ["pl_task_planed", false];
//         _group setVariable ["pl_execute_plan", nil];
//     };

//     if (pl_cancel_strike) exitWith { 
//         deleteMarker _areaMarker; 
//         pl_cancel_strike = false;
//     };


//     // if (pl_enable_beep_sound) then {playSound "beep"};
//     [_group, "confirm", 1] call pl_voice_radio_answer;
//     [_group] call pl_reset;

//     sleep 0.5;

//     [_group] call pl_reset;

//     sleep 0.5;

//     _group setVariable ["onTask", true];
//     _group setVariable ["setSpecial", true];
//     _group setVariable ["specialIcon", _icon];

    
//     _mineMarkers = [];
//     _minePositions = [];
//     _mineFieldSize = pl_mine_field_size;
//     _neededMines = pl_mine_field_size / (pl_mine_spacing / 2);
//     private _mineSpacing = pl_mine_spacing;

//     _mineTypeTxt = "AT";
//     if (_mineType isEqualTo "APERSBoundingMine") then {_mineTypeTxt = "AP"};

//     if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Laying %2 %3 Mines with %4m Spacing",groupId _group, _neededMines, _mineTypeTxt, pl_mine_spacing]};
//     if (pl_enable_map_radio) then {[_group, format ["...Laying %1 %2 Mines with %3m Spacing", _neededMines, _mineTypeTxt, pl_mine_spacing], 20] call pl_map_radio_callout};

//     _usedMines = 0; 
//     _offSet = pl_mine_field_size * 2;
//     _startPos = [((_offSet / 2) - (pl_mine_spacing / 2)) *(sin (_watchDir - 90)), ((_offSet / 2) - (pl_mine_spacing / 2)) *(cos (_watchDir - 90)), 0] vectorAdd _cords;

//     for "_i" from 1 to _neededMines do {
//         _offSet = _offSet - pl_mine_spacing;
//         _mPos =  [_offSet *(sin (_watchDir + 90)), _offSet *(cos (_watchDir + 90)), 0] vectorAdd _startPos;
//         _minePositions pushBack _mPos;
//     };

//     // _minePositions = [_minePositions, [], {_x distance2D _engVic}, "ASCEND"] call BIS_fnc_sortBy;

//     _pos1 = _minePositions#0;
//     _pos2 = _minePositions#(_neededMines - 1);

//     if ((_pos1 distance2D _engVic) < (_pos2 distance2D _engVic)) then {
//         _startPos = _pos1;
//         _endPos = _pos2 getPos [15, _pos1 getDir _pos2];
//     } else {
//         _startPos = _pos2;
//         _endPos = _pos1 getPos [15, _pos2 getDir _pos1];
//         reverse _minePositions;
//     };

//     [_engVic, _startPos, 6] call pl_vic_advance_to_pos_static;

//     sleep 0.25;

//     if !(_group getVariable ["onTask", false]) exitWith {deleteMarker _areaMarker};

//     [_engVic, _endPos, 3] spawn pl_vic_advance_to_pos_static;

//     sleep 0.5;

//     if !(_group getVariable ["onTask", false]) exitWith {deleteMarker _areaMarker};
//     // waitUntil {sleep 0.1;!(_group getVariable ["onTask", false]) or (_engVic distance2D _startPos) > 6};

//     private _i = 0;

//     while {(_group getVariable ["pl_on_march", false]) and (_group getVariable ["onTask", false]) and alive _engVic} do {

//         if (_i > (count _minePositions) - 1) exitWith {};

//         _distance = _startPos distance2D _engVic;
//         if ((round (_distance % _mineSpacing)) == 0) then {

//             [_minePositions#_i, _mineType, _engVic, _watchDir] spawn {
//                 params ["_minePos", "_mineType", "_engVic", "_watchDir"];

//                 waitUntil {sleep 0.25; _engVic distance2D _minePos > 6};
//                 _mine = createMine [_mineType, _minePos, [], 0];
//                 _mine setDir _watchDir;

//                 _cm = createMarker [str (random 3), getPos _mine];
//                 _cm setMarkerType "mil_dot";
//                 _cm setMarkerSize [0.4, 0.4];
//                 _cm setMarkerColor "colorGreen";
//                 _cm setMarkerShadow false;
//                 pl_engineering_markers pushBack _cm;
//             };

//             _usedMines = _usedMines + 1;
//             _i = _i + 1;
//             waitUntil {sleep 0.01; (round (_engVic distance2D _startPos)) % _mineSpacing != 0};
//         };

//         sleep 0.05;
//     };

//     for "_i" from 1 to _usedMines do {
//         {
//             _unitsMines = _x getVariable ["pl_virtual_mines", 0];
//             if (_unitsMines > 0) exitWith {
//                 _x setVariable ["pl_virtual_mines", _unitsMines - 1];
//             };
//         } forEach (units _group);
//     };

//     waitUntil {sleep 0.5; !(_group getVariable ["pl_on_march", false]) or !(_group getVariable ["onTask", false])};

//     if (_group getVariable ["onTask", true]) then {
//         [_group] call pl_reset;
//     };
// };


// dozer_blade_elev_source



// pl_plane_fire_at_pos = {
// 	params ["_plane", "_targetPos", ["_height", 200], ["_weaponTypesID", 3]];

// 	_m = createMarker [str (random 3), _targetpos];
// 	_m setMarkerType "mil_dot";

// 	if (_plane distance2D _targetPos < 4000) then {
// 		_movePos = (getPos _plane) getPos [4500, _targetpos getDir _plane];
// 		_plane doMove _movePos;

// 		waitUntil {sleep 0.25; (_plane distance2D _targetPos) > 4000};
// 	};

// 	_startPos = getPosASL _plane;
// 	// _plane forceSpeed 800;


// 	_planeClass = typeOf _plane;
// 	_planeCfg = configfile >> "cfgvehicles" >> _planeClass;
// 	_weapons = [];
// 	{
// 		if (tolower ((_x call bis_fnc_itemType) select 1) in ["bomblauncher", "missilelauncher", "machinegun"]) then {
// 			_modes = getarray (configfile >> "cfgweapons" >> _x >> "modes");
// 			if (count _modes > 0) then {
// 				_mode = _modes select 0;
// 				if (_mode == "this") then {_mode = _x;};
// 					_weapons set [count _weapons,[_x,_mode]];
// 			};
// 		};
// 	} foreach ((typeOf _plane) call bis_fnc_weaponsEntityType);

// 	if (count _weapons == 0) exitwith {hint "error"};
// 	_planeSide = (getnumber (_planeCfg >> "side")) call bis_fnc_sideType;
// 	private _targetType = if (_planeSide getfriend west > 0.6) then {"CBA_O_InvisibleTargetVehicle"} else {"CBA_B_InvisibleTargetVehicle"};
// 	_target = createvehicle [_targetType,_targetpos,[],0,"none"];
// 	_targetGroup = createVehicleCrew _target;

// 	_plane flyInHeight _height;
// 	_plane doMove _targetPos;
// 	_plane reveal _target;
// 	_plane dowatch _target;
// 	_plane dotarget _target;

// 	// (driver _plane) disableai "target";
// 	// (driver _plane) disableai "autotarget";
// 	group (driver _plane) setCombatmode "blue";
// 	group (driver _plane) setBehaviour "CARELESS";

// 	waitUntil {sleep 0.25; !alive _plane or (getposasl _plane) distance2D _targetpos < 1000};

// 	sleep 2;

// 	{
// 		(driver _plane) fireattarget [_target,(_x select 0)];
// 	} foreach _weapons;


// 	_plane doMove _startPos;
// 	deleteVehicle _target;
// 	deleteGroup _targetGroup;

// };


// [plane_1, getPosASL player] spawn pl_plane_fire_at_pos;

// pl_vehicle_unstuck_to_pos = {
//     params [["_group", (hcSelected player)#0]];
//     private ["_vic", "_cords", "_mPos"];
//     if (vehicle (leader _group) != leader _group) then {

//         _vic = vehicle (leader _group);
//         _type = typeOf _vic;

//         if (visibleMap or !(isNull findDisplay 2000)) then {
//             hintSilent "";
//             hint "Select Unstuck position on MAP (SHIFT + LMB to cancel)";
//             pl_show_obstacles = true;
//             pl_show_obstacles_pos = getPos (leader _group);

//             private _rangelimiter = 20;

//             _markerBorderName = str (random 2);
//             private _borderMarkerPos = getPos (leader _group);
//             if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
//             createMarker [_markerBorderName, _borderMarkerPos];
//             _markerBorderName setMarkerShape "ELLIPSE";
//             _markerBorderName setMarkerBrush "Border";
//             _markerBorderName setMarkerColor "colorOrange";
//             _markerBorderName setMarkerAlpha 0.8;
//             _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

//             onMapSingleClick {
//                 pl_mine_cords = _pos;
//                 pl_mapClicked = true;
//                 if (_shift) then {pl_cancel_strike = true};
//                 hintSilent "";
//                 onMapSingleClick "";
//             };

//             while {!pl_mapClicked} do {
//                 if (visibleMap) then {
//                     _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//                 } else {
//                     _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
//                 };
//             };
//             pl_mapClicked = false;
//             if (pl_cancel_strike) exitWith {
//                 pl_show_obstacles = false;
//                 pl_mapClicked = false;
//             };

//             _cords = _mPos;
//             deleteMarker _markerBorderName;
//             pl_show_obstacles = false;
//             pl_mapClicked = false;
//         }
//         else
//         {
//             _cords = screenToWorld [0.5, 0.5];
//             _rangelimiter = 20;
//             if (_cords distance2D (getpos (leader _group))) > _rangelimiter then {
//                 hint "Out of Range";
//             };
//         };

//         if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

//         _vic setVehiclePosition [_cords, [], 0, "NONE"];
//     }
//     else
//     {
//         hint "Only for Vehicles";
//     };
// };





pl_get_grenade_muzzle = {
	// AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
	params ["_grenade"];
	_muzzleRaw = (format ["%1 in (getArray (_x >> 'Magazines'))", str _grenade]) configClasses (configfile >> "CfgWeapons" >> "Throw");

	_muzzleRawArray = ((str(_muzzleRaw#0)) splitString "/");
	_muzzle = _muzzleRawArray select ((count _muzzleRawArray) - 1);

	_muzzle
};

_oof = ["gm_handgrenade_frag_dm51a1"] call pl_get_grenade_muzzle;

systemChat _oof;