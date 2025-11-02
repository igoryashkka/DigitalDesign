# 2025-11-03T00:17:31.177711900
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

comp = client.get_component(name="app_component")
comp.build()

comp.build()

comp.build()

comp.build()

vitis.dispose()

