-- Tunggu sampai game benar-benar 100% termuat
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(3)

local placeId = game.PlaceId
print("[Loader] Mengecek lokasi... Place ID yang terbaca saat ini: " .. tostring(placeId))

-- Tabel Kumpulan Place ID (Bisa kalian tambah sendiri kalau nanti nemu ID baru)
local Sea2_IDs = {4442272000, 4442272183, 79091703265657}
local Sea3_IDs = {7449423635, 100117331123089}
local Sea1_IDs = {2753915549}

if table.find(Sea2_IDs, placeId) then
    print("[Loader] Terdeteksi di SEA 2 (Public/PS)! Memuat script Sea 2...")
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chaints/dakzzui/refs/heads/main/Sea2b.lua"))()
    end)
    if not success then
        warn("[Loader Error] Gagal memuat script Sea 2! Detail: " .. tostring(err))
    end

elseif table.find(Sea3_IDs, placeId) then
    print("[Loader] Terdeteksi di SEA 3 (Public/PS)! Memuat script Sea 3...")
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chaints/dakzzui/refs/heads/main/Sea3b.lua"))()
    end)
    if not success then
        warn("[Loader Error] Gagal memuat script Sea 3! Detail: " .. tostring(err))
    end

elseif table.find(Sea1_IDs, placeId) then
    warn("[Loader] Kamu berada di Sea 1. Silakan pindah ke Sea 2 atau Sea 3 dulu!")

else
    -- Kalau masuk ke sini, berarti ID gamenya anomali lagi
    warn("==============================================")
    warn("🚨 GAME TIDAK DIKENALI SEBAGAI BLOX FRUITS 🚨")
    warn("PLACE ID YANG TERBACA: " .. tostring(placeId))
    warn("==============================================")
    warn("Masukkan angka di atas ke dalam tabel 'Sea2_IDs' atau 'Sea3_IDs' di baris atas script!")
end
