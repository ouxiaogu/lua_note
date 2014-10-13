test = "int x; /* x */ int y; /* y */"
print(string.gsub(test, "/%*.*%*/", "<COMMENT>"))
-- int x; <COMMENT>  1
-- substitution "s x */ int y; /* y " all be regards as comment
print(string.gsub(test, "/%*.-%*/", "<COMMENT>"))
-- int x; <COMMENT> int y; <COMMENT> 2