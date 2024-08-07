#Include "util.ahk"
#Include "gui.ahk"

_real_show_option(option_menu, guiObj, guiCtrlObj, item, isRightClick, x, y)
{
    if isRightClick {
        option_menu.Show()
    }
}

init_main_gui()
{
    main_gui := Gui("+Resize -MaximizeBox")

    main_gui.Title := "KPS Display"
    main_gui.OnEvent("Close", (*) => ExitApp())

    kps_text := main_gui.AddText("vkps_text w300 h300 Right", "##")
    kps_text.SetFont("S72", default_font())

    return main_gui
}

update_kps_text(kps)
{
    kps_text := get_guis("main")['kps_text']
    if kps_text.Text != kps
    {
        kps_text.Text := kps
    }
}