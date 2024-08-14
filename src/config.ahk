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

#Include "font.ahk"
#Include "color.ahk"
#Include "monitored_keys.ahk"
#Include "format.ahk"
#Include "util.ahk"

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
            throw ValueError("Failed to read `"" key "`" in [" section "].")
        }
        else
        {
            throw e
        }
    }
}

class ConfigParseError extends Error
{

}

class Configuration
{
    class General
    {
        update_interval := 0
        monitored_keys := MonitoredKeys()
        margin := [0, 0, 0, 0]

        Clone()
        {
            new_object := Configuration.General()
            new_object.update_interval := this.update_interval
            new_object.monitored_keys := this.monitored_keys.Clone()
            new_object.margin := this.margin.Clone()

            return new_object
        }

        equal(other)
        {
            res := this.update_interval = other.update_interval &&
                this.monitored_keys.equal(other.monitored_keys) &&
                array_equal(this.margin, other.margin)
            
            return res
        }
    }

    class KPS
    {
        bg_color := RGB(0, 0, 0)
        fg_color := RGB(0, 0, 0)
        style := Font()
        align := ""
        format := CustomFormat()
        padding := ""
        prefix := ""
        suffix := ""

        Clone()
        {
            new_object := Configuration.KPS()
            new_object.bg_color := this.bg_color.Clone()
            new_object.fg_color := this.fg_color.Clone()
            new_object.style := this.style.Clone()
            new_object.align := this.align
            new_object.format := this.format.Clone()
            new_object.padding := this.padding
            new_object.prefix := this.prefix
            new_object.suffix := this.suffix

            return new_object
        }

        ; Every field should be included
        equal(other)
        {
            res := this.bg_color.equal(other.bg_color) &&
                this.fg_color.equal(other.fg_color) &&
                this.style.equal(other.style) &&
                this.align = other.align &&
                this.format.equal(other.format) &&
                this.padding == other.padding &&
                this.prefix == other.prefix &&
                this.suffix == other.suffix

            return res
        }

        read_prefix(input)
        {
            this.prefix := Configuration.KPS._read_prefix_or_suffix(input)
        }

        read_suffix(input)
        {
            this.suffix := Configuration.KPS._read_prefix_or_suffix(input)
        }

        prefix_to_string()
        {
            return this.prefix_to_config()
        }

        suffix_to_string()
        {
            return this.suffix_to_config()
        }

        prefix_to_config()
        {
            return Configuration.KPS._prefix_or_suffix_to_config(this.prefix)
        }
        
        suffix_to_config()
        {
            return Configuration.KPS._prefix_or_suffix_to_config(this.suffix)
        }

        static _read_prefix_or_suffix(input)
        {
            result := StrReplace(input, "\n", "`n")
            result := StrReplace(result, "\\", "\")

            return result
        }

        static _prefix_or_suffix_to_config(input)
        {
            result := StrReplace(input, "\", "\\")
            result := StrReplace(input, "`n", "\n")

            return result
        }
    }

    filepath := ""
    general := Configuration.General()
    KPS := Configuration.KPS()
    custom_kps := Map()

    read_custom_kps_from_config(custom_kps_strs)
    {
        result := Map()

        for key_pair in custom_kps_strs
        {
            match := 0

            if !RegExMatch(key_pair, "^(\d+?)=(.*)$", &match)
            {
                throw ConfigParseError("Invalid custom KPS: `"" key_pair "`"")
            }

            if !IsInteger(match[1])
            {
                throw ConfigParseError(key " is not an integer in `"" key_pair "`" (custom KPS)")
            }

            key := Integer(match[1])

            if result.Has(key)
            {
                throw ConfigParseError(key " is read twice for custom KPS")
            }

            val := StrReplace(match[2], "\n", "`n")
            result[key] := StrReplace(val, "\\", "\")
        }

        this.custom_kps := result
    }

    read_custom_kps_from_listview(listview)
    {
        result := Map()

        Loop listview.GetCount()
        {
            key := Integer(listview.GetText(A_Index, 1))
            val := listview.GetText(A_Index, 2)

            result[key] := val
        }

        this.custom_kps := result
    }
    
    ; TODO untested
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


    equal(other)
    {
        res := (this.filepath == other.filepath) &&
            map_equal(this.custom_kps, other.custom_kps) &&
            this.general.equal(other.general) &&
            this.KPS.equal(other.KPS)
                
        return res
    }

    ; Use this when comparing changes that are settable in GUI
    equivalent(other)
    {
        res := map_equal(this.custom_kps, other.custom_kps) &&
            this.general.equal(other.general) &&
            this.KPS.equal(other.KPS)
        
        return res
    }

    static read(filepath)
    {
        try
        {
            result := Configuration()
            result.filepath := filepath
            
            if !IsInteger(update_interval := better_ini_read(filepath, "general", "update_interval"))
            {
                throw ConfigParseError( update_interval " is not an integer (update_interval in [general])")
            }

            update_interval := Integer(update_interval)

            if update_interval < 1
            {
                throw ConfigParseError("update_interval must be positive. Found " update_interval)
            }

            result.general.update_interval := update_interval
            result.general.monitored_keys := MonitoredKeys.from_config(better_ini_read(filepath, "general", "monitored_keys"))

            margin := []

            for m in StrSplit(better_ini_read(filepath, "general", "margin"), A_Space)
            {
                if StrLen(m) = 0
                {
                    continue
                }

                if !IsInteger(m)
                {
                    throw ConfigParseError(update_interval " is not an integer (margin in [general])")
                }

                margin.Push(Integer(m))
            }

            if margin.length = 4
            {
                result.general.margin := margin
            }
            else if margin.length > 0
            {
                ConfigParseError("Expected 4 number in margin but got " margin.Length " (margin in [general])")
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
            result.KPS.format := CustomFormat.from_format(better_ini_read(filepath, "KPS", "format"))
            result.KPS.padding := better_ini_read(filepath, "KPS", "padding")
            result.KPS.read_prefix(better_ini_read(filepath, "KPS", "prefix"))
            result.KPS.read_suffix(better_ini_read(filepath, "KPS", "suffix"))

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
                else if line && 1 = parse_custom_kps_state
                {
                    first_ch := SubStr(line, 1, 1)

                    if first_ch = "["
                    {
                        parse_custom_kps_state := 2
                    }
                    else if first_ch != ";"
                    {
                        kps_key_pairs.Push(line)
                    }
                }
            }

            if parse_custom_kps_state
            {
                result.read_custom_kps_from_config(kps_key_pairs)
            }

            return result
        }
        catch Error as e
        {
            Throw ConfigParseError(e.Message, e.What, e.Extra)
        }
    }

    _dbg_equal(other)
    {
        equ_val := this.equal(other)

        MsgBox "Overall " equ_val "`n" .
            "equivalency " this.equivalent(other) "`n" .
            "custom KPS " map_equal(this.custom_kps, other.custom_kps) "`n" .
            "general " this.general.equal(other.general) "`n" .
            "KPS " this.KPS.equal(other.KPS)
        
        return equ_val
    }

    export(filepath?)
    {
        if !IsSet(filepath)
        {
            filepath := this.filepath
        }
        
        fp := FileOpen(filepath, "w", "UTF-16")
        fp.WriteLine("; Generated by the program on " A_YYYY "-" A_MM "-" A_DD "T" A_Hour ":" A_Min ":" A_Sec " localtime`n")
        fp.Close()

        IniWrite this.general.update_interval, filepath, "general", "update_interval"
        IniWrite this.general.monitored_keys.to_config(), filepath, "general", "monitored_keys"
        IniWrite join_array(this.general.margin), filepath, "general", "margin"
        IniWrite this.KPS.bg_color.to_config(), filepath, "KPS", "bg_color"
        IniWrite this.KPS.fg_color.to_config(), filepath, "KPS", "fg_color"
        IniWrite this.KPS.style.to_config(), filepath, "KPS", "style"
        IniWrite this.KPS.align, filepath, "KPS", "align"
        IniWrite this.KPS.format.orig_format, filepath, "KPS", "format"
        IniWrite this.KPS.padding, filepath, "KPS", "padding"
        IniWrite this.KPS.prefix_to_config(), filepath, "KPS", "prefix"
        IniWrite this.KPS.suffix_to_config(), filepath, "KPS", "suffix"

        for kps, kps_text in this.custom_kps
        {
            ; val does not trim; key Ltrim-ed
            IniWrite kps_text, filepath, "custom_KPS", kps
        }
    }
}