
pl_rearm = {

    params ["_unit", "_target"];

    if !(isNull _target) then {
        if (_unit getVariable "pl_wia") exitWith {};
        createMarker ["sup_zone_marker", (getPos _target)];
        "sup_zone_marker" setMarkerType "b_support";
        "sup_zone_marker" setMarkerText "Supply Point";

        _unit disableAI "AUTOCOMBAT";
        _unit doMove (position _target);
        _unit moveTo (position _target);

        waitUntil {sleep 0.1; ((_unit distance2D  _target) < 8) or !((group _unit) getVariable ["onTask", true])};
        _unit action ["rearm",_target];
        0 = [_unit, "Rearming..."] remoteExecCall ["groupChat",[0,-2] select isDedicated,false];
        sleep 1;
        if ((secondaryWeapon _unit) != "") then {
            sleep 3;
            _unit action ["rearm",_target];
            0 = [_unit, "Rearming..."] remoteExecCall ["groupChat",[0,-2] select isDedicated,false];
        };

        _unit enableAI "AUTOCOMBAT";

        _time = time + 20;
        waitUntil {sleep 0.1; (time > _time) or !((group _unit) getVariable ["onTask", true])};
        deleteMarker "sup_zone_marker";
        (group _unit) setVariable ["setSpecial", false];
        (group _unit) setVariable ["onTask", true];
    };
};

pl_spawn_rearm = {
    private ["_box", "_magAmount"];
    {
        if (vehicle (leader _x) != leader _x) exitWith {hint "Infantry ONLY Task!"};
        if (visibleMap) then {
            _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _supplies = _cords nearSupplies 100;
            _magAmount = 0;

            if (count _supplies > 0) then {
                {
                    if !(_x isKindOf "Man") then {
                        _cargo = magazineCargo _x;
                        if (count _cargo > _magAmount) then {
                            _magAmount = count _cargo;
                            _box = _x;
                        };
                    };
                } forEach _supplies;

                [_x] call pl_reset;
                sleep 0.2;

                playSound "beep";

                _x setVariable ["setSpecial", true];
                _x setVariable ["onTask", true];
                _x setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"];    
            
                _boxName = getText (configFile >> "CfgVehicles" >> typeOf _box >> "displayName");
                playSound "beep";
                (leader _x) sideChat format ["%1: Resupplying at %2", (groupId _x), _boxName];

                {
                    [_x, _box] spawn pl_rearm; 
                } forEach units _x;
            }
            else
            {
                playSound "beep";
                leader _x sideChat "Negativ, There are no avaiable Supplies, Over";
            };
        }
        else
        {
            _supplies = cursorTarget nearSupplies 10;
            if (count _supplies > 0) then {
                _box = cursorTarget;
                if !(_box isKindOf "Man") then {

                    [_x] call pl_reset;
                    sleep 0.2;

                    _x setVariable ["setSpecial", true];
                    _x setVariable ["onTask", true];
                    _x setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"];
                    _boxName = getText (configFile >> "CfgVehicles" >> typeOf _box >> "displayName");
                    playSound "beep";
                    (leader _x) sideChat format ["%1: Resupplying at %2", (groupId _x), _boxName];
                    {
                        [_x, _box] spawn pl_rearm; 
                    } forEach units _x;
                }
                else
                {
                    // playSound "beep";
                    hint "No avaiable Supplies!";
                };
            }
            else
            {
                // playSound "beep";
                hint "No avaiable Supplies!";
            };
        };

    } forEach hcSelected player;
};

// call pl_spawn_rearm;


pl_supply_area_size = 25;

pl_resupply = {
    params ["_group", ["_taskPlanWp", []]];
    private ["_cords", "_limiter", "_targets", "_markerName", "_wp", "_icon", "_supplies"];

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    _markerName = format ["%1resupply", _group];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Vertical";
    _markerName setMarkerColor "colorBLUFOR";
    _markerName setMarkerAlpha 0.5;
    _markerName setMarkerSize [pl_supply_area_size, pl_supply_area_size];
    if (visibleMap) then {
        _message = "Select Resupply Area <br /><br />
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
    }
    else
    {
        _vic = cursorTarget;
        if !(isNil "_vic") then {
            _cords = getPos _vic;
        };
    };

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa";

    if (count _taskPlanWp != 0) then {

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11) or !(_group getVariable ["pl_task_planed", false])};

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};

    _supplies = _cords nearSupplies pl_supply_area_size;
    if ((count _supplies) == 0) exitWith {deleteMarker _markerName; hint "No availble Supplies in Area!"};

    [_group] call pl_reset;
    sleep 0.2;
    
    playsound "beep";

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    (leader _group) limitSpeed 15;

    _markerName setMarkerPos _cords;

    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);

    _wp = _group addWaypoint [_cords, 0];

    pl_draw_planed_task_array pushBack [_wp, _icon];
    _group setBehaviour "AWARE";

    waitUntil {sleep 0.1; (((leader _group) distance _cords) < (pl_supply_area_size)) or !(_group getVariable ["onTask", true])};

    [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
    sleep 0.1;
    for "_i" from count waypoints _group - 1 to 0 step -1 do {
        deleteWaypoint [_group, _i];
    };

    {
        _unit = _x;
        _box = selectRandom _supplies;

        [_unit, _box, _supplies] spawn {
            params ["_unit", "_box", "_supplies"];

            // move to box
            private _pos = getPosATL _box;
            _unit doMove _pos;
            _unit moveTo _pos;

            // wait unit box reached
            waitUntil {!alive _unit or (_unit distance2D _pos) < 4 or !((group _unit) getVariable ["onTask", true])};

            // if Task canceled exit
            if !((group _unit) getVariable ["onTask", true]) exitWith {};

            // rearm on each box
            {
                _unit action ["rearm", _x];
            } forEach _supplies;

            // get Items to be added to backpack
            _startBackpackLoad = _unit getVariable "pl_start_backpack_load";
            _currentBackpackLoad = backpackItems _unit;
            private _backPackLoad = [];
            {
                _item = _x;
                if (_item in _currentBackpackLoad) then {
                    _currentBackpackLoad deleteAt (_currentBackpackLoad find _item);
                }
                else
                {
                    _backPackLoad pushBack _item;
                };
            } forEach _startBackpackLoad;

            // add avaiable magzines form supplies to _unit
            {
                _item = _x;
                {
                    _availableItems = ((getMagazineCargo _x) select 0);
                    if (_item in _availableItems) exitWith {
                        if (([_x, _item, 1] call CBA_fnc_removeMagazineCargo)) then {
                            _unit addItemToBackpack _item;
                        };
                    };
                } forEach (_supplies select {!(_x isKindOf "Man")}) ;
            } forEach _backPackLoad;
        };
    } forEach (units _group);

    sleep 2;
    // waitUnitl all units ready or task canceled
    waitUntil{(({unitReady _x} count (units _group)) == count (units _group)) or !(_group getVariable ["onTask", true])};

    pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp, _icon]];
    deleteMarker _markerName;
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
};
