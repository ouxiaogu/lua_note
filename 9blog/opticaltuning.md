# opticalTuning

## 1st optical tuning
  
### Init1

1). Input

|  terms      | meaning      
---           | ---
| OPTICAL\_TUNING\_INPUT\_BEST\_MODEL | a model directory
| OPTICAL\_TUNING\_INPUT\_BEST\_FOCUS | best focus value
| ADJUST\_WEIGHT | a table, it seems only have NMC cost_weight
| best\_model   | DM.get\_cal\_model(OPTICAL\_TUNING\_INPUT\_BEST\_MODEL) 
| best\_rst     | DM.get_ressit(best\_model) 
| best\_opt     | DM.get_exposure(best\_model) 
| best\_rst     | DM.get_masktemplate(best\_model) 
| MY_USETERM    | a table, composed by all the used resist term 
| MY_FIXED_PARAMETERS | fixed parameter will not be searched
| modelinfo     | resist, optical search algorithm selection
| MASKOPTIONS   | a.t.t. , Options
| tccoptions    | a.t.t. , Options
| resistoptions | a.t.t. , Options |

```lua
OPTICAL_TUNING_INPUT_BEST_MODEL = "/gpfs/PEG/FEM/peyang/data/training/prac/prac9/h/cache/dummydb/result/calibrate/job1/models/model14/"
OPTICAL_TUNING_INPUT_BEST_FOCUS = -0.06
ADJUST_WEIGHT = {
  G_ButtingIsoLEGap200W100_H  ={
    cost_wt = 0.21157861909454
  };
  G_ButtingDenceLEGap200W85 ={
    cost_wt = 0.21308516111304
  }; ...
}
MY_USETERMS = {   1 = cBp; 2 = cMG1; 3 = cMav; 4 = cAG1; 5 = cAm; 6 = cA;
  7 = cAp; 8 = cSlope; 9 = cMG2; 10  = cBn; 11  = cAG2 }
MY_VARIABLES = {
  aiBlur  ={
    attr  = optics
    range ={
      max = 0
      step  = 0.001
      min = 0 } };
  qtrFiltSizeAG1  ={
    attr  = resist
    range ={
      max = 9
      step  = 0.001
      min = 9 } };
  InnerCorner ={
    attr  = mask
    range ={
      max = 0
      step  = 0.001
      min = 0 } };
  ... 
};
MY_FIXED_PARAMETERS = {};
modelinfo = { 
  resistsearch  = simplex
  opticalsearch = brute } ;
maskoptions = {};
tccoptions = {};
resistoptions = {
  speedupSimplex  = 1 };
```

2). initialization ( user-defined and default hybrid  )

Q1 Analysis `modelselect.lua | adjust_resist_parameter function`: why input a "AG2" ?

```lua
adjust_resist_parameter = function(best_model, best_rst, my_variables, userTerms, inputTerms)
-- best_rst: best process resist; userTerms: from job settings; inputTerms: input from API.
--  local adjust, adjustIn = adjust_resist_parameter(best_model, best_rst, MY_VARIABLES, MY_USETERMS, "AG2")
```

2.1) sigma range constraint

EUV: load values in table *\model_form_range* in `autocal_def.lua`(define the global var of autoCal in this file) to load the search range setting;
DUV: use default settings as below:

Q1.1 why the type of logic : when findMG1 = false, then set MG2's constraint directly ?

```lua
-- draw a excel file
  local sigma_range_constraint =  {
  Bn  ={
    min = 0.035
    max = 0.3
  }
  MG1 ={
    min = 0.06
    max = 0.2
  }
  Am  ={
    min = 0.04
    max = 0.3
  }
  AG1 ={
    min = 0.06
    max = 0.26
  }
  MG2 ={
    min = 0.16
    max = 0.4
  }
  Bp  ={
    min = 0.035
    max = 0.3
  }
  AG2 ={
    min = 0.16
    max = 0.3
  }
  Ap  ={
    min = 0.04
    max = 0.3}
}
```
2.2) calrangeraw = my_variables

for key, value in pairs(calrangeraw) do

| Term |  Pattern | Meaning | Table Format
---|--- | --- | ---
| calrange   | find(key, "sigma") | sigma range | sigmaAG1 ={ attr = .. ; range = {}; }, ... 
| calrangetrunc | find(key, "ratio") | ratio range | b0n_ratio ={ attr = .. ; range = {} ;}, ...

2.3) bestTerms 

```lua
bestTerms["AG1"] = get_parameter_in_template_with_role_name(best_rst, "sigmaAG1")
--> the sigma value of the resist terms , e.g.
bestTerms = {   Bn  = 0.2; MG1 = 0.142638; Am  = 0.2; AG1 = 0.0770768;
  MG2 = 0.1; Bp  = 0.09; AG2 = 0.162021; Ap  = 0.1 }
```

2.5) userTerms

```
userTerms = MY_USETERM
```

3) range adjustment

3.1) bestTerms range adjust

Firstly, match the bestTerms with userTerms
Then, adjust the term range by the following rules, save the new range value into table *cache*

- rule 0: sigma is too small(30nm) or too big(400nm)
- rule 1: if term.sigma-Min or Max)<10nm, set Min=term.sigma-1/2*Range, Max=term.sigma+1/2*Range
- rule 2 : if term.sigma-20 and term.sigma+20 locate at (min,max), set (min,max)=(term.sigma-20, term.sigma+20)

all the adjusted range result are saved in table *adjust_target*

>**Note**
the  1st adjust targets of `adjust_resist_parameter`

3.2) bestTerms calrangetrunc adjust
- rule 3: reduce the truncation level search range to 1/2 if |max-min|>4*step, otherwise, fix the truncation level

>**Note**
the  2nd adjust targets of `adjust_resist_parameter`

3.3) binding validation stage: use inputTerms = "AG2" as an example
Q1.2 What the physical meaning of these binding range setting criteria ?

a). inputTerms == "AG2" , then define a associated table

```lua
list = { AG1, Ap, Bp  }
```
b). *hash_calrange* :result of exacting the sigma term from the *calrange* table 
 find the term from table *list* can be also found in the *hash_calrange* table
c). *search_range_array* :

- merge  {0, 0.04} , { hash\_calrange["AG1"].min ,max } , calrange["Ap"].min max, and calrange["Bp"].min max to generate a new table *search_range_array*
- descending sort *search_range_array*. by Min Value of the range
- if max of the current range is large than the min of the next range, then adjust *search_range_array*, current range set to (-1,-1 )

```lua
if(search_range_array[key][2] >= search_range_array[key+1][1])then
    local min = search_range_array[key][1]
    local max = math.max(search_range_array[key][2], search_range_array[key+1][2])
    search_range_array[key+1][1] = min
    search_range_array[key+1][2] = max
    search_range_array[key][1] = -1
    search_range_array[key][2] = -1
end
```

- table *index*: count the indexes of items in *search_range_array* which is not equal to (-1,-1) 
- traverse table *index*
  + <code>if #index == 1 and the-only-range.max < 0.25 </code>
    * <code>if the-only-range.max + + 0.005 > 0.06  then min = the-only-range.max + 0.005 </code>
    * <code>else min = 0.06 </code>
  + <code> else #index ~= 1 or the-only-range.max >= 0.25  </code>
    * traverse the *index*, <code>if range[index+1].min - range[index].max >= 0.03 then min = range[index].max-0.005; max = range[index + 1].min + 0.005 </code>

d) set the new *step*, *max*, *min* of the *inputTerms*,save the new range value into table *cache*

```
adjust_resist_parameter add sigmaAG2 into local cache
adjust_resist_parameter adjust_inputterms[sigmaAG2]: {min = 0.06, max = 0.11, step = 0.01}
```

e) if input term is truncation term , adjust the bo, bm, bn range by specific constraint

```lua
  local temp = {["Ap"] = "b0_ratio", ["Bp"] = "b0_ratio", ["Am"] = "b0m ratio", ["Bn"] = "b0n_ratio"}
```



Q1.3 Line 1367  of `modelselect.lua`,  what the usage of flag ?

```lua
if(false == flag)then
    min= search_range_array[index[key]][2] - 0.005
    max = search_range_array[index[key + 1]][1] + 0.005
else
    flag = true
end
```

3.4) table *cache*, which composed by all the new range of the adjusted terms.

```lua
--> adjust_resist_parameter local cache(all tuning resist parameters) is:
  sigmaAG2  ={
    max = 0.11
    step  = 0.01
    min = 0.06
  }
  sigmaMG2  ={
    max = 0.24
    step  = 0.005
    min = 0.2
  }
```

input is table *cache*, output is table *tmp_list*

- define a new AI MI diffusion effect term pair table <code>local opt_pair = {{"AG1", "AG2"}, {"MG1", "MG2"}}</code> 
- traverse table *opt_pair*'s value, i.e., the AI or MI Gaussian term pair
  + if AG1/AG2  existed in *calrange* (in resist form)
    * if AG1/AG2 existed in *cache*(have done adjust) then insert the term's sigma range into *tmp_list* from *cache* 
    * else   insert the term's sigma range into *tmp_list* from *calrange* 
  + else AG1/AG2 not existed in *calrange* (in resist form)
    * insert the term's sigma range into *tmp_list* from *cache* if existed
  + *tmp_list* result output log : <code> tmp_list = {0, 0.011, 0.06, 0.11} </code>
  +  sort *tmp_list* by ascending order, set the step by the first two value.<code> step = max{ 0.01, (sorted_tmp_list[2]-sorted_tmp_list[1])/5 }</code>
  +  update new range into table *adjust_target*

>**Note**
So far, the  final adjust targets of `adjust_resist_parameter` is setted




**function list**

- 1st optical tuning
  + Init1
  + Main1
  + Done1
- 2st optical tuning
  + Init2
  + Main2
  + Done2

**Appendix: utility functions**
1) `get_stage_result` : parse the xml file

```lua
get_stage_result = function(param)
    local xml = get_stage_results()
    if(xml ~= nil and xml ~= "")then
        if(xml[param] == nil)then
            return nil
        else
            return xml[param]
        end
    else
        return nil
    end
end
```

2). `adjust_gauge_weight`: autocal_weightinitialization.lua



