#include <amxmodx>
#include <amxmisc>
#include <mf_gag>

#pragma semicolon 1

#define PLUGIN "MF Gag Cmds"
#define VERSION "1.0"
#define AUTHOR "mochifoxy && FoxyBlinks"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    // Konsol Komutları
    register_concmd("amx_gag", "cmd_gag", ADMIN_KICK, "<nick/userid> <sure dk>");
    register_concmd("amx_ungag", "cmd_ungag", ADMIN_KICK, "<nick/userid>");
    
    // Chat Komutları Yakalayıcı (Gizli komut için en iyi yöntem)
    register_clcmd("say", "cmd_say");
    register_clcmd("say_team", "cmd_say");
}

public cmd_gag(id, level, cid) {
    if (!cmd_access(id, level, cid, 3))
        return PLUGIN_HANDLED;
        
    new szArg1[32], szArg2[32], szArg3[64];
    read_argv(1, szArg1, charsmax(szArg1));
    read_argv(2, szArg2, charsmax(szArg2));
    read_argv(3, szArg3, charsmax(szArg3));
    
    new target = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
    if (!target) return PLUGIN_HANDLED;
    
    new iTime = str_to_num(szArg2);
    if (iTime < 0) iTime = 0;
    
    if (szArg3[0] == '^0') {
        copy(szArg3, charsmax(szArg3), "Belirtilmedi");
    }
    
    mfgag_set_gag(id, target, iTime, szArg3);
    
    return PLUGIN_HANDLED;
}

public cmd_ungag(id, level, cid) {
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;
        
    new szArg1[32];
    read_argv(1, szArg1, charsmax(szArg1));
    
    new target = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF);
    if (!target) return PLUGIN_HANDLED;
    
    if (!mfgag_is_gagged(target)) {
        console_print(id, "Bu oyuncu zaten gagli degil.");
        return PLUGIN_HANDLED;
    }
    
    mfgag_remove_gag(id, target);
    
    return PLUGIN_HANDLED;
}

public cmd_say(id) {
    new szText[128];
    read_args(szText, charsmax(szText));
    remove_quotes(szText);
    
    new szCmd[16], szTarget[32], szTime[32], szReason[64];
    parse(szText, szCmd, charsmax(szCmd), szTarget, charsmax(szTarget), szTime, charsmax(szTime), szReason, charsmax(szReason));
    
    if (equali(szCmd, "/gag")) {
        if (!access(id, ADMIN_KICK)) return PLUGIN_CONTINUE;
        
        if (szTarget[0] == '^0') {
            client_print_color(id, print_team_default, "%sKullanim: ^4/gag ^3<isim> ^1<sure>", GAG_TAG);
            return PLUGIN_HANDLED;
        }
        
        new target = cmd_target(id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
        if (!target) return PLUGIN_HANDLED;
        
        new iTime = str_to_num(szTime);
        if (iTime < 0) iTime = 0;
        
        if (szReason[0] == '^0') {
            copy(szReason, charsmax(szReason), "Belirtilmedi");
        }
        
        mfgag_set_gag(id, target, iTime, szReason);
        return PLUGIN_HANDLED; // Gizle
    }
    else if (equali(szCmd, "/ungag")) {
        if (!access(id, ADMIN_KICK)) return PLUGIN_CONTINUE;
        
        if (szTarget[0] == '^0') {
            client_print_color(id, print_team_default, "%sKullanim: ^4/ungag ^3<isim>", GAG_TAG);
            return PLUGIN_HANDLED;
        }
        
        new target = cmd_target(id, szTarget, CMDTARGET_ALLOW_SELF);
        if (!target) return PLUGIN_HANDLED;
        
        if (!mfgag_is_gagged(target)) {
            client_print_color(id, print_team_default, "%sBu oyuncu zaten gagli degil.", GAG_TAG);
            return PLUGIN_HANDLED;
        }
        
        mfgag_remove_gag(id, target);
        return PLUGIN_HANDLED; // Gizle
    }
    
    return PLUGIN_CONTINUE;
}
