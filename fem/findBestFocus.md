#FindBestFocus


[TOC]

---
## I. Key functions

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

just call the polyfit function. search defocus within (0.2,1.1)\*resist\_thickness with a step of 0.08\*resist\_thickness.

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
best\_focus_{final} = \frac {\sum\limits_i \left | a2_i  \right | \cdot best\_focus_i } {\sum\limits_i \left | a2_i  \right |}
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

## 5. DataFilter = function(x, raw_y)

```lua
-- parameters
-- all the data is about bossung curve
-- x: defocus
-- y: model_cd (but some it is contained in table named as _nils_) 
-- example of y: y = {"gauge_name" = {model_cd1, model_cd2, ..., model_cd12}}
{ isosp_1_20  ={
    1 = 55.275179826556
    2 = 57.842241431347
    ...
    12  = 57.56186180634
  } }
```

**Usage**:apply filters on gaugename[focus]=wafer_cd table

**Example**:
```lua
print_log("BestFocusFind: nils has "..get_length(y).." elements, they are: ", y)
print_log("BestFocusFind: defocus are: ", x)
local y_filtered, det = DataFilter(x, y)
```


##  Some Support Functions of DataFilter

### 5.1 findMax = function(table, s, e)

find the maximum value from the *start*  to *end* of the *table.*
convex or concave

### 5.2 judgeMax = function(table, s, e, part)

**Usage**: check whether the cd through defocus is a rigid convex upward curve

**algo**
cut from the global maximum: idx0=findMax(table, head, tail)
For index <- idx0-1 : head do
  tail = index
  idx_l = findMax( table, head, tail)
  if idx_l != tail then
    return false;
  end
end
For index <- idx0+1 : tail do
  head = index 
  idx_r = findMax( table, head, tail)
  if idx_r != head then
    return false;
  end
end
return true

```lua
judgeMax = function(table, s, e, part)
    if(s == e or s > e)then
        return true
    end
    local index = findMax(table, s, e)
    if(part == "left")then
        if(index == e)then
            return judgeMax(table, s, e-1, part)
        else
            return false
        end
    elseif(part == "right")then
        if(index == s)then
            return judgeMax(table, s+1, e, part)
        else
            return false
        end
    end
end
```
### 5.3 findMin = function(table, s, e)
likewise

### 5.4 judgeMin = function(table, s, e, part)
likewise


## II. Flow Analysis by Stages

Take GF 28nm RX as an example, FEM data: 7 focus condition, 2 off-dose condition.

### 1. AppStage of whole BestFocusFind autocal job
Compared to *DM.run_stage*, there is a hiding TccPrep option in *run_stage*.

```lua
run_stage = function(stagetype, stagename, stageoption, stageparam, tccprep)
    local date1, time1, clock1 = get_current_time(stagename.." starting...")
    if(tccprep == 1)then
        local debuginfo = _DEBUG_
        _DEBUG_ = 0
        local tccprepparam = {}
        tccprepparam["DistributeMode"] = "optics+fem_d"
        tccprepparam["AppInit"] = stageparam["AppInit"]
        tccprepparam["AppMain"] = "TccPrep"
        tccprepparam["keeptemptcc"] = 1 
        DM.run_stage(stagetype, stagename.."TccPrep", {}, tccprepparam)
        _DEBUG_ = debuginfo
    end
    DM.run_stage(stagetype, stagename, {}, stageparam)
    local date2, time2, clock2 = get_current_time(stagename.." finished...")
    print_user(stagename.." runtime ("..get_run_time(os.difftime(time2, time1))..")")
    outputResult(stagename.." runtime ("..get_run_time(os.difftime(time2, time1))..")")
end
```

>Note
  TccPrep stage computes TCCs. If don't set keeptemptcc = 1, TCCs computed by TccPrep stage will be invalid for later processing.
  >  1. Users must set keeptemptcc = 1 in dm_run_stage() in TccPrep.
  >  2. If users don't set it, next Main stage will compute TCCs again itself.

Stages in BestFocusFinder job Lua:
  
1. run_stage("fem+", "CheckSettings", {}, {AppInit = "CheckSettingInit", AppMain = "CheckSettingMain", AppDone = "CheckSettingDone"})
2. run_stage("fem+", "PreValidation", {}, {AppInit = "PreValidationInit", AppMain = "PreValidationMain", AppDone = "PreValidationDone"}, 1) ; (because no process as input baseline model)
3. run_stage("fem+", "BestFocusFind", {}, {AppInit = "BestFocusFindInit", AppMain = "BestFocusFindMain", AppDone = "BestFocusFindDone"}, 1)

### 2. TccPrep(AppMain) in BestFocusFindTccPrep stage

```lua
TccPrep = function()
    print_log("TccPrep works in BestFocusFind")
    conds = DM.get_cur_fem_conditions()
    tcctemplate = DM.get_exposure()
    masktemplate = DM.get_masktemplate()
    tccs = DM.compute_tcc(tcctemplate, conds, masktemplate)
    DM.add_fem_result(tccs)
end
```
**need to be continue....**

### 3. BestFocusFind stage
Aligning with the Host-Leaf hierarchy, there are 3 functions: BestFocusFindInit(AppInit), BestFocusFindMain(AppMain) and BestFocusFindDone(AppDone).

#### 3.1 BestFocusFindInit(AppInit)

**need to be continue....** Programming in Lua chapter 13
```lua
_G["SearchConstraintsFunc"] = SearchConstraintsFunc
_G["TccPrep"] = TccPrep
```
There are declaration in head:

```
local modname = "FINDBESTFOCUS"
local M={}
_G[modname]=M
_LOADED[modname]=M
setmetatable(M, {__index=_G})
setfenv(1, M)
```
**Usage**:

AppInit Save GUI settings and some LUA settings(such as TCCOPTIONS) to STAGE for later calibration work.
  1. AppInit executes on both host and leaves.
    1. STAGE executes on host, so binary must initialize the environments for STAGE. That's why AppInit executes on host.
      1. On host, when a STAGE starts, AppInit is called.
    2. SUBJOBS executes on leaves, some necessary information must be provided for the execution of SUBJOBs. That's why AppInit executes on leaves.
      1. On leaf, AppInit executes just once to build some cache so that later procs will reuse the cache, and no need to run AppInit again.

**Additional Action in BestFocusFind**
1. change searched variables: 
  - resist_thickness
  - defocus:
    + DUV: (0.2, 1.1, 0.08)
    + EUV: (-1.5, 2.5, 0.33)
2. if processid ~= nil
  -   

#### 3.2 BestFocusFindMain(AppMain) 


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

for gaugename, modelcd in pairs(refcd) do
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

Q2. the size of model\_cd Matrix  calculated in BestFocusFinder is 12X7 ai\_loc steps X conds), but only take the size of Matrix reduce to 12X1 by only take the NM condition, it seems 12X6XGauge_Num model\_cd computation is redundant, can we just compute the NMC gauge here? 

Q3. In DataFilter, why don't open filter 2?

```lua
  num1 = num1 + 1
  val["y"][i] = nil
  val["x"][i] = nil
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

## suggestion

1. *truncate* function , add 5 before division

```lua
truncate = function(a, n)
-- generally, can keep 3 more digital numbers
    if(a == nil)then return nil end
    if(n == nil)then n = 3 end
    local b = math.pow(10, n)
    a = math.floor(a*b) + 5 
    a = a/b
    return a
end
```

