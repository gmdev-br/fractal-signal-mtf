//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Fractal signal MTF"

#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input string                  inputAtivo = "";
input int                     LevDP = 2;       // Fractal Period or Levels Demar Pint
input int                     qSteps = 40;     // Number  Trendlines per UpTrend or DownTrend
input int                     BackStep = 0;  // Number of Steps Back
input int                     showBars = 10000; // Bars Back To Draw
input int                     ArrowCodeUp = 233;
input int                     ArrowCodeDown = 234;
input bool                    plotMarkers = false;
input int                     historicBars = 300;
input color                   UpTrendColorHistoric = clrLime;
input color                   DownTrendColorHistoric = clrRed;
input color                   UpTrendColorRecent = clrDodgerBlue;
input color                   DownTrendColorRecent = clrOrange;
input color                   buyFractalColor = clrLime;
input color                   sellFractalColor = clrRed;
input int                     colorFactor = 160;
input int                     TrendlineWidth = 1;
input ENUM_LINE_STYLE         TrendlineStyle = STYLE_SOLID;
input string                  UniqueID  = "trendline"; // Indicator unique ID
input int                     WaitMilliseconds = 10000;  // Timer (milliseconds) for recalculation
input double                  fatorLimitadorHistoric = 5;
input double                  fatorLimitadorRecent = 5;
input double                  dolar1 = 5.1574;
input double                  dolar2 = 5.3952;
input bool                    enable1m = true;
input bool                    enable5m = true;
input bool                    enable15m = true;
input bool                    enable30m = true;
input bool                    enable60m = true;
input bool                    enable120m = true;
input bool                    enable240m = true;
input bool                    enableD = true;
input bool                    enableW = true;
input bool                    enableMN = true;
input int                     boxNumber = 4;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double temp1[], Buf1[], Fractal1[];
double temp2[], Buf2[], Fractal2[];
double precoAtual;

string ativo;
int _showBars = showBars;
ENUM_TIMEFRAMES periodo;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {

   ativo = inputAtivo;
   StringToUpper(ativo);
   if (ativo == "")
      ativo = _Symbol;

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);

   SetIndexBuffer(0, Fractal1, INDICATOR_DATA);
   ArraySetAsSeries(Fractal1, true);

   SetIndexBuffer(1, Fractal2, INDICATOR_DATA);
   ArraySetAsSeries(Fractal2, true);

   SetIndexBuffer(2, Buf1, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(Buf1, true);

   SetIndexBuffer(3, Buf2, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(Buf2, true);

   SetIndexBuffer(4, temp1, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(temp1, true);

   SetIndexBuffer(5, temp2, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(temp2, true);

   if (plotMarkers) {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_ARROW);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
   } else {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
   }

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);

   PlotIndexSetInteger(0, PLOT_LINE_COLOR, sellFractalColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, buyFractalColor);

   PlotIndexSetInteger(0, PLOT_ARROW, ArrowCodeDown);
   PlotIndexSetInteger(1, PLOT_ARROW, ArrowCodeUp);

   EventSetMillisecondTimer(WaitMilliseconds);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int  reason) {

   delete(_updateTimer);
   ObjectsDeleteAll(0, "label_");
   ChartRedraw();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update(ENUM_TIMEFRAMES p_tf, int row) {


   long totalRates = SeriesInfoInteger(ativo, p_tf, SERIES_BARS_COUNT);
   double onetick = SymbolInfoDouble(ativo, SYMBOL_TRADE_TICK_VALUE);

//   int tempVar = CopyLow(NULL, p_tf, 0, totalRates, arrayLow);
//   tempVar = CopyClose(NULL, p_tf, 0, totalRates, arrayClose);
//   tempVar = CopyHigh(NULL, p_tf, 0, totalRates, arrayHigh);
//   tempVar = CopyOpen(NULL, p_tf, 0, totalRates, arrayOpen);
//
//   ArrayReverse(arrayLow);
//   ArrayReverse(arrayClose);
//   ArrayReverse(arrayHigh);
//   ArrayReverse(arrayOpen);
//
//   ArraySetAsSeries(arrayOpen, true);
//   ArraySetAsSeries(arrayLow, true);
//   ArraySetAsSeries(arrayClose, true);
//   ArraySetAsSeries(arrayHigh, true);

   ArrayInitialize(temp1, 0.0);
   ArrayInitialize(temp2, 0.0);
   ArrayInitialize(Buf1, 0.0);
   ArrayInitialize(Buf2, 0.0);
   ArrayInitialize(Fractal1, 0.0);
   ArrayInitialize(Fractal2, 0.0);

//ArrayResize(Buf1, totalRates);

   string tipo[];

   precoAtual = iClose(ativo, PERIOD_CURRENT, 0);

   static datetime prevTime = 0;
//if(prevTime != iTime(_Symbol, PERIOD_CURRENT, 0)) { // New Bar
   int cnt = 0;
   if(_showBars == 0 || _showBars > totalRates - 1)
      _showBars = totalRates - 1;

   for(cnt = _showBars; cnt > LevDP; cnt--) {
      temp1[cnt] = DemHigh(cnt, LevDP, p_tf);
      temp2[cnt] = DemLow(cnt, LevDP, p_tf);
      Buf1[cnt] = DemHigh(cnt, LevDP, PERIOD_CURRENT);
      Buf2[cnt] = DemLow(cnt, LevDP, PERIOD_CURRENT);
      Fractal1[cnt] =  temp1[cnt];
      Fractal2[cnt] =  temp2[cnt];
   }

   int count = 0;
   int n_last = boxNumber;
   int largura = 20;
   int altura = 20;

   int x = 5;
   int y = 10;
   int offset = 30;
   ArrayResize(tipo, n_last);

//SetPanel("label_" + GetTimeFrame(p_tf), 0, x, y, largura * 2, altura - 3, clrNONE, clrWhite, 1);
//ObjectSetString(0, "label_" + GetTimeFrame(p_tf), OBJPROP_TEXT, GetTimeFrame(p_tf) );
   SetText("label_" + GetTimeFrame(p_tf), GetTimeFrame(p_tf), x, (row * altura / 10) * y, clrWhite, 12, GetTimeFrame(p_tf));

   for(int i = 0; i < ArraySize(Fractal1) - 1; i++) {
      if (count == n_last)
         break;

      if (Fractal1[i] > 0 && !Fractal2[i] > 0) {
         tipo[count] = "bearish";
         string name = "label_" + GetTimeFrame(p_tf) + "_" + i;
         SetPanel(name, 0, offset + x * ((n_last - count) * 4), (row * altura / 10) * y, largura, altura - 1, clrRed, clrBlack, 1);
         //Print(tipo[count]);
         count++;
      } else if (Fractal2[i] > 0 && !Fractal1[i] > 0) {
         tipo[count] = "bullish";
         string name = "label_" + GetTimeFrame(p_tf) + "_" + i;
         SetPanel(name, 0, offset + x * ((n_last - count) * 4), (row * altura / 10) * y, largura, altura - 1, clrLime, clrBlack, 1);
         //Print(tipo[count]);
         count++;
      }

   }

//prevTime = iTime(_Symbol, PERIOD_CURRENT, 0);
//}
   ChartRedraw();

   return true;
}

//+------------------------------------------------------------------+
//| Draw a Panel1with given color for a symbol                       |
//+------------------------------------------------------------------+
void SetPanel(string name, int sub_window, int x, int y, int width, int height, color bg_color, color border_clr, int border_width) {
   if(ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, sub_window, 0, 0)) {
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_COLOR, border_clr);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      //ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, neutralColor);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, border_width);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, 0);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
   }
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_color);
}

//+------------------------------------------------------------------+
//| Draw data about a symbol in a Panel1                             |
//+------------------------------------------------------------------+
void SetText(string name, string text, int x, int y, color colour, int fontsize = 12, string tooltip = "\n") {
   if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) {
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_COLOR, colour);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      if (enable1m) Update(PERIOD_M1, 1);
      if (enable5m) Update(PERIOD_M5, 2);
      if (enable15m) Update(PERIOD_M15, 3);
      if (enable30m) Update(PERIOD_M30, 4);
      if (enable60m) Update(PERIOD_H1, 5);
      if (enable120m) Update(PERIOD_H2, 6);
      if (enable240m) Update(PERIOD_H4, 7);
      if (enableD) Update(PERIOD_D1, 8);
      if (enableW) Update(PERIOD_W1, 9);
      if (enableMN) Update(PERIOD_MN1, 10);

      _lastOK = true;
      bool debug=false;
      if (debug) Print("Regressão linear híbrida " + " " + _Symbol + ":" + GetTimeFrame(Period()) + " ok");

      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemHigh(int cnt, int sh, ENUM_TIMEFRAMES periodo) {
   if(iHigh(ativo, periodo, cnt) >= iHigh(ativo, periodo, cnt + sh) && iHigh(ativo, periodo, cnt) > iHigh(ativo, periodo, cnt - sh)) {
      if(sh > 1)
         return(DemHigh(cnt, sh - 1, periodo));
      else
         return(iHigh(ativo, periodo, cnt));
   } else
      return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemLow(int cnt, int sh, ENUM_TIMEFRAMES periodo) {
   if(iLow(ativo, periodo, cnt) <= iLow(ativo, periodo, cnt + sh) && iLow(ativo, periodo, cnt) < iLow(ativo, periodo, cnt - sh)) {
      if(sh > 1)
         return(DemLow(cnt, sh - 1, periodo));
      else
         return(iLow(ativo, periodo, cnt));
   } else
      return(0);
}

//+------------------------------------------------------------------+

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {

   if(id == CHARTEVENT_CHART_CHANGE) {
      _lastOK = false;
      CheckTimer();
      return;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

bool _lastOK = false;
MillisecondTimer *_updateTimer;
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
