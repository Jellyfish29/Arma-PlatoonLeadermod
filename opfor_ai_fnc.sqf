pl_enable_enhanced_ai_behaviour = true;
if !(pl_enable_enhanced_ai_behaviour) exitwith {};

pl_opfor_ai_helper_debug = {
	params ["_grp", "_color"];

	_leaderPos = getPosATLVisual (leader _grp) vectorAdd [0,0,2];
    _helper1 = createVehicle ["Sign_Sphere25cm_F", _leaderPos, [], 0, "none"];
    _helper1 setObjectTexture [0, _color];
    _helper1 setposATL _leaderPos;

	while {True} do {
		_leaderPos = getPosATLVisual (leader _grp) vectorAdd [0,0,2];
		_helper1 setposATL _leaderPos;
		sleep 0.5;
	};
};

// find Cover when Suppressed
pl_opfor_task_take_cover = {
	params ["_grp"];

	private _r = false;
	private _treshhold = (count (units _grp)) * 0.25;
	private _grpSuppression = 0;
	{
	 	_grpSuppression = _grpSuppression + (getSuppression _x);
	} forEach (units _grp);

	_oldAlive = _grp getVariable ["pl_opfor_alive_count", count (units _grp)];
	_newAlive = count ((units _grp) select {alive _x});
	if (_grpSuppression >= _treshhold or (_oldAlive - _newAlive) >= 2) then {
		_r = true;
		// leader _grp playActionNow "GestureCover";
		// leader _grp groupRadio "SentCmdHide";
		[_grp, '#(argb,8,8,3)color(0,0,1,1)'] spawn pl_opfor_ai_helper_debug;

		player sideChat "cover";
		{
			_x enableAI "AUTOCOMBAT";
			if (_x checkAIFeature "PATH") then {
		 		[_x, getPos _x, getDir _x, 20, false] spawn pl_find_cover;
		 	};
		} forEach (units _grp);
	};
	_r
};

// attack
pl_opfor_task_attack_open = {
	params ["_grp"];

	if ([getPos (leader _grp)] call pl_is_city) exitWith {false};

	private _r = false;
    if ((currentWaypoint _grp) < count (waypoints _grp)) then {
   		_wp = waypointPosition ((waypoints _grp) select (currentWaypoint _grp));
   		_distance = _wp distance2D (leader _grp);

   		if (_distance > 200 and (behaviour (leader _grp)) == "COMBAT") then {
			_grp setBehaviour "AWARE";
	    	_grp setSpeedMode "FULL";
	        _grp setFormation "VEE";
   			_r = true;
   			player sideChat "advance";
   			[_grp, '#(argb,8,8,3)color(0,1,0,1)'] spawn pl_opfor_ai_helper_debug;
   			{
   				_unit = _x;
	            _unit disableAI "AUTOCOMBAT";
	            _unit enableAI "PATH";
	            _unit setUnitPos "UP";
	            // _unit doMove (waypointPosition _wp);
        	} forEach (units _grp);
   		};

    	_targets = ((nearestObjects [getPos (leader _grp), ["Man", "Car", "Tank"], 100, true]) select {side _x == playerSide});

   		if ((count _targets) > 0) then {
   			_grp setBehaviour "COMBAT";
   			{
   				_x enableAI "PATH";
   				_x enableAI "AUTOCOMBAT";
   				_x setUnitPos "AUTO";
   				_x doMove getPos (selectRandom _targets);
   			} forEach (units _grp);	
   		};
   	};
   	_r
};


// retreat
pl_opfor_task_retreat = {
	params ["_grp"];
};

// suppress
pl_opfor_task_suppress = {
	params ["_grp"];
};



pl_opfor_task_main_loop = {
	sleep 2;

	while {True} do {

		sleep 10;
		{
			_grp = _x;
			if (vehicle (leader _grp) == leader _grp) then {
				_cover = [_grp] call pl_opfor_task_take_cover;
				sleep 4;
				if !(_cover) then {
					[_grp] call pl_opfor_task_attack_open;
				};
				_grp setVariable ["pl_opfor_alive_count", count ((units _grp) select {alive _x})];
			};
		} forEach (allGroups select {(side _x) != playerSide});

	};
};

[] spawn pl_opfor_task_main_loop;


// chance for ai to get wounded
pl_opfor_get_wounded = {
	params ["_grp"]	;
};