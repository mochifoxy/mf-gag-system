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
new g_iWarnings[33];
new g_iOffenses[33];
new g_iLastActionTime[33];

// Flood Korumasi icin degiskenler
new Float:g_flLastTalkTime[33];
new g_iMessageCount[33];

// CVAR Pointers
new g_pCvarEnabled;
new g_pCvarFloodTime;
new g_pCvarFloodLimit;
new g_pCvarDecayTime;
new g_pCvarWarnLimit;
new g_pCvarDefaultTime;

// Vault Handle
new g_Vault;

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
    g_pCvarWarnLimit = create_cvar("amx_autogag_warning_limit", "3");
    g_pCvarDefaultTime = create_cvar("amx_autogag_default_time", "15");
    
    g_tBadWords = TrieCreate();
    g_aBadWords = ArrayCreate(32);
    LoadWords();
    
    g_Vault = nvault_open("autogag_offenses");
    
    // 24 saatten eski kayitlari sil (Dosya sismesini onlemek icin)
    nvault_prune(g_Vault, 0, get_systime() - 86400);
}

public plugin_end() {
    TrieDestroy(g_tBadWords);
    ArrayDestroy(g_aBadWords);
    nvault_close(g_Vault);
}

public client_putinserver(id) {
    g_iWarnings[id] = 0;
    g_flLastTalkTime[id] = 0.0;
    g_iMessageCount[id] = 0;
    g_iOffenses[id] = 0;
    
    if (is_user_bot(id) || is_user_hltv(id)) return;
    
    set_task(1.0, "load_offenses", id);
}

public load_offenses(id) {
    if (!is_user_connected(id)) return;
    
    // nVault'tan veri oku (Hem ID hem IP kontrolu)
    new szAuthID[32], szIP[32];
    get_user_authid(id, szAuthID, charsmax(szAuthID));
    get_user_ip(id, szIP, charsmax(szIP), 1);
    
    new iCountID = 0, iWarningsID = 0, iTimestampID = 0;
    new iCountIP = 0, iWarningsIP = 0, iTimestampIP = 0;
    new szData[48], szCount[10], szWarnings[10], szTime[20];
    
    // SteamID ile kontrol
    if (nvault_get(g_Vault, szAuthID, szData, charsmax(szData))) {
        parse(szData, szCount, charsmax(szCount), szWarnings, charsmax(szWarnings), szTime, charsmax(szTime));
        iCountID = str_to_num(szCount);
        iWarningsID = str_to_num(szWarnings);
        iTimestampID = str_to_num(szTime);
    }
    
    // IP ile kontrol
    if (nvault_get(g_Vault, szIP, szData, charsmax(szData))) {
        parse(szData, szCount, charsmax(szCount), szWarnings, charsmax(szWarnings), szTime, charsmax(szTime));
        iCountIP = str_to_num(szCount);
        iWarningsIP = str_to_num(szWarnings);
        iTimestampIP = str_to_num(szTime);
    }
    
    new iCurrentTime = get_systime();
    new iDecayTime = get_pcvar_num(g_pCvarDecayTime);
    
    // 24 saat kontrolu (86400 saniye)
    if (iCurrentTime - iTimestampID > 86400) {
        iCountID = 0;
        iWarningsID = 0;
    } else if (iDecayTime > 0) {
        new iPassed = (iCurrentTime - iTimestampID) / iDecayTime;
        if (iPassed > 0) {
            iCountID = max(0, iCountID - iPassed);
            iWarningsID = 0;
        }
    }
    
    if (iCurrentTime - iTimestampIP > 86400) {
        iCountIP = 0;
        iWarningsIP = 0;
    } else if (iDecayTime > 0) {
        new iPassed = (iCurrentTime - iTimestampIP) / iDecayTime;
        if (iPassed > 0) {
            iCountIP = max(0, iCountIP - iPassed);
            iWarningsIP = 0;
        }
    }
    
    // Hangisi daha buyukse onu al (Cezadan kacamasin)
    g_iOffenses[id] = max(iCountID, iCountIP);
    g_iWarnings[id] = max(iWarningsID, iWarningsIP);
    g_iLastActionTime[id] = max(iTimestampID, iTimestampIP);
}

LoadWords() {
    new szFilePath[128];
    get_configsdir(szFilePath, charsmax(szFilePath));
    format(szFilePath, charsmax(szFilePath), "%s/kufurler.txt", szFilePath);
    
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
        
        CleanWord(szLine);
        
        if (szLine[0] != '^0') {
            TrieSetCell(g_tBadWords, szLine, 1);
            ArrayPushString(g_aBadWords, szLine);
        }
    }
    
    fclose(f);
    log_amx("[AutoGag] Kelime listesi yuklendi.");
}

public cmd_Say(id) {
    if (!is_user_connected(id)) return PLUGIN_CONTINUE;
    
    if (!get_pcvar_num(g_pCvarEnabled)) return PLUGIN_CONTINUE;
    
    new szMessage[192];
    read_args(szMessage, charsmax(szMessage));
    remove_quotes(szMessage);
    trim(szMessage);
    
    if (szMessage[0] == '^0') return PLUGIN_CONTINUE;
    
    if (szMessage[0] == '/' || szMessage[0] == '.') return PLUGIN_CONTINUE;
    
    new szName[32];
    get_user_name(id, szName, charsmax(szName));
    
    // --- Otomatik Sicil Temizleme (Decay) ---
    new iCurrentTime = get_systime();
    new iDecayTime = get_pcvar_num(g_pCvarDecayTime);
    if (iDecayTime > 0 && g_iLastActionTime[id] > 0) {
        new iPassed = (iCurrentTime - g_iLastActionTime[id]) / iDecayTime;
        if (iPassed > 0) {
            g_iOffenses[id] = max(0, g_iOffenses[id] - iPassed);
            g_iWarnings[id] = 0;
            g_iLastActionTime[id] = iCurrentTime;
            
            // Dusurulmus ihlali nVault'a kaydet (cik-gir sonrasi tutarli kalsin)
            new szDecayAuthID[32], szDecayIP[32], szDecayData[48];
            get_user_authid(id, szDecayAuthID, charsmax(szDecayAuthID));
            get_user_ip(id, szDecayIP, charsmax(szDecayIP), 1);
            formatex(szDecayData, charsmax(szDecayData), "%d %d %d", g_iOffenses[id], g_iWarnings[id], iCurrentTime);
            nvault_set(g_Vault, szDecayAuthID, szDecayData);
            nvault_set(g_Vault, szDecayIP, szDecayData);
        }
    }
    
    // --- Flood Korumasi ---
    new Float:flCurrentTime = get_gametime();
    if (flCurrentTime - g_flLastTalkTime[id] < get_pcvar_float(g_pCvarFloodTime)) {
        g_iMessageCount[id]++;
        if (g_iMessageCount[id] >= get_pcvar_num(g_pCvarFloodLimit)) {
            g_iWarnings[id]++;
            
            client_print_color(id, print_team_default, "%sCok hizli mesaj gonderiyorsunuz (Flood)! Uyari: ^3%d/%d", AUTOGAG_TAG, g_iWarnings[id], get_pcvar_num(g_pCvarWarnLimit));
            
            if (g_iWarnings[id] >= get_pcvar_num(g_pCvarWarnLimit)) {
                g_iOffenses[id]++;
                
                new iDefaultTime = get_pcvar_num(g_pCvarDefaultTime);
                new iGagTime = iDefaultTime;
                
                iGagTime = iDefaultTime * (1 << (g_iOffenses[id] - 1));
                client_print_color(id, print_team_default, "%sFlood yaptiginiz icin ^3%d dakika ^1gaglandiniz.", AUTOGAG_TAG, iGagTime);
                
                new szReason[64];
                formatex(szReason, charsmax(szReason), "Otomatik Gag (Flood %d. Ihlal)", g_iOffenses[id]);
                
                mfgag_set_gag(0, id, iGagTime, szReason);
                g_iWarnings[id] = 0;
                
                // nVault'a kaydet (Hem ID hem IP)
                new szAuthID[32], szIP[32], szData[48];
                get_user_authid(id, szAuthID, charsmax(szAuthID));
                get_user_ip(id, szIP, charsmax(szIP), 1);
                formatex(szData, charsmax(szData), "%d %d %d", g_iOffenses[id], g_iWarnings[id], get_systime());
                nvault_set(g_Vault, szAuthID, szData);
                nvault_set(g_Vault, szIP, szData);
                
                log_amx("[AutoGag] %s flood nedeniyle otomatik gaglandi. Sure: %d Dk, Ihlal: %d", szName, iGagTime, g_iOffenses[id]);
            }
            
            g_flLastTalkTime[id] = flCurrentTime;
            return PLUGIN_HANDLED;
        }
    } else {
        g_iMessageCount[id] = 1;
    }
    g_flLastTalkTime[id] = flCurrentTime;
    // ----------------------
    
    new bool:bFound = false;
    new szNewMessage[192];
    
    // --- Nukleer Blok (Bosluksuz Arama) ---
    new szSpaceless[192];
    copy(szSpaceless, charsmax(szSpaceless), szMessage);
    
    new iOutIndex = 0;
    for (new i = 0; szSpaceless[i] != '^0'; i++) {
        if (szSpaceless[i] != ' ') {
            szSpaceless[iOutIndex++] = szSpaceless[i];
        }
    }
    szSpaceless[iOutIndex] = '^0';
    CleanWord(szSpaceless);
    
    new szCurrentBadWord[32];
    for (new i = 0; i < ArraySize(g_aBadWords); i++) {
        ArrayGetString(g_aBadWords, i, szCurrentBadWord, charsmax(szCurrentBadWord));
        if (containsi(szSpaceless, szCurrentBadWord) != -1) {
            bFound = true;
            break;
        }
    }
    
    new szWord[192], szClean[192];
    new szSingleBuffer[64], szOriginalBuffer[128];
    new iPos = 0;
    new bool:bFirst = true;
    
    if (bFound) {
        copy(szNewMessage, charsmax(szNewMessage), "*****");
    } else {
        while ((iPos = argparse(szMessage, iPos, szWord, charsmax(szWord))) != -1) {
        copy(szClean, charsmax(szClean), szWord);
        CleanWord(szClean);
        
        if (szClean[0] == '^0') {
            if (!bFirst) add(szNewMessage, charsmax(szNewMessage), " ");
            add(szNewMessage, charsmax(szNewMessage), szWord);
            bFirst = false;
            continue;
        }
        
        new iLen = strlen(szClean);
        if (iLen == 1) {
            // Tekil harf yakaladik, buffer'a ekle
            add(szSingleBuffer, charsmax(szSingleBuffer), szClean);
            if (szOriginalBuffer[0] != '^0') add(szOriginalBuffer, charsmax(szOriginalBuffer), " ");
            add(szOriginalBuffer, charsmax(szOriginalBuffer), szWord);
            continue;
        } else {
            // Uzun bir kelime geldi. Once buffer'da biriken harfler var mi bakalim!
            if (szSingleBuffer[0] != '^0') {
                if (TrieKeyExists(g_tBadWords, szSingleBuffer)) {
                    bFound = true;
                    if (!bFirst) add(szNewMessage, charsmax(szNewMessage), " ");
                    add(szNewMessage, charsmax(szNewMessage), "*****");
                    bFirst = false;
                } else {
                    // Kufur degilmis, orijinal halini (bosluklu) mesaja ekle
                    if (!bFirst) add(szNewMessage, charsmax(szNewMessage), " ");
                    add(szNewMessage, charsmax(szNewMessage), szOriginalBuffer);
                    bFirst = false;
                }
                szSingleBuffer[0] = '^0';
                szOriginalBuffer[0] = '^0';
            }
        }
        
        // Normal kelime kontrolu
        if (TrieKeyExists(g_tBadWords, szClean)) {
            bFound = true;
            if (!bFirst) add(szNewMessage, charsmax(szNewMessage), " ");
            add(szNewMessage, charsmax(szNewMessage), "*****");
        } else {
            if (!bFirst) add(szNewMessage, charsmax(szNewMessage), " ");
            add(szNewMessage, charsmax(szNewMessage), szWord);
        }
        bFirst = false;
    }
    
    // Dongu bitti ama sonda harf kaldi mi? (Orn: mesajin sonu "E Z" ile bitiyorsa)
    if (szSingleBuffer[0] != '^0') {
        if (TrieKeyExists(g_tBadWords, szSingleBuffer)) {
            bFound = true;
            if (!bFirst) add(szNewMessage, charsmax(szNewMessage), " ");
            add(szNewMessage, charsmax(szNewMessage), "*****");
        } else {
            if (!bFirst) add(szNewMessage, charsmax(szNewMessage), " ");
            add(szNewMessage, charsmax(szNewMessage), szOriginalBuffer);
        }
    }
    }
    
    if (bFound) {
        g_iWarnings[id]++;
        
        new szCmd[10];
        read_argv(0, szCmd, charsmax(szCmd));
        
        new bTeamChat = equal(szCmd, "say_team");
        
        // Crash Korumasi: Yuzde isaretlerini kacis karakteri yap
        replace_all(szNewMessage, charsmax(szNewMessage), "%", "%%");
        
        if (bTeamChat) {
            new iTeam = get_user_team(id);
            new players[32], pnum, target;
            get_players(players, pnum, "ch");
            
            for (new i = 0; i < pnum; i++) {
                target = players[i];
                if (get_user_team(target) == iTeam) {
                    client_print_color(target, id, "^3(TEAM) %s :  ^1%s", szName, szNewMessage);
                }
            }
        } else {
            client_print_color(0, id, "^3%s :  ^1%s", szName, szNewMessage);
        }
        
        if (g_iWarnings[id] >= get_pcvar_num(g_pCvarWarnLimit)) {
            g_iOffenses[id]++;
            
            new iDefaultTime = get_pcvar_num(g_pCvarDefaultTime);
            new iGagTime = iDefaultTime;
            
            iGagTime = iDefaultTime * (1 << (g_iOffenses[id] - 1));
            client_print_color(id, print_team_default, "%sYasakli kelime sinirini astiginiz icin ^3%d dakika ^1gaglandiniz.", AUTOGAG_TAG, iGagTime);
            
            new szReason[64];
            formatex(szReason, charsmax(szReason), "Otomatik Gag (Yasakli Kelime %d. Ihlal)", g_iOffenses[id]);
            
            mfgag_set_gag(0, id, iGagTime, szReason);
            g_iWarnings[id] = 0;
            
            // nVault'a kaydet (Hem ID hem IP)
            new szAuthID[32], szIP[32], szData[48];
            get_user_authid(id, szAuthID, charsmax(szAuthID));
            get_user_ip(id, szIP, charsmax(szIP), 1);
            formatex(szData, charsmax(szData), "%d %d %d", g_iOffenses[id], g_iWarnings[id], get_systime());
            nvault_set(g_Vault, szAuthID, szData);
            nvault_set(g_Vault, szIP, szData);
            
            log_amx("[AutoGag] %s otomatik gaglandi. Sure: %d Dk, Ihlal: %d, Neden: Yasakli Kelime", szName, iGagTime, g_iOffenses[id]);
        } else {
            client_print_color(id, print_team_default, "%sLutfen yasakli kelime kullanmayiniz! Uyari: ^3%d/%d", AUTOGAG_TAG, g_iWarnings[id], get_pcvar_num(g_pCvarWarnLimit));
            
            // nVault'a kaydet (Uyarilari da sakla)
            new szAuthID[32], szIP[32], szData[48];
            get_user_authid(id, szAuthID, charsmax(szAuthID));
            get_user_ip(id, szIP, charsmax(szIP), 1);
            formatex(szData, charsmax(szData), "%d %d %d", g_iOffenses[id], g_iWarnings[id], get_systime());
            nvault_set(g_Vault, szAuthID, szData);
            nvault_set(g_Vault, szIP, szData);
        }
        
        return PLUGIN_HANDLED;
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
    CleanWord(szClean);
    
    if (szClean[0] == '^0') {
        console_print(id, "[AutoGag] Gecersiz kelime!");
        return PLUGIN_HANDLED;
    }
    
    if (TrieKeyExists(g_tBadWords, szClean)) {
        console_print(id, "[AutoGag] Bu kelime zaten listede var!");
        return PLUGIN_HANDLED;
    }
    
    TrieSetCell(g_tBadWords, szClean, 1);
    ArrayPushString(g_aBadWords, szClean);
    
    new szFilePath[128];
    get_configsdir(szFilePath, charsmax(szFilePath));
    format(szFilePath, charsmax(szFilePath), "%s/kufurler.txt", szFilePath);
    
    if (!file_exists(szFilePath)) {
        formatex(szFilePath, charsmax(szFilePath), "kufurler.txt");
    }
    
    new f = fopen(szFilePath, "at");
    if (f) {
        fprintf(f, "%s^n", szClean); // Temizlenmis hali yaz, dosyayi duzenli tut
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
    CleanWord(szClean);
    
    if (!TrieKeyExists(g_tBadWords, szClean)) {
        console_print(id, "[AutoGag] Bu kelime listede yok!");
        return PLUGIN_HANDLED;
    }
    
    TrieDeleteKey(g_tBadWords, szClean);
    
    // Global diziden de sil
    for (new i = 0; i < ArraySize(g_aBadWords); i++) {
        new szTemp[32];
        ArrayGetString(g_aBadWords, i, szTemp, charsmax(szTemp));
        if (equal(szTemp, szClean)) {
            ArrayDeleteItem(g_aBadWords, i);
            break;
        }
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
            CleanWord(szCleanLine);
            
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
    g_iLastActionTime[target] = get_systime();
    
    new szName[32], szAdminName[32];
    get_user_name(target, szName, charsmax(szName));
    get_user_name(id, szAdminName, charsmax(szAdminName));
    
    // nVault'a kaydet
    new szAuthID[32], szIP[32], szData[48];
    get_user_authid(target, szAuthID, charsmax(szAuthID));
    get_user_ip(target, szIP, charsmax(szIP), 1);
    formatex(szData, charsmax(szData), "0 0 %d", g_iLastActionTime[target]);
    nvault_set(g_Vault, szAuthID, szData);
    nvault_set(g_Vault, szIP, szData);
    
    client_print_color(0, print_team_default, "%s^3%s^1, ^3%s ^1tarafindan ihlalleri sifirlandi.", AUTOGAG_TAG, szName, szAdminName);
    log_amx("[AutoGag] %s tarafindan %s ihlalleri sifirlandi.", szAdminName, szName);
    
    return PLUGIN_HANDLED;
}

CleanWord(szWord[]) {
    new iOutIndex = 0;
    new iInIndex = 0;
    new c;
    new iLastChar = 0;
    
    while ((c = szWord[iInIndex++]) != 0) {
        switch (c) {
            case 222: c = 's'; // Ş
            case 254: c = 's'; // ş
            case 221: c = 'i'; // İ
            case 253: c = 'i'; // ı
            case 208: c = 'g'; // Ğ
            case 240: c = 'g'; // ğ
            case 220: c = 'u'; // Ü
            case 252: c = 'u'; // ü
            case 214: c = 'o'; // Ö
            case 246: c = 'o'; // ö
            case 199: c = 'c'; // Ç
            case 231: c = 'c'; // ç
            
            case '4': c = 'a';
            case '3': c = 'e';
            case '1': c = 'i';
            case '0': c = 'o';
            case '7': c = 't';
            case '5': c = 's';
            case '8': c = 'b';
        }
        
        if ('A' <= c && c <= 'Z') {
            c += ('a' - 'A');
        }
        
        if (('a' <= c && c <= 'z') || ('0' <= c && c <= '9')) {
            if (c == iLastChar) {
                continue;
            }
            
            szWord[iOutIndex++] = c;
            iLastChar = c;
        }
    }
    szWord[iOutIndex] = '^0';
}
