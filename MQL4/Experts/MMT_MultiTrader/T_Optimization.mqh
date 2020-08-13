//+------------------------------------------------------------------+
//|                                               T_Optimization.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

#include <MC_Common/MC_MultiSettings.mqh>

//+------------------------------------------------------------------+

input string Lbl_Opt = "********** Optimization Values **********"; // :
//#ifdef __MQL4__
input string Lbl_Opt_Info = "Set start/step/stop below for the setting index"; // Notation [value]@[index]
//#else
//#ifdef __MQL5__
//input string Lbl_Opt_Info0 = "Set start/step/stop in the notation or the below index"; // Notation [value]@[index]
//input string Lbl_Opt_Info1 = "The below values are ignored when specifying in the notation"; // or [value]@[index],[start],[step],[stop]
//#endif
//#endif
//input string Lbl_Opt_Info2 = "These values have no effect outside of optimization mode"; // :
input string Opt_0_Comment = "";
input double Opt_0 = 0.0;
input string Opt_1_Comment = "";
input double Opt_1 = 0.0;
input string Opt_2_Comment = "";
input double Opt_2 = 0.0;
input string Opt_3_Comment = "";
input double Opt_3 = 0.0;
input string Opt_4_Comment = "";
input double Opt_4 = 0.0;
input string Opt_5_Comment = "";
input double Opt_5 = 0.0;
input string Opt_6_Comment = "";
input double Opt_6 = 0.0;
input string Opt_7_Comment = "";
input double Opt_7 = 0.0;
input string Opt_8_Comment = "";
input double Opt_8 = 0.0;
input string Opt_9_Comment = "";
input double Opt_9 = 0.0;
input string Opt_10_Comment = "";
input double Opt_10 = 0.0;
input string Opt_11_Comment = "";
input double Opt_11 = 0.0;
input string Opt_12_Comment = "";
input double Opt_12 = 0.0;
input string Opt_13_Comment = "";
input double Opt_13 = 0.0;
input string Opt_14_Comment = "";
input double Opt_14 = 0.0;

void LoadOptimizationValues() {
    MultiSettings::PrepareRedirects(10);
    MultiSettings::LoadRedirect(0, Opt_0);
    MultiSettings::LoadRedirect(1, Opt_1);
    MultiSettings::LoadRedirect(2, Opt_2);
    MultiSettings::LoadRedirect(3, Opt_3);
    MultiSettings::LoadRedirect(4, Opt_4);
    MultiSettings::LoadRedirect(5, Opt_5);
    MultiSettings::LoadRedirect(6, Opt_6);
    MultiSettings::LoadRedirect(7, Opt_7);
    MultiSettings::LoadRedirect(8, Opt_8);
    MultiSettings::LoadRedirect(9, Opt_9);
    MultiSettings::LoadRedirect(10, Opt_10);
    MultiSettings::LoadRedirect(11, Opt_11);
    MultiSettings::LoadRedirect(12, Opt_12);
    MultiSettings::LoadRedirect(13, Opt_13);
    MultiSettings::LoadRedirect(14, Opt_14);
}