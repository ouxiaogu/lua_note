# PLT30621, RTS: Make ILS Curve Smooth

##  Documentation History

| Name |  Remark | Date |
--- | --- | --- |
Peng-cheng | Initial draft | 2/12/2015
 | Reviewed |  
  | Approved   |


##  1.  User Scenario 

- In model product, the ILS curve is only an indicator of model performance on this gauge.  
- In iOPC & MO, Customer use RTS ILS curve to verify their result of iOPC, MO tuning or other solutions. 
- They will They may also care about the values "near" RI=Threshold, sometimes there's some difference between target and RI/AI contour.

The ticket created is PLT-30621 .

## 2. Successful criteria

1. The ILS curve look smooth
2. At evaluation point RI=thres, the ILS value difference between binary and GUI  should no larger than 1%. 

## 3.  Implement Suggestion

1. In all conditions, if cut line will generate *x* sampling points, extend the number of sampling points to _x+2*kernel_
2. If the length of cut line contain one or two RI=thresh critical points, then add the dense of sampling point in this area.
3. compute AILS & ILS , and do the smooth on AILS & ILS.

## 4. Scope of function

RTS

## 5. Influence of LMC/OPC/SMO

iOPC, MO. This ticket will not directly influence the procedure of iOPC,MO. But it will influence users' quality judgment on solutions like iOPC, MO and etc.
