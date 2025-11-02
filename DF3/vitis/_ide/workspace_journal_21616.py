# 2025-10-24T23:32:54.418632600
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

advanced_options = client.create_advanced_options_dict(dt_overlay="0")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../Decoder/project/design_1_wrapper.xsa",os = "standalone",cpu = "ps7_cortexa9_0",domain_name = "standalone_ps7_cortexa9_0",generate_dtb = False,advanced_options = advanced_options,compiler = "gcc")

platform = client.get_component(name="platform")
domain = platform.add_domain(cpu = "ps7_cortexa9_1",os = "standalone",name = "name",display_name = "name",support_app = "hello_world",generate_dtb = False)

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_ps7_cortexa9_0")

status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

comp.build()

vitis.dispose()

vitis.dispose()

