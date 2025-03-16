#include "\a3\editor_f\Data\Scripts\dikCodes.h"

sleep 2;

pl_get_group_health = {
    params ["_group"];
    private ["_healthState"];
    _healthState = [0.4,1,0.2,1];
    {
        if ((damage _x) > 0.15) then {
            _healthState = [0.9,0.9,0,1];
        };
        if ((lifeState _x) isEqualTo "INCAPACITATED") exitWith {
            _healthState = [0.7,0,0,1];
        };
    } forEach (units _group);
    _healthState;
};

pl_get_unit_color = {
    params ["_unit"];
    if (_unit getVariable ['pl_wia', false]) exitWith {[0.9,0,0,0.8]}; //[0.7,0,0,1]
    if (_unit getVariable ['pl_firing', false]) exitWith {[0.92,0.24,0.07,1]};
    if (_unit getVariable ['pl_is_ccp_medic', false]) exitWith {[0.4,1,0.2,0.9]};
    if (_unit getVariable ['pl_is_at', false]) exitWith {[1,0.7,0.4,0.8]};
    pl_side_color_rgb
};

pl_get_side_color_rgb = {
    params ["_unit", ["_alpha", 0.7]];

    private _sideColorRGB = [0,0.3,0.6,_alpha];

    switch (side _unit) do { 
        case west : {_sideColorRGB = [0,0.3,0.6,_alpha]}; 
        case east : {_sideColorRGB = [0.5,0,0,_alpha]};
        case resistance : {__sideColorRGB = [0,0.5,0,_alpha]};
        default {_sideColorRGB = [0.5,0,0,_alpha]}; 
    };

    _sideColorRGB
};

pl_get_vic_health = {
    params ["_vic"];
    if !([_vic] call pl_canMove) exitWith {[0.49,0.06,0.8,0.8]}; // 7E11CA};
    if ((damage _vic) > 0) exitWith {[0.9,0.7,0.1,0.8]};
    if ((damage _vic) > 0.6) exitWith {[0.7,0,0,0.8]};
    pl_side_color_rgb
};

pl_get_vic_speed_color = {
    params ["_vic"];
    _vicSpeedLimit = _vic getVariable 'pl_speed_limit';
    _vicSpeedColor = [0.9, 0.9, 0.9,1];
    switch (_vicSpeedLimit) do { 
        case '50' : {_vicSpeedColor = [0.4,1,0.2,1]}; 
        case '30' : {_vicSpeedColor = [0.9,0.9,0,1]};
        case '15' : {_vicSpeedColor = [0.7,0,0,1]}; 
        case 'CON' : {_vicSpeedColor = [0.92,0.24,0.07,1]}; 
        default {_vicSpeedColor = [0.4,1,0.2,1]}; 
    };
    // if (_vic getVariable ["pl_force_road", false]) then {_vicSpeedColor = [0,0,0.8,1]};
    _vicSpeedColor
};

pl_get_at_status = {
    params ["_group"];
    private ["_ammoStatus", "_liveStatus", "_missileCount", "_c "];

    _ammoStatus = false;
    _liveStatus = false;
    _c = 0;
    { 
        _c = _c + 1;
        _unit = _x;
        _missileCount = ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit);
        if (toUpper ((secondaryWeaponMagazine _unit)#0) in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "magazines") apply {toUpper _x})) then {_missileCount = _missileCount + 1};
        if (_missileCount <= 0 ) then {_ammoStatus = true};

        if (!alive _unit or _unit getVariable ["pl_wia", false] or (lifeState _unit isEqualTo "INCAPACITATED")) then {
            _liveStatus = true;
        };
    } forEach ((units _group) select {secondaryWeapon _x != ""});

    if (_group getVariable ["pl_has_at", false] and _c <= 0) then {_liveStatus = true};

    [_ammoStatus, _liveStatus]
};

pl_get_mg_status = {
    params ["_group"];
    private ["_ammoStatus", "_liveStatus", "_c"];

    _ammoStatus = false;
    _liveStatus = false;
    _c = 0;
    {   
        _c = _c + 1;
        _unit = _x;
        if (({toUpper _x in (getArray (configFile >> "CfgWeapons" >> primaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit) <= 0) then {
            _ammoStatus = true;
        };
        if (!alive _unit or _unit getVariable ["pl_wia", false] or (lifeState _unit isEqualTo "INCAPACITATED")) then {
            _liveStatus = true;
        };
    } forEach ((units _group) select {(primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun"});

    if (_group getVariable ["pl_has_mg", false] and _c <= 0) then {_liveStatus = true};

    [_ammoStatus, _liveStatus]
};


pl_update_group_ammo_status = {

    {
        _group = _x;
        _mg = {
            if ((primaryweapon _x call BIS_fnc_itemtype) select 1 == "MachineGun") exitWith {true};
            false
        } forEach (units _group);
        _at = {
            if (secondaryWeapon _x != "") exitWith {true};
            false
        } forEach (units _group);
        _group setVariable ["pl_has_mg", _mg];
        _group setVariable ["pl_has_at", _at];
    } forEach (allGroups select {hcLeader _x == player});

    sleep 8;
    
    while {true} do {
        {
            _x setVariable ["pl_group_mg_status", [_x] call pl_get_mg_status];
            _x setVariable ["pl_group_at_status", [_x] call pl_get_at_status];
            _x setVariable ["pl_group_ammo_status", [_x] call pl_get_ammo_group_state];
        } forEach (allGroups select {hcLeader _x == player});
        sleep 2;
    };
};

[] spawn pl_update_group_ammo_status;

pl_world_size_x = round (worldSize * 0.03);
pl_world_size_y = round (worldSize * 0.02);

pl_draw_group_info = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        {
            if (hcShownBar and (_x getVariable ['pl_show_info', false])) then {
                pl_map_scale = ctrlMapScale (_this select 0);
                pl_map_scale_x = pl_map_scale * pl_world_size_x;
                pl_map_scale_y = pl_map_scale * pl_world_size_y;
                if ((getText (configFile >> 'CfgVehicles' >> typeOf (units _x select 0)>> 'displayName')) isEqualTo 'Game Logic') exitWith {};
                {
                    _unit = _x;
                    if ((isNull objectParent _x or _unit getVariable ['pl_in_static', false]) and (alive _unit)) then {
                        _icon = getText (configfile >> 'CfgVehicles' >> typeof (vehicle _unit) >> 'icon');
                        _size = 10;
                        _unitColor = [_unit] call pl_get_unit_color;
                        _display drawIcon [
                            _icon,
                            _unitColor,
                            getPosVisual _unit,
                            _size,
                            _size,
                            getDirVisual _unit
                        ];
                        if (_unitColor isEqualTo [0.9,0,0,1]) then {
                            _display drawLine [
                                getPosVisual _unit,
                                getPosVisual (leader (group _unit)),
                                _unitColor
                            ];
                        };
                    };
                } forEach (units _x);
                _pos = getPosVisual (vehicle (leader _x));
                _callsignText = format ['  %1', groupId _x];
                if (count (units _x) == 1 and _x != (group player)) then {
                    _unitMos = getText (configFile >> 'CfgVehicles' >> typeOf (units _x select 0)>> 'displayName');
                    if ((vehicle (units _x select 0)) != (units _x select 0)) then {
                        _unitMos = getText (configFile >> 'CfgVehicles' >> typeOf (vehicle (units _x select 0))>> 'displayName');
                        if ((vehicle (units _x select 0)) isKindOf 'Air') then {
                            _unitMos = groupId _x;
                        };
                    };
                    _callsignText = format ['  %1', _unitMos];
                };
                _display drawIcon [
                    '#(rgb,4,1,1)color(1,1,1,0)',
                    pl_side_color_rgb,
                    _pos,
                    23,
                    23,
                    0,
                    _callsignText,
                    0,
                    0.025,
                    'EtelkaMonospacePro',
                    'right'
                    ];
                _strength = {alive _x} count (units _x);
                _healthColor = [_x] call pl_get_group_health;
                _strengthText = format ['%1  ', _strength];
                if (_healthColor isEqualto [0.7,0,0,1]) then {
                    _strengthText = format ['%1 ', count ((units _x) select {(lifeState _x) isNotEqualTo 'INCAPACITATED'})];
                };
                _display drawIcon [
                    '#(rgb,4,1,1)color(1,1,1,0)',
                    _healthColor,
                    _pos,
                    23,
                    25,
                    0,
                    _strengthText,
                    1,
                    0.03,
                    'EtelkaMonospacePro',
                    'left'
                ];
                _contactIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa';
                _contactPos = [(_pos select 0) - pl_map_scale_x, (_pos select 1) - pl_map_scale_y];
                _contactColor = [0.4,1,0.2,1];
                _x setVariable ['inContact', false];
                _contactTime = (_x getVariable 'PlContactTime') - 30;
                if (_contactTime > time) then {
                    _contactColor = [0.7,0,0,1];
                    _x setVariable ['inContact', true];
                };
                if (_x getVariable ['pl_hold_fire', false]) then {
                    if ((combatMode _x) isEqualto 'GREEN') then {
                        _contactColor = [0.92,0.24,0.07,1];
                    } else {
                        _contactColor = [0.1,0.1,0.6,1];
                    };
                };
                _display drawIcon [
                    _contactIcon,
                    _contactColor,
                    _contactPos,
                    14,
                    14,
                    0,
                    '',
                    2
                ];
                _behaviourPos = [(_pos select 0) + pl_map_scale_x, (_pos select 1) - pl_map_scale_y];
                _behaviour = behaviour (leader _x);
                _color = [0.4,1,0.2,1];
                _icon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\listen_ca.paa';
                if (_behaviour isEqualTo 'COMBAT') then {
                    _color = [0.7,0,0,1];
                    _icon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\danger_ca.paa';
                };
                if (_behaviour isEqualTo 'STEALTH') then {
                    _color = [0.1,0.1,0.6,1];
                    _icon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa';
                };
                if (_behaviour isEqualTo 'SAFE') then {
                    _color = [0.9,0.9,0.9,1];
                    _icon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa';
                };
                _display drawIcon [
                    _icon,
                    _color,
                    _behaviourPos,
                    12,
                    12,
                    0,
                    '',
                    2
                ];
                if (((_x getVariable ['pl_group_ammo_status', ['Green',0, [0.4,1,0.2,1]]])#0) isEqualTo 'Red') then {
                    _ammoStatusPos = [(_pos select 0) - (pl_map_scale_x * 2.3), _pos select 1];
                    _display drawIcon [
                        '\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa',
                        [1,0,0,0.8],
                        _ammoStatusPos,
                        12,
                        12,
                        0,
                        '',
                        2
                    ];
                };
                if (_x getVariable 'setSpecial') then {
                    _specialIcon = _x getVariable 'specialIcon';
                    _posOffset = pl_map_scale_x + (pl_map_scale_x * 0.85);
                    _specialPos = [(_pos select 0) + _posOffset, (_pos select 1) - pl_map_scale_y];
                    _color = [0.9,0.9,0,1];
                    if (_x getVariable ['pl_on_hold', false]) then {_color = [0.92,0.24,0.07,1];};
                    _display drawIcon [
                        _specialIcon,
                        _color,
                        _specialpos,
                        14,
                        14,
                        0,
                        '',
                        2
                    ];
                };
                if (_x getVariable ['pl_healing_active', false]) then {
                    _healingPos = [(_pos select 0) - (pl_map_scale_x * 1.9), _pos select 1];
                    _color = [0.9,0.9,0,1];
                    if (_x getVariable ['pl_on_hold', false]) then {_color = [0.92,0.24,0.07,1];};
                    _display drawIcon [
                        '\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa',
                        _color,
                        _healingPos,
                        8,
                        8,
                        0,
                        '',
                        2
                    ];
                };

                if ((_x getVariable ['pl_sop_icon', '']) != '') then {
                    _sopPos = [(_pos select 0), (_pos select 1) - (pl_map_scale_y * 2)];
                    _sopIcon = _x getVariable ['pl_sop_icon', ''];
                    _display drawIcon [
                        _sopIcon,
                        [0.92,0.24,0.07,1],
                        _soppos,
                        11,
                        11,
                        0,
                        '',
                        2
                    ];
                };

                if (_x getVariable ['pl_sop_is_jtac', false]) then {
                    _casColor = [0.92,0.24,0.07,1];
                    if (pl_cas_auto_confirm) then {
                        _casColor = [0.4,1,0.2,1];
                    };
                    _display drawIcon [
                        '\A3\ui_f\data\map\markers\military\destroy_CA.paa',
                        _casColor,
                        [(_pos select 0), (_pos select 1) - (pl_map_scale_y * 2.4)],
                        12,
                        12,
                        0,
                        '',
                        2
                    ];
                };


                if ((vehicle (leader _x)) != leader _x) then {
                    _vicPos = [(_pos select 0), (_pos select 1) - (pl_map_scale_y * 1.25)];
                    _vicColor = [vehicle (leader _x)] call pl_get_vic_health;
                    _vicDir = getDir (vehicle (leader _x));
                    _vicIcon = '\A3\ui_f\data\map\MapControl\viewtower_CA.paa';
                    _display drawIcon [
                        _vicIcon,
                        _vicColor,
                        _vicpos,
                        11,
                        11,
                        _vicDir,
                        '',
                        2
                    ];

                    _vicSpeedPos = [(_pos select 0), (_pos select 1) + (pl_map_scale_y * 1.25)];

                    _vicSpeedColor = [vehicle (leader _x)] call pl_get_vic_speed_color;
                    
                    _display drawIcon [
                        '\A3\ui_f\data\map\markers\military\dot_CA.paa',
                        _vicSpeedColor,
                        _vicSpeedPos,
                        12,
                        12,
                        0,
                        '',
                        2
                    ];

                    if (vehicle (leader _x) getVariable ['pl_force_road', false]) then {
                        _display drawIcon [
                            '\A3\ui_f\data\map\MapControl\Tree_CA.paa',
                            _vicSpeedColor,
                            _vicSpeedPos,
                            12,
                            12,
                            0,
                            '',
                            2
                        ];
                    };

                    if (_x getVariable ['pl_has_cargo', false]) then {
                        _cargoPos = [(_pos select 0) - (pl_map_scale_x * 2), _pos select 1];
                        _color = [0.9,0.9,0,1];
                        _display drawIcon [
                            '\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa',
                            _color,
                            _cargoPos,
                            10,
                            10,
                            0,
                            '',
                            2
                        ];
                    };
                }
                else
                {
                    _wStatusPos1 = [(_pos select 0) - (pl_map_scale_x * 1), (_pos select 1) + (pl_map_scale_y * 1)];
                    _wStatusPos2 = [(_pos select 0) - (pl_map_scale_x * 1.8), (_pos select 1) + (pl_map_scale_y * 1)];

                    pl_wStatus_pos = 0;
                    if (true in (_x getVariable ['pl_group_at_status', [false, false]])) then {
                        _atStatusPos = _wStatusPos1;
                        pl_wStatus_pos = pl_wStatus_pos + 1;
                        _statusColor = [1,0.3,0.3,1];
                        if ((_x getVariable ['pl_group_at_status', [false, false]])#1) then {
                            _statusColor = [0.9,0,0,1];
                        };
                        _display drawIcon [
                            '#(rgb,4,1,1)color(1,1,1,0)',
                            _statusColor,
                            _atStatusPos,
                            6,
                            6,
                            0,
                            'AT!',
                            0,
                            0.019,
                            'EtelkaMonospacePro',
                            'center'
                        ];
                    };
                    if (true in (_x getVariable ['pl_group_mg_status', [false, false]])) then {
                        _mgStatusPos = _wStatusPos1;
                        if (pl_wStatus_pos == 1) then {_mgStatusPos = _wStatusPos2};
                        _statusColor = [1,0.7,0.3,1];
                        if ((_x getVariable ['pl_group_mg_status', [false, false]])#1) then {
                            _statusColor = [0.9,0,0,1];
                        };
                        _display drawIcon [
                            '#(rgb,4,1,1)color(1,1,1,0)',
                            _statusColor,
                            _mgStatusPos,
                            6,
                            6,
                            0,
                            'MG!',
                            0,
                            0.019,
                            'EtelkaMonospacePro',
                            'center'
                        ];
                    };

                    _formPos = [(_pos select 0), (_pos select 1) - pl_map_scale_y];
                    _form = formation _x;
                    _formIcon = '\A3\3den\data\Attributes\Formation\wedge_ca.paa';
                    _formationColor = [0.9,0.9,0,1];
                    if (_x getVariable ['pl_choose_auto_formation', false]) then {
                        _formationColor = [0.92,0.24,0.07,1];
                    };
                    switch (_form) do { 
                        case 'COLUMN' : {_formIcon = '\A3\3den\data\Attributes\Formation\column_ca.paa'}; 
                        case 'STAG COLUMN' : {_formIcon = '\A3\3den\data\Attributes\Formation\stag_column_ca.paa'}; 
                        case 'WEDGE' : {_formIcon = '\A3\3den\data\Attributes\Formation\wedge_ca.paa'}; 
                        case 'ECH LEFT' : {_formIcon = '\A3\3den\data\Attributes\Formation\ech_left_ca.paa'}; 
                        case 'ECH RIGHT' : {_formIcon = '\A3\3den\data\Attributes\Formation\ech_right_ca.paa'}; 
                        case 'VEE' : {_formIcon = '\A3\3den\data\Attributes\Formation\vee_ca.paa'}; 
                        case 'LINE' : {_formIcon = '\A3\3den\data\Attributes\Formation\line_ca.paa'};
                        case 'FILE' : {_formIcon = '\A3\3den\data\Attributes\Formation\file_ca.paa'}; 
                        case 'DIAMOND' : {_formIcon = '\A3\3den\data\Attributes\Formation\diamond_ca.paa'}; 
                        default {_formIcon = '\A3\3den\data\Attributes\Formation\line_ca.paa'}; 
                    };
                    _display drawIcon [
                        _formIcon,
                        _formationColor,
                        _formPos,
                        15,
                        15,
                        0,
                        '',
                        2
                    ];
                };

                if (pl_enable_map_radio) then {
                    _radioText = _x getVariable ['pl_radio_text',''];
                    if !(_radioText isEqualTo '') then {
                        _radioPos = [(_pos select 0), (_pos select 1) + pl_map_scale_y * ([1.9, 2] call BIS_fnc_randomNum)];
                        _display drawIcon [
                            '\A3\modules_f_curator\data\portraitRadioChannelCreate_ca.paa',
                            [0.9,0.9,0,1],
                            _radioPos,
                            16,
                            16,
                            0,
                            '',
                            2
                        ];
                        _display drawIcon [
                            '#(rgb,4,1,1)color(1,1,1,0)',
                            [0.9,0.9,0,1],
                            _radioPos,
                            14,
                            14,
                            0,
                            _radioText,
                            2,
                            0.02,
                            'EtelkaMonospacePro',
                            'right'
                        ];
                    };
                }; 
            };
        } forEach (allGroups select {side _x isEqualTo playerSide});
    "]; // "
};

// [findDisplay 12 displayCtrl 51] call pl_draw_group_info;

// if (_x getVariable ['pl_group_mg_status', false]) then {
//     _mgStatusPos = [(_pos select 0) - (pl_map_scale_x * 2.1), (_pos select 1) + (pl_map_scale_y * 1)];
//     _display drawIcon [
//         '\Plmod\gfx\pl_mg_indicator.paa',
//         [1,0,0,0.8],
//         _mgStatusPos,
//         15,
//         15,
//         0,
//         '',
//         2
//     ];
// };
// if (_x getVariable ['pl_group_at_status', false]) then {
//     _atStatusPos = [(_pos select 0) - (pl_map_scale_x * 1), (_pos select 1) + (pl_map_scale_y * 1)];
//     _display drawIcon [
//         '\Plmod\gfx\pl_at_indicator.paa',
//         [1,0,0,0.8],
//         _atStatusPos,
//         15,
//         15,
//         0,
//         '',
//         2
//     ];
// };

pl_mark_vics = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_show_vehicles) then {
            {
                if ((_x distance2D pl_show_vehicles_pos < 150) or (_x isKindOf 'Air')) then {
                    if (((side _x) isEqualTo playerSide) or ((side _x) isEqualTo civilian)) then {
                        if ((_x isKindOf 'Tank') or (_x isKindOf 'Car') or (_x isKindOf 'Air') or (_x isKindOf 'Truck')) then {
                            _vic = _x;
                            _icon = getText (configfile >> 'CfgVehicles' >> typeof _vic >> 'icon');
                            _size = 30;
                            _display drawIcon [
                                _icon,
                                [0.9,0.9,0,1],
                                getPosVisual _vic,
                                _size,
                                _size,
                                getDirVisual _vic
                            ]
                        };
                    };
                };
            } forEach vehicles;
        };
    "]; // "
};

// [] call pl_mark_vics;

pl_convoy_marker = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _convoy = _x;
                {
                    if (_x != (_convoy select 0) and _x getVariable ['pl_draw_convoy', false]) then {
                        _convoyPos = _convoy find _x;
                        _pos1 = getPos (leader _x);
                        _pos2 = getPos (leader (_convoy select (_convoyPos -1)));
                        _display drawLine [
                            _pos1,
                            _pos2,
                            [0.9,0.9,0,1]
                        ];
                    };
                } forEach _convoy;
            } forEach pl_draw_convoy_array;
    "]; // "
};

// [] call pl_convoy_marker;

pl_dead_vics = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_show_dead_vehicles) then {
            {
                _vic = _x #1;
                _icon = getText (configfile >> 'CfgVehicles' >> typeof _vic >> 'icon');
                _size = 30;
                _display drawIcon [
                    _icon,
                    [0.7,0,0,1],
                    getPosVisual _vic,
                    _size,
                    _size,
                    getDirVisual _vic
                ]
            } forEach pl_destroyed_vics_data;
        };
    "]; // "
};

// [] call pl_dead_vics;

pl_damaged_vics = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_show_damaged_vehicles) then {
            {
                if (_x isKindOf 'Tank' or _x isKindOf 'Car' or _x isKindOf 'Truck') then {
                    if ((((pl_show_vehicles_pos distance2D _x) < 300) and ((getDammage _x) > 0 or !(canMove _x)) and alive _x and (side _x) == playerSide) or ((count (crew _x)) <= 0 and ((getDammage _x) > 0 or !(canMove _x)) and alive _x)) then {
                        _vic = _x;
                        _icon = getText (configfile >> 'CfgVehicles' >> typeof _vic >> 'icon');
                        _size = 30;
                        _display drawIcon [
                            _icon,
                            [0.92,0.24,0.07,1],
                            getPosVisual _vic,
                            _size,
                            _size,
                            getDirVisual _vic
                        ]
                    };
                };
            } forEach vehicles;
        };
    "]; // "
};

// [] call pl_damaged_vics;

pl_draw_building_search_marker = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _group = _x select 0;
                _building = _x select 1;
                _pos1 = getPos (leader _group);
                _pos2 = getPos _building;
                _display drawLine [
                    _pos1,
                    _pos2,
                    [0.9,0.9,0,1]
                    ];
            } forEach pl_draw_building_array;
    "]; // "
};

// [] call pl_draw_building_search_marker;

pl_draw_follow_marker = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_follow_active) then {
            {
                _group = _x;
                _pos1 = getPos (leader _group);
                _pos2 = getPos player;
                _display drawLine [
                    _pos1,
                    _pos2,
                    [0.9,0.9,0,1]
                    ];
            } forEach pl_follow_array;
        };
    "]; // "
};

// [] call pl_draw_follow_marker;

pl_draw_defence_line = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = getMarkerPos (_x select 0);
                _pos2 = getPos (_x select 1);
                _display drawLine [
                    _pos1,
                    _pos2,
                    [0.9,0.9,0,1]
                    ];
            } forEach pl_denfence_draw_array;
    "]; // "
};

// [] call pl_draw_defence_line;

pl_draw_bounding_line = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = getPos (leader (_x select 0));
                _pos2 =_x select 1;
                _display drawArrow [
                    _pos1,
                    _pos2,
                    [0.9,0.9,0,1]
                    ];
            } forEach pl_bounding_draw_array;
    "]; // "
};

// [] call pl_draw_bounding_line;

pl_draw_follow_marker_other = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = getPos (leader (_x select 0));
                _pos2 = getPos (leader (_x select 1));
                _display drawLine [
                    _pos1,
                    _pos2,
                    [0.9,0.9,0,1]
                    ];
            } forEach pl_follow_array_other;
    "]; // "
};

// [] call pl_draw_follow_marker_other;

pl_draw_follow_marker_other_setup = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = getPos (leader _x);
                _pos2 = [];
                if (visibleMap) then {
                    _pos2 = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _pos2 = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };
                _display drawLine [
                    _pos1,
                    _pos2,
                    [0.9,0.9,0,1]
                    ];
            } forEach pl_follow_array_other_setup;
    "]; // "
};

// [] call pl_draw_follow_marker_other_setup;

pl_draw_left_vehicles = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = getPos (_x select 0);
                _pos2 = getPos (leader (_x select 1));
                _display drawLine [
                    _pos1,
                    _pos2,
                    [0,0.3,0.6,0.3]
                    ];
                _vic = _x#0;
                _icon = getText (configfile >> 'CfgVehicles' >> typeof _vic >> 'icon');
                _size = 25;
                _display drawIcon [
                    _icon,
                    [0,0.3,0.6,0.3],
                    getPosVisual _vic,
                    _size,
                    _size,
                    getDirVisual _vic
                ]
            } forEach pl_left_vehicles;
    "]; // "
};

// [] call pl_draw_left_vehicles;


pl_draw_planed_task = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _wp = _x select 0;
                    _icon = _x select 1;
                    _pos = waypointPosition _wp;
                    _color = [0.9,0.9,0,1];
                    _display drawIcon [
                        _icon,
                        _color,
                        _pos,
                        15,
                        15,
                        0,
                        '',
                        2
                    ];
            } forEach pl_draw_planed_task_array;
    "]; // "
};

// [] call pl_draw_planed_task;

pl_draw_planed_task_array_wp = [];

pl_draw_planed_task_wp = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _pos_dest = _x select 0;
                    _pos_src = waypointPosition (_x select 1);
                    _icon = _x select 2;
                    _color = [0.9,0.9,0,1];
                    _display drawIcon [
                        _icon,
                        _color,
                        _pos_dest,
                        15,
                        15,
                        0,
                        '',
                        2
                    ];

                    _display drawLine [
                        _pos_src,
                        _pos_dest,
                        [0.9,0.9,0,1]
                    ];

            } forEach pl_draw_planed_task_array_wp;
    "]; // "
};

// [] call pl_draw_planed_task_wp;

pl_show_charges = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                 _charges = _x getVariable ['pl_placed_charges', []];
                 _pos1 = getPos (leader _x);
                 {
                    _pos2 = getPos _x;
                    _display drawLine [
                        _pos1,
                        _pos2,
                        [0.7,0,0,1]
                    ];

                    _display drawIcon [
                        '\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa',
                        [0.7,0,0,1],
                        _pos2,
                        15,
                        15,
                        0,
                        '',
                        2,
                        0.05
                    ];
                } forEach _charges;
            } forEach pl_groups_with_charges;
    "]; // "
};

// [] call pl_show_charges;

pl_draw_suppression = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _targetPos = _x select 0;
                    _grpPos = getPos (_x select 1);
                    _icon = _x select 3;
                    _color = [0.9,0.9,0,1];
                    _text = '';
                    if (_x select 2) then {
                        _color = [0.7,0,0,1];
                        _text = 'C';
                    };
                    _display drawIcon [
                        _icon,
                        _color,
                        _targetPos,
                        15,
                        15,
                        0,
                        _text,
                        2,
                        0.05
                    ];

                    _display drawLine [
                        _grpPos,
                        _targetPos,
                        _color
                    ];

            } forEach pl_draw_suppression_array;
    "]; // "
};

pl_draw_auto_suppression = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _targetPos = _x#0;
                    _grpPos = getPos (leader (_x#1));
                    _color = [0.92,0.24,0.07,1];
                    _text = '';
                    _display drawIcon [
                        '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa',
                        _color,
                        _targetPos,
                        15,
                        15,
                        0,
                        _text,
                        2,
                        0.05
                    ];

                    _display drawLine [
                        _grpPos,
                        _targetPos,
                        _color
                    ];

            } forEach pl_suppression_poses;
    "]; // "
};

// [] call pl_draw_suppression;

pl_draw_resupply_line = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = _x select 0;
                _pos2 =_x select 1;
                _color = _x select 2;
                _display drawArrow [
                    _pos1,
                    _pos2,
                    _color
                    ];
            } forEach pl_supply_draw_array;
    "]; // "
};

// [] call pl_draw_resupply_line;

pl_draw_formation_move_mouse = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_draw_formation_mouse) then {
            {
                _vic = _x#0;
                _relPos = _x#1;
                _wpPos = _x#2;
                _formationLeader = (pl_draw_formation_move_mouse_array#0)#0;
                _mPos = [];
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };
                _vicPos = getPos _vic;
                _newPos = [(_mPos select 0) + (_relPos select 0), (_mPos select 1) + (_relPos select 1)];
                _vDir = _wpPos getDir _newPos;
                _icon = getText (configfile >> 'CfgVehicles' >> typeof _vic >> 'icon');
                _size = 30;

                _display drawLine [
                    _wpPos,
                    _newPos,
                    [0.9,0.9,0,1]
                    ];

                _display drawIcon [
                    _icon,
                    [0.9,0.9,0,1],
                    _newPos,
                    _size,
                    _size,
                    _vDir
                ]
            } forEach pl_draw_formation_move_mouse_array;
        };
    "]; // "
};

// [] call pl_draw_formation_move_mouse;


pl_draw_sync_wps = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                for '_i' from ((count _x) - 1) to 1 step -1 do {
                    _pos1 = waypointPosition (_x#_i);
                    _pos2 = waypointPosition (_x#(_i - 1));
                    _grp = (_x#_i)#0;
                    if (((leader _grp) distance2d _pos1) < 20) then {
                        _x deleteAt (_x find (_x#_i));
                    };

                    if (!(_pos1 isEqualto [0,0,0]) and !(_pos2 isEqualto [0,0,0])) then {
                        _display drawLine [
                            _pos1,
                            _pos2,
                            [0.92,0.24,0.07,1]
                        ];
                    };
                };
            } forEach pl_draw_sync_wp_array;
    "]; // "
};

// [] call pl_draw_sync_wps;

// pl_draw_tank_hunt = {
//     params ["_display"];
//    _display ctrlAddEventHandler ["Draw","
//         _display = _this#0;
//         if (hcShownBar) then {
//             {
//                 _pos1 = _x;
//                 _pos2 = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
//                 _display drawLine [
//                     _pos1,
//                     _pos2,
//                     [0.7,0,0,1]
//                 ];
//             } forEach pl_draw_tank_hunt_array
//         };
//     "]; // "
// };

// [] call pl_draw_tank_hunt;

pl_mark_supllies = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_show_supllies) then {
            {
                _box = _x;
                _icon = getText (configfile >> 'CfgVehicles' >> typeof _box >> 'icon');
                _size = 15;
                if (_box isKindOf 'WeaponHolder') then { _size = 8};
                _display drawIcon [
                    _icon,
                    [0.9,0.9,0,1],
                    getPosVisual _box,
                    _size,
                    _size,
                    getDirVisual _box
                ];
            } forEach ((pl_show_supplies_pos nearSupplies 150) select {!(_x isKindOf 'Man')});
        };
    "]; // "
};

// [] call pl_mark_supllies;

pl_draw_unload_inf_task_plan_icon = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos = [0, 15, 0] vectorAdd (_x#1);
                _color = [0.9,0.9,0,1];
                _display drawIcon [
                    '\A3\ui_f\data\map\markers\nato\b_inf.paa',
                    _color,
                    _pos,
                    15,
                    15,
                    0,
                    '',
                    2
                ];

                _mpos = _display ctrlMapScreenToWorld getMousePosition;
                if (inputAction 'zoomTemp' > 0 and (_mpos distance2D _pos) < 15) then {
                    pl_draw_unload_inf_task_plan_icon_array = pl_draw_unload_inf_task_plan_icon_array - [[_x#0, _x#1]];
                    [_x#0, _x#1] spawn pl_unload_inf_follow_up_plan;
                };

                if (leader (_x#0) distance2D (_x#1) <= 40) then {
                    pl_draw_unload_inf_task_plan_icon_array = pl_draw_unload_inf_task_plan_icon_array - [[_x#0, _x#1]];
                }

            } forEach pl_draw_unload_inf_task_plan_icon_array;
    "]; // "
};

// [] call pl_draw_unload_inf_task_plan_icon;


pl_draw_ccp_medic = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = _x select 0;
                _pos2 = getPos (_x select 1);
                if !(isNull (_x#1)) then {
                    _display drawLine [
                        _pos1,
                        _pos2,
                        [0.4,1,0.2,0.8]
                    ];
                };
            } forEach pl_ccp_draw_array;
    "]; // "
};

// [] call pl_draw_ccp_medic;


pl_draw_unit_group_lines = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = getPos (leader _x);
                {
                    if (alive _x) then {
                        _pos2 = getPos _x;
                        _color = pl_side_color_rgb;
                        if (_x getVariable ['pl_wia', false]) then {_color = [0.9,0,0,0.4]};
                        _display drawLine [
                            _pos1,
                            _pos2,
                            _color
                            ];
                    };
                } forEach ((units _x) - [leader _x]);
            } forEach ((hcSelected player) select {(vehicle (leader _x)) == (leader _x)});
    "]; // "
};

// [findDisplay 12 displayCtrl 51] call pl_draw_unit_group_lines;
// allGroups select {hcLeader _x isEqualTo player}
                    // 


pl_draw_at_targets_indicator = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _pos1 = _x#0;
                    _pos2 = _x#1;
                    _display drawArrow [
                        _pos1,
                        _pos2,
                        [0.92,0.24,0.07,1]
                    ];

            } forEach pl_at_targets_indicator;
    "]; // "
};

// [] call pl_draw_at_targets_indicator;

pl_draw_mg_fire_indicator = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                if (_x getVariable ['pl_firing', false]) then {
                    _pos1 = getPos _x;
                    _pos2 = _pos1 getPos [60, getDir _x];
                    _display drawArrow [
                        _pos1,
                        _pos2,
                        [0.92,0.24,0.07,1]
                        ];
                };
            } forEach pl_actvie_mg_gunners;
    "]; // "
};

// [] call pl_draw_mg_fire_indicator;

pl_mark_obstacles = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_show_obstacles) then {
            {
                _obstacle = _x;
                if !(isObjectHidden _obstacle) then {
                    _icon = '\A3\ui_f\data\map\mapControl\bunker_ca.paa';
                    _size = 15;
                    if (_x isKindOf 'Tank' or _x isKindOf 'Car') then {
                        _icon = getText (configfile >> 'CfgVehicles' >> typeof _x >> 'icon');
                        _size = 30;
                    };
                    _display drawIcon [
                        _icon,
                        [0.92,0.24,0.07,1],
                        getPosVisual _obstacle,
                        _size,
                        _size,
                        getDirVisual _obstacle
                    ]
                };
            } forEach ((pl_show_obstacles_pos nearObjects 90) select {['fence', typeOf _x] call BIS_fnc_inString or ['barrier', typeOf _x] call BIS_fnc_inString or ['wall', typeOf _x] call BIS_fnc_inString or ['sand', typeOf _x] call BIS_fnc_inString or ['bunker', typeOf _x] call BIS_fnc_inString or ['wire', typeOf _x] call BIS_fnc_inString}) + (allDead - allDeadMen);
        };
    "]; // "
};

pl_valid_terrain_obstacles = ['TREE', 'BUSH', 'SMALL TREE', 'ROCK', 'ROCKS', 'BUNKER', 'BUSSTOP', 'FOUNTAIN', 'POWERSOLAR', 'POWERWIND', 'VIEW-Tower', 'TRANSMITTER'];

pl_show_obstacles_group = false;

pl_mark_obstacles_group = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_show_obstacles_group) then {
            {
                _groupPos = getPos (leader _x);
                {
                    _obstacle = _x;
                    private _icon = '';
                    if !(isObjectHidden _obstacle) then {
                        _icon = getText (configfile >> 'CfgVehicles' >> typeof _obstacle >> 'icon');
                        _size = 20;

                        if ((['sand', typeOf _x] call BIS_fnc_inString or ['barrier', typeOf _x] call BIS_fnc_inString or ['rampart', typeOf _x] call BIS_fnc_inString or ['trench', typeOf _x] call BIS_fnc_inString) and _icon isEqualTo 'iconObject' or _icon isEqualTo 'iconThing') then {
                            _icon = '\A3\ui_f\data\map\mapControl\bunker_ca.paa';
                        };
                        if (_icon isEqualTo 'iconObject' or _icon isEqualTo 'iconThing' or _icon isEqualTo '') then {
                            _icon = '\A3\ui_f\data\map\mapControl\bush_ca.paa';
                        };
                        _display drawIcon [
                            _icon,
                            [0.92,0.24,0.07,1],
                            getPosVisual _obstacle,
                            _size,
                            _size,
                            getDirVisual _obstacle
                        ]
                    };
                } forEach (((_groupPos nearObjects 80) select {['fence', typeOf _x] call BIS_fnc_inString or ['barrier', typeOf _x] call BIS_fnc_inString or ['wall', typeOf _x] call BIS_fnc_inString or ['sand', typeOf _x] call BIS_fnc_inString or ['bunker', typeOf _x] call BIS_fnc_inString or ['wire', typeOf _x] call BIS_fnc_inString})  + (vehicles select {(_x distance2D _groupPos) <= 80 and ((crew _x) isEqualTo [])}) + (allDead select {(_x distance2D _groupPos) <= 80}));
            } forEach (hcSelected player);    
        };
    "]; // "
};

// + (nearestTerrainObjects [_groupPos, pl_valid_terrain_obstacles, 80])

// [] call pl_mark_obstacles;

pl_draw_text_array = [];
pl_draw_text = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        {
            _text = _x#0;
            _textPos = _x#1;
            _textSize = _x#2;
            _color = _x#3;
            _display drawIcon [
                '#(rgb,4,1,1)color(1,1,1,0)',
                _color,
                _textPos,
                6,
                6,
                0,
                _text,
                0,
                _textSize,
                'EtelkaMonospacePro',
                'center'
            ];
        } forEach pl_draw_text_array;
    "]; 
};

// [] call pl_draw_text;

pl_draw_defence_watchpos_select = {
    params ["_display"];
   _display ctrlAddEventHandler ["Draw","
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
                '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa',
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

[findDisplay 12 displayCtrl 51] call pl_draw_defence_watchpos_select;

pl_draw_at_attack = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = getPos (_x select 0);
                _pos2 =_x select 1;
                _escord = _x select 2;
                _color = [1,0.7,0.4,0.9];
                if (currentWeapon (_x#0) == secondaryWeapon (_x#0)) then {
                    _color = [0,1,0,0.7];
                };
                if !((typeName _pos2) isEqualTo 'ARRAY') then {
                    _pos2 = getPos _pos2;
                    _display drawIcon [
                        '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa',
                        [1,0.7,0.4,0.9],
                        _pos2,
                        10,
                        10,
                        0,
                        '',
                        2,
                        0.05
                    ];
                };
                if !(isNull _escord) then {
                    if (alive _escord) then {
                        _display drawLine [
                            _pos1,
                            getPos _escord,
                            _color
                        ];
                    };
                };
                _display drawLine [
                    _pos1,
                    _pos2,
                    _color
                    ];
                _display drawLine [
                    _pos1,
                    getPos (leader(_x#0)),
                    pl_side_color_rgb
                    ];
            } forEach pl_at_attack_array;
    "]; // "
};


// [] call pl_draw_at_attack;

pl_opfor_wp_dic = createHashMap;
pl_opfor_wp_arrow = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                if !(isNull (_y#3)) then {
                    _pos1 = _y#0;
                    _pos2 = _y#1;
                    _color = _y#2;
                    _display drawArrow [
                        _pos1,
                        _pos2,
                        _color
                    ];
                } else {
                    pl_opfor_wp_dic deleteat _x;  
                };
            } forEach pl_opfor_wp_dic;
    "]; // "  
};

// [] call pl_opfor_wp_arrow;

pl_draw_convoy_path_array = [];
pl_draw_convoy_path = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                for '_i' from 0 to (count _x) -2 do {
                    _pos1 = _x#_i;
                    _pos2 = _x#(_i + 1);
                    _display drawLine [
                        _pos1,
                        _pos2,
                        [0.92,0.24,0.07,1]
                    ];
                };
            } forEach pl_draw_convoy_path_array;
    "]; // "  
};

// [] call pl_draw_convoy_path;


pl_draw_vic_advance_wp = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _pos1 = getPos (_x#0);
                    _pos2 = _x#1;
                    _display drawArrow [
                        _pos1,
                        _pos2,
                        pl_side_color_rgb
                    ];

            } forEach pl_draw_vic_advance_wp_array;
    "]; // "
};

// [] call pl_draw_vic_advance_wp;


pl_draw_planed_wps = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                {
                    _pos1 = _x#0;
                    _pos2 = _x#1;
                    _display drawArrow [
                        _pos1,
                        _pos2,
                        pl_side_color_rgb
                    ];
                } forEach _y;
            } forEach pl_draw_planed_wps_dic;
    "]; // "
}; // [0.9,0.9,0,1]

pl_draw_disengage_array = [];
pl_draw_disengage = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _pos1 = getPos (vehicle (leader (_x#0)));
                    _pos2 = _x#1;
                    _display drawArrow [
                        _pos1,
                        _pos2,
                        pl_side_color_rgb
                    ];

            } forEach pl_draw_disengage_array;
    "]; // "
};

pl_draw_kia_array = [];

pl_draw_kia_unit = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _unit = _x;
                _icon = getText (configfile >> 'CfgVehicles' >> typeof (vehicle _unit) >> 'icon');
                _size = 10;
                _unitColor = [0,0,0,0.6];
                _display drawIcon [
                    _icon,
                    _unitColor,
                    getPosVisual _unit,
                    _size,
                    _size,
                    getDirVisual _unit
                ];
            } forEach pl_draw_kia_array;
    "]; // "
};

// [findDisplay 12 displayCtrl 51] call pl_draw_kia_unit;

pl_draw_arrow_ptm_array = [];

pl_draw_arrow_pos_to_mouse = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                    _pos1 = _x;
                    _pos2 = _display ctrlMapScreenToWorld getMousePosition;
                    _display drawArrow [
                        _pos1,
                        _pos2,
                        pl_side_color_rgb
                    ];

            } forEach pl_draw_arrow_ptm_array;
    "]; // 
};

// [findDisplay 12 displayCtrl 51] call pl_draw_arrow_pos_to_mouse;

pl_draw_arrow_ptp_array = [];

pl_draw_arrow_pos_to_pos = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
    _display = _this#0;
        {
                _pos1 = _x#0;
                _pos2 = _x#1;
                _display drawArrow [
                    _pos1,
                    _pos2,
                    pl_side_color_rgb
                ];

        } forEach pl_draw_arrow_ptp_array;
    "]; // 
};

// [findDisplay 12 displayCtrl 51] call pl_draw_arrow_pos_to_pos;

pl_draw_icon_array = [];

pl_draw_icon = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        {
            _icon = _x#0;
            _pos = _x#1;
            _size = _x#2;
            _color = _x#3;
            _color set [3, 1];
            _display drawIcon [
                _icon,
                _color,
                _pos,
                _size,
                _size,
                0,
                '',
                2
            ];
        } forEach pl_draw_icon_array;
    "]; // 
};

pl_mark_cover_objects = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_show_covers) then {
            {
                _cover = _x;
                if !(isObjectHidden _cover) then {
                    _icon = '\A3\ui_f\data\map\mapControl\bunker_ca.paa';
                    _size = 15;
                    _display drawIcon [
                        _icon,
                        pl_side_color_rgb,
                        getPosVisual _cover,
                        _size,
                        _size,
                        0
                    ]
                };
            } forEach (nearestTerrainObjects [pl_show_covers_pos, ['WALL', 'RUIN', 'FENCE', 'ROCK', 'ROCKs', 'STACK', 'HIDE'], pl_garrison_area_size, false, false]);
        };
    "]; // "
};

pl_show_vic_defense1_51 = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        {         
            _display drawIcon [
                getText (configfile >> 'CfgVehicles' >> typeof _x >> 'icon'),
                pl_side_color_rgb,
                (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition,
                35,
                35,
                (getpos _x) getDir ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)
            ]
        } forEach pl_show_vic_defense1_array;
    "]; // "
};


pl_show_vic_defense2_51 = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        {         
            _display drawIcon [
                getText (configfile >> 'CfgVehicles' >> typeof (_x#0) >> 'icon'),
                pl_side_color_rgb,
                (_x#1),
                35,
                35,
                (_x#1) getDir ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)
            ]
        } forEach pl_show_vic_defense2_array;
    "]; // "
};

pl_show_vic_defense1_2000 = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        {         
            _display drawIcon [
                getText (configfile >> 'CfgVehicles' >> typeof _x >> 'icon'),
                pl_side_color_rgb,
                (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition,
                35,
                35,
                (getpos _x) getDir ((findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition)
            ]
        } forEach pl_show_vic_defense1_array;
    "]; // "
};


pl_show_vic_defense2_2000 = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        {         
            _display drawIcon [
                getText (configfile >> 'CfgVehicles' >> typeof (_x#0) >> 'icon'),
                pl_side_color_rgb,
                (_x#1),
                35,
                35,
                (_x#1) getDir ((findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition)
            ]
        } forEach pl_show_vic_defense2_array;
    "]; // "
};

pl_draw_vision_tool = {
    params ["_display"];
    _display ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_vision_tool_enabled) then {
            _path = ([] call pl_get_vistool_pos)#0;
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



// [findDisplay 12 displayCtrl 51] call pl_draw_icon;

// pl_draw_icon_array = [['\Plmod\gfx\pl_position.paa', getPos player, 20, pl_side_color_rgb]];




pl_init_map_icons = {
    [findDisplay 12 displayCtrl 51] call pl_draw_group_info;
    [findDisplay 12 displayCtrl 51] call pl_mark_vics;
    [findDisplay 12 displayCtrl 51] call pl_convoy_marker;
    [findDisplay 12 displayCtrl 51] call pl_dead_vics;
    [findDisplay 12 displayCtrl 51] call pl_draw_building_search_marker;
    [findDisplay 12 displayCtrl 51] call pl_draw_follow_marker;
    [findDisplay 12 displayCtrl 51] call pl_draw_defence_line;
    [findDisplay 12 displayCtrl 51] call pl_draw_bounding_line;
    [findDisplay 12 displayCtrl 51] call pl_draw_follow_marker_other;
    [findDisplay 12 displayCtrl 51] call pl_draw_follow_marker_other_setup;
    [findDisplay 12 displayCtrl 51] call pl_draw_planed_task;
    [findDisplay 12 displayCtrl 51] call pl_draw_planed_task_wp;
    [findDisplay 12 displayCtrl 51] call pl_draw_suppression;
    [findDisplay 12 displayCtrl 51] call pl_draw_auto_suppression;
    [findDisplay 12 displayCtrl 51] call pl_draw_resupply_line;
    [findDisplay 12 displayCtrl 51] call pl_draw_formation_move_mouse;
    [findDisplay 12 displayCtrl 51] call pl_draw_sync_wps;
    [findDisplay 12 displayCtrl 51] call pl_draw_unload_inf_task_plan_icon;
    [findDisplay 12 displayCtrl 51] call pl_draw_ccp_medic;
    [findDisplay 12 displayCtrl 51] call pl_draw_unit_group_lines;
    [findDisplay 12 displayCtrl 51] call pl_damaged_vics;
    [findDisplay 12 displayCtrl 51] call pl_draw_at_targets_indicator;
    [findDisplay 12 displayCtrl 51] call pl_mark_obstacles;
    // [findDisplay 12 displayCtrl 51] call pl_draw_defence_watchpos_select;
    [findDisplay 12 displayCtrl 51] call pl_opfor_wp_arrow;
    [findDisplay 12 displayCtrl 51] call pl_draw_convoy_path;
    [findDisplay 12 displayCtrl 51] call pl_draw_at_attack;
    [findDisplay 12 displayCtrl 51] call pl_draw_vic_advance_wp;
    [findDisplay 12 displayCtrl 51] call pl_draw_planed_wps;
    [findDisplay 12 displayCtrl 51] call pl_draw_left_vehicles;
    [findDisplay 12 displayCtrl 51] call pl_draw_text;
    [findDisplay 12 displayCtrl 51] call pl_draw_mg_fire_indicator;
    [findDisplay 12 displayCtrl 51] call pl_mark_supllies;
    [findDisplay 12 displayCtrl 51] call pl_show_charges;
    [findDisplay 12 displayCtrl 51] call pl_draw_disengage;
    [findDisplay 12 displayCtrl 51] call pl_draw_kia_unit;
    [findDisplay 12 displayCtrl 51] call pl_draw_arrow_pos_to_mouse;
    [findDisplay 12 displayCtrl 51] call pl_draw_arrow_pos_to_pos;
    [findDisplay 12 displayCtrl 51] call pl_draw_icon;
    [findDisplay 12 displayCtrl 51] call pl_mark_obstacles_group;
    [findDisplay 12 displayCtrl 51] call pl_mark_cover_objects;
    [findDisplay 12 displayCtrl 51] call pl_show_vic_defense1_51;
    [findDisplay 12 displayCtrl 51] call pl_show_vic_defense2_51;
    [findDisplay 12 displayCtrl 51] call pl_draw_vision_tool;
    // [findDisplay 12 displayCtrl 51] call pl_draw_recon_LOS;
};

[] call pl_init_map_icons;

addMissionEventHandler ["Loaded", {
    params ["_saveType"];
    [findDisplay 12 displayCtrl 51] call pl_draw_group_info;
    [findDisplay 12 displayCtrl 51] call pl_mark_vics;
    [findDisplay 12 displayCtrl 51] call pl_convoy_marker;
    [findDisplay 12 displayCtrl 51] call pl_dead_vics;
    [findDisplay 12 displayCtrl 51] call pl_draw_building_search_marker;
    [findDisplay 12 displayCtrl 51] call pl_draw_follow_marker;
    [findDisplay 12 displayCtrl 51] call pl_draw_defence_line;
    [findDisplay 12 displayCtrl 51] call pl_draw_bounding_line;
    [findDisplay 12 displayCtrl 51] call pl_draw_follow_marker_other;
    [findDisplay 12 displayCtrl 51] call pl_draw_follow_marker_other_setup;
    [findDisplay 12 displayCtrl 51] call pl_draw_planed_task;
    [findDisplay 12 displayCtrl 51] call pl_draw_planed_task_wp;
    [findDisplay 12 displayCtrl 51] call pl_draw_suppression;
    [findDisplay 12 displayCtrl 51] call pl_draw_auto_suppression;
    [findDisplay 12 displayCtrl 51] call pl_draw_resupply_line;
    [findDisplay 12 displayCtrl 51] call pl_draw_formation_move_mouse;
    [findDisplay 12 displayCtrl 51] call pl_draw_sync_wps;
    [findDisplay 12 displayCtrl 51] call pl_draw_unload_inf_task_plan_icon;
    [findDisplay 12 displayCtrl 51] call pl_draw_ccp_medic;
    [findDisplay 12 displayCtrl 51] call pl_draw_unit_group_lines;
    [findDisplay 12 displayCtrl 51] call pl_damaged_vics;
    [findDisplay 12 displayCtrl 51] call pl_draw_at_targets_indicator;
    [findDisplay 12 displayCtrl 51] call pl_mark_obstacles;
    // [findDisplay 12 displayCtrl 51] call pl_draw_defence_watchpos_select;
    [findDisplay 12 displayCtrl 51] call pl_opfor_wp_arrow;
    [findDisplay 12 displayCtrl 51] call pl_draw_convoy_path;
    [findDisplay 12 displayCtrl 51] call pl_draw_at_attack;
    [findDisplay 12 displayCtrl 51] call pl_draw_vic_advance_wp;
    [findDisplay 12 displayCtrl 51] call pl_draw_planed_wps;
    [findDisplay 12 displayCtrl 51] call pl_draw_left_vehicles;
    [findDisplay 12 displayCtrl 51] call pl_draw_text;
    [findDisplay 12 displayCtrl 51] call pl_draw_mg_fire_indicator;
    [findDisplay 12 displayCtrl 51] call pl_mark_supllies;
    [findDisplay 12 displayCtrl 51] call pl_show_charges;
    [findDisplay 12 displayCtrl 51] call pl_draw_disengage;
    [findDisplay 12 displayCtrl 51] call pl_draw_kia_unit;
    [findDisplay 12 displayCtrl 51] call pl_draw_arrow_pos_to_mouse;
    [findDisplay 12 displayCtrl 51] call pl_draw_arrow_pos_to_pos;
    [findDisplay 12 displayCtrl 51] call pl_draw_icon;
    [findDisplay 12 displayCtrl 51] call pl_mark_obstacles_group;
    [findDisplay 12 displayCtrl 51] call pl_mark_cover_objects;
    [findDisplay 12 displayCtrl 51] call pl_show_vic_defense1_51;
    [findDisplay 12 displayCtrl 51] call pl_show_vic_defense2_51;
    [findDisplay 12 displayCtrl 51] call pl_draw_vision_tool;
    // [findDisplay 12 displayCtrl 51] call pl_draw_recon_LOS;
}];


pl_marker_targets = [];


pl_map_radio_callout = {
    params ["_group", "_text", "_cdTime"];

    _group setVariable ["pl_radio_time", time + _cdTime];
    _group setVariable ["pl_radio_text", _text];
};

pl_reset_group_radio_setup = {
    params ["_group"];

    while {!(isNull _group)} do {
        _radioTime = _group getVariable ["pl_radio_time", time + 0];
        sleep 0.1;
        if (time > _radioTime) then {
            _group setVariable ["pl_radio_text", ""];
        };
        sleep 1;
    };
};

pl_draw_kia = {
    params ["_unit"];

    sleep 2;

    _pos = getPosVisual _unit;
    _markerName = str _unit;
    _marker = createMarker [_markerName, _pos];
    _markerName setMarkerSize [0.4, 0.4];
    _markerName setMarkerType "mil_destroy";
    _markerName setMarkerColor "colorPink";
    _markerName setMarkerDir 45;
    _markerName setMarkerShadow false;

    pl_draw_kia_array pushBack _unit;

    _time = time + 120;
    waitUntil {sleep 1; time >= _time};
    deleteMarker _markerName;
    // pl_draw_kia_array deleteAt (pl_draw_kia_array find _unit);
};

pl_show_tac_map_icons = {
    [findDisplay 2000 displayCtrl 2000] call pl_draw_group_info;
    [findDisplay 2000 displayCtrl 2000] call pl_mark_vics;
    [findDisplay 2000 displayCtrl 2000] call pl_convoy_marker;
    [findDisplay 2000 displayCtrl 2000] call pl_dead_vics;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_building_search_marker;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_follow_marker;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_defence_line;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_bounding_line;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_follow_marker_other;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_follow_marker_other_setup;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_planed_task;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_planed_task_wp;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_suppression;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_auto_suppression;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_resupply_line;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_formation_move_mouse;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_sync_wps;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_unload_inf_task_plan_icon;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_ccp_medic;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_unit_group_lines;
    [findDisplay 2000 displayCtrl 2000] call pl_damaged_vics;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_at_targets_indicator;
    [findDisplay 2000 displayCtrl 2000] call pl_mark_obstacles;
    // [findDisplay 2000 displayCtrl 2000] call pl_draw_defence_watchpos_select;
    [findDisplay 2000 displayCtrl 2000] call pl_opfor_wp_arrow;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_convoy_path;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_at_attack;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_vic_advance_wp;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_planed_wps;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_left_vehicles;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_text;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_mg_fire_indicator;
    [findDisplay 2000 displayCtrl 2000] call pl_mark_supllies;
    [findDisplay 2000 displayCtrl 2000] call pl_show_charges;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_disengage;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_kia_unit;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_arrow_pos_to_mouse;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_arrow_pos_to_pos;
    [findDisplay 2000 displayCtrl 2000] call pl_draw_icon;
    [findDisplay 2000 displayCtrl 2000] call pl_mark_obstacles_group;
    [findDisplay 2000 displayCtrl 2000] call pl_mark_cover_objects;
    [findDisplay 2000 displayCtrl 2000] call pl_show_vic_defense1_2000;
    [findDisplay 2000 displayCtrl 2000] call pl_show_vic_defense2_2000;
};

pl_last_tac_zoom = 0.1;
pl_last_tac_pos = getPos player;

pl_open_tac_map = {

    if (visibleMap) then {
        [] spawn pl_vision_tool;

    } else {

        // setGroupIconsVisible [true,false]; 
        if !(isNull findDisplay 2000) exitWith {
            pl_last_tac_zoom = ctrlMapScale (findDisplay 2000 displayCtrl 2000);
            pl_last_tac_pos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld [0.5, 1.117];
            // pl_last_tac_pos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld [0.5, 0.5];
            // pl_last_tac_pos = (findDisplay 2000 displayCtrl 2000) ctrlMapAnimAdd [0, 0.05, getPos player];
            (findDisplay 2000) closeDisplay 1;
            playSound "HintCollapse";
            // player playAction "Default";
            pl_tac_map_active = false;
            // ctrlDelete (uiNamespace getVariable "pl_pouch_gfx");
        };

        playSound "HintExpand";
        // player playAction "Gear";
        pl_tac_map_active = true;
        _map = findDisplay 46 createDisplay "pl_RscMap";
        _map displayAddEventHandler ["KeyDown", {call cba_events_fnc_keyHandlerDown}];
        _map displayAddEventHandler ["KeyUp", {call cba_events_fnc_keyHandlerUp}];

        with uiNamespace do {
            pl_pouch_gfx = findDisplay 2000 ctrlCreate ["RscPicture", -1];

            if ((date#0) < 2016) then {
                pl_pouch_gfx ctrlSetPosition [0.1 * safezoneW + safezoneX, 0.5 * safezoneH + safezoneY,2,2];
                pl_pouch_gfx ctrlSetText "plmod\gfx\pl_mapbag_1.paa";
            } else {
                pl_pouch_gfx ctrlSetPosition [0.28 * safezoneW + safezoneX, 0.47 * safezoneH + safezoneY,1.07,1.35];
                pl_pouch_gfx ctrlSetText "plmod\gfx\pl_tactical_phone_case1.paa";
            };
            pl_pouch_gfx ctrlCommit 0;
        };

        (findDisplay 2000 displayCtrl 2000) ctrlMapAnimAdd [0, pl_last_tac_zoom, pl_last_tac_pos];
        // (findDisplay 2000 displayCtrl 2000) ctrlMapAnimAdd [0, 0.05, getPos player];
        ctrlMapAnimCommit (findDisplay 2000 displayCtrl 2000);
        sleep 0.1;

        [findDisplay 2000 displayCtrl 2000] call pl_map_ehs;

        [] call pl_show_tac_map_icons;
    };
};


pl_open_tac_forced = {
    params ["_pos"];

    playSound "HintExpand";
    // player playAction "Gear";
    pl_tac_map_active = true;
    _map = findDisplay 46 createDisplay "pl_RscMap";
    _map displayAddEventHandler ["KeyDown", {call cba_events_fnc_keyHandlerDown}];
    _map displayAddEventHandler ["KeyUp", {call cba_events_fnc_keyHandlerUp}];

    with uiNamespace do {
        pl_pouch_gfx = findDisplay 2000 ctrlCreate ["RscPicture", -1];
        if ((date#0) < 2016) then {
            pl_pouch_gfx ctrlSetPosition [0.1 * safezoneW + safezoneX, 0.5 * safezoneH + safezoneY,2,2];
            pl_pouch_gfx ctrlSetText "plmod\gfx\pl_mapbag_1.paa";
        } else {
            pl_pouch_gfx ctrlSetPosition [0.28 * safezoneW + safezoneX, 0.47 * safezoneH + safezoneY,1.07,1.35];
            pl_pouch_gfx ctrlSetText "plmod\gfx\pl_tactical_phone_case1.paa";
        };
        pl_pouch_gfx ctrlCommit 0;
    };

    (findDisplay 2000 displayCtrl 2000) ctrlMapAnimAdd [0, 0.05, _pos];
    ctrlMapAnimCommit (findDisplay 2000 displayCtrl 2000);

    sleep 0.1;

    [findDisplay 2000 displayCtrl 2000] call pl_map_ehs;
    [] call pl_show_tac_map_icons;
};

pl_map_ehs = {
    params ["_control"];

    pl_boxsel_active = false;
    pl_mousewheel_idx = 0;                  // 0: Buddy OW, 1: Set WP, 2: Bounding OW
    pl_mousewheel_idx_ALT = 0;              // 0: VIC Revers, 1: VIC Forward , 2: Move On Path
    pl_mousewheel_idx_CTRL = 0;             // 0: Add WP
    pl_mousewheel_idx_CTRL_ALT = 0;         // 0: Disengage


    // enable use of LMB in TavMap 
    // DONT USE to resource Heavy

    // [] spawn {

    //     while {(findDisplay 2000) isNotEqualto displayNull} do {

    //         // mouse wheel UP
    //         if (inputAction "prevAction" > 0) then {

    //             // LCTRL
    //             if (inputAction "curatorGroupMod" > 0) then {

    //                 pl_mousewheel_idx_CTRL = pl_mousewheel_idx_CTRL - 1;
    //                 if (pl_mousewheel_idx_CTRL < 0) then {pl_mousewheel_idx_CTRL = 0};

    //             } else {

    //                 // ALT
    //                 if (inputAction "lookAround" > 0) then {

    //                     pl_mousewheel_idx_ALT = pl_mousewheel_idx_ALT - 1;
    //                     if (pl_mousewheel_idx_ALT < 0) then {pl_mousewheel_idx_ALT = 2};

    //                 } else {

    //                     // LCTR + ALT
    //                     if ((inputAction "curatorGroupMod" > 0) and (inputAction "lookAround" > 0)) then {

    //                         pl_mousewheel_idx_CTRL_ALT = pl_mousewheel_idx_CTRL_ALT - 1;
    //                         if (pl_mousewheel_idx_CTRL_ALT < 0) then {pl_mousewheel_idx_CTRL_ALT = 0};

    //                     // NONE
    //                     } else {

    //                         pl_mousewheel_idx = pl_mousewheel_idx - 1;
    //                         if (pl_mousewheel_idx < 0) then {pl_mousewheel_idx = 2};
    //                     };
    //                 };
    //             };
    //             waitUntil {inputAction "prevAction" == 0};
    //         };

    //         // mouse wheel down
    //         if (inputAction "nextAction" > 0) then {

    //             // LCTRL
    //             if (inputAction "curatorGroupMod" > 0) then {

    //                 pl_mousewheel_idx_CTRL = pl_mousewheel_idx_CTRL + 1;
    //                 if (pl_mousewheel_idx_CTRL > 0) then {pl_mousewheel_idx_CTRL = 0};

    //             } else {

    //                 // ALT
    //                 if (inputAction "lookAround" > 0) then {

    //                     pl_mousewheel_idx_ALT = pl_mousewheel_idx_ALT + 1;
    //                     if (pl_mousewheel_idx_ALT > 2) then {pl_mousewheel_idx_ALT = 0};

    //                 } else {

    //                     // LCTR + ALT
    //                     if ((inputAction "curatorGroupMod" > 0) and (inputAction "lookAround" > 0)) then {

    //                         pl_mousewheel_idx_CTRL_ALT = pl_mousewheel_idx_CTRL_ALT + 1;
    //                         if (pl_mousewheel_idx_CTRL_ALT > 0) then {pl_mousewheel_idx_CTRL_ALT = 0};

    //                     // NONE
    //                     } else {
                        
    //                         pl_mousewheel_idx = pl_mousewheel_idx + 1;
    //                         if (pl_mousewheel_idx > 2) then {pl_mousewheel_idx = 0};
    //                     };
    //                 };
    //             };
    //             waitUntil {inputAction "nextAction" == 0};
    //         };
    //     };
    // };

    // change cursor
    _control ctrlAddEventHandler ["MouseMoving", {
        params [
            ["_mapCtrl",controlNull, [controlNull]],
            ["_xPos",-1,[0]],
            ["_yPos",-1,[0]],
            ["_mouseIn", false, [true]]
        ];

        if (_mouseIn and !(pl_boxsel_active)) then {
            _mapCtrl ctrlMapCursor ["", "Track"];
        } else {
            if (_mouseIn and pl_boxsel_active) then {
                _mapCtrl ctrlMapCursor ["", "Move"];
            } else {
                _mapCtrl ctrlMapCursor ["", "Arrow"];
            };
        };
    }];

    _control ctrlAddEventHandler ["MouseButtonDown", {
        params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

        if (_button == 0) then {

            _logic = player getvariable "BIS_HC_scope";
            _wp = _logic getvariable "WPover";

            // Waypoint Drag and Drop
            if !((count _wp) == 1) then {
                pl_wp_mover = _displayOrControl ctrlAddEventHandler ["MouseMoving", {
                     params [
                        ["_mapCtrl",controlNull, [controlNull]],
                        ["_xPos",-1,[0]],
                        ["_yPos",-1,[0]],
                        ["_mouseIn", false, [true]]
                    ];

                    _logic = player getvariable "BIS_HC_scope";
                    _wp = _logic getvariable "WPover";

                    if (_mouseIn) then {
                        if !((count _wp) == 1) then {
                            _wp setWaypointPosition [(findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition, 0];
                        };
                    };
                }];

                _displayOrControl ctrlAddEventHandler ["MouseButtonup", {
                    params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

                    _displayOrControl ctrlRemoveEventHandler ["MouseButtonup", _thisEventHandler];
                    _displayOrControl ctrlRemoveEventHandler ["MouseMoving", pl_wp_mover];
                }];

            // selectionbox
            } else {

                pl_boxsel_active = true;
                pl_boxsel_bLeft = _displayOrControl ctrlMapScreenToWorld getMousePosition;

                pl_boxsel_drawer = _displayOrControl ctrlAddEventHandler ["Draw", {
                    ["_control"];

                    _display = (findDisplay 2000 displayCtrl 2000);

                    _tRight = _display ctrlMapScreenToWorld getMousePosition;

                    _tLeft = [pl_boxsel_bLeft#0, _tRight#1];
                    _bRight = [_tRight#0, pl_boxsel_bLeft#1];

                    _display drawLine [pl_boxsel_bLeft, _tLeft, [0,1,0,1]];
                    _display drawLine [_tLeft, _tRight, [0,1,0,1]];
                    _display drawLine [pl_boxsel_bLeft, _bRight, [0,1,0,1]];
                    _display drawLine [_bRight, _tRight, [0,1,0,1]];

                    pl_boxsel_center = pl_boxsel_bLeft getPos [(pl_boxsel_bLeft distance2D _tRight) / 2, pl_boxsel_bLeft getDir _tRight];
                    pl_boxsel_center deleteAt 2;

                    pl_boxsel_y = (pl_boxsel_bLeft distance2D _tLeft) / 2;
                    pl_boxsel_x = (pl_boxsel_bLeft distance2D _bRight) / 2; 
                }];

                _displayOrControl ctrlAddEventHandler ["MouseButtonup", {
                    params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

                    {
                        if ((getPos (leader _x)) inArea [pl_boxsel_center, pl_boxsel_x, pl_boxsel_y, 0, true]) then {
                            player hcSelectGroup [_x];
                        };
                    } forEach (hcAllGroups player);

                    _displayOrControl ctrlMapCursor ["", "Track"];
                    _displayOrControl ctrlRemoveEventHandler ["MouseButtonup", _thisEventHandler];
                    _displayOrControl ctrlRemoveEventHandler ["Draw", pl_boxsel_drawer];
                    pl_boxsel_active = false;

                }];
            };
        };

        // if (_button == 1) then { 
        //     {
        //         showCommandingMenu "";
        //     } forEach (hcSelected player)
        // };
    }];

    _control ctrlAddEventHandler ["MouseButtonDown", {
        params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

        // LMB
        if ((_button == 0) and (count (hcSelected player) > 0)) then {

            if (count (hcSelected player) > 1 and (!pl_draw_formation_mouse)) then {[hcSelected player, true] spawn pl_move_as_formation}; if (count (hcSelected player) <= 1) then {[] spawn pl_march};

            //LCTRL
            // if (inputAction "curatorGroupMod" > 0) then {

            //     if (pl_mousewheel_idx_CTRL == 0) then {

            //         switch (pl_mousewheel_idx_CTRL) do { 
            //             // Add WP
            //             case 0 : {if (count (hcSelected player) > 1 and (!pl_draw_formation_mouse)) then {[hcSelected player, true] spawn pl_move_as_formation}; if (count (hcSelected player) <= 1) then {[] spawn pl_march};}; 
            //             default {}; 
            //         };
            //     };

            // } else {

            //     // ALT
            //     if (inputAction "lookAround" > 0) then {

            //         switch (pl_mousewheel_idx_ALT) do { 
            //             case 0 : {[] spawn pl_vic_advance_to_pos}; 
            //             case 1 : {[] spawn pl_vic_advance_to_pos_reverse};
            //             case 2 : {[] spawn pl_move_as_column}; 
            //             default {}; 
            //         };

            //     } else {

            //         // ALT + LCTRL
            //         if ((inputAction "curatorGroupMod" > 0) and (inputAction "lookAround" > 0)) then {

            //             switch (pl_mousewheel_idx_CTRL_ALT) do { 
            //                 case 0 : {{[_x] spawn pl_disengage}forEach (hcSelected player)}; 
            //                 default {}; 
            //             };

            //         // NONE
            //         } else {
            //             switch (pl_mousewheel_idx) do { 
            //                 case 0 : {['buddy'] spawn pl_bounding_switch}; 
            //                 case 1 : {{[_x] spawn pl_set_waypoint} forEach (hcSelected player)};
            //                 case 2 : {['team'] spawn pl_bounding_switch}; 
            //                 default {}; 
            //             };
            //         };

            //     };
            // };
        };
    }];
};


