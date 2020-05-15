pl_get_group_health = {
    params ["_group"];
    private ["_healthState"];
    _healthState = [0.4,1,0.2,1];
    {
        if ((damage _x) > 0.1) then {
            _healthState = [0.9,0.9,0,1];
        };
        if (_x getVariable "pl_wia" and alive _x) then {
            _healthState = [0.7,0,0,1];
        };
    } forEach (units _group);
    _healthState;
};


pl_draw_group_info = {

    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw"," 
        _display = _this#0;
        {
            if (hcShownBar) then {

                {
                    _unit = _x;
                    _icon = getText (configfile >> 'CfgVehicles' >> typeof _unit >> 'icon');
                    _size = 15;
                    _unitColor = [0,0.3,0.6,0.65];
                    if (_unit getVariable 'pl_wia') then {
                        _unitColor = [0.7,0,0,0.65];
                    };
                    if (_unit getVariable 'pl_is_ccp_medic' and (alive _unit)) then {
                        _unitColor = [0.4,1,0.2,0.65];
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


                _worldSizeX = round (worldSize * 0.03);
                _worldSizeY = round (worldSize * 0.02);
                _mapScale = ctrlMapScale (_this select 0);
                _mapscaleX = _mapScale * _worldSizeX;
                _mapScaleY = _mapScale * _worldSizeY;
                _pos = getPosVisual (leader _x);


                _callsignText = format ['  %1', groupId _x];
                if (count (units _x) == 1 and _x != (group player)) then {
                    _unitMos = getText (configFile >> 'CfgVehicles' >> typeOf (units _x select 0)>> 'displayName');
                    _callsignText = format ['  %1', _unitMos];
                };
                _display drawIcon [
                    '#(rgb,4,1,1)color(1,1,1,0)',
                    [0,0.3,0.6,1],
                    _pos,
                    25,
                    25,
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
                    25,
                    25,
                    0,
                    _strengthText,
                    1,
                    0.03,
                    'TahomaB',
                    'left'
                ];


                _contactIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa';
                _contactPos = [(_pos select 0) - _mapscaleX, (_pos select 1) - _mapScaleY];
                _contactColor = [0.4,1,0.2,1];
                _x setVariable ['inContact', false];
                _time = (_x getVariable 'PlContactTime') - 30;
                if (_time > time) then {
                    _contactColor = [0.7,0,0,1];
                    _x setVariable ['inContact', true];
                };
                _display drawIcon [
                    _contactIcon,
                    _contactColor,
                    _contactPos,
                    15,
                    15,
                    0,
                    '',
                    2
                ];


                _behaviourPos = [(_pos select 0) + _mapscaleX, (_pos select 1) - _mapScaleY];
                _behaviour = behaviour (leader _x);
                _setSpecial = _x getVariable 'setSpecial';
                _specialIcon = _x getVariable 'specialIcon';
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
                    15,
                    15,
                    0,
                    '',
                    2
                ];


                if (_setSpecial) then {
                    _posOffset = _mapscaleX + (_mapscaleX * 0.85);
                    _specialPos = [(_pos select 0) + _posOffset, (_pos select 1) - _mapScaleY];
                    _color = [0.9,0.9,0,1];
                    _display drawIcon [
                        _specialIcon,
                        _color,
                        _specialpos,
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


[] spawn pl_draw_group_info;

pl_mark_vics = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw"," 
        _display = _this#0;
        if (hcShownBar and pl_show_vehicles) then {
            {
                if (_x distance2D pl_show_vehicles_pos < 200) then {
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
                    ];
                };
            } forEach vehicles;
        };
    "]; // "
};

[] spawn pl_mark_vics;


pl_marker_targets = [];

pl_mark_targets_on_map = {
    params ["_targets"];
    _markers = [];
    _markerTargets = [];
    _time = time + 60;
    {
        if !(_x in pl_marker_targets) then {
            if (alive _x and (side _x) != civilian) then {
                _pos = getPos _x;
                _clockTime = [daytime, "HH:MM"] call BIS_fnc_timeToString;
                _markerText = format ["<t color='#ff2020' size='0.01'>%1</t>", _clockTime];
                _markerName = str _x;
                _markerSize = 0.3;
                _marker = createMarker [_markerName, _pos];
                _markerName setMarkerType "o_unknown";
                if (_x isKindOf "Tank") then {
                    _markerName setMarkerType "o_armor";
                    _markerSize = 0.5;
                };
                if (_x isKindOf "Car") then {
                    _markerName setMarkerType "o_motor_inf";
                    _markerSize = 0.4;
                };
                _markerName setMarkerColor "ColorRed";
                _markerName setMarkerSize [_markerSize, _markerSize];
                // _markerName setMarkerText str (parseText _markerText);
                _markers pushBack _markerName;
                _markerTargets pushBack _x;
                pl_marker_targets pushBack _x;
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