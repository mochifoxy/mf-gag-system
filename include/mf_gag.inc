#if defined _mf_gag_included
  #endinput
#endif
#define _mf_gag_included

#define GAG_TAG "^4[ MochiGAG ] ^1"
#define AUTOGAG_TAG "^4[ Auto MochiGAG ] ^1"

/**
 * Oyuncunun gaglı olup olmadığını kontrol eder.
 *
 * @param id        Oyuncu ID
 * @return          true eğer gaglı ise, false değilse
 */
native bool:mfgag_is_gagged(id);

/**
 * Oyuncuya gag atar.
 *
 * @param admin_id  Gag atan admin (0 ise Server/Sistem)
 * @param target_id Gag atılacak hedef oyuncu
 * @param minutes   Gag süresi (dakika) (0 ise sınırsız)
 * @param reason    Gag sebebi
 * @return          true başarıyla atıldıysa, false atılamadıysa
 */
native bool:mfgag_set_gag(admin_id, target_id, minutes, const reason[], bool:bIsAbsolute = false);

/**
 * Oyuncunun gagını kaldırır.
 *
 * @param admin_id  Gagı kaldıran admin (0 ise Server/Sistem)
 * @param target_id Gagı kaldırılacak oyuncu
 * @return          true başarıyla kaldırıldıysa, false oyuncu gaglı değilse
 */
native bool:mfgag_remove_gag(admin_id, target_id);

/**
 * Kalan gag süresini saniye cinsinden döndürür.
 *
 * @param id        Oyuncu ID
 * @return          Saniye cinsinden kalan süre (0: Sınırsız, -1: Gaglı değil)
 */
native mfgag_get_time(id);

stock argparse(const input[], pos, output[], len) {
    if (pos == -1) return -1;
    new i = pos, outLen = 0;
    while (input[i] == ' ' || input[i] == '^t') i++;
    if (input[i] == '^0') return -1;
    new bool:inQuotes = false;
    if (input[i] == '"') { inQuotes = true; i++; }
    while (input[i] != '^0') {
        if (inQuotes && input[i] == '"') { i++; break; }
        if (!inQuotes && (input[i] == ' ' || input[i] == '^t')) break;
        if (outLen < len) output[outLen++] = input[i];
        i++;
    }
    output[outLen] = '^0';
    while (input[i] == ' ' || input[i] == '^t') i++;
    return (input[i] == '^0') ? -1 : i;
}
