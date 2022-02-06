pl_show_watchpos_selector = false;

pl_defend_position = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_watchDir", "_cords", "_watchPos", "_defenceWatchPos", "_markerAreaName", "_markerDirName", "_buildings", "_allPos", "_validPos", "_units", "_unit", "_pos", "_icon", "_unitWatchDir", "_vPosCounter", "_defenceAreaSize", "_mgPosArray", "_mgPos", "_mgOffset"];

    if (vehicle (leader _group) != leader _group and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa";

    _markerAreaName = format ["%1garrison%2", _group, random 2];
    createMarker [_markerAreaName, [0,0,0]];
    _markerAreaName setMarkerShape "ELLIPSE";
    _markerAreaName setMarkerBrush "SolidBorder";
    _markerAreaName setMarkerColor pl_side_color;
    _markerAreaName setMarkerAlpha 0.35;
    _markerAreaName setMarkerSize [pl_garrison_area_size, pl_garrison_area_size];

    if (visibleMap) then {
        hintSilent "";

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
            _markerAreaName setMarkerPos _mPos;
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

        _markerAreaName setMarkerPos pl_defence_cords;
        _markerDirName = format ["defenceAreaDir%1%2", _group, random 2];
        createMarker [_markerDirName, pl_defence_cords];
        _markerDirName setMarkerPos pl_defence_cords;
        _markerDirName setMarkerType "marker_position";
        _markerDirName setMarkerColor pl_side_color;
        
        sleep 0.1;
        _cords = pl_defence_cords;
        _defenceAreaSize = pl_garrison_area_size;

        onMapSingleClick {
            pl_defenceWatchPos = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            if (_alt) then {pl_360_area = true};
            hintSilent "";
            onMapSingleClick "";
        };
        pl_show_watchpos_selector = true;

        while {!pl_mapClicked} do {
            _watchDir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _markerDirName setMarkerDir _watchDir;
            _defenceWatchPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
        };
        pl_mapClicked = false;
        pl_show_watchpos_selector = false;

        _defenceWatchPos = pl_defenceWatchPos;
        _defenceWatchPos = ASLToATL _defenceWatchPos;
        _defenceWatchPos = [_defenceWatchPos#0, _defenceWatchPos#1, 1.5];
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

        // if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerDirName; deleteMarker _markerAreaName;};

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

    _buildings = nearestObjects [_cords, ["house"], _defenceAreaSize];
    _validBuildings = [];
    {
        if (count ([_x] call BIS_fnc_buildingPositions) >= 2) then {
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
    _medic = {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) exitWith {_x};
    } forEach (units _group); 


    _validPos = [];
    _allPos = [];
    {
        _building = _x;
        pl_draw_building_array pushBack [_group, _building];
        _bPos = [_building] call BIS_fnc_buildingPositions;
        _vPosCounter = 0;
        {
            _allPos pushBack _x;
            _watchPos = [10*(sin _watchDir), 10*(cos _watchDir), 1.2] vectorAdd _x;
            _standingPos = [0, 0, 1.2] vectorAdd _x;
            _standingPos = ATLToASL _standingPos;
            _watchPos = ATLToASL _watchPos;

            // _helper1 = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
            // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
            // _helper1 setposASL _watchPos;

            // _helper2 = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
            // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
            // _helper2 setposATL _standingPos;

            _cansee = [objNull, "FIRE"] checkVisibility [_standingPos, _watchPos];
            if (_cansee > 0.5) then {
                _bPos deleteAt (_bPos find _x);
                _validPos pushBack _x;
                _vPosCounter = _vPosCounter + 1;
            };
            // _vis = lineIntersects [_standingPos, _watchPos];
            // if !(_vis) then {
            //     _validPos pushBack _x;
            //     _vPosCounter = _vPosCounter + 1;
            // };
            // _vis = lineIntersectsSurfaces [_standingPos, _watchPos, objNull, objNull, true, 1, "VIEW", "FIRE"];
            // if (_vis isEqualTo []) then {
            //     _validPos pushBack _x;
            //     _vPosCounter = _vPosCounter + 1;
            // };
        } forEach _bPos;
        if (_vPosCounter <= 2) then {
            for "_i" from 0 to 1 do {
                _validPos pushBack (selectRandom _bPos);
            };
        };
    } forEach _validBuildings;

    // deploy packed static weapons if no buildings
    _isStatic = [false, []];
    if (_validBuildings isEqualTo [] and !(pl_360_area)) then {
        _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _cords;
        _leaderDir = _watchDir - 90;
        _leaderPos = [6*(sin _leaderDir), 6*(cos _leaderDir), 0] vectorAdd _cords;
        (leader _group) addWeapon "Binocular";
        _isStatic = [_group, _cords, _watchPos, _leaderPos] call pl_reworked_bis_unpack;
    };


    // {
    //     _helper = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
    //     _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
    //     _helper setposATL _x;
    // } forEach _validPos;

    _watchPos = [500*(sin _watchDir), 500*(cos _watchDir), 0] vectorAdd _cords;

    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _units = units _group;
    _posOffsetStep = _defenceAreaSize / (round ((count _units) / 2));
    private _posOffset = 0; //+ _posOffsetStep;
    private _maxOffset = _posOffsetStep * (round ((count _units) / 2));

    // find static weapons
    private _weapons = nearestObjects [_cords, ["StaticWeapon"], _defenceAreaSize, true];
    _avaiableWeapons = _weapons select { simulationEnabled _x && { !isObjectHidden _x } && { locked _x != 2 } && { (_x emptyPositions "Gunner") > 0 } };
    _weapons = + _avaiableWeapons;


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
            // if 360 Option move to 360 Positions
            if (pl_360_area) then {
                _diff = 360/ (count _units);
                _degree = 1 + _i*_diff;
                _pos = [_defenceAreaSize*(sin _degree), _defenceAreaSize*(cos _degree), 0] vectorAdd _cords;
                _watchDir = _degree;
                _unitWatchDir = _degree;
            }
            // if no more covers avaible move to left or right side of best cover
            else
            {
                // deploy along a line
                if (_validBuildings isEqualTo []) then {
                    _dirOffset = 90;
                    if (_i % 2 == 0) then {_dirOffset = -90};
                    _pos = [_posOffset *(sin (_watchDir + _dirOffset)), _posOffset *(cos (_watchDir + _dirOffset)), 0] vectorAdd _cords;
                    if (_i % 2 == 0) then {_posOffset = _posOffset + _posOffsetStep};

                    if (_i == (count _units) - 2 or _i == (count _units) - 3) then {
                        _unitWatchDir = _watchDir + _dirOffset;
                    };

                    // last unit in group backwards position watch back if Medic active the nunit is medic
                    if (!(isNil "_medic") and pl_enabled_medical and (_group getVariable ["pl_healing_active", false])) then {
                        if (_unit == _medic) then {
                            _pos = [(_defenceAreaSize * 0.5) *(sin (_watchDir - 180)), (_defenceAreaSize * 0.5) *(cos (_watchDir - 180)), 0] vectorAdd _cords;
                            _unitWatchDir = _watchDir - 180;
                        };
                    }
                    else
                    {
                        if (_unit == (_units#((count _units) - 1))) then {
                            _pos = [(_defenceAreaSize * 0.5) *(sin (_watchDir - 180)), (_defenceAreaSize * 0.5) *(cos (_watchDir - 180)), 0] vectorAdd _cords;
                            _unitWatchDir = _watchDir - 180;
                        };
                    };
                }
                else
                {
                    if !(_covers isEqualTo []) then {
                        _pos = getPos (selectRandom _covers);
                    }
                    else
                    {
                        _pos = _cords findEmptyPosition [0, _defenceAreaSize, typeOf _x];
                    };
                };
            };
        };

        if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {

            _mgPosArray = [];
            _mgOffset = 2;
            for "_j" from 0 to 20 do {
                if (_j % 2 == 0) then {
                    _mgPos = (_cords getPos [2, _watchDir]) getPos [_mgOffset, _watchDir + 90];
                }
                else
                {
                    _mgPos = (_cords getPos [2, _watchDir]) getPos [_mgOffset, _watchDir - 90];
                };
                _mgOffset = _mgOffset + (_defenceAreaSize / 20);

                _mgPos = ASLToATL _mgPos;
                _mgPos = [_mgPos#0, _mgPos#1, 1.5];
                _mgPos = ATLToASL _mgPos;

                // _m = createMarker [str (random 1), _mgPos];
                // _m setMarkerType "mil_dot";

                _vis = lineIntersectsSurfaces [_mgPos, _defenceWatchPos, _unit, vehicle _unit, true, 1, "FIRE"];

                if (_vis isEqualTo []) then {

                    // _m = createMarker [str (random 1), _mgPos];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerColor "colorRed";

                    _mgPosArray pushBack _mgPos;
                };
            };
            if (count _mgPosArray > 0) then {
                // _pos = ([_mgPosArray, [], {_cords distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;
                _pos = ([_mgPosArray, [], {[_unit, "FIRE"] checkVisibility [_x, _defenceWatchPos]}, "ASCEND"] call BIS_fnc_sortBy) select 0; 
                _watchPos = _defenceWatchPos;
                _cover = false;

                _m = createMarker [str (random 1), _pos];
                _m setMarkerType "mil_dot";
                _m setMarkerColor "colorGreen";
                
            };
        };


        _pos = ATLToASL _pos;
        private _unitPos = "UP";
        _checkPos = [7*(sin _watchDir), 7*(cos _watchDir), 0.7] vectorAdd _pos;
        _crouchPos = [0, 0, 0.7] vectorAdd _pos;
        if (([_unit, "VIEW"] checkVisibility [_crouchPos, _checkPos]) >= 0.7) then {
            _unitPos = "MIDDLE";
        };
        _checkPos = [7*(sin _watchDir), 7*(cos _watchDir), 0.1] vectorAdd _pos;
        if (([_unit, "VIEW"] checkVisibility [_pos, _checkPos]) == 1) then {
            _unitPos = "DOWN";
        };

        // _helper1 = createVehicle ["Sign_Sphere25cm_F", _crouchPos, [], 0, "none"];
        // _helper1 setObjectTexture [0,'#(argb,8,8,3)color(1,0,0,1)'];
        // _helper1 setposASL _crouchPos;

        // _helper2 = createVehicle ["Sign_Sphere25cm_F", _pos, [], 0, "none"];
        // _helper2 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
        // _helper2 setposASL _pos;

        // _helper3 = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
        // _helper3 setObjectTexture [0,'#(argb,8,8,3)color(0,0,1,1)'];
        // _helper3 setposASL _checkPos;

        _pos = ASLToATL _pos;

        if !(_moveToStatic and !(_unit in (_isStatic#1))) then {
            [_unit, _pos, _watchPos, _unitWatchDir, _unitPos, _cover, _cords, _defenceAreaSize] spawn {
                params ["_unit", "_pos", "_watchPos", "_unitWatchDir", "_unitPos", "_cover", "_cords", "_defenceAreaSize"];
                _unit disableAI "AUTOCOMBAT";
                _unit disableAI "TARGET";
                _unit disableAI "AUTOTARGET";
                _unit doMove _pos;
                // _unit setDestination [_pos, "LEADER DIRECT", false];
                _unit setDestination [_pos, "LEADER PLANNED", true];
                // if !([_unit, _pos, _defenceAreaSize] call pl_not_reachable_escape) then {_cover = true};

                sleep 0.2;

                waitUntil {sleep 0.5; (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or [_unit, _pos] call pl_position_reached_check};
                _unit enableAI "AUTOCOMBAT";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                if ((group _unit) getVariable ["onTask", true]) then {
                    if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                        [_unit, group _unit, _cords, _defenceAreaSize, _unitWatchDir, _pos] spawn pl_at_defence;
                    };
                    if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {
                        _unitPos = "MIDDLE";
                        [_unit, group _unit, _watchPos] spawn pl_defence_suppression;
                    };
                    if !(_cover) then {
                        _unit doWatch _watchPos;
                        doStop _unit;
                        // _unit setUnitPosWeak _unitPos;
                        _unit setUnitPos _unitPos;
                        _unit disableAI "PATH";
                    }
                    else
                    {
                        if ([_pos] call pl_is_forest) then {
                            [_unit, _watchPos, _unitWatchDir, 5, false] spawn pl_find_cover;
                        } else {
                            [_unit, _watchPos, _unitWatchDir, 15, true] spawn pl_find_cover;
                        };
                    };
                };
            };
        };
    };

    // hint (str _allPos);

    if (!(isNil "_medic") and pl_enabled_medical) then {

        waitUntil {_group getVariable ["pl_healing_active", false] or !(_group getVariable ["onTask", true])};

        _medic setVariable ["pl_is_ccp_medic", true];
        while {(_group getVariable ["onTask", true])} do {
            _time = time + 10;
            waitUntil {time > _time or !(_group getVariable ["onTask", true])};
            {
                if (_x getVariable ["pl_wia", false] and !(_x getVariable "pl_beeing_treatet")) then {
                    _medic setUnitPos "MIDDLE";
                    _medic enableAI "PATH";
                    _h1 = [_group, _medic, nil, _x, getPos _medic, 40, "onTask"] spawn pl_ccp_revive_action;
                    waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                    [_x, getPos _x, getDir _x, 7, false] spawn pl_find_cover;
                    sleep 1;
                    waitUntil {unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                    [_medic, getPos _medic, getDir _medic, 10, false] spawn pl_find_cover;
                };
                // if ((_x getVariable "pl_injured") and (getDammage _x) > 0 and (alive _x) and !(_x getVariable "pl_wia") and !(lifeState _x isEqualTo "INCAPACITATED")) then {
                //     _medic setUnitPos "MIDDLE";
                //     _medic enableAI "PATH";
                //     _h1 = [_medic, _x, getPos _medic, "onTask"] spawn pl_medic_heal;
                //     waitUntil {scriptDone _h1 or !(_group getVariable ["onTask", true])};
                //     sleep 1;
                //     waitUntil {unitReady _medic or !alive _medic or !(_group getVariable ["onTask", true])};
                //     [_medic, getPos _medic, getDir _medic, 10, false] spawn pl_find_cover;
                // };
            } forEach (units _group);
        };
        _medic setVariable ["pl_is_ccp_medic", false];
    }
    else
    {
        waitUntil {!(_group getVariable ["onTask", true])};
    };
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


pl_at_defence = {
    params ["_unit", "_group", "_defencePos", "_defenceAreaSize", "_defenceDir", "_startPos"];
    private ["_vics", "_targets", "_target", "_p", "_posArray"];

    sleep 2;

    while {_group getVariable ["onTask", false]} do {
        
        _watchPos = _defencePos getPos [250, _defenceDir];
        _vics = nearestObjects [_watchPos, ["Car", "Tank"], 350, true];


        _targets = [];
        {
            if (speed _x <= 5) then {
                _targets pushBack _x;
            };
        } forEach (_vics select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

        if (count _targets > 0) then {
            _targets = [_targets, [], {_x distance2D _defencePos}, "ASCEND"] call BIS_fnc_sortBy;
            _target = _targets#0;

            _posArray = [];
            _offset = 0.8;
            _dist = 0;
            _rightPos = _defencePos getPos [_defenceAreaSize, _defenceDir + 90];
            _leftPos = _defencePos getPos [_defenceAreaSize, _defenceDir - 90];
            for "_i" from -7 to 100 do {
                if (_i < 0) then {
                    _p = [-2 + (random 4), -2 + (random 4), 0] vectorAdd (getPos _unit);
                }
                else
                {
                    if (_i % 2 == 0) then {
                        _p = _rightPos getPos [ _dist , _defenceDir + ([-10 , 10] call BIS_fnc_randomInt)];
                    }
                    else
                    {
                        _p = _leftPos getPos [ _dist , _defenceDir + ([-10 , 10] call BIS_fnc_randomInt)];
                    };
                    _dist = _dist + _offset;
                };
                if (_i == 0) then {_p = getPos _unit};

                // _m = createMarker [str (random 1), _p];
                // _m setMarkerType "mil_dot";

                _p = ASLToATL _p;
                _p = [_p#0, _p#1, 1.5];
                _p = ATLToASL _p;

                _vis = lineIntersectsSurfaces [_p, aimPos _target, _target, vehicle _target, true, 1, "FIRE"];

                if (_vis isEqualTo []) then {

                    // _m = createMarker [str (random 1), _p];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerColor "colorRED";

                    _posArray pushBack _p;
                };
            };
            if (count _posArray > 0) then {
                doStop _unit;
                _unit enableAI "PATH";
                _unit setUnitPos "AUTO";
                _unit disableAI "AUTOTARGET";
                _unit setUnitTrait ["camouflageCoef", 0.1, true];
                _unit setUnitCombatMode "WHITE";
                _movePos = ([_posArray, [], {getPos _unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;

                _m = createMarker [str (random 1), _movePos];
                _m setMarkerType "mil_dot";
                _m setMarkerColor "colorGreen";

                _unit doWatch _movePos;
                _unit doMove _movePos;
                sleep 1;

                _time = time + 25;
                waitUntil {_time > _time or unitReady _unit or !alive _unit or !alive _target or (count (crew _target) == 0) or !((group _unit) getVariable ["onTask", true])};
                if (time > _time) then { continue};

                _vis = lineIntersectsSurfaces [_movePos, aimPos _target, _target, vehicle _target, true, 1, "FIRE"];

                if !(_vis isEqualTo []) then {continue};

                _unit disableAi "AIMINGERROR";
                _unit reveal [_target, 4];
                // _unit doWatch _target;
                _unit doTarget _target;
                _unit doFire _target;

                sleep 7;

                if ((alive _unit) and (alive _target) and (count (crew _target) > 0) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true]) and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                    _unit doTarget objNull;
                    // _unit doWatch objNull;
                    continue;
                };

                sleep 2;

                _unit setUnitTrait ["camouflageCoef", 1, true];
                _unit enableAi "AIMINGERROR";
                _unit setUnitCombatMode "Yellow";
                _unit disableAI "TARGET";
                _unit disableAI "AUTOTARGET";
                doStop _unit;

                _unit doWatch (leader _group);
                _unit doMove _startPos;

                sleep 2;

                waitUntil {unitReady _unit or !(alive _unit) or !((group _unit) getVariable ["onTask", true])};
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";

                [_unit, getPos _unit, _defenceDir, 15, true] spawn pl_find_cover;
            };
        };
        sleep 10;
    };
};


pl_defence_suppression = {
    params ["_unit", "_group", "_watchPos"];
    private ["_targetsPos"];


    // _markerAreaName = format ["%1gsdfrrison%2", _group, random 2];
    // createMarker [_markerAreaName, _watchPos];
    // _markerAreaName setMarkerShape "ELLIPSE";
    // _markerAreaName setMarkerBrush "SolidBorder";
    // _markerAreaName setMarkerColor pl_side_color;
    // _markerAreaName setMarkerAlpha 0.35;
    // _markerAreaName setMarkerSize [250, 250];

    sleep 5;

    while {_group getVariable ["onTask", false]} do {

        _allTargets = nearestObjects [_watchPos, ["Man", "Car"], 250, true];
        _targetsPos = [];
        {
            _vis = lineIntersectsSurfaces [eyePos _unit, getPosASl _x, _unit, vehicle _unit, true, 1]; 
            if !(_vis isEqualTo []) then {
                _pos = (_vis select 0) select 0;

                if ((_pos distance2D _unit) > pl_suppression_min_distance and !([_pos] call pl_friendly_check)) then { 

                    // _m = createMarker [str (random 1), _pos];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerColor "colorRED";
                    _unit reveal [_x, 2];
                    _targetsPos pushBack _pos;
                };
            };
        } forEach (_allTargets select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

        if (count _targetsPos > 0 and !(_group getVariable ["pl_hold_fire", false])) then { 
            _target = selectRandom _targetsPos;
            _unit doSuppressiveFire _target;
        };

        sleep 15;
    };
};

pl_is_forest = {
    params ["_pos"];

    _trees = nearestTerrainObjects [_pos, ["Tree"], 50, false, true];

    if (count _trees > 25) exitWith {true};

    false
};

pl_draw_defence_watchpos_select = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_show_watchpos_selector) then {
            _pos1 = pl_defence_cords;
            _pos2 = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;

            _display drawArrow [
                _pos1,
                _pos2,
                pl_side_color_rgb
            ];

            _display drawIcon [
                '\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa',
                [0.9,0.9,0,1],
                _pos2,
                14,
                14,
                0,
                '',
                2
            ];
        };
    "]; // "
};

[] call pl_draw_defence_watchpos_select;