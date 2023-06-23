_module=_this select 0;
// _units=_this select 1;
// _activated=_this select 2;
// if(_activated)then{
    [
    (_module getVariable "PLDCM_ModuleEnemySide"),
    (_module getVariable "PLDCM_ModuleEnemyStrength"),
    (_module getVariable "PLDCM_ModuleWeather"),
    (_module getVariable "PLDCM_ModuleCivilians"),
    (_module getVariable "PLDCM_ModulePlacePlayer")
    ] execVM "Plmod\dcm\start.sqf";
// };

true

