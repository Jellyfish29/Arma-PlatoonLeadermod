pl_mc_lc = {
	// _motor = "Land_RotorCoversBag_01_F" createVehicle [0,0,0];
	params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
	private ["_cords", "_watchDir", "_mPos", "_launchPos", "_markerNameLaunchPos"];

	if (vehicle (leader _group) == (leader _group)) exitWith {hint "Vehicle Only Task!"};

	private _engVic = vehicle (leader _group);

	if ((!(_engVic isKindOf "Tank") or !(_engVic getVariable ["pl_is_repair_vehicle", false])) and !(_engVic getVariable ["pl_is_mc_lc_vehicle", false])) exitWith {hint "Requires Engineering Tank"};


	if !(visibleMap) then {
        if (isNull findDisplay 2000) then {
            [leader _group] call pl_open_tac_forced;
        };
    };

    private _markerName = format ["%1mineSweepe%2", _group, random 3];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "RECTANGLE";
    _markerName setMarkerBrush "SolidBorder";;
    _markerName setMarkerColor "colorGreen";
    _markerName setMarkerAlpha 0.5;
    _markerName setMarkerSize [40, 40 * 0.25];

    private _rangelimiter = 100;

    private _markerBorderName = str (random 2);
    private _borderMarkerPos = getPos (leader _group);
    if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
    createMarker [_markerBorderName, _borderMarkerPos];
    _markerBorderName setMarkerShape "ELLIPSE";
    _markerBorderName setMarkerBrush "Border";
    _markerBorderName setMarkerColor "colorORANGE";
    _markerBorderName setMarkerAlpha 0.8;
    _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

    _markerNameLaunchPos = format ["%1_mclc_launch%2", _group, random 3];
    createMarker [_markerNameLaunchPos, [0,0,0]];
    _markerNameLaunchPos setMarkerColor "colorGreen";
    _markerNameLaunchPos setMarkerType "mil_start";
    _markerNameLaunchPos setMarkerSize [0.5, 0.5];

    _message = "Select Search Area <br /><br />
    <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
    hint parseText _message;
    onMapSingleClick {
        pl_sweep_cords = _pos;
        if (_shift) then {pl_cancel_strike = true};
        pl_mapClicked = true;
        hintSilent "";
        onMapSingleClick "";
    };

    player enableSimulation false;

    while {!pl_mapClicked} do {
        // sleep 0.1;
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
            _markerName setMarkerPos _mPos;
        };
    };

    // player enableSimulation true;
    pl_mapClicked = false;
    _cords = getMarkerPos _markerName;

    onMapSingleClick {
        pl_mapClicked = true;
        if (_shift) then {pl_cancel_strike = true};
        // if (_alt) then {pl_mine_type = "APERSBoundingMine"};
        onMapSingleClick "";
    };

    while {!pl_mapClicked} do {
        if (visibleMap) then {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        } else {
            _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
        };
        _watchDir = _cords getdir _mPos;
        _markerName setMarkerDir (_watchDir + 90);
        _launchPos = _cords getPos [50, _watchDir - 180];
        _markerNameLaunchPos setMarkerPos _launchPos;

    };

    player enableSimulation true;

    pl_mapClicked = false;
    _markerName setMarkerAlpha 0.3;
    deleteMarker _markerBorderName;

    if (pl_cancel_strike) exitwith {pl_cancel_strike = false; deleteMarker _markerName; deleteMarker _markerNameLaunchPos};

    private _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa";

    if (count _taskPlanWp != 0) then {

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; deleteMarker _markerNameLaunchPos};

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"];


    [_engVic, _launchPos] call pl_vic_advance_to_pos_static;

    sleep 0.5;

    [_engVic, _cords] call pl_vic_turn_in_place;

    _time = time + 6;

    waitUntil {sleep 0.5; time >= _time or !alive _engVic or !(_group getVariable ["onTask", false])};

    deleteMarker _markerNameLaunchPos;
    if (!(_group getVariable ["onTask", false]) or !alive _engVic) exitWith {deleteMarker _markerName;};

	_motor = "Land_Sleeping_bag_folded_F" createVehicle [0,0,0];
	_motor attachTo [_engVic, [0,0,1]];
	_target = (getPos _engVic) getPos [300, getDir _engVic];

	_vel = [_engVic, _target, 60] call pl_THROW_VEL;

	detach _motor;
	_rope = ropeCreate [_engVic, [0,0,0], _motor, [0,0,0], 200];

	_motor setVelocity _vel;
	_smoke = "#particlesource" createVehicle [0,0,0];
	_smoke setParticleClass "missile1";
	_smoke attachTo [_motor,[0,0,0.5]];
	playSound3D ["A3\Sounds_F\weapons\Rockets\missile_1.wss", _engVic];

	[_group] call pl_reset;

	sleep 2;

	// eng_vic_1 ropeDetach _rope;
	deleteVehicle _smoke;

	sleep 5;

	while { ropeLength _rope > 20} do
    {
       _ends = ropeEndPosition _rope;
      if (((_ends select 1) distance2d _engVic) > 15) then {
	      _charge = createMine ["SatchelCharge_F", _ends select 1, [], 0];
	      _charge setDamage 1;
	  };
        ropeCut [_rope,ropeLength _rope-10];
        sleep 0.0002;
    };
    ropeDestroy _rope;
    deleteVehicle _motor;

	_markerName setMarkerBrush "Cross";
	_markerName setMarkerColor "colorGreen";
	_markerName setMarkerText "CLR";
	pl_engineering_markers pushBack _markerName;
};

// [] spawn pl_mc_lc;

