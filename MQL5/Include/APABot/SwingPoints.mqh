//+------------------------------------------------------------------+
//|                                                SwingPoints.mqh     |
//|                    APA Trading System - Swing Detection           |
//+------------------------------------------------------------------+
#property copyright "APA Trading System"
#property link      ""
#property version   "1.00"

#ifndef SWING_POINTS_MQH
#define SWING_POINTS_MQH

enum ENUM_SWING_TYPE {
    SWING_HIGH,
    SWING_LOW
};

struct SwingPoint {
    double price;
    datetime time;
    int barIndex;
    ENUM_SWING_TYPE type;
    bool isValid;
};

class CSwingDetector {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int m_lookback;
    int m_minStrength;

    SwingPoint m_swingHighs[];
    SwingPoint m_swingLows[];

    bool m_processedBars[];

    bool IsSwingHigh(int bar) {
        double centerHigh = iHigh(m_symbol, m_timeframe, bar);
        
        for(int i = 1; i <= m_minStrength; i++) {
            if(bar + i >= Bars(m_symbol, m_timeframe)) return false;
            if(centerHigh <= iHigh(m_symbol, m_timeframe, bar + i)) return false;
        }
        
        for(int i = 1; i <= m_minStrength; i++) {
            if(bar - i < 0) return false;
            if(centerHigh <= iHigh(m_symbol, m_timeframe, bar - i)) return false;
        }
        
        return true;
    }

    bool IsSwingLow(int bar) {
        double centerLow = iLow(m_symbol, m_timeframe, bar);
        
        for(int i = 1; i <= m_minStrength; i++) {
            if(bar + i >= Bars(m_symbol, m_timeframe)) return false;
            if(centerLow >= iLow(m_symbol, m_timeframe, bar + i)) return false;
        }
        
        for(int i = 1; i <= m_minStrength; i++) {
            if(bar - i < 0) return false;
            if(centerLow >= iLow(m_symbol, m_timeframe, bar - i)) return false;
        }
        
        return true;
    }

    bool IsBarProcessed(int bar) {
        int size = ArraySize(m_processedBars);
        if(bar >= size) {
            ArrayResize(m_processedBars, bar + 100);
            for(int i = size; i < ArraySize(m_processedBars); i++) {
                m_processedBars[i] = false;
            }
        }
        return m_processedBars[bar];
    }

    void MarkBarAsProcessed(int bar) {
        int size = ArraySize(m_processedBars);
        if(bar >= size) {
            ArrayResize(m_processedBars, bar + 100);
            for(int i = size; i < ArraySize(m_processedBars); i++) {
                m_processedBars[i] = false;
            }
        }
        m_processedBars[bar] = true;
    }

    void AddSwingPoint(SwingPoint &sp) {
        if(sp.type == SWING_HIGH) {
            int size = ArraySize(m_swingHighs);
            ArrayResize(m_swingHighs, size + 1);
            m_swingHighs[size] = sp;
        } else {
            int size = ArraySize(m_swingLows);
            ArrayResize(m_swingLows, size + 1);
            m_swingLows[size] = sp;
        }
    }

    void CleanOldSwings() {
        int maxSwings = 50;
        
        int highSize = ArraySize(m_swingHighs);
        if(highSize > maxSwings) {
            for(int i = 0; i < maxSwings; i++) {
                m_swingHighs[i] = m_swingHighs[highSize - maxSwings + i];
            }
            ArrayResize(m_swingHighs, maxSwings);
        }
        
        int lowSize = ArraySize(m_swingLows);
        if(lowSize > maxSwings) {
            for(int i = 0; i < maxSwings; i++) {
                m_swingLows[i] = m_swingLows[lowSize - maxSwings + i];
            }
            ArrayResize(m_swingLows, maxSwings);
        }
    }

public:
    CSwingDetector(string sym, ENUM_TIMEFRAMES tf, int lb, int strength) {
        m_symbol = sym;
        m_timeframe = tf;
        m_lookback = lb;
        m_minStrength = strength;
        ArrayResize(m_swingHighs, 0);
        ArrayResize(m_swingLows, 0);
        ArrayResize(m_processedBars, 100);
        ArrayInitialize(m_processedBars, false);
    }

    ~CSwingDetector() {
    }

    bool Initialize() {
        return DetectNewSwings();
    }

    bool DetectNewSwings() {
        int totalBars = Bars(m_symbol, m_timeframe);
        if(totalBars < m_minStrength * 2 + 1) return false;
        
        int startBar = m_minStrength;
        int endBar = MathMin(m_lookback, totalBars - m_minStrength - 1);
        
        for(int i = startBar; i <= endBar; i++) {
            if(IsBarProcessed(i)) continue;
            
            if(IsSwingHigh(i)) {
                SwingPoint sp;
                sp.price = iHigh(m_symbol, m_timeframe, i);
                sp.time = iTime(m_symbol, m_timeframe, i);
                sp.barIndex = i;
                sp.type = SWING_HIGH;
                sp.isValid = true;
                AddSwingPoint(sp);
            }
            
            if(IsSwingLow(i)) {
                SwingPoint sp;
                sp.price = iLow(m_symbol, m_timeframe, i);
                sp.time = iTime(m_symbol, m_timeframe, i);
                sp.barIndex = i;
                sp.type = SWING_LOW;
                sp.isValid = true;
                AddSwingPoint(sp);
            }
            
            MarkBarAsProcessed(i);
        }
        
        CleanOldSwings();
        return true;
    }

    int GetSwingHighCount() {
        return ArraySize(m_swingHighs);
    }

    int GetSwingLowCount() {
        return ArraySize(m_swingLows);
    }

    bool GetLastSwingHigh(SwingPoint &sp) {
        int size = ArraySize(m_swingHighs);
        if(size == 0) return false;
        sp = m_swingHighs[size - 1];
        return true;
    }

    bool GetLastSwingLow(SwingPoint &sp) {
        int size = ArraySize(m_swingLows);
        if(size == 0) return false;
        sp = m_swingLows[size - 1];
        return true;
    }

    bool GetSwingHigh(int index, SwingPoint &sp) {
        int size = ArraySize(m_swingHighs);
        if(index < 0 || index >= size) return false;
        sp = m_swingHighs[index];
        return true;
    }

    bool GetSwingLow(int index, SwingPoint &sp) {
        int size = ArraySize(m_swingLows);
        if(index < 0 || index >= size) return false;
        sp = m_swingLows[index];
        return true;
    }

    double GetLastSwingHighPrice() {
        int size = ArraySize(m_swingHighs);
        if(size == 0) return 0;
        return m_swingHighs[size - 1].price;
    }

    double GetLastSwingLowPrice() {
        int size = ArraySize(m_swingLows);
        if(size == 0) return 0;
        return m_swingLows[size - 1].price;
    }

    bool IsValidSwing(SwingPoint &swing) {
        return swing.isValid;
    }

    void Reset() {
        ArrayResize(m_swingHighs, 0);
        ArrayResize(m_swingLows, 0);
        ArrayInitialize(m_processedBars, false);
    }
};

#endif
