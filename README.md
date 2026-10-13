# DENGE

Godot 4 ile geliştirilen 3D psikolojik strateji oyunu.

## Açılış
1. Godot 4.3 veya üzerini açın.
2. Bu depoyu indirin/klonlayın ve `project.godot` dosyasını içe aktarın.
3. F6 veya F5 ile `GameRoom` sahnesini çalıştırın.

## Mevcut sürüm
- Mahkeme salonu tarzında geniş dairesel salon: kubbe, galeri, hakim kürsüsü, terazi heykelleri
- Beşgen düzende 5 açılı masa; her oyuncuya sayı girişi ekranı ve kendine özel sonuç monitörü
- Oyuncu 1 bakış açısı, fare ile bakma, [E] ile sayı terminali

## Grafik geliştirme
Prosedürel parçalar yer tutucudur. `assets/models/<slot>.tscn` eklenince ilgili parça otomatik değişir
(slotlar: player_chair, player_desk, touch_console, result_monitor, host_bench, gallery_section).
`assets/materials/<ad>.tres` ile malzemeler değiştirilebilir (adlar: `scripts/room_materials.gd`).
