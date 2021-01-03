sleep 1.5;

pl_global_spotrep_cd = 0;
pl_At_fire_report_cd = 0;
// pl_ai_skill = 0.8;
// pl_radio_range = 700;
pl_max_reinforcement_per_vic = parseNumber pl_max_reinforcement_per_vic;

pl_share_info = {

    params ["_group"];
    _group setVariable ["spotRepEnabled", true];

    while {true} do {
        waitUntil {(behaviour (leader _group)) isEqualto "COMBAT"};

        _targets = [];

        // [_targets] spawn pl_mark_targets_on_map;

        _targets = [(leader _group)] call pl_get_targets;
        [_targets, (leader _group)] call pl_reveal_targets;

        sleep 20;
    };
};

pl_get_targets = {
    params ["_leader"];
    private ["_targets"];
    _targets = [];
    {
        if (alive _x and (side _x) != civilian) then {
            if (_leader knowsAbout _x > 1) then {
            _targets append [_x];
            };
        };
    } forEach (allUnits+vehicles select {side _x != playerSide});
    _targets
};

pl_reveal_targets = {
    params ["_targets", "_leader"];
    {
        _t = _x;
        {
            if (((leader _x) distance2D _leader) < pl_radio_range) then {
                _x reveal _t;
            };
        } forEach (allGroups select {side _x isEqualTo playerSide});
    } forEach _targets;
};



pl_share_info_opfor = {

    params ["_group"];
    _group setVariable ["spotRepEnabled", true];

    while {true} do {
        waitUntil {(behaviour (leader _group)) isEqualto "COMBAT"};

        _targets = [];

        // [_targets] spawn pl_mark_targets_on_map;

        _targets = [(leader _group)] call pl_get_targets_opfor;
        [_targets, (leader _group)] call pl_reveal_targets_opfor;

        sleep 20;
    };
};

pl_get_targets_opfor = {
    params ["_leader"];
    private ["_targets"];
    _targets = [];
    {
        if (alive _x and (side _x) != civilian) then {
            if (_leader knowsAbout _x > 2) then {
            _targets append [_x];
            };
        };
    } forEach (allUnits+vehicles select {side _x isEqualTo playerSide});
    _targets
};

pl_reveal_targets_opfor = {
    params ["_targets", "_leader"];
    {
        _t = _x;
        {
            if (((leader _x) distance2D _leader) < (pl_radio_range / 2) and ((_leader distance2D _t) < 300)) then {
                _x reveal _t;
            };
        } forEach (allGroups select {side _x != playerSide});
    } forEach _targets;
};



pl_contact_info_share = {
    params ["_unit"];
    sleep 7;
    _targets = [];
    _targets = [_unit] call pl_get_targets;
    [_targets, _unit] call pl_reveal_targets;

    [_targets] spawn pl_mark_targets_on_map;
};

pl_contact_report = {
    params ["_group", "_inTransport"];

    _leader = leader _group;
    _leader setVariable ["PlContactRepEnabled", true];
    _group setVariable ["PlContactTime", 0];
    if !(_inTransport) then {
        if (vehicle _leader != _leader) then {
            _leader = vehicle _leader;
        };
    };
    if (_leader != player) then {
        _leader addEventHandler ["FiredNear", {
            params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];

            if ((group _firer) isEqualTo (group _unit)) then {
                if (((group _unit) getVariable "PlContactTime") < time) then {
                        _callsign = groupId (group _unit);
                        if ((vehicle _unit) isKindOf "Air") then {
                            playSound "beep";
                            _unit sideChat format ["%1: Engaging Ground Targets", _callsign];
                        }
                        else
                        {
                            playSound "beep";
                            _unit sideChat format ["%1: Engaging Enemies", _callsign];
                        };
                        [_unit] spawn pl_contact_info_share;
                        (group _unit) setVariable ['inContact', true];
                };
                (group _unit) setVariable ["PlContactTime", (time + 60)];
                if ("launch" in (_weapon splitString "_")) then {
                    if (pl_At_fire_report_cd < time) then {
                        pl_At_fire_report_cd = time + 5;
                        _callsign = groupId (group _unit);
                        _unit sideChat format ["%1: Engaging Vehicles with AT", _callsign];
                    };
                };
            };
            if !(alive _unit) then {
                _unit setVariable ["PlContactRepEnabled", false];
            };
        }];
    };
};



pl_player_report = {
    playSound "beep";
    // player sideChat "to all Elements, stand by for SPOTREP, over";
    _targets = [];
    {
        if (player knowsAbout _x > 0) then {
          _targets pushBack _x;
        };
    } forEach (allUnits+vehicles select {side _x != playerSide});

    [_targets] spawn pl_mark_targets_on_map;

    [_targets, player] call pl_reveal_targets;
};

pl_enemy_destroyed_report = {
    params ["_unit", "_killer", "_group"];
    _typeStr = "Infantry Unit";
    if (vehicle _unit != _unit) then {
        _vic = vehicle _unit;
        _typeStr = getText (configFile >> "CfgVehicles" >> typeOf _vic >> "displayName");
    };
    _time = time + 10;
    waitUntil {time >= _time};
    _unitsAlive = false;
    {
        if (alive _x) then {
            _unitsAlive = true;
        };
    } forEach (units _group);
    if !(_unitsAlive) then {
        if (isNil {_group getVariable "pl_death_reported"}) then {
            _gridPos = mapGridPosition _unit;
            _group setVariable ["pl_death_reported", true];
            playSound "beep";
            _killer sideChat format ["%1 destroyed enemy %2", groupId (group _killer), _typeStr];
        };
    };
};

pl_auto_crouch = {
    params ["_unit"];
    while {alive _unit} do {
        if ((behaviour _unit) isEqualTo "AWARE") then {
            if !((group _unit) getVariable ["onTask", false]) then {
                if ((speed _unit) == 0) then {
                    _unit setUnitPos "MIDDLE";
                    waitUntil {sleep 1; (speed _unit) > 0 or !(alive _unit)};
                    if ((unitPos _unit) == "MIDDLE") then {
                        _unit setUnitPos "AUTO";
                    };
                };
            };
        };
        sleep 3;
    };  
};

pl_medical_setup = {
    params ["_unit"];
    _unit setVariable ["pl_beeing_treatet", false];
    _unit setVariable ["pl_wia_calledout", false];
    _unit setVariable ["pl_injured", false];
    _unit setVariable ["pl_bleedout_time", 700];
    _unit setVariable ["pl_bleedout_set", false];
    _unit setVariable ["pl_damage_reduction", false];
    _unit addEventHandler ['HandleDamage', {
        params['_unit', '_selName', '_damage', '_source'];
        if ((_unit getVariable "pl_damage_reduction") or (_unit getVariable ["pl_special_force", false])) then {
            _dmg = _damage * 0.7 ;
            _damage = _dmg;
        };
        if !(_unit getVariable "pl_wia") then {
            if (_damage > 0.99) then {
                if (([0, 100] call BIS_fnc_randomInt) > 10) then {
                    _damage = 0;
                    _unit setUnconscious true;
                    if (vehicle _unit != _unit) then {
                        if (alive (vehicle _unit)) then {
                            [_unit, vehicle _unit] call pl_crew_eject;
                        };
                    };
                    if !(_unit getVariable "pl_wia_calledout") then {
                        [_unit] spawn pl_wia_callout;
                    };
                    if !(_unit getVariable "pl_bleedout_set") then {
                        [_unit] spawn pl_bleedout;
                    };
                };
            }
            else
            {
                _unit setVariable ["pl_injured", true];
            };
        };
        _damage
    }];
};

pl_special_forces_skills = {
    params ["_unit"];
    private ["_targets"];

    _unit setSkill 1;
    while {alive _unit} do {
        sleep 10;
        _targets = (getPos _unit) nearEntities [["Man", "Tank", "Car", "Truck"], 100];
        {
            _unit reveal [_x, 3];
        } forEach _targets select {!(side _x isEqualTo playerSide)};
    };
};

pl_set_up_ai = {
    params ["_group"];
    private ["_magCountAll", "_magCountSolo"];
    if ((vehicle (leader _group)) != leader _group) then {
        _vic = vehicle (leader _group);
        _vic setVariable ["pl_rtb_pos", getPos _vic];
    };
    _group setVariable ["aiSetUp", true];
    _group setVariable ["onTask", false];
    _group setVariable ["inContact", false];
    _group setVariable ["sitrepCd", 0];
    _group setVariable ["pl_show_info", true];
    _group setVariable ["pl_hold_fire", false];
    _group setVariable ["pl_killed_units", []];
    _groupComposition = [];
    {
        _type = typeOf _x;
        _loadout = getUnitLoadout _x;
        _groupComposition pushBack [_x, _type, _loadout];
    } forEach (units _group);

    _group setVariable ["pl_group_comp", _groupComposition];
    _group allowFleeing 0;

    [_group] spawn pl_ammoBearer;
    _magCountAll = 0;
    {     
        if ((_x != player) or !(_x in switchableUnits)) then {
            _x unassignItem "Binocular";
            _x removeWeapon "Binocular";
            _x unassignItem "Rangefinder";
            _x removeWeapon "Rangefinder";
        };
        if (_x getVariable ["pl_special_force", false]) then {
            [_x] spawn pl_special_forces_skills;
        };
        _mags = magazines _x;
        _mag = "";
        if ((primaryWeapon _x) != "") then {
            _mag = (getArray (configFile >> "CfgWeapons" >> (primaryWeapon _x) >> "magazines")) select 0;
        };
        _magCount = 0;
        {
            if ((_mag isEqualto _x)) then {
                _magCount = _magCount + 1;
            };
        }forEach _mags;
        _magCountAll = _magCountAll + _magCount;
        _x setVariable ["pl_wia", false];
        _x setVariable ["pl_unstuck_cd", 0];
        _laodout = getUnitLoadout _x;
        _x setVariable ["pl_loadout", _laodout];
        [_x] spawn pl_auto_crouch;
        if (pl_enabled_medical) then {
            [_x] call pl_medical_setup; 
        };
    } forEach (units _group);

    _group setVariable ["magCountAllDefault", _magCountAll];
    if ((count (units _group)) > 1) then {
        _magCountSolo = round (_magCountAll / (count (units _group)));
    }
    else
    {
        _magCountSolo = _magCountAll;
    }; 
    _group setVariable ["magCountSoloDefault", _magCountSolo];

    _unitCount = count (units _group);
    _group setVariable ["_unitCountDefault", _unitCount];
};

pl_vehicle_setup = {
    params ["_vic"];

    if (_vic isKindOf "Air") exitWith {};

    _vic setUnloadInCombat [false, false];
    
    if (isNil {_vic getVariable "pl_vehicle_setup_complete"}) then {
        _vic limitSpeed 50;
        _vic setVariable ["pl_speed_limit", "50"];
        if (isNil {_vic getVariable "pl_repair_lifes"}) then {
            if (_vic isKindOf "Tank") then {
                _vic setVariable ["pl_repair_lifes", 100]; //4
            }
            else
            {
                _vic setVariable ["pl_repair_lifes", 100]; //2
            };
        };

        if (isNil {_vic getVariable "pl_appereance"}) then {
            _animations = "true" configClasses (configFile >> "CfgVehicles" >> typeOf _vic >> "AnimationSources");
            _animationPhases = [];

            {
                _s = (str _x) splitString "/";
                _a =  _s select ((count _s) - 1);
                _animationPhases pushBack [_a, (_vic animationSourcePhase _a)];
            } forEach _animations;

            _vic setVariable ["pl_appereance", _animationPhases];
        };
        // Supply Vehicle setup
        _vicType = typeOf _vic;
        _ammoCap = getNumber (configFile >> "cfgVehicles" >> _vicType >> "transportAmmo");
        _repairCap = getNumber (configFile >> "cfgVehicles" >> _vicType >> "transportRepair");
        if (_ammoCap > 0 or _vic getVariable ["pl_is_supply_vehicle", false]) then {
            _vic setVariable ["pl_is_supply_vehicle", true];
            _vic setVariable ["pl_avaible_reinforcements", pl_max_reinforcement_per_vic];
        };
        if (_repairCap > 0 or _vic getVariable ["pl_is_supply_vehicle", false]) then {
            _vic setVariable ["pl_is_supply_vehicle", true];
            // _vic setVariable ["pl_avaible_reinforcements", pl_max_reinforcement_per_vic];
        };
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _vic >> "attendant" ) isEqualTo 1) then {
            _vic setVariable ["pl_avaible_reinforcements", pl_max_reinforcement_per_vic];
            _vic setVariable ["pl_is_supply_vehicle", true];
        };
        _vic addEventHandler ["IncomingMissile", {
            params ["_target", "_ammo", "_vehicle", "_instigator"];

            _pos = getPos _vehicle;
            _markerPos = [[[_pos, 50]],[]] call BIS_fnc_randomPos;
            _markerDir =  (_target getDir _markerPos) + 90;
            _markerName = format ["%1at", _vehicle];
            [_markerPos, _markerDir, _markerName] spawn {
                params ["_markerPos", "_markerDir", "_markerName"];
                createMarker [_markerName, _markerPos];
                _markerName setMarkerType "mil_ambush";
                _markerName setMarkerSize [0.5, 0.5];
                _markerName setMarkerDir _markerDir;
                _markerName setMarkerColor "ColorRed";
                _markerName setMarkerText "AT";
                sleep 30;
                deleteMarker _markerName;
            };
        }];




        _vic setVariable ["pl_vehicle_setup_complete", true];
    };
    _w = getWeaponCargo _vic;
    _t = getItemCargo _vic;
    _m = getMagazineCargo _vic;
    _b = getBackpackCargo _vic;
    _vicInv = [_w, _t, _m ,_b];

    _vic setVariable ["pl_vic_inv", _vicInv];
};

pl_ai_setUp_loop = {
    while {true} do {
        {
            if (side _x isEqualTo playerSide) then {
                [_x]spawn pl_vehicle_setup;
            }
            else
            {
                // _x limitSpeed 45;
                _x setUnloadInCombat [true, true];
            };
        } forEach vehicles;

        {
            if (side _x isEqualTo playerSide) then {
                if (isNil {_x getVariable "spotRepEnabled"}) then {
                    [_x] spawn pl_share_info;
                };
                if (isNil {(leader _x) getVariable "PlContactRepEnabled"}) then {
                    [_x, false] spawn pl_contact_report;
                };
                if (isNil {_x getVariable "aiSetUp"}) then {
                    [_x] call pl_set_up_ai;
                };
                // unit Reset loop
                {
                    if !(lifeState _x isEqualTo "INCAPACITATED") then {
                        [_x] call pl_auto_unstuck;
                        if (_x getVariable "pl_wia") then {
                            _x setVariable ["pl_wia", false];
                        };
                    };
                } forEach (units _x);
            }
            else
            {
                if (pl_opfor_info_share_enabled) then {
                    if (isNil {_x getVariable "spotRepEnabled"}) then {
                        [_x] spawn pl_share_info_opfor;
                    };
                };
            };

            if(_x != (group player)) then {
                if !(_x getVariable ["pl_combat_mode", false]) then {
                    _x enableAttack false;
                    _x setCombatMode "YELLOW";
                };
            };
        } forEach allGroups;
        sleep 20;
    };
};

[] spawn pl_ai_setUp_loop;

pl_auto_unstuck = {
    params ["_unit"];
    if (group _unit != group player and (time >= _unit getVariable "pl_unstuck_cd") and !(group _unit getVariable ["pl_combat_mode", true])) then {
        _distance = _unit distance2D leader (group _unit);
        if (_distance > 150) then {
            // [_unit] spawn pl_hard_reset;
            _unit setVariable ["pl_unstuck_cd", time + 90];
            _type = typeOf _unit;
            _pos = (getPos _unit) findEmptyPosition [0, 50, _type];
            _unit setPos _pos;
            _unit doFollow leader (group _unit);
        };
    };
};

pl_vehicle_unstuck = {
    params ["_group"];
    private ["_vic"];
    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _type = typeOf _vic;
        _pos = (getPos _vic) findEmptyPosition [0, 40, _type];
        _vic setPos _pos;
    }
    else
    {
        {
            _type = typeOf _x;
            _pos = (getPos _x) findEmptyPosition [0, 40, _type];
            _x setPos _pos;
        } forEach (units _group);
    };
};
pl_vehicle_soft_unstuck = {
    params ["_group"];
    private ["_vic"];
    _vic = vehicle (leader _group);
    _pos = [1, 1, 0.1] vectorAdd (getPos _vic);
    _vic setPos _pos;
};

pl_reset_group = {
    params ["_group"];

    {
        if !(_x isEqualTo player) then{
            _x spawn pl_hard_reset;
        };
    } forEach (units _group);

    _groupId = groupId _group;

    sleep 1.5;

    _newGroup = createGroup playerside;
    { 
        [_x] joinSilent _newGroup;
    } forEach (units _group);

    [_newGroup] spawn pl_set_up_ai;
    deleteGroup _group;

    _newGroup setGroupId [_groupId];
    player hcSetGroup [_newGroup]
};


pl_hard_reset = {
    params ["_unit"];

    _origGroup = group _unit;
    _pos = getPosATL _unit ;
    _damage = damage _unit;
    _dir = getDir _unit ;
    _type = typeOf _unit ;
    _name = name _unit ;
    _nameSound = nameSound _unit ;
    _face = face _unit ;
    _speaker = speaker _unit ;
    _loadout = getUnitLoadout _unit ;
    _unitWia = _unit getVariable "pl_wia";
    // _wpnCargo = getWeaponCargo (_pos nearestObject "weaponHolderSimulated");
    deleteVehicle _unit;

    _newUnit = _origGroup createUnit [_type,_pos,[],0,"CAN_COLLIDE"] ;
    _newUnit setDir _dir ;
    _newUnit setUnitLoadout _loadout ;
    // _newUnit addWeapon (_wpnCargo select 0 select 0) ;
    _newUnit setName _name ;
    _newUnit setNameSound _nameSound ;
    _newUnit setFace _face ;
    _newUnit setSpeaker _speaker ;
    _newUnit setDamage _damage;
    _newUnit setHit ["legs", 0];
    _newUnit setSkill pl_ai_skill;
    _newUnit setVariable ["pl_wia", false];
    _newUnit setVariable ["pl_unstuck_cd", 0];

    [_newUnit] spawn pl_auto_crouch;

    if (pl_enabled_medical) then {
        [_newUnit] call pl_medical_setup; 
        if (_unitWia) then {
            [_newUnit] spawn {
                params ["_newUnit"];
                sleep 0.1;
                _newUnit setUnconscious true;
                _newUnit setVariable ["pl_bleedout_time", 300];
                sleep 2;
                _newUnit setVariable ["pl_wia", true];
                sleep 1;
                [_newUnit] spawn pl_bleedout;
            };
        };
    };
};


pl_spawn_hard_reset = {
    {
        {
            [_x] call pl_hard_reset;
        } forEach (units _x);
        {
            _type = typeOf _x;
            _loadout = getUnitLoadout _x;
            _groupComposition pushBack [_x, _type, _loadout];
        } forEach (units _x);
    } forEach hcSelected player;

    _group setVariable ["pl_group_comp", _groupComposition];
};

pl_ch_vehicle_dir = {
    params ["_group"];
    private ["_vic"];

    if ((vehicle (leader _group)) == (leader _group)) exitWith {};

    _vic = vehicle (leader _group);
    _dir = getDir _vic;
    _vic setDir (_dir - 180);
};

// {[_x] call pl_ch_vehicle_dir} forEach (hcSelected player);

pl_reset_vehicle = {
    params ["_group"];
    private ["_vic"];

    if ((vehicle (leader _group)) == (leader _group)) exitWith {};

    _vic = vehicle (leader _group);
};

sleep 1;

[group player] call pl_set_up_ai;


pl_viv_trans_set_up = {
    params ["_group"];
    _vic = vehicle (leader _group);
    _targetVic = isVehicleCargo _vic;
    _group setVariable ["pl_show_info", false];
    (group (driver _targetVic)) setVariable ["setSpecial", true];
    (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
    {
        player hcRemoveGroup (group (_x select 0));
    } forEach fullCrew[_vic, "cargo", false];
};

pl_inf_trans_set_up = {
    params ["_group"];
    _targetVic = vehicle (leader _group);
    (group (driver _targetVic)) setVariable ["setSpecial", true];
    (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    _group setVariable ["pl_show_info", false];
};


player addEventHandler ["GetInMan", {
    params ["_vehicle", "_role", "_unit", "_turret"];
    private ["_group"];
    _group = group player;
    _vicGroup = group (driver (vehicle player));
    _vicGroup setVariable ["setSpecial", true];
    _vicGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
    player setVariable ["pl_player_vicGroup", _vicGroup];
    if (_vicGroup != (group player)) then {
        _group setVariable ["pl_show_info", false];
        player hcRemoveGroup _group;
    };
}];

player addEventHandler ["GetOutMan", {
    params ["_vehicle", "_role", "_unit", "_turret"];
    private ["_group"];
    _group = group player;
    _vicGroup = player getVariable ["pl_player_vicGroup", (group player)];
    _group setVariable ["setSpecial", false];
    _group setVariable ["onTask", false];
    _group setVariable ["pl_show_info", true];
    player hcSetGroup [_group];

    _cargo = fullCrew [(vehicle ((units _vicGroup)#0)), "cargo", false];
    if ((count _cargo == 0)) exitWith {
        _vicGroup setVariable ["setSpecial", false];
    };
    if (({(group (_x#0)) isEqualTo _group} count _cargo) > 0) then {
        [_vicGroup, _cargo, _group] spawn {
            params ["_vicGroup", "_cargo", "_group"];
            waitUntil {sleep 1; (({(group (_x#0)) isEqualTo _group} count (fullCrew [(vehicle ((units _vicGroup)#0)), "cargo", false])) == 0)};
            _vicGroup setVariable ["setSpecial", false];
        };
    };
}];

{
    _leader = leader _x;
    private _hcs = allMissionObjects "HighCommandSubordinate" select 0;
    if (isNil{_hcs}) exitWith {};
    if ((_hcs in (synchronizedObjects _leader)) and (vehicle _leader != _leader)) then {
        if (((assignedVehicleRole _leader) select 0) isEqualTo "cargo") then {
            [_x] call pl_inf_trans_set_up;
            [_x, true] spawn pl_contact_report;
        };
        if !(isNull (isVehicleCargo (vehicle _leader))) then {
            [_x] call pl_viv_trans_set_up;
            [_x, true] spawn pl_contact_report;

        };

    };
} forEach (allGroups select {side _x isEqualTo playerSide});



// [spec1] spawn pl_special_forces_skills;
