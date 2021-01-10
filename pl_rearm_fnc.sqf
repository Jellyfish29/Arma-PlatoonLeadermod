sleep 1;

pl_max_supplies_per_vic = parseNumber pl_max_supplies_per_vic;


pl_show_supllies = false;
pl_show_supplies_pos = [0,0,0];
pl_rearm_supplies = [];

pl_rearm = {
    private ["_group", "_cords", "_targetBox"];

    _group = (hcSelected player) select 0;

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    if (visibleMap) then {
        pl_show_supplies_pos = getPos (leader _group);
        pl_show_supllies = true;
        hint "Select Box on Map";
        onMapSingleClick {
            pl_mapClicked = true;
            pl_show_supplies_pos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            pl_rearm_supplies = pl_show_supplies_pos nearSupplies 150 select {!(_x isKindOf "Man")};
            pl_rearm_pos = _pos;
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {sleep 0.1};
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

    [_group] call pl_reset;

    sleep 0.2;

    playSound "beep";

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"];    

    _markerName = createMarker [format ["sup_zone_marker%1", random 1], (getPos _targetBox)];
    _markerName setMarkerType "b_support";
    _markerName setMarkerSize [0.5, 0.5];
    _markerName setMarkerColor "colorYellow";

    _boxName = getText (configFile >> "CfgVehicles" >> typeOf _targetBox >> "displayName");
    (leader _group) sideChat format ["%1: Resupplying at %2", (groupId _group), _boxName];
    {    
        [_x, _targetBox] spawn {
            params ["_unit", "_targetBox"];
            if (_unit getVariable "pl_wia" or !alive _unit) exitWith {};

            _unit disableAI "AUTOCOMBAT";
            _pos = getPosATL _targetBox;
            _finalPos = _pos findEmptyPosition [0, 8];
            if (_finalPos isEqualTo []) then {_finalPos = _pos};
            _unit doMove _finalPos;

            sleep 1;

            waitUntil {((_unit distance2D _targetBox) < 8) or unitReady _unit or !((group _unit) getVariable ["onTask", true]) or !alive _unit};

            if ((group _unit) getVariable ["onTask", true]) then {
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

                _unit enableAI "AUTOCOMBAT";
                _unit setVariable ["pl_finished_rearm", true];
            };
        };
    } forEach (units _group);

    _time = time + 80;
    waitUntil {(time > _time) or !(_group getVariable ["onTask", true]) or ({_x getVariable ["pl_finished_rearm", false]} count (units _group)) == count (units _group)};
    deleteMarker _markerName;
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", true];

    {
        _x setVariable ["pl_finished_rearm", nil];
    } forEach (units _group);
};

pl_supply_area = 70;
pl_supply_point_active = false;
pl_supply_draw_array = [];

pl_supply_point = {
    params [["_taskPlanWp", []]];
    private ["_group", "_cords", "_suppliedGroups", "_ammoBearer", "_toSupplyGroups", "_toSupplyGroups", "_ammoCargo"];

    // if already supply point exit
    if (pl_supply_point_active) exitWith {hint "Only on Supply Point!"};

    // check if vehicle group
    _group = (hcSelected player) select 0;
    if (vehicle (leader _group) == (leader _group)) exitWith {hint "Requires Supply Vehicle!"};

    _vic = vehicle (leader _group);

    // check if vehicle is supply vehicle
    if !(_vic getVariable ["pl_is_supply_vehicle", false]) exitWith {hint "Requires Supply Vehicle!"};

    // get current Ammo Cargo of Vic and calc _ammoStep -> per one inve refill -2% Supplies
    _ammoCargo = _vic getVariable ["pl_supplies", 0];
    // if no Ammo Left send message
    if (_ammoCargo <= 0) then {
        (leader _group) sideChat format ["%1: No Ammo left!", groupId _group];
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
    _ammoBearer = leader _group;
    pl_supply_point_active = true;

    // Setup Markers
    _areaMarkerName = createMarker ["supply_point_area", getPos (leader _group)];
    _areaMarkerName setMarkerShape "ELLIPSE";
    _areaMarkerName setMarkerBrush "SolidBorder";
    _areaMarkerName setMarkerColor "colorIndependent";
    _areaMarkerName setMarkerAlpha 0.15;
    _areaMarkerName setMarkerSize [pl_supply_area, pl_supply_area];

    _pointMarkerName = createMarker ["supply_point_center", (getPos (leader _group))];
    _pointMarkerName setMarkerType "b_support";
    _pointMarkerName setMarkerText "SP/MCP";
    _pointMarkerName setMarkerSize [1.3, 1.3];

    // Setup Group at Position
    [_group] call pl_reset;
    sleep 0.2;

    _cords = getPos (leader _group);

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

                        waitUntil {unitReady _ammoBearer or !alive _ammoBearer or !(_group getVariable ["onTask", true])};

                        // 15s Supply Time
                        doStop _ammoBearer;
                        _time = time + 15;
                        waitUntil {time >= _time or !alive _ammoBearer or !(_group getVariable ["onTask", true])};

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
                                // heal Unit
                                _x setDamage 0;
                            } forEach (units _targetGrp);

                            // vehicle rearm
                            if (vehicle (leader _targetGrp) != leader _targetGrp) then {
                                if (_ammoCargo > 0) then {
                                    vehicle (leader _targetGrp) setVehicleAmmo 1;
                                    vehicle (leader _targetGrp) setDamage 0;
                                    _ammoCargo = _ammoCargo - 5;
                                };
                            }; 

                            // reinforcements if enabled -> add dead units back to group
                            if (pl_enable_reinforcements) then {
                                _groupComp = _targetGrp getVariable ["pl_group_comp", []];
                                _groupUnits = units _targetGrp;
                                _avaibleReinforcements =  _vic getVariable "pl_avaible_reinforcements";
                                private _reinforced = 0;

                                {
                                    if (_reinforced <= _avaibleReinforcements) then {
                                        _unit = _x#0;
                                        _type = _x#1;
                                        _loadout = _x#2;
                                        if !(alive _unit) then {
                                            _newUnit = _targetGrp createUnit [_type, getPos _vic,[],0, "NONE"];
                                            _newUnit setUnitLoadout _loadout;
                                            _newUnit doFollow (leader _targetGrp);
                                            _newUnit setVariable ["pl_wia", false];
                                            _newUnit setVariable ["pl_unstuck_cd", 0];
                                            [_newUnit] spawn pl_auto_crouch;
                                            _newUnit setVariable ["pl_loadout", _loadout];
                                            _newUnit setSkill pl_ai_skill;
                                            if (pl_enabled_medical) then {
                                                [_newUnit] call pl_medical_setup; 
                                            };
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
                            };
                        };

                        // stop Hold and move back to _vic
                        [_targetGrp] call pl_execute;
                        pl_supply_draw_array = pl_supply_draw_array - [[_cords, _pos, [0.4,1,0.2,1]]];
                        _pos = _cords findEmptyPosition [0, 15];
                        _ammoBearer doMove _pos;
                        _suppliedGroups pushBack _targetGrp;

                        waitUntil {unitReady _ammoBearer or !alive _ammoBearer or !(_group getVariable ["onTask", true])};

                        if !(_group getVariable ["onTask", true]) exitWith{};
                    };
                };
            };
        } forEach _toSupplyGroups;
    };

    // subtract used ammo from _vic
    _vic setVariable ["pl_supplies", _ammoCargo];

    // reset group Variables
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    _group setVariable ["pl_is_support", false];
    _ammoBearer setVariable ["pl_is_ccp_medic", false];
    pl_supply_point_active = false;
    deleteMarker _areaMarkerName;
    deleteMarker _pointMarkerName;

    [_group, _vic] spawn pl_crew_vehicle_now;

    sleep 3;
    deleteVehicle _net;
    deleteVehicle _crate;
};
