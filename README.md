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
- `scenes/props/player_station.tscn` — 101 sayı içeren taşınabilir masa tableti, tavan askılı animasyonlu sonuç monitörü
- `assets/materials/*.tres` — bütün malzemeler, renkler ve parlaklıklar

**Düzenleme:** Godot'ta ana sahneyi açın. İç içe PackedScene örneklerinin parçalarını düzenlemek için ilgili `.tscn` dosyasını açın veya *Editable Children* kullanın. Koltukların yerini ana sahnede değiştirin, duvar/kubbe parçalarını RoomShell sahnesinde, malzemeleri .tres dosyalarında ayarlayın.

**Kontrol:** Tablete bakıp `E` ile tablet etkileşimine gir. Fiziksel tuşlara tıkla veya klavyeden `0-9` kullan; `Backspace` siler, `Enter` sayıyı kilitler, `Esc` bakış moduna döner. Sonuçlar bitince masadaki tablete bakıp `E` ile yeni tura geçilir.

**Durum:** Sahne geometrileri Godot editöründe düzenlenebilir. Fiziksel tablette yalnızca sayı girişi vardır; açıklamalar, rakiplerin sayıları, hedef hesaplaması, tur sonuçları ve geçiş animasyonları yalnızca masadan ayrı 3D monitörlerde görüntülenir. Eski 2D sayı seçim ve sonuç popup sahneleri artık ana sahneye bağlı değildir.

## Salon simetrisi ve giriş
- Salon kabuğu ana sahnede %16 genişletildi; salon yüksekliği %6 artırıldı.
- `scenes/props/entrance_door.tscn`: eski kürsünün bulunduğu eksende çift kanatlı kapı, gerçek duvar boşluğu ve açık galeri geçidi. Kapı kanatları ayrı `LeftHinge` / `RightHinge` düğümlerinden döndürülebilir.
- 5 oyuncu istasyonu eşit açılarla dizilir ve aynı yüksekliktedir. Her istasyonun arkasında kendi terazisi vardır. Ortada terazi ve hâkim kürsüsü yoktur.

## İlk oynanabilir tur (yerel prototip)

- Oyuncu 1 insan; diğer dört koltukta geçici olarak **0–100 arasında sayı seçen bilgisayar rakipleri** var. Bu aşama gerçek çok oyunculu veya gelişmiş yapay zekâ değildir.
- Her tur hedef sayı: **aktif oyuncuların seçtiği sayıların ortalaması × 0,8**.
- Hedefe en yakın sayı(lar) kazanır; kazanmayan aktif oyuncular **-1 puan** alır. Eşit uzaklıktakiler birlikte kazanır.
- Her oyuncu **10 puanla başlar**. Kaybedilen turlarda **1 puan düşer**. **0 puana düşen elenir** ve sonraki turların hesabına katılmaz.
- Oyun bitince ya da insan oyuncu elenince masa tabletine bakıp **E** ile yeniden başlanabilir.
- 3D salon, dokunmatik terminaller ve sonuç ekranı ayrı, düzenlenebilir Godot sahneleridir.

Sahne: `scenes/props/monitor_blueprint.tscn` — monitörde tur özeti; hesaplama: `scripts/round_rules.gd`.
Test: `godot --headless --path . --script res://tests/test_round_rules.gd` (Godot kurulu makinede).

## Fiziksel ekran akışı

- **Tablet:** 0’dan 100’e kadar **101 sayı, her biri ayrı dokunulabilir seçenek**, seçili sayıyı vurgulama, `TEMIZLE` ve `ONAY`. Tam ekran panel yok.
- **Ayrı monitör:** Yaklaşık **2,04 × 1,19 m**, koyu mavi ışıklı zemin, camgöbeği çerçeve, 5 oyuncunun ayrı sayı alanı, ortalama/hedef hesabı, kazanan/puanlar ve sırayla açıklama animasyonu.
- **Görüntü:** Her istasyonda `ResultTitle`, `ResultBody`, `PlayerReadouts/Player_1..5`, `ResultDetails`, `ResultFooter` ve çerçeve ışıkları Godot editöründe düzenlenebilir.
- Bilgisayar rakipleri şimdilik rastgele sayılar üretir. Görsel dil dramatik, özgün ve uyarlama sahnenin birebir kopyası değildir.

**Tablet seçimi:** `E` ile standart boyutlu tableti eline al ve büyük yakın görünümde fare imlecini aç; 0–100 arasından istediğin sayıya tıkla, `ONAY` ile kilitle. `TEMIZLE` seçimi siler. Klavyeden rakam/Enter alternatif olarak kullanılabilir. Bütün oyun açıklamaları ve sonuç animasyonları sadece büyük 3D monitöre gider.

## Küçük tablet / ele alma görünümü

- Masada tablet **standart yaklaşık 34 × 20 cm boyutundadır**, masanın üzerine yatık durur.
- Oyuncu **E**'ye bastığında aynı 3D tablet yumuşak bir hareketle kameranın önüne gelir; ekranda büyük görünür, fiziksel boyutu değişmez.
- Tablet yakındayken 0–100 sayılarına dokunulabilir. `TEMIZLE` ve `ONAY` çalışır. **Esc** tableti masaya geri bırakır; seçim onaylanınca da otomatik geri döner.
- Ayrı 2D pencere yoktur. Oyun açıklamaları ve sonuçlar tavandan asılı sonuç monitöründe kalır.

Test: `godot --headless --path . --script res://tests/test_tablet_pickup.gd`.

## Referans görsellerindeki monitör düzeni

Monitörün **koyu lacivert teknik ızgaralı zemini**, arkadaki **soluk terazi çizimi**, üstte **5 özgün oyuncu silüeti** ve hemen altında **5 beyaz sayı kutusu** bulunur. Seçimler kutularda sırayla belirir. Ortalama hesaplanırken sayı kutuları **kırmızı dikdörtgen çerçeve** içine alınır. Hedef sayı ortada, alt bölümde ayrı bir beyaz kutuda görünür. Son aşamada kazanan kutusu vurgulanır, puanlar görünür. Tüm bu sahne unsurları `scenes/props/monitor_blueprint.tscn` üzerinden düzenlenebilir; hiçbir açılır panel yoktur.

## Ekran boyutu ve yenileme

- Monitör toplamda %20 küçültüldü (görünen genişlik yaklaşık 2,04 m); beş oyuncu kutusu ve çizimler orantılı kalır; zemin ayağı kaldırılıp tavandan iki askı eklenmiştir.
- Yenileme sırasında akan mavi şerit (`MonitorSweep`) sahneden ve animasyon kodundan çıkarıldı; metinlerin yumuşak belirmesi korundu.

## Başlangıç puanı ve elenme

Tüm beş oyuncu **10 puanla** başlar. Turun kazanan(lar)ı puan kaybetmez; diğerleri 1 puan kaybeder. Puan **0'a ulaştığında** oyuncu elenir, sonraki turlarda seçim yapamaz ve ortalama hesabına katılmaz. Puan 0'ın altına düşmez. Oyun sıfırlanınca herkes yeniden 10 puana döner.

## Ekran animasyon sırası (referans düzeni)

Oyuncular seçimlerini tamamlayınca büyük monitörde şu akış oynatılır: **(1)** Beş sayı tek tek beyaz kutularda açılır, bu aşamada resimler görünmez. **(2)** Kırmızı çerçeve içinde sayıların ortalaması hesaplanıp gösterilir. **(3)** Ortalama × **0,8** işlemi, cevabı henüz görünmeden ekrana gelir. **(4)** Hesaplanan **hedef sayı** işlemin sonucunda belirir. **(5)** Oyuncuların özgün silüetleri sayı kutularının üzerinde açılır ve hedef sayı altta kalır. **(6)** Kazananın resmi ve sayısı kırmızı çerçeveyle birlikte vurgulanır. **(7)** Son adımda bütün oyuncuların **kalan puanları**, doğrudan resimlerin üzerinde görünür; ardından E ile yeni tura geçilebilir. Sahne düzeni `scenes/props/monitor_blueprint.tscn` üzerinden değiştirilebilir. Yeni açılır panel eklenmez.

## Siyah ekran, tur başlığı ve tavana bağlantı

- **Seçim süresince:** Monitör siyah görünür; ortada sadece **DENGE** yazar. Oyuncu sayısı/tur başlığı, 0–100 yönergesi ve tablet için E yazısı **monitörde gösterilmez**.
- **Herkes seçimini tamamlayınca:** Monitörde önce **1. TUR** (ilerleyen turlarda 2. TUR vb.) büyük yazıyla belirir; ardından sayılar sırayla açılır ve ortalama → ×0,8 → hedef → resimler → kazanan → kalan puanlar animasyonu oynar.
- **E etkileşimi:** Sadece masadaki küçük tablete bakınca tabletin üstünde **[E] ETKİLEŞİM** belirir. E ile tablet elde tutulur; Esc ile masaya bırakılır. Tur sonuçlarından sonra da masadaki tablete bakarak E ile devam edilir.
- **Monitör:** Oyuncunun son yükselttiği konum korunmuştur. Artık zemin ayağı yoktur; her oyuncunun monitörü tavan askı çubukları ve üst bağlantı parçalarıyla tavandan asılıdır. Bunlar Godot sahnesinde düzenlenebilir.

## Puan azaldıkça dolan terazi ve elenme animasyonu

Her oyuncunun koltuğu arkasındaki terazinin **oyuncuya yakın sağ kefesi** puan kaybıyla dolmaya başlar: **10 puan = boş**, **9 puan = %10**, **5 puan = %50**, **1 puan = %90**, **0 puan = tam dolu**. Sıvı birikince kefe yavaşça ağırlaşıp alçalır. Puanı ilk kez **0'a ulaşan oyuncunun kefesi devrilir**; ışıklı sıvı oyuncunun başına dökülür, oyuncu koltuğunda yığılır ve görsel olarak oyundan çıkar. Bu, oyun kurallarındaki 0 puanda elenmeyle aynı anda tetiklenen, grafik şiddet içermeyen görsel animasyondur. Sıfırdan yeniden başlatıldığında kefeler boşalır, teraziler eski konumuna gelir ve oyuncular geri döner. Geometri Godot sahnesinde düzenlenebilir; yeni `tests/test_elimination_vfx.gd` test dosyası eklendi.

## Üretilen görsellerin entegrasyonu (8 PNG)

Özgün konsept portreler (5 oyuncu), parlak DENGE logosu, kazananın kırmızı çerçevesi ve eleme sıvı efekti için Godot sahnelerine `Sprite3D` düğümleri eklendi. Resimler `assets/generated/portrait_1.png` … `portrait_5.png`, `denge_logo.png`, `winner_frame.png`, `elimination_splash.png` yollarından otomatik yüklenir. **Görsel paketi ZIP'ini proje köküne açmak gerekir; bu PNG ikili dosyaları GitHub'daki metin bağlayıcısı ile yüklenemedi.** Dosyalar bulunmazsa eski sahne resimleri/efektleriyle oyun çalışır. Ayrıntılar: `assets/generated/README.md`.
