// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class uart_agent_cfg extends dv_base_agent_cfg;

  bit is_active     = 1'b1; // active driver or passive monitor
  bit en_cov        = 1'b1; // enable coverage
  bit en_rx_checks  = 1'b1; // enable RX checks (implemented in monitor)
  bit en_tx_checks  = 1'b1; // enable TX checks (implemented in monitor)
  bit en_rx_monitor = 1'b1; // enable RX monitor
  bit en_tx_monitor = 1'b1; // enable TX monitor

  // device specific cfg
  baud_rate_e baud_rate;
  bit en_parity;
  bit odd_parity;

  // interface handle used by driver, monitor & the sequencer
  virtual uart_if vif;

  `uvm_object_utils_begin(uart_agent_cfg)
    `uvm_field_int(is_active,    UVM_DEFAULT)
    `uvm_field_int(en_cov,       UVM_DEFAULT)
    `uvm_field_int(en_rx_checks, UVM_DEFAULT)
    `uvm_field_int(en_tx_checks, UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_object_new

  function void set_baud_rate(baud_rate_e b);
    baud_rate = b;
    vif.uart_clk_period_ns = (get_baud_rate_period_ns(b) * 1ns);
  endfunction

  function void set_parity(bit en_parity, bit odd_parity);
    this.en_parity = en_parity;
    this.odd_parity = odd_parity;
  endfunction

endclass
