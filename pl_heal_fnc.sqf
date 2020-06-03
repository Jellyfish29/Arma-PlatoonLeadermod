// sleep 1;
if !(pl_enabled_medical) exitWith {};

pl_ccp_set = false;
pl_medic_cls_names = ["B_medic_F", "B_recon_medic_F", "B_T_Recon_medic_F", "B_W_Medic_F", "O_medic_F", "O_recon_medic_F", "O_T_medic_F", "O_T_Recon_medic_F", "I_medic_F", "I_E_medic_F",
                      "rhsusf_army_ocp_medic", "rhsusf_army_ocp_arb_medic", "rhsusf_army_ucp_medic", "rhsusf_army_ucp_arb_medic", "rhsusf_socom_marsoc_sarc", "rhsusf_navy_marpat_d_medic",
                      "rhsusf_navy_marpat_wd_medic"];

pl_medic_heal = {
    params ["_medic", "_target", "_ccpPos"];
    _healPos = (getPos _target) findEmptyPosition [0, 40];
    _moveToPos = {
        params ["_unit", "_pos", "_isMedic", "_secUnit"];
        _unit disableAI "AUTOCOMBAT";
        _unit doMove _pos;
        sleep 2;
        if (_isMedic) then {
            waitUntil {sleep 0.1; (_unit distance2D _pos < 2) or (unitReady _unit) or (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or (_unit getVariable ["pl_wia", false]) or (!alive _secUnit) or (_secUnit getVariable ["pl_wia", false])};
        }
        else
        {
            waitUntil {sleep 0.1; (_unit distance2D _pos < 2) or (unitReady _unit) or (!alive _unit) or (_unit getVariable ["pl_wia", false]) or (!alive _secUnit) or (_secUnit getVariable ["pl_wia", false]) or !((group _secUnit) getVariable ["onTask", true])};
        };
        doStop _unit;
        _unit disableAI "PATH";
        _unit setUnitPos "MIDDLE";
    };
    if (_target == player) then {
        _h1 = [_medic, _healPos, true, player] spawn _moveToPos;
        _medic sideChat "Hold Position Sir, Help is on the Way!";
        // Idicator for player at _healPos
        waitUntil {(scriptDone _h1) or !((group _medic) getVariable "onTask")};
    }
    else
    {
        _h1 = [_medic, _healPos, true, _target] spawn _moveToPos;
        _h2 = [_target, _healPos, false, _medic] spawn _moveToPos;
        _time = time + 25;
        waitUntil {sleep 0.1; ((scriptDone _h1) and (scriptDone _h2)) or !((group _medic) getVariable ["onTask", true]) or (time >= _time)};
    };
    if ((!alive _target) or (_target getVariable "pl_wia")) exitWith {
        _medic enableAI "PATH";
        _medic enableAI "AUTOCOMBAT";
        _medic setUnitPos "AUTO";
        _medic doFollow leader (group _medic);
    };
    if ((!alive _medic) or (_medic getVariable ["pl_wia", false])) exitWith {(group _medic) setVariable ["onTask", false]};
    if (_medic distance2D _target < 3) then {
        _medic playAction "MedicOther";
        sleep 6;
        _target setDamage 0;
    };
    _medic enableAI "PATH";
    _medic enableAI "AUTOCOMBAT";
    _target enableAI "PATH";
    _target enableAI "AUTOCOMBAT";
    _medic setUnitPos "AUTO";
    _target setUnitPos "AUTO";
    if (isNil "_ccpPos") then {
        _medic doFollow leader (group _medic);
    }
    else
    {
        _medic doMove _ccpPos;
    };
    _target doFollow leader (group _target);
};



pl_heal_group = {
    params ["_group"];
    private ["_medic", "_healTarget", "_escort"];

    _group setVariable ["onTask", false];
    sleep 0.25;

    // _medic = ((units _group) select {(typeOf _x) in pl_medic_cls_names}) select 0;
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {
            _medic = _x;
        };
    } forEach (units _group);
    // _escort = nil;
    if !(isNil "_medic") then {
        if !(_medic getVariable "pl_wia") then {
            {
                doStop _x;
            } forEach (units _group);
            _group setVariable ["onTask", true];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"];
            _medic setVariable ["pl_is_ccp_medic", true];
            while {(_group getVariable "onTask")} do {
                if (_group isEqualTo grpNull) exitWith {};
                // _reviveTargets = (getPos leader _group) nearObjects ["Man", 50];
                {
                    if (lifeState _x isEqualTo "INCAPACITATED" and !(_x getVariable "pl_beeing_treatet")) then {
                        _h1 = [_group, _medic, nil, _x, getPos (leader _group), 50] spawn pl_ccp_revive_action;
                        waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])}
                    };
                } forEach (units _group);
                sleep 2;
                {
                    if ((damage _x > 0.1) and (alive _x) and !(_x getVariable "pl_wia")) then {
                        _h1 = [_medic, _x, nil] spawn pl_medic_heal;
                        waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])}
                    };
                } forEach (units _group);
            };
            _medic setVariable ["pl_is_ccp_medic", false];
        }
        else
        {
            playSound "beep";
            leader _group sideChat "Negativ, Our Medic is Wounded, over";
        };
    }
    else
    {
        playSound "beep";
        leader _group sideChat "Negativ, Our Medic is K.I.A, over";
    };
};

pl_spawn_heal_group = {
    {
        [_x] spawn pl_heal_group;
    } forEach hcSelected player;
};

pl_wia_callout = {
    params ["_unit"];
    sleep 3;
    _unit setVariable ["pl_wia_calledout", true];
    sleep 3;
    _unit setVariable ["pl_wia", true];
    if (alive _unit and (_unit getVariable "pl_wia_calledout")) then {
        _unit setVariable ["pl_wia_calledout", false];
        // _unitMos = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName");
        // leader (group _unit) sideChat format ["%1 is W.I.A, requesting Medic, over", _unitMos];
        playSound "beep";
        leader (group _unit) sideChat "We have a Casualty, over"
    };
};

pl_bleedout = {
    params ["_unit"];
    sleep 10;
    if (alive _unit and !(_unit getVariable "pl_bleedout_set")) then {
        _unit setVariable ["pl_bleedout_set", true];
        _time = _unit getVariable ["pl_bleedout_time", 300];
        _deathTime = time + _time;
        waitUntil {sleep 1; time > _deathTime};
        if (_unit getVariable "pl_wia") then {
            _unit setDamage 1;
        };
        if (alive _unit) then {
            _unit setVariable ["pl_bleedout_time", 300];
        };
    };
};

pl_ccp_revive_action = {
    params ["_group", "_medic", "_escort", "_healTarget", "_ccpPos", "_reviveTime"];
    _healTarget setVariable ["pl_beeing_treatet", true];
    _medic disableAI "AUTOCOMBAT";
    _medic disableAI "AUTOTARGET";
    _medic disableAI "TARGET";
    _medic enableAI "PATH";
    doStop _medic;
    _medic doMove (getPos _healTarget);
    if !(isNil "_escort") then {
        _escort disableAI "AUTOCOMBAT";
        _escort enableAI "PATH";
        _escort doMove ((getPos _healTarget) findEmptyPosition [8, 25]);
    };
    waitUntil {sleep 0.1; unitReady _medic or !(_group getVariable ["onTask", true]) or (!alive _healTarget) or (!alive _medic) or (_medic getVariable ["pl_wia", false])};
    // Animation
    if (_group getVariable "onTask" and (alive _healTarget) and (alive _medic) and !(_medic getVariable "pl_wia")) then {
        // _medic setUnitPos "MIDDLE";
        sleep 0.1;
        _reviveTime = time + _reviveTime;
        _medic attachTo [_healTarget, [0.6,0.2,0]];
        _medic setDir -90;
        _medic playAction "medicStart";
        _medic disableAI "ANIM";
        sleep 2;
        _medic switchMove "AinvPknlMstpSnonWrflDnon_medic3";
        waitUntil {
            sleep 5;
            _medic switchMove selectRandom ["AinvPknlMstpSnonWrflDnon_medic3", "AinvPknlMstpSnonWrflDnon_medic2", "AinvPknlMstpSnonWrflDnon_medic1", "AinvPknlMstpSnonWrflDnon_medic4"];
            (time > _reviveTime) or !(_group getVariable ["onTask", true]);
         };
        detach _medic;
        _medic playAction "medicStop";
        sleep 2;
        _medic enableAI "ANIM";
    }
    else
    {
        _healTarget setVariable ["pl_beeing_treatet", false];
    };
    _medic setUnitPos "AUTO";
    if (_group getVariable "onTask" and (alive _medic) and !(_medic getVariable "pl_wia")) then {
        _healTarget setUnconscious false;
        _healTarget setDamage 0;
        _healTarget setUnitPos "AUTO";
        _healTarget enableAI "PATH";
        _healTarget setVariable ["pl_wia", false];
        _healTarget setVariable ["pl_wia_calledout", false];
        _healTarget setVariable ["pl_beeing_treatet", false];
        _medic doMove _ccpPos;
        if !(isNil "_escort") then {
            _escort enableAI "AUTOCOMBAT";
            _escort doMove _ccpPos;
        };
    }
    else
    {
        _healTarget setVariable ["pl_beeing_treatet", false];
    };
};

pl_ccp = {
    private ["_medic", "_healTarget", "_escort", "_group", "_ccpPos"];

    _group = hcSelected player select 0;

    if (_group != (group player)) exitWith {
        playSound "beep";
        (leader _group) sideChat "Negativ, only the Platoon Medic can set up the CCP, over";
    };
    _group setVariable ["onTask", false];
    sleep 0.25;

    // _medic = ((units _group) select {(typeOf _x) in pl_medic_cls_names}) select 0;
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {
            _medic = _x;
        };
    } forEach (units _group);
    _escort = nil;
    if !(isNil "_medic") then {
        if !(_medic getVariable "pl_wia") then {
            if !(pl_ccp_set) then {
                pl_ccp_set = true;
                for "_i" from count waypoints _group - 1 to 0 step -1 do{
                    deleteWaypoint [_group, _i];
                };
                {
                    doStop _x;
                } forEach (units _group);
                if (count (units _group) > 2) then {
                    {
                        if (_x != _medic and _x != (leader _group) and !(_x getVariable "pl_wia") and (alive _x)) exitWith {
                            _escort = _x;
                        };
                    } forEach (units _group);
                };
                _group setVariable ["onTask", true];
                _group setVariable ["setSpecial", true];
                _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"];
                _ccpGuard = (units _group) - [_medic];
                if !(isNil "_escort") then {
                    _escort setVariable ["pl_is_ccp_medic", true];
                   _ccpGuard = _ccpGuard - [_escort]
                };
                {
                    [_x, getPos leader _group, getDir leader _group, 20, false] spawn pl_find_cover;
                } forEach _ccpGuard;

                _medic setVariable ["pl_damage_reduction", true];
                _medic setVariable ["pl_is_ccp_medic", true];

                createMarker ["ccp_area_marker", getPos (leader _group)];
                "ccp_area_marker" setMarkerShape "ELLIPSE";
                "ccp_area_marker" setMarkerBrush "DiagGrid";
                "ccp_area_marker" setMarkerColor "colorBLUFOR";
                "ccp_area_marker" setMarkerAlpha 0.4;
                "ccp_area_marker" setMarkerSize [150, 150];

                createMarker ["ccp_inner_area_marker", getPos (leader _group)];
                "ccp_inner_area_marker" setMarkerShape "ELLIPSE";
                "ccp_inner_area_marker" setMarkerBrush "DiagGrid";
                "ccp_inner_area_marker" setMarkerColor "colorGreen";
                "ccp_inner_area_marker" setMarkerAlpha 0.4;
                "ccp_inner_area_marker" setMarkerSize [25, 25];

                createMarker ["ccp_marker", getPos (leader _group)];
                "ccp_marker" setMarkerType "marker_CCP";
                "ccp_marker" setMarkerColor "colorBLUFOR";

                _ccpPos = getPos (leader _group);

                while {(_group getVariable "onTask") and (alive _medic) and !(_medic getVariable "pl_wia")} do {
                    _reviveTargets = _ccpPos nearObjects ["Man", 150];
                    _healTargets = _ccpPos nearObjects ["Man", 25];
                    {
                        if (lifeState _x isEqualTo "INCAPACITATED" and !(_x getVariable "pl_beeing_treatet")) then {
                            if !(isNil "_escort") then {
                                _h1 = [_group, _medic, _escort, _x, _ccpPos, 10] spawn pl_ccp_revive_action;
                                waitUntil {sleep 0.1; (scriptDone _h1) or !(_group getVariable ["onTask", true])};
                            }
                            else
                            {
                                _h1 = [_group, _medic, nil, _x, _ccpPos, 10] spawn pl_ccp_revive_action;
                                waitUntil {sleep 0.1; (scriptDone _h1) or !(_group getVariable ["onTask", true])};
                            };
                        };
                    } forEach _reviveTargets;
                    {
                        if ((damage _x > 0) and (alive _x) and !(_x getVariable "pl_wia")) then {
                            _h2 = [_medic, _x, _ccpPos] spawn pl_medic_heal;
                            _time = time + 30;
                            waitUntil {sleep 0.1; scriptDone _h2 or !(_group getVariable ["onTask", true]) or (time > _time)}
                        };
                    } forEach _healTargets;
                    _medic enableAI "AUTOCOMBAT";
                    _medic enableAI "AUTOTARGET";
                    _medic enableAI "TARGET";
                    sleep 2;
                };
                pl_ccp_set = false;
                _group setVariable ["setSpecial", false];
                _group setVariable ["onTask", false];
                _medic setVariable ["pl_damage_reduction", false];
                _medic setVariable ["pl_is_ccp_medic", false];
                if !(isNil "_escort") then {
                    _escort setVariable ["pl_is_ccp_medic", false];
                };
                deleteMarker "ccp_marker";
                deleteMarker "ccp_area_marker";
                deleteMarker "ccp_inner_area_marker";
            }
            else
            {
                playSound "beep";
                leader _group sideChat "Negativ, Our Platoon already has a CCP, over";
            };
        }
        else
        {
            playSound "beep";
            leader _group sideChat "Negativ, Our Medic is Wounded, over";
        };
    }
    else
    {
        playSound "beep";
        leader _group sideChat "Negativ, Our Medic is K.I.A, over";
    };
};
