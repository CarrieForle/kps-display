_add_custom_kps(custom_kps_map, listview, kps, kps_text, overwrite := false)
{
    if !custom_kps_map.Has(kps)
    {
        listview.Add("Select", kps, kps_text)
        custom_kps_map[kps] := kps_text
    }
    else if overwrite || "Yes" = MsgBox(kps " has been bind to " custom_kps_map[kps] "`nDo you want to overwrite it?", "Custom KPS Warning", 0x124)
    {
        str_kps := String(kps)

        loop custom_kps_map.Count
        {
            if str_kps = listview.GetText(A_Index)
            {
                listview.Modify(A_Index, "Select Vis", str_kps, kps_text)
                custom_kps_map[kps] := kps_text

                break
            }
        }
    }
}

_real_add_custom_kps(custom_kps_map, listview, kps_edit, kps_text_edit, overwrite_checkbox, *)
{
    int_kps := Integer(kps_edit.Value)

    if custom_kps_map.Has(int_kps) && custom_kps_map[int_kps] = kps_text_edit.Value
    {
        return
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

    _add_custom_kps(custom_kps_map, listview, int_kps, kps_text_edit.Value, 1 = overwrite_checkbox.Value)
}