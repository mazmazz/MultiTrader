# MultiTrader

![MultiTrader illustration](https://github.com/marcolovescode/MultiTrader/raw/master/docs/multitrader.gif)

This MetaTrader 4 and MetaTrader 5 plugin trades and monitors multiple foreign exchange currencies
concurrently. It is designed to accept multiple indicators (called "filters") that dictate whether
to open or close a trade.

This plugin supports the following scenarios:

* Selecting and excluding specific currencies
* Max trades per account or symbol
* Minimum account margin level
* Delays to react to a filter signal, or delay re-entering a trade
* Grid trades
* Constant stop loss/take profit (SL/TP), as well as trailing, jumping, and breakeven SL/TP
* Basket trades
* Honoring a broker's trading schedule
* Multiple filters and variants, e.g., track the Stochastic indicator on M15, M30, and H1 timeframes
* Optimization of each filter and variant during backtesting

## Docs

* [MultiTrader User Manual](https://github.com/marcolovescode/MultiTrader/blob/master/docs/MultiOp%20User%20Manual.pdf) -- End user manual for operating this plugin.
* [MultiTrader Code Reference](https://github.com/marcolovescode/MultiTrader/blob/master/docs/MultiOp%20Code%20Reference.pdf) -- Programmer's reference for this codebase. Incomplete.

## Author's Notes

I built this plugin to support complex account management scenarios. If I continued development,
I would have designed a signal generator on Python then piped those signals into this
plugin via interprocess communication.

## License

See LICENSE for the current license. The following files may have different licenses:

* [/MQL/Experts/MMT_MultiTrader/depends](https://github.com/marcolovescode/MultiTrader/blob/master/MQL4/Experts/MMT_MultiTrader/depends) -- Order utility code. See files for authorship.

## Other Projects

This project is part of a suite of programs I wrote to guide a trading business strategy. The other programs are:

* [AccountRecorder](https://github.com/marcolovescode/AccountRecorder) - Record FX transactions onto a SQL database.
* [SkepticSystem](https://github.com/marcolovescode/SkepticSystem) - Generate trading algorithms by using a hyperparameter search to test for prediction accuracy.
