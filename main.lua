local BASE_URL = "https://raw.githubusercontent.com/Chaints/dakzzui/main/"

local function loadRemote(path)
    -- cache-busting: raw.githubusercontent.com di-cache oleh CDN GitHub
    -- selama beberapa menit per URL. Nambahin query string random bikin
    -- tiap request keliatan sebagai URL baru buat CDN-nya, jadi selalu
    -- ambil versi terbaru dari repo, bukan versi lama yang ke-cache.
    local url = BASE_URL .. path .. "?v=" .. tostring(math.random(1, 1000000000)) .. tostring(tick())
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
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
