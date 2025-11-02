# 2025-11-02T15:55:19.268302500
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.get_component(name="zync_dsp_03")
status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

comp.build()

comp.build()

comp.build()

