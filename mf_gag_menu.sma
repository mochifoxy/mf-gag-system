#include <amxmodx>
#include <amxmisc>
#include <mf_gag>

#pragma semicolon 1

#define PLUGIN "MF Gag Menu"
#define VERSION "1.0"
#define AUTHOR "mochifoxy && FoxyBlinks"

new g_MenuTarget[33];
new bool:g_bFromUngag[33];
new g_MenuTime[33];
new bool:g_bIsShortening[33];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    register_clcmd("say /gagmenu", "cmd_gagmenu");
    register_clcmd("say_team /gagmenu", "cmd_gagmenu");
    register_clcmd("amx_gagmenu", "cmd_gagmenu");
    
    register_clcmd("say /ungagmenu", "cmd_ungagmenu");
    register_clcmd("say_team /ungagmenu", "cmd_ungagmenu");
    register_clcmd("amx_ungagmenu", "cmd_ungagmenu");
    
    register_clcmd("custom_gag_time", "cmd_CustomGagTime");
    register_clcmd("custom_gag_reason", "cmd_CustomGagReason");
}

public cmd_gagmenu(id) {
    if (!access(id, ADMIN_KICK)) {
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Bu komutu kullanmaya yetkiniz yok.");
        return PLUGIN_HANDLED;
    }
    
    ShowPlayerMenu(id);
    return PLUGIN_HANDLED; // Komutu chatten gizle
}

public ShowPlayerMenu(id) {
    new menu = menu_create("\d[\r GAG YONETIM PANELI \d]^n\y==========================", "Handler_PlayerMenu");
    
    new players[32], pnum, target;
    new szName[32], szTargetId[10], szItem[64];
    
    get_players(players, pnum, "h"); // HLTV'yi atla (Botlari dahil et)
    
    for (new i = 0; i < pnum; i++) {
        target = players[i];
        
        get_user_name(target, szName, charsmax(szName));
        num_to_str(target, szTargetId, charsmax(szTargetId));
        
        if (mfgag_is_gagged(target)) {
            new iRemaining = mfgag_get_time(target);
            if (iRemaining > 0) {
                new iMins = iRemaining / 60;
                if (iMins < 1) iMins = 1;
                formatex(szItem, charsmax(szItem), "\w%s \y[Gagli - %d Dk]", szName, iMins);
            } else if (iRemaining == 0) {
                formatex(szItem, charsmax(szItem), "\w%s \r[Gagli - Sinirsiz]", szName);
            } else {
                formatex(szItem, charsmax(szItem), "\w%s \y[Gagli]", szName);
            }
        } else {
            formatex(szItem, charsmax(szItem), "\w%s", szName);
        }
        
        menu_additem(menu, szItem, szTargetId);
    }
    
    menu_setprop(menu, MPROP_BACKNAME, "\wGeri");
    menu_setprop(menu, MPROP_NEXTNAME, "\wIleri");
    menu_setprop(menu, MPROP_EXITNAME, "\rCikis");
    
    menu_display(id, menu, 0);
}

public Handler_PlayerMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new szData[6], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    new target = str_to_num(szData);
    
    if (!is_user_connected(target)) {
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Oyuncu oyundan ayrilmis.");
        menu_destroy(menu);
        ShowPlayerMenu(id);
        return PLUGIN_HANDLED;
    }
    
    g_MenuTarget[id] = target;
    g_bFromUngag[id] = false;
    
    if (mfgag_is_gagged(target)) {
        menu_destroy(menu);
        ShowGagActionMenu(id);
    } else {
        // Gaglı değilse süre seçme menüsüne geç
        g_bIsShortening[id] = false;
        menu_destroy(menu);
        ShowTimeMenu(id);
    }
    
    return PLUGIN_HANDLED;
}

public ShowGagActionMenu(id) {
    new target = g_MenuTarget[id];
    if (!is_user_connected(target)) return;
    
    new szName[32], szTitle[128];
    get_user_name(target, szName, charsmax(szName));
    formatex(szTitle, charsmax(szTitle), "\d[\r GAG ISLEMLERI \d]^n\y==========================^n\wOyuncu: \y%s^n", szName);
    
    new menu = menu_create(szTitle, "Handler_GagActionMenu");
    
    menu_additem(menu, "\wGagi Kaldir", "1");
    menu_additem(menu, "\wGag Suresini Uzat", "2");
    menu_additem(menu, "\wGag Suresini Kisalt", "3");
    
    menu_setprop(menu, MPROP_EXITNAME, "\dGeri");
    
    menu_display(id, menu, 0);
}

public Handler_GagActionMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        if (g_bFromUngag[id]) ShowUngagMenu(id);
        else ShowPlayerMenu(id);
        return PLUGIN_HANDLED;
    }
    
    new szData[6], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    new iAction = str_to_num(szData);
    new target = g_MenuTarget[id];
    
    if (!is_user_connected(target)) {
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Oyuncu oyundan ayrilmis.");
        menu_destroy(menu);
        if (g_bFromUngag[id]) ShowUngagMenu(id);
        else ShowPlayerMenu(id);
        return PLUGIN_HANDLED;
    }
    
    if (iAction == 1) {
        // Gagı Kaldır
        mfgag_remove_gag(id, target);
        menu_destroy(menu);
        if (g_bFromUngag[id]) ShowUngagMenu(id);
        else ShowPlayerMenu(id);
    } else if (iAction == 2) {
        // Gagı Uzat
        g_bIsShortening[id] = false;
        menu_destroy(menu);
        ShowTimeMenu(id);
    } else if (iAction == 3) {
        // Gagı Kısalt
        g_bIsShortening[id] = true;
        menu_destroy(menu);
        ShowTimeMenu(id);
    }
    
    return PLUGIN_HANDLED;
}

public ShowTimeMenu(id) {
    new target = g_MenuTarget[id];
    if (!is_user_connected(target)) return;
    
    new szName[32], szTitle[128];
    get_user_name(target, szName, charsmax(szName));
    formatex(szTitle, charsmax(szTitle), "\d[\r GAG SURESI SECIMI \d]^n\y==========================^n\wHedef: \y%s^n", szName);
    
    new menu = menu_create(szTitle, "Handler_TimeMenu");
    
    menu_additem(menu, "\w1 Dakika", "1");
    menu_additem(menu, "\w5 Dakika", "5");
    menu_additem(menu, "\w10 Dakika", "10");
    menu_additem(menu, "\w20 Dakika", "20");
    menu_additem(menu, "\w30 Dakika", "30");
    menu_additem(menu, "\w60 Dakika", "60");
    menu_additem(menu, "\rSinirsiz", "0");
    menu_additem(menu, "\yOzel Sure", "custom");
    
    menu_setprop(menu, MPROP_EXITNAME, "\dIptal/Geri");
    
    menu_display(id, menu, 0);
}

public Handler_TimeMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        if (g_bFromUngag[id]) ShowUngagMenu(id);
        else ShowPlayerMenu(id);
        return PLUGIN_HANDLED;
    }
    
    new szData[10], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    if (equal(szData, "custom")) {
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Lutfen chat kisminda sureyi (dakika) yazin.");
        client_cmd(id, "messagemode custom_gag_time");
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new iTime = str_to_num(szData);
    new target = g_MenuTarget[id];
    
    if (is_user_connected(target)) {
        if (mfgag_is_gagged(target) && iTime != 0) {
            new iCurrentTime = mfgag_get_time(target);
            if (iCurrentTime > 0) {
                new iRemainingMins = iCurrentTime / 60;
                if (g_bIsShortening[id]) {
                    new iNewMins = iRemainingMins - iTime;
                    if (iNewMins <= 0) {
                        mfgag_remove_gag(id, target);
                        menu_destroy(menu);
                        if (g_bFromUngag[id]) ShowUngagMenu(id);
                        else ShowPlayerMenu(id);
                        return PLUGIN_HANDLED;
                    }
                    mfgag_set_gag(id, target, iNewMins, "Sure Kisaltildi");
                    menu_destroy(menu);
                    if (g_bFromUngag[id]) ShowUngagMenu(id);
                    else ShowPlayerMenu(id);
                    return PLUGIN_HANDLED;
                } else {
                    g_MenuTime[id] = iRemainingMins + iTime;
                }
                menu_destroy(menu);
                ShowReasonMenu(id);
                return PLUGIN_HANDLED;
            } else if (iCurrentTime == 0) {
                client_print_color(id, print_team_default, "^4[ GAG ] ^1Bu oyuncu zaten sinirsiz gagli!");
                menu_destroy(menu);
                return PLUGIN_HANDLED;
            }
        } else {
            g_MenuTime[id] = iTime;
            menu_destroy(menu);
            ShowReasonMenu(id);
            return PLUGIN_HANDLED;
        }
    }
    
    menu_destroy(menu);
    if (g_bFromUngag[id]) ShowUngagMenu(id);
    else ShowPlayerMenu(id);
    
    return PLUGIN_HANDLED;
}

public cmd_ungagmenu(id) {
    if (!access(id, ADMIN_KICK)) {
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Bu komutu kullanmaya yetkiniz yok.");
        return PLUGIN_HANDLED;
    }
    
    ShowUngagMenu(id);
    return PLUGIN_HANDLED;
}

public ShowUngagMenu(id) {
    new menu = menu_create("\d[\r UNGAG YONETIM PANELI \d]^n\y==========================", "Handler_UngagMenu");
    
    new players[32], pnum, target;
    new szName[32], szTargetId[10];
    new bool:bGaggedFound = false;
    
    get_players(players, pnum, "h");
    
    for (new i = 0; i < pnum; i++) {
        target = players[i];
        
        if (mfgag_is_gagged(target)) {
            bGaggedFound = true;
            get_user_name(target, szName, charsmax(szName));
            num_to_str(target, szTargetId, charsmax(szTargetId));
            
            new iTime = mfgag_get_time(target);
            new szItem[64];
            
            if (iTime == 0) {
                formatex(szItem, charsmax(szItem), "\w%s \r[Sinirsiz]", szName);
            } else {
                new iMins = iTime / 60;
                if (iMins < 1) iMins = 1;
                formatex(szItem, charsmax(szItem), "\w%s \y[%d Dk]", szName, iMins);
            }
            
            menu_additem(menu, szItem, szTargetId);
        }
    }
    
    if (!bGaggedFound) {
        menu_destroy(menu);
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Su anda gagli oyuncu bulunmuyor.");
        return;
    }
    
    menu_setprop(menu, MPROP_BACKNAME, "\wGeri");
    menu_setprop(menu, MPROP_NEXTNAME, "\wIleri");
    menu_setprop(menu, MPROP_EXITNAME, "\rCikis");
    
    menu_display(id, menu, 0);
}

public Handler_UngagMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new szData[6], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    new target = str_to_num(szData);
    
    if (!is_user_connected(target)) {
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Oyuncu oyundan ayrilmis.");
        menu_destroy(menu);
        ShowUngagMenu(id);
        return PLUGIN_HANDLED;
    }
    
    g_MenuTarget[id] = target;
    g_bFromUngag[id] = true;
    
    menu_destroy(menu);
    ShowGagActionMenu(id); // Direkt kaldırmak yerine seçenek sun
    
    return PLUGIN_HANDLED;
}

public cmd_CustomGagTime(id) {
    new szArg[10];
    read_argv(1, szArg, charsmax(szArg));
    
    new i = 0;
    new bool:bIsNumeric = true;
    while (szArg[i] != '^0') {
        if (!isdigit(szArg[i])) {
            bIsNumeric = false;
            break;
        }
        i++;
    }
    
    if (!bIsNumeric || i == 0) {
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Gecersiz sure girdiniz! Lutfen sadece sayi girin.");
        if (g_bFromUngag[id]) ShowUngagMenu(id);
        else ShowPlayerMenu(id);
        return PLUGIN_HANDLED;
    }
    
    new iTime = str_to_num(szArg);
    new target = g_MenuTarget[id];
    
    if (is_user_connected(target)) {
        if (mfgag_is_gagged(target) && iTime != 0) {
            new iCurrentTime = mfgag_get_time(target);
            if (iCurrentTime > 0) {
                new iRemainingMins = iCurrentTime / 60;
                if (g_bIsShortening[id]) {
                    new iNewMins = iRemainingMins - iTime;
                    if (iNewMins <= 0) {
                        mfgag_remove_gag(id, target);
                        if (g_bFromUngag[id]) ShowUngagMenu(id);
                        else ShowPlayerMenu(id);
                        return PLUGIN_HANDLED;
                    }
                    mfgag_set_gag(id, target, iNewMins, "Sure Kisaltildi");
                    if (g_bFromUngag[id]) ShowUngagMenu(id);
                    else ShowPlayerMenu(id);
                    return PLUGIN_HANDLED;
                } else {
                    g_MenuTime[id] = iRemainingMins + iTime;
                }
                ShowReasonMenu(id);
                return PLUGIN_HANDLED;
            } else if (iCurrentTime == 0) {
                client_print_color(id, print_team_default, "^4[ GAG ] ^1Bu oyuncu zaten sinirsiz gagli!");
                return PLUGIN_HANDLED;
            }
        } else {
            g_MenuTime[id] = iTime;
            ShowReasonMenu(id);
            return PLUGIN_HANDLED;
        }
    }
    
    if (g_bFromUngag[id]) ShowUngagMenu(id);
    else ShowPlayerMenu(id);
    
    return PLUGIN_HANDLED;
}

public ShowReasonMenu(id) {
    new target = g_MenuTarget[id];
    if (!is_user_connected(target)) return;
    
    new szName[32], szTitle[128];
    get_user_name(target, szName, charsmax(szName));
    formatex(szTitle, charsmax(szTitle), "\d[\r GAG SEBEBI SECIMI \d]^n\y==========================^n\wHedef: \y%s^n", szName);
    
    new menu = menu_create(szTitle, "Handler_ReasonMenu");
    
    menu_additem(menu, "\wKufur / Hakaret", "Kufur / Hakaret");
    menu_additem(menu, "\wSpam / Flood", "Spam / Flood");
    menu_additem(menu, "\wGereksiz Mikrofon", "Gereksiz Mikrofon");
    menu_additem(menu, "\wReklam", "Reklam");
    menu_additem(menu, "\yOzel Sebep", "custom");
    
    menu_setprop(menu, MPROP_EXITNAME, "\dIptal/Geri");
    
    menu_display(id, menu, 0);
}

public Handler_ReasonMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        ShowTimeMenu(id); // Süre seçimine geri dön
        return PLUGIN_HANDLED;
    }
    
    new szData[64], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    if (equal(szData, "custom")) {
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Lutfen chat kisminda sebebi yazin.");
        client_cmd(id, "messagemode custom_gag_reason");
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new target = g_MenuTarget[id];
    new iTime = g_MenuTime[id];
    
    if (is_user_connected(target)) {
        mfgag_set_gag(id, target, iTime, szData);
    }
    
    menu_destroy(menu);
    if (g_bFromUngag[id]) ShowUngagMenu(id);
    else ShowPlayerMenu(id);
    
    return PLUGIN_HANDLED;
}

public cmd_CustomGagReason(id) {
    new szArg[64];
    read_argv(1, szArg, charsmax(szArg));
    
    new target = g_MenuTarget[id];
    new iTime = g_MenuTime[id];
    
    if (is_user_connected(target)) {
        mfgag_set_gag(id, target, iTime, szArg);
    }
    
    if (g_bFromUngag[id]) ShowUngagMenu(id);
    else ShowPlayerMenu(id);
    
    return PLUGIN_HANDLED;
}
