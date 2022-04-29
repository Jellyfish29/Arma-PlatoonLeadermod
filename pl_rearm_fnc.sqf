sleep 1;

pl_max_supplies_per_vic = parseNumber pl_max_supplies_per_vic;


pl_show_supllies = false;
pl_show_supplies_pos = [0,0,0];
pl_rearm_supplies = [];

pl_rearm = {
    private ["_group", "_cords", "_targetBox", "_mPos"];

    _group = (hcSelected player) select 0;

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    if (visibleMap or !(isNull findDisplay 2000)) then {
        pl_show_supplies_pos = getPos (leader _group);
        pl_show_supllies = true;
        hint "Select Box on Map";
        onMapSingleClick {
            pl_mapClicked = true;
            
            pl_rearm_supplies = pl_show_supplies_pos nearSupplies 150 select {!(_x isKindOf "Man")};
            pl_rearm_pos = _pos;
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            
            pl_show_supplies_pos = _mPos;
            
            sleep 0.1
        };
        pl_show_supllies = false;
        pl_mapClicked = false;
        _cords = pl_rearm_pos;
        hintSilent "";
    }
    else
    {
        pl_rearm_supplies = [cursorTarget];
        _cords = getPos cursorTarget;
    };
    _supplies = [pl_rearm_supplies, [], {_x distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy;
    _targetBox = _supplies select 0;
    if (isNil "_targetBox") exitWith {hint "No available Supplies!"};
    if ((_targetBox distance2D _cords) >= 25) exitWith {hint "No available Supplies!"};


    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"];    

    _markerName = createMarker [format ["sup_zone_marker%1", random 1], (getPos _targetBox)];
    _markerName setMarkerType "b_support";
    _markerName setMarkerSize [0.5, 0.5];
    _markerName setMarkerColor "colorYellow";

    _boxName = getText (configFile >> "CfgVehicles" >> typeOf _targetBox >> "displayName");
    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Resupplying at %2", (groupId _group), _boxName]};
    if (pl_enable_map_radio) then {[_group, format ["...Resupplying at %1", _boxName], 15] call pl_map_radio_callout};

    {    
        [_x, _targetBox] spawn {
            params ["_unit", "_targetBox"];
            if (_unit getVariable "pl_wia" or !alive _unit) exitWith {};

            _unit disableAI "AUTOCOMBAT";
            _pos = getPosATL _targetBox;
            _finalPos = _pos findEmptyPosition [0, 8];
            if (_finalPos isEqualTo []) then {_finalPos = _pos};

            waitUntil {sleep 0.5; unitReady _unit or !alive _unit};

            _unit doMove _finalPos;

            sleep 1;

            waitUntil {sleep 0.5; ((_unit distance2D _targetBox) < 8) or unitReady _unit or !((group _unit) getVariable ["onTask", true]) or !alive _unit};

            if ((group _unit) getVariable ["onTask", true]) then {


                private _ammoCargo = _targetBox getVariable ["pl_supplies", 0];
                if (_ammoCargo > 0 and _unit != player) then {
                    _loadout = _unit getVariable "pl_loadout";
                    if !((getUnitLoadout _unit) isEqualTo _loadout) then {
                        _unit setUnitLoadout [_loadout, true];
                        _ammoCargo = _ammoCargo - 1;
                    };
                    if (_unit getUnitTrait "explosiveSpecialist" and pl_virtual_mines_enabled) then {
                        _unit setVariable ["pl_virtual_mines", pl_max_mines_per_explo];
                    };
                    _targetBox setVariable ["pl_supplies", _ammoCargo];
                } else {
                    _unit action ["rearm",_targetBox];
                    _secWeapon = _unit getVariable ["pl_sec_weapon", []];
                    if !(_secWeapon isEqualTo []) then {
                        _launcher = _secWeapon#0;
                        _missile = _secWeapon#1;
                        if (secondaryWeapon _unit == "") then {
                            _launcherSplit = _launcher splitString "_"; 
                            _launcherSplit = _launcherSplit - ["Loaded"];
                            _launcher = _launcherSplit joinString "_";

                            if (_launcher in ((getWeaponCargo _targetBox)#0)) then {
                                _unit addWeapon _launcher;
                                _unit addSecondaryWeaponItem _missile;
                            };
                        }
                        else
                        {
                            if (_missile in ((getMagazineCargo _targetBox)#0)) then {
                                _unit addSecondaryWeaponItem _missile;
                                _targetBox removeMagazine _missile;
                            };
                        };
                    };
                };


                _unit enableAI "AUTOCOMBAT";
                _unit setVariable ["pl_finished_rearm", true];
            };
        };
    } forEach (units _group);

    _time = time + 80;
    waitUntil {sleep 0.5; (time > _time) or !(_group getVariable ["onTask", true]) or ({_x getVariable ["pl_finished_rearm", false]} count (units _group)) == count (units _group)};
    deleteMarker _markerName;
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", true];

    {
        _x setVariable ["pl_finished_rearm", nil];
    } forEach (units _group);
};

pl_supply_area = 50;
pl_active_supply_points = [];
pl_supply_draw_array = [];

pl_supply_point = {
    params [["_group", (hcSelected player) select 0],["_taskPlanWp", []]];
    private ["_group", "_cords", "_suppliedGroups", "_ammoBearer", "_toSupplyGroups", "_toSupplyGroups", "_ammoCargo", "_marker3D"];

    // if already supply point exit
    // if (pl_supply_point_active) exitWith {hint "Only on Supply Point!"};

    // check if vehicle group
    if (vehicle (leader _group) == (leader _group)) exitWith {hint "Requires Supply Vehicle!"};

    _vic = vehicle (leader _group);

    // check if vehicle is supply vehicle
    if !(_vic getVariable ["pl_is_supply_vehicle", false]) exitWith {hint "Requires Supply Vehicle!"};

    // get current Ammo Cargo of Vic and calc _ammoStep -> per one inve refill -2% Supplies
    _ammoCargo = _vic getVariable ["pl_supplies", 0];
    // if no Ammo Left send message
    if (_ammoCargo <= 0) then {
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: No Ammo left!", groupId _group]};
        if (pl_enable_map_radio) then {[_group, "...No Ammo left", 15] call pl_map_radio_callout};
    };

    private _valid = true;
    {
        if (((getPos _vic) distance2D _x) < pl_supply_area * 2) exitWith {_valid = false};
    } forEach pl_active_supply_points;

    if !(_valid) exitwith {hint "Too close to another supply point"};


    // Taskplanning
    if (count _taskPlanWp != 0) then {

        waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 40) or !(_group getVariable ["pl_task_planed", false])};

        deleteWaypoint [_group, _taskPlanWp#1];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    // setup Variables
    _suppliedGroups = [_group];
    _toSupplyGroups = [];
    if (count (units _group) > 1) then {
        _ammoBearer = ((units _group) - [leader _group])#0;
    } else {
        _ammoBearer = leader _group;
    };

    _cords = getPos (leader _group);
    pl_active_supply_points pushBack _cords;

    // Setup Markers
    _areaMarkerName = createMarker [format ["supply_point_area_%1", random 3], getPos (leader _group)];
    _areaMarkerName setMarkerShape "ELLIPSE";
    _areaMarkerName setMarkerBrush "SolidBorder";
    _areaMarkerName setMarkerColor pl_side_color;
    _areaMarkerName setMarkerAlpha 0.15;
    _areaMarkerName setMarkerSize [pl_supply_area, pl_supply_area];

    _pointMarkerName = createMarker [format ["supply_point_center_%1", random 3], (getPos (leader _group)) getPos [7, 0]];
    _pointMarkerName setMarkerType "marker_r3p";
    _pointMarkerName setMarkerColor pl_side_color;
    // _pointMarkerName setMarkerText "SP/MCP";
    // _pointMarkerName setMarkerSize [1.3, 1.3];

    // _marker3D = [_group, '\Plmod\gfx\pl_r3p_marker.paa'] call pl_draw_3d_icon;

    // Setup Group at Position

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    

    [_group] call pl_leave_vehicle;

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa";
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _group setVariable ["pl_is_support", true];
    // _group setVariable ["MARTA_customIcon", ["b_support"]];
    _ammoBearer setVariable ["pl_is_ccp_medic", true];
    {
        _x disableAI "AUTOCOMBAT";
        _x disableAI "TARGET";
    } forEach (units _group);
    _group setBehaviour "AWARE";

    sleep 2;
    [_group, "support"] call pl_change_group_icon;
    // delay to geive _ammoBearer Time to disembark
    sleep 4;

    // create ambiant Net and Crate behind _vic
    _netPos = [5 * (sin ((getDir _vic) - 180)), 5 * (cos ((getDir _vic) - 180)), 0] vectorAdd (getPos _vic);
    _cPos = _netPos findEmptyPosition [0, 20];
    _crate = "VirtualReammoBox_camonet_F" createVehicle _cPos;
    sleep 0.5;
    _net = "CamoNet_BLUFOR_open_F" createVehicle _netPos;

    // Rest of group take Cover
    {
        _x disableAI "PATH";
        // [_x, (getPos _engineer), 0, 10, false] spawn pl_find_cover;
        // _anim = selectRandom ["WATCH", "WATCH1", "WATCH2"];
        // [_x, _anim, "ASIS"] call BIS_fnc_ambientAnimCombat;
    } forEach (units _group) - [_ammoBearer];


    {
        if (((leader _x) distance2D _vic) <= pl_supply_area and !(_x getVariable ["pl_is_support", false])) then {
            _suppliedGroups pushBackUnique _x;
        };
    } forEach (allGroups select {side _x == playerSide});

    // Supply Loop -> Supllies every Group in Range once while actice
    while {(_group getVariable ["onTask", true] and (alive _ammoBearer))} do {

        // Get all friendly Groups in Range
        {
            if (((leader _x) distance2D _vic) <= pl_supply_area and !(_x getVariable ["pl_is_support", false])) then {
                _toSupplyGroups pushBackUnique _x;
            };
        } forEach (allGroups select {side _x == playerSide});

        // remove already supplied Groups and sort group closed to vic
        _toSupplyGroups = _toSupplyGroups - _suppliedGroups;
        _toSupplyGroups = [_toSupplyGroups, [], {_vic distance2D (leader _x)}, "ASCEND"] call BIS_fnc_sortBy;

        {
            if !(isNull _x) then {

                // ammobearer move to Pos of group
                _targetGrp = _x;
                _pos = getPos (leader _targetGrp) findEmptyPosition [0, 15];
                if !((count _pos) <= 0) then {
                    if ((_pos distance2D _cords) <= pl_supply_area and _group getVariable ["onTask", true]) then {

                        // target group on hold
                        [_targetGrp] call pl_hold;
                        pl_supply_draw_array pushBack [_cords, _pos, [0.4,1,0.2,1]];
                        _ammoBearer doMove _pos;

                        waitUntil {sleep 0.5; unitReady _ammoBearer or !alive _ammoBearer or !(_group getVariable ["onTask", true])};

                        // 15s Supply Time
                        doStop _ammoBearer;
                        _time = time + 15;
                        waitUntil {sleep 0.5; time >= _time or !alive _ammoBearer or !(_group getVariable ["onTask", true])};

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
                                if (_x getUnitTrait "explosiveSpecialist" and ((_x getVariable ["pl_virtual_mines", 0]) < pl_max_mines_per_explo) and pl_virtual_mines_enabled) then {
                                    _x setVariable ["pl_virtual_mines", pl_max_mines_per_explo];
                                    _ammoCargo = _ammoCargo - 1;
                                };
                                // heal Unit
                                _x setDamage 0;
                            } forEach (units _targetGrp);

                            // vehicle rearm
                            if (vehicle (leader _targetGrp) != leader _targetGrp) then {
                                if (_ammoCargo > 0) then {
                                    vehicle (leader _targetGrp) setVehicleAmmo 1;
                                    if (getDammage vehicle (leader _targetGrp) > 0) then {
                                        vehicle (leader _targetGrp) setDamage 0;
                                        _ammoCargo = _ammoCargo - 5;
                                    };
                                    if (([vehicle (leader _targetGrp)] call pl_is_apc) or ([vehicle (leader _targetGrp)] call pl_is_ifv) or vehicle (leader _targetGrp) isKindOf "Car") then {
                                        vehicle (leader _targetGrp) setVariable ["pl_supplies", 40];
                                    };
                                };
                            }; 

                            // reinforcements if enabled -> add dead units back to group
                            if (pl_enable_reinforcements) then {
                                _groupComp = _targetGrp getVariable ["pl_group_comp", []];
                                _groupUnits = units _targetGrp;
                                _groupIsReset = _targetGrp getVariable ["pl_is_reset", false];
                                _avaibleReinforcements =  _vic getVariable "pl_avaible_reinforcements";
                                private _reinforced = 0;

                                if (_targetGrp getVariable ["pl_is_reset", false]) then {
                                    {
                                        deleteVehicle _x;
                                        _reinforced = _reinforced - 1;
                                    } forEach _groupUnits;
                                };

                                {
                                    if (_reinforced <= _avaibleReinforcements) then {
                                        _unit = _x#0;
                                        _type = _x#1;
                                        _loadout = _x#2;

                                        if (!(alive _unit) or (_targetGrp getVariable ["pl_is_reset", false])) then {
                                            _newUnit = _targetGrp createUnit [_type, getPos _vic,[],0, "NONE"];
                                            _newUnit setUnitLoadout _loadout;
                                            _newUnit doFollow (leader _targetGrp);
                                            [_newUnit, _targetGrp] call pl_set_up_single_unit;
                                            _reinforced = _reinforced + 1;
                                        };
                                    };
                                } forEach _groupComp;


                                _vic setVariable ["pl_avaible_reinforcements", _avaibleReinforcements - _reinforced];
                                _groupComposition = [];
                                {
                                    _type = typeOf _x;
                                    _loadout = getUnitLoadout _x;
                                    _groupComposition pushBack [_x, _type, _loadout];
                                } forEach (units _targetGrp);

                                _targetGrp setVariable ["pl_group_comp", _groupComposition];
                                _targetGrp setVariable ["pl_is_reset", false];
                            };
                        };

                        // stop Hold and move back to _vic
                        [_targetGrp] call pl_execute;
                        pl_supply_draw_array = pl_supply_draw_array - [[_cords, _pos, [0.4,1,0.2,1]]];
                        _pos = _cords findEmptyPosition [0, 15];
                        _ammoBearer doMove _pos;
                        _suppliedGroups pushBack _targetGrp;

                        waitUntil {sleep 0.5; unitReady _ammoBearer or !alive _ammoBearer or !(_group getVariable ["onTask", true])};

                        if !(_group getVariable ["onTask", true]) exitWith{};
                    };
                };
            };
        } forEach _toSupplyGroups;

        sleep 2;
    };

    // subtract used ammo from _vic
    _vic setVariable ["pl_supplies", _ammoCargo];

    // reset group Variables
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    _group setVariable ["pl_is_support", false];
    _ammoBearer setVariable ["pl_is_ccp_medic", false];
    pl_active_supply_points deleteAt (pl_active_supply_points find _cords);
    deleteMarker _areaMarkerName;
    deleteMarker _pointMarkerName;
    // [_marker3D] call pl_remove_3d_icon;

    [_group, _vic] spawn pl_crew_vehicle_now;

    sleep 3;
    deleteVehicle _net;
    deleteVehicle _crate;
};

pl_rearm_point = {
    params [["_group", (hcSelected player) select 0],["_taskPlanWp", []]];
    private ["_group", "_cords", "_suppliedGroups", "_ammoBearer", "_toSupplyGroups", "_toSupplyGroups", "_ammoCargo", "_marker3D"];


    // check if vehicle group
    if (vehicle (leader _group) == (leader _group)) exitWith {hint "Requires APC"};

    _vic = vehicle (leader _group);

    private _isAPC = [_vic] call pl_is_apc;
    private _isIFV = [_vic] call pl_is_ifv;

    // check if vehicle is supply vehicle
    if (!(_isAPC) and !(_isIFV) and !(_vic isKindOf "Car")) exitWith {hint "Requires APC or Supply Vehicle"};

    // get current Ammo Cargo of Vic and calc _ammoStep -> per one inve refill -2% Supplies
    _ammoCargo = _vic getVariable ["pl_supplies", 0];
    // if no Ammo Left send message
    if (_ammoCargo <= 0) then {
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: No Ammo left!", groupId _group]};
        if (pl_enable_map_radio) then {[_group, "...No Ammo left", 15] call pl_map_radio_callout};
    };


    // Taskplanning
    if (count _taskPlanWp != 0) then {

        waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 30) or !(_group getVariable ["pl_task_planed", false])};

        deleteWaypoint [_group, _taskPlanWp#1];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    // setup Variables
    _suppliedGroups = [_group];
    _toSupplyGroups = [];

    // Setup Markers
    _areaMarkerName = createMarker [format ["ammo_area%1", random 1], getPos (leader _group)];
    _areaMarkerName setMarkerShape "ELLIPSE";
    _areaMarkerName setMarkerBrush "SolidBorder";
    _areaMarkerName setMarkerColor "colorIndependent";
    _areaMarkerName setMarkerAlpha 0.15;
    _areaMarkerName setMarkerSize [20, 20];

    _supplyWalkupRange = 250;
    _areaMarkerNameOuter = createMarker [format ["ammo_area_outer%1", random 1], getPos (leader _group)];
    _areaMarkerNameOuter setMarkerShape "ELLIPSE";
    _areaMarkerNameOuter setMarkerBrush "Border";
    _areaMarkerNameOuter setMarkerColor "colorIndependent";
    _areaMarkerNameOuter setMarkerAlpha 0.15;
    _areaMarkerNameOuter setMarkerSize [_supplyWalkupRange, _supplyWalkupRange];

    _pointMarkerName = createMarker [format ["ressupplypoint%1", _group], (getPos (leader _group)) getPos [7, 0]];
    _pointMarkerName setMarkerType "marker_asp";
    _pointMarkerName setMarkerColor pl_side_color;
    // _pointMarkerName setMarkerText "SP/MCP";
    // _pointMarkerName setMarkerSize [1.3, 1.3];

    // _marker3D = [_group, '\Plmod\gfx\pl_asp_marker.paa'] call pl_draw_3d_icon;

    // Setup Group at Position

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

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
        _x disableAI "PATH";
    } forEach (units _group);
    // _group setBehaviour "SAFE";
    _vic setVariable ["pl_is_rearm_point", true];

    sleep 2;

    // Supply Loop -> Supllies every Group in Range once while actice
    while {_group getVariable ["onTask", true] and alive _vic} do {

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
                waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", true])};

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
                        if (_x getUnitTrait "explosiveSpecialist" and ((_x getVariable ["pl_virtual_mines", 0]) < pl_max_mines_per_explo) and pl_virtual_mines_enabled) then {
                            _x setVariable ["pl_virtual_mines", pl_max_mines_per_explo];
                            _ammoCargo = _ammoCargo - 1;
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
    _vic setVariable ["pl_is_rearm_point", nil];

    // reset group Variables
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    deleteMarker _areaMarkerName;
    deleteMarker _pointMarkerName;
    // [_marker3D] call pl_remove_3d_icon;

    [_group, _vic] spawn pl_crew_vehicle_now;
};

pl_rearm_in_transport = {
    params ["_targetGrp", "_vic"];

    private _ammoCargo = _vic getVariable ["pl_supplies", 0];
    if (_ammoCargo <= 0) exitWith {};

    sleep 5;

    {
        if (_ammoCargo > 0 and _x != player) then {
            _loadout = _x getVariable "pl_loadout";
            if !((getUnitLoadout _x) isEqualTo _loadout) then {
                _x setUnitLoadout [_loadout, true];
                _ammoCargo = _ammoCargo - 1;
            };
        };
        if (_x getUnitTrait "explosiveSpecialist" and ((_x getVariable ["pl_virtual_mines", 0]) < pl_max_mines_per_explo) and pl_virtual_mines_enabled) then {
            _x setVariable ["pl_virtual_mines", pl_max_mines_per_explo];
            _ammoCargo = _ammoCargo - 1;
        };
        _x setDamage 0;
        _time = time + 5;
        waitUntil {time >= _time or !(_vic getVariable ["pl_has_cargo", false]) or !alive _vic};
        if !(_vic getVariable ["pl_has_cargo", false] or !alive _vic) exitWith {};
    } forEach (units _targetGrp);

    _vic setVariable ["pl_supplies", _ammoCargo];
};