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

#Include "config.ahk"

class MonitoredKeys
{
    params := ["", ""]

    static from_config(input)
    {
        result := MonitoredKeys()

        if !input
        {
            result.params := ["{All}", "+N"]
            
            return result
        }

        if pos := InStr(input, "{All}")
        {
            throw ConfigParseError("Found invalid text `"{All}`" for monitored keys at pos: " pos)
        }

        indicator := SubStr(input, 1, 1)

        if indicator = "+" || indicator = "-"
        {
            if StrLen(input) = 1
            {
                return result.params := ["{" input "}", "+N"]
            }

            result.params := [SubStr(input, 2), indicator "N"]
        }
        else
        {
            result.params := [input, "+N"]
        }

        result.params[1] := RegExReplace(result.params[1], "[!#^+]", "{$0}")

        ; Early check
        ih := InputHook("B V L0")

        result.transform(ih)
        ih.Start()
        ih.Stop()

        return result
    }

    static from_gui(text, is_invert)
    {
        result := MonitoredKeys()
        text := Trim(text)

        if StrLen(text) = 0
        {
            result.params := ["{All}", "+N"]
        }
        else
        {
            result.params[1] := text
            result.params[2] := is_invert ? "-N" : "+N"
        }
        

        return result
    }

    to_config()
    {
        if (this.params[1] = "{All}" && this.params[2] = "+N")
        {
            return ""
        }

        if (this.params[1] = "{+}" || this.params[1] = "{-}") && this.params[2] = "+N"
        {
            return SubStr(this.params[1], 2, 1)
        }

        result := RegExReplace(this.params[1], "{([!#^+])}", "$1")

        return SubStr(this.params[2], 1, 1) result
    }

    to_gui()
    {
        if (this.params[1] = "{All}" && this.params[2] = "+N")
        {
            return ""
        }

        if (this.params[1] = "{+}" || this.params[1] = "{-}") && this.params[2] = "+N"
        {
            return SubStr(this.params[1], 2, 1)
        }

        result := RegExReplace(this.params[1], "{([!#^+])}", "$1")

        return result
    }

    transform(ih)
    {
        if this.params[2] = "-N"
        {
            ih.KeyOpt("{All}", "+N")
        }
        else
        {
            ih.KeyOpt("{All}", "-N")
        }

        ih.KeyOpt(this.params*)
    }

    Clone()
    {
        new_object := MonitoredKeys()
        new_object.params := this.params.Clone()

        return new_object
    }

    equal(other)
    {
        return this.params[1] = other.params[1] && 
            this.params[2] = other.params[2]
    }
}

add_monitored_keys(monitored_key_edit, listview, invert_checkbox, *)
{    
    keys := []

    in_arr(a, b)
    {
        for v in a
        {
            if v == b
            {
                return true
            }
        }

        return false
    }
    
    loop listview_count := listview.GetCount()
    {
        keys.Push(listview.GetText(A_Index))
    }
    
    match := 0
    text := StrLower(monitored_key_edit.Value)

    while pos := RegExMatch(text, "\{\w+\}", &match)
    {
        key := StrTitle(match[0])

        if !in_arr(keys, key)
        {
            keys.Push(key)
        }

        loop parse SubStr(text, 1, pos - 1), , A_Space
        {
            if !in_arr(keys, A_LoopField)
            {
                keys.Push(A_LoopField)
            }
        }

        text := SubStr(text, pos)
    }

    loop parse text, , A_Space
    {
        if !in_arr(keys, A_LoopField)
        {
            keys.Push(A_LoopField)
        }
    }

    loop keys.Length - listview_count
    {
        listview.Add(, keys[A_Index + listview_count])
    }

    monitored_key_edit.Value := ""
}