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

add_custom_kps(listview, kps_edit, kps_text_edit, overwrite_checkbox, add_button, *)
{
    if kps_edit.Value = "*"
    {
        multiedit_kps(add_button, listview, kps_edit, kps_text_edit, overwrite_checkbox)

        return
    }
    
    listview.Gui.Opt("OwnDialogs")
    kps_map := Map()
    kps_text := kps_text_edit.Value

    loop listview.GetCount()
    {
        kps_map[Integer(listview.GetText(A_Index, 1))] := listview.GetText(A_Index, 2)
    }

    if StrLen(kps_edit.Value) = 0
    {
        MsgBox "KPS must not be empty", "Error", 16
        return
    }

    if StrLen(kps_text_edit.Value) = 0
    {
        if "No" = MsgBox("KPS text is empty. Do you want to continue?", "Custom KPS Warning", 0x124)
        {
            return
        }
    }
    else if StrLen(Trim(kps_text_edit.Value)) = 0
    {
        if "No" = MsgBox("KPS text is of blank characters. Do you want to continue?", "Custom KPS Warning", 0x124)
        {
            return
        }
    }

    row := 0
    while row := listview.GetNext(row)
    {
        listview.Modify(row, "-Select")
    }

    int_kps := Integer(kps_edit.Value)

    if !kps_map.Has(int_kps)
    {
        listview.Add("Select", int_kps, kps_text)
        kps_map[int_kps] := kps_text
    }
    else if overwrite_checkbox.Value || kps_map[int_kps] == kps_text || "Yes" = MsgBox(int_kps " has been bind to " kps_map[int_kps] "`nDo you want to overwrite it?", "Custom KPS Warning", 0x124)
    {
        loop kps_map.Count
        {
            if int_kps = listview.GetText(A_Index)
            {
                listview.Modify(A_Index, "Select Vis", int_kps, kps_text)
                kps_map[int_kps] := kps_text

                break
            }
        }
    }
}

multiedit_kps(add_button, listview, kps_edit, kps_text_edit, overwrite_checkbox)
{
    if StrLen(kps_edit.Value) = 0
    {
        MsgBox "KPS must not be empty", "Error", 16
        return
    }

    if StrLen(kps_text_edit.Value) = 0
    {
        if "No" = MsgBox("KPS text is empty. Do you want to continue?", "Custom KPS Warning", 0x124)
        {
            return
        }
    }
    else if StrLen(Trim(kps_text_edit.Value)) = 0
    {
        if "No" = MsgBox("KPS text is of blank characters. Do you want to continue?", "Custom KPS Warning", 0x124)
        {
            return
        }
    }

    row := 0

    while row := listview.GetNext(row)
    {
        text := StrReplace(kps_text_edit.Value, "%d", listview.GetText(row))
        text := StrReplace(kps_text_edit.Value, "%%", "%")
        listview.Modify(row, "-Select", , text)
    }

    kps_edit.Value := 0
    kps_edit.Enabled := true
    overwrite_checkbox.Value := false
    overwrite_checkbox.Enabled := true
    add_button.Text := "Add"
}

delete_custom_kps(listview, *)
{
    while row := listview.GetNext()
    {
        listview.Delete(row)
    }
}

selected_custom_kps(add_button, kps_edit, overwrite_checkbox, listview, *)
{
    selected_row_count := 0
    iter := -1

    while iter := listview.GetNext(iter)
    {
        row := iter
        selected_row_count += 1
    }
    
    if selected_row_count = 0
    {
        kps_edit.Value := 0
        overwrite_checkbox.Value := false
        overwrite_checkbox.Enabled := true
        kps_edit.Enabled := true
        add_button.Text := "Add"
    }
    else if selected_row_count = 1
    {
        kps_edit.Value := listview.GetText(row)
        overwrite_checkbox.Value := true
        overwrite_checkbox.Enabled := true
        kps_edit.Enabled := true
        add_button.Text := "Add"
    }
    else
    {
        kps_edit.Value := "*"
        overwrite_checkbox.Value := true
        overwrite_checkbox.Enabled := false
        kps_edit.Enabled := false
        add_button.Text := "Edit"
    }
}