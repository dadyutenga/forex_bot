//+------------------------------------------------------------------+
//|                                                   APABot_v1.mq5   |
//|                                     APA Trading System v1.0       |
//+------------------------------------------------------------------+
#property copyright "APA Trading System"
#property link      ""
#property version   "1.00"
#property strict

#include <APABot/MarketStructure.mqh>
#include <APABot/SwingPoints.mqh>
#include <APABot/TradeManager.mqh>
#include <APABot/RiskManager.mqh>
#include <APABot/VisualManager.mqh>

input group "=== GENERAL SETTINGS ==="
input int                MagicNumber = 100001;
input string             TradeComment = "APA_Bot_v1";
input bool               EnableLogging = true;

input group "=== TIMEFRAME SETTINGS ==="
input ENUM_TIMEFRAMES    HTF_Timeframe = PERIOD_D1;
input ENUM_TIMEFRAMES    EntryTimeframe = PERIOD_M15;

input group "=== STRATEGY SELECTION ==="
input bool               EnableAPA = true;
input bool               EnableCHOCH = true;
input bool               EnableHiddenStructure = false;
input bool               EnableTopDown = false;

input group "=== RISK MANAGEMENT ==="
input double             RiskPercent = 1.0;
input double             MaxSpreadPips = 3.0;
input int                MinTP_Pips = 20;
input double             RiskRewardRatio = 2.0;
input double             MaxDailyLoss = 3.0;
input double             StopLossBufferPips = 5.0;

input group "=== STRUCTURE DETECTION ==="
input int                SwingLookback = 20;
input int                MinSwingStrength = 3;
input double             MinStructureDistance_Pips = 10;

input group "=== ENTRY FILTERS ==="
input bool               RequireCandleConfirmation = true;
input int                ConfirmationCandles = 1;
input bool               UseVolumeFilter = false;
input int                MinVolume = 1000;

input group "=== EXIT MANAGEMENT ==="
input bool               UseTrailingStop = false;
input double             TrailingStart_Pips = 20;
input double             TrailingStep_Pips = 10;
input bool               UsePartialTP = false;
input double             PartialTP_Percent = 50;
input double             PartialTP_RR = 1.0;

input group "=== VISUAL SETTINGS ==="
input bool               EnableVisuals = true;
input color              ColorBuySignal = clrGreen;
input color              ColorSellSignal = clrRed;
input color              ColorStructure = clrYellow;
input int                LineWidth = 2;

CMarketStructure        *htfStructure = NULL;
CMarketStructure        *ltfStructure = NULL;
CTradeManager           *tradeManager = NULL;
CRiskManager            *riskManager = NULL;
CVisualManager          *visualManager = NULL;

bool                    isInitialized = false;
datetime                lastBarTime = 0;
int                     tradesToday = 0;
double                  dailyPL = 0.0;
datetime                lastTradeTime = 0;
double                  lastEntryPrice = 0.0;

int OnInit() {
    Print("=== Initializing APA Bot v1.0 ===");
    
    if(!ValidateInputs()) {
        Print("ERROR: Invalid input parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    htfStructure = new CMarketStructure(_Symbol, HTF_Timeframe, SwingLookback, MinSwingStrength, MinStructureDistance_Pips);
    ltfStructure = new CMarketStructure(_Symbol, EntryTimeframe, SwingLookback, MinSwingStrength, MinStructureDistance_Pips);
    tradeManager = new CTradeManager(MagicNumber, _Symbol, UseTrailingStop, TrailingStart_Pips, TrailingStep_Pips,
                                      UsePartialTP, PartialTP_Percent, PartialTP_RR);
    riskManager = new CRiskManager(_Symbol, RiskPercent, MaxSpreadPips, MinTP_Pips, RiskRewardRatio, StopLossBufferPips);
    visualManager = new CVisualManager(_Symbol, EnableVisuals, ColorBuySignal, ColorSellSignal, ColorStructure, LineWidth);
    
    if(!htfStructure.Initialize() || !ltfStructure.Initialize()) {
        Print("ERROR: Failed to initialize market structure");
        return INIT_FAILED;
    }
    
    if(!tradeManager.Initialize() || !riskManager.Initialize()) {
        Print("ERROR: Failed to initialize trade/risk manager");
        return INIT_FAILED;
    }
    
    if(!visualManager.Initialize()) {
        Print("ERROR: Failed to initialize visual manager");
        return INIT_FAILED;
    }
    
    EventSetTimer(60);
    
    LoadState();
    
    isInitialized = true;
    Print("=== Initialization Complete ===");
    
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    Print("=== Deinitializing APA Bot ===");
    
    SaveState();
    
    if(CheckPointer(htfStructure) == POINTER_DYNAMIC) delete htfStructure;
    if(CheckPointer(ltfStructure) == POINTER_DYNAMIC) delete ltfStructure;
    if(CheckPointer(tradeManager) == POINTER_DYNAMIC) delete tradeManager;
    if(CheckPointer(riskManager) == POINTER_DYNAMIC) delete riskManager;
    if(CheckPointer(visualManager) == POINTER_DYNAMIC) delete visualManager;
    
    EventKillTimer();
    
    Print("=== Deinitialization Complete ===");
}

void OnTick() {
    if(!isInitialized) return;
    
    if(!IsNewBar(EntryTimeframe)) return;
    
    if(EnableLogging) {
        Print("OnTick: New bar detected on ", EnumToString(EntryTimeframe));
    }
    
    htfStructure.Update();
    ltfStructure.Update();
    
    if(CheckDailyLossLimit()) {
        if(EnableLogging) Print("Daily loss limit reached. Trading suspended.");
        return;
    }
    
    if(tradeManager.HasOpenPosition()) {
        ManageOpenPosition();
        return;
    }
    
    if(EnableAPA) {
        CheckAPASetup();
    }
    
    if(EnableCHOCH) {
        CheckCHOCHSetup();
    }
    
    if(EnableHiddenStructure) {
        CheckHiddenStructureSetup();
    }
    
    if(EnableTopDown) {
        CheckTopDownSetup();
    }
    
    if(EnableVisuals) {
        UpdateVisuals();
    }
}

void OnTimer() {
    if(!isInitialized) return;
    
    tradesToday = 0;
    dailyPL = 0;
}

bool IsNewBar(ENUM_TIMEFRAMES tf) {
    datetime currentBarTime = iTime(_Symbol, tf, 0);
    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

bool ValidateInputs() {
    if(RiskPercent <= 0 || RiskPercent > 10) return false;
    if(SwingLookback < 5) return false;
    if(MinSwingStrength < 1) return false;
    if(RiskRewardRatio < 1.0) return false;
    if(StopLossBufferPips < 0) return false;
    return true;
}

bool CheckDailyLossLimit() {
    double maxLoss = AccountInfoDouble(ACCOUNT_BALANCE) * (MaxDailyLoss / 100.0);
    
    double todayPL = 0;
    if(tradeManager.HasOpenPosition()) {
        todayPL = tradeManager.GetCurrentProfit();
    }
    
    return (todayPL < -maxLoss);
}

void ManageOpenPosition() {
    if(UseTrailingStop) {
        tradeManager.ApplyTrailingStop();
    }
    
    if(UsePartialTP) {
        tradeManager.CheckPartialTP();
    }
}

void CheckAPASetup() {
    ENUM_STRUCTURE_EVENT event = ltfStructure.DetectStructureEvent();
    
    if(event == STRUCT_BOS_BULLISH) {
        double invalidation = ltfStructure.GetLastLowerLow();
        double currentPrice = iClose(_Symbol, EntryTimeframe, 0);
        double tolerance = MinStructureDistance_Pips * _Point;
        
        if(MathAbs(currentPrice - invalidation) <= tolerance) {
            if(CanEnterTrade(TRADE_LONG)) {
                double sl = riskManager.CalculateStopLoss(TRADE_LONG, invalidation, StopLossBufferPips);
                double tp = riskManager.CalculateTakeProfitRR(currentPrice, sl);
                double lots = riskManager.CalculateLotSize(currentPrice, sl);
                
                if(tradeManager.PrepareEntry(TRADE_LONG, currentPrice, sl, tp, lots, TradeComment)) {
                    if(tradeManager.ExecuteTrade()) {
                        lastTradeTime = TimeCurrent();
                        lastEntryPrice = currentPrice;
                        if(EnableLogging) Print("APA Buy entry executed at ", currentPrice);
                        DrawTradeVisuals(TRADE_LONG, currentPrice, sl, tp);
                    }
                }
            }
        }
    }
    
    if(event == STRUCT_BOS_BEARISH) {
        double invalidation = ltfStructure.GetLastHigherHigh();
        double currentPrice = iClose(_Symbol, EntryTimeframe, 0);
        double tolerance = MinStructureDistance_Pips * _Point;
        
        if(MathAbs(currentPrice - invalidation) <= tolerance) {
            if(CanEnterTrade(TRADE_SHORT)) {
                double sl = riskManager.CalculateStopLoss(TRADE_SHORT, invalidation, StopLossBufferPips);
                double tp = riskManager.CalculateTakeProfitRR(currentPrice, sl);
                double lots = riskManager.CalculateLotSize(currentPrice, sl);
                
                if(tradeManager.PrepareEntry(TRADE_SHORT, currentPrice, sl, tp, lots, TradeComment)) {
                    if(tradeManager.ExecuteTrade()) {
                        lastTradeTime = TimeCurrent();
                        lastEntryPrice = currentPrice;
                        if(EnableLogging) Print("APA Sell entry executed at ", currentPrice);
                        DrawTradeVisuals(TRADE_SHORT, currentPrice, sl, tp);
                    }
                }
            }
        }
    }
}

void CheckCHOCHSetup() {
    ENUM_STRUCTURE_EVENT event = ltfStructure.DetectStructureEvent();
    
    if(event == STRUCT_CHOCH_BULLISH) {
        double currentPrice = iClose(_Symbol, EntryTimeframe, 0);
        double invalidation = ltfStructure.GetLastSwingLowPrice();
        
        if(CanEnterTrade(TRADE_LONG)) {
            double sl = riskManager.CalculateStopLoss(TRADE_LONG, invalidation, StopLossBufferPips);
            double tp = riskManager.CalculateTakeProfitRR(currentPrice, sl);
            double lots = riskManager.CalculateLotSize(currentPrice, sl);
            
            if(tradeManager.PrepareEntry(TRADE_LONG, currentPrice, sl, tp, lots, TradeComment)) {
                if(tradeManager.ExecuteTrade()) {
                    lastTradeTime = TimeCurrent();
                    lastEntryPrice = currentPrice;
                    if(EnableLogging) Print("CHOCH Buy entry executed at ", currentPrice);
                    DrawTradeVisuals(TRADE_LONG, currentPrice, sl, tp);
                }
            }
        }
    }
    
    if(event == STRUCT_CHOCH_BEARISH) {
        double currentPrice = iClose(_Symbol, EntryTimeframe, 0);
        double invalidation = ltfStructure.GetLastSwingHighPrice();
        
        if(CanEnterTrade(TRADE_SHORT)) {
            double sl = riskManager.CalculateStopLoss(TRADE_SHORT, invalidation, StopLossBufferPips);
            double tp = riskManager.CalculateTakeProfitRR(currentPrice, sl);
            double lots = riskManager.CalculateLotSize(currentPrice, sl);
            
            if(tradeManager.PrepareEntry(TRADE_SHORT, currentPrice, sl, tp, lots, TradeComment)) {
                if(tradeManager.ExecuteTrade()) {
                    lastTradeTime = TimeCurrent();
                    lastEntryPrice = currentPrice;
                    if(EnableLogging) Print("CHOCH Sell entry executed at ", currentPrice);
                    DrawTradeVisuals(TRADE_SHORT, currentPrice, sl, tp);
                }
            }
        }
    }
}

void CheckHiddenStructureSetup() {
}

void CheckTopDownSetup() {
}

bool CanEnterTrade(ENUM_TRADE_DIRECTION direction) {
    if(tradeManager.HasOpenPosition()) return false;
    
    if(!riskManager.IsSpreadAcceptable()) {
        if(EnableLogging) Print("Spread too high: ", SymbolInfoDouble(_Symbol, SYMBOL_SPREAD));
        return false;
    }
    
    if(!riskManager.HasEnoughMargin(0.01)) {
        if(EnableLogging) Print("Not enough margin");
        return false;
    }
    
    if(RequireCandleConfirmation) {
        for(int i = 0; i < ConfirmationCandles; i++) {
            if(iClose(_Symbol, EntryTimeframe, i) == iOpen(_Symbol, EntryTimeframe, i)) {
                return false;
            }
        }
    }
    
    return true;
}

void DrawTradeVisuals(ENUM_TRADE_DIRECTION direction, double entry, double sl, double tp) {
    if(!EnableVisuals) return;
    
    datetime entryTime = iTime(_Symbol, EntryTimeframe, 0);
    
    visualManager.DrawEntryArrow(entryTime, entry, direction);
    visualManager.DrawStopLoss(entryTime, sl, direction);
    visualManager.DrawTakeProfit(entryTime, tp, direction);
}

void UpdateVisuals() {
    if(!EnableVisuals) return;
    
    MarketStructureData htfData = htfStructure.GetData();
    MarketStructureData ltfData = ltfStructure.GetData();
    
    string trendText = "HTF Trend: " + (htfData.trend == TREND_UP ? "UP" : htfData.trend == TREND_DOWN ? "DOWN" : "RANGE");
    string eventText = "LTF Event: " + EnumToString(ltfData.bullishBOS ? STRUCT_BOS_BULLISH : 
                                                      ltfData.bearishBOS ? STRUCT_BOS_BEARISH :
                                                      ltfData.bullishCHOCH ? STRUCT_CHOCH_BULLISH :
                                                      ltfData.bearishCHOCH ? STRUCT_CHOCH_BEARISH : STRUCT_NONE);
    
    string panelText = "APA Bot v1.0\n" + trendText + "\n" + eventText;
    
    visualManager.DrawInfoPanel(panelText);
}

void SaveState() {
}

void LoadState() {
}
