//+------------------------------------------------------------------+
//|                                               RiskManager.mqh     |
//|              APA Trading System - Risk & Position Management      |
//+------------------------------------------------------------------+
#property copyright "APA Trading System"
#property link      ""
#property version   "1.00"

#ifndef RISK_MANAGER_MQH
#define RISK_MANAGER_MQH

enum ENUM_TRADE_DIRECTION {
    TRADE_LONG,
    TRADE_SHORT
};

class CRiskManager {
private:
    double m_riskPercent;
    double m_maxSpreadPips;
    int m_minTPPips;
    double m_riskRewardRatio;
    double m_stopLossBufferPips;
    string m_symbol;

    double GetAccountRiskAmount() {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        return balance * (m_riskPercent / 100.0);
    }

    double GetPipValue() {
        double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
        double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        return tickValue / tickSize * point;
    }

    double NormalizeLots(double lots) {
        double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
        
        lots = MathMax(lots, minLot);
        lots = MathMin(lots, maxLot);
        lots = MathFloor(lots / lotStep) * lotStep;
        
        return lots;
    }

public:
    CRiskManager(string sym, double risk, double spread, int minTP, double rr, double slBuffer) {
        m_symbol = sym;
        m_riskPercent = risk;
        m_maxSpreadPips = spread;
        m_minTPPips = minTP;
        m_riskRewardRatio = rr;
        m_stopLossBufferPips = slBuffer;
    }

    ~CRiskManager() {
    }

    bool Initialize() {
        return true;
    }

    double CalculateLotSize(double entryPrice, double stopLoss) {
        if(entryPrice == 0 || stopLoss == 0) return 0;
        
        double riskAmount = GetAccountRiskAmount();
        double slDistance = MathAbs(entryPrice - stopLoss);
        
        if(slDistance == 0) return 0;
        
        double pipValue = GetPipValue();
        if(pipValue == 0) return 0;
        
        double lotSize = riskAmount / (slDistance / pipValue);
        
        return NormalizeLots(lotSize);
    }

    double CalculateStopLoss(ENUM_TRADE_DIRECTION dir, double invalidationLevel, double bufferPips) {
        double buffer = bufferPips * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        
        if(dir == TRADE_LONG) {
            return invalidationLevel - buffer;
        } else {
            return invalidationLevel + buffer;
        }
    }

    double CalculateTakeProfit(double entryPrice, double stopLoss, double rrRatio) {
        double slDistance = MathAbs(entryPrice - stopLoss);
        double tpDistance = slDistance * rrRatio;
        
        if(rrRatio <= 0) {
            tpDistance = m_minTPPips * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        }
        
        if(entryPrice > stopLoss) {
            return entryPrice + tpDistance;
        } else {
            return entryPrice - tpDistance;
        }
    }

    double CalculateTakeProfitRR(double entryPrice, double stopLoss) {
        return CalculateTakeProfit(entryPrice, stopLoss, m_riskRewardRatio);
    }

    bool IsSpreadAcceptable() {
        double spread = SymbolInfoDouble(m_symbol, SYMBOL_SPREAD);
        double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        double spreadInPips = spread / point;
        return (spreadInPips <= m_maxSpreadPips);
    }

    bool IsRiskAcceptable(double lots, double slPips) {
        double pipValue = GetPipValue();
        double riskAmount = lots * slPips * pipValue;
        double maxRisk = GetAccountRiskAmount();
        return (riskAmount <= maxRisk);
    }

    double GetMaxPositionSize() {
        double freeMargin = AccountInfoDouble(ACCOUNT_FREE_MARGIN);
        double marginRequirement = SymbolInfoDouble(m_symbol, SYMBOL_MARGIN_REQUIRED);
        
        if(marginRequirement == 0) return 0;
        
        double maxLots = freeMargin / marginRequirement;
        return NormalizeLots(maxLots);
    }

    bool HasEnoughMargin(double lots) {
        double marginRequired = SymbolInfoDouble(m_symbol, SYMBOL_MARGIN_REQUIRED) * lots;
        double freeMargin = AccountInfoDouble(ACCOUNT_FREE_MARGIN);
        return (freeMargin > marginRequired);
    }

    double GetRiskRewardRatio() {
        return m_riskRewardRatio;
    }

    double GetRiskPercent() {
        return m_riskPercent;
    }

    double GetMinTPPips() {
        return m_minTPPips;
    }

    double GetMaxSpreadPips() {
        return m_maxSpreadPips;
    }
};

#endif
