//+------------------------------------------------------------------+
//|                                                    EA_Grech6.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
// Include
#include <Trade\Trade.mqh>
CTrade *Trade;

// Setup Variables
input int InpMagicNumber = 2921;                        // unique identifier for this expert advisor
input string InpTradeComment = __FILE__;                // optional comment for trades
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // applied price for indicators

// Global Variables
string indicatorMetrics = "";          // will reset variable each time OnTick occurs.
int TicksReceivedCount = 0;            // counts the number of ticks from oninit function
int TicksProcessedCount = 0;           // counts the number of ticks processed from oninit function based off candle opens only
static datetime timeLastTickProcessed; // stored the last time a tick was processed based off candle opens only

//risk metrics
input bool riskCompounding        = false;  //use the compounded risk method or not
double startingEquity             = 0.0;    //starting equity
double currentEquityRisk          = 0.0;    //equity that will be risked per trade
double currentEquity              = 0.0;    //current equity
input double maxLossPercent       = 0.02;   //percent risk per trade
input double atrProfitMultiplier  = 2.0;    //atr profit multiple
input double atrLossMultiplier    = 1.0;    //atr loss multiple

//ATR variables and handle
int handleAtr;
int atrPeriod = 10;//Grech used 14, but said 10 makes sense for forex

// MACD variables and handle
int handleMacd;
int macdFast = 12;
int macdSlow = 26;
int macdSignal = 9;

// EMA variables and handle
int handleEma;
int EmaPeriod = 100;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  //--- create timer
  EventSetTimer(60);

  Trade = new CTrade();
  Trade.SetExpertMagicNumber(InpMagicNumber);

  //store starting equity onInit
  startingEquity = AccountInfoDouble(ACCOUNT_EQUITY);

  // set up the handle for atr indicator
  handleEma = iATR(Symbol(), Period(), atrPeriod);
  Print("Handle for ATR /", Symbol(), " / ", EnumToString(Period()), " successfully created.");

  // set up the handle for macd indicator
  handleMacd = iMACD(Symbol(), Period(), macdFast, macdSlow, macdSignal, InpAppliedPrice);
  // Print("Handle for MACD /", Symbol(), " / ", EnumToString(Period()), " successfully created.");

  // set up the handle for ema indicator
  handleEma = iMA(Symbol(), Period(), EmaPeriod, 0, MODE_EMA, InpAppliedPrice);
  //Print("Handle for EMA /", Symbol(), " / ", EnumToString(Period()), " successfully created.");

  Print("OnInit() has completed.");
  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  //--- destroy timer
  EventKillTimer();
  IndicatorRelease(handleAtr);
  Print("handleAtr has been released.");
  IndicatorRelease(handleMacd);
  Print("handleMacd has been released.");
  IndicatorRelease(handleEma);
  Print("handleEma has been released.");
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  //---

  // declare variables
  TicksReceivedCount++;

  // checks for a new candle
  bool isNewCandle = false;
  // iTime(Symbol(), Period(),0) gets the most current candle
  // if the last processed candle is not equal to iTime...
  if (timeLastTickProcessed != iTime(Symbol(), Period(), 0))
  {
    // there is a new candle
    isNewCandle = true;
    // set the last processed candle to the current candle
    timeLastTickProcessed = iTime(Symbol(), Period(), 0);
  }

  // if there is a new candle...
  if (isNewCandle == true)
  {
    // increment the processed count by 1
    TicksProcessedCount++; // counts the number of ticks that have been processed
    indicatorMetrics = ""; // will reset variable each time OnTick occurs.
    // begin building a new indicatorMetrics string
    StringConcatenate(indicatorMetrics, Symbol(), "|Last Processed: ", timeLastTickProcessed);

    //money management- ATR
    double currentAtr = GetAtrValue(); //gets ATR value double using custom function.  convert double to string as per symbol digits
    //add to the indicatorMetrics string
    StringConcatenate(indicatorMetrics, indicatorMetrics, "|ATR: ", currentAtr);
    //Print("currentAtr: " + currentAtr);

    //strategy trigger MACD
    string openSignalMacd = GetMacdOpenSignal(); // will return buy or sell on a crossover event
    //add to the indicatorMetrics string
    StringConcatenate(indicatorMetrics, indicatorMetrics, "|MACD bias: ", openSignalMacd);
    //Print("openSignalMacd: " + openSignalMacd);

    //strategy filter EMA
    string openSignalEma = GetEmaOpenSignal(); // will return buy or sell based on the ema line
    StringConcatenate(indicatorMetrics, indicatorMetrics, "|EMA bias: ", openSignalEma);
    // Print("openSignalEma: " + openSignalEma);

    //open trades
    if (openSignalMacd == "buy" && openSignalEma == "buy")
    {
      Print("ProcessTradeOpen(ORDER_TYPE_BUY)");
      ProcessTradeOpen(ORDER_TYPE_BUY, currentAtr);
    }
    else if (openSignalMacd == "sell" && openSignalEma == "sell")
    {
      Print("ProcessTradeOpen(ORDER_TYPE_SELL)");
      ProcessTradeOpen(ORDER_TYPE_SELL, currentAtr);
    }

    //for debugging
    //Print("New candle.  indicatorMetrics: " + indicatorMetrics);
  }

  // write out the comments section
  Comment(
      "\n\rExpert: ", InpMagicNumber, "\n\r",
      "MT5 Servertime: " + TimeCurrent(), "\n\r",
      "Ticks received: " + TicksReceivedCount, "\n\r",
      "Ticks processed: " + TicksProcessedCount, "\n\r\n\r",
      "Symbols Traded: \n\r",
      // Symbol(), "|", timeLastTickProcessed, "|", indicatorMetrics
      indicatorMetrics);
}
//+------------------------------------------------------------------+
//| Custom functions                                            |
//+------------------------------------------------------------------+

//get the ATR value
double GetAtrValue()
{
  // Print("GetMacdOpenSignal() has been called.");
  // set symbol string and indicator buffers
  string currentSymbol      = Symbol();
  const int startCandle     = 0;
  const int requiredCandles = 3; // how many candles are required to be stored in the EA, [prior, current confirmed, not confirmed]

  // indicator variables and buffers
  const int indexAtr  = 0;//atr value can be found in output buffer index 0
  double bufferAtr[];// will store the atr value for a copy.  prior, current confirmed, not yet confirmed

  // define atr, from not confirmed candle 0, for 3 candles and store the results
  bool fillAtr = CopyBuffer(handleAtr, indexAtr, startCandle, requiredCandles, bufferAtr);//copy buffer uses oldest as 0
  if(fillAtr == false)
    return "fillAtr buffer not yet loaded"; // if the buffers are not filled then return to end this onTick

  //find ATR value for candle 1 only with five decimals
  double currentAtr = NormalizeDouble(bufferAtr[1], 5);

  return currentAtr;
}
// custom function to get MACD signals
string GetMacdOpenSignal()
{
  //---

  // Print("GetMacdOpenSignal() has been called.");
  // set symbol string and indicator buffers
  string currentSymbol = Symbol();
  const int startCandle = 0;
  const int requiredCandles = 3; // how many candles are required to be stored in the EA, [prior, current confirmed, not confirmed]

  // indicator variables and buffers
  const int indexMacd = 0;   // macd line can be found in output buffer index 0
  const int indexSignal = 1; // signal line can be found in output buffer index 1
  double bufferMacd[];       // will store the macd value for a copy.  prior, current confirmed, not yet confirmed
  double bufferSignal[];     // will store the signal value for a copy.  prior, current confirmed, not yet confirmed

  // define macd and signal lines, from not confirmed candle 0, for 3 candles and store the results
  bool fillMacd = CopyBuffer(handleMacd, indexMacd, startCandle, requiredCandles, bufferMacd);
  bool fillSignal = CopyBuffer(handleMacd, indexSignal, startCandle, requiredCandles, bufferSignal);

  if (fillMacd == false || fillSignal == false)
    return "buffers not yet loaded"; // if the buffers are not filled then return to end this onTick

  // find the required macd signal lines and normalize them to 10 places to prevent rounding errors in crossovers
  double currentMacd = NormalizeDouble(bufferMacd[1], 10);
  double currentSignal = NormalizeDouble(bufferSignal[1], 10);
  double priorMacd = NormalizeDouble(bufferMacd[0], 10);
  double priorSignal = NormalizeDouble(bufferSignal[0], 10);

  //Print("priorMacd: " + priorMacd + "priorSignal: " + priorSignal);
  //Print("currentMacd: " + currentMacd + "currentSignal: " + currentSignal);

  //submit buy and sell trades

  //the prior macd is less than the prior signal AND
  //the current macd is greater than the current signal
  //basically, when the macd breaks above the signal
  if (priorMacd <= priorSignal && currentMacd > currentSignal && currentMacd < 0 && currentSignal < 0)
  {   
    //Print("GetMacdOpenSignal return buy. The MACD has crossed above the signal line.");
    return "buy";
  }
  //the prior macd is greater than the prior signal AND
  //the current macd is less than the current signal
  //basically, when the macd breaks below the signal
  else if (priorMacd >= priorSignal && currentMacd < currentSignal  && currentMacd > 0 && currentSignal > 0)
  {
    //Print("GetMacdOpenSignal return sell. The MACD has crossed below the signal line.");
    return "sell";
  }
  else
  {
    //openSignalMacd = "no trade";
    //Print("GetMacdOpenSignal return no trade");
    return "no trade";
  }
}

//custom function that returns buy, sell or no trade based off EMA and close price
string GetEmaOpenSignal()
{
  //Print("GetMacdOpenSignal() has been called.");
  //set symbol string and indicator buffers
  string currentSymbol = Symbol();
  const int startCandle = 0;
  const int requiredCandles = 2; // how many candles are required to be stored in the EA, [prior, current confirmed, not confirmed]

  //indicator variables and buffers
  const int indexEma = 0; // ema line can be found in output buffer index 0
  double bufferEma[];     // will store the ema value for a copy. current confirmed, not yet confirmed

  //define ema line, from not confirmed candle 0, for 2 candles and store the results
  bool fillEma = CopyBuffer(handleEma, indexEma, startCandle, requiredCandles, bufferEma);

  if (fillEma == false)
    return "buffers not yet loaded"; // if the buffers are not filled then return to end this onTick

  //find the required ema line and normalize it to 10 places to prevent rounding errors in crossovers
  double currentEma = NormalizeDouble(bufferEma[1], 10);
  double currentClose = NormalizeDouble(iClose(Symbol(), Period(), 0), 10);

  //open trades
  if(currentClose > currentEma) return ("buy");
  else if (currentClose < currentEma) return ("sell");
  else return ("no trade");
}

// process open trades for buy and sell
bool ProcessTradeOpen(ENUM_ORDER_TYPE orderType, double currentAtr)
{
  // set symbol string and variables
  string currentSymbol = Symbol();
  double price = 0;
  double stopLossPrice = 0;
  double takeProfitPrice = 0;

  if (orderType == ORDER_TYPE_BUY)
  {
    // the number of decimals differ among instruments
    price = NormalizeDouble(SymbolInfoDouble(currentSymbol, SYMBOL_ASK), Digits());
    //stopLossPrice = NormalizeDouble(price - (currentAtr * atrLossMultiplier), Digits());
    //takeProfitPrice = NormalizeDouble(price + (currentAtr * atrLossMultiplier), Digits());

    stopLossPrice = NormalizeDouble(price - currentAtr * atrLossMultiplier, Digits());
    takeProfitPrice = NormalizeDouble(price + currentAtr * atrProfitMultiplier, Digits());

    Print("price + currentAtr * atrProfitMultiplier: " + price + currentAtr * atrProfitMultiplier);
    Print("price: " + price);
    Print("currentAtr: " + currentAtr);
    Print("atrProfitMultiplier: " + atrProfitMultiplier); 
    Print("takeProfitPrice: " + takeProfitPrice);
    //Print("open buy");
  }
  else if (orderType == ORDER_TYPE_SELL)
  {
    price = NormalizeDouble(SymbolInfoDouble(currentSymbol, SYMBOL_BID), Digits());
    //stopLossPrice = NormalizeDouble(price + (currentAtr * atrLossMultiplier), Digits());
    //takeProfitPrice = NormalizeDouble(price - (currentAtr * atrLossMultiplier), Digits());

    stopLossPrice = NormalizeDouble(price + currentAtr * atrLossMultiplier, Digits());
    takeProfitPrice = NormalizeDouble(price - currentAtr * atrProfitMultiplier, Digits());

    Print("price + currentAtr * atrProfitMultiplier: " + price + currentAtr * atrProfitMultiplier);
    Print("price: " + price);
    Print("currentAtr: " + currentAtr);
    Print("atrProfitMultiplier: " + atrProfitMultiplier); 
    Print("takeProfitPrice: " + takeProfitPrice);

    //Print("open sell");
  }

  // get lot size
  //double lotSize = 1;
  double lotSize = OptimalLotSize(currentSymbol, price, stopLossPrice);

  // execute trades
  Print("Trade.PositionClose logic.");
  Trade.PositionClose(currentSymbol);
  
  Print("Trade.PositionOpen logic.");
  Trade.PositionOpen(currentSymbol, orderType, lotSize, price, stopLossPrice, takeProfitPrice, InpTradeComment);

  // add error handling
  return (true);
}

double OptimalLotSize (string currentSymbol, double entryPrice, double stopLoss)
{
  //set symbol string and calculate point value
  double tickSize   = SymbolInfoDouble(currentSymbol, SYMBOL_TRADE_TICK_SIZE);
  double tickValue  = SymbolInfoDouble(currentSymbol, SYMBOL_TRADE_TICK_VALUE);

  //this handles the special case of the japanese yen
  if (SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS) <= 3)
    tickValue = tickValue/100;

    double pointAmount    = SymbolInfoDouble(currentSymbol, SYMBOL_POINT);
    double ticksPerPoint  = tickSize / pointAmount;
    double pointValue     = tickValue / ticksPerPoint;

    //calculate risk based off entry and stop loss level by pips
    double riskPoints = MathAbs((entryPrice - stopLoss) / tickSize);

    //set risk model to fixed or compounding
    if (riskCompounding == true)
    {
      currentEquityRisk = AccountInfoDouble(ACCOUNT_EQUITY);
      currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    }
    else
    {
      currentEquityRisk = startingEquity;
      currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    }

    //calculate total risk amount in dollars
    double riskAmount = currentEquityRisk * maxLossPercent;
    //calculate lot size
    //double riskLots = NormalizeDouble(riskAmount / (riskPoints * pointValue), 2);
    double riskLots = NormalizeDouble(riskAmount / (riskPoints * pointValue), 10);

    //print values in the journal to check if operating correctly
    PrintFormat("tickSize: %f, tickValue: %f, pointAmount: %f, ticksPerPoint: %f, pointValue: %f,",
    tickSize, tickValue, pointAmount, ticksPerPoint, pointValue);
    PrintFormat("entryPrice: %f, stopLoss: %f, riskPoints: %f, riskAmount: %f, riskLots: %f,",
    entryPrice, stopLoss, riskPoints, riskAmount, riskLots);

    //return optimal lot size
    riskLots = 0.01;//forced to test a bug
    return riskLots;
}
