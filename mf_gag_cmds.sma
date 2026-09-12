#include <amxmodx>
#include <amxmisc>
#include <mf_gag>

#pragma semicolon 1

#define PLUGIN "MF Gag Cmds"
#define VERSION "1.5"
#define AUTHOR "mochifoxy && FoxyBlinks"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    // Konsol Komutları
    register_concmd("amx_gag", "cmd_gag", ADMIN_KICK, "<nick/userid> <sure dk>");
    register_concmd("amx_ungag", "cmd_ungag", ADMIN_KICK, "<nick/userid>");
    
    // Ozel Komutlar (Cakisma onlemek icin)
    register_concmd("amx_mgag", "cmd_gag", ADMIN_KICK, "<nick/userid> <sure dk>");
    register_concmd("amx_mungag", "cmd_ungag", ADMIN_KICK, "<nick/userid>");
    
    // Kisaltmalar
    register_concmd("amx_mg", "cmd_gag", ADMIN_KICK, "<nick/userid> <sure dk>");
    register_concmd("amx_mug", "cmd_ungag", ADMIN_KICK, "<nick/userid>");
    
    // Chat Komutları Yakalayıcı (Gizli komut için en iyi yöntem)
    register_clcmd("say", "cmd_say");
    register_clcmd("say_team", "cmd_say");
}

stock bool:is_quote_char(c) {
    return (c == '"' || c == 39 || c == 96 || c == 180 || c == 145 || c == 146);
}

stock clean_param_quotes(szStr[]) {
    trim(szStr);
    remove_quotes(szStr);
    new l = strlen(szStr);
    while (l >= 2 && is_quote_char(szStr[0]) && is_quote_char(szStr[l - 1])) {
        szStr[l - 1] = '^0';
        new i = 0;
        while (szStr[i + 1] != '^0') {
            szStr[i] = szStr[i + 1];
            i++;
        }
        szStr[i] = '^0';
        trim(szStr);
        l = strlen(szStr);
    }
}

public cmd_gag(id, level, cid) {
    if (!cmd_access(id, level, cid, 3))
        return PLUGIN_HANDLED;
        
    new szArg1[32], szArg2[32], szArg3[64];
    read_argv(1, szArg1, charsmax(szArg1));
    read_argv(2, szArg2, charsmax(szArg2));
    read_argv(3, szArg3, charsmax(szArg3));
    
    clean_param_quotes(szArg1);
    clean_param_quotes(szArg2);
    clean_param_quotes(szArg3);
    
    new target = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
    if (!target) return PLUGIN_HANDLED;
    
    new i = 0;
    new bool:bIsNumeric = true;
    while (szArg2[i] != '^0') {
        if (!isdigit(szArg2[i])) {
            bIsNumeric = false;
            break;
        }
        i++;
    }
    
    if (!bIsNumeric || i == 0 || i > 6) {
         console_print(id, "[GAG] Gecersiz sure! Sadece sayi kullanin (Max 999999).");
         return PLUGIN_HANDLED;
    }
    
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
    clean_param_quotes(szArg1);
    
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
    new szText[192];
    read_args(szText, charsmax(szText));
    trim(szText);
    remove_quotes(szText);
    trim(szText);
    
    // Bazi istemciler cift kat tirnak gonderir
    if (szText[0] == '"' && szText[strlen(szText) - 1] == '"') {
        remove_quotes(szText);
        trim(szText);
    }
    
    // Eger komutla baslamiyorsa devam et
    if (szText[0] != '/') return PLUGIN_CONTINUE;
    
    // Escape karakterlerini temizle
    replace_all(szText, charsmax(szText), "\^"", "^"");
    replace_all(szText, charsmax(szText), "\'", "^"");
    
    // Tum tek tirnak, kesme ve aksan varyasyonlarini cift tirnaga normalize et
    for (new i = 0; szText[i] != '^0'; i++) {
        new c = szText[i];
        if (c == 39 || c == 96 || c == 180 || c == 145 || c == 146) {
            szText[i] = '"';
        }
    }
    
    new szCmd[16], szTarget[32], szTime[32], szReason[64];
    new iPos = 0;
    iPos = argparse(szText, iPos, szCmd, charsmax(szCmd));
    if (iPos != -1) iPos = argparse(szText, iPos, szTarget, charsmax(szTarget));
    if (iPos != -1) iPos = argparse(szText, iPos, szTime, charsmax(szTime));
    
    clean_param_quotes(szTarget);
    clean_param_quotes(szTime);
    
    if (iPos != -1) {
        copy(szReason, charsmax(szReason), szText[iPos]);
        clean_param_quotes(szReason);
    } else {
        szReason[0] = '^0';
    }
    
    if (equali(szCmd, "/gag") || equali(szCmd, "/mgag") || equali(szCmd, "/mg")) {
        if (!access(id, ADMIN_KICK)) {
            if (mfgag_is_gagged(id)) {
                return PLUGIN_HANDLED;
            }
            return PLUGIN_CONTINUE;
        }
        
        if (szTarget[0] == '^0') {
            client_print_color(id, print_team_default, "%sKullanim: ^4/gag ^3<isim> ^1<sure>", GAG_TAG);
            return PLUGIN_HANDLED;
        }
        
        new target = cmd_target(id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
        if (!target) return PLUGIN_HANDLED;
        
        if (szTime[0] == '^0') {
            client_print_color(id, print_team_default, "%sLutfen sure belirtin! Kullanim: ^4/gag ^3<isim> ^1<sure>", GAG_TAG);
            return PLUGIN_HANDLED;
        }
        
        new i = 0;
        new bool:bIsNumeric = true;
        while (szTime[i] != '^0') {
            if (!isdigit(szTime[i])) {
                bIsNumeric = false;
                break;
            }
            i++;
        }
        
        if (!bIsNumeric || i == 0 || i > 6) {
             client_print_color(id, print_team_default, "%sGecersiz sure! Maksimum 999999 girebilirsiniz.", GAG_TAG);
             return PLUGIN_HANDLED;
        }
        
        new iTime = str_to_num(szTime);
        if (iTime < 0) iTime = 0;
        
        if (szReason[0] == '^0') {
            copy(szReason, charsmax(szReason), "Belirtilmedi");
        }
        
        mfgag_set_gag(id, target, iTime, szReason);
        return PLUGIN_HANDLED; // Gizle
    }
    else if (equali(szCmd, "/ungag") || equali(szCmd, "/mungag") || equali(szCmd, "/mug")) {
        if (!access(id, ADMIN_KICK)) {
            if (mfgag_is_gagged(id)) {
                return PLUGIN_HANDLED;
            }
            return PLUGIN_CONTINUE;
        }
        
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
