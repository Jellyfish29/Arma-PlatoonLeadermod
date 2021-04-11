sleep 2;

pl_get_group_health = {
    params ["_group"];
    private ["_healthState"];
    _healthState = [0.4,1,0.2,1];
    {
        if ((damage _x) > 0.1) then {
            _healthState = [0.9,0.9,0,1];
        };
        if ((_x getVariable "pl_wia") and (alive _x)) then {
            _healthState = [0.7,0,0,1];
        };
    } forEach (units _group);
    _healthState;
};

pl_get_vic_health = {
    params ["_vic"];
    private ["_healthState"];
    _healthState = [0,0.3,0.6,0.8];
    if ((damage _vic) > 0) then {
        _healthState = [0.9,0.7,0.1,1];
    };
    if ((damage _vic) > 0.6) then {
        _healthState = [0.7,0,0,1];
    };
    if !(canMove _vic) then {
        _healthState = [0.49,0.06,0.8,1]; // 7E11CA
    };
    _healthState;
};


pl_world_size_x = round (worldSize * 0.03);
pl_world_size_y = round (worldSize * 0.02);

pl_draw_group_info = {

    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
        {
            if (hcShownBar and (_x getVariable 'pl_show_info') and visibleMap) then {

                pl_map_scale = ctrlMapScale (_this select 0);
                pl_map_scale_x = pl_map_scale * pl_world_size_x;
                pl_map_scale_y = pl_map_scale * pl_world_size_y;

                if ((getText (configFile >> 'CfgVehicles' >> typeOf (units _x select 0)>> 'displayName')) isEqualTo 'Game Logic') exitWith {};
                {
                    _unit = _x;
                    _icon = getText (configfile >> 'CfgVehicles' >> typeof _unit >> 'icon');
                    _size = 15;
                    _unitColor = [0,0.3,0.6,0.65];
                    if (_unit getVariable 'pl_is_ccp_medic' and (alive _unit)) then {
                        _unitColor = [0.4,1,0.2,0.65];
                    };
                    if (_unit getVariable 'pl_wia') then {
                        _unitColor = [0.7,0,0,0.65];
                    };
                    if (vehicle _unit == _unit and (alive _unit)) then {
                        _display drawIcon [
                            _icon,
                            _unitColor,
                            getPosVisual _unit,
                            _size,
                            _size,
                            getDirVisual _unit
                        ];
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
                    [0,0.3,0.6,1],
                    _pos,
                    23,
                    23,
                    0,
                    _callsignText,
                    0,
                    0.03,
                    'TahomaB',
                    'right'
                    ];

                _strength = count (units _x);
                _healthColor = [_x] call pl_get_group_health;
                _strengthText = format ['%1  ', _strength];
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
                    'TahomaB',
                    'left'
                ];


                _contactIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa';
                _contactPos = [(_pos select 0) - pl_map_scale_x, (_pos select 1) - pl_map_scale_y];
                _contactColor = [0.4,1,0.2,1];
                _x setVariable ['inContact', false];
                _time = (_x getVariable 'PlContactTime') - 30;
                if (_x getVariable ['pl_hold_fire', false]) then {
                    _contactColor = [0.1,0.1,0.6,1];
                };
                if (_time > time) then {
                    _contactColor = [0.7,0,0,1];
                    _x setVariable ['inContact', true];
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
                    _healingPos = [(_pos select 0) - (pl_map_scale_x * 1.8), _pos select 1];
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

                if ((vehicle (leader _x)) != leader _x) then {
                    _vicPos = [(_pos select 0), (_pos select 1) - pl_map_scale_y];
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

                    _vicSpeedLimit = vehicle (leader _x) getVariable 'pl_speed_limit';
                    _vicSpeedPos = [(_pos select 0), (_pos select 1) - (pl_map_scale_y * 1.5)];
                    _vicSpeedColor = [0.9, 0.9, 0.9,1];

                    switch (_vicSpeedLimit) do { 
                        case '50' : {_vicSpeedColor = [0.4,1,0.2,1]}; 
                        case '30' : {_vicSpeedColor = [0.9,0.9,0,1]};
                        case '15' : {_vicSpeedColor = [0.7,0,0,1]}; 
                        case 'CON' : {_vicSpeedColor = [0.92,0.24,0.07,1]}; 
                        default {_vicSpeedColor = [0.4,1,0.2,1]}; 
                    };
                    
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
                }
                else
                {
                    _formPos = [(_pos select 0), (_pos select 1) - pl_map_scale_y];

                    _form = formation _x;
                    _formIcon = '\A3\3den\data\Attributes\Formation\wedge_ca.paa';
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
                        [0.9,0.9,0,1],
                        _formPos,
                        15,
                        15,
                        0,
                        '',
                        2
                    ];
                };

                
            };
        } forEach (allGroups select {side _x isEqualTo playerSide});
    "]; // "
};


[] call pl_draw_group_info;

pl_mark_vics = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_mark_vics;

pl_convoy_marker = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _convoy = _x;
                {
                    if (_x != (_convoy select 0) and _x getVariable 'pl_draw_convoy') then {
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

[] call pl_convoy_marker;

pl_dead_vics = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_damaged_vics;

pl_draw_building_search_marker = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_building_search_marker;

pl_draw_follow_marker = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_follow_marker;

pl_draw_defence_line = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_defence_line;

pl_draw_bounding_line = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_bounding_line;

pl_draw_follow_marker_other = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_follow_marker_other;

pl_draw_follow_marker_other_setup = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = getPos (leader _x);
                _pos2 = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                _display drawLine [
                    _pos1,
                    _pos2,
                    [0.9,0.9,0,1]
                    ];
            } forEach pl_follow_array_other_setup;
    "]; // "
};

[] call pl_draw_follow_marker_other_setup;

pl_draw_left_vehicles = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_left_vehicles;


pl_draw_planed_task = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_planed_task;

pl_draw_planed_task_array_wp = [];

pl_draw_planed_task_wp = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_planed_task_wp;

pl_show_charges = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_show_charges;

pl_draw_suppression = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_suppression;

pl_draw_resupply_line = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_resupply_line;

pl_draw_formation_move_mouse = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
        if (pl_draw_formation_mouse) then {
            {
                _vic = _x#0;
                _relPos = _x#1;
                _wpPos = _x#2;
                _formationLeader = (pl_draw_formation_move_mouse_array#0)#0;
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
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

[] call pl_draw_formation_move_mouse;


pl_draw_sync_wps = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_sync_wps;

// pl_draw_tank_hunt = {
//     findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_mark_supllies;

pl_draw_unload_inf_task_plan_icon = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
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

[] call pl_draw_unload_inf_task_plan_icon;


pl_draw_ccp_medic = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = _x select 0;
                _pos2 = getPos (_x select 1);
                _display drawLine [
                    _pos1,
                    _pos2,
                    [0.4,1,0.2,0.8]
                    ];
            } forEach pl_ccp_draw_array;
    "]; // "
};

[] call pl_draw_ccp_medic;


pl_draw_unit_group_lines = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                if (vehicle (leader _x) == leader _x) then {
                    _pos1 = getPos (leader _x);
                    {
                        _pos2 = getPos _x;
                        _display drawLine [
                            _pos1,
                            _pos2,
                            [0,0.4,0.6,0.5]
                            ];
                    } forEach ((units _x) - [leader _x]);
                };
            } forEach (hcSelected player);
    "]; // "
};

[] call pl_draw_unit_group_lines;

addMissionEventHandler ["Loaded", {
    params ["_saveType"];
    [] call pl_draw_group_info;
    [] call pl_mark_vics;
    [] call pl_convoy_marker;
    [] call pl_dead_vics;
    [] call pl_draw_building_search_marker;
    [] call pl_draw_follow_marker;
    [] call pl_draw_defence_line;
    [] call pl_draw_bounding_line;
    [] call pl_draw_follow_marker_other;
    [] call pl_draw_follow_marker_other_setup;
    [] call pl_draw_planed_task;
    [] call pl_draw_planed_task_wp;
    [] call pl_draw_mine_dir;
    [] call pl_draw_suppression;
    [] call pl_draw_resupply_line;
    [] call pl_draw_formation_move_mouse;
    [] call pl_draw_sync_wps;
    [] call pl_draw_unload_inf_task_plan_icon;
    [] call pl_draw_ccp_medic;
    [] call pl_draw_unit_group_lines;
    [] call pl_damaged_vics;
}];


pl_marker_targets = [];

pl_mark_targets_on_map = {
    params ["_targets"];
    _markers = [];
    _markerTargets = [];
    _time = time + 60;
    {
        if !(_x in pl_marker_targets) then {
            if (alive _x and (side _x) != civilian) then {
                if (_x isKindOf "Man" or _x isKindOf "Tank" or _x isKindOf "Car" or _x isKindOf "Truck") then {
                    _pos = getPos _x;
                    _markerName = str _x;
                    _markerSize = 0.3;
                    _marker = createMarker [_markerName, _pos];
                    _markerName setMarkerType "o_unknown";
                    if (_x isKindOf "Tank") then {
                        _markerName setMarkerType "o_armor";
                        _markerSize = 0.8;
                    };
                    if (_x isKindOf "Car") then {
                        _markerName setMarkerType "o_motor_inf";
                        _markerSize = 0.5;
                    };
                    _markerName setMarkerColor "ColorRed";
                    _markerName setMarkerSize [_markerSize, _markerSize];
                    // _markerName setMarkerText str (parseText _markerText);
                    _markers pushBack _markerName;
                    _markerTargets pushBack _x;
                    pl_marker_targets pushBack _x;
                };
            };
        };
    } forEach _targets;

    waitUntil {time >= _time};
    {
        deleteMarker _x;
    } forEach _markers;
    pl_marker_targets = pl_marker_targets - _markerTargets; 
};

pl_draw_kia = {
    params ["_unit"];
    _pos = getPos _unit;
    _markerName = str _unit;
    _marker = createMarker [_markerName, _pos];
    _markerName setMarkerSize [0.5, 0.5];
    _markerName setMarkerType "mil_warning";
    _markerName setMarkerColor "ColorBlufor";
    _time = time + 60;
    waitUntil {time >= _time};
    deleteMarker _markerName;
};
