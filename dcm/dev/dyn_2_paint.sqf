pl_draw_scenario = {
	params ["_locPos", "_playerStart", "_allBuildings"];

	// private _locPos = getPos _loc;
	_playerDir = _locPos getDir _playerStart;
	private _allLocs = +dyn2_all_towns;
	// _allLocs = _allLocs - [_loc];
	private _steps = 20;
	private _interval = (worldSize / _steps) / 2 ;


	{
		private _alliedLocs = [];
		private _drawPathL = [];
		private _drawPathR = []; 
		for "_i" from 0 to _steps do {

			_checkPos1 = _locPos getPos [_interval * _i, _playerDir + _x];

			if ([_checkPos1] call dyn2_is_water) exitWith {_alliedLocs pushBackUnique _checkPos1};

		 	// _m = createMarker [str (random 5), _checkPos1];
		 	// _m setMarkerType "mil_circle";

		 	private _locs = nearestLocations [_checkPos1, ["NameCity", "NameVillage", "NameCityCapital"], _interval];
		 	if !(_locs isEqualTo []) then {
		 		if (!((_locs#0) in _alliedLocs) and ((getpos (_locs#0)) distance2D _locPos) > 3000) then {
		 			_unitMarker = createMarker [str (random 5), getPos (_locs#0)];
		 			_unitMarker setMarkerType (selectRandom ["b_p_inf_pl", "b_c_inf_pl", "b_p_mech_pl"]);
		 			// _unitMarker setMarkerColor "colorBLUFOR";

		 			_unitMarker = createMarker [str (random 5), (getPos (_locs#0)) getpos [800, _playerDir - 180]];
		 			_unitMarker setMarkerType (selectRandom ["o_c_inf_pl", "o_p_mech_pl"]);
		 		};
		 		_alliedLocs pushBackUnique (getPos (_locs#0));
		 	} else {
		 		if ((random 1) > 0.6 and (_checkPos1 distance2D _locPos) > 2000) then {
		 			_unitMarker = createMarker [str (random 5), _checkPos1];
		 			_unitMarker setMarkerType "b_f_s_recon_pl";
		 			_unitMarker setMarkerSize [0.5, 0.5];

		 			if ((random 1) > 0.6) then {
			 			_unitMarker = createMarker [str (random 5), _checkPos1 getpos [800, _playerDir - 180]];
			 			_unitMarker setMarkerType (selectRandom ["o_c_inf_pl", "o_p_mech_pl"]);
			 		};
		 		};
		 		_alliedLocs pushBackUnique _checkPos1;
		 	};
		};

		_alliedLocs deleteAt 0;

		{
	 		_dP1 = _x getPos [[300, 450] call BIS_fnc_randomInt, _playerDir - 180];
	 		_dP2 = _dp1 getPos [[150, 200] call BIS_fnc_randomInt, _playerDir];
	 		_drawPathL pushBack _dP1#0;
	 		_drawPathL pushBack _dP1#1;

	 		_drawPathR pushBack _dP2#0;
	 		_drawPathR pushBack _dP2#1;

		} forEach _alliedLocs;


		if ((count _drawPathL) > 2) then { 
			_lineLMarker = createMarker [str (random 3), [0,0,0]];
		    _lineLMarker setMarkerShape "POLYLINE";
		    _lineLMarker setMarkerPolyline _drawPathL;
		    _lineLMarker setMarkerColor "colorOPFOR";
		 };

	    // _lineLMarker = createMarker [str (random 3), [0,0,0]];
	    // _lineLMarker setMarkerShape "POLYLINE";
	    // _lineLMarker setMarkerPolyline _drawPathR;
	    // _lineLMarker setMarkerColor "colorBLUFOR";

	    _textPos = (_alliedLocs#((count _alliedLocs) - 1)) getPos [400, _playerDir - 180];

	    _textMarker = createMarker [str (random 5), _textPos];
	    _textMarker setMarkerType "mil_marker";
	    _textMarker setMarkerText "CONTACT LINE";
	    _textMarker setMarkerSize [0,0];
	    _textMarker setMarkerColor "colorOPFOR"



	} forEach [90, -90];

    if !(_allBuildings isEqualTo []) then {
	   [_locPos, _allBuildings, selectRandom dyn2_phase_names] call dyn2_draw_mil_symbol_objectiv;
    };

	// [_playerStart, _playerDir - 180, 500, "colorBLUFOR"] call dyn2_draw_mil_symbol_block;

    // _arrowMarkerBlufor = createMarker [str (random 5), _playerStart];
    // _arrowMarkerBlufor setMarkerType "marker_std_atk";
    // _arrowMarkerBlufor setMarkerSize [1, 1];
    // _arrowMarkerBlufor setMarkerColor "colorBLUFOR";
    // _arrowMarkerBlufor setMarkerDir _playerDir - 180;

    _arrowMarkerOpfor = createMarker [str (random 5), _locPos getPos [800, _playerDir - 180]];
    _arrowMarkerOpfor setMarkerType "marker_std_atk";
    _arrowMarkerOpfor setMarkerSize [1, 1];
    _arrowMarkerOpfor setMarkerColor "colorOPFOR";
    _arrowMarkerOpfor setMarkerDir _playerDir;
    _arrowMarkerOpfor setMarkerText (format ["%1 Incursion", toUpper dyn2_opfor_fation]);


    // _natoMarker = createMarker [str (random 5), _locPos getPos [4000, _playerDir]];
    // _natoMarker setMarkerType "flag_NATO";
    // _natoMarker setMarkerSize [1.3, 1.3];

    // _altisMarker = createMarker [str (random 5), (getMarkerPos _natoMarker) getPos [1000, 90]];
    // _altisMarker setMarkerType "flag_ALTIS";
    // _altisMarker setMarkerSize [1.3, 1.3];
    // _natoMarker setMarkerDir _playerDir;

    _flagPos = _locPos getPos [1000, _playerDir - 180];
    _csatMarker = createMarker [str (random 5), _flagPos];
    // _csatMarker setMarkerType "flag_CSAT";
    _csatMarker setMarkerType "o_c_inf_pl";
    _csatMarker setMarkerSize [1.3, 1.3];

    // if ([_flagPos] call dyn2_is_water) then {
    //     _arrowMarkerOpfor setMarkerText (format ["%1 Naval Landing", toUpper dyn2_opfor_fation]);
    // };
};


dyn2_draw_mil_symbol_objectiv = {
    params ["_objPos", "_buildings", "_name"];

    private _path = [];

    {
        _watchPos = _objPos getpos [1000, _x];
        _b = ([_buildings, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy)#0;
        _path pushBack ((getPos _b)#0);
        _path pushBack ((getPos _b)#1);
        if (_x == 90) then {
            _textPos = (getPos _b) getPos [50, _x];
            _m = createMarker [str (random 3), _textPos];
            _m setMarkerType "mil_dot",
            _m setMarkerText _name;
            _m setMarkerSize [0,0];
            _m setMarkerColor "colorOPFOR";

        };
    } forEach [0, 90, 180, 270];

    _path pushBack (_path#0);
    _path pushBack (_path#1);

    _objMarker = createMarker [str (random 3), [0,0,0]];
    _objMarker setMarkerShape "POLYLINE";
    _objMarker setMarkerPolyline _path;
    _objMarker setMarkerColor "colorOPFOR";
};

dyn2_draw_mil_symbol_block = {
    params ["_pos", "_dir", ["_size", 200], ["_color", "colorOpfor"]];

    private _path = [_pos#0, _pos#1];

    _pos2 = _pos getPos [_size, _dir];
    _path pushBack (_pos2#0);
    _path pushBack (_pos2#1);
    _pos3 = _pos2 getPos [_size / 2, _dir + 90];
    _path pushBack (_pos3#0);
    _path pushBack (_pos3#1);
    _pos4 = _pos2 getPos [_size / 2, _dir - 90];
    _path pushBack (_pos4#0);
    _path pushBack (_pos4#1);

    _blockMarker = createMarker [str (random 3), [0,0,0]];
    _blockMarker setMarkerShape "POLYLINE";
    _blockMarker setMarkerPolyline _path;
    _blockMarker setMarkerColor _color;

    _m = createMarker [str (random 3), _pos getPos [_size / 2, _dir]];
    _m setMarkerType "mil_dot",
    _m setMarkerText "B";
    _m setMarkerSize [0,0];
    _m setMarkerColor _color;
};

dyn2_draw_mil_symbol_screen = {
    params ["_pos", "_dir", ["_type", "S"], ["_color", "colorOpfor"]];


    {
        private _path = [];
        _sidePos = _pos getpos [100, _dir + _x];
        _sidePos3 = _sidePos getpos [300, _dir + _x];
        _sidePos2 = _sidePos3 getpos [50, _dir];
        _sidePos4 = _sidePos2 getpos [300, _dir + _x];
        _sidePos5 = _sidePos3 getpos [260, _dir + _x];
        _sidePos6 = (_sidePos2 getpos [260, _dir + _x]) getPos [30, _dir];

        _path pushBack (_sidePos#0);
        _path pushBack (_sidePos#1);
        _path pushBack (_sidePos2#0);
        _path pushBack (_sidePos2#1);
        _path pushBack (_sidePos3#0);
        _path pushBack (_sidePos3#1);
        _path pushBack (_sidePos4#0);
        _path pushBack (_sidePos4#1);
        _path pushBack (_sidePos5#0);
        _path pushBack (_sidePos5#1);
        _path pushBack (_sidePos4#0);
        _path pushBack (_sidePos4#1);
        _path pushBack (_sidePos6#0);
        _path pushBack (_sidePos6#1);


        _screenMarker = createMarker [str (random 3), [0,0,0]];
        _screenMarker setMarkerShape "POLYLINE";
        _screenMarker setMarkerPolyline _path;
        _screenMarker setMarkerColor _color;

    } forEach [90, -90];

    _m = createMarker [str (random 3), _pos];
    _m setMarkerType "mil_dot",
    _m setMarkerText _type;
    _m setMarkerSize [0,0];
    _m setMarkerColor _color;

};

dyn2_draw_mil_symbol_objectiv_free = {
    params ["_objPos", "_size", "_name", ["_color", "colorOpfor"]];

    // systemChat "oof";

    private _path = [];

    {
        _pos = _objPos getpos [_size, _x + ([-45, 45] call BIS_fnc_randomInt)];

        _path pushBack (_pos#0);
        _path pushBack (_pos#1);
        if (_x == 90) then {
            _textPos = _pos getPos [50, _x];
            _m = createMarker [str (random 3), _textPos];
            _m setMarkerType "mil_dot",
            _m setMarkerText _name;
            _m setMarkerSize [0,0];
            _m setMarkerColor _color;


        };
    } forEach [0, 90, 180, 270];

    _path pushBack (_path#0);
    _path pushBack (_path#1);

    _objMarker = createMarker [str (random 3), [0,0,0]];
    _objMarker setMarkerShape "POLYLINE";
    _objMarker setMarkerPolyline _path;
    _objMarker setMarkerColor _color;

};