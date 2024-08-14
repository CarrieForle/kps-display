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

number_change(kps_other, kps_text, prefix, suffix, custom_format, custom_kps, padding, kps_subject, info)
{
    kps_other.Value := kps_subject.Value
    kps_text.Text := prefix . custom_format.to_string(kps_subject.Value, custom_kps, padding) . suffix
}

kps_resize(kps_text, kps_slider, margin, preview_gui, minmax, width, height)
{
    kps_text.Move(margin[4], margin[1] + 30, width - margin[2] - margin[4], height - margin[1] - margin[3] - 30)
    kps_slider.Move(, , width - 125)
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

    res := 0

    try
    {
        preview_gui.BackColor := RGB.from_string(val.bg_color_edit).to_string()
    }
    catch
    {
        preview_gui.BackColor := "default"
    }

    kps_edit := preview_gui.AddEdit("vkps_edit Section X0 Y0 r1 w80 Center Number -WantReturn Limit7", "0")
    kps_updown := preview_gui.AddUpDown("vkps_updown range0-9999999 0x80")

    restart_button := preview_gui.AddButton("X+0", "Restart")
    restart_button.SetFont(, "Segoe UI")

    kps_slider := preview_gui.AddSlider("vkps_slider X+0 range0-30 AltSubmit NoTicks BackgroundDefault")

    kps_text := preview_gui.AddText("XS Y30 vkps_text " val.alignment_dropdown, val.prefix_edit . custom_format.to_string(0, config.custom_kps, val.padding_edit) val.suffix_edit)
    config_gui.style.set(kps_text, RGB.from_string(val.fg_color_edit).to_string())

    margin := []

    for text in ["top", "right", "bottom", "left"]
    {
        res := val.%"margin_" text "_edit"%
            
        margin.Push(IsInteger(res) ? res : 0)
    }

    kps_edit.OnEvent("Change", number_change.Bind(kps_slider, kps_text, val.prefix_edit, val.suffix_edit, custom_format, config.custom_kps, val.padding_edit))
    kps_updown.OnEvent("Change", number_change.Bind(kps_slider, kps_text, val.prefix_edit, val.suffix_edit, custom_format, config.custom_kps, val.padding_edit))
    restart_button.OnEvent("Click", restart_preview_gui.Bind(config_gui, last_pos, last_dimension))
    kps_slider.OnEvent("Change", number_change.Bind(kps_edit, kps_text, val.prefix_edit, val.suffix_edit, custom_format, config.custom_kps, val.padding_edit))
    preview_gui.OnEvent("Size", kps_resize.Bind(kps_text, kps_slider, [
        val.margin_top_edit,
        val.margin_right_edit,
        val.margin_bottom_edit,
        val.margin_left_edit
    ]))

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