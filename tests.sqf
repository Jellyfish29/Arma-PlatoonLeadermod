pl_defend_position = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_watchDir", "_cords", "_watchPos", "_defenceWatchPos", "_markerAreaName", "_markerDirName", "_buildings", "_doorPos", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon", "_unitWatchDir", "_vPosCounter", "_defenceAreaSize", "_mgPosArray", "_mgPos", "_mgOffset", "_atEscord"];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";


    if (visibleMap) then {
        hintSilent "";

        _markerAreaName = format ["%1garrison%2", _group, random 2];
        createMarker [_markerAreaName, [0,0,0]];
        _markerAreaName setMarkerShape "ELLIPSE";
        _markerAreaName setMarkerBrush "SolidBorder";
        _markerAreaName setMarkerColor pl_side_color;
        _markerAreaName setMarkerAlpha 0.35;
        _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];

        _markerAreaName setMarkerPos pl_defence_cords;
        _markerDirName = format ["defenceAreaDir%1%2", _group, random 2];
        createMarker [_markerDirName, pl_defence_cords];
        _markerDirName setMarkerPos pl_defence_cords;
        _markerDirName setMarkerType "marker_position";
        _markerDirName setMarkerColor pl_side_color;


        private _rangelimiterCenter = getPos (leader _group);
        if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};
        private _rangelimiter = 200;
        _markerBorderName = str (random 2);
        createMarker [_markerBorderName, _rangelimiterCenter];
        _markerBorderName setMarkerShape "ELLIPSE";
        _markerBorderName setMarkerBrush "Border";
        _markerBorderName setMarkerColor "colorOrange";
        _markerBorderName setMarkerAlpha 0.8;
        _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

        pl_garrison_area_size = 25;
        pl_360_area = false;
        _message = "Select Area <br /><br /><t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
                     <t size='0.8' align='left'>-> W/S</t><t size='0.8' align='right'>Increase/Decrease Size</t>";
        hint parseText _message;

        onMapSingleClick {
            pl_defence_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        player enableSimulation false;

        while {!pl_mapClicked} do {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
                _watchDir = _rangelimiterCenter getDir _mPos;
                _markerAreaName setMarkerPos _mPos;
                _markerDirName setMarkerPos _mPos;
                _markerDirName setMarkerDir _watchDir;
            };
            if (inputAction "MoveForward" > 0) then {pl_garrison_area_size = pl_garrison_area_size + 5; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_garrison_area_size = pl_garrison_area_size - 5; sleep 0.05};
            _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];
            if (pl_garrison_area_size >= 55) then {pl_garrison_area_size = 55};
            if (pl_garrison_area_size <= 10) then {pl_garrison_area_size = 10};
        };

        player enableSimulation true;

        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerAreaName};
        _message = "Select Defence FACING <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
        <t size='0.8' align='left'> -> ALT + LMB</t><t size='0.8' align='right'>360° Security</t>";
        hint parseText _message;
        
        sleep 0.1;
        deleteMarker _markerBorderName;
        _cords = getMarkerPos _markerAreaName;
        _markerDirName setMarkerPos _cords;
        // _cords = pl_defence_cords;
        _defenceAreaSize = pl_garrison_area_size;

        onMapSingleClick {
            pl_defenceWatchPos = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            if (_alt) then {pl_360_area = true};
            hintSilent "";
            onMapSingleClick "";
        };
        // pl_show_watchpos_selector = true;

        while {!pl_mapClicked} do {
            _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _markerDirName setMarkerDir _watchDir;
            _defenceWatchPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        };
        pl_mapClicked = false;
        // pl_show_watchpos_selector = false;

        // _defenceWatchPos = pl_defenceWatchPos;
        _defenceWatchPos = _cords getPos [250, _watchDir];
        _defenceWatchPos = ASLToATL _defenceWatchPos;
        _defenceWatchPos = [_defenceWatchPos#0, _defenceWatchPos#1, 2];
        _defenceWatchPos = ATLToASL _defenceWatchPos;

        deletemarker _markerAreaName;

        if (pl_360_area) then {
            _markerDirName setMarkerType "mil_circle";
            _markerDirName setMarkerSize [0.5, 0.5];
        };

        if (count _taskPlanWp != 0) then {

            // add Arrow indicator
            pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

            waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false]) or (_group getVariable ["pl_disembark_finished", false])};
            _group setVariable ["pl_disembark_finished", nil];

            // remove Arrow indicator
            pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

            if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
            _group setVariable ["pl_task_planed", false];
        };

        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
        _watchDir = ((leader _group) getDir player) - 180;
        _defenceAreaSize = 10;
        pl_360_area = true;
        _markerDirName = format ["defenceArea%1", _group];
        createMarker [_markerDirName, _cords];
        _markerDirName setMarkerType "mil_circle";
        _markerDirName setMarkerColor pl_side_color;
        _markerAreaName setMarkerPos _cords;
        _markerDirName setMarkerSize [0.5, 0.5];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

    _buildings = nearestObjects [_cords, ["House", "Strategic", "Ruins"], _defenceAreaSize, true];
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 4) then {
            _validBuildings pushBack _x;
        };
    } forEach _buildings;

    // if ((count _validBuildings == 0)) exitWith {hint "No buildings in Area!"; deleteMarker _markerAreaName; deleteMarker _markerDirName;};

    [_group] call pl_reset;

    sleep 0.2;

    if (pl_enable_beep_sound) then {playSound "beep"};

    if (pl_360_area) then {_icon = "\A3\ui_f\data\map\markers\military\circle_CA.paa"};
    if ((count _validBuildings) > 0) then {_icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _group setVariable ["pl_combat_mode", true];
    _group setVariable ["pl_in_position", true];
    [_group, _defenceWatchPos] spawn pl_defence_suppression;
    [_group, _cords] spawn pl_defence_rearm;

    _validPos = [];
    _allPos = [];
    {
        _building = _x;
        pl_draw_building_array pushBack [_group, _building];
        _bPos = [_building] call BIS_fnc_buildingPositions;
        _vPosCounter = 0;
        {
            _bP = _x;
            _allPos pushBack _bP;
            _watchPos = [3*(sin _watchDir), 3*(cos _watchDir), 1] vectorAdd _bP;
            _watchPos = ATLToASL _watchPos;
            if !(lineIntersects [_watchPos, _watchPos vectorAdd [0, 0, 6]]) then {

                _standingPos = [0, 0, 1] vectorAdd _bP;
                _standingPos = ATLToASL _standingPos;

                _helper1 = createVehicle ["Sign_Sphere25cm_F", _standingPos, [], 0, "none"];
                _helper1 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
                _helper1 setposASL _standingPos;

                _helper2 = createVehicle ["Sign_Sphere25cm_F", _watchPos, [], 0, "none"];
                _helper2 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
                _helper2 setposASL _watchPos;

                _vis = lineIntersectsSurfaces [_standingPos, _watchPos, objNull, objNull, true, 1, "VIEW"];
                if (_vis isEqualTo []) then {

                    _bPos deleteAt (_bPos find _bP);
                    _validPos pushBack _bP;
                    _vPosCounter = _vPosCounter + 1;
                };
            };
        } forEach _bPos;

        if (_vPosCounter <= 2) then {
            _validPos pushBack (selectRandom _bPos);
        };
    } forEach _validBuildings;

    // deploy packed static weapons if no buildings
    _isStatic = [false, []];
    // if (_validBuildings isEqualTo [] and !(pl_360_area)) then {
    //     _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _cords;
    //     _leaderDir = _watchDir - 90;
    //     _leaderPos = [6*(sin _leaderDir), 6*(cos _leaderDir), 0] vectorAdd _cords;
    //     (leader _group) addWeapon "Binocular";
    //     _isStatic = [_group, _cords, _watchPos, _leaderPos] call pl_reworked_bis_unpack;
    // };

    _watchPos = [500*(sin _watchDir), 500*(cos _watchDir), 0] vectorAdd _cords;

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _units = [];
    private _mgGunners = [];
    private _atSoldiers = [];
    private _atEscord = objNull;
    private _medic = objNull;


    // classify units
    {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 != "MachineGun" and secondaryWeapon _x == "" and _x != _medic) then {
            _units pushBackUnique _x;
        };
        if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") then {
            _mgGunners pushBackUnique _x;
        };
        if (secondaryWeapon _x != "") then {
            _atSoldiers pushBackUnique _x;
        };
    } forEach (units _group);

    if (count _atSoldiers > 0 and count _units > 3) then {
        _atEscord = {
            if (_x != (leader _group) and _x != _medic) exitWith {_x};
            objNull
        } forEach _units;
    };
    {_units pushBack _x} forEach _atSoldiers;
    {_units pushBack _x} forEach _mgGunners;
    _units pushBack _medic;


    _posOffsetStep = _defenceAreaSize / (round ((count _units) / 2));
    private _posOffset = 0; //+ _posOffsetStep;
    private _maxOffset = _posOffsetStep * (round ((count _units) / 2));

    // find static weapons
    private _weapons = nearestObjects [_cords, ["StaticWeapon"], _defenceAreaSize, true];
    _avaiableWeapons = _weapons select { simulationEnabled _x && { !isObjectHidden _x } && { locked _x != 2 } && { (_x emptyPositions "Gunner") > 0 } };
    _weapons = + _avaiableWeapons;
    _coverCount = 0;

    for "_i" from 0 to (count _units) - 1 step 1 do {
        private _cover = false;
        private _covers = nearestTerrainObjects [_cords, pl_valid_covers, _defenceAreaSize, true, true];
        // private _blacklist = nearestTerrainObjects [_cords, [], (_defenceAreaSize - 8), true, true];
        // _covers = _covers - _blacklist;
        _covers = [_covers, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

        _unitWatchDir = _watchDir;
        private _moveToStatic = false;
        if !(_avaiableWeapons isEqualTo []) then {
            _weapon = selectRandom _avaiableWeapons;
            _weapon setDir _watchDir;
            (_units#_i) assignAsGunner _weapon;
            [_units#_i] orderGetIn true;
            _group addVehicle _weapon;
            _avaiableWeapons deleteAt (_avaiableWeapons find _weapon);
            _moveToStatic = true;
        };

        // move to optimal Pos first
        if (_i < (count _validPos)) then {
            _pos = _validPos#_i;
            _unit = _units#_i;
        }
        else
        {
            _cover = true;
            _unit = _units#_i;
            // if no more covers avaible move to left or right side of best cover
                // deploy along a line
            if (_validBuildings isEqualTo []) then {
                _dirOffset = 90;
                if (_i % 2 == 0) then {_dirOffset = -90};
                _pos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _cords;
                if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};
            }
            else
            {
                if (_coverCount < (count _covers)) then {
                    _pos = getPos (_covers#_coverCount);
                    _coverCount = _coverCount + 1;
                } else {
                    _offSet = ((((boundingBox (_validBuildings#0))#1)#0) + 4) + _posOffset;
                    _forwardPos = getPos (_validBuildings#0);
                    if (_i % 2 == 0) then {
                        _pos = _forwardPos getPos [_offSet, _watchDir + 90]
                    } else {
                        _pos = _forwardPos getPos [_offSet, _watchDir - 90];
                        _posOffset = _posOffset + _posOffsetStep;
                    };
                };


                // _m = createMarker [str (random 1), _pos];
                // _m setMarkerType "mil_dot";
                // _m setMarkerSize [0.5, 0.5];

            };
        };

        // seelct best Medic Pos
        if (!(isNil "_medic") and pl_enabled_medical) then {
            if (_unit == _medic) then {
                _rearPos = _cords getPos [_defenceAreaSize * 0.7, _watchDir - 180];
                _lineStartPos = _rearPos getPos [_defenceAreaSize / 2, _watchDir - 90];
                _unitWatchDir = _watchDir - 180;
                private _posCandidates = [];
                private _ccpPosOffset = 0;
                for "_l" from 0 to 20 do {
                    _cPos = _lineStartPos getPos [_ccpPosOffset, _watchDir + 90];
                    _ccpPosOffset = _ccpPosOffset + (_defenceAreaSize / 20);
                    if !([_cPos] call pl_is_indoor) then {
                        _posCandidates pushBack _cPos;
                        _m = createMarker [str (random 1), _cPos];
                        _m setMarkerType "mil_dot";
                        _m setMarkerSize [0.5, 0.5];
                    };

                };
                _posCandidates = [_posCandidates, [], {_x distance2D _cords}, "DESCEND"] call BIS_fnc_sortBy;
                _pos = ([_posCandidates, [], {[objNull, "VIEW", objNull] checkVisibility [_x, [_x getPos [50, _watchDir], 0.5] call pl_convert_to_heigth_ASL]}, "DESCEND"] call BIS_fnc_sortBy)#0;
                _m = createMarker [str (random 1), _pos];
                _m setMarkerType "mil_dot";
                _m setMarkerColor "colorGreen";

            };
        };

        // select Best Mg Pos
        if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {

            _cover = false;
            _mgOffset = 2;
            private _maxLos = 0;
            _mgStartLine = _cords getPos [5, _watchDir];
            if !(_validBuildings isEqualTo []) then {
                _mgStartLine = (getPos (_validBuildings#0)) getPos [5, _watchDir];
            };
            for "_j" from 0 to 30 do {
                if (_j % 2 == 0) then {
                    _mgPos = (_mgStartLine getPos [2, _watchDir]) getPos [_mgOffset, _watchDir + 90];
                }
                else
                {
                    _mgPos = (_mgStartLine getPos [2, _watchDir]) getPos [_mgOffset, _watchDir - 90];
                };
                _mgOffset = _mgOffset + (_defenceAreaSize / 30);

                _mgPos = [_mgPos, 1] call pl_convert_to_heigth_ASL;

                if !([_mgPos] call pl_is_indoor) then {
                    private _losCount = 0;
                    for "_l" from 10 to 510 step 50 do {

                        _checkPos = _mgPos getPos [_l, _watchDir];
                        _checkPos = [_checkPos, 1] call pl_convert_to_heigth_ASL;
                        _vis = lineIntersectsSurfaces [_mgPos, _checkPos, _unit, vehicle _unit, true, 1, "VIEW"];

                        if !(_vis isEqualTo []) exitWith {};

                        _losCount = _losCount + 1;
                    };
                    if (_losCount > _maxLos) then {
                        _maxLos = _losCount;
                        _pos = _mgPos
                    };
                };
            };
        };


        _pos = ATLToASL _pos;
        private _unitPos = "UP";
        _checkPos = [7*(sin _watchDir), 7*(cos _watchDir), 1] vectorAdd _pos;
        _crouchPos = [0, 0, 1] vectorAdd _pos;
        _vis = lineIntersectsSurfaces [_crouchPos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "MIDDLE";
            _watchPos = _checkPos;
        };
        _checkPos = [7*(sin _watchDir), 7*(cos _watchDir), 0.2] vectorAdd _pos;
        _vis = lineIntersectsSurfaces [_pos, _checkPos, objNull, objNull, true, 1, "VIEW"];
        if (_vis isEqualTo []) then {
            _unitPos = "DOWN";
            _watchPos = _checkPos;
        };

        _pos = ASLToATL _pos;

        if !(_moveToStatic and !(_unit in (_isStatic#1))) then {
            [_unit, _pos, _watchPos, _unitWatchDir, _unitPos, _cover, _cords, _defenceAreaSize, _defenceWatchPos, _watchDir, _atEscord, _medic] spawn {
                params ["_unit", "_pos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_cords", "_defenceAreaSize", "_defenceWatchPos", "_defenceDir", "_atEscord", "_medic"];

                _m = createMarker [str (random 1), _pos];
                _m setMarkerType "mil_dot";
                _m setMarkerSize [0.5, 0.5];


                _unit setVariable ["pl_def_pos", _pos];
                _unit disableAI "AUTOCOMBAT";
                _unit disableAI "AUTOTARGET";
                _unit disableAI "TARGET";
                _unit setUnitTrait ["camouflageCoef", 0.7, true];
                _unit setVariable ["pl_damage_reduction", true];
                // _unit disableAI "FSM";
                _unit doMove _pos;
                _unit setDestination [_pos, "FORMATION PLANNED", false];
                sleep 1;
                // waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or [_unit, _pos] call pl_position_reached_check};
                waitUntil {unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
                _unit enableAI "AUTOCOMBAT";
                _unit enableAI "AUTOTARGET";
                _unit enableAI "TARGET";
                // _unit enableAI "FSM";
                if !(_cover) then {
                    doStop _unit;
                    _unit doWatch _watchPos;
                    _unit setUnitPos _unitPos;
                }
                else
                {
                    if ([_pos] call pl_is_forest) then {
                        [_unit, _watchPos, _unitWatchDir, 5, false] spawn pl_find_cover;
                    } else {
                        [_unit, _watchPos, _unitWatchDir, 10, false] spawn pl_find_cover;
                    };
                };
                if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                    [_unit, group _unit, _cords, _defenceAreaSize, _defenceDir, _pos, _atEscord] spawn pl_at_defence;
                    sleep 0.1;
                    _m setMarkerColor "colorOrange";
                };
                if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                    [_unit, _watchPos, _unitWatchDir, 0, false, false, "", true] spawn pl_find_cover;
                    _m setMarkerColor "colorRed";
                };
                if (_unit == _medic) then {
                    [(group _unit), _unit, _pos] spawn pl_defence_ccp;
                    _m setMarkerColor "colorGreen";
                };
            };
        };
    };

    // hint (str _allPos);

    waitUntil {!(_group getVariable ["onTask", true])};

    deleteMarker _markerAreaName;
    deleteMarker _markerDirName;

    if (_isStatic#0) then {
        _weapon = {
            if ((vehicle _x) != _x) exitWith {vehicle _x};
            objNull
        } forEach (units _group);
        if !(isNull _weapon) then {
            [_group, _weapon] call pl_reworked_bis_pack;
        };
        (leader _group) removeWeapon "Binocular";
    };

    {
        _group leaveVehicle _x;
    } forEach _weapons;

    {
        pl_draw_building_array = pl_draw_building_array - [[_group, _x]];
    } forEach _validBuildings;
};


