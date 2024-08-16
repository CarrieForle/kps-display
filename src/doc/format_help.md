# Format KPS

## Starter

The format textbox allows you to format KPS display with the text of your input. This is typically used, for example to add an indicator ("KPS: 7" instead of just 7).

The following description applies to the format textbox in the program and in turn `format` of `[KPS]` section in the profiles.  

The format text is composed of **placeholders** and arbitrary texts. Placeholders are substituted as some values (typically KPS) by the program and accompanied with rest of the texts.  

## Placeholder

The placeholders are in the format: `%[flag][width]<type>`  

### Type
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

### Flag and Width

The **flags** and **width** can be optionally used inside the placeholders. You may combine multiple flags.
- `-` flag left aligns KPS. (By default KPS is right-aligned)  
- `0` flag pads with 0. 
- `=` flag pads with custom padding. 

If `-` flag is present, it **must** be specified in front of all the other flags.  

if `=` flag is present, `0` flag must not be used and width is not supported.

The width is a positive integer controlling the minimum length (number of characters) of KPS. If KPS is shorter than width, characters will be *padded* onto KPS. By default it's blank character but you can use flags to alter it.  

If you are familiar with C programming language, it basically works like `printf()`.  

For example, if KPS were 10 and custom KPS is not specified:  
`%11s`  = `.........10`  
`%011s`  = `00000000010`  
`%-11s` = `10.........`  

(Pretend the `.` is space :))  

Note the width of KPS in this case is 2 because `10` is two characters long. We specified the minimum width of KPS as 11, so 9 extra space are *padded* to KPS.  

Because we don't have custom KPS, `%d` and `%s` in this case is the same. If we specified a custom KPS for 10 to `Madeline`:  
`%11s`  = `...Madeline`  
`%011s`  = `000Madeline`  
`%-11s` = `Madeline...`  

`Madeline` is in place of `%s` while `%d` will look the same as the previous example.  

## Escape Character

You may use these [escape characters](https://en.wikipedia.org/wiki/Escape_character) in the format text:  
- `\n` line feed (i.e., new line)
- `\t` tabs
- `\\` literal `\`
- `\'` literal `'`
- `\"` literal `"`

Other other escape characters are not supported.

## Troubleshooting

> Padding doesn't work

In order for padding to work. *Width* must be provided so the program know how much should it pad.  

If you use custom padding flag i.e., `=` flag, be sure you provided custom padding in the profile.