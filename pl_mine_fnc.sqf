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

pl_mine_clearing = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_cords", "_engineer", "_mines"];

    _group = (hcSelected player) select 0;

    _engineer = {
        if ("MineDetector" in (items _x) and "ToolKit" in (items _x)) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _engineer) exitWith {hint "No mineclearing equipment"};

    pl_mine_sweep_area_size = 35;

    _markerName = format ["%1mineSweeper", _group];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";;
    _markerName setMarkerColor "colorORANGE";
    _markerName setMarkerAlpha 0.5;
    _markerName setMarkerSize [pl_mine_sweep_area_size, pl_mine_sweep_area_size];

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

    if (visibleMap) then {
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
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            if ((_mPos distance2D (leader _group)) <= _rangelimiter) then {
                _markerName setMarkerPos _mPos;
            };
            if (inputAction "MoveForward" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size + 5; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_mine_sweep_area_size = pl_mine_sweep_area_size - 5; sleep 0.05};
            _markerName setMarkerSize [pl_mine_sweep_area_size, pl_mine_sweep_area_size];
            if (pl_mine_sweep_area_size >= 80) then {pl_mine_sweep_area_size = 80};
            if (pl_mine_sweep_area_size <= 5) then {pl_mine_sweep_area_size = 5};
        };

        player enableSimulation true;

        pl_mapClicked = false;
        _cords = getMarkerPos _markerName;
        _markerName setMarkerPos _cords;
        _markerName setMarkerAlpha 0.3;
        deleteMarker _markerBorderName;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};

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
        [_x, getPos _x, _x getDir _cords, 15, false] spawn pl_find_cover;
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
    } forEach [_engineer, _escort];
    pl_at_attack_array pushBack [_engineer, _cords, _escort];

    _mines = allMines select {(_x distance2D _cords) < pl_mine_sweep_area_size + 3};

    while {count _mines > 0} do {

        _mine = ([_mines, [], { _engineer distance _x }, "ASCEND"] call BIS_fnc_sortBy)#0;
        _pos = getPosATL _mine;
        _engineer doMove _pos;
        _escort doFollow _engineer;

        sleep 0.5;

        waitUntil {sleep 0.5; ((_engineer distance2D _pos) < 1) or (unitReady _engineer) or !(_group getVariable ["onTask", true])};

        if !(_group getVariable ["onTask", true]) exitWith {};

        _engineer action ["Deactivate", _engineer, _mine];

        _mines deleteAt (_mines find _mine);

        sleep 2;
    };

    if (_group getVariable ["onTask", true]) then {
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Mine Sweep complete", groupId _group]};
        if (pl_enable_map_radio) then {[_group, "...Mine Sweep Complete", 20] call pl_map_radio_callout};
        [_group] call pl_reset;
    };
    pl_at_attack_array = pl_at_attack_array - [[_engineer, _cords, _escort]];
    deleteMarker _markerName
};


pl_mine_field_size = 16;
pl_Mine_field_cords = [0,0,0];
pl_mine_spacing = 4;

pl_lay_mine_field = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_group", "_exSpecialist", "_cords", "_areaMarker", "_watchDir", "_mineMarkers", "_neededMines", "_minePositions", "_usedMines", "_mineType", "_origPos", "_availableMines", "_text"];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry Only Task!"};

    if !(visibleMap) exitWith {hint "Open Map to lay Mine field"};
    _exSpecialist = {
        if (_x getUnitTrait "explosiveSpecialist") exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _exSpecialist) exitWith {hint "No Explosive Specialist in Group!"};

    _availableMines = 0;
    {
        _mines = _x getVariable ["pl_virtual_mines", 0];
        _availableMines = _availableMines + _mines;
    } forEach (units _group);

    if (_availableMines <= 0) exitWith {hint "No Mines Left!"};

    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: %2 Mines Available",groupId _group, _availableMines]};
    if (pl_enable_map_radio) then {[_group, format ["...%1 Mines Available",_availableMines], 15] call pl_map_radio_callout};

    hintSilent "";
    pl_mine_field_size = 16;
    pl_mine_type = "ATMine";
    _maxFieldSize = pl_mine_spacing * 20;
    _mineFieldSize = pl_mine_spacing * 2;

    _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br /> <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
    hint parseText _message;

    _areaMarker = format ["%1mineField%2", _group, random 2];
    createMarker [_areaMarker, [0,0,0]];
    _areaMarker setMarkerShape "RECTANGLE";
    // _areaMarker setMarkerBrush "Cross";
    _areaMarker setMarkerBrush "SolidBorder";
    _areaMarker setMarkerColor "colorRED";
    _areaMarker setMarkerAlpha 0.8;
    _areaMarker setMarkerSize [pl_mine_field_size, 3];

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
        _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
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
        pl_cancel_strike = false;
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
        if (_shift) then {pl_cancel_strike = true};
        if (_alt) then {pl_mine_type = "APERSBoundingMine"};
        onMapSingleClick "";
    };

    player enableSimulation false;

    while {!pl_mapClicked} do {
        _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
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

    _mineType = pl_mine_type;
    _areaMarker setMarkerAlpha 0.5;
    hintSilent "";
    pl_mapClicked = false;

    if (pl_cancel_strike) exitWith { 
        deleteMarker _areaMarker; 
        pl_cancel_strike = false;
    };

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa";

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

    private _escort = {
        if (_x != (leader _group) and _x != _exSpecialist) exitWith {_x};
        objNull
    } forEach (units _group);

    {
        [_x, getPos _x, _x getDir _cords, 15, false] spawn pl_find_cover;
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
    } forEach [_exSpecialist, _escort];
    pl_at_attack_array pushBack [_exSpecialist, _cords, _escort];

    reverse _minePositions;

    {
        _exSpecialist doMove _x;
        _escort doFollow _exSpecialist;
        sleep 1;
        waitUntil {sleep 0.5; (!alive _exSpecialist) or (unitReady _exSpecialist) or !(_group getVariable ["onTask", true])};

        if !(_group getVariable ["onTask", true] and alive _exSpecialist and !(_exSpecialist getVariable ["pl_wia", false])) exitWith {};

        _exSpecialist setUnitPos "Middle";
        _exSpecialist playAction "PutDown";
        sleep 2.5;
        _mine = createMine [_mineType, _x, [], 0];
        _mine setDir _watchDir;
        _usedMines = _usedMines + 1;
        _exSpecialist setUnitPos "Auto";

        // _m = createMarker [str (random 5), _x];
        // _m setMarkerType "mil_dot";
        // _m setMarkerColor "colorRED";
        // _m setMarkerSize [0.5, 0.5];

        // _mineMarkers pushBack _m;
    } forEach _minePositions;

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
    }
    else
    {
        deleteMarker _areaMarker;
    };
    pl_at_attack_array = pl_at_attack_array - [[_exSpecialist, _cords, _escort]];
};

pl_groups_with_charges = [];

pl_place_charge = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_cords", "_exSpecialist", "_availableMines", "_markerName"];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry Only Task!"};

    _exSpecialist = {
        if (_x getUnitTrait "explosiveSpecialist" and ((_x getVariable ["pl_virtual_mines", 0]) > 0)) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _exSpecialist) exitWith {hint "No Explosive Specialist in Group!"};

    _availableMines = _exSpecialist getVariable ["pl_virtual_mines", 0];

    if (visibleMap) then {
        hintSilent "";
        hint "Select MINE position on MAP (SHIFT + LMB to cancel)";
        pl_show_obstacles = true;
        pl_show_obstacles_pos = getPos (leader _group);

        _markerName = createMarker ["pl_charge_range_marker", [0,0,0]];
        _markerName setMarkerColor "colorOrange";
        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "Border";
        _markerName setMarkerSize [25, 25];

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
            pl_mine_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
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
        _cords = screenToWorld [0.5, 0.5];
        _rangelimiter = 60;
        if (_cords distance2D (getpos (leader _group))) > _rangelimiter then {
            hint "Out of Range";
        };
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa";
    
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

    if (pl_cancel_strike) exitWith {deleteMarker _markerName; pl_cancel_strike = false};

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    private _escort = {
        if (_x != (leader _group) and _x != _exSpecialist) exitWith {_x};
        objNull
    } forEach (units _group);

    {
        [_x, getPos _x, _x getDir _cords, 15, false] spawn pl_find_cover;
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

    _exSpecialist doMove _cords;
    _escort doFollow _exSpecialist;

    sleep 1;
    waitUntil {sleep 0.5; (!alive _exSpecialist) or (unitReady _exSpecialist) or !(_group getVariable ["onTask", true])};

    _charges = _group getVariable ["pl_placed_charges", []];
    if (_group getVariable ["onTask", true] and alive _exSpecialist and !(_exSpecialist getVariable ["pl_wia", false])) then {
        _exSpecialist setUnitPos "Middle";
        _exSpecialist playAction "PutDown";
        sleep 3;
        _charge = createMine ["DemoCharge_F", _cords, [], 0];
        _charges pushBack _charge;
        _exSpecialist setUnitPos "Auto";
        _exSpecialist enableAI "AUTOCOMBAT";
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
            if ((_x distance2D _charge) < 25) then {
                    deleteVehicle _x;
                };
        } forEach (allDead - allDeadMen);
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
    private ["_cords", "_exSpecialist", "_bridges", "_bridgeMarkers", "_wp", "_charge"];

    _exSpecialist = {
        if (_x getUnitTrait "explosiveSpecialist" and ((_x getVariable ["pl_virtual_mines", 0]) > 0)) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _exSpecialist) exitWith {hint format ["%1 has no Engineer!", groupId _group]};

    if (visibleMap) then {

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
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
                _markerName setMarkerPos _mPos;
            };
        };

        pl_mapClicked = false;
        _cords = getMarkerPos _markerName;
        deleteMarker _markerName;
        deleteMarker _markerBorderName;
    }
    else
    {
        _cords = screenToWorld [0.5, 0.5];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

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
        [_x, getPos _x, _x getDir _cords, 15, false] spawn pl_find_cover;
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

    if (pl_enable_beep_sound) then {playSound "beep"};
    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Bridge Destroyed", (groupId _group)]};
    if (pl_enable_map_radio) then {[_group, "...Bridge Destroyed", 20] call pl_map_radio_callout};
};


