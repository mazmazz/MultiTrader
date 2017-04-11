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
    int result = 0;
    
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

    if(result > 0) { addOrderToOpenCount(result, -1, false, false); }
    
    return result;
}
#else
#ifdef __MQL5__
ulong OrderManager::sendOpen(string posSymName, int posCmd, double posVolume, double posPrice, double posSlippage, double posStoploss, double posTakeprofit, string posComment = "", int posMagic = 0, datetime posExpiration = 0) {
    ulong finalResult = 0;
    bool callResult = false, isPending = false;
    MqlTradeRequest request={0};
    MqlTradeResult result={0};
    
    switch(posCmd) {
        case OrderTypeBuy:
            request.action = TRADE_ACTION_DEAL;
            request.type = ORDER_TYPE_BUY;
            break;
        case OrderTypeSell:
            request.action = TRADE_ACTION_DEAL;
            request.type = ORDER_TYPE_SELL;
            break;
        case OrderTypeBuyStop:
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_BUY_STOP;
            isPending = true;
            break;
        case OrderTypeSellStop:
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_SELL_STOP;
            isPending = true;
            break;
        case OrderTypeBuyLimit:
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_BUY_LIMIT;
            isPending = true;
            break;
        case OrderTypeSellLimit:
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
            ulong targetTicket = result.order; //isPending ? result.order : HistoryDealGetInteger(result.deal, DEAL_POSITION_ID);
            double targetPrice = isPending ? posPrice : result.price;
            if(!sendModify(targetTicket, targetPrice, posStoploss, posTakeprofit, posExpiration, !isPending)) {
                Error::PrintError(ErrorNormal, "Could not set immediate SLTP for order " + targetTicket, NULL, NULL, true);
            }
        }
    } else {
        request.sl = posStoploss;
        request.tp = posTakeprofit;
        callResult = OrderSend(request, result);
    }

    if(callResult && Common::IsOrderRetcodeSuccess(result.retcode, false)) {
        // note: 10008 (TRADE_RETCODE_PLACED) result for OrderAsync, 10009 (TRADE_RETCODE_DONE) for OrderSend
        finalResult = result.order; //isPending ? result.order : HistoryDealGetInteger(result.deal, DEAL_POSITION_ID); // todo: we pass net position as result and unit position to the counter?
        addOrderToOpenCount(finalResult, -1, !isPending, false);
    }
    
    return finalResult; 
}
#endif
#endif

//+------------------------------------------------------------------+

#ifdef __MQL4__
bool OrderManager::sendModify(int ticket, double price, double stoploss, double takeprofit, datetime expiration, bool isPosition) {
    bool result = false;
    
#ifdef _OrderReliable
    result = OrderModifyReliable(ticket, price, stoploss, takeprofit, expiration);
#else
    result = OrderModify(ticket, price, stoploss, takeprofit, expiration);
#endif

    return result;
}
#else
#ifdef __MQL5__
bool OrderManager::sendModify(ulong ticket, double price, double stoploss, double takeprofit, datetime expiration, bool isPosition) {
    MqlTradeRequest modRequest = {0};
    MqlTradeResult modResult = {0};
    
    if(!isPosition) {
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
        || !Common::IsOrderRetcodeSuccess(modResult.retcode, true) 
    ) {
        return false;
    } else { return true; }
}
#endif
#endif

//+------------------------------------------------------------------+

#ifdef __MQL4__
bool OrderManager::sendClose(int ticket, int symIdx, bool isPosition) {
    if(IsTradeContextBusy()) { return false; }

    bool result = false;
    if(!checkDoSelect(ticket, isPosition)) { return false; }

    string posSymName = getOrderSymbol(isPosition);
    double posLots = getOrderLots(isPosition);
    int posType = getOrderType(isPosition);
    double posPrice = 0;
    if(Common::OrderIsLong(posType)) { posPrice = SymbolInfoDouble(posSymName, SYMBOL_BID); } // Buy order, even idx
    else { posPrice = SymbolInfoDouble(posSymName, SYMBOL_ASK); } // Sell order, odd idx
    
    int posSlippage = 0;
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
bool OrderManager::sendClose(ulong ticket, int symIdx, bool isPosition) {
    MqlTradeRequest closeRequest = {0};
    MqlTradeResult closeResult = {0};
    
    bool callResult = false;
    if(!isPosition) {
        closeRequest.action = TRADE_ACTION_REMOVE;
        closeRequest.order = ticket;
        callResult = OrderSend(closeRequest, closeResult);
    } else { // is position
        if(!checkDoSelect(ticket, isPosition)) { return false; }
        
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
        
        int posSlippage = 0;
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
bool OrderManager::checkDoSelect(int ticket, bool isPosition) {
    if(getOrderTicket(false) != ticket) { 
        if(!OrderSelect(ticket, SELECT_BY_TICKET)) { 
            return false; 
        } 
    }
    
    return true;
}
#else
#ifdef __MQL5__
bool OrderManager::checkDoSelect(ulong ticket, bool isPosition) {
    if(!isPosition) {
        if(getOrderTicket(isPosition) != ticket) { 
            if(!OrderSelect(ticket)) { 
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
int OrderManager::getOrderType(bool isPosition) { return OrderType(); }
int OrderManager::getOrderTicket(bool isPosition) { return OrderTicket(); }
double OrderManager::getOrderStopLoss(bool isPosition) { return OrderStopLoss(); }
double OrderManager::getOrderTakeProfit(bool isPosition) { return OrderTakeProfit(); }
int OrderManager::getOrderMagicNumber(bool isPosition) { return OrderMagicNumber(); }
string OrderManager::getOrderSymbol(bool isPosition) { return OrderSymbol(); }
double OrderManager::getOrderLots(bool isPosition) { return OrderLots(); }
double OrderManager::getOrderOpenPrice(bool isPosition) { return OrderOpenPrice(); }
datetime OrderManager::getOrderExpiration(bool isPosition) { return OrderExpiration(); }
bool OrderManager::getOrderSelect(int index, int select, int pool, bool isPosition) { return OrderSelect(index, select, pool); }
double OrderManager::getOrderProfit(bool isPosition) { return OrderProfit(); }
int OrderManager::getOrdersTotal(bool isPosition) { return OrdersTotal(); }
#else
#ifdef __MQL5__
long OrderManager::getOrderType(bool isPosition) {
    if(!isPosition) { return OrderGetInteger(ORDER_TYPE); }
    else { return PositionGetInteger(POSITION_TYPE); }
}

long OrderManager::getOrderTicket(bool isPosition) {
    if(!isPosition) { return OrderGetInteger(ORDER_TICKET); }
    else { return PositionGetInteger(POSITION_TICKET); }
}

double OrderManager::getOrderStopLoss(bool isPosition) {
    if(!isPosition) { return OrderGetDouble(ORDER_SL); }
    else { return PositionGetDouble(POSITION_SL); }
}

double OrderManager::getOrderTakeProfit(bool isPosition) {
    if(!isPosition) { return OrderGetDouble(ORDER_TP); }
    else { return PositionGetDouble(POSITION_TP); }
}

long OrderManager::getOrderMagicNumber(bool isPosition) {
    if(!isPosition) { return OrderGetInteger(ORDER_MAGIC); }
    else { return PositionGetInteger(POSITION_MAGIC); }
}

string OrderManager::getOrderSymbol(bool isPosition) {
    if(!isPosition) { return OrderGetString(ORDER_SYMBOL); }
    else { return PositionGetString(POSITION_SYMBOL); }
}

double OrderManager::getOrderLots(bool isPosition) {
    if(!isPosition) { return OrderGetDouble(ORDER_VOLUME_CURRENT); }
    else { return PositionGetDouble(POSITION_VOLUME); }
}

double OrderManager::getOrderOpenPrice(bool isPosition) {
    if(!isPosition) { return OrderGetDouble(ORDER_PRICE_OPEN); }
    else { return PositionGetDouble(POSITION_PRICE_OPEN); }
}

datetime OrderManager::getOrderExpiration(bool isPosition) {
    if(!isPosition) { return (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION); }
    else { return 0; }
}

bool OrderManager::getOrderSelect(int index, int select, int pool=MODE_TRADES, bool isPosition = false) {
    switch(pool) {
        case MODE_TRADES:
            switch(select) {
                case SELECT_BY_TICKET:
                    if(!isPosition) { return OrderSelect(index); }
                    else { return PositionSelectByTicket(index); }
                
                case SELECT_BY_POS:
                    if(!isPosition) { return (OrderGetTicket(index) > 0); }
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

double OrderManager::getOrderProfit(bool isPosition) { // should always be called for a position
    if(!isPosition) { 
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

int OrderManager::getOrdersTotal(bool isPosition) {
    if(!isPosition) {
        return OrdersTotal();
    } else {
        return PositionsTotal();
    }
}
#endif
#endif
