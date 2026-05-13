# 🔇 MF Gag System

Copyright (c) 2026 [MochiFoxy && FoxyBlinks]. All rights reserved. Bu projenin kaynak kodu hiçbir şekilde kopyalanamaz, dağıtılamaz veya izinsiz kullanılamaz

CS 1.6 (GoldSrc) motoru için geliştirilmiş, yüksek performanslı, güvenli ve estetik bir Gag (Susturma) sistemidir. AMX Mod X altyapısını kullanır.

[![Game](https://img.shields.io/badge/Game-CS%201.6-orange.svg)](https://store.steampowered.com/app/10/CounterStrike/)
[![Platform](https://img.shields.io/badge/Platform-AMX%20Mod%20X%201.10%2B-blue.svg)](https://www.amxmodx.org/)

---

## ✨ Özellikler

*   **🧱 Modüler Mimari:** Core, Commands ve Menu olmak üzere 3 ayrı parçadan oluşur. Birinde yapılan değişiklik diğerlerini bozmaz.
*   **💾 Kalıcı Kayıt (nVault):** Oyuncu sunucudan çıksa bile cezası `AuthID` ve `IP` üzerinden hafızada tutulur. Süre dolmadan girerse cezası devam eder.
*   **🎙️ Tam Engelleme:** Hem Chat (Yazı) hem de Voice (Ses) engellemesi yapar. Ses engellemesi için en stabil yöntem olan `Fakemeta` kancaları kullanılmıştır.
*   **🎨 Estetik Tasarım (ASCII):** CS 1.6 motorunun sınırları zorlanarak, tüm dillerde ve sistemlerde bozulmadan çalışan şık bir ASCII menü tasarımı yapılmıştır.
*   **🛡️ Çakışma Koruması:** Task ID'leri ofsetlenerek diğer eklentilerle çakışması engellenmiştir.
*   **🛠️ Admin Dostu İşlem Menüsü:** Gaglı bir oyuncuya tıklandığında direkt açmak yerine "Gagı Kaldır" veya "Süreyi Düzenle" seçenekleri sunar.

---

## 📁 Dosya Yapısı

*   `mf_gag_core.sma` - Sistem çekirdeği, nVault kayıtları ve engelleme mantığı.
*   `mf_gag_cmds.sma` - Konsol ve Chat üzerinden kullanılan `/gag` komutları.
*   `mf_gag_menu.sma` - Adminlerin kullandığı gelişmiş `/gagmenu` arayüzü.
*   `include/mf_gag.inc` - Modüllerin birbiriyle konuşmasını sağlayan API dosyası.

---

## 🚀 Kurulum

1.  `include/mf_gag.inc` dosyasını `scripting/include/` klasörüne atın.
2.  3 adet `.sma` dosyasını derleyin (`compile` edin).
3.  Oluşan `.amxx` dosyalarını `plugins/` klasörüne atın.
4.  `plugins.ini` dosyasına eklenti isimlerini sırasıyla ekleyin:
    ```text
    mf_gag_core.amxx
    mf_gag_cmds.amxx
    mf_gag_menu.amxx
    ```
5.  Sunucuyu yeniden başlatın veya harita değiştirin.

---

## ⌨️ Komutlar

### 👑 Admin Komutları (KICK Yetkisi Gerekir)
*   `say /gagmenu` - Gelişmiş estetik yönetim menüsünü açar.
*   `say /gag <isim/userid> <sure>` - Chat üzerinden hızlı gag atar.
*   `say /ungag <isim/userid>` - Chat üzerinden gag kaldırır.
*   `amx_gag <isim/userid> <sure>` - Konsol üzerinden gag atar.
*   `amx_ungag <isim/userid>` - Konsol üzerinden gag kaldırır.

> [!NOTE]
> Süre olarak `0` girilirse veya boş bırakılırsa ceza **SINIRSIZ** olarak uygulanır.

---

## 👨‍💻 Yapımcılar
*   **mochifoxy** & **FoxyBlinks**
