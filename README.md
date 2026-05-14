# 🔇 MF Gag & Auto Gag System

Copyright (c) 2026 [MochiFoxy && FoxyBlinks]. All rights reserved. Bu projenin kaynak kodu hiçbir şekilde kopyalanamaz, dağıtılamaz veya izinsiz kullanılamaz.

CS 1.6 (GoldSrc) motoru için geliştirilmiş, yüksek performanslı, güvenli, estetik ve **yapay zeka benzeri akıllı filtreleme** özelliklerine sahip gelişmiş bir Gag (Susturma) ve Otomatik Ceza sistemidir. AMX Mod X altyapısını kullanır.

[![Game](https://img.shields.io/badge/Game-CS%201.6-orange.svg)](https://store.steampowered.com/app/10/CounterStrike/)
[![Platform](https://img.shields.io/badge/Platform-AMX%20Mod%20X%201.10%2B-blue.svg)](https://www.amxmodx.org/)

---

## ✨ Özellikler

### 🛡️ Genel Gag Sistemi
*   **🧱 Modüler Mimari:** Core, Commands ve Menu olmak üzere 3 ayrı parçadan oluşur. Birinde yapılan değişiklik diğerlerini bozmaz.
*   **💾 Kalıcı Kayıt (nVault):** Oyuncu sunucudan çıksa bile cezası `AuthID` ve `IP` üzerinden hafızada tutulur. Süre dolmadan girerse cezası devam eder.
*   **🎙️ Tam Engelleme:** Hem Chat (Yazı) hem de Voice (Ses) engellemesi yapar. Ses engellemesi için en stabil yöntem olan `Fakemeta` kancaları kullanılmıştır.
*   **🎨 Estetik Tasarım:** CS 1.6 motorunun sınırları zorlanarak, tüm dillerde ve sistemlerde bozulmadan çalışan şık bir menü tasarımı yapılmıştır.
*   **🛠️ Admin Dostu İşlem Menüsü:** Gaglı bir oyuncuya tıklandığında direkt açmak yerine "Gagı Kaldır" veya "Süreyi Düzenle" seçenekleri sunar.
*   **🔓 Komut İzni:** Gaglı oyuncular `/top15`, `/rank` veya `/gagmenu` gibi komutları kullanmaya devam edebilirler.

### 🤖 Akıllı Otomatik Gag Sistemi (YENİ!)
*   **⚡ Trie Map Teknolojisi:** Yasaklı kelime aramaları O(1) karmaşıklığında, yani şimşek hızında yapılır. Sunucuda kesinlikle lag veya FPS düşüşü yapmaz.
*   **🧠 Akıllı Filtreleme (Anti-Spam):** 
    *   *Harf Sıkıştırma:* `kuuuufuuuur` yazılsa bile otomatik olarak `kufur` haline getirilip yakalanır.
    *   *Sembol Temizleme:* `k.u_f.u_r` gibi aralara konulan semboller temizlenir.
    *   *Türkçe Karakter Eşleme:* `şalak` yazıldığında `salak` olarak algılanır.
    *   *Leet Speak Desteği:* `s4l4k` gibi sayıyla gizlenen kelimeler harfe çevrilip yakalanır.
*   **🌊 Dinamik Flood Koruması:** Belirli bir sürede çok fazla mesaj atan oyuncuları otomatik olarak uyarır ve susturur (CVAR ile ayarlanabilir).
*   **📈 Dinamik Kademeli Ceza Sistemi:** İlk ihlalde varsayılan süre (15 dk) uygulanır. Sonraki her ihlalde süre 2'ye katlanarak artar (30, 60, 120). **5. ihlalde ise SINIRSIZ** gag atılır!
*   **❤️ Otomatik Sicil Temizleme (Davranış Analizi):** Oyuncu sunucuda temiz kaldığı her 1 saat (ayarlanabilir) için ihlal puanı otomatik olarak 1 düşer. Sunucuyu yormayan akıllı algoritma kullanılmıştır.
*   **💾 Gelişmiş nVault Hafızası:** Oyuncuların sadece ihlal sayıları değil, o anki uyarı sayıları da kaydedilir. Çık-gir yaparak uyarılardan kaçamazlar.
*   **🔒 Crash Koruması:** Oyuncuların chatten `%` işaretleri kullanarak sunucuyu çökertmesi (Format String açığı) tamamen engellenmiştir.

---

## 📁 Dosya Yapısı

*   `mf_gag_core.sma` - Sistem çekirdeği, nVault kayıtları ve engelleme mantığı.
*   `mf_gag_cmds.sma` - Konsol ve Chat üzerinden kullanılan manuel `/gag` komutları.
*   `mf_gag_menu.sma` - Adminlerin kullandığı gelişmiş `/gagmenu` arayüzü.
*   `mf_auto_gag.sma` - **[YENİ]** Akıllı otomatik gag ve yasaklı kelime filtreleme eklentisi.
*   `include/mf_gag.inc` - Modüllerin birbiriyle konuşmasını sağlayan API dosyası.
*   `configs/kufurler.txt` - **[YENI]** 700+ kelimelik devasa kelime kara listesi.

---

## 🚀 Kurulum

1.  `include/mf_gag.inc` dosyasını `scripting/include/` klasörüne atın.
2.  Tüm `.sma` dosyalarını derleyin (`compile` edin).
3.  Oluşan `.amxx` dosyalarını `plugins/` klasörüne atın.
4.  `plugins.ini` dosyasına eklenti isimlerini sırasıyla ekleyin:
    ```text
    mf_gag_core.amxx
    mf_gag_cmds.amxx
    mf_gag_menu.amxx
    mf_auto_gag.amxx
    ```
5.  `kufurler.txt` dosyasını `addons/amxmodx/configs/` klasörüne atın.
6.  Sunucuyu yeniden başlatın veya harita değiştirin.

---

## ⌨️ Komutlar

### 👑 Admin Komutları (KICK / RCON Yetkisi Gerekir)
*   `say /gagmenu` - Gelişmiş estetik yönetim menüsünü açar.
*   `say /gag <isim/userid> <sure>` - Chat üzerinden hızlı gag atar.
*   `say /ungag <isim/userid>` - Chat üzerinden gag kaldırır.
*   `amx_kufurekle <kelime>` - Oyundan çıkmadan yeni yasaklı kelime ekler.
*   `amx_kufursil <kelime>` - Yasaklı kelimeyi listeden kaldırır.

### ⚙️ CVAR Ayarları (AutoGag)
*   `amx_autogag <0/1>` - Otomatik gag sistemini açar veya kapatır. (Varsayılan: 1)
*   `amx_autogag_default_time <dakika>` - Temel gag süresi. (Varsayılan: 15)
*   `amx_autogag_flood_time <saniye>` - Flood için iki mesaj arasındaki minimum süre. (Varsayılan: 2.0)
*   `amx_autogag_flood_limit <sayi>` - Üst üste kaç hızlı mesajın flood sayılacağı. (Varsayılan: 3)
*   `amx_autogag_warning_limit <sayi>` - Gag atılmadan önceki uyarı sınırı. (Varsayılan: 3)
*   `amx_autogag_decay_time <saniye>` - Sicil temizleme süresi. Oyuncu bu süre boyunca temiz durursa ihlali 1 düşer. (Varsayılan: 3600 = 1 saat)

> [!NOTE]
> Manuel gag atarken süre olarak `0` girilirse veya boş bırakılırsa ceza **SINIRSIZ** olarak uygulanır.

---

## 👨‍💻 Yapımcılar
*   **mochifoxy** & **FoxyBlinks**
