pl_recon = {
    private ["_group", "_markerName", "_intelInterval", "_intelMarkers", "_wp", "_leader", "_distance", "_pos", "_dir", "_markerNameArrow", "_markerNameGroup", "_posOccupied"];

    _group = (hcSelected player) select 0;

    if (_group == (group player)) exitWith {hint "Player group can´t be designated as Recon Group!";};

    // turn off recon mode
    if (pl_recon_active and _group == pl_recon_group) exitWith {pl_recon_active = false; pl_recon_group = grpNull};

    // check if another group is in Recon
    if (pl_recon_active) exitWith {hint "Only one GROUP can be designated as Recon";};

    pl_recon_active = true;
    pl_recon_group = _group;


    // [_group] call pl_reset;
    // sleep 0.2;

    playSound "beep";

    // sealth, holdfire, recon icon
    _group setBehaviour "STEALTH";
    _group setVariable ["MARTA_customIcon", ["b_recon"]];
    _group setVariable ["pl_recon_area_size", 1400];

    // _group setCombatMode "GREEN";
    // _group setVariable ["pl_hold_fire", true];
    // _group setVariable ["pl_combat_mode", true];

    // chosse intervall
    _intelInterval = 30;
    // if  infantry slower recon Interval
    if (leader _group == vehicle (leader _group)) then {
        _intelInterval = 60;
    }
    // if Vehicle faster recon interval
    else
    {
        _intelInterval = 30;
    };

    // stop leader to get full recon size
    sleep 0.5;
    doStop (leader _group);
    
    // create Recon are Marker
    _markerName = createMarker ["reconArea", getPos (leader _group)];
    _markerName setMarkerColor "colorBlue";
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Border";
    _markerName setMarkerAlpha 0.3;
    _markerName setMarkerSize [1400, 1400];

    sleep 1;

    _intelMarkers = [];

    // check if group is moving --> change area size + force stealth
    [_group, _markerName] spawn {
    params ["_group", "_markerName"];

        while {pl_recon_active} do {
            _group setBehaviour "STEALTH";
            _markerName setMarkerPos (getPos (leader _group));
            if (((currentWaypoint _group) < count (waypoints _group))) then {
                _group setVariable ["pl_recon_area_size", 600 ];
                _markerName setMarkerSize [600, 600];
            }
            else
            {
                // Get height of Group and compare to average sorrounding Height to get Bounus Vision Range
                _height = getTerrainHeightASL (getPos (leader _group));
                _diff = 360 / 12;
                _avHeight = 0;
                // check 12 test location 300m around group and calc average terrain height
                for "_i" from 0 to 12 do {
                    _degree = 1 + _i*_diff;
                    _checkPos = [400 *(sin _degree), 400 *(cos _degree), 0] vectorAdd (getPos leader _group);
                    _checkheight = getTerrainHeightASL _checkPos;
                    _avHeight = _avHeight + _checkheight;
                };
                _reconHeight = _height - (_avHeight / 12);
                // hintSilent str _reconHeight;
                // if negativ Height no Bonus Range
                if (_reconHeight <= 0) then {_reconHeight = 0};

                // Set Bonus Range
                _group setVariable ["pl_recon_area_size", 700 + (_reconHeight * 20)];
                _h = _group getVariable "pl_recon_area_size";
                _markerName setMarkerSize [_h, _h];
            };
            sleep 1;
        };
        _group setBehaviour "AWARE";
        _group setVariable ["pl_recon_area_size", nil];
    };

    // short delay
    sleep 5;

    // recon logic
    while {pl_recon_active} do {
        
        {
            // check if group has active WP and within reconarea
            if (((leader _x) distance2D (leader _group) < (_group getVariable ["pl_recon_area_size", 1400])) and alive (leader _x)) then {

                _markerNameArrow = format ["intelMarkerArrow%1", _x];
                _markerNameGroup = format ["intelMarkerGroup%1", _x];

                if ((currentWaypoint _x) < count (waypoints _x)) then {
                    _wp = waypointPosition ((waypoints _x) select (currentWaypoint _x));
                    _leader = leader _x;
                    _distance = _wp distance2D _leader;

                    // if distance to wp > 100 create Markers
                    if (_distance > 100) then {

                        _dir = _leader getDir _wp;
                        _pos = [(_distance * 0.1)*(sin _dir), (_distance * 0.1)*(cos _dir), 0] vectorAdd (getPos _leader);

                        // check if marker already exists at pos --> avoid clutter
                        _posOccupied = false;
                        if ((count _intelMarkers) == 0) then {
                            _posOccupied = false;
                        }
                        else
                        {
                            _posOccupied = {
                                if ((_pos distance2D (markerPos (_x#0))) < 100) exitWith {true};
                                false
                            } forEach _intelMarkers;
                        };

                        // 80 % chance to create Marker
                        if (!_posOccupied and (random 1) > 0.2) then {
                            createMarker [_markerNameArrow, _pos];
                            _markerNameArrow setMarkerDir _dir;
                            _markerNameArrow setMarkerType "mil_arrow2";
                            _markerNameArrow setMarkerSize [0.3, 0.3];
                            _markerNameArrow setMarkerAlpha 0.7;
                            _markerNameArrow setMarkerColor "COLOROPFOR";

                            createMarker [_markerNameGroup, getPos _leader];
                            _markerType = "o_unknown";
                            _markerSize = 0.4;
                            if (vehicle (leader _x) != leader _x) then {
                                _markerType = "o_recon";
                                _markerSize = 0.5;
                            };

                            _markerNameGroup setMarkerType _markerType;
                            _markerNameGroup setMarkerSize [_markerSize, _markerSize];
                            _markerNameGroup setMarkerAlpha 0.7;

                            _intelMarkers pushBack [_markerNameArrow , _markerNameGroup];
                        };
                    };
                }
                else
                {
                    // 45 % chance to discover static groups
                    if ((random 1) > 0.55) then {
                        createMarker [_markerNameGroup, getPos (leader _x)];
                        _markerType = "o_unknown";
                        _markerSize = 0.4;
                        if (vehicle (leader _x) != leader _x) then {
                            _markerType = "o_recon";
                            _markerSize = 0.5;
                        };
                        _markerNameGroup setMarkerType _markerType;
                        _markerNameGroup setMarkerSize [_markerSize, _markerSize];
                        _markerNameGroup setMarkerAlpha 0.7;

                        _intelMarkers pushBack ["" , _markerNameGroup];
                    };
                };
            };

            // if enemy closer then 300 m --> reveal enemy
            if ((leader _x) distance2D (leader _group) < 200) then {
                _group reveal [leader _x, 3.5];
            };

        } forEach (allGroups select {side _x != playerSide});

        // intervall
        _time = time + _intelInterval;
        waitUntil {time >= _time or !pl_recon_active};
        // cancel recon if leader dead
        if !(alive (leader pl_recon_group)) exitWith {pl_recon_active = false; pl_recon_group = grpNull};

        // delete all markers after Intervall
        {
            deleteMarker (_x#0);
            deleteMarker (_x#1);
        } forEach _intelMarkers;
        _intelMarkers = [];
    };

    // rest variables
    pl_recon_active = false;
    deleteMarker _markerName;
    _group setVariable ["MARTA_customIcon", nil];

    // _group setCombatMode "YELLOW";
    // _group setVariable ["pl_hold_fire", false];
    // _group setVariable ["pl_combat_mode", false];
};