# 2026-02-16T14:53:00.588189200
import vitis

client = vitis.create_client()
client.set_workspace(path="ws_vitis")

platform = client.get_component(name="platform_xsa")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../sources/microblaze_wrapper.xsa")

status = platform.build()

status = platform.build()

comp = client.get_component(name="app_component_xsa")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

