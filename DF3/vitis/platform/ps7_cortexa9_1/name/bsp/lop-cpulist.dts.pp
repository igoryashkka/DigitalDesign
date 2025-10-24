# 1 "C:/Xilinx/2025.1/Vitis/bin/unwrapped/win64.o/lopper/depends/lopper/lops/lop-cpulist.dts"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "C:/Xilinx/2025.1/Vitis/bin/unwrapped/win64.o/lopper/depends/lopper/lops/lop-cpulist.dts"
# 10 "C:/Xilinx/2025.1/Vitis/bin/unwrapped/win64.o/lopper/depends/lopper/lops/lop-cpulist.dts"
/dts-v1/;

/ {
        compatible = "system-device-tree-v1,lop";
        lops {
                compatible = "system-device-tree-v1,lop";
                lop_0 {
                      compatible = "system-device-tree-v1,lop,select-v1";
                      select_1;
                      select_2 = "/.*:compatible:cpus,cluster";
                      lop_0_1 {
                              compatible = "system-device-tree-v1,lop,code-v1";
                              inherit = "lopper_lib";
                              code = "
                                     import yaml
                                     cpu_output = {}
                                     for c in __selected__:
                                         for c_node in c.subnodes( children_only = True ):
                                             try:
                                                 cpu_node = c_node['reg'].value
                                                 cpu_node = c_node.name
                                                 symbol_node = node.tree['/__symbols__']
                                                 prop_dict = symbol_node.__props__
                                                 match = [label for label,node_abs in prop_dict.items() if re.match(node_abs[0], c_node.abs_path) and len(node_abs[0]) == len(c_node.abs_path)]
                                                 cpu_node = match[0]
                                                 ip_name = c_node['xlnx,ip-name'].value
                                             except:
                                                 cpu_node = None
                                             if cpu_node:
                                               cpu_output[cpu_node] = ip_name[0]
                                     with open('cpulist.yaml', 'w') as fd:
                                         fd.write(yaml.dump(cpu_output, indent = 4))
                                     ";
                      };
                };
        };
};
