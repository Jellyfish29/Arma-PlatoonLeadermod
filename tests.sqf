pl_at_targets_indicator = [];
pl_fire_indicator_enabled = true;

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
                            if (pl_enable_beep_sound) then {playSound "beep"};
                            if (pl_enable_chat_radio) then (_unit sideChat format ["%1: Engaging Ground Targets", _callsign]);
                                if (pl_enable_map_radio) then ([group _unit, "...Engaging Ground Targets!", 15] call pl_map_radio_callout);
                        }
                        else
                        {
                            if (pl_enable_beep_sound) then {playSound "beep"};
                            if (pl_enable_chat_radio) then (_unit sideChat format ["%1: Engaging Enemies", _callsign]);
                            if (pl_enable_map_radio) then ([group _unit, "...Contact!", 15] call pl_map_radio_callout);
                        };
                        [_unit] spawn pl_contact_info_share;
                        (group _unit) setVariable ['inContact', true];
                };
                (group _unit) setVariable ["PlContactTime", (time + 60)];
                // if ("launch" in (_weapon splitString "_")) then {
                if ((secondaryWeapon _firer) isEqualTo _weapon) then {
                    if (pl_At_fire_report_cd < time) then {
                        pl_At_fire_report_cd = time + 5;
                        _callsign = groupId (group _unit);
                        if (pl_enable_chat_radio) then (_unit sideChat format ["%1: Engaging Vehicles with AT", _callsign]);
                        if (pl_enable_map_radio) then ([group _unit, "...Engaging Vehicle!", 15] call pl_map_radio_callout);
                    };

                    if (pl_fire_indicator_enabled) then {
                        _target = assignedTarget _firer;
                        if !(isNull _target) then {
                            [_firer, _target] spawn {
                                params ["_firer", "_target"];
                                _firerPos = getPos _firer;
                                _targetPos = getPos _target;
                                pl_at_targets_indicator pushBack [_firerPos, _targetPos];

                                sleep 5;

                                pl_at_targets_indicator = pl_at_targets_indicator - [[_firerPos, _targetPos]];
                            };
                        };
                    };
                };

                if (pl_fire_indicator_enabled and ((vehicle _firer) isKindOf "Tank" or (vehicle _firer) isKindOf "Car")) then {
                    _target = assignedTarget _firer;
                    if (!(isNull _target) and !(_firer getVariable ["pl_fire_indicator_on", false])) then {
                        [_firer, _target] spawn {
                            params ["_firer", "_target"];
                            _firerPos = getPos _firer;
                            _targetPos = getPos _target;
                            pl_at_targets_indicator pushBack [_firerPos, _targetPos];
                            _firer setVariable ["pl_fire_indicator_on", true];

                            sleep 3;

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
    };
};

[g1, false] call pl_contact_report;
[g2, false] call pl_contact_report;
[g3, false] call pl_contact_report;




pl_draw_at_targets_indicator = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _pos1 = _x#0;
                    _pos2 = _x#1;
                    _display drawIcon [
                        '\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa',
                        [0.92,0.24,0.07,1],
                        _pos2,
                        15,
                        15,
                        0,
                        '',
                        2
                    ];

                    _display drawArrow [
                        _pos1,
                        _pos2,
                        [0.92,0.24,0.07,1]
                    ];

            } forEach pl_at_targets_indicator;
    "]; // "
};

[] call pl_draw_at_targets_indicator;