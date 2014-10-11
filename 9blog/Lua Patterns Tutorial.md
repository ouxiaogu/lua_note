# Lua Patterns Tutorial
---
[TOC]

Lua patterns can match sequences of characters, where each character can be optional, or repeat multiple times. If you're used to other languages that have regular expressions to match text, remember that Lua's pattern matching is not the same: it's more limited, and has different syntax.

Reference


1. [the Lua manual on patterns](http://www.lua.org/manual/5.1/manual.html#5.4.1) , strongly recommended to read the manual on patterns, so you know everything it offers.
2. [pattern tutorial](http://lua-users.org/wiki/PatternsTutorial) in lua-user org wiki

## Introduction to patterns

```lua
> =string.find('banana', 'lua')
nil
> = string.find('banana', 'lua') -- 'lua' will not be found
nil
```
