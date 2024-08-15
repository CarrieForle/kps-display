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

#Include "../../color.ahk"
#Include "../../format.ahk"
#Include "../../config.ahk"

number_change(kps_other, kps_text, custom_format, custom_kps, padding, kps_subject, info)
{
    kps_other.Value := kps_subject.Value
    kps_text.Text := custom_format.to_string(kps_subject.Value, custom_kps, padding)
}

kps_resize(kps_text, kps_slider, align, offsets, preview_gui, minmax, width, height)
{
    static last_width := 0
    
    if last_width = width
    {
        return
    }

    kps_slider.Move(, , width - 125)

    if align = "Center"
    {
        kps_text.Move(offsets[1] - (A_ScreenWidth - width) // 2, offsets[2])
    }
    else
    {
        kps_text.Move(offsets[1] - A_ScreenWidth + width, offsets[2])
    }

    last_width := width
    kps_text.Redraw()
}

destroy_preview(config_gui, last_pos, last_dimension, preview_gui)
{
    x := 0
    y := 0
    width := 0
    height := 0
    preview_gui.GetPos(&x, &y, &width, &height)
    last_pos[1] := x
    last_pos[2] := y
    last_dimension[1] := width
    last_dimension[2] := height
    preview_gui.Destroy()
    config_gui.DeleteProp("_has_preview_window")
}

restart_preview_gui(config_gui, last_pos, last_dimension, restart_button, *)
{
    destroy_preview(config_gui, last_pos, last_dimension, restart_button.Gui)
    init_and_show_config_preview_gui(config_gui)
}

init_and_show_config_preview_gui(config_gui)
{
    static hwnd := 0
    static last_pos := [-1, -1]
    static last_dimension := [350, 300]

    if config_gui.HasOwnProp("_has_preview_window")
    {
        WinClose "ahk_id " hwnd
    }

    config_gui._has_preview_window := true
    val := config_gui.Submit(false)
    custom_format := CustomFormat.from_format(val.format_edit)
    config := Configuration()
    config.read_custom_kps_from_listview(config_gui["custom_kps_listview"])

    preview_gui := Gui("ToolWindow Resize Owner" config_gui.hwnd)
    preview_gui.Title := "Preview"
    hwnd := preview_gui.Hwnd

    offsets := []

    for text in ["horizontal", "vertical"]
    {
        res := val.%"offset_" text "_edit"%
        offsets.Push(IsInteger(res) ? Integer(res) : 0)
    }

    kps_text := preview_gui.AddText("vkps_text -Wrap X0 Y" 30 + offsets[2] " w" A_ScreenWidth " h" A_ScreenHeight " " val.alignment_dropdown, custom_format.to_string(0, config.custom_kps, val.padding_edit))
    config_gui.style.set(kps_text, RGB.from_string(val.fg_color_edit).to_string())

    try
    {
        kps_text.Opt("Background" RGB.from_string(val.bg_color_edit).to_string())
    }

    kps_edit := preview_gui.AddEdit("vkps_edit Section X0 Y0 r1 w80 Center Number -WantReturn Limit7", "0")
    kps_updown := preview_gui.AddUpDown("vkps_updown range0-9999999 0x80")

    restart_button := preview_gui.AddButton("X+0", "Restart")
    restart_button.SetFont(, "Segoe UI")

    kps_slider := preview_gui.AddSlider("vkps_slider X+0 range0-50 AltSubmit NoTicks BackgroundDefault")

    kps_edit.OnEvent("Change", number_change.Bind(kps_slider, kps_text, custom_format, config.custom_kps, val.padding_edit))
    kps_updown.OnEvent("Change", number_change.Bind(kps_slider, kps_text, custom_format, config.custom_kps, val.padding_edit))
    restart_button.OnEvent("Click", restart_preview_gui.Bind(config_gui, last_pos, last_dimension))
    kps_slider.OnEvent("Change", number_change.Bind(kps_edit, kps_text, custom_format, config.custom_kps, val.padding_edit))

    if val.alignment_dropdown != "Left"
    {
        preview_gui.OnEvent("Size", kps_resize.Bind(kps_text, kps_slider, val.alignment_dropdown, offsets))
    }

    preview_gui.OnEvent("Close", destroy_preview.Bind(config_gui, last_pos, last_dimension))
    
    if last_pos[1] != -1
    {
        preview_gui.Show("w" last_dimension[1] " h" last_dimension[2] " x" last_pos[1] " y" last_pos[2])
    }
    else
    {
        preview_gui.Show("w" last_dimension[1] " h" last_dimension[2])
    }
}