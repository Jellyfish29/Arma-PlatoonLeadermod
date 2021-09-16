sleep 1;
if !(pl_enabled_medical) exitWith {};

pl_ccp_set = false;
pl_medic_cls_names = ["B_medic_F", "B_recon_medic_F", "B_T_Recon_medic_F", "B_W_Medic_F", "O_medic_F", "O_recon_medic_F", "O_T_medic_F", "O_T_Recon_medic_F", "I_medic_F", "I_E_medic_F",
                      "rhsusf_army_ocp_medic", "rhsusf_army_ocp_arb_medic", "rhsusf_army_ucp_medic", "rhsusf_army_ucp_arb_medic", "rhsusf_socom_marsoc_sarc", "rhsusf_navy_marpat_d_medic",
                      "rhsusf_navy_marpat_wd_medic"];

pl_ccp_heal_range = 50;
pl_ccp_revive_range = 200;
pl_ccp_draw_array = [];
pl_bleedout_time = 500;

pl_medic_heal = {
    params ["_medic", "_target", "_ccpPos", "_waitVar"];
    // _healPos = (getPos _target) findEmptyPosition [0, 40];
    if (_target == _medic) exitWith {
        _medic playAction "Medic";
        sleep 6;
        _medic setDamage 0;
        _medic setVariable ["pl_injured", false];
    };
    _healPos = getPosATL _target;
    _healPos = [0.3, 0] vectorAdd _healPos;
    _moveToPos = {
        params ["_medic", "_pos", "_isMedic", "_target", "_waitVar"];
        _medic disableAI "AUTOCOMBAT";
        _medic disableAI "AUTOTARGET";
        _medic disableAI "TARGET";
        // _medic disableAI "FSM";
        _medic doMove _pos;
        _medic setDestination [_pos, "LEADER DIRECT", true];
        _stopTarget = false;
        if (_target checkAIFeature "PATH") then {
            doStop _target;
            _target disableAI "PATH";
            _stopTarget = true;
        };
        sleep 2;
        waitUntil {(_medic distance2D _pos < 2) or (unitReady _medic) or (!alive _medic) or !((group _medic) getVariable [_waitVar, true]) or (_medic getVariable ["pl_wia", false]) or (!alive _target) or (_target getVariable ["pl_wia", false])};
        doStop _medic;
        _medic disableAI "PATH";
        _medic setUnitPos "MIDDLE";
        _medic enableAI "AUTOCOMBAT";
        _medic enableAI "AUTOTARGET";
        _medic enableAI "TARGET";
        _medic enableAI "FSM";
        if (_stopTarget) then {
            _target setUnitPos "MIDDLE";
            [_target] spawn {
                params ["_target"];
                sleep 6;
                _target enableAI "PATH";
                _target doFollow leader (group _target);
                _target setUnitPos "AUTO";
            };
        };
    };
    if (_target != player) then {
            _h1 = [_medic, _healPos, true, _target, _waitVar] spawn _moveToPos;
            _time = time + 40;
            waitUntil {(scriptDone _h1) or !((group _medic) getVariable [_waitVar, true]) or (time >= _time)};
        if ((!alive _target) or (_target getVariable "pl_wia")) exitWith {
            _medic enableAI "PATH";
            _medic setUnitPos "AUTO";
            _medic doFollow leader (group _medic);
        };
        if ((!alive _medic) or (_medic getVariable ["pl_wia", false])) exitWith {(group _medic) setVariable [_waitVar, false]};
        if (_medic distance2D _healPos <= 5) then {
            _medic playAction "MedicOther";
            sleep 6;
            _target setDamage 0;
            _target setVariable ["pl_injured", false];
        };
        _medic enableAI "PATH";
        _medic enableAI "AUTOCOMBAT";
        _medic setUnitPos "AUTO";
    };
    if (isNil "_ccpPos") then {
        _medic doFollow leader (group _medic);
    }
    else
    {
        _medic doMove _ccpPos;
        _medic moveTo _ccpPos;
    };
};



pl_heal_group = {
    params ["_group"];
    private ["_medic", "_healTarget", "_escort"];

    _group = (hcSelected player) select 0;

    if (_group getVariable ["pl_healing_active", false]) exitWith {if (pl_enable_beep_sound) then {playSound "beep"}; _group setVariable ["pl_healing_active", false]};

    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};

    // _medic = ((units _group) select {(typeOf _x) in pl_medic_cls_names}) select 0;
    {
        // if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {
        if (_x getUnitTrait "Medic") then {
            _medic = _x;
        };
    } forEach (units _group);
    // _escort = nil;
    if !(isNil "_medic") then {
        if !(_medic getVariable "pl_wia") then {

            if (pl_enable_beep_sound) then {playSound "beep"};

            _group setVariable ["pl_healing_active", true];
            // _medic setVariable ["pl_is_ccp_medic", true];
            // _medic disableAI "FSM";
            // _medic disableAI "AUTOCOMBAT";
            sleep 2;
            while {(_group getVariable "pl_healing_active")} do {
                // if (_group isEqualTo grpNull) exitWith {};
                // _reviveTargets = (getPos leader _group) nearObjects ["Man", 50];

                // double check !!!
                if !(_group getVariable ["onTask", true]) then {
                    sleep 1;
                    if !(_group getVariable ["onTask", true]) then {
                        {
                            _enemySides = [side player] call BIS_fnc_enemySides;
                            // _enemies = ((getPos _x) nearEntities [["Man", "Tank", "Car"], 25]) select {(side _x) in _enemySides and alive _x};
                            // if (_enemies isEqualTo []) then {
                                if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet") and !(_group getVariable ["onTask", true])) then {
                                    _h1 = [_group, _medic, nil, _x, getPos (leader _group), 40, "pl_healing_active"] spawn pl_ccp_revive_action;
                                    waitUntil {scriptDone _h1 or !(_group getVariable ["pl_healing_active", true])}
                                };
                            // };
                        } forEach ((units _group) select {_x getVariable ["pl_wia", false]});;
                        // _medic sideChat "Tick";
                        {
                            _enemySides = [side player] call BIS_fnc_enemySides;
                            _enemies = ((getPos _x) nearEntities [["Man", "Tank", "Car"], 25]) select {(side _x) in _enemySides and alive _x};
                            if ((count _enemies) <= 0 and !(_group getVariable ["onTask", true])) then {
                                if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and !(lifeState _x isEqualTo "INCAPACITATED")) then {
                                    _h1 = [_medic, _x, nil, "pl_healing_active"] spawn pl_medic_heal;
                                    waitUntil {scriptDone _h1 or !(_group getVariable ["pl_healing_active", true])}
                                };
                            };
                        } forEach (units _group);
                        // _medic setVariable ["pl_is_ccp_medic", true];
                    };
                };
                _time = time + 10;
                waitUntil {time > _time or !(_group getVariable "pl_healing_active") or !alive _medic or (_medic getVariable ["pl_wia", false])};
            };

            sleep 1;

            // _medic setVariable ["pl_is_ccp_medic", false];
        }
        else
        {
            // if (pl_enable_beep_sound) then {playSound "beep"};
            hint "Medic is wounded!";
        };
    }
    else
    {
        // if (pl_enable_beep_sound) then {playSound "beep"};
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
        if (pl_enable_beep_sound) then {playSound "beep"};
        if (pl_enable_chat_radio) then {leader (group _unit) sideChat format ["%1: %2 WOUNDED", groupId (group _unit), _unitMos]};
        if (pl_enable_map_radio) then {[group _unit, format ["...%1 is hit!", _unitMos], 20] call pl_map_radio_callout};
    };
};

pl_bleedout = {
    params ["_unit"];
    sleep 5;
    if (alive _unit and !(_unit getVariable "pl_bleedout_set")) then {
        _unit setVariable ["pl_bleedout_set", true];
        _time = _unit getVariable ["pl_bleedout_time", pl_bleedout_time];
        _deathTime = time + _time;
        waitUntil {sleep 1; time > _deathTime};
        if (_unit getVariable "pl_wia") then {
            _unit setDamage 1;
        };
        if (alive _unit) then {
            _unit setVariable ["pl_bleedout_time", pl_bleedout_time];
        };
    };
};



pl_ccp_revive_action = {
    params ["_group", "_medic", "_escort", "_healTarget", "_ccpPos", "_reviveTime", "_waitVar"];
    // player sideChat str (alive _healTarget);
    _healTarget setVariable ["pl_beeing_treatet", true];
    _medic disableAI "AUTOCOMBAT";
    _medic disableAI "AUTOTARGET";
    _medic disableAI "TARGET";
    // _medic disableAI "FSM";
    _medic enableAI "PATH";
    doStop _medic;
    _pos = getPosASL _healtarget;
    _pos = [0.5 - (random 1), 0.5 - (random 1)] vectorAdd _pos;
    _medic doMove _pos;
    _medic setDestination [_pos,"LEADER DIRECT", true];
    if !(isNil "_escort") then {
        _escort disableAI "AUTOCOMBAT";
        // _escort disableAI "FSM";
        _escort enableAI "PATH";
        _escort doMove (_pos findEmptyPosition [2, 40]);

    };
    sleep 1;
    waitUntil {(unitReady _medic) or ((_medic distance2D _healTarget) < 2) or !(_group getVariable [_waitVar, true]) or (!alive _healTarget) or (!alive _medic) or (_medic getVariable ["pl_wia", false])};
    // Animation
    if (_group getVariable [_waitVar, true] and (alive _healTarget) and (alive _medic) and !(_medic getVariable ["pl_wia", false]) and ((_medic distance2D _healTarget) <= 5)) then {
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
            (time > _reviveTime) or !(_group getVariable [_waitVar, true]);
         };
        detach _medic;
        _medic playAction "medicStop";
        sleep 2;
        _medic enableAI "ANIM";
        // if !(_group getVariable [_waitVar, true]) then {
            _healTarget setVariable ["pl_beeing_treatet", false];
        // }
    }
    else
    {
        _healTarget setVariable ["pl_beeing_treatet", false];
    };
    _medic setUnitPos "AUTO";
    if (_group getVariable _waitVar and (alive _medic) and !(_medic getVariable "pl_wia") and ((_medic distance2D _healTarget) < 2) and time > _reviveTime) then {
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
            _escort enableAI "FSM";
            _escort doMove _ccpPos;
            _escort moveTo _ccpPos;
        };
    }
    else
    {
        _healTarget setVariable ["pl_beeing_treatet", false];
    };
    _medic enableAI "AUTOCOMBAT";
    _medic enableAI "AUTOTARGET";
    _medic enableAI "TARGET";
    _medic enableAI "FSM";
    if !(isNil "_escort") then {
        _escort enableAI "AUTOCOMBAT";
        _escort enableAI "FSM";
    };
};

pl_ccp = {
    params [["_group", hcSelected player select 0], ["_isMedevac", false], ["_escort", nil], ["_reviveRange", 650], ["_healRange", 50], ["_medic", nil]];
    private ["_healTarget", "_escort", "_group", "_ccpPos", "_markerNameOuter", "_markerNameInner", "_markerNameCCP"];

    // _group = hcSelected player select 0;
    if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};
    if (pl_ccp_set and !(_isMedevac)) exitWith {hint "Only one CCP allowed!"};

    if (_group != (group player) and !(_isMedevac) and !(_group getVariable ["pl_set_as_medical", false])) exitWith {
        // if (pl_enable_beep_sound) then {playSound "beep"};
        hint "Only the Player Group or a Medical Vehicle can set up the CCP";
    };
    

    // _medic = ((units _group) select {(typeOf _x) in pl_medic_cls_names}) select 0;
    {
        // if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {
        //     _medic = _x;
        // };
        if (_x getUnitTrait "Medic") then {
            _medic = _x;
        };
    } forEach (units _group);
    // _escort = nil;
    // player sideChat "erstens is da";
    if !(isNil "_medic") then {
        // player sideChat "Medic is da";
        if !(_medic getVariable ["pl_wia", false]) then {

            _markerNameCCP = str (random 3);
            createMarker [_markerNameCCP, getPos (leader _group)];
            _markerNameCCP setMarkerType "marker_CCP";
            _markerNameCCP setMarkerColor "colorBLUFOR";

            if (visibleMap) then {
                hint "Select CCP Position on Map";
                onMapSingleClick {
                    pl_ccp_cords = _pos;
                    if (_shift) then {pl_cancel_strike = true};
                    pl_mapClicked = true;
                    hintSilent "";
                    onMapSingleClick "";
                };
                while {!pl_mapClicked} do {
                    // sleep 0.1;
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                    _markerNameCCP setMarkerPos _mPos;
                };
                pl_mapClicked = false;
                _ccpPos = pl_ccp_cords;
            }
            else
            {
                _ccpPos = getPos (leader _group);
            };

            if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerNameCCP; pl_ccp_set = false;};

            [_group] call pl_reset;
            sleep 0.2;

            if (pl_enable_beep_sound) then {playSound "beep"};

            pl_ccp_set = true;
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
            pl_ccp_draw_array pushBack [_ccpPos, _medic];
            if !(isNil "_escort") then {
                _escort setVariable ["pl_is_ccp_medic", true];
                _ccpGuard = _ccpGuard - [_escort];
                pl_ccp_draw_array pushBack [_ccpPos, _escort];
            };
            // {
            //     [_x, getPos leader _group, getDir leader _group, 20, false] spawn pl_find_cover;
            // } forEach _ccpGuard;

            _medic setVariable ["pl_damage_reduction", true];
            _medic setVariable ["pl_is_ccp_medic", true];


            _markerNameOuter = str (random 2);
            createMarker [_markerNameOuter, _ccpPos];
            _markerNameOuter setMarkerShape "ELLIPSE";
            _markerNameOuter setMarkerBrush "Border";
            _markerNameOuter setMarkerColor "colorGreen";
            _markerNameOuter setMarkerAlpha 0.15;
            _markerNameOuter setMarkerSize [_reviveRange, _reviveRange];

            _markerNameInner = str (random 2);
            createMarker [_markerNameInner, _ccpPos];
            _markerNameInner setMarkerShape "ELLIPSE";
            _markerNameInner setMarkerBrush "SolidBorder";
            _markerNameInner setMarkerColor "colorGreen";
            _markerNameInner setMarkerAlpha 0.10;
            _markerNameInner setMarkerSize [_healRange, _healRange];

            sleep 0.5;
            _ambPos = [random 2, random 2] vectorAdd _ccpPos;
            _medKit = "Item_Medikit" createVehicle _ambPos;
            sleep 0.5;
            _medGarbage = "MedicalGarbage_01_3x3_v1_F" createVehicle _ambPos;

            sleep 1;
            _medic doMove _ccpPos;
            _medic setDestination [_ccpPos, "LEADER DIRECT", true];
            if !(isNil "_escort") then {
                _escort doMove _ccpPos;
            };

            while {(_group getVariable ["onTask", true]) and (alive _medic) and !(_medic getVariable ["pl_wia", false])} do {
                // player sideChat "Loop is da";
                _reviveTargets = _ccpPos nearObjects ["Man", _reviveRange];
                _healTargets = _ccpPos nearObjects ["Man", _healRange];
                {
                    if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                        if !(isNil "_escort") then {
                            _h1 = [_group, _medic, _escort, _x, _ccpPos, 20, "onTask"] spawn pl_ccp_revive_action;
                            waitUntil {(scriptDone _h1) or !(_group getVariable ["onTask", true])};
                        }
                        else
                        {
                            _h1 = [_group, _medic, nil, _x, _ccpPos, 20, "onTask"] spawn pl_ccp_revive_action;
                            waitUntil {(scriptDone _h1) or !(_group getVariable ["onTask", true])};
                        };
                    };
                } forEach (_reviveTargets select {_x getVariable ["pl_wia", false]});
                {
                    if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia")) then {
                        _h2 = [_medic, _x, _ccpPos, "onTask"] spawn pl_medic_heal;
                        _time = time + 40;
                        waitUntil {scriptDone _h2 or !(_group getVariable ["onTask", true]) or (time > _time)}
                    };
                } forEach (_healTargets select {side _x isEqualTo playerSide});
                sleep 1;
                // if ((_medic distance2D _ccpPos) > 20) then {
                //     _medic doMove _ccpPos;
                //     if !(isNil "_escort") then {
                //         _escort doMove _ccpPos;
                //     };
                // };
                // _medic enableAI "AUTOCOMBAT";
                // _medic enableAI "AUTOTARGET";
                // _medic enableAI "TARGET";
                // _medic enableAI "FSM";
            };

            _group setVariable ["setSpecial", false];
            _group setVariable ["onTask", false];
            _medic setVariable ["pl_damage_reduction", false];
            _medic setVariable ["pl_is_ccp_medic", false];
            pl_ccp_draw_array = pl_ccp_draw_array - [[_ccpPos, _medic]];
            if !(isNil "_escort") then {
                _escort setVariable ["pl_is_ccp_medic", false];
                pl_ccp_draw_array = pl_ccp_draw_array - [[_ccpPos, _escort]];
            };
            deleteMarker _markerNameCCP;
            deleteMarker _markerNameOuter;
            deleteMarker _markerNameInner;
            deleteVehicle _medKit;
            deleteVehicle _medGarbage;
            pl_ccp_set = false;
        }
        else
        {
            // if (pl_enable_beep_sound) then {playSound "beep"};
            hint "Medic is wounded!";
        };
    }
    else
    {
        // if (pl_enable_beep_sound) then {playSound "beep"};
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


    if (pl_enable_beep_sound) then {playSound "beep"};
    [_srcMedic] joinSilent _destGroup;   
};




