File.rm_rf("test/tmp")
Mix.Task.run("nerves_hub_ca.init")

Application.stop(:nerves_hub_ca)
Application.start(:nerves_hub_ca)

ExUnit.start()
