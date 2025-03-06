

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

        _targets = _triggerPos nearEntities [["Tank", "Car"], 20];

        if (_targets isNotEqualTo []) then {
            [getPosASLVisual _mine, "R_TBG32V_F", _targets#0, 90, true, [0,0,0.25], 2, "", false] spawn BIS_fnc_EXP_camp_guidedProjectile;
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

    private _triggerPos = _minePos getPos [15, _mineDir];

    private _mineMarker = createMarker [str (random 5), _minePos];
    _mineMarker setMarkerType "marker_ap_dir_mine";
    _mineMarker setMarkerColor "colorGreen";
    _mineMarker setMarkerSize [0.4, 0.4];
    _mineMarker setMarkerDir _mineDir;

    private _mineMarkerArea = createMarker [str (random 5), _triggerPos];
    _mineMarkerArea setMarkerShape "RECTANGLE";
    _mineMarkerArea setMarkerBrush "SolidBorder";
    _mineMarkerArea setMarkerColor "colorGreen";
    _mineMarkerArea setMarkerSize [15, 15];
    _mineMarkerArea setMarkerAlpha 0.8;
    _mineMarkerArea setMarkerDir _mineDir;
 
    private _targets = [];

    sleep 15;

    while {mineActive _mine} do {

        _targets = _triggerPos nearEntities [["Man"], 15];

        if (_targets isNotEqualTo []) then {
            _mine setDamage 1;
        };

        sleep 1;
    };

    deleteMarker _mineMarker;
    deleteMarker _mineMarkerArea;

};


pl_place_dir_mine = {
    params ["_mineType", ["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_mineDir","_mPos", "_cords", "_exSpecialist", "_availableMines", "_markerName", "_markerBorderName", "_rangelimiter"];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry Only Task!"};

    _exSpecialist = {
        if (_x getUnitTrait "explosiveSpecialist" and ((_x getVariable ["pl_virtual_mines", 0]) > 0) and alive _x and lifeState _x isNotEqualto "INCAPACITATED") exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _exSpecialist) exitWith {hint "No Explosive Specialist in Group!"};

    _availableMines = _exSpecialist getVariable ["pl_virtual_mines", 0];

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

        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            
            _markerName setMarkerPos _mPos;
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

    private _escort = {
        if (_x != (leader _group) and _x != _exSpecialist and alive _x and lifeState _x isNotEqualto "INCAPACITATED") exitWith {_x};
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

    waitUntil {sleep 0.5; unitReady _exSpecialist or !alive _exSpecialist};

    _exSpecialist doMove _cords;
    _escort doFollow _exSpecialist;

    sleep 1;
    waitUntil {sleep 0.5; (!alive _exSpecialist) or (unitReady _exSpecialist) or !(_group getVariable ["onTask", true])};

    _charges = _group getVariable ["pl_placed_charges", []];
    if (_group getVariable ["onTask", true] and alive _exSpecialist and !(_exSpecialist getVariable ["pl_wia", false]) and (_exSpecialist distance2D _cords) <= 5) then {
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
                    _areaMarker setMarkerColor "colorGreen";
                    _areaMarker setMarkerAlpha 0.8;
                    _areaMarker setMarkerSize [17, 17];
                    _areaMarker setMarkerDir _mineDir;
                    pl_engineering_markers pushBack _areaMarker;


                    [_exSpecialist, _mine] spawn {
                        params ["_exSpecialist", "_mine"];

                        _exSpecialist addOwnedMine _mine;

                        sleep 8;

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

    deleteMarker _markerName;
    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
    };
    pl_at_attack_array = pl_at_attack_array - [[_exSpecialist, _cords, _escort]];
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

    private _escort = {
        if (_x != (leader _group) and _x != _exSpecialist and alive _x and lifeState _x isNotEqualto "INCAPACITATED") exitWith {_x};
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
    } forEach [_exSpecialist, _escort];
    pl_at_attack_array pushBack [_exSpecialist, _cords, _escort];

    reverse _minePositions;

    waitUntil {sleep 0.5; unitReady _exSpecialist or !alive _exSpecialist};

    {
        _exSpecialist doMove _x;
        _escort doFollow _exSpecialist;
        sleep 1;
        waitUntil {sleep 0.5; (!alive _exSpecialist) or (unitReady _exSpecialist) or !(_group getVariable ["onTask", true])};

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


pl_task_plan_menu_eng_sub = [
    ['Task Plan Combat Engineering', true],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"/><t> Place AT Mine Field</t>', [2], '', -5, [['expression', '["ATmine"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"/><t> Place AP Mine Field</t>', [3], '', -5, [['expression', '["APmine"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\Plmod\gfx\pl_at_dir_mine.paa"/><t> Place AT Directional Mine</t>', [4], '', -5, [['expression', '["ATDIRmine"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\Plmod\gfx\pl_ap_dir_mine.paa"/><t> Place AP Directional Mine</t>', [5], '', -5, [['expression', '["APDIRmine"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\Plmod\gfx\pl_ap_dir_mine.paa"/><t> Place AP Dispenser Mine</t>', [6], '', -5, [['expression', '["APDISDIRmine"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"/><t> Clear Mine Field</t>', [7], '', -5, [['expression', '["mineclear"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Deploy Mine Clearing Line Charge</t>', [8], '', -5, [['expression', '["mc_lc"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Place Charge</t>', [9], '', -5, [['expression', '["charge"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa"/><t> Deploy Vehicle Launched Bridge</t>', [0], '', -5, [['expression', '["createbridge"] call pl_task_planer']], '1', '1']
];


pl_task_planer = {
    // plan Task to be executed when reaching a Waypoint

    params ["_taskType"];
    private ["_group", "_wp", "_icon"];

    // get _wp and _group
    _logic = player getvariable "BIS_HC_scope";
    _wp = _logic getvariable "WPover";
    if ((count _wp) == 1) exitWith {hint "Keep Cursor Over Waypoint To Plan Task!"};
    _group = _wp select 0;
    
    // if Task already planed exit
    if (_group getVariable ["pl_task_planed", false]) exitWith {hint format ["%1 already has a Task planed", groupId _group]};

    // if already on active Task exit
    if (_group getVariable ["onTask", false] and !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa")) exitWith {hint format ["%1 already has a Task", groupId _group]};

    // delete following wps
    for "_i" from count waypoints _group - 1 to (_wp select 1) + 1 step -1 do {
            deleteWaypoint [_group, _i];
    };

    // set Variable
    _group setVariable ["pl_task_planed", true];
    _wp setWaypointStatements ["true", "(group this) setVariable ['pl_execute_plan', true]"];

    // call task to be executed
    switch (_taskType) do { 
        case "assault" : {[_group, _wp] spawn pl_assault_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa"};
        case "defend" : {[_group, _wp] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "resupply" : {[_group, _wp] spawn pl_supply_point; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"};
        case "recover" : {[_group, _wp] spawn pl_repair; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"};
        case "ATmine" : {[1, _group, _wp] spawn pl_lay_mine_field_switch; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "APmine" : {[2, _group, _wp] spawn pl_lay_mine_field_switch; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "ATDIRmine" : {[1, _group, _wp] spawn pl_place_dir_mine; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "APDIRmine" : {[2, _group, _wp] spawn pl_place_dir_mine; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "APDISDIRmine" : {[3, _group, _wp] spawn pl_place_dir_mine; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "charge" : {[_group, _wp] spawn pl_place_charge; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"};
        case "unload" : {[_group, _wp] spawn pl_unload_at_position_planed; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"};
        case "load" : {[_group, _wp] spawn pl_getIn_vehicle; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};
        case "crew" : {[_group, _wp] spawn pl_crew_vehicle; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};
        case "leave" : {[_group, _wp] spawn pl_leave_vehicle; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"};
        case "mineclear" : {[_group, _wp] spawn pl_mine_clearing; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"};
        case "ccp" : {[_group, false, objNull, 100, 25, objNull, _wp] spawn pl_ccp; _icon = "\Plmod\gfx\pl_ccp_marker.paa"};
        case "sfp" : {[_group, _wp, [], 0, true] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "garrison" : {[_group, _wp] spawn pl_garrison; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};
        case "mech" : {[_group, _wp] spawn pl_change_kampfweise; _icon = "\Plmod\gfx\pl_mech_task.paa"};
        case "createbridge" : {[_group, _wp] spawn pl_create_bridge; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa"};
        case "mc_lc" : {[_group, _wp] spawn pl_mc_lc; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"};
        default {}; 
    };

    // add indicator
    pl_draw_planed_task_array pushBack [_wp, _icon];

    // waituntil wp reached then delete indicator
    [_wp, _group, _icon] spawn {
        params ["_wp", "_group", "_icon"];
        waitUntil {sleep 1; !(_group getVariable ["pl_task_planed", true])};
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    };
};

pl_task_planer_unload_inf = {
    // plan Task to be executed when reaching a Waypoint
    params ["_taskType"];
    private ["_group", "_wp", "_icon"];

    // get _wp and _group
    _group = (missionNamespace getVariable "pl_unload_inf_group_array")#0;
    _cords = (missionNamespace getVariable "pl_unload_inf_group_array")#1;
    _wp = _group addWaypoint [_cords, 0];

    sleep 0.2;

    // set Variable
    _group setVariable ["pl_task_planed", true];
    _group setVariable ["pl_unload_task_planed", true];
    _wp setWaypointStatements ["true", "(group this) setVariable ['pl_execute_plan', true]"];

    // call task to be executed
    switch (_taskType) do { 
        case "assault" : {[_group, _wp] spawn pl_assault_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa"};
        case "defend" : {[_group, _wp] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "resupply" : {[_group, _wp] spawn pl_supply_point; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"};
        case "recover" : {[_group, _wp] spawn pl_repair; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"};
        case "ATmine" : {[1, _group, _wp] spawn pl_lay_mine_field_switch; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "APmine" : {[2, _group, _wp] spawn pl_lay_mine_field_switch; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "ATDIRmine" : {[1, _group, _wp] spawn pl_place_dir_mine; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "APDIRmine" : {[2, _group, _wp] spawn pl_place_dir_mine; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "APDISDIRmine" : {[3, _group, _wp] spawn pl_place_dir_mine; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "charge" : {[_group, _wp] spawn pl_place_charge; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"};
        case "unload" : {[_group, _wp] spawn pl_unload_at_position_planed; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"};
        case "load" : {[_group, _wp] spawn pl_getIn_vehicle; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};
        case "crew" : {[_group, _wp] spawn pl_crew_vehicle; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};
        case "leave" : {[_group, _wp] spawn pl_leave_vehicle; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"};
        case "mineclear" : {[_group, _wp] spawn pl_mine_clearing; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"};
        case "ccp" : {[_group, false, objNull, 100, 25, objNull, _wp] spawn pl_ccp; _icon = "\Plmod\gfx\pl_ccp_marker.paa"};
        case "sfp" : {[_group, _wp, [], 0, true] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "garrison" : {[_group, _wp] spawn pl_garrison; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};
        case "mech" : {[_group, _wp] spawn pl_change_kampfweise; _icon = "\Plmod\gfx\pl_mech_task.paa"};
        case "createbridge" : {[_group, _wp] spawn pl_create_bridge; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa"};
        case "mc_lc" : {[_group, _wp] spawn pl_mc_lc; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"};
        default {}; 
    };

    // add indicator
    pl_draw_planed_task_array pushBack [_wp, _icon];

    // waituntil wp reached then delete indicator
    [_wp, _group, _icon] spawn {
        params ["_wp", "_group", "_icon"];
        waitUntil {!(_group getVariable ["pl_task_planed", true])};
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    };
};

pl_task_plan_menu_unloaded_inf = [
    ['Task Plan', true],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa'/><t> Assault Position</t>", [2], '', -5, [['expression', '["assault"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText "<img color='#e5e500' image='\Plmod\gfx\pl_position.paa'/><t> Defend Position</t>", [3], '', -5, [['expression', '["defend"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText "<img color='#e5e500' image='\Plmod\gfx\sfp.paa'/><t> Support by Fire</t>", [4], '', -5, [['expression', '["sfp"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa'/><t> Garrison Building</t>", [5], '', -5, [['expression', '["garrison"] spawn pl_task_planer_unload_inf']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\3den\data\Attributes\SpeedMode\normal_ca.paa'/><t> Add Waypoints</t>", [6], '', -5, [['expression', '["addwp"] spawn pl_task_planer_unload_inf']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1'],
    [parseText '<img color="#e5e500" image="\Plmod\gfx\pl_eng_task.paa"/><t> Combat Engineering Tasks</t>', [7], '#USER:pl_task_plan_menu_eng_sub_unloaded_inf', -5, [['expression', '']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1'],
    [parseText '<img color="#e5e500" image="\Plmod\gfx\pl_ccp_marker.paa"/><t> Set Up Casualty Collection Point</t>', [10], '', -5, [['expression', '["ccp"] spawn pl_task_planer_unload_inf']], '1', '1']
];

pl_task_plan_menu_eng_sub_unloaded_inf = [
    ['Task Plan Combat Engineering', true],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Place Charge</t>', [2], '', -5, [['expression', '["charge"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"/><t> Place AT Mine Field</t>', [3], '', -5, [['expression', '["ATmine"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"/><t> Place AP Mine Field</t>', [4], '', -5, [['expression', '["APmine"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText '<img color="#e5e500" image="\Plmod\gfx\pl_at_dir_mine.paa"/><t> Place AT Directional Mine</t>', [5], '', -5, [['expression', '["ATDIRmine"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText '<img color="#e5e500" image="\Plmod\gfx\pl_ap_dir_mine.paa"/><t> Place AP Directional Mine</t>', [6], '', -5, [['expression', '["APDIRmine"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText '<img color="#e5e500" image="\Plmod\gfx\pl_ap_dir_mine.paa"/><t> Place AP Dispenser Mine</t>', [7], '', -5, [['expression', '["APDISDIRmine"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"/><t> Clear Mine Field</t>', [8], '', -5, [['expression', '["mineclear"] spawn pl_task_planer_unload_inf']], '1', '1']
    
];


// {
//     west revealMine _x;
// } forEach allMines