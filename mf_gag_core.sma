#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <fakemeta>

#pragma semicolon 1

#define PLUGIN "MF Gag Core"
#define VERSION "1.0"
#define AUTHOR "mochifoxy && FoxyBlinks"

#define TASK_CHECK_GAG 1000
#define TASK_GAG_EXPIRE 2000

new g_Vault;

// Oyuncu verileri
new bool:g_bIsGagged[33];
new g_iGagEnd[33];
new g_szAuthID[33][35];
new g_szIP[33][32];
new g_szGagReason[33][64];

public plugin_natives() {
    register_native("mfgag_is_gagged", "native_is_gagged");
    register_native("mfgag_set_gag", "native_set_gag");
    register_native("mfgag_remove_gag", "native_remove_gag");
    register_native("mfgag_get_time", "native_get_time");
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    register_clcmd("say", "cmd_say");
    register_clcmd("say_team", "cmd_say_team");
    
    register_forward(FM_Voice_SetClientListening, "fwd_VoiceSetClientListening");
    
    g_Vault = nvault_open("mf_gag_system");
    if (g_Vault == INVALID_HANDLE) {
        set_fail_state("nVault acilamadi! Eklenti durduruldu.");
    }
}

public plugin_end() {
    if (g_Vault != INVALID_HANDLE) {
        nvault_close(g_Vault);
    }
}

public client_putinserver(id) {
    g_bIsGagged[id] = false;
    g_iGagEnd[id] = 0;
    if (is_user_bot(id) || is_user_hltv(id))
        return;
        
    get_user_authid(id, g_szAuthID[id], charsmax(g_szAuthID[]));
    get_user_ip(id, g_szIP[id], charsmax(g_szIP[]), 1);
    
    set_task(1.0, "check_gag", id + TASK_CHECK_GAG);
}

public client_disconnected(id) {
    g_bIsGagged[id] = false;
    g_iGagEnd[id] = 0;
    g_szAuthID[id][0] = '^0';
    g_szIP[id][0] = '^0';
    g_szGagReason[id][0] = '^0';
    remove_task(id + TASK_CHECK_GAG);
    remove_task(id + TASK_GAG_EXPIRE);
}

public check_gag(task_id) {
    new id = task_id - TASK_CHECK_GAG;
    if (!is_user_connected(id)) return;
    
    new szData[128], iTimestamp;
    new bool:bFound = false;
    
    get_user_authid(id, g_szAuthID[id], charsmax(g_szAuthID[]));
    get_user_ip(id, g_szIP[id], charsmax(g_szIP[]), 1);
    
    if (nvault_lookup(g_Vault, g_szAuthID[id], szData, charsmax(szData), iTimestamp)) {
        bFound = true;
    }
    else if (nvault_lookup(g_Vault, g_szIP[id], szData, charsmax(szData), iTimestamp)) {
        bFound = true;
    }
    
    if (bFound) {
        new szEnd[32], szReason[64];
        new iPos = contain(szData, "^^");
        if (iPos != -1) {
            copyc(szEnd, charsmax(szEnd), szData, '^^');
            copy(szReason, charsmax(szReason), szData[iPos+1]);
        } else {
            copy(szEnd, charsmax(szEnd), szData);
            copy(szReason, charsmax(szReason), "Bilinmiyor");
        }
        
        new iEnd = str_to_num(szEnd);
        new iCurrentTime = get_systime();
        
        if (iEnd > iCurrentTime || iEnd == 0) {
            g_bIsGagged[id] = true;
            g_iGagEnd[id] = iEnd;
            copy(g_szGagReason[id], charsmax(g_szGagReason[]), szReason);
            
            if (iEnd > 0) {
                new iRemaining = iEnd - iCurrentTime;
                set_task(float(iRemaining), "task_GagExpired", id + TASK_GAG_EXPIRE);
            }
            new szName[32];
            get_user_name(id, szName, charsmax(szName));
            if (iEnd == 0) {
                client_print_color(0, print_team_default, "^4[ GAG ] ^3%s ^1adli oyuncu sunucuya ^4SINIRSIZ GAGLI ^1olarak baglandi. Sebep: ^3%s", szName, szReason);
            } else {
                new iRemainingMinutes = (iEnd - iCurrentTime) / 60;
                if (iRemainingMinutes < 1) iRemainingMinutes = 1;
                client_print_color(0, print_team_default, "^4[ GAG ] ^3%s ^1adli oyuncu sunucuya ^4%d DK GAGLI ^1olarak baglandi. Sebep: ^3%s", szName, iRemainingMinutes, szReason);
            }
        } else {
            new szName[32];
            get_user_name(id, szName, charsmax(szName));
            remove_gag_from_db(g_szAuthID[id], g_szIP[id]);
            log_to_file("mf_gag.log", "Sistem | Hedef: %s (%s) | Gag Suresi Dolmus (Baglandi)", szName, g_szAuthID[id]);
        }
    }
}

public task_GagExpired(task_id) {
    new id = task_id - TASK_GAG_EXPIRE;
    if (is_user_connected(id)) {
        remove_gag_from_db(g_szAuthID[id], g_szIP[id]);
        g_bIsGagged[id] = false;
        g_iGagEnd[id] = 0;
        
        new szName[32];
        get_user_name(id, szName, charsmax(szName));
        
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Gag sureniz doldu, artik konusabilirsiniz.");
        client_print_color(0, print_team_default, "^4[ GAG ] ^3%s ^1adli oyuncunun gag cezasi bitmistir.", szName);
        
        log_to_file("mf_gag.log", "Sistem | Hedef: %s (%s) | Gag Suresi Doldu", szName, g_szAuthID[id]);
    }
}

stock remove_gag_from_db(const szAuth[], const szIP[]) {
    nvault_remove(g_Vault, szAuth);
    nvault_remove(g_Vault, szIP);
}

// Hooks
public cmd_say(id) {
    if (g_bIsGagged[id]) {
        new szText[128];
        read_args(szText, charsmax(szText));
        remove_quotes(szText);
        
        // Gagli olsa bile '/' veya '.' ile baslayan komutlari engelleme
        if (szText[0] == '/' || szText[0] == '.') {
            return PLUGIN_CONTINUE;
        }
        
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Susturuldugunuz icin yazi yazamazsiniz.");
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public cmd_say_team(id) {
    if (g_bIsGagged[id]) {
        new szText[128];
        read_args(szText, charsmax(szText));
        remove_quotes(szText);
        
        if (szText[0] == '/' || szText[0] == '.') {
            return PLUGIN_CONTINUE;
        }
        
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Susturuldugunuz icin takim ici yazi yazamazsiniz.");
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public fwd_VoiceSetClientListening(receiver, sender, listen) {
    if (receiver == sender) return FMRES_IGNORED;
    
    if (g_bIsGagged[sender]) {
        engfunc(EngFunc_SetClientListening, receiver, sender, 0);
        return FMRES_SUPERCEDE;
    }
    
    return FMRES_IGNORED;
}

// Natives
public bool:native_is_gagged(plugin_id, num_params) {
    new id = get_param(1);
    return g_bIsGagged[id];
}

public bool:native_set_gag(plugin_id, num_params) {
    new admin_id = get_param(1);
    new target_id = get_param(2);
    new minutes = get_param(3);
    
    new szReason[64];
    get_string(4, szReason, charsmax(szReason));
    
    if (!is_user_connected(target_id)) return false;
    
    if (admin_id == target_id) {
        client_print_color(admin_id, print_team_default, "^4[ GAG ] ^1Kendinizi gaglayamazsiniz!");
        return false;
    }
    
    if (access(target_id, ADMIN_IMMUNITY) && admin_id != 0) {
        client_print_color(admin_id, print_team_default, "^4[ GAG ] ^1Dokunulmazligi olan bir oyuncuyu gaglayamazsiniz!");
        return false;
    }
    
    new iEnd = (minutes == 0) ? 0 : get_systime() + (minutes * 60);
    
    new bool:bIsExtension = false;
    new bool:bIsShortening = false;
    new iAddedMinutes = minutes;
    
    if (g_bIsGagged[target_id] && minutes != 0) {
        if (g_iGagEnd[target_id] == 0) {
            // Sinirsiz gagliydi, simdi sureli yapiliyo -> Kisaltma!
            bIsShortening = true;
            iAddedMinutes = minutes;
        } else {
            new iRemainingSeconds = g_iGagEnd[target_id] - get_systime();
            if (iRemainingSeconds > 0) {
                new iRemainingMins = iRemainingSeconds / 60;
                if (minutes < iRemainingMins) {
                    bIsShortening = true;
                    iAddedMinutes = iRemainingMins - minutes;
                    if (iAddedMinutes < 1) iAddedMinutes = 1;
                } else if (minutes > iRemainingMins) {
                    bIsExtension = true;
                    iAddedMinutes = minutes - iRemainingMins;
                    if (iAddedMinutes < 1) iAddedMinutes = 1;
                }
            }
        }
    }
    g_bIsGagged[target_id] = true;
    g_iGagEnd[target_id] = iEnd;
    copy(g_szGagReason[target_id], charsmax(g_szGagReason[]), szReason);
    
    remove_task(target_id + TASK_GAG_EXPIRE);
    if (minutes > 0) {
        set_task(float(minutes * 60), "task_GagExpired", target_id + TASK_GAG_EXPIRE);
    }
    
    new szData[128];
    formatex(szData, charsmax(szData), "%d^^%s", iEnd, szReason);
    
    nvault_set(g_Vault, g_szAuthID[target_id], szData);
    nvault_set(g_Vault, g_szIP[target_id], szData);
    
    new szTargetName[32], szAdminName[32], szAdminAuthID[35];
    get_user_name(target_id, szTargetName, charsmax(szTargetName));
    
    if (admin_id == 0) {
        copy(szAdminName, charsmax(szAdminName), "Server");
        copy(szAdminAuthID, charsmax(szAdminAuthID), "Server");
    } else {
        get_user_name(admin_id, szAdminName, charsmax(szAdminName));
        get_user_authid(admin_id, szAdminAuthID, charsmax(szAdminAuthID));
    }
    
    if (minutes == 0) {
        client_print_color(0, print_team_default, "^4[ GAG ] ^3%s ^1yetkilisi, ^4%s ^1adli oyuncuyu ^3SINIRSIZ ^1sureyle gag'ladi. Sebep: ^3%s", szAdminName, szTargetName, szReason);
        log_to_file("mf_gag.log", "Yetkili: %s (%s) | Hedef: %s (%s) | Sure: Sinirsiz | Sebep: %s", szAdminName, szAdminAuthID, szTargetName, g_szAuthID[target_id], szReason);
    } else if (bIsExtension) {
        client_print_color(0, print_team_default, "^4[ GAG ] ^3%s ^1yetkilisi, ^4%s ^1adli oyuncunun gag suresini ^3%d dakika ^1uzatti. Sebep: ^3%s", szAdminName, szTargetName, iAddedMinutes, szReason);
        log_to_file("mf_gag.log", "Yetkili: %s (%s) | Hedef: %s (%s) | Sure: %d Dakika Uzatildi | Sebep: %s", szAdminName, szAdminAuthID, szTargetName, g_szAuthID[target_id], iAddedMinutes, szReason);
    } else if (bIsShortening) {
        client_print_color(0, print_team_default, "^4[ GAG ] ^3%s ^1yetkilisi, ^4%s ^1adli oyuncunun gag suresini ^3%d dakika ^1kisaltti. Sebep: ^3%s", szAdminName, szTargetName, iAddedMinutes, szReason);
        log_to_file("mf_gag.log", "Yetkili: %s (%s) | Hedef: %s (%s) | Sure: %d Dakika Kisaltildi | Sebep: %s", szAdminName, szAdminAuthID, szTargetName, g_szAuthID[target_id], iAddedMinutes, szReason);
    } else {
        client_print_color(0, print_team_default, "^4[ GAG ] ^3%s ^1yetkilisi, ^4%s ^1adli oyuncuyu ^3%d dakika ^1sureyle gag'ladi. Sebep: ^3%s", szAdminName, szTargetName, minutes, szReason);
        log_to_file("mf_gag.log", "Yetkili: %s (%s) | Hedef: %s (%s) | Sure: %d Dakika | Sebep: %s", szAdminName, szAdminAuthID, szTargetName, g_szAuthID[target_id], minutes, szReason);
    }
    
    return true;
}

public bool:native_remove_gag(plugin_id, num_params) {
    new admin_id = get_param(1);
    new target_id = get_param(2);
    
    if (!is_user_connected(target_id)) return false;
    if (!g_bIsGagged[target_id]) return false;
    
    remove_task(target_id + TASK_GAG_EXPIRE);
    g_bIsGagged[target_id] = false;
    g_iGagEnd[target_id] = 0;
    
    remove_gag_from_db(g_szAuthID[target_id], g_szIP[target_id]);
    
    new szTargetName[32], szAdminName[32], szAdminAuthID[35];
    get_user_name(target_id, szTargetName, charsmax(szTargetName));
    
    if (admin_id == 0) {
        copy(szAdminName, charsmax(szAdminName), "Server");
        copy(szAdminAuthID, charsmax(szAdminAuthID), "Server");
    } else {
        get_user_name(admin_id, szAdminName, charsmax(szAdminName));
        get_user_authid(admin_id, szAdminAuthID, charsmax(szAdminAuthID));
    }
    
    client_print_color(0, print_team_default, "^4[ GAG ] ^3%s ^1yetkilisi, ^4%s ^1adli oyuncunun gag'ini kaldirdi.", szAdminName, szTargetName);
    log_to_file("mf_gag.log", "Yetkili: %s (%s) | Hedef: %s (%s) | Gag Kaldirildi", szAdminName, szAdminAuthID, szTargetName, g_szAuthID[target_id]);
    
    return true;
}

public native_get_time(plugin_id, num_params) {
    new id = get_param(1);
    if (!g_bIsGagged[id]) return -1;
    if (g_iGagEnd[id] == 0) return 0;
    
    return g_iGagEnd[id] - get_systime();
}
