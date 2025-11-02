# 2025-11-02T01:45:55.616889800
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

comp = client.get_component(name="app_component")
comp.build()

comp.build()

vitis.dispose()

