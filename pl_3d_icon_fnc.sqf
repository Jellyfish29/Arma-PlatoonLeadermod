sleep 1;

if !(pl_enable_3d_icons) exitWith {};

addMissionEventHandler ["Draw3D", {
    {


        if (hcShownBar and _x getVariable ["pl_show_info", false]) then {
            _pos = getPosATLVisual (vehicle (leader _x));
            if ((vehicle (leader _x)) isKindOf "Air") exitWith{};
            if ((count (units _group)) < 1) exitWith{};
            _distance = round (player distance2D (leader _x));

            _offset = 0.03 * _distance;
            _dir = (getPosATLVisual player) getDir _pos;

            _callsignText = format ["%1 (%2m)", (groupId _x), _distance];
            drawIcon3D [
                '',
                [0,0.3,0.6,0.7],
                [(_pos select 0),(_pos select 1), 5 + _offset],
                0,
                0,
                0,
                _callsignText,
                2,
                0.02,
                'TahomaB'];

            if (_x getVariable ["inContact", false] or (_x in hcSelected player) or ((_x getVariable ["pl_show_3d_info", false] and _x getVariable ["pl_show_info", false]))) then {
                _cdir = _dir - 90;
                _contactPos = [_offset * (sin _cdir),  _offset * (cos _cdir), 4] vectorAdd _pos;

                _contactColor = [0.4,1,0.2,0.7];
                if (_x getVariable ['pl_hold_fire', false]) then {
                    _contactColor = [0.1,0.1,0.6,0.7];
                };
                if (_x getVariable ["inContact", false]) then {
                    _contactColor = [0.7,0,0,0.7];
                };
                drawIcon3D [
                    '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa',
                    _contactColor,
                    _contactPos,
                    0.4,
                    0.4,
                    0,
                    "",
                    1,
                    0
                    ];
            };

            if ((_x getVariable ["pl_show_3d_info", false] and _x getVariable ["pl_show_info", false]) or (_x in hcSelected player)) then {


                _bdir = _dir + 90;
                _behaviourPos = [_offset * (sin _bdir),  _offset * (cos _bdir), 4] vectorAdd _pos;

                _behaviour = behaviour (leader _x);
                _behaviourColor = [0.4,1,0.2,0.7];
                _behaviuorIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\listen_ca.paa';
                if (_behaviour isEqualTo 'COMBAT') then {
                    _behaviourColor = [0.7,0,0,0.7];
                    _behaviuorIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\danger_ca.paa';
                };
                if (_behaviour isEqualTo 'STEALTH') then {
                    _behaviourColor = [0.1,0.1,0.6,0.7];
                    _behaviuorIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa';
                };
                if (_behaviour isEqualTo 'SAFE') then {
                    _behaviourColor = [0.9,0.9,0.9,0.7];
                    _behaviuorIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa';
                };
                drawIcon3D [
                        _behaviuorIcon,
                        _behaviourColor,
                        _behaviourPos,
                        0.4,
                        0.4,
                        0,
                        "",
                        1,
                        0
                        ];

                
                _specialPos = [0 * (sin _bdir),  0 * (cos _bdir), 3 - _offset] vectorAdd _pos;

                _setSpecial = _x getVariable 'setSpecial';
                _specialIcon = _x getVariable 'specialIcon';
                _specialColor = [0.9,0.9,0,0.7];
                if (_x getVariable ['pl_on_hold', false]) then {_specialColor = [0.92,0.24,0.07,1];};

                if (_setSpecial) then {
                    drawIcon3D [
                        _specialIcon,
                        _specialColor,
                        _specialPos,
                        0.4,
                        0.4,
                        0,
                        "",
                        1,
                        0
                        ];
                };

                _strength = count (units _x);
                _strengthTxt = format ["                      %1", _strength];
                _healthColor = [_x] call pl_get_group_health;
                drawIcon3D [
                        "",
                        _healthColor,
                        [(_pos # 0) ,(_pos # 1) , 5 + _offset],
                        0,
                        0,
                        0,
                        _strengthTxt,
                        2,
                        0.025,
                        'TahomaB'];
            };
        };
    } forEach (allGroups select {side _x isEqualTo playerSide});

}];

pl_3dIcon_select_cd = 0;
addMissionEventHandler ["GroupIconOverEnter", {
    params [
        "_is3D", "_group", "_waypointId",
        "_posX", "_posY",
        "_shift", "_control", "_alt"
    ];
    if (_is3D) then {
        _group setVariable ["pl_show_3d_info", true];
    };
    if (_shift and ((side (leader _group)) isEqualTo playerside)) then {
        if (time > pl_3dIcon_select_cd) then {
            playsound "beep";
            player hcSelectGroup [_group];
            pl_3dIcon_select_cd = time + 1.5;
        };
    };
}];

addMissionEventHandler ["GroupIconOverLeave", {
    params [
        "_is3D", "_group", "_waypointId",
        "_posX", "_posY",
        "_shift", "_control", "_alt"
    ];
    if (_is3D) then {
        _group setVariable ["pl_show_3d_info", false];
    };
}];