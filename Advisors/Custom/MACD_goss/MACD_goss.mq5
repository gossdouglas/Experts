//+------------------------------------------------------------------+
//|                                                    MACD_goss.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  //cretaing an array for prices for MACD main line
   double MACDMainLine[];
   
   //Defining MACD and its parameters
   int MACDDef = iMACD(_Symbol,_Period,12,26,9,PRICE_CLOSE);
   int MACDDef2 = iMACD(_Symbol,_Period,40,85,9,PRICE_CLOSE);
   int MACDDef3 = iMACD(_Symbol,_Period,80,120,9,PRICE_CLOSE);
   int MACDDef4 = iMACD(_Symbol,_Period,78,135,9,PRICE_CLOSE);
   
   //Sorting price array from current data
   ArraySetAsSeries(MACDMainLine,true);
   
   //Storing results after defining MA, line, current data
   CopyBuffer(MACDDef,MAIN_LINE,1,3,MACDMainLine);
   CopyBuffer(MACDDef2,MAIN_LINE,1,3,MACDMainLine);
   CopyBuffer(MACDDef3,MAIN_LINE,1,3,MACDMainLine);
   CopyBuffer(MACDDef4,MAIN_LINE,1,3,MACDMainLine);
   
   
   //Get values of current data
   float MACDMainLineVal = (MACDMainLine[0]);
   
   //Commenting on the chart the value of MACD
   if (MACDMainLineVal>0)
   Comment("Bullish Setup As MACD MainLine is ",MACDMainLineVal);
   
   if (MACDMainLineVal<0)
   Comment("Bearish Setup As MACD MainLine is ",MACDMainLineVal);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
//---
   
  }
//+------------------------------------------------------------------+
