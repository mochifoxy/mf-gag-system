# 🔇 MF Gag & Auto Gag System

Copyright (c) 2026 [MochiFoxy && FoxyBlinks]. All rights reserved. Bu projenin kaynak kodu hiçbir şekilde kopyalanamaz, dağıtılamaz veya izinsiz kullanılamaz.

CS 1.6 (GoldSrc) motoru için geliştirilmiş, yüksek performanslı, güvenli, estetik ve **yapay zeka benzeri akıllı filtreleme** özelliklerine sahip gelişmiş bir Gag (Susturma) ve Otomatik Ceza sistemidir. AMX Mod X altyapısını kullanır.

[![Game](https://img.shields.io/badge/Game-CS%201.6-orange.svg)](https://store.steampowered.com/app/10/CounterStrike/)
[![Platform](https://img.shields.io/badge/Platform-AMX%20Mod%20X%201.10%2B-blue.svg)](https://www.amxmodx.org/)
[![Version](https://img.shields.io/badge/Versiyon-1.3-green.svg)]()

---

## ✨ Özellikler

### 🛡️ Genel Gag Sistemi
*   **🧱 Modüler Mimari:** Core, Commands ve Menu olmak üzere 3 ayrı parçadan oluşur. Birinde yapılan değişiklik diğerlerini bozmaz.
*   **💾 Kalıcı Kayıt (nVault):** Oyuncu sunucudan çıksa bile cezası `AuthID` ve `IP` üzerinden hafızada tutulur. Süre dolmadan girerse cezası devam eder.
*   **🎙️ Tam Engelleme:** Hem Chat (Yazı) hem de Voice (Ses) engellemesi yapar. Ses engellemesi için en stabil yöntem olan `Fakemeta` kancaları kullanılmıştır.
*   **🎨 Estetik Tasarım:** CS 1.6 motorunun sınırları zorlanarak, tüm dillerde ve sistemlerde bozulmadan çalışan şık bir menü tasarımı yapılmıştır.
*   **🛠️ Admin Dostu İşlem Menüsü:** Gaglı bir oyuncuya tıklandığında "Gagı Kaldır", "Süreyi Uzat" veya "Süreyi Kısalt" seçenekleri sunar. Sebep seçimi ekranında **seçilen süre ve hedef oyuncu** gösterilir.
*   **🔓 Komut İzni:** Gaglı oyuncular `/top15`, `/rank` veya `/gagmenu` gibi `/` ve `.` ile başlayan komutları kullanmaya devam edebilirler.

### 🤖 Akıllı Otomatik Gag Sistemi
*   **⚡ Trie Map Teknolojisi:** Yasaklı kelime aramaları O(1) karmaşıklığında, yani şimşek hızında yapılır. Büyük kelime listelerinde bile sunucuda kesinlikle lag veya FPS düşüşü yapmaz.
*   **🧠 Akıllı Filtreleme (Anti-Bypass):**
    *   *Harf Sıkıştırma:* `kuuuufuuuur` yazılsa bile otomatik olarak `kufur` haline getirilip yakalanır.
    *   *Sembol Temizleme:* `k.u_f.u_r` gibi aralara konulan semboller temizlenir.
    *   *Türkçe Karakter Eşleme:* `şalak` yazıldığında `salak` olarak algılanır.
    *   *Leet Speak Desteği:* `s4l4k` gibi sayıyla gizlenen kelimeler harfe çevrilip yakalanır.
*   **🌊 Dinamik Flood Koruması:** Kısa sürede art arda mesaj atan oyuncuları uyarır ve susturur. Eşikler CVAR ile tamamen özelleştirilebilir.
*   **📈 Dinamik Kademeli Ceza Sistemi:** Temel süre CVAR ile belirlenir (varsayılan 15 dk). Her ihlalde süre **2'ye katlanarak** artar: `15 → 30 → 60 → 120 dk`. **5. ihlalde SINIRSIZ** gag atılır.
*   **❤️ Otomatik Sicil Temizleme (Davranış Analizi):** Oyuncu temiz kaldığı her `N` saatte (CVAR ile ayarlanır) ihlal puanı otomatik olarak 1 azalır. Timer yerine **On-Demand hesaplama** yapılır — sunucuya sıfır ek yük bindirir. Sicil düşüşü anında **nVault'a kaydedilir**, çık-gir yapsa bile doğru değer korunur.
*   **💾 Gelişmiş nVault Hafızası:** İhlal ve uyarı sayıları 24 saat boyunca hem `SteamID` hem de `IP` üzerinden takip edilir. Çık-gir yaparak uyarılardan veya cezalardan kaçılamaz.
*   **🔒 Format String Crash Koruması:** Oyuncuların chatten `%s%s%s` gibi özel karakterler göndererek sunucuyu çökertemsi (Segment Fault) tamamen engellenmiştir.
*   **📁 Temiz Kelime Listesi:** `amx_kufurekle` komutu kelimeyi Trie'a temizlenmiş haliyle ekler ve dosyaya da **temizlenmiş** halini yazar. Dosya her zaman tutarlı ve okunabilir kalır.

---

## 📁 Dosya Yapısı

```
addons/amxmodx/
├── scripting/
│   ├── mf_gag_core.sma       # Sistem çekirdeği, nVault ve engelleme mantığı
│   ├── mf_gag_cmds.sma       # /gag, /ungag konsol komutları
│   ├── mf_gag_menu.sma       # Estetik /gagmenu arayüzü
│   ├── mf_auto_gag.sma       # Akıllı otomatik gag ve yasaklı kelime filtresi
│   └── include/
│       └── mf_gag.inc        # Modüller arası API
├── plugins/
│   ├── mf_gag_core.amxx
│   ├── mf_gag_cmds.amxx
│   ├── mf_gag_menu.amxx
│   └── mf_auto_gag.amxx
└── configs/
    └── kufurler.txt          # 700+ kelimelik yasaklı kelime listesi
```

---

## 🚀 Kurulum

1.  `include/mf_gag.inc` dosyasını `scripting/include/` klasörüne atın.
2.  Tüm `.sma` dosyalarını derleyin (`compile` edin).
3.  Oluşan `.amxx` dosyalarını `plugins/` klasörüne atın.
4.  `plugins.ini` dosyasına eklenti isimlerini **sırasıyla** ekleyin:
    ```
    mf_gag_core.amxx
    mf_gag_cmds.amxx
    mf_gag_menu.amxx
    mf_auto_gag.amxx
    ```
5.  `kufurler.txt` dosyasını `addons/amxmodx/configs/` klasörüne atın.
6.  Sunucuyu yeniden başlatın veya harita değiştirin.

> [!IMPORTANT]
> `mf_gag_core.amxx` diğer tüm eklentilerden **önce** yüklenmelidir. `plugins.ini` sıralaması bu açıdan kritiktir.

---

## ⌨️ Komutlar

### 👑 Admin Komutları (KICK Yetkisi Gerekir)

| Komut | Açıklama |
|---|---|
| `say /gagmenu` veya `/gm` | Estetik gag yönetim panelini açar |
| `say /ungagmenu` veya `/ugm` | Gaglı oyuncuların listesini doğrudan açar |
| `say /gag <isim/userid> <sure>` | Chat üzerinden hızlı gag atar |
| `say /ungag <isim/userid>` | Chat üzerinden gag kaldırır |

### 🔑 Admin Komutları (RCON Yetkisi Gerekir)

| Komut | Açıklama |
|---|---|
| `amx_kufurekle <kelime>` | Çalışırken yeni yasaklı kelime ekler |
| `amx_kufursil <kelime>` | Yasaklı kelimeyi listeden kaldırır |

### ⚙️ CVAR Ayarları

| CVAR | Varsayılan | Açıklama |
|---|---|---|
| `amx_autogag` | `1` | AutoGag sistemini açar/kapatır |
| `amx_autogag_default_time` | `15` | Temel gag süresi (dakika) |
| `amx_autogag_warning_limit` | `3` | Gag atılmadan önceki uyarı sayısı |
| `amx_autogag_flood_time` | `2.0` | Flood sayılacak mesaj aralığı (saniye) |
| `amx_autogag_flood_limit` | `3` | Art arda kaç hızlı mesajın flood sayılacağı |
| `amx_autogag_decay_time` | `3600` | Sicil temizleme süresi (saniye). `0` = kapalı |

> [!NOTE]
> Manuel gag atarken süre olarak `0` girilirse ceza **SINIRSIZ** olarak uygulanır.

> [!TIP]
> `amx_autogag_decay_time 3600` → Oyuncu 1 saat temiz kalırsa ihlali 1 azalır. `7200` yaparsanız 2 saat olur.

---

## 🏗️ Mimari & Teknik Detaylar

*   **Arama Karmaşıklığı:** O(1) — Trie (Hash Map) sayesinde kelime listesi ne kadar büyük olursa olsun arama süresi sabittir.
*   **Hafıza Yönetimi:** `plugin_end` fonksiyonunda `TrieDestroy` ve `nvault_close` çağrılır, memory leak yoktur.
*   **Bot/HLTV Güvenliği:** Botlar ve HLTV kopyaları `client_putinserver` içinde filtrelenerek nVault şişmesi önlenir.
*   **Güvenlik:** Format String açıkları `%%` dönüşümü ile kapatılmıştır.
*   **Kayıt:** Tüm işlemler `mf_gag.log` dosyasına zaman damgasıyla loglanır.

---

## 👨‍💻 Yapımcılar
*   **mochifoxy** & **FoxyBlinks**
