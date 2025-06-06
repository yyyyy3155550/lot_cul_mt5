//+------------------------------------------------------------------+
//|                                                       LotCul.mq5 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      ""
#property version   "1.00"


#include <Trade\Trade.mqh>    // 取引関数クラス CTrade を使うために追加
#include <Controls\Dialog.mqh> // GUI部品を使うために
#include <Controls\Button.mqh> // ボタンを使うために
#include <Controls\Edit.mqh>   // 編集ボックス (入力欄) を使うために
#include <Controls\Label.mqh>  // ラベル (文字表示) を使うために
#include <ChartObjects\ChartObjectsLines.mqh> //ラインを引くため
#include <Controls\Panel.mqh>     // CPanel　パネル
#include <Controls\CheckBox.mqh>  // チェックボックス



//---- グローバル変数 -------------------------
//- UI Panel -
CAppDialog UIPanel; // パネルオブジェクト
//-buy sell Button-
CButton buySellButton; // Buy/Sell切り替えボタンを追加
bool isBuyMode = true; // 現在のモード (true: Buy, false: Sell) を保持する変数を追加
//-market or limit button-
CButton marketLimitButton; // 成り行き/指値切り替えボタンを追加
bool isMarketOrder = true; // 現在の注文タイプ (true: 成り行き, false: 指値) を保持する変数を追加
//-entry Price-
CLabel entryPriceLabel;      // "Entry Price:" ラベル用
CEdit entryPriceEdit;        // 価格入力欄用
CLabel EntryKeyLabel;     // キーショートカットラベル
double entryPriceValue = 0.0; // 入力されたエントリー価格を保持する変数
//-entry Price +- buttons-
CButton entryPricePlusButton; // 価格 +1 point ボタン
CButton entryPriceMinusButton; // 価格 -1 point ボタン
//-Stop Loss-
CLabel slLabel;          // "SL Price:" ラベル
CEdit slEdit;            // SL価格入力欄
CLabel StopKeyLabel;     // キーショートカットラベル
double slValue ;     // 入力されたSL価格
CButton slPlusButton;    // SL価格 +1 point ボタン
CButton slMinusButton;   // SL価格 -1 point ボタン
//-Take Profit-
CLabel tpLabel;          // "TP Price:" ラベル
CEdit tpEdit;            // TP価格入力欄
CLabel ProfitKeyLabel;     // キーショートカットラベル
double tpValue = 0.0;     // 入力されたTP価格
CButton tpPlusButton;    // TP価格 +1 point ボタン
CButton tpMinusButton;   // TP価格 -1 point ボタン
//- risk Percent-
CLabel riskPercentLabel; //許容損失％ "risk %"ラベル
CEdit riskPercentEdit; //許容損失％入力欄
double RiskPercent = 1.00; //許容リスク％値
//- EntryPrice/ SL/ TP Lines ライン -
CChartObjectHLine entryPriceLine; //CchartObjectHLine から水平線を ET ライン
string entryPriceLineName = "LotCul_EntryLine"; // エントリー価格ラインのオブジェクト名
CChartObjectHLine slLine;           //SLライン
string slLineName = "LotCul_SlLine"; // SL価格ラインのオブジェクト名
CChartObjectHLine tpLine;          //TPライン
string tpLineName = "LotCul_TpLine"; // TP価格ラインのオブジェクト名
//- ET/SL/TP Info Labels (OBJ_LABEL) -
string etInfoLabelName = "LotCul_EtInfoLabel"; // TE情報ラベル名
string slInfoLabelName = "LotCul_SlInfoLabel"; // SL情報ラベル名
string tpInfoLabelName = "LotCul_TpInfoLabel"; // TP情報ラベル名
//- Cul Lot--
CLabel CulLotLabel; // "Lot"
CEdit CulLotEdit; // Lot 入力・表示欄
double CulLotValue = 0.0; //ロットを保持する変数
//- Risk $--
CLabel RiskUSDLabel; // ラベル "Risk $" リスクを通貨で表現
CEdit RiskUSDEdit; // Edit  "Risk $" リスクを通貨で表現
double RiskUSDValue; //　損切幅と、Risk%　→　ロットから計算される損失金額　を　保持する変数
//- Order Button--
CButton OrderButton; //発注ボタン
CLabel OrderKeyLabel; //キーショートカットラベル
//- Confirm --
CLabel ConfirmCheckBoxLabel; //チェックボックスのラベル
CCheckBox ConfirmCheckBox; //発注前の確認表示をするかしないか
//- Order send--
CTrade trade;  // 取引操作用オブジェクト
input int MAGIC_NUMBER = 20240725 ; //magic number

// --- マウスカーソル位置保存用グローバル変数 ---
long   g_mouse_last_x = 0;      // 最後に記録されたマウスのX座標
long   g_mouse_last_y = 0;      // 最後に記録されたマウスのY座標
int    g_mouse_last_subwindow = -1; // 最後に記録されたサブウィンドウ番号 (-1は無効)

// --- ライン表示/非表示用グローバル変数 ---
bool    g_showLines = true; // ライン表示状態 (true: 表示, false: 非表示)
CButton linesToggleButton;  // ライン表示切り替えボタン




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
   {
//ChartSetInteger(0, CHART_KEYBOARD_CONTROL, true);

    trade.SetExpertMagicNumber(MAGIC_NUMBER); //マジックナンバーを設定
    trade.SetDeviationInPoints(5);     //スリッページを設定　point


    EventSetMillisecondTimer(5); // OnTimer : 1000ms == 1sec

//--- SLの初期値 数値を現在価格とずらして表示させとく、かぶると見にくいから。
    slValue = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK) - (SymbolInfoDouble(_Symbol,SYMBOL_POINT) * 30),_Digits);

//===========- UIパネル関連 -===============
//--- パネルの作成 ---
// UIPanel.Create(チャートID, パネル名, サブウィンドウ番号, X座標, Y座標, X2, Y2)
    if(ObjectFind(0, "LotCul") == -1)
       {
        if(!UIPanel.Create(0, "LotCul", 0, 50, 50, 250, 400))
           {
            Print("パネルの作成に失敗しました。エラーコード: ", GetLastError());
            return(INIT_FAILED); // 初期化失敗
           }
       }

//--- Buy/Sell 切り替えボタンの作成 ---
// buySellButton.Create(チャートID, オブジェクト名, サブウィンドウ番号, X座標, Y座標, X2, Y2)
    if(!buySellButton.Create(0, "BuySellButton", 0, 15, 15, 85, 40)) // パネル内の相対座標で指定
       {
        Print("ボタンの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    buySellButton.Text("Buy"); // 初期テキストを "Buy" に設定
    if(!UIPanel.Add(buySellButton)) // ボタンをパネルに追加
       {
        Print("ボタンのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }

//--- 成り行き/指値 切り替えボタンの作成 ---
// marketLimitButton.Create(チャートID, オブジェクト名, サブウィンドウ番号, X座標, Y座標, X2, Y2)
    if(!marketLimitButton.Create(0, "MarketLimitButton", 0, 95, 15, 165, 40)) // buySellButton の隣に配置 (X座標を調整)
       {
        Print("成り行き/指値ボタンの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    marketLimitButton.Text("Market"); // 初期テキストを "Market" (成り行き) に設定
    if(!UIPanel.Add(marketLimitButton)) // ボタンをパネルに追加
       {
        Print("成り行き/指値ボタンのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }


//基準　XY
//Label
    int EditLabelX = 5;
    int EditLabelY = 50;
    int EditLabelDistance = 35;
//Edit box
    int EditBoxX1 = 75;
    int EditBoxY1 = 48;
    int EditBoxX2 = 168;
    int EditBoxY2 = 72;
    int EditBoxDistance = 35;

//--- Entry Price ラベルの作成 ---
    if(!entryPriceLabel.Create(0, "EntryPriceLabel", 0, EditLabelX, EditLabelY, 0, 0)) // ボタンの下あたりに配置
       {
        Print("Entry Price ラベルの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    entryPriceLabel.Text("Entry Price:"); // ラベルのテキストを設定
    if(!UIPanel.Add(entryPriceLabel))
       {
        Print("Entry Price ラベルのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }

//--- Entry Price 編集ボックスの作成 ---
    if(!entryPriceEdit.Create(0, "EntryPriceEdit", 0, EditBoxX1, EditBoxY1, EditBoxX2, EditBoxY2)) // ラベルの右隣に配置 83 107
       {
        Print("Entry Price ボックスの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    entryPriceEdit.Text(DoubleToString(0,_Digits));
    entryPriceValue = 0.00; // 初期値をグローバル変数にも保持
    if(!UIPanel.Add(entryPriceEdit))
       {
        Print("Entry Price ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- Entry Price +プラス ボタンの作成 ---
    if(!entryPricePlusButton.Create(0, "EntryPricePlus", 0, 170, 47, 189, 60))
       {
        Print("Entry Price + ボタンの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    entryPricePlusButton.Text("+"); // ボタンテキスト
    if(!UIPanel.Add(entryPricePlusButton))
       {
        Print("Entry Price + ボタンのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- Entry Price -マイナス ボタンの作成 ---
    if(!entryPriceMinusButton.Create(0, "EntryPriceMinus", 0, 170, 60, 189, 73))
       {
        Print("Entry Price - ボタンの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    entryPriceMinusButton.Text("-"); // ボタンテキスト
    if(!UIPanel.Add(entryPriceMinusButton))
       {
        Print("Entry Price - ボタンのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- Entry Price キーショートカット ラベルの作成 ---
    if(!EntryKeyLabel.Create(0, "EntryKeyLabel", 0, EditLabelX+72, EditLabelY+19, 0, 0))
       {
        Print("Entry Key ラベルの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    EntryKeyLabel.Text("-- E --"); // ラベルのテキストを設定
    EntryKeyLabel.FontSize(8);
    if(!UIPanel.Add(EntryKeyLabel))
       {
        Print("Entry Key ラベルのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }

//--- SL Price ラベルの作成 ---
    if(!slLabel.Create(0, "SlLabel", 0, 10, EditLabelY+EditLabelDistance, 0, 0))
       {
        Print("SL Price ラベルの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    slLabel.Text("SL Price:");
    if(!UIPanel.Add(slLabel))
       {
        Print("SL Price ラベルのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- SL Price 編集ボックスの作成 ---
    if(!slEdit.Create(0, "SlEdit", 0, EditBoxX1, EditBoxY1+(EditBoxDistance*1), EditBoxX2, EditBoxY2+(EditBoxDistance*1)))
       {
        Print("SL Price ボックスの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    slEdit.Text(DoubleToString(slValue, _Digits));
    slValue = slValue; // 初期値
    if(!UIPanel.Add(slEdit))
       {
        Print("SL Price ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- SL Price + ボタンの作成 ---
    if(!slPlusButton.Create(0, "SlPlus", 0, 170, 83, 187, 95))
       {
        Print("SL Price + ボタンの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    slPlusButton.Text("+");
    if(!UIPanel.Add(slPlusButton))
       {
        Print("SL Price + ボタンのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- SL Price - ボタンの作成 ---
    if(!slMinusButton.Create(0, "SlMinus", 0, 170, 95, 187, 107))
       {
        Print("SL Price - ボタンの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    slMinusButton.Text("-");
    if(!UIPanel.Add(slMinusButton))
       {
        Print("SL Price - ボタンのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- Stop Price キーショートカット ラベルの作成 ---
    if(!StopKeyLabel.Create(0, "StopKeyLabel", 0, EditLabelX+72, EditLabelY+54, 0, 0))
       {
        Print("Stop Key ラベルの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    StopKeyLabel.Text("-- S --"); // ラベルのテキストを設定
    StopKeyLabel.FontSize(8);
    if(!UIPanel.Add(StopKeyLabel))
       {
        Print("Stop Key ラベルのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }

//--- TP Price ラベルの作成 ---
    if(!tpLabel.Create(0, "TpLabel", 0, 10, EditLabelY+(EditLabelDistance*2), 0, 0))
       {
        Print("TP Price ラベルの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    tpLabel.Text("TP Price:");
    if(!UIPanel.Add(tpLabel))
       {
        Print("TP Price ラベルのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- TP Price 編集ボックスの作成 ---
    if(!tpEdit.Create(0, "TpEdit", 0, EditBoxX1, EditBoxY1+(EditBoxDistance*2), EditBoxX2, EditBoxY2+(EditBoxDistance*2)))
       {
        Print("TP Price ボックスの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    tpEdit.Text(DoubleToString(tpValue, _Digits));
    if(!UIPanel.Add(tpEdit))
       {
        Print("TP Price ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- TP Price + ボタンの作成 ---
    if(!tpPlusButton.Create(0, "TpPlus", 0, 170, 118, 187, 130))
       {
        Print("TP Price + ボタンの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    tpPlusButton.Text("+");
    if(!UIPanel.Add(tpPlusButton))
       {
        Print("TP Price + ボタンのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- TP Price - ボタンの作成 ---
    if(!tpMinusButton.Create(0, "TpMinus", 0, 170, 130, 187, 142))
       {
        Print("TP Price - ボタンの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    tpMinusButton.Text("-");
    if(!UIPanel.Add(tpMinusButton))
       {
        Print("TP Price - ボタンのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- Profit Price キーショートカット ラベルの作成 ---
    if(!ProfitKeyLabel.Create(0, "ProfitKeyLabel", 0, EditLabelX+72, EditLabelY+89, 0, 0))
       {
        Print("Profit Key ラベルの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    ProfitKeyLabel.Text("-- P --"); // ラベルのテキストを設定
    ProfitKeyLabel.FontSize(8);
    if(!UIPanel.Add(ProfitKeyLabel))
       {
        Print("Profit Key ラベルのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }

//--- Risk Percent Label ラベル -----
    if(!riskPercentLabel.Create(0, "riskPercentLabel", 0, 14, EditLabelY+(EditLabelDistance*3), 0, 0))
       {
        Print("riskPercentLabel - 作成失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    riskPercentLabel.Text("Risk % :");
    if(!UIPanel.Add(riskPercentLabel))
       {
        Print("riskPercentLabel ラベルのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- Risk Percent Edit 入力欄 ----
    if(!riskPercentEdit.Create(0, "riskPercentEdit", 0, EditBoxX1, EditBoxY1+(EditBoxDistance*3), EditBoxX2, EditBoxY2+(EditBoxDistance*3)))
       {
        Print("riskPercent入力欄 - 作成失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    riskPercentEdit.Text(DoubleToString(RiskPercent, 2));
    if(!UIPanel.Add(riskPercentEdit))
       {
        Print("risk% ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- Lot Label ラベル ---
    if(!CulLotLabel.Create(0, "CulLotLabel", 0, 26, EditLabelY+(EditLabelDistance*4), 0, 0))
       {
        Print("CulLotLabel - 作成失敗");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    CulLotLabel.Text("Lot :");
    if(!UIPanel.Add(CulLotLabel))
       {
        Print("CulLotLabel ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- CulLot Edit ---
    if(!CulLotEdit.Create(0, "CulLotEdit", 0, EditBoxX1, EditBoxY1+(EditBoxDistance*4), EditBoxX2, EditBoxY2+(EditBoxDistance*4)))
       {
        Print("CulLotEdit - 作成失敗");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    CulLotEdit.Text(DoubleToString(CulLotValue, 2));
    if(!UIPanel.Add(CulLotEdit))
       {
        Print("CulLotEdit ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }

//--- Risk $ Label　ラベル ---
    if(!RiskUSDLabel.Create(0, "RiskUSDLabel", 0, 26, EditLabelY+(EditLabelDistance*5), 0, 0))
       {
        Print("RiskUSDLabel - 作成失敗");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    RiskUSDLabel.Text("Risk $ :");
    if(!UIPanel.Add(RiskUSDLabel))
       {
        Print("RiskUSDLabel ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- Risk $ Edit ---
    if(!RiskUSDEdit.Create(0, "RiskUSDEdit", 0, EditBoxX1, EditBoxY1+(EditBoxDistance*5), EditBoxX2, EditBoxY2+(EditBoxDistance*5)))
       {
        Print("RiskUSDEdit - 作成失敗");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    RiskUSDEdit.Text(DoubleToString(RiskUSDValue, 2));
// 読み取り専用にして、背景をグレーにする
    RiskUSDEdit.ReadOnly(true);
    RiskUSDEdit.ColorBackground(clrLightGray);
    if(!UIPanel.Add(RiskUSDEdit))
       {
        Print("RiskUSDEdit ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }

//--- ConfirmCheckBox　Label ---
    if(!ConfirmCheckBoxLabel.Create(0, "OrderConfirmCheckBoxLabel", 0, 10, EditLabelY+(EditLabelDistance*5)+28, 0, 0))
       {
        Print("ConfirmCheckBoxLabel - 作成失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    ConfirmCheckBoxLabel.Text("noConfirm:");
    ConfirmCheckBoxLabel.FontSize(9);
//ConfirmCheckBoxLabel.Color(clrRed);
    if(!UIPanel.Add(ConfirmCheckBoxLabel))
       {
        Print("ConfirmCheckBoxLabel ラベルのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- ConfirmCheckBox ---
    if(!ConfirmCheckBox.Create(0, "ConfirmCheckBox", 0, 72, EditBoxY1+(EditBoxDistance*5)+30, 92, EditBoxY2+(EditBoxDistance*5)+30))
       {
        Print("ConfirmCheckBox - 作成失敗");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    ConfirmCheckBox.Text("");
    ConfirmCheckBox.Checked(false);
    if(!UIPanel.Add(ConfirmCheckBox))
       {
        Print("ConfirmCheckBox ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }

//--- ライン表示/非表示 切り替えボタンの作成 ---
    if(!linesToggleButton.Create(0, "LinesToggleButton", 0, EditBoxX1+22, 251, EditBoxX2, 273))
       {
        Print("Lines Toggle Button 作成失敗");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    linesToggleButton.Text(g_showLines ? "Lines: ON" : "Lines: OFF"); // 初期テキスト設定
    linesToggleButton.FontSize(9); // フォントサイズ調整
    if(!UIPanel.Add(linesToggleButton))
       {
        Print("Lines Toggle Button パネルへの追加失敗");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }

//--- Order Button ----
    if(!OrderButton.Create(0, "OrderButton", 0, 75, 278, 168, 310))
       {
        Print("OrderButton - 作成失敗");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    OrderButton.Text("Order");
    if(!UIPanel.Add(OrderButton))
       {
        Print("OrderButton ボックスのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
//--- Order Key Label キーショートカット ラベルの作成 ---
    if(!OrderKeyLabel.Create(0, "OrderKeyLabel", 0, EditLabelX+72, EditLabelY+258, 0, 0))
       {
        Print("Profit Key ラベルの作成に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }
    OrderKeyLabel.Text("-- Shift + T --"); // ラベルのテキストを設定
    OrderKeyLabel.FontSize(8);
    if(!UIPanel.Add(OrderKeyLabel))
       {
        Print("Order Key ラベルのパネルへの追加に失敗しました。");
        UIPanel.Destroy();
        return(INIT_FAILED);
       }




//--- 初期状態を反映 ---
    UpdateEntryPriceEditBoxState();

    UpdateAllLines();


//--- パネルの実行（表示とイベント処理開始） 起動 ---
    if(!UIPanel.Run())
       {
        Print("パネルの実行に失敗しました。");
        UIPanel.Destroy(); // 作成したパネルを破棄
        return(INIT_FAILED); // 初期化失敗
       }
//===-- UIパネル関連 --------------------------------------


//---
    return(INIT_SUCCEEDED);
   }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
   {
// --- 終了理由コードをログに出力 ---
    string reason_str = "Unknown reason";
    switch(reason)
       {
        case REASON_REMOVE:
            reason_str = "REASON_REMOVE (EA removed from chart)";
            break;
        case REASON_RECOMPILE:
            reason_str = "REASON_RECOMPILE";
            break;
        case REASON_CHARTCHANGE:
            reason_str = "REASON_CHARTCHANGE (Symbol or Period changed)";
            break; // 通常の時間足変更はこれのはず
        case REASON_CHARTCLOSE:
            reason_str = "REASON_CHARTCLOSE";
            break;
        case REASON_PARAMETERS:
            reason_str = "REASON_PARAMETERS (Input parameters changed)";
            break;
        case REASON_ACCOUNT:
            reason_str = "REASON_ACCOUNT";
            break;
        case REASON_TEMPLATE:
            reason_str = "REASON_TEMPLATE";
            break;
        case REASON_INITFAILED:
            reason_str = "REASON_INITFAILED";
            break;
        case REASON_CLOSE:
            reason_str = "REASON_CLOSE (Terminal closed)";
            break;
       }
    Print("OnDeinit called. Reason: ", reason, " (", reason_str, ")");
//---------------------


// Line Delete

    entryPriceLine.Delete(); //ライブラリの機能で消す機能まで内蔵 すげ

    slLine.Delete();
    tpLine.Delete();
// Line Label Delete
    DeleteEtSlTpInfoLabels();

//---終了時 パネルの破棄 ---
    UIPanel.Destroy(reason); //引数なしでいくとタイムフレーム変更でなぜかEA勝手に削除される。reasonを入れることでやっと解決。。。。。


    EventKillTimer();

    ChartRedraw();

   }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {


   }

//+------------------------------------------------------------------+
//| On Timer function                                         |
//+------------------------------------------------------------------+
void OnTimer()
   {

//--- 成り行き注文モードの場合のみ、価格表示を更新 ---
    if(isMarketOrder)
       {
        UpdateEntryPriceEditBoxState();
       }

    CalculateLotSizeAndRisk();

//UpdateAllLines(); //timer高頻度呼び出しすると、挙動が悪くなる。あと特に必要もない

//UpdateEntryPriceEditBoxState();

// --- ラインが表示されている場合のみラベルを更新 --- 修正
    if(g_showLines)
       {
        UpdateEtSlTpInfoLabels();
       }
   }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
   {
//---

   }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
   {
//---

   }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
   {


// --- マウス移動イベント: 座標をグローバル変数に保存 ---
    if(id == CHARTEVENT_MOUSE_MOVE)
       {
        g_mouse_last_x = lparam;          // X座標を保存
        g_mouse_last_y = (long)dparam;    // Y座標を保存 (dparamはdoubleなのでlongにキャスト)

        // サブウィンドウ番号も取得して保存する
        datetime time_dummy;
        double price_dummy;
        // ChartXYToTimePriceを使って、座標がどのサブウィンドウにあるかを特定
        if(!ChartXYToTimePrice(0, (int)g_mouse_last_x, (int)g_mouse_last_y, g_mouse_last_subwindow, time_dummy, price_dummy))
           {
            // 座標からサブウィンドウの特定に失敗した場合（チャート外など）は無効にする
            g_mouse_last_subwindow = -1;
           }
        // PrintFormat("Mouse Move: X=%d, Y=%d, SubWindow=%d", g_mouse_last_x, g_mouse_last_y, g_mouse_last_subwindow); // デバッグ用

        // マウス移動イベント自体で他の処理を止めないように、ここでは return しない
       }

//--- Key ---
    if(id == CHARTEVENT_KEYDOWN)
       {
        // デバッグ用: どんなキーが押されたかログに出力
        // PrintFormat("キーイベント: id=%d, lparam=%d, dparam=%.f, sparam=%s", id, lparam, dparam, sparam);

        //-- T --
        // 1. 押されたキーが 'T' かどうかをチェック
        //    lparam には押されたキーの番号 (仮想キーコード) が入っています。
        //    'T' のキーコードは 84 です。
        bool isTKeyPressed = (lparam == 84);

        //-- Shift --
        //    dparam には修飾キー (Shift, Ctrl, Alt) の状態が入っています。
        //    ビット演算 (&) を使って、Shift キーに対応するビット (1) が立っているか確認します。
        //    dparam は double型ですが、ここでは整数として扱います。
        bool isShiftPressed = (((int)dparam & 1) != 0); // Shiftキーはビット 0 (値は 1)



        //-- 'T' キー と Shift キーが両方押されていた場合の処理
        if(isTKeyPressed && isShiftPressed)
           {
            //Print("Shift + T が押されました"); //デバッグ用

            //=== 発注 ====
            //--- 確認チェックボックスの状態を確認 ---
            bool skipConfirm = ConfirmCheckBox.Checked(); // チェックが入っていれば true (確認スキップ)
            //--- 確認が必要な場合 ---
            if(!skipConfirm)
               {
                // 確認メッセージボックスを表示
                string confirmMsg = StringFormat("Order Confirm:\nSymbol: %s\nType: %s %s\nLot: %.2f\nEntry: %s\nSL: %s\nTP: %s",
                                                 _Symbol,
                                                 (isMarketOrder ? "Market" : "Limit"),
                                                 (isBuyMode ? "Buy" : "Sell"),
                                                 CulLotValue,
                                                 (isMarketOrder ? "Current" : DoubleToString(entryPriceValue, _Digits)),
                                                 (slValue > 0 ? DoubleToString(slValue, _Digits) : "None"),
                                                 (tpValue > 0 ? DoubleToString(tpValue, _Digits) : "None"));
                // Yes/No ボタン付きのメッセージボックス
                int result = MessageBox(confirmMsg, "Confirm Order", MB_YESNO | MB_ICONQUESTION);

                // "No" が押されたら何もしないで終了
                if(result != IDYES)
                   {
                    Print("Order cancelled by user.");
                    UIPanel.ChartEvent(id,lparam,dparam,sparam);
                    return; // イベント処理完了
                   }
                else
                   {
                    SendOrder(); //発注
                    UIPanel.ChartEvent(id,lparam,dparam,sparam);
                    return;
                   }
               }
            SendOrder(); //発注
            UIPanel.ChartEvent(id,lparam,dparam,sparam);
            return;
           }

        // --- マウスカーソル位置の価格を取得する準備 (グローバル変数を使用) ---
        long chart_id = ChartID();
        double price_at_cursor = 0.0;
        datetime time_at_cursor = 0; // 時間は今回は使わない
        bool cursor_price_valid = false; // 価格が取得できたかどうかのフラグ

        // 保存しておいたマウス座標とサブウィンドウ番号が有効かチェック
        if(g_mouse_last_subwindow >= 0)
           {
            // 保存しておいた座標を使って価格に変換
            if(ChartXYToTimePrice(chart_id, (int)g_mouse_last_x, (int)g_mouse_last_y, g_mouse_last_subwindow, time_at_cursor, price_at_cursor))
               {
                // メインチャート (サブウィンドウ番号 0) でのみ価格を有効とする
                if(g_mouse_last_subwindow == 0)
                   {
                    cursor_price_valid = true;
                    price_at_cursor = NormalizeDouble(price_at_cursor, _Digits); // 桁数正規化
                   }
               }
           }

        // --- E, S, P キーの処理 ---
        if(cursor_price_valid)  // マウスカーソル下の価格が正常に取得できた場合のみ
           {
            // --- 'E' キー: Entry Price 設定 ---
            if(lparam == 69) // 'E' のキーコードは 69
               {
                // 指値注文モードの場合のみエントリー価格を設定
                if(!isMarketOrder)
                   {
                    entryPriceValue = price_at_cursor;
                    entryPriceEdit.Text(DoubleToString(entryPriceValue, _Digits));
                    Print("Entry Price set to cursor price: ", entryPriceValue);
                    UpdateAllLines();           // ライン表示を更新
                    CalculateLotSizeAndRisk(); // ロットとリスクを再計算
                   }
                else
                   {
                    Print("Cannot set Entry Price in Market order mode via hotkey.");
                   }
                UIPanel.ChartEvent(id,lparam,dparam,sparam);
                return; // Eキーの処理完了
               }

            // --- 'S' キー: Stop Loss 設定 ---
            if(lparam == 83) // 'S' のキーコードは 83
               {
                slValue = price_at_cursor;
                slEdit.Text(DoubleToString(slValue, _Digits));
                Print("Stop Loss set to cursor price: ", slValue);
                UpdateAllLines();           // ライン表示を更新
                CalculateLotSizeAndRisk(); // ロットとリスクを再計算
                UIPanel.ChartEvent(id,lparam,dparam,sparam);
                return; // Sキーの処理完了
               }

            // --- 'P' キー: Take Profit 設定 ---
            if(lparam == 80) // 'P' のキーコードは 80
               {
                tpValue = price_at_cursor;
                tpEdit.Text(DoubleToString(tpValue, _Digits));
                Print("Take Profit set to cursor price: ", tpValue);
                UpdateAllLines();           // ライン表示を更新 (TP更新ではロット再計算は不要)
                UIPanel.ChartEvent(id,lparam,dparam,sparam);
                return; // Pキーの処理完了
               }
           }
        else
            if(lparam == 69 || lparam == 83 || lparam == 80)  // E,S,P が押されたが価格取得に失敗した場合
               {
                Print("Failed to get price at cursor or cursor is not on the main chart window.");
                UIPanel.ChartEvent(id,lparam,dparam,sparam);
                return; // 何もせず終了
               }
       } // if(id == CHARTEVENT_KEYDOWN) の終わり


//--- buy/sell ボタンクリックイベントの処理 ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == buySellButton.Name()) // クリックされたオブジェクトがボタンか確認
       {
        isBuyMode = !isBuyMode; // モードを反転させる
        if(isBuyMode)
           {
            buySellButton.Text("Buy"); // テキストを "Buy" に変更
           }
        else
           {
            buySellButton.Text("Sell"); // テキストを "Sell" に変更
           }
        UpdateEntryPriceEditBoxState();// 状態が変わったのでUIを更新
        ChartRedraw(); // チャートを再描画してボタン表示を更新
        return; // イベント処理完了
       }

//--- 成り行き/指値ボタンクリックイベントの処理 ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == marketLimitButton.Name()) // クリックされたのが MarketLimit ボタンか確認
       {
        isMarketOrder = !isMarketOrder; // 注文タイプを反転 (trueならfalse, falseならtrueへ)
        if(isMarketOrder)
           {
            marketLimitButton.Text("Market"); // テキストを "Market" に変更
           }
        else
           {
            marketLimitButton.Text("Limit"); // テキストを "Limit" に変更

            //ETPriceラインaskとかだと見にくいから、limitmodeにしたらちょっとずらして表示
            //entryPriceValue += (SymbolInfoDouble(_Symbol,SYMBOL_POINT) * 100); //UpdateEntryPriceEditBoxState内に移転
           }
        UpdateEntryPriceEditBoxState(); // 状態が変わったのでUIを更新
        UpdateAllLines();
        CalculateLotSizeAndRisk();
        ChartRedraw(); // ボタン表示更新のためにチャート再描画
        return; // このイベント処理はここで完了
       }

//--- Entry Price 編集ボックスの入力完了イベント処理 ---
    if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == entryPriceEdit.Name()) // 編集完了イベントで、対象がEntryPriceEditか確認
       {
        string inputText = entryPriceEdit.Text(); // 入力されたテキストを取得
        double price = StringToDouble(inputText);   // テキストを double 型の数値に変換
        double normalizedPrice = NormalizeDouble(price, _Digits); // 通貨ペアの桁数に正規化(丸め)
        entryPriceEdit.Text(DoubleToString(normalizedPrice, _Digits)); //入力値に基づいて、正規化した数字を再描写。
        if(price > 0) // 簡単な入力チェック (0より大きいか)
           {
            entryPriceValue = normalizedPrice; // 有効な数値なら entryPriceValue 変数を更新
            //Print("Entry Price が更新されました: ", entryPriceValue);
           }
        else
           {
            // 入力が無効な場合 (例: 文字が入力された、0以下の数値など) は元の値に戻す
            entryPriceEdit.Text(DoubleToString(entryPriceValue, _Digits));
            Print("無効な Entry Price が入力されました: ", inputText);
           }
        UpdateAllLines();
        CalculateLotSizeAndRisk();
        // ChartRedraw(); // 通常、Editボックスの更新は自動で反映される
        return; // このイベント処理はここで完了
       }

//--- Entry Price + ボタンクリックイベント ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == entryPricePlusButton.Name())
       {
        double currentPrice = entryPriceValue; // 現在の価格を取得
        // 現在の価格に、この通貨ペアの最小価格変動単位 (Point) を加算し、桁数を正規化
        double adjustedPrice = NormalizeDouble(currentPrice + SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits);
        entryPriceValue = adjustedPrice; // 更新した価格をグローバル変数に保存
        entryPriceEdit.Text(DoubleToString(entryPriceValue, _Digits)); // Editボックスの表示を更新
        UpdateAllLines();
        CalculateLotSizeAndRisk();
        // ChartRedraw(); // ボタンやEditの表示更新は通常自動で行われるため、必須ではない
        return; // イベント処理完了
       }

//--- Entry Price - ボタンクリックイベント ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == entryPriceMinusButton.Name())
       {
        double currentPrice = entryPriceValue; // 現在の価格を取得
        // 現在の価格から、この通貨ペアの最小価格変動単位 (Point) を減算し、桁数を正規化
        double adjustedPrice = NormalizeDouble(currentPrice - SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits);
        if(adjustedPrice > 0) // 価格が0より大きいことを確認 (マイナス価格防止)
           {
            entryPriceValue = adjustedPrice; // 更新した価格をグローバル変数に保存
            entryPriceEdit.Text(DoubleToString(entryPriceValue, _Digits)); // Editボックスの表示を更新
            UpdateAllLines();
            CalculateLotSizeAndRisk();
            // ChartRedraw();
           }
        return; // イベント処理完了
       }

//--- SL Price 編集ボックスの入力完了イベント処理 ---
    if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == slEdit.Name())
       {
        string inputText = slEdit.Text();
        double price = StringToDouble(inputText);
        double normalizedPrice = NormalizeDouble(price, _Digits);
        slEdit.Text(DoubleToString(normalizedPrice, _Digits)); // 正規化した値を表示
        if(price > 0)
           {
            slValue = normalizedPrice; // 有効ならグローバル変数更新
           }
        else
           {
            slEdit.Text(DoubleToString(slValue, _Digits)); // 無効なら元の値に戻す
            Print("無効な SL Price が入力されました: ", inputText);
           }
        UpdateAllLines();
        CalculateLotSizeAndRisk();
        return;
       }
//--- SL Price + ボタンクリックイベント ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == slPlusButton.Name())
       {
        double currentPrice = slValue;
        double adjustedPrice = NormalizeDouble(currentPrice + SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits);
        slValue = adjustedPrice;
        slEdit.Text(DoubleToString(slValue, _Digits));
        UpdateAllLines();
        CalculateLotSizeAndRisk();
        return;
       }
//--- SL Price - ボタンクリックイベント ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == slMinusButton.Name())
       {
        double currentPrice = slValue;
        double adjustedPrice = NormalizeDouble(currentPrice - SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits);
        if(adjustedPrice > 0)
           {
            slValue = adjustedPrice;
            slEdit.Text(DoubleToString(slValue, _Digits));
           }
        UpdateAllLines();
        CalculateLotSizeAndRisk();
        return;
       }

//--- TP Price 編集ボックスの入力完了イベント処理 ---
    if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == tpEdit.Name())
       {
        string inputText = tpEdit.Text();
        double price = StringToDouble(inputText);
        double normalizedPrice = NormalizeDouble(price, _Digits);
        tpEdit.Text(DoubleToString(normalizedPrice, _Digits)); // 正規化した値を表示
        if(price > 0)
           {
            tpValue = normalizedPrice; // 有効ならグローバル変数更新
           }
        else
           {
            //tpEdit.Text(DoubleToString(tpValue, _Digits)); // 無効なら元の値に戻す
            //Print("無効な TP Price が入力されました: ", inputText);
            tpValue = normalizedPrice; //０なら削除
           }
        UpdateAllLines();
        return;
       }
//--- TP Price + ボタンクリックイベント ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == tpPlusButton.Name())
       {
        double currentPrice = tpValue;
        double adjustedPrice = NormalizeDouble(currentPrice + SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits);
        tpValue = adjustedPrice;
        tpEdit.Text(DoubleToString(tpValue, _Digits));
        UpdateAllLines();
        return;
       }
//--- TP Price - ボタンクリックイベント ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == tpMinusButton.Name())
       {
        double currentPrice = tpValue;
        double adjustedPrice = NormalizeDouble(currentPrice - SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits);
        if(adjustedPrice > 0)
           {
            tpValue = adjustedPrice;
            tpEdit.Text(DoubleToString(tpValue, _Digits));
           }
        UpdateAllLines();
        return;
       }

//--- Risk Percent 編集ボックスの入力完了イベント処理 ---
    if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == riskPercentEdit.Name())
       {
        string inputText = riskPercentEdit.Text();
        double percent = StringToDouble(inputText);

        // 入力値チェック (0より大きく、現実的な上限値まで。例: 100%以下)
        if(percent > 0 && percent <= 100.0)
           {
            RiskPercent = percent; // 有効な値ならグローバル変数更新
            riskPercentEdit.Text(DoubleToString(RiskPercent, 2)); // 整形して再表示
            CalculateLotSizeAndRisk(); // ロットとリスク額を再計算
           }
        else
           {
            // 無効な場合は元の値に戻す
            riskPercentEdit.Text(DoubleToString(RiskPercent, 2));
            Print("無効な Risk Percent が入力されました: ", inputText);
           }
        return; // イベント処理完了
       }


//--- エントリーラインのドラッグイベント処理 ---
    if(id == CHARTEVENT_OBJECT_DRAG && sparam == entryPriceLineName)
       {
        // ドラッグされたラインの現在の価格を取得
        //double draggedPrice = ObjectGetDouble(0, entryPriceLineName, OBJPROP_PRICE, 0);
        double draggedPrice = entryPriceLine.Price(0); //引数の(0)は、アンカーポイント。オブジェクトによってはアンカーが複数あるが、水平線は0。
        // 価格を正規化
        double normalizedPrice = NormalizeDouble(draggedPrice, _Digits);

        // 価格が有効な場合のみ更新
        if(normalizedPrice > 0)
           {
            entryPriceValue = normalizedPrice; // グローバル変数を更新
            entryPriceEdit.Text(DoubleToString(entryPriceValue, _Digits)); // Editボックスの表示を更新
            UpdateAllLines();
            CalculateLotSizeAndRisk();
            //ChartRedraw(); //UpdateAllLines内で呼ぶので不要
           }
        return; // イベント処理完了
       }

//--- SLラインのドラッグイベント処理 ---
    if(id == CHARTEVENT_OBJECT_DRAG && sparam == slLineName)
       {
        double draggedPrice = slLine.Price(0); //引数の(0)は、アンカーポイント。
        double normalizedPrice = NormalizeDouble(draggedPrice, _Digits);
        if(normalizedPrice > 0)
           {
            slValue = normalizedPrice;
            slEdit.Text(DoubleToString(slValue, _Digits));
            UpdateAllLines();
            CalculateLotSizeAndRisk();
            //ChartRedraw();
           }
        return;
       }

//--- TPラインのドラッグイベント処理 ---
    if(id == CHARTEVENT_OBJECT_DRAG && sparam == tpLineName)
       {
        double draggedPrice = tpLine.Price(0);
        double normalizedPrice = NormalizeDouble(draggedPrice, _Digits);
        if(normalizedPrice > 0)
           {
            tpValue = normalizedPrice;
            tpEdit.Text(DoubleToString(tpValue, _Digits));
            UpdateAllLines();
           }
        return;
       }


//--- Order Button クリックイベント処理 ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == OrderButton.Name())
       {
        //--- 確認チェックボックスの状態を確認 ---
        bool skipConfirm = ConfirmCheckBox.Checked(); // チェックが入っていれば true (確認スキップ)

        //--- 確認が必要な場合 ---
        if(!skipConfirm)
           {
            // 確認メッセージボックスを表示
            string confirmMsg = StringFormat("Order Confirm:\nSymbol: %s\nType: %s %s\nLot: %.2f\nEntry: %s\nSL: %s\nTP: %s",
                                             _Symbol,
                                             (isMarketOrder ? "Market" : "Limit"),
                                             (isBuyMode ? "Buy" : "Sell"),
                                             CulLotValue,
                                             (isMarketOrder ? "Current" : DoubleToString(entryPriceValue, _Digits)),
                                             (slValue > 0 ? DoubleToString(slValue, _Digits) : "None"),
                                             (tpValue > 0 ? DoubleToString(tpValue, _Digits) : "None"));

            // Yes/No ボタン付きのメッセージボックス
            int result = MessageBox(confirmMsg, "Confirm Order", MB_YESNO | MB_ICONQUESTION);

            // "No" が押されたら何もしないで終了
            if(result != IDYES)
               {
                Print("Order cancelled by user.");
                return; // イベント処理完了
               }
            else
               {
                //--- 発注処理を実行 ---
                SendOrder();
                return;
               }
           }
        SendOrder(); //発注
        return; // イベント処理完了
       }

// --- ライン表示/非表示ボタンクリックイベント処理 ---
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == linesToggleButton.Name())
       {
        g_showLines = !g_showLines; // 状態を反転
        linesToggleButton.Text(g_showLines ? "Lines: ON" : "Lines: OFF"); // ボタンテキスト更新
        UpdateAllLines(); // ライン表示を更新
        ChartRedraw();    // ボタン表示とライン更新を反映
        UIPanel.ChartEvent(id, lparam, dparam, sparam); // パネルイベントを渡す
        return; // このイベント処理は完了
       }



//--- パネルにイベントを渡す ---
    UIPanel.ChartEvent(id,lparam,dparam,sparam);

   }


//+------------------------------------------------------------------+
//| エントリー価格欄の状態を更新する関数   | //marketモードで、ETpriceboxを無効化(グレーに)。リアルタイムで現在価格を表示するようにする関数
//+------------------------------------------------------------------+
void UpdateEntryPriceEditBoxState()
   {
//--- 成り行き注文の場合 ---
    if(isMarketOrder)
       {
        entryPriceEdit.ReadOnly(true);  // エントリー価格欄を読み取り専用に
        ObjectSetInteger(0, entryPriceEdit.Name(), OBJPROP_BGCOLOR, clrLightGray);
        entryPricePlusButton.Disable(); // +ボタンを無効化
        entryPriceMinusButton.Disable();// -ボタンを無効化

        // 現在の価格を取得
        MqlTick currentTick;
        if(SymbolInfoTick(_Symbol, currentTick)) // 最新のティック情報を取得
           {
            double priceToSet = 0.0;
            if(isBuyMode) // BuyモードならAsk価格
               {
                priceToSet = currentTick.ask;
               }
            else // SellモードならBid価格
               {
                priceToSet = currentTick.bid;
               }

            // 価格が有効な場合のみ更新
            if(priceToSet > 0)
               {
                entryPriceValue = NormalizeDouble(priceToSet, _Digits); // グローバル変数を更新
                entryPriceEdit.Text(DoubleToString(entryPriceValue, _Digits)); // Editボックス表示を更新
               }
           }
        else
           {
            // ティック情報が取得できない場合 (市場クローズ等)
            // Print("ティック情報の取得に失敗しました。");
            // 必要であれば、前回値のままにするか、"N/A"などを表示する処理を追加
           }
       }
//--- 指値注文の場合 ---
    else
       {

        double referencePrice = 0.0;
        MqlTick tick;
        if(SymbolInfoTick(_Symbol, tick))
           {
            referencePrice = isBuyMode ? tick.ask : tick.bid;
           }
        if(entryPriceValue == 0.0)
           {
            entryPriceValue += (referencePrice + ((SymbolInfoDouble(_Symbol,SYMBOL_POINT) * 100)));
           }
        entryPriceEdit.ReadOnly(false); // エントリー価格欄を編集可能に
        ObjectSetInteger(0, entryPriceEdit.Name(), OBJPROP_BGCOLOR, clrWhite);
        entryPricePlusButton.Enable();  // +ボタンを有効化
        entryPriceMinusButton.Enable(); // -ボタンを有効化
        // 指値の場合は、現在の entryPriceValue を表示 (ユーザー入力値 or +/- ボタン操作後の値)
        entryPriceEdit.Text(DoubleToString(entryPriceValue, _Digits));


        ChartRedraw(); // UI変更を即時反映させる場合 (呼び出し元で呼ぶなら不要)
       }
   }

//+------------------------------------------------------------------+
//| 全てのラインの価格を更新/表示/非表示する関数 |
//+------------------------------------------------------------------+
void UpdateAllLines()
   {

// --- LINE OFF---
// --- ライン表示が OFF なら、全て削除して終了 ---
    if(!g_showLines)
       {
        // ラインオブジェクトを削除
        if(ObjectFind(0, entryPriceLineName) >= 0)
            entryPriceLine.Delete();
        if(ObjectFind(0, slLineName) >= 0)
            slLine.Delete();
        if(ObjectFind(0, tpLineName) >= 0)
            tpLine.Delete();

        // ライン情報ラベルも削除
        DeleteEtSlTpInfoLabels();

        ChartRedraw(); // 削除をチャートに反映
        return; // ラインを表示しないので、ここで処理終了
       }

// --- LINE ON ---
//--- 基準価格を取得 ---
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double referencePrice = 0.0;
    if(isMarketOrder) // 成り行きモード
       {
        MqlTick tick;
        if(SymbolInfoTick(_Symbol, tick))
           {
            referencePrice = isBuyMode ? tick.ask : tick.bid;
           }
       }
    else // 指値モード
       {
        referencePrice = entryPriceValue;
       }

//--- Entry Price Line ---
    if(!isMarketOrder && entryPriceValue > 0)
       {
        // オブジェクトが存在しなければ作成し、スタイルを設定
        if(ObjectFind(0, entryPriceLineName) < 0)
           {
            if(entryPriceLine.Create(0, entryPriceLineName, 0, entryPriceValue))
               {
                entryPriceLine.Color(clrGreen);
                entryPriceLine.Style(STYLE_DASH);
                entryPriceLine.Width(1);
                entryPriceLine.Selectable(true);
                entryPriceLine.Selected(true);
                ObjectSetInteger(0, entryPriceLine.Name(), OBJPROP_RAY, false);
                entryPriceLine.Tooltip("Entry Price");
                entryPriceLine.Background(true);
               }
            else
               {
                Print("Entry Line 作成失敗");
               }
           }
        // 存在すれば価格を更新
        else
           {
            entryPriceLine.Price(0, entryPriceValue);
           }
       }
    else // 非表示条件
       {
        if(ObjectFind(0, entryPriceLineName) >= 0)
            entryPriceLine.Delete(); // 存在すれば削除
       }


//--- SL Price Line ---
    if(slValue > 0)
       {
        if(ObjectFind(0, slLineName) < 0)
           {
            if(slLine.Create(0, slLineName, 0, slValue))
               {
                slLine.Color(clrRed);
                slLine.Style(STYLE_DASH);
                slLine.Width(1);
                slLine.Selectable(true);
                slLine.Selected(true);
                ObjectSetInteger(0, slLine.Name(), OBJPROP_RAY, false);
                slLine.Tooltip("Stop Loss");
                slLine.Background(true);
               }
            else
               {
                Print("SL Line 作成失敗");
               }
           }
        else
           {
            slLine.Price(0, slValue);
           }
       }
    else // 非表示条件
       {
        if(ObjectFind(0, slLineName) >= 0)
            slLine.Delete(); // 存在すれば削除
       }


//--- TP Price Line ---
    if(tpValue > 0)
       {
        if(ObjectFind(0, tpLineName) < 0)
           {
            if(tpLine.Create(0, tpLineName, 0, tpValue))
               {
                tpLine.Color(clrLightBlue);
                tpLine.Style(STYLE_DASH);
                tpLine.Width(1);
                tpLine.Selectable(true);
                tpLine.Selected(true);
                ObjectSetInteger(0, tpLine.Name(), OBJPROP_RAY, false);
                tpLine.Tooltip("Take Profit");
                tpLine.Background(true);
               }
            else
               {
                Print("TP Line 作成失敗");
               }
           }
        else
           {
            tpLine.Price(0, tpValue);
           }
       }
    else // 非表示条件
       {
        if(ObjectFind(0, tpLineName) >= 0)
            tpLine.Delete(); // 存在すれば削除
       }

// ラベル更新関数を呼び出す
    UpdateEtSlTpInfoLabels();

    ChartRedraw(); // 変更を反映
   }

//+------------------------------------------------------------------+
//| ET/SL/TP情報ラベル(OBJ_LABEL)を作成/更新/削除する関数(ライン追従版) |
//+------------------------------------------------------------------+
//OnChartEventでUpdateAllLines関数をよぶ。そのなかで、UpdateEtSlTpInfoLabelsをよぶ。 また、ontimerでもリアルタイム追随を表現
void UpdateEtSlTpInfoLabels()
   {
//--- 基準価格を取得 ---
    double referencePrice = 0.0;
    if(isMarketOrder) // 成り行きモード
       {
        MqlTick tick;
        if(SymbolInfoTick(_Symbol, tick))
           {
            referencePrice = isBuyMode ? tick.ask : tick.bid;
           }
       }
    else // 指値モード
       {
        referencePrice = entryPriceValue;
       }

//--- 描画位置計算のための準備 ---
//datetime lastBarTime = iTime(_Symbol, _Period, 0); // 最新バーの時間
//double priceOffsetY = point * 5; // ラインからラベルを下に表示するオフセット
//int xOffsetPixels = 5; // チャート右端からのピクセルオフセット

//--- ラベル表示 -マイナス表現のため
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

//--- EntryPrice情報ラベルの更新 ---
    if(entryPriceValue > 0 && !isMarketOrder) // 有効なETP値がある場合のみラベルを処理
       {
        double ETLineGetPrice = entryPriceLine.Price(0); //オブジェクトの位置をpriceで取得 (アンカーポイント（通常0）)
        int x,y; //chartTimePriceToXY の 代入用のハコ ｘも引数に入れないといけないので。
        ChartTimePriceToXY(0, 0, NULL, ETLineGetPrice, x, y); //Lineの位置をピクセルで取得
        //Print("slLineGetPrice : ",slLineGetPrice); //デバッグ用

        string etText = "E:";

        if(ObjectFind(0, etInfoLabelName) < 0) // ラベルが存在しない場合
           {
            if(!ObjectCreate(0, etInfoLabelName, OBJ_LABEL, 0, 0, 0))
               {
                Print("ET情報ラベル作成失敗");
               }
           }
        // 位置とテキストを更新
        if(ObjectFind(0, etInfoLabelName) >= 0)
           {
            ObjectSetInteger(0, etInfoLabelName, OBJPROP_ANCHOR, ANCHOR_RIGHT);
            ObjectSetInteger(0, etInfoLabelName, OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, etInfoLabelName, OBJPROP_FONTSIZE, 9);
            ObjectSetInteger(0, etInfoLabelName, OBJPROP_BACK, true);
            ObjectSetInteger(0, etInfoLabelName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, etInfoLabelName, OBJPROP_CORNER, CORNER_RIGHT_UPPER); // 右上基準
            ObjectSetInteger(0, etInfoLabelName, OBJPROP_XDISTANCE, 5); // 右端から10ピクセル左
            ObjectSetInteger(0, etInfoLabelName, OBJPROP_YDISTANCE, y -9);
            ObjectSetString(0, etInfoLabelName, OBJPROP_TEXT, etText);
           }
       }
    else // ET値が無効ならラベルを削除
       {
        if(ObjectFind(0, etInfoLabelName) >= 0)
            ObjectDelete(0, etInfoLabelName);
       }


//--- SL情報ラベルの更新 ---
    if(slValue > 0) // 有効なSL値がある場合のみラベルを処理
       {
        double slLineGetPrice = slLine.Price(0); //オブジェクトの位置をpriceで取得 (アンカーポイント（通常0）)
        int x,y; //chartTimePriceToXY の 代入用のハコ
        ChartTimePriceToXY(0, 0, NULL, slLineGetPrice, x, y); //Lineの位置をピクセルで取得
        //Print("slLineGetPrice : ",slLineGetPrice); //デバッグ用

        string slText = "SL: ---";
        if(referencePrice > 0 && point > 0)
           {
            double points = 0;

            if(isBuyMode)
               {
                points = (referencePrice - slValue) / point;
               }
            else
               {
                points = (slValue - referencePrice) / point;
               }

            slText = StringFormat("SL: %.f ", points);
           }

        if(ObjectFind(0, slInfoLabelName) < 0) // ラベルが存在しない場合
           {
            if(!ObjectCreate(0, slInfoLabelName, OBJ_LABEL, 0, 0, 0))
               {
                Print("SL情報ラベル作成失敗");
               }
            else
               {
                ObjectSetInteger(0, slInfoLabelName, OBJPROP_ANCHOR, ANCHOR_RIGHT);
                //ObjectSetInteger(0, slInfoLabelName, OBJPROP_XDISTANCE, xOffsetPixels);
                ObjectSetInteger(0, slInfoLabelName, OBJPROP_CORNER, CORNER_RIGHT_UPPER); // 右上基準
                ObjectSetInteger(0, slInfoLabelName, OBJPROP_XDISTANCE, 5); // 右端から10ピクセル左
                ObjectSetInteger(0, slInfoLabelName, OBJPROP_YDISTANCE, y -9);
                ObjectSetInteger(0, slInfoLabelName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, slInfoLabelName, OBJPROP_FONTSIZE, 9);
                ObjectSetInteger(0, slInfoLabelName, OBJPROP_BACK, true);
                ObjectSetInteger(0, slInfoLabelName, OBJPROP_SELECTABLE, false);
               }
           }
        // 位置とテキストを更新
        if(ObjectFind(0, slInfoLabelName) >= 0)
           {
            ObjectSetInteger(0, slInfoLabelName, OBJPROP_CORNER, CORNER_RIGHT_UPPER); // 右上基準
            ObjectSetInteger(0, slInfoLabelName, OBJPROP_XDISTANCE, 5); // 右端から10ピクセル左
            ObjectSetInteger(0, slInfoLabelName, OBJPROP_YDISTANCE, y -9);
            //ObjectSetDouble(0, slInfoLabelName, OBJPROP_PRICE, 0, slValue - priceOffsetY); // SLラインの少し下
            //ObjectSetInteger(0, slInfoLabelName, OBJPROP_TIME, 0, lastBarTime);
            ObjectSetString(0, slInfoLabelName, OBJPROP_TEXT, slText);
           }
       }
    else // SL値が無効ならラベルを削除
       {
        if(ObjectFind(0, slInfoLabelName) >= 0)
            ObjectDelete(0, slInfoLabelName);
       }

//--- TP情報ラベルの更新 ---
    if(tpValue > 0) // 有効なTP値がある場合のみラベルを処理
       {
        double tpLineGetPrice = tpLine.Price(0); //オブジェクトの位置をpriceで取得 (アンカーポイント（通常0）)
        int x,y; //chartTimePriceToXY の 代入用のハコ
        ChartTimePriceToXY(0, 0, NULL, tpLineGetPrice, x, y); //Lineの位置をピクセルで取得

        string tpText = "TP: ---";
        if(referencePrice > 0 && point > 0)
           {

            double points = 0;

            if(!isBuyMode)
               {
                points = (referencePrice - tpValue) / point;
               }
            else
               {
                points = (tpValue - referencePrice) / point;
               }


            tpText = StringFormat("TP: %.f", points);
           }

        if(ObjectFind(0, tpInfoLabelName) < 0) // ラベルが存在しない場合
           {
            if(!ObjectCreate(0, tpInfoLabelName, OBJ_LABEL, 0, 0, 0))
               {
                Print("TP情報ラベル作成失敗");
               }
            else
               {
                ObjectSetInteger(0, tpInfoLabelName, OBJPROP_ANCHOR, ANCHOR_RIGHT);
                //ObjectSetInteger(0, tpInfoLabelName, OBJPROP_XDISTANCE, xOffsetPixels);
                ObjectSetInteger(0, tpInfoLabelName, OBJPROP_CORNER, CORNER_RIGHT_UPPER); // 右上基準
                ObjectSetInteger(0, tpInfoLabelName, OBJPROP_XDISTANCE, 5); // 右端から10ピクセル左
                ObjectSetInteger(0, tpInfoLabelName, OBJPROP_YDISTANCE, y -9);
                ObjectSetInteger(0, tpInfoLabelName, OBJPROP_COLOR, clrLightBlue);
                ObjectSetInteger(0, tpInfoLabelName, OBJPROP_FONTSIZE, 8);
                ObjectSetInteger(0, tpInfoLabelName, OBJPROP_BACK, true);
                ObjectSetInteger(0, tpInfoLabelName, OBJPROP_SELECTABLE, false);
               }
           }
        // 位置とテキストを更新
        if(ObjectFind(0, tpInfoLabelName) >= 0)
           {
            ObjectSetInteger(0, tpInfoLabelName, OBJPROP_CORNER, CORNER_RIGHT_UPPER); // 右上基準
            ObjectSetInteger(0, tpInfoLabelName, OBJPROP_XDISTANCE, 5); // 右端から10ピクセル左
            ObjectSetInteger(0, tpInfoLabelName, OBJPROP_YDISTANCE, y -9);
            //ObjectSetDouble(0, tpInfoLabelName, OBJPROP_PRICE, 0, tpValue - priceOffsetY); // TPラインの少し下
            //ObjectSetInteger(0, tpInfoLabelName, OBJPROP_TIME, 0, lastBarTime);
            ObjectSetString(0, tpInfoLabelName, OBJPROP_TEXT, tpText);
           }
       }
    else // TP値が無効ならラベルを削除
       {
        if(ObjectFind(0, tpInfoLabelName) >= 0)
            ObjectDelete(0, tpInfoLabelName);
       }
// ChartRedraw() は UpdateAllLines の最後で呼ばれるのでここでは不要
   }

//+------------------------------------------------------------------+
//| SL/TP情報ラベル(OBJ_LABEL)を削除する関数                         |
//+------------------------------------------------------------------+
void DeleteEtSlTpInfoLabels()
   {
    if(ObjectFind(0, etInfoLabelName) >= 0)
        ObjectDelete(0, etInfoLabelName);
    if(ObjectFind(0, slInfoLabelName) >= 0)
        ObjectDelete(0, slInfoLabelName);
    if(ObjectFind(0, tpInfoLabelName) >= 0)
        ObjectDelete(0, tpInfoLabelName);
   }


//+------------------------------------------------------------------+
//| ロット数を正規化する関数                                         |
//+------------------------------------------------------------------+
double NormalizeLotSize(double lot)
   {
    double volume_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double volume_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

// ステップに合わせて丸める (ステップが0.01なら小数点以下2桁に)
    lot = MathRound(lot / volume_step) * volume_step;

// 最小ロット未満なら最小ロットに
    if(lot < volume_min)
        lot = volume_min;

// 最大ロット超過なら最大ロットに
    if(lot > volume_max)
        lot = volume_max;

// 最終的なロット数を返す (念のため再度小数点以下の桁数を整える)
    return NormalizeDouble(lot, 2); // 一般的なロットは小数点以下2桁
   }

//+------------------------------------------------------------------+
//| ロットサイズとリスク額を計算し、UIを更新する関数                   |
//+------------------------------------------------------------------+
void CalculateLotSizeAndRisk()
   {
//--- 計算に必要な値を取得 ---
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double entry = entryPriceValue;
    double sl = slValue;
    double riskPercent = RiskPercent;

//--- 入力値チェック ---
    if(accountBalance <= 0 || riskPercent <= 0 || sl <= 0 || (isMarketOrder == false && entry <= 0))
       {
        // 計算に必要な値が不足している場合は、表示をリセットして終了
        CulLotEdit.Text("0.00");
        RiskUSDEdit.Text("0.00");
        CulLotValue = 0.0;
        RiskUSDValue = 0.0;
        return;
       }

// 成り行きの場合、最新価格を entry として使う
    if(isMarketOrder)
       {
        MqlTick tick;
        if(SymbolInfoTick(_Symbol, tick))
           {
            entry = isBuyMode ? tick.ask : tick.bid;
           }
        else // 価格取得失敗時は計算中断
           {
            Print("ロット計算のため価格取得試行も失敗");
            CulLotEdit.Text("0.00");
            RiskUSDEdit.Text("0.00");
            CulLotValue = 0.0;
            RiskUSDValue = 0.0;
            return;
           }
       }


//--- 損切り幅を計算 (価格単位) ---
    double stopLossDiff = MathAbs(entry - sl);
    if(stopLossDiff <= 0) // 損切り幅が0以下の場合は計算不可
       {
        CulLotEdit.Text("0.00");
        RiskUSDEdit.Text("0.00");
        CulLotValue = 0.0;
        RiskUSDValue = 0.0;
        Print("損切り幅が0または無効です。Entry:", entry, " SL:", sl);
        return;
       }

//--- 許容損失額を計算 (口座通貨建て) ---
    double riskAmount = accountBalance * (riskPercent / 100.0);

//--- 1ロットあたりの損失額を計算 (口座通貨建て) ---
    double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT); // 通常は100000だが取得する
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE); // 1ロットで1Tick動いた時の価値
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);   // 1Tickの価格変動幅

    if(tickSize <= 0) // TickSizeが0やマイナスは異常
       {
        Print("Tick Size が不正です:", tickSize);
        CulLotEdit.Text("0.00");
        RiskUSDEdit.Text("0.00");
        CulLotValue = 0.0;
        RiskUSDValue = 0.0;
        return;
       }
// 1価格単位あたりの価値 (1ロットあたり)
    double valuePerPriceUnit = tickValue / tickSize;
// 1ロットあたりの損失額
    double lossPerLot = stopLossDiff * valuePerPriceUnit;

    if(lossPerLot <= 0) // 1ロットあたりの損失が計算できない場合
       {
        Print("1ロットあたりの損失額が計算できません。");
        CulLotEdit.Text("0.00");
        RiskUSDEdit.Text("0.00");
        CulLotValue = 0.0;
        RiskUSDValue = 0.0;
        return;
       }

//--- ロットサイズを計算 ---
    double calculatedLot = riskAmount / lossPerLot;

//--- ロットサイズを正規化 ---
    CulLotValue = NormalizeLotSize(calculatedLot);

//--- 実際の予想損失額を計算 ---
    RiskUSDValue = lossPerLot * CulLotValue;

//--- UIを更新 ---
    CulLotEdit.Text(DoubleToString(CulLotValue, 2));
    RiskUSDEdit.Text(DoubleToString(RiskUSDValue, 2)); // RiskUSDEditはReadOnlyなので表示のみ更新
   }

//+------------------------------------------------------------------+
//| 注文を発行する関数                                               |
//+------------------------------------------------------------------+
void SendOrder()
   {
//--- 発注前の最終チェック ---
    if(CulLotValue <= 0)
       {
        Print("Invalid Lot size: ", CulLotValue);
        MessageBox("Cannot place order: Lot size is zero or negative.", "Order Error", MB_OK | MB_ICONERROR);
        return;
       }

//--- パラメータ設定 ---
    double lot = CulLotValue;
    double price = 0; // 成行の場合は0
    double sl = slValue;
    double tp = tpValue;
    ENUM_ORDER_TYPE orderType;
    string comment = "LotCul Order"; // 注文コメント

//--- 注文タイプと価格を設定 ---
    if(isMarketOrder) // 成り行き注文
       {
        orderType = isBuyMode ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        // 成り行きの場合、price は 0 のままでOK (CTradeが現在価格を使用)
        // SL/TP が近すぎる場合のチェック (省略。CTradeがある程度ハンドリングする)
       }
    else // 指値注文
       {
        price = entryPriceValue;
        if(price <= 0)
           {
            Print("Invalid Limit Price: ", price);
            MessageBox("Cannot place order: Limit price is zero or negative.", "Order Error", MB_OK | MB_ICONERROR);
            return;
           }

        // 指値/逆指値の判定 (現在の価格と比較)
        MqlTick tick;
        if(!SymbolInfoTick(_Symbol, tick))
           {
            Print("Cannot get current tick for Limit/Stop order type determination.");
            MessageBox("Cannot determine Limit/Stop order type.", "Order Error", MB_OK | MB_ICONERROR);
            return;
           }

        if(isBuyMode) // 買い注文
           {
            if(price < tick.ask) // 現在のAskより安い指値 -> Buy Limit
               {
                orderType = ORDER_TYPE_BUY_LIMIT;
               }
            else // 現在のAsk以上 -> Buy Stop (価格が同じ場合もStopとみなすことが多い)
               {
                orderType = ORDER_TYPE_BUY_STOP;
               }
           }
        else // 売り注文
           {
            if(price > tick.bid) // 現在のBidより高い指値 -> Sell Limit
               {
                orderType = ORDER_TYPE_SELL_LIMIT;
               }
            else // 現在のBid以下 -> Sell Stop
               {
                orderType = ORDER_TYPE_SELL_STOP;
               }
           }
        // SL/TP が近すぎる場合のチェック (省略)
       }

//--- SL/TPの値が0ならCTradeに渡さないように0.0にする ---
    if(sl <= 0)
        sl = 0.0;
    if(tp <= 0)
        tp = 0.0;


//--- 注文実行 ---
    bool result = false;
    Print("Sending Order: ", EnumToString(orderType), ", Lot:", lot, ", Price:", price, ", SL:", sl, ", TP:", tp);

// CTrade のメソッドを呼び出す
    switch(orderType)
       {
        case ORDER_TYPE_BUY:
            result = trade.Buy(lot, _Symbol, 0, sl, tp, comment); // price=0 で成行
            break;
        case ORDER_TYPE_SELL:
            result = trade.Sell(lot, _Symbol, 0, sl, tp, comment); // price=0 で成行
            break;
        case ORDER_TYPE_BUY_LIMIT:
            result = trade.BuyLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
            break;
        case ORDER_TYPE_SELL_LIMIT:
            result = trade.SellLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
            break;
        case ORDER_TYPE_BUY_STOP:
            result = trade.BuyStop(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
            break;
        case ORDER_TYPE_SELL_STOP:
            result = trade.SellStop(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
            break;
       }

//--- 結果確認 ---
    /*
        if(result)
           {
            Print("Order placed successfully. Ticket: ", trade.ResultOrder());
            MessageBox("Order placed successfully.\nTicket: " + (string)trade.ResultOrder(), "Order Result", MB_OK | MB_ICONINFORMATION);
           }
        else
           {
            Print("Order placement failed. Error code: ", trade.ResultRetcode(), ", Message: ", trade.ResultComment());
            MessageBox("Order placement failed.\nError: " + (string)trade.ResultRetcode() + "\n" + trade.ResultComment(), "Order Error", MB_OK | MB_ICONERROR);
           }
    */
   }



//+------------------------------------------------------------------+
