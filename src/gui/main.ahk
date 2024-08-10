#Include "util.ahk"
#Include "gui.ahk"

_real_show_option(option_menu, guiObj, guiCtrlObj, item, isRightClick, x, y)
{
    if isRightClick {
        option_menu.Show()
    }
}

_real_resize(font_height, gui_obj, mimmax, width, height)
{
    kps_text := gui_obj["kps_text"]
    kps_text.Move(, , width - 30, height)
    kps_text.Redraw()
}

_real_enable_main(main_gui, *)
{
    main_gui.Show()
    main_gui.Opt("-Disabled")
    main_gui["kps_text"].Enabled := false
    main_gui["kps_text"].Enabled := true
}

init_main_gui(config)
{
    main_gui := Gui("+Resize -MaximizeBox", "KPS Display")
    main_gui.BackColor := config.KPS.bg_color.to_string()
    ; config.KPS.style.set(main_gui, "a75252")
    main_gui.Title := "KPS Display"
    main_gui.OnEvent("Close", (*) => ExitApp())
    resize := _real_resize.bind(config.KPS.style.height)

    main_gui.OnEvent("Size", resize)
    
    kps_text := main_gui.AddText("vkps_text Right H270 W270", "0")
    config.KPS.style.set(kps_text, config.Kps.fg_color.to_string())
    
    return main_gui
}

update_kps_text(kps_text, kps)
{
    if kps_text.Value != kps
    {
        kps_text.Value := kps
    }
}