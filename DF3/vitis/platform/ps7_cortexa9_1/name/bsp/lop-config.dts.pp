# 1 "C:/Users/igor4/trash/Documents/DigitalDesign/DF3/vitis/platform/ps7_cortexa9_1/name/bsp/lop-config.dts"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "C:/Users/igor4/trash/Documents/DigitalDesign/DF3/vitis/platform/ps7_cortexa9_1/name/bsp/lop-config.dts"

/dts-v1/;
/ {
        compatible = "system-device-tree-v1,lop";
        lops {
                lop_0 {
                        compatible = "system-device-tree-v1,lop,load";
                        load = "assists/baremetal_validate_comp_xlnx.py";
                };

                lop_1 {
                    compatible = "system-device-tree-v1,lop,assist-v1";
                    node = "/";
                    outdir = "C:/Users/igor4/trash/Documents/DigitalDesign/DF3/vitis/platform/ps7_cortexa9_1/name/bsp";
                    id = "module,baremetal_validate_comp_xlnx";
                    options = "ps7_cortexa9_1 C:/Xilinx/2025.1/Vitis/data/embeddedsw/lib/sw_apps/hello_world/src C:/Users/igor4/trash/Documents/DigitalDesign/DF3/vitis/_ide/.wsdata/.repo.yaml";
                };

        };
    };
