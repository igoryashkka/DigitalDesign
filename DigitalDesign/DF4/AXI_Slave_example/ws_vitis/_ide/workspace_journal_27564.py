# 2026-02-11T19:57:22.767432
import vitis

client = vitis.create_client()
client.set_workspace(path="ws_vitis")

platform = client.create_platform_component(name = "platform_mb",hw_design = "$COMPONENT_LOCATION/../../sources/microblaze_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform_mb")
status = platform.build()

comp = client.create_app_component(name="app_component_MB",platform = "$COMPONENT_LOCATION/../platform_mb/export/platform_mb/platform_mb.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="app_component_MB")
status = comp.import_files(from_loc="", files=["C:\Users\user\Documents\dd_ihor\DigitalDesign\DF4\workspace_vitis\sources\main.c"], is_skip_copy_sources = False)

status = platform.build()

comp = client.get_component(name="app_component_MB")
comp.build()

status = platform.build()

comp.build()

client.delete_component(name="app_component_MB")

client.delete_component(name="componentName")

client.delete_component(name="componentName")

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../platform_mb/export/platform_mb/platform_mb.xpfm",domain = "standalone_microblaze_0")

status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../sources/microblaze_wrapper.xsa")

platform = client.create_platform_component(name = "platform_mb01",hw_design = "$COMPONENT_LOCATION/../../sources/microblaze_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform_mb01")
status = platform.build()

platform = client.create_platform_component(name = "platform_02",hw_design = "$COMPONENT_LOCATION/../../sources/microblaze_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform_mb")
status = platform.build()

comp.build()

status = platform.build()

comp.build()

client.delete_component(name="platform_02")

client.delete_component(name="platform_mb")

client.delete_component(name="componentName")

client.delete_component(name="platform_mb01")

client.delete_component(name="platform_mb01")

platform = client.create_platform_component(name = "platform_xsa",hw_design = "$COMPONENT_LOCATION/../../sources/microblaze_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform_xsa")
status = platform.build()

comp.build()

comp.build()

comp.build()

comp.build()

client.delete_component(name="app_component")

client.delete_component(name="componentName")

comp = client.create_app_component(name="app_component_xsa",platform = "$COMPONENT_LOCATION/../platform_xsa/export/platform_xsa/platform_xsa.xpfm",domain = "standalone_microblaze_0")

status = platform.build()

comp = client.get_component(name="app_component_xsa")
comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../sources/microblaze_wrapper.xsa")

status = platform.build()

comp.build()

