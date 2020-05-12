pl_ammoBearer = {
    params ["_group"];

    {    
        if (isNil {_x getVariable "ammoBearerSet"}) then {
            _x setVariable ["ammoBearerSet", true];
            _x addEventHandler ["Reloaded", {
                params ["_unit", "_weapon", "_muzzle", "_newMagazine", "_oldMagazine"];

                _ammoBearerClsNames = ["B_Soldier_A_F", "O_Soldier_A_F", "I_E_Soldier_A_F", "I_Soldier_A_F"];
                _mag = (getArray (configFile >> "CfgWeapons" >> (primaryWeapon _unit) >> "magazines")) select 0;
                _mags = magazines _unit;
                _magCount = 0;

                {
                    if ((_mag isEqualto _x)) then {
                        _magCount = _magCount + 1;
                    };
                }forEach _mags;

                if ((_magCount == 0)) then {
                    _ammoBearer = 0;

                    {
                        if ((typeOf _x) in _ammoBearerClsNames) then {
                            _ammoBearer = _x
                        };
                    } forEach (units (group _unit));

                    if !((str _ammoBearer) isEqualto "0") then {

                        _abMag = (getArray (configFile >> "CfgWeapons" >> (primaryWeapon _ammoBearer) >> "magazines")) select 0;
                        _abMags = magazines _ammoBearer;
                        _availableMagCount = 0;

                        {
                            if ((_mag isEqualto _x)) then {
                                _availableMagCount = _availableMagCount + 1;
                            };
                        }forEach _abMags;

                        if (_availableMagCount > 0) then {

                            if (_mag isEqualto _abMag) then {
                                if (_availableMagCount > 1) then {
                                    _unit addItem _mag;
                                    _ammoBearer removeItem _mag;
                                };
                            }
                            else
                            {
                                if (_availableMagCount > 0) then {
                                    _unit addItem _mag;
                                    _ammoBearer removeItem _mag;
                                };
                            };
                        };
                    };
                };

                // Secondary Weapon Rearm from any group member

                if ((secondaryWeapon _unit) != "") then {
                    _missile = (getArray (configFile >> "CfgWeapons" >> (secondaryWeapon _unit) >> "magazines")) select 0;
                    _missileCount = 0;
                    _assistant = 0;
                    {
                        if ((_missile isEqualto _x)) then {
                            _missileCount = _missileCount + 1;
                        };
                    }forEach _mags;

                    if (_missileCount == 0) then {
                        {
                            _assMags = magazines _x;
                            if (_missile in _assMags) then {
                                if ((secondaryWeapon _x) isEqualto "") then {
                                    _assistant = _x;
                                };
                            };
                        } forEach (units (group _unit));

                        if !((str _assistant) isEqualto "0") then {
                            _unit addItem _missile;
                            _assistant removeItem _missile;
                        };
                    };
                };
            }];
        };
    } forEach (units _group);
};