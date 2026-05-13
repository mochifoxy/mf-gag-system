#include <amxmodx>
#include <amxmisc>
#include <mf_gag>

#pragma semicolon 1

#define PLUGIN "MF Gag Menu"
#define VERSION "1.0"
#define AUTHOR "mochifoxy && FoxyBlinks"

new g_MenuTarget[33];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    register_clcmd("say /gagmenu", "cmd_gagmenu");
    register_clcmd("say_team /gagmenu", "cmd_gagmenu");
    register_clcmd("amx_gagmenu", "cmd_gagmenu");
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
    
    get_players(players, pnum, "ch"); // Botları ve HLTV'yi atla
    
    for (new i = 0; i < pnum; i++) {
        target = players[i];
        
        get_user_name(target, szName, charsmax(szName));
        num_to_str(target, szTargetId, charsmax(szTargetId));
        
        if (mfgag_is_gagged(target)) {
            formatex(szItem, charsmax(szItem), "\w%s \y[Gagli]", szName);
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
    
    if (mfgag_is_gagged(target)) {
        menu_destroy(menu);
        ShowGagActionMenu(id);
    } else {
        // Gaglı değilse süre seçme menüsüne geç
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
    menu_additem(menu, "\wSureyi Duzenle", "2");
    
    menu_setprop(menu, MPROP_EXITNAME, "\dGeri");
    
    menu_display(id, menu, 0);
}

public Handler_GagActionMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        ShowPlayerMenu(id); // Geri dön
        return PLUGIN_HANDLED;
    }
    
    new szData[6], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    new iAction = str_to_num(szData);
    new target = g_MenuTarget[id];
    
    if (!is_user_connected(target)) {
        client_print_color(id, print_team_default, "^4[ GAG ] ^1Oyuncu oyundan ayrilmis.");
        menu_destroy(menu);
        ShowPlayerMenu(id);
        return PLUGIN_HANDLED;
    }
    
    if (iAction == 1) {
        // Gagı Kaldır
        mfgag_remove_gag(id, target);
        menu_destroy(menu);
        ShowPlayerMenu(id);
    } else if (iAction == 2) {
        // Süreyi Düzenle
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
    
    menu_setprop(menu, MPROP_EXITNAME, "\dIptal/Geri");
    
    menu_display(id, menu, 0);
}

public Handler_TimeMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        ShowPlayerMenu(id); // Geri dön
        return PLUGIN_HANDLED;
    }
    
    new szData[6], dummy;
    menu_item_getinfo(menu, item, dummy, szData, charsmax(szData), _, _, dummy);
    
    new iTime = str_to_num(szData);
    new target = g_MenuTarget[id];
    
    if (is_user_connected(target)) {
        mfgag_set_gag(id, target, iTime);
    }
    
    menu_destroy(menu);
    ShowPlayerMenu(id); // Menüyü tekrar aç
    
    return PLUGIN_HANDLED;
}
