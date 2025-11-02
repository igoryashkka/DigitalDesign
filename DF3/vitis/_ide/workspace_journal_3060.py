# 2025-11-02T14:18:19.509546700
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

comp = client.get_component(name="app_component")
comp.build()

comp.build()

comp.build()

comp.build()

advanced_options = client.create_advanced_options_dict(dt_overlay="0")

platform = client.create_platform_component(name = "zync_dsp_03",hw_design = "$COMPONENT_LOCATION/../../Decoder/design_1_wrapper_zync_with_dsp_02.xsa",os = "standalone",cpu = "ps7_cortexa9_0",domain_name = "standalone_ps7_cortexa9_0",generate_dtb = False,advanced_options = advanced_options,compiler = "gcc")

platform = client.get_component(name="zync_dsp_03")
status = platform.build()

comp.build()

comp.build()

comp.build()

client.delete_component(name="zync_dsp_02")

client.delete_component(name="componentName")

comp.build()

status = platform.build()

vitis.dispose()

