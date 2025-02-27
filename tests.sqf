
pl_get_vistool_poly = {
	private ["_end"];

	_mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
 	private _start = [_mPos#0, _mPos#1, 2];
	private _intersects = [];
	_start = ATLToASL _start;

	private _linePath = [];

	// for "_i" from 0 to 719 step 0.5 do {
	for "_i" from 0 to 359 step 1 do {
		_end = _start vectorAdd [(sin _i) * 2000, (cos _i) * 2000, 0];
		_vis = (lineIntersectsSurfaces [_start, _end, objNull, objNull, true, 1, "GEOM", "VIEW"]);
		if !(_vis isEqualTo []) then {
			_linePath pushBack (_vis#0#0#0);
			_linePath pushBack (_vis#0#0#1);
		} else {
			_linePath pushBack _end#0;
			_linePath pushBack _end#1;
		};
	};
	_linePath
};

pl_get_vistool_pos = {
	private ["_end"];

	_mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
 	private _start = [_mPos#0, _mPos#1, 3];
	private _intersects = [];
	_start = ATLToASL _start;

	private _linePath = [];

	// for "_i" from 0 to 719 step 0.5 do {
	for "_i" from 0 to 359 step 1 do {
		// _end = _start vectorAdd [(sin _i) * 2000, (cos _i) * 2000, 0];
		_end = _start getPos [2000, _i] vectorAdd [0,0,30];
		_vis = (lineIntersectsSurfaces [_start, _end, objNull, objNull, true, 1, "GEOM", "VIEW"]);
		if !(_vis isEqualTo []) then {
			_linePath pushBack (_vis#0#0);
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
	        for '_i' from -1 to 358 step 1 do {
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