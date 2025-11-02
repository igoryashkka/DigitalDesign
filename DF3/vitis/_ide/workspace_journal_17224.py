# 2025-11-01T22:29:35.010235400
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

comp = client.get_component(name="app_component")
comp.build()

vitis.dispose()

