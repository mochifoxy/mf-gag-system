# 🔇 MF Gag & Auto Gag System

Copyright (c) 2026 [MochiFoxy && FoxyBlinks]. All rights reserved  
CS 1.6 (GoldSrc) motoru için geliştirilmiş; yüksek performanslı, bellek güvenli, estetik ve gelişmiş heuristic anti-bypass filtreleme mimarisine sahip modüler bir Gag (Susturma) ve Otomatik Ceza sistemidir. AMX Mod X ve ReAPI altyapısını kullanır.

> [!NOTE]
> **Güncel Sürüm:** v1.5 (Dinamik Glob Eşleşme, 64-Slot Desteği, Non-Steam İzolasyonu, Gelişmiş Anti-Bypass ve Kalıcı Ceza Koruması).

[![Game](https://img.shields.io/badge/Game-CS%201.6-orange.svg)](https://store.steampowered.com/app/10/CounterStrike/)
[![Platform](https://img.shields.io/badge/Platform-AMX%20Mod%20X%201.10%2B-blue.svg)](https://www.amxmodx.org/)
[![Requirements](https://img.shields.io/badge/Gereksinim-ReAPI-red.svg)]()
[![Version](https://img.shields.io/badge/Versiyon-1.5-green.svg)]()

---

## 📋 Gereksinimler

Eklentinin sorunsuz derlenebilmesi ve çalışabilmesi için aşağıdaki altyapıların sunucuda bulunması gerekir:
1.  **AMX Mod X 1.10.0 veya üzeri:** Gelişmiş Trie veri yapıları, modern string işleme ve `client_print_color` gibi native fonksiyonlar için.
2.  **ReGameDLL & ReAPI Modülü:** Ses engellemesinin (Voice Gag) en performanslı ve kararlı biçimde sunucu seviyesinde kancalanması (`CanPlayerHearPlayer`) için zorunludur.

---

## 🚀 v1.2 Sürümünden v1.5'e Geçişte Yapılan Düzeltmeler & Eklemeler

*   **🌐 Tam Kapsamlı Glob / Wildcard Desteği:** v1.2'de yalnızca kelime sonuna yıldız konulabiliyorken (`kelime*`), v1.5 ile birlikte çift taraflı içerme kuralı (`*kelime*` ve `*kelime`) eklendi. Artık `*skm*` veya `*amk*` yazarak kelimenin önüne/arkasına eklenen tüm türevler tek kuralda yakalanır.
*   **🛡️ Subsequence (Araya Harf Sıkıştırma) Motoru:** v1.2'deki harf dönüştürmeyi aşmak için araya yabancı harfler sokularak yapılan (`s a i k`, `siokerler`, `s x k`) akıllı bypass girişimleri yeni alt-dizi algoritmasıyla engellendi.
*   **📈 Kalıcı (Süresiz) Gag Sistemi:** v1.2'de süre yalnızca katlanıyordu; v1.5'te 5. ihlale ulaşan iflah olmaz oyunculara doğrudan **KALICI (Süresiz)** gag atılması sağlandı.
*   **👥 64-Slot ReHLDS Altyapısı:** v1.2'deki 32 kişilik bellek sınırları 64-slot sunuculara uyumlu hale getirilerek bellek taşması (stack corruption) çökmeleri önlendi.
*   **🔒 Non-Steam Oyuncu İzolasyonu:** Non-Steam oyuncuların paylaştığı `VALVE_ID_LAN` gibi ortak ID'lerin çakışması engellendi; cezalar IP üzerinden tutularak masum oyuncuların etkilenmesi önlendi.
*   **💬 Tırnaklı İsim Parser Düzeltmesi:** Chat üzerinden tırnaklı ve boşluklu isimlere gag atarken (`/gag "Deneme Queen" 15` veya `/gag 'Deneme Queen' 15`) oluşan isim bölünme hatası `read_args` ve otomatik tırnak normalizasyonu ile tamamen giderildi.
*   **👑 Yetkili Dokunulmazlık CVAR'ı:** `amx_autogag_immunity` ayarı eklenerek yetkililerin filtreden muaf tutulabilmesi seçeneğe bağlandı.

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
*   **🔓 Komut İzni (Configurable):** Gaglı oyuncular `/top15`, `/rank` veya `/me` gibi sunucu komutlarını kullanmaya devam edebilirler (Dinamik olarak `gag_whitelist.ini` üzerinden yönetilir).

### ⚡ Gelişmiş Otomatik Gag & Anti-Bypass Filtresi
*   **🌐 %100 Dinamik Glob / Wildcard Sistemi (Zero Hardcoded):** Eklenti kaynak kodunda (`.sma`) tek bir küfür kelimesi dahi gömülü değildir. Sistem, [kufurler.txt](file:///addons/amxmodx/configs/kufurler.txt) üzerinden okunan kurallarla çalışır. 4 farklı eşleşme tipini destekler:
    *   `*kelime*` **(İçerme / Substring):** Kelimenin neresinde geçerse geçsin yakalar. Oyuncuların küfürlerin önüne ek getirerek türettiği yüzlerce varyasyonu (`anskm`, `anaskm`, `ananskm`, `hasiktir`, `yohamk`, `anamk` vb.) tek bir kural ile (`*skm*`, `*siktir*`, `*amk*`) kökten çözer. Yüzlerce kelimeyi tek tek ekleme zorunluluğunu bitirir.
    *   `kelime*` **(Ön-Ek / Prefix):** Bu kökle başlayan kelimeleri ve araya harf sokarak yapılan bypass'ları (`ContainsSubsequence`) yakalar (örn: `sik*` -> `sikerim`, `siokerler`, `saikerler`, `sxixk`, `s1kerler`). Masum kelimelerin (`eksik`, `klasik`, `fizik`, `muzik`) yanlışlıkla filtrelenmesini engeller.
    *   `kelime` **(Tam Eşleşme / Exact - O(1) Trie):** Yalnızca kelime birebir yazıldığında yakalar (örn: `oc`, `aq`). `çocuk`, `doktor` gibi masum kelimeleri korur.
    *   `*kelime` **(Son-Ek / Suffix):** Bu ekle biten kelimeleri yakalar.
*   **🛡️ Gelişmiş Anti-Bypass Koruması:**
    *   *O(N) Tek Geçişli Heuristic Temizleyici:* Tek bir döngüde UTF-8 çok baytlı Türkçe karakterler (ç, ö, ü, ı, ğ, ş), ANSI kodları ve leetspeak sayısal harf dönüşümleri (4->a, 3->e, 1->i, 0->o, 5->s, 7->t, 8->b) normalize edilir.
    *   *Harf Tekrarı Sıkıştırma (Deduplication):* Arka arkaya uzatılan harfler (`kuuuufuuuur` -> `kufur`, `siiikeeeer` -> `siker`) tek harfe indirgenerek tespit edilir.
    *   *Bileşik / Açılım Küfür Taraması (Bigram & Spaceless):* `o çocuğu`, `orospu çocuğu`, `o evladı` gibi iki kelimelik veya araya nokta/boşluk konularak yazılan açılımlar; çift token birleştirmesi (`o` + `cocugu` = `ococugu`) ve cümlenin boşluksuz analizi ile otomatik tespit edilir.
    *   *Cümle İçi Sembol & Boşluklu Harf Tespiti:* Cümle içinde sembollerle gizlenen (`sen k.u_f.u_r sundun`) veya boşluklarla harf harf yazılan (`k u f u r`, `s . i . k`) küfürler harf akümülatörü ile birleştirilerek yakalanır.
*   **🔄 Çalışma Zamanında Anlık Güncelleme (Runtime Reload):** Konsoldan `amx_kufurekle` veya `amx_kufursil` kullanıldığında harita değişimi veya sunucu restartı gerekmeksizin bellekteki tüm veri yapıları (Trie ve Dinamik Diziler) anında güncellenir.
*   **🌊 Dinamik Flood Koruması:** Kısa sürede art arda mesaj atan oyuncuları uyarır ve susturur. Eşikler CVAR ile tamamen özelleştirilebilir.
*   **📈 Kademeli Ceza Sistemi & Kalıcı Gag:** Temel süre CVAR ile belirlenir (varsayılan 15 dk). Her ihlalde süre **2'ye katlanarak** artar: `15 → 30 → 60 → 120 dk`. **5. ihlal ve sonrasında KALICI (Süresiz, iGagTime = 0)** gag uygulanır.
*   **⏱️ Çift Kronometre Sistemi:** Uyarılar ve İhlaller için RAM üzerinde bağımsız iki ayrı zamanlayıcı çalışır. 15 dakikalık uyarı silinmesi, 1 saatlik ihlal silinme süresini asla bozmaz.
*   **❤️ Kademeli Sicil Temizleme:** Oyuncu temiz kaldığı her `N` saatte ihlal puanı 1 azalır. Ayrıca her 15 dakikada bir (CVAR ile ayarlanır) uslu durursa 1 uyarısı silinir.
*   **💾 Deferred Saving (Gecikmeli Kayıt):** nVault yazmaları anlık olarak yapılmaz. Sadece oyuncu çıktığında ve harita bittiğinde yazılarak disk I/O yükü minimuma indirilmiştir.

### 🔒 Güvenlik & Stabilizasyon Yamaları
*   **👥 Non-Steam Çakışma Önleme (IP-Only Fallback):** Sunucudaki Non-Steam oyuncuların kullandığı ortak/generic Steam ID'ler (`VALVE_ID_LAN`, `STEAM_ID_LAN`, `STEAM_ID_PENDING` vb.) tespit edilerek nVault veritabanı işlemlerinde es geçilir. Cezaları sadece benzersiz IP adresleri üzerinden yönetilerek masum oyuncuların zincirleme cezalandırılması engellenmiştir.
*   **💬 Chat Komut Parser Düzeltmesi:** Chat üzerinden boşluklu ve tırnaklı isimlere gag atarken (`/gag "Deneme Queen" 15` veya `/gag 'Deneme Queen' 15`) parser'ın ismi yanlış bölmesi hatası giderilmiştir. Hem tek tırnak (`'`) hem de çift tırnak (`"`) tam desteklenir.
*   **🧱 Stack Corruption Önleme:** Menülerdeki `get_players` kullanımı ve yerel `players[32]` tampon dizileri tamamen kaldırılarak yerine `1`'den `get_maxplayers()`'a kadar güvenli manuel döngüler yazılmıştır. Böylece 32'den fazla oyuncu olduğunda oluşabilecek stack bozulma çökme riski sıfırlanmıştır.
*   **🛡️ Admin Dokunulmazlığı:** `amx_autogag_immunity` CVAR'ı ile yetkililerin otomatik filtreye takılıp takılmayacağı belirlenir (Varsayılan `0` yapılarak yetkililerin de sistemi test edebilmesi sağlanmıştır).
*   **Zaman Makinesi Açığı Kapatıldı:** Oyuncu küfür ettiğinde af süresi dürüstçe baştan başlar.
*   **Zaman Hırsızlığı Açığı Kapatıldı:** Harita değiştiğinde veya oyuncu çıkıp girdiğinde uslu durduğu süreler nVault'a doğru kaydedilir, hakkı yenmez.
*   **Delimiter Injection Koruması:** Adminlerin girdiği sebeplerin içine `^^` yazarak veritabanını bozması engellenmiştir.
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
    ├── kufurler.txt          # Yasaklı kelime listesi (Standart Glob / Wildcard desteği)
    ├── whitelist.txt         # Korumadan muaf kelimeler
    └── gag_whitelist.ini     # Gaglıların yazabileceği chat komutları
```

---

## ⚙️ Yapılandırma Dosyaları (Configs)

### 1. `configs/kufurler.txt`
Yasaklı kelime ve anti-bypass kural veritabanıdır. Her satıra bir kural yazılır:

| Kural Formatı | Açıklama | Örnek Girdi | Yakaladığı Varyasyonlar | Masum Kelime Durumu |
|---|---|---|---|---|
| `*kelime*` | **İçerme (Substring):** Kelimenin neresinde geçerse geçsin engeller. | `*skm*` | `anskm`, `anaskm`, `ananskm`, `skm323`, `yaskm` | Ön-ek bypass'larını tek satırda yok eder. |
| `*kelime*` | İçerme kuralı | `*siktir*` | `hasiktir`, `hassiktir`, `siktirgit` | Yüzlerce kombinasyon eklemeyi engeller. |
| `*kelime*` | İçerme kuralı | `*amk*` | `yohamk`, `anamk`, `amkk` | `amk` içeren tüm ön-ekleri yakalar. |
| `kelime*` | **Ön-Ek (Prefix):** Sadece bu kökle başlayanları ve araya harf sokma bypass'larını yakalar. | `sik*` | `sikerim`, `siokerler`, `saikerler`, `sxixk`, `s1kerler` | `eksik`, `klasik`, `fizik` gibi masum kelimeleri **KORUR**. |
| `kelime` | **Tam Eşleşme (Exact):** Sadece tek başına tam yazıldığında engeller. | `oc` / `oç` | `oc`, `oxc`, `o.c` | `çocuk`, `doktor`, `bocce` gibi kelimeleri **KORUR**. |
| `*kelime` | **Son-Ek (Suffix):** Bu ekle biten kelimeleri engeller. | `*kufur` | `birkufur`, `baskufur` | Yalnızca son-ek eşleşir. |

### 2. `configs/whitelist.txt`
Küfür filtresinin taramasını **öncelikli olarak** atlamasını istediğiniz güvenli kelimelerdir. Örneğin yasaklılar listenizde `sal` varsa veya kök filtrelerinin benzeyebileceği kelimeleri korumak için (`eksik`, `klasik`, `fizik`, `muzik`, `tebrik`, `nasilsin`, `acmak`, `ekmek` vb.) buraya eklenir.

### 3. `configs/gag_whitelist.ini`
Susturulan oyuncuların chatte engellenmeden kullanabilmesini istediğiniz chat komutlarıdır (Örn: `/rank`, `/top15`). Argüman alan bir komutun sonuna yıldız koyabilirsiniz (örn: `/ungag *`).

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
5.  `kufurler.txt`, `whitelist.txt` ve `gag_whitelist.ini` dosyalarını `addons/amxmodx/configs/` klasörüne atın.
6.  Sunucuyu yeniden başlatın veya harita değiştirin.

> [!IMPORTANT]
> 1. `mf_gag_core.amxx` diğer tüm eklentilerden **önce** yüklenmelidir. `plugins.ini` sıralaması bu açıdan kritiktir.
> 2. `mf_auto_gag.amxx` kendi gelişmiş kademeli flood ve ceza sistemine sahip olduğu için, `plugins.ini` içindeki varsayılan `antiflood.amxx` eklentisi devre dışı bırakılmalıdır (başına `;` koyarak `;antiflood.amxx`).

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
| `amx_kufurekle <kural>` | Çalışma zamanında yeni kural ekler (Örn: `*skm*`, `sik*`, `oc`) ve anında aktifleştirir |
| `amx_kufursil <kural>` | Yasaklı kuralı listeden kaldırır ve anında aktifleştirir |
| `amx_ihlaltemizle <isim>` | Oyuncunun ihlal puanlarını ve zamanlayıcılarını sıfırlar |

### ⚙️ CVAR Ayarları

| CVAR | Varsayılan | Açıklama |
|---|---|---|
| `amx_gag_admin_bypass` | `0` | Gaglı yetkili komut muafiyeti (`0`: Yetkililer de `gag_whitelist.ini` listesine tabidir, `1`: Yetkililer tüm `/` ve `.` komutlarını serbestçe çalıştırabilir) |
| `amx_autogag` | `1` | AutoGag sistemini açar/kapatır |
| `amx_autogag_default_time` | `15` | Temel gag süresi (dakika) |
| `amx_autogag_warning_limit` | `3` | Gag atılmadan önceki uyarı sayısı |
| `amx_autogag_flood_time` | `0.75` | Flood eşik süresi (saniye). 0.75 saniyeden hızlı mesajlar engellenir |
| `amx_autogag_flood_limit` | `3` | Art arda kaç hızlı mesaj girişiminde uyarı verileceği |
| `amx_autogag_immunity` | `0` | Yetkili muafiyeti (`0`: Yetkililer de denetlenir, `1`: Yetkililer muaf) |
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
