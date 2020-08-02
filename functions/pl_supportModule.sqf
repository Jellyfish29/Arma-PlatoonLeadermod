private ["_module","_units","_activated"];
_module=_this select 0;
_units=_this select 1;
_activated=_this select 2;

hint "module";

pl_support_module_active = true;
pl_arty_ammo = _module getVariable "pl_arty_rounds";
pl_sorties = _module getVariable "pl_sorties";

true