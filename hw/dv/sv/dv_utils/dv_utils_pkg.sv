// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package dv_utils_pkg;
  // dep packages
  import uvm_pkg::*;
  import top_pkg::*;

  // macro includes
  `include "dv_macros.svh"
  `include "uvm_macros.svh"

  // common parameters used across all benches
  parameter int NUM_MAX_INTERRUPTS  = 32;
  parameter int NUM_MAX_ALERTS      = 32;
  parameter int NUM_ALERT_PINS      = 10;

  // types & variables
  typedef bit [31:0] uint;
  typedef bit [7:0]  uint8;
  typedef bit [15:0] uint16;
  typedef bit [31:0] uint32;
  typedef bit [63:0] uint64;

  // typedef parameterized pins_if for ease of implementation for interrupts and alerts
  typedef virtual pins_if #(NUM_MAX_INTERRUPTS) intr_vif;
  typedef virtual pins_if #(NUM_MAX_ALERTS)     alerts_vif;
  typedef virtual pins_if #(1)                  devmode_vif;
  typedef virtual pins_if #(1)                  tlul_assert_ctrl_vif;

  // alert io signals
  typedef enum {
    PingEn    = 0,
    PingOk    = 1,
    IntegFail = 2,
    Alert     = 3,
    AlertRx   = 4, // rx has 4 bits
    AlertTx   = 8  // tx has 2 bits
  } alert_pin_e;

  // interface direction / mode - Host or Device
  typedef enum bit {
    Host,
    Device
  } if_mode_e;

  // speed for the clock
  typedef enum int {
    ClkFreq24Mhz  = 24,
    ClkFreq25Mhz  = 25,
    ClkFreq48Mhz  = 48,
    ClkFreq50Mhz  = 50,
    ClkFreq100Mhz = 100
  } clk_freq_mhz_e;

  // compare operator types
  typedef enum {
    CompareOpEq,
    CompareOpCaseEq,
    CompareOpNe,
    CompareOpCaseNe,
    CompareOpGt,
    CompareOpGe,
    CompareOpLt,
    CompareOpLe
  } compare_op_e;

  // mem address struct
  typedef struct {
    uvm_reg_addr_t start_addr;
    uvm_reg_addr_t end_addr;
  } mem_addr_s;

  string msg_id = "dv_utils_pkg";

  // Simple function to set max errors before quitting sim
  function automatic void set_max_quit_count(int n);
    uvm_report_server report_server = uvm_report_server::get_server();
    report_server.set_max_quit_count(n);
  endfunction

  // return if uvm_fatal occurred
  function automatic bit has_uvm_fatal_occurred();
    uvm_report_server report_server = uvm_report_server::get_server();
    return report_server.get_severity_count(UVM_FATAL) > 0;
  endfunction

  // task that waits for the specfied timeout
  task automatic wait_timeout(input uint    timeout_ns,
                              input string  error_msg_id  = msg_id,
                              input string  error_msg     = "timeout occurred!",
                              input bit     report_fatal  = 1);
    #(timeout_ns * 1ns);
    if (report_fatal) `uvm_fatal(error_msg_id, error_msg)
    else              `uvm_error(error_msg_id, error_msg)
  endtask : wait_timeout

  // get masked data based on provided byte mask; if csr reg handle is provided (optional) then
  // masked bytes from csr's mirrored value are returned, else masked bytes are 0's
  function automatic bit [TL_DW-1:0] get_masked_data(bit [TL_DW-1:0]  data,
                                                     bit [TL_DBW-1:0] mask,
                                                     uvm_reg          csr = null);
    bit [TL_DW-1:0] csr_data;
    csr_data = (csr != null) ? csr.get_mirrored_value() : '0;
    get_masked_data = data;
    foreach (mask[i])
      if (~mask[i]) get_masked_data[i * 8 +: 8] = csr_data[i * 8 +: 8];
  endfunction

  // get absolute value of the input. Usage: absolute(val) or absolute(a - b)
  function automatic uint absolute(int val);
    return val >= 0 ? val : -val;
  endfunction

  // endian swap
  function automatic logic [31:0] endian_swap(logic [31:0] data);
    return {<<8{data}};
  endfunction

  // create a sequence by name and return the handle of uvm_sequence
  function automatic uvm_sequence create_seq_by_name(string seq_name);
    uvm_object      obj;
    uvm_factory     factory;
    uvm_sequence    seq;

    factory = uvm_factory::get();
    obj = factory.create_object_by_name(seq_name, "", seq_name);
    if (obj == null) begin
      // print factory overrides to help debug
      factory.print(1);
      `uvm_fatal(msg_id, $sformatf("could not create %0s seq", seq_name))
    end
    if (!$cast(seq, obj)) begin
      `uvm_fatal(msg_id, $sformatf("cast failed - %0s is not a uvm_sequence", seq_name))
    end
    return seq;
  endfunction

  // sources
  `include "dv_report_server.sv"

endpackage
