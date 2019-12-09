//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Prevents processing this includes file for the second time.
#ifndef ORDER_MQH
#define ORDER_MQH

/* Forward declaration */
#ifdef __MQL5__
class CPositionInfo;
class CTrade;
#endif

/* Includes */
#include "Log.mqh"
#include "String.mqh"
#include "SymbolInfo.mqh"
#ifdef __MQL5__
//#include <Trade/Trade.mqh>
//#include <Trade/PositionInfo.mqh>
#endif

/* Enums */
// A variety of properties for reading order values.
#ifndef __MQL__
// For functions OrderGet(), OrderGetInteger() and HistoryOrderGetInteger().
// @docs https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
enum ENUM_ORDER_PROPERTY_INTEGER {
  ORDER_TICKET,          // Order ticket. Unique number assigned to each order.
  ORDER_TIME_SETUP,      // Order setup time.
  ORDER_TYPE,            // Order type.
  ORDER_STATE,           // Order state.
  ORDER_TIME_EXPIRATION, // Order expiration time.
  ORDER_TIME_DONE,       // Order execution or cancellation time.
  ORDER_TIME_SETUP_MSC,  // The time of placing an order for execution in milliseconds since 01.01.1970.
  ORDER_TIME_DONE_MSC,   // Order execution/cancellation time in milliseconds since 01.01.1970.
  ORDER_TYPE_FILLING,    // Order filling type.
  ORDER_TYPE_TIME,       // Order lifetime.
  ORDER_MAGIC,           // ID of an Expert Advisor that has placed the order.
  ORDER_REASON,          // The reason or source for placing an order.
  ORDER_POSITION_ID,     // Position identifier that is set to an order as soon as it is executed.
  ORDER_POSITION_BY_ID   // Identifier of an opposite position used for closing by order ORDER_TYPE_CLOSE_BY.
};
#ifndef __MQL__
// For functions OrderGet(), OrderGetDouble() and HistoryOrderGetDouble().
// @docs https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
enum ENUM_ORDER_PROPERTY_DOUBLE {
  ORDER_VOLUME_INITIAL,  // Order initial volume.
  ORDER_VOLUME_CURRENT,  // Order current volume.
  ORDER_PRICE_OPEN,      // Price specified in the order.
  ORDER_SL,              // Stop Loss value.
  ORDER_TP,              // Take Profit value.
  ORDER_PRICE_CURRENT,   // The current price of the order symbol.
  ORDER_PRICE_STOPLIMIT  // The Limit order price for the StopLimit order.
};
#endif
#endif

/* Defines for backward compability. */

// Index in the order pool.
#ifndef SELECT_BY_POS
#define SELECT_BY_POS 0
#endif

// Index by the order ticket.
#ifndef SELECT_BY_TICKET
#define SELECT_BY_TICKET 1
#endif

#ifndef POSITION_TICKET
#define POSITION_TICKET 1
#endif

#ifndef ORDER_TICKET
#define ORDER_TICKET 1
#endif

#ifndef DEAL_TICKET
#define DEAL_TICKET 1
#endif

/* Structs */
#ifdef __MQL4__
// The Structure of Results of a Trade Request Check (MqlTradeCheckResult).
// The check is performed using the OrderCheck() function.
// @docs https://www.mql5.com/en/docs/constants/structures/mqltradecheckresult
struct MqlTradeCheckResult {
  uint         retcode;             // Reply code.
  double       balance;             // Balance after the execution of the deal.
  double       equity;              // Equity after the execution of the deal.
  double       profit;              // Floating profit.
  double       margin;              // Margin requirements.
  double       margin_free;         // Free margin.
  double       margin_level;        // Margin level.
  string       comment;             // Comment to the reply code (description of the error).
};
#endif
struct OrderParams {
  bool                          dummy;            // Whether order is dummy (real) or not (fake).
  color                         arrow_color;      // Color of the opening arrow on the chart.
  void OrderParams()
    : dummy(false), arrow_color(clrNONE) {};
};
struct OrderData {
  unsigned long                 ticket;           // Order ticket number.
  ENUM_ORDER_STATE              state;            // Order state.
  double                        profit;           // Order profit.
  double                        open_price;       // Open price.
  double                        close_price;      // Close price.
  datetime                      open_time;        // Open time.
  datetime                      close_time;       // Close time.
  double                        sl;               // Current Stop loss level of the order.
  double                        tp;               // Current Take Profit level of the order.
  datetime                      last_update;      // Last update of order values.
  unsigned int                  last_error;       // Last error code.
  double                        volume;           // Order's current volume.
  Log                          *logger;           // Pointer to logger.
  OrderData() : ticket(0), profit(0), last_error(ERR_NO_ERROR) {}
};

#ifndef __MQLBUILD__
// Order operation type.
// @docs
// - https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
enum ENUM_ORDER_TYPE {
  ORDER_TYPE_BUY,             // Market Buy order.
  ORDER_TYPE_SELL,            // Market Sell order.
  ORDER_TYPE_BUY_LIMIT,       // Buy Limit pending order.
  ORDER_TYPE_SELL_LIMIT,      // Sell Limit pending order.
  ORDER_TYPE_BUY_STOP,        // Buy Stop pending order
  ORDER_TYPE_SELL_STOP,       // Sell Stop pending order.
  ORDER_TYPE_BUY_STOP_LIMIT,  // Upon reaching the order price, a pending Buy Limit order is placed at the StopLimit price.
  ORDER_TYPE_SELL_STOP_LIMIT, // Upon reaching the order price, a pending Sell Limit order is placed at the StopLimit price.
  ORDER_TYPE_CLOSE_BY         // Order to close a position by an opposite one.
}
// Defines.
// Mode constants.
// @see: https://docs.mql4.com/trading/orderselect
#define MODE_TRADES 0
#define MODE_HISTORY 1
#endif

/**
 * Class to provide methods to deal with the order.
 *
 * @see
 * - https://www.mql5.com/en/docs/trading/ordergetinteger
 */
class Order : public SymbolInfo { // : public Deal

public:

  /*
   * Default enumerations:
   *
   * Trade operation:
   *   0: OP_BUY (Buy operation)
   *   1: OP_SELL (Sell operation)
   *   2: OP_BUYLIMIT (Buy limit pending order)
   *   3: OP_SELLLIMIT (Sell limit pending order)
   *   4: OP_BUYSTOP (Buy stop pending order)
   *   5: OP_SELLSTOP (Sell stop pending order)
   */

  // Defines.
  #define ORDER_REFRESH_RATE 10

protected:

  // Struct variables.
  OrderParams oparams;
  OrderData odata;
  MqlTradeRequest orequest;          // Trade Request Structure.
  MqlTradeCheckResult oresult_check; // Results of a Trade Request Check.
  MqlTradeResult oresult;            // Trade Request Result.

  // OrderType orderType;
  #ifdef __MQL5__
  //CTrade ctrade;
  //CPositionInfo position_info;
  #endif
  // Other variables.

public:

  /**
   * Class constructor.
   */
  Order() {
  }
  Order(long _ticket_no) {
    odata.ticket = _ticket_no;
    Update(_ticket_no);
  }
  Order(const MqlTradeRequest &_req) {
    orequest = _req;
    SendRequest();
  }
  Order(const MqlTradeRequest &_req, const OrderParams &_oparams) {
    orequest = _req;
    oparams = _oparams;
    SendRequest();
  }
  // Copy constructor.
  Order(const Order &_order) {
    this = _order;
  }

  /**
   * Class deconstructor.
   */
  ~Order() {
  }

  /* Getters */

  /**
   * Get order's params.
   */
  OrderParams GetParams() {
    return oparams;
  }

  /**
   * Get order's data.
   */
  OrderData GetData() {
    return odata;
  }

  /**
   * Get order's request.
   */
  MqlTradeRequest GetRequest() {
    return orequest;
  }

  /**
   * Get order's result.
   */
  MqlTradeResult GetResult() {
    return oresult;
  }

  /**
   * Get order's check result.
   */
  MqlTradeCheckResult GetResultCheck() {
    return oresult_check;
  }

  /* Setters */

  /* Trade methods */

  /**
   * Send the trade operation to a trade server.
   */
  static bool SendRequest(MqlTradeRequest &_request, MqlTradeResult &_result) {
    return OrderSend(_request) ? _result.retcode < TRADE_RETCODE_ERROR : false;
  }
  bool SendRequest() {
    if (OrderSend()) {
      return oresult.retcode < TRADE_RETCODE_ERROR;
    }
    else {
      odata.logger.Error(StringFormat("%s [%d]", Terminal::GetErrorText(odata.last_error), odata.last_error));
      return false;
    }
  }

  /**
   * Get allowed order filling modes.
   */
  static ENUM_ORDER_TYPE_FILLING GetOrderFilling(const string _symbol) {
    ENUM_ORDER_TYPE_FILLING _result = ORDER_FILLING_RETURN;
    long _filling = SymbolInfo::SymbolInfoInteger(_symbol, SYMBOL_FILLING_MODE);
    if ((_filling & SYMBOL_FILLING_IOC) != 0) {
      _result = ORDER_FILLING_IOC;
    }
    else if ((_filling & SYMBOL_FILLING_FOK) != 0) {
      _result = ORDER_FILLING_FOK;
    }
    return (_result);
  }
  ENUM_ORDER_TYPE_FILLING GetOrderFilling() {
    return GetOrderFilling(orequest.symbol);
  }

  /**
   * Get allowed order filling modes.
   */
  static ENUM_ORDER_TYPE_FILLING GetOrderFilling(const string _symbol, const long _type) {
    const ENUM_SYMBOL_TRADE_EXECUTION _exe_mode = (ENUM_SYMBOL_TRADE_EXECUTION) SymbolInfo::SymbolInfoInteger(_symbol, SYMBOL_TRADE_EXEMODE);
    const long _filling_mode = SymbolInfo::SymbolInfoInteger(_symbol, SYMBOL_FILLING_MODE);
    return ((_filling_mode == 0 || (_type >= ORDER_FILLING_RETURN) || ((_filling_mode & (_type + 1)) != _type + 1)) ?
      (((_exe_mode == SYMBOL_TRADE_EXECUTION_EXCHANGE) || (_exe_mode == SYMBOL_TRADE_EXECUTION_INSTANT)) ?
       ORDER_FILLING_RETURN : ((_filling_mode == SYMBOL_FILLING_IOC) ? ORDER_FILLING_IOC : ORDER_FILLING_FOK)) :
      (ENUM_ORDER_TYPE_FILLING) _type);
  }

  /* MT ORDER METHODS */

  /**
   * Closes opened order.
   *
   * @docs
   * - http://docs.mql4.com/trading/orderclose
   */
  static bool OrderClose(
      unsigned long _ticket,         // Unique number of the order ticket.
      double _lots,                  // Number of lots.
      double _price,                 // Closing price.
      int    _deviation,             // Maximal possible deviation/slippage from the requested price (in points).
      color  _arrow_color = CLR_NONE // Color of the closing arrow on the chart.
      ) {
    #ifdef __MQL4__
    return ::OrderClose((uint) _ticket, _lots, _price, _deviation, _arrow_color);
    #else
    MqlTradeRequest _request = {0};
    MqlTradeResult _result = {0};
    if (::OrderSelect(_ticket) || ::PositionSelectByTicket(_ticket) || ::HistoryOrderSelect(_ticket)) {
      _request.action       = TRADE_ACTION_DEAL;
      _request.position     = _ticket;
      _request.symbol       = ::PositionGetString(POSITION_SYMBOL);
      _request.volume       = _lots;
      _request.price        = _price;
      _request.deviation    = _deviation;
      _request.type         = (ENUM_ORDER_TYPE) (1 - ::PositionGetInteger(POSITION_TYPE));
      return SendRequest(_request, _result);
    }
    return false;
    #endif
  }
  bool OrderClose(double _price, int _deviation = 50, color _acolor = CLR_NONE) {
    ResetLastError();
    bool _result = OrderClose(odata.ticket, orequest.volume, _price, _deviation, _acolor);
    odata.last_error = Terminal::GetLastError();
    return _result;
  }

  /**
   * Closes a position by an opposite one.
   */
  static bool OrderCloseBy(int _ticket, int _opposite, color _color) {
    #ifdef __MQL4__
    return ::OrderCloseBy(_ticket, _opposite, _color);
    #else
    if (::OrderSelect(_ticket)) {
      MqlTradeRequest _request = {0};
      MqlTradeResult _result;
      _request.action      = TRADE_ACTION_CLOSE_BY;
      _request.position    = _ticket;
      _request.position_by = _opposite;
      return SendRequest(_request, _result);
    }
    return false;
    #endif
  }

  /**
   * Returns close price of the currently selected order.
   */
  static double OrderClosePrice() {
    #ifdef __MQL4__
    return ::OrderClosePrice();
    #else // __MQL5__
    return ::PositionGetDouble(POSITION_PRICE_CURRENT);
    #endif
  }
  double GetClosePrice() {
    return odata.close_price;
  }

  /**
   * Returns open time of the currently selected order.
   *
   * @see
   * - http://docs.mql4.com/trading/orderopentime
   * - https://www.mql5.com/en/docs/trading/ordergetinteger
   */
  static datetime OrderOpenTime() {
    #ifdef __MQL4__
    return ::OrderOpenTime();
    #else
    return (datetime) Order::OrderGetInteger(ORDER_TIME_SETUP);
    #endif
  }
  datetime GetOpenTime() {
    return odata.open_time;
  }

  /*
   * Returns close time of the currently selected order.
   *
   * @see:
   * - https://docs.mql4.com/trading/orderclosetime
   * - https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
   */
  static datetime OrderCloseTime() {
    #ifdef __MQL4__
    return ::OrderCloseTime();
    #else // __MQL5__
    // @todo
    // return position_info.?
    return 0;
    #endif
  }
  datetime GetCloseTime() {
    return odata.close_time;
  }

  /**
   * Returns comment of the currently selected order.
   *
   * @see:
   * - https://docs.mql4.com/trading/ordercomment
   * - https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
   */
  static string OrderComment() {
    #ifdef __MQL4__
    return ::OrderComment();
    #else // __MQL5__
    return Order::OrderGetString(ORDER_COMMENT);
    #endif
  }

  /**
   * Returns calculated commission of the currently selected order.
   *
   * @see:
   * - https://docs.mql4.com/trading/ordercommission
   * - https://www.mql5.com/en/docs/standardlibrary/tradeclasses/cpositioninfo/cpositioninfocommission
   */
  static double OrderCommission() {
    #ifdef __MQL4__
    return ::OrderCommission();
    #else // __MQL5__
    return ::PositionGetDouble(POSITION_COMMISSION);
    #endif
  }

  /**
   * Deletes previously opened pending order.
   *
   * @see: https://docs.mql4.com/trading/orderdelete
   */
  static bool OrderDelete(ulong _ticket, color _color = NULL) {
    #ifdef __MQL4__
    return ::OrderDelete((uint) _ticket, _color);
    #else
    if (::OrderSelect(_ticket)) {
      MqlTradeRequest _request = {0};
      MqlTradeResult _result;
      _request.action = TRADE_ACTION_REMOVE;
      _request.order = _ticket;
      return SendRequest(_request, _result);
    }
    return false;
    #endif
  }
  bool OrderDelete() {
    return OrderDelete(GetTicket());
  }

  /**
   * Returns expiration date of the selected pending order.
   *
   * @see
   * - https://docs.mql4.com/trading/orderexpiration
   * - https://www.mql5.com/en/docs/trading/ordergetinteger
   */
  static datetime OrderExpiration() {
    #ifdef __MQL4__
    return ::OrderExpiration();
    #else
    return (datetime) Order::OrderGetInteger(ORDER_TIME_EXPIRATION);
    #endif
  }

  /**
   * Returns amount of lots of the selected order.
   *
   * @see:
   * - https://docs.mql4.com/trading/orderlots
   * - https://www.mql5.com/en/docs/trading/ordergetdouble
   */
  static double OrderLots() {
    #ifdef __MQL4__
    return ::OrderLots();
    #else
    return Order::OrderGetDouble(ORDER_VOLUME_CURRENT);
    #endif
  }
  double GetVolume() {
    return orequest.volume = IsSelected() ? OrderLots() : orequest.volume;
  }

  /**
   * Returns an identifying (magic) number of the currently selected order.
   *
   * @see
   * - http://docs.mql4.com/trading/ordermagicnumber
   * - https://www.mql5.com/en/docs/trading/ordergetinteger
   */
  static long OrderMagicNumber() {
    #ifdef __MQL4__
    return (long) ::OrderMagicNumber();
    #else
    return Order::OrderGetInteger(ORDER_MAGIC);
    #endif
  }
  ulong GetMagicNumber() {
    return orequest.magic = IsSelected() ? OrderMagicNumber() : orequest.magic;
  }

  /**
   * Modification of characteristics of the previously opened or pending orders.
   *
   * @see http://docs.mql4.com/trading/ordermodify
   */
  static bool OrderModify(
          ulong      _ticket,      // Ticket number.
          double     _price,       // Price.
          double     _stoploss,    // Stop loss.
          double     _takeprofit,  // Take profit.
          datetime   _expiration,  // Expiration.
          color      _arrow_color  // Color of order.
          ) {
    #ifdef __MQL4__
    return ::OrderModify((uint) _ticket, _price, _stoploss, _takeprofit, _expiration, _arrow_color);
    #else
    MqlTradeRequest _request = {0};
    MqlTradeResult _result;
    _request.order = _ticket;
    _request.price = _price;
    _request.sl = _stoploss;
    _request.tp = _takeprofit;
    _request.expiration = _expiration;
    return SendRequest(_request, _result);
    #endif
  }

  /**
   * Returns open price of the currently selected order.
   *
   * @see
   * - http://docs.mql4.com/trading/orderopenprice
   * - https://www.mql5.com/en/docs/trading/ordergetinteger
   */
  static double OrderOpenPrice() {
    #ifdef __MQL4__
    return ::OrderOpenPrice();
    #else
    return Order::OrderGetDouble(ORDER_PRICE_OPEN);
    #endif
  }
  double GetOpenPrice() {
    return odata.open_price;
  }

  /**
   * Returns profit of the currently selected order.
   *
   * @return
   * Returns the net profit value (without swaps or commissions) for the selected order.
   * For open orders, it is the current unrealized profit. For closed orders, it is the fixed profit.
   *
   * @see https://docs.mql4.com/trading/orderprofit
   */
  static double OrderProfit() {
    #ifdef __MQL4__
    return ::OrderProfit();
    #else
    return ::PositionGetDouble(POSITION_PROFIT);
    #endif
  }
  double GetProfit() {
    return odata.profit;
  }

  /**
   * Executes trade operations by sending the request to a trade server.
   *
   * The main function used to open market or place a pending order.
   *
   * @see
   * - http://docs.mql4.com/trading/ordersend
   * - https://www.mql5.com/en/docs/trading/ordersend
   *
   * @return
   * Returns number of the ticket assigned to the order by the trade server
   * or -1 if it fails.
   */
  static long OrderSend(
          string   _symbol,              // Symbol.
          int      _cmd,                 // Operation.
          double   _volume,              // Volume.
          double   _price,               // Price.
          uint     _deviation,           // Deviation.
          double   _stoploss,            // Stop loss.
          double   _takeprofit,          // Take profit.
          string   _comment=NULL,        // Comment.
          ulong    _magic=0,             // Magic number.
          datetime _expiration=0,        // Pending order expiration.
          color    _arrow_color=clrNONE  // Color.
          ) {
    ResetLastError();
    #ifdef __MQL4__
    return ::OrderSend(_symbol,
      _cmd,
      _volume,
      _price,
      _deviation,
      _stoploss,
      _takeprofit,
      _comment,
      (uint) _magic,
      _expiration,
      _arrow_color);
    #else
    MqlTradeRequest _request = {0}; // Query structure.
    MqlTradeCheckResult _check_result = {0};
    MqlTradeResult _result = {0}; // Structure of the result.
    _request.action = TRADE_ACTION_DEAL;
    _request.symbol = _symbol;
    _request.volume = _volume;
    _request.price = _price;
    _request.sl = _stoploss;
    _request.tp = _takeprofit;
    _request.deviation = _deviation;
    _request.comment = _comment;
    _request.magic = _magic;
    _request.expiration = _expiration;
    _request.type = (ENUM_ORDER_TYPE) _cmd;
    _request.type_filling = GetOrderFilling(_symbol);
    // The trade requests go through several stages of checking on a trade server.
    // First of all, it checks if all the required fields of the request parameter are filled out correctly.
    if (!OrderCheck(_request, _check_result)) {
      // If funds are not enough for the operation,
      // or parameters are filled out incorrectly, the function returns false.
      // In order to obtain information about the error, call the GetLastError() function.
      // @see: https://www.mql5.com/en/docs/trading/ordercheck
      return -1;
    }
    else {
      // If there are no errors, the server accepts the order for further processing.
      // The check results are placed to the fields of the MqlTradeCheckResult structure.
      // For a more detailed description of the function execution result,
      // analyze the fields of the result structure.
      // In order to obtain information about the error, call the GetLastError() function.
    }
    // Sends trade requests to a server.
    if (::OrderSend(_request, _result)) {
      // In case of a successful basic check of structures (index checking) returns true.
      // However, this is not a sign of successful execution of a trade operation.
      // @see: https://www.mql5.com/en/docs/trading/ordersend
      // In order to obtain information about the error, call the GetLastError() function.
      return (long) (_request.action == TRADE_ACTION_DEAL ? _result.deal : _result.order);
    }
    else {
      // The function execution result is placed to structure MqlTradeResult,
      // whose retcode field contains the trade server return code.
      // @see: https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes
      // In order to obtain information about the error, call the GetLastError() function.
    }
    return -1;
    #endif
  }
  static long OrderSend(const MqlTradeRequest &_req, color _color = clrNONE) {
    return ::OrderSend(
      _req.symbol,           // Symbol.
      _req.type,             // Operation.
      _req.volume,           // Volume.
      _req.price,            // Price.
      (uint) _req.deviation, // Deviation.
      _req.sl,               // Stop loss.
      _req.tp,               // Take profit.
      _req.comment,          // Comment.
      (uint) _req.magic,     // Magic number.
      _req.expiration,       // Pending order expiration.
      _color                 // Color.
      );
  }
  long OrderSend() {
    ResetLastError();
    #ifdef __MQL4__
    long _result = ::OrderSend(
      orequest.symbol,           // Symbol.
      orequest.type,             // Operation.
      orequest.volume,           // Volume.
      orequest.price,            // Price.
      (uint) orequest.deviation, // Deviation (in pts).
      orequest.sl,               // Stop loss.
      orequest.tp,               // Take profit.
      orequest.comment,          // Comment.
      (uint) orequest.magic,     // Magic number.
      orequest.expiration,       // Pending order expiration.
      oparams.arrow_color        // Color.
      );
    odata.last_error = Terminal::GetLastError();
    return _result;
    #else
    // The trade requests go through several stages of checking on a trade server.
    // First of all, it checks if all the required fields of the request parameter are filled out correctly.
    if (!OrderCheck(orequest, oresult_check)) {
      // If funds are not enough for the operation,
      // or parameters are filled out incorrectly, the function returns false.
      // In order to obtain information about the error, call the GetLastError() function.
      // @see: https://www.mql5.com/en/docs/trading/ordercheck
      odata.last_error = oresult_check.retcode;
      return -1;
    }
    else {
      // If there are no errors, the server accepts the order for further processing.
      // The check results are placed to the fields of the MqlTradeCheckResult structure.
      // For a more detailed description of the function execution result,
      // analyze the fields of the result structure.
      // In order to obtain information about the error, call the GetLastError() function.
    }
    // Sends trade requests to a server.
    if (::OrderSend(orequest, oresult)) {
      // In case of a successful basic check of structures (index checking) returns true.
      // However, this is not a sign of successful execution of a trade operation.
      // @see: https://www.mql5.com/en/docs/trading/ordersend
      // In order to obtain information about the error, call the GetLastError() function.
      return (long) GetTicket();
    }
    else {
      // The function execution result is placed to structure MqlTradeResult,
      // whose retcode field contains the trade server return code.
      // @see: https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes
      // In order to obtain information about the error, call the GetLastError() function.
    }
    odata.last_error = oresult.retcode;
    return -1;
    #endif
  }

  /**
   * Checks if there are enough money to execute a required trade operation.
   *
   * @param
   *   _request MqlTradeRequest
   *     Pointer to the structure of the MqlTradeRequest type, which describes the required trade action.
   *   _result_check MqlTradeCheckResult
   *     Pointer to the structure of the MqlTradeCheckResult type, to which the check result will be placed.
   *
   * @return
   *   If funds are not enough for the operation, or parameters are filled out incorrectly, the function returns false.
   *   In case of a successful basic check of structures (check of pointers), it returns true.
   *
   * @docs https://www.mql5.com/en/docs/trading/ordercheck
   */
  static bool OrderCheck(const MqlTradeRequest &_request, MqlTradeCheckResult &_result_check) {
    #ifdef __MQL4__
    // @todo
    // _result_check.balance = Account::Balance() - something; // Balance value that will be after the execution of the trade operation.
    // equity;              // Equity value that will be after the execution of the trade operation.
    // profit;              // Value of the floating profit that will be after the execution of the trade operation.
    // margin;              // Margin required for the trade operation.
    // margin_free;         // Free margin that will be left after the execution of the trade operation.
    // margin_level;        // Margin level that will be set after the execution of the trade operation.
    // comment;             // Comment to the reply code (description of the error).
    return true;
    #else
    return ::OrderCheck(_request, _result_check);
    #endif
  }

  /**
   * Returns stop loss value of the currently selected order.
   *
   * @see http://docs.mql4.com/trading/orderstoploss
   */
  static double OrderStopLoss() {
    #ifdef __MQL4__
    return ::OrderStopLoss();
    #else
    return ::PositionGetDouble(POSITION_SL);
    #endif
  }
  double GetStopLoss() {
    return odata.sl;
  }

  /**
   * Returns take profit value of the currently selected order.
   *
   * @return
   * Returns take profit value of the currently selected order.
   *
   * @see
   * - https://docs.mql4.com/trading/ordertakeprofit
   * - https://www.mql5.com/en/docs/trading/ordergetinteger
   */
  static double OrderTakeProfit() {
    #ifdef __MQL4__
    return ::OrderTakeProfit();
    #else
    return Order::OrderGetDouble(ORDER_TP);
    #endif
  }
  double GetTakeProfit() {
    return odata.tp;
  }

  /**
   * Returns SL/TP value of the currently selected order.
   */
  static double OrderSLTP(ENUM_ORDER_PROPERTY_DOUBLE _mode) {
    switch (_mode) {
      case ORDER_SL: return OrderStopLoss();
      case ORDER_TP: return OrderTakeProfit();
    }
    return NULL;
  }

  /**
   * Returns swap value of the currently selected order.
   *
   * @see: https://docs.mql4.com/trading/orderswap
   */
  static double OrderSwap() {
    #ifdef __MQL4__
    return ::OrderSwap();
    #else
    return ::PositionGetDouble(POSITION_SWAP);
    #endif
  }

  /**
   * Returns symbol name of the currently selected order.
   *
   * @see
   * - https://docs.mql4.com/trading/ordersymbol
   * - https://www.mql5.com/en/docs/trading/positiongetstring
   */
  static string OrderSymbol() {
    #ifdef __MQL4__
    return ::OrderSymbol();
    #else
    return Order::OrderGetString(ORDER_SYMBOL);
    #endif
  }
  string GetSymbol() {
    return orequest.symbol;
  }

  /**
   * Returns a ticket number of the currently selected order.
   *
   * It is a unique number assigned to each order.
   *
   * @see https://docs.mql4.com/trading/orderticket
   * @see https://www.mql5.com/en/docs/trading/ordergetticket
   */
  static ulong OrderTicket() {
    #ifdef __MQL4__
    return ::OrderTicket();
    #else
    return Order::OrderGetInteger(ORDER_TICKET);
    #endif
  }
  ulong GetTicket() {
    Update();
    return odata.ticket;
  }

  /**
   * Returns order operation type of the currently selected order.
   *
   * @see http://docs.mql4.com/trading/ordertype
   */
  static ENUM_ORDER_TYPE OrderType() {
    #ifdef __MQL4__
    return (ENUM_ORDER_TYPE) ::OrderType();
    #else
    return (ENUM_ORDER_TYPE) Order::OrderGetInteger(ORDER_TYPE);
    #endif
  }

  /**
   * Returns order operation type of the currently selected order.
   *
   * Limit and stop orders are on a GTC basis unless an expiry time is set explicitly.
   *
   * @see https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
   */
  static ENUM_ORDER_TYPE_TIME OrderTypeTime() {
    // MT4 orders are usually on an FOK basis in that you get a complete fill or nothing.
    #ifdef __MQL4__
    return ORDER_TIME_GTC;
    #else
    return (ENUM_ORDER_TYPE_TIME) Order::OrderGetInteger(ORDER_TYPE);
    #endif
  }

  /**
   * Returns the order position based on the ticket.
   *
   * It is set to an order as soon as it is executed.
   * Each executed order results in a deal that opens or modifies an already existing position.
   * The identifier of exactly this position is set to the executed order at this moment.
   */
  static ulong OrderGetPositionID(ulong _ticket) {
    #ifdef __MQL4__
    for (int _pos = 0; _pos < OrdersTotal(); _pos++) {
      if (OrderSelect(_pos, SELECT_BY_POS, MODE_TRADES) && OrderTicket() == _ticket) {
        return _pos;
      }
    }
    return -1;
    #else // __MQL5__
    OrderSelect(_ticket, SELECT_BY_TICKET, MODE_TRADES);
    return Order::OrderGetInteger(ORDER_POSITION_ID);
    #endif
  }
  ulong OrderGetPositionID() {
    return OrderGetPositionID(GetTicket());
  }

  /**
   * Returns the ticket of an opposite position.
   *
   * Used when a position is closed by an opposite one open for the same symbol in the opposite direction.
   *
   * @see:
   * - https://www.mql5.com/en/docs/constants/structures/mqltraderequest
   * - https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
   */
  static ulong OrderGetPositionBy(ulong _ticket) {
    #ifdef __MQL4__
    // @todo
    /*
    for (int _pos = 0; _pos < OrdersTotal(); _pos++) {
      if (OrderSelect(_pos, SELECT_BY_POS, MODE_TRADES) && OrderTicket() == _ticket) {
        return _pos;
      }
    }
    */
    return -1;
    #else // __MQL5__
    OrderSelect(_ticket, SELECT_BY_TICKET, MODE_TRADES);
    return Order::OrderGetInteger(ORDER_POSITION_BY_ID);
    #endif
  }
  ulong OrderGetPositionBy() {
    return OrderGetPositionBy(GetTicket());
  }

  /**
   * Returns the ticket of a position in the list of open positions.
   *
   * @see https://www.mql5.com/en/docs/trading/positiongetticket
   */
  ulong PositionGetTicket(int _index) {
    #ifdef __MQL4__
    if (::OrderSelect(_index, SELECT_BY_POS, MODE_TRADES)) {
      return ::OrderTicket();
    }
    return -1;
    #else // __MQL5__
    return PositionGetTicket(_index);
    #endif
  }

  /* Order selection methods */

  /**
   * Select an order to work with.
   *
   * The function selects an order for further processing.
   *
   *  @see http://docs.mql4.com/trading/orderselect
   */
  static bool OrderSelect(ulong index, int select = SELECT_BY_POS, int pool = MODE_TRADES) {
    #ifdef __MQL4__
      return ::OrderSelect((int) index, select, pool);
    #else
      if (select == SELECT_BY_POS) {
        if (pool == MODE_TRADES) {
          // Returns ticket of a corresponding order and automatically selects the order for further working with it
          // using functions.
          // Declaration: ulong  OrderGetTicket (int index (Number in the list of orders) )
          return OrderGetTicket((int) index) != 0;
        }
        else
        if (pool == MODE_HISTORY) {
          // The HistoryOrderGetTicket(index) return the ticket of the historical order, by its index from the cache of
          // the historical orders (not from the terminal base!). The obtained ticket can be used in the
          // HistoryOrderSelect(ticket) function, which clears the cache and re-fill it with only one order, in the
          // case of success. Recall that the value, returned from HistoryOrdersTotal() depends on the number of orders
          // in the cache.
          ulong ticket_id = HistoryOrderGetTicket((int) index);
          
          if (ticket_id == 0) {
            return false;
          }

          // For MQL5-targeted code, we need to call HistoryOrderGetTicket(index), so user may use
          // HistoryOrderGetTicket(), HistoryOrderGetDouble() and so on.
          if (!HistoryOrderSelect(ticket_id))
            return false;

          // For MQL4-legacy code, we also need to call OrderSelect(ticket), as user may still use OrderTicket(),
          // OrderType() and so on.
          return ::OrderSelect(ticket_id);
        }
      }
      else
      if (select == SELECT_BY_TICKET) {
        // Pool parameter is ignored if the order is selected by the ticket number. The ticket number is a unique order identifier.
        return ::OrderSelect(index);
      }
      Print("OrderSelect(): Possible values for \"select\" parameters are: SELECT_BY_POS or SELECT_BY_HISTORY.");
      return false;
    #endif
  }
  bool OrderSelect() {
    return OrderSelect(odata.ticket, SELECT_BY_TICKET);
  }

  /* State checking */

  /**
   * Check whether order is selected and it is same as the class one.
   */
  bool IsSelected() {
   return OrderTicket() == odata.ticket;
  }

  /**
   * Check whether order is active and open.
   */
  bool IsOrderOpen() {
   return OrderOpenTime() > 0 && !(OrderCloseTime() > 0);
  }

  /* Setters */

  /**
   * Update values of the current order.
   */
  bool Update(ulong _ticket_no) {
    return OrderSelect(_ticket_no, SELECT_BY_TICKET) ? Update() : false;
  }

  /**
   * Update values of the current order.
   *
   * It assumes that the order is already pre-selected.
   */
  bool Update() {
    if (!IsSelected()) {
      if (!OrderSelect()) {
        return false;
      }
    }
    // @todo Add time limit.
    odata.ticket = orequest.action == TRADE_ACTION_DEAL ? oresult.deal : oresult.order; // Order ticket number.
    //order.ticket      = OrderTicket();
    //order.magic_id    = OrderMagicNumber();         // Magic number ID.
    odata.profit      = OrderProfit();              // Order profit.
    //order.volume      = OrderLots();                // Requested volume for a deal in lots.
    //order.open_price  = OrderOpenPrice();           // Open price.
    //order.close_price = OrderClosePrice();          // Close price.
    //order.open_time   = OrderOpenTime();            // Open time.
    //order.close_time  = OrderCloseTime();           // Close time.
    //order.stoplimit    = ?;                      // StopLimit level of the order.
    odata.sl          = OrderStopLoss();            // Stop Loss level of the order.
    odata.tp          = OrderTakeProfit();          // Take Profit level of the order.
    //order.type        = OrderType();                // Order type.
    //order.filling     = GetOrderFilling();          // Order execution type.
    //order.type_time   = OrderTypeTime();            // Order expiration type.
    //order.expiration  = OrderExpiration();          // Order expiration time (for the orders of ORDER_TIME_SPECIFIED type.
    //order.comment     = new String(OrderComment()); // Order comment.
    //order.position    = OrderGetPositionID();       // Position ticket.
    //order.position_by = OrderGetPositionBy();       // The ticket of an opposite position.
    //order.symbol      = new String(OrderSymbol());  // Order symbol;
    // odata.volume        = ... // Order's current volume.
    return true;
  }

  /**
   * Update specific order value.
   */
  double UpdateValue(double _src, double &_dst) {
    _dst = _src;
    return _dst;
  }

  /* Conversion methods */

  /**
   * Returns OrderType as a text.
   *
   * @param
   *   op_type int Order operation type of the order.
   *   lc bool If true, return order operation in lower case.
   *
   * @return
   *   Return text representation of the order.
   */
  static string OrderTypeToString(ENUM_ORDER_TYPE _cmd, bool _lc = false) {
    _cmd = _cmd != NULL ? _cmd : OrderType();
    string _res = StringSubstr(EnumToString(_cmd), 11);
    StringReplace(_res, "_", " ");
    if (_lc) {
      StringToLower(_res);
    }
    return _res;
  }
  string OrderTypeToString(bool _lc = false) {
    return OrderTypeToString(orequest.type, _lc);
  }

  /* Custom order methods */

  /**
   * Returns profit of the currently selected order.
   *
   * @return
   * Returns the gross profit value (with swaps or commissions) for the selected order,
   * in the base currency.
   */
  static double GetOrderProfit() {
    return OrderProfit() - OrderCommission() - OrderSwap();
  }

  /**
   * Returns profit of the currently selected order in pips.
   *
   * @return
   * Returns the profit value for the selected order in pips.
   */
  static double GetOrderProfitInPips() {
    return (OrderOpenPrice() - SymbolInfo::GetCloseOffer(OrderSymbol(), OrderType())) / SymbolInfo::GetPointSize(OrderSymbol());
  }

  /**
   * Return opposite trade of command operation.
   *
   * @param
   *   cmd int Trade command operation.
   */
  static ENUM_ORDER_TYPE NegateOrderType(ENUM_ORDER_TYPE _cmd) {
    if (_cmd == ORDER_TYPE_BUY)  return ORDER_TYPE_SELL;
    if (_cmd == ORDER_TYPE_SELL) return ORDER_TYPE_BUY;
    return -1;
  }

  /*
   * Returns direction value of order.
   *
   * @param
   *   op_type int Order operation type of the order.
   *
   * @return
   *   Returns 1 for buy, -1 for sell orders, otherwise EMPTY (-1).
   */
  static int OrderDirection(ENUM_ORDER_TYPE _cmd) {
    switch (_cmd) {
      case ORDER_TYPE_SELL:
      case ORDER_TYPE_SELL_LIMIT:
      case ORDER_TYPE_SELL_STOP:
        return -1;
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_BUY_LIMIT:
      case ORDER_TYPE_BUY_STOP:
        return 1;
      default:
        return 0;
    }
  }
  static int OrderDirection(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_PROPERTY_DOUBLE _mode) {
    return OrderDirection(_cmd) * (_mode == ORDER_SL ? -1 : 1);
  }

  /**
   * Get color of the order based on its type.
   */
  static color GetOrderColor(ENUM_ORDER_TYPE _cmd = NULL, color cbuy = Blue, color csell = Red) {
    if (_cmd == NULL) _cmd = (ENUM_ORDER_TYPE) OrderType();
    return OrderDirection(_cmd) > 0 ? cbuy : csell;
  }

  /**
    * Returns the requested property of an order.
    *
    * @param ENUM_ORDER_PROPERTY_DOUBLE property_id
    *   Identifier of a property.
    *
    * @return double
    *   Returns the value of the property.
    *   In case of error, information can be obtained using GetLastError() function.
    *
    * @docs
    * - https://www.mql5.com/en/docs/trading/ordergetdouble
    *
    */
  static double OrderGetDouble(ENUM_ORDER_PROPERTY_DOUBLE property_id) {
#ifdef __MQLBUILD__
    return ::OrderGetDouble(property_id);
#else
  printf("@fixme: %s\n", "Symbol::OrderGetDouble()");
  return 0;
#endif
  }

  /**
    * Returns the requested property of an order.
    *
    * @param ENUM_ORDER_PROPERTY_INTEGER property_id
    *   Identifier of a property.
    *
    * @return long
    *   Returns the value of the property.
    *   In case of error, information can be obtained using GetLastError() function.
    *
    * @docs
    * - https://www.mql5.com/en/docs/trading/ordergetinteger
    *
    */
  static long OrderGetInteger(ENUM_ORDER_PROPERTY_INTEGER property_id) {
#ifdef __MQLBUILD__
    return ::OrderGetInteger(property_id);
#else
  printf("@fixme: %s\n", "OrderGet::OrderGetInteger()");
  return 0;
#endif
  }

  /**
    * Returns the requested property of an order.
    *
    * @param ENUM_ORDER_PROPERTY_STRING property_id
    *   Identifier of a property.
    *
    * @return string
    *   Returns the value of the property.
    *   In case of error, information can be obtained using GetLastError() function.
    *
    * @docs
    * - https://www.mql5.com/en/docs/trading/ordergetstring
    *
    */
  static string OrderGetString(ENUM_ORDER_PROPERTY_STRING property_id) {
#ifdef __MQLBUILD__
    return ::OrderGetString(property_id);
#else
  printf("@fixme: %s\n", "OrderGet::OrderGetString()");
  return 0;
#endif
  }

  /**
    * Returns the requested property of an order.
    *
    * @param ENUM_ORDER_PROPERTY_DOUBLE _prop_id
    *   Identifier of a property.
    *
    * @return long
    *   Returns the value of the property.
    *
    * @docs
    * - https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
    *
    */
  double OrderGet(ENUM_ORDER_PROPERTY_DOUBLE _prop_id) {
    switch (_prop_id) {
      case ORDER_VOLUME_INITIAL:  return orequest.volume;
      case ORDER_VOLUME_CURRENT:  return odata.volume;
      case ORDER_PRICE_OPEN:      return oresult.price;
      case ORDER_SL:              return odata.sl;
      case ORDER_TP:              return odata.tp;
      case ORDER_PRICE_CURRENT:   return SymbolInfo::GetCloseOffer(orequest.type);
      case ORDER_PRICE_STOPLIMIT: return orequest.stoplimit;
    }
    return EMPTY;
  }

  /**
    * Returns the requested property of an order.
    *
    * @param ENUM_ORDER_PROPERTY_INTEGER _prop_id
    *   Identifier of a property.
    *
    * @return long
    *   Returns the value of the property.
    *
    * @docs
    * - https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
    *
    */
  long OrderGet(ENUM_ORDER_PROPERTY_INTEGER _prop_id) {
    switch (_prop_id) {
      case ORDER_TICKET:          return (long) odata.ticket;
      case ORDER_TYPE:            return orequest.type;
      case ORDER_STATE:           return odata.state;
      case ORDER_TIME_EXPIRATION: return orequest.expiration;
      //case ORDER_TIME_DONE:
      //case ORDER_TIME_SETUP_MSC:
      //case ORDER_TIME_DONE_MSC:
      case ORDER_TYPE_FILLING:    return orequest.type_filling;
      case ORDER_TYPE_TIME:       return orequest.type_time;
      case ORDER_MAGIC:           return (long) orequest.magic;
      //case ORDER_REASON:
#ifdef ORDER_POSITION_ID
      case ORDER_POSITION_ID:     return (long) orequest.position;
#endif
#ifdef ORDER_POSITION_BY_ID
      case ORDER_POSITION_BY_ID:  return (long) orequest.position_by;
#endif
    }
    return EMPTY;
  }

  /**
    * Returns the requested property of an order.
    *
    * @param ENUM_ORDER_PROPERTY_STRING _prop_id
    *   Identifier of a property.
    *
    * @return long
    *   Returns the value of the property.
    *
    * @docs
    * - https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
    *
    */
  string OrderGet(ENUM_ORDER_PROPERTY_STRING _prop_id) {
    switch (_prop_id) {
      case ORDER_SYMBOL:        return orequest.symbol;
      case ORDER_COMMENT:       return orequest.comment;
#ifdef ORDER_EXTERNAL_ID
      case ORDER_EXTERNAL_ID:   return "n/a";
#endif
    }
    return "";
  }

  /* Printer methods */

  /**
   * Returns order details in text.
   */
  static string ToString() {
    return StringFormat(
      "Order Details: Ticket: %d; Time: %s; Comment: %s; Commision: %g; Symbol: %s; Type: %s, Expiration: %s; " +
      "Open Price: %g, Close Price: %g, Take Profit: %g, Stop Loss: %g" +
      "Swap: %g; Lot size: %g",
      OrderTicket(),
      DateTime::TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS),
      OrderComment(),
      OrderCommission(),
      OrderSymbol(),
      OrderTypeToString(OrderType()),
      OrderExpiration(),
      DoubleToStr(OrderOpenPrice(), Digits),
      DoubleToStr(OrderClosePrice(), Digits),
      OrderProfit(),
      OrderStopLoss(),
      OrderSwap(),
      OrderLots()
    );
  }

  /**
   * Returns order details in text.
   */
  string ToString(long &_props[], ENUM_DATATYPE _type = TYPE_DOUBLE, string _dlm = ";") {
    int i = 0;
    string _output = "";
    switch (_type) {
      case TYPE_DOUBLE:
        for (i = 0; i < Array::ArraySize(_props); i++) {
          _output += StringFormat("%g%s", OrderGet((ENUM_ORDER_PROPERTY_DOUBLE) _props[i]), _dlm);
        }
        break;
      case TYPE_LONG:
        for (i = 0; i < Array::ArraySize(_props); i++) {
          _output += StringFormat("%d%s", OrderGet((ENUM_ORDER_PROPERTY_INTEGER) _props[i]), _dlm);
        }
        break;
      case TYPE_STRING:
        for (i = 0; i < Array::ArraySize(_props); i++) {
          _output += StringFormat("%d%s", OrderGet((ENUM_ORDER_PROPERTY_STRING) _props[i]), _dlm);
        }
        break;
      default:
        this.Logger().Error(StringFormat("%s: Unsupported type: %s!", __FUNCTION_LINE__, EnumToString(_type)));
    }
    return "";
  }

  /**
   * Prints information about the selected order in the log.
   *
   * @see http://docs.mql4.com/trading/orderprint
   */
  static void OrderPrint() {
#ifdef __MQLBUILD__
#ifdef __MQL4__
    ::OrderPrint();
#else
    Print(ToString());
#endif
#else
    printf("%s", ToString());
#endif
  }

};
#endif ORDER_MQH
