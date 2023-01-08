#include "\a3\editor_f\Data\Scripts\dikCodes.h"

[
    "pl_enable_hc_default",
    "CHECKBOX",
    ["High Command by Default","High Command will be enabled by default (All Playerside Groups will be subordinate to the Player)"],
    ["Platoon Leader", "General"],
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enable_beep_sound",
    "CHECKBOX",
    ["Radio Beep Sounds","Plays a short beep sound when issuing Orders"],
    ["Platoon Leader", "General"],
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

// [
//     "pl_enable_auto_air_remove",
//     "CHECKBOX",
//     ["No HC Air Units","Makes Air Units no selectable by Commander"],
//     ["Platoon Leader", "General"],
//     [true],
//     nil,
//     {},
//     true
// ] call CBA_fnc_addSetting;

[
    "pl_ai_skill",
    "SLIDER", 
    ["Player Side Ai Skill", "AI Skill Level for Player Side"],
    ["Platoon Leader","AI"], 
    [0, 1, 0.8, 2],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_radio_range", 
    "SLIDER", 
    ["Radio Range", 
    "Set the maximum range for ai info sharing"],
    ["Platoon Leader","AI"], 
    [0, 2000, 700, 0], 
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_opfor_info_share_enabled",
    "CHECKBOX",
    ["Enable Enemy Info sharing","Enable the sharing of information among enemy groups"],
    ["Platoon Leader","AI"],
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_opfor_enhanced_ai",
    "CHECKBOX",
    ["Enable Enemy Enhanced AI","Enhanced Enemy Group Behaviour"],
    ["Platoon Leader","AI"],
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;


[
    "pl_suppression_min_distance", 
    "SLIDER", 
    ["Minimum Suppression Distance", 
    "..."],
    ["Platoon Leader","AI"], 
    [0, 100, 25, 0], 
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_auto_crouch_enabled",
    "CHECKBOX",
    ["Enable friendly AI Auto Crouch","Friendly Ai will crouch when aware and not moving"],
    ["Platoon Leader","AI"],
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enabled_medical",
    "CHECKBOX",
    ["Enable Medical System","enable or disable Medical System"],
    ["Platoon Leader", "Logistics"],
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_virtual_mines_enabled",
    "CHECKBOX",
    ["Enable Virtual Mines","Enable or disable the ability for engineers to lay minefields"],
    ["Platoon Leader", "Logistics"],
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enable_vehicle_recovery",
    "CHECKBOX",
    ["Enable Vehicle Recovery","enable or disable Vehicle Recovery"],
    ["Platoon Leader", "Logistics"],
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enable_reinforcements",
    "CHECKBOX",
    ["Enable Reinforcements","enable or disable Reinforcements from Supply Points"],
    ["Platoon Leader", "Logistics"],
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_max_mines_per_explo",
    "EDITBOX",
    ["Max Mines Per Explosiv Specialist","Maximum amount of virtual mines an explosiv Specialist can carry"],
    ["Platoon Leader", "Logistics"],
    ["20"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_max_reinforcement_per_vic",
    "EDITBOX",
    ["Max Reinforcements","Max Reinforcements per Supply Vehicle"],
    ["Platoon Leader", "Logistics"],
    ["20"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_max_supplies_per_vic",
    "EDITBOX",
    ["Max Supplies","Max Supplies per Supply Vehicle / 1xSupply == 1xInfantry Rearm/Heal / 5xSupply == 1xVehicle Rearm/Heal/Repair"],
    ["Platoon Leader", "Logistics"],
    ["150"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_max_repair_supplies_per_vic",
    "EDITBOX",
    ["Max Repair Supplies","Max Supplies per Repair Supply Vehicle / 1xSupply == 1xRepair / 2xSupply == 1xRecovery "],
    ["Platoon Leader", "Logistics"],
    ["20"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_arty_enabled",
    "CHECKBOX",
    ["Enable Artillery","enable or disable Platoon Leader Artillery Supports"],
    ["Platoon Leader", "Fire Support"],
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_arty_ammo",
    "EDITBOX",
    ["155mm Artillery Ammo","Set Amount of Rounds for 155mm Artillery Support"],
    ["Platoon Leader", "Fire Support"],
    ["24"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_enabled",
    "CHECKBOX",
    ["Enable CAS","enable or disable Platoon Leader Close Air Support"],
    ["Platoon Leader", "Fire Support"],
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_sorties",
    "EDITBOX",
    ["CAS Sortie Amount","Different CAS Strikes cost different amount of 'Sorties' select Amount"],
    ["Platoon Leader", "Fire Support"],
    ["25"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_plane_1",
    "EDITBOX",
    ["CAS Plane 1","Define Classname for CAS Plane 1 (Gun, Attack, SAD)"],
    ["Platoon Leader", "Fire Support"],
    ['B_Plane_CAS_01_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_plane_2",
    "EDITBOX",
    ["CAS Plane 2","Define Classname for CAS Plane 2 (JDAM)"],
    ["Platoon Leader", "Fire Support"],
    ['B_Plane_Fighter_01_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_plane_3",
    "EDITBOX",
    ["CAS Plane 3","Define Classname for CAS Plane 3 (Cluster)"],
    ["Platoon Leader", "Fire Support"],
    ['B_Plane_Fighter_01_Cluster_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_Heli_1",
    "EDITBOX",
    ["CAS Heli 1","Define Classname for CAS Heli 1 (SAD)"],
    ["Platoon Leader", "Fire Support"],
    ['B_Heli_Attack_01_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_medevac_Heli_1",
    "EDITBOX",
    ["MEDEVAC Heli","Define Classname for MEDEVAC Heli"],
    ["Platoon Leader", "Fire Support"],
    ['B_Heli_Transport_01_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_supply_Heli_1",
    "EDITBOX",
    ["Supply Heli","Define Classname for Supply Heli"],
    ["Platoon Leader", "Fire Support"],
    ['B_Heli_Transport_03_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_uav_1",
    "EDITBOX",
    ["UAV","Define Classname for UAV"],
    ["Platoon Leader", "Fire Support"],
    ['B_UAV_02_dynamicLoadout_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enable_3d_icons",
    "CHECKBOX",
    ["Enable 3D Icons","Enable Extra 3D Icons when selecting or hovering over a group"],
    ["Platoon Leader", "UI"],
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

// [
//     "pl_enable_3d_mil_symbols",
//     "CHECKBOX",
//     ["Enable 3D mil. Symbols","Enable Extra 3D military Symbols"],
//     ["Platoon Leader", "UI"],
//     [true],
//     nil,
//     {},
//     true
// ] call CBA_fnc_addSetting;

[
    "pl_enable_map_icons",
    "CHECKBOX",
    ["Enable Map Icons","Enable Map Icons for all player side groups"],
    ["Platoon Leader", "UI"],
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_fire_indicator_enabled",
    "CHECKBOX",
    ["Enable Unit Fire Indicator","When a unit is firing, its map icon will flash orange"],
    ["Platoon Leader", "UI"],
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enable_map_radio",
    "CHECKBOX",
    ["Enable Map Radio Callouts","Enable Text Radio Callouts by Ai Groups on the map"],
    ["Platoon Leader", "UI"],
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enable_chat_radio",
    "CHECKBOX",
    ["Enable Side Chat Radio Callouts","Enable Text Radio Callouts by Ai Groups"],
    ["Platoon Leader", "UI"],
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

pl_enable_vanilla_marta = false;
// [
//     "pl_enable_vanilla_marta",
//     "CHECKBOX",
//     ["Enable Vanilla Mil. Symbols","Restores Standardt MARTA-Module Functionality"],
//     ["Platoon Leader", "UI"],
//     [false],
//     nil,
//     {},
//     true
// ] call CBA_fnc_addSetting;

// [
//     "pl_enable_map_icons_performance",
//     "CHECKBOX",
//     ["Enable Map Icons Performance Mode","Less Icons and only on selected Groups"],
//     "Platoon Leader: UI",
//     [false],
//     nil,
//     {},
//     true
// ] call CBA_fnc_addSetting;


// [
//     "pl_permanent_3d_icons",
//     "CHECKBOX",
//     ["Enable Permanent 3D Icons","If off only shows 3D Icons when hovering over a Groupicon with the mouse"],
//     "Platoon Leader",
//     [true],
//     nil,
//     {},
//     true
// ] call CBA_fnc_addSetting;

pl_mark_obstacles_group_switch = {
    if (pl_show_obstacles_group) then {
        pl_show_obstacles_group = false;
        hint "Show Obstacles DEACTIVATED";
    } else {
        pl_show_obstacles_group = true;
        hint "Show Obstacles ACTIVATED";
    };  
};


["Platoon Leader","Select HC Group", "Selects the HCGroup of the Unit the player aims at", {_this spawn pl_select_group}, "", [DIK_T, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","Show Obstacles", "Show Terrain Obstacles around selected Groups", {_this spawn pl_mark_obstacles_group_switch}, "", [DIK_U, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","hcSquadIn_key", "Remote View Leader of HC Group", {_this spawn pl_spawn_cam }, "", [DIK_HOME, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","hcSquadOut_key", "Release Remote View", {_this spawn pl_remote_camera_out}, "", [DIK_END, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","pl_tac_map", "Open_Tac_Map", {_this spawn pl_open_tac_map}, "", [DIK_TAB, [false, false, false]]] call CBA_fnc_addKeybind;




