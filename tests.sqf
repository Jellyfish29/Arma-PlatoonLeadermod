
pl_ccp = {
    params [["_group", hcSelected player select 0], ["_isMedevac", false], ["_escort", nil], ["_reviveRange", 100], ["_healRange", 25], ["_medic", nil]];
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
    createMarker [_markerNameOuter, [0,0,0]];
    _markerNameOuter setMarkerShape "ELLIPSE";
    _markerNameOuter setMarkerBrush "SolidBorder";
    _markerNameOuter setMarkerColor pl_side_color;
    _markerNameOuter setMarkerAlpha 0.35;
    _markerNameOuter setMarkerSize [pl_ccp_size, pl_ccp_size];

    if (visibleMap or !(isNull findDisplay 2000)) then {
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
            if (pl_ccp_size >= 200) then {pl_ccp_size = 200};
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

        _markerNameInner = str (random 2);
        createMarker [_markerNameInner, _ccpPos];
        _markerNameInner setMarkerShape "ELLIPSE";
        _markerNameInner setMarkerBrush "SolidBorder";
        _markerNameInner setMarkerColor "colorGreen";
        _markerNameInner setMarkerAlpha 0.10;
        _markerNameInner setMarkerSize [_healRange, _healRange];
    }
    else
    {
        _ccpPos = getPos (leader _group);
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerNameCCP; pl_ccp_set = false;};


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
    _group setVariable ["specialIcon", "\Plmod\gfx\pl_ccp_marker.paa"];

    
    private _units = units _group;
    if (_group == (group player)) then {_units = [_medic, _escort]};
    {
        if (isNull _x) exitWith {};
        _x doMove _ccpPos;
        // _x setDestination [_ccpPos, "LEADER DIRECT", true];
        if (_x in [_medic, _escort]) then {
            pl_ccp_draw_array pushBack [_ccpPos, _x];
            _x setVariable ["pl_damage_reduction", true];
            _x setVariable ["pl_is_ccp_medic", true];
        };
    } forEach _units;

    waitUntil {_medic distance2D _ccpPos < 20 or !alive _medic or !(_medic getVariable ["pl_wia", false]) or !(_group getVariable ["onTask", false])};

    while {(_group getVariable ["onTask", true]) and (alive _medic) and !(_medic getVariable ["pl_wia", false])} do {
        _reviveTargets = _ccpPos nearObjects ["Man", _reviveRange];
        _healTargets = _ccpPos nearObjects ["Man", _healRange];
        {
            if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet") and (_group getVariable ["onTask", true])) then {
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
        {
            if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and (_group getVariable ["onTask", true])) then {
                _h2 = [_medic, _x, _ccpPos, "onTask"] spawn pl_medic_heal;
                _time = time + 40;
                waitUntil {sleep 0.5; scriptDone _h2 or !(_group getVariable ["onTask", true]) or (time > _time)}
            };
        } forEach (_healTargets select {side _x isEqualTo playerSide});
        
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
    // [_marker3D] call pl_remove_3d_icon;
};


pl_ccp_revive_action = {
    params ["_group", "_medic", "_escort", "_healTarget", "_ccpPos", "_reviveTime", "_waitVar", ["_minDragRange", 0]];
    // player sideChat str (alive _healTarget);

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
        // _medic setUnitPos "MIDDLE";

        _nearEnemies = allUnits select {[(side _x), playerside] call BIS_fnc_sideIsEnemy and (_x distance2D _healTarget) < 500};
        if (!(_ccpPos isEqualTo []) and (count _nearEnemies) > 0  ) then {
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

{unitReady _x} count (units (group cursorObject))