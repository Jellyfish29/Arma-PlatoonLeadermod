pl_sitrep = {

    params ["_group"];

    _message = format ["
        <t color='#2020ff' size='1.5' align='center' underline='1'>SITREP</t>
        <br /><br />
        <t color='#ffffff' size='1' align='left'>Callsign:</t><t color='#ffffff' size='1' align='right'>%1</t>
        <br /><br />
        <t color='#ffffff' size='1' align='left'>Status:</t><t color='#ffffff' size='1' align='right'>%2</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Formation:</t><t color='#ffffff' size='1' align='right'>%3</t>
        <br /><br />
        <t color='#ffffff' size='1' align='left'>Active Men:</t><t color='#ffffff' size='1' align='right'>%4x</t>
        <br />
        <t color='#ffffff' size='0.9' align='left'>Health/MOS:</t><t color='#ffffff' size='0.9' align='right'>Ammo:</t>
    ", _group, (behaviour (leader _group)), (formation _group), (count (units _group))];

    {
        _mags = magazines _x;
        _mag = " ";
        _missile = " ";
        _magCount = 0;
        _missileCount = 0;

        if ((primaryWeapon _x) != "") then {
            _mag = (getArray (configFile >> "CfgWeapons" >> (primaryWeapon _x) >> "magazines")) select 0;
        };
        if ((secondaryWeapon _x) != "") then {
            _missile = (getArray (configFile >> "CfgWeapons" >> (secondaryWeapon _x) >> "magazines")) select 0;
        };

        {
            if ((_mag isEqualto _x)) then {
                _magCount = _magCount + 1;
            };
            if ((_missile isEqualto _x)) then {
                _missileCount = _missileCount + 1;
            };
        }forEach _mags;

        _unitMos = getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName");
        _unitDamage = getDammage _x;
        _unitDamage = 100 - (round (_unitDamage * 100));
        _message = _message + format ["<br /><t color='#cccccc' size='0.8' align='left'>- %1%2 / %3</t><t color='#cccccc' size='0.8' align='right'>%4x</t>",_unitDamage, "%", _unitMos, _magCount];
        if (_missileCount > 0) then{
            _message = _message + format ["<t color='#cccccc' size='0.8' align='right'>/%1x</t>", _missileCount];
        };

    }forEach (units _group);
    if (vehicle (leader _group) != (leader _group)) then{
        _vic = vehicle (leader _group);
        _vicName = getText (configFile >> "CfgVehicles" >> typeOf _vic >> "displayName");
        _unitDamage = getDammage _vic;
        _unitDamage = 100 - (round (_unitDamage * 100));
        _message = _message + format ["
            <br /><br /><t color='#cccccc' size='1' align='left'>Vehicle:</t>
            <br /><t color='#cccccc' size='1' align='left'>- %1 </t><t color='#cccccc' size='1' align='center'>%2 %3</t>", _vicName, _unitDamage, "%"];
    };



    _targets = [];
    {
      if ((leader _group) knowsAbout _x > 1) then {
        _targets append [_X];
      };
    } forEach (allUnits+vehicles select {side _x isEqualTo east});

    if ((count _targets) > 0) then {
        
        [_targets] spawn pl_mark_targets_on_map;

        _manSpotted = "Man" countType _targets;
        _tankSpotted = "Tank" countType _targets;
        _carSpotted = "Car" countType _targets;
        _airSpotted = "Air" countType _targets;

        _message = _message + format ["
        <br /><br />
        <t color='#ff2020' size='1.5' align='center' underline='1'>CONTACTS</t>
        <br /><br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_inf.paa'/><t size='0.9' align='center'>INF</t><t size='0.9' align='right'>%1x</t>
        <br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_armor.paa'/><t size='0.9' align='center'>ARM</t><t color='#ffffff' size='0.9' align='right'>%2x</t>
        <br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_motor_inf.paa'/><t size='0.9' align='center'>MOT</t><t color='#ffffff' size='0.9' align='right'>%3x</t>
        <br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_air.paa'/><t size='0.9' align='center'>AIR</t><t color='#ffffff' size='0.9' align='right'>%4x</t>
        ",_manSpotted, _tankSpotted, _carSpotted, _airSpotted];

        {
            _t = _x;
            {
                if (((leader _x) distance2D (leader _group)) < 700) then {
                    _x reveal _t;
                };
            } forEach (allGroups select {side _x isEqualTo west});
        } forEach _targets;
    }
    else
    {
        _message = _message + "
        <br /><br />
        <t color='#ff2020' size='1.5' align='center' underline='1'>CONTACTS</t>
        <br /><br />
        <t color='#aa2020' size='1' align='center'>Unknown Enemy Contacts</t>
        ";
    };
    hint parseText _message;
};


pl_spawn_sitrep = {
    [(hcSelected player select 0)] spawn pl_sitrep;
};
