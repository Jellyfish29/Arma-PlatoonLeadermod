sleep 1;


pl_draw_3d_icon = {

params ["_group", "_type"];
private _r = -1;

if (pl_enable_3d_mil_symbols) then {
    _r = addMissionEventHandler ["Draw3D", {
        _group = _thisArgs#0;
        _type = _thisArgs#1;
        _distance = (leader _group) distance2D player;
        _mPos = (getPos leader _group) vectorAdd [0,0,3];
        _size = (1.8 - ((_distance * 0.06) - (_distance * 0.057)));
        drawIcon3D [
            _type, //texture)
            [0,0,0,0.5], //color
            _mPos, //pos
            _size, //width
            _size, //height,
            0, //angle,
            "", //text,
            true, //shadow,
            0.05, //textSize,
            'EtelkaMonospacePro', //font
            "center", //textAlign,
            false, //drawSideArrows,
            0, //offsetX,
            0 //offsetY
        ];
        },
        [_group, _type]];
    };
    _r
};

pl_remove_3d_icon = {
    params ["_eh"];

    if (_eh > 0) then {

        removeMissionEventHandler ["Draw3D", _eh];
    };
};



pl_draw_3dline_array = [];

pl_3d_interface = {

    private _eventHandlers3D = [];

    while {true} do {

        
        if (pl_enable_3d_icons and hcShownBar) then {
            {
                _group = _x;
                if (_group == group player) then {continue};
                // _pos3D = getPosATLVisual (vehicle (leader _group));
                private _alpha = 0.6;
                _distance = round ((leader _group) distance2D player);

                if (_distance < 800) then {

                    if (pl_enable_map_radio) then {
                        _radioText = _group getVariable ['pl_radio_text',''];
                        if !(_radioText isEqualTo '') then {
                            _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                                drawIcon3D [
                                    '\A3\modules_f_curator\data\portraitRadioChannelCreate_ca.paa', //texture)
                                    [0.9,0.9,0,0.8], //color
                                    [0,0, 3 + (_thisArgs#1) * 0.03] vectorAdd (getPosATLVisual (_thisArgs#0)), //pos
                                    0.7, //width
                                    0.7, //height,
                                    0, //angle,
                                    _thisArgs#2, //text,
                                    true, //shadow,
                                    0.02, //textSize,
                                    'EtelkaMonospacePro', //font
                                    "right", //textAlign,
                                    false, //drawSideArrows,
                                    0, //offsetX,
                                    0 //offsetY
                                ];
                            }, [vehicle (leader _group), _distance, _radioText]];
                        };
                    };

                    if (_group in (hcSelected player)) then {

                        _alpha = 0.9;

                        if (vehicle (leader _group) == (leader _group)) then {
                            {
                                _unit = _x;
                                // _pos3DUnit = [0,0,1] vectorAdd (getPosATLVisual _x);
                                _icon = getText (configfile >> 'CfgVehicles' >> typeof (vehicle _x) >> 'icon');

                                _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                                    drawIcon3D [
                                        _thisArgs#0, //texture)
                                        _thisArgs#2, //color
                                        [0,0,1] vectorAdd (getPosATLVisual (_thisArgs#1)), //pos
                                        0.55, //width
                                        0.55, //height,
                                        0, //angle,
                                        "", //text,
                                        true, //shadow,
                                        0, //textSize,
                                        'EtelkaMonospacePro', //font
                                        "center", //textAlign,
                                        false, //drawSideArrows,
                                        0, //offsetX,
                                        0 //offsetY
                                    ];
                                }, [_icon, _unit, [_unit] call pl_get_unit_color]];
                            } forEach (units _group);
                        };

                        // show WP
                    //     if (count (waypoints _group) > 0) then {

                    //         _wps = waypoints _group;

                    //         if (count _wps >= 2) then {

                    //             for "_i" from (currentWaypoint _group) to (count _wps) -2 do {

                    //                 _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                    //                     drawLine3D [
                    //                         _thisArgs#0,
                    //                         _thisArgs#1,
                    //                         [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2]
                    //                     ];

                    //                     drawLine3D [
                    //                         _thisArgs#3,
                    //                         _thisArgs#0,
                    //                         [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2]
                    //                     ];

                    //                     drawIcon3D [
                    //                         '\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa', //texture)
                    //                         [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2], //color
                    //                         _thisArgs#0, //pos
                    //                         0.6, //width
                    //                         0.6, //height,
                    //                         0, //angle,
                    //                         "", //text,
                    //                         false, //shadow,
                    //                         0, //textSize,
                    //                         'EtelkaMonospacePro', //font
                    //                         "center", //textAlign,
                    //                         false, //drawSideArrows,
                    //                         0, //offsetX,
                    //                         0 //offsetY
                    //                     ];
                    //                 }, [[0,0,4] vectorAdd (waypointPosition (_wps#_i)), [0,0,4] vectorAdd (waypointPosition (_wps#(_i + 1))), _alpha, waypointPosition (_wps#_i)]];
                    //             };
                    //         };

                    //         _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {

                    //             drawLine3D [
                    //                 _thisArgs#0,
                    //                 _thisArgs#1,
                    //                 [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2]
                    //             ];

                    //             drawIcon3D [
                    //                     '\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa', //texture)
                    //                     [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2], //color
                    //                     _thisArgs#1, //pos
                    //                     0.6, //width
                    //                     0.6, //height,
                    //                     0, //angle,
                    //                     "", //text,
                    //                     false, //shadow,
                    //                     0, //textSize,
                    //                     'EtelkaMonospacePro', //font
                    //                     "center", //textAlign,
                    //                     false, //drawSideArrows,
                    //                     0, //offsetX,
                    //                     0 //offsetY
                    //                 ];
                    //             }, [waypointPosition (_wps#((count _wps) - 1)), [0,0,4] vectorAdd (waypointPosition (_wps#((count _wps) - 1))), _alpha]];

                    //         if ((currentWaypoint _group) < (count _wps)) then {
                    //             _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                    //                 drawLine3D [
                    //                     getPos (leader (_thisArgs#0)),
                    //                     _thisArgs#1,
                    //                     [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2]
                    //                 ];
                    //             }, [_group, [0,0,4] vectorAdd (waypointPosition (_wps#(currentWaypoint _group))), _alpha]];
                    //         };
                    //     };
                    };

                    if (_group getVariable ["inContact", false]) then {

                        _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                            drawIcon3D [
                                '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa', //texture)
                                [0.7,0,0,0.7], //color
                                [0, 0, 2] vectorAdd (getPosATLVisual (_thisArgs#0)), //pos
                                0.4, //width
                                0.4, //height,
                                0, //angle,
                                "", //text,
                                false, //shadow,
                                0, //textSize,
                                'EtelkaMonospacePro', //font
                                "center", //textAlign,
                                false, //drawSideArrows,
                                0, //offsetX,
                                0 //offsetY
                            ];
                        }, [leader _group]];
                    };

                    // show distance to player  
                    _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                        drawIcon3D [
                            "", //texture)
                            [pl_side_color_rgb#0, pl_side_color_rgb#1, pl_side_color_rgb#2, _thisArgs#2], //color
                            [0,0,5 + (_thisArgs#0) * 0.06] vectorAdd (getPosATLVisual (leader (_thisArgs#1))), //pos
                            0.6, //width
                            0.6, //height,
                            0, //angle,
                            format ["%1: %2m",groupid (_thisArgs#1), _thisArgs#0], //text,
                            false, //shadow,
                            0.02, //textSize,
                            'EtelkaMonospacePro', //font
                            "center", //textAlign,
                            false, //drawSideArrows,
                            0, //offsetX,
                            0 //offsetY
                        ];
                    }, [_distance, _group, _alpha]];

                    if ((_group getVariable ["onTask", false]) or (_group getVariable ["pl_task_planed", false])) then {

                        _iconPos3DTask = [0, 0, 6] vectorAdd (_group getVariable ["pl_task_pos", [0,0,0]]);
                        // _iconPos3DTask = [0,0, (player distance2D (_group getVariable ["pl_task_pos", [0,0,0]])) * 0.025] vectorAdd (_group getVariable ["pl_task_pos", [0,0,0]]);
                        _icon = _group getVariable ["specialIcon", ""];

                        if (!(_iconPos3DTask isEqualTo [0,0,6]) and !(_icon isEqualTo "")) then {

                            // systemChat str (_group getVariable ["pl_task_pos", "nein"]);
                            // systemChat str _group;

                            _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {

                                drawIcon3D [
                                    _thisArgs#0, //texture)
                                    [0.9,0.9,0, _thisArgs#3], //color
                                    _thisArgs#1, //pos
                                    0.6, //width
                                    0.6, //height,
                                    0, //angle,
                                    format ["%1m", round ((leader (_thisArgs#2)) distance2D (_thisArgs#1))], //text,
                                    false, //shadow,
                                    0.02, //textSize,
                                    'EtelkaMonospacePro', //font
                                    "center", //textAlign,
                                    false, //drawSideArrows,
                                    0, //offsetX,
                                    0 //offsetY
                                ];

                                drawLine3D [
                                    _thisArgs#1,
                                    (_thisArgs#2) getVariable "pl_task_pos",
                                    [0.9,0.9,0,_thisArgs#3]
                                ];

                                // if !(((_thisArgs#2) getVariable ["pl_grp_task_plan_wp", []]) isEqualTo []) then {

                                //     drawLine3D [
                                //         [0,0,4] vectorAdd (waypointPosition ((_thisArgs#2) getVariable ["pl_grp_task_plan_wp", []])),
                                //         _thisArgs#1,
                                //         [0.9,0.9,0,_thisArgs#3]
                                //     ];

                                // } else {

                                if (((_thisArgs#1) distance2d (getPosATLVisual (vehicle (leader (_thisArgs#2)))) > 15)) then {

                                    drawLine3D [
                                        [0,0,2] vectorAdd (getPosATLVisual (vehicle (leader (_thisArgs#2)))),
                                        _thisArgs#1,
                                        [0.9,0.9,0,_thisArgs#3]
                                    ];
                                };
                                // };

                            }, [_icon, _iconPos3DTask, _group, _alpha]];
                        };
                    };

                };

            } forEach (allGroups select {hcLeader _x isEqualTo player});

            {
                _opfGrp = (pl_marta_dic get _x)#0;

                _opfDistance = ([((leader _opfGrp) distance2D player) / 50, 0] call BIS_fnc_cutDecimals) * 50;

                if (_opfDistance <= 1500) then {

                    _opfMarker =((pl_marta_dic get _x)#1)#0;

                    _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                        drawIcon3D [
                            _thisArgs#0, //texture)
                            _thisArgs#1, //color
                            _thisArgs#2, //pos
                            0.6, //width
                            0.6, //height,
                            0, //angle,
                            _thisArgs#3, //text,
                            false, //shadow,
                            0.02, //textSize,
                            'EtelkaMonospacePro', //font
                            "right", //textAlign,
                            false, //drawSideArrows,
                            0, //offsetX,
                            0 //offsetY
                        ];

                        drawLine3D [
                            _thisArgs#2,
                            _thisArgs#4,
                            _thisArgs#1
                        ];
                    },[
                        format ['\Plmod\gfx\marta\%1.paa', markerType _opfMarker],
                        [leader _opfGrp, 0.5] call pl_get_side_color_rgb,
                        [0,0,_opfDistance * 0.025] vectorAdd (getmarkerPos [_opfMarker, false]),
                        format ["%1m", _opfDistance],
                        getmarkerPos [_opfMarker, false]]];
                };
            } forEach (keys pl_marta_dic);


            {
                _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {
                    drawLine3D [
                        getPosATL (_thisArgs#0),
                        getPosATL (_thisArgs#1),
                        [0.9,0.9,0,1]
                    ];
                },[_x#0, _x#1]];

            } forEach pl_draw_3dline_array;


            {

                _targetPos3D = _x#0;
                _spGrp  = _x#1;
                _spDistance = round (_targetPos3D distance2D player);

                _eventHandlers3D pushback addMissionEventHandler ["Draw3D", {

                    drawIcon3D [
                        '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa', //texture)
                        [0.92,0.24,0.07,1], //color
                        _thisArgs#0, //pos
                        0.6, //width
                        0.6, //height,
                        0, //angle,
                        _thisArgs#1, //text,
                        false, //shadow,
                        0.02, //textSize,
                        'EtelkaMonospacePro', //font
                        "center", //textAlign,
                        false, //drawSideArrows,
                        0, //offsetX,
                        0 //offsetY
                    ];

                    drawLine3D [
                        _thisArgs#0,
                        _thisArgs#2,
                        [1,0.0,0.0,1]
                    ];
                }, [[0,0,3] vectorAdd _targetPos3D, format ["%1m", _spDistance], [0,0,2] vectorAdd (getPosATLVisual (leader _spGrp))]];
            } forEach pl_suppression_poses;

        };

        sleep 2.5;

        {
            removeMissionEventHandler ["Draw3D", _x];
        } forEach _eventHandlers3D

    };
};

[] spawn pl_3d_interface;


pl_3dIcon_select_cd = 0;
addMissionEventHandler ["GroupIconOverEnter", {
    params [
        "_is3D", "_group", "_waypointId",
        "_posX", "_posY",
        "_shift", "_control", "_alt"
    ];
    if (inputAction "BuldTextureInfo" > 0 and ((side (leader _group)) isEqualTo playerside)) then {
        if (time > pl_3dIcon_select_cd) then {
            playsound "beep";
            player hcSelectGroup [_group];
            pl_3dIcon_select_cd = time + 1.5;
        };
    };
}];

