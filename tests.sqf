pl_full_cover = {
    params ["_group"];

    [_group] call pl_reset;

    sleep 0.2;
    playsound "beep";
    leader _group groupRadio "SentCmdHide";

    _group setVariable ["setSpecial", true];
    _group setVariable ["onTask", true];
    _group setVariable ["specialIcon", '\A3\3den\data\Attributes\Stance\down_ca.paa'];

    if (vehicle (leader _group) != leader _group) then {
        _group setCombatMode "GREEN";
        // _group setVariable ["pl_hold_fire", true];
        _group setVariable ["pl_combat_mode", true];
        {
            _x setVariable ["pl_damage_reduction", true];
            _x setUnitTrait ["camouflageCoef", 0.5, true];
            _x disableAI "PATH";
        } forEach (units _group);

    }
    else
    {
        {
            [_x, getPos _x, getDir _x, 5, false, true] spawn pl_find_cover;
            // _x setUnitPos "DOWN";
            // _x disableAI "PATH";
            _x setVariable ["pl_damage_reduction", true];
            _x setUnitTrait ["camouflageCoef", 0.5, true];
        } forEach (units _group);
    };

    waitUntil {!(_group getVariable ["onTask", true])};

    {
        _x setVariable ["pl_damage_reduction", false];
        _x setUnitTrait ["camouflageCoef", 1, true];
        _x enableAI "PATH";
    } forEach (units _group);

    if (vehicle (leader _group) != leader _group) then {
        _group setCombatMode "YELLOW";
        // _group setVariable ["pl_hold_fire", false];
        _group setVariable ["pl_combat_mode", false];
    };
};


pl_find_cover = {
    params ["_unit", "_watchPos", "_watchDir", "_radius", "_moveBehind", ["_fullCover", false]];

    _covers = nearestTerrainObjects [getPos _unit, pl_valid_covers, _radius, true, true];
    // _unit enableAI "AUTOCOMBAT";
    _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _watchPos;
    if ((count _covers) > 0) then {
        {
            if !(_x in pl_covers) exitWith {
                pl_covers pushBack _x;
                _unit doMove (getPos _x);
                waitUntil {(unitReady _unit) or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
                if ((group _unit) getVariable ["onTask", true]) then {
                    if (_fullCover) then {
                        _unit setUnitPos "DOWN";
                    }
                    else
                    {
                        _unit setUnitPos "MIDDLE";
                    };
                    if (_moveBehind) then {
                        _moveDir = [(_watchDir - 180)] call pl_angle_switcher;
                        _coverPos =  [2*(sin _moveDir), 2*(cos _moveDir), 0] vectorAdd (getPos _unit);
                        _unit doMove _coverPos;
                        waitUntil {(unitReady _unit) or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
                        if ((group _unit) getVariable ["onTask", true]) then {
                            doStop _unit;
                            _unit doWatch _watchPos;
                            _unit disableAI "PATH";
                        };
                    }
                    else
                    {
                        doStop _unit;
                        _unit doWatch _watchPos;
                        _unit disableAI "PATH";
                    };
                    [_x] spawn {
                        params ["_cover"];
                        sleep 10;
                        pl_covers deleteAt (pl_covers find _cover);
                    };
                };
            };
        } forEach _covers;
        if ((unitPos _unit) == "Auto") then {
            _unit setUnitPos "DOWN";
            doStop _unit;
            _unit doWatch _watchPos;
            _unit disableAI "PATH";
        };
    }
    else
    {
        _unit setUnitPos "DOWN";
        if (_moveBehind) then {
            _checkPos = [20 *(sin _watchDir), 20 *(cos _watchDir), 0.25] vectorAdd (getPosASL _unit);

            // // _helper = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
            // // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
            // // _helper setposASL _checkPos;
            // // _cansee = [_helper, "VIEW"] checkVisibility [(eyePos _unit), _checkPos];

            _unitPos = [0, 0, 0.25] vectorAdd (getPosASL _unit);
            _cansee = [_unit, "FIRE"] checkVisibility [_unitPos, _checkPos];
            // _unit sideChat str _cansee;
            if (_cansee < 0.6) then {
                _unit setUnitPos "MIDDLE";
            };
        };
        doStop _unit;
        _unit doWatch _watchPos;
        _unit disableAI "PATH";
    };
};