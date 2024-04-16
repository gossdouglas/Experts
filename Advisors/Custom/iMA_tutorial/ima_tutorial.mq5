//+------------------------------------------------------------------+
//|                                                 ima_tutorial.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

int HandleMACD;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  int fastPeriod = 12;
  int slowPeriod = 26;
  int signalPeriod = 9;

  HandleMACD = iMACD(Symbol(), Period(), fastPeriod, slowPeriod, signalPeriod, PRICE_CLOSE);


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
   IndicatorRelease(HandleMACD);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double macdBuffer[];
   double signalBuffer[];
   int macdNumber = 0;
   int signalNumber =1;
   int count;
   int required = 2;
   int start = 1;

   count = CopyBuffer(HandleMACD, macdNumber, start, required, macdBuffer);
   if (count<required) return;
   count = CopyBuffer(HandleMACD, signalNumber, start, required, signalBuffer);
   if (count<required) return;
   
   // Detect new bar condition
      static datetime dtBarCurrent  = WRONG_VALUE;
             datetime dtBarPrevious = dtBarCurrent;
                      dtBarCurrent  = (datetime) SeriesInfoInteger( _Symbol, _Period, SERIES_LASTBAR_DATE );
             bool     bBarNew       = ( dtBarCurrent != dtBarPrevious );

   // Execute only on a new bar condition
      if(bBarNew)
      {
         // Do something here
         //Print("macdBuffer[0]:" + NormalizeDouble(macdBuffer[0], 6) + " signalBuffer[0]:" + NormalizeDouble(signalBuffer[0], 6));
         //Print("macdBuffer[1]:" + NormalizeDouble(macdBuffer[1], 6) + " signalBuffer[1]:" + NormalizeDouble(signalBuffer[1], 6));
         
         
         if ((macdBuffer[0] < 0) && (macdBuffer[1] > 0)) {
         Print("Upward cross.");
         Print("macdBuffer[0]:" + NormalizeDouble(macdBuffer[0], 6));
         Print("macdBuffer[1]:" + NormalizeDouble(macdBuffer[1], 6));
         }      
      };      
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
