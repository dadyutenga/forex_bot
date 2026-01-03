# MT5 Advanced Price Action Trading Bot - Complete Documentation

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Strategy Summary](#strategy-summary)
3. [System Architecture](#system-architecture)
4. [Installation Guide](#installation-guide)
5. [Configuration](#configuration)
6. [Development Roadmap](#development-roadmap)
7. [Testing & Deployment](#testing--deployment)

## Project Overview

This project implements a sophisticated multi-strategy trading bot for MetaTrader 5 (MT5) that combines multiple advanced price action strategies: 

- **APA Strategy** - Advanced Price Action with market structure analysis
- **CHOCH Strategy** - Change of Character with invalidation points
- **Hidden Structure Strategy** - Break and retest with hidden order blocks
- **Top-Down Strategy** - Multi-timeframe trend following

### Key Features
- ✅ Multi-timeframe analysis (Monthly to M15)
- ✅ Automated market structure detection
- ✅ Dynamic support/resistance identification
- ✅ Break of Structure (BOS) detection
- ✅ Change of Character (CHOCH) signals
- ✅ Hidden invalidation zones
- ✅ Risk-based position sizing
- ✅ Multiple take-profit strategies
- ✅ Visual chart annotations

## Strategy Summary

### 1. APA Strategy (Advanced Price Action)
**Objective**: Trade reversals using market structure breaks and invalidation points

**Key Concepts**:
- Market structure:  HH/HL (uptrend), LL/LH (downtrend)
- Break of Structure (BOS): Price breaks key structural level
- Invalidation Point: Entry zone after BOS

**Entry Rules**:
- **Buy**:  Downtrend → BOS above last LH → Retest of LL before BOS
- **Sell**:  Uptrend → BOS below last HL → Retest of HH before BOS

### 2. CHOCH Strategy (Change of Character)
**Objective**:  Identify trend reversals with precise entry zones

**Key Concepts**: 
- CHOCH: Break of recent swing high/low
- INV-P: Previous invalidation point
- INV-X: Entry invalidation zone
- Multi-timeframe confirmation (D1 + M15)

**Entry Rules**:
- **Buy**: CHOCH above LH → Retest INV-X zone → Bullish confirmation
- **Sell**: CHOCH below HL → Retest INV-X zone → Bearish confirmation

### 3. Hidden Structure Strategy
**Objective**: Exploit hidden order blocks within retest zones

**Key Concepts**: 
- HTF Break & Retest: Major support/resistance break
- Hidden Structure: Last impulse candle before break
- Supply/Demand zones from candle wicks to bodies

**Entry Rules**:
- **Sell**: HTF resistance broken → Retest → Enter at hidden supply zone
- **Buy**: HTF support broken → Retest → Enter at hidden demand zone

### 4. Top-Down Strategy
**Objective**: Follow primary trend with lower timeframe entries

**Key Concepts**: 
- Monthly trend identification
- Weekly structure identification
- Lower timeframe entry execution

**Entry Rules**:
- Identify monthly BOS for trend bias
- Find nearby weekly structures
- Enter on lower timeframe retest with confirmation

## System Architecture

```
MT5-Trading-Bot/
├── MQL5/
│   ├── Experts/
│   │   └── APABot_v1.mq5           # Main EA file
│   ├── Include/
│   │   ├── MarketStructure.mqh     # Structure detection
│   │   ├── SwingPoints.mqh         # Swing high/low detection
│   │   ├── TradeManager.mqh        # Order management
│   │   ├── RiskManager.mqh         # Position sizing
│   │   └── VisualManager.mqh       # Chart drawings
│   └── Indicators/
│       ├── StructureDetector.mq5   # Custom structure indicator
│       └── SwingZigZag.mq5         # Custom swing detector
├── Documentation/
│   ├── 01_Technical_Specification.md
│   ├── 02_Code_Structure.md
│   ├── 03_Algorithm_Details.md
│   ├── 04_Input_Parameters.md
│   ├── 05_Testing_Guide.md
│   └── 06_Troubleshooting.md
└── Backtesting/
    ├── test_data/
    └── results/
```

## Installation Guide

### Prerequisites
- MetaTrader 5 build 3280 or higher
- Windows 10/11 or compatible VPS
- Minimum 4GB RAM
- Stable internet connection

### Step-by-Step Installation

1. **Download MT5**
   ```
   Download from: https://www.metaquotes.net/en/metatrader5
   Install and open MetaTrader 5
   ```

2. **Access MetaEditor**
   - Press F4 in MT5 or click "MetaEditor" button
   - This opens the development environment

3. **Create Project Structure**
   - In MetaEditor, navigate to File → New → Expert Advisor
   - Name it "APABot_v1"
   - Save in:  `MQL5/Experts/`

4. **Import Include Files**
   - Create folder: `MQL5/Include/APABot/`
   - Place all . mqh files in this folder

5. **Compile**
   - Open APABot_v1.mq5
   - Press F7 to compile
   - Check for errors in "Toolbox" window

6. **Attach to Chart**
   - In MT5, open desired currency pair chart
   - In Navigator window (Ctrl+N), expand "Expert Advisors"
   - Drag "APABot_v1" onto chart
   - Configure parameters in dialog
   - Enable "Allow Algo Trading" (top toolbar)

## Configuration

### Essential Parameters

```cpp
// === GENERAL SETTINGS ===
input int MagicNumber = 100001;              // Unique identifier
input string TradeComment = "APA_Bot_v1";    // Order comment

// === TIMEFRAME SETTINGS ===
input ENUM_TIMEFRAMES HTF_Timeframe = PERIOD_D1;     // Higher timeframe
input ENUM_TIMEFRAMES EntryTimeframe = PERIOD_M15;   // Entry timeframe

// === STRATEGY SELECTION ===
input bool EnableAPA = true;                 // Enable APA Strategy
input bool EnableCHOCH = true;               // Enable CHOCH Strategy
input bool EnableHiddenStructure = false;    // Enable Hidden Structure
input bool EnableTopDown = false;            // Enable Top-Down

// === RISK MANAGEMENT ===
input double RiskPercent = 1.0;              // Risk per trade (%)
input double MaxSpreadPips = 3.0;            // Maximum spread allowed
input int MinTP_Pips = 20;                   // Minimum take profit
input double RiskRewardRatio = 2.0;          // R: R ratio

// === STRUCTURE DETECTION ===
input int SwingLookback = 20;                // Bars for swing detection
input int MinSwingStrength = 3;              // Candles on each side
input double MinStructureDistance_Pips = 10; // Min distance between levels

// === ENTRY FILTERS ===
input bool RequireCandleConfirmation = true; // Wait for candle close
input int ConfirmationCandles = 1;           // # of confirmation candles
input bool UseVolumeFilt = false;            // Volume filter
```

### Symbol-Specific Settings

**For GBPUSD (Forex)**:
- HTF_Timeframe:  PERIOD_H4
- EntryTimeframe:  PERIOD_M15
- RiskPercent: 1.0
- MinTP_Pips: 20

**For Volatility 75 Index**:
- HTF_Timeframe: PERIOD_H4
- EntryTimeframe:  PERIOD_M15
- RiskPercent: 0.5 (more volatile)
- MinTP_Pips: 50

## Development Roadmap

### Phase 1: Core Foundation (Week 1-2)
- [ ] Implement swing point detection algorithm
- [ ] Create market structure analyzer
- [ ] Build BOS detection logic
- [ ] Develop basic trade management

### Phase 2: Strategy Implementation (Week 3-4)
- [ ] Implement APA strategy
- [ ] Implement CHOCH strategy
- [ ] Add invalidation point logic
- [ ] Create entry zone detection

### Phase 3: Advanced Features (Week 5-6)
- [ ] Add Hidden Structure strategy
- [ ] Implement Top-Down analysis
- [ ] Multi-timeframe synchronization
- [ ] Visual chart annotations

### Phase 4: Risk & Money Management (Week 7)
- [ ] Position sizing calculator
- [ ] Dynamic SL/TP placement
- [ ] Trailing stop logic
- [ ] Partial TP functionality

### Phase 5: Testing & Optimization (Week 8-10)
- [ ] Strategy Tester backtesting
- [ ] Forward testing on demo
- [ ] Parameter optimization
- [ ] Performance analysis

### Phase 6: Deployment (Week 11-12)
- [ ] Final bug fixes
- [ ] Documentation completion
- [ ] Live trading preparation
- [ ] Monitoring system setup

## Testing & Deployment

### Backtesting Checklist
- [ ] Test on at least 6 months of historical data
- [ ] Test on multiple currency pairs
- [ ] Verify all entry conditions trigger correctly
- [ ] Check SL/TP placement accuracy
- [ ] Validate risk calculations
- [ ] Review drawdown statistics

### Demo Testing Checklist
- [ ] Run for minimum 1 month
- [ ] Test in different market conditions
- [ ] Monitor slippage and execution
- [ ] Verify visual annotations
- [ ] Check error handling
- [ ] Log all trades for review

### Live Deployment Checklist
- [ ] Start with minimum position size
- [ ] Monitor first 20 trades closely
- [ ] Keep detailed trade journal
- [ ] Set maximum daily loss limit
- [ ] Have contingency plan for malfunctions
- [ ] Regular performance reviews

## Support & Resources

### MQL5 Documentation
- Official MQL5 Reference:  https://www.mql5.com/en/docs
- Trading Functions: https://www.mql5.com/en/docs/trading
- Technical Indicators: https://www.mql5.com/en/docs/indicators

### Community Resources
- MQL5 Forum: https://www.mql5.com/en/forum
- Code Base: https://www.mql5.com/en/code
- Trading Articles: https://www.mql5.com/en/articles

### Contact & Support
For questions or issues, refer to the troubleshooting guide in `Documentation/06_Troubleshooting.md`

---

**Version**:  1.0.0  
**Last Updated**: 2026-01-03  
**Author**: APA Trading System Development Team