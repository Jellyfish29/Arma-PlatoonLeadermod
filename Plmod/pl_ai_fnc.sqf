
pl_spotrep = {

    params ["_group"];
    _group setVariable ["spotRepEnabled", true];

    while {true} do {
        waitUntil {(behaviour (leader _group)) isEqualto "COMBAT"};

        _targets = [];

        // [_targets] spawn pl_mark_targets_on_map;

        {
          if ((leader _group) knowsAbout _x > 1) then {
            _targets pushBack _x;
          };
        } forEach (allUnits+vehicles select {side _x isEqualTo east});
        {
            _t = _x;
            {
                if (((leader _x) distance2D (leader _group)) < 700) then {
                    _x reveal _t;
                };
            } forEach (allGroups select {side _x isEqualTo west});
        } forEach _targets;

        sleep 25;
    };
};

pl_spotrep_east = {

    params ["_group"];
    _group setVariable ["spotRepEnabled", true];

    while {true} do {

        waitUntil {(behaviour (leader _group)) isEqualto "COMBAT"};

        sleep 4;

        _targets = [];

        {
          if ((leader _group) knowsAbout _x > 1) then {
            _targets pushBack _x;
          };
        } forEach (allUnits+vehicles select {side _x isEqualTo west});

        {
            _t = _x;
            {
                if (((leader _x) distance2D (leader _group)) < 700) then {
                    _x reveal _t;
                };
            } forEach (allGroups select {side _x isEqualTo east});
        } forEach _targets;

        sleep 37;
    };
};



pl_contact_report = {
    params ["_group", "_time"];

    _leader = leader _group;
    _leader setVariable ["PlContactRepEnabled", true];
    _group setVariable ["PlContactTime", 0];
    if (vehicle _leader != _leader) then {
        _leader = vehicle _leader;
    };

    if (_leader != player) then {
        _leader addEventHandler ["FiredNear", {
            params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];

            if (((group _unit) getVariable "PlContactTime") < time) then {
                [_unit] spawn pl_contact_spotrep;
            };
            (group _unit) setVariable ["PlContactTime", (time + 80)];
            if !(alive _unit) then {
                _unit setVariable ["PlContactRepEnabled", false];
            };
        }];
    };
};

pl_global_spotrep_cd = 0;

pl_contact_spotrep = {
    params ["_unit"];
    private ["_strength"];
    _callsign = groupId (group _unit);
    _clockTime = [daytime, "HH:MM"] call BIS_fnc_timeToString;
    _gridPos = mapGridPosition _unit;
     _strength = count (units (group _unit));
    _unit sideChat format ["%1 is Engaging Enemys, over", _callsign];
    sleep 10;
    _targets = [];
    {
      if (_unit knowsAbout _x > 1) then {
        _targets pushBack _x;
      };
    } forEach (allUnits+vehicles select {side _x isEqualTo east});
    if (count _targets > 0) then {

        [_targets] spawn pl_mark_targets_on_map;

        _manSpotted = "Man" countType _targets;
        _tankSpotted = "Tank" countType _targets;
        _carSpotted = "Car" countType _targets;
        _airSpotted = "Air" countType _targets;

        _message = format ["
        <t color='#ff2020' size='1.5' align='center' underline='1'>SPOTREP</t>
        <br /><br />
        <t color='#ffffff' size='1' align='left'>Callsign:</t><t color='#ffffff' size='1' align='right'>%1</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Time:</t><t color='#ffffff' size='1' align='right'>%2</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Grid:</t><t color='#ffffff' size='1' align='right'>%3</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Own Strength:</t><t color='#ffffff' size='1' align='right'>%4</t>
        <br /><br />
        <t color='#ff2020' size='1.1' align='center' underline='1'>Enemy Strength</t>
        <br /><br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_inf.paa'/><t size='0.9' align='center'>INF</t><t size='0.9' align='right'>%5x</t>
        <br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_armor.paa'/><t size='0.9' align='center'>ARM</t><t color='#ffffff' size='0.9' align='right'>%6x</t>
        <br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_motor_inf.paa'/><t size='0.9' align='center'>MOT</t><t color='#ffffff' size='0.9' align='right'>%7x</t>
        <br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_air.paa'/><t size='0.9' align='center'>AIR</t><t color='#ffffff' size='0.9' align='right'>%8x</t>
        ",_callsign, _clockTime, _gridPos, _strength, _manSpotted, _tankSpotted, _carSpotted, _airSpotted];

        if (pl_global_spotrep_cd <= time) then {
            hint parseText _message;
            pl_global_spotrep_cd = time + 30;
        };
    }
    else
    {
        _message = format ["
        <t color='#ff2020' size='1.5' align='center' underline='1'>SPOTREP</t>
        <br /><br />
        <t color='#ffffff' size='1' align='left'>Callsign:</t><t color='#ffffff' size='1' align='right'>%1</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Time:</t><t color='#ffffff' size='1' align='right'>%2</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Grid:</t><t color='#ffffff' size='1' align='right'>%3</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Own Strength:</t><t color='#ffffff' size='1' align='right'>%4</t>
        <br /><br />
        <t color='#ff2020' size='1.1' align='center' underline='1'>Enemy Strength</t>
        <br /><br />
        <t color='#ffffff' size='1' align='center'>Unknow Strength</t>
        
        ",_callsign, _clockTime, _gridPos, _strength];

         if (pl_global_spotrep_cd <= time) then {
            hint parseText _message;
            pl_global_spotrep_cd = time + 30;
        };
    };
};

pl_player_report = {
        player sideChat "to all Elements, stand by for SPOTREP, over";
        _targets = [];
        {
          if (player knowsAbout _x > 0) then {
            _targets pushBack _x;
          };
        } forEach (allUnits+vehicles select {side _x isEqualTo east});

        [_targets] spawn pl_mark_targets_on_map;

        {
            _t = _x;
            {
                if (((leader _x) distance2D player) < 700) then {
                    _x reveal _t;
                };
            } forEach (allGroups select {side _x isEqualTo west});
        } forEach _targets;
};

pl_set_up_ai = {
    params ["_group"];
    _group setVariable ["aiSetUp", true];
    _group setVariable ["onTask", false];
    _group allowFleeing 0;
    {
        _x setSkill 1;
    } forEach (units _group);
};


while {true} do {
    {
        if (isNil {_x getVariable "spotRepEnabled"}) then {
            [_x] spawn pl_spotrep;
        };
        if (isNil {(leader _x) getVariable "PlContactRepEnabled"}) then {
            [_x] spawn pl_contact_report;
        };
        if (isNil {_x getVariable "aiSetUp"}) then {
            [_x] call pl_set_up_ai;
        };
        
    } forEach (allGroups select {side _x isEqualTo west});
    // {
    //     if (isNil {_x getVariable "spotRepEnabled"}) then {
    //         [_x] spawn pl_spotrep_east;
    //     };
    // } forEach (allGroups select {side _x isEqualTo east});
    sleep 10;
    {
        if(_x != (group player)) then {
            _x enableAttack false;
            _x setCombatMode "YELLOW";
        };
    } forEach allGroups;
    sleep 10;
    };

