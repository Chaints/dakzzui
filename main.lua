-- ==========================================
-- main.lua — Bounty Hunter Loader
-- Paste file ini ke Delta. Semua modul lain (loading, ui, auto)
-- otomatis di-download & dijalankan dari GitHub.
--
-- CATATAN: Ganti semua "USERNAME/REPO/main" di bawah dengan
-- link raw GitHub repo kamu yang sebenarnya.
-- ==========================================

local BASE_URL = "https://raw.githubusercontent.com/USERNAME/REPO/main/"

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

-- 1. Jalankan animasi loading ZxD dulu (berjalan sampai selesai / blocking)
loadRemote("loading.lua")

-- 2. Jalankan auto.lua — dia akan otomatis load ui.lua sendiri di dalamnya
loadRemote("auto.lua")
