The format textbox allows you to format KPS display with the text of your input. This is typically used to add indicator (e.g., KPS: 7) but you are free to do whatever you want.  

The format text is composed of placeholders and arbitrary texts.

## Placeholder

The placeholders look like this: `%[flags][width]<type>`  
- `%s` is the placeholder for KPS.
- `%d` is `%s` except it does not use customized KPS.
- `%x` is `%d` except it display in hex in lower case.
- `%X` is `%x` but in upper case.

If you want `%` in the format text, use `%%`.  

For example, if KPS were 5 and the custom KPS for 5 is `V`:  
`KPS: %s` = `KPS: V`  
`%s%d`    = `V5`  
`%s%%`    = `V%`  

If KPS were 12:  
`%x` = `c`  
`%x` = `C`  

## Escape Character

You may use these [escape characters](https://en.wikipedia.org/wiki/Escape_character) in the format text:  
- `\n` line feed (i.e., new line)
- `\t` tabs
- `\\` literal `\`
- `\'` literal `'`
- `\"` literal `"`

## Flag and Width

The **flags** and **width** can be optionally used inside the placeholders.  
- `-` flag left aligns KPS. (By default KPS is right-aligned)  
- `0` flag pads with 0. 
- `c` flag pads with custom padding. 

You cannot combine `0` and `c` flag.

The width is a positive integer controlling the minimum width (number of characters) of KPS.  

If you are familiar with C programming language, it basically works like `printf()`.  

Note while there exist more escape characters, they are not supported unless explicitly stated.  

For example, if KPS were 10 and custom KPS is not specified:  
`%11s`  = `.........10`  
`%011s`  = `00000000010`  
`%-11s` = `10.........`

(Pretend the `.` is space :))

Note the width of KPS in this case is 2 because `10` 2 characters long. We specified the minimum width of KPS as 11, so 9 extra space are *padded* to KPS.  

Because we don't have custom KPS, `%d` and `%s` in this case is the same. If we specified a custom KPS for 10 to `Madeline`:  
`%11s`  = `...Madeline`  
`%011s`  = `000Madeline`  
`%-11s` = `Madeline...`  

`Madeline` is in place of %s while %d will look the same as the previous example.  