// import RscActiveText;
// import RscText;

class cfgFunctions
{
    class PlModFnc
    {
        class AddonPlMod
        {
            class init
            {
                postInit=1;
                file="\Plmod\init.sqf";
            };
        };
    };
//     class A3
//     {
//         class A2
//         {
//             class Misc
//             {
//                 class createmenu
//                 {
//                     file="Plmod\functions\fn_createMenu.sqf";
//                 };
//             };
//         };
//     };
};

class CfgPatches
{
    class Pl_Mod
    {
        projectName="Platoon Leader: High Command Mod";
        version="A3.1.5.4.3";
        author="Jellyfish";
        requiredVersion=0.1;
        units[]={};
        requiredAddons[]=
        {
            "A3_UI_F",
            "A3_Dubbing_Radio_F"
        };
    };
};

class CfgSurfaces {
    class Default {
        AIAvoidStance = 1;
    };
};

// class Extended_PreInit_EventHandlers {
//     class pl_settings {
//         init = "call compile preprocessFileLineNumbers '\Plmod\XEH_preInit.sqf'";
//     };
// };

class RscHCGroupRootMenu
{
    access=0;
    contexsensitive=1;
    title="";
    atomic=0;
    vocabulary="";
    class Items
    {
        class Empty1
        {
            title="";
            shortcuts[]={0};
            command="";
            show="HCIsLeader * (1 - HCCursorOnIconEnemy)";
            enable="0";
            speechId=0;
        };
        class EmptyBlank1: Empty1
        {
            title="";
            show="0";
            enable="0";
        };
        class Attack
        {
            title="<img color='#e5e500' image='\Plmod\gfx\buddy_bounding.paa'/><t> Buddy Bounding OW</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="['buddy'] spawn pl_bounding_squad";
            };
            show="HCIsLeader * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=1;
        };
        class EmptyBlank2: Empty1
        {
            title="command 3";
            show="0" //"(1 - HCIsLeader) + (HCIsLeader * (1 - CursorOnGround)) + (HCCursorOnIconSelectable)";
            enable="0";
        };
        class Move
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Set Waypoint</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="{[_x] spawn pl_set_waypoint} forEach (hcSelected player)"; //['MOVE',_pos,_is3D,hcselected player,false] call BIS_HC_path_menu";
            };
            show="HCIsLeader * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=3;
        };
        class MoveAdd
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Add Waypoint</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="if (count (hcSelected player) > 1 and (!pl_draw_formation_mouse)) then {[hcSelected player, true] spawn pl_move_as_formation}; if (count (hcSelected player) <= 1) then {[] spawn pl_march}";
            };
            show="HCIsLeader * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * IsSelectedToAdd";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=2;
        };
        class Watch
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa'/><t> Watch Direction</t>";
            shortcuts[]={0};
            command=-5;
            class params
            {
                expression="[] call pl_spawn_watch_dir";
            };
            show="HCIsLeader * IsWatchCommanded * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\watch_ca.paa";
            priority=2;
        };
        class Empty3
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa'/><t> Rusch/Fallback</t>";
            shortcuts[]={};
            command=-5;
            class Params
            {
                expression="{[_x] spawn pl_rush} forEach hcSelected player";
            };
            show="HCIsLeader * IsWatchCommanded * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=1;
        };
        class Empty4
        {
            title="<img color='#e5e500' image='\Plmod\gfx\team_bounding.paa'/><t> Team Bounding OW</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="['team'] spawn pl_bounding_squad";
            };
            show="HCIsLeader * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * (1 - IsSelectedToAdd)";
            enable="1";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=2;
        };
        class Empty5
        {
            title="<img color='#e5e500' image='\A3\3den\data\Attributes\SpeedMode\normal_ca.paa'/><t> Advance</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="{[_x] spawn pl_march}forEach (hcSelected player)";
            };
            show="0";//"HCIsLeader * (1 - HCCursorOnIconSelectable) * IsSelectedToAdd * IsWatchCommanded";
            enable="0";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=4;
        };
        class Empty6: Empty1
        {
            title="";
            show="0";
        };
        class Empty7: Empty1
        {
            title="";
            show="0";
        };
        class EmptyBlank7: Empty1
        {
            title="";
            show="0";
        };
        class Select
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_Selectset0";
            shortcuts[]={0};
            command="CMD_HC_SELECT_AUTO";
            show="0";//"HCIsLeader * HCCursorOnIconSelectable * (1 - IsSelectedToAdd)";
            enable="0";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\selectOver_ca.paa";
            priority=2;
        };
        class SelectAdd
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_Select0";
            shortcuts[]={0};
            command="CMD_HC_SELECT_AUTO_ADD";
            show="HCIsLeader * HCCursorOnIconSelectable * (1 - HCCursorOnIconSelectableSelected) * IsSelectedToAdd";
            enable="1";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\selectOver_ca.paa";
            priority=2;
        };
        class Deselect
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_Deselect0";
            shortcuts[]={0};
            command="CMD_HC_DESELECT_AUTO";
            show="0";//"HCIsLeader * HCCursorOnIconSelectable * (HCCursorOnIconSelectableSelected) * IsSelectedToAdd";
            enable="0";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\selectOver_ca.paa";
            priority=2;
        };
        class Empty8: Empty1
        {
            title="";
            command=-1;
            show="0";
        };
        class SelectUnitFromBar
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_SelectUnitFromBar0";
            shortcuts[]=
            {
                0,
                "0x00050000 + 3"
            };
            command="CMD_SELECT_UNIT_FROM_BAR";
            show="IsXbox * HCCanSelectUnitFromBar";
            enable="HCNotEmpty";
            speechId=0;
            priority=3;
        };
        class DeselectUnitFromBar
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_DeselectUnitFromBar0";
            shortcuts[]=
            {
                0,
                "0x00050000 + 3"
            };
            command="CMD_DESELECT_UNIT_FROM_BAR";
            show="IsXbox * HCCanDeselectUnitFromBar";
            enable="HCNotEmpty";
            speechId=0;
            priority=3;
        };
        class SelectTeamFromBar
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_SelectTeamFromBar0";
            shortcuts[]=
            {
                0,
                "0x00050000 + 3"
            };
            command="CMD_SELECT_TEAM_FROM_BAR";
            show="IsXbox * HCCanSelectTeamFromBar";
            enable="HCNotEmpty";
            speechId=0;
            priority=3;
        };
        class DeselectTeamFromBar
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_DeselectTeamFromBar0";
            shortcuts[]=
            {
                0,
                "0x00050000 + 3"
            };
            command="CMD_DESELECT_TEAM_FROM_BAR";
            show="IsXbox * HCCanDeselectTeamFromBar";
            enable="HCNotEmpty";
            speechId=0;
            priority=3;
        };
        class Empty9: Empty1
        {
            title="";
            show="0";
        };
        class Empty10: Empty1
        {
            title="";
            show="0";
        };
        class Reply
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_Communication0";
            shortcuts[]={0};
            menu="#User:BIS_fnc_addCommMenuItem_menu";
            show="1";
            enable="1";
            speechId=0;
        };
    };
};
    class RscHCMainMenu
    {
        class Items
        {
            class Move
            {
                shortcuts[] = {2};
                title = "Move";
                shortcutsAction = "CommandingMenu1";
                menu = "RscHCMoveHigh";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Target
            {
                shortcuts[] = {3};
                title = "Target";
                shortcutsAction = "CommandingMenu2";
                menu = "#USER:HC_Targets_0";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Engage
            {
                shortcuts[] = {4};
                title = "Engage";
                shortcutsAction = "CommandingMenu3";
                menu = "RscHCWatchDir";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Speed
            {
                shortcuts[] = {5};
                title = "Speed";
                shortcutsAction = "CommandingMenu4";
                menu = "RscHCSpeedMode";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Mission
            {
                shortcuts[] = {6};
                title = "Mission";
                shortcutsAction = "CommandingMenu5";
                menu = "#USER:HC_Missions_0";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Action
            {
                shortcuts[] = {7};
                title = "Action";
                shortcutsAction = "CommandingMenu6";
                menu = "#USER:HC_Custom_0";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class CombatMode
            {
                shortcuts[] = {8};
                title = "Combat Mode";
                shortcutsAction = "CommandingMenu7";
                menu = "RscHCCombatMode";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Formations
            {
                shortcuts[] = {9};
                title = "Formation";
                shortcutsAction = "CommandingMenu8";
                menu = "RscHCFormations";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Team
            {
                shortcuts[] = {10};
                title = "Team";
                shortcutsAction = "CommandingMenu9";
                menu = "RscHCTeam";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Reply
            {
                shortcuts[] = {11};
                title = "Reply";
                shortcutsAction = "CommandingMenu0";
                menu = "RscHCReply";
                speechId = 0;
            };
            // class Back
            // {
            //     shortcuts[] = {"BACK"};
            //     title = "";
            //     command = -4;
            //     speechId = 0;
            // };
        };
        access = 0;
        title = "High Command - Commander";
        atomic = 0;
        vocabulary = "";
    };
    class RscHCMoveHigh
    {
        class Items
        {
            class NextWP
            {
                shortcuts[] = {2};
                class Params
                {
                    expression = "'NEXTWP' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Next Waypoint</t>";
                shortcutsAction = "CommandingMenu1";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class CancelWP
            {
                shortcuts[] = {3};
                class Params
                {
                    expression = "'CANCELWP' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\default_ca.paa'/><t> Cancel Last Waypoint</t>";
                shortcutsAction = "CommandingMenu2";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class CancelAllWPs
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "'CANCELALLWP' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\default_ca.paa'/><t> Cancel All Waypoint</t>";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class PlSeperator1
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlStop
            {
                title="<img color='#b20000' image='\A3\3den\data\Attributes\default_ca.paa'/><t> Cancel Task / Stop</t>";
                shortcuts[]={5};
                shortcutsAction = "CommandingMenu4";
                submenu="";
                command=-5;
                class params
                {
                    expression="playSound 'beep'; [] call pl_spawn_reset";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator15
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlHold
            {
                title="<img color='#EC3E14' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa'/><t> Hold</t>";
                shortcuts[]={6};
                shortcutsAction = "CommandingMenu5";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_hold";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlExecute
            {
                title="<img color='#EC3E14' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa'/><t> Execute</t>";
                shortcuts[]={7};
                shortcutsAction = "CommandingMenu6";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_execute";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator10
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlFollow
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa'/><t> Form on Commander</t>";
                shortcuts[]={8};
                shortcutsAction = "CommandingMenu7";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_follow ";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };

            // class PlFormationMove
            // {
            //     title="<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\line_ca.paa'/><t> Formation Move</t";
            //     shortcuts[]={9};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_move_as_formation";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            
        };
        title = "Move";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCWatchDir
    {
        class items
        {
            class OpenFire
            {
                title="<img color='#e5e500' image='\Plmod\gfx\pl_std_atk.paa'/><t> Assault Position</t>";
                shortcuts[]={2};
                shortcutsAction = "CommandingMenu1";
                submenu="";
                command=-5;
                class params
                {
                    expression="[(hcSelected player) select 0] spawn pl_assault_position";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
                cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            };
            class HoldFire
            {
                title="<img color='#e5e500' image='\Plmod\gfx\pl_position.paa'/><t> Defend Position</t>";
                shortcuts[]={3};
                shortcutsAction = "CommandingMenu2";
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_defend_position} forEach (hcSelected player)";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
                cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            };
            // class PlTakePosition
            // {
            //     title="<img color='#e5e500' image='\Plmod\gfx\SFP.paa'/><t> Take Position</t>";
            //     shortcuts[]={4};
            //     shortcutsAction = "CommandingMenu3";
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_take_position;";
            //     };
            //     show="0";
            //     enable="0";
            //     speechId=0;
            // };
            class PlSuppressArea
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/><t> Suppress Position</t>";
                shortcuts[]={4};
                shortcutsAction = "CommandingMenu4";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_suppressive_fire_position";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
                cursorTexture="\A3\ui_f\data\igui\cfg\cursors\attack_ca.paa";
            };
            // class PlSeperator11
            // {
            //     title="";
            //     shortcuts[]={};
            //     submenu="";
            //     command=-1;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="1";
            //     enable="1";
            //     speechId=0;
            // };
            class Pldisengage
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa'/><t> Disengage</t>";
                shortcuts[]={5};
                shortcutsAction = "CommandingMenu5";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_disengage";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
                cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            };
            class PlSeperator21
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlGarrisonB
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa'/><t> Garrison Building</t>";
                shortcuts[]={6};
                shortcutsAction = "CommandingMenu6";
                submenu="";
                command=-5;
                class params
                {
                    expression="{[] psawn pl_garrison";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            // class PlTankHunt
            // {
            //     title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa'/><t> Destroy Vehicles</t>";
            //     shortcuts[]={6};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_tank_hunt";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            //     cursorTexture="\A3\ui_f\data\igui\cfg\cursors\attack_ca.paa";
            // };
            // class PlSeperator5
            // {
            //     title="";
            //     shortcuts[]={};
            //     submenu="";
            //     command=-1;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="1";
            //     enable="1";
            //     speechId=0;
            // };
            
            class PlAttachInf
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\n_mech_inf.paa'/><t> Attach/Detach Infantry</t";
                shortcuts[]={7};
                shortcutsAction = "CommandingMenu7";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_attach_inf";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator566666
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlComEng
            {
                title="<img color='#e5e500' image='\Plmod\gfx\b_engineer.paa'/><t> Combat Engineering Tasks</t>";
                shortcuts[]={8};
                shortcutsAction = "CommandingMenu8";
                menu="#USER:pl_combat_engineer";
                command=-5;
                class params
                {
                    expression="";
                };
                show="HCIsLeader";
                enable="1";
                speechId=0;
            };
            
            // class PlCancelTask2
            // {
            //     title="<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Cancel Task</t>";
            //     shortcuts[]={10};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="playSound 'beep'; [] call pl_spawn_reset";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
        };
        title = "Combat Tasking";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCCombatMode
    {
        class items
        {
            class Stealth
            {
                shortcuts[] = {2};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT'; _x setUnitTrait ['camouflageCoef', 0.3, true];}forEach (units _x);}forEach (hcSelected player); 'COMBAT_STEALTH' call BIS_HC_path_menu";
                };
                title = "<img color='#191999' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa'/><t> Stealth</t>";
                shortcutsAction = "CommandingMenu2";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Combat
            {
                shortcuts[] = {3};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT'; _x setUnitTrait ['camouflageCoef', 1, true];}forEach (units _x);}forEach (hcSelected player); 'COMBAT_DANGER' call BIS_HC_path_menu";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\danger_ca.paa'/><t> Combat</t";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Aware
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT'; _x setUnitTrait ['camouflageCoef', 1, true];}forEach (units _x);}forEach (hcSelected player); 'COMBAT_AWARE' call BIS_HC_path_menu";
                };
                title = "<img color='#66ff33' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\listen_ca.paa'/><t> Aware</t";
                shortcutsAction = "CommandingMenu4";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Safe
            {
                shortcuts[] = {5};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT'; _x setUnitTrait ['camouflageCoef', 1, true];}forEach (units _x);}forEach (hcSelected player); 'COMBAT_SAFE' call BIS_HC_path_menu";
                };
                title = "<img color='#ffffff' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa'/><t> Safe</t";
                shortcutsAction = "CommandingMenu5";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };

            class PlSeperator701013
            {
                title="Vehicle Speed:";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };

            class OpenFire
            {
                shortcuts[] = {6};
                class Params
                {
                    expression = "{[_x] call pl_open_fire} forEach (hcSelected player)";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/><t> Open Fire</t";
                shortcutsAction = "CommandingMenu6";
                command = -5;
                show = "1";
                enable = "HCNotEmpty";
            };
            class HoldFire
            {
                shortcuts[] = {7};
                class Params
                {
                    expression = "{[_x] call pl_hold_fire} forEach (hcSelected player)";
                };
                title = "<img color='#191999' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/><t> Hold Fire</t";
                shortcutsAction = "CommandingMenu7";
                command = -5;
                show = "1";
                enable = "HCNotEmpty";
            };
        };
        title = "Combat Mode";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCSpeedMode
    {
        class items
        {
            class Limited
            {
                shortcuts[] = {2};
                class Params
                {
                    expression = "'SPEED_LIMITED' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\SpeedMode\limited_ca.paa'/><t> Limited</t";
                shortcutsAction = "CommandingMenu1";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Normal
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "'SPEED_NORMAL' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\SpeedMode\normal_ca.paa'/><t> Normal</t";
                shortcutsAction = "CommandingMenu2";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Full
            {
                shortcuts[] = {5};
                class Params
                {
                    expression = "'SPEED_FULL' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\SpeedMode\full_ca.paa'/><t> Full</t";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlSeperator7
            {
                title="Vehicle Speed:";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlVic15
            {
                shortcuts[]={6};
                class Params
                {
                    expression = "[15] call pl_spawn_vic_speed";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> 15 km/h</t";
                shortcutsAction = "CommandingMenu6";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlVic30
            {
                shortcuts[]={7};
                class Params
                {
                    expression = "[30] call pl_spawn_vic_speed";
                };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> 30 km/h</t";
                shortcutsAction = "CommandingMenu7";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlVic50
            {
                shortcuts[]={8};
                class Params
                {
                    expression = "[50] call pl_spawn_vic_speed";
                };
                title = "<img color='#66ff33' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> 50 km/h</t";
                shortcutsAction = "CommandingMenu8";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlVicMax
            {
                shortcuts[]={9};
                class Params
                {
                    expression = "[5000] call pl_spawn_vic_speed";
                };
                title = "<img color='#ffffff' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> Max</t";
                shortcutsAction = "CommandingMenu9";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlAutoSpeed
            {
                shortcuts[]={10};
                class Params
                {
                    expression = "[] call pl_toggle_auto_speed";
                };
                title = "<img color='#ffffff' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\map_ca.paa'/><t> Toggle Auto Speed</t";
                shortcutsAction = "CommandingMenu10";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
        };
        title = "Speed";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCFormations
    {
        class items
        {
            class Column
            {
                shortcuts[] = {2};
                class Params
                {
                    expression = "'COLUMN' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\column_ca.paa'/><t> Column</t>";
                shortcutsAction = "CommandingMenu1";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class ColumnStag
            {
                shortcuts[] = {3};
                class Params
                {
                    expression = "'STAG COLUMN' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\stag_column_ca.paa'/><t> Stag Column</t>";
                shortcutsAction = "CommandingMenu2";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Wedge
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "'WEDGE' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\wedge_ca.paa'/><t> Wedge</t>";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class EchelonL
            {
                shortcuts[] = {5};
                class Params
                {
                    expression = "'ECH LEFT' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\ech_left_ca.paa'/><t> Echelon L.</t>";
                shortcutsAction = "CommandingMenu4";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class EchelonR
            {
                shortcuts[] = {6};
                class Params
                {
                    expression = "'ECH RIGHT' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\ech_right_ca.paa'/><t> Echelon R.</t>";
                shortcutsAction = "CommandingMenu5";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Vee
            {
                shortcuts[] = {7};
                class Params
                {
                    expression = "'VEE' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\vee_ca.paa'/><t> Vee</t>";
                shortcutsAction = "CommandingMenu6";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Line
            {
                shortcuts[] = {8};
                class Params
                {
                    expression = "'LINE' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\line_ca.paa'/><t> Line</t>";
                shortcutsAction = "CommandingMenu7";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class ColumnCompact
            {
                shortcuts[] = {9};
                class Params
                {
                    expression = "'FILE' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\file_ca.paa'/><t> File</t>";
                shortcutsAction = "CommandingMenu8";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Delta
            {
                shortcuts[] = {10};
                class Params
                {
                    expression = "'DIAMOND' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\diamond_ca.paa'/><t> Diamond</t>";
                shortcutsAction = "CommandingMenu9";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class plAutoFormation
            {
                shortcuts[] = {11};
                class Params
                {
                    expression = "[] call pl_toggle_auto_formation";
                };
                title = "<img color='#ffffff' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\map_ca.paa'/><t> Toggle Auto Formation</t";
                shortcutsAction = "CommandingMenu11";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
        };
        title = "Formation";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCTeam
    {
        class items
        {
            class AssignRed
            {
                title="Get in Vehicle as Cargo";
                shortcuts[]={2};
                shortcutsAction = "CommandingMenu1";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_getIn_vehicle";
                };
                show="0";
                enable="HCNotEmpty";
                speechId=0;
            };
            class AssignGreen
            {
                title="Get Out Vehicle";
                shortcuts[]={3};
                shortcutsAction = "CommandingMenu2";
                submenu="";
                command=-5;
                class params
                {
                    expression="[hcSelected player select 0] spawn pl_getOut_vehicle";
                };
                show="0";
                enable="HCNotEmpty";
                speechId=0;
            };
            class AssignBlue
            {
                title="Clear Area/Buildings";
                shortcuts[]={4};
                shortcutsAction = "CommandingMenu3";
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_sweep_area} forEach (hcSelected player)";
                };
                show="0";
                enable="0";
                speechId=0;
            };
            class AssignYellow
            {
                title="Garrison Building";
                shortcuts[]={5};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_building_garrison";
                };
                show="0";
                enable="0";
                speechId=0;
            };
            class AssignMain
            {
                shortcuts[] = {6};
                title = "Assign White";
                shortcutsAction = "CommandingMenu5";
                command = "CMD_ASSIGN_MAIN";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class SelectTeam
            {
                shortcuts[] = {10};
                title = "Team";
                shortcutsAction = "CommandingMenu9";
                menu = "0";
                show = "0";
            };
            class PlGetInVic
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa'/><t> Load Cargo</t";
                shortcuts[]={2};
                shortcutsAction = "CommandingMenu1";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_getIn_vehicle";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };

            class PlGetOutVicAtPos
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa'/><t> Unload Cargo</t";
                shortcuts[]={3};
                shortcutsAction = "CommandingMenu3";
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_unload_at_position_planed} forEach (hcSelected player);";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator15
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlCrewVehicle
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> Crew Vehicle</t";
                shortcuts[]={4};
                shortcutsAction = "CommandingMenu4";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_crew_vehicle";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlLeaveVehicle
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa'/><t> Leave Vehicle</t";
                shortcuts[]={5};
                shortcutsAction = "CommandingMenu5";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_leave_vehicle";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator46
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlmoveInConvoy
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa'/><t> Road Convoy</t";
                shortcuts[]={6};
                shortcutsAction = "CommandingMenu6";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_convoy";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlAirInsertion
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\heli_ca.paa'/><t> Air Insertion</t";
                shortcuts[]={7};
                shortcutsAction = "CommandingMenu7";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_air_insertion";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator47
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };

            class PllineUp
            {
                title="Line Up on Road";
                shortcuts[]={9};
                shortcutsAction = "CommandingMenu9";
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_line_up_on_road";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };

            class PlReverseVic
            {
                title="Reverse Vehicle Direction";
                shortcuts[]={10};
                shortcutsAction = "CommandingMenu9";
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] call pl_ch_vehicle_dir} forEach (hcSelected player)";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlUnstuckVic
            {
                title="Unstuck Vehicle/Group";
                shortcuts[]={11};
                shortcutsAction = "CommandingMenu0";
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] call pl_vehicle_unstuck;} forEach (hcSelected player);";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            // class PlResetVic
            // {
            //     title="Reset Vehicle";
            //     shortcuts[]={11};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="{[_x] call pl_vehicle_reset} forEach (hcSelected player)";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
        };
        title = "Transport";
        vocabulary = "";
    };
    class RscHCSelectTeam
    {
        class items
        {
            class TeamRed
            {
                shortcuts[] = {2};
                title = "Red";
                shortcutsAction = "CommandingMenu1";
                command = "CMD_TEAM_RED";
                show = "IsLeader";
                enable = "NotEmptyRedTeam";
            };
            class TeamGreen
            {
                shortcuts[] = {3};
                title = "Green";
                shortcutsAction = "CommandingMenu2";
                command = "CMD_TEAM_GREEN";
                show = "IsLeader";
                enable = "NotEmptyGreenTeam";
            };
            class TeamBlue
            {
                shortcuts[] = {4};
                title = "Blue";
                shortcutsAction = "CommandingMenu3";
                command = "CMD_TEAM_BLUE";
                show = "IsLeader";
                enable = "NotEmptyBlueTeam";
            };
            class TeamYellow
            {
                shortcuts[] = {5};
                title = "Yellow";
                shortcutsAction = "CommandingMenu4";
                command = "CMD_TEAM_YELLOW";
                show = "IsLeader";
                enable = "NotEmptyYellowTeam";
            };
            class TeamMain
            {
                shortcuts[] = {6};
                title = "White";
                shortcutsAction = "CommandingMenu5";
                command = "CMD_TEAM_MAIN";
                show = "IsLeader";
                enable = "NotEmptyMainTeam";
            };
        };
        title = "Team";
        vocabulary = "";
    };
    class RscHCReply
    {
        class items
        {
            class SITREP
            {
                shortcuts[]={2};
                class Params
                {
                    expression = "[] call pl_spawn_sitrep";
                };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\radio_ca.paa'/><t> SITREP</t";
                shortcutsAction = "CommandingMenu1";
                show = "HCIsLeader";
                enable = "HCNotEmpty";
                speechId = 0;
                command = -5;
            };
            class Communication
            {
                shortcuts[]={3};
                title = "Supports";
                shortcutsAction = "CommandingMenu2";
                menu = "#User:BIS_MENU_GroupCommunication";
            };
            // PL Support
            class UserRadio
            {
                shortcuts[]={4};
                title = "Custom";
                shortcutsAction = "CommandingMenu3";
                menu = "#CUSTOM_RADIO";
                show = "0"
            };
            class Radio
            {
                shortcuts[]={4};
                title = "Radio";
                shortcutsAction = "CommandingMenu3";
                menu = "RscRadio";
                enable = "HasRadio";
            };
            class PlSeperator8
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlContacts
            {
                shortcuts[]={5};
                class Params
                {
                    expression = "[] call pl_player_report";
                };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\radio_ca.paa'/><t> Report own Contacts</t";
                shortcutsAction = "CommandingMenu4";
                show = "HCIsLeader";
                enable = "1";
                speechId = 0;
                command = -5;
            };
            class PlSeperator12
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            // class PlJoinGroup
            // {
            //     title="Join Group";
            //     shortcuts[]={6};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[hcSelected player select 0] spawn pl_join_hc_group";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            class PlGroupManagement
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa'/><t> Group Management</t";
                shortcuts[]={6};
                shortcutsAction = "CommandingMenu5";
                menu="#USER:pl_group_management";
                command=-5;
                class params
                {
                    expression="";
                };
                show="HCIsLeader";
                enable="1";
                speechId=0;
            };
            // class PlSplitGroups
            // {
            //     title="Split Group";
            //     shortcuts[]={7};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[hcSelected player select 0] spawn pl_split_hc_group";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            // class PlSeperator13
            // {
            //     title="";
            //     shortcuts[]={};
            //     submenu="";
            //     command=-1;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="1";
            //     enable="1";
            //     speechId=0;
            // };
            // class PlAddGroup
            // {
            //     title="Add Group";
            //     shortcuts[]={8};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_add_to_hc";
            //     };
            //     show="HCIsLeader";
            //     enable="1";
            //     speechId=0;
            // };
            // class PlRemoveGroup
            // {
            //     title="Remove Group";
            //     shortcuts[]={9};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_spawn_remove_hc";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            // class PlSeperator18
            // {
            //     title="";
            //     shortcuts[]={};
            //     submenu="";
            //     command=-1;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="1";
            //     enable="1";
            //     speechId=0;
            // };
            // class PlChangeIconGroup
            // {
            //     title="Change Group Marker";
            //     shortcuts[]={10};
            //     menu="#USER:pl_change_icon_menu";
            //     command=-5;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            // class PlSeperator303
            // {
            //     title="";
            //     shortcuts[]={};
            //     submenu="";
            //     command=-1;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="1";
            //     enable="1";
            //     speechId=0;
            // };
            // class PlResetGroup
            // {
            //     title="Reset Group";
            //     shortcuts[]={11};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[(hcSelected player) select 0] spawn pl_reset_group";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
        };
        title = "Reply";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };

class RscHCWPRootMenu
    {
        class Items
        {
            class Type
            {
                shortcuts[] = {2};
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Type</t>";
                shortcutsAction = "CommandingMenu2";
                menu = "RscHCWPType";
                show = "1";
                enable = "1";
                speechId = 0;
            };
            class CombatMode
            {
                shortcuts[] = {3};
                title = "Combat Mode";
                shortcutsAction = "CommandingMenu2";
                menu = "RscHCWPCombatMode";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class Formations
            {
                shortcuts[] = {4};
                title = "Formation";
                shortcutsAction = "CommandingMenu3";
                menu = "RscHCWPFormations";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class Speed
            {
                shortcuts[] = {5};
                title = "Speed";
                shortcutsAction = "CommandingMenu4";
                menu = "RscHCWPSpeedMode";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class Wait
            {
                shortcuts[] = {6};
                title = "Timeout";
                shortcutsAction = "CommandingMenu5";
                menu = "RscHCWPWait";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class WaitUntil
            {
                shortcuts[] = {7};
                title = "Wait until";
                shortcutsAction = "CommandingMenu6";
                menu = "#USER:HCWPWaitUntil";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class WaitRadio
            {
                shortcuts[] = {8};
                title = "Radio";
                shortcutsAction = "CommandingMenu7";
                menu = "#USER:HCWPWaitRadio";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class Separator1
            {
                shortcuts[] = {0};
                title = "";
                command = -1;
            };
            class CreateTask
            {
                shortcuts[] = {3};
                // class Params
                // {
                //     expression = "[] call pl_get_task_plan_wp";
                // };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa'/><t> Plan Task</t>";
                shortcutsAction = "CommandingMenu3";
                menu = "#USER:pl_task_plan_menu"
                command = -5;
                show = "1";
                enable = "1";
                speechId = 0;
            };
            class CancleTask
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "[] call pl_cancel_planed_task";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa'/><t> Cancel Planed Task</t>";
                shortcutsAction = "CommandingMenu4";
                command = -5;
                show = "1";
                enable = "1";
                speechId = 0;
            };
            class Separator200
            {
                shortcuts[] = {0};
                title = "";
                command = -1;
            };
            class CancelWP
            {
                shortcuts[] = {5};
                class Params
                {
                    expression = "[] call pl_cancel_planed_task; 'WP_CANCELWP' call BIS_HC_path_menu";
                };
                title = "<img color='#b20000' image='\A3\3den\data\Attributes\default_ca.paa'/><t> Cancel Waypoint</t>";
                shortcutsAction = "CommandingMenu5";
                command = -5;
                show = "1";
                enable = "1";
                speechId = 0;
            };
            // class Back
            // {
            //     shortcuts[] = {14};
            //     shortcutsAction = "NavigateMenu";
            //     title = "";
            //     command = -4;
            //     speechId = 0;
            // };
        };
        access = 0;
        title = "";
        atomic = 0;
        vocabulary = "";
    };

class CfgMarkerClasses
{
    class Check_point_1
    {
        displayName="PL Markers";
    };
    class pl_marta_markers
    {
        displayName="PL MARTA";
    };
};
class CfgMarkers
{
    class pl_marker
    {
        name="Check Point";
        icon="\Plmod\gfx\CP.paa";
        color[]={0,0,0,1};
        size=48;
        scope=2;
        scopeCurator=2;
        shadow=0;
        markerClass="Check_point_1";
    };
    class marker_CCP: pl_marker
    {
        name="CCP";
        icon="\Plmod\gfx\pl_ccp_marker.paa";
        texture="\Plmod\gfx\pl_ccp_marker.paa";
    };
    class marker_afp: pl_marker
    {
        name="Attack by Fire Position";
        icon="\Plmod\gfx\AFP.paa";
        texture="\Plmod\gfx\AFP.paa";
    };
    class marker_sfp: pl_marker
    {
        name="Support by Fire Position";
        icon="\Plmod\gfx\SFP.paa";
        texture="\Plmod\gfx\SFP.paa";
    };
    class marker_eng: pl_marker
    {
        name="NATO Engineer";
        icon="\Plmod\gfx\b_engineer.paa";
        texture="\Plmod\gfx\b_engineer.paa";
    };
    class marker_at: pl_marker
    {
        name="NATO AT";
        icon="\Plmod\gfx\b_antiarmor.paa";
        texture="\Plmod\gfx\b_antiarmor.paa";
    };
    class marker_mcp: pl_marker
    {
        name="MCP";
        icon="\Plmod\gfx\pl_mcp_marker.paa";
        texture="\Plmod\gfx\pl_mcp_marker.paa";
    };
    class marker_r3p: pl_marker
    {
        name="R3P";
        icon="\Plmod\gfx\pl_r3p_marker.paa";
        texture="\Plmod\gfx\pl_r3p_marker.paa";
    };
    class marker_asp: pl_marker
    {
        name="ASP";
        icon="\Plmod\gfx\pl_asp_marker.paa";
        texture="\Plmod\gfx\pl_asp_marker.paa";
    };
    class marker_pp: pl_marker
    {
        name="pp";
        icon="\Plmod\gfx\pl_pp_marker.paa";
        texture="\Plmod\gfx\pl_pp_marker.paa";
    };
    class marker_rp: pl_marker
    {
        name="rp";
        icon="\Plmod\gfx\pl_rp_marker.paa";
        texture="\Plmod\gfx\pl_rp_marker.paa";
    };
    class marker_std_atk: pl_marker
    {
        name="Attack Arrow";
        icon="\Plmod\gfx\pl_std_atk.paa";
        texture="\Plmod\gfx\pl_std_atk.paa";
    };
    class marker_cqb_atk: pl_marker
    {
        name="Clear Attack Arrow";
        icon="\Plmod\gfx\pl_cqb_atk.paa";
        texture="\Plmod\gfx\pl_cqb_atk.paa";
    };
    class marker_fst_atk: pl_marker
    {
        name="Fast Attack Arrow";
        icon="\Plmod\gfx\pl_fst_atk.paa";
        texture="\Plmod\gfx\pl_fst_atk.paa";
    };
    class marker_position: pl_marker
    {
        name="Position Marker";
        icon="\Plmod\gfx\pl_position.paa";
        texture="\Plmod\gfx\pl_position.paa";
    };
    class marker_position_eny: pl_marker
    {
        name="Position Marker Enemy";
        icon="\Plmod\gfx\pl_position_eny.paa";
        texture="\Plmod\gfx\pl_position_eny.paa";
    };
    class marker_obj_eny: pl_marker
    {
        name="Objective Marker Enemy";
        icon="\Plmod\gfx\pl_obj_eny.paa";
        texture="\Plmod\gfx\pl_obj_eny.paa";
    };

    class o_f_tank_pl
    {
        name="Heavy Tank Opfor";
        icon="\Plmod\gfx\marta\o_f_tank_pl.paa";
        texture="\Plmod\gfx\marta\o_f_tank_pl.paa";
        color[]={0.5,0,0,0.8};
        size=24;
        scope=2;
        scopeCurator=2;
        shadow=0;
        markerClass="pl_marta_markers";
    };
    class o_s_tank_pl: o_f_tank_pl
    {
        name="Heavy Tank Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_tank_pl.paa";
        texture="\Plmod\gfx\marta\o_s_tank_pl.paa";
    };

    class b_f_tank_pl
    {
        name="Heavy Tank Blufor";
        icon="\Plmod\gfx\marta\b_f_tank_pl.paa";
        texture="\Plmod\gfx\marta\b_f_tank_pl.paa";
        color[]={0,0.3,0.6,0.8};
        size=24;
        scope=2;
        scopeCurator=2;
        shadow=0;
        markerClass="pl_marta_markers";
    };
    class b_s_tank_pl: b_f_tank_pl
    {
        name="Heavy Tank Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_tank_pl.paa";
        texture="\Plmod\gfx\marta\b_s_tank_pl.paa";
    };
    class n_f_tank_pl
    {
        name="Heavy Tank Independet";
        icon="\Plmod\gfx\marta\n_f_tank_pl.paa";
        texture="\Plmod\gfx\marta\n_f_tank_pl.paa";
        color[]={0,0.5,0,0.8};
        size=24;
        scope=2;
        scopeCurator=2;
        shadow=0;
        markerClass="pl_marta_markers";
    };
    class n_s_tank_pl: n_f_tank_pl
    {
        name="Heavy Tank Independet";
        icon="\Plmod\gfx\marta\n_s_tank_pl.paa";
        texture="\Plmod\gfx\marta\n_s_tank_pl.paa";
    };

    class o_f_apctr_pl: o_f_tank_pl
    {
        name="APC Tracked Opfor";
        icon="\Plmod\gfx\marta\o_f_apctr_pl.paa";
        texture="\Plmod\gfx\marta\o_f_apctr_pl.paa";
    };
    class o_s_apctr_pl: o_f_tank_pl
    {
        name="APC Tracked Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_apctr_pl.paa";
        texture="\Plmod\gfx\marta\o_s_apctr_pl.paa";
    };
    class b_f_apctr_pl: b_f_tank_pl
    {
        name="APC Tracked Blufor";
        icon="\Plmod\gfx\marta\b_f_apctr_pl.paa";
        texture="\Plmod\gfx\marta\b_f_apctr_pl.paa";
    };
    class b_s_apctr_pl: b_f_tank_pl
    {
        name="APC Tracked Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_apctr_pl.paa";
        texture="\Plmod\gfx\marta\b_s_apctr_pl.paa";
    };
    class n_f_apctr_pl: n_f_tank_pl
    {
        name="APC Tracked Independent";
        icon="\Plmod\gfx\marta\n_f_apctr_pl.paa";
        texture="\Plmod\gfx\marta\n_f_apctr_pl.paa";
    };
    class n_s_apctr_pl: n_f_tank_pl
    {
        name="APC Tracked Independent Suspected";
        icon="\Plmod\gfx\marta\n_s_apctr_pl.paa";
        texture="\Plmod\gfx\marta\n_s_apctr_pl.paa";
    };

    class o_f_apcwe_pl: o_f_tank_pl
    {
        name="APC Wheeled Opfor";
        icon="\Plmod\gfx\marta\o_f_apcwe_pl.paa";
        texture="\Plmod\gfx\marta\o_f_apcwe_pl.paa";
    };
    class o_s_apcwe_pl: o_f_tank_pl
    {
        name="APC Wheeled Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_apcwe_pl.paa";
        texture="\Plmod\gfx\marta\o_s_apcwe_pl.paa";
    };
    class b_f_apcwe_pl: b_f_tank_pl
    {
        name="APC Wheeled Blufor";
        icon="\Plmod\gfx\marta\b_f_apcwe_pl.paa";
        texture="\Plmod\gfx\marta\b_f_apcwe_pl.paa";
    };
    class b_s_apcwe_pl: b_f_tank_pl
    {
        name="APC Wheeled Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_apcwe_pl.paa";
        texture="\Plmod\gfx\marta\b_s_apcwe_pl.paa";
    };
    class n_f_apcwe_pl: n_f_tank_pl
    {
        name="APC Wheeled Independet";
        icon="\Plmod\gfx\marta\n_f_apcwe_pl.paa";
        texture="\Plmod\gfx\marta\n_f_apcwe_pl.paa";
    };
    class n_s_apcwe_pl: n_f_tank_pl
    {
        name="APC Wheeled Independet Suspected";
        icon="\Plmod\gfx\marta\n_s_apcwe_pl.paa";
        texture="\Plmod\gfx\marta\n_s_apcwe_pl.paa";
    };

    class o_f_ifvtr_pl: o_f_tank_pl
    {
        name="IFV Tracked Opfor";
        icon="\Plmod\gfx\marta\o_f_ifvtr_pl.paa";
        texture="\Plmod\gfx\marta\o_f_ifvtr_pl.paa";
    };
    class o_s_ifvtr_pl: o_f_tank_pl
    {
        name="IFV Tracked Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_ifvtr_pl.paa";
        texture="\Plmod\gfx\marta\o_s_ifvtr_pl.paa";
    };
    class b_f_ifvtr_pl: b_f_tank_pl
    {
        name="IFV Tracked Blufor";
        icon="\Plmod\gfx\marta\b_f_ifvtr_pl.paa";
        texture="\Plmod\gfx\marta\b_f_ifvtr_pl.paa";
    };
    class b_s_ifvtr_pl: b_f_tank_pl
    {
        name="IFV Tracked Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_ifvtr_pl.paa";
        texture="\Plmod\gfx\marta\b_s_ifvtr_pl.paa";
    };
    class n_f_ifvtr_pl: n_f_tank_pl
    {
        name="IFV Tracked Independent";
        icon="\Plmod\gfx\marta\n_f_ifvtr_pl.paa";
        texture="\Plmod\gfx\marta\n_f_ifvtr_pl.paa";
    };
    class n_s_ifvtr_pl: n_f_tank_pl
    {
        name="IFV Tracked Independent Suspected";
        icon="\Plmod\gfx\marta\n_s_ifvtr_pl.paa";
        texture="\Plmod\gfx\marta\n_s_ifvtr_pl.paa";
    };

    class o_f_ifvwe_pl: o_f_tank_pl
    {
        name="IFV Wheeled Opfor";
        icon="\Plmod\gfx\marta\o_f_ifvwe_pl.paa";
        texture="\Plmod\gfx\marta\o_f_ifvwe_pl.paa";
    };
    class o_s_ifvwe_pl: o_f_tank_pl
    {
        name="IFV Wheeled Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_ifvwe_pl.paa";
        texture="\Plmod\gfx\marta\o_s_ifvwe_pl.paa";
    };
    class b_f_ifvwe_pl: b_f_tank_pl
    {
        name="IFV Wheeled Blufor";
        icon="\Plmod\gfx\marta\b_f_ifvwe_pl.paa";
        texture="\Plmod\gfx\marta\b_f_ifvwe_pl.paa";
    };
    class b_s_ifvwe_pl: b_f_tank_pl
    {
        name="IFV Wheeled Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_ifvwe_pl.paa";
        texture="\Plmod\gfx\marta\b_s_ifvwe_pl.paa";
    };
    class n_f_ifvwe_pl: n_f_tank_pl
    {
        name="IFV Wheeled Independet";
        icon="\Plmod\gfx\marta\n_f_ifvwe_pl.paa";
        texture="\Plmod\gfx\marta\n_f_ifvwe_pl.paa";
    };
    class n_s_ifvwe_pl: n_f_tank_pl
    {
        name="IFV Wheeled Independet Suspected";
        icon="\Plmod\gfx\marta\n_s_ifvwe_pl.paa";
        texture="\Plmod\gfx\marta\n_s_ifvwe_pl.paa";
    };

    class o_f_truck_pl: o_f_tank_pl
    {
        name="Truck Opfor";
        icon="\Plmod\gfx\marta\o_f_truck_pl.paa";
        texture="\Plmod\gfx\marta\o_f_truck_pl.paa";
    };
    class o_s_truck_pl: o_f_tank_pl
    {
        name="Truck Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_truck_pl.paa";
        texture="\Plmod\gfx\marta\o_s_truck_pl.paa";
    };
    class b_f_truck_pl: b_f_tank_pl
    {
        name="Truck Blufor";
        icon="\Plmod\gfx\marta\b_f_truck_pl.paa";
        texture="\Plmod\gfx\marta\b_f_truck_pl.paa";
    };
    class b_s_truck_pl: b_f_tank_pl
    {
        name="Truck Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_truck_pl.paa";
        texture="\Plmod\gfx\marta\b_s_truck_pl.paa";
    };
    class n_f_truck_pl: n_f_tank_pl
    {
        name="Truck Independet";
        icon="\Plmod\gfx\marta\n_f_truck_pl.paa";
        texture="\Plmod\gfx\marta\n_f_truck_pl.paa";
    };
    class n_s_truck_pl: n_f_tank_pl
    {
        name="Truck Independet Suspected";
        icon="\Plmod\gfx\marta\n_s_truck_pl.paa";
        texture="\Plmod\gfx\marta\n_s_truck_pl.paa";
    };

    class o_f_truck_sup_pl: o_f_tank_pl
    {
        name="Truck Support Opfor";
        icon="\Plmod\gfx\marta\o_f_truck_sup_pl.paa";
        texture="\Plmod\gfx\marta\o_f_truck_sup_pl.paa";
    };
    class o_s_truck_sup_pl: o_f_tank_pl
    {
        name="Truck Support Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_truck_sup_pl.paa";
        texture="\Plmod\gfx\marta\o_s_truck_sup_pl.paa";
    };
    class b_f_truck_sup_pl: b_f_tank_pl
    {
        name="Truck Support Blufor";
        icon="\Plmod\gfx\marta\b_f_truck_sup_pl.paa";
        texture="\Plmod\gfx\marta\b_f_truck_sup_pl.paa";
    };
    class b_s_truck_sup_pl: b_f_tank_pl
    {
        name="Truck Support Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_truck_sup_pl.paa";
        texture="\Plmod\gfx\marta\b_s_truck_sup_pl.paa";
    };
    class n_f_truck_sup_pl: n_f_tank_pl
    {
        name="Truck Support Independet";
        icon="\Plmod\gfx\marta\n_f_truck_sup_pl.paa";
        texture="\Plmod\gfx\marta\n_f_truck_sup_pl.paa";
    };
    class n_s_truck_sup_pl: n_f_tank_pl
    {
        name="Truck Support Independet Suspected";
        icon="\Plmod\gfx\marta\n_s_truck_sup_pl.paa";
        texture="\Plmod\gfx\marta\n_s_truck_sup_pl.paa";
    };

    class o_f_truck_rep_pl: o_f_tank_pl
    {
        name="Truck Repair Opfor";
        icon="\Plmod\gfx\marta\o_f_truck_rep_pl.paa";
        texture="\Plmod\gfx\marta\o_f_truck_rep_pl.paa";
    };
    class o_s_truck_rep_pl: o_f_tank_pl
    {
        name="Truck Repair Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_truck_rep_pl.paa";
        texture="\Plmod\gfx\marta\o_s_truck_rep_pl.paa";
    };
    class b_f_truck_rep_pl: b_f_tank_pl
    {
        name="Truck Repair Blufor";
        icon="\Plmod\gfx\marta\b_f_truck_rep_pl.paa";
        texture="\Plmod\gfx\marta\b_f_truck_rep_pl.paa";
    };
    class b_s_truck_rep_pl: b_f_tank_pl
    {
        name="Truck Repair Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_truck_rep_pl.paa";
        texture="\Plmod\gfx\marta\b_s_truck_rep_pl.paa";
    };
    class n_f_truck_rep_pl: n_f_tank_pl
    {
        name="Truck Repair Independet";
        icon="\Plmod\gfx\marta\n_f_truck_rep_pl.paa";
        texture="\Plmod\gfx\marta\n_f_truck_rep_pl.paa";
    };
    class n_s_truck_rep_pl: n_f_tank_pl
    {
        name="Truck Repair Independet Suspected";
        icon="\Plmod\gfx\marta\n_s_truck_rep_pl.paa";
        texture="\Plmod\gfx\marta\n_s_truck_rep_pl.paa";
    };

    class b_f_t_inf_pl: b_f_tank_pl
    {
        name="Inf Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_inf_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_inf_pl.paa";
    };
    class b_s_t_inf_pl: b_f_tank_pl
    {
        name="Inf Team Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_t_inf_pl.paa";
        texture="\Plmod\gfx\marta\b_s_t_inf_pl.paa";
    };
    class b_f_s_inf_pl: b_f_tank_pl
    {
        name="Inf Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_inf_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_inf_pl.paa";
    };
    class b_s_s_inf_pl: b_f_tank_pl
    {
        name="Inf Squad Blufor Suspected";
        icon="\Plmod\gfx\marta\b_s_s_inf_pl.paa";
        texture="\Plmod\gfx\marta\b_s_s_inf_pl.paa";
    };
    class b_f_t_recon_pl: b_f_tank_pl
    {
        name="Recon Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_recon_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_recon_pl.paa";
    };
    class b_f_s_recon_pl: b_f_tank_pl
    {
        name="Recon Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_recon_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_recon_pl.paa";
    };
    class b_f_t_eng_pl: b_f_tank_pl
    {
        name="Eng Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_eng_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_eng_pl.paa";
    };
    class b_f_s_eng_pl: b_f_tank_pl
    {
        name="Eng Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_eng_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_eng_pl.paa";
    };
    class b_f_t_med_pl: b_f_tank_pl
    {
        name="med Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_med_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_med_pl.paa";
    };
    class b_f_s_med_pl: b_f_tank_pl
    {
        name="med Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_med_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_med_pl.paa";
    };
    class b_f_t_aa_pl: b_f_tank_pl
    {
        name="aa Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_aa_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_aa_pl.paa";
    };
    class b_f_s_aa_pl: b_f_tank_pl
    {
        name="aa Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_aa_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_aa_pl.paa";
    };

    class o_f_t_inf_pl: o_f_tank_pl
    {
        name="Inf Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_inf_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_inf_pl.paa";
    };
    class o_s_t_inf_pl: o_f_tank_pl
    {
        name="Inf Team Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_t_inf_pl.paa";
        texture="\Plmod\gfx\marta\o_s_t_inf_pl.paa";
    };
    class o_f_s_inf_pl: o_f_tank_pl
    {
        name="Inf Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_inf_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_inf_pl.paa";
    };
    class o_s_s_inf_pl: o_f_tank_pl
    {
        name="Inf Squad Opfor Suspected";
        icon="\Plmod\gfx\marta\o_s_s_inf_pl.paa";
        texture="\Plmod\gfx\marta\o_s_s_inf_pl.paa";
    };
    class o_f_t_recon_pl: o_f_tank_pl
    {
        name="Recon Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_recon_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_recon_pl.paa";
    };
    class o_f_s_recon_pl: o_f_tank_pl
    {
        name="Recon Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_recon_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_recon_pl.paa";
    };
    class o_f_t_eng_pl: o_f_tank_pl
    {
        name="Eng Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_eng_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_eng_pl.paa";
    };
    class o_f_s_eng_pl: o_f_tank_pl
    {
        name="Eng Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_eng_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_eng_pl.paa";
    };
    class o_f_t_med_pl: o_f_tank_pl
    {
        name="med Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_med_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_med_pl.paa";
    };
    class o_f_s_med_pl: o_f_tank_pl
    {
        name="med Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_med_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_med_pl.paa";
    };
    class o_f_t_aa_pl: o_f_tank_pl
    {
        name="aa Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_aa_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_aa_pl.paa";
    };
    class o_f_s_aa_pl: o_f_tank_pl
    {
        name="aa Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_aa_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_aa_pl.paa";
    };

    class n_f_t_inf_pl: n_f_tank_pl
    {
        name="Inf Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_inf_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_inf_pl.paa";
    };
    class n_s_t_inf_pl: n_f_tank_pl
    {
        name="Inf Team Independet Suspected";
        icon="\Plmod\gfx\marta\n_s_t_inf_pl.paa";
        texture="\Plmod\gfx\marta\n_s_t_inf_pl.paa";
    };
    class n_f_s_inf_pl: n_f_tank_pl
    {
        name="Inf Squad Independet";
        icon="\Plmod\gfx\marta\n_f_s_inf_pl.paa";
        texture="\Plmod\gfx\marta\n_f_s_inf_pl.paa";
    };
    class n_s_s_inf_pl: n_f_tank_pl
    {
        name="Inf Squad Independet Suspected";
        icon="\Plmod\gfx\marta\n_s_s_inf_pl.paa";
        texture="\Plmod\gfx\marta\n_s_s_inf_pl.paa";
    };
    class n_f_t_recon_pl: n_f_tank_pl
    {
        name="Recon Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_recon_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_recon_pl.paa";
    };
    class n_f_s_recon_pl: n_f_tank_pl
    {
        name="Recon Squad Independet";
        icon="\Plmod\gfx\marta\o_f_s_recon_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_recon_pl.paa";
    };
    class n_f_t_eng_pl: n_f_tank_pl
    {
        name="Eng Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_eng_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_eng_pl.paa";
    };
    class n_f_s_eng_pl: n_f_tank_pl
    {
        name="Eng Squad Independet";
        icon="\Plmod\gfx\marta\o_f_s_eng_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_eng_pl.paa";
    };
    class n_f_t_med_pl: n_f_tank_pl
    {
        name="med Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_med_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_med_pl.paa";
    };
    class n_f_s_med_pl: n_f_tank_pl
    {
        name="med Squad Independet";
        icon="\Plmod\gfx\marta\o_f_s_med_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_med_pl.paa";
    };
    class n_f_t_aa_pl: n_f_tank_pl
    {
        name="aa Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_aa_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_aa_pl.paa";
    };
    class n_f_s_aa_pl: n_f_tank_pl
    {
        name="aa Squad Independet";
        icon="\Plmod\gfx\marta\o_f_s_aa_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_aa_pl.paa";
    };

    class unknown_f_pl: n_f_tank_pl
    {
        name="Unknown";
        icon="\Plmod\gfx\marta\unknown_f_pl.paa";
        texture="\Plmod\gfx\marta\unknown_f_pl.paa";
    };
    class unknown_s_pl: n_f_tank_pl
    {
        name="Unknown Suspected";
        icon="\Plmod\gfx\marta\unknown_s_pl.paa";
        texture="\Plmod\gfx\marta\unknown_s_pl.paa";
    };
};

class cfgGroupIcons
{
    class Flag
    {
        name = "Flag";
        icon = "\A3\ui_f\data\map\markers\system\dummy_ca.paa";
        color[] = {1, 0, 0, 1};
        size = 32;
        shadow = 1;
        scope = 1;
    };
    class b_unknown_pl: Flag
    {
        name = "Unknown";
        icon = "\A3\ui_f\data\map\markers\nato\b_unknown_pl.paa";
        texture = "\A3\ui_f\data\map\markers\nato\b_unknown_pl.paa";
        side = 1;
        size = 24;
        scope = 1;
        shadow = 0;
        color[] = {"(profilenamespace getvariable ['Map_BLUFOR_R',0])", "(profilenamespace getvariable ['Map_BLUFOR_G',1])", "(profilenamespace getvariable ['Map_BLUFOR_B',1])", "(profilenamespace getvariable ['Map_BLUFOR_A',0.8])"};
        markerClass = "NATO_BLUFOR";
        showEditorMarkerColor = 1;
    };
    class o_unknown_pl: b_unknown_pl
    {
        icon = "\A3\ui_f\data\map\markers\nato\o_unknown_pl.paa";
        texture = "\A3\ui_f\data\map\markers\nato\o_unknown_pl.paa";
        side = 0;
        color[] = {"(profilenamespace getvariable ['Map_OPFOR_R',0])", "(profilenamespace getvariable ['Map_OPFOR_G',1])", "(profilenamespace getvariable ['Map_OPFOR_B',1])", "(profilenamespace getvariable ['Map_OPFOR_A',0.8])"};
        markerClass = "NATO_OPFOR";
    };
    class n_unknown_pl: b_unknown_pl
    {
        icon = "\A3\ui_f\data\map\markers\nato\n_unknown_pl.paa";
        texture = "\A3\ui_f\data\map\markers\nato\n_unknown_pl.paa";
        side = 1;
        color[] = {"(profilenamespace getvariable ['Map_Independent_R',0])", "(profilenamespace getvariable ['Map_Independent_G',1])", "(profilenamespace getvariable ['Map_Independent_B',1])", "(profilenamespace getvariable ['Map_Independent_A',0.8])"};
        markerClass = "NATO_Independent";
    };

    class b_f_tank_pl: b_unknown_pl
    {
        name="Heavy Tank Blufor";
        icon="\Plmod\gfx\marta\b_f_tank_pl.paa";
        texture="\Plmod\gfx\marta\b_f_tank_pl.paa";
    };
    class b_f_apctr_pl: b_unknown_pl
    {
        name="APC Tracked Blufor";
        icon="\Plmod\gfx\marta\b_f_apctr_pl.paa";
        texture="\Plmod\gfx\marta\b_f_apctr_pl.paa";
    };
    class b_f_apcwe_pl: b_unknown_pl
    {
        name="APC Wheeled Blufor";
        icon="\Plmod\gfx\marta\b_f_apcwe_pl.paa";
        texture="\Plmod\gfx\marta\b_f_apcwe_pl.paa";
    };
    class b_f_ifvtr_pl: b_unknown_pl
    {
        name="ifv Tracked Blufor";
        icon="\Plmod\gfx\marta\b_f_ifvtr_pl.paa";
        texture="\Plmod\gfx\marta\b_f_ifvtr_pl.paa";
    };
    class b_f_ifvwe_pl: b_unknown_pl
    {
        name="ifv Wheeled Blufor";
        icon="\Plmod\gfx\marta\b_f_ifvwe_pl.paa";
        texture="\Plmod\gfx\marta\b_f_ifvwe_pl.paa";
    };
    class b_f_truck_pl: b_unknown_pl
    {
        name="Truck Blufor";
        icon="\Plmod\gfx\marta\b_f_truck_pl.paa";
        texture="\Plmod\gfx\marta\b_f_truck_pl.paa";
    };
    class b_f_truck_sup_pl: b_unknown_pl
    {
        name="Truck Support Blufor";
        icon="\Plmod\gfx\marta\b_f_truck_sup_pl.paa";
        texture="\Plmod\gfx\marta\b_f_truck_sup_pl.paa";
    };
    class b_f_truck_rep_pl: b_unknown_pl
    {
        name="Truck Repair Blufor";
        icon="\Plmod\gfx\marta\b_f_truck_rep_pl.paa";
        texture="\Plmod\gfx\marta\b_f_truck_rep_pl.paa";
    };
    class b_f_truck_med_pl: b_unknown_pl
    {
        name="Truck medical Blufor";
        icon="\Plmod\gfx\marta\b_f_truck_med_pl.paa";
        texture="\Plmod\gfx\marta\b_f_truck_med_pl.paa";
    };
    class b_f_tank_med_pl: b_unknown_pl
    {
        name="Tank medical Blufor";
        icon="\Plmod\gfx\marta\b_f_tank_med_pl.paa";
        texture="\Plmod\gfx\marta\b_f_tank_med_pl.paa";
    };
    class b_f_tank_rep_pl: b_unknown_pl
    {
        name="Tank repair Blufor";
        icon="\Plmod\gfx\marta\b_f_tank_rep_pl.paa";
        texture="\Plmod\gfx\marta\b_f_tank_rep_pl.paa";
    };
    class b_f_tank_sup_pl: b_unknown_pl
    {
        name="Tank support Blufor";
        icon="\Plmod\gfx\marta\b_f_tank_sup_pl.paa";
        texture="\Plmod\gfx\marta\b_f_tank_sup_pl.paa";
    };

    class b_f_t_inf_pl: b_unknown_pl
    {
        size = 24;
        name="Inf Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_inf_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_inf_pl.paa";
    };
    class b_f_s_inf_pl: b_f_t_inf_pl
    {
        name="Inf Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_inf_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_inf_pl.paa";
    };
    class b_f_t_recon_pl: b_f_t_inf_pl
    {
        name="Recon Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_recon_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_recon_pl.paa";
    };
    class b_f_s_recon_pl: b_f_t_inf_pl
    {
        name="Recon Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_recon_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_recon_pl.paa";
    };
    class b_f_t_eng_pl: b_f_t_inf_pl
    {
        name="Eng Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_eng_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_eng_pl.paa";
    };
    class b_f_s_eng_pl: b_f_t_inf_pl
    {
        name="Eng Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_eng_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_eng_pl.paa";
    };
    class b_f_t_med_pl: b_f_t_inf_pl
    {
        name="med Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_med_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_med_pl.paa";
    };
    class b_f_s_med_pl: b_f_t_inf_pl
    {
        name="med Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_med_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_med_pl.paa";
    };
    class b_f_t_aa_pl: b_f_t_inf_pl
    {
        name="aa Team Blufor";
        icon="\Plmod\gfx\marta\b_f_t_aa_pl.paa";
        texture="\Plmod\gfx\marta\b_f_t_aa_pl.paa";
    };
    class b_f_s_aa_pl: b_f_t_inf_pl
    {
        name="aa Squad Blufor";
        icon="\Plmod\gfx\marta\b_f_s_aa_pl.paa";
        texture="\Plmod\gfx\marta\b_f_s_aa_pl.paa";
    };
    class b_f_heli_pl: b_unknown_pl
    {
        name="Helicopter Blufor";
        icon="\Plmod\gfx\marta b_f_heli_pl.paa";
        texture="\Plmod\gfx\marta b_f_heli_pl.paa";
    };
    class b_f_heliatk_pl: b_unknown_pl
    {
        name="Helicopter Attack Blufor";
        icon="\Plmod\gfx\marta b_f_heliatk_pl.paa";
        texture="\Plmod\gfx\marta b_f_heliatk_pl.paa";
    };
    class b_f_helic_pl: b_unknown_pl
    {
        name="Helicopter Cargo Blufor";
        icon="\Plmod\gfx\marta b_f_helic_pl.paa";
        texture="\Plmod\gfx\marta b_f_helic_pl.paa";
    };
    class b_f_planea_pl: b_unknown_pl
    {
        name="Plane Attack Blufor";
        icon="\Plmod\gfx\marta b_f_planea_pl.paa";
        texture="\Plmod\gfx\marta b_f_planea_pl.paa";
    };


    class o_f_tank_pl: o_unknown_pl
    {
        name="Heavy Tank Opfor";
        icon="\Plmod\gfx\marta o_f_tank_pl.paa";
        texture="\Plmod\gfx\marta o_f_tank_pl.paa";
    };
    class o_f_apctr_pl: o_unknown_pl
    {
        name="APC Tracked Opfor";
        icon="\Plmod\gfx\marta o_f_apctr_pl.paa";
        texture="\Plmod\gfx\marta o_f_apctr_pl.paa";
    };
    class o_f_apcwe_pl: o_unknown_pl
    {
        name="APC Wheeled Opfor";
        icon="\Plmod\gfx\marta o_f_apcwe_pl.paa";
        texture="\Plmod\gfx\marta o_f_apcwe_pl.paa";
    };
    class o_f_ifvtr_pl: o_unknown_pl
    {
        name="ifv Tracked Opfor";
        icon="\Plmod\gfx\marta o_f_ifvtr_pl.paa";
        texture="\Plmod\gfx\marta o_f_ifvtr_pl.paa";
    };
    class o_f_ifvwe_pl: o_unknown_pl
    {
        name="ifv Wheeled Opfor";
        icon="\Plmod\gfx\marta o_f_ifvwe_pl.paa";
        texture="\Plmod\gfx\marta o_f_ifvwe_pl.paa";
    };
    class o_f_truck_pl: o_unknown_pl
    {
        name="Truck Opfor";
        icon="\Plmod\gfx\marta o_f_truck_pl.paa";
        texture="\Plmod\gfx\marta o_f_truck_pl.paa";
    };
    class o_f_truck_sup_pl: o_unknown_pl
    {
        name="Truck Support Opfor";
        icon="\Plmod\gfx\marta o_f_truck_sup_pl.paa";
        texture="\Plmod\gfx\marta o_f_truck_sup_pl.paa";
    };
    class o_f_truck_rep_pl: o_unknown_pl
    {
        name="Truck Repair Opfor";
        icon="\Plmod\gfx\marta o_f_truck_rep_pl.paa";
        texture="\Plmod\gfx\marta o_f_truck_rep_pl.paa";
    };
    class o_f_truck_med_pl: o_unknown_pl
    {
        name="Truck medical Opfor";
        icon="\Plmod\gfx\marta o_f_truck_med_pl.paa";
        texture="\Plmod\gfx\marta o_f_truck_med_pl.paa";
    };
    class o_f_tank_rep_pl: o_unknown_pl
    {
        name="tank Repair Opfor";
        icon="\Plmod\gfx\marta o_f_tank_rep_pl.paa";
        texture="\Plmod\gfx\marta o_f_tank_rep_pl.paa";
    };
    class o_f_tank_med_pl: o_unknown_pl
    {
        name="tank medical Opfor";
        icon="\Plmod\gfx\marta o_f_tank_med_pl.paa";
        texture="\Plmod\gfx\marta o_f_tank_med_pl.paa";
    };
    class o_f_tank_sup_pl: o_unknown_pl
    {
        name="tank support Opfor";
        icon="\Plmod\gfx\marta o_f_tank_sup_pl.paa";
        texture="\Plmod\gfx\marta o_f_tank_sup_pl.paa";
    };
    class o_f_heli_pl: o_unknown_pl
    {
        name="tank support Independet";
        icon="\Plmod\gfx\marta o_f_heli_pl.paa";
        texture="\Plmod\gfx\marta o_f_heli_pl.paa";
    };
    class o_f_heliatk_pl: o_unknown_pl
    {
        name="tank support Independet";
        icon="\Plmod\gfx\marta o_f_heliatk_pl.paa";
        texture="\Plmod\gfx\marta o_f_heliatk_pl.paa";
    };
    class o_f_helic_pl: o_unknown_pl
    {
        name="tank support Independet";
        icon="\Plmod\gfx\marta o_f_helic_pl.paa";
        texture="\Plmod\gfx\marta o_f_helic_pl.paa";
    };
    class o_f_planea_pl: o_unknown_pl
    {
        name="tank support Independet";
        icon="\Plmod\gfx\marta o_f_planea_pl.paa";
        texture="\Plmod\gfx\marta o_f_planea_pl.paa";
    };

    class o_f_t_inf_pl: o_unknown_pl
    {
        size = 24;
        name="Inf Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_inf_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_inf_pl.paa";
    };
    class o_f_s_inf_pl: o_f_t_inf_pl
    {
        name="Inf Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_inf_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_inf_pl.paa";
    };
    class o_f_t_recon_pl: o_f_t_inf_pl
    {
        name="Recon Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_recon_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_recon_pl.paa";
    };
    class o_f_s_recon_pl: o_f_t_inf_pl
    {
        name="Recon Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_recon_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_recon_pl.paa";
    };
    class o_f_t_eng_pl: o_f_t_inf_pl
    {
        name="Eng Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_eng_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_eng_pl.paa";
    };
    class o_f_s_eng_pl: o_f_t_inf_pl
    {
        name="Eng Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_eng_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_eng_pl.paa";
    };
    class o_f_t_med_pl: o_f_t_inf_pl
    {
        name="med Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_med_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_med_pl.paa";
    };
    class o_f_s_med_pl: o_f_t_inf_pl
    {
        name="med Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_med_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_med_pl.paa";
    };
    class o_f_t_aa_pl: o_f_t_inf_pl
    {
        name="aa Team Opfor";
        icon="\Plmod\gfx\marta\o_f_t_aa_pl.paa";
        texture="\Plmod\gfx\marta\o_f_t_aa_pl.paa";
    };
    class o_f_s_aa_pl: o_f_t_inf_pl
    {
        name="aa Squad Opfor";
        icon="\Plmod\gfx\marta\o_f_s_aa_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_aa_pl.paa";
    };

    class n_f_tank_pl: n_unknown_pl
    {
        size = 24;
        name="Heavy Tank Independet";
        icon="\Plmod\gfx\marta n_f_tank_pl.paa";
        texture="\Plmod\gfx\marta n_f_tank_pl.paa";
    };
    class n_f_apctr_pl: n_unknown_pl
    {
        name="APC Tracked Independet";
        icon="\Plmod\gfx\marta n_f_apctr_pl.paa";
        texture="\Plmod\gfx\marta n_f_apctr_pl.paa";
    };
    class n_f_apcwe_pl: n_unknown_pl
    {
        name="APC Wheeled Independet";
        icon="\Plmod\gfx\marta n_f_apcwe_pl.paa";
        texture="\Plmod\gfx\marta n_f_apcwe_pl.paa";
    };
    class n_f_ifvtr_pl: n_unknown_pl
    {
        name="ifv Tracked Independet";
        icon="\Plmod\gfx\marta n_f_ifvtr_pl.paa";
        texture="\Plmod\gfx\marta n_f_ifvtr_pl.paa";
    };
    class n_f_ifvwe_pl: n_unknown_pl
    {
        name="ifv Wheeled Independet";
        icon="\Plmod\gfx\marta n_f_ifvwe_pl.paa";
        texture="\Plmod\gfx\marta n_f_ifvwe_pl.paa";
    };
    class n_f_truck_pl: n_unknown_pl
    {
        name="Truck Independet";
        icon="\Plmod\gfx\marta n_f_truck_pl.paa";
        texture="\Plmod\gfx\marta n_f_truck_pl.paa";
    };
    class n_f_truck_sup_pl: n_unknown_pl
    {
        name="Truck Repair Independet";
        icon="\Plmod\gfx\marta n_f_truck_sup_pl.paa";
        texture="\Plmod\gfx\marta n_f_truck_sup_pl.paa";
    };
    class n_f_truck_rep_pl: n_unknown_pl
    {
        name="Truck repport Independet";
        icon="\Plmod\gfx\marta n_f_truck_rep_pl.paa";
        texture="\Plmod\gfx\marta n_f_truck_rep_pl.paa";
    };
    class n_f_truck_med_pl: n_unknown_pl
    {
        name="Truck medical Independet";
        icon="\Plmod\gfx\marta n_f_truck_med_pl.paa";
        texture="\Plmod\gfx\marta n_f_truck_med_pl.paa";
    };
    class n_f_tank_med_pl: n_unknown_pl
    {
        name="tank medical Independet";
        icon="\Plmod\gfx\marta n_f_tank_med_pl.paa";
        texture="\Plmod\gfx\marta n_f_tank_med_pl.paa";
    };
    class n_f_tank_rep_pl: n_unknown_pl
    {
        name="tank repair Independet";
        icon="\Plmod\gfx\marta n_f_tank_rep_pl.paa";
        texture="\Plmod\gfx\marta n_f_tank_rep_pl.paa";
    };
    class n_f_tank_sup_pl: n_unknown_pl
    {
        name="tank support Independet";
        icon="\Plmod\gfx\marta n_f_tank_sup_pl.paa";
        texture="\Plmod\gfx\marta n_f_tank_sup_pl.paa";
    };
    class n_f_heli_pl: n_unknown_pl
    {
        name="tank support Independet";
        icon="\Plmod\gfx\marta n_f_heli_pl.paa";
        texture="\Plmod\gfx\marta n_f_heli_pl.paa";
    };
    class n_f_heliatk_pl: n_unknown_pl
    {
        name="tank support Independet";
        icon="\Plmod\gfx\marta n_f_heliatk_pl.paa";
        texture="\Plmod\gfx\marta n_f_heliatk_pl.paa";
    };
    class n_f_helic_pl: n_unknown_pl
    {
        name="tank support Independet";
        icon="\Plmod\gfx\marta n_f_helic_pl.paa";
        texture="\Plmod\gfx\marta n_f_helic_pl.paa";
    };
    class n_f_planea_pl: n_unknown_pl
    {
        name="tank support Independet";
        icon="\Plmod\gfx\marta n_f_planea_pl.paa";
        texture="\Plmod\gfx\marta n_f_planea_pl.paa";
    };

    class n_f_t_inf_pl: n_unknown_pl
    {
        size = 24;
        name="Inf Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_inf_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_inf_pl.paa";
    };
    class n_f_s_inf_pl: n_f_t_inf_pl
    {
        name="Inf Squad Independet";
        icon="\Plmod\gfx\marta\o_f_s_inf_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_inf_pl.paa";
    };
    class n_f_t_recon_pl: n_f_t_inf_pl
    {
        name="Recon Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_recon_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_recon_pl.paa";
    };
    class n_f_s_recon_pl: n_f_t_inf_pl
    {
        name="Recon Squad Independet";
        icon="\Plmod\gfx\marta\o_f_s_recon_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_recon_pl.paa";
    };
    class n_f_t_eng_pl: n_f_t_inf_pl
    {
        name="Eng Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_eng_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_eng_pl.paa";
    };
    class n_f_s_eng_pl: n_f_t_inf_pl
    {
        name="Eng Squad Independet";
        icon="\Plmod\gfx\marta\o_f_s_eng_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_eng_pl.paa";
    };
    class n_f_t_med_pl: n_f_t_inf_pl
    {
        name="med Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_med_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_med_pl.paa";
    };
    class n_f_s_med_pl: n_f_t_inf_pl
    {
        name="med Squad Independet";
        icon="\Plmod\gfx\marta\o_f_s_med_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_med_pl.paa";
    };
    class n_f_t_aa_pl: n_f_t_inf_pl
    {
        name="aa Team Independet";
        icon="\Plmod\gfx\marta\n_f_t_aa_pl.paa";
        texture="\Plmod\gfx\marta\n_f_t_aa_pl.paa";
    };
    class n_f_s_aa_pl: n_f_t_inf_pl
    {
        name="aa Squad Independet";
        icon="\Plmod\gfx\marta\o_f_s_aa_pl.paa";
        texture="\Plmod\gfx\marta\o_f_s_aa_pl.paa";
    };

    class b_recon_add_pl: Flag
    {
        name = "Recon add B";
        icon="\Plmod\gfx\marta\b_recon_add_pl.paa";
        texture="\Plmod\gfx\marta\b_recon_add_pl.paa";
        side = 1;
        size = 29;
        scope = 1;
        shadow = 0;
        color[] = {0,0,0,1};
        markerClass = "NATO_BLUFOR";
        showEditorMarkerColor = 1;
    };
    class o_recon_add_pl: Flag
    {
        name = "Recon add O";
        icon="\Plmod\gfx\marta\o_recon_add_pl.paa";
        texture="\Plmod\gfx\marta\o_recon_add_pl.paa";
        side = 1;
        size = 29;
        scope = 1;
        shadow = 0;
        color[] = {0,0,0,1};
        markerClass = "NATO_BLUFOR";
        showEditorMarkerColor = 1;
    };
    class n_recon_add_pl: Flag
    {
        name = "Recon add N";
        icon="\Plmod\gfx\marta\n_recon_add_pl.paa";
        texture="\Plmod\gfx\marta\n_recon_add_pl.paa";
        side = 1;
        size = 29;
        scope = 1;
        shadow = 0;
        color[] = {0,0,0,1};
        markerClass = "NATO_BLUFOR";
        showEditorMarkerColor = 1;
    };
};
class RscSubmenu;
class RscMenuStatus: RscSubmenu
{
    class Items
    {
        class Pl_Status_Separator1
        {
            title="";
            shortcuts[]={};
            submenu="";
            command=-1;
            class params
            {
                expression="";
            };
            show="1";
            enable="1";
            speechId=0;
        };
        class Pl_Status_CreateHCGroup
        {
            title="Create HC Group";
            shortcuts[]={10};
            submenu="";
            command=-5;
            class params
            {
                expression="[] call pl_create_hc_group";
            };
            show="1";
            enable="NotEmpty";
            speechId=0;
        };
    };
};

class CfgSounds {
    
    class radioina
    {
    name = "in2a";
    sound[] = {"A3\Dubbing_Radio_F\sfx\in2a.ogg",1,1};
    titles[] = {};
    };

    class radioinb
    {
    name = "in2b";
    sound[] = {"A3\Dubbing_Radio_F\sfx\in2b.ogg",1,1};
    titles[] = {};
    };

    class radioinc
    {
    name = "in2c";
    sound[] = {"A3\Dubbing_Radio_F\sfx\in2c.ogg",1,1};
    titles[] = {};
    };

    class radiouta
    {
    name = "out2a";
    sound[] = {"A3\Dubbing_Radio_F\sfx\out2a.ogg",1,1};
    titles[] = {};
    };
    class radioutb
    {
    name = "out2b";
    sound[] = {"A3\Dubbing_Radio_F\sfx\out2b.ogg",1,1};
    titles[] = {};
    };
    class radioutc
    {
    name = "out2c";
    sound[] = {"A3\Dubbing_Radio_F\sfx\out2c.ogg",1,1};
    titles[] = {};
    };
    class radionoise1
    {
    name = "noise1";
    sound[] = {"A3\Dubbing_Radio_F\sfx\radionoise1.ogg",1,1};
    titles[] = {};
    };
    class radionoise2
    {
    name = "noise2";
    sound[] = {"A3\Dubbing_Radio_F\sfx\radionoise2.ogg",1,1};
    titles[] = {};
    };
    class radionoise3
    {
    name = "noise3";
    sound[] = {"A3\Dubbing_Radio_F\sfx\radionoise3.ogg",1,1};
    titles[] = {};
    };
};


class pl_RscMapControl
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = 101;
    idc = 2000;
    style = 48;
    colorBackground[] = {0.969, 0.957, 0.949, 1};
    colorOutside[] = {0, 0, 0, 1};
    colorText[] = {0, 0, 0, 1};
    font = "TahomaB";
    sizeEx = 0.04;
    colorSea[] = {0.467, 0.631, 0.851, 0.5};
    colorForest[] = {0.624, 0.78, 0.388, 0.5};
    colorRocks[] = {0, 0, 0, 0.3};
    colorCountlines[] = {0.572, 0.354, 0.188, 0.25};
    colorMainCountlines[] = {0.572, 0.354, 0.188, 0.5};
    colorCountlinesWater[] = {0.491, 0.577, 0.702, 0.3};
    colorMainCountlinesWater[] = {0.491, 0.577, 0.702, 0.6};
    colorForestBorder[] = {0, 0, 0, 0};
    colorRocksBorder[] = {0, 0, 0, 0};
    colorPowerLines[] = {0.1, 0.1, 0.1, 1};
    colorRailWay[] = {0.8, 0.2, 0, 1};
    colorNames[] = {0.1, 0.1, 0.1, 0.9};
    colorInactive[] = {1, 1, 1, 0.5};
    colorLevels[] = {0.286, 0.177, 0.094, 0.5};
    colorTracks[] = {0.84, 0.76, 0.65, 0.15};
    colorRoads[] = {0.7, 0.7, 0.7, 1};
    colorMainRoads[] = {0.9, 0.5, 0.3, 1};
    colorTracksFill[] = {0.84, 0.76, 0.65, 1};
    colorRoadsFill[] = {1, 1, 1, 1};
    colorMainRoadsFill[] = {1, 0.6, 0.4, 1};
    colorGrid[] = {0.1, 0.1, 0.1, 0.6};
    colorGridMap[] = {0.1, 0.1, 0.1, 0.6};
    stickX[] = {0.2, {"Gamma", 1, 1.5}};
    stickY[] = {0.2, {"Gamma", 1, 1.5}};
    moveOnEdges = 1;
    x = 0.29 * safezoneW + safezoneX;
    y = 0.262 * safezoneH + safezoneY;
    w = 0.426562 * safezoneW;
    h = 0.504 * safezoneH;

    shadow = 0;
    ptsPerSquareSea = 5;
    ptsPerSquareTxt = 20;
    ptsPerSquareCLn = 10;
    ptsPerSquareExp = 10;
    ptsPerSquareCost = 10;
    ptsPerSquareFor = 9;
    ptsPerSquareForEdge = 9;
    ptsPerSquareRoad = 6;
    ptsPerSquareObj = 9;
    showCountourInterval = 0;
    scaleMin = 0.001;
    scaleMax = 1;
    scaleDefault = 0.16;
    // maxSatelliteAlpha = 0.85;
    // alphaFadeStartScale = 2;
    // alphaFadeEndScale = 2;
    maxSatelliteAlpha = 0;
    alphaFadeStartScale = 0;
    alphaFadeEndScale = 0;
    colorTrails[] = {0.84, 0.76, 0.65, 0.15};
    colorTrailsFill[] = {0.84, 0.76, 0.65, 0.65};
    fontLabel = "RobotoCondensed";
    sizeExLabel = "(            (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    fontGrid = "TahomaB";
    sizeExGrid = 0.02;
    fontUnits = "TahomaB";
    sizeExUnits = "(            (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    fontNames = "EtelkaNarrowMediumPro";
    sizeExNames = "(            (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8) * 2";
    fontInfo = "RobotoCondensed";
    sizeExInfo = "(         (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    fontLevel = "TahomaB";
    sizeExLevel = 0.02;
    text = "#(argb,8,8,3)color(1,1,1,1)";
    idcMarkerColor = -1;
    idcMarkerIcon = -1;
    textureComboBoxColor = "#(argb,8,8,3)color(1,1,1,1)";
    showMarkers = 1;
    widthRailWay = 1;
    class Legend
    {
        colorBackground[] = {1, 1, 1, 0.5};
        color[] = {0, 0, 0, 1};
        x = "SafeZoneX +                    (           ((safezoneW / safezoneH) min 1.2) / 40)";
        y = "SafeZoneY + safezoneH - 4.5 *                  (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
        w = "10 *                   (           ((safezoneW / safezoneH) min 1.2) / 40)";
        h = "3.5 *                  (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
        font = "RobotoCondensed";
        sizeEx = "(         (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    };
    class ActiveMarker
    {
        color[] = {0.3, 0.1, 0.9, 1};
        size = 50;
    };
    class Command
    {
        color[] = {1, 1, 1, 1};
        icon = "\a3\ui_f\data\map\mapcontrol\waypoint_ca.paa";
        size = 18;
        importance = 1;
        coefMin = 1;
        coefMax = 1;
    };
    class Task
    {
        taskNone = "#(argb,8,8,3)color(0,0,0,0)";
        taskCreated = "#(argb,8,8,3)color(0,0,0,1)";
        taskAssigned = "#(argb,8,8,3)color(1,1,1,1)";
        taskSucceeded = "#(argb,8,8,3)color(0,1,0,1)";
        taskFailed = "#(argb,8,8,3)color(1,0,0,1)";
        taskCanceled = "#(argb,8,8,3)color(1,0.5,0,1)";
        colorCreated[] = {1, 1, 1, 1};
        colorCanceled[] = {0.7, 0.7, 0.7, 1};
        colorDone[] = {0.7, 1, 0.3, 1};
        colorFailed[] = {1, 0.3, 0.2, 1};
        color[] = {"(profilenamespace getvariable ['IGUI_TEXT_RGB_R',0])", "(profilenamespace getvariable ['IGUI_TEXT_RGB_G',1])", "(profilenamespace getvariable ['IGUI_TEXT_RGB_B',1])", "(profilenamespace getvariable ['IGUI_TEXT_RGB_A',0.8])"};
        icon = "\A3\ui_f\data\map\mapcontrol\taskIcon_CA.paa";
        iconCreated = "\A3\ui_f\data\map\mapcontrol\taskIconCreated_CA.paa";
        iconCanceled = "\A3\ui_f\data\map\mapcontrol\taskIconCanceled_CA.paa";
        iconDone = "\A3\ui_f\data\map\mapcontrol\taskIconDone_CA.paa";
        iconFailed = "\A3\ui_f\data\map\mapcontrol\taskIconFailed_CA.paa";
        size = 27;
        importance = 1;
        coefMin = 1;
        coefMax = 1;
    };
    class CustomMark
    {
        color[] = {1, 1, 1, 1};
        icon = "\a3\ui_f\data\map\mapcontrol\custommark_ca.paa";
        size = 18;
        importance = 1;
        coefMin = 1;
        coefMax = 1;
    };
    class Tree
    {
        color[] = {0.45, 0.64, 0.33, 0.4};
        icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
        size = 12;
        importance = "0.9 * 16 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class SmallTree
    {
        color[] = {0.45, 0.64, 0.33, 0.4};
        icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
        size = 12;
        importance = "0.6 * 12 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Bush
    {
        color[] = {0.45, 0.64, 0.33, 0.4};
        icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
        size = "14/2";
        importance = "0.2 * 14 * 0.05 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Church
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\church_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Chapel
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\Chapel_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Cross
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\Cross_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Rock
    {
        color[] = {0.1, 0.1, 0.1, 0.8};
        icon = "\A3\ui_f\data\map\mapcontrol\rock_ca.paa";
        size = 12;
        importance = "0.5 * 12 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Bunker
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\bunker_ca.paa";
        size = 14;
        importance = "1.5 * 14 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Fortress
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\bunker_ca.paa";
        size = 16;
        importance = "2 * 16 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Fountain
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\fountain_ca.paa";
        size = 11;
        importance = "1 * 12 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class ViewTower
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\viewtower_ca.paa";
        size = 16;
        importance = "2.5 * 16 * 0.05";
        coefMin = 0.5;
        coefMax = 4;
    };
    class Lighthouse
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\lighthouse_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Quay
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\quay_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Fuelstation
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\fuelstation_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Hospital
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\hospital_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class BusStop
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\busstop_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class LineMarker
    {
        textureComboBoxColor = "#(argb,8,8,3)color(1,1,1,1)";
        lineWidthThin = 0.008;
        lineWidthThick = 0.014;
        lineDistanceMin = 3e-005;
        lineLengthMin = 5;
    };
    class Transmitter
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\transmitter_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Stack
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\stack_ca.paa";
        size = 20;
        importance = "2 * 16 * 0.05";
        coefMin = 0.9;
        coefMax = 4;
    };
    class Ruin
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\ruin_ca.paa";
        size = 16;
        importance = "1.2 * 16 * 0.05";
        coefMin = 1;
        coefMax = 4;
    };
    class Tourism
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\tourism_ca.paa";
        size = 16;
        importance = "1 * 16 * 0.05";
        coefMin = 0.7;
        coefMax = 4;
    };
    class Watertower
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\watertower_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Waypoint
    {
        color[] = {1, 1, 1, 1};
        importance = 1;
        coefMin = 1;
        coefMax = 1;
        icon = "\a3\ui_f\data\map\mapcontrol\waypoint_ca.paa";
        size = 18;
    };
    class WaypointCompleted
    {
        color[] = {1, 1, 1, 1};
        importance = 1;
        coefMin = 1;
        coefMax = 1;
        icon = "\a3\ui_f\data\map\mapcontrol\waypointcompleted_ca.paa";
        size = 18;
    };

    class power
    {
        icon = "\A3\ui_f\data\map\mapcontrol\power_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {1, 1, 1, 1};
    };
    class powersolar
    {
        icon = "\A3\ui_f\data\map\mapcontrol\powersolar_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {1, 1, 1, 1};
    };
    class powerwave
    {
        icon = "\A3\ui_f\data\map\mapcontrol\powerwave_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {1, 1, 1, 1};
    };
    class powerwind
    {
        icon = "\A3\ui_f\data\map\mapcontrol\powerwind_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {1, 1, 1, 1};
    };
    class Shipwreck
    {
        icon = "\A3\ui_f\data\map\mapcontrol\Shipwreck_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {0, 0, 0, 1};
    };
};

class pl_RscMap
// RscDisplayMainMap
{
    idd = 2000;
    class controls
    {
        class Map: pl_RscMapControl
        {
            shadow = 0;
            moveOnEdges = 0;
            idc = 2000;
            x = 0.60572 * safezoneW + safezoneX;
            y = 0.170948 * safezoneH + safezoneY;
            w = 0.383234 * safezoneW;
            h = 0.808527 * safezoneH;
        };
    };
    access = 0;
};

class CfgVehicles
{
    class Module_F;
    class MartaManager: Module_F
    {
        author="$STR_A3_Bohemia_Interactive";
        _generalMacro="MartaManager";
        scope=2;
        displayName="$STR_MARTA_NAME";
        icon="\A3\modules_f\data\icon_MARTA_ca.paa";
        class EventHandlers
        {
            init="if (isnil 'BIS_marta_mainscope') then {BIS_marta_mainscope = _this select 0; if (isServer) then {private [""_ok""];_ok = _this execVM ""Plmod\overwrites\marta_main.sqf""}};";
        };
    };
};
