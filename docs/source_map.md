# Source and subsystem map

The authoritative machine-readable map is `config/rom_layout.json`. The table
below is an orientation layer; exact ownership is checked from the assembler
listing by `make verify-layout`. `make lint` checks that these broad ranges
cover each layout module exactly once and that the file counts stay current.

| ROM range           | Broad owner                                                                                                     | Files | Confidence               |
| ------------------- | --------------------------------------------------------------------------------------------------------------- | ----: | ------------------------ |
| `0x000000-0x003549` | header, boot, interrupts, rendering primitives, objects, input                                                  |    19 | mixed: static/hypothesis |
| `0x00354A-0x00483F` | math, score, palette, results, and text engines                                                                 |     6 | mixed: static/hypothesis |
| `0x004840-0x009321` | story, planet, credits, and ship sequences                                                                      |     9 | mixed: static/hypothesis |
| `0x009322-0x00C83D` | title/options/password UI, results, and palette assets                                                          |     8 | hypothesis               |
| `0x00C83E-0x00D6D5` | early-stage process states, Flying Neo train flow, Stage 9 transitions, and Terobuster intro effects            |     4 | static/hypothesis        |
| `0x00D6D6-0x010025` | Flying Neo effects, later stage groups, boss transitions, and dispatch helpers                                  |    16 | static/hypothesis        |
| `0x010026-0x010D15` | camera, scroll planes, and tilemap rendering                                                                    |     5 | static/hypothesis        |
| `0x010D16-0x012B69` | DMA, asset transfer, Stage 3 tile resampling, and stage loading/configuration                                   |     9 | static/hypothesis        |
| `0x012B6A-0x013ADD` | debug UI, HUD, and status display                                                                               |     6 | static/hypothesis        |
| `0x013ADE-0x0146FB` | entity, terrain, and combat collision                                                                           |     2 | static/hypothesis        |
| `0x0146FC-0x016F35` | player terrain and state families                                                                               |     9 | hypothesis               |
| `0x016F36-0x0199F3` | player rendering, weapons, projectiles, and weapon UI                                                           |     8 | hypothesis               |
| `0x0199F4-0x01C3F9` | player scripts, stage intros, Seven Forces states, object utilities, and projectile slots                       |     6 | hypothesis               |
| `0x01C3FA-0x01E869` | gameplay entry states, main loop, debug helpers, plane shake, frontend, results, and transitions                |    17 | static/hypothesis        |
| `0x01E86A-0x020249` | cutscenes, stage initialization, menus, and results scrolling                                                   |     5 | hypothesis               |
| `0x02024A-0x023CB9` | results data, credits, selection UI, and floating icons                                                         |     5 | hypothesis               |
| `0x023CBA-0x02A30D` | demo, cutscene, transition, VDP layout, and Valkirie systems                                                    |    10 | hypothesis               |
| `0x02A30E-0x02B6D3` | shared combat helpers, sprite debug tooling, and enemy projectiles                                              |     4 | hypothesis               |
| `0x02B6D4-0x02C253` | Jetsripper combat, weapon-selection UI, resource pickups, and explosion effects                                 |     5 | static/hypothesis        |
| `0x02C254-0x02CB85` | Bugmax debris, shared enemy spawning/movement, and stage actors                                                 |     3 | static/hypothesis        |
| `0x02CB86-0x02D27B` | projectile-attack and ship enemies, shared helpers, and phase/debris states                                     |     3 | static/hypothesis        |
| `0x02D27C-0x02DF7D` | circling and Stage 9 flies, Viblack shots, and bird enemies                                                     |     3 | static/hypothesis        |
| `0x02DF7E-0x02F1A1` | stage 10/12 enemies, Stage 11 fish, and Xi-Tiger entrance sequences                                             |     5 | static/hypothesis        |
| `0x02F1A2-0x030D8F` | orphaned radial-particle test, stage environment, yacht, stage 18, and stage 15 fragment hazards                |     6 | static/runtime           |
| `0x030D90-0x0323E1` | stage 11 rising hazards, type-$390 linked chain, Destroyer Proto, and shared hit-reactive projectiles           |     6 | static/runtime           |
| `0x0323E2-0x033F2F` | Victor, Wolf Garopa rewards, formation waves, Stage 21 asteroids, rising-shot effects, and Missiray projectiles |     8 | static/hypothesis        |
| `0x033F30-0x035613` | Stage 3 orbiting formation, shared metasprite code, and multi-boss metasprite definitions                       |     5 | static/hypothesis        |
| `0x035614-0x0374C5` | Jetsripper and Sniper Honeyviper state, movement, and projectiles                                               |     8 | hypothesis               |
| `0x0374C6-0x0394D7` | Antroid and Terobuster systems                                                                                  |    11 | hypothesis               |
| `0x0394D8-0x03B29D` | Shellshogun and Madam Barbar systems                                                                            |     6 | hypothesis               |
| `0x03B29E-0x03D0AD` | Joker and Flying Neo systems                                                                                    |     5 | hypothesis               |
| `0x03D0AE-0x040CED` | Caterpillar, Xi-Tiger, Deep Strider, Gusthead, and Snake                                                        |    12 | hypothesis               |
| `0x040CEE-0x045ACF` | dormant type-$1C0 family, Sunset Sting, Viblack, and Back Stringer systems                                      |    13 | static/runtime           |
| `0x045AD0-0x04912D` | Epsilon 1 and Sharpssteel systems                                                                               |     9 | hypothesis               |
| `0x04912E-0x04BEBB` | Jampan and Destroyer MK2 systems                                                                                |     7 | hypothesis               |
| `0x04BEBC-0x04DDD1` | Bugmax systems                                                                                                  |     5 | hypothesis               |
| `0x04DDD2-0x050CD3` | Shield Viper and Wolf Garopa systems                                                                            |     8 | hypothesis               |
| `0x050CD4-0x0537A7` | Valkirie transition, Z-Leo, and Valkirie Force                                                                  |     8 | hypothesis               |
| `0x0537A8-0x05575D` | Missiray and Seven Forces projectile/introduction controller                                                    |     9 | hypothesis               |
| `0x05575E-0x057497` | Valkirie battle/rendering and Medusa                                                                            |     3 | hypothesis               |
| `0x057498-0x058FED` | Sirene, Artemis, and an unidentified Seven Force                                                                |     5 | hypothesis               |
| `0x058FEE-0x05A43B` | alternate Valkirie, Sylpheed, and shared Seven Forces metasprite data                                           |     4 | static/hypothesis        |
| `0x05A43C-0x082323` | final entity stub, packed-BCD lookup with opaque tail, and first padding gap                                    |     1 | static                   |
| `0x082324-0x083E6F` | 68k sound driver, playback, and sequence commands                                                               |     7 | static                   |
| `0x083E70-0x084A6F` | embedded Z80 sound program                                                                                      |     1 | static                   |
| `0x084A70-0x085265` | channel playback and sound lookup tables                                                                        |     2 | static                   |
| `0x085266-0x097FFF` | music tracks and sound effects                                                                                  |     3 | static                   |
| `0x098000-0x0E7FFF` | PCM sample banks and second padding gap                                                                         |     1 | static                   |
| `0x0E8000-0x0ED4B3` | frontend, player, enemy, projectile, and boss sprite mappings                                                   |    45 | hypothesis               |
| `0x0ED4B4-0x1412B5` | gameplay tile art, player sprite art, and stage mappings                                                        |     5 | static                   |
| `0x1412B6-0x14AE07` | Japanese font assets                                                                                            |     1 | static                   |
| `0x14AE08-0x17FFFF` | credits scene assets and third padding gap                                                                      |     1 | static                   |
| `0x180000-0x189D37` | message-display pattern templates and frontend scene assets                                                     |     1 | static/hypothesis        |
| `0x189D38-0x18E5D1` | planet, credits, and menu assets                                                                                |     2 | static                   |
| `0x18E5D2-0x1A1025` | stage object art, sprite mappings, and shared asset data                                                        |     5 | static/hypothesis        |
| `0x1A1026-0x1CE4F7` | stage phase and Seven Force cutscene assets                                                                     |    11 | static                   |
| `0x1CE4F8-0x1FFFFF` | late-stage mappings, Stage 3 phase 3 tiles, ROM padding, and final byte                                         |     7 | static                   |

The ranges are intentionally address ordered. A broad owner is not proof that
every routine in that interval belongs to the named subsystem. As analysis
improves, modules may be split and moved between subsystem directories without
changing emitted order or bytes.
