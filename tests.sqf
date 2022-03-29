pl_disengage = {
    params [["_group", (hcSelected player) select 0]];

    private _enemy = (leader _group) findNearestEnemy getPos (leader _group);

    if (isNull _enemy) exitWith {hint "Group not in Combat"};

    private _allyUnits = allUnits+vehicles select {side _x == playerSide};
    _allyUnits = _allyUnits - (units _group);
    private _ally = ([_allyUnits, [], {_x distance2D (leader _group)}, "ASCEND"] call BIS_fnc_sortBy)#0;

    private _retreatDistance = 200;
    if (((leader _group) distance2D _ally) < 250) then {
        _retreatDistance = ((leader _group) distance2D _ally) + 80;
    };

    if (vehicle (leader _group) != leader _group) then { _retreatDistance = _retreatDistance + 100};

    if ([getpos (leader _group)] call pl_is_city) then {_retreatDistance = _retreatDistance / 2};

    private _enemyDir = (leader _group) getDir _enemy;
    private _allyDir = (leader _group) getDir _ally;
    private _retreatPos = (getPos (leader _group)) getPos [_retreatDistance, _enemyDir - 180];

    _retreatPos findEmptyPosition [0, 25, typeOf (vehicle (leader _group))];

    private _markerDirName = format ["delayDir%1%2", _group, random 1];
    createMarker [_markerDirName, _retreatPos];
    _markerDirName setMarkerPos _retreatPos;
    _markerDirName setMarkerType "marker_position_eny";
    _markerDirName setMarkerColor pl_side_color;
    _markerDirName setMarkerDir _enemyDir;

    pl_draw_disengage_array pushBack [_group, _retreatPos];

    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa";
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    {
        _x setUnitTrait ["camouflageCoef", 0.5, true];
        _x setVariable ["pl_damage_reduction", true];
    } forEach (units _group);

    if (vehicle (leader _group) == leader _group) then {

        private _units = (units _group) select {alive _x};
        private _injured = _units select {lifeState _x isEqualTo "INCAPACITATED" or (_x getVariable ["pl_wia", false])};

        if (count _injured > 0) then {

            (leader _group) disableAI "AUTOCOMBAT";
            (leader _group) disableAI "TARGET";
            (leader _group) disableAI "AUTOTARGET";
            (leader _group) setCombatBehaviour "AWARE";
            (leader _group) doMove _retreatPos;
            (leader _group) setDestination [_retreatPos,"LEADER DIRECT", true];
            [leader _group, "SmokeShellMuzzle"] call BIS_fnc_fire;

            private _dragScripts = []; 
            private _restUnits = _units - _injured - [leader _group];
            private _draggers = [];

            for "_i" from 0 to (count _injured) - 1 do {
                if ((count _restUnits) - 1 >= _i) then {
                    _unit = _injured#_i;
                    _dragger = ([_restUnits, [], {_x distance2D _unit}, "ASCEND"] call BIS_fnc_sortBy)#0;
                    _draggers pushBack _dragger;
                    [_dragger, "SmokeShellMuzzle"] call BIS_fnc_fire;
                    _injured deleteAt (_injured find _unit);
                    _restUnits deleteAt (_restUnits find _dragger);
                    _dragScripts pushBack ([_dragger, _unit, _retreatPos, true] spawn pl_injured_drag);
                };
            };

            private _ii = 0;
            {
                if (_ii <= (count _draggers) - 1) then {
                    _x disableAI "AUTOCOMBAT";
                    _x setCombatBehaviour "AWARE";
                    doStop _x;
                    _x doFollow (_draggers#_ii);
                    [_x, _draggers#_ii] spawn {
                        params ["_unit", "_escortTarget"];
                        while {(group _unit) getVariable ["onTask", false]} do {

                            if (!(alive _escortTarget) or (_escortTarget getVariable ["pl_wia", false])) exitWith {_x doFollow (leader (group _unit))};

                            sleep 0.5;
                        };
                    };
                    _ii = _ii + 1;
                } else {
                    _x disableAI "AUTOCOMBAT";
                    _x setCombatBehaviour "AWARE";
                    _x disableAI "AUTOTARGET";
                    _x doFollow (leader _group);
                };
            } forEach _restUnits;

            waitUntil {sleep 0.5; ({!(scriptDone _x)} count _dragScripts) <= 0 or ({alive _x} count _units) <= 0};

        } else {
            _group setCombatMode "BLUE";
            _group setVariable ["pl_combat_mode", true];
            _group setSpeedMode "FULL";
            [leader _group, "SmokeShellMuzzle"] call BIS_fnc_fire;

            {
                _x disableAI "AUTOCOMBAT";
                _x disableAI "TARGET";
                _x disableAI "AUTOTARGET";
                _x setCombatBehaviour "AWARE";
                _x doMove _retreatPos;
                _x setDestination [_retreatPos,"LEADER DIRECT", true];
            } forEach _units;

            waitUntil {sleep 0.5; ({_x distance2D _retreatPos < 10} count _units) > 0 or !(_group getVariable ["onTask", false])};

            _group setCombatMode "YELLOW";
            _group setVariable ["pl_combat_mode", false];
        };


    } else {
        private _vic = vehicle (leader _group);
        [_vic, "SmokeLauncher"] call BIS_fnc_fire;

        _vic doMove _retreatPos;
        _vic setDestination [_retreatPos,"VEHICLE PLANNED" , true];
        waitUntil {sleep 0.5, unitReady _vic or !alive _vic};
    };

    sleep 1;
    if (_group getVariable ["onTask", false]) then {
        [_group, [], _retreatPos, _enemyDir] spawn pl_defend_position;
    };
    pl_draw_disengage_array =  pl_draw_disengage_array - [[_group, _retreatPos]];
    deleteMarker _markerDirName;
};

pl_draw_disengage_array = [];
pl_draw_disengage = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _pos1 = getPos (vehicle (leader (_x#0)));
                    _pos2 = _x#1;
                    _display drawLine [
                        _pos1,
                        _pos2,
                        pl_side_color_rgb
                    ];

            } forEach pl_draw_disengage_array;
    "]; // "
};

[findDisplay 12 displayCtrl 51] call pl_draw_disengage;

pl_injured_drag = {
    params ["_dragger", "_unit", "_ccpPos", ["_moveTo", false]];

    if (_moveTo) then {
        private _movePos = getPosASL _unit;
        _movePos = [0.5 - (random 1), 0.5 - (random 1)] vectorAdd _movePos;
        _dragger doMove _movePos;
        _dragger setDestination [_movePos,"LEADER DIRECT", true];
        _dragger disableAI "AUTOCOMBAT";
        _dragger setCombatBehaviour "AWARE";

        sleep 0.5;

        waitUntil {sleep 0.5; (unitReady _dragger) or ((_dragger distance2D _unit) < 2) or !((group _dragger) getVariable ["onTask", true]) or (!alive _unit) or (!alive _dragger) or (_dragger getVariable ["pl_wia", false])};
    };

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