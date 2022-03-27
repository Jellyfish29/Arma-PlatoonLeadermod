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



addMissionEventHandler ["Draw3D", {
     
    if (pl_enable_3d_icons and hcShownBar) then { 
        {
            _group = _x;
            _distance = (leader _group) distance2D player;
            _pos3D = ASLToAGL getPosASLVisual (vehicle (leader _group));

            if (_group getVariable ["inContact", false]) then {
                _iconPos3D = [0, 0, 2] vectorAdd _pos3D;
                drawIcon3D [
                    '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa', //texture)
                    [0.7,0,0,0.7], //color
                    _iconPos3D, //pos
                    0.4, //width
                    0.4, //height,
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
            };

            if (pl_enable_map_radio) then {
                _radioText = _group getVariable ['pl_radio_text',''];
                if !(_radioText isEqualTo '') then {
                    _radioPos3D = [0,0, 3 + _distance * 0.03] vectorAdd _pos3D;
                    drawIcon3D [
                        '\A3\modules_f_curator\data\portraitRadioChannelCreate_ca.paa', //texture)
                        [0.9,0.9,0,0.8], //color
                        _radioPos3D, //pos
                        0.7, //width
                        0.7, //height,
                        0, //angle,
                        _radioText, //text,
                        true, //shadow,
                        0.02, //textSize,
                        'EtelkaMonospacePro', //font
                        "right", //textAlign,
                        false, //drawSideArrows,
                        0, //offsetX,
                        0 //offsetY
                    ];
                };
            }; 

       } forEach (allGroups select {hcLeader _x isEqualTo player});
    };
}];

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
