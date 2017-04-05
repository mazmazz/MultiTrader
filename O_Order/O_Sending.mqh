//+------------------------------------------------------------------+
//|                                                 MMT_Schedule.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+

#include "../MC_Common/MC_Common.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "../D_Data/D_Data.mqh"
#include "../S_Symbol.mqh"
//#include "../depends/OrderReliable.mqh"
#include "../depends/PipFactor.mqh"

#include "O_Defines.mqh"

#ifdef __MQL4__
int OrderManager::sendOpen(string posSymName, int posCmd, double posVolume, double posPrice, double posSlippage, double posStoploss, double posTakeprofit, string posComment = "", int posMagic = 0, datetime posExpiration = 0) {
    int result;
    
#ifdef _OrderReliable
    result = OrderSendReliable(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
#else
    if(BrokerTwoStep && (posStoploss > 0 || posTakeprofit > 0)) { //  && !Common::OrderIsPending(posCmd)
        result = OrderSend(posSymName, posCmd, posVolume, posPrice, posSlippage, 0, 0, posComment, posMagic, posExpiration);
        if(result > 0) {
            if(!OrderModify(result, posPrice, posStoploss, posTakeprofit, posExpiration)) {
                Error::PrintError(ErrorNormal, "Could not set stop loss/take profit for order " + result, FunctionTrace, NULL, true);
            }
        }
    } else {
        result = OrderSend(posSymName, posCmd, posVolume, posPrice, posSlippage, posStoploss, posTakeprofit, posComment, posMagic, posExpiration);
    }
#endif

    if(result > 0) { addOrderToOpenCount(result); }
    
    return result;
}
#else
#ifdef __MQL5__
ulong OrderManager::sendOpen(string posSymName, int posCmd, double posVolume, double posPrice, double posSlippage, double posStoploss, double posTakeprofit, string posComment = "", int posMagic = 0, datetime posExpiration = 0) {
    ulong finalResult = 0;
    bool callResult, isPending;
    MqlTradeRequest request={0};
    MqlTradeResult result={0};
    
    switch(posCmd) {
        case OP_BUY:
            request.action = TRADE_ACTION_DEAL;
            request.type = ORDER_TYPE_BUY;
            break;
        case OP_SELL:
            request.action = TRADE_ACTION_DEAL;
            request.type = ORDER_TYPE_SELL;
            break;
        case OP_BUYSTOP:
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_BUY_STOP;
            isPending = true;
            break;
        case OP_SELLSTOP:
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_SELL_STOP;
            isPending = true;
            break;
        case OP_BUYLIMIT:
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_BUY_LIMIT;
            isPending = true;
            break;
        case OP_SELLLIMIT:
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_SELL_LIMIT;
            isPending = true;
            break;
        default:
            return 0;
    }
    
    request.symbol = posSymName;
    request.volume = posVolume;
    request.price = posPrice;
    request.deviation = posSlippage;
    request.comment = posComment;
    request.magic = posMagic;
    if(posExpiration > 0) {
        request.expiration = posExpiration;
        request.type_time = ORDER_TIME_SPECIFIED;
    } else { request.type_time = ORDER_TIME_GTC; }
    
    request.type_filling = ORDER_FILLING_FOK; // todo: more flexibility? 
        // IOC: Partial fill possible, rest canceled; RETURN: a pending order is partially filled; an additional order for remaining volume is placed
    
    if(BrokerTwoStep && (posStoploss > 0 || posTakeprofit > 0)) { //  && !Common::OrderIsPending(posCmd)
        callResult = OrderSend(request, result);
        if(callResult && Common::IsOrderRetcodeSuccess(result.retcode, false)) {
            // todo: is correct? TRADE_ACTION_MODIFY = modify sltp of pending order, TRADE_ACTION_SLTP = modify sltp of open position
            finalResult = isPending ? result.order : result.deal;
            ulong targetTicket = isPending ? finalResult : HistoryDealGetInteger(finalResult, DEAL_POSITION_ID);
            
            if(!sendModify(targetTicket, result.price, posStoploss, posTakeprofit, posExpiration, isPending)) {
                Error::PrintError(ErrorNormal, "Could not modify order " + finalResult, NULL, NULL, true);
            }
        }
    } else {
        request.sl = posStoploss;
        request.tp = posTakeprofit;
        callResult = OrderSend(request, result);
    }

    if(callResult && Common::IsOrderRetcodeSuccess(result.retcode, false)) {
        // note: 10008 (TRADE_RETCODE_PLACED) result for OrderAsync, 10009 (TRADE_RETCODE_DONE) for OrderSend
        finalResult = isPending ? result.order : result.deal;
        addOrderToOpenCount(finalResult); // todo: count deals, or positions? // if(PositionSelect(posSymName) && HistoryDealGetInteger(finalResult, DEAL_POSITION_ID) == PositionGetInteger(POSITION_IDENTIFIER))
    }
    
    return finalResult; // todo: is order/deal/position ID what we want to pass?
}
#endif
#endif

//+------------------------------------------------------------------+

#ifdef __MQL4__
bool OrderManager::sendModify(int ticket, double price, double stoploss, double takeprofit, datetime expiration = 0) {
    bool result;
    
#ifdef _OrderReliable
    result = OrderModifyReliable(ticket, price, stoploss, takeprofit, expiration);
#else
    result = OrderModify(ticket, price, stoploss, takeprofit, expiration);
#endif

    return result;
}
#else
#ifdef __MQL5__
bool OrderManager::sendModify(ulong ticket, double price, double stoploss, double takeprofit, datetime expiration = 0, bool isOrder = false) {
    bool finalResult;
    MqlTradeRequest modRequest = {0};
    MqlTradeResult modResult = {0};
    
    if(isOrder) {
        modRequest.action = TRADE_ACTION_MODIFY;
        modRequest.order = ticket; // ticket = order ID
    } else {
        modRequest.action = TRADE_ACTION_SLTP;
        modRequest.position = ticket; // ticket = position ID, already passed. //HistoryDealGetInteger(finalResult, DEAL_POSITION_ID);
            // position ID is the net position in netting, position ticket # is each individual position ticket that added/subbed from net position
            
        // get position ID from deal. if hedging, position ID = position ticket. if netting, we need to get ticket from symbol -- position ID simply contributes to the first open position
        //if(Common::IsAccountHedging()) {
        //    modRequest.position = HistoryDealGetInteger(finalResult, DEAL_POSITION_ID);
        //} else if(PositionSelect(posSymName)) {
        //    modRequest.position = PositionGetInteger(POSITION_IDENTIFIER);
        //}
    }
    
    modRequest.price = price;
    modRequest.sl = stoploss;
    modRequest.tp = takeprofit;
    modRequest.expiration = expiration;
    
    if(!OrderSend(modRequest, modResult) 
        || Common::IsOrderRetcodeSuccess(modResult.retcode, true) 
    ) {
        return false;
    } else { return true; }
}
#endif
#endif

//+------------------------------------------------------------------+

#ifdef __MQL4__
bool OrderManager::sendClose(int ticket, int symIdx) {
    if(IsTradeContextBusy()) { return false; }

    bool result;
    if(!checkDoSelectOrder(ticket)) { return false; }

    string posSymName = OrderSymbol(cycleIsOrder);
    double posLots = OrderLots(cycleIsOrder);
    int posType = OrderType(cycleIsOrder);
    double posPrice;
    if(Common::OrderIsLong(posType)) { posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); } // Buy order, even idx
    else { posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); } // Sell order, odd idx
    
    int posSlippage;
    if(!getValuePoints(posSlippage, maxSlippageLoc, symIdx)) { return -1; }
    
#ifdef _OrderReliable
    result = 
        !Common::OrderIsPending(posType) ? 
        OrderCloseReliable(ticket, posLots, posPrice, posSlippage)
        : OrderDeleteReliable(ticket) // pending order
        ;
#else
    result = 
        !Common::OrderIsPending(posType) ? 
        OrderClose(ticket, posLots, posPrice, posSlippage)
        : OrderDelete(ticket) // pending order
        ;
#endif
    
    if(result) {
        if(isTradeModeGrid()) { 
            // set flag to trigger fulfilled in aggregate at end of loop
            // todo: grid - how to handle failures?
            gridExit[symIdx] = true;
        }
    } else {
        Error::PrintNormal("Failed Closing Ticket " + ticket + " - " + "Type: " + posType, NULL, NULL, true);
    }
    
    return result;
}
#else
#ifdef __MQL5__
bool OrderManager::sendClose(ulong ticket, int symIdx, bool isOrder = false) {
    MqlTradeRequest closeRequest = {0};
    MqlTradeResult closeResult = {0};
    
    bool callResult;
    if(isOrder) {
        closeRequest.action = TRADE_ACTION_REMOVE;
        closeRequest.order = ticket;
        callResult = OrderSend(closeRequest, closeResult);
    } else { // is position
        if(!checkDoSelectOrder(ticket, false)) { return false; }
        
        // stupid: take the current position ticket number (already passed in) and send an opposite order of the same lotsize
        if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) {
            //--- prepare request for close BUY position
            closeRequest.type =ORDER_TYPE_SELL;
            closeRequest.price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
        }
        else {
            //--- prepare request for close SELL position
            closeRequest.type =ORDER_TYPE_BUY;
            closeRequest.price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
        }
        
        int posSlippage;
        if(!getValuePoints(posSlippage, maxSlippageLoc, symIdx)) { return -1; }
        
        closeRequest.action = TRADE_ACTION_DEAL;
        closeRequest.symbol = PositionGetString(POSITION_SYMBOL);
        closeRequest.volume = PositionGetDouble(POSITION_VOLUME);
        closeRequest.magic = PositionGetInteger(POSITION_MAGIC);
        closeRequest.deviation = posSlippage;
        closeRequest.position =PositionGetInteger(POSITION_TICKET);
        
        callResult = OrderSend(closeRequest, closeResult);
    }
    
    return (callResult && Common::IsOrderRetcodeSuccess(closeResult.retcode));
}
#endif
#endif

//+------------------------------------------------------------------+

#ifdef __MQL4__
bool OrderManager::checkDoSelectOrder(int ticket) {
    if(OrderTicket(cycleIsOrder) != ticket) { 
        if(!OrderSelect(ticket, SELECT_BY_TICKET)) { 
            return false; 
        } 
    }
    
    return true;
}
#else
#ifdef __MQL5__
bool OrderManager::checkDoSelectOrder(ulong ticket, bool isOrder = false) {
    if(isOrder) {
        if(OrderTicket(cycleIsOrder) != ticket) { 
            if(!OrderSelect(ticket, SELECT_BY_TICKET)) { 
                return false; 
            } 
        }
    } else {
        if(PositionGetInteger(POSITION_TICKET) != ticket) {
            if(!PositionSelectByTicket(ticket)) {
                return false;
            }
        }
    }
    
    return true;
}
#endif
#endif

//+------------------------------------------------------------------+

#ifdef __MQL4__
int OrderManager::OrderType(bool isOrder) { return OrderType(); }
int OrderManager::OrderTicket(bool isOrder) { return OrderTicket(); }
double OrderManager::OrderStopLoss(bool isOrder) { return OrderStopLoss(); }
double OrderManager::OrderTakeProfit(bool isOrder) { return OrderTakeProfit(); }
int OrderManager::OrderMagicNumber(bool isOrder) { return OrderMagicNumber(); }
string OrderManager::OrderSymbol(bool isOrder) { return OrderSymbol(); }
double OrderManager::OrderLots(bool isOrder) { return OrderLots(); }
double OrderManager::OrderOpenPrice(bool isOrder) { return OrderOpenPrice(); }
datetime OrderManager::OrderExpiration(bool isOrder) { return OrderExpiration(); }
bool OrderManager::OrderSelect(int index, int select, int pool, bool isOrder) { return OrderSelect(index, select, pool); }
double OrderManager::OrderProfit(bool isOrder) { return OrderProfit(); }
int OrderManager::OrdersTotal(bool isOrder) { return OrdersTotal(); }
#else
#ifdef __MQL5__
long OrderManager::OrderType(bool isOrder) {
    if(isOrder) { return OrderGetInteger(ORDER_TYPE); }
    else { return PositionGetInteger(POSITION_TYPE); }
}

long OrderManager::OrderTicket(bool isOrder) {
    if(isOrder) { return OrderGetInteger(ORDER_TICKET); }
    else { return PositionGetInteger(POSITION_TICKET); }
}

double OrderManager::OrderStopLoss(bool isOrder) {
    if(isOrder) { return OrderGetDouble(ORDER_SL); }
    else { return PositionGetDouble(POSITION_SL); }
}

double OrderManager::OrderTakeProfit(bool isOrder) {
    if(isOrder) { return OrderGetDouble(ORDER_TP); }
    else { return PositionGetDouble(POSITION_TP); }
}

long OrderManager::OrderMagicNumber(bool isOrder) {
    if(isOrder) { return OrderGetInteger(ORDER_MAGIC); }
    else { return PositionGetInteger(POSITION_MAGIC); }
}

string OrderManager::OrderSymbol(bool isOrder) {
    if(isOrder) { return OrderGetString(ORDER_SYMBOL); }
    else { return PositionGetString(POSITION_SYMBOL); }
}

double OrderManager::OrderLots(bool isOrder) {
    if(isOrder) { return OrderGetDouble(ORDER_VOLUME_CURRENT); }
    else { return PositionGetDouble(POSITION_VOLUME); }
}

double OrderManager::OrderOpenPrice(bool isOrder) {
    if(isOrder) { return OrderGetDouble(ORDER_PRICE_OPEN); }
    else { return PositionGetDouble(POSITION_PRICE_OPEN); }
}

datetime OrderManager::OrderExpiration(bool isOrder) {
    if(isOrder) { return (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION); }
    else { return 0; }
}

bool OrderManager::OrderSelect(int index, int select, int pool=MODE_TRADES, bool isOrder = false) {
    switch(pool) {
        case MODE_TRADES:
            switch(select) {
                case SELECT_BY_TICKET:
                    if(isOrder) { return OrderSelect(index); }
                    else { return PositionSelectByTicket(index); }
                
                case SELECT_BY_POS:
                    if(isOrder) { return (OrderGetTicket(index) > 0); }
                    else { return PositionGetSymbol(index) != NULL; }
                
                default: 
                    return false;
            }
            
        case MODE_HISTORY:
            // todo: history - how does history work?
            return false;
            
        default:
            return false;
    }
}

double OrderManager::OrderProfit(bool isOrder) { // should always be called for a position
    if(isOrder) { 
        // todo: MQL4 OrderProfit returns this in deposit currency. how do?
        int type = OrderGetInteger(ORDER_TYPE);
        bool isLong = (type == ORDER_TYPE_BUY || type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_BUY_STOP_LIMIT);
        return isLong ? OrderGetDouble(ORDER_PRICE_CURRENT) - OrderGetDouble(ORDER_PRICE_OPEN) : OrderGetDouble(ORDER_PRICE_OPEN) - OrderGetDouble(ORDER_PRICE_CURRENT);
    } else {
        int type = PositionGetInteger(POSITION_TYPE);
        bool isLong = (type == POSITION_TYPE_BUY);
        return isLong ? PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) : PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT);
    }
}

int OrderManager::OrdersTotal(bool isOrder) {
    if(isOrder) {
        return OrdersTotal();
    } else {
        return PositionsTotal();
    }
}
#endif
#endif
