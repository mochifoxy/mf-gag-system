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
new g_iCurrentPage[33];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    register_clcmd("say /gagmenu", "cmd_gagmenu");
    register_clcmd("say_team /gagmenu", "cmd_gagmenu");
    register_clcmd("amx_gagmenu", "cmd_gagmenu");
    
    register_clcmd("say /ungagmenu", "cmd_ungagmenu");
    register_clcmd("say_team /ungagmenu", "cmd_ungagmenu");
    register_clcmd("amx_ungagmenu", "cmd_ungagmenu");
    
    // Kisayollar
    register_clcmd("say /gm", "cmd_gagmenu");
    register_clcmd("say_team /gm", "cmd_gagmenu");
    register_clcmd("say /ugm", "cmd_ungagmenu");
    register_clcmd("say_team /ugm", "cmd_ungagmenu");
    
    // MochiGag Ozel Komutlari ve Kisaltmalari
    register_clcmd("say /mgagmenu", "cmd_gagmenu");
    register_clcmd("say_team /mgagmenu", "cmd_gagmenu");
    register_clcmd("say /mungagmenu", "cmd_ungagmenu");
    register_clcmd("say_team /mungagmenu", "cmd_ungagmenu");
    
    register_clcmd("say /mgm", "cmd_gagmenu");
    register_clcmd("say_team /mgm", "cmd_gagmenu");
    register_clcmd("say /mugm", "cmd_ungagmenu");
    register_clcmd("say_team /mugm", "cmd_ungagmenu");
    
    register_clcmd("amx_mgagmenu", "cmd_gagmenu");
    register_clcmd("amx_mungagmenu", "cmd_ungagmenu");
    
    register_clcmd("custom_gag_time", "cmd_CustomGagTime");
    register_clcmd("custom_gag_reason", "cmd_CustomGagReason");
}

public client_disconnected(id) {
    g_MenuTarget[id] = 0;
    g_bFromUngag[id] = false;
    g_MenuTime[id] = 0;
    g_bIsShortening[id] = false;
    g_iCurrentPage[id] = 0;
}

public cmd_gagmenu(id) {
    if (!access(id, ADMIN_KICK)) {
        client_print_color(id, print_team_default, "%sBu komutu kullanmaya yetkiniz yok.", GAG_TAG);
        return PLUGIN_HANDLED;
    }
    
    g_iCurrentPage[id] = 0; // Komutla acildiginda ilk sayfadan basla
    ShowPlayerMenu(id);
    return PLUGIN_HANDLED; // Komutu chatten gizle
}

public ShowPlayerMenu(id) {
    new menu = menu_create("\r* [Mochi] \yGAG YONETIM PANELI \r*^n\d--------------------------", "Handler_PlayerMenu");
    
    new players[32], pnum, target;
    new szName[32], szTargetId[10], szItem[128];
    
    get_players(players, pnum, "h"); // HLTV'yi atla
    
    for (new i = 0; i < pnum; i++) {
        target = players[i];
        
        get_user_name(target, szName, charsmax(szName));
        num_to_str(target, szTargetId, charsmax(szTargetId));
        
        // Takim Tagı
        new iTeam = get_user_team(target);
        new szTeamTag[16];
        if (iTeam == 1) copy(szTeamTag, charsmax(szTeamTag), "\r[T] ");
        else if (iTeam == 2) copy(szTeamTag, charsmax(szTeamTag), "\y[CT] ");
        else copy(szTeamTag, charsmax(szTeamTag), "\d[Spec] ");
        
        // Kendini belirleme
        new szSen[16];
        if (target == id) copy(szSen, charsmax(szSen), " \y[SEN]");
        
        // Gag Durumu
        new szStatus[48];
        if (mfgag_is_gagged(target)) {
            new iRemaining = mfgag_get_time(target);
            if (iRemaining > 0) {
                new iMins = iRemaining / 60;
                if (iMins < 1) iMins = 1;
                formatex(szStatus, charsmax(szStatus), " \r[Gagli - %d Dk]", iMins);
            } else if (iRemaining == 0) {
                formatex(szStatus, charsmax(szStatus), " \r[Gagli - Sinirsiz]");
            } else {
                formatex(szStatus, charsmax(szStatus), " \r[Gagli]");
            }
        }
        
        formatex(szItem, charsmax(szItem), "\y-> %s\w%s%s%s", szTeamTag, szName, szSen, szStatus);
        menu_additem(menu, szItem, szTargetId);
    }
    
    menu_setprop(menu, MPROP_BACKNAME, "\wGeri");
    menu_setprop(menu, MPROP_NEXTNAME, "\wIleri");
    menu_setprop(menu, MPROP_EXITNAME, "\rCikis");
    
    menu_display(id, menu, g_iCurrentPage[id]);
}

public Handler_PlayerMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        g_MenuTarget[id] = 0; // Hedefi unuttur
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    if (item == MENU_BACK || item == MENU_MORE) {
        return PLUGIN_CONTINUE;
    }
    
    new szData[6], dummy, iPage;
    player_menu_info(id, dummy, iPage);
    g_iCurrentPage[id] = iPage; // Sayfayi kaydet
    
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    new target = str_to_num(szData);
    
    if (!is_user_connected(target)) {
        client_print_color(id, print_team_default, "%sOyuncu oyundan ayrilmis.", GAG_TAG);
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
        menu_destroy(menu);
        ShowGagTimeMenu(id);
    }
    
    return PLUGIN_HANDLED;
}

public ShowGagActionMenu(id) {
    new target = g_MenuTarget[id];
    if (!is_user_connected(target)) return;
    
    new szName[32], szTitle[128];
    get_user_name(target, szName, charsmax(szName));
    formatex(szTitle, charsmax(szTitle), "\r* [Mochi] \yGAG ISLEMLERI \r*^n\d--------------------------^n\wOyuncu: \y%s", szName);
    
    new menu = menu_create(szTitle, "Handler_GagActionMenu");
    
    menu_additem(menu, "\y-> \wGagi Kaldir", "1");
    menu_additem(menu, "\y-> \wGag Suresini Uzat", "2");
    menu_additem(menu, "\y-> \wGag Suresini Kisalt", "3");
    
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
        client_print_color(id, print_team_default, "%sOyuncu oyundan ayrilmis.", GAG_TAG);
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
        menu_destroy(menu);
        ShowExtendMenu(id);
    } else if (iAction == 3) {
        // Gagı Kısalt
        menu_destroy(menu);
        ShowShortenMenu(id);
    }
    
    return PLUGIN_HANDLED;
}

public ShowGagTimeMenu(id) {
    new target = g_MenuTarget[id];
    if (!is_user_connected(target)) return;
    
    new szName[32], szTitle[128];
    get_user_name(target, szName, charsmax(szName));
    
    formatex(szTitle, charsmax(szTitle), "\r* [Mochi] \yGAG SURESI \r*^n\d--------------------------^n\wHedef: \y%s", szName);
    
    new menu = menu_create(szTitle, "Handler_GagTimeMenu");
    
    menu_additem(menu, "\y-> \w1 Dakika", "1");
    menu_additem(menu, "\y-> \w5 Dakika", "5");
    menu_additem(menu, "\y-> \w10 Dakika", "10");
    menu_additem(menu, "\y-> \w20 Dakika", "20");
    menu_additem(menu, "\y-> \w30 Dakika", "30");
    menu_additem(menu, "\y-> \w60 Dakika", "60");
    menu_additem(menu, "\y-> \rSinirsiz", "0");
    menu_additem(menu, "\y-> \yOzel Sure", "custom");
    
    menu_setprop(menu, MPROP_BACKNAME, "\wGeri");
    menu_setprop(menu, MPROP_NEXTNAME, "\wIleri");
    menu_setprop(menu, MPROP_EXITNAME, "\dIptal/Geri");
    
    menu_display(id, menu, 0);
}

public Handler_GagTimeMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        ShowPlayerMenu(id);
        return PLUGIN_HANDLED;
    }
    
    if (item == MENU_BACK || item == MENU_MORE) {
        return PLUGIN_CONTINUE;
    }
    
    new szData[10], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    if (equal(szData, "custom")) {
        client_print_color(id, print_team_default, "%sLutfen chat kisminda sureyi (dakika) yazin.", GAG_TAG);
        g_bIsShortening[id] = false;
        client_cmd(id, "messagemode custom_gag_time");
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new iTime = str_to_num(szData);
    g_MenuTime[id] = iTime;
    
    menu_destroy(menu);
    ShowReasonMenu(id);
    
    return PLUGIN_HANDLED;
}

public ShowExtendMenu(id) {
    new target = g_MenuTarget[id];
    if (!is_user_connected(target)) return;
    
    new szName[32], szTitle[128];
    get_user_name(target, szName, charsmax(szName));
    
    formatex(szTitle, charsmax(szTitle), "\r* [Mochi] \ySURE UZATMA \r*^n\d--------------------------^n\wHedef: \y%s", szName);
    
    new menu = menu_create(szTitle, "Handler_ExtendMenu");
    
    menu_additem(menu, "\y-> \w1 Dakika", "1");
    menu_additem(menu, "\y-> \w5 Dakika", "5");
    menu_additem(menu, "\y-> \w10 Dakika", "10");
    menu_additem(menu, "\y-> \w20 Dakika", "20");
    menu_additem(menu, "\y-> \w30 Dakika", "30");
    menu_additem(menu, "\y-> \w60 Dakika", "60");
    menu_additem(menu, "\y-> \rSinirsiz", "0");
    menu_additem(menu, "\y-> \yOzel Sure", "custom");
    
    menu_setprop(menu, MPROP_BACKNAME, "\wGeri");
    menu_setprop(menu, MPROP_NEXTNAME, "\wIleri");
    menu_setprop(menu, MPROP_EXITNAME, "\dIptal/Geri");
    
    menu_display(id, menu, 0);
}

public Handler_ExtendMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        ShowGagActionMenu(id);
        return PLUGIN_HANDLED;
    }
    
    if (item == MENU_BACK || item == MENU_MORE) {
        return PLUGIN_CONTINUE;
    }
    
    new szData[10], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    new target = g_MenuTarget[id];
    if (!is_user_connected(target)) {
        client_print_color(id, print_team_default, "%sOyuncu oyundan ayrilmis.", GAG_TAG);
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    if (equal(szData, "custom")) {
        client_print_color(id, print_team_default, "%sLutfen chat kisminda sureyi (dakika) yazin.", GAG_TAG);
        g_bIsShortening[id] = false;
        client_cmd(id, "messagemode custom_gag_time");
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new iTime = str_to_num(szData);
    new iCurrentTime = mfgag_get_time(target);
    new iRemainingMins = iCurrentTime / 60;
    
    if (iTime == 0) {
        mfgag_set_gag(id, target, 0, "Sure Uzatildi");
    } else {
        mfgag_set_gag(id, target, iRemainingMins + iTime, "Sure Uzatildi");
    }
    
    menu_destroy(menu);
    if (g_bFromUngag[id]) ShowUngagMenu(id);
    else ShowPlayerMenu(id);
    
    return PLUGIN_HANDLED;
}

public ShowShortenMenu(id) {
    new target = g_MenuTarget[id];
    if (!is_user_connected(target)) return;
    
    new szName[32], szTitle[128];
    get_user_name(target, szName, charsmax(szName));
    
    formatex(szTitle, charsmax(szTitle), "\r* [Mochi] \ySURE KISALTMA \r*^n\d--------------------------^n\wHedef: \y%s", szName);
    
    new menu = menu_create(szTitle, "Handler_ShortenMenu");
    
    menu_additem(menu, "\y-> \w1 Dakika", "1");
    menu_additem(menu, "\y-> \w5 Dakika", "5");
    menu_additem(menu, "\y-> \w10 Dakika", "10");
    menu_additem(menu, "\y-> \w20 Dakika", "20");
    menu_additem(menu, "\y-> \w30 Dakika", "30");
    menu_additem(menu, "\y-> \w60 Dakika", "60");
    menu_additem(menu, "\y-> \yOzel Sure", "custom");
    
    menu_setprop(menu, MPROP_BACKNAME, "\wGeri");
    menu_setprop(menu, MPROP_NEXTNAME, "\wIleri");
    menu_setprop(menu, MPROP_EXITNAME, "\dIptal/Geri");
    
    menu_display(id, menu, 0);
}

public Handler_ShortenMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        ShowGagActionMenu(id);
        return PLUGIN_HANDLED;
    }
    
    if (item == MENU_BACK || item == MENU_MORE) {
        return PLUGIN_CONTINUE;
    }
    
    new szData[10], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    new target = g_MenuTarget[id];
    if (!is_user_connected(target)) {
        client_print_color(id, print_team_default, "%sOyuncu oyundan ayrilmis.", GAG_TAG);
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    if (equal(szData, "custom")) {
        client_print_color(id, print_team_default, "%sLutfen chat kisminda sureyi (dakika) yazin.", GAG_TAG);
        g_bIsShortening[id] = true;
        client_cmd(id, "messagemode custom_gag_time");
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new iTime = str_to_num(szData);
    new iCurrentTime = mfgag_get_time(target);
    new iRemainingMins = iCurrentTime / 60;
    
    new iNewMins = iRemainingMins - iTime;
    if (iNewMins <= 0) {
        mfgag_remove_gag(id, target);
    } else {
        mfgag_set_gag(id, target, iNewMins, "Sure Kisaltildi");
    }
    
    menu_destroy(menu);
    if (g_bFromUngag[id]) ShowUngagMenu(id);
    else ShowPlayerMenu(id);
    
    return PLUGIN_HANDLED;
}

public cmd_ungagmenu(id) {
    if (!access(id, ADMIN_KICK)) {
        client_print_color(id, print_team_default, "%sBu komutu kullanmaya yetkiniz yok.", GAG_TAG);
        return PLUGIN_HANDLED;
    }
    
    ShowUngagMenu(id);
    return PLUGIN_HANDLED;
}

public ShowUngagMenu(id) {
    new menu = menu_create("\r* [Mochi] \yUNGAG YONETIM PANELI \r*^n\d--------------------------", "Handler_UngagMenu");
    
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
        client_print_color(id, print_team_default, "%sSu anda gagli oyuncu bulunmuyor.", GAG_TAG);
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
    
    if (item == MENU_BACK || item == MENU_MORE) {
        return PLUGIN_CONTINUE;
    }
    
    new szData[6], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    new target = str_to_num(szData);
    
    if (!is_user_connected(target)) {
        client_print_color(id, print_team_default, "%sOyuncu oyundan ayrilmis.", GAG_TAG);
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
    if (!access(id, ADMIN_KICK) || g_MenuTarget[id] == 0) {
        return PLUGIN_HANDLED;
    }
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
        client_print_color(id, print_team_default, "%sGecersiz sure girdiniz! Lutfen sadece sayi girin.", GAG_TAG);
        if (g_bFromUngag[id]) ShowUngagMenu(id);
        else ShowPlayerMenu(id);
        return PLUGIN_HANDLED;
    }
    
    new iTime = str_to_num(szArg);
    new target = g_MenuTarget[id];
    
    if (g_bIsShortening[id] && iTime == 0) {
        client_print_color(id, print_team_default, "%sSure kisaltirken 0 (Sinirsiz) giremezsiniz!", GAG_TAG);
        return PLUGIN_HANDLED;
    }
    
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
                    new iNewMins = iRemainingMins + iTime;
                    mfgag_set_gag(id, target, iNewMins, "Sure Uzatildi");
                    if (g_bFromUngag[id]) ShowUngagMenu(id);
                    else ShowPlayerMenu(id);
                    return PLUGIN_HANDLED;
                }
            } else if (iCurrentTime == 0) {
                client_print_color(id, print_team_default, "%sBu oyuncu zaten sinirsiz gagli!", GAG_TAG);
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
    
    new iTime = g_MenuTime[id];
    if (iTime == 0) {
        formatex(szTitle, charsmax(szTitle), "\r* [Mochi] \yGAG SEBEBI \r*^n\d--------------------------^n\wHedef: \y%s^n\wSure: \rSINIRSIZ", szName);
    } else {
        formatex(szTitle, charsmax(szTitle), "\r* [Mochi] \yGAG SEBEBI \r*^n\d--------------------------^n\wHedef: \y%s^n\wSure: \y%d Dakika", szName, iTime);
    }
    
    new menu = menu_create(szTitle, "Handler_ReasonMenu");
    
    menu_additem(menu, "\y-> \wKufur / Hakaret", "Kufur / Hakaret");
    menu_additem(menu, "\y-> \wSpam / Flood", "Spam / Flood");
    menu_additem(menu, "\y-> \wGereksiz Mikrofon", "Gereksiz Mikrofon");
    menu_additem(menu, "\y-> \wReklam", "Reklam");
    menu_additem(menu, "\y-> \yOzel Sebep", "custom");
    
    menu_setprop(menu, MPROP_EXITNAME, "\dIptal/Geri");
    
    menu_display(id, menu, 0);
}

public Handler_ReasonMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        ShowGagTimeMenu(id);
        return PLUGIN_HANDLED;
    }
    
    new szData[64], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    if (equal(szData, "custom")) {
        client_print_color(id, print_team_default, "%sLutfen chat kisminda sebebi yazin.", GAG_TAG);
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
    if (!access(id, ADMIN_KICK) || g_MenuTarget[id] == 0) {
        return PLUGIN_HANDLED;
    }
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
