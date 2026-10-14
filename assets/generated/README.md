# DENGE – üretilen görsel paket (8 PNG)

Bu klasörün resim dosyaları, ChatGPT tarafından hazırlanan **DENGE_asset_pack.zip** içindedir. GitHub bağlayıcısının metin-dosyası yazma sınırı nedeniyle PNG ikili dosyaları bu commit ile yüklenemedi.

Zip içindeki `assets/generated/` klasörünü **Godot proje köküne** çıkarın. Böylece aşağıdaki dosyalar burada bulunacak:

| Dosya | Oyun içindeki yeri |
|---|---|
| `portrait_1.png` … `portrait_5.png` | 3D sonuç monitöründeki 5 oyuncu kartı; PHOTO, WIN ve SCORE aşamaları |
| `denge_logo.png` | Herkes seçim yaparken siyah monitör ekranındaki DENGE logosu |
| `winner_frame.png` | Kazananın resmini ve sayı kutusunu kapsayan kırmızı çerçeve |
| `elimination_splash.png` | 0 puandaki oyuncunun üzerine sıvı dökülme/elenme görsel efekti |

Sahnedeki `Sprite3D` düğümleri halihazırda GitHub'dadır; `scripts/player_station.gd::_load_generated_art()` bu PNG'leri **varsa** otomatik yükler. Dosyalar eksikse oyun eski silüetleri, metin logosunu ve küresel eleme efektini kullanır; sahne kırılmaz.

**Not:** Portreler özgün konsept çizimleridir, mevcut beş Meshy .glb karakter modelinin birebir render görüntüleri değildir. Gerçek 3D model kimliğiyle tam uyum için ileride bu dosyalar oyuncu modellerinin Godot kamera renderlarıyla değiştirilebilir.

Godot otomatik içe aktarmayı tamamlayana kadar kısa süre bekleyin; daha sonra `scenes/game_room.tscn` dosyasını çalıştırın. İlgili sahne dosyalarında modellerin yeri ve kullanıcının son düzenlediği dönüşümler değiştirilmemiştir.
