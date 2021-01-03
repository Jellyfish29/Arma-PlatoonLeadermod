
pl_rearm = {

    params ["_unit", "_target"];

    if !(isNull _target) then {
        if (_unit getVariable "pl_wia") exitWith {};
        createMarker ["sup_zone_marker", (getPos _target)];
        "sup_zone_marker" setMarkerType "b_support";
        "sup_zone_marker" setMarkerSize [0.5, 0.5];
        // "sup_zone_marker" setMarkerText "Supply Point";

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


pl_supply_area = 80;
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
    _vicType = typeOf _vic;
    _ammoCap = getNumber (configFile >> "cfgVehicles" >> _vicType >> "transportAmmo");
    _ammoCargoPercent = getAmmoCargo _vic;
    _ammoCargo = _ammoCap * _ammoCargoPercent;
    _ammoStep = _ammoCap * 0.02;

    // if no Ammo Left send message
    if (_ammoCargo <= 0) then {
        (leader _group) sideChat format ["%1: No Ammo left!", groupId _group];
    };

    // setup Variables
    _suppliedGroups = [_group];
    _toSupplyGroups = [];
    _ammoBearer = leader _group;
    pl_supply_point_active = true;

    // Taskplanning
    if (count _taskPlanWp != 0) then {

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 20) or !(_group getVariable ["pl_task_planed", false])};

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    // Setup Markers
    _areaMarkerName = createMarker ["supply_point_area", getPos (leader _group)];
    _areaMarkerName setMarkerShape "ELLIPSE";
    _areaMarkerName setMarkerBrush "SolidBorder";
    _areaMarkerName setMarkerColor "colorIndependent";
    _areaMarkerName setMarkerAlpha 0.15;
    _areaMarkerName setMarkerSize [pl_supply_area, pl_supply_area];

    _pointMarkerName = createMarker ["supply_point_center", (getPos (leader _group))];
    _pointMarkerName setMarkerType "b_support";
    _pointMarkerName setMarkerText "Supply Point";
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
                                        _x setUnitLoadout _loadout;
                                        _ammoCargo = _ammoCargo - _ammoStep;
                                    };
                                };
                                // heal Unit
                                _x setDamage 0;
                            } forEach (units _targetGrp);

                            // vehicle rearm
                            if (vehicle (leader _targetGrp) != leader _targetGrp) then {
                                if (_ammoCargo > 0) then {
                                    vehicle (leader _targetGrp) setVehicleAmmo 1;
                                    _ammoCargo = _ammoCargo - (_ammoStep * 1.5);
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
    _ammoCargo = _ammoCargo / _ammoCap;
    _vic setAmmoCargo _ammoCargo;

    // reset group Variables
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    _group setVariable ["pl_is_support", false];
    _ammoBearer setVariable ["pl_is_ccp_medic", false];
    pl_supply_point_active = false;
    deleteMarker _areaMarkerName;
    deleteMarker _pointMarkerName;

    _group addVehicle _vic;
    {
        // _x call BIS_fnc_ambientAnim__terminate;
        [_x] allowGetIn true;
        [_x] orderGetIn true;
    } forEach (units _group);

    sleep 3;
    deleteVehicle _net;
    deleteVehicle _crate;
};
