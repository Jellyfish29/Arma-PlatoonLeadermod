// pl_opfor_enhanced_ai = true;
if !(pl_opfor_enhanced_ai) exitwith {};

pl_opfor_ai_helper_debug = {
	params ["_grp"];

    _color = '#(argb,8,8,3)color(1,1,1,1)';
	_leaderPos = getPosATLVisual (leader _grp) vectorAdd [0,0,2];
    _helper1 = createVehicle ["Sign_Sphere25cm_F", _leaderPos, [], 0, "none"];
    _helper1 setposATL _leaderPos;

	while {True} do {
	    switch (_grp getVariable ["pl_opf_task", "none"]) do { 
	    	case "none" : {_color = '#(argb,8,8,3)color(1,1,1,1)'}; 
	    	case "cover" : {_color = '#(argb,8,8,3)color(0,0,1,1)'};
	    	case "suppress" : {_color = '#(argb,8,8,3)color(1,0.5,0,1)'}; 
	    	case "advance" : {_color = '#(argb,8,8,3)color(0,1,0,1)'}; 
	    	case "assault" : {_color = '#(argb,8,8,3)color(1,0,0,1)'}; 
	    	default {_color = '#(argb,8,8,3)color(1,1,1,1)'}; 
	    };
		_leaderPos = getPosATLVisual (leader _grp) vectorAdd [0,0,2];
		_helper1 setposATL _leaderPos;
    	_helper1 setObjectTexture [0, _color];
		sleep 0.5;
	};
};

pl_opfor_reset = {
	params ["_grp"];

    [_grp, (currentWaypoint _grp)] setWaypointType "MOVE";
    [_grp, (currentWaypoint _grp)] setWaypointPosition [getPosASL (leader _grp), -1];
    sleep 0.1;
    deleteWaypoint [_grp, (currentWaypoint _grp)];
    for "_i" from count waypoints _grp - 1 to 0 step -1 do {
        deleteWaypoint [_grp, _i];
    };
    _leader = leader _grp;
    (units _grp) joinSilent _grp;
    _grp selectLeader _leader;
};

pl_opfor_find_cover = {
    params ["_unit", "_watchPos", "_watchDir", "_radius", "_moveBehind", ["_fullCover", false], ["_inArea", ""], ["_fofScan", false]];
    private ["_valid"];

    _covers = nearestTerrainObjects [getPos _unit, pl_valid_covers, _radius, true, true];
    _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _watchPos;
    if ((count _covers) > 0) then {
        {

            if !(_x in pl_covers) exitWith {
                pl_covers pushBack _x;
                _coverPos = getPos _x;
                _unit doMove _coverPos;
                sleep 0.5;
                waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["pl_opf_task", "cover"] == "cover") or unitReady _unit};
                if ((group _unit) getVariable ["pl_opf_task", "cover"] == "cover") then {
                    if ((group _unit) getVariable ["onTask", true]) then {
                        _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
                        _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
                        _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
                        if (_visP isEqualTo []) then {
                            _unit setUnitPos "DOWN";
                        } else {
                            _unit setUnitPos "MIDDLE";
                        };

                        doStop _unit;
                        _unit doWatch _watchPos;
                        _unit disableAI "PATH";
                    };
                    [_x] spawn {
                        params ["_cover"];
                        sleep 5;
                        pl_covers deleteAt (pl_covers find _cover);
                    };
                };
            };
        } forEach _covers;

        if ((unitPos _unit) == "Auto" and ((group _unit) getVariable ["pl_opf_task", "cover"] == "cover")) then {
            _unit setUnitPos "DOWN";
            doStop _unit;
            _unit doWatch _watchPos;
            _unit disableAI "PATH";
        };
    }
    else
    {
        _pronePos = [getPos _unit, 0.2] call pl_convert_to_heigth_ASL;
        _checkPos = [(getPos _unit) getPos [25, _watchDir], 1] call pl_convert_to_heigth_ASL;
        _visP = lineIntersectsSurfaces [_pronePos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];
        if (_visP isEqualTo []) then {
            _unit setUnitPos "DOWN";
        } else {
            _unit setUnitPos "MIDDLE";
        };
        doStop _unit;
        _unit doWatch _watchPos;
        _unit disableAI "PATH";
    };
};

pl_opfor_advance = {
	params ["_grp"];

	if (behaviour (leader _grp) != "SAFE") then {
		{
			_x disableAI "AUTOCOMBAT";
			_x enableAI "PATH";
			_x enableAI "AUTOTARGET";
			_x enableAI "TARGET";
			_x setBehaviour "AWARE";
			_x setUnitPos "AUTO";
			if !(_x == leader _grp) then {
				_x doFollow (leader _grp);
			} else {
				_x doMove (waypointPosition ((waypoints _grp) select (currentWaypoint _grp)));
				_x playActionNow "GestureAdvance";
				_x forceSpeed 4;
			};
		} forEach (units _grp);
		_grp setBehaviour "AWARE";
		_grp setFormation "LINE";
		_grp setSpeedMode "NORMAL";
		_grp allowFleeing 0.2;
		
	};
};

pl_opfor_panic_cover = {
	params ["_grp"];

	(leader _grp) playActionNow "gestureFreeze";
	_grp setBehaviour "COMBAT";
	{
		_x forceSpeed -1;
	 	[_x, getPos _x, getDir _x, 10, false] spawn pl_opfor_find_cover;
	} forEach (units _grp);
};

pl_opfor_line_cover_static = {
	params ["_grp"];
		
	[_grp, getDir (leader _grp)] call pl_opfor_form_line;
};


pl_opfor_dynamic_cover = {
	params ["_grp"];

	[_grp] spawn pl_opfor_reset;
	private _targets = ((getPos (leader _grp)) nearEntities [["Man"], 600]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0};
	private _targetDir = getDir (leader _grp);
	if (count _targets > 0) then {
		_target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
		_targetDir = (leader _grp) getDir _target; 
	};
	_grp setSpeedMode "FULL";
	_grp setBehaviour "AWARE";
	(leader _grp) playActionNow "GestureCover";
	if ([getPos (leader _grp)] call pl_is_city) then {
		{
			[_x, _movePos, _watchDir, 20, false] spawn pl_opfor_find_cover;
		} forEach (units _grp);
	} else {
		[_grp, _targetDir] call pl_opfor_form_line;
	};
};


pl_opfor_form_line = {
	params ["_grp", "_dir", ["_startPos", []], ["_mode", "cover"]];

	private _lineSpacing = 9;
	if (_startPos isEqualTo []) then {
		private _targets = (((getPos (leader _grp)) nearEntities [["Man"], 600]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0});
		if (count _targets > 0) then {
			private _target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
			_units = units _grp;
			_startPos = getPos (([_units, [], {_target distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0);
		} else {
			_startPos = getPos (leader _grp);
		};
	};
    private _posArray = [];

    private _offSet = 0;
    private _moveDir = 0;
    for "_i" from 0 to ((count (units _grp))- 1) do {
        if ((_i % 2) != 0) then {
            _offSet = _offSet + _lineSpacing;
            _moveDir = _dir - 90;
        } else {
            _moveDir = _dir + 90;
        };
        _movePos = _startPos getPos [_offSet, _moveDir];
        _posArray pushBack _movePos;

        // _m = createMarker [str (random 1), _movePos];
        // _m setMarkerType "mil_dot";
	};

	{
		_unit = _x;
	 	_movePos = ([_posArray, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
	 	_posArray deleteAt (_posArray find _movePos);
	 	[_unit, _movePos, _dir, _mode] spawn {
            params ["_unit", "_movePos", "_watchDir", "_mode"];
            doStop _unit;
            _unit enableAI "PATH";
            _unit forceSpeed -1;
            _unit setUnitPos "AUTO";
            _unit disableAI "AUTOCOMBAT";
            if (_mode == "cover") then {
	            _unit disableAI "AUTOTARGET";
	            _unit disableAI "TARGET";
	        };
            _unit doMove _movePos;
            _unit setDestination [_movePos, "FORMATION PLANNED", false];
            sleep 1;
            waitUntil {sleep 0.5; (!alive _unit) or [_unit, _movePos] call pl_position_reached_check or ((group _unit) getVariable ["pl_opf_task", "cover"] != _mode)};
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "TARGET";
            if ((group _unit) getVariable ["pl_opf_task", "cover"] == "cover") then {
            	[_unit, _movePos, _watchDir, 7, false] spawn pl_opfor_find_cover;
            };
        };
	} forEach (units _grp);
};


// suppress
pl_opfor_suppress = {
	params ["_grp"];

	// _targets = ((nearestObjects [getPos (leader _grp), ["Man"], 400, true]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 1});
	_targets = (((getPos (leader _grp)) nearEntities [["Man"], 700]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0});
	_targets = [_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;
	_targetGroupUnits = units (group (_targets#0));
	private _targetsPos= [];

	{
		_targetsPos pushBack (getPosATL _x);
		_targetsPos pushBack( [[[(getPosATL _x), 15]], nil] call BIS_fnc_randomPos);
	} forEach _targetGroupUnits;

	if !(_targetsPos isEqualTo []) then {

		{
			_unit = _x;
			private _pos = selectRandom _targetsPos;
	        _pos = ATLToASL _pos;
			_vis = lineIntersectsSurfaces [eyePos _unit, _pos, _unit, vehicle _unit, true, 1];
	        if !(_vis isEqualTo []) then {
	            _pos = (_vis select 0) select 0;
	        };
	        if ((_pos distance2D _unit) > pl_suppression_min_distance) then {
	        	_unit doSuppressiveFire _pos;
	        };
		} forEach (units _grp);
	};

};


pl_opfor_assault = {
	params ["_grp"];

	_targets = (((getPos (leader _grp)) nearEntities [["Man"], 500]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0});
	_target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
	_targetGroupUnits = units (group _target);
	_targetPos = getPos _target;
	_grp addWaypoint [_targetPos, 0];
	_grp setVariable ["pl_opfor_flee_pos", getPosAsl (leader _grp)];
	_grp allowFleeing 0.3;
	(leader _grp) playActionNow "GestureAttack";

	if !([_targetPos] call pl_is_city) then {
		[_grp, (leader _grp) getDir _targetPos, _targetPos, "assault"] call pl_opfor_form_line;
	} else {
		// _grp setFormation "DIAMOND";
		{
			_x enableAI "PATH";
			_x enableAI "AUTOCOMBAT";
			_x setUnitPos "AUTO";
			_x forceSpeed -1;
			_target = selectRandom _targetGroupUnits;
            _pos = getPosATL _target;
            _movePos = _pos vectorAdd [0.5 - (random 1), 0.5 - (random 1), 0];
            _x limitSpeed 15;
            _x doMove _movePos;
            _x setDestination [_movePos, "FORMATION PLANNED", false];
            _x lookAt _target;
            _x doTarget _target;
            _reachable = [_x, _movePos, 20] spawn pl_not_reachable_escape;

		} forEach (units _grp);
	};


	_targetPos
};

pl_opfor_flanking_move = {
	params ["_grp"];
	private ["_fankPos"];

	
	private _targets = (((getPos (leader _grp)) nearEntities [["Man"], 800]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0});
	_flankPos = getPos (leader _grp);
	if !(_targets isEqualto []) then {
		private _target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
		private _targetPos = getPos _target;
		private _targetDir = (leader _grp) getDir _targetPos;
		private _flankDistance = ((leader _grp) distance2D _targetPos) * 0.7;
		_leftPos = (getPos (leader _grp)) getPos [_flankDistance, _targetDir + 90];
		_rightPos = (getPos (leader _grp)) getPos [_flankDistance, _targetDir - 90];

		_flankPos = ([[_leftPos, _rightPos], [], {count (_x nearEntities [["Man"], 350])}, "ASCEND"] call BIS_fnc_sortBy)#0;

		// _flankPos = (getPos (leader _grp)) getPos [_flankDistance, _targetDir + (selectRandom [90, -90])];

		[_grp, _flankPos, _flankDistance, _targetDir, _targetPos] spawn {
			params ["_grp", "_flankPos", "_flankDistance", "_targetDir", "_targetPos"];

			[_grp] call pl_opfor_reset;
			sleep 0.2;

			// _grp allowFleeing 0;
			_grp addWaypoint [_flankPos, 0];
			_grp addWaypoint [_flankPos getPos [_flankDistance, _targetDir], 0];
			_grp addWaypoint [_targetPos, 0];
			{
				_x disableAI "AUTOCOMBAT";
				_x enableAI "PATH";
				_x enableAI "AUTOTARGET";
				_x enableAI "TARGET";
				_x setBehaviour "AWARE";
				_x setUnitPos "AUTO";
				_x forceSpeed -1;
				if !(_x == leader _grp) then {
					_x doFollow (leader _grp);
				} else {
					_x doMove _flankPos;
					_x playActionNow "GestureAdvance";
				};
			} forEach (units _grp);
			_grp allowFleeing 0;
			_grp setBehaviour "AWARE";
			_grp setFormation "COLUMN";
			_grp setSpeedMode "FULL";
		};
	};
	_flankPos
};

pl_opfor_cqb = {
	params ["_grp"];
	{
		_x enableAI "AUTOCOMBAT";
		_x setBehaviour "COMBAT";
		_x setUnitPos "AUTO";
		_x doFollow (leader _grp);
	} forEach (units _grp);
};


pl_opfor_attack_closest_enemy = {
	params ["_grp"];
	
	[_grp] spawn {
		params ["_grp"];

	    _units = allUnits select {side _x == playerSide and alive _x};
	    _units = [_units, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy;
	    _atkPos = getPos (_units#0);

	    [_grp, (currentWaypoint _grp)] setWaypointType "MOVE";
	    [_grp, (currentWaypoint _grp)] setWaypointPosition [getPosASL (leader _grp), -1];
	    sleep 0.1;
	    deleteWaypoint [_grp, (currentWaypoint _grp)];
	    for "_i" from count waypoints _grp - 1 to 0 step -1 do {
	        deleteWaypoint [_grp, _i];
	    };

	    _wp = _grp addWaypoint [_atkPos, 20];
	    _wp setWaypointType "SAD";
	};
};


pl_opfor_create_marker = {
	params ["_grp", "_type", "_pos", "_dir", "_color"];

	private _targets = (((getPos (leader _grp)) nearEntities [["Man"], 800]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0});
	private _target = ([_targets, [], {(leader _grp) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
	private _targetPos = getPos _target;
	private _targetDir = (leader _grp) getDir _targetPos;

	_markerName = _grp getVariable "pl_opfor_marker_Name";
     createMarker [_markerName, _pos];
    _markerName setMarkerType _type;
    _markerName setMarkerColor _color;
    _markerName setMarkerDir _targetDir;

};

pl_opfor_join_group = {
	params ["_grp"];

	_grps = allgroups select {(side _x) isEqualTo (side (leader _grp))};
	if !(_grps isEqualTo []) exitWith {
		_targetGrp = ([_grps, [], {(leader _grp) distance2D (leader _x)}, "ASCEND"] call BIS_fnc_sortBy)#0;
		{
			[_x] joinSilent _targetGrp;
			_x doFollow (leader _targetGrp);
		} forEach (units _grp);
		true
	};
	false
};

// hint "oof";
// count ((units _grp) select {getSuppression _x > 0.6}) > 1;

// {
// 	if (leader _x == vehicle (leader _x)) then {
// 		_x execFSM "pl_opfor_cmd_test.fsm";
// 	};
// } forEach (allGroups select {side _x == east});

