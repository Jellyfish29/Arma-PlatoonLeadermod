sleep 1.5;

pl_global_spotrep_cd = 0;
pl_At_fire_report_cd = 0;
// pl_ai_skill = 0.8;
// pl_radio_range = 700;
pl_max_reinforcement_per_vic = parseNumber pl_max_reinforcement_per_vic;
pl_max_repair_supplies_per_vic = parseNumber pl_max_repair_supplies_per_vic;
pl_max_mines_per_explo = parseNumber pl_max_mines_per_explo;
pl_abandoned_markers = [];
pl_at_targets_indicator = [];
pl_bleedout_time = 1000;
pl_plow_vehicles = ["B_APC_Tracked_01_CRV_F", "B_T_APC_Tracked_01_CRV_F", "rhsusf_stryker_m1132_m2_wd", "rhsusf_stryker_m1132_m2_d"];

pl_share_info = {

    params ["_group"];
    _group setVariable ["spotRepEnabled", true];

    while {sleep 1; count ((units _group) select {alive _x}) > 0} do {
        waitUntil {sleep 1; (behaviour (leader _group)) isEqualto "COMBAT"};

        _targets = [];

        // [_targets] spawn pl_mark_targets_on_map;

        _targets = [(leader _group)] call pl_get_targets;
        if !(_targets isEqualto []) then {
            [_targets, (leader _group)] call pl_reveal_targets;
            [_targets, _group] call pl_mark_targets_on_map;
        };

        sleep 8 + (random 4);
    };
};

pl_get_targets = {
    params ["_leader"];
    private ["_targets"];
    _targets = [];
    {
        if (alive _x and [(side _x), playerside] call BIS_fnc_sideIsEnemy) then {
            if (_leader knowsAbout _x > 0.105) then {
                _targets pushBack _x;
            };
        };
    } forEach (allUnits+vehicles);
    _targets
};

pl_reveal_targets = {
    params ["_targets", "_leader"];
    {
        _t = _x;
        {
            if (((leader _x) distance2D _leader) < ((group _leader) getVariable ["pl_radio_range_custom", pl_radio_range])) then {
                _x reveal _t;
            };
        } forEach (allGroups select {side _x isEqualTo playerSide});
    } forEach _targets;
};



pl_share_info_opfor = {

    params ["_group"];
    _group setVariable ["spotRepEnabled", true];

    while {sleep 1; count ((units _group) select {alive _x}) > 0} do {
        // waitUntil {(behaviour (leader _group)) isEqualto "COMBAT"};

        _targets = [];

        // [_targets, _group] spawn pl_mark_targets_on_map;

        _targets = [(leader _group)] call pl_get_targets_opfor;
        if !(_targets isEqualto []) then {
            [_targets, (leader _group)] call pl_reveal_targets_opfor;
        };

        sleep 15;
    };
};

pl_get_targets_opfor = {
    params ["_leader"];
    private ["_targets"];
    _targets = [];
    {
        if (alive _x and (side _x) != civilian) then {
            if (_leader knowsAbout _x > 0) then {
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
            // if (((leader _x) distance2D _leader) < (pl_radio_range / 2) and ((_leader distance2D _t) < 300)) then {
            if (((leader _x) distance2D _leader) < pl_radio_range) then {
                _x reveal _t;
            };
        } forEach (allGroups select {side _x != playerSide});
    } forEach _targets;
};

pl_forget_targets = {
    params ["_group", ["_infoTimeOut", 30]];

    {
        _group forgetTarget _x;
    } forEach allUnits;

    _group setVariable ["pl_radio_range_custom", 0];
    sleep _infoTimeOut;
    _group setVariable ["pl_radio_range_custom", nil];
};

pl_forget_group = {
    params ["_group"];
    {
        _grp = _x;
        {
            _grp forgetTarget _x;
        } forEach (units _group);
    } forEach (allGroups select {side _x != playerSide});
};

pl_forget_unit = {
    params ["_unit"];
    {
        _x forgetTarget _unit;
    } forEach (allGroups select {side _x != playerSide});
};


pl_contact_info_share = {
    params ["_unit"];

    sleep (random 4);

    _targets = [_unit] call pl_get_targets;
    [_targets, _unit] call pl_reveal_targets;

    [_targets, group _unit] call pl_mark_targets_on_map;
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

            // onContact SOPs

            if ((group _firer) isEqualTo (group _unit)) then {
                if (((group _unit) getVariable "PlContactTime") < time) then {

                    _callsign = groupId (group _unit);
                    if ((vehicle _unit) isKindOf "Air") then {
                        if (pl_enable_beep_sound) then {playSound "beep"};
                        if (pl_enable_chat_radio) then {_unit sideChat format ["%1: Engaging Ground Targets", _callsign]};
                            if (pl_enable_map_radio) then {[group _unit, "...Engaging Ground Targets!", 15] call pl_map_radio_callout};
                    }
                    else
                    {
                        if (pl_enable_beep_sound) then {playSound "beep"};
                        if (pl_enable_chat_radio) then {_unit sideChat format ["%1: Engaging Enemies", _callsign]};
                        if (pl_enable_map_radio) then {[group _unit, "...Contact!", 15] call pl_map_radio_callout};
                        [group _unit, "contact", 1] call pl_voice_radio_answer;

                    };
                    [_unit] spawn pl_contact_info_share;
                    (group _unit) setVariable ['inContact', true];


                    {
                        _hcGroup = _x;
                        if (_hcGroup getVariable ["pl_sop_active", false]) then {

                            if (_unit distance2D (leader _hcGroup) < 300) then {

                                if (_hcGroup getVariable ["pl_sop_atkOnContact", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    if (vehicle _unit == _unit) then {
                                        [_hcGroup, [], getPos (_unit findNearestEnemy (getPos _unit))] spawn pl_assault_position;
                                        [_hcGroup] call pl_reset_sop;
                                    };
                                };

                                if (_hcGroup getVariable ["pl_sop_defOnContact", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    [_hcGroup, [], getPos (leader _hcGroup), getDir _unit, false, false, 35] spawn pl_defend_position;
                                    [_hcGroup] call pl_reset_sop;
                                };

                                if (_hcGroup getVariable ["pl_sop_disengageOnContact", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    [_hcGroup, _hcGroup getVariable ['pl_last_wp_pos', getPos _unit]] spawn pl_disengage;
                                    [_hcGroup] call pl_reset_sop;
                                };

                                if (_hcGroup getVariable ["pl_sop_stopOnContact", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    [_hcGroup] call pl_reset;
                                    [_hcGroup] call pl_reset_sop;
                                };

                                if (_hcGroup getVariable ["pl_sop_unloadUnderAt", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    [_hcGroup] spawn pl_unload_at_combat;
                                    [_hcGroup] call pl_reset_sop;
                                };

                                // [_hcGroup] call pl_reset_sop;
                            };
                        };
                    } forEach (allGroups select {(hcLeader _x) == player});

                };
                (group _unit) setVariable ["PlContactTime", (time + 80)];
                // if ("launch" in (_weapon splitString "_")) then {
                if ((secondaryWeapon _firer) isEqualTo _weapon) then {
                    if (pl_At_fire_report_cd < time) then {
                        pl_At_fire_report_cd = time + 5;
                        _callsign = groupId _hcGroup;
                        if (pl_enable_chat_radio) then {_unit sideChat format ["%1: Engaging Vehicles with AT", _callsign]};
                        if (pl_enable_map_radio) then {[group _unit, "...Engaging Vehicle!", 15] call pl_map_radio_callout};
                    };

                    if (pl_fire_indicator_enabled) then {
                        _target = assignedTarget _firer;
                        if !(isNull _target) then {
                            [_firer, _target] spawn {
                                params ["_firer", "_target"];
                                _firerPos = getPos _firer;
                                _targetPos = getPos _target;
                                pl_at_targets_indicator pushBack [_firerPos, _targetPos];

                                sleep 8;

                                pl_at_targets_indicator = pl_at_targets_indicator - [[_firerPos, _targetPos]];
                            };
                        };
                    };
                };

                if (pl_fire_indicator_enabled and ((vehicle _firer) isKindOf "Tank" or (vehicle _firer) isKindOf "Car") or (getNumber (configFile >> "CfgVehicles" >> typeOf (vehicle _firer) >> "artilleryScanner")) == 1) then {
                    _target = assignedTarget _firer;
                    if (!(isNull _target) and !(_firer getVariable ["pl_fire_indicator_on", false])) then {
                        [_firer, _target] spawn {
                            params ["_firer", "_target"];
                            _firerPos = getPos _firer;
                            _targetPos = getPos _target;
                            pl_at_targets_indicator pushBack [_firerPos, _targetPos];
                            _firer setVariable ["pl_fire_indicator_on", true];

                            sleep 5;

                            pl_at_targets_indicator = pl_at_targets_indicator - [[_firerPos, _targetPos]];
                            _firer setVariable ["pl_fire_indicator_on", false];
                        };
                    };
                };
            };
            if !(alive _unit) then {
                _unit setVariable ["PlContactRepEnabled", false];
            };
        }];

        _leader addEventHandler ["Killed", {
            params ["_unit", "_killer", "_instigator", "_useEffects"];

            [group _unit] call pl_contact_report;
        }];
    };

    {
        _x addEventHandler ["Hit", {
            params ["_unit", "_source", "_damage", "_instigator"];

            if ((side _source) != playerSide) then {
                if (((group _unit) getVariable "PlContactTime") < time) then {

                    _callsign = groupId (group _unit);
                    if ((vehicle _unit) isKindOf "Air") then {
                        if (pl_enable_beep_sound) then {playSound "beep"};
                        if (pl_enable_chat_radio) then {_unit sideChat format ["%1: Taking Ground Fire!", _callsign]};
                            if (pl_enable_map_radio) then {[group _unit, "...Taking Ground Fire!", 15] call pl_map_radio_callout};
                    }
                    else
                    {
                        if (pl_enable_beep_sound) then {playSound "beep"};
                        if (pl_enable_chat_radio) then {_unit sideChat format ["%1: Incoming", _callsign]};
                        if (pl_enable_map_radio) then {[group _unit, "...Incoming!", 15] call pl_map_radio_callout};
                        [group _unit, "contact", 1] call pl_voice_radio_answer;

                    };
                    [_unit] spawn pl_contact_info_share;
                    (group _unit) setVariable ['inContact', true];


                    {
                        _hcGroup = _x;
                        if (_hcGroup getVariable ["pl_sop_active", false]) then {

                            if (_unit distance2D (leader _hcGroup) < 300) then {

                                if (_hcGroup getVariable ["pl_sop_atkOnContact", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    if (vehicle _unit == _unit) then {
                                        [_hcGroup, [], getPos (_unit findNearestEnemy (getPos _unit))] spawn pl_assault_position;
                                        [_hcGroup] call pl_reset_sop;
                                    };
                                };

                                if (_hcGroup getVariable ["pl_sop_defOnContact", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    [_hcGroup, [], getPos (leader _hcGroup), getDir _unit, false, false, 35] spawn pl_defend_position;
                                    [_hcGroup] call pl_reset_sop;
                                };

                                if (_hcGroup getVariable ["pl_sop_disengageOnContact", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    [_hcGroup, _hcGroup getVariable ['pl_last_wp_pos', getPos _unit], true] spawn pl_disengage;
                                    [_hcGroup] call pl_reset_sop;
                                };

                                if (_hcGroup getVariable ["pl_sop_stopOnContact", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    [_hcGroup] call pl_reset;
                                    [_hcGroup] call pl_reset_sop;
                                };

                                if (_hcGroup getVariable ["pl_sop_unloadUnderAt", false] and !(_hcGroup getVariable ["onTask", false])) then {
                                    [_hcGroup] spawn pl_unload_at_combat;
                                    [_hcGroup] call pl_reset_sop;
                                };

                                // [_hcGroup] call pl_reset_sop;
                            };
                        };
                    } forEach (allGroups select {(hcLeader _x) == player});

                };
                (group _unit) setVariable ["PlContactTime", (time + 20)];
            };


        }];
    } forEach (units _group);
};

// {
//     [_x] call pl_contact_report
// } forEach (allGroups select {(hcLeader _x) == player});



pl_player_report = {
    if (pl_enable_beep_sound) then {playSound "beep"};
    // player sideChat "to all Elements, stand by for SPOTREP, over";
    _targets = [];
    {
        if (player knowsAbout _x > 0) then {
          _targets pushBack _x;
        };
    } forEach (allUnits+vehicles select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

    [_targets, group player] spawn pl_mark_targets_on_map;

    [_targets, player] call pl_reveal_targets;
};

pl_enemy_destroyed_report = {
    params ["_unit", "_killer", "_group"];

    _typeStr = "Infantry Unit";
    if (vehicle _unit != _unit) then {
        _vic = vehicle _unit;
        _typeStr = getText (configFile >> "CfgVehicles" >> typeOf _vic >> "displayName");
    };
    _group setVariable ["pl_marta_no_delete", true];
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
            _group setVariable ["pl_death_reported", true];
            _gridPos = mapGridPosition _unit;
            // if (pl_enable_beep_sound) then {playSound "beep"};
            if (pl_enable_chat_radio) then {_killer sideChat format ["%1 destroyed enemy %2", groupId (group _killer), _typeStr]};
            if (pl_enable_map_radio) then {[group _killer, format ["...destroyed enemy %1", _typeStr], 15] call pl_map_radio_callout};
            [group _killer, "destroyed", 1] call pl_voice_radio_answer;
            [_group, true] spawn pl_marta_cleanup;
        } else {
            _group setVariable ["pl_marta_no_delete", nil];
        };
    } else {
        _group setVariable ["pl_marta_no_delete", nil];
    };
};

pl_auto_crouch = {
    params ["_unit"];

    if !(pl_auto_crouch_enabled) exitwith {};

    while {alive _unit} do {
        if ((behaviour _unit) isEqualTo "AWARE") then {
            if (_unit checkAIFeature "PATH" and !((group _unit) getVariable ["onTask", false])) then {
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

pl_auto_360 = {
    params ["_group"];
    private ["_leader"];

    if (true) exitwith {};

    if (_group == (group player)) exitWith {};

    sleep 25;

    if !(pl_auto_360_enabled) exitwith {};

    while {!(isNull _group) and pl_auto_360_enabled} do {

        _leader = leader _group;

        if (!(_group getVariable ["onTask", false]) and !(_group getVariable ["pl_on_march", false]) and !(_group getVariable ["pl_is_task_selected", false]) and (vehicle _leader) == _leader) then {

            if (speed _leader == 0 and (vehicle _leader) == _leader) then {
                sleep 8;
                if (speed _leader == 0 and !(_group getVariable ["onTask", false]) and !(_group getVariable ["pl_on_march", false]) and !(_group in (hcSelected player)) and !(_group getVariable ["pl_is_task_selected", false]) and (vehicle _leader) == _leader) then {
                    [_group, [], getPos _leader, 0, false, false,  20, true] spawn pl_defend_position;
                };
            };
        };

        sleep 5;
    }; 

};

// [] spawn pl_auto_360;

pl_auto_formation = {
    params ["_group"];
    private ["_dest", "_distance"];

    // if (vehicle (leader _group) != (leader _group)) exitWith {};
    waitUntil {sleep 1; vehicle (leader _group) == (leader _group)};
    _group setVariable ["pl_choose_auto_formation", true];

    _group setFormation "LINE";
    while {sleep 0.5; {alive _x} count (units _group) > 0} do {

        waitUntil {sleep 1; vehicle (leader _group) == (leader _group)};
        waitUntil {sleep 1; !(_group getVariable ["pl_vic_attached", false]) and (_group getVariable ["pl_choose_auto_formation", false])};

        if ([getPos (leader _group)] call pl_is_city) then {
            if (formation _group != "DIAMOND") then {
                _group setFormation "DIAMOND";
            }; 
        } else {
            if ((currentWaypoint _group) < count (waypoints _group)) then {
                _dest = waypointPosition ((waypoints _group) select (count (waypoints _group) - 1));
                _distance = _dest distance2D (leader _group);
                if (_distance > 300 and behaviour (leader _group) != "COMBAT") then {
                    if (formation _group != "STAG COLUMN") then {
                        _group setFormation "STAG COLUMN";
                    };
                } else {
                    if (formation _group != "LINE") then {
                        _group setFormation "LINE";
                    };
                };
            } else {
                if (formation _group != "LINE") then {
                    _group setFormation "LINE";
                };
            };
        };
        sleep 5;
    };   
};

pl_auto_vic_speed = {
    params ["_vic"];

    _vic setVariable ["pl_choose_auto_speed", true];
    private _group = group (driver _vic);

    while {alive _vic and ({alive _x} count (crew _vic)) > 0} do {
        waitUntil {sleep 1; _vic getVariable ["pl_choose_auto_speed", false] and (_vic getVariable ["pl_speed_limit", "CON"]) != "CON"};
        if ([getPos _vic] call pl_is_city or [getPos _vic] call pl_is_forest) then {
            _vic limitSpeed 15;
            _vic setVariable ["pl_speed_limit", "15"];
        } else {
            if ((currentWaypoint _group) < count (waypoints _group)) then {
                _dest = waypointPosition ((waypoints _group) select ((count (waypoints _group)) - 1));
                _distance = _dest distance2D _vic;
                if (_distance > 300) then {
                    _vic limitSpeed 50;
                    _vic setVariable ["pl_speed_limit", "50"];
                } else {
                    _vic limitSpeed 30;
                    _vic setVariable ["pl_speed_limit", "30"];
                };
            } else {
                _vic limitSpeed 50;
                _vic setVariable ["pl_speed_limit", "50"];
            };
        };
        sleep 5;
    };  
};


pl_medical_setup = {
    params ["_unit"];
    _unit setVariable ["pl_beeing_treatet", false];
    _unit setVariable ["pl_wia_calledout", false];
    _unit setVariable ["pl_injured", false];
    _unit setVariable ["pl_bleedout_time", pl_bleedout_time];
    _unit setVariable ["pl_bleedout_set", false];
    _unit setVariable ["pl_damage_reduction", false];

    _unit addEventHandler ['HandleDamage', {
        params['_unit', '_selName', '_damage', '_source'];

        if ((_unit getVariable "pl_damage_reduction") or (_unit getVariable ["pl_special_force", false])) then {

            if ((getNumber (configFile >> "CfgVehicles" >> typeOf _source >> "artilleryScanner")) == 1) then {
                _dmg = _damage * 0.25 ;
                _damage = _dmg;
                // _damage = 0;
                // player sideChat (format ["%1   %2", _unit, _damage]);
            } else {
                _dmg = _damage * 0.8 ;
                _damage = _dmg;
            };
        };

        // if ((_source isKindOf "Tank" or _source isKindOf "Car") and (side _source) isEqualto (side _unit)) then {_damage = 0};

        if !(_unit getVariable "pl_wia") then {
            if (_damage > 0.99) then {
                // if (([0, 100] call BIS_fnc_randomInt) > 10) then {
                    _damage = 0;
                    _unit setUnconscious true;
                    if (vehicle _unit != _unit) then {
                        if !(alive (vehicle _unit)) then {
                            if ((vehicle _unit) getVariable ["pl_has_cargo", false] and _unit == (driver (vehicle _unit))) then {
                                [group _unit, (vehicle _unit)] call pl_eject_cargo;
                            };
                            if !((group _unit) getVariable ["pl_show_info", false]) then {[group _unit] call pl_show_group_icon};
                            [_unit, vehicle _unit] call pl_crew_eject;
                        };
                    };
                    if !(_unit getVariable "pl_wia_calledout") then {
                        [_unit] spawn pl_wia_callout;
                    };
                    if !(_unit getVariable "pl_bleedout_set") then {
                        [_unit] spawn pl_bleedout;
                    };

                // };
            }
            else
            {
                _unit setVariable ["pl_injured", true];
            };
        };
        _damage
    }];
};

pl_ammo_bearer = {
    params ["_group"];

    {
        _unit = _x;
        if (!(_unit getVariable ["pl_ammo_bearer_set", false]) and _unit != player) then {
            _unit setVariable ["pl_ammo_bearer_set", true];
            _unit addEventHandler ["Reloaded", {
                params ["_unit", "_weapon", "_muzzle", "_newMagazine", "_oldMagazine"];

                _mag = _oldMagazine#0;
                _magCount = count ((magazines _unit) select {_x isEqualTo _mag});
                if (_magCount <= 0 and (_weapon != (secondaryWeapon _unit))) then {
                    _ammoBearer = objNull;
                    _highestAmount = 0;
                    {
                        _friendMagCount = count ((magazines _x) select {_x isEqualTo _mag});
                        if (_friendMagCount > _highestAmount ) then {
                            _highestAmount = _friendMagCount;
                            _ammoBearer = _x;
                        };
                    } forEach ((units (group _unit)) - [_unit]);
                    if !(isNull _ammoBearer) then {
                        _unit addItem _mag;
                        _ammoBearer removeItem _mag;
                    };
                };
            }];

            if !((secondaryWeapon _unit) == "") then {
                _unit addEventHandler ["FiredMan", {
                    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

                    if (_weapon == (secondaryWeapon _unit)) then {
                        {
                            _friend = _x;
                            _friendMagCount = count ((magazines _friend) select {_x isEqualTo _magazine});
                            if (_friendMagCount >= 1) exitWith {
                                if (_unit canAdd _magazine) then {
                                    _unit addItem _magazine;
                                }
                                else
                                { 
                                    [_unit, _magazine] spawn {
                                        params ["_unit", "_magazine"];
                                        sleep 1;
                                        _unit playMove "ReloadRPG";
                                        _unit addSecondaryWeaponItem _magazine;
                                    };
                                };
                                _friend removeItem _magazine;
                            }; 
                        } forEach ((units (group _unit)) - [_unit]);
                    };
                }];
            };
        };
    } forEach (units _group);
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

pl_actvie_mg_gunners = [];

pl_add_unit_fire_indicator = {
    params ["_unit"];

    if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
        pl_actvie_mg_gunners pushBack _unit;
    };

    _unit addEventHandler ["FiredMan", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

        [_unit] spawn {
            params ["_unit"];

            _unit setVariable ["pl_firing", true];

            sleep 0.1;

            _unit setVariable ["pl_firing", false];
        };
    }];
};

pl_set_up_ai = {
    params ["_group"];
    private ["_magCountAll", "_magCountSolo", "_mag"];
    if ((vehicle (leader _group)) != leader _group) then {
        _vic = vehicle (leader _group);
        _vic setVariable ["pl_rtb_pos", getPos _vic];
        // [_group] call pl_hc_mech_inf_icon_changer;
        // if (_vic isKindOf "Air" and pl_enable_auto_air_remove) then {
        //     player hcRemoveGroup _group;
        // };
    };
    _group setVariable ["aiSetUp", true];
    _group setVariable ["onTask", false];
    _group setVariable ["inContact", false];
    _group setVariable ["sitrepCd", 0];
    _group setVariable ["pl_show_info", true];
    _group setVariable ["pl_hold_fire", false];
    _group setVariable ["pl_killed_units", []];
    _group setVariable ["pl_allow_static", true];
    // SOP Set UP
    _group setVariable ["pl_sop_def_disenage", true];
    _group setVariable ["pl_sop_def_ATEngagement", true];
    _group setVariable ["pl_sop_def_resupply", true];
    _group setVariable ["pl_sop_def_suppress", true];
    _group setVariable ["pl_sop_def_deployStatic", true];
    _group setVariable ["pl_sop_atk_disenage", true];
    _group setVariable ["pl_sop_atk_ATEngagement", true];
    _groupComposition = [];

    private _engineer = objNull;
    _engineer = {
        if (_x getUnitTrait "engineer") exitWith {_x};
        objNull
    } forEach (units _group);

    if !(isNull _engineer) then {
        _group setVariable ["pl_is_repair_group", true];
        _group setVariable ["pl_repair_supplies", 10]
    };

    if (pl_enable_map_radio) then {
        [_group] spawn pl_reset_group_radio_setup;
    };

    if (pl_auto_360_enabled) then {
        [_group] spawn pl_auto_360;
    };

    if !(_group getVariable ["pl_is_reset", false]) then {
        {
            _type = typeOf _x;
            _loadout = getUnitLoadout _x;
            _groupComposition pushBack [_x, _type, _loadout];
        } forEach (units _group);

        _group setVariable ["pl_group_comp", _groupComposition];
    };
    
    _group allowFleeing 0;

    [_group] call pl_ammo_bearer;
    if (_group != (group player)) then {[_group] spawn pl_auto_formation};

    {
        if (_x getUnitTrait "Medic") exitWith {
            [_group] spawn {
                params ["_g"];
                sleep 2;
                // [_g] spawn pl_heal_group;
                _g setVariable ["pl_healing_active", true];
            };
        };
    } forEach (units _group);
        
    _magCountAll = 0;
    {    
        _primary = primaryWeapon _x;
        _standartMagAmount = ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> _primary >> "magazines") apply {toUpper _x})} count magazines _x) + 1;
        _magCountAll = _magCountAll + _standartMagAmount;
        [_x, _group] call pl_set_up_single_unit;
    } forEach (units _group);

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
 
    if ((([_vic] call BIS_fnc_objectType)#1) == "StaticWeapon") exitWith {};

    _vic setUnloadInCombat [false, false];
    _vic allowCrewInImmobile true;
    _vic setVariable ["pl_assigned_group", group (driver _vic)];
    _vic allowService 0;
    
    if (isNil {_vic getVariable "pl_vehicle_setup_complete"}) then {
        _vic limitSpeed 50;
        _vic setVariable ["pl_speed_limit", "50"];

        // {
        //     _x addEventHandler ["GetOutMan", {
        //         params ["_unit", "_role", "_vehicle", "_turret"];

        //         if (_role == "driver" and !(canMove _vehicle) and alive _unit) then {

        //             _markerName = format ["abandoned%1", _vehicle];
        //             createMarker [_markerName, getPos _vehicle];
        //             _markerName setMarkerType "mil_destroy";
        //             _vicName = getText (configFile >> "CfgVehicles" >> typeof _vehicle >> "displayName");
        //             _markerName setMarkerText format ["Abandoned %1", _vicName];

        //             pl_abandoned_markers pushBackUnique [_vehicle, _markerName];
        //         };
        //     }];

        //     _x addEventHandler ["GetInMan", {
        //         params ["_unit", "_role", "_vehicle", "_turret"];
                
        //         if (_role == "driver") then {
        //             {
        //                 if (_vehicle == (_x#0)) exitWith {
        //                     deleteMarker (_x#1);
        //                     pl_abandoned_markers = pl_abandoned_markers - [[_x#0, _x#1]];
        //                 };
        //             } forEach pl_abandoned_markers;
        //         };
        //     }];
        // } forEach (crew _vic);

        [_vic] spawn pl_vehicle_tree_stuck_fix;
        [_vic] spawn pl_auto_vic_speed;

        if (isNil {_vic getVariable "pl_repair_lifes"}) then {
            if (_vic isKindOf "Tank") then {
                _vic setVariable ["pl_repair_lifes", 100]; //4
            }
            else
            {
                _vic setVariable ["pl_repair_lifes", 100]; //2
            };
        };

        // if (isNil {_vic getVariable "pl_appereance"}) then {
        //     _animations = "true" configClasses (configFile >> "CfgVehicles" >> typeOf _vic >> "AnimationSources");
        //     _animationPhases = [];

        //     {
        //         _s = (str _x) splitString "/";
        //         _a =  _s select ((count _s) - 1);
        //         _animationPhases pushBack [_a, (_vic animationSourcePhase _a)];
        //     } forEach _animations;

        //     _vic setVariable ["pl_appereance", _animationPhases];
        // };

        _vic setVariable ["pl_appereance", [_vic] call BIS_fnc_getVehicleCustomization];

        _vic addEventHandler ['HandleDamage', {
            params['_unit', '_selName', '_damage', '_source'];
            if ((_unit getVariable "pl_damage_reduction")) then {
                _dmg = _damage * 0.8;
                _damage = _dmg;
            };
            _damage
        }];
        // Supply Vehicle setup
        _vicType = typeOf _vic;
        _ammoCap = getNumber (configFile >> "cfgVehicles" >> _vicType >> "transportAmmo");
        _magazineCap = getNumber (configFile >> "cfgVehicles" >> _vicType >> "transportMaxMagazines");
        _repairCap = getNumber (configFile >> "cfgVehicles" >> _vicType >> "transportRepair");
        _transportCap = getNumber (configFile >> "cfgVehicles" >> _vicType >> "transportSoldier");

        if ((_magazineCap >= 256 and _transportCap > 8 and _repairCap <= 0 and _vic isKindOf "Car") or _vic getVariable ["pl_is_supply_vehicle", false] or _ammoCap > 0) then {
            _vic setVariable ["pl_is_supply_vehicle", true];
            if ((_vic getVariable ["pl_supplies", -1]) == -1) then {_vic setVariable ["pl_supplies", pl_max_supplies_per_vic]};
            if ((_vic getVariable ["pl_avaible_reinforcements", -1]) == -1) then {_vic setVariable ["pl_avaible_reinforcements", pl_max_reinforcement_per_vic]};
            _vic setAmmoCargo 0;
            // [group (driver _vic)] spawn {
            //     params ["_grp"];
            //     sleep 5;
            //     [_grp, "f_truck_sup_pl"] call pl_change_group_icon;
            // };
        };

        if (_repairCap > 0 or _vic getVariable ["pl_is_repair_vehicle", false]) then {
            _vic setVariable ["pl_is_repair_vehicle", true];
            if ((_vic getVariable ["pl_repair_supplies", -1]) == -1) then {_vic setVariable ["pl_repair_supplies", pl_max_repair_supplies_per_vic]};
            _vic setVariable ["pl_bridge_available", true];
            _vic setRepairCargo 0;

            if (_vic isKindOf "Tank") then {
                if ((_vic getVariable ["pl_line_charges", -1]) == -1) then {_vic setVariable ["pl_line_charges", 4]};
            };

            // [group (driver _vic)] spawn {
            //     params ["_grp"];
            //     _grp setvariable ["pl_is_repair_group", true];
            //     sleep 5;
            //     [_grp, "f_truck_rep_pl"] call pl_change_group_icon;
            // };
        } else {
            if (([_vic] call pl_is_apc) or ([_vic] call pl_is_ifv) or _vic isKindOf "Car") then {
                _vic setVariable ["pl_supplies", 40];
            };
        };

        if ((typeof _vic) isEqualTo "gm_ge_army_bibera0") then {_vic setVariable ["pl_bridge_available", true];};

        if (_vic getVariable ["pl_is_mine_vic", false]) then {
            if ((_vic getVariable ["pl_virtual_mines", -1]) == -1) then {_vic setVariable ["pl_virtual_mines", 150]};
        };

        if (_vic getVariable ["pl_is_mc_lc_vehicle", false]) then {
            if ((_vic getVariable ["pl_line_charges", -1]) == -1) then {_vic setVariable ["pl_line_charges", 4]};
        };
        
        if (_vic getVariable ["pl_is_eng_apc", false]) then {
            _vic setVariable ["pl_is_mine_vic", true];
            _vic setVariable ["pl_is_mc_lc_vehicle", true];
            if ((_vic getVariable ["pl_virtual_mines", -1]) == -1) then {_vic setVariable ["pl_virtual_mines", 150]};
            if ((_vic getVariable ["pl_line_charges", -1]) == -1) then {_vic setVariable ["pl_line_charges", 4]};
            _vic setVariable ["pl_bridge_available", true];
            [(group (driver _vic))] spawn pl_continous_mine_detection;
        };

        if ((typeof _vic) in pl_plow_vehicles) then {_vic setVariable ["pl_is_eng_vic_plow", true]};

        // Missile alert
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

            // onAT SOPS

            // if (group (driver _target) getVariable ["pl_sop_stopUnderAt", false] and !(group (driver _target) getVariable ["onTask", false])) then {
            //     [group (driver _target)] call pl_reset;
            // };
            // if (group (driver _target) getVariable ["pl_sop_disengageUnderAt", false]) then {
            //     [group (driver _target), (group (driver _target)) getVariable ['pl_last_wp_pos', getPos _target]] spawn pl_disengage;
            // };
            // [group (driver _target)] call pl_reset_sop;

            {
                if (group (driver _target) getVariable ["pl_sop_unloadUnderAt", false]) then {
                    [group (driver _x)] spawn pl_unload_at_combat;
                    [group (driver _x)] call pl_reset_sop;
                };
                if (group (driver _x) getVariable ["pl_sop_atkOnContact", false]) then {
                    [group (driver _x), [], getPos _vehicle] spawn pl_suppressive_fire_position;
                    [group (driver _x)] call pl_reset_sop;
                };
                if (group (driver _x) getVariable ["pl_sop_defOnContact", false]) then {
                    // [group (driver _x)] spawn pl_unload_at_combat;
                    [group (driver _x), [], getPos _x, getDir _x, false, false, 35] spawn pl_defend_position;
                    [group (driver _x)] call pl_reset_sop;
                };
                if (group (driver _x) getVariable ["pl_sop_stopOnContact", false] and !(group (driver _x) getVariable ["onTask", false])) then {
                    [group (driver _x)] call pl_reset;
                    [group (driver _x)] call pl_reset_sop;
                };
                if (group (driver _x) getVariable ["pl_sop_disengageOnContact", false]) then {
                    [group (driver _x), (group (driver _x)) getVariable ['pl_last_wp_pos', getPos _x]] spawn pl_disengage;
                    [group (driver _x)] call pl_reset_sop;
                };
            } forEach (vehicles select {_x distance2D _target <= 150});

        }];


        (driver _vic) addEventHandler ["GetOutMan", {
            params ["_unit", "_role", "_vehicle", "_turret"];

            if (_vehicle getVariable ["pl_has_cargo", false]) then {
                [group _unit, _vehicle] call pl_eject_cargo;
            };
        }];

        _vic addEventHandler ["HandleDamage", {
            params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

            if (["mine", _projectile] call BIS_fnc_inString) then {

                if !(_unit getVariable ["pl_mine_called_out", false]) then {
                    if (pl_enable_beep_sound) then {playSound "radioina"};
                    if (pl_enable_chat_radio) then {(leader (group (driver _unit))) sideChat format ["...We Just Hit a Mine", (groupId (group (driver _unit)))]};
                    if (pl_enable_map_radio) then {[(group (driver _unit)), "...We Just Hit a Mine", 20] call pl_map_radio_callout};

                    _mineArea = createMarker [str (random 3), getPos _unit];
                    _mineArea setMarkerShape "RECTANGLE";
                    _mineArea setMarkerBrush "Cross";
                    _mineArea setMarkerColor "colorORANGE";
                    _mineArea setMarkerAlpha 0.5;
                    _mineArea setMarkerSize [25, 25];
                    _mineArea setMarkerDir (getDir _unit);
                    pl_engineering_markers pushBack _mineArea;

                    _mines = allMines select {(_x distance2D _unit) < 20};

                    {
                        _m = createMarker [str (random 3), getPos _x];
                        _m setMarkerType "mil_triangle";
                        _m setMarkerSize [0.4, 0.4];
                        _m setMarkerColor "ColorRed";
                        _m setMarkerShadow false;
                        pl_engineering_markers pushBack _m;
                        playerSide revealMine _x;
                    } forEach _mines;

                    _unit setVariable ["pl_mine_called_out", true];

                    [_unit] spawn {
                        params ["_unit"];

                        sleep 5;

                        _unit setVariable ["pl_mine_called_out", nil];
                    }
                };

            };
            _damage
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

pl_set_up_single_unit = {
    params ["_unit", "_group"];  
    if ((_unit != player) or !(_unit in switchableUnits)) then {
        _unit unassignItem "Binocular";
        _unit removeWeapon "Binocular";
        _unit unassignItem "Rangefinder";
        _unit removeWeapon "Rangefinder";
    };
    if (_unit getVariable ["pl_special_force", false]) then {
        [_unit] spawn pl_special_forces_skills;
    };
    _unit setVariable ["pl_wia", false];
    _unit setVariable ["pl_unstuck_cd", 0];
    _laodout = getUnitLoadout _unit;
    _unit setVariable ["pl_loadout", _laodout];

    if (_unit getUnitTrait "explosiveSpecialist" and pl_virtual_mines_enabled) then {
        _unit setVariable ["pl_virtual_mines", pl_max_mines_per_explo];
    };

    if (secondaryWeapon _unit != "") then {
        _launcher = secondaryWeapon _unit;
        _missile = (getArray (configFile >> "CfgWeapons" >> (secondaryWeapon _unit) >> "magazines")) select 0;
        _unit setVariable ["pl_sec_weapon", [_launcher, _missile]];
    };
    
    if (pl_auto_crouch_enabled) then {
        [_unit] spawn pl_auto_crouch;
    };

    if (pl_fire_indicator_enabled) then {
        [_unit] call pl_add_unit_fire_indicator;
    };

    if (pl_enabled_medical) then {
        [_unit] call pl_medical_setup; 
    }; 
};

pl_active_opfor_vic_grps = [];

pl_ai_setUp_loop = {
    while {pl_hc_active} do {
        {
            if (side _x isEqualTo playerSide) then {
                [_x] spawn pl_vehicle_setup;
                [group (driver _x)] spawn pl_change_to_vic_symbols;
            }
            else
            {
                if (([(side _x), playerside] call BIS_fnc_sideIsEnemy) and side _x != civilian) then {
                    if (pl_opfor_enhanced_ai) then {
                        if !((group (driver _x)) getVariable ["pl_opfor_ai_enabled", false]) then {
                            (group (driver _x)) execFSM "Plmod\fsm\pl_opfor_cmd_vic_2.fsm";
                            pl_active_opfor_vic_grps pushback (group (driver _x));
                            (group (driver _x)) setVariable ["pl_opfor_ai_enabled", true];
                        };
                    };
                };
            };
        } forEach vehicles;

        {
            if (side _x isEqualTo playerSide) then {

                if (isNil {_x getVariable "spotRepEnabled"}) then {
                    [_x] spawn pl_share_info;
                };
                
                if (hcLeader _x isEqualTo player) then {
                    if (isNil {(leader _x) getVariable "PlContactRepEnabled"}) then {
                        [_x, false] spawn pl_contact_report;
                    };
                    if !(_x getVariable ["aiSetUp", false]) then {
                        [_x] call pl_set_up_ai;
                    };
                    // unit Reset loop
                    {
                        if (!((lifeState _x) isEqualTo "INCAPACITATED") and alive _x) then {
                            
                            // limping escape
                            _x setHit ["legs", 0];

                            [_x] call pl_auto_unstuck;
                            if (_x getVariable "pl_wia") then {
                                _x setVariable ["pl_wia", false];
                            };
                        };
                    } forEach (units _x);
                };
            };

            if (([(side _x), playerside] call BIS_fnc_sideIsEnemy) and side _x != civilian) then {
                
                if (pl_opfor_info_share_enabled) then {
                    if (isNil {_x getVariable "spotRepEnabled"}) then {
                        [_x] spawn pl_share_info_opfor;
                    };
                };

                if (pl_opfor_enhanced_ai) then {
                    if (!(_x getVariable ["pl_opfor_ai_enabled", false]) and !(_x in pl_active_opfor_vic_grps)) then {
                        _x setVariable ["pl_opfor_ai_enabled", true];
                        _x execFSM "Plmod\fsm\pl_opfor_cmd_inf_2.fsm";
                        [_x] spawn pl_opfor_auto_unstuck;
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
        sleep 35;
    };
};



pl_auto_unstuck = {
    params ["_unit"];

    // _distance = _unit distance2D leader (group _unit);
    // if (_distance > 100 and _unit checkAIFeature "PATH" and !(_unit getVariable ["pl_engaging", false])) then {
    //     doStop _unit;
    //     _pos = (getPos _unit) findEmptyPosition [2, 50, typeOf _unit];
    //     _unit setPos _pos;
    //     _unit doFollow leader (group _unit);
    //     _unit switchMove "";
    //     if ([getPos _unit] call pl_is_indoor) then {
    //         _b = nearestBuilding (getPos _unit);
    //         _unit disableCollisionWith _b;
    //         [_unit, _b] spawn {
    //             sleep 15;
    //             (_this#0) enableCollisionWith (_this#1);
    //         };
    //     };
    // };
};

pl_vehicle_tree_stuck_fix = {
    params ["_vic"];

    while {alive _vic} do {
        if ((currentCommand _vic isEqualTo "MOVE" or ((group (driver _vic)) getVariable ["pl_on_march", false])) and (speed _vic) < 2) then {
            {
                _x setDamage 1;
            } forEach (nearestTerrainObjects [getPos _vic, ["TREE", "SMALL TREE", "BUSH"], 8, false, true]);
        };
        sleep 10;
    };
};

pl_vehicle_unstuck = {
    params ["_group"];
    private ["_vic"];
    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _type = typeOf _vic;
        _pos = (getPos _vic) findEmptyPosition [0, 20, _type];
        _vic setVehiclePosition [_pos, [], 0, "NONE"];
    }
    else
    {
        {
            _type = typeOf _x;
            _pos = (getPos _x) findEmptyPosition [0, 20, _type];
            _x setVehiclePosition [_pos, [], 0, "NONE"];
            _x switchMove "";
        } forEach (units _group);
    };
};


pl_vehicle_unstuck_to_pos = {
    params [["_group", (hcSelected player)#0]];
    private ["_vic", "_cords", "_mPos"];
    if (vehicle (leader _group) != leader _group) then {

        _vic = vehicle (leader _group);
        _type = typeOf _vic;

        if (visibleMap or !(isNull findDisplay 2000)) then {
            hintSilent "";
            hint "Select Unstuck position on MAP (SHIFT + LMB to cancel)";
            pl_show_obstacles = true;
            pl_show_obstacles_pos = getPos (leader _group);

            private _rangelimiter = 20;

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
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };
            };
            pl_mapClicked = false;
            if (pl_cancel_strike) exitWith {
                pl_show_obstacles = false;
                pl_mapClicked = false;
            };

            _cords = _mPos;
            deleteMarker _markerBorderName;
            pl_show_obstacles = false;
            pl_mapClicked = false;
        }
        else
        {
            _cords = screenToWorld [0.5, 0.5];
            _rangelimiter = 20;
            if (_cords distance2D (getpos (leader _group))) > _rangelimiter then {
                hint "Out of Range";
            };
        };

        if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

        _vic setVehiclePosition [_cords, [], 0, "NONE"];
    }
    else
    {
        hint "Only for Vehicles";
    };
};


pl_force_road = {
    {
        if (vehicle (leader _x) != leader _x) then {
            _vic = vehicle (leader _x);

            if (_vic getVariable ["pl_force_road", false]) then {
                _vic forceFollowRoad false;
                _vic setVariable ["pl_force_road", nil];
            } else {
                _vic forceFollowRoad true;
                _vic setVariable ["pl_force_road", true];
            };

        };
    } forEach (hcSelected player);  
};

pl_vehicle_soft_unstuck = {
    params ["_vic"];
    _pos = (getPos _vic) getPos [0.2, getDir _vic];
    _vic setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];
};

pl_reset_group = {
    params ["_group"];


    if (vehicle (leader _group) == leader _group) then {
        {
            if !(_x isEqualTo player) then{
                _x spawn pl_reset_unit;
            };
        } forEach (units _group);
    } else {
        _vic = vehicle (leader _group);
        [_vic] call pl_reset_vic;
    };

    _groupId = groupId _group;
    _groupComp = _group getVariable "pl_group_comp";
    _newGroup = createGroup playerside;
    _newGroup setVariable ["pl_is_reset", true];
    _newGroup setVariable ["pl_set_as_medical", _group getVariable ["pl_set_as_medical", false]];

    sleep 1.5;

    { 
        [_x] joinSilent _newGroup;
    } forEach (units _group);

    [_newGroup] spawn pl_set_up_ai;
    _newGroup setVariable ["pl_group_comp", _groupComp];
    deleteGroup _group;

    _newGroup setGroupId [_groupId];
    player hcSetGroup [_newGroup];
    [_newGroup] call pl_change_inf_icons;
};


pl_reset_unit = {
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
    _bleedoutTime = _unit getVariable ["pl_bleedout_time", pl_bleedout_time];
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
            [_newUnit, _bleedoutTime] spawn {
                params ["_newUnit", "_bleedoutTime"];
                sleep 0.1;
                _newUnit setUnconscious true;
                _newUnit setVariable ["pl_bleedout_time", _bleedoutTime];
                sleep 2;
                _newUnit setVariable ["pl_wia", true];
                sleep 1;
                [_newUnit] spawn pl_bleedout;
            };
        };
    };
};

pl_reset_vic = {
    params ["_vic", ["_setPos", []]];

    _animations = "true" configClasses (configFile >> "CfgVehicles" >> typeOf _vic >> "AnimationSources");
    private _appereance = [];

    {
        _s = (str _x) splitString "/";
        _a =  _s select ((count _s) - 1);
        _appereance pushBack [_a, (_vic animationSourcePhase _a)];
    } forEach _animations;

    _w = getWeaponCargo _vic;
    _t = getItemCargo _vic;
    _m = getMagazineCargo _vic;
    _b = getBackpackCargo _vic;
    _vicInv = [_w, _t, _m ,_b];

    _lifes = _vic getVariable ["pl_repair_lifes", 1];
    _varName = vehicleVarName _vic;
    _damage = getDammage _vic;

    private _vars = [];
    {
        _value = _killed getVariable [_x, objNull];
        if !(isNull _value) then {
            _vars pushback [_x, _value];
        };
    } forEach ["pl_line_charges", "pl_bridge_available", "pl_is_supply_vehicle", "pl_supplies", "pl_avaible_reinforcements", "pl_is_repair_vehicle", "pl_repair_supplies", "pl_bridge_available", "pl_is_mine_vic", "pl_virtual_mines", "pl_is_mc_lc_vehicle", "pl_line_charges", "pl_is_eng_apc"];

    _crew = fullCrew _vic;
    _pos = getPosATLVisual _vic;
    _dir = getDir _vic;
    _driver = driver _vic;
    _commander = commander _vic;
    _gunner = gunner _vic;
    _type = typeof _vic;
    hideObject _vic;
    deleteVehicle _vic;

    sleep 0.1;

    private _newVic = createVehicle [_type, _pos, [], 0, "CAN_COLLIDE"];
    // _newVic disableCollisionWith _vic;

    if !(_setPos isEqualTo []) then {
        _newVic setPosATL _setPos;
    } else {
        _newVic setPosATL _pos;
    };
    _newVic setDir _dir;
    _newVic setDamage _damage;

    // {
    //     _newVic animateSource [_x#0, _x#1, true];
    // } forEach _appereance;
    // _newVic setVariable ["pl_appereance", _appereance];
    _newVic setVariable ["pl_appereance", [_newVic] call BIS_fnc_getVehicleCustomization];
    
    {
        _unit = _x#0;
        switch (_x#1) do { 
            case "driver" : {_unit moveindriver _newVic;}; 
            case "gunner" : {_unit moveInGunner _newVic;};
            case "commander" : {_unit moveInCommander _newVic};
            case "cargo" : {_unit moveIncargo [_newVic, _x#2, true]};
            case "turret" : {_unit moveInTurret [_newVic, _x#3]};
            default {_unit moveIncargo _newVic}; 
        };
    } forEach _crew;

    _newVic setVehicleVarName _varName;
    _newVic limitSpeed 50;
    _newVic setVariable ["pl_speed_limit", "50"];
    _newVic setUnloadInCombat [false, false];
    _newVic allowCrewInImmobile true;
    _newVic engineOn true;


    [_vicInv, _newVic] call pl_set_vic_laodout;
    _newVic setVariable ["pl_vic_inv", _vicInv];
    [_newVic] spawn pl_vehicle_tree_stuck_fix;
    [_newVic] spawn pl_auto_vic_speed;
    _newVic setVariable ["pl_repair_lifes", _lifes];

    {
        _newVic setVariable [_x#0, _x#1];
    } forEach _vars;
    
    _newVic addEventHandler ["IncomingMissile", {
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
    
     _newVic addEventHandler ['HandleDamage', {
        params['_unit', '_selName', '_damage', '_source'];
        if ((_unit getVariable "pl_damage_reduction")) then {
            _dmg = _damage * 0.8;
            _damage = _dmg;
        };
        _damage
    }];

    _newVic setVariable ["pl_vehicle_setup_complete", true];
};


pl_spawn_hard_reset = {
    {
        {
            [_x] call pl_reset_unit;
        } forEach (units _x);
        
    } forEach hcSelected player;
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

pl_viv_trans_set_up = {
    params ["_group"];
    _vic = vehicle (leader _group);
    _targetVic = isVehicleCargo _vic;
    _group setVariable ["pl_show_info", false];
    // (group (driver _targetVic)) setVariable ["setSpecial", true];
    // (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
    (group (driver _targetVic)) setVariable ["pl_has_cargo", true];
    {
        // player hcRemoveGroup (group (_x select 0));
        [group (_x select 0)] call pl_hide_group_icon;
    } forEach fullCrew[_vic, "cargo", false];
};

pl_inf_trans_set_up = {
    params ["_group"];
    _targetVic = vehicle (leader _group);
    [_group] call pl_change_inf_icons;
    // (group (driver _targetVic)) setVariable ["setSpecial", true];
    // (group (driver _targetVic)) setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
    (group (driver _targetVic)) setVariable ["pl_has_cargo", true];
    _group setVariable ["onTask", false];
    _group setVariable ["setSpecial", false];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
    _group setVariable ["pl_disembark_finished", false];
    [_group, true] call pl_contact_report;
    // _group setVariable ["pl_show_info", false];
    // {
    //     _x assignAsCargo _targetVic;
    // } forEach (units _group);
    // [units _group] allowGetIn true; //false;
    // if !(_group getVariable ["pl_is_recon", false]) then {
        [_group] call pl_hide_group_icon;
    // } else {
        // [_group, "recon_add_pl"] call pl_change_group_icon;
        // _group setVariable ["pl_show_info", false];
        // player hcRemoveGroup _group;
    // };
    _group addVehicle _targetVic;
    (units _group) orderGetIn true;

};


// player addEventHandler ["GetInMan", {
//     params ["_vehicle", "_role", "_unit", "_turret"];
//     private ["_group"];
//     _group = group player;
//     _vicGroup = group (driver (vehicle player));
//     _vicGroup setVariable ["setSpecial", true];
//     _vicGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
//     player setVariable ["pl_player_vicGroup", _vicGroup];
//     if (_vicGroup != (group player)) then {
//         [_group] call pl_hide_group_icon;
//     };
// }];

// player addEventHandler ["GetOutMan", {
//     params ["_vehicle", "_role", "_unit", "_turret"];
//     private ["_group"];
//     _group = group player;
//     _vicGroup = player getVariable ["pl_player_vicGroup", (group player)];
//     _group setVariable ["setSpecial", false];
//     _group setVariable ["onTask", false];
//     [_group] call pl_show_group_icon;

//     _cargo = fullCrew [(vehicle ((units _vicGroup)#0)), "cargo", false];
//     if (count _cargo == 0) exitWith {
//         _vicGroup setVariable ["setSpecial", false];
//     };
//     if (({(group (_x#0)) isEqualTo _group} count _cargo) > 0) then {
//         [_vicGroup, _cargo, _group] spawn {
//             params ["_vicGroup", "_cargo", "_group"];
//             waitUntil {sleep 1; (({(group (_x#0)) isEqualTo _group} count (fullCrew [(vehicle ((units _vicGroup)#0)), "cargo", false])) == 0)};
//             _vicGroup setVariable ["setSpecial", false];
//         };
//     };
// }];

pl_switch_effective_vic_cmd_action = {
    params ["_target", "_caller", "_actionId", "_arguments"];

    // allows the player to command from a tank commnander position without beeing effective commander of that tank. Allows giving effective command of the vehicle to the AI Gunner or Driver. Player should be in a different group from the crew

    if ((vehicle player) != player) then {
        if (effectiveCommander (vehicle player) == player) then {
            if (gunner (vehicle player) != player) then {
                (vehicle player) setEffectiveCommander (gunner (vehicle player));
                hint "Gunner is Commander"
            } else {
                (vehicle player) setEffectiveCommander (driver (vehicle player));
                hint "Driver is Commander"
            };
        } else {
            if (gunner (vehicle player) != player) then {
                (vehicle player) setEffectiveCommander player;
                hint "Player is Commander"
            };
        };
    } else {
        hint "Only usable inside vehicle"
    };
};


/////////////////// Start Set Up ///////////////////////////
pl_start_set_up = {
    sleep 8;


    

    _hcc = allMissionObjects "HighCommand";
    pl_hc_active = false;
    if (_hcc isEqualto []) then {
        if (pl_enable_hc_default) then {
            _newHcc = (createGroup (sideLogic)) createUnit ["HighCommand", [0, 0, 0], [], 0, "NONE"];
            player synchronizeObjectsAdd [_newHcc];
            pl_hc_active = true;
            hcShowBar true;
            sleep 1;
        };
    }
    else
    {
        pl_hc_active = true;
        hcShowBar true;
    };

    if ((vehicle player) != player) then {
        _commander = leader (group driver (vehicle player));
        (vehicle player) setEffectiveCommander _commander;
        if ((date#0) > 2010) then {
            (vehicle player) addAction ["Use UAV-Terminal", {[] spawn pl_add_uav_terminal}];
        };
    };

    sleep 2;

    if (pl_hc_active) then {

        if (pl_opfor_enhanced_ai) then {[] execFSM "Plmod\fsm\pl_opfor_cmd_commander.fsm"};
        [group player] call pl_set_up_ai;

        // player addAction
        //     [
        //         "Switch Vehicle Command",
        //         {
        //             [] call pl_switch_effective_vic_cmd_action;
        //         },
        //         "(vehicle player) != player"
        //     ];

        [] spawn pl_ai_setUp_loop;

        sleep 2;

        // sleep 0.1;
        if (((vehicle player) != player) and (group (driver (vehicle player)) != (group player))) then {
            [group player] call pl_inf_trans_set_up;
        };

        {
            _leader = leader _x;
            // private _hcs = allMissionObjects "HighCommandSubordinate" select 0;
            // if (isNil{_hcs}) exitWith {};

            // if !((_x getVariable ["pl_custom_icon", ""]) isEqualTo "") then {
            //     [_x] call pl_show_group_icon;
            // };

            // sleep 0.1;
            if ((vehicle _leader) != _leader) then {
                private _vic = vehicle _leader;
                if ((((assignedVehicleRole _leader) select 0) isEqualTo "cargo" or ((assignedVehicleRole _leader) select 0) isEqualTo "turret") and _leader != commander _vic and _leader != gunner _vic) then {
                    if (group (driver (vehicle _leader)) != _x) then {
                        [_x] call pl_inf_trans_set_up;
                    };
                    // [_x, true] spawn pl_contact_report;
                } else {
                    [_x] spawn pl_reset;
                };
                if !(isNull (isVehicleCargo (vehicle _leader))) then {
                    [_x] call pl_viv_trans_set_up;
                    // [_x, true] spawn pl_contact_report;
                };
                // if ((vehicle _leader) isKindOf "Air" and pl_enable_auto_air_remove) then {
                //     player hcRemoveGroup _x;
                // };
            } else {
                [_x] call pl_change_inf_icons;
                [_x] spawn pl_reset;
            };

            sleep 0.2;

            if (_x getVariable ["pl_is_recon", false]) then {
                [_x, true] spawn pl_recon;
            };

        } forEach (allGroups select {side _x isEqualTo playerSide and hcLeader _x == player});





    };

    sleep 1;

    systemChat "Platoon Leader Started";
};

[] spawn pl_start_set_up;


// [spec1] spawn pl_special_forces_skills;


// SOPs
// def pos on contact --> on contact Report (reset contact on new order)
// def Pos on Idle (360) -- performance?
// attack on contact --> on contact report
// disengage on contact --> on contact report
// dismount when under AT fire --> on IncominfMissle
// stop when under AT fire --> on IncominfMissle
// auto disengage (attack, def) OK
    // set Breakingpoint % <100 , <75, <50

//static deploy OK
// auto medic/revive OK
// Auto at defence OK
// auto defence suppress OK
// auto defence supply OK

//auto formation OK
//auto speed OK




