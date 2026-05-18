#include <amxmodx>
#include <amxmisc>
#include <mf_gag>
#include <nvault>

#pragma semicolon 1

#define PLUGIN "MF Auto Gag"
#define VERSION "1.3"
#define AUTHOR "mochifoxy && FoxyBlinks"

new Trie:g_tBadWords;
new Array:g_aBadWords;
new Array:g_aWhitelist;
new g_iWarnings[33];
new g_iOffenses[33];
new g_iWarnDecayTimer[33]; // YENI: Uyari icin ozel kronometre
new g_iOffenseDecayTimer[33]; // YENI: Ihlal icin ozel kronometre

// Flood Korumasi icin degiskenler
new Float:g_flLastTalkTime[33];
new g_iMessageCount[33];

// CVAR Pointers
new g_pCvarEnabled;
new g_pCvarFloodTime;
new g_pCvarFloodLimit;
new g_pCvarDecayTime;
new g_pCvarWarnDecayTime;
new g_pCvarWarnLimit;
new g_pCvarDefaultTime;

// Vault Handle
new g_Vault;

bool:CleanWord(szWord[]);

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    register_clcmd("say", "cmd_Say");
    register_clcmd("say_team", "cmd_Say");
    
    register_concmd("amx_kufurekle", "cmd_AddWord", ADMIN_RCON, "<kelime> - Kufur listesine kelime ekler");
    register_concmd("amx_kufursil", "cmd_DelWord", ADMIN_RCON, "<kelime> - Kufur listesinden kelime siler");
    register_concmd("amx_ihlaltemizle", "cmd_ClearOffenses", ADMIN_RCON, "<isim> - Oyuncunun ihlallerini sifirlar");
    
    g_pCvarEnabled = create_cvar("amx_autogag", "1");
    g_pCvarFloodTime = create_cvar("amx_autogag_flood_time", "2.0");
    g_pCvarFloodLimit = create_cvar("amx_autogag_flood_limit", "3");
    g_pCvarDecayTime = create_cvar("amx_autogag_decay_time", "3600"); // 3600 saniye = 1 saat
    g_pCvarWarnDecayTime = create_cvar("amx_autogag_warn_decay_time", "900"); // 15 Dakika
    g_pCvarWarnLimit = create_cvar("amx_autogag_warning_limit", "3");
    g_pCvarDefaultTime = create_cvar("amx_autogag_default_time", "15");
    
    g_tBadWords = TrieCreate();
    g_aBadWords = ArrayCreate(32);
    LoadWords();
    
    g_aWhitelist = ArrayCreate(32);
    LoadWhitelist();
    
    g_Vault = nvault_open("autogag_offenses");
    if (g_Vault == INVALID_HANDLE) {
        set_fail_state("nVault (autogag_offenses) acilamadi! AutoGag durduruldu.");
    }
    
    // 24 saatten eski kayitlari sil (Dosya sismesini onlemek icin)
    nvault_prune(g_Vault, 0, get_systime() - 86400);
}

public plugin_end() {
    TrieDestroy(g_tBadWords);
    ArrayDestroy(g_aBadWords);
    ArrayDestroy(g_aWhitelist);
    
    // Map kapanmadan once iceride kalan herkesin kaydini diske yaz
    new szAuthID[35], szIP[32], szData[48];
    for (new id = 1; id <= 32; id++) {
        if (is_user_connected(id) && !is_user_bot(id) && !is_user_hltv(id)) {
            if (g_iOffenses[id] > 0 || g_iWarnings[id] > 0) {
                get_user_authid(id, szAuthID, charsmax(szAuthID));
                get_user_ip(id, szIP, charsmax(szIP), 1);
                
                if (szAuthID[0] != '^0' && !equal(szAuthID, "STEAM_ID_PENDING") && szIP[0] != '^0') {
                    formatex(szData, charsmax(szData), "%d %d %d %d", g_iOffenses[id], g_iWarnings[id], g_iWarnDecayTimer[id], g_iOffenseDecayTimer[id]);
                    if (g_Vault) {
                        nvault_set(g_Vault, szAuthID, szData);
                        nvault_set(g_Vault, szIP, szData);
                    }
                }
            }
        }
    }
    
    if (g_Vault != INVALID_HANDLE) {
        nvault_close(g_Vault);
    }
}

public client_disconnected(id) {
    if (is_user_bot(id) || is_user_hltv(id)) return;
    
    // Sadece uyarisi veya ihlali olanlari kaydet (Diski bosuna yormamak icin)
    if (g_iOffenses[id] > 0 || g_iWarnings[id] > 0) {
        new szAuthID[35], szIP[32], szData[48];
        get_user_authid(id, szAuthID, charsmax(szAuthID));
        get_user_ip(id, szIP, charsmax(szIP), 1);
        
        if (szAuthID[0] != '^0' && !equal(szAuthID, "STEAM_ID_PENDING") && szIP[0] != '^0') {
            formatex(szData, charsmax(szData), "%d %d %d %d", g_iOffenses[id], g_iWarnings[id], g_iWarnDecayTimer[id], g_iOffenseDecayTimer[id]);
            nvault_set(g_Vault, szAuthID, szData);
            nvault_set(g_Vault, szIP, szData);
        }
    }
    
    // Hafizayi temizle
    g_iOffenses[id] = 0;
    g_iWarnings[id] = 0;
    g_iMessageCount[id] = 0;
    g_flLastTalkTime[id] = 0.0;
    remove_task(id + 5000);
}

public client_putinserver(id) {
    g_iWarnings[id] = 0;
    g_flLastTalkTime[id] = 0.0;
    g_iMessageCount[id] = 0;
    g_iOffenses[id] = 0;
    
    if (is_user_bot(id) || is_user_hltv(id)) return;
    
    set_task(1.0, "load_offenses", id + 5000);
}

public load_offenses(taskid) {
    new id = taskid - 5000; // Offseti geri al
    if (!is_user_connected(id)) return;
    
    new szAuthID[35], szIP[32];
    get_user_authid(id, szAuthID, charsmax(szAuthID));
    
    if (equal(szAuthID, "STEAM_ID_PENDING") || szAuthID[0] == '^0') {
        remove_task(taskid);
        set_task(0.5, "load_offenses", taskid);
        return;
    }
    
    get_user_ip(id, szIP, charsmax(szIP), 1);
    
    new iCountID = 0, iWarningsID = 0, iWarnTimeID = 0, iOffTimeID = 0;
    new iCountIP = 0, iWarningsIP = 0, iWarnTimeIP = 0, iOffTimeIP = 0;
    new szData[64], szCount[10], szWarnings[10], szWarnTime[20], szOffTime[20];
    
    // SteamID Kontrolu
    if (nvault_get(g_Vault, szAuthID, szData, charsmax(szData))) {
        parse(szData, szCount, charsmax(szCount), szWarnings, charsmax(szWarnings), szWarnTime, charsmax(szWarnTime), szOffTime, charsmax(szOffTime));
        iCountID = str_to_num(szCount);
        iWarningsID = str_to_num(szWarnings);
        iWarnTimeID = str_to_num(szWarnTime);
        iOffTimeID = szOffTime[0] ? str_to_num(szOffTime) : iWarnTimeID; // Eski kayitlarla uyumlu (Fallback)
    }
    
    // IP Kontrolu
    if (nvault_get(g_Vault, szIP, szData, charsmax(szData))) {
        parse(szData, szCount, charsmax(szCount), szWarnings, charsmax(szWarnings), szWarnTime, charsmax(szWarnTime), szOffTime, charsmax(szOffTime));
        iCountIP = str_to_num(szCount);
        iWarningsIP = str_to_num(szWarnings);
        iWarnTimeIP = str_to_num(szWarnTime);
        iOffTimeIP = szOffTime[0] ? str_to_num(szOffTime) : iWarnTimeIP;
    }
    
    new iCurrentTime = get_systime();
    new iDecayTime = get_pcvar_num(g_pCvarDecayTime);
    new iWarnDecay = get_pcvar_num(g_pCvarWarnDecayTime);
    
    // ID Icin Offline Decay (KADEMELI)
    if (iWarnTimeID > 0 && iWarnDecay > 0) {
        new iPassed = (iCurrentTime - iWarnTimeID) / iWarnDecay;
        if (iPassed > 0) {
            iWarningsID = max(0, iWarningsID - iPassed);
            iWarnTimeID += (iPassed * iWarnDecay); // Kronometreyi sadece kullanilan sure kadar ileri sar
        }
    }
    if (iOffTimeID > 0 && iDecayTime > 0) {
        new iPassed = (iCurrentTime - iOffTimeID) / iDecayTime;
        if (iPassed > 0) {
            iCountID = max(0, iCountID - iPassed);
            iOffTimeID += (iPassed * iDecayTime);
        }
    }
    
    // IP Icin Offline Decay (KADEMELI)
    if (iWarnTimeIP > 0 && iWarnDecay > 0) {
        new iPassed = (iCurrentTime - iWarnTimeIP) / iWarnDecay;
        if (iPassed > 0) {
            iWarningsIP = max(0, iWarningsIP - iPassed);
            iWarnTimeIP += (iPassed * iWarnDecay);
        }
    }
    if (iOffTimeIP > 0 && iDecayTime > 0) {
        new iPassed = (iCurrentTime - iOffTimeIP) / iDecayTime;
        if (iPassed > 0) {
            iCountIP = max(0, iCountIP - iPassed);
            iOffTimeIP += (iPassed * iDecayTime);
        }
    }
    
    g_iOffenses[id] = max(iCountID, iCountIP);
    g_iWarnings[id] = max(iWarningsID, iWarningsIP);
    g_iWarnDecayTimer[id] = max(iWarnTimeID, iWarnTimeIP);
    g_iOffenseDecayTimer[id] = max(iOffTimeID, iOffTimeIP);
}

LoadWhitelist() {
    new szFilePath[128];
    get_configsdir(szFilePath, charsmax(szFilePath));
    add(szFilePath, charsmax(szFilePath), "/whitelist.txt");
    
    if (!file_exists(szFilePath)) {
        new f = fopen(szFilePath, "wt");
        if (f) {
            fprintf(f, "// Buraya kufur filtresine takilmasini istemediginiz kelimeleri yazabilirsiniz^n");
            fprintf(f, "// Her satira bir kelime^n");
            fprintf(f, "nasilsin^n");
            fclose(f);
        }
    }
    
    new f = fopen(szFilePath, "rt");
    if (!f) return;
    
    new szLine[64], szClean[64];
    while (!feof(f)) {
        fgets(f, szLine, charsmax(szLine));
        trim(szLine);
        
        if (szLine[0] == '^0' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/')) {
            continue;
        }
        
        strtolower(szLine);
        copy(szClean, charsmax(szClean), szLine);
        CleanWord(szClean);
        
        if (szClean[0] != '^0') {
            ArrayPushString(g_aWhitelist, szClean);
        }
    }
    fclose(f);
}

LoadWords() {
    new szFilePath[128];
    get_configsdir(szFilePath, charsmax(szFilePath));
    add(szFilePath, charsmax(szFilePath), "/kufurler.txt");
    
    if (!file_exists(szFilePath)) {
        formatex(szFilePath, charsmax(szFilePath), "kufurler.txt");
    }
    
    if (!file_exists(szFilePath)) {
        log_amx("[AutoGag] Dosya bulunamadi: %s", szFilePath);
        return;
    }
    
    new f = fopen(szFilePath, "rt");
    if (!f) return;
    
    new szLine[64];
    while (!feof(f)) {
        fgets(f, szLine, charsmax(szLine));
        trim(szLine);
        
        if (szLine[0] == '^0' || szLine[0] == ';' || (szLine[0] == '/' && szLine[1] == '/')) {
            continue;
        }
        
        new bool:bIsWildcard = false;
        new iLen = strlen(szLine);
        if (iLen > 1 && szLine[iLen - 1] == '*') {
            bIsWildcard = true;
            szLine[iLen - 1] = '^0';
            trim(szLine); 
        }
        
        CleanWord(szLine);
        if (szLine[0] != '^0') {
            if (bIsWildcard) {
                add(szLine, charsmax(szLine), "*");
                ArrayPushString(g_aBadWords, szLine); // Wildcard kelimeler doğrusal diziye
            } else {
                TrieSetCell(g_tBadWords, szLine, 1); // Tam eşleşmeler doğrudan O(1) Trie'ye
            }
        }
    }
    
    fclose(f);
    log_amx("[AutoGag] Kelime listesi yuklendi.");
}

public cmd_Say(id) {
    if (!is_user_connected(id)) return PLUGIN_CONTINUE;
    
    if (!get_pcvar_num(g_pCvarEnabled)) return PLUGIN_CONTINUE;
    
    // Eger oyuncu zaten gagliysa bosuna islemciyi yorma
    if (mfgag_is_gagged(id)) return PLUGIN_CONTINUE;
    
    new szMessage[192];
    read_args(szMessage, charsmax(szMessage));
    remove_quotes(szMessage);
    trim(szMessage);
    
    if (szMessage[0] == '^0') return PLUGIN_CONTINUE;
    
    // if (szMessage[0] == '/' || szMessage[0] == '.') return PLUGIN_CONTINUE; // bug fix
    
    new szName[32];
    get_user_name(id, szName, charsmax(szName));
    
    // --- KADEMELI SICIL TEMIZLEME ---
    new iCurrentTime = get_systime();
    new iDecayTime = get_pcvar_num(g_pCvarDecayTime);
    new iWarnDecay = get_pcvar_num(g_pCvarWarnDecayTime);
    
    // Ihlal Azalmasi (1 Saatlik Kronometre)
    if (g_iOffenseDecayTimer[id] > 0 && iDecayTime > 0) {
        new iDiff = iCurrentTime - g_iOffenseDecayTimer[id];
        if (iDiff >= iDecayTime) {
            new iPassed = iDiff / iDecayTime;
            g_iOffenses[id] = max(0, g_iOffenses[id] - iPassed);
            g_iOffenseDecayTimer[id] += (iPassed * iDecayTime); // Sadece o kadar ileri sar!
        }
    }

    // Uyari Azalmasi (15 Dakikalik Kronometre)
    if (g_iWarnDecayTimer[id] > 0 && iWarnDecay > 0) {
        new iDiff = iCurrentTime - g_iWarnDecayTimer[id];
        if (iDiff >= iWarnDecay) {
            new iPassed = iDiff / iWarnDecay;
            g_iWarnings[id] = max(0, g_iWarnings[id] - iPassed);
            g_iWarnDecayTimer[id] += (iPassed * iWarnDecay); // Sadece o kadar ileri sar!
        }
    }
    
    // --- Flood Korumasi ---
    new Float:flCurrentTime = get_gametime();
    new Float:flDiff = flCurrentTime - g_flLastTalkTime[id];
    g_flLastTalkTime[id] = flCurrentTime;
    
    if (flDiff < get_pcvar_float(g_pCvarFloodTime)) {
        g_iMessageCount[id]++;
        if (g_iMessageCount[id] >= get_pcvar_num(g_pCvarFloodLimit)) {
            g_iWarnings[id]++;
            g_iWarnDecayTimer[id] = get_systime();
            
            client_print_color(id, print_team_default, "%sFlood yaptiginiz icin uyari aldiniz! (%d/%d)", AUTOGAG_TAG, g_iWarnings[id], get_pcvar_num(g_pCvarWarnLimit));
            
            // Tek bir bind basımında (aynı anda gelen paketlerde) arka arkaya uyarı alıp anında ceza yememesi için sayaç sıfırlanıyor
            g_iMessageCount[id] = 0;
            
            if (g_iWarnings[id] >= get_pcvar_num(g_pCvarWarnLimit)) {
                g_iOffenses[id]++;
                g_iOffenseDecayTimer[id] = get_systime();
                
                new iDefaultTime = get_pcvar_num(g_pCvarDefaultTime);
                new iGagTime = iDefaultTime;
                
                new iShift = min(g_iOffenses[id] - 1, 14);
                iGagTime = iDefaultTime * (1 << iShift);
                if (iGagTime > 43200) iGagTime = 43200; // Max 30 days
                client_print_color(id, print_team_default, "%sFlood yaptiginiz icin ^3%d dakika ^1gaglandiniz.", AUTOGAG_TAG, iGagTime);
                
                new szReason[64];
                formatex(szReason, charsmax(szReason), "Otomatik Gag (Flood %d. Ihlal)", g_iOffenses[id]);
                
                mfgag_set_gag(0, id, iGagTime, szReason);
                g_iWarnings[id] = 0;
                
                log_amx("[AutoGag] %s flood nedeniyle otomatik gaglandi. Sure: %d Dk, Ihlal: %d", szName, iGagTime, g_iOffenses[id]);
            }
            
            return PLUGIN_HANDLED;
        }
    } else {
        g_iMessageCount[id] = 1;
    }
    // ----------------------
    
    new bool:bFound = false;
    new szWord[192], szClean[192];
    new iPos = 0;
    
    new szGlobalSpaceless[192];
    copy(szGlobalSpaceless, charsmax(szGlobalSpaceless), szMessage);
    CleanWord(szGlobalSpaceless);
    
    if (szGlobalSpaceless[0] != '^0') {
        if (TrieKeyExists(g_tBadWords, szGlobalSpaceless)) {
            bFound = true;
        } else {
            new szCurrentBadWord[32];
            for (new i = 0; i < ArraySize(g_aBadWords); i++) {
                ArrayGetString(g_aBadWords, i, szCurrentBadWord, charsmax(szCurrentBadWord));
                new iLen = strlen(szCurrentBadWord);
                if (iLen > 1 && szCurrentBadWord[iLen - 1] == '*') {
                    szCurrentBadWord[iLen - 1] = '^0';
                    if (iLen - 1 >= 3 && containi(szGlobalSpaceless, szCurrentBadWord) != -1) {
                        bFound = true;
                        break;
                    }
                } else {
                    if (iLen >= 4 && containi(szGlobalSpaceless, szCurrentBadWord) != -1) {
                        bFound = true;
                        break;
                    }
                }
            }
        }
    }
    
    new szPunctspacedMessage[192];
    copy(szPunctspacedMessage, charsmax(szPunctspacedMessage), szMessage);
    for (new i = 0; szPunctspacedMessage[i] != '^0'; i++) {
        new c = szPunctspacedMessage[i];
        if (c > 32 && c < 128) {
            if (!(('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || ('0' <= c && c <= '9'))) {
                szPunctspacedMessage[i] = ' ';
            }
        }
    }
    
    while ((iPos = argparse(szPunctspacedMessage, iPos, szWord, charsmax(szWord))) != -1) {
        copy(szClean, charsmax(szClean), szWord);
        CleanWord(szClean);
        if (szClean[0] == '^0') continue;
        
        // --- Exact Whitelist (Beyaz Liste) ---
        new bool:bIsWhitelisted = false;
        for (new i = 0; i < ArraySize(g_aWhitelist); i++) {
            new szWhite[32];
            ArrayGetString(g_aWhitelist, i, szWhite, charsmax(szWhite));
            if (equal(szClean, szWhite)) {
                bIsWhitelisted = true;
                break;
            }
        }
        
        if (bIsWhitelisted) {
            continue; // Beyaz listedeki kelime
        }
        
        if (TrieKeyExists(g_tBadWords, szClean)) {
            bFound = true;
            break;
        } else {
            for (new i = 0; i < ArraySize(g_aBadWords); i++) {
                new szCurrentBadWord[32];
                ArrayGetString(g_aBadWords, i, szCurrentBadWord, charsmax(szCurrentBadWord));
                new badLen = strlen(szCurrentBadWord);
                if (badLen > 1 && szCurrentBadWord[badLen - 1] == '*') {
                    szCurrentBadWord[badLen - 1] = '^0';
                    if (equal(szClean, szCurrentBadWord, badLen - 1)) {
                        bFound = true;
                        break;
                    }
                }
            }
            if (bFound) break;
        }
    }
    
    if (bFound) {
        g_iWarnings[id]++;
        g_iWarnDecayTimer[id] = get_systime();
        
        if (g_iWarnings[id] >= get_pcvar_num(g_pCvarWarnLimit)) {
            g_iOffenses[id]++;
            g_iOffenseDecayTimer[id] = get_systime();
            
            new iDefaultTime = get_pcvar_num(g_pCvarDefaultTime);
            new iGagTime = iDefaultTime;
            
            new iShift = min(g_iOffenses[id] - 1, 14);
            iGagTime = iDefaultTime * (1 << iShift);
            if (iGagTime > 43200) iGagTime = 43200; // Max 30 days
            client_print_color(id, print_team_default, "%sYasakli kelime sinirini astiginiz icin ^3%d dakika ^1gaglandiniz.", AUTOGAG_TAG, iGagTime);
            
            new szReason[64];
            formatex(szReason, charsmax(szReason), "Otomatik Gag (Yasakli Kelime %d. Ihlal)", g_iOffenses[id]);
            
            mfgag_set_gag(0, id, iGagTime, szReason);
            g_iWarnings[id] = 0;
            
            log_amx("[AutoGag] %s otomatik gaglandi. Sure: %d Dk, Ihlal: %d, Neden: Yasakli Kelime", szName, iGagTime, g_iOffenses[id]);
            
            return PLUGIN_HANDLED; // Gaglandigi icin mesaji engelle
        } else {
            client_print_color(id, print_team_default, "%sLutfen yasakli kelime kullanmayiniz! Mesajiniz engellendi. Uyari: ^3%d/%d", AUTOGAG_TAG, g_iWarnings[id], get_pcvar_num(g_pCvarWarnLimit));
            
            return PLUGIN_HANDLED; // Mesajin gorunmesini engelle
        }
    }
    
    return PLUGIN_CONTINUE;
}

public cmd_AddWord(id, level, cid) {
    if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;
    
    new szWord[32];
    read_argv(1, szWord, charsmax(szWord));
    trim(szWord);
    
    if (szWord[0] == '^0') return PLUGIN_HANDLED;
    
    strtolower(szWord);
    new szClean[32];
    copy(szClean, charsmax(szClean), szWord);
    
    new bool:bHasWildcard = false;
    new iLen = strlen(szClean);
    if (iLen > 1 && szClean[iLen - 1] == '*') {
        bHasWildcard = true;
        szClean[iLen - 1] = '^0';
    }
    
    CleanWord(szClean);
    
    if (szClean[0] == '^0') {
        console_print(id, "[AutoGag] Gecersiz kelime!");
        return PLUGIN_HANDLED;
    }
    
    if (bHasWildcard) {
        add(szClean, charsmax(szClean), "*");
        
        // Array'de zaten var mı kontrolü
        new szTemp[32], bool:bExists = false;
        for(new i = 0; i < ArraySize(g_aBadWords); i++) {
            ArrayGetString(g_aBadWords, i, szTemp, charsmax(szTemp));
            if(equal(szTemp, szClean)) { bExists = true; break; }
        }
        
        if (bExists) {
            console_print(id, "[AutoGag] Bu wildcard kelime zaten listede var!");
            return PLUGIN_HANDLED;
        }
        ArrayPushString(g_aBadWords, szClean);
    } else {
        if (TrieKeyExists(g_tBadWords, szClean)) {
            console_print(id, "[AutoGag] Bu kelime zaten listede var!");
            return PLUGIN_HANDLED;
        }
        TrieSetCell(g_tBadWords, szClean, 1);
    }
    
    new szFilePath[128];
    get_configsdir(szFilePath, charsmax(szFilePath));
    format(szFilePath, charsmax(szFilePath), "%s/kufurler.txt", szFilePath);
    
    if (!file_exists(szFilePath)) {
        formatex(szFilePath, charsmax(szFilePath), "kufurler.txt");
    }
    
    new f = fopen(szFilePath, "at");
    if (f) {
        fprintf(f, "%s^n", szClean);
        fclose(f);
        console_print(id, "[AutoGag] '%s' kelimesi basariyla eklendi.", szClean);
    } else {
        console_print(id, "[AutoGag] Dosya acilamadi!");
    }
    
    return PLUGIN_HANDLED;
}

public cmd_DelWord(id, level, cid) {
    if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;
    
    new szWord[32];
    read_argv(1, szWord, charsmax(szWord));
    trim(szWord);
    
    if (szWord[0] == '^0') return PLUGIN_HANDLED;
    
    strtolower(szWord);
    new szClean[32];
    copy(szClean, charsmax(szClean), szWord);
    
    new bool:bHasWildcard = false;
    new iLen = strlen(szClean);
    if (iLen > 1 && szClean[iLen - 1] == '*') {
        bHasWildcard = true;
        szClean[iLen - 1] = '^0';
    }
    
    CleanWord(szClean);
    
    if (bHasWildcard) {
        add(szClean, charsmax(szClean), "*");
    }
    
    new bool:bExists = false;
    if (bHasWildcard) {
        new szTemp[32];
        for (new i = 0; i < ArraySize(g_aBadWords); i++) {
            ArrayGetString(g_aBadWords, i, szTemp, charsmax(szTemp));
            if (equal(szTemp, szClean)) {
                bExists = true;
                break;
            }
        }
    } else {
        bExists = TrieKeyExists(g_tBadWords, szClean);
    }
    
    if (!bExists) {
        console_print(id, "[AutoGag] Bu kelime listede yok!");
        return PLUGIN_HANDLED;
    }
    
    if (bHasWildcard) {
        new szTemp[32];
        for (new i = 0; i < ArraySize(g_aBadWords); i++) {
            ArrayGetString(g_aBadWords, i, szTemp, charsmax(szTemp));
            if (equal(szTemp, szClean)) {
                ArrayDeleteItem(g_aBadWords, i);
                break;
            }
        }
    } else {
        TrieDeleteKey(g_tBadWords, szClean);
    }
    
    new szFilePath[128];
    get_configsdir(szFilePath, charsmax(szFilePath));
    format(szFilePath, charsmax(szFilePath), "%s/kufurler.txt", szFilePath);
    
    if (!file_exists(szFilePath)) {
        formatex(szFilePath, charsmax(szFilePath), "kufurler.txt");
    }
    
    new Array:aLines = ArrayCreate(64);
    new f = fopen(szFilePath, "rt");
    if (f) {
        new szLine[64];
        while (!feof(f)) {
            fgets(f, szLine, charsmax(szLine));
            trim(szLine);
            
            if (szLine[0] == '^0') continue;
            
            new szCleanLine[64];
            copy(szCleanLine, charsmax(szCleanLine), szLine);
            
            new bool:bLineHasWildcard = false;
            new iLineLen = strlen(szCleanLine);
            if (iLineLen > 1 && szCleanLine[iLineLen - 1] == '*') {
                bLineHasWildcard = true;
                szCleanLine[iLineLen - 1] = '^0';
            }
            
            CleanWord(szCleanLine);
            
            if (bLineHasWildcard) {
                add(szCleanLine, charsmax(szCleanLine), "*");
            }
            
            if (!equal(szCleanLine, szClean)) {
                ArrayPushString(aLines, szLine);
            }
        }
        fclose(f);
        
        f = fopen(szFilePath, "wt");
        if (f) {
            new szCurrentLine[64];
            for (new i = 0; i < ArraySize(aLines); i++) {
                ArrayGetString(aLines, i, szCurrentLine, charsmax(szCurrentLine));
                fprintf(f, "%s^n", szCurrentLine);
            }
            fclose(f);
            console_print(id, "[AutoGag] '%s' kelimesi basariyla silindi.", szWord);
        } else {
            console_print(id, "[AutoGag] Dosya yazilamadi!");
        }
    } else {
        console_print(id, "[AutoGag] Dosya okunamadi!");
    }
    
    ArrayDestroy(aLines);
    return PLUGIN_HANDLED;
}

public cmd_ClearOffenses(id, level, cid) {
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;
        
    new szArg[32];
    read_argv(1, szArg, charsmax(szArg));
    
    new target = cmd_target(id, szArg, 0);
    if (!target) return PLUGIN_HANDLED;
    
    g_iOffenses[target] = 0;
    g_iWarnings[target] = 0;
    g_iWarnDecayTimer[target] = get_systime();
    g_iOffenseDecayTimer[target] = get_systime();
    
    new szName[32], szAdminName[32];
    get_user_name(target, szName, charsmax(szName));
    get_user_name(id, szAdminName, charsmax(szAdminName));
    
    // nVault'a kaydet
    new szAuthID[35], szIP[32], szData[48];
    get_user_authid(target, szAuthID, charsmax(szAuthID));
    get_user_ip(target, szIP, charsmax(szIP), 1);
    formatex(szData, charsmax(szData), "0 0 %d %d", g_iWarnDecayTimer[target], g_iOffenseDecayTimer[target]);
    nvault_set(g_Vault, szAuthID, szData);
    nvault_set(g_Vault, szIP, szData);
    
    client_print_color(0, print_team_default, "%s^3%s^1, ^3%s ^1tarafindan ihlalleri sifirlandi.", AUTOGAG_TAG, szName, szAdminName);
    log_amx("[AutoGag] %s tarafindan %s ihlalleri sifirlandi.", szAdminName, szName);
    
    return PLUGIN_HANDLED;
}

bool:CleanWord(szWord[]) {
    new iOutIndex = 0;
    new iInIndex = 0;
    new c;
    new iLastChar = 0;

    // Tek bir O(N) pass ile karakterleri tarıyoruz
    while ((c = szWord[iInIndex++]) != 0) {
        
        // 1. ADIM: UTF-8 (2 Byte'lık Türkçe Karakter) Tespiti
        if (c == 0xC3) {
            if (szWord[iInIndex] == 0) break;
            c = szWord[iInIndex++];
            switch(c) {
                case 0xA7, 0x87: c = 'c'; // ç, Ç
                case 0xB6, 0x96: c = 'o'; // ö, Ö
                case 0xBC, 0x9C: c = 'u'; // ü, Ü
                default: { continue; } // Eşleşmediyse pas geç!
            }
        }
        else if (c == 0xC4) {
            if (szWord[iInIndex] == 0) break;
            c = szWord[iInIndex++];
            switch(c) {
                case 0xB1, 0xB0: c = 'i'; // ı, İ
                case 0x9F, 0x9E: c = 'g'; // ğ, Ğ
                default: { continue; }
            }
        }
        else if (c == 0xC5) {
            if (szWord[iInIndex] == 0) break;
            c = szWord[iInIndex++];
            switch(c) {
                case 0x9F, 0x9E: c = 's'; // ş, Ş
                default: { continue; }
            }
        }
        else if (c >= 0xD0) {
            // Şüpheli yabancı Unicode karakteri temizle/atla, oyuncuyu cezalandırma!
            continue; 
        }
        else {
            // 2. ADIM: ANSI Türkçe Karakterler ve Leetspeak Switch
            switch (c) {
                case 222, 254, '5': c = 's'; // Ş, ş, 5
                case 221, 253, '1': c = 'i'; // İ, ı, 1
                case 208, 240:      c = 'g'; // Ğ, ğ
                case 220, 252:      c = 'u'; // Ü, ü
                case 214, 246, '0': c = 'o'; // Ö, ö, 0
                case 199, 231:      c = 'c'; // Ç, ç
                
                case '4': c = 'a';
                case '3': c = 'e';
                case '7': c = 't';
                case '8': c = 'b';
            }
        }

        // 3. ADIM: Küçültme (ToLowerCase)
        if ('A' <= c && c <= 'Z') {
            c += ('a' - 'A');
        }

        // 4. ADIM: İstenmeyen karakterleri filtreleme ve tekrarları engelleme (Deduplication)
        if (('a' <= c && c <= 'z') || ('0' <= c && c <= '9')) {
            if (c == iLastChar) continue; // Aynı harf arka arkaya geldiyse atla
            
            szWord[iOutIndex++] = c;
            iLastChar = c;
        }
    }
    szWord[iOutIndex] = '^0'; // Stringi bitir
    return true;
}


