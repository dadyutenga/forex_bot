//+------------------------------------------------------------------+
//|                                              TradeManager.mqh     |
//|              APA Trading System - Trade Execution & Management    |
//+------------------------------------------------------------------+
#property copyright "APA Trading System"
#property link      ""
#property version   "1.00"

#ifndef TRADE_MANAGER_MQH
#define TRADE_MANAGER_MQH

struct TradeSetup {
    ENUM_TRADE_DIRECTION direction;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double lotSize;
    string comment;
    bool isActive;
    datetime setupTime;
    double invalidationLevel;
};

class CTradeManager {
private:
    int m_magicNumber;
    string m_symbol;
    bool m_useTrailingStop;
    double m_trailingStartPips;
    double m_trailingStepPips;
    bool m_usePartialTP;
    double m_partialTPPercent;
    double m_partialTPRR;

    TradeSetup m_currentSetup;
    ulong m_currentTicket;
    bool m_hasPosition;

    bool ValidateSetup(TradeSetup &setup) {
        if(setup.entryPrice <= 0) return false;
        if(setup.stopLoss <= 0) return false;
        if(setup.takeProfit <= 0) return false;
        if(setup.lotSize <= 0) return false;
        return true;
    }

    bool SendOrder(TradeSetup &setup) {
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = m_symbol;
        request.volume = setup.lotSize;
        request.type = (setup.direction == TRADE_LONG) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        request.price = (setup.direction == TRADE_LONG) ? 
            SymbolInfoDouble(m_symbol, SYMBOL_ASK) : 
            SymbolInfoDouble(m_symbol, SYMBOL_BID);
        request.sl = setup.stopLoss;
        request.tp = setup.takeProfit;
        request.deviation = 10;
        request.magic = m_magicNumber;
        request.comment = setup.comment;
        
        if(!OrderSend(request, result)) {
            Print("OrderSend failed: ", GetLastError());
            Print("Result: ", result.retcode);
            return false;
        }
        
        m_currentTicket = result.order;
        return true;
    }

public:
    CTradeManager(int magic, string sym, bool trailing = false, double trailStart = 0, double trailStep = 0,
                  bool partialTP = false, double partialPercent = 0, double partialRR = 0) {
        m_magicNumber = magic;
        m_symbol = sym;
        m_useTrailingStop = trailing;
        m_trailingStartPips = trailStart;
        m_trailingStepPips = trailStep;
        m_usePartialTP = partialTP;
        m_partialTPPercent = partialPercent;
        m_partialTPRR = partialRR;
        
        m_currentSetup.isActive = false;
        m_currentTicket = 0;
        m_hasPosition = false;
    }

    ~CTradeManager() {
    }

    bool Initialize() {
        return true;
    }

    bool PrepareEntry(ENUM_TRADE_DIRECTION dir, double entry, double sl, double tp, double lots, string comment = "") {
        m_currentSetup.direction = dir;
        m_currentSetup.entryPrice = entry;
        m_currentSetup.stopLoss = sl;
        m_currentSetup.takeProfit = tp;
        m_currentSetup.lotSize = lots;
        m_currentSetup.comment = comment;
        m_currentSetup.isActive = true;
        m_currentSetup.setupTime = TimeCurrent();
        m_currentSetup.invalidationLevel = sl;
        
        return ValidateSetup(m_currentSetup);
    }

    bool ExecuteTrade() {
        if(!m_currentSetup.isActive) return false;
        
        if(!SendOrder(m_currentSetup)) {
            m_currentSetup.isActive = false;
            return false;
        }
        
        m_hasPosition = true;
        return true;
    }

    bool HasOpenPosition() {
        if(!PositionSelect(m_symbol)) {
            m_hasPosition = false;
            return false;
        }
        
        ulong posMagic = PositionGetInteger(POSITION_MAGIC);
        if(posMagic != m_magicNumber) {
            m_hasPosition = false;
            return false;
        }
        
        m_hasPosition = true;
        return true;
    }

    bool ClosePosition() {
        if(!HasOpenPosition()) return false;
        
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = m_symbol;
        request.volume = PositionGetDouble(POSITION_VOLUME);
        request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
            ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        request.price = (request.type == ORDER_TYPE_SELL) ? 
            SymbolInfoDouble(m_symbol, SYMBOL_BID) : 
            SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        request.deviation = 10;
        request.magic = m_magicNumber;
        request.comment = "Close by EA";
        
        if(!OrderSend(request, result)) {
            Print("ClosePosition failed: ", GetLastError());
            return false;
        }
        
        m_hasPosition = false;
        return true;
    }

    bool ModifyPosition(double newSL, double newTP) {
        if(!HasOpenPosition()) return false;
        
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_MODIFY;
        request.symbol = m_symbol;
        request.order = PositionGetInteger(POSITION_TICKET);
        request.sl = newSL;
        request.tp = newTP;
        
        if(!OrderSend(request, result)) {
            Print("ModifyPosition failed: ", GetLastError());
            return false;
        }
        
        return true;
    }

    double GetCurrentProfit() {
        if(!HasOpenPosition()) return 0;
        return PositionGetDouble(POSITION_PROFIT);
    }

    double GetCurrentEntryPrice() {
        if(!HasOpenPosition()) return 0;
        return PositionGetDouble(POSITION_PRICE_OPEN);
    }

    double GetCurrentStopLoss() {
        if(!HasOpenPosition()) return 0;
        return PositionGetDouble(POSITION_SL);
    }

    double GetCurrentTakeProfit() {
        if(!HasOpenPosition()) return 0;
        return PositionGetDouble(POSITION_TP);
    }

    ENUM_POSITION_TYPE GetCurrentPositionType() {
        if(!HasOpenPosition()) return POSITION_TYPE_BUY;
        return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    }

    double GetCurrentLotSize() {
        if(!HasOpenPosition()) return 0;
        return PositionGetDouble(POSITION_VOLUME);
    }

    bool IsLongPosition() {
        return HasOpenPosition() && (GetCurrentPositionType() == POSITION_TYPE_BUY);
    }

    bool IsShortPosition() {
        return HasOpenPosition() && (GetCurrentPositionType() == POSITION_TYPE_SELL);
    }

    bool ApplyTrailingStop() {
        if(!m_useTrailingStop || !HasOpenPosition()) return false;
        
        double currentSL = GetCurrentStopLoss();
        double currentTP = GetCurrentTakeProfit();
        double entryPrice = GetCurrentEntryPrice();
        double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        
        double newSL = currentSL;
        
        if(IsLongPosition()) {
            double profitPips = (bid - entryPrice) / point;
            if(profitPips >= m_trailingStartPips) {
                newSL = MathMax(currentSL, bid - m_trailingStepPips * point);
            }
        } else if(IsShortPosition()) {
            double profitPips = (entryPrice - ask) / point;
            if(profitPips >= m_trailingStartPips) {
                newSL = MathMin(currentSL, ask + m_trailingStepPips * point);
            }
        }
        
        if(newSL != currentSL) {
            return ModifyPosition(newSL, currentTP);
        }
        
        return true;
    }

    bool CheckPartialTP() {
        if(!m_usePartialTP || !HasOpenPosition()) return false;
        
        double entryPrice = GetCurrentEntryPrice();
        double currentSL = GetCurrentStopLoss();
        double currentTP = GetCurrentTakeProfit();
        double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        
        double slDistance = MathAbs(entryPrice - currentSL);
        double targetDistance = slDistance * m_partialTPRR;
        
        double currentDistance;
        if(IsLongPosition()) {
            currentDistance = bid - entryPrice;
        } else {
            currentDistance = entryPrice - ask;
        }
        
        if(currentDistance >= targetDistance) {
            double currentLots = GetCurrentLotSize();
            double closeLots = currentLots * (m_partialTPPercent / 100.0);
            closeLots = MathFloor(closeLots / SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP)) * 
                        SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
            
            if(closeLots >= SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN)) {
                MqlTradeRequest request = {};
                MqlTradeResult result = {};
                
                request.action = TRADE_ACTION_DEAL;
                request.symbol = m_symbol;
                request.volume = closeLots;
                request.type = (IsLongPosition()) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
                request.price = (IsLongPosition()) ? bid : ask;
                request.deviation = 10;
                request.magic = m_magicNumber;
                request.comment = "Partial TP";
                
                return OrderSend(request, result);
            }
        }
        
        return true;
    }

    void ResetSetup() {
        m_currentSetup.isActive = false;
    }

    TradeSetup GetCurrentSetup() {
        return m_currentSetup;
    }

    ulong GetCurrentTicket() {
        return m_currentTicket;
    }
};

#endif
