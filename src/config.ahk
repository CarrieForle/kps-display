#Include "choosefont.ahk"
#Include "choosecolor.ahk"

better_ini_read(filepath, section, key, default?)
{
    try
    {
        return IniRead(filepath, section, key)
    }
    catch Error as e ; OSError somehow is not thrown but other unidentified Error
    {
        ; https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-getprivateprofilestring#return-value
        if A_LastError = 2
        {
            throw ValueError("Failed to read `"" key "`" in [" section "] is not found")
        }
        else
        {
            throw e
        }
    }
}

_array_equal(a, b)
{
    if a.Length != b.Length
    {
        return false
    }

    for _ in a
    {
        if a[A_Index] != b[A_Index]
        {
            return false
        }
    }

    return true
}

_map_equal(a, b)
{
    if a.Count != b.Count
    {
        return false
    }

    a_keypair := ""
    b_keypair := ""

    for key in a
    {
        a_keypair .="``" key "``=``" a[key] "```n"
    }

    for key in b
    {
        b_keypair .= "``" key "``=``" b[key] "```n"
    }

    FileAppend "a`n" a_keypair, "a.txt"
    FileAppend "b`n" b_keypair, "b.txt"

    try
    {
        for key in a
        {
            if !b.Has(key) || a[key] != b[key]
            {
                return false
            }
        }
    }

    return true
}

class ConfigParseError extends Error
{

}

class Configuration
{
    class General
    {
        update_interval := 0
        monitored_keys := 0
        dimension := [0, 0]
        margin := [0, 0, 0, 0]

        Clone()
        {
            new_object := Configuration.General()
            new_object.update_interval := this.update_interval
            new_object.monitored_keys := this.monitored_keys
            new_object.dimension := this.dimension.Clone()
            new_object.margin := this.margin.Clone()

            return new_object
        }

        equal(other)
        {
            res := this.update_interval = other.update_interval &&
                this.monitored_keys = other.monitored_keys &&
                _array_equal(this.dimension, other.dimension) &&
                _array_equal(this.margin, other.margin)
            
            return res
        }
    }

    class KPS
    {
        bg_color := RGB(0, 0, 0)
        fg_color := RGB(0, 0, 0)
        style := Font()
        align := ""
        format := ""

        Clone()
        {
            new_object := Configuration.KPS()
            new_object.bg_color := this.bg_color.Clone()
            new_object.fg_color := this.fg_color.Clone()
            new_object.style := this.style.Clone()
            new_object.align := this.align
            new_object.format := this.format

            return new_object
        }

        equal(other)
        {
            res := this.bg_color.equal(other.bg_color) &&
                this.fg_color.equal(other.fg_color) &&
                this.style.equal(other.style) &&
                this.align = other.align &&
                this.format = other.format

            return res
        }

    }

    filepath := ""
    general := Configuration.General()
    KPS := Configuration.KPS()
    custom_kps := Map()

    read_custom_kps(custom_kps_strs)
    {
        result := Map()

        for key_pair in custom_kps_strs
        {
            match := 0

            if !RegExMatch(key_pair, "^(\d+?)=(.*)$", &match)
            {
                throw ConfigParseError("Invalid custom KPS: `"" key_pair "`"")
            }

            key := Integer(match[1])

            if result.Has(key)
            {
                throw ConfigParseError(key " is read twice for custom KPS")
            }

            result[key] := match[2]
        }

        this.custom_kps := result
    }

    ; TODO
    read_monitored_keys(keys)
    {

    }
    
    ; untested
    Clone()
    {
        new_object := Configuration()
        new_object.filepath := this.filepath
        new_object.general := this.general.Clone()
        new_object.KPS := this.KPS.Clone()
        
        ; int: str. Clone OK
        new_object.custom_kps := this.custom_kps.Clone()

        return new_object
    }

    equal(other, ignore_filepath := true)
    {
        res := (this.filepath == other.filepath || ignore_filepath) &&
            _map_equal(this.custom_kps, other.custom_kps) &&
            this.general.equal(other.general) &&
            this.KPS.equal(other.KPS)
                
        return res
    }

    static read(filepath)
    {
        result := Configuration()
        
        result_filepath := 0
        SplitPath filepath, &result_filepath
        result.filepath := result_filepath

        try
        {
            result.general.update_interval := Integer(better_ini_read(filepath, "general", "update_interval"))
        }
        catch Error as e
        {
            MsgBox e.Message
            return
        }
        result.general.monitored_keys := better_ini_read(filepath, "general", "monitored_keys")

        if result.general.monitored_keys = ""
        {
            result.general.monitored_keys := "{All}"
        }

        result.KPS.bg_color := RGB.from_string(better_ini_read(filepath, "KPS", "bg_color"))
        result.KPS.fg_color := RGB.from_string(better_ini_read(filepath, "KPS", "fg_color"))
        result.KPS.style := Font.from_config(better_ini_read(filepath, "KPS", "style"))

        align := StrTitle(better_ini_read(filepath, "KPS", "align"))

        if align != "Left" && align != "Center" && align != "Right"
        {
            throw ConfigParseError("Invalid alignment: `"" align "`"`n The value must be one of `"Left`", `"Center`", `"Right`".")
        }

        result.KPS.align := align
        result.KPS.format := better_ini_read(filepath, "KPS", "format")

        parse_custom_kps_state := 0
        kps_key_pairs := []
        
        loop read filepath
        {
            line := Trim(A_LoopReadLine)

            if line = "[custom_KPS]"
            {
                if parse_custom_kps_state
                {
                    throw ConfigParseError("[custom_KPS] appears twice")
                }

                parse_custom_kps_state := 1
            }
            else if 1 = parse_custom_kps_state
            {
                first_ch := SubStr(line, 1, 1)

                if first_ch = "["
                {
                    parse_custom_kps_state := 2
                }
                else if StrLen(line) > 0 && ";" != SubStr(line, 1, 1)
                {
                    kps_key_pairs.Push(A_LoopReadLine)
                }
            }
        }
        
        if parse_custom_kps_state
        {
            result.read_custom_kps(kps_key_pairs)
        }

        return result
    }

    export(filepath?)
    {
        if !IsSet(filepath)
        {
            filepath := this.filepath
        }
        
        fp := FileOpen(filepath, "w", "UTF-16")
        fp.WriteLine("; Generated by the program")
        fp.Close()

        IniWrite this.general.update_interval, filepath, "general", "update_interval"

        ; TODO not implemented yet
        IniWrite this.general.monitored_keys, filepath, "general", "monitored_keys"

        IniWrite this.general.dimension[1], filepath, "general", "window_width"
        IniWrite this.general.dimension[2], filepath, "general", "window_height"

        IniWrite this.general.margin[1], filepath, "general", "top_margin"
        IniWrite this.general.margin[2], filepath, "general", "right_margin"
        IniWrite this.general.margin[3], filepath, "general", "bottom_margin"
        IniWrite this.general.margin[4], filepath, "general", "left_margin"

        IniWrite this.KPS.bg_color.to_config(), filepath, "KPS", "bg_color"
        IniWrite this.KPS.fg_color.to_config(), filepath, "KPS", "fg_color"

        IniWrite this.KPS.style.to_config(), filepath, "KPS", "style"
        IniWrite this.KPS.align, filepath, "KPS", "align"
        IniWrite this.KPS.format, filepath, "KPS", "format"

        for kps, kps_text in this.custom_kps
        {
            ; val does not trim; key Ltrim-ed
            IniWrite kps_text, filepath, "custom_KPS", kps
        }
    }
}