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
pl_active_ccps = [];

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
            // _target disableAI "PATH";
            _stopTarget = true;
        };
        sleep 0.2;
        waitUntil {sleep 0.5; (_medic distance2D _pos < 2) or (unitReady _medic) or (!alive _medic) or !((group _medic) getVariable [_waitVar, true]) or (_medic getVariable ["pl_wia", false]) or (!alive _target) or (_target getVariable ["pl_wia", false])};
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
            waitUntil {sleep 0.5; (scriptDone _h1) or !((group _medic) getVariable [_waitVar, true]) or (time >= _time)};
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
    _medic enableAI "PATH";
    if (isNil "_ccpPos") then {
        _medic doFollow leader (group _medic);
    }
    else
    {
        _medic doMove _ccpPos;
    };
};



pl_heal_group = {
    params [["_group", (hcSelected player) select 0]];
    private ["_medic", "_healTarget", "_escort"];

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
            while {(_group getVariable "pl_healing_active") and alive _medic and !(_medic getVariable ["pl_wia", false])} do {
                // if (_group isEqualTo grpNull) exitWith {};
                // _reviveTargets = (getPos leader _group) nearObjects ["Man", 50];

                // double check !!!
                if !(_group getVariable ["onTask", false]) then {
                    sleep 1;
                    if !(_group getVariable ["onTask", false]) then {
                        {
                            _enemySides = [side player] call BIS_fnc_enemySides;
                            // _enemies = ((getPos _x) nearEntities [["Man", "Tank", "Car"], 25]) select {(side _x) in _enemySides and alive _x};
                            // if (_enemies isEqualTo []) then {
                                if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet") and !(_group getVariable ["onTask", true])) then {
                                    _medic setVariable ["pl_is_ccp_medic", true];
                                    _h1 = [_group, _medic, objNull, _x, [] , 20, "pl_healing_active"] spawn pl_ccp_revive_action;
                                    waitUntil {sleep 0.5; scriptDone _h1 or !(_group getVariable ["pl_healing_active", true])};
                                    _medic setVariable ["pl_is_ccp_medic", false];
                                };
                            // };
                        } forEach ((units _group) select {_x getVariable ["pl_wia", false]});;
                        // _medic sideChat "Tick";
                        // {
                            // _enemySides = [side player] call BIS_fnc_enemySides;
                            // _enemies = ((getPos _x) nearEntities [["Man", "Tank", "Car"], 25]) select {(side _x) in _enemySides and alive _x};
                            // if ((count _enemies) <= 0 and !(_group getVariable ["onTask", true])) then {
                            //     if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and !(lifeState _x isEqualTo "INCAPACITATED")) then {
                            //         _medic setVariable ["pl_is_ccp_medic", true];
                            //         _h1 = [_medic, _x, nil, "pl_healing_active"] spawn pl_medic_heal;
                            //         waitUntil {sleep 0.5; scriptDone _h1 or !(_group getVariable ["pl_healing_active", true])};
                            //         _medic setVariable ["pl_is_ccp_medic", false];
                            //     };
                            // };
                        // } forEach (units _group);
                        // _medic setVariable ["pl_is_ccp_medic", true];
                        _medic setVariable ["pl_is_ccp_medic", false];
                    };
                };
                _time = time + 10;
                waitUntil {sleep 0.5; time > _time or !(_group getVariable "pl_healing_active") or !alive _medic or (_medic getVariable ["pl_wia", false])};
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
        [group _unit, "wia", 1] call pl_voice_radio_answer;

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
    params ["_group", "_medic", "_escort", "_healTarget", "_ccpPos", "_reviveTime", "_waitVar", ["_minDragRange", 0]];
    // player sideChat str (alive _healTarget);

    if !(alive _healTarget) exitWith {};

    _healTarget setVariable ["pl_beeing_treatet", true];
    _medic disableAI "AUTOCOMBAT";
    _medic disableAI "AUTOTARGET";
    _medic disableAI "TARGET";
    _medic setVariable ["pl_damage_reduction", true];
    _medic setUnitTrait ["camouflageCoef", 0.1, true];
    _medic setVariable ["pl_engaging", true];
    // _medic disableAI "FSM";
    _medic enableAI "PATH";
    _medic setUnitPos "AUTO";
    doStop _medic;
    private _pos = getPos _healtarget;
    if !(isNull objectParent _healtarget) then {
        _pos = getPos (vehicle _healtarget);
    };
    _pos = [0.5 - (random 1), 0.5 - (random 1)] vectorAdd _pos;
    _medic doMove _pos;
    // _medic setDestination [_pos,"LEADER DIRECT", true];
    if !(isNull _escort) then {
        _escort disableAI "AUTOCOMBAT";
        _escort setVariable ["pl_engaging", true];
        _escort enableAI "PATH";
        _escort doMove _pos;
    };
    sleep 1;
    waitUntil {sleep 0.5; ((_medic distance2D _pos) < 5) or !(_group getVariable [_waitVar, true]) or (!alive _healTarget) or (!alive _medic) or (_medic getVariable ["pl_wia", false])};
    
    if (_group getVariable [_waitVar, true] and (alive _healTarget) and (alive _medic) and !(_medic getVariable ["pl_wia", false]) and ((_medic distance2D _pos) <= 5)) then {

        if !(isNull objectParent _healtarget) then {
            moveOut _healtarget;
            _healtarget setPos (getPos _medic);

            sleep 1;
        };
        // _medic setUnitPos "MIDDLE";

        _nearEnemies = allUnits select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and (_x distance2D _healTarget) < 500};
        _closeEnemies = allUnits select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and (_x distance2D _healTarget) < 200};
        if (!(_ccpPos isEqualTo []) and (count _nearEnemies) > 0) then {
            if ((count _closeEnemies) > 0) then {[_medic, (getpos _medic) getPos [65, _medic getDir _healTarget]] call pl_throw_smoke_at_pos};
            if ((_ccpPos distance2D _healTarget) > _minDragRange and ((_ccpPos distance2D _healTarget) < 200)) then {
                _escort doFollow _medic;
                _dragScript = [_medic, _healTarget, _ccpPos] spawn pl_injured_drag;
                waitUntil {sleep 0.5; scriptDone _dragScript};
            };
        };
        // sleep 1;
        if (alive _medic and alive _healTarget and (_group getVariable [_waitVar, true]) and !(lifeState _medic isEqualTo "INCAPACITATED")) then {

            doStop _escort;
            _reviveTime = time + _reviveTime;
            _medic attachTo [_healTarget, [0.6,0.2,0]];
            _medic setDir -90;
            _medic playAction "medicStart";
            _medic disableAI "ANIM";
            // while {_reviveTime > time and (_group getVariable [_waitVar, true])} do {
            while {_reviveTime > time and (_group getVariable [_waitVar, true])} do {
              _medic switchMove selectRandom ["AinvPknlMstpSnonWrflDnon_medic3", "AinvPknlMstpSnonWrflDnon_medic2", "AinvPknlMstpSnonWrflDnon_medic1", "AinvPknlMstpSnonWrflDnon_medic4"];
              _time = time + 5;
              waitUntil {sleep 0.5; time >=_time or time > _reviveTime or !(_group getVariable [_waitVar, true])};
            };
            detach _medic;
            _medic playAction "medicStop";
            _medic enableAI "ANIM";
            _healTarget setVariable ["pl_beeing_treatet", false];
        } else {
            _healTarget setVariable ["pl_beeing_treatet", false];
            if (_ccpPos isEqualTo []) then {
                _medic doFollow (leader (group _medic));
            } else {
                _medic doMove _ccpPos;
                _escort doMove _ccpPos;
            };
        };
    }
    else
    {
        _healTarget setVariable ["pl_beeing_treatet", false];
    };
    _medic setUnitPos "AUTO";
    if (_group getVariable _waitVar and (alive _medic) and !(_medic getVariable "pl_wia") and ((_medic distance2D _healTarget) < 2) and time > _reviveTime and !(lifeState _medic isEqualTo "INCAPACITATED")) then {
        _healTarget setUnconscious false;
        _healTarget setDamage 0;
        _healTarget setUnitPos "AUTO";
        _healTarget enableAI "PATH";
        _healTarget setVariable ["pl_wia", false];
        _healtarget setVariable ["pl_injured", false];
        _healTarget setVariable ["pl_wia_calledout", false];
        _healTarget setVariable ["pl_beeing_treatet", false];
        _healTarget setVariable ["pl_bleedout_set", false];
        if !((_healTarget getVariable ["pl_def_pos", []]) isEqualTo []) then {
            [_healTarget] spawn pl_move_back_to_def_pos;
        } else {
            _healTarget doFollow (leader (group _healtarget));
        };

        if !(_ccpPos isEqualTo []) then {
            _medic doMove _ccpPos;
            _medic setDestination [_ccpPos, "LEADER DIRECT", true];
            _escort doMove _ccpPos;
            _escort setDestination [_ccpPos, "LEADER DIRECT", true];
        } else {
            _medic doFollow (leader (group _medic));
            _escort doFollow (leader (group _medic));
        };
        _escort enableAI "AUTOCOMBAT";
        _escort enableAI "FSM";
    }
    else
    {
        _healTarget setVariable ["pl_beeing_treatet", false];
    };
    _medic enableAI "AUTOCOMBAT";
    _medic enableAI "AUTOTARGET";
    _medic enableAI "TARGET";
    _medic enableAI "FSM";
    _medic setVariable ["pl_engaging", false];
    _medic setVariable ["pl_damage_reduction", false];
    _medic setUnitTrait ["camouflageCoef", 1, true];
    _escort enableAI "AUTOCOMBAT";
    _escort enableAI "FSM";
    _escort setVariable ["pl_engaging", nil];
};

pl_injured_drag = {
    params ["_dragger", "_unit", "_ccpPos", ["_moveTo", false]];

    if (_moveTo) then {
        private _movePos = getPosASL _unit;
        _movePos = [0.5 - (random 1), 0.5 - (random 1)] vectorAdd _movePos;
        _dragger doMove _movePos;
        // _dragger setDestination [_movePos,"LEADER DIRECT", true];
        _dragger disableAI "AUTOCOMBAT";
        _dragger setCombatBehaviour "AWARE";

        sleep 0.5;

        waitUntil {sleep 0.5; (unitReady _dragger) or ((_dragger distance2D _unit) < 2) or !((group _dragger) getVariable ["onTask", true]) or (!alive _unit) or (!alive _dragger) or (_dragger getVariable ["pl_wia", false])};
    };

    if ((_dragger distance2D _unit) >= 4) exitWith {};


    // [ _unit ] remoteExec [ "dam_unit playMove _anim;_fnc_wake", 2 ];
    // _unit setUnconscious false;
    if (_ccpPos isEqualTo []) then {
        _ccpPos = getPos _dragger;
    };
    // _anim = selectRandom [
    //     "UnconsciousReviveArms_A","UnconsciousReviveArms_B","UnconsciousReviveArms_C","UnconsciousReviveBody_A",
    //     "UnconsciousReviveBody_B","UnconsciousReviveDefault_A","UnconsciousReviveDefault_B","UnconsciousReviveHead_A",
    //     "UnconsciousReviveHead_B","UnconsciousReviveHead_C","UnconsciousReviveLegs_A","UnconsciousReviveLegs_B"
    // ];  
    // _unit playMove _anim;
    _dragger setUnitPos "MIDDLE";
    _ccpDir = _unit getDir _ccpPos;
    // _dragger setPos ((getPos _unit) getPos [2, _ccpDir]);
    sleep 0.5;
    _unit setDir _ccpDir;
    _dragger attachTo [_unit, [0,1.2,0]];
    _dragger setDir -180;
    sleep 1;
    _dragger playAction "grabDrag";
    sleep 0.3;
    _unit switchmove "AinjPpneMrunSnonWnonDb";
        
    waitUntil {sleep 0.5; ((AnimationState _dragger) == "AmovPercMstpSlowWrflDnon_AcinPknlMwlkSlowWrflDb_2") || ((AnimationState _dragger) == "AmovPercMstpSnonWnonDnon_AcinPknlMwlkSnonWnonDb_2")}; 

    detach _dragger;

    _unit attachTo [_dragger, [0, 1.15, 0]];
    _unit setDir 180;
    _unit allowDamage false;

    _dummygrp = createGroup [civilian, true];
    _dummygrp setSpeedMode "LIMITED";
    _dummygrp setCombatMode "BLUE";
    _dummy = _dummygrp createUnit [typeOf _dragger, (getPos _dragger) getPos [1, _ccpDir], [], 0, "CAN_COLLIDE"]; //"C_man_polo_1_F"
    _dummy setDir _ccpDir;
    _dummy setUnitPos "up";
    _dummy hideObjectGlobal true;
    _dummy allowdammage false;
    _dummy setBehaviour "CARELESS";
    _dummy disableAI "FSM";
    _dummy disableAI "AUTOCOMBAT";
    _dummy disableAI "COVER";
    _dummy disableAI "SUPPRESSION";
    _dummy disableAI "TARGET";
    _dummy disableAI "AUTOCOMBAT";
    _dummy enabledynamicSimulation false;
    _dummy enableSimulation true;
    // _dummy forceSpeed 0.5;
    sleep 0.3;
    // [_dragger, _dummy, true] call BIS_fnc_attachToRelative;
    _dragger attachTo [_dummy, [0, -0.2, 0]]; 
    _dragger setDir 180;

    sleep 0.2,
        
    _dragger playMoveNow "AcinPknlMwlkSrasWrflDb";
    _dragger disableAI "ANIM";
    _dummy doMove _ccpPos;

    waitUntil {sleep 0.5; !alive _unit or !alive _dragger or (lifeState _dragger isEqualTo "INCAPACITATED") or (_dragger distance2D _ccpPos) < 4 or ((group _dragger) getVariable ["pl_stop_event", false]) or !((group _dragger) getVariable ["onTask", false])};

    doStop _dummy;
    detach _unit;
    detach _dragger;
    detach _dummy;
    deleteVehicle _dummy;
    _dragger enableAI "ANIM";
    _unit allowDamage true;
    _unit switchmove "";
    _unit setUnconscious true;
    _anim = selectRandom [
        "UnconsciousReviveArms_A","UnconsciousReviveArms_B","UnconsciousReviveArms_C","UnconsciousReviveBody_A",
        "UnconsciousReviveBody_B","UnconsciousReviveDefault_A","UnconsciousReviveDefault_B","UnconsciousReviveHead_A",
        "UnconsciousReviveHead_B","UnconsciousReviveHead_C","UnconsciousReviveLegs_A","UnconsciousReviveLegs_B"
    ];  
    _unit playMove _anim;
    doStop _dragger;
    _dragger switchmove "grabstop";
    _dragger setUnitPos "MIDDLE";
};


pl_ccp = {
    params [["_group", hcSelected player select 0], ["_isMedevac", false], ["_escort", objNull], ["_reviveRange", 100], ["_healRange", 25], ["_medic", objNull], ["_taskPlanWp", []]];
    private ["_mPos", "_healTarget", "_escort", "_group", "_ccpPos", "_markerNameOuter", "_markerNameInner", "_markerNameCCP", "_marker3D", "_ccpVic"];

    // _group = hcSelected player select 0;
    // if (vehicle (leader _group) != leader _group) exitWith {hint "Infantry ONLY Task!"};
    // if (pl_ccp_set and !(_isMedevac)) exitWith {hint "Only one CCP allowed!"};

    if (_group != (group player) and !(_isMedevac) and !(_group getVariable ["pl_set_as_medical", false])) exitWith {
        hint "Only the Player Group or a Medical Group can set up the CCP";
    };
    
    private _medic = {
        if (_x getUnitTrait "Medic" and alive _x and !(_x getVariable ["pl_wia", false])) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _medic) exitWith {hint "No Medic"};

    pl_ccp_size = 150;
    _markerNameCCP = str (random 3);
    createMarker [_markerNameCCP, getPos (leader _group)];
    _markerNameCCP setMarkerType "marker_CCP";
    _markerNameCCP setMarkerColor "colorBLUFOR";

    _markerNameOuter = format ["%1ccp%2", _group, random 2];
    createMarker [_markerNameOuter, getPos (leader _group)];
    _markerNameOuter setMarkerShape "ELLIPSE";
    _markerNameOuter setMarkerBrush "SolidBorder";
    _markerNameOuter setMarkerColor pl_side_color;
    _markerNameOuter setMarkerAlpha 0.35;
    _markerNameOuter setMarkerSize [_reviveRange, _reviveRange];

    _markerNameInner = str (random 2);
    createMarker [_markerNameInner, getPos (leader _group)];
    _markerNameInner setMarkerShape "ELLIPSE";
    _markerNameInner setMarkerBrush "SolidBorder";
    _markerNameInner setMarkerColor "colorGreen";
    _markerNameInner setMarkerAlpha 0.10;
    _markerNameInner setMarkerSize [_healRange, _healRange];

    if ((visibleMap or !(isNull findDisplay 2000)) and !_isMedevac) then {
        hint "Select CCP Position on Map";
        onMapSingleClick {
            pl_ccp_cords = _pos;
            if (_shift) then {pl_cancel_strike = true};
            pl_mapClicked = true;
            hintSilent "";
            onMapSingleClick "";
        };

        player enableSimulation false;

        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            _markerNameOuter setMarkerPos _mPos;
            _markerNameCCP setMarkerPos _mPos;
            if (inputAction "MoveForward" > 0) then {pl_ccp_size = pl_ccp_size + 20; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_ccp_size = pl_ccp_size - 20; sleep 0.05};
            _markerNameOuter setMarkerSize [pl_ccp_size, pl_ccp_size];
            if (pl_ccp_size >= 600) then {pl_ccp_size = 600};
            if (pl_ccp_size <= 25) then {pl_ccp_size = 25};
        };

        player enableSimulation true;

        pl_mapClicked = false;
        _reviveRange = pl_ccp_size;
        _ccpPos = pl_ccp_cords;
        pl_active_ccps pushBack _ccpPos;
        _markerNameOuter setMarkerBrush "Border";
        _markerNameOuter setMarkerPos _ccpPos;
        _markerNameCCP setMarkerPos _ccpPos;
        _markerNameInner setMarkerPos _ccpPos;

    }
    else
    {
        _ccpPos = getPos (leader _group);
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerNameCCP; deleteMarker _markerNameOuter; deleteMarker _markerNameInner; pl_ccp_set = false;};

    private _icon = "\Plmod\gfx\pl_ccp_marker.paa";

    _group setVariable ["pl_task_pos", _ccpPos];
    _group setVariable ["specialIcon", _icon];

    if (count _taskPlanWp != 0) then {

        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_ccpPos, _taskPlanWp, _icon];

        if (vehicle (leader _group) != leader _group) then {
            if !(_group getVariable ["pl_unload_task_planed", false]) then {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
            } else {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; ((_group getVariable ["pl_execute_plan", false]) and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
            };
        } else {
            // waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 or !(_group getVariable ["pl_task_planed", false])};
            waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
        };
        _group setVariable ["pl_disembark_finished", nil];

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_ccpPos, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_unload_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerNameCCP; deleteMarker _markerNameOuter; deleteMarker _markerNameInner; pl_ccp_set = false;};


    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    if (count (units _group) > 3) then {
        _escort = {
            if (_x != _medic and _x != (leader _group) and !(_x getVariable "pl_wia") and (alive _x)) exitWith {_x};
            objNull
        } forEach (units _group);
    } else {
        _escort = objNull;
    };
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    
    if (vehicle (leader _group) == leader _group) then {
        private _units = units _group;
        if (_group == (group player)) then {_units = [_medic, _escort]};
        {
            _x doMove _ccpPos;
            // _x setDestination [_ccpPos, "LEADER DIRECT", true];
            if (_x in [_medic, _escort]) then {
                pl_ccp_draw_array pushBack [_ccpPos, _x];
                _x setVariable ["pl_damage_reduction", true];
                _x setVariable ["pl_is_ccp_medic", true];
            };
        } forEach _units;
    } else {
        // [vehicle (leader _group), 6] call pl_vic_advance_to_pos_static;
        _group addWaypoint [_ccpPos, 0];
    };

    waitUntil {(_medic distance2D _ccpPos) < 25 or !alive _medic or (lifeState _medic isEqualTo "INCAPACITATED") or !(_group getVariable ["onTask", false])};

    private _mev = objNull;

    if (_group getVariable ["onTask", false]) then {

        if (vehicle (leader _group) != leader _group) then {
            _mev = vehicle (leader _group);
            // _group setVariable ["pl_on_march", false];
            [_group] spawn pl_leave_vehicle;

            waitUntil {sleep 0.5; (_group getVariable ["pl_disembark_finished", false]) or !(_group getVariable ["onTask", false])};

            private _units = units _group;
            if (_group == (group player)) then {_units = [_medic, _escort]};
            {
                if (_x in [_medic, _escort]) then {
                    pl_ccp_draw_array pushBack [_ccpPos, _x];
                    _x setVariable ["pl_damage_reduction", true];
                    _x setVariable ["pl_is_ccp_medic", true];
                } else {
                    [_x, 20, getDir _x] spawn pl_find_cover;
                };  
            } forEach _units;
        };

        while {(_group getVariable ["onTask", true]) and (alive _medic) and !(_medic getVariable ["pl_wia", false])} do {
            _reviveTargets = _ccpPos nearObjects ["Man", _reviveRange];
            {
                _reviveTargets = _reviveTargets + _x;
            } forEach ((nearestObjects [_ccpPos, ["Tank", "Car", "Truck"], _reviveRange, true]) apply {crew _x});

            _healTargets = _ccpPos nearObjects ["Man", _healRange];
            {
                if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and (_group getVariable ["onTask", true])) then {
                    _h2 = [_medic, _x, _ccpPos, "onTask"] spawn pl_medic_heal;
                    _time = time + 40;
                    waitUntil {sleep 0.5; scriptDone _h2 or !(_group getVariable ["onTask", true]) or (time > _time)}
                };
            } forEach (_healTargets select {side _x isEqualTo playerSide});

            {
                if (_x getVariable ["pl_wia", false] and !(_x getVariable ["pl_beeing_treatet", false]) and (_group getVariable ["onTask", true])) then {
                    if !(isNil "_escort") then {
                        _h1 = [_group, _medic, _escort, _x, _ccpPos, 20, "onTask", _healRange] spawn pl_ccp_revive_action;
                        waitUntil {sleep 0.5; (scriptDone _h1) or !(_group getVariable ["onTask", true])};
                    }
                    else
                    {
                        _h1 = [_group, _medic, objNull, _x, _ccpPos, 20, "onTask", _healRange] spawn pl_ccp_revive_action;
                        waitUntil {sleep 0.5; (scriptDone _h1) or !(_group getVariable ["onTask", true])};
                    };
                };
            } forEach (_reviveTargets select {_x getVariable ["pl_wia", false]});
            
            if ((_medic distance2D _ccpPos) < 15) then {
                doStop _medic;
                doStop _escort;
            } else {
                _medic doMove _ccpPos;
                _escort doMove _ccpPos;
            };
            _time = time + 5;
            waitUntil {sleep 0.5; time > _time or !(_group getVariable ["onTask", false])};
        };
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
    pl_active_ccps = pl_active_ccps - [_ccpPos];

    if !(isNull _mev) then {
        [_group, _mev] call pl_crew_vehicle_now;
    };
    // [_marker3D] call pl_remove_3d_icon;
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
    waitUntil {sleep 0.5; !(missionNamespace getVariable ["pl_transfer_medic_enabled", true])};
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




