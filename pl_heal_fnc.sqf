sleep 1;
if !(pl_enabled_medical) exitWith {};

pl_ccp_set = false;
pl_medic_cls_names = ["B_medic_F", "B_recon_medic_F", "B_T_Recon_medic_F", "B_W_Medic_F", "O_medic_F", "O_recon_medic_F", "O_T_medic_F", "O_T_Recon_medic_F", "I_medic_F", "I_E_medic_F",
                      "rhsusf_army_ocp_medic", "rhsusf_army_ocp_arb_medic", "rhsusf_army_ucp_medic", "rhsusf_army_ucp_arb_medic", "rhsusf_socom_marsoc_sarc", "rhsusf_navy_marpat_d_medic",
                      "rhsusf_navy_marpat_wd_medic"];

pl_ccp_heal_range = 50;
pl_ccp_revive_range = 200;

pl_medic_heal = {
    params ["_medic", "_target", "_ccpPos"];
    _healPos = (getPos _target) findEmptyPosition [0, 40];
    _moveToPos = {
        params ["_unit", "_pos", "_isMedic", "_secUnit"];
        _unit disableAI "AUTOCOMBAT";
        _unit doMove _pos;
        _unit moveTo _pos;
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
        _time = time + 20;
        waitUntil {sleep 0.1; ((scriptDone _h1) and (scriptDone _h2)) or !((group _medic) getVariable ["onTask", true]) or (time >= _time)};
    };
    if ((!alive _target) or (_target getVariable "pl_wia")) exitWith {
        _medic enableAI "PATH";
        // _medic enableAI "AUTOCOMBAT";
        _medic setUnitPos "AUTO";
        _medic doFollow leader (group _medic);
    };
    if ((!alive _medic) or (_medic getVariable ["pl_wia", false])) exitWith {(group _medic) setVariable ["onTask", false]};
    if (_medic distance2D _target < 3) then {
        _medic playAction "MedicOther";
        sleep 6;
        _target setDamage 0;
        _target setVariable ["pl_injured", false];
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
        _medic moveTo _ccpPos;
    };
    _target doFollow leader (group _target);
};



pl_heal_group = {
    params ["_group"];
    private ["_medic", "_healTarget", "_escort"];

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    // _medic = ((units _group) select {(typeOf _x) in pl_medic_cls_names}) select 0;
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {
            _medic = _x;
        };
    } forEach (units _group);
    // _escort = nil;
    if !(isNil "_medic") then {
        if !(_medic getVariable "pl_wia") then {

            [_group] call pl_reset;
            sleep 0.2;

            playSound "beep";

            _group setVariable ["onTask", true];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"];
            _medic setVariable ["pl_is_ccp_medic", true];
            // _medic disableAI "FSM";
            _medic disableAI "AUTOCOMBAT";
            sleep 2;
            while {(_group getVariable "onTask")} do {
                // if (_group isEqualTo grpNull) exitWith {};
                // _reviveTargets = (getPos leader _group) nearObjects ["Man", 50];
                {
                    if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                        _h1 = [_group, _medic, nil, _x, getPos (leader _group), 50] spawn pl_ccp_revive_action;
                        waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])}
                    };
                } forEach ((units _group) select {_x getVariable ["pl_wia", false]});;
                // _medic sideChat "Tick";
                {
                    if ((_x getVariable "pl_injured") and (alive _x) and !(_x getVariable "pl_wia") and !(lifeState _x isEqualTo "INCAPACITATED")) then {
                        _h1 = [_medic, _x, nil] spawn pl_medic_heal;
                        waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])}
                    };
                } forEach (units _group);
                sleep 1;
            };

            sleep 1;

            _medic setVariable ["pl_is_ccp_medic", false];
        }
        else
        {
            // playSound "beep";
            hint "Medic is wounded!";
        };
    }
    else
    {
        // playSound "beep";
        hint "Medic is Kia!";
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
        _unitMos = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName");
        // leader (group _unit) sideChat format ["%1 is W.I.A, requesting Medic, over", _unitMos];
        playSound "beep";
        leader (group _unit) sideChat format ["%1: %2 WOUNDED", groupId (group _unit), _unitMos];
    };
};

pl_bleedout = {
    params ["_unit"];
    sleep 5;
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
    // player sideChat str (alive _healTarget);
    _healTarget setVariable ["pl_beeing_treatet", true];
    _medic disableAI "AUTOCOMBAT";
    _medic disableAI "AUTOTARGET";
    _medic disableAI "TARGET";
    // _medic disableAI "FSM";
    _medic enableAI "PATH";
    doStop _medic;
    _medic doMove (getPos _healTarget);
    _medic moveTo (getPos _healTarget);
    if !(isNil "_escort") then {
        _escort disableAI "AUTOCOMBAT";
        _escort enableAI "PATH";
        _escort doMove ((getPos _healTarget) findEmptyPosition [3, 40]);
        _escort moveTo ((getPos _healTarget) findEmptyPosition [3, 40]);

    };
    waitUntil {(unitReady _medic) or ((_medic distance2D _healTarget) < 2) or !(_group getVariable ["onTask", true]) or (!alive _healTarget) or (!alive _medic) or (_medic getVariable ["pl_wia", false])};
    // Animation
    if (_group getVariable ["onTask", true] and (alive _healTarget) and (alive _medic) and !(_medic getVariable ["pl_wia", false])) then {
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
        if !(_group getVariable ["onTask", true]) then {
            _healTarget setVariable ["pl_beeing_treatet", false];
        }
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
        _healtarget setVariable ["pl_injured", false];
        _healTarget setVariable ["pl_wia_calledout", false];
        _healTarget setVariable ["pl_beeing_treatet", false];
        _healTarget setVariable ["pl_bleedout_set", false];
        _medic doMove _ccpPos;
        _medic moveTo _ccpPos;
        if !(isNil "_escort") then {
            _escort enableAI "AUTOCOMBAT";
            _escort doMove _ccpPos;
            _escort moveTo _ccpPos;
        };
    }
    else
    {
        _healTarget setVariable ["pl_beeing_treatet", false];
    };
};

pl_ccp = {
    params [["_group", hcSelected player select 0], ["_isMedevac", false], ["_escort", nil]];
    private ["_medic", "_healTarget", "_escort", "_group", "_ccpPos", "_markerNameOuter", "_markerNameInner", "_markerNameCCP"];

    // _group = hcSelected player select 0;
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    if (_group != (group player) and !(_isMedevac)) exitWith {
        // playSound "beep";
        hint "Only the Player Group can set up the CCP";
    };
    

    // _medic = ((units _group) select {(typeOf _x) in pl_medic_cls_names}) select 0;
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {
            _medic = _x;
        };
    } forEach (units _group);
    // _escort = nil;
    // player sideChat "erstens is da";
    if !(isNil "_medic") then {
        // player sideChat "Medic is da";
        if !(_medic getVariable ["pl_wia", false]) then {

            [_group] call pl_reset;
            sleep 0.2;

            playSound "beep";

            if (count (units _group) > 2) then {
                {
                    if (_x != _medic and _x != (leader _group) and !(_x getVariable "pl_wia") and (alive _x)) exitWith {
                        _escort = _x;
                    };
                } forEach (units _group);
            };
            _group setVariable ["onTask", true];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", "\Plmod\gfx\CCP.paa"];
            _ccpGuard = (units _group) - [_medic];
            if !(isNil "_escort") then {
                _escort setVariable ["pl_is_ccp_medic", true];
               _ccpGuard = _ccpGuard - [_escort]
            };
            // {
            //     [_x, getPos leader _group, getDir leader _group, 20, false] spawn pl_find_cover;
            // } forEach _ccpGuard;

            _medic setVariable ["pl_damage_reduction", true];
            _medic setVariable ["pl_is_ccp_medic", true];

            _markerNameOuter = str (random 2);
            createMarker [_markerNameOuter, getPos (leader _group)];
            _markerNameOuter setMarkerShape "ELLIPSE";
            _markerNameOuter setMarkerBrush "DiagGrid";
            _markerNameOuter setMarkerColor "colorBLUFOR";
            _markerNameOuter setMarkerAlpha 0.4;
            _markerNameOuter setMarkerSize [pl_ccp_revive_range, pl_ccp_revive_range];

            _markerNameInner = str (random 2);
            createMarker [_markerNameInner, getPos (leader _group)];
            _markerNameInner setMarkerShape "ELLIPSE";
            _markerNameInner setMarkerBrush "DiagGrid";
            _markerNameInner setMarkerColor "colorGreen";
            _markerNameInner setMarkerAlpha 0.4;
            _markerNameInner setMarkerSize [pl_ccp_heal_range, pl_ccp_heal_range];

            _markerNameCCP = str (random 3);
            createMarker [_markerNameCCP, getPos (leader _group)];
            _markerNameCCP setMarkerType "marker_CCP";
            _markerNameCCP setMarkerColor "colorBLUFOR";

            _ccpPos = getPos (leader _group);

            sleep 1;

            while {(_group getVariable ["onTask", true]) and (alive _medic) and !(_medic getVariable ["pl_wia", false])} do {
                // player sideChat "Loop is da";
                _reviveTargets = _ccpPos nearObjects ["Man", pl_ccp_revive_range];
                _healTargets = _ccpPos nearObjects ["Man", pl_ccp_heal_range];
                {
                    if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                        if !(isNil "_escort") then {
                            _h1 = [_group, _medic, _escort, _x, _ccpPos, 10] spawn pl_ccp_revive_action;
                            waitUntil {(scriptDone _h1) or !(_group getVariable ["onTask", true])};
                        }
                        else
                        {
                            _h1 = [_group, _medic, nil, _x, _ccpPos, 10] spawn pl_ccp_revive_action;
                            waitUntil {(scriptDone _h1) or !(_group getVariable ["onTask", true])};
                        };
                    };
                } forEach (_reviveTargets select {_x getVariable ["pl_wia", false]});
                {
                    if ((_x getVariable "pl_injured") and (alive _x) and !(_x getVariable "pl_wia")) then {
                        _h2 = [_medic, _x, _ccpPos] spawn pl_medic_heal;
                        _time = time + 30;
                        waitUntil {scriptDone _h2 or !(_group getVariable ["onTask", true]) or (time > _time)}
                    };
                } forEach (_healTargets select {side _x isEqualTo playerSide});
                sleep 0.1;
                _medic enableAI "AUTOCOMBAT";
                _medic enableAI "AUTOTARGET";
                _medic enableAI "TARGET";
                // _medic enableAI "FSM";
            };

            _group setVariable ["setSpecial", false];
            _group setVariable ["onTask", false];
            _medic setVariable ["pl_damage_reduction", false];
            _medic setVariable ["pl_is_ccp_medic", false];
            if !(isNil "_escort") then {
                _escort setVariable ["pl_is_ccp_medic", false];
            };
            deleteMarker _markerNameCCP;
            deleteMarker _markerNameOuter;
            deleteMarker _markerNameInner;
        }
        else
        {
            // playSound "beep";
            hint "Medic is wounded!";
        };
    }
    else
    {
        // playSound "beep";
        hint "Medic is KIA";
    };
};


pl_transfer_medic = {
    private ["_destMedic", "_srcMedic", "_srcGroup", "_destGroup"];

    _srcGroup = hcSelected player select 0;

    _srcMedic = {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) exitWith {_x};
        objNull
    } forEach (units _srcGroup);

    if (_srcMedic isEqualTo objNull) exitWith {hint format ["%1 doens't has a Medic to transfer!", groupId _srcGroup]};
        
    missionNamespace setVariable ["pl_transfer_medic_enabled", true];

    hint "Select Group to transfer to";
    waitUntil {!(missionNamespace getVariable ["pl_transfer_medic_enabled", true])};
    hintSilent "";

    _destGroup = missionNamespace getVariable ["pl_transfer_medic_group", false];

    _destMedic = {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) exitWith {_x};
        objNull
    } forEach (units _destGroup);

    if (!(_destMedic isEqualTo objNull) and !(_destMedic getVariable "pl_wia")) exitWith {hint "Group already has a Medic"};


    playSound "beep";
    [_srcMedic] joinSilent _destGroup;   
};




