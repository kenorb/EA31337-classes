//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 *  This file is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * @file
 * Test functionality of Strategy class.
 */

// Includes.
#include "../Strategy.mqh"
#include "../Test.mqh"

// Properties.
#property strict

// Define strategy classes.
class Stg1 : public Strategy {

  public:

    // Class constructor.
    void Stg1(StgParams &_params, string _name = "") : Strategy(_params, _name) {}

    bool SignalOpen(ENUM_ORDER_TYPE cmd, long signal_method = EMPTY, double signal_level1 = EMPTY, double signal_level12 = EMPTY) {
      return signal_method % 2 == 0;
    }

};

class Stg2 : public Strategy {

  public:

    // Class constructor.
    void Stg2(StgParams &_params, string _name = "") : Strategy(_params, _name) {}

    bool SignalOpen(ENUM_ORDER_TYPE cmd, long signal_method = EMPTY, double signal_level1 = EMPTY, double signal_level12 = EMPTY) {
      return signal_method % 2 == 0;
    }

};

// Global variables.
Strategy *strat1;
Strategy *strat2;

/**
 * Implements OnInit().
 */
int OnInit() {

  // Initial market tests.
  assertTrueOrFail(SymbolInfo::GetAsk(_Symbol) > 0, "Invalid Ask price!");

  /* Test 1st strategy. */

  // Initialize strategy.
  StgParams stg1_params(new Trade(PERIOD_M1, _Symbol));
  stg1_params.magic_no = 1;
  strat1 = new Stg1(stg1_params, "Stg1");
  assertTrueOrFail(strat1.GetName() == "Stg1", "Invalid Strategy name!");
  assertTrueOrFail(strat1.IsValid(), "Fail on IsValid()!");

  // Test whether strategy is enabled and not suspended.
  assertTrueOrFail(strat1.IsEnabled(), "Fail on IsEnabled()!");
  assertFalseOrFail(strat1.IsSuspended(), "Fail on IsSuspended()!");

  // Test market.
  assertTrueOrFail(strat1.Market().GetOpen() > 0, "Fail on GetOpen()!");
  assertTrueOrFail(strat1.Market().GetSymbol() == _Symbol, "Fail on GetSymbol()!");
  assertTrueOrFail(strat1.Chart().GetTf() == PERIOD_M1,
    StringFormat("Fail on GetTf() => [%s]!",
      EnumToString(strat1.Chart().GetTf())));

  /* Test 2nd strategy. */

  // Initialize strategy.
  StgParams stg2_params(new Trade(PERIOD_M5, _Symbol));
  stg2_params.magic_no = 2;
  stg2_params.enabled = false;
  stg2_params.suspended = true;
  strat2 = new Stg2(stg2_params);
  strat2.SetName("Stg2");
  assertTrueOrFail(strat2.GetName() == "Stg2", "Invalid Strategy name!");
  assertTrueOrFail(strat2.IsValid(), "Fail on IsValid()!");

  // Test market.
  assertTrueOrFail(strat2.Market().GetClose() > 0, "Fail on GetClose()!");
  assertTrueOrFail(strat2.Market().GetSymbol() == _Symbol, "Fail on GetSymbol()!");
  assertTrueOrFail(strat2.Chart().GetTf() == PERIOD_M5,
    StringFormat("Fail on GetTf() => [%s]!",
      EnumToString(strat1.Chart().GetTf())));

  // Test enabling.
  assertFalseOrFail(strat2.IsEnabled(), "Fail on IsEnabled()!");
  assertTrueOrFail(strat2.IsSuspended(), "Fail on IsSuspended()!");
  strat2.Enable();
  strat2.Resume();
  assertTrueOrFail(strat2.IsEnabled(), "Fail on IsEnabled()!");
  assertFalseOrFail(strat2.IsSuspended(), "Fail on IsSuspended()!");

  return (INIT_SUCCEEDED);
}

/**
 * Implements OnTick().
 */
void OnTick() {
}

/**
 * Implements OnDeinit().
 */
void OnDeinit(const int reason) {
  delete(strat1);
  delete(strat2);
}
