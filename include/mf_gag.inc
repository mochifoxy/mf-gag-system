#if defined _mf_gag_included
  #endinput
#endif
#define _mf_gag_included

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
 * @return          true başarıyla atıldıysa, false atılamadıysa
 */
native bool:mfgag_set_gag(admin_id, target_id, minutes);

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
