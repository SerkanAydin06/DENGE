# DENGE

Godot 4 ile geliştirilen 3D psikolojik strateji oyunu.

## Godot'ta düzenlenebilir salon

Ana sahne: `scenes/game_room.tscn`

Tüm salon artık Godot sahnelerinde kaydedilmiş gerçek düğümlerden oluşur; çalışma anında dekor üretimi **yoktur**.

- `scenes/room_shell.tscn` — geniş salon, beton döşemeler, 44 duvar paneli, galeri, kubbe, ışık halkaları ve aplikler
- `scenes/center_platform.tscn` — üç katlı simetrik beşgen platform (ortada terazi yok)
- `scenes/props/player_station.tscn` — deri koltuk, açılı masa, yatık dokunmatik ekran, sonuç monitörü
- `scenes/props/balance_scale.tscn` — büyük terazi heykeli (eğim ayarı Inspector'dan)
- `scenes/props/entrance_door.tscn` — çift kanatlı giriş/çıkış kapısı
- `scenes/props/player_station.tscn` — fiziksel 12 tuşlu dokunmatik sayı tableti ve animasyonlu sonuç monitörü
- `assets/materials/*.tres` — bütün malzemeler, renkler ve parlaklıklar

**Düzenleme:** Godot'ta ana sahneyi açın. İç içe PackedScene örneklerinin parçalarını düzenlemek için ilgili `.tscn` dosyasını açın veya *Editable Children* kullanın. Koltukların yerini ana sahnede değiştirin, duvar/kubbe parçalarını RoomShell sahnesinde, malzemeleri .tres dosyalarında ayarlayın.

**Kontrol:** Tablete bakıp `E` ile tablet etkileşimine gir. Fiziksel tuşlara tıkla veya klavyeden `0-9` kullan; `Backspace` siler, `Enter` sayıyı kilitler, `Esc` bakış moduna döner. Sonuçlar bitince `E` ile yeni tura geçilir.

**Durum:** Sahne geometrileri Godot editöründe düzenlenebilir. Fiziksel tablette yalnızca sayı girişi vardır; açıklamalar, rakiplerin sayıları, hedef hesaplaması, tur sonuçları ve geçiş animasyonları yalnızca masadan ayrı 3D monitörlerde görüntülenir. Eski 2D sayı seçim ve sonuç popup sahneleri artık ana sahneye bağlı değildir.

## Salon simetrisi ve giriş
- Salon kabuğu ana sahnede %16 genişletildi; salon yüksekliği %6 artırıldı.
- `scenes/props/entrance_door.tscn`: eski kürsünün bulunduğu eksende çift kanatlı kapı, gerçek duvar boşluğu ve açık galeri geçidi. Kapı kanatları ayrı `LeftHinge` / `RightHinge` düğümlerinden döndürülebilir.
- 5 oyuncu istasyonu eşit açılarla dizilir ve aynı yüksekliktedir. Her istasyonun arkasında kendi terazisi vardır. Ortada terazi ve hâkim kürsüsü yoktur.

## İlk oynanabilir tur (yerel prototip)

- Oyuncu 1 insan; diğer dört koltukta geçici olarak **0–100 arasında rastgele sayı seçen bilgisayar rakipleri** var. Bu aşama gerçek çok oyunculu veya gelişmiş yapay zekâ değildir.
- Her tur hedef sayı: **aktif oyuncuların seçtiği sayıların ortalaması × 0,8**.
- Hedefe en yakın sayı(lar) kazanır; kazanmayan aktif oyuncular **-1 puan** alır. Eşit uzaklıktakiler birlikte kazanır.
- **-10 puan** elenme sınırı. Elenenler sonraki turların hesabına katılmaz.
- Oyun bitince ya da insan oyuncu elenince sonuç ekranından **YENİDEN BAŞLAT** kullanılabilir.
- 3D salon, dokunmatik terminaller ve sonuç ekranı ayrı, düzenlenebilir Godot sahneleridir.

Sahne: `scenes/ui/round_results_ui.tscn` — tur özeti; hesaplama: `scripts/round_rules.gd`.
Test: `godot --headless --path . --script res://tests/test_round_rules.gd` (Godot kurulu makinede).

## Fiziksel ekran akışı

- **Tablet:** 0’dan 100’e kadar **101 sayı, her biri ayrı dokunulabilir seçenek**, seçili sayıyı vurgulama, `TEMIZLE` ve `ONAY`. Tam ekran panel yok.
- **Ayrı monitör:** Yaklaşık **2,55 × 1,49 m**, koyu mavi ışıklı zemin, camgöbeği çerçeve, 5 oyuncunun ayrı sayı alanı, ortalama/hedef hesabı, kazanan/puanlar ve sırayla açıklama animasyonu.
- **Görüntü:** Her istasyonda `ResultTitle`, `ResultBody`, `PlayerReadouts/Player_1..5`, `ResultDetails`, `ResultFooter`, `MonitorSweep` ve çerçeve ışıkları Godot editöründe düzenlenebilir.
- Bilgisayar rakipleri şimdilik rastgele sayılar üretir. Görsel dil dramatik, özgün ve uyarlama sahnenin birebir kopyası değildir.

**Tablet seçimi:** `E` ile standart boyutlu tableti eline al ve büyük yakın görünümde fare imlecini aç; 0–100 arasından istediğin sayıya tıkla, `ONAY` ile kilitle. `TEMIZLE` seçimi siler. Klavyeden rakam/Enter alternatif olarak kullanılabilir. Bütün oyun açıklamaları ve sonuç animasyonları sadece büyük 3D monitöre gider.

## Küçük tablet / ele alma görünümü

- Masada tablet **standart yaklaşık 34 × 20 cm boyutundadır**, masanın üzerine yatık durur.
- Oyuncu **E**'ye bastığında aynı 3D tablet yumuşak bir hareketle kameranın önüne gelir; ekranda büyük görünür, fiziksel boyutu değişmez.
- Tablet yakındayken 0–100 sayılarına dokunulabilir. `TEMIZLE` ve `ONAY` çalışır. **Esc** tableti masaya geri bırakır; seçim onaylanınca da otomatik geri döner.
- Ayrı 2D pencere yoktur. Oyun açıklamaları ve sonuçlar zemine bağlı büyük oyun monitöründe kalır.

Test: `godot --headless --path . --script res://tests/test_tablet_pickup.gd`.
