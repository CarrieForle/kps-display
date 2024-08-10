#Include "../config.ahk"
#Include "../choosefont.ahk"
#Include "../choosecolor.ahk"
#Include "util.ahk"
#Include "main.ahk"
#Include "config/custom_kps.ahk"

change_text_in_font_edit(my_font, font_edit, *)
{
    font_str := StrLower(my_font.typeface) ", " my_font.height "pt"

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

monitor_config(config, config_gui)
{
    ; values := config_gui.Submit()
    ; errors := []

    ; on_err(f, g)
    ; {
    ;     err := 0
    ;     if !try_do(f, &err)
    ;     {
    ;         return g(err.What)
    ;     }
    ; }

    ; on_err(RGB.from_string(values.bg_color_edit), errors.Push)
    ; on_err(RGB.from_string(values.fg_color_edit), errors.Push)
    ; on_err(Integer(values.update_interval), errors.Push)
}

; until I found a way to stop closing window with X
disable_close_button(hWnd) {
    hSysMenu := DllCall("GetSystemMenu", "Int", hWnd, "Int", false)
    nCnt := DllCall("GetMenuItemCount", "Int", hSysMenu)
    DllCall("RemoveMenu", "Int", hSysMenu, "UInt", nCnt - 1, "Uint", "0x400")
    DllCall("RemoveMenu", "Int", hSysMenu, "UInt", nCnt - 2, "Uint", "0x400")
    DllCall("DrawMenuBar", "Int", hWnd)
}

_real_show_format_help(*)
{
    Run "format_help.txt", "doc"
}

_real_load_config(&result, condition, config_gui, guiCtrlObj, info)
{
    if !condition() && "No" = MsgBox("Load a profile will lose your unsaved works. Do you want to continue?", "Discard unsaved changes?", 0x134)
    {
        return
    }

    config_filepath := FileSelect(1, , "Choose a profile", "Configs (*.ini)")
    filename := "config"
    SplitPath config_filepath, &filename

    try
    {
        if config_filepath
        {
            config := Configuration.read(config_filepath)
            apply_config(config, config_gui)
            config_gui["statusbar"].SetText("Loaded " filename)
        }
    }
    catch Error as e
    {
        MsgBox e.Message, "Error reading " filename, 16
        config_gui["statusbar"].SetText("Failed to load " filename)
    }
}

_real_show_config(main_gui, config_gui, itemName, itemPos, myMenu)
{
    main_gui.Opt("+Disabled")
    config_gui.Show()
}

_real_close_config(main_gui, config_gui, condition, gui_obj, info)
{
    if condition() || "Yes" = MsgBox("You have unsaved changes. Proceed and lose your works?", "Discard unsaved changes?", 0x134)
    {
        config_gui.Hide()
        _real_enable_main(main_gui)
    }

    ; remove this in prod
}

apply_config(config, config_gui)
{
    filename := 0
    SplitPath config.filepath, &filename

    config_gui["current_profile_text"].Value := filename
    
    ; TODO load monitored keys from config
    
    config_gui["bg_color_edit"].Value := "#" config.KPS.bg_color.to_string()
    config_gui["fg_color_edit"].Value := "#" config.KPS.fg_color.to_string()

    change_text_in_font_edit(config.KPS.style, config_gui["font_preview_edit"])
    change_font_in_font_edit(config.KPS.style, config_gui["font_preview_edit"])
    
    config_gui["underline_checkbox"].Value := config.KPS.style.underline
    config_gui["strikethrough_checkbox"].Value := config.KPS.style.strikethrough
    
    config_gui["alignment_dropdown"].Text := config.KPS.align
    config_gui["format_edit"].Value := config.KPS.format
    
    config_gui["custom_kps_listview"].Delete()
    
    for kps, kps_text in config.custom_KPS
    {
        config_gui["custom_kps_listview"].Add("Select", kps, kps_text)
    }
        
    config_gui["update_interval_edit"].Value := config.general.update_interval
}
    
; TODO apply a GUI control (presumable a box of solid color) to preview color in config window
; https://www.autohotkey.com/boards/viewtopic.php?t=40218
_real_apply_color(config_gui, &color, predefined_color, predefined_color_boxes, applicable_guis, guiCtrlObj, info)
{
    choose_color(config_gui.Hwnd, &color, predefined_color_boxes)

    for my_gui in applicable_guis
    {
        my_gui.Opt("c" (color.lum() > 127 ? "000000" : "ffffff"))
    }
}

; TODO
append_to_list(guiCtrlObj, info)
{
    
}

_real_try_save_update_interval(config, gui_ctrl_obj, info)
{
    config.general.update_interval := gui_ctrl_obj.Value
}

_real_try_save_color(config, gui_ctrl_obj, info)
{
    color := RGB.from_string(gui_ctrl_obj)

    switch gui_ctrl_obj.Name
    {
        case "bg_color_edit":
            config.style.bg_color := color
        case "fg_color_edit":
            config.style.fg_color := color
    }
}

init_config_gui(main_gui, config)
{
    help_ico_handle_type := 0
    help_ico_handle := LoadPicture("res/help.ico", , &help_ico_handle_type)
    new_config := config.Clone()
    
    config_gui := Gui("+Owner" main_gui.Hwnd " -MinimizeBox -MaximizeBox")
    config_gui.Title := "Configure"
    config_gui.SetFont(, default_font())
    disable_close_button(config_gui.Hwnd)
    config_gui.OnEvent("Close", _real_enable_main.Bind(main_gui))
    
    config_statusbar := config_gui.AddStatusBar("vstatusbar")
    config_tab := config_gui.AddTab3("vconfig_tab Choose1", ["General", "Style", "Custom KPS", "Advanced"])
    
    config_tab.UseTab(1)
    load_profile_from_file_button := config_gui.AddButton("vload_profile_from_file_button Section", "Choose a profile")
    
    filename := "Unknown"

    current_profile_text := config_gui.AddText("vcurrent_profile_text X+M", "Current profile: " filename)
    
    load_profile_from_file_button.OnEvent("Click", _real_load_config.Bind(&new_config, (*) => new_config.equal(config), config_gui))
    
    add_key_button := config_gui.AddButton("vadd_key_button Section XS", "Add a key")
    monitored_keys_edit := config_gui.AddEdit("vmonitored_keys_edit X+M r1")
    
    monitored_keys_listview := config_gui.AddListView("vmonitored_keys_listview XS Y+M r6 Grid -Hdr NoSortHdr NoSort", ["Key"])
    
    load_default_button := config_gui.AddButton("vload_default_button", "Reset to default")
    add_key_button.OnEvent("Click", append_to_list)
    
    config_tab.UseTab(2)
    bg_color_text := config_gui.AddText("Section", "Background color")
    bg_color_edit := config_gui.AddEdit("vbg_color_edit X+M r1 w100 Limit7 Uppercase -WantReturn", "#000000")
    bg_color_button := config_gui.AddButton("vbg_color_button X+M", "Choose")
    
    ; cannot apply reference to field
    choose_bg_color(config_gui_hwnd, new_config, color_edit, *)
    {
        color := new_config.KPS.bg_color

        choose_color(
            config_gui_hwnd,
            &color,
            RGB.color_boxes()
        )

        new_config.KPS.bg_color := color

        color_edit.Value := "#" new_config.KPS.bg_color.to_string()
    }

    bg_color_button.OnEvent("Click", choose_bg_color.Bind(config_gui.Hwnd, new_config, bg_color_edit))
    
    fg_color_text := config_gui.AddText("XS", "Font color")
    fg_color_edit := config_gui.AddEdit("vfg_color_edit X+M r1 w100 Limit7 Uppercase -WantReturn", "#000000")
    fg_color_button := config_gui.AddButton("vfg_color_button X+M", "Choose")
    
    choose_fg_color(config_gui_hwnd, new_config, color_edit, *)
    {
        color := new_config.KPS.fg_color

        choose_color(
            config_gui_hwnd,
            &color,
            RGB.color_boxes()
        )

        new_config.KPS.fg_color := color

        color_edit.Value := "#" new_config.KPS.fg_color.to_string()
    }

    fg_color_button.OnEvent("Click", choose_fg_color.Bind(config_gui.Hwnd, new_config, fg_color_edit))
    
    choose_font_button := config_gui.AddButton("vchoose_font_butotn XS ChooseLeft", "Choose font")
    font_preview_edit := config_gui.AddEdit("vfont_preview_edit X+m r1 w170")
    change_font(*) {
        new_config.KPS.style := choose_font(config_gui.Hwnd, , new_config.KPS.style)
        change_text_in_font_edit(config.KPS.style, config_gui["font_preview_edit"])
        change_font_in_font_edit(new_config.KPS.style, font_preview_edit)
    }
    choose_font_button.OnEvent("Click", change_font)

    change_font_underline(gui_ctrl_obj, *)
    {
        new_config.KPS.style.underline := gui_ctrl_obj.Value
        change_font_in_font_edit(new_config.KPS.style, font_preview_edit)
    }

    change_font_strikethrough(gui_ctrl_obj, *)
    {
        new_config.KPS.style.strikethrough := gui_ctrl_obj.Value
        change_font_in_font_edit(new_config.KPS.style, font_preview_edit)
    }

    underline_checkbox := config_gui.AddCheckBox("vunderline_checkbox XS", "Underline")
    underline_checkbox.OnEvent("Click", change_font_underline)
    
    strikethrough_checkbox := config_gui.AddCheckBox("vstrikethrough_checkbox X+m", "Strikethrough")
    strikethrough_checkbox.OnEvent("Click", change_font_strikethrough)

    alignment_text := config_gui.AddText("XS", "Alignment")
    alignment_dropdown := config_gui.AddDropDownList("valignment_dropdown w60 Choose3 X+M", [ "Left", "Center", "Right" ])
    format_text := config_gui.AddText("XS", "Format")
    format_edit := config_gui.AddEdit("vformat_edit X+M r1 w200", "%s")
    format_help_picture := config_gui.AddPicture("vformat_help_picture X+ w16 h-1", "HICON:*" help_ico_handle)
    format_help_picture.OnEvent("Click", _real_show_format_help)
    
    preview_button := config_gui.AddButton("vpreview XS", "Preview")
    
    config_tab.UseTab(3)
    custom_kps_edit := config_gui.AddEdit("vcustom_kps_edit Section r1 w70 Limit7 Number")
    custom_kps_updown := config_gui.AddUpDown("vcustom_kps_updown range0-9999999 0x80")
    config_gui.AddText("X+M", "=")
    custom_kps_text_edit := config_gui.AddEdit("vcustom_kps_text_edit X+M r1 w160")
    add_custom_kps_button := config_gui.AddButton("vadd_custom_kps_button XS", "Add")
    overwrite_kps_checkbox := config_gui.AddCheckbox("voverwrite_kps_checkbox X+M", "Overwrite")
    custom_kps_listview := config_gui.AddListView("vcustom_kps_listview XS r5 Grid NoSort", ["KPS", "Text"])
    
    add_custom_kps_button.OnEvent(
        "Click",
        _real_add_custom_kps.Bind(
            new_config.custom_kps,
            custom_kps_listview, 
            custom_kps_edit, 
            custom_kps_text_edit,
            overwrite_kps_checkbox
        )
    )
    
    for kps, kps_text in new_config.custom_kps
        {
            custom_kps_listview.Add("Select", kps, kps_text)
        }
        
        config_tab.UseTab(4)
        update_interval_text := config_gui.AddText("Section", "Update interval")
        update_interval_edit := config_gui.AddEdit("vupdate_interval_edit X+M r1 w63 Limit5 Number")
        update_interval_updown := config_gui.AddUpDown("vupdate_interval_updown range0-99999")
        
        update_interval_updown.OnEvent("Change", _real_try_save_update_interval.Bind(config))
        
        config_tab.UseTab(0)
        save_and_quit_button := config_gui.AddButton("vsave_and_quit_button", "Save && Quit")
        save_button := config_gui.AddButton("vsave_button X+M", "Save")
        save_as_button := config_gui.AddButton("vsave_as_button X+M", "Save as")
        cancel_button := config_gui.AddButton("vcancel_button X+M", "Cancel")
    
        cancel_button.OnEvent(
        "Click",
        _real_close_config.Bind(
            main_gui,
            config_gui,
            (*) => new_config.equal(config)
        )
    )
    
    apply_config(config, config_gui)
    SetTimer monitor_config.Bind(config, config_gui), -1000
    
    ; test_func()
    ; {
        ;     config.export("old.ini")
        ;     new_config.export("new.ini")
        ; }
        
        ; cancel_button.OnEvent(
            ;      "Click",
            ;      (*) => test_func()
    ; )
    
    return config_gui
}