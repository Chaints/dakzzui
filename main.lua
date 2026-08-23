local BASE_URL = "https://raw.githubusercontent.com/Chaints/dakzzui/main/"

local function loadRemote(path)
    local url = BASE_URL .. path
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if not ok then
        warn("[Loader] Gagal load " .. path .. ": " .. tostring(result))
        return nil
    end

    return result
end

-- ==========================================
-- 1. Jalankan animasi loading dulu (blocking sampai selesai,
--    karena loading.lua sendiri pakai task.wait di akhir baris-baris eksekusinya)
-- ==========================================
loadRemote("loading.lua")

-- ==========================================
-- 2. Baru jalankan logic utama (auto.lua), yang di dalamnya
--    otomatis meng-load ui.lua juga
-- ==========================================
loadRemote("auto.lua")
