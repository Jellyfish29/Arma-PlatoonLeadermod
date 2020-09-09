pl_mine_cls = ["APERSMineDispenser_Mag", "APERSBoundingMine_Range_Mag", "APERSMine_Range_Mag", "ATMine_Range_Mag", "SLAMDirectionalMine_Range_Mag", "ClaymoreDirectionalMine_Remote_Mag", "DemoCharge_Remote_Mag", "SatchelCharge_Remote_Mag", "ClaymoreDirectionalMine_Remote_Mag"];
// "APERSTripMine_Wire_Mag"

pl_get_group_mines = {
    params ["_group"];
    private ["_groupMines"];

    _groupMines = [];

    {
        _unit = _x;
        _mines = (magazines _unit) select {_x in pl_mine_cls};
        {
            _groupMines pushBack [_x, _unit];
        } forEach _mines;
    } forEach (units _group);
    _groupMines
};

pl_create_mine_menu = {
    private ["_group", "_idx", "_mine", "_unit"];
    _group = (hcSelected player) select 0; 
    _groupMines = [_group] call pl_get_group_mines;
    pl_test = _groupMines;

    _menuStr = "pl_mine_menu = [['Available Mines', true],";
    pl_mine_idx = -1;
    _idx = 0;
    {
        _mine = _x select 0;
        _unit = _x select 1;
        _mineName = getText (configFile >> "CfgMagazines" >> _mine >> "displayName");
        _unitName = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName");
        _menuStr = _menuStr + format ["['%1 (%2)', [%3 + 2], '', -5, [['expression', 'pl_mine_idx = %3']], '1', '1'],", _mineName, _unitName, _idx];
        _idx = _idx + 1;
    } forEach _groupMines;
    _menuStr = _menuStr + "['', [], '', -5, [['expression', '']], '0', '0']]";
    call compile _menuStr;

    showCommandingMenu "#USER:pl_mine_menu";

    _time = time + 20;
    waitUntil {pl_mine_idx != -1 or commandingMenu == ""};
    if (pl_mine_idx == -1) exitWith {};
    _mineUnit = _groupMines select pl_mine_idx;
    [_mineUnit#0, _group, _mineUnit#1] call pl_place_mine;
    pl_mine_idx = -1;
};

pl_get_closest_mine = {
    params ["_unit"];

    _mines = allMines;
    _mine = ([_mines, [], { _unit distance2D _x }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    _mine
};

pl_place_mine = {
    params ["_mine", "_group", "_unit"];
    private ["_cords", "_mineDir"];


    if (visibleMap) then {
        hintSilent "";
        hint "Select MINE position on MAP (SHIFT + LMB to cancel)";

        onMapSingleClick {
            pl_mine_cords = _pos;
            pl_mapClicked = true;
            pl_show_draw_mine_dir = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {sleep 0.1;};
        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {};

        _cords = pl_mine_cords;

        hint "Select MINE facing on MAP (SHIFT + LMB to cancel)";

        onMapSingleClick {
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _mineDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            sleep 0.1;
        };
        pl_mapClicked = false;
        pl_show_draw_mine_dir = false;
    }
    else
    {
        _cords = screenToWorld [0.5, 0.5];
        _mineDir = getDir player;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    // kompleter scheiß, weil _unit einfach randam sein Value aendert
    missionNamespace setVariable ["mine_unit", _unit];
    if ((_unit distance2D _cords) > 75) exitWith {hint "Group needs to be within 75 Meters of position!"};
    if (_unit getVariable ["pl_mining_task", false]) exitWith {hint "Unit is already placing a mine!"};
    
    [_group] call pl_reset;
    sleep 0.2;
    _unit = missionNamespace getVariable "mine_unit";

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"];
    _unit setVariable ["pl_mining_task", true];
    _mineVic = (_mine splitString "_") select 0;
    [_group, _unit, _mine, _mineVic, _cords, _mineDir] spawn {
        params ["_group", "_unit", "_mine", "_mineVic", "_cords", "_mineDir"];

        _unit disableAI "AUTOCOMBAT";
        _unit doMove _cords;

        waitUntil {unitReady _unit or !(_group getVariable ["onTask", true])};

        _unit enableAI "AUTOCOMBAT";
        _muzzles = getArray (configFile >> "CfgWeapons" >> "Put" >> "muzzles");

        _muzzle = {
            _mags = getArray (configFile >> "CfgWeapons" >> "Put" >> _x >> "magazines");
            if (_mine in _mags) exitWith {_x};
            objNull
        } forEach _muzzles;

        // _unit playActionNow "PutDown";
        _unit fire [_muzzle, _muzzle, _mine];
        sleep 1.5;
        _mines = allMines;
        _mine = ([_mines, [], { _unit distance2D _x }, "ASCEND"] call BIS_fnc_sortBy) select 0;
        // playerSide reveal _mine;
        player addOwnedMine _mine;
        _mine setDir _mineDir;

        sleep 1;
        _unit setVariable ["pl_mining_task", nil];
        [_group] call pl_reset;
    };
    {
        _x disableAI "AUTOCOMBAT";
        [_x, (getPos _x), 0, 10, false] spawn pl_find_cover;
    } forEach (units _group) - [_unit];
};

pl_mine_clearing = {
    private ["_group", "_cords", "_engineer", "_mines"];

    _group = (hcSelected player) select 0;

    _engineer = {
        if ("MineDetector" in (items _x) and "ToolKit" in (items _x)) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _engineer) exitWith {hint "No mineclearing equipment"};

    _markerName = format ["%1mineSweeper", _group];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Vertical";
    _markerName setMarkerColor "colorYellow";
    _markerName setMarkerAlpha 0.5;
    _markerName setMarkerSize [35, 35];

    if (visibleMap) then {
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
        while {!pl_mapClicked} do {
            // sleep 0.1;
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerName setMarkerPos _mPos;
        };
        pl_mapClicked = false;
        _cords = pl_sweep_cords;
    };

    [_group] call pl_reset;
    sleep 0.2;

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"];

    _wp = _group addWaypoint [_cords, 0];

    waitUntil {sleep 0.1; (((leader _group) distance _cords) < (50)) or !(_group getVariable ["onTask", true])};

    [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
    sleep 0.1;
    for "_i" from count waypoints _group - 1 to 0 step -1 do {
        deleteWaypoint [_group, _i];
    };

    _mines = allMines select {(_x distance2D _cords) < 35};
    _mines = [_mines, [], { _engineer distance _x }, "ASCEND"] call BIS_fnc_sortBy;

    {
        [_x, getPos _x, 0, 10, false] spawn pl_find_cover;
    } forEach (units _group) - [_engineer];

    if ((count _mines) > 0) then {
        {
            _pos = getPosATL _x;
            _engineer doMove _pos;

            sleep 0.5;

            waitUntil {((_engineer distance2D _pos) < 1.8) or (unitReady _engineer) or !(_group getVariable ["onTask", true])};

            if !(_group getVariable ["onTask", true]) exitWith {};

            _engineer action ["Deactivate", _engineer, _x];

        } forEach _mines;
    }
    else
    {
        _engineer doMove _cords;
        waitUntil {(unitReady _engineer) or !(_group getVariable ["onTask", true])};
    };

    if (_group getVariable ["onTask", true]) then {
        (leader _group) sideChat format ["%1: Mine Sweep complete", groupId _group];
        [_group] call pl_reset;
    };
    deleteMarker _markerName
};

