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

#Include "../config.ahk"
#Include "../font.ahk"
#Include "../color.ahk"
#Include "../monitored_keys.ahk"
#Include "util.ahk"
#Include "main.ahk"
#Include "config/custom_kps.ahk"
#Include "config/preview.ahk"

; TODO make a function to apply a GUI control (presumable a box of solid color) to preview color in config window

config_gui_name()
{
    return "Configure"
}

change_text_in_font_edit(my_font, font_edit, *)
{
    font_str := StrTitle(my_font.typeface) ", " my_font.height "pt"

    switch my_font.weight
    {
        case 100:
            font_str .= ", thin"
        case 200:
            font_str .= ", extra light"
        case 300:
            font_str .= ", light"
        case 400:
            _ .= 0
        case 500:
            font_str .= ", medium"
        case 600:
            font_str .= ", semi bold"
        case 700:
            font_str .= ", bold"
        case 800:
            font_str .= ", extra bold"
        case 900:
            font_str .= ", black"
        default:
            font_str .= ", w" my_font.weight
    }

    if my_font.italic
    {
        font_str .= ", italic"
    }
    if my_font.strikethrough
    {
        font_str .= ", strike"
    }
    if my_font.underline
    {
        font_str .= ", underline"
    }

    font_edit.Value := font_str
}

change_font_in_font_edit(my_font, font_edit, *)
{
    font_str := ""

    if my_font.italic
    {
        font_str .= "italic "
    }
    if my_font.strikethrough
    {
        font_str .= "strike "
    }
    if my_font.underline
    {
        font_str .= "underline "
    }

    font_edit.SetFont("norm " font_str "w" my_font.weight, my_font.typeface)
}

change_color(config_gui_hwnd, color_edit, *)
{
    try
    {
        color := RGB.from_string(color_edit.Value)
    }
    catch
    {
        color := RGB(0, 0, 0)
    }

    choose_color(
        config_gui_hwnd,
        &color,
        RGB.color_boxes()
    )

    color_edit.Value := "#" color.to_string()
    color_edit.Opt("Background" color.to_string())
    color_edit.SetFont("c" (color.lum() > 127 ? "000000" : "ffffff"))
}

show_current_config_error(statusbar, info)
{
    statusbar.Gui.Opt("OwnDialogs")
    count := statusbar.error_contexts.Count

    if info = 1 && count >= 1
    {
        if count = 1
        {
            err_title := "Found 1 error"
        }
        else
        {
            err_title := "Found 2 errors"
        }

        err_text := ""

        for , err_msg in statusbar.error_contexts
        {
            err_text .= "`n" err_msg
        }

        err_text := Trim(err_text, A_Space A_Tab "`n`r")

        MsgBox err_text, err_title
    }
}

; Until I found a way to stop closing window with X (OnEvent("Close") doesn't work)
; https://www.autohotkey.com/board/topic/80593-how-to-disable-grey-out-the-close-button/
disable_close_button(hWnd) {
    hSysMenu := DllCall("GetSystemMenu", "Int", hWnd, "Int", false)
    nCnt := DllCall("GetMenuItemCount", "Int", hSysMenu)
    DllCall("RemoveMenu", "Int", hSysMenu, "UInt", nCnt - 1, "Uint", "0x400")
    DllCall("RemoveMenu", "Int", hSysMenu, "UInt", nCnt - 2, "Uint", "0x400")
    DllCall("DrawMenuBar", "Int", hWnd)
}

show_format_help(format_picture, *)
{
    format_picture.Gui.Opt("OwnDialogs")

    try
    {
        Run "format_help.md", "doc"
    }
    catch Error as e
    {
        MsgBox "Failed to open format_help.md: " e.Message, "Error", 0x20
    }
}

load_config(&config, condition, gui_ctrl_obj, *)
{
    gui_ctrl_obj.Gui.Opt("OwnDialogs")

    if !condition() && "No" = MsgBox("Load a profile will lose your unsaved works. Do you want to continue?", "Discard unsaved changes?", 0x134)
    {
        return
    }

    config_filepath := FileSelect(1, , "Choose a profile", "Config (*.ini)")

    if !config_filepath
    {
        return false
    }

    filename := "config"
    SplitPath config_filepath, &filename

    try
    {
        if config_filepath
        {
            config := Configuration.read(config_filepath)
            apply_config_to_config_gui(config, gui_ctrl_obj.Gui)
        }
    }
    catch Error as e
    {
        MsgBox "Failed to load " filename "`nError: " e.Message, "Error", 16
        gui_ctrl_obj.Gui["statusbar"].SetText("Failed to load " filename, 2)

        return false
    }

    gui_ctrl_obj.Gui.has_made_change := true
    gui_ctrl_obj.Gui["statusbar"].SetText("Loaded " filename, 2)

    return true
}

get_config_from_gui(config_gui)
{
    new_config := Configuration()
    val := config_gui.Submit(false)
    config_gui.Opt("OwnDialogs")

    try
    {
        new_config.general.update_interval := Integer(val.update_interval_edit)
        new_config.general.monitored_keys := MonitoredKeys.from_gui(val.monitored_keys_edit, val.monitored_keys_invert_checkbox)

        new_config.KPS.bg_color := RGB.from_string(val.bg_color_edit)
        new_config.KPS.fg_color := RGB.from_string(val.fg_color_edit)

        new_config.KPS.style := config_gui.style
        new_config.KPS.style.underline := val.underline_checkbox
        new_config.KPS.style.strikethrough := val.strikethrough_checkbox
        new_config.KPS.align := val.alignment_dropdown
        new_config.KPS.padding := val.padding_edit
        new_config.KPS.read_prefix(val.prefix_edit)
        new_config.KPS.read_suffix(val.suffix_edit)

        new_config.KPS.format := CustomFormat.from_format(val.format_edit)
        new_config.read_custom_kps_from_listview(config_gui["custom_kps_listview"])

        new_config.general.margin := [
            Integer(val.margin_top_edit),
            Integer(val.margin_right_edit),
            Integer(val.margin_bottom_edit),
            Integer(val.margin_left_edit),
        ]

        return new_config
    }
    catch Error as e
    {
        unrecoverable_error(e)
    }
}

has_changed(config_gui, &config)
{
    return !get_config_from_gui(config_gui).equivalent(config)
}

apply_config_to_config_gui(config, config_gui)
{
    try
    {
        filename := 0
        SplitPath config.filepath, &filename
    
        config_gui.style := config.KPS.style
    
        config_gui["current_profile_text"].Value := "Current profile: " filename
        config_gui["monitored_keys_edit"].Value := config.general.monitored_keys.to_gui()
        config_gui["monitored_keys_invert_checkbox"].Value := config.general.monitored_keys.params[2] = "-N"
        config_gui["padding_edit"].Value := config.KPS.padding
        config_gui["bg_color_edit"].Value := "#" config.KPS.bg_color.to_string()
        config_gui["bg_color_edit"].Opt("Background" config.KPS.bg_color.to_string())
        config_gui["bg_color_edit"].SetFont("c" (config.KPS.bg_color.lum() > 127 ? "000000" : "ffffff"))
        config_gui["fg_color_edit"].Value := "#" config.KPS.fg_color.to_string()
        config_gui["fg_color_edit"].Opt("Background" config.KPS.fg_color.to_string())
        config_gui["fg_color_edit"].SetFont("c" (config.KPS.fg_color.lum() > 127 ? "000000" : "ffffff"))
    
        change_text_in_font_edit(config.KPS.style, config_gui["font_preview_edit"])
        change_font_in_font_edit(config.KPS.style, config_gui["font_preview_edit"])
        
        config_gui["underline_checkbox"].Value := config.KPS.style.underline
        config_gui["strikethrough_checkbox"].Value := config.KPS.style.strikethrough
        config_gui["alignment_dropdown"].Text := config.KPS.align
        config_gui["format_edit"].Value := config.KPS.format.orig_format
        config_gui["prefix_edit"].Value := config.KPS.prefix_to_string()
        config_gui["suffix_edit"].Value := config.KPS.suffix_to_string()
        
        config_gui["custom_kps_listview"].Delete()
        
        for kps, kps_text in config.custom_KPS
        {
            config_gui["custom_kps_listview"].Add(, kps, kps_text)
        }
            
        config_gui["update_interval_edit"].Value := config.general.update_interval

        for name in ["top", "right", "bottom", "left"]
        {
            config_gui["margin_" name "_edit"].Value := config.general.margin[A_Index]
        }
    }
    catch Error as e
    {
        unrecoverable_error(e)
    }
}

quit_config(main_gui, condition, &config, gui_ctrl_obj, *)
{
    gui_ctrl_obj.Gui.Opt("+OwnDialogs")

    if !condition() && "No" = MsgBox("You have unsaved changes. Do you want to lose your works?", "Discard current works?", 0x134)
    {
        return
    }

    if gui_ctrl_obj.Gui.has_made_change
    {
        enable_main_and_destroy_self(main_gui, gui_ctrl_obj.Gui, config)
    }
    else
    {
        enable_main_and_destroy_self(main_gui, gui_ctrl_obj.Gui)
    }
}

ok_and_saved(config_gui, &config)
{
    return config_gui["statusbar"].error_contexts.Count = 0 && !has_changed(config_gui, &config)
}

is_ok_to_save(statusbar)
{
    statusbar.Gui.Opt("OwnDialogs")

    if statusbar.error_contexts.Count > 0
    {
        MsgBox "Couldn't save config because there remains errors.", , 16
        return false
    }

    return true
}

save_as_config(&config, gui_ctrl_obj, *)
{
    if !is_ok_to_save(gui_ctrl_obj.Gui["statusbar"])
    {
        return
    }

    gui_ctrl_obj.Gui.Opt("OwnDialogs")
    forbidded_filepath := A_WorkingDir "\setup.ini"

    if config.filepath != "default.ini" && config.filepath != A_WorkingDir "\default.ini"
    {
        selected_filepath := FileSelect("S16", config.filepath, "Save config", "Config (*.ini)")
    }
    else
    {
        if FileExist("profile.ini")
        {
            index := "wtf_bro"

            loop 100
            {
                if !FileExist("profile_" A_index ".ini")
                {
                    index := A_Index
                    break
                }
            }

            selected_filepath := FileSelect("S16", "profile_" index ".ini", "Save config", "Config (*.ini)")
        }
        else
        {
            selected_filepath := FileSelect("S16", "profile.ini", "Save config", "Config (*.ini)")
        }
    }

    if !selected_filepath
    {
        return false
    }

    config := get_config_from_gui(gui_ctrl_obj.Gui)
    config.filepath := selected_filepath
    config.export()

    length := 50
    announcement := "Saved to " selected_filepath

    if StrLen(announcement) > length
    {
        announcement := 
        announcement := "Saved to ..." SubStr(selected_filepath, StrLen(selected_filepath) - length + 13)
    }

    gui_ctrl_obj.Gui["statusbar"].SetText(announcement, 2)
    gui_ctrl_obj.Gui.has_made_change := true

    return true
}

save_config(&config, gui_ctrl_obj, *)
{
    if !is_ok_to_save(gui_ctrl_obj.Gui["statusbar"])
    {
        return false
    }

    if config.filepath = "default.ini" || config.filepath = A_WorkingDir "\default.ini"
    {
        return save_as_config(&config, gui_ctrl_obj)
    }

    filepath := config.filepath
    config := get_config_from_gui(gui_ctrl_obj.Gui)
    config.filepath := filepath
    config.export()

    filename := "config"
    SplitPath config.filepath, &filename
    gui_ctrl_obj.Gui["statusbar"].SetText("Saved " filename, 2)
    gui_ctrl_obj.Gui.has_made_change := true

    return true
}

save_config_and_quit(main_gui, &config, gui_ctrl_obj, *)
{
    if !is_ok_to_save(gui_ctrl_obj.Gui["statusbar"])
    {
        return false
    }

    if config.filepath = "default.ini" || config.filepath = A_WorkingDir "\default.ini"
    {
        if save_as_config(&config, gui_ctrl_obj)
        {
            enable_main_and_destroy_self(main_gui, gui_ctrl_obj.Gui, config)
            
            return true
        }
        return false
    }

    filepath := config.filepath
    config := get_config_from_gui(gui_ctrl_obj.Gui)
    config.filepath := filepath
    config.export()
    gui_ctrl_obj.Gui.has_made_change := true

    enable_main_and_destroy_self(main_gui, gui_ctrl_obj.Gui, config)

    return true
}

verify(condition, format_text, gui_ctrl_obj, *)
{
    e := 0

    if !(success := try_do(condition.Bind(gui_ctrl_obj.Value), &e))
    {
        gui_ctrl_obj.Gui["statusbar"].error_contexts[gui_ctrl_obj.Name] := Format(format_text, e.Message)
    }
    else if gui_ctrl_obj.Gui["statusbar"].error_contexts.Has(gui_ctrl_obj.Name)
    {   
        gui_ctrl_obj.Gui["statusbar"].error_contexts.Delete(gui_ctrl_obj.Name)
    }

    if gui_ctrl_obj.HasProp("error_picture")
    {
        gui_ctrl_obj.error_picture.Visible := !success
    }

    announcement := ""

    if (count := gui_ctrl_obj.Gui["statusbar"].error_contexts.Count) = 1
    {
        announcement := "Found 1 error. Click for more details"
    }
    else if count > 1
    {
        announcement := "Found " count " errors. Click for more details"
    }

    gui_ctrl_obj.Gui["statusbar"].SetText(announcement)

    return success
}

is_not_empty_str(x)
{
    if StrLen(x) = 0
    {
        throw ValueError("Value must not be empty")
    }

    return x
}

is_number(i)
{
    if IsInteger(i)
    {
        return Integer(i)
    }
    else
    {
        throw ValueError(i " is not a number")
    }
}

is_positive(n)
{
    if !IsInteger(n)
    {
        throw ValueError(n " is not a number")
    }

    if Integer(n) < 1
    {
        throw ValueError(n " is not positive")
    }
}

init_config_gui(main_gui, config)
{    
    config_gui := Gui("+Owner" main_gui.Hwnd " -MinimizeBox -MaximizeBox")
    config_gui.style := config.KPS.style
    config_gui.has_made_change := false
    
    config_gui.Title := config_gui_name()
    config_gui.SetFont(, default_font())
    
    disable_close_button(config_gui.Hwnd)

    config_gui.OnEvent("Close", enable_main_and_destroy_self.Bind(main_gui))
    
    statusbar := config_gui.AddStatusBar("vstatusbar")
    statusbar.SetParts(80)
    statusbar.error_contexts := Map()
    statusbar.OnEvent("Click", show_current_config_error)

    config_tab := config_gui.AddTab3("vconfig_tab Choose1", ["General", "Style", "Custom KPS", "Advanced"])
    
    config_tab.UseTab(1)
    load_config_from_file_button := config_gui.AddButton("vload_config_from_file_button Section", "Choose a profile")
    current_profile_text := config_gui.AddText("vcurrent_profile_text X+M", "Current profile: Unspecified")
    
    load_config_from_file_button.OnEvent("Click", load_config.Bind(
        &config, 
        ok_and_saved.Bind(config_gui, &config)
    ))

    padding_text := config_gui.AddText("XS", "Padding")
    padding_edit := config_gui.AddEdit("vpadding_edit X+M w150")
    
    monitored_keys_text := config_gui.AddText("XS", "Monitored keys")
    monitored_keys_invert_checkbox := config_gui.AddCheckBox("vmonitored_keys_invert_checkbox X+M", "Invert")
    monitored_keys_help_picture := config_gui.AddPicture("vmonitored_keys_help_picture X+5 w16 h-1 Icon-24", "Shell32")
    monitored_keys_edit := config_gui.AddEdit("vmonitored_keys_edit XS r8 w270")

    config_tab.UseTab(2)
    bg_color_text := config_gui.AddText("Section", "Background color")
    bg_color_edit := config_gui.AddEdit("vbg_color_edit X+M r1 w100 Limit7 Uppercase -WantReturn", "#000000")
    bg_color_edit.error_picture := config_gui.AddPicture("X+5 w16 h-1 Hidden Icon-161", "Shell32")
    bg_color_button := config_gui.AddButton("vbg_color_button X+M", "Pick")

    change_color_on_ok(format_text, color_edit, *)
    {
        if verify((val) => RGB.from_string(val), format_text, color_edit)
        {
            color := RGB.from_string(color_edit.Value)
            color_edit.Opt("Background" color.to_string())
            color_edit.SetFont("c" (color.lum() > 127 ? "000000" : "ffffff"))
        }
        else
        {
            color_edit.Opt("Backgrounddefault")
            color_edit.SetFont("cdefault")
        }
    }

    bg_color_edit.OnEvent("Change", change_color_on_ok.Bind("[Style: Background color]`n{}"))
    bg_color_button.OnEvent("Click", change_color.Bind(config_gui.Hwnd, bg_color_edit))
    
    fg_color_text := config_gui.AddText("XS", "Font color")
    fg_color_edit := config_gui.AddEdit("vfg_color_edit X+M r1 w100 Limit7 Uppercase -WantReturn", "#000000")
    fg_color_edit.error_picture := config_gui.AddPicture("X+5 w16 h-1 Hidden Icon-161", "Shell32")
    fg_color_button := config_gui.AddButton("vfg_color_button X+M", "Pick")
    
    fg_color_edit.OnEvent("Change", change_color_on_ok.Bind("[Style: Font color]`n{}"))
    fg_color_button.OnEvent("Click", change_color.Bind(config_gui.Hwnd, fg_color_edit))
    
    choose_font_button := config_gui.AddButton("vchoose_font_butotn XS ChooseLeft", "Choose font")
    font_preview_edit := config_gui.AddEdit("vfont_preview_edit X+m r1 w170")

    change_font(*) {
        style := config_gui.style
        config_gui.style := choose_font(config_gui.Hwnd, &style)
        change_font_in_font_edit(style, font_preview_edit)
    }

    choose_font_button.OnEvent("Click", change_font)
    
    change_font_underline(gui_ctrl_obj, *)
    {
        config_gui.style.underline := gui_ctrl_obj.Value
        change_font_in_font_edit(config_gui.style, font_preview_edit)
    }
    
    change_font_strikethrough(gui_ctrl_obj, *)
    {
        config_gui.style.strikethrough := gui_ctrl_obj.Value
        change_font_in_font_edit(config_gui.style, font_preview_edit)
    }
    
    underline_checkbox := config_gui.AddCheckBox("vunderline_checkbox XS", "Underline")
    underline_checkbox.OnEvent("Click", change_font_underline)
    
    strikethrough_checkbox := config_gui.AddCheckBox("vstrikethrough_checkbox X+m", "Strikethrough")
    strikethrough_checkbox.OnEvent("Click", change_font_strikethrough)

    alignment_text := config_gui.AddText("XS", "Alignment")
    alignment_dropdown := config_gui.AddDropDownList("valignment_dropdown w60 Choose3 X+M", [ "Left", "Center", "Right" ])
    format_text := config_gui.AddText("XS", "Format")
    format_edit := config_gui.AddEdit("vformat_edit X+M r1 w200", config.KPS.format.orig_format)
    format_help_picture := config_gui.AddPicture("vformat_help_picture X+5 w16 h-1 Icon-24", "Shell32")
    format_help_picture.OnEvent("Click", show_format_help)
    prefix_text := config_gui.AddText("XS", "Prefix")
    prefix_edit := config_gui.AddEdit("vprefix_edit X+M r1 w100", config.KPS.prefix)
    
    suffix_text := config_gui.AddText("X+M", "Suffix")
    suffix_edit := config_gui.AddEdit("vsuffix_edit X+M r1 w100", config.KPS.suffix)
    
    preview_button := config_gui.AddButton("vpreview XS", "Preview")
    preview_button.OnEvent("Click", (button, *) => init_and_show_config_preview_gui(button.Gui))
    
    config_tab.UseTab(3)
    custom_kps_edit := config_gui.AddEdit("vcustom_kps_edit Section r1 w70 Limit7 Number")
    custom_kps_updown := config_gui.AddUpDown("vcustom_kps_updown 0x80 range0-9999999")
    config_gui.AddText("X+M", "=")
    custom_kps_text_edit := config_gui.AddEdit("vcustom_kps_text_edit X+M r1 w160 -WantReturn WantTab")
    custom_kps_text_help_picture := config_gui.AddPicture("vcustom_kps_text_help_picture X+5 w16 h-1 Icon-24", "Shell32")
    
    add_custom_kps_button := config_gui.AddButton("vadd_custom_kps_button XS", "Add")
    overwrite_kps_checkbox := config_gui.AddCheckbox("voverwrite_kps_checkbox X+M", "Overwrite")
    custom_kps_listview := config_gui.AddListView("vcustom_kps_listview XS r6 Grid ", ["KPS", "Text"])
    
    add_custom_kps_button.OnEvent(
        "Click",
        add_custom_kps.Bind(
            custom_kps_listview,
            custom_kps_edit,
            custom_kps_text_edit,
            overwrite_kps_checkbox
        )
    )
    
    custom_kps_listview.OnEvent(
        "ItemSelect",
        selected_custom_kps.Bind(
            add_custom_kps_button,
            custom_kps_edit,
            overwrite_kps_checkbox,
        )
    )

    delete_custom_kps_button := config_gui.AddButton("vdelete_custom_kps_button", "Delete")
    delete_custom_kps_button.OnEvent("Click", delete_custom_kps.Bind(custom_kps_listview))

    config_tab.UseTab(4)
    update_interval_text := config_gui.AddText("Section", "Update interval")
    update_interval_edit := config_gui.AddEdit("vupdate_interval_edit X+M r1 w63 Limit5 Number")
    update_interval_updown := config_gui.AddUpDown("vupdate_interval_updown +0x80 range1-99999")
    update_interval_edit.error_picture := config_gui.AddPicture("X+5 w16 h-1 Hidden Icon-161", "Shell32")

    update_interval_edit.OnEvent("Change", verify.Bind(is_positive, "[Advanced: Update interval]`n{}"))

    margin_groupbox := config_gui.AddGroupBox("XS w287 h100", "Margin")

    margin_top_text := config_gui.AddText("Section XS+10 YS+55", "Top")
    margin_top_edit := config_gui.AddEdit("vmargin_top_edit X+m r1 w80 -WantReturn Limit6")
    margin_top_updown := config_gui.AddUpDown("vmargin_top_updown +0x80 Range-99999-999999")
    margin_top_edit.error_picture := config_gui.AddPicture("X+5 w16 h-1 Hidden Icon-161", "Shell32")
    margin_top_edit.OnEvent("Change", verify.Bind(is_number, "[Advanced: Top margin]`n{}"))
    
    margin_right_text := config_gui.AddText("X+M", "Right")
    margin_right_edit := config_gui.AddEdit("vmargin_right_edit X+m r1 w60 -WantReturn Limit6")
    margin_right_updown := config_gui.AddUpDown("vmargin_right_updown +0x80 Range-99999-999999")
    margin_right_edit.error_picture := config_gui.AddPicture("X+5 w16 h-1 Hidden Icon-161", "Shell32")
    margin_right_edit.OnEvent("Change", verify.Bind(is_number, "[Advanced: Right margin]`n{}"))
    
    margin_bottom_text := config_gui.AddText("XS Y+20", "Bottom")
    margin_bottom_edit := config_gui.AddEdit("vmargin_bottom_edit X+M r1 w60 -WantReturn Limit6")
    margin_bottom_updown := config_gui.AddUpDown("vmargin_bottom_updown +0x80 Range-99999-999999")
    margin_bottom_edit.error_picture := config_gui.AddPicture("X+5 w16 h-1 Hidden Icon-161", "Shell32")
    margin_bottom_edit.OnEvent("Change", verify.Bind(is_number, "[Advanced: Bottom margin]`n{}"))
    
    margin_left_text := config_gui.AddText("X+M", "Left")
    margin_left_edit := config_gui.AddEdit("vmargin_left_edit X+m r1 w68 -WantReturn Limit6")
    margin_left_updown := config_gui.AddUpDown("vmargin_left_updown +0x80 Range-99999-999999")
    margin_left_edit.error_picture := config_gui.AddPicture("X+5 w16 h-1 Hidden Icon-161", "Shell32")
    margin_left_edit.OnEvent("Change", verify.Bind(is_number, "[Advanced: Left margin]`n{}"))
        
    config_tab.UseTab(0)
    save_and_quit_button := config_gui.AddButton("vsave_and_quit_button", "Save && Quit")
    save_button := config_gui.AddButton("vsave_button X+M", "Save")
    save_as_button := config_gui.AddButton("vsave_as_button X+M", "Save as")
    quit_button := config_gui.AddButton("vquit_button X+M", "Quit")
    dbg_button := config_gui.AddButton("X+M", "dbg_export")

    save_and_quit_button.OnEvent("Click", save_config_and_quit.Bind(main_gui, &config))
    save_button.OnEvent("Click", save_config.Bind(&config))
    save_as_button.OnEvent("Click", save_as_config.Bind(&config))
    
    quit_button.OnEvent("Click", quit_config.Bind(
        main_gui, 
        ok_and_saved.Bind(config_gui, &config),
        &config
    ))

    dbg_button.OnEvent("Click", (*) => config.export("_dbg.ini"))
    
    apply_config_to_config_gui(config, config_gui)

    return config_gui
}