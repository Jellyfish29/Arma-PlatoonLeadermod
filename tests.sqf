
pl_get_vistool_poly = {
	params [["_start", []], ["_range", 2000], ["_accuracy", 2], ["_heightOver", 2], ["_ignoreObj", objNull]];
	private ["_end", "_lastVis"];

	if (_start isEqualTo []) then {
		_mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
	 	_start = [_mPos#0, _mPos#1, _heightOver];
	} else {
		_start = [_start#0,_start#1,_heightOver];
	};

	_start = ATLToASL _start;
	private _linePath = [];
	private _j = 0;

	// for "_i" from 0 to 719 step 0.5 do {
	for "_i" from 0 to 359 step _accuracy do {
		_end = _start vectorAdd [(sin _i) * _range, (cos _i) * _range, 0];
		// _end = _start getPos [2000, _i] vectorAdd [0,0,5];
		_vis = (lineIntersectsSurfaces [_start, _end, _ignoreObj, _ignoreObj, true, 1, "GEOM", "FIRE"]);

		if !(_vis isEqualTo []) then {
			_lastVis = _vis;
			_j = 0;
			while {_j < 30} do {
				_end = _end vectorAdd [100, 100, 5];
				_vis = (lineIntersectsSurfaces [_start, _end, _ignoreObj, _ignoreObj, true, 1, "GEOM", "FIRE"]);
				if (_vis isEqualTo []) exitWith {
					_linePath pushBack (_lastVis#0#0#0);
					_linePath pushBack (_lastVis#0#0#1);
				};
				_j = _j + 1;
				_lastVis = _vis;
			};

			if (_j >= 30) then {
				_linePath pushBack (_vis#0#0#0);
				_linePath pushBack (_vis#0#0#1);
			};
		} else {
			_linePath pushBack _end#0;
			_linePath pushBack _end#1;
		};
	};
	// sleep 0.2;
	_linePath
};


pl_get_vistool_pos = {
	params [["_start", []], ["_range", 2000], ["_accuracy", 2], ["_heightOver", 2], ["_ignoreObj", objNull]];
	private ["_end", "_lastVis"];

	if (_start isEqualTo []) then {
		_mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
	 	_start = [_mPos#0, _mPos#1, _heightOver];
	} else {
		_start = [_start#0,_start#1,_heightOver];
	};

	_start = ATLToASL _start;
	private _linePath = [];
	private _j = 0;

	// for "_i" from 0 to 719 step 0.5 do {
	for "_i" from 0 to 359 step _accuracy do {
		_end = _start vectorAdd [(sin _i) * _range, (cos _i) * _range, 0];
		// _end = _start getPos [2000, _i] vectorAdd [0,0,5];
		_vis = (lineIntersectsSurfaces [_start, _end, _ignoreObj, _ignoreObj, true, 1, "GEOM", "FIRE"]);

		if !(_vis isEqualTo []) then {
			_lastVis = _vis;
			_j = 0;
			while {_j < 30} do {
				_end = _end vectorAdd [100, 100, 5];
				_vis = (lineIntersectsSurfaces [_start, _end, _ignoreObj, _ignoreObj, true, 1, "GEOM", "FIRE"]);
				if (_vis isEqualTo []) exitWith {
					_linePath pushBack (_lastVis#0#0);
				};
				_j = _j + 1;
				_lastVis = _vis;
			};

			if (_j >= 30) then {
				_linePath pushBack (_vis#0#0);
			};
		} else {
			_linePath pushBack _end;
		};
	};
	// sleep 0.2;
	_linePath
};

pl_vision_tool_enabled = false;

pl_vision_tool = {
	private ["_lineLMarker", "_linePath"];

	if (pl_vision_tool_enabled) exitwith {pl_vision_tool_enabled = false};

	pl_vision_tool_enabled = true;

	// while {pl_vision_tool_enabled} do {

	// 	_linePath = [] call pl_get_intersects;
	// 	_lineMarker = createMarker [str (random 3), [0,0,0]];
	// 	_lineMarker setMarkerShape "POLYLINE";
	// 	_lineMarker setMarkerPolyline _linePath;
	// 	_lineMarker setMarkerColor "colorGreen";

	// 	sleep 0.25;
	// 	deleteMarker _lineMarker;


	// };
};


pl_draw_vision_tool = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_vision_tool_enabled) then {
	        _path = [] call pl_get_vistool_pos;
	        for '_i' from -1 to (count _path) - 2 step 1 do {
                _display drawLine [
                    _path#_i,
                    _path#(_i+1),
                    [0.92,0.24,0.07,1],
                    6
                ];
	        };
        };
    "]; // "
};

[findDisplay 12 displayCtrl 51] call pl_draw_vision_tool;


pl_isPointInPolygon = {
    params ["_point", "_polygon"];
    
    private _x = _point select 0;
    private _y = _point select 1;
    private _inside = false;
    
    private _n = count _polygon;
    private _j = _n - 1;
    
    for "_i" from 0 to (_n - 1) do {
        private _xi = (_polygon select _i) select 0;
        private _yi = (_polygon select _i) select 1;
        private _xj = (_polygon select _j) select 0;
        private _yj = (_polygon select _j) select 1;
        
        if ((_yi < _y && _yj >= _y) || (_yj < _y && _yi >= _y)) then {
            private _x_intersect = _xi + (_y - _yi) / (_yj - _yi) * (_xj - _xi);
            if (_x_intersect < _x) then {
                _inside = !_inside;
            };
        };
        _j = _i;
    };

    _inside
};

// [getPos player, pl_polygon] call isPointInPolygon;




pl_recon = {
    params [["_group", (hcSelected player) select 0],["_preSet", false]];
    private ["_group", "_markerName", "_intelInterval", "_intelMarkers", "_wp", "_leader", "_distance", "_pos", "_dir", "_markerNameArrow", "_markerNameGroup", "_posOccupied"];

    if (_group == (group player)) exitWith {hint "Player group can´t be designated as Recon Group!";};

    if (pl_recon_count >= 2) exitWith {hint "Only THREE Groups can be designated as Recon";};

    _group setVariable ["pl_is_recon", true];
    if !(_preSet) then {pl_recon_count = pl_recon_count + 1; if (pl_enable_beep_sound) then {playSound "beep"}};

    private _size = "s";
    if ((count (units _group)) < 6) then {_size = "t"};

    if (vehicle (leader _group) != leader _group) then {
        if !((leader _group) == commander (vehicle (leader _group)) or (leader _group) == driver (vehicle (leader _group)) or (leader _group) == gunner (vehicle (leader _group))) then {
            [_group, format ["f_%1_recon_pl", _size]] call pl_change_group_icon;
            [_group] call pl_hide_group_icon;
        };
    } else {
        [_group, format ["f_%1_recon_pl", _size]] call pl_change_group_icon;
    }; 
    _group setVariable ["pl_recon_area_size", pl_recon_area_size_default];

    _intelInterval = 30;

    sleep 0.5;

    _markerName = createMarker [format ["reconArea%1", _group], getPos (leader _group)];
    _markerName setMarkerColor "colorBlue";
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Border";
    _markerName setMarkerAlpha 0.3;
    _markerName setMarkerSize [pl_recon_area_size_default, pl_recon_area_size_default];
    pl_active_recon_groups pushBack _group;

    sleep 1;

    _intelMarkers = [];

    // check if group is moving --> change area size + force stealth
    [_group, _markerName] spawn {
        params ["_group", "_markerName"];

        private _airBonus = 0;

        if (vehicle (leader _group) isKindOf "AIR") then {_airBonus = 500};

        while {_group getVariable ["pl_is_recon", false]} do {
            _bonus = 0 + _airBonus;
            _markerName setMarkerPos (getPos (leader _group));
            if !(((currentWaypoint _group) < count (waypoints _group))) then {
                _bonus = 400;
                // Get height of Group and compare to average sorrounding Height to get Bounus Vision Range
                _height = getTerrainHeightASL (getPos (leader _group));
                _interval = 12;
                _diff = 360 / _interval;
                _avHeight = 0;
                // check _interval test location 350m around group and calc average terrain height
                for "_i" from 0 to _interval do {
                    _degree = 1 + _i * _diff;
                    _checkPos = [350 * (sin _degree), 350 * (cos _degree), 0] vectorAdd (getPos leader _group);
                    _checkheight = getTerrainHeightASL _checkPos;
                    _avHeight = _avHeight + _checkheight;
                };
                _reconHeight = _height - (_avHeight / _interval);
                // hintSilent str _reconHeight;
                // if negativ Height no Bonus Range
                if (_reconHeight <= 0) then {_reconHeight = 0};

                // Set Bonus Range
                _group setVariable ["pl_recon_area_size", pl_recon_area_size_default + (_reconHeight * 20) + _bonus];
            } else {
                _group setVariable ["pl_recon_area_size", pl_recon_area_size_default];
            };
            _h = _group getVariable "pl_recon_area_size";
            _markerName setMarkerSize [_h, _h];
            // if (({alive _x} count (units _group)) <= 0) exitWith {};
            if (isNull _group) exitWith {};
                
            sleep 1;
        };
        _group setVariable ["pl_recon_area_size", nil];
    };

    _reconGrpLeader = leader _group;

    // short delay
    sleep 5;

    private _lineMarker = "";

    // recon logic
    while {sleep 0.5; _group getVariable ["pl_is_recon", false]} do {
        
        _reconLOSPolygon = [ASLToATL ([_group] call pl_find_centroid_of_group), _group getVariable ["pl_recon_area_size", 1400], 4, 4, leader _group] call pl_get_vistool_pos;

        pl_recon_los_polys pushBack _reconLOSPolygon;

        {
            _opfGrp = _x;
            _leader = leader _opfGrp;

            if ([getPosASL (leader _opfGrp), _reconLOSPolygon] call pl_isPointInPolygon) then {
                private _reveal = false;
                if ((_reconGrpLeader knowsAbout _leader) > 0.105) then {_reveal = true};
                [_opfGrp, _reveal, false, _group] call Pl_marta;
            };
        } forEach (allGroups select {([(side _x), playerside] call BIS_fnc_sideIsEnemy) and alive (leader _x)});

        _time = time + _intelInterval;
        waitUntil {sleep 1; time >= _time or !(_group getVariable ["pl_is_recon", false])};

        pl_recon_los_polys = pl_recon_los_polys - [_reconLOSPolygon];

        if !(alive (leader _group)) exitWith {_group setVariable ["pl_is_recon", false]; pl_recon_count = pl_recon_count - 1};

    };

    pl_recon_count = pl_recon_count - 1;
    deleteMarker _markerName;
    pl_active_recon_groups = pl_active_recon_groups - [_group];
    _group setVariable ["MARTA_customIcon", nil];
};

pl_recon_los_polys = [];

pl_draw_recon_LOS = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        {
	        for '_i' from -1 to (count _x) - 2 step 1 do {
                _display drawLine [
                    _x#_i,
                    _x#(_i+1),
                    pl_side_color_rgb,
                    2
                ];
	        };
        } forEach pl_recon_los_polys;
    "]; // "
};

[findDisplay 12 displayCtrl 51] call pl_draw_recon_LOS;
