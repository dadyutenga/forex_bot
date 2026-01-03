# Algorithm Implementation Details

## 1. Swing Point Detection Algorithm

### 1.1 Mathematical Definition

A swing high at bar `i` is identified when: 

```
∀ j ∈ [i-n, i+n], j ≠ i:  High[i] > High[j]
```

Where `n` = MinSwingStrength

A swing low at bar `i` is identified when:

```
∀ j ∈ [i-n, i+n], j ≠ i: Low[i] < Low[j]
```

### 1.2 Implementation

```cpp
bool CSwingDetector::IsSwingHigh(int bar) {
    double centerHigh = iHigh(symbol, timeframe, bar);
    
    // Check left side
    for(int i = 1; i <= minStrength; i++) {
        if(bar + i >= Bars(symbol, timeframe)) return false;
        if(centerHigh <= iHigh(symbol, timeframe, bar + i)) return false;
    }
    
    // Check right side
    for(int i = 1; i <= minStrength; i++) {
        if(bar - i < 0) return false;
        if(centerHigh <= iHigh(symbol, timeframe, bar - i)) return false;
    }
    
    return true;
}

bool CSwingDetector::IsSwingLow(int bar) {
    double centerLow = iLow(symbol, timeframe, bar);
    
    // Check left side
    for(int i = 1; i <= minStrength; i++) {
        if(bar + i >= Bars(symbol, timeframe)) return false;
        if(centerLow >= iLow(symbol, timeframe, bar + i)) return false;
    }
    
    // Check right side
    for(int i = 1; i <= minStrength; i++) {
        if(bar - i < 0) return false;
        if(centerLow >= iLow(symbol, timeframe, bar - i)) return false;
    }
    
    return true;
}

bool CSwingDetector::DetectNewSwings() {
    // Only check bars that are fully formed
    int startBar = minStrength;
    int endBar = MathMin(lookback, Bars(symbol, timeframe) - minStrength - 1);
    
    for(int i = startBar; i <= endBar; i++) {
        // Check if already processed
        if(IsBarProcessed(i)) continue;
        
        // Check for swing high
        if(IsSwingHigh(i)) {
            SwingPoint sp;
            sp.price = iHigh(symbol, timeframe, i);
            sp.time = iTime(symbol, timeframe, i);
            sp.barIndex = i;
            sp. type = 1;
            sp.isValid = true;
            
            AddSwingPoint(sp);
        }
        
        // Check for swing low
        if(IsSwingLow(i)) {
            SwingPoint sp;
            sp.price = iLow(symbol, timeframe, i);
            sp.time = iTime(symbol, timeframe, i);
            sp.barIndex = i;
            sp.type = -1;
            sp.isValid = true;
            
            AddSwingPoint(sp);
        }
        
        MarkBarAsProcessed(i);
    }
    
    return true;
}
```

### 1.3 Optimization Techniques

**Caching**: Store processed bars to avoid recalculation
```cpp
private:
    bool processedBars[];
    
bool IsBarProcessed(int bar) {
    if(bar >= ArraySize(processedBars)) ArrayResize(processedBars, bar + 1);
    return processedBars[bar];
}

void MarkBarAsProcessed(int bar) {
    if(bar >= ArraySize(processedBars)) ArrayResize(processedBars, bar + 1);
    processedBars[bar] = true;
}
```

**Pruning**: Remove old swing points to save memory
```cpp
void CSwingDetector::CleanOldSwings() {
    int maxSwings = 50; // Keep last 50 swings
    
    if(ArraySize(recentSwings) > maxSwings) {
        // Shift array
        for(int i = 0; i < maxSwings; i++) {
            recentSwings[i] = recentSwings[ArraySize(recentSwings) - maxSwings + i];
        }
        ArrayResize(recentSwings, maxSwings);
    }
}
```

## 2. Market Structure Analysis

### 2.1 Trend Determination Algorithm

```cpp
ENUM_TREND_TYPE CMarketStructure::DetermineTrend() {
    // Need at least 4 swing points (2 highs + 2 lows)
    if(ArraySize(swingHighs) < 2 || ArraySize(swingLows) < 2) {
        return TREND_RANGING;
    }
    
    // Get last two highs and lows
    double lastHigh = swingHighs[0]. price;
    double prevHigh = swingHighs[1].price;
    double lastLow = swingLows[0].price;
    double prevLow = swingLows[1].price;
    
    // Count structure characteristics
    bool higherHighs = (lastHigh > prevHigh);
    bool higherLows = (lastLow > prevLow);
    bool lowerHighs = (lastHigh < prevHigh);
    bool lowerLows = (lastLow < prevLow);
    
    // Determine trend
    if(higherHighs && higherLows) {
        return TREND_UP;
    } else if(lowerHighs && lowerLows) {
        return TREND_DOWN;
    } else {
        return TREND_RANGING;
    }
}
```

### 2.2 Break of Structure (BOS) Detection

```cpp
bool CMarketStructure::IsBullishBOS() {
    // Must be in downtrend
    if(currentTrend != TREND_DOWN) return false;
    
    // Get last lower high
    double lastLH = GetLastLowerHigh();
    if(lastLH == 0) return false;
    
    // Check current price
    double currentClose = iClose(symbol, timeframe, 0);
    double minDistance = MinStructureDistance_Pips * SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // BOS occurs when price closes above last LH
    if(currentClose > lastLH + minDistance) {
        // Additional confirmation:  check volume
        if(UseVolumeFilter) {
            long currentVolume = iVolume(symbol, timeframe, 0);
            long avgVolume = CalculateAverageVolume(10);
            
            if(currentVolume < avgVolume) return false;
        }
        
        return true;
    }
    
    return false;
}

bool CMarketStructure:: IsBearishBOS() {
    // Must be in uptrend
    if(currentTrend != TREND_UP) return false;
    
    // Get last higher low
    double lastHL = GetLastHigherLow();
    if(lastHL == 0) return false;
    
    // Check current price
    double currentClose = iClose(symbol, timeframe, 0);
    double minDistance = MinStructureDistance_Pips * SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // BOS occurs when price closes below last HL
    if(currentClose < lastHL - minDistance) {
        // Additional confirmation: check volume
        if(UseVolumeFilter) {
            long currentVolume = iVolume(symbol, timeframe, 0);
            long avgVolume = CalculateAverageVolume(10);
            
            if(currentVolume < avgVolume) return false;
        }
        
        return true;
    }
    
    return false;
}

double CMarketStructure::GetLastLowerHigh() {
    // In a downtrend, find the most recent swing high
    for(int i = 0; i < ArraySize(swingHighs) - 1; i++) {
        if(swingHighs[i].price < swingHighs[i+1].price) {
            return swingHighs[i]. price;
        }
    }
    return 0;
}

double CMarketStructure::GetLastHigherLow() {
    // In an uptrend, find the most recent swing low
    for(int i = 0; i < ArraySize(swingLows) - 1; i++) {
        if(swingLows[i].price > swingLows[i+1].price) {
            return swingLows[i].price;
        }
    }
    return 0;
}
```

### 2.3 Change of Character (CHOCH) Detection

```cpp
ENUM_STRUCTURE_EVENT CMarketStructure::DetectCHOCH() {
    double currentClose = iClose(symbol, timeframe, 0);
    double minDistance = MinStructureDistance_Pips * SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Bullish CHOCH:  In downtrend, break above recent swing high
    if(currentTrend == TREND_DOWN) {
        if(ArraySize(swingHighs) > 0) {
            double lastSwingHigh = swingHighs[0].price;
            
            if(currentClose > lastSwingHigh + minDistance) {
                return STRUCT_CHOCH_BULLISH;
            }
        }
    }
    
    // Bearish CHOCH: In uptrend, break below recent swing low
    if(currentTrend == TREND_UP) {
        if(ArraySize(swingLows) > 0) {
            double lastSwingLow = swingLows[0].price;
            
            if(currentClose < lastSwingLow - minDistance) {
                return STRUCT_CHOCH_BEARISH;
            }
        }
    }
    
    return STRUCT_NONE;
}
```

## 3.  Invalidation Point Calculation

### 3.1 APA Strategy Invalidation

```cpp
double CalculateInvalidationPoint_APA(int direction) {
    if(direction == TRADE_LONG) {
        // For buy:  invalidation is the LL before the BOS
        // Find the swing low that occurred before the BOS
        int bosBar = FindBOSBar();
        
        for(int i = 0; i < ArraySize(swingLows); i++) {
            if(swingLows[i].barIndex > bosBar) {
                return swingLows[i].price;
            }
        }
    } else {
        // For sell: invalidation is the HH before the BOS
        int bosBar = FindBOSBar();
        
        for(int i = 0; i < ArraySize(swingHighs); i++) {
            if(swingHighs[i].barIndex > bosBar) {
                return swingHighs[i].price;
            }
        }
    }
    
    return 0;
}

int FindBOSBar() {
    // Find the bar where BOS occurred
    // This is stored when BOS is detected
    return bosBarIndex;
}
```

### 3.2 CHOCH Strategy INV-X Calculation

```cpp
struct InvalidationZone {
    double high;
    double low;
    int barIndex;
};

InvalidationZone CalculateINV_X_CHOCH(int direction) {
    InvalidationZone zone;
    
    if(direction == TRADE_LONG) {
        // Find the demand zone (last down candle before impulse)
        int chochBar = FindCHOCHBar();
        
        // Look for the last bearish candle before the impulse
        for(int i = chochBar + 1; i < chochBar + 50; i++) {
            double open = iOpen(symbol, timeframe, i);
            double close = iClose(symbol, timeframe, i);
            
            if(close < open) { // Bearish candle
                // Check if this initiated the impulse
                double nextClose = iClose(symbol, timeframe, i - 1);
                if(nextClose > close) { // Next candle is bullish
                    zone.high = iHigh(symbol, timeframe, i);
                    zone.low = iOpen(symbol, timeframe, i); // Body low
                    zone.barIndex = i;
                    break;
                }
            }
        }
    } else {
        // Find the supply zone (last up candle before impulse)
        int chochBar = FindCHOCHBar();
        
        for(int i = chochBar + 1; i < chochBar + 50; i++) {
            double open = iOpen(symbol, timeframe, i);
            double close = iClose(symbol, timeframe, i);
            
            if(close > open) { // Bullish candle
                double nextClose = iClose(symbol, timeframe, i - 1);
                if(nextClose < close) { // Next candle is bearish
                    zone.low = iLow(symbol, timeframe, i);
                    zone.high = iOpen(symbol, timeframe, i); // Body high
                    zone. barIndex = i;
                    break;
                }
            }
        }
    }
    
    return zone;
}
```

## 4. Hidden Structure Detection

### 4.1 HTF Break and Retest Detection

```cpp
struct HTF_Level {
    double price;
    int levelType; // 1 = resistance, -1 = support
    bool wasBroken;
    int breakBar;
};

HTF_Level DetectHTF_BreakAndRetest() {
    HTF_Level level;
    level.wasBroken = false;
    
    // Find significant resistance on HTF
    double resistance = FindHTF_Resistance();
    if(resistance == 0) return level;
    
    level.price = resistance;
    level.levelType = 1;
    
    // Check if it was broken
    for(int i = 0; i < 100; i++) {
        double close = iClose(symbol, HTF_Timeframe, i);
        if(close > resistance) {
            level.wasBroken = true;
            level.breakBar = i;
            break;
        }
    }
    
    if(! level.wasBroken) return level;
    
    // Check if currently retesting
    double currentPrice = iClose(symbol, HTF_Timeframe, 0);
    double tolerance = RetestZone_TolerancePips * SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    if(MathAbs(currentPrice - resistance) <= tolerance) {
        // Valid retest
        return level;
    }
    
    level.wasBroken = false; // Reset if not retesting
    return level;
}

double FindHTF_Resistance() {
    // Look for price level with multiple touches
    int lookbackBars = 200;
    double priceRange = iHigh(symbol, HTF_Timeframe, iHighest(symbol, HTF_Timeframe, MODE_HIGH, lookbackBars, 0)) -
                       iLow(symbol, HTF_Timeframe, iLowest(symbol, HTF_Timeframe, MODE_LOW, lookbackBars, 0));
    
    double gridSize = priceRange / 100; // Divide into 100 levels
    
    int touchCounts[];
    ArrayResize(touchCounts, 100);
    ArrayInitialize(touchCounts, 0);
    
    // Count touches at each level
    for(int i = 0; i < lookbackBars; i++) {
        double high = iHigh(symbol, HTF_Timeframe, i);
        double low = iLow(symbol, HTF_Timeframe, i);
        
        for(int level = 0; level < 100; level++) {
            double levelPrice = iLow(symbol, HTF_Timeframe, iLowest(symbol, HTF_Timeframe, MODE_LOW, lookbackBars, 0)) + level * gridSize;
            
            if(high >= levelPrice && low <= levelPrice) {
                touchCounts[level]++;
            }
        }
    }
    
    // Find level with most touches
    int maxTouches = 0;
    int maxLevel = 0;
    
    for(int i = 0; i < 100; i++) {
        if(touchCounts[i] > maxTouches) {
            maxTouches = touchCounts[i];
            maxLevel = i;
        }
    }
    
    if(maxTouches >= 2) {
        return iLow(symbol, HTF_Timeframe, iLowest(symbol, HTF_Timeframe, MODE_LOW, lookbackBars, 0)) + maxLevel * gridSize;
    }
    
    return 0;
}
```

### 4.2 LTF Hidden Structure Identification

```cpp
struct HiddenStructure {
    double zoneHigh;
    double zoneLow;
    int barIndex;
    bool isValid;
};

HiddenStructure FindHiddenStructure(HTF_Level &htfLevel) {
    HiddenStructure hs;
    hs.isValid = false;
    
    if(! htfLevel.wasBroken) return hs;
    
    // Switch to LTF and find the impulse candle
    int htfBreakBar = htfLevel.breakBar;
    datetime breakTime = iTime(symbol, HTF_Timeframe, htfBreakBar);
    
    // Find corresponding bar on LTF
    int ltfBreakBar = iBarShift(symbol, EntryTimeframe, breakTime);
    
    // Look back for the last strong candle before impulse
    for(int i = ltfBreakBar; i < ltfBreakBar + 100; i++) {
        double open = iOpen(symbol, EntryTimeframe, i);
        double close = iClose(symbol, EntryTimeframe, i);
        double