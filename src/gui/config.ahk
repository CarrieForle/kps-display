#Include "../config.ahk"
#Include "../resread.ahk"
#Include "../choosefont.ahk"
#Include "util.ahk"
#Include "config/format_help.ahk"

_real_load_config(&result, guiCtrlObj, info)
{
    config := FileSelect(1,, "Choose a profile", "Configs (*.ini)")

    try
    {
        if config
        {
            result := read_config(config)
        }
    }
    catch Error as e
    {
        filename := "config"
        SplitPath config, &filename
        MsgBox e.Message, "Error reading " filename, 16
    }
}

append_to_list(guiCtrlObj, info)
{
    
}

init_config_gui(main_gui)
{
    help_ico_handle_type := 0
    help_ico_handle := LoadPicture("res/help.ico", , &help_ico_handle_type)
    
    config := 0
    load_config := _real_load_config.bind(&config)
    
    config_gui := Gui("+Owner" main_gui.Hwnd " -MinimizeBox -MaximizeBox")
    
    config_gui.Title := "Configure"
    config_gui.SetFont(, default_font())
    config_gui.OnEvent("Close", (*) => main_gui.opt("-Disabled"))
    
    config_tab := config_gui.AddTab3("vconfig_tab Choose1", ["General", "Style"])
    
    config_tab.UseTab(0)
    save_button := config_gui.AddButton("vsave_button", "Save")
    cancel_button := config_gui.AddButton("vcancel_button X+M", "Cancel")
    
    config_tab.UseTab(1)
    load_profile_from_file_button := config_gui.AddButton("vload_profile_from_file_button ", "Choose a profile")
    add_button := config_gui.AddButton("vadd_button Section", "Add a key")
    monitored_keys_edit := config_gui.AddEdit("vmonitored_keys_edit X+M")
    monitored_keys_list_view := config_gui.AddListView("vmonitored_keys_list_view XS Y+M R1")
    load_default_button := config_gui.AddButton("vload_default_button", "Reset to default")
    add_button.OnEvent("Click", append_to_list)
    load_profile_from_file_button.OnEvent("Click", load_config)
    
    config_tab.UseTab(2)
    bg_color_text := config_gui.AddText("Section", "Background color")
    bg_color_edit := config_gui.AddEdit("vbg_color_edit X+M r1 w100 Limit7 Uppercase -WantReturn", "#")
    bg_color_button := config_gui.AddButton("vbg_color_button X+M", "Choose")
    fg_color_text := config_gui.AddText("XS", "Font color")
    fg_color_edit := config_gui.AddEdit("vfg_color_edit X+M r1 w100 Limit7 Uppercase -WantReturn", "#")
    bg_color_button := config_gui.AddButton("vfg_color_button X+M", "Choose")
    choose_font_button := config_gui.AddButton("vchoose_font_butotn XS ChooseLeft", "Choose font")
    
    my_font := 0
    
    choose_font_button.OnEvent("Click", (*) => choose_font(config_gui.Hwnd, &my_font))
    
    font_preview_edit := config_gui.AddEdit("vfont_preview_edit X+m r1 -WantReturn w150")
    underline_checkbox := config_gui.AddCheckBox("vunderline_checkbox XS", "Underline")
    strikethrough_checkbox := config_gui.AddCheckBox("vstrikethrough_checkbox X+m", "Strikethrough")
    alignment_text := config_gui.AddText("XS", "Alignment")
    alignment_dropdown := config_gui.AddDropDownList("vset_alignment_dropdown w60 Choose3 X+M", ["Left", "Center", "Right"])
    format_text := config_gui.AddText("XS", "Format")
    format_edit := config_gui.AddEdit("vkps_format_edit X+M r1 w200 Wrap  -WantReturn", "%s")
    
    ; https://www.autohotkey.com/docs/v2/misc/ImageHandles.htm
    init_config_format_help_gui(config_gui, help_ico_handle)

    set_custom_kps_button := config_gui.AddButton("vset_custom_kps_button XS", "Customize KPS")

    return config_gui
}

_real_show_config(main_gui, config_gui, itemName, itemPos, myMenu)
{
    main_gui.Opt("+Disabled")
    config_gui.Show("Restore")
}