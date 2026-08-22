-- Menggunakan Rayfield UI Library untuk tampilan modern
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Dakzz UI | Hub",
   LoadingTitle = "Loading UI...",
   LoadingSubtitle = "by Chaints",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DakzzConfig",
      FileName = "Config"
   },
   KeySystem = false
})

local MainTab = Window:CreateTab("Main", 4483362458)
local Section = MainTab:CreateSection("Features")

MainTab:CreateButton({
   Name = "Test Button",
   Callback = function()
       Rayfield:Notify({
          Title = "Notifikasi",
          Content = "Tombol berhasil diklik!",
          Duration = 3,
          Image = 4483362458,
       })
   end,
})

MainTab:CreateToggle({
   Name = "Example Toggle",
   CurrentValue = false,
   Flag = "Toggle1",
   Callback = function(Value)
       print("Status Toggle:", Value)
   end,
})
