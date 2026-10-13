# DENGE

Godot 4 ile geliştirilen 3D psikolojik strateji oyunu.

## Godot'ta düzenlenebilir salon

Ana sahne: `scenes/game_room.tscn`

Tüm salon artık Godot sahnelerinde kaydedilmiş gerçek düğümlerden oluşur; çalışma anında dekor üretimi **yoktur**.

- `scenes/room_shell.tscn` — geniş salon, beton döşemeler, 44 duvar paneli, galeri, kubbe, ışık halkaları ve aplikler
- `scenes/center_platform.tscn` — yükseltilmiş basamaklı platform ve ortadaki terazi
- `scenes/props/player_station.tscn` — deri koltuk, açılı masa, yatık dokunmatik ekran, sonuç monitörü
- `scenes/props/balance_scale.tscn` — büyük terazi heykeli (eğim ayarı Inspector'dan)
- `scenes/props/judge_bench.tscn` — hâkim kürsüsü
- `scenes/ui/number_terminal_ui.tscn` — 0–100 sayı düğmeleri ve kilitleme
- `assets/materials/*.tres` — bütün malzemeler, renkler ve parlaklıklar

**Düzenleme:** Godot'ta ana sahneyi açın. İç içe PackedScene örneklerinin parçalarını düzenlemek için ilgili `.tscn` dosyasını açın veya *Editable Children* kullanın. Koltukların yerini ana sahnede değiştirin, duvar/kubbe parçalarını RoomShell sahnesinde, malzemeleri .tres dosyalarında ayarlayın.

**Kontrol:** Fare ile bak; `E` ile koltuğun önündeki sayı terminalini aç; 0–100 arasında sayı seçip kilitle; `Esc` ile kapat.

**Durum:** Bu sahneler yerleşim ve ışıklandırma açısından düzenlenebilir bir 3D prototiptir; filmin hazır 3D varlıklarının birebir kopyası değildir. Terminal seçimi hâlen 2D katman olarak açılır; fiziksel 3D ekran üzerinden doğrudan tıklama sonraki aşamadır.

## Salon simetrisi ve giriş
- Salon kabuğu ana sahnede %16 genişletildi; salon yüksekliği %6 artırıldı.
- `scenes/props/entrance_door.tscn`: eski kürsünün bulunduğu eksende çift kanatlı kapı, gerçek duvar boşluğu ve açık galeri geçidi. Kapı kanatları ayrı `LeftHinge` / `RightHinge` düğümlerinden döndürülebilir.
- 5 oyuncu istasyonu eşit açılarla dizilir ve aynı yüksekliktedir. Her istasyonun arkasında kendi terazisi vardır. Ortada terazi ve hâkim kürsüsü yoktur.
