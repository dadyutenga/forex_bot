# Code Structure and Organization

## 1. File Organization

### 1.1 Main Expert Advisor File
**File**: `MQL5/Experts/APABot_v1.mq5`

```cpp
//+------------------------------------------------------------------+
//|                                                   APABot_v1.mq5  |
//|                                     APA Trading System v1.0       |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "APA Trading System"
#property link      ""
#property version   "1.00"
#property strict

// Include files
#include <APABot/MarketStructure.mqh>
#include <APABot/SwingPoints.mqh>
#include <APABot/TradeManager.mqh>
#include <APABot/RiskManager.mqh>
#include <APABot/VisualManager.mqh>

// Input parameters (see section 2)

// Global variables (see section 3)

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialization code
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Cleanup code
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick() {
    // Main trading logic
}

//+------------------------------------------------------------------+
//| Timer function                                                     |
//+------------------------------------------------------------------+
void OnTimer() {
    // Periodic tasks
}
```

### 1.2 Include Files Structure

#### MarketStructure.mqh
**Purpose**: Market structure analysis and trend detection

```cpp
//+------------------------------------------------------------------+
//|                                            MarketStructure.mqh    |
//+------------------------------------------------------------------+

// Enumerations
enum ENUM_TREND_TYPE {
    TREND_UP,
    TREND_DOWN,
    TREND_RANGING
};

enum ENUM_STRUCTURE_EVENT {
    STRUCT_BOS_BULLISH,
    STRUCT_BOS_BEARISH,
    STRUCT_CHOCH_BULLISH,
    STRUCT_CHOCH_BEARISH,
    STRUCT_NONE
};

// Class definition
class CMarketStructure {
private: 
    string symbol;
    ENUM_TIMEFRAMES timeframe;
    ENUM_TREND_TYPE currentTrend;
    
    SwingPoint swingHighs[];
    SwingPoint swingLows[];
    
    // Private methods
    bool UpdateSwingPoints();
    ENUM_TREND_TYPE DetermineTrend();
    
public:
    // Constructor
    CMarketStructure(string sym, ENUM_TIMEFRAMES tf);
    
    // Public methods
    bool Initialize();
    bool Update();
    ENUM_TREND_TYPE GetTrend();
    ENUM_STRUCTURE_EVENT DetectStructureEvent();
    double GetLastHigherHigh();
    double GetLastHigherLow();
    double GetLastLowerHigh();
    double GetLastLowerLow();
    bool IsBullishBOS();
    bool IsBearishBOS();
};
```

#### SwingPoints.mqh
**Purpose**: Swing point detection and management

```cpp
//+------------------------------------------------------------------+
//|                                                SwingPoints.mqh    |
//+------------------------------------------------------------------+

// Structure definition
struct SwingPoint {
    double price;
    datetime time;
    int barIndex;
    int type; // 1 = high, -1 = low
    bool isValid;
};

// Class definition
class CSwingDetector {
private:
    string symbol;
    ENUM_TIMEFRAMES timeframe;
    int lookback;
    int minStrength;
    
    SwingPoint recentSwings[];
    
    // Private methods
    bool IsSwingHigh(int bar);
    bool IsSwingLow(int bar);
    void AddSwingPoint(SwingPoint &point);
    void CleanOldSwings();
    
public:
    // Constructor
    CSwingDetector(string sym, ENUM_TIMEFRAMES tf, int lb, int strength);
    
    // Public methods
    bool Initialize();
    bool DetectNewSwings();
    SwingPoint GetLastSwingHigh();
    SwingPoint GetLastSwingLow();
    int GetSwingCount(int type);
    bool IsValidSwing(SwingPoint &swing);
};
```

#### TradeManager.mqh
**Purpose**: Trade execution and management

```cpp
//+------------------------------------------------------------------+
//|                                              TradeManager.mqh     |
//+------------------------------------------------------------------+

// Trade direction enum
enum ENUM_TRADE_DIRECTION {
    TRADE_LONG,
    TRADE_SHORT
};

// Trade setup structure
struct TradeSetup {
    ENUM_TRADE_DIRECTION direction;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double lotSize;
    string comment;
    bool isActive;
};

// Class definition
class CTradeManager {
private:
    int magicNumber;
    string symbol;
    
    TradeSetup currentSetup;
    ulong currentTicket;
    
    // Private methods
    bool ValidateSetup(TradeSetup &setup);
    bool CheckMarginRequirement(double lots);
    bool SendOrder(TradeSetup &setup);
    
public:
    // Constructor
    CTradeManager(int magic, string sym);
    
    // Public methods
    bool Initialize();
    bool PrepareEntry(ENUM_TRADE_DIRECTION dir, double entry, double sl, double tp);
    bool ExecuteTrade();
    bool HasOpenPosition();
    bool ClosePosition();
    bool ModifyPosition(double newSL, double newTP);
    double GetCurrentProfit();
    bool IsTradeActive();
};
```

#### RiskManager.mqh
**Purpose**: Risk calculation and position sizing

```cpp
//+------------------------------------------------------------------+
//|                                               RiskManager.mqh     |
//+------------------------------------------------------------------+

class CRiskManager {
private: 
    double riskPercent;
    double maxSpreadPips;
    double minTPPips;
    double rrRatio;
    
    // Private methods
    double GetAccountRiskAmount();
    double GetPipValue();
    double NormalizeLots(double lots);
    
public:
    // Constructor
    CRiskManager(double risk, double spread, double minTP, double rr);
    
    // Public methods
    bool Initialize();
    double CalculateLotSize(double entryPrice, double stopLoss);
    double CalculateStopLoss(ENUM_TRADE_DIRECTION dir, double invalidation, double buffer);
    double CalculateTakeProfit(double entry, double sl, double rrRatio);
    bool IsSpreadAcceptable();
    bool IsRiskAcceptable(double lots, double slPips);
    double GetMaxPositionSize();
};
```

#### VisualManager.mqh
**Purpose**: Chart visualization and annotations

```cpp
//+------------------------------------------------------------------+
//|                                             VisualManager.mqh     |
//+------------------------------------------------------------------+

class CVisualManager {
private:
    string symbol;
    bool enableVisuals;
    
    // Private methods
    string GenerateObjectName(string base);
    void DeleteOldObjects();
    
public:
    // Constructor
    CVisualManager(string sym, bool enable);
    
    // Public methods
    bool Initialize();
    void DrawSwingPoint(SwingPoint &swing, color clr);
    void DrawStructureLine(double price, string label, color clr);
    void DrawInvalidationZone(double high, double low, color clr);
    void DrawEntryArrow(datetime time, double price, int direction);
    void DrawInfoPanel(string text);
    void ClearAll();
    void UpdateLabels();
};
```

## 2. Input Parameters Organization

```cpp
//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+

//--- General Settings
input group "=== GENERAL SETTINGS ==="
input int                MagicNumber = 100001;           // Magic Number
input string             TradeComment = "APA_v1";        // Trade Comment
input bool               EnableLogging = true;            // Enable Detailed Logging

//--- Timeframe Settings
input group "=== TIMEFRAME SETTINGS ==="
input ENUM_TIMEFRAMES    HTF_Timeframe = PERIOD_D1;      // Higher Timeframe
input ENUM_TIMEFRAMES    EntryTimeframe = PERIOD_M15;    // Entry Timeframe

//--- Strategy Selection
input group "=== STRATEGY SELECTION ==="
input bool               EnableAPA = true;                // Enable APA Strategy
input bool               EnableCHOCH = true;              // Enable CHOCH Strategy
input bool               EnableHiddenStructure = false;   // Enable Hidden Structure
input bool               EnableTopDown = false;           // Enable Top-Down Strategy

//--- Risk Management
input group "=== RISK MANAGEMENT ==="
input double             RiskPercent = 1.0;               // Risk Per Trade (%)
input double             MaxSpreadPips = 3.0;             // Maximum Spread (pips)
input int                MinTP_Pips = 20;                 // Minimum TP (pips)
input double             RiskRewardRatio = 2.0;           // Risk: Reward Ratio
input double             MaxDailyLoss = 3.0;              // Max Daily Loss (%)

//--- Structure Detection
input group "=== STRUCTURE DETECTION ==="
input int                SwingLookback = 20;              // Swing Lookback Bars
input int                MinSwingStrength = 3;            // Minimum Swing Strength
input double             MinStructureDistance_Pips = 10;  // Min Structure Distance (pips)

//--- Entry Filters
input group "=== ENTRY FILTERS ==="
input bool               RequireCandleConfirmation = true; // Require Candle Close
input int                ConfirmationCandles = 1;          // Confirmation Candles
input bool               UseVolumeFilter = false;          // Use Volume Filter
input int                MinVolume = 1000;                 // Minimum Volume

//--- Exit Management
input group "=== EXIT MANAGEMENT ==="
input bool               UseTrailingStop = false;          // Use Trailing Stop
input double             TrailingStart_Pips = 20;          // Trailing Start (pips)
input double             TrailingStep_Pips = 10;           // Trailing Step (pips)
input bool               UsePartialTP = false;             // Use Partial Take Profit
input double             PartialTP_Percent = 50;           // Partial TP (%)
input double             PartialTP_RR = 1.0;               // Partial TP R:R

//--- Visual Settings
input group "=== VISUAL SETTINGS ==="
input bool               EnableVisuals = true;             // Enable Chart Visuals
input color              ColorBuySignal = clrGreen;        // Buy Signal Color
input color              ColorSellSignal = clrRed;         // Sell Signal Color
input color              ColorStructure = clrYellow;       // Structure Line Color
input int                LineWidth = 2;                    // Line Width
```

## 3. Global Variables

```cpp
//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+

// Class instances
CMarketStructure    *htfStructure = NULL;
CMarketStructure    *ltfStructure = NULL;
CSwingDetector      *swingDetector = NULL;
CTradeManager       *tradeManager = NULL;
CRiskManager        *riskManager = NULL;
CVisualManager      *visualManager = NULL;

// State variables
bool                 isInitialized = false;
datetime             lastBarTime = 0;
int                  totalTradestoday = 0;
double               dailyPL = 0.0;

// Structure tracking
double               lastInvalidationLevel = 0.0;
ENUM_STRUCTURE_EVENT lastStructureEvent = STRUCT_NONE;
bool                 setupActive = false;

// Trade tracking
datetime             lastTradeTime = 0;
double               lastEntryPrice = 0.0;
```

## 4. Main Logic Flow

### 4.1 OnInit() Function

```cpp
int OnInit() {
    Print("=== Initializing APA Bot v1.0 ===");
    
    // 1. Validate inputs
    if(! ValidateInputs()) {
        Print("ERROR: Invalid input parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 2. Initialize class instances
    htfStructure = new CMarketStructure(_Symbol, HTF_Timeframe);
    ltfStructure = new CMarketStructure(_Symbol, EntryTimeframe);
    swingDetector = new CSwingDetector(_Symbol, EntryTimeframe, SwingLookback, MinSwingStrength);
    tradeManager = new CTradeManager(MagicNumber, _Symbol);
    riskManager = new CRiskManager(RiskPercent, MaxSpreadPips, MinTP_Pips, RiskRewardRatio);
    visualManager = new CVisualManager(_Symbol, EnableVisuals);
    
    // 3. Initialize all components
    if(!htfStructure. Initialize() || !ltfStructure.Initialize() ||
       !swingDetector. Initialize() || !tradeManager.Initialize() ||
       !riskManager.Initialize() || !visualManager.Initialize()) {
        Print("ERROR: Failed to initialize components");
        return INIT_FAILED;
    }
    
    // 4. Setup timer
    EventSetTimer(60); // 1 minute
    
    // 5. Load historical state
    LoadState();
    
    isInitialized = true;
    Print("=== Initialization Complete ===");
    
    return INIT_SUCCEEDED;
}
```

### 4.2 OnTick() Function

```cpp
void OnTick() {
    if(!isInitialized) return;
    
    // 1. Check if new bar on entry timeframe
    if(! IsNewBar(EntryTimeframe)) return;
    
    // 2. Update market structure
    htfStructure. Update();
    ltfStructure.Update();
    swingDetector.DetectNewSwings();
    
    // 3. Check daily loss limit
    if(CheckDailyLossLimit()) {
        Print("Daily loss limit reached.  Trading suspended.");
        return;
    }
    
    // 4. Manage existing positions
    if(tradeManager.HasOpenPosition()) {
        ManageOpenPosition();
        return;
    }
    
    // 5. Scan for new setups
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
    
    // 6. Update visuals
    if(EnableVisuals) {
        visualManager.UpdateLabels();
    }
}
```

### 4.3 Strategy Check Functions

```cpp
void CheckAPASetup() {
    // Detect BOS
    ENUM_STRUCTURE_EVENT event = ltfStructure.DetectStructureEvent();
    
    if(event == STRUCT_BOS_BULLISH) {
        // Get invalidation point
        double invalidation = ltfStructure.GetLastLowerLow();
        
        // Check if price is retesting
        double currentPrice = iClose(_Symbol, EntryTimeframe, 0);
        double tolerance = MinStructureDistance_Pips * _Point;
        
        if(MathAbs(currentPrice - invalidation) <= tolerance) {
            // Prepare buy setup
            double sl = riskManager.CalculateStopLoss(TRADE_LONG, invalidation, StopLoss_BufferPips);
            double tp = riskManager.CalculateTakeProfit(currentPrice, sl, RiskRewardRatio);
            
            if(tradeManager.PrepareEntry(TRADE_LONG, currentPrice, sl, tp)) {
                tradeManager.ExecuteTrade();
                
                // Draw visual
                if(EnableVisuals) {
                    visualManager.DrawEntryArrow(iTime(_Symbol, EntryTimeframe, 0), currentPrice, 1);
                }
            }
        }
    }
    
    // Similar logic for bearish BOS
    if(event == STRUCT_BOS_BEARISH) {
        // ...  bearish setup logic
    }
}

void CheckCHOCHSetup() {
    // CHOCH detection and entry logic
    // Similar structure to CheckAPASetup()
}

void CheckHiddenStructureSetup() {
    // Hidden structure detection and entry logic
}

void CheckTopDownSetup() {
    // Top-down analysis and entry logic
}
```

## 5. Helper Functions

```cpp
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
    if(RiskRewardRatio < 1. 0) return false;
    return true;
}

bool CheckDailyLossLimit() {
    // Calculate today's P/L
    dailyPL = CalculateDailyPL();
    double maxLoss = AccountInfoDouble(ACCOUNT_BALANCE) * (MaxDailyLoss / 100.0);
    
    return (dailyPL < -maxLoss);
}

void ManageOpenPosition() {
    // Trailing stop logic
    if(UseTrailingStop) {
        ApplyTrailingStop();
    }
    
    // Partial TP logic
    if(UsePartialTP) {
        CheckPartialTP();
    }
}

void SaveState() {
    // Save important state variables to file
}

void LoadState() {
    // Load state from file
}
```

---

**Document Version**: 1.0  
**Date**: 2026-01-03