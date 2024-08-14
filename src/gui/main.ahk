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

#Include "util.ahk"
#Include "gui.ahk"
#Include "../main.ahk"

apply_config_to_main_gui(main_gui, config)
{
    config.KPS.style.set(main_gui["kps_text"], config.KPS.fg_color.to_string())
    main_gui["kps_text"].Text := config.KPS.format.to_string(0, config.custom_kps, config.KPS.padding)
    main_gui.BackColor := config.KPS.bg_color.to_string()
    main_gui["kps_text"].Opt(config.KPS.align)
    
    margin := config.general.margin

    main_gui["kps_text"].Move(margin[4], margin[1], main_gui.size[1] - margin[2] - margin[4], main_gui.size[2] - margin[1] - margin[3])
    update_context_menu(init_guis(0, 0), main_gui, config, main_gui.context_menu)
}

show_option(option_menu, guiObj, guiCtrlObj, item, isRightClick, x, y)
{
    if isRightClick {
        option_menu.Show()
    }
}

_real_resize(&config, gui_obj, minmax, width, height)
{
    margin := config.general.margin
    kps_text := gui_obj["kps_text"]
    kps_text.Move(margin[4], margin[1], width - margin[2] - margin[4], height - margin[1] - margin[3])
    gui_obj.size := [width, height]

    kps_text.Redraw()
}

enable_main_and_destroy_self(main_gui, orig_gui, config?)
{
    orig_gui.Destroy()
    
    main_gui.Show()
    main_gui.Opt("-Disabled")
    main_gui["kps_text"].Enabled := false
    main_gui["kps_text"].Enabled := true

    if IsSet(config)
    {
        apply_config_to_main_gui(main_gui, config)
        transmit_config_to_event_loop(config)
        IniWrite config.filepath, "setup.ini", "general", "current_profile"
    }
}

close_main_gui(gui_obj)
{
    IniWrite join_array(gui_obj.size), "setup.ini", "general", "dimension"
    ExitApp
}

init_main_gui(config, context_menu, dimension)
{
    main_gui := Gui("Resize", "KPS Display")

    main_gui.size := dimension
    main_gui.context_menu := context_menu
    main_gui.Title := "KPS Display"
    main_gui.BackColor := config.KPS.bg_color.to_string()

    main_gui.OnEvent("Close", close_main_gui)
    main_gui.OnEvent("ContextMenu", show_option.Bind(context_menu))

    kps_text := main_gui.AddText("vkps_text " config.KPS.align " w" dimension[1] " h" dimension[2], config.KPS.format.to_string(0, config.custom_kps, config.KPS.padding))
    config.KPS.style.set(kps_text, config.KPS.fg_color.to_string())
    
    margin := config.general.margin

    kps_text.Move(margin[4], margin[1], main_gui.size[1] - margin[2] - margin[4], main_gui.size[2] - margin[1] - margin[3])
    
    return main_gui
}

update_kps_text(kps_text, kps_other_text)
{
    if kps_text.Value != kps_other_text
    {
        kps_text.Value := kps_other_text
    }
}