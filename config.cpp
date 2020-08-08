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
            show="(1 - HCIsLeader)";
            enable="0";
        };
        class Attack
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/><t> Suppress</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="[] call pl_spawn_suppression";
            };
            show="HCIsLeader * IsWatchCommanded * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\attack_ca.paa";
            priority=2;
        };
        class EmptyBlank2: Empty1
        {
            title="command 3";
            show="(1 - HCIsLeader) + (HCIsLeader * (1 - CursorOnGround)) + (HCCursorOnIconSelectable)";
            enable="0";
        };
        class Move
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Set Waypoint</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="{[_x, false] call pl_reset;} forEach (hcSelected player); playSound 'beep'; ['MOVE',_pos,_is3D,hcselected player,false] call BIS_HC_path_menu";
            };
            show="HCIsLeader * CursorOnGround * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=1;
        };
        class MoveAdd
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Add Waypoint</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="{if ((count (waypoints _x)) == 0) then {[_x, false] call pl_reset;}} forEach (hcSelected player); playSound 'beep'; ['MOVE',_pos,_is3D,hcselected player,true] call BIS_HC_path_menu";
            };
            show="HCIsLeader * CursorOnGround * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * IsSelectedToAdd";
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
            show="HCIsLeader * CursorOnGround * IsWatchCommanded * (1 - IsSelectedToAdd)";
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
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\walk_ca.paa'/><t> Advance</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="[] call pl_spawn_advance";
            };
            show="HCIsLeader * CursorOnGround * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=2;
        };
        class Separator
        {
            title="";
            shortcuts[]={0};
            command=-1;
        };
        class Empty5
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa'/><t> March</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="{[_x] spawn pl_march}forEach (hcSelected player)";
            };
            show="HCIsLeader * CursorOnGround * (1 - HCCursorOnIconSelectable) * IsSelectedToAdd * IsWatchCommanded";
            enable="1";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=4;
        };
        class Empty6
        {
            title="Creep";
            shortcuts[]={};
            command=-5;
            class Params
            {
                expression="{[_x] spawn pl_creep} forEach hcSelected player";
            };
            show="0";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
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
            show="HCIsLeader * HCCursorOnIconSelectable * (1 - IsSelectedToAdd)";
            enable="1";
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
            show="HCIsLeader * HCCursorOnIconSelectable * (HCCursorOnIconSelectableSelected) * IsSelectedToAdd";
            enable="1";
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
            class Back
            {
                shortcuts[] = {"BACK"};
                title = "";
                command = -4;
                speechId = 0;
            };
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
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Cancel Last Waypoint</t>";
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
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Cancel All Waypoint</t>";
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
                title="<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Cancel Task / Stop</t>";
                shortcuts[]={5};
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
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa'/><t> Hold</t>";
                shortcuts[]={6};
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
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa'/><t> Execute</t>";
                shortcuts[]={7};
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
            class PlFollowOther
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa'/><t> Form on other Group</t>";
                shortcuts[]={9};
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_follow_other} forEach (hcSelected player);";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            // class PlResupply
            // {
            //     title="Resupply at Position";
            //     shortcuts[]={8};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_spawn_rearm";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            // class PlHeal
            // {
            //     title="Heal Group";
            //     shortcuts[]={9};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_spawn_heal_group";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            // class PlCcp
            // {
            //     title="Set up CCP";
            //     shortcuts[]={10};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_ccp";
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
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa'/><t> Assault Position</t>";
                shortcuts[]={2};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_attack";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            class HoldFire
            {
                title="<img color='#e5e500' image='\Plmod\gfx\SFP.paa'/><t> Defend Position</t>";
                shortcuts[]={3};
                submenu="";
                command=-5;
                class params
                {
                    expression="[hcSelected player select 0, false] spawn pl_defend_position;";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlBoundingSquad
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\help_ca.paa'/><t> Bounding Overwatch</t>";
                shortcuts[]={4};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_bounding_squad";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator11
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
            class PlTakeCover
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa'/><t> Take Cover</t>";
                shortcuts[]={5};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_take_cover";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            class Pl360
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\map\markers\military\circle_CA.paa'/><t> Form 360</t>";
                shortcuts[]={6};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_360";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator5
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
            class PlClearBuilding
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa'/><t> Clear Area/Buildings</t>";
                shortcuts[]={7};
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_sweep_area} forEach (hcSelected player)";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlGarrisonArea
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa'/><t> Defend Buildings</t>";
                shortcuts[]={8};
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_garrison_area_building} forEach (hcSelected player)";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlGarBuilding
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa'/><t> Garrison Building</t>";
                shortcuts[]={9};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_garrison_building";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
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
            class PlCancelTask2
            {
                title="<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Cancel Task</t>";
                shortcuts[]={10};
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
                    expression = "{{_x disableAI 'AUTOCOMBAT';}forEach (units _x);}forEach (hcSelected player); 'COMBAT_STEALTH' call BIS_HC_path_menu";
                };
                title = "<img color='#191999' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa'/><t> Stealth</t>";
                shortcutsAction = "CommandingMenu1";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Combat
            {
                shortcuts[] = {3};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT';}forEach (units _x);}forEach (hcSelected player); 'COMBAT_DANGER' call BIS_HC_path_menu";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\danger_ca.paa'/><t> Combat</t";
                shortcutsAction = "CommandingMenu2";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Aware
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT';}forEach (units _x);}forEach (hcSelected player); 'COMBAT_AWARE' call BIS_HC_path_menu";
                };
                title = "<img color='#66ff33' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\listen_ca.paa'/><t> Aware</t";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Safe
            {
                shortcuts[] = {5};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT';}forEach (units _x);}forEach (hcSelected player); 'COMBAT_SAFE' call BIS_HC_path_menu";
                };
                title = "<img color='#ffffff' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa'/><t> Safe</t";
                shortcutsAction = "CommandingMenu4";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
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
            class OpenFire
            {
                shortcuts[] = {6};
                class Params
                {
                    expression = "{[_x] call pl_open_fire} forEach (hcSelected player)";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/><t> Open Fire</t";
                shortcutsAction = "CommandingMenu5";
                command = -5;
                show = "";
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
                shortcutsAction = "CommandingMenu6";
                command = -5;
                show = "";
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
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move1_ca.paa'/><t> Limited</t";
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
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move2_ca.paa'/><t> Normal</t";
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
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move3_ca.paa'/><t> Full</t";
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
                title = "<img color='#66ff33' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> 15 km/h</t";
                shortcutsAction = "CommandingMenu4";
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
                shortcutsAction = "CommandingMenu5";
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
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> 50 km/h</t";
                shortcutsAction = "CommandingMenu6";
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
                shortcutsAction = "CommandingMenu7";
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
                title = "Column";
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
                title = "Staggered Col.";
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
                title = "Wedge";
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
                title = "Echelon L.";
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
                title = "Echelon R.";
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
                title = "Vee";
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
                title = "Line";
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
                title = "File";
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
                title = "Diamond";
                shortcutsAction = "CommandingMenu9";
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
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa'/><t> Load / Extraction</t";
                shortcuts[]={2};
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
            class PlGetOutVic
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa'/><t> Unload / Insertion</t";
                shortcuts[]={3};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_spawn_getOut_vehicle";
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
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa'/><t> Move as Convoy</t";
                shortcuts[]={6};
                submenu="";
                command=-5;
                class params
                {
                    expression="[true] call pl_spawn_getOut_vehicle";
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
            class PlReverseVic
            {
                title="Reverse Vehicle Direction";
                shortcuts[]={11};
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
            class PlMergeGroups
            {
                title="Merge Groups";
                shortcuts[]={6};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_merge_hc_groups";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSplitGroups
            {
                title="Split Group";
                shortcuts[]={7};
                submenu="";
                command=-5;
                class params
                {
                    expression="[hcSelected player select 0] spawn pl_split_hc_group";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator13
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
            class PlAddGroup
            {
                title="Add Group";
                shortcuts[]={8};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_add_to_hc";
                };
                show="HCIsLeader";
                enable="1";
                speechId=0;
            };
            class PlRemoveGroup
            {
                title="Remove Group";
                shortcuts[]={9};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_spawn_remove_hc";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator18
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
            class PlResetGroup
            {
                title="Reset Group";
                shortcuts[]={10};
                submenu="";
                command=-5;
                class params
                {
                    expression="[(hcSelected player) select 0] spawn pl_reset_group";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
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
                title = "Type";
                shortcutsAction = "CommandingMenu1";
                menu = "RscHCWPType";
                show = "0";
                enable = "0";
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
                shortcuts[] = {9};
                class Params
                {
                    expression = "'WP_CREATETASK' call BIS_HC_path_menu";
                };
                title = "Create Task";
                shortcutsAction = "CommandingMenu8";
                command = -5;
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class Separator2
            {
                shortcuts[] = {0};
                title = "";
                command = -1;
            };
            class CancelWP
            {
                shortcuts[] = {1};
                class Params
                {
                    expression = "'WP_CANCELWP' call BIS_HC_path_menu";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Cancel Waypoint</t>";
                shortcutsAction = "CommandingMenu1";
                command = -5;
                show = "";
                enable = "";
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
};
class CfgMarkers
{
    class marker_nato
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
    class marker_CCP: marker_nato
    {
        name="CCP";
        icon="\Plmod\gfx\CCP.paa";
        texture="\Plmod\gfx\CCP.paa";
    };
    class marker_afp: marker_nato
    {
        name="Attack by Fire Position";
        icon="\Plmod\gfx\AFP.paa";
        texture="\Plmod\gfx\AFP.paa";
    };
    class marker_sfp: marker_nato
    {
        name="Support by Fire Position";
        icon="\Plmod\gfx\SFP.paa";
        texture="\Plmod\gfx\SFP.paa";
    };
};

// class CfgFactionClasses
// {
//     class NO_CATEGORY;
//     class pl_faction: NO_CATEGORY
//     {
//         displayName = "Platoon Leader";
//     };
// };

// class CfgVehicles
// {
//     class Logic;
//     class Module_F: Logic
//     {
//         class ArgumentsBaseUnits
//         {
//             class Units;
//         };
//         class ModuleDescription;
//     };
//     class Pl_Support_module: Module_F
//     {
//         author = "Jellyfish";
//         scope = 2;
//         displayName = "Support Options";
//         category = "pl_faction";
//         function = "Plmod_fnc_supportModule";
//         functionPriority = 1;
//         isGlobal = 1;
//         isTriggerActivated = 0;
//         isDisposable = 0;
//         class Arguments
//         {
//             class pl_arty_rounds
//             {
//                 displayName = "Artillery Ammo";
//                 description = "155mm Artillery Ammo";
//                 typeName = "NUMBER";
//                 defaultValue = "30";
//             };
//             class pl_sorties
//             {
//                 displayName = "Sortie Ammount";
//                 description = "Amount of avaiable CAS Sorties";
//                 typeName = "NUMBER";
//                 defaultValue = "20";
//             };
//         }
//     }
// }


