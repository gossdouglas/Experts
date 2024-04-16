//+------------------------------------------------------------------+
//|                                                     EA_Grech.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//Include
#include <Trade\Trade.mqh>
CTrade *Trade;

//Setup Variables
input int InpMagicNumber                  =2921;//unique identifier for this expert advisor
input string InpTradeComment              = __FILE__;//optional comment for trades
input ENUM_APPLIED_PRICE InpAppliedPrice  = PRICE_CLOSE;//applied price for indicators

//Global Variables
string indicatorMetrics = "";    //will reset variable each time OnTick occurs.
int TicksReceivedCount = 0;//counts the number of ticks from oninit function
int TicksProcessedCount = 0;//counts the number of ticks processed from oninit function based off candle opens only
static datetime timeLastTickProcessed;//stored the last time a tick was processed based off candle opens only

//MACD variables and handle
int handleMacd;
int macdFast   = 12;
int macdSlow   = 26;
int macdSignal = 9;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   
   Print("OnInit() has completed.");
   Trade = new CTrade();
   Trade.SetExpertMagicNumber(InpMagicNumber);
   
   //set up the handle for macd indicator
   handleMacd = iMACD(Symbol(), Period(), macdFast, macdSlow, macdSignal, InpAppliedPrice);
   //Print("Handle for MACD /", Symbol(), " / ", EnumToString(Period()), " successfully created.");
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
   IndicatorRelease(handleMacd);
   Print("handleMacd has been released.");
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   //declare variables
   TicksReceivedCount++;
   
   //checks for a new candle
   bool isNewCandle = false; 
   //iTime(Symbol(), Period(),0) gets the most current candle
   //if the last processed candle is not equal to iTime...
   if (timeLastTickProcessed != iTime(Symbol(), Period(),0))
   {
   //there is a new candle
   isNewCandle = true;
   //set the last processed candle to the current candle
   timeLastTickProcessed = iTime(Symbol(), Period(),0);
   }
   
   //if there is a new candle...
   if (isNewCandle == true) 
   {
   //increment the processed count by 1
   TicksProcessedCount++;//counts the number of ticks that have been processed
   indicatorMetrics = "";    //will reset variable each time OnTick occurs.
   //begin building a new indicatorMetrics string
   StringConcatenate(indicatorMetrics, Symbol(), "|Last Processed: ", timeLastTickProcessed);
   
   //strategy trigger MACD
   string openSignalMacd = GetMacdOpenSignal();//will return buy or sell on a crossover event
   //add to the indicatorMetrics string 
   StringConcatenate(indicatorMetrics, indicatorMetrics, "|MACD bias: ", openSignalMacd);
   
   //for debugging
   Print("New candle.  indicatorMetrics: " + indicatorMetrics);
   }
     
   //write out the comments section
   Comment(
         "\n\rExpert: ", InpMagicNumber, "\n\r",
         "MT5 Servertime: " + TimeCurrent(), "\n\r", 
         "Ticks received: " + TicksReceivedCount, "\n\r", 
         "Ticks processed: " + TicksProcessedCount, "\n\r\n\r", 
         "Symbols Traded: \n\r", 
         //Symbol(), "|", timeLastTickProcessed, "|", indicatorMetrics
         indicatorMetrics
   );  
  }
//+------------------------------------------------------------------+
//| Custom functions                                            |
//+------------------------------------------------------------------+
//custom function to get MACD signals
string GetMacdOpenSignal()
 {
//---

   //Print("GetMacdOpenSignal() has been called.");
   //set symbol string and indicator buffers
   string currentSymbol = Symbol();
   const int startCandle = 0;
   const int requiredCandles = 3;   //how many candles are required to be stored in the EA, [prior, current confirmed, not confirmed]
   
   //indicator variables and buffers
   const int indexMacd = 0;   //macd line can be found in output buffer index 0
   const int indexSignal =1;  //signal line can be found in output buffer index 1
   double bufferMacd[];       //will store the macd value for a copy.  prior, current confirmed, not yet confirmed
   double bufferSignal[];     //will store the signal value for a copy.  prior, current confirmed, not yet confirmed
   
   //define macd and signal lines, from not confirmed candle 0, for 3 candles and store the results
   bool fillMacd = CopyBuffer(handleMacd,indexMacd,startCandle,requiredCandles,bufferMacd);
   bool fillSignal = CopyBuffer(handleMacd, indexSignal,startCandle, requiredCandles, bufferSignal);
   
   if (fillMacd == false || fillSignal == false) return "buffers not yet loaded";//if the buffers are not filled then return to end this onTick
   
   //find the required macd signal lines and normalize them to 10 places to prevent rounding errors in crossovers
   double currentMacd = NormalizeDouble(bufferMacd[1], 10);
   double currentSignal = NormalizeDouble(bufferSignal[1], 10);
   double priorMacd = NormalizeDouble(bufferMacd[0], 10);
   double priorSignal = NormalizeDouble(bufferSignal[0], 10);
   
   //submit buy and sell trades
   if (priorMacd <= priorSignal && currentMacd > currentSignal)
   {
   //openSignalMacd = "buy";
   //Print("return buy");
   return "buy";
   } else if 
   (priorMacd >= priorSignal && currentMacd < currentSignal)
   {
   //openSignalMacd = "sell";
   //Print("return sell");
   return "sell";
   } else 
   {
   //openSignalMacd = "no trade";
   //Print("return no trade");
   return "no trade";
   }
   
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

