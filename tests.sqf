v5 setVariable ["pl_supplies", 50];

pl_rearm_point = {
    params [["_group", (hcSelected player) select 0],["_taskPlanWp", []]];
    private ["_group", "_cords", "_suppliedGroups", "_ammoBearer", "_toSupplyGroups", "_toSupplyGroups", "_ammoCargo"];


    // check if vehicle group
    if (vehicle (leader _group) == (leader _group)) exitWith {hint "Requires APC"};

    _vic = vehicle (leader _group);

    // check if vehicle is supply vehicle
    if !(getText (configFile >> "CfgVehicles" >> typeOf _vic >> "textSingular") isEqualTo "APC" or _vic isKindOf "Car") exitWith {hint "Requires APC"};

    // get current Ammo Cargo of Vic and calc _ammoStep -> per one inve refill -2% Supplies
    _ammoCargo = _vic getVariable ["pl_supplies", 0];
    // if no Ammo Left send message
    if (_ammoCargo <= 0) then {
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: No Ammo left!", groupId _group]};
        if (pl_enable_map_radio) then {[_group, "...No Ammo left", 15] call pl_map_radio_callout};
    };


    // Taskplanning
    if (count _taskPlanWp != 0) then {

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 30) or !(_group getVariable ["pl_task_planed", false])};

        deleteWaypoint [_group, _taskPlanWp#1];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    // setup Variables
    _suppliedGroups = [_group];
    _toSupplyGroups = [];
    pl_supply_point_active = true;

    // Setup Markers
    _areaMarkerName = createMarker [format ["ammo_area%1", random 1], getPos (leader _group)];
    _areaMarkerName setMarkerShape "ELLIPSE";
    _areaMarkerName setMarkerBrush "SolidBorder";
    _areaMarkerName setMarkerColor "colorIndependent";
    _areaMarkerName setMarkerAlpha 0.15;
    _areaMarkerName setMarkerSize [20, 20];

    // Setup Group at Position
    [_group] call pl_reset;
    sleep 0.2;

    _cords = getPos (leader _group);

    // [_group] call pl_leave_vehicle;

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa";
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    // _group setVariable ["MARTA_customIcon", ["b_support"]];
    {
        _x disableAI "AUTOCOMBAT";
        _x disableAI "TARGET";
    } forEach (units _group);
    _group setBehaviour "AWARE";

    sleep 2;
    // delay to geive _ammoBearer Time to disembark
    sleep 4;


    // Supply Loop -> Supllies every Group in Range once while actice
    while {_group getVariable ["onTask", true]} do {

        // Get all friendly Groups in Range
        {
            if (((leader _x) distance2D _vic) <= 20 and !(_x getVariable ["pl_is_support", false]) and vehicle (leader _x) == leader _x) then {
                _toSupplyGroups pushBackUnique _x;
            };
        } forEach (allGroups select {side _x == playerSide});

        // remove already supplied Groups and sort group closed to vic
        _toSupplyGroups = _toSupplyGroups - _suppliedGroups;
        _toSupplyGroups = [_toSupplyGroups, [], {_vic distance2D (leader _x)}, "ASCEND"] call BIS_fnc_sortBy;

        {
            if !(isNull _x) then {

                _targetGrp = _x;
                _leaderPos = getPos (leader _targetGrp);

                pl_supply_draw_array pushBack [_cords, _leaderPos, [0.4,1,0.2,1]];

                (leader _targetGrp) doMove (getPos _vic);

                // 15s Supply Time
                _time = time + 15;
                waitUntil {time >= _time or !(_group getVariable ["onTask", true])};

                if (_group getVariable ["onTask", true]) then {

                    // refill Loadout and subtract used supplies for Inf
                    {
                        if (_ammoCargo > 0 and _x != player) then {
                            _loadout = _x getVariable "pl_loadout";
                            if !((getUnitLoadout _x) isEqualTo _loadout) then {
                                _x setUnitLoadout [_loadout, true];
                                _ammoCargo = _ammoCargo - 1;
                            };
                        };
                        if (_x getUnitTrait "explosiveSpecialist" and pl_virtual_mines_enabled) then {
                            _x setVariable ["pl_virtual_mines", pl_max_mines_per_explo];
                        };
                    } forEach (units _targetGrp);
                };

                // stop Hold and move back to _vic
                pl_supply_draw_array = pl_supply_draw_array - [[_cords, _leaderPos, [0.4,1,0.2,1]]];

                _suppliedGroups pushBack _targetGrp;

                if !(_group getVariable ["onTask", true]) exitWith{};
            };
        } forEach _toSupplyGroups;
    };

    // subtract used ammo from _vic
    _vic setVariable ["pl_supplies", _ammoCargo];

    // reset group Variables
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    deleteMarker _areaMarkerName;

    [_group, _vic] spawn pl_crew_vehicle_now;
};