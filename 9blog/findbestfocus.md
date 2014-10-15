#FindBestFocus


[TOC]

---
## functions

## 1. polyfit = function(n,y,x) 
- target equation 
$$y=a_0x+a_1x+a_2x^2+...+a_nx^n$$
- syntax

```lua
param = polyfit(n,y,x)
    -- n : highest order of the fitting polynomial
    -- y : table 1
    -- x : table 2
```

- e.g.
 
```lua
local coeff = polyfit(2, modelcd ,array_defocus)
```

- algorithm
1. [Least Squares Fitting--Polynomial](http://mathworld.wolfram.com/LeastSquaresFittingPolynomial.html)
2. [Gaussian Elimination](http://mathworld.wolfram.com/GaussianElimination.html)

- detail

1. math equations $X^TXa = X^Ty$ , 
  - here $x$ is table _cd_ , $y$ is table _defocus_, $X$ is a Vandermonde matrix, composed by table _x_
  -  the order of matrix $X$ is $(n+1)*1$; $length$ is  length of the table x & y
  - element in matrix $X$ is $X[i][j] = x_i^{j-1}$
  - let $A=X^TX$ , $B = X^Ty$, then $Aa=B$
   $$ \\A[i][j]= \sum\limits_{k=1}^{length} x_k^{i+j-2}
      \\B[i] = \sum\limits_{j=1}^{length} x_j^{i-1}*y_j $$
  - slightly difference , add a translate matrix $M$(as below), $M^TM=I$, so $X^TXa = X^Ty$ just equal to $X^TXMMa = X^Ty$ , $A'=X^TXM$, and new solution $b=Ma$, it elements are in  descending order, in other saying, $b[0]=a_n, b[1]=a_{n-1}, ... $  $$ M = \begin{bmatrix}
 &  &  &1 \\ 
 &  &1  & \\ 
 &...  &  & \\ 
 1&  &  & 
\end{bmatrix}$$

2. code

1). gen the element a matrix x yx

```lua
x_power[i] = x_power[i]+x[j]^i
yx_power[i] = yx_power[i]+(x[j]^i) * y[j]
```
2). gen the element a matrix x yx

```lua
matrix[i][j]=x_power[i+n-j] -- i=0,n ; j=0,n
matrix[i][n+1]=yx_power[i] -- the n+1 column 
```
3) Gaussian elimination

```lua
  --> Find row with the largest first value
  maxrow = j 
  --> Swap the maxrow and current  number on the diagonal line (lower triangular)
  matrix[i] = matrix[maxrow] 
  --> Eliminate elements right under this diagonal number.
  matrix[j][k] = matrix[j][k] +(-matrix[i][k]*matrix[j][i])/matrix[i][i]
  --> solve the coefficient 
  param[n] = matrix[n-1][n]/matrix[n-1][n-1]
  param[j+1] = (matrix[j][n]-tmp2)/matrix[j][j]
```  

## 2. BestFocusFinder = function(array\_defocus, table\_cd)

just call the polyfit function.

```lua
local coeff = polyfit(2, modelcd ,array_defocus) 
```
e.g BestFocusFind: focus and modelcd have already match in pairs, no need to sort.

```lua
defocus= {
  1 = -0.0898 
  2 = -0.0746
  3 = -0.105  -- max
  4 = -0.067
  5 = -0.0974 
  6 = -0.0594
  7 = -0.0822
  8 = -0.0366
  9 = -0.029
  10  = -0.0518
  11  = -0.0442
  12  = -0.0214 -- min }
modelcd["pitch_04A7_K13_1"]  ={
    1 = 57.610888128349
    2 = 60.373536531325
    3 = 52.86956348621
    4 = 61.193338152629
    5 = 55.542777748938
    6 = 61.698385385156
    7 = 59.18767814208
    8 = 61.486699559403
    9 = 60.83451361824
    10  = 61.907097243666
    11  = 61.838938598972
    12  = 59.85134113905
  }
```

Very confused with its costfunction to calculate bestfocus of all gauge : 

```lua
for gaugename,modelcd in pairs(table_cd) do
    local coeff = polyfit(2, modelcd ,array_defocus)
    local a =0
    a = coeff[1]
    a = math.abs(a)
    if (coeff[1] ~= 0 and coeff[2]~=nil and coeff[1]~=nil) then
        bestfocus[gaugename] = -coeff[2]/(2*coeff[1])
        temp_def_a = temp_def_a + a*bestfocus[gaugename]
        temp_sum_a = temp_sum_a + a
    end
end
local final_bestdefocus = temp_def_a/temp_sum_a
final_bestdefocus = truncate(final_bestdefocus)
```

translate into equations:
$$
\\f(x)=a0 + a1 \cdot x + a2 \cdot x^2
\\best\_focus = -\frac {a1}{2 \cdot  a2}
$$

$$
best\_focus_{final} = \frac {\sum\limits_i \left | a1_i  \right | \cdot best\_focus_i } {\sum\limits_i \left | a1_i  \right |}
$$

## 3. FocusShiftFinder = function(wafer\_cd, conds)

1. data structure

(1). table *wafer_cd*
```lua
wafer_cd={
  pitch_23_6  = 108.851
  isoLend_10A7_Y27_1++@2  = 136.230155
  isoLend_10A7_S27_1++@1  = 61.374789
  pitch_04A7_B13_1++@5  = 62.67901
  isosp_09A7_O26_1++@5  = 497.600231
  twoT_17A8_S10_1++@4 = 69.291171 ...}
```
Generally, { key = gaugename.."++@"..condvecid, val = wafercd}, but NM condition have no "++@"..condvecid postfix .

(2). table *condAllParams* -> table *params*

```lua 
condAllParams = {
  params = { 
              { condvecid = 0,
                params = {defocus = 0
                          dose  = 0} 
              { condvecid = 1,
                params = {defocus = -0.015
                          dose  = 0} 
            } 
  haseFunc = false/true,
  ...
}
```

only use table *condAllParams* find the corresponding condition description of condvecid .

(3). read focus and dose , write the polyfit data table _wcd_ by conditions and skip those conditions with *dose != 0*

```lua
if(dose < -0.000001 or dose > 0.000001)then
    skip = true
end
```

For those skip = false gauge, insert them into table _wcd_

```lua
table.insert(wcd[mykey], {["defocus"] = defocus, ["wcd"] = val})
```

(4). _wcd_ data validation

```lua
wcd = {
  gaugename = { defocus = val1, wcd = val2} ,
  ...
}
```

in validate _wcd_ stage, firstly sort _wcd_ by val["defocus"] in ascending order

```lua
table.sort(val, cmpByDef)
```
then, remove the duplicate _wcd_ item

```lua
for i = 1,num-1 do
  if(val[i]["defocus"] == val[i+1]["defocus"]) then
    val[i] = nil
  end
end
```
at last, the _wcd_ item is valid after it meet the final rule : **`#(wcd[gaugename]) >= 4`**

```lua
if(get_length(val) < 4)then
            wcd[key] = nil end
```

(5). do the  polyfit

FocusShiftFinder  polyfit(2, wcd , defocus)

```lua
local coeff = polyfit(2, y, x)
```

e.g. FocusShiftFind: for gauge 'pitch_04A7_K13_1',

```lua
x = {   1 = -0.045
        2 = -0.03
        3 = -0.015
        4 = 0
        5 = 0.015
        6 = 0.03
        7 = 0.045 }
y = {   1 = 59.16074
        2 = 60.525337
        3 = 61.283071
        4 = 61.060977
        5 = 59.89526
        6 = 59.012457
        7 = 57.458394}
```

Also confused with the equation to calculate the focusShift of all gauges like BestFocusFinder().

## 4. computeDOF = function(cd, rate, neg, pos)

input
```lua
--> cd   ( modelcd at dose=0)
cd = { 
  pitch_25_0  ={
      1 ={
        defocus = -0.105
        mcd = 297.04970573858
      }
      2 ={
        defocus = -0.0974
        mcd = 298.33315650756
      }
      ...
      12  ={
        defocus = -0.0214
        mcd = 300.2301715173
      }
    }
  ...
}

--> rate : ?
--> neg : ?
--> pos : ?
```

Then, use table _cd_ val["defocus"] & val["mcd"] to do polyfit. and calculate the DOF use several criteria based on the circumstance .

```lua
coef = polyfit(2, y_array[key], x_array)
bestx = -b/(2*a) ;  besty = a*(bestx*bestx) + b*bestx + c ; 
esty = besty*(1+r) 
dof[key] = math.abs(((b*b - 4*a*(c-esty))^0.5) / a)
```

## 5. done = function()

Read Result or wafer cd
BestFocusFinder 
FocusShiftFinder 


Q1. why model cd have strange names _nils_, its meaning ?
    -- cd ; wafercd ; aicd
    -- ails
    -- pdcd - "allowedPositiveDeltaCD";  ndcd - "allowedNegetiveDeltaCD"
    -- ### ??? Q11 : pdcd, ndcd is R3D ?
    -- refils nils

``` lua
refcd = DM.get_result_table(result, "cd1")
refils = DM.get_result_table(result, "ils")

for gaugename,modelcd in pairs(refcd) do
  table.insert(nils[gaugename],modelcd)
end
```
``` lua
--> defocus_array
defocus_array = {
  isosp_1_20  = -0.05
  isoSend_102_6 = -0.051
  twoline_01A8_C9_1 = -0.044
  ...
}
``` 
**appendix A： function list**

- polyfit = function(n,y,x) 
- BestFocusFinder = function(array_defocus, table_cd)
- FocusShiftFinder = function(wafer_cd, conds)
- computeDOF = function(cd, rate, neg, pos)
- Init = function()
- Main = function()
- cmpByDef = function(a, b)
- Done = function()

**appendix B：key utility function used in this stage**

1). **`truncate`** function in *`autocal_util.lua`* :  keep 3 digits after the decimal point

```lua
truncate = function(a, n)
-- generally, can keep 3 more digital numbers
    if(a == nil)then return nil end
    if(n == nil)then n = 3 end
    local b = math.pow(10, n)
    a = math.floor(a*b)
    a = a/b
    return a
end
```

2). **`get_length`** function in *`autocal_util.lua | "autocal_def.lua | autocal_algo.lua`* 

```lua
get_length = function(t)
    if("table"==type(t))then
        local n = 0
        for key,val in pairs(t)do
            n = n + 1
        end
        return n
    elseif("string" == type(t))then
        return string.len(t)
    else
        return 0
    end
end
```