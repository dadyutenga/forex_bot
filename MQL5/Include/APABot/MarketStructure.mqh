//+------------------------------------------------------------------+
//|                                            MarketStructure.mqh    |
//|                 APA Trading System - Market Structure Analysis    |
//+------------------------------------------------------------------+
#property copyright "APA Trading System"
#property link      ""
#property version   "1.00"

#ifndef MARKET_STRUCTURE_MQH
#define MARKET_STRUCTURE_MQH

#include "SwingPoints.mqh"

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

struct MarketStructureData {
    ENUM_TREND_TYPE trend;
    double lastHigherHigh;
    double lastHigherLow;
    double lastLowerHigh;
    double lastLowerLow;
    bool bullishBOS;
    bool bearishBOS;
    bool bullishCHOCH;
    bool bearishCHOCH;
    datetime lastUpdate;
};

class CMarketStructure {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int m_swingLookback;
    int m_minSwingStrength;
    double m_minStructureDistance;

    CSwingDetector *m_swingDetector;
    MarketStructureData m_data;

    void UpdateData() {
        m_data.lastUpdate = TimeCurrent();
        
        SwingPoint sp;
        int highCount = m_swingDetector.GetSwingHighCount();
        int lowCount = m_swingDetector.GetSwingLowCount();
        
        if(highCount >= 2) {
            m_swingDetector.GetSwingHigh(highCount - 1, sp);
            m_data.lastHigherHigh = sp.price;
            m_swingDetector.GetSwingHigh(highCount - 2, sp);
            m_data.lastLowerHigh = sp.price;
        } else {
            m_data.lastHigherHigh = 0;
            m_data.lastLowerHigh = 0;
        }
        
        if(lowCount >= 2) {
            m_swingDetector.GetSwingLow(lowCount - 1, sp);
            m_data.lastHigherLow = sp.price;
            m_swingDetector.GetSwingLow(lowCount - 2, sp);
            m_data.lastLowerLow = sp.price;
        } else {
            m_data.lastHigherLow = 0;
            m_data.lastLowerLow = 0;
        }
        
        m_data.trend = DetermineTrend();
        m_data.bullishBOS = DetectBullishBOS();
        m_data.bearishBOS = DetectBearishBOS();
        m_data.bullishCHOCH = DetectBullishCHOCH();
        m_data.bearishCHOCH = DetectBearishCHOCH();
    }

    ENUM_TREND_TYPE DetermineTrend() {
        int highCount = m_swingDetector.GetSwingHighCount();
        int lowCount = m_swingDetector.GetSwingLowCount();
        
        if(highCount < 2 || lowCount < 2) {
            return TREND_RANGING;
        }
        
        double lastHigh = m_data.lastHigherHigh;
        double prevHigh = m_data.lastLowerHigh;
        double lastLow = m_data.lastHigherLow;
        double prevLow = m_data.lastLowerLow;
        
        bool higherHighs = (lastHigh > prevHigh);
        bool higherLows = (lastLow > prevLow);
        bool lowerHighs = (lastHigh < prevHigh);
        bool lowerLows = (lastLow < prevLow);
        
        if(higherHighs && higherLows) {
            return TREND_UP;
        } else if(lowerHighs && lowerLows) {
            return TREND_DOWN;
        } else {
            return TREND_RANGING;
        }
    }

    bool DetectBullishBOS() {
        if(m_data.trend != TREND_DOWN) return false;
        if(m_data.lastLowerHigh == 0) return false;
        
        double currentClose = iClose(m_symbol, m_timeframe, 0);
        double minDistance = m_minStructureDistance * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        
        return (currentClose > m_data.lastLowerHigh + minDistance);
    }

    bool DetectBearishBOS() {
        if(m_data.trend != TREND_UP) return false;
        if(m_data.lastHigherLow == 0) return false;
        
        double currentClose = iClose(m_symbol, m_timeframe, 0);
        double minDistance = m_minStructureDistance * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        
        return (currentClose < m_data.lastHigherLow - minDistance);
    }

    bool DetectBullishCHOCH() {
        if(m_data.trend != TREND_DOWN) return false;
        
        double lastHigh = m_swingDetector.GetLastSwingHighPrice();
        if(lastHigh == 0) return false;
        
        double currentClose = iClose(m_symbol, m_timeframe, 0);
        double minDistance = m_minStructureDistance * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        
        return (currentClose > lastHigh + minDistance);
    }

    bool DetectBearishCHOCH() {
        if(m_data.trend != TREND_UP) return false;
        
        double lastLow = m_swingDetector.GetLastSwingLowPrice();
        if(lastLow == 0) return false;
        
        double currentClose = iClose(m_symbol, m_timeframe, 0);
        double minDistance = m_minStructureDistance * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        
        return (currentClose < lastLow - minDistance);
    }

public:
    CMarketStructure(string sym, ENUM_TIMEFRAMES tf, int lb, int strength, double minDist) {
        m_symbol = sym;
        m_timeframe = tf;
        m_swingLookback = lb;
        m_minSwingStrength = strength;
        m_minStructureDistance = minDist;
        
        m_swingDetector = new CSwingDetector(sym, tf, lb, strength);
        
        m_data.trend = TREND_RANGING;
        m_data.lastHigherHigh = 0;
        m_data.lastHigherLow = 0;
        m_data.lastLowerHigh = 0;
        m_data.lastLowerLow = 0;
        m_data.bullishBOS = false;
        m_data.bearishBOS = false;
        m_data.bullishCHOCH = false;
        m_data.bearishCHOCH = false;
        m_data.lastUpdate = 0;
    }

    ~CMarketStructure() {
        if(CheckPointer(m_swingDetector) == POINTER_DYNAMIC) {
            delete m_swingDetector;
        }
    }

    bool Initialize() {
        return m_swingDetector.Initialize();
    }

    bool Update() {
        m_swingDetector.DetectNewSwings();
        UpdateData();
        return true;
    }

    ENUM_TREND_TYPE GetTrend() {
        return m_data.trend;
    }

    ENUM_STRUCTURE_EVENT DetectStructureEvent() {
        if(m_data.bullishBOS) return STRUCT_BOS_BULLISH;
        if(m_data.bearishBOS) return STRUCT_BOS_BEARISH;
        if(m_data.bullishCHOCH) return STRUCT_CHOCH_BULLISH;
        if(m_data.bearishCHOCH) return STRUCT_CHOCH_BEARISH;
        return STRUCT_NONE;
    }

    double GetLastHigherHigh() {
        return m_data.lastHigherHigh;
    }

    double GetLastHigherLow() {
        return m_data.lastHigherLow;
    }

    double GetLastLowerHigh() {
        return m_data.lastLowerHigh;
    }

    double GetLastLowerLow() {
        return m_data.lastLowerLow;
    }

    bool IsBullishBOS() {
        return m_data.bullishBOS;
    }

    bool IsBearishBOS() {
        return m_data.bearishBOS;
    }

    bool IsBullishCHOCH() {
        return m_data.bullishCHOCH;
    }

    bool IsBearishCHOCH() {
        return m_data.bearishCHOCH;
    }

    bool IsUptrend() {
        return m_data.trend == TREND_UP;
    }

    bool IsDowntrend() {
        return m_data.trend == TREND_DOWN;
    }

    bool IsRanging() {
        return m_data.trend == TREND_RANGING;
    }

    MarketStructureData GetData() {
        return m_data;
    }

    datetime GetLastUpdate() {
        return m_data.lastUpdate;
    }

    CSwingDetector* GetSwingDetector() {
        return m_swingDetector;
    }
};

#endif
