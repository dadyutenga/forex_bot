//+------------------------------------------------------------------+
//|                                             VisualManager.mqh     |
//|              APA Trading System - Chart Visualization             |
//+------------------------------------------------------------------+
#property copyright "APA Trading System"
#property link      ""
#property version   "1.00"

#ifndef VISUAL_MANAGER_MQH
#define VISUAL_MANAGER_MQH

class CVisualManager {
private:
    string m_symbol;
    bool m_enableVisuals;
    color m_colorBuySignal;
    color m_colorSellSignal;
    color m_colorStructure;
    color m_colorSwingHigh;
    color m_colorSwingLow;
    color m_colorZone;
    int m_lineWidth;
    string m_prefix;

    string GenerateObjectName(string base) {
        return m_prefix + "_" + base + "_" + IntegerToString(TimeCurrent());
    }

    void DeleteOldObjects() {
        string prefix = m_prefix + "_";
        int totalObjects = ObjectsTotal(ChartID());
        
        for(int i = totalObjects - 1; i >= 0; i--) {
            string name = ObjectName(ChartID(), i);
            if(StringFind(name, prefix) == 0) {
                ObjectDelete(ChartID(), name);
            }
        }
    }

public:
    CVisualManager(string sym, bool enable, color buyColor = clrGreen, color sellColor = clrRed,
                   color structColor = clrYellow, int width = 2) {
        m_symbol = sym;
        m_enableVisuals = enable;
        m_colorBuySignal = buyColor;
        m_colorSellSignal = sellColor;
        m_colorStructure = structColor;
        m_colorSwingHigh = clrRed;
        m_colorSwingLow = clrBlue;
        m_colorZone = clrGray;
        m_lineWidth = width;
        m_prefix = "APA_" + sym;
    }

    ~CVisualManager() {
    }

    bool Initialize() {
        if(!m_enableVisuals) return true;
        DeleteOldObjects();
        return true;
    }

    void DrawSwingPoint(double price, datetime time, ENUM_SWING_TYPE type) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName((type == SWING_HIGH) ? "SwingHigh" : "SwingLow");
        color objColor = (type == SWING_HIGH) ? m_colorSwingHigh : m_colorSwingLow;
        
        ObjectCreate(ChartID(), name, OBJ_ARROW, 0, time, price);
        ObjectSetInteger(ChartID(), name, OBJPROP_ARROWCODE, (type == SWING_HIGH) ? 119 : 120);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, objColor);
        ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 3);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
    }

    void DrawStructureLine(double price1, datetime time1, double price2, datetime time2, bool isBullish) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("StructureLine");
        color objColor = isBullish ? m_colorBuySignal : m_colorSellSignal;
        
        ObjectCreate(ChartID(), name, OBJ_TREND, 0, time1, price1, time2, price2);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, objColor);
        ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, m_lineWidth);
        ObjectSetInteger(ChartID(), name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
        ObjectSetInteger(ChartID(), name, OBJPROP_RAY_RIGHT, false);
    }

    void DrawInvalidationZone(double high, double low, datetime startTime, datetime endTime) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("InvalidationZone");
        
        ObjectCreate(ChartID(), name, OBJ_RECTANGLE, 0, startTime, high, endTime, low);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, m_colorZone);
        ObjectSetInteger(ChartID(), name, OBJPROP_BGCOLOR, m_colorZone);
        ObjectSetInteger(ChartID(), name, OBJPROP_FILL, true);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
        ObjectSetInteger(ChartID(), name, OBJPROP_TRANSP, 70);
    }

    void DrawEntryArrow(datetime time, double price, int direction) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("EntryArrow");
        color objColor = (direction == 1) ? m_colorBuySignal : m_colorSellSignal;
        int arrowCode = (direction == 1) ? 241 : 242;
        
        ObjectCreate(ChartID(), name, OBJ_ARROW, 0, time, price);
        ObjectSetInteger(ChartID(), name, OBJPROP_ARROWCODE, arrowCode);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, objColor);
        ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 4);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
    }

    void DrawStopLoss(datetime time, double price, int direction) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("StopLoss");
        color objColor = (direction == 1) ? m_colorSellSignal : m_colorBuySignal;
        
        ObjectCreate(ChartID(), name, OBJ_HLINE, 0, 0, price);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, objColor);
        ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(ChartID(), name, OBJPROP_STYLE, STYLE_DASH);
    }

    void DrawTakeProfit(datetime time, double price, int direction) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("TakeProfit");
        color objColor = (direction == 1) ? m_colorBuySignal : m_colorSellSignal;
        
        ObjectCreate(ChartID(), name, OBJ_HLINE, 0, 0, price);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, objColor);
        ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(ChartID(), name, OBJPROP_STYLE, STYLE_DASH);
    }

    void DrawInfoPanel(string text) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("InfoPanel");
        
        ObjectCreate(ChartID(), name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, 10);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrWhite);
        ObjectSetString(ChartID(), name, OBJPROP_TEXT, text);
        ObjectSetString(ChartID(), name, OBJPROP_FONT, "Arial");
        ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, 10);
    }

    void DrawBOSIndicator(bool isBullish) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("BOSIndicator");
        color objColor = isBullish ? m_colorBuySignal : m_colorSellSignal;
        
        datetime time = iTime(m_symbol, PERIOD_CURRENT, 0);
        double price = iClose(m_symbol, PERIOD_CURRENT, 0);
        
        ObjectCreate(ChartID(), name, OBJ_ARROW, 0, time, price);
        ObjectSetInteger(ChartID(), name, OBJPROP_ARROWCODE, isBullish ? 233 : 234);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, objColor);
        ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 3);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
    }

    void DrawCHOCHIndicator(bool isBullish) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("CHOCHIndicator");
        color objColor = isBullish ? m_colorBuySignal : m_colorSellSignal;
        
        datetime time = iTime(m_symbol, PERIOD_CURRENT, 0);
        double price = iClose(m_symbol, PERIOD_CURRENT, 0);
        
        ObjectCreate(ChartID(), name, OBJ_ARROW, 0, time, price);
        ObjectSetInteger(ChartID(), name, OBJPROP_ARROWCODE, isBullish ? 225 : 226);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, objColor);
        ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 3);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
    }

    void DrawTrendLine(double price, datetime time, int direction) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("TrendLine");
        color objColor = (direction == 1) ? m_colorBuySignal : m_colorSellSignal;
        
        ObjectCreate(ChartID(), name, OBJ_ARROW, 0, time, price);
        ObjectSetInteger(ChartID(), name, OBJPROP_ARROWCODE, (direction == 1) ? 117 : 118);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, objColor);
        ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
    }

    void DrawSupplyZone(double high, double low, datetime startTime, datetime endTime) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("SupplyZone");
        
        ObjectCreate(ChartID(), name, OBJ_RECTANGLE, 0, startTime, high, endTime, low);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, m_colorSellSignal);
        ObjectSetInteger(ChartID(), name, OBJPROP_BGCOLOR, m_colorSellSignal);
        ObjectSetInteger(ChartID(), name, OBJPROP_FILL, true);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
        ObjectSetInteger(ChartID(), name, OBJPROP_TRANSP, 70);
    }

    void DrawDemandZone(double high, double low, datetime startTime, datetime endTime) {
        if(!m_enableVisuals) return;
        
        string name = GenerateObjectName("DemandZone");
        
        ObjectCreate(ChartID(), name, OBJ_RECTANGLE, 0, startTime, high, endTime, low);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, m_colorBuySignal);
        ObjectSetInteger(ChartID(), name, OBJPROP_BGCOLOR, m_colorBuySignal);
        ObjectSetInteger(ChartID(), name, OBJPROP_FILL, true);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
        ObjectSetInteger(ChartID(), name, OBJPROP_TRANSP, 70);
    }

    void ClearAll() {
        DeleteOldObjects();
    }

    void UpdateLabels() {
    }

    void SetColors(color buyColor, color sellColor, color structColor) {
        m_colorBuySignal = buyColor;
        m_colorSellSignal = sellColor;
        m_colorStructure = structColor;
    }

    void EnableVisuals(bool enable) {
        m_enableVisuals = enable;
        if(!m_enableVisuals) {
            ClearAll();
        }
    }
};

#endif
