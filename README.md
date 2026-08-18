# KillCount Knox Hostiles

Project Zomboid Build 42.20 Stable icin baslangic modu.

Bu mod su an:

- Vanilla `player:getZombieKills()` verisini HUD'da gosterir.
- `OnCharacterDeath` uzerinden olen karakteri kontrol edip hostile NPC oldurmesini sayar.
- `K` tusu ile HUD ac/kapat yapar.

## Klasor yapisi

Bu klasoru workshop/paketleme oncesi mod klasoru olarak kullan:

- `mod.info`
- `media/lua/shared`
- `media/lua/client`

## Nasil calisiyor

Zombie sayisi Build 42'nin kendi kill sayacindan okunur; bu yuzden zombie oldurmelerinde ek hook'a ihtiyac yok.

Hostile NPC sayisi ise su mantikla bulunur:

1. Olen sey zombie degilse
2. Player degilse
3. `modData` veya method tarafinda `hostile/aggressive/enemy` benzeri bir isaret tasiyorsa
4. Ve olduren local player ise

sayac `hostileNpcKills` olarak artar.

## Knox Survivors / Knox Event icin not

Bu repo icindeki tespit mantigi esnek yazildi ama `Knox Survivors` tarafindaki gercek class, method veya `modData` alanlarini gormeden %100 kesin baglanti diyemem.

En iyi bir sonraki adim:

- Sen bana Knox modunun ilgili Lua dosyalarini ver
- Ben hostile flag'i tam dogru alanlara baglayayim
- Gerekirse oldureni `getAttackedBy()` disinda modun kendi combat kaydindan cekelim

## Kurulum

1. Modu `Zomboid/mods/KillCountKnoxHostiles` altina koy.
2. Oyunda modu aktif et.
3. Yeni veya mevcut save'de gir.
4. `K` ile HUD gorunurlugunu degistir.

## Su anki sinirlar

- SP / local host odakli yazildi.
- Knox tarafi farkli hostile flag isimleri kullaniyorsa NPC kill'i saymayabilir.
- Vehicle veya dolayli oldurmelerde `killer` tespiti modun implementasyonuna gore ek duzeltme isteyebilir.
