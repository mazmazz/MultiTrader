//+------------------------------------------------------------------+
//|                                            MMT_Helper_Filter.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://www.mql5.com"
#property strict

int GetMaxCheckMode(int &checkModeList[]) {
    int maxValueId = ArrayMaximum(checkModeList);
    
    if(maxValueId < 0) { return -1; }
    else { return checkModeList[maxValueId]; }
}