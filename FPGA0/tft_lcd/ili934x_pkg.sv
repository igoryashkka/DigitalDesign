package ili934x_pkg;
  typedef struct packed {
    logic       is_cmd;   // 1 = command, 0 = data
    logic [7:0] byte;
  } wr_item_t;
endpackage
