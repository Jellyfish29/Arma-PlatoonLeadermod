pl_global_spotrep_cd = 0;
pl_At_fire_report_cd = 0;
pl_ai_skill = 0.8;
pl_radio_range = 700;

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

pl_contact_info_share = {
    params ["_unit"];
    sleep 7;
    _targets = [];
    _targets = [_unit] call pl_get_targets;
    [_targets, _unit] call pl_reveal_targets;

    [_targets] spawn pl_mark_targets_on_map;
};

pl_contact_report = {
    params ["_group", "_time"];

    _leader = leader _group;
    _leader setVariable ["PlContactRepEnabled", true];
    _group setVariable ["PlContactTime", 0];
    if (vehicle _leader != _leader) then {
        _leader = vehicle _leader;
    };

    if (_leader != player) then {
        _leader addEventHandler ["FiredNear", {
            params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];

            if ((group _firer) isEqualTo (group _unit)) then {
                if (((group _unit) getVariable "PlContactTime") < time) then {
                        _callsign = groupId (group _unit);
                        _unit sideChat format ["%1 is Engaging Enemies, over", _callsign];
                        [_unit] spawn pl_contact_info_share;
                        (group _unit) setVariable ['inContact', true];
                };
                (group _unit) setVariable ["PlContactTime", (time + 60)];
                if ("launch" in (_weapon splitString "_")) then {
                    if (pl_At_fire_report_cd < time) then {
                        pl_At_fire_report_cd = time + 5;
                        _callsign = groupId (group _unit);
                        _unit sideChat format ["%1 is Engaging enemy Vehicles with AT Weapons, over", _callsign];
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
        player sideChat "to all Elements, stand by for SPOTREP, over";
        _targets = [];
        {
            if (player knowsAbout _x > 0) then {
              _targets pushBack _x;
            };
        } forEach (allUnits+vehicles select {side _x != playerSide});

        [_targets] spawn pl_mark_targets_on_map;

        [_targets, player] call pl_reveal_targets;
};

pl_set_ai_skill_option = {
    params ["_skill"];
    {
        _x setSkill _skill;
    } forEach allUnits select {side _x isEqualTo playerSide};  
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
            _killer sideChat format ["We destroyed an enemy %1 at %2, over", _typeStr, _gridPos];
        };
    };
};


pl_set_up_ai = {
    params ["_group"];
    private ["_magCountAll"];
    _group setVariable ["aiSetUp", true];
    _group setVariable ["onTask", false];
    _group setVariable ["inContact", false];
    _group setVariable ["sitrepCd", 0];
    _group allowFleeing 0;
    [_group] spawn pl_ammoBearer;
    {
        _x setSkill pl_ai_skill;
        if ((_x != player) or !(_x in switchableUnits)) then {
            _x unassignItem "Binocular";
            _x removeWeapon "Binocular";
            _x unassignItem "Rangefinder";
            _x removeWeapon "Rangefinder";
        };
    } forEach (units _group);
    _magCountAll = 0;
    {
        // Ammo Count
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

        // WIA Set Up
        _x setVariable ["pl_wia", false];
        _x setVariable ["pl_wia_calledout", false];
        _x setVariable ["pl_bleedout_set", false];
        _x setVariable ["pl_damage_reduction", false];
        _x addEventHandler ['HandleDamage', {
            params['_unit', '_selName', '_damage', '_source'];
            if (_unit getVariable "pl_damage_reduction") then {
                _dmg = _damage * 0.7 ;
                _damage = _dmg;
            };
            if !(_unit getVariable "pl_wia") then {
                if (_damage > 0.99) then {
                    if (([0, 100] call BIS_fnc_randomInt) > 20) then {
                        _damage = 0;
                        _unit setUnconscious true;
                        if !(_unit getVariable "pl_wia_calledout") then {
                            [_unit] spawn pl_wia_callout;
                        };
                        if !(_unit getVariable "pl_bleedout_set") then {
                            [_unit] spawn pl_bleedout;
                        };
                    };
                };
            };
            _damage
        }];
    } forEach (units _group);

    _group setVariable ["magCountAllDefault", _magCountAll];
    _magCountSolo = round (_magCountAll / (count (units _group)));
    _group setVariable ["magCountSoloDefault", _magCountSolo];

    _unitCount = count (units _group);
    _group setVariable ["_unitCountDefault", _unitCount];
};



pl_ai_setUp_loop = {
    while {true} do {
        {
            if (isNil {_x getVariable "spotRepEnabled"}) then {
                [_x] spawn pl_share_info;
            };
            if (isNil {(leader _x) getVariable "PlContactRepEnabled"}) then {
                [_x] spawn pl_contact_report;
            };
            if (isNil {_x getVariable "aiSetUp"}) then {
                [_x] call pl_set_up_ai;
            };
            
        } forEach (allGroups select {side _x isEqualTo playerSide});
        sleep 10;
        {
            if(_x != (group player)) then {
                _x enableAttack false;
                _x setCombatMode "YELLOW";
            };
        } forEach allGroups;
        sleep 10;
    };
};

[] spawn pl_ai_setUp_loop;
