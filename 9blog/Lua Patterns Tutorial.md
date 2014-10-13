# Lua Patterns Tutorial
---
[TOC]

Lua patterns can match sequences of characters, where each character can be optional, or repeat multiple times. If you're used to other languages that have regular expressions to match text, remember that Lua's pattern matching is not the same: it's more limited, and has different syntax.

Reference

1. [the Lua manual on patterns](http://www.lua.org/manual/5.1/manual.html#5.4.1) , strongly recommended to read the manual on patterns, so you know everything it offers.
2. [Programing in Lua](http://www.lua.org/pil/20.2.html) 20.2 pattern
3. [pattern tutorial](http://lua-users.org/wiki/PatternsTutorial) in lua-user org wiki

## Introduction to patterns

First, we will use the string.find function, which finds the first occurrence of a pattern in a string and returns start and end indices of the first and last characters that matched the text:
```lua
> = string.find('banana', 'an') -- find 1st occurance of 'an' (letters are matched literally) , return first and last indice of the matched char 
2       3
> = string.find('banana', 'lua') -- 'lua' will not be found
nil
```

However ,when you not know the explicit word to find , the _character classes_ begin to take its effort.  A _character class_ is a pattern that matches one of a set of characters.
```lua
> = string.find("abcdefg", 'b..')
2 4
```

Here, pattern `b..` define a _character class_ that start with `b` and `..` matches two chars with any type . The semanteme of this pattern can be seen more clearly in _string.match_.

### 1. `%` identify 

_table 1. `%` to identify the class_

| pattern    |  meaning      
 ------      | -------       
|  %a        | letters        
|  %c        | control characters 
| %d  | digits     
| %l  | lower case letters 
| %p  | punctuation characters(标点) 
| %s  | space characters 
| %u  | upper case letters 
| %w  | alphanumeric characters 字母数字类型 
| %x  | hexadecimal digits 
| %z  | the character with representation 0 |

>note

> -  `%´ works as an escape for those magic characters, e.g. _%._ matches a dot 
> -  _%_ can only be as an escape when pattern is used as function. otherwise , using _/_ as usual escape character
> - An upper case version of any of those classes represents the complement of the class.
> - e.g. `%A` is complement of `%a`, matches character of non letter 

```lua
 print(string.gsub("hello, up-down!", "%A", "."))
      --> hello..up.down. 4
```
string.gsub(s, pattern, replace [, n]) 
it can replace all instances of the _pattern_ provided with the _replacement_ .
its return value is [s' , n], the new string and the total number of substitutions.

### 2. magic characters
```lua
 ( ) . % + - * ? [ ^ $
```
_table 2. magic characters list_

| pattern    |  meaning      
 ------      | -------       
| .   | can represent for a char of all type
| %   | an escape when have an magic character in pattern
| []  | _char-set_,  e.g. '[01]' matches binary digits
| -   | range, e.g. '[0-9]' equals '%d', `[0-9a-fA-F]' : '%x', '[0-9a-zA-Z]': '%w' 
| ^   | the complement of any char-set , e.g. [^0-7] find any character that is not an octal digit 
| +   | 1 or more repetitions
| *   | 0 or more repetitions, matching the longest sequence
| -   | also 0 or more repetitions , matching the shortest sequence
| ?   | optional (0 or 1 occurrence)
| ^   | it will match only at the beginning of the subject string
| $   | it will match only at the end of the subject string
| %b  | which matches balanced strings, typically used to detect delimiters '%b()', '%b[]', '%b{}', or `%b<>'|

Then , I will give some useful examples,
- `[_%a][_%w]*`:  matches identifiers in a Lua program: a sequence starting with a letter or an underscore, followed by zero or more underscores or alphanumeric characters.
- `[_%a][_%w]*`: you will find only the first letter, because the `[_%w]-` will always match the empty sequence
- `/%*.*%*/` v.s. `/%*-*%*/` : the 1st find the longest part start from `/*`  end with `*/`, is not what we wanted , but the 2nd just find the first `*/` as the end.

```lua
test = "int x; /* x */ int y; /* y */"
print(string.gsub(test, "/%*.*%*/", "<COMMENT>"))
-- int x; <COMMENT>  1
-- substitution "s x */ int y; /* y " all be regards as comment
print(string.gsub(test, "/%*.-%*/", "<COMMENT>"))
-- int x; <COMMENT> int y; <COMMENT> 2
```
- <code>if string.find(s, "^%d") then ...</code> checks whether the string s starts with a digit, <code> if string.find(s, "^[+-]?%d+$") then ... </code> checks whether this string represents an integer number, without other leading
or trailing characters.
- balanced string "%b"

```lua
s = "a (enclosed (in) parentheses) line"
print(string.gsub(s, "%b()", "")) 
--> a line
```