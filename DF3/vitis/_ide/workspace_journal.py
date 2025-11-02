# 2025-11-03T00:48:27.296362600
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

advanced_options = client.create_advanced_options_dict(dt_overlay="0")

platform = client.create_platform_component(name = "zync_dsp_04",hw_design = "$COMPONENT_LOCATION/../../Decoder/project/design_1_wrapper_zync_with_dsp_04.xsa",os = "standalone",cpu = "ps7_cortexa9_0",domain_name = "standalone_ps7_cortexa9_0",generate_dtb = False,advanced_options = advanced_options,compiler = "gcc")

platform = client.get_component(name="zync_dsp_04")
status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

comp.build()

client.delete_component(name="zync_dsp")

client.delete_component(name="zync_dsp_03")

client.delete_component(name="componentName")

