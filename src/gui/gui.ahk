/*
 * Copyright (c) 2024 CarrieForle
 * This file is part of KPS Display.
 *
 * KPS Display is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * KPS Display is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with KPS Display. If not, see <https://www.gnu.org/licenses/>.
 */

#Include "main.ahk"
#Include "config.ahk"
#Include "about.ahk"
#Include "util.ahk"

show_config_in_explorer(filepath, *)
{
    drive := 0
    SplitPath filepath, , , , , &drive

    if !drive
    {
        filepath := A_WorkingDir "\" filepath
    }

    IL := DllCall("Shell32\ILCreateFromPath", "str", filepath)
    success := !DllCall("Shell32\SHOpenFolderAndSelectItems",
        "ptr", IL,
        "uint", 0,
        "ptr", 0,
        "int", 0
    )
    DllCall("Shell32\ILFree", "ptr", IL)

    return success
}

spawn_gui_from_context(guis, main_gui, config, init_gui, item_name, item_pos, context_menu)
{
    guis[item_name] := init_gui(main_gui, config)
    guis[item_name].Show()
    main_gui.Opt("+Disabled")
    SetTimer kps_update, 0

    context_menu.Insert(item_pos "&", item_name, spawn_gui_from_context.Bind(guis, main_gui, config, init_gui))
    context_menu.Delete((item_pos + 1) "&")
}

update_context_menu(guis, main_gui, config, context_menu)
{
    context_menu.Delete()

    context_menu.Add(config_gui_name(), spawn_gui_from_context.Bind(guis, main_gui, config, init_config_gui))
    context_menu.Add(about_gui_name(), spawn_gui_from_context.Bind(guis, main_gui, config, init_about_gui))

    filename := 0
    SplitPath config.filepath, &filename

    context_menu.Add("Load profile (" filename ")", show_config_in_explorer.Bind(config.filepath))
    context_menu.Add("Show profile location", show_config_in_explorer.Bind(config.filepath))
}

load_config_from_context_menu(main_gui, config, *)
{
    filepath := FileSelect(1, , "Open config", "Config (*.ini)")

    if !filepath
    {
        return
    }

    try
    {
        config := Configuration.read(filepath)
        apply_config_to_main_gui(main_gui, config)
        transmit_config_to_event_loop(config)
        IniWrite config.filepath, "setup.ini", "general", "current_profile"
    }
    catch Error as e
    {
        filename := 0
        SplitPath filepath, &filename
        MsgBox("Failed to read " filename "`nError: " e.Message, "Error", 16)
    }
}

init_guis(config, dimension)
{
    static called := false
    static guis := Map()

    if !called {
        context_menu := Menu()

        main_gui := init_main_gui(config, context_menu, dimension)
        guis["main"] := main_gui

        update_context_menu(guis, main_gui, config, context_menu)
        
        main_gui.Show()
        main_gui.Opt("-Disabled")
        main_gui["kps_text"].Enabled := false
        main_gui["kps_text"].Enabled := true

        OnMessage 0x0200, show_tooltip

        called := true
    }

    return guis
}