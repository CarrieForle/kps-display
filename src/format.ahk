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

class CustomFormat
{
    left_custom_padding := [0, 0, 0, 0]
    right_custom_padding := [0, 0, 0, 0]
    format_string := ""
    orig_format := ""

    to_string(kps, custom_kps_map, custom_padding)
    {
        if custom_padding
        {
            left_custom_padding_string := [kps, custom_kps_map.Get(kps, kps), Format("{:x}", kps), Format("{:X}", kps)]
            right_custom_padding_string := left_custom_padding_string.Clone()
            length := StrLen(custom_padding)

            for default_val in left_custom_padding_string
            {
                if this.left_custom_padding[A_Index] && length > StrLen(default_val)
                {
                    left_custom_padding_string[A_Index] .= SubStr(custom_padding, StrLen(default_val) + 1)
                }
            }

            for default_val in right_custom_padding_string
            {
                if this.right_custom_padding[A_Index] && length > StrLen(default_val)
                {
                    right_custom_padding_string[A_Index] := SubStr(custom_padding, 1, length - StrLen(default_val)) . default_val
                }
            }

            left_custom_padding_string.Push(right_custom_padding_string*)
            
            return Format(this.format_string, kps, custom_kps_map.Get(kps, kps), left_custom_padding_string*)
        }
        else
        {
            return Format(this.format_string, kps, custom_kps_map.Get(kps, kps), kps, kps, kps, kps, kps, kps, kps, kps)
        }
    }

    equal(other)
    {
        return this.format_string == other.format_string
    }

    Clone()
    {
        new_object := CustomFormat()

        new_object.left_custom_padding := this.left_custom_padding.Clone()
        new_object.right_custom_padding := this.right_custom_padding.Clone()
        new_object.format_string := this.format_string
        new_object.orig_format := this.orig_format

        return new_object
    }

    ; Specification in doc/format_help.md
    ; The return value should be applied to Format()
    ; Format("{1:}{2:}", "a") -> "a{2:}"
    ; 1 is normal KPS, 2 is custom KPS,
    ; Pther numbers are for custom padding

    static from_format(input)
    {
        result := CustomFormat()
        result.orig_format := input

        input := StrReplace(input, "{", "{{")
        input := StrReplace(input, "}", "}}")
        regex_input := input
        regex_output := ""

        match := 0

        while pos := RegExMatch(regex_input, "S)(?>%(?:(-)?(\d+|=))?([dsxX]))", &match)
        {
            custom_padding_dir := 0
            pattern_output := ""

            if match[2] = "="
            {
                if match[1] ; pad left
                {
                    custom_padding_dir := 1
                }
                else ; pad right
                {
                    custom_padding_dir := 2
                }

                loop parse "sdxX"
                {
                    if match[3] == A_LoopField
                    {
                        numbering := 4 * custom_padding_dir + A_Index - 2
                        
                        if custom_padding_dir = 1
                        {
                            result.left_custom_padding[A_Index] := true
                        }
                        else
                        {
                            result.right_custom_padding[A_Index] := true
                        }
                    }
                }

                pattern_output := "{" numbering ":}"
            }
            else
            {
                flags := match[1] . match[2]
                numbering := 1

                if match[3] = "s"
                {
                    numbering := 2
                }
                else if match[3] = "x"
                {
                    flags .= match[3]
                }

                pattern_output := "{" numbering ":" flags "}"
            }

            regex_output .= Substr(regex_input, 1, pos - 1) . pattern_output
            regex_input := SubStr(regex_input, pos + StrLen(match[0]))
        }

        regex_output .= regex_input
        regex_input := ""

        regex_output := StrReplace(regex_output, "%%", "%")
        regex_output := StrReplace(regex_output, "\n", "`n")
        regex_output := StrReplace(regex_output, "\t", "`t")
        regex_output := RegExReplace(regex_output, "\\([`'`"\\])", "$1")

        result.format_string := regex_output

        return result
    }
}