dyn2_opfor_fation = "csat";
dyn2_opfor_side = east;
dyn2_debug = false;
// 1 - 3;
dyn2_strength = 1;


dyn2_faction_standart_squad =  createHashMapFromArray [["csat", configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad"]];
dyn2_faction_standart_fire_team =  createHashMapFromArray [["csat", configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam"]];
dyn2_faction_standart_at_team =  createHashMapFromArray [["csat", configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AT"]];
dyn2_faction_standart_recon_team =  createHashMapFromArray [["csat", configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OI_reconTeam"]];
dyn2_faction_standart_soldier =  createHashMapFromArray [["csat", "O_Soldier_F"]];
dyn2_faction_standart_mg =  createHashMapFromArray [["csat", "O_Soldier_AR_F"]];
dyn2_faction_standart_at_soldier = createHashMapFromArray [["csat", "O_Soldier_LAT_F"]];
dyn2_faction_standart_officer =  createHashMapFromArray [["csat", "O_Officer_F"]];
dyn2_faction_standart_HVT =  createHashMapFromArray [["csat", "C_man_hunter_1_F"]];
dyn2_faction_standart_PMCs = createHashMapFromArray [["csat", ["B_ION_Soldier_lxWS", "B_ION_soldier_AR_lxWS", "B_ION_shot_lxWS"]]];
dyn2_faction_standart_trasnport_vehicles =  createHashMapFromArray [["csat",["O_Truck_02_covered_F", "O_Truck_03_covered_F", "O_Truck_02_transport_F", "O_Truck_03_transport_F"]]];
dyn2_faction_standart_combat_vehicles =  createHashMapFromArray [["csat", ["O_APC_Wheeled_02_rcws_v2_F", "O_MRAP_02_hmg_F", "O_APC_Tracked_02_cannon_F"]]];// ,"CUP_O_T55_CSAT"];
dyn2_faction_standart_IFV = createHashMapFromArray [["csat", "O_APC_Wheeled_02_rcws_v2_F"]];
dyn2_faction_standart_light_armed_transport =  createHashMapFromArray [["csat", ["O_LSV_02_armed_F", "O_LSV_02_unarmed_F", "O_LSV_02_AT_F"]]];
dyn2_faction_standart_light_amored_vic =  createHashMapFromArray [["csat", "O_MRAP_02_hmg_F"]];
dyn2_faction_light_amored_vics = createHashMapFromArray [["csat", "O_MRAP_02_hmg_F"]];
dyn2_faction_standart_MBT =  createHashMapFromArray [["csat", "O_MBT_04_cannon_F"]];
dyn2_faction_standart_flag =  createHashMapFromArray [["csat", "flag_CSAT_F"]];
dyn2_faction_standart_statics_high =  createHashMapFromArray [["csat", ["O_HMG_01_high_f"]]];
dyn2_faction_standart_statics_low =  createHashMapFromArray [["csat", ["O_HMG_01_f"]]];
dyn2_faction_standart_attack_heli =  createHashMapFromArray [["csat", "O_Heli_Light_02_dynamicLoadout_F"]];
dyn2_faction_standart_transport_heli =  createHashMapFromArray [["csat", "O_Heli_Transport_04_covered_F"]];
dyn2_faction_standart_transport_plane =  createHashMapFromArray [["csat", "O_T_VTOL_02_infantry_dynamicLoadout_F"]];
dyn2_faction_standart_arty =  createHashMapFromArray [["csat", "O_MBT_02_arty_F"]];
dyn2_faction_standart_light_arty =  createHashMapFromArray [["csat", "O_Mortar_01_F"]];
dyn2_faction_standart_aa =  createHashMapFromArray [["csat", "O_APC_Tracked_02_AA_F"]];
dyn2_faction_standart_jet =  createHashMapFromArray [["csat", "O_Plane_Fighter_02_F"]];

dyn2_standart_squad = dyn2_faction_standart_squad get dyn2_opfor_fation;
dyn2_standart_fire_team = dyn2_faction_standart_fire_team get dyn2_opfor_fation;
dyn2_standart_at_team = dyn2_faction_standart_at_team get dyn2_opfor_fation;
dyn2_standart_recon_team = dyn2_faction_standart_recon_team get dyn2_opfor_fation;
dyn2_standart_soldier = dyn2_faction_standart_soldier get dyn2_opfor_fation;
dyn2_standart_at_soldier = dyn2_faction_standart_at_soldier get dyn2_opfor_fation;
dyn2_standart_mg = dyn2_faction_standart_mg get dyn2_opfor_fation;
dyn2_standart_officer = dyn2_faction_standart_officer get dyn2_opfor_fation;
dyn2_standart_HVT = dyn2_faction_standart_HVT get dyn2_opfor_fation;
dyn2_standart_PMCs = dyn2_faction_standart_PMCs get dyn2_opfor_fation;
dyn2_standart_trasnport_vehicles = dyn2_faction_standart_trasnport_vehicles get dyn2_opfor_fation;
dyn2_standart_combat_vehicles = dyn2_faction_standart_combat_vehicles get dyn2_opfor_fation;
dyn2_standart_IFV = dyn2_faction_standart_IFV get dyn2_opfor_fation;
dyn2_standart_light_armed_transport = dyn2_faction_standart_light_armed_transport get dyn2_opfor_fation;
dyn2_standart_light_amored_vic = dyn2_faction_standart_light_amored_vic get dyn2_opfor_fation;
dyn2_standart_MBT = dyn2_faction_standart_MBT get dyn2_opfor_fation;
dyn2_standart_flag = dyn2_faction_standart_flag get dyn2_opfor_fation;
dyn2_standart_statics_high = dyn2_faction_standart_statics_high get dyn2_opfor_fation;
dyn2_standart_statics_low = dyn2_faction_standart_statics_low get dyn2_opfor_fation;
dyn2_standart_attack_heli = dyn2_faction_standart_attack_heli get dyn2_opfor_fation;
dyn2_standart_transport_heli = dyn2_faction_standart_transport_heli get dyn2_opfor_fation;
dyn2_standart_transport_plane = dyn2_faction_standart_transport_plane get dyn2_opfor_fation;
dyn2_standart_light_amored_vics = dyn2_faction_light_amored_vics get dyn2_opfor_fation;
dyn2_standart_arty = dyn2_faction_standart_arty get dyn2_opfor_fation;
dyn2_standart_light_arty = dyn2_faction_standart_light_arty get dyn2_opfor_fation;
dyn2_standart_aa = dyn2_faction_standart_aa get dyn2_opfor_fation;
dyn2_standart_jet = dyn2_faction_standart_jet get dyn2_opfor_fation;
dyn2_phase_names = ["OBJ VICTORY", "OBJ ABLE", "OBJ RHINO", "OBJ BISON", "OBJ HAMMER", "OBJ WIDOW", "OBJ FIONA", "OBJ IRINE", "OBJ DAVID", "OBJ DAWN", "OBJ DIAMOND", "OBJ GOLD", "OBJ REAPER", "OBJ MARY"];
dyn2_NGO_civilians = ["C_IDAP_Man_AidWorker_01_F", "C_IDAP_Man_AidWorker_02_F", "C_IDAP_Man_AidWorker_03_F", "C_IDAP_Man_AidWorker_04_F", "C_IDAP_Man_AidWorker_05_F", "C_IDAP_Man_AidWorker_06_F", "C_IDAP_Man_AidWorker_07_F"];

// "Group" setDynamicSimulationDistance 1500;
dyn2_map_center = [worldSize / 2, worldsize / 2, 0];
dyn2_civilian_cars = ["C_Van_02_vehicle_F", "C_Van_01_transport_F", "C_Hatchback_01_F", "C_SUV_01_F"];

execVM "dyn_2_setup.sqf";
execVM "dyn_2_paint.sqf";
execVM "dyn_2_util.sqf";
execVM "dyn_2_spawn.sqf";
execVM "dyn_2_ambiance.sqf";
execVM "dyn_2_secondary_objectives.sqf";
execVM "dyn_2_opfor_missions.sqf";
execVM "dyn_2_objectives.sqf";

switch (side player) do { 
    case west : {dyn2_side_color = "colorBlufor"; dyn2_side_color_rgb = [0,0.3,0.6,0.4]; dyn2_side_prefix = "b"; dyn2_opfor_prefix = "o"}; 
    case east : {dyn2_side_color = "colorOpfor"; dyn2_side_color_rgb = [0.5,0,0,0.4]; dyn2_side_prefix = "o"; dyn2_opfor_prefix = "b"};
    case resistance : {dyn2_side_color = "colorIndependent"; dyn2_side_color_rgb = [0,0.5,0,0.4]; dyn2_side_prefix = "n"; dyn2_opfor_prefix = "o"};
    default {dyn2_side_color = "colorBlufor"; dyn2_side_color_rgb = [0,0.3,0.6,0.4]; dyn2_side_prefix = "b"; dyn2_opfor_prefix = "o"}; 
};



dyn2_small_OP = [
    ["Land_BagFence_Round_F",[-3.65332,2.32227,-0.00130081],76.7557,1,0,[0,0],"","",true,false], 
    ["Land_BagFence_Long_F",[3.19336,3.32813,-0.000999451],40.3705,1,0,[0,0],"","",true,false], 
    ["Land_BagBunker_Small_F",[4.94922,-0.117188,0],219.652,1,0,[0,0],"","",true,false], 
    ["Land_BagFence_Long_F",[-2.30566,4.73145,-0.000999451],132.701,1,0,[0,-0],"","",true,false], 
    ["Land_BagFence_Long_F",[0.929688,5.21484,-0.000999451],40.3705,1,0,[0,0],"","",true,false], 
    ["Land_TentDome_F",[-4.89941,-2.46582,-8.58307e-005],225.124,1,0,[0.108338,0.000247712],"","",true,false], 
    ["Land_BagFence_Long_F",[4.51855,-3.41504,-0.00053215],312.102,1,0,[0,0],"","",true,false], 
    ["Land_TentDome_F",[-0.124023,-5.77148,-0.0004673],305.227,1,0,[0.018377,0.106769],"","",true,false], 
    ["Land_BagFence_Corner_F",[-0.6875,6.53906,-0.00100136],310.309,1,0,[0,0],"","",true,false]
];

// dyn_grab = [getMarkerPos "grabber", 50, true] call BIS_fnc_objectsGrabber;

dyn2_standart_csat_CP = [
    ["Land_ConnectorTent_01_CSAT_brownhex_cross_F",[-1.6582,-1.14844,0],46.7815,1,0,[0,0],"","",false,false], 
    ["Land_Laptop_03_olive_F",[1.26563,-2.88086,0],42.5516,1,0,[0,0],"","",true,false], 
    ["Land_Laptop_03_olive_F",[-3.06445,1.1582,0],42.5516,1,0,[0,0],"","",true,false], 
    ["Land_PortableDesk_01_black_F",[1.80176,-3.36328,0],224.587,1,0,[0,0],"","",true,false], 
    ["Land_IPPhone_01_black_F",[1.78516,-3.42969,0],43.208,1,0,[0,0],"","",true,false], 
    ["Land_PortableDesk_01_olive_F",[-3.6582,1.9248,0],47.2169,1,0,[0,0],"","",true,false], 
    ["Land_IPPhone_01_black_F",[-3.63574,1.86133,0],43.208,1,0,[0,0],"","",true,false], 
    ["Land_ConnectorTent_01_CSAT_brownhex_open_F",[1.19824,-4.05859,0],135.507,1,0,[0,-0],"","",false,false], 
    ["Land_ConnectorTent_01_CSAT_brownhex_open_F",[-4.29883,1.58301,0],135.507,1,0,[0,-0],"","",false,false], 
    ["Land_Laptop_03_olive_F",[-4.07031,2.19434,0],42.5516,1,0,[0,0],"","",true,false], 
    ["Land_Laptop_03_olive_F",[2.28809,-4.02734,0],42.5516,1,0,[0,0],"","",true,false], 
    ["Land_TripodScreen_01_dual_v1_black_F",[0.90918,-4.93848,0],46.0979,1,0,[0,0],"","",true,false], 
    ["O_APC_Wheeled_02_unarmed_lxWS",[3.2998,3.7793,0.150011],46.7881,1,0,[-0.108286,-0.0033941],"","",true,false], 
    ["Land_PowerGenerator_F",[-0.568359,-5.93652,0],136.408,1,0,[0,-0],"","",true,false], 
    ["O_supplyCrate_F",[-1.3584,6.81348,-1.90735e-006],132.843,1,0,[0,-0],"","",true,false], 
    ["Land_PortableGenerator_01_sand_F",[-3.13184,-6.2627,0],222.742,1,0,[0,0],"","",true,false], 
    ["Land_PortableCabinet_01_bookcase_sand_F",[4.30176,-5.75977,0],46.3223,1,0,[0,0],"","",true,false], 
    ["Land_PortableCabinet_01_7drawers_black_F",[2.62695,-6.99512,0],228.047,1,0,[0,0],"","",true,false], 
    ["O_supplyCrate_F",[-2.30078,7.58301,-1.90735e-006],132.843,1,0,[0,-0],"","",true,false], 
    ["Land_MultiScreenComputer_01_closed_olive_F",[5.00684,-6.38281,0],44.4827,1,0,[0,0],"","",true,false], 
    ["Land_PortableGenerator_01_sand_F",[7.42871,-3.39648,0],227.762,1,0,[0.0547877,-0.0497453],"","",true,false], 
    ["Land_ConnectorTent_01_CSAT_brownhex_open_F",[4.31348,-7.11914,0],135.507,1,0,[0,-0],"","",false,false], 
    ["O_Truck_02_box_F",[-5.89941,-5.82324,0.217445],224.846,1,0,[0,0],"","",true,false], 
    ["Land_PortableCabinet_01_7drawers_black_F",[3.87793,-8.09082,0],228.047,1,0,[0,0],"","",true,false], 
    ["SatelliteAntenna_01_Small_Sand_F",[-1.08691,-8.96289,0],168.394,1,0,[0,-0],"","",true,false], 
    ["OmniDirectionalAntenna_01_sand_F",[7.76855,-4.71289,0],340.685,1,0,[0.0244775,0.0698365],"","",true,false], 
    ["SatelliteAntenna_01_Small_Sand_F",[-4.31055,-8.75,0],168.394,1,0,[0,-0],"","",true,false], 
    ["Land_TentDome_F",[3.30176,9.96289,0.000167847],109.686,1,0,[-0.0696768,-0.0249283],"","",true,false], 
    ["Land_PortableWeatherStation_01_sand_F",[11.3848,-1.1123,3.8147e-006],43.1772,1,0,[-0.0506364,0.0539652],"","",true,false], 
    ["Land_TentDome_F",[-11.375,2.75684,0],109.686,1,0,[0,-0],"","",true,false], 
    ["Land_TentDome_F",[-8.08203,8.67676,0],109.686,1,0,[0,-0],"","",true,false], 
    ["Land_TentDome_F",[8.55566,8.12988,0],109.686,1,0,[0,-0],"","",true,false], 
    ["CamoNet_OPFOR_F",[6.76855,10.6709,-5.72205e-006],8.70094,1,0,[-0.0111948,0.0731502],"","",true,false], 
    ["CamoNet_OPFOR_big_F",[-10.2109,7,0],318.065,1,0,[0,0],"","",true,false], 
    ["Land_PortableGenerator_01_sand_F",[13.6846,2.74512,-1.90735e-006],227.762,1,0,[0,0],"","",true,false], 
    ["OmniDirectionalAntenna_01_sand_F",[14.1396,1.7666,0],340.685,1,0,[0,0],"","",true,false]
];


dyn2_standart_nato_cp = [
    ["Land_ConnectorTent_01_NATO_open_F",[-1.09473,-0.84375,0],131.026,1,0,[0,-0],"","",true,false], 
    ["Land_PortableGenerator_01_black_F",[2.31055,1.28711,0],41.8273,1,0,[0,0],"","",true,false], 
    ["OmniDirectionalAntenna_01_sand_F",[1.51855,2.20508,-1.90735e-006],222.483,1,0,[0,0],"","",true,false], 
    ["Land_ConnectorTent_01_NATO_cross_F",[-4.21094,1.83008,0],131.918,1,0,[0,-0],"","",true,false], 
    ["Land_PowerGenerator_F",[-3.12695,-3.65723,0],129.925,1,0,[0,-0],"","",true,false], 
    ["Land_ConnectorTent_01_NATO_open_F",[-1.4209,4.85449,0],42.9099,1,0,[0,0],"","",true,false], 
    ["SatelliteAntenna_01_Small_Sand_F",[-5.2959,-3.8623,0],219.068,1,0,[0,0],"","",true,false], 
    ["SatelliteAntenna_01_Small_Sand_F",[-3.98242,-5.37402,0],217.621,1,0,[0,0],"","",true,false], 
    ["SatelliteAntenna_01_Small_Sand_F",[-2.05469,-6.53223,0],123.912,1,0,[0,-0],"","",true,false], 
    ["Land_PortableGenerator_01_black_F",[-4.64746,6.83105,0],75.7512,1,0,[0,0],"","",true,false], 
    ["OmniDirectionalAntenna_01_sand_F",[-3.93457,8.04004,-1.90735e-006],222.483,1,0,[0,0],"","",true,false], 
    ["APC_Wheeled_01_command_base_lxWS",[-8.63379,-3.35352,0.112127],221.867,1,0,[0,0],"","",true,false], 
    ["APC_Wheeled_01_command_base_lxWS",[-9.1416,6.61621,0.112127],310.616,1,0,[0,0],"","",true,false]
];

sleep 2;

sleep 10;

pl_sorties = 20;
pl_arty_ammo = 12;



// [position, 0, dyn2_standart_csat_CP, 0] call BIS_fnc_objectsMapper;