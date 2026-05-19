# 🔇 MF Gag & Auto Gag System

Copyright (c) 2026 [MochiFoxy && FoxyBlinks]. All rights reserved
CS 1.6 (GoldSrc) motoru için geliştirilmiş, yüksek performanslı, güvenli, estetik ve **yapay zeka benzeri akıllı filtreleme** özelliklerine sahip gelişmiş bir Gag (Susturma) ve Otomatik Ceza sistemidir. AMX Mod X altyapısını kullanır.

[![Game](https://img.shields.io/badge/Game-CS%201.6-orange.svg)](https://store.steampowered.com/app/10/CounterStrike/)
[![Platform](https://img.shields.io/badge/Platform-AMX%20Mod%20X%201.10%2B-blue.svg)](https://www.amxmodx.org/)
[![Version](https://img.shields.io/badge/Versiyon-1.6-green.svg)]()

---

## ✨ Özellikler

### 🛡️ Genel Gag Sistemi
*   **🧱 Modüler Mimari:** Core, Commands ve Menu olmak üzere 3 ayrı parçadan oluşur. Birinde yapılan değişiklik diğerlerini bozmaz.
*   **💾 Kalıcı Kayıt (nVault):** Oyuncu sunucudan çıksa bile cezası `AuthID` ve `IP` üzerinden hafızada tutulur. Süre dolmadan girerse cezası devam eder.
*   **🎙️ ReAPI Entegrasyonu:** Ses engellemesi için en modern ve performanslı yöntem olan ReAPI `CanPlayerHearPlayer` kancası kullanılmıştır.
*   **👥 64-Slot Desteği (High-Capacity):** Sunucudaki oyuncu limiti 32'den 64'e yükseltilmiştir. Tüm bellek yapıları ve dizi boyutları 65 olarak genişletilmiş, sınır taşmasından (Out of Bounds) kaynaklı çökmeler engellenmiştir.
*   **🎨 Estetik Tasarım:** CS 1.6 motorunun sınırları zorlanarak, tüm dillerde ve sistemlerde bozulmadan çalışan şık bir menü tasarımı yapılmıştır.
*   **🛠️ Admin Dostu İşlem Menüsü:** Gaglı bir oyuncuya tıklandığında "Gagı Kaldır", "Süreyi Uzat" veya "Süreyi Kısalt" seçenekleri sunar. Sebep seçimi ekranında **seçilen süre ve hedef oyuncu** gösterilir.
*   **🧠 UI/UX İyileştirmeleri:** Menüde sayfa hafızası (kaldığın sayfayı unutmaz), oyuncuların takım tagları (`[T]`, `[CT]`) ve adminin kendi isminin yanında `[SEN]` ibaresi yer alır.
*   **🔓 Komut İzni:** Gaglı oyuncular `/top15`, `/rank` veya `/gagmenu` gibi `/` ve `.` ile başlayan komutları kullanmaya devam edebilirler.

### 🤖 Akıllı Otomatik Gag Sistemi
*   **⚡ Trie Map Teknolojisi:** Yasaklı kelime ve Whitelist aramaları O(1) karmaşıklığında, yani şimşek hızında yapılır. Büyük kelime listelerinde bile sunucuda kesinlikle lag veya CPU darboğazı yapmaz.
*   **🧠 Akıllı Filtreleme (Anti-Bypass):**
    *   *O(N) Tek Geçişli Temizleyici:* Eski usül 12 kez `replace_all` çalıştırmak yerine, kelimeyi tek bir döngüde UTF-8 Türkçe karakterleri ve leetspeak dönüşümlerini yaparak temizler. İşlemci dostudur.
    *   *Harf Sıkıştırma:* `kuuuufuuuur` yazılsa bile otomatik olarak `kufur` haline getirilip yakalanır.
    *   *Sembol Temizleme:* `k.u_f.u_r` gibi aralara konulan semboller temizlenir.
    *   *Leet Speak Desteği:* `s4l4k` gibi sayıyla gizlenen kelimeler harfe çevrilip yakalanır.
*   **🌊 Dinamik Flood Koruması:** Kısa sürede art arda mesaj atan oyuncuları uyarır ve susturur. Eşikler CVAR ile tamamen özelleştirilebilir.
*   **📈 Dinamik Kademeli Ceza Sistemi:** Temel süre CVAR ile belirlenir (varsayılan 15 dk). Her ihlalde süre **2'ye katlanarak** artar: `15 → 30 → 60 → 120 dk`. **5. ihlalde SINIRSIZ** gag atılır.
*   **⏱️ Çift Kronometre Sistemi:** Uyarılar ve İhlaller için RAM üzerinde bağımsız iki ayrı zamanlayıcı çalışır. 15 dakikalık uyarı silinmesi, 1 saatlik ihlal silinme süresini asla bozmaz.
*   **❤️ Kademeli Sicil Temizleme:** Oyuncu temiz kaldığı her `N` saatte ihlal puanı 1 azalır. Ayrıca her 15 dakikada bir (CVAR ile ayarlanır) uslu durursa 1 uyarısı silinir.
*   **💾 Deferred Saving (Gecikmeli Kayıt):** nVault yazmaları anlık olarak yapılmaz. Sadece oyuncu çıktığında ve harita bittiğinde yazılarak disk I/O yükü minimuma indirilmiştir.
*   **🛡️ Whitelist (Beyaz Liste):** `configs/whitelist.txt` dosyasına eklenen kelimeler (Örn: "nasilsin") küfür korumasına takılmaz.

### 🔒 Güvenlik & Stabilizasyon Yamaları
*   **👥 Non-Steam Çakışma Önleme (IP-Only Fallback):** Sunucudaki Non-Steam oyuncuların kullandığı ortak/generic Steam ID'ler (`VALVE_ID_LAN`, `STEAM_ID_LAN`, `STEAM_ID_PENDING` vb.) tespit edilerek nVault veritabanı işlemlerinde es geçilir. Cezaları sadece benzersiz IP adresleri üzerinden yönetilerek masum oyuncuların zincirleme cezalandırılması engellenmiştir.
*   **💬 Chat Komut Parser Düzeltmesi:** Chat üzerinden boşluklu isimleri tırnak içinde susturmak isterken (`/gag "Mochi Foxy" 10`) parser'ın tırnakları erken silerek ismi yanlış bölmesi hatası giderilmiştir. `read_argv(1)` kullanılarak tırnak yapısı korunmuş ve başarılı parse edilmesi sağlanmıştır.
*   **🧱 Stack Corruption Önleme:** Menülerdeki `get_players` kullanımı ve yerel `players[32]` tampon dizileri tamamen kaldırılarak yerine `1`'den `get_maxplayers()`'a kadar güvenli manuel döngüler yazılmıştır. Böylece 32'den fazla oyuncu olduğunda oluşabilecek stack bozulma çökme riski sıfırlanmıştır.
*   **🛡️ Admin Dokunulmazlığı:** `ADMIN_IMMUNITY` yetkisine sahip yetkililer otomatik küfür ve flood susturmalarından muaf tutulmuştur.
*   **Zaman Makinesi Açığı Kapatıldı:** Oyuncu küfür ettiğinde af süresi dürüstçe baştan başlar.
*   **Zaman Hırsızlığı Açığı Kapatıldı:** Harita değiştiğinde veya oyuncu çıkıp girdiğinde uslu durduğu süreler nVault'a doğru kaydedilir, hakkı yenmez.
*   **Delimiter Injection Korumasi:** Adminlerin girdiği sebeplerin içine `^^` yazarak veritabanını bozması engellenmiştir.
*   **Ghost Target Koruması:** Menüden çıkıldığında veya admin oyundan düştüğünde hedeflerin karışması engellenmiştir.

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
    ├── kufurler.txt          # 700+ kelimelik yasaklı kelime listesi
    └── whitelist.txt         # Korumadan muaf tutulacak kelimeler
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
5.  `kufurler.txt` ve `whitelist.txt` dosyalarını `addons/amxmodx/configs/` klasörüne atın.
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
| `say /mgagmenu` veya `/mgm` | MochiGag menüsünü açar (Alternatif) |
| `say /mungagmenu` veya `/mugm` | MochiGag gaglılar listesini açar (Alternatif) |
| `say /mgag` veya `/mg` | MochiGag chat komutu (Alternatif) |
| `say /mungag` veya `/mug` | MochiGag chat ungag komutu (Alternatif) |
| `amx_gag` / `amx_mgag` / `amx_mg` | Konsoldan hızlı gag atar |
| `amx_ungag` / `amx_mungag` / `amx_mug` | Konsoldan hızlı gag kaldırır |
| `amx_gagmenu` / `amx_mgagmenu` | Konsoldan gag menüsünü açar |

### 🔑 Admin Komutları (RCON Yetkisi Gerekir)

| Komut | Açıklama |
|---|---|
| `amx_kufurekle <kelime>` | Çalışırken yeni yasaklı kelime ekler |
| `amx_kufursil <kelime>` | Yasaklı kelimeyi listeden kaldırır |
| `amx_ihlaltemizle <isim>` | Oyuncunun ihlal puanlarını ve zamanlayıcılarını sıfırlar |

### ⚙️ CVAR Ayarları

| CVAR | Varsayılan | Açıklama |
|---|---|---|
| `amx_autogag` | `1` | AutoGag sistemini açar/kapatır |
| `amx_autogag_default_time` | `15` | Temel gag süresi (dakika) |
| `amx_autogag_warning_limit` | `3` | Gag atılmadan önceki uyarı sayısı |
| `amx_autogag_flood_time` | `2.0` | Flood sayılacak mesaj aralığı (saniye) |
| `amx_autogag_flood_limit` | `3` | Art arda kaç hızlı mesajın flood sayılacağı |
| `amx_autogag_decay_time` | `3600` | Sicil temizleme süresi (saniye). `0` = kapalı |
| `amx_autogag_warn_decay_time` | `900` | Uyarı silinme süresi (saniye). `0` = kapalı |

---
## 📸 Görseller

### 🖥️ Menü Arayüzleri
<p align="center">
  <img src="https://github.com/user-attachments/assets/1f0bb7f6-b40d-4d79-acca-866d2a423206" alt="Gag Menüsü" width="200" />
  <img src="https://github.com/user-attachments/assets/52ac12ee-e978-4ffc-9290-0d5f22b06521" alt="Süre Menüsü" width="210" />
  <img src="https://github.com/user-attachments/assets/6d831fc4-bbd2-4bd5-8745-4f8474f6d918" alt="Sebep Menüsü" width="180" />
  <img src="https://github.com/user-attachments/assets/506d9d56-a978-4841-93ca-af79defcce7a" alt="Gaglılar Menüsü" width="260" />
</p>

### 💬 Chat Bildirimleri

* **Küfür Uyarı Mesajı:**
  <br><img src="https://github.com/user-attachments/assets/ba9542f9-4011-4ffa-be72-0401ed9e6fe0" alt="Gag Uyarı" />

* **Limit Dolunca Otomatik Gag:**
  <br><img src="https://github.com/user-attachments/assets/e7be8ca7-53f1-4eeb-b0ad-7a92e710fc07" alt="Limit Dolunca Gag" />

* **Kademeli İhlal Katlanma Bildirimi:**
  <br><img src="https://github.com/user-attachments/assets/5f07707e-8e7a-41da-b025-8d483815169b" alt="İhlal Aşaması" />

* **Menüden Atılan Gag Bilgilendirmesi:**
  <br><img src="https://github.com/user-attachments/assets/380cc45e-454b-4d78-9d9b-1adacc3cccbc" alt="Menü Mesajı" />


## 👨‍💻 Yapımcılar
*   **mochifoxy** & **FoxyBlinks**
