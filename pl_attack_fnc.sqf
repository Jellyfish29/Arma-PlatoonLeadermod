pl_bounding_cords = [0,0,0];
pl_bounding_mode = "full";
pl_bounding_draw_array = [];
pl_draw_tank_hunt_array = [];
pl_suppress_area_size = 20;
pl_suppress_cords = [0,0,0];
pl_supppress_continuous = false;
pl_draw_suppression_array = [];
pl_sweep_cords = [0,0,0];
pl_sweep_area_size = 35;
pl_attack_mode = "normal";
pl_suppression_poses = [];
pl_assault_poses = [];
pl_suppression_min_distance = 5;


pl_suppressive_fire_position = {
    params [["_group", (hcSelected player) select 0], ["_sfpPos", []], ["_cords", []]];
    private ["_markerName", "_targets", "_pos", "_units", "_leader", "_area", "_mPos", "_markerPosName", "_leaderPos"];

    // _group = (hcSelected player) select 0;
    _group setVariable ["pl_is_task_selected", true];

    // if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0 and (_group getVariable ["pl_is_suppressing", false])) exitWith {_group setVariable ["pl_is_suppressing", false]};

    // if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0) exitWith {};

    if ((_group getVariable ["pl_is_suppressing", false])) exitWith {_group setVariable ["pl_is_suppressing", false]};

    pl_suppress_area_size = 25;

    _markerName = format ["%1suppress%2", _group, random 1];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor "colorOrange";
    _markerName setMarkerAlpha 0.2;
    _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];

    if (_cords isEqualTo []) then {

        if (visibleMap or !(isNull findDisplay 2000)) then {
            _leaderPos = getPos (leader _group);
            if !(_sfpPos isEqualTo []) then {
                _leaderPos = _sfpPos;
            };
            private _rangelimiter = 1500;
            if (vehicle (leader _group) != (leader _group)) then { _rangelimiter = 2000};

            _markerBorderName = str (random 2);
            createMarker [_markerBorderName, _leaderPos];
            _markerBorderName setMarkerShape "ELLIPSE";
            _markerBorderName setMarkerBrush "Border";
            _markerBorderName setMarkerColor "colorOrange";
            _markerBorderName setMarkerAlpha 0.8;
            _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];
            
            _message = "Select Position <br /><br />
                <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>30 Seconds</t> <br />
                <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />
                <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>Cancel</t> <br />";
            hint parseText _message;
            onMapSingleClick {
                pl_suppress_cords = _pos;
                if (_shift) then {pl_cancel_strike = true};
                pl_mapClicked = true;
                hintSilent "";
                onMapSingleClick "";
            };

            player enableSimulation false;

            if !(_sfpPos isEqualTo []) then {
                pl_show_watchpos_selector = true;
            };

            while {!pl_mapClicked} do {
                // sleep 0.1;
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };
                if ((_mPos distance2D _leaderPos) <= _rangelimiter) then {
                    _markerName setMarkerPos _mPos;
                };
                // _markerName setMarkerPos _mPos;
                if (inputAction "MoveForward" > 0) then {pl_suppress_area_size = pl_suppress_area_size + 5; sleep 0.05};
                if (inputAction "MoveBack" > 0) then {pl_suppress_area_size = pl_suppress_area_size - 5; sleep 0.05};
                _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];
                if (pl_suppress_area_size >= 150) then {pl_suppress_area_size = 150};
                if (pl_suppress_area_size <= 10) then {pl_suppress_area_size = 10};
            };

            pl_show_watchpos_selector = false;

            player enableSimulation true;

            pl_mapClicked = false;
            _cords = getMarkerPos _markerName;
            _area = pl_suppress_area_size;
            deleteMarker _markerBorderName;
        }
        else
        {
            _cursorPosIndicator = createVehicle ["Sign_Circle_F", [-1000, -1000, 0], [], 0, "none"];
            _cursorPosIndicator2 = createVehicle ["Sign_Sphere25cm_F", [-1000, -1000, 0], [], 0, "none"];
            _cursorPosIndicator setObjectScale 1.5;

            _leader = leader _group;
            pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

            while {inputAction "Action" <= 0} do {
                _viewDistance = _cursorPosIndicator distance2D player;
                // _cursorPosIndicator setPosATL ([0,0,_viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
                _cursorPosIndicator setPosATL (screenToWorld [0.5,0.5]);
                _cursorPosIndicator2 setPosATL (screenToWorld [0.5,0.5]);
                _cursorPosIndicator2 setObjectScale (_viewDistance * 0.025);
                _cursorPosIndicator setDir (_leader getDir _cursorPosIndicator);

                if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

                sleep 0.025
            };

            pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

            deleteVehicle _cursorPosIndicator;
            deleteVehicle _cursorPosIndicator2;

            if (pl_cancel_strike) exitWith {};

            _cords = getPosATL _cursorPosIndicator;

            _area = pl_suppress_area_size;

            _markerName setMarkerPos _cords;
        };
    } else {
        _markerName setMarkerPos _cords;
        _area = pl_suppress_area_size;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; _group setVariable ["pl_is_task_selected", nil];};

    if !(_sfpPos isEqualTo []) then {

        pl_at_targets_indicator pushBack [_sfpPos, _cords];

        waitUntil {sleep 0.5; !(_group getVariable ["pl_task_planed", false])};

        sleep 2;
        if (vehicle (leader _group) == (leader _group)) then {

            waitUntil {(({_x getVariable ["pl_in_position", false]} count (units _group)) == count (units _group)) or !(_group getVariable ["onTask", false])};
            if !(_group getVariable ["onTask", false]) exitWith {pl_cancel_strike = true};
        } else {
            waitUntil {(_group getVariable ["pl_in_position", false]) or !(_group getVariable ["onTask", false])};
            if !(_group getVariable ["onTask", false]) exitWith {pl_cancel_strike = true};
        };
        pl_at_targets_indicator = pl_at_targets_indicator - [[_sfpPos, _cords]];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; _group setVariable ["pl_is_task_selected", nil];};

    if (_group getVariable ["pl_in_position", false]) then {
        _markerPosName = format ["defenceAreaDir%1", _group];
        _markerPosName setMarkerType "marker_sfp";
    } else {
        _markerPosName  = format ["afp%1", _group];
        createMarker [_markerPosName , getPos (vehicle (leader _group))];
        _markerPosName setMarkerDir ((leader _group) getDir _cords);
        _markerPosName  setMarkerType "marker_afp";
        _markerPosName  setMarkerColor pl_side_color;
    };   

    
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa";
    _leader = leader _group;
    pl_draw_suppression_array pushBack [_cords, _leader, false, _icon];
    [_group, "suppress", 1] call pl_voice_radio_answer;
    

    _group setVariable ["pl_is_suppressing", true];
    pl_suppression_poses pushback [_cords, _group];
    // check if enemy in Area
    // _allTargets = nearestObjects [_cords, ["Man", "Car", "Truck", "Tank"], _area, true];
    _getTargets = {
        params ["_cords", "_area"];
        private _targetsPos = [];
        private _allTargets = _cords nearEntities [["Man", "Car", "Truck", "Tank"], _area];
        {
            _targetsPos pushBack (getPosATL _x);
        } forEach (_allTargets select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

        // if no enemy target buildings;
        private _buildings = nearestObjects [_cords, ["house"], _area];
        if !((count _buildings) == 0) then {
            {
                _bPos = [0,0,2] vectorAdd (getPosATL _x);
                _targetsPos pushBack _bPos;
            } forEach _buildings;
        };

        // add Random Possitions
        if (_targetsPos isEqualTo []) then {
            for "_i" from 0 to 5 do {
                _rPos = [[[_cords, _area]], nil] call BIS_fnc_randomPos;
                _targetsPos pushBack _rPos;
            };
        };
        private _return = ATLToASL (selectRandom _targetsPos);
        _return
    };

    private _units = (units _group);

    if (_group getVariable ["pl_inf_attached", false]) then {
        _vicGroup = _group getVariable ["pl_attached_vicGrp", grpNull];
        _units = _units + (units _vicGroup);
    };

    _vicTargets = _cords nearEntities [["Car", "Truck", "Tank"], _area] select {alive _x and (side _x) != playerSide and (_group knowsAbout _x) > 0};

    if (leader _group != vehicle (leader _group)) then {
        if (([vehicle (leader _group)] call pl_has_cannon )and (_vicTargets isEqualTo [])) then {
            [vehicle (leader _group)] call pl_load_he;
        };
    };

    private _allHelpers = [];

    {
        _x setVariable ["pl_current_unitPos", unitPos _x];

        if ((unitPos _x) isEqualto "Down") then {
            _x setUnitPos "Middle";
        };
    } forEach _units;

    sleep 0.3;

    while {(_group getVariable ["pl_is_suppressing", true]) and !(isNull _group)} do {
        {
            _unit = _x;
            if (_unit != (vehicle _unit) or (((primaryweapon _unit call BIS_fnc_itemtype) select 1) == "MachineGun") or (random 1) > 0) then {
                if (_unit != (vehicle _unit) and (_unit) == gunner (vehicle _unit)) then {
                    _vic = vehicle _unit;
                    _vicTargets = _cords nearEntities [["Car", "Truck", "Tank"], _area] select {alive _x and (side _x) != playerSide and (_group knowsAbout _x) > 0};

                    if (!(_vicTargets isEqualTo []) and ([_vic] call pl_has_cannon)) then {

                        _vicTargets = ([_vicTargets, [], {_x distance2D _vic}, "ASCEND"] call BIS_fnc_sortBy);
                        _weapon = [_vic] call pl_get_weapon;
                        _turretPath = _vic unitTurret _unit;

                        {
                            _vic doTarget _x;
                            _vic doFire _x;
                            _timeOut = time + 8;
                            waitUntil {sleep 0.1; !(_group getVariable ["pl_is_suppressing", false]) or ((_vic aimedAtTarget [_x, _weapon]) > 0.5 and ((weaponState [_vic, _turretPath, _weapon])#5 <= 0.2)) or time >= _timeOut};
                            if (_group getVariable ["pl_is_suppressing", true] and time < _timeOut) then {
                                [_vic , _weapon] call BIS_fnc_Fire;
                                // _fired = _vic fireAtTarget [_x, _weapon];
                                sleep 0.5;
                            }

                        } forEach _vicTargets;

                    };
                };


                _pos = [_cords, _area] call _getTargets;
                _targetPos = [_pos , _unit] call pl_get_suppress_target_pos;

                if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_unit, _targetPos] call pl_friendly_check)) then {

                    _unit doWatch _targetPos;
                    _unit doSuppressiveFire _targetPos;

                };
            };
        } forEach _units ;
        _time = time + 15;
        waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["pl_is_suppressing", false])};
        if ((([_group] call pl_get_ammo_group_state)#0) == "Red") exitWith {};

    };

    sleep 0.5;

    // waitUntil {sleep 0.5; (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) <= 0 and !(_group getVariable ["pl_is_suppressing", false])) or !alive (leader _group)};

    if (leader _group != vehicle (leader _group)) then {
        [vehicle (leader _group)] call pl_load_ap;
    };

    {
        _x setUnitPos (_x getVariable ["pl_current_unitPos", "Middle"]);
        _x setVariable ["pl_current_unitPos", nil];
    } forEach (units _group);

    {
      deleteVehicle _x;
    } forEach _allHelpers;

    pl_suppression_poses = pl_suppression_poses - [[_cords, _group]];
    deleteMarker _markerName;
    if (_group getVariable ["pl_in_position", false]) then {
        _markerPosName = format ["defenceAreaDir%1", _group];
        _markerPosName setMarkerType "marker_position";
    } else {
        deleteMarker _markerPosName;
    };

    pl_draw_suppression_array = pl_draw_suppression_array - [[_cords, _leader, false, _icon]];
};


pl_throw_granade_at_target = {
    params ["_unit", "_target"];

    _loadOut = getUnitLoadout _unit;
    _uniform = (_loadOut#3)#1;
    _vest = (_loadOut#4)#1;
    _grenadeType = {
        if ((([_x#0] call BIS_fnc_itemType)#1) isEqualTo "Grenade") exitWith {_x#0};
        ""
    } forEach (_uniform + _vest);

    if (_grenadeType isEqualto "") exitWith {false};

    _grenadeTypeMuzzle =  [_grenadeType] call pl_get_grenade_muzzle;
    _unit setVariable ["pl_grenadeTypeMuzzle", _grenadeTypeMuzzle];

    if (((_unit weaponState _grenadeTypeMuzzle)#4) <= 0) exitWith {false};

    private _safetyDistance = 15;
    if ([getpos _target] call pl_is_indoor) then {
        _safetyDistance = 8;
    };

    if ((_unit distance2D _target) > 30) exitWith {_target setVariable ["pl_nade_cd", time + 10]; false};
    if ((_unit distance2D _target) < _safetyDistance) exitWith {_target setVariable ["pl_nade_cd", time + 10]; false};

    if ([_unit, getPos _target, _safetyDistance] call pl_friendly_check_excact) exitWith {false};

    _unit setVariable ["pl_hg_target", _target];
    _unit forceSpeed 0;
    _unit setUnitPos "MIDDLE";
    _unit doWatch _target;
    _unit doTarget _target;

    _eh = _unit addEventHandler ["FiredMan", {
            params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

            if (_muzzle isEqualto (_unit getVariable ["pl_grenadeTypeMuzzle", ""])) then {
                [_unit, _projectile] spawn {
                    params ["_unit", "_projectile"];

                    _target = _unit getVariable ["pl_hg_target", objNull];

                    _vel = [_unit, getPos _target, 30] call pl_THROW_VEL;

                    _projectile setVelocity _vel;

                    _targetPos = (getPosASLVisual _target) vectorAdd [1 - (random 2), 1 - (random 2), 1];

                    sleep 3;
                    // waitUntil{ (vectorMagnitude velocity _projectile) < 0.02 };

                    _allies = (nearestObjects [getPos _target, ["Man"], 15]) select {(side _x) == (side _unit)};

                    {
                        _x forceSpeed 0;
                        _x setUnitPos "MIDDLE";
                    } forEach _allies;


                    _projectile setPosASL _targetPos;
                    // _projectile setPosASL (getPosATLVisual _target);

                    // _m = createMarker [str (random 2), getPosASLVisual _target];
                    // _m setMarkerType "mil_dot";
                    _unit setVariable ["pl_hg_target", nil];

                    sleep 1;

                    {
                        _x forceSpeed -1;
                        _x setUnitPos "AUTO";
                    } forEach _allies;
                };
                _unit removeEventHandler [_thisEvent, _thisEventHandler];
                
            };
        }];
    _target setVariable ["pl_nade_cd", time + 8];
    _unit directSay "SentThrowingGrenade";
    sleep 1;
    _fired = [_unit, _grenadeTypeMuzzle] call BIS_fnc_fire;
    // _unit forceSpeed -1;
    [_unit, _target] spawn {
        params ["_unit", "_target"];
        sleep 5;
        _unit forceSpeed ([_unit distance2D _target] call pl_get_assault_speed);
        _unit setUnitPos "AUTO";
    };
    _fired
};

// [cursorTarget, target_1] spawn pl_throw_granade_at_target;

pl_throw_smoke_at_pos = {
    params ["_unit", "_smokePos"];

    if ((_unit distance2D _smokePos) > 75) exitWith {false}; 


    _loadOut = getUnitLoadout _unit;
    _uniform = (_loadOut#3)#1;
    _vest = (_loadOut#4)#1;
    _grenadeType = {
        if ((([_x#0] call BIS_fnc_itemType)#1) isEqualTo "SmokeShell") exitWith {_x#0};
        ""
    } forEach (_uniform + _vest);

    if (_grenadeType isEqualto "") exitWith {false};

    _grenadeTypeMuzzle =  _grenadeType + "Muzzle";
    _unit setVariable ["pl_grenadeTypeMuzzle", _grenadeTypeMuzzle];

    _unit forceSpeed 0;
    _unit setVariable ["pl_smoke_pos", _smokePos];

    _eh = _unit addEventHandler ["FiredMan", {
            params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

            if (_muzzle isEqualto (_unit getVariable ["pl_grenadeTypeMuzzle", "_grenadeTypeMuzzle"])) then {
                _unit directSay "SentThrowingSmoke";
                [_unit, _projectile] spawn {
                    params ["_unit", "_projectile"];

                    _smokePos = _unit getVariable ["pl_smoke_pos", getpos _unit];

                    _vel = [_unit, _smokePos, 50] call pl_THROW_VEL;

                    _projectile setVelocity _vel;

                    // sleep 2;
                    waitUntil{ (vectorMagnitude velocity _projectile) < 0.02 };

                    _projectile setPos (_unit getVariable ["pl_smoke_pos", getpos _unit]);

                    _unit setVariable ["pl_smoke_pos", nil];

                };
                _unit removeEventHandler [_thisEvent, _thisEventHandler];
                
            };
        }];
    // sleep 0.5;
    _fired = [_unit, _grenadeTypeMuzzle] call BIS_fnc_fire;
    _unit forceSpeed -1;
    _fired
};

pl_group_throw_smoke = {
    params ["_group", "_smokePos"];

    {
        if ([_x, _smokePos] call pl_throw_smoke_at_pos) exitWith {};
    } forEach (units _group);
};

pl_fire_ugl_at_target = {
    params ["_unit", "_target"];

    if ((_unit distance2D _target) > 300) exitWith {false};
    if ((_unit distance2D _target) < 30) exitWith {false};

    if ([_unit, getPos _target, 35] call pl_friendly_check_excact) exitWith {false};

    _ugl = (getArray (configfile >> "CfgWeapons" >> primaryWeapon _unit >> "muzzles") - ["SAFE", "this"]) param [0, ""];

    if (_ugl isEqualto "") exitWith {false};

    _unit forceSpeed 0;
    _unit doTarget _target;
    _unit setVariable ["pl_ugl_data", [_ugl, getPosASL _target]];
    _eh = _unit addEventHandler ["FiredMan", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

        _uglData = _unit getVariable "pl_ugl_data";

        if (_muzzle isEqualto (_uglData#0)) then {

            _vel = [_unit, (_uglData#1) getPos [[-6, 6] call BIS_fnc_randomInt, (_uglData#1) getDir _unit], 300] call pl_THROW_VEL;

            _projectile setVelocity _vel;

            _unit removeEventHandler [_thisEvent, _thisEventHandler];
        };


    }];

    [_unit ,_ugl] spawn {
        params ["_unit", "_ugl"];

        sleep 1;
        
        _unit selectWeapon _ugl;
        _unit forceWeaponFire [_ugl, weaponState _unit select 2];

        sleep 2;
        _unit forceSpeed -1;
        _unit doWatch objNull;
    };
    true

};

pl_fire_AT_at_target = {
    params ["_unit", "_target"];

     if ((secondaryWeapon _unit) == "" or ((secondaryWeaponMagazine _unit) isEqualTo [])) exitWith {false};

    private _targetpos = getPosATL _target;
    private _targetBuilding = objNull;

    if (_target isKindOf "Man") then {
        if ([_targetpos] call pl_is_indoor) then {
            _targetBuilding = nearestBuilding _targetpos;
        }
    };

    _targetpos = ATLtoASL _targetpos;

    private _exit = false;

    _vis = lineIntersectsSurfaces [eyePos _unit, _targetPos, _unit, vehicle _unit, true, 1];

    if !(_vis isEqualTo []) then {
        _targetObject = (_vis select 0) select 2;

        if (isNull _targetObject) exitWith {_exit = true};

        // attack inf in building
        if !(isnull _targetBuilding) then {
            if (_targetObject == _targetBuilding) then {
                _targetPos = (_vis select 0) select 0;
                // _targetPos set [2, (_targetPos select 2) + 3];
            };
        } else {
                _exit = true;
        };
    };

    if (_exit) exitwith {false};
    if ([_unit, _targetPos] call pl_friendly_check) exitWith {};

    [_unit, _target, _targetPos] spawn {
        params ["_unit", "_target", "_targetPos"];
        _unit forceSpeed 0;

        // doStop _unit;    
        //systemchat str _targetpos;

        _targetPos set [2, (_targetPos select 2) + 0.5];
        _unit reveal _target;
        _unit lookat _target;
        _unit doWatch _target;
        _unit dotarget _target;

        _time = time + 3;
        waitUntil {sleep 0.1; !alive _unit or !((group _unit) getVariable ["onTask", false]) or time >= _time};
        if (!alive _unit or !((group _unit) getVariable ["onTask", false])) exitWith {_unit enableAI "anim"; _unit forceSpeed -1;};
        // sleep 2;

        _unit setDir (([(_unit modeltoworld (_unit selectionposition "lefthand")),_targetPos] call BIS_fnc_dirTo) + 0);
        private _wm = (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "modes")) select 0;
        if (_wm == "this") then {_wm = secondaryWeapon _unit};
        _unit selectWeapon (secondaryWeapon _unit);
        _unit forceWeaponFire [secondaryweapon _unit, _wm];

        _time = time + 1.8;
        waitUntil {sleep 0.1; !alive _unit or !((group _unit) getVariable ["onTask", false]) or time >= _time};
        if (!alive _unit or !((group _unit) getVariable ["onTask", false])) exitWith {_unit enableAI "anim"; _unit forceSpeed -1;};

        _unit disableAI "anim"; 
        _unit dotarget _target;

        _time = time + 1.8;
        waitUntil {sleep 0.1; !alive _unit or !((group _unit) getVariable ["onTask", false]) or time >= _time};
        if (!alive _unit or !((group _unit) getVariable ["onTask", false])) exitWith {_unit enableAI "anim"; _unit forceSpeed -1;};

        _unit forceWeaponFire [secondaryweapon _unit, _wm];

        _unit forceSpeed -1;
        _unit enableAI "anim"; 
        _unit lookat objNull;
        _unit doWatch objNull;
    };

    true
};

pl_get_assault_speed = {
     params ["_distance"];

     _unit setHit ["legs", 0];
     _unit enableAI "PATH";
     _unit setUnitPos "AUTO";

     if (_distance <= 40) exitWith {_unit disableAI "AIMINGERROR"; 2};
     _unit enableAI "AIMINGERROR";
     if (_distance < 100) exitWith {3};
     -1  
};

pl_force_seperation = {
    params ["_unit"];

    sleep (random 1);

    _nearFriendlyUnits = ((getPos _unit) nearObjects ["Man", [2,3] call BIS_fnc_randomInt]) select {side _x == playerside and !(_x getVariable ["pl_forced_stoped", false]) and (_x checkAIFeature "PATH") and ((lifeState _x) isNotEqualTo "INCAPACITATED")};

    if !(_nearFriendlyUnits isEqualto []) then {
        _unit forceSpeed 0;
        _unit setVariable ["pl_forced_stoped", true];
        _unit setUnitPosWeak "MIDDLE";

        [_unit] spawn {

            sleep ([1, 3] call BIS_fnc_randomInt);
            (_this#0) forceSpeed 3;
            (_this#0) setUnitPos "AUTO";
            (_this#0) setVariable ["pl_forced_stoped", nil];
        };
    };
};

pl_add_aslt_hit_eh = {
    params ["_unit"];

    _eh =  _unit addEventHandler ["Hit", {
        params ["_unit", "_source", "_damage", "_instigator"];

        if ((vehicle _source) isKindOf "Car" or (vehicle _source) isKindOf "Tank") then {
            // systemChat "hit";

            if (time > (_unit getVariable ["pl_vic_hit_cd", 0])) then {

                _unit setVariable ["pl_vic_hit_cd", time + 15];

                
                _temp = missionNamespace getVariable [format ["targets_%1", group _unit], []];
                _temp pushBackUnique (vehicle _source);
                (group _unit) setVariable [format ["targets_%1", group _unit], _temp];

                _smk = false;
                {
                    _x setVariable ["pl_aslt_reasses_target", true];
                    if ((_x distance2D _unit) <= 150 and !_smk and alive _x and (lifeState _x) != "INCAPACITATED") then {
                        _smk = [_x, getPos _unit] call pl_throw_smoke_at_pos;
                        _unitPos = unitPos _x;
                        _x setUnitPos "DOWN";
                        _x forceSpeed 0;
                        [_x, _unitPos] spawn {
                            params ["_unit", "_unitPos"];
                            _time = time + 15;
                            waituntil {sleep 0.5; !((group _unit) getVariable ["onTask", false]) or time >= _time};
                            _unit setUnitPos _unitPos;
                            _unit forceSpeed -1;
                        };
                    };
                } forEach (units (group _unit));
            };
        };
    }];

    waituntil {sleep 1; !((group _unit) getVariable ["onTask", false])};

    _unit removeEventHandler ["Hit", _eh];

};



pl_assault_position = {
    params ["_group", ["_taskPlanWp", []], ["_cords", []]];
    private ["_mPos", "_approachPos", "_lineArea", "_phaseDistance", "_phaseDir", "_markerPhaselineName", "_cords", "_targets", "_markerName", "_icon", "_coverTeam","_manuverTeam", "_manuverPos", "_coverPos", "_breakingPoint", "_startPos", "_area", "_vicGroup", "_flankSide", "_flank"];

    pl_sweep_area_size = 50;
    pl_phase_line_distance = 20;
    pl_phase_line_dir = 0;
    pl_phase_line_size = pl_sweep_area_size / 2;

    _group setVariable ["pl_is_task_selected", true];

    if ((vehicle (leader _group) != leader _group and !(_group getVariable ["pl_has_cargo", false] or _group getVariable ["pl_vic_attached", false])) and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};


    _markerName = format ["%1sweeper", _group];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor pl_side_color;
    _markerName setMarkerAlpha 0.35;
    _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];

    _arrowMarkerName = format ["%1arrow", _group];
    createMarker [_arrowMarkerName, [0,0,0]];
    _arrowMarkerName setMarkerType "marker_std_atk";
    _arrowMarkerName setMarkerDir 0;
    _arrowMarkerName setMarkerColor pl_side_color;
    _arrowMarkerName setMarkerSize [1.2, 1.2];

    _markerPhaselineName = format ["%1atk_phase", _group];
    createMarker [_markerPhaselineName, [0,0,0]];
    _markerPhaselineName setMarkerShape "RECTANGLE";
    _markerPhaselineName setMarkerBrush "Solid";
    _markerPhaselineName setMarkerColor pl_side_color;
    _markerPhaselineName setMarkerAlpha 0.7;
    _markerPhaselineName setMarkerSize [pl_sweep_area_size, 0.5];

    if (_cords isEqualTo []) then {

        if (visibleMap or !(isNull findDisplay 2000)) then {

            private _rangelimiterCenter = getPos (leader _group);
            if !(_taskPlanWp isEqualTo []) then {_rangelimiterCenter = waypointPosition _taskPlanWp};
            if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};
            private _rangelimiter = 200;
            _markerBorderName = str (random 2);
            createMarker [_markerBorderName, _rangelimiterCenter];
            _markerBorderName setMarkerShape "ELLIPSE";
            _markerBorderName setMarkerBrush "Border";
            _markerBorderName setMarkerColor "colorOrange";
            _markerBorderName setMarkerAlpha 0.8;
            _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

            _message = "Select Assault Location <br /><br />
                <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>SELECT Position</t> <br />
                <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
                <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />";
            hint parseText _message;
            onMapSingleClick {
                pl_sweep_cords = _pos;
                if (_shift) then {pl_cancel_strike = true};
                pl_mapClicked = true;
                hintSilent "";
                onMapSingleClick "";
            };

            private _rangelimiterCenter = getPos (leader _group);
            if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};

            player enableSimulation false;

            while {!pl_mapClicked} do {
                // sleep 0.1;
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };

                if (inputAction "MoveForward" > 0) then {pl_sweep_area_size = pl_sweep_area_size + 2; sleep 0.05};
                if (inputAction "MoveBack" > 0) then {pl_sweep_area_size = pl_sweep_area_size - 2; sleep 0.05};
                _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
                if (pl_sweep_area_size >= 120) then {pl_sweep_area_size = 120};
                if (pl_sweep_area_size <= 5) then {pl_sweep_area_size = 5};

                if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
                    _markerName setMarkerPos _mPos;
                    _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
                };
            };

            pl_mapClicked = false;

            _cords = getMarkerPos _markerName;

            _rangelimiter = pl_sweep_area_size * 2.5;
            _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];
            _rangelimiterCenter = _cords;
            _markerBorderName setMarkerPos _cords;

            onMapSingleClick {
                pl_sweep_cords = _pos;
                if (_shift) then {pl_cancel_strike = true};
                pl_mapClicked = true;
                hintSilent "";
                onMapSingleClick "";
            };

            while {!pl_mapClicked} do {
                // sleep 0.1;
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };

                if (inputAction "MoveForward" > 0) then {pl_phase_line_size = pl_phase_line_size + 2; sleep 0.05};
                if (inputAction "MoveBack" > 0) then {pl_phase_line_size = pl_phase_line_size - 2; sleep 0.05};
                if (pl_phase_line_size >= pl_sweep_area_size + 25) then {pl_phase_line_size = pl_sweep_area_size + 25};
                if (pl_phase_line_size <= 15) then {pl_phase_line_size = 15};

                if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {

                    _markerPhaselineName setMarkerPos _mPos;
                    _markerPhaselineName setMarkerDir (_mPos getDir _cords);
                    _markerPhaselineName setMarkerSize [pl_phase_line_size, 0.5];

                    _arrowMarkerName setMarkerPos _mPos;
                    _arrowMarkerName setMarkerDir (_mPos getDir _cords);

                    if (pl_phase_line_size >= 25) then {
                        _markerPhaselineName setMarkerColor "colorOrange";
                    } else {
                        _markerPhaselineName setMarkerColor pl_side_color;
                    };

                };
            };

            pl_mapClicked = false;

            player enableSimulation true;

            deleteMarker _markerBorderName;

            _approachPos = getMarkerPos _markerPhaselineName;
            _lineArea = pl_phase_line_size;

            _markerName setMarkerPos _cords;
            _markerName setMarkerBrush "Border";
            _area = pl_sweep_area_size;

        // 3d Order
        } else {

            waitUntil {sleep 0.1; inputAction "Action" <= 0};

            _cursorPosIndicator = createVehicle ["Sign_Arrow_Large_Yellow_F", [-1000, -1000, 0], [], 0, "none"];

            _leader = leader _group;
            pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

            while {inputAction "Action" <= 0} do {
                _viewDistance = _cursorPosIndicator distance2D player;
                if (cursorTarget isKindOf "house") then {
                    _cursorPosIndicator setPosATL ([0, 0, ((boundingBox cursorTarget)#1)#2] vectorAdd (screenToWorld [0.5,0.5]));
                } else {
                    _cursorPosIndicator setPosATL ([0,0,_viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
                };
                _cursorPosIndicator setObjectScale (_viewDistance * 0.05);

                if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

                sleep 0.025
            };

            if (pl_cancel_strike) exitWith {deleteVehicle _cursorPosIndicator; pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]]};

            _cords = getPosATL _cursorPosIndicator;

            pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];

            deleteVehicle _cursorPosIndicator;

            _cursorPosIndicator = createVehicle ["Sign_Arrow_Direction_Yellow_F", _cords, [], 0, "none"];

            _leader = leader _group;
            pl_draw_3dline_array pushback [_leader, _cursorPosIndicator];

            waitUntil {sleep 0.1; inputAction "Action" <= 0};

            _cursorPosIndicatorDir = createVehicle ["Sign_Sphere25cm_F", screenToWorld [0.5,0.5], [], 0, "none"];

            pl_draw_3dline_array pushback [_cursorPosIndicator, _cursorPosIndicatorDir];

            while {inputAction "Action" <= 0} do {
                _viewDistance = _cursorPosIndicatorDir distance2D player;
                _cursorPosIndicatorDir setPosATL ([0, 0, _viewDistance * 0.01] vectorAdd (screenToWorld [0.5,0.5]));
                _cursorPosIndicator setDir (_cursorPosIndicatorDir getDir _cords);
                _cursorPosIndicatorDir setObjectScale (_viewDistance * 0.07);
                _cursorPosIndicator setObjectScale ((_cursorPosIndicator distance2D player) * 0.07);

                if (inputAction "selectAll" > 0) exitWith {pl_cancel_strike = true};

                sleep 0.025
            };

            _approachPos = getPosATL _cursorPosIndicatorDir;

            _area = (_approachPos distance2D _cords) * 0.6;
            _lineArea = _area * 0.7;
            if (_area > 60) then {_area = 60};
            _phaseDir = _approachPos getDir _cords;
            _markerName setMarkerPos _cords;
            _markerName setMarkerBrush "Border";

            pl_draw_3dline_array = pl_draw_3dline_array - [[_cursorPosIndicator, _cursorPosIndicatorDir]];
            pl_draw_3dline_array = pl_draw_3dline_array - [[_leader, _cursorPosIndicator]];
            deleteVehicle _cursorPosIndicator;
            deleteVehicle _cursorPosIndicatorDir;

            // _phaseDir = (leader _group) getDir _cords;

            if (_group getVariable ["pl_on_march", false]) then {
                _taskPlanWp = (waypoints _group) select ((count waypoints _group) - 1);
                _group setVariable ["pl_task_planed", true];
                _taskPlanWp setWaypointStatements ["true", "(group this) setVariable ['pl_execute_plan', true]"];
                // _phaseDir = (waypointPosition _taskPlanWp) getDir _cords;
            };

            _markerPhaselineName setMarkerPos _approachPos;
            _arrowPos = (getMarkerPos _markerPhaselineName) getPos [- 15, _phaseDir - 180];
            _markerPhaselineName setMarkerDir _phaseDir;
            _markerPhaselineName setMarkerSize [_area - 10, 0.5];
            _arrowMarkerName setMarkerPos _arrowPos;
            _arrowMarkerName setMarkerDir _phaseDir;
            _markerName setMarkerSize [_area, _area];

            if (_area >= 50) then {
                _markerPhaselineName setMarkerColor "colorOrange";
            } else {
                _markerPhaselineName setMarkerColor pl_side_color;
            };

        };

    } else {
        if (_cords isEqualTo [0, 0, 0]) then {
            waitUntil {sleep 0.1; ((leader _group) findNearestEnemy (getPos (leader _group))) isNotEqualTo objNull};
            _cords = getPos ((leader _group) findNearestEnemy (getPos (leader _group)));
        };
        _area = (((leader _group) distance2D _cords) / 2) + 30;
        _approachPos = getPos (leader _group);
        _lineArea = _area * 0.7;
        _markerName setMarkerPos _cords;
        _markerName setMarkerBrush "Border";
        _phaseDir = _approachPos getDir _cords;
        _phaseDir = _approachPos getDir _cords;

        _markerPhaselineName setMarkerPos _approachPos;
        _arrowPos = (getMarkerPos _markerPhaselineName) getPos [- 15, _phaseDir - 180];
        _markerPhaselineName setMarkerDir _phaseDir;
        _markerPhaselineName setMarkerSize [_area - 10, 0.5];
        _arrowMarkerName setMarkerPos _arrowPos;
        _arrowMarkerName setMarkerDir _phaseDir;
        _markerName setMarkerSize [_area, _area];
    };

    if (pl_cancel_strike) exitWith {
        pl_cancel_strike = false;
        deleteMarker _markerName;
        deleteMarker _markerPhaselineName;
        deleteMarker _arrowMarkerName;
        _group setVariable ["pl_is_task_selected", nil];
     };

    _rightPos = _cords getPos [pl_sweep_area_size, 90];
    _leftPos = _cords getPos [pl_sweep_area_size, 270];
    pl_draw_text_array pushBack ["ENY", _leftPos, 0.02, pl_side_color_rgb];
    pl_draw_text_array pushBack ["ENY", _rightPos, 0.02, pl_side_color_rgb];

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa";

    _group setVariable ["pl_task_pos", _cords];
    _group setVariable ["specialIcon", _icon];

    if (count _taskPlanWp != 0) then {

        _group setVariable ["pl_grp_task_plan_wp", _taskPlanWp];

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

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
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_unload_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];
    };

    if (pl_cancel_strike) exitWith {
        pl_cancel_strike = false;
        deleteMarker _markerName;
        deleteMarker _markerPhaselineName;
        deleteMarker _arrowMarkerName;
        pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
        _group setVariable ["pl_is_task_selected", nil];
     };

    _arrowDir = (leader _group) getDir _cords;
    _arrowDis = ((leader _group) distance2D _cords) / 2;
    _arrowPos = [_arrowDis * (sin _arrowDir), _arrowDis * (cos _arrowDir), 0] vectorAdd (getPos (leader _group));

    pl_draw_text_array pushBack ["SEIZE", _cords, 0.025, pl_side_color_rgb]; 

    [_group, "attack", 1] call pl_voice_radio_answer;

    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _group setVariable ["pl_is_attacking", true];

    _startPos = getPos (leader _group);

    _markerName setMarkerPos _cords;

    // sleep 0.2;

    private _machinegunner = objNull;
    private _medic = objNull;

    private _startUnitCount = {alive _x and !((lifeState _x) isEqualto "INCAPACITATED")} count (units _group);
    _breakingPoint = round (_startUnitCount * 0.66);
    if (_breakingPoint >= ({alive _x and !((lifeState _x) isEqualto "INCAPACITATED")} count (units _group))) then {_breakingPoint = -1};

    // [_approachPos, _cords, _area,  _group, _markerPhaselineName, _arrowMarkerName] spawn {
    //     params ["_approachPos", "_cords", "_area",  "_group", "_markerPhaselineName", "_arrowMarkerName"];

    //     while {(({(_x distance _approachPos) < 25} count (units _group)) == 0) and (_group getVariable ["onTask", true]) and !(isNull _group)} do {

    //         if (_cords distance2D (leader _group) > _area + 20) then {
    //             _phaseDir = (leader _group) getDir _cords;
    //             _markerPhaselineName setMarkerDir _phaseDir;

    //             _arrowPos = (getMarkerPos _markerPhaselineName) getPos [- 15, _phaseDir - 180];
    //             _arrowDis = ((leader _group) distance2D _cords) / 2;

    //             _arrowMarkerName setMarkerPos _arrowPos;
    //             _arrowMarkerName setMarkerDir _phaseDir;
    //             _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
    //         } else {
    //             _arrowMarkerName setMarkerSize [0,0];
    //             _markerPhaselineName setMarkerSize [0,0];
    //         };
    //         sleep 0.1;
    //     };
    // };

    if !(_group getVariable ["onTask", false]) exitWith {};

    private _teams = [];
    private _vic = objNull;

    if (_group getVariable ["pl_has_cargo", false] or _group getVariable ["pl_vic_attached", false]) then {

        if (vehicle (leader _group) != leader _group) then {
            [vehicle (leader _group), _approachPos, 7] call pl_advance_to_pos_switch;
        };

        if (!(_group getVariable ["onTask", true])) exitWith {};

        if ((({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) < _startUnitCount)) then {
            _approachPos = [_group] call pl_find_centroid_of_group;
        };


        private _infGroup = grpNull;
        _vic = vehicle (leader _group);
        _vicGroup = _group;

        [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
        sleep 0.1;
        for "_i" from count waypoints _group - 1 to 0 step -1 do {
            deleteWaypoint [_group, _i];
        };
        
        _vicGroup setVariable ["pl_on_march", false];

        if (_group getVariable ["pl_has_cargo", false]) then {

            private _cargo = (crew _vic) - (units _group);

            private _cargoGroups = [];
            {
                _unit = _x;

                if !(_unit in (units (group player))) then {
                    _cargoGroups pushBack (group _unit);
                };

            } forEach _cargo;

            // _infGroup leaveVehicle _vic;

            private _limit = 0;
            {
                if ((count (units _x)) > _limit) then {
                    _limit = count (units _x);
                    _infGroup = _x;
                };
                // [_x] spawn pl_reset;
            } forEach _cargoGroups;

            [_infGroup, _cargo, _vic] call pl_combat_dismount;

            if !(_infGroup getVariable ["pl_show_info", false]) then {
                [_infGroup] call pl_show_group_icon;
            };

            _vic setVariable ["pl_on_transport", nil];
            _group setVariable ["pl_has_cargo", false];

            waitUntil {sleep 0.5; (({vehicle _x != _x} count (units _infGroup)) == 0) or (!alive _vic)};
            sleep 0.5;
            _timeOut = time + 7;
            waitUntil {sleep 0.5;time >= _timeOut or ({unitReady _x} count (units _infGroup)) == (count (units _infGroup))};

        } else {

            _infGroup = _group getVariable ["pl_attached_infGrp", grpNull];
            _group setVariable ["pl_vic_attached", false];
            _group setVariable ["pl_attached_infGrp", nil];

            {
                _x disableAI "AUTOCOMBAT";
                _x setCombatBehaviour "AWARE";
            } forEach (units _infGroup);
        };

        // sleep 0.5;

        [_infGroup] call pl_reset;

        sleep 0.5;

        [_infGroup] call pl_reset;

        sleep 0.5;

        _infGroup setVariable ["onTask", true];
        _infGroup setVariable ["setSpecial", true];
        _infGroup setVariable ["specialIcon", _icon];
        _infGroup setVariable ["pl_is_attacking", true];

        _startPos = getPos (leader _infGroup);

        _vicGroup = _group;
        _group = _infGroup;

        [_vicGroup] spawn pl_reset;

        sleep 0.5;

        [_vicGroup, _infGroup] spawn pl_attach_vic;

        _breakingPoint = round (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) * 0.66);
        if (_breakingPoint >= ({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group))) then {_breakingPoint = -1};

    };

    if (!(_group getVariable ["onTask", true])) exitWith {
        deleteMarker _markerName;
        deleteMarker _markerPhaselineName;
        pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["SEIZE", _cords, 0.025, pl_side_color_rgb]]; 
        deleteMarker _arrowMarkerName;
        _group setVariable ["pl_is_attacking", false];
        {
            _x setVariable ["pl_damage_reduction", false];
        } forEach (units _group);
    };

    // ATTACK //

    (leader _group) playActionNow "gestureFreeze";

    {
        _unit = _x;
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
        if (((primaryweapon _unit call BIS_fnc_itemtype) select 1) == "MachineGun") then {_machinegunner = _unit};
        _x setVariable ["pl_damage_reduction", true];
    } forEach (units _group);

    private _taskTime = time + 180;

    // set Teams and Sturmausgangspositionen
    if (_teams isEqualto []) then {

        if (count ((units _group) select {alive _x and !((lifeState _x) isEqualto "INCAPACITATED")}) >= 6) then {
            private _team1 = [];
            private _team2 = [];
            _ii = 1;
            {
                if (_ii % 2 == 0) then {
                    _team1 pushBack _x;
                }
                else
                {
                    _team2 pushBack _x;
                };
                _ii = _ii + 1;
            } forEach ((units _group) select {alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")});

            _teams = [_team1, _team2];

            if (_machinegunner in (_teams#0)) then {
                _coverTeam = _teams#0;
                _manuverTeam = _teams#1;
            } else {
                _coverTeam = _teams#1;
                _manuverTeam = _teams#0;
            };

            if (_medic in _manuverTeam) then {
                _u = {
                    if (_x != _machinegunner) exitWith {_x};
                    objNull
                } forEach _coverTeam;

                if !(isNull _u) then {
                    _manuverTeam deleteAt (_manuverTeam find _medic);
                    _coverTeam deleteAt (_coverTeam find _u);
                    _coverTeam pushBack _medic;
                    _manuverTeam pushBack _u;
                };
            };
        } else {
            _coverTeam = [];
            if !(isNull _machinegunner) then {_coverTeam pushBack _machinegunner};
            if !(isNull _medic) then {_coverTeam pushBack _medic};
            _manuverTeam = (units _group) - _coverTeam;
        };

        _pos1 = _approachPos getpos [_area, (_cords getDir _approachPos) + 90];
        _pos2 = _approachPos getpos [_area, (_cords getDir _approachPos) - 90];

        private _accuracy = 40;
        private _losOffset = 2;
        private _watchDir = _approachPos getDir _cords;
        private _losPos = [];
        private _validLosPos = [];
        private _losCount = 0;
        // private _lineArea = _area * 0.75;
        private _losDir = _watchDir;

        for "_j" from 0 to _accuracy do {

            _losOffset = _losOffset + (_lineArea / _accuracy);

            if (_j % 2 == 0) then {
                _losPos = (_approachPos getPos [2, _watchDir]) getPos [_losOffset, _watchDir + 90];
            }
            else
            {
                _losPos = (_approachPos getPos [2, _watchDir]) getPos [_losOffset, _watchDir - 90];
            };

            _losPos = [_losPos, 1.75] call pl_convert_to_heigth_ASL;
            _losDir = _losPos getDir (_cords getPos [_area, _approachPos getDir _cords]);

            _losCount = 0;

            for "_l" from 0 to 400 step 10 do {

                _checkPos = _losPos getPos [_l, _losDir];
                _checkPos = [_checkPos, 1.75] call pl_convert_to_heigth_ASL;
                _vis = lineIntersectsSurfaces [_losPos, _checkPos, objNull, objNull, true, 1, "FIRE"];

                // _helper1 = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
                // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                // _helper1 setposASL _checkPos;

                if !(_vis isEqualTo []) exitWith {};

                _losCount = _losCount + 1;
            };
            if !(isOnRoad ([_losPos, 0] call pl_convert_to_heigth_ASL)) then {
                _validLosPos pushback [_losPos, _losCount];
            };
        };

        _coverPos = (([_validLosPos, [], {_x#1}, "DESCEND"] call BIS_fnc_sortBy)#0)#0;
        // _manuverPos = (([_validLosPos, [], {_x#1}, "ASCEND"] call BIS_fnc_sortBy)#0)#0;

        // -
        if ((_coverPos distance2D _pos1) < (_coverPos distance2D _pos2)) then {
            _manuverPos = _coverPos getpos [_area, (_cords getDir _approachPos) - 90];
            _flankSide = "+";
        // +
        } else {
            _manuverPos = _coverPos getpos [_area, (_cords getDir _approachPos) + 90];
            _flankSide = "-";
        };

        // {
        //     _m = createMarker [str (random 5), _x#0];
        //     _m setMarkerType "mil_dot";
        //     _m setMarkerColor (_x#1);
        // } forEach [[_coverPos, "colorGreen"], [_manuverPos, "colorRED"]];

        _flank = false;
        if (_lineArea >= 25) then {

            if !([_approachPos] call pl_is_city) then {
                _flank = true;
                if !(_coverTeam isEqualto []) then {
                    [_coverTeam, _coverPos, _approachPos getDir _cords, 18, true, [], false] call pl_get_to_cover_positions; //,_cords getPos [_area, _approachPos getDir _cords]
                };
                [_manuverTeam, _manuverPos, _approachPos getDir _cords, 10, false, [], false] call pl_get_to_cover_positions;

                _time = time + 30;
                waitUntil {sleep 0.5; !(_group getVariable ["onTask", false]) or ({_x getVariable ["pl_in_position", false]} count (units _group)) == count ((units _group) select {alive _x and !((lifeState _x) isEqualto "INCAPACITATED")}) or time >= _time};
            } else {
               [_coverTeam, _approachPos, _approachPos getDir _cords, 18, true, [], false] call pl_get_to_cover_positions; 
            };

        } else {
            _manuverTeam = _manuverTeam + _coverTeam;
            _coverTeam = [];
            // if !(isnull _machinegunner) then {_coverTeam pushBack _machinegunner};
            if !(isNull _medic) then {_coverTeam pushBack _medic};
            {
                [_x, 15, _x getDir _cords] spawn pl_find_cover;
            } forEach _coverTeam;
        };
    };

    if (!(_group getVariable ["onTask", true])) exitWith {
        deleteMarker _markerName;
        deleteMarker _markerPhaselineName;
        pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["SEIZE", _cords, 0.025, pl_side_color_rgb]]; 
        deleteMarker _arrowMarkerName;
        _group setVariable ["pl_is_attacking", false];
        {
            _x setVariable ["pl_damage_reduction", false];
        } forEach (units _group);
    };

    sleep 0.2;

    {
        _x setVariable ["pl_is_at", true];
        _x disableAI "AUTOCOMBAT";
        _x enableAI "PATH";
        _x setUnitPos "AUTO";
    } forEach _manuverTeam;

    if (_lineArea >= 25) then {
        _group setBehaviour "COMBAT";
    } else {
        _group setBehaviour "AWARE";
    };
    _group setCombatMode "RED";


    _targets = (_cords nearObjects ["Man", _area + 10 + (_area * 0.2)]) select {[(side _x), playerside] call BIS_fnc_sideIsEnemy};

    _vicTargets = (_cords nearEntities [["Car", "Tank", "Truck"], _area + 10 + (_area * 0.2)]) select {[(side _x), playerside] call BIS_fnc_sideIsEnemy};

    _targets = _targets + _vicTargets;

    _targets = [_targets, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;



    if ((count _targets) == 0) then {

        missionNamespace setVariable [format ["targets_%1", _group], []];
        [_group, (getPos (_manuverTeam#0)) getpos [40, _approachPos getDir _cords]] spawn pl_group_throw_smoke;
        (_manuverTeam#0) playActionNow "gestureGo";
        [_manuverTeam, _cords, _approachPos getDir _cords, 20, false, [], false] call pl_get_to_cover_positions;
        _time = time + 20;
        waitUntil {sleep 0.5; !(_group getVariable ["onTask", true]) or (time > _time) or (leader _group) distance2D _cords < 10};
    }
    else
    {

        missionNamespace setVariable [format ["targets_%1", _group], _targets];

        [_group, (getPos (_manuverTeam#0)) getpos [40, _approachPos getDir _cords]] spawn pl_group_throw_smoke;
        (_manuverTeam#0) playActionNow "gestureGo";

        [_manuverTeam, _coverTeam] call pl_team_grenade_swap;

        {

            if (_x == _medic) then {
                [_group, _x, _x getVariable ["pl_def_pos", _startPos], 100] spawn pl_defence_ccp;
                _breakingPoint = _breakingPoint - 1;
            } else {

                [_x, _group, _area, _cords, _medic, _machinegunner, _coverTeam, _manuverTeam, _flankSide, _flank] spawn {
                    params ["_unit", "_group", "_area", "_cords", "_medic", "_machinegunner", "_coverTeam", "_manuverTeam", "_flankSide", "_flank"];
                    private ["_movePos", "_target", "_flankPos"];

                    if (_unit in _manuverTeam and _flank) then {

                        _target = ([missionNamespace getVariable format ["targets_%1", _group], [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;

                        if (_flankSide == "+") then {
                            // _flankPos = (getPos _target) getPos [(_area * 0.75) - ([3, 6] call BIS_fnc_randomInt), (_unit getDir _target) + 90];
                            _flankPos = ((getpos _unit) getPos [(_unit distance2D _target) / 2, _unit getDir _target]) getPos [(_area * 0.75) - ([3, 6] call BIS_fnc_randomInt), (_unit getDir _target) + 90];
                        } else {
                            // _flankPos = (getPos _target) getPos [(_area * 0.75) - ([3, 6] call BIS_fnc_randomInt), (_unit getDir _target) - 90];
                            _flankPos = ((getpos _unit) getPos [(_unit distance2D _target) / 2, _unit getDir _target]) getPos [(_area * 0.75) - ([3, 6] call BIS_fnc_randomInt), (_unit getDir _target) - 90];
                        };

                        _unit doMove _flankPos ;
                        // _unit setDestination [_flankPos, "LEADER DIRECT", true];
                        _reachable = [_unit, _flankPos, 20] call pl_not_reachable_escape;

                        // _m = createMarker [str (random 5), _flankPos];
                        // _m setMarkerType "mil_dot";

                        _sleepTime = time + 40;
                        waitUntil {sleep 0.5; (_unit distance2D _flankPos) <= 20 or time >= _sleepTime or !(alive _unit) or !((group _unit) getVariable ["onTask", false])};
                    };

                    [_unit] spawn pl_add_aslt_hit_eh;

                    while {sleep 0.5; (count (missionNamespace getVariable format ["targets_%1", _group])) > 0} do {

                        _unit setVariable ["pl_aslt_reasses_target", nil];

                        if ((!alive _unit) or !((group _unit) getVariable ["onTask", true])) exitWith {};

                        if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                            _target = {
                                _attacker = _x getVariable ["pl_at_enaged_by", objNull];
                                if (!(_x isKindOf "Man") and alive _x and (isNull _attacker or _attacker == _unit)) exitWith {_x};
                                objNull
                            } forEach (missionNamespace getVariable format ["targets_%1", _group]);

                            // systemChat str _target;

                            if !(isNull _target) then {
                                _target setVariable ["pl_at_enaged_by", _unit];
                                _checkPosArray = [];
                                private _atkDir = _unit getDir _target;
                                private _lineStartPos = (getPos _unit) getPos [(_area + 100)  / 2, _atkDir - 90];
                                _lineStartPos = _lineStartPos getPos [8, _atkDir];
                                private _lineOffsetHorizon = 0;
                                private _lineOffsetVertical = (_target distance2D _unit) / 60;
                                _targetDir = getDir _target;
                                for "_i" from 0 to 60 do {
                                    for "_j" from 0 to 60 do { 
                                        _checkPos = _lineStartPos getPos [_lineOffsetHorizon, _atkDir + 90];
                                        _lineOffsetHorizon = _lineOffsetHorizon + ((_area + 100) / 60);

                                        _checkPos = [_checkPos, 1.579] call pl_convert_to_heigth_ASL;

                                        // _m = createMarker [str (random 1), _checkPos];
                                        // _m setMarkerType "mil_dot";
                                        // _m setMarkerSize [0.2, 0.2];

                                        _vis = lineIntersectsSurfaces [_checkPos, AGLToASL (unitAimPosition _target), _target, vehicle _target, true, 1, "VIEW"];
                                        // _vis2 = [_target, "VIEW", _target] checkVisibility [_checkPos, AGLToASL (unitAimPosition _target)];
                                        if (_vis isEqualTo []) then {
                                            if ((_unit distance2D _target) < 250) then {
                                                _pointDir = _target getDir _checkPos;
                                                if (_pointDir >= (_targetDir - 50) and _pointDir <= (_targetDir + 50)) then {
                                                    // _m setMarkerColor "colorORANGE";
                                                } else {
                                                    if (_target distance2D _checkPos >= 30) then {
                                                        _checkPosArray pushBack _checkPos;
                                                        // _m setMarkerColor "colorRED";
                                                    };
                                                };
                                            } else {
                                                _checkPosArray pushBack _checkPos;
                                                // _m setMarkerColor "colorRED";
                                            };
                                        };
                                    };
                                    _lineStartPos = _lineStartPos getPos [_lineOffsetVertical, _atkDir];
                                    _lineOffsetHorizon = 0;
                                };
                                _lineOffsetVertical = 0;

                                if (count _checkPosArray > 0 and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {

                                    _unit enableAI "PATH";
                                    _unit forceSpeed -1;

                                    _movePos = ([_checkPosArray, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;
                                    _unit doMove _movePos;
                                    // _unit setDestination [_movePos, "LEADER DIRECT", true];
                                    // _unit forceSpeed 3;

                                    // _m = createMarker [str (random 1), _movePos];
                                    // _m setMarkerType "mil_dot";
                                    // _m setMarkerSize [0.6, 0.6];
                                    // _m setMarkerColor "colorGreen";

                                    _unit setUnitTrait ["camouflageCoef", 0, true];
                                    _unit disableAi "AIMINGERROR";
                                    _unit setVariable ["pl_engaging", true];
                                    _unit setVariable ['pl_is_at', true];
                                    pl_at_attack_array pushBack [_unit, _target, objNull];

                                    [_unit, _movePos] call pl_force_move_on_task;

                                    // sleep 0.5;
                                    // _time = time + ((_unit distance _movePos) / 1.6 + 10);
                                    // waitUntil {sleep 0.5; (time >= _time or unitReady _unit or !alive _unit or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true]) or !alive _target or (count (crew _target) == 0))};

                                    _unit reveal [_target, 2];
                                    _unit doTarget _target;
                                    _unit doFire _target;

                                    _time = time + 5;
                                    waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", false]) or !alive _target or (count (crew _target) == 0)};

                                    if (alive _target) then {_unit setVariable ['pl_is_at', false]; pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]]; continue};
                                    if !(alive _target or !alive _unit or _unit getVariable ["pl_wia", false]) then {_target setVariable ["pl_at_enaged_by", nil]};
                                    pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]];

                                    _unit setVariable ['pl_is_at', false];
                                    _unit setUnitTrait ["camouflageCoef", 1, true];
                                    _unit enableAi "AIMINGERROR";
                                    _unit setVariable ["pl_engaging", false];
                                    _unit enableAI "AUTOTARGET";
                                    _group setVariable ["pl_grp_active_at_soldier", nil];
                                } else {
                                    _target setVariable ["pl_at_enaged_by", nil];
                                };
                                sleep 1;
                            };
                        };

                        _target = ([missionNamespace getVariable format ["targets_%1", _group], [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;

                        if !(isNil "_target") then {

                            if (!(alive _target) or captive _target) then {
                                (missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target);
                                continue;
                            };
                            
                            if (alive _target and !(captive _target) and (_target isKindOf "Man")) then {
                                _movePos = (getPosATL _target) vectorAdd [0.5 - (random 1), 0.5 - (random 1), 0];

                                _unit setVariable ["pl_engaging", true];

                                private _unreachableTimeOut = time + 10;
                                if (_unit in _coverTeam) then {

                                    private _ugled = false;

                                    if (_unit getVariable ["pl_in_position", false]) then {

                                        if (_area >= 50) then {

                                            _ugled = [_unit, _target] call pl_fire_ugl_at_target;

                                            if !(_ugled) then {
                                                if (_unit == _machinegunner) then {
                                                    [_unit, selectRandom ([missionNamespace getVariable format ["targets_%1", _group], [], {([_manuverTeam] call pl_find_centroid_of_units) distance2D _x}, "DESCEND"] call BIS_fnc_sortBy), false] call pl_quick_suppress;
                                                } else {
                                                    [_unit, selectRandom ([missionNamespace getVariable format ["targets_%1", _group], [], {([_manuverTeam] call pl_find_centroid_of_units) distance2D _x}, "DESCEND"] call BIS_fnc_sortBy), true] call pl_quick_suppress;
                                                };
                                            };

                                            // if !(_unit getVariable ["pl_ated", false]) then {
                                            //     _ated = [_unit, _target] call pl_fire_AT_at_target;
                                            //     if (_ated) then {
                                            //         _unit setVariable ["pl_ated", true];
                                            //     };
                                            // };

                                            waitUntil {sleep 0.5; time >= _unreachableTimeOut or !((group _unit) getVariable ["onTask", false]) or !alive _unit or (_unit getVariable ["pl_aslt_reasses_target", false])};
                                            continue;
                                        };
                                    };

                                } else {

                                    _unit enableAI "PATH";
                                    _unit setUnitPos "AUTO";

                                    _unit doMove _movePos;

                                    _reachable = [_unit, _movePos, 20] call pl_not_reachable_escape;
                                    _unreachableTimeOut = time + 25;
                                    while {(alive _unit) and (alive _target) and !(captive _target) and ((group _unit) getVariable ["onTask", true]) and (_unreachableTimeOut >= time) and !(_unit getVariable ["pl_aslt_reasses_target", false])} do { // and _reachable
                                        _distance = _unit distance2D _target;
                                        _unit forceSpeed ([_distance] call pl_get_assault_speed);
                                        // [_unit] call pl_force_seperation;

                                        if (_distance > 35 and (random 1) > 0.5) then {
                                            _ugled = [_unit, _target] call pl_fire_ugl_at_target;

                                            // if !(_unit getVariable ["pl_ated", false]) then {
                                                // _ated = [_unit, _target] call pl_fire_AT_at_target;
                                                // if (_ated) then {
                                                //     _unit setVariable ["pl_ated", true];
                                                // };
                                            // };
                                        };

                                        if ((_target getVariable ["pl_naded", false]) and alive _target) then {
                                            _target setVariable ["pl_naded", nil];
                                        };

                                        if ((_unit distance2D _target) <= 35 and alive _target and !(_target getVariable ["pl_naded", false]) and time > (_target getVariable ["pl_nade_cd", 0]) and (random 1) > 0.5) then {

                                            sleep 0.5;

                                            _naded = [_unit, _target] call pl_throw_granade_at_target;
                                            if (_naded) then {
                                                _target setVariable ["pl_naded", true];
                                            };
                                        }; 

                                        _sleepTime = time + 4.5;
                                        waitUntil {sleep 0.5; time >= _sleepTime or !(alive _unit) or !((group _unit) getVariable ["onTask", false]) or (_unit getVariable ["pl_aslt_reasses_target", false])};

                                    };
                                    if (time >= _unreachableTimeOut) then {
                                        _target enableAI "PATH";
                                        _target doMove ((getPos _target) findEmptyPosition [10, 100, typeOf _target]);
                                    };
                                };

                                if (!(alive _target) or (captive _target)) then {(missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target)};
                            };
                        };

                        if ((!alive _unit) or !((group _unit) getVariable ["onTask", true])) exitWith {};

                    };
                };
            };
            sleep 0.15;
        } forEach (units _group);

        waitUntil {sleep 0.5; (({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _breakingPoint) or (time > _taskTime) or !(_group getVariable ["onTask", true]) or ({!alive _x or (captive _x)} count (missionNamespace getVariable format ["targets_%1", _group]) == count (missionNamespace getVariable format ["targets_%1", _group]))};
    };

    _group setVariable ["pl_is_attacking", false];
    {
        _x setVariable ["pl_damage_reduction", false];
        _x setVariable ["pl_ated", nil];
        _x limitSpeed 5000;
        _x forceSpeed -1;
    } forEach (units _group);

    _group setCombatMode "YELLOW";
    _group setVariable ["pl_combat_mode", false];
    _group enableAttack false;

    deleteMarker _markerName;
    deleteMarker _arrowMarkerName;
    deleteMarker _markerPhaselineName;
    pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
    pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
    pl_draw_text_array = pl_draw_text_array - [["SEIZE", _cords, 0.025, pl_side_color_rgb]]; 

    pl_assault_poses = pl_assault_poses - [[_cords, _group, _taskPlanWp]];

    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
        sleep 0.5;
        if (({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _breakingPoint or time > (_taskTime + 1)) then {
            if (pl_enable_beep_sound) then {playSound "radioina"};
            if (pl_enable_map_radio) then {[_group, "...Assault failed! ...Retreating", 20] call pl_map_radio_callout};
            if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault failed! ...Retreating", (groupId _group)]};

            [_group, _startPos, true, _startPos getDir _cords] spawn pl_disengage;

        } else {
            // {
            //     [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
            // } forEach (units _group);
            if ({!alive _x or (captive _x)} count (missionNamespace getVariable format ["targets_%1", _group]) == count (missionNamespace getVariable format ["targets_%1", _group])) then {
                if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault complete", (groupId _group)]};
                if (pl_enable_map_radio) then {[_group, "...Assault Complete!", 20] call pl_map_radio_callout};
                [_group, "atk_complete", 1] call pl_voice_radio_answer;

                [_group, [], _cords, _startPos getDir _cords, false, false, _area / 2] spawn pl_defend_position;

            } else {

                if (pl_enable_beep_sound) then {playSound "radioina"};
                if (pl_enable_map_radio) then {[_group, "...Assault failed!", 20] call pl_map_radio_callout};
                if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault failed", (groupId _group)]};

                [_group, [], _approachPos, _startPos getDir _cords, false, false, _area / 2] spawn pl_defend_position;
            };
            missionNamespace setVariable [format ["targets_%1", _group], nil];
        };
    };
};

