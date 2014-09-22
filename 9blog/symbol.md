###  symbols
1. `;` : optional
2. `'` and `""` : the same
3. `..` for string concatenating
4. `...` for  variable argument list 

#### keywords 

    and       break     do        else      elseif    end
    false     for       function  goto      if        in
    local     nil       not       or        repeat    return
    then      true      until     while

#### strings denote other tokens

    +     -     *     /     %     ^     #
    ==    ~=    <=    >=    <     >     =
    (     )     {     }     [     ]     ::
    ;     :     ,     .     ..    ...

#### literal strings

  '\a' (bell), '\b' (backspace), '\f' (form feed), '\n' (newline), '\r' (carriage return), '\t' (horizontal tab), '\v' (vertical tab), '\\' (backslash), '\"' (quotation mark [double quote]), and '\'' (apostrophe [single quote])

>long brackets
  + define an opening long bracket of level n as an opening square bracket followed by n equal signs
  + *open long bracket* 
    * level 0: [[ 
    * level 1: [=[
    * ....
  + *closed long bracket* 
    * level 1: ]=]
    * level 4: ]====]
  + *long literal* : begin with open long bracket , and end with closed bracket of the same level
    + can run for several lines
    * do not interpret any escape sequences
    * ignore long brackets of any other level
    * 
    
    ```
           a = [==[
           alo
           123"]==]
    ```
    





