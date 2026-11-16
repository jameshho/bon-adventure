# Word audit

*(7 Nov 2026: `docs/word_audit.gd` was replaced by `tools/vocabulary_report.gd`, which
adds placement per building and site, the games that test or show each word, phrase slots
and an unknown-key check; see the
[guide](../guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-usage-report) and the
[current result](../guides/vocabulary-report/summary.md). This page keeps the dated audit results and
word decisions below.)*

## Current result — 28 October 2026, after the word clean-up

**486 words in 19 categories (464 at the audit; pizza, hamburger, french fries, wine and soda added 28 October 2026 for the new restaurants; skis, ski poles, snowboard, ski boots, gloves, winter hat, ski goggles and sled added for the sports store's winter department, same day; passport, boarding pass, suitcase, luggage cart, check-in counter, metal detector and flight board (new Travel category) plus airport and baggage claim for the airport terminal, same day); every word is clickable somewhere in town** (2,491
clickable objects). No object uses an unknown word, no two words share a Spanish
translation, and no word appears in both singular and plural.

| Category | Words (all placed) |
| --- | ---: |
| Food & Drink | 58 |
| Kitchen & Dining | 19 |
| Furniture | 27 |
| Around the House | 17 |
| Electronics & Appliances | 29 |
| Places & Rooms | 33 |
| Building Parts | 22 |
| Streets & Town | 17 |
| Vehicles | 17 |
| Shopping & Money | 26 |
| School & Arts | 39 |
| Health & Body | 53 |
| Clothing | 21 |
| Sports & Play | 15 |
| People | 13 |
| Animals | 20 |
| Nature | 25 |
| Time & Directions | 13 |

Informational only: 18 everyday words are clickable in six or more areas (road 14,
parking 13, floor and lamp 9, chair 8, shrub 131 objects…). That is expected for a
reference; they make the By Area lists longer, not wrong.

## Decisions applied (user, 28 October 2026)

The first audit found 534 words, 83 with nothing to click, 5 shared translations and
one singular/plural pair. The user decided:

- **Home:** tag the sink tap as *faucet* and the oven front as *oven*. Cabinet handles
  become part of the kitchen cabinetry. Add *frying pan, cup, salt, pepper, oil, tea,
  juice* to the kitchen and *towel, toothbrush, toilet paper, shampoo, perfume* to
  each bathroom. Room plaques for *bedroom, bathroom, living room, kitchen, garage*;
  post signs for *yard* and *garden*. *Olive oil* became *oil* (el aceite).
- **Deleted words:** *hallway, pantry, house*, the other unplaced kitchen,
  bathroom and household words, the duplicates (*monitor, patient bed, parking stall,
  note*) and the general words (*appliances, clinic, magazine, calendar, shopping
  list, fountain, grass, man*). 293 leftover tags of those words were stripped from
  saved scenes; those objects stay only as decoration. The hospital mission now
  asks for *medical monitor*.
- **Shared Spanish:** *mug, cubby, locker, rack, coat rack, clothes rack, carpet, rug*
  were deleted **with their objects** (listed in `removed_with_objects`; the game
  removes them at load). *Cup* stays. *Bank* and *bench* stay, labelled
  "el banco (dinero)" / "el banco (asiento)".
- **Singular/plural:** *shoe* deleted; its objects now teach *shoes*.
- **Body parts:** taught only by the hospital anatomy model. People and mascot pigs
  now teach their job or *pig* wherever they are clicked.
- **Trees and clouds:** every tree crown has a flat, clickable platform you can land
  on; clouds keep their platform collision and *cloud* word.

## One Mexican translation per word — 28 October 2026

At the user's request every word now has **one primary translation in everyday
Mexican Spanish** at A2/B1 level. Only `data/words.json` changed (Spanish values;
keys, aliases, categories, `prefab_size` and notes are untouched, so saves, scenes
and quests are unaffected). The game never splits the string on ` / `: the HUD,
journal and quests print and compare the whole value, so no code change was needed.
`docs/evidence/town-checks/check_vocabulary_translations.py` now fails on an extra alternative, and on two
English words sharing one Spanish translation.

**Kept as two forms:** the gendered person pairs (*cashier, child, cook, doctor,
driver, firefighter, nurse, police officer, student, teacher, waiter*) and
*fish* = `el pez (animal) / el pescado (comida)`, which are two meanings, not
regional variants.

### Alternatives removed (83 words)

| English | Before | Now |
| --- | --- | --- |
| avocado | el aguacate / la palta | **el aguacate** |
| banana | la banana / el plátano | **el plátano** |
| beans | los frijoles / los porotos | **los frijoles** |
| cake | el pastel / la torta | **el pastel** |
| cereal | el cereal / los cereales | **el cereal** |
| chili pepper | el chile / el ají | **el chile** |
| corn | el maíz / el elote | **el maíz** |
| croissant | el croissant / el cruasán | **el croissant** |
| cupcake | el cupcake / el pastelito | **el cupcake** |
| donut | la dona / el dónut | **la dona** |
| food | la comida / los alimentos | **la comida** |
| lime | el limón verde / la lima | **el limón verde** |
| lunch | el almuerzo / la comida (del mediodía) | **el almuerzo** |
| menu | el menú / la carta | **el menú** |
| potato | la papa / la patata | **la papa** |
| snack | el refrigerio / la botana | **la botana** |
| steak | el bistec / el filete de res | **el bistec** |
| bowl | el tazón / el bol | **el tazón** |
| jar | el frasco / el tarro | **el frasco** |
| whisk | el batidor de globo / el batidor manual | **el batidor de globo** |
| bookshelf | el librero / la estantería | **el estante para libros** |
| cabinet | el gabinete de cocina / el armario | **el gabinete** |
| nightstand | la mesita de noche / la mesa de noche | **la mesita de noche** |
| wardrobe | el ropero / el armario | **el ropero** |
| basket | la canasta / la cesta | **la canasta** |
| hanger | el gancho para ropa / la percha | **el gancho para ropa** |
| computer | la computadora / el computador | **la computadora** |
| electronics | los aparatos electrónicos / la electrónica | **los aparatos electrónicos** |
| game controller | el control de videojuegos / el mando de videojuegos | **el control de videojuegos** |
| headphones | los audífonos / los auriculares | **los audífonos** |
| laptop | la computadora portátil / la laptop | **la laptop** |
| mouse | el mouse / el ratón | **el mouse** |
| phone | el teléfono / el celular | **el teléfono** |
| refrigerator | el refrigerador / la nevera / la heladera | **el refrigerador** |
| smartphone | el teléfono inteligente / el celular inteligente | **el celular** |
| speaker | el parlante / la bocina / el altavoz | **la bocina** |
| stove | la estufa / la cocina | **la estufa** |
| bedroom | el dormitorio / la habitación | **la recámara** |
| electronics store | la tienda de artículos electrónicos / la tienda de electrónica | **la tienda de electrónica** |
| living room | la sala / la sala de estar | **la sala** |
| main hall | el vestíbulo principal / el salón principal | **el vestíbulo principal** |
| police station | la estación de policía / la comisaría | **la estación de policía** |
| swimming pool | la alberca / la piscina | **la alberca** |
| ceiling | el techo interior / el cielo raso | **el techo interior** |
| counter | la cubierta de cocina / la encimera | **la cubierta de cocina** |
| faucet | la llave de agua / el grifo | **la llave de agua** |
| fence | la cerca / la valla | **la cerca** |
| floor | el piso / el suelo | **el piso** |
| gate | el portón / la puerta de la cerca | **el portón** |
| sink | el fregadero / la pileta de cocina | **el fregadero** |
| tile | la baldosa / el azulejo | **el azulejo** |
| crosswalk | el cruce peatonal / el paso de peatones | **el cruce peatonal** |
| curb | el borde de la acera / el bordillo | **el borde de la banqueta** |
| driveway | la entrada para autos / la entrada de vehículos | **la entrada para carros** |
| sidewalk | la acera / la banqueta / la vereda | **la banqueta** |
| streetlight | el poste de alumbrado / la farola | **el poste de luz** |
| bus | el autobús / el bus | **el autobús** |
| car | el auto / el carro / el coche | **el carro** |
| motorcycle | la motocicleta / la moto | **la moto** |
| police car | la patrulla / el auto de policía | **la patrulla** |
| school bus | el autobús escolar / el bus escolar | **el autobús escolar** |
| tire | la llanta / el neumático | **la llanta** |
| checkout counter | el mostrador de pago / la caja | **la caja** |
| deli counter | el mostrador de embutidos / el mostrador de fiambres | **el mostrador de carnes frías** |
| shopping cart | el carrito de compras / el carrito del supermercado | **el carrito de compras** |
| ticket | el boleto / el tiquete | **el boleto** |
| whiteboard | el pizarrón blanco / la pizarra blanca | **el pizarrón blanco** |
| examination bed | la camilla de examen / la camilla de exploración | **la camilla de examen** |
| oxygen tank | el tanque de oxígeno / el cilindro de oxígeno | **el tanque de oxígeno** |
| patient chart | el expediente médico / la historia clínica | **el expediente médico** |
| jeans | los jeans / los pantalones de mezclilla | **los jeans** |
| shorts | los pantalones cortos / los shorts | **los shorts** |
| sneakers | los tenis / las zapatillas deportivas | **los tenis** |
| sunglasses | los lentes de sol / las gafas de sol | **los lentes de sol** |
| sweater | el suéter / el jersey | **el suéter** |
| goal | el arco / la portería | **la portería** |
| play tent | la carpa de juegos / la tienda de campaña para jugar | **la carpa de juegos** |
| sandbox | el arenero / la caja de arena | **el arenero** |
| skateboard | la patineta / el monopatín | **la patineta** |
| slide | el tobogán / la resbaladilla | **la resbaladilla** |
| hedge | el cerco vivo / el seto | **la cerca viva** |
| later | más tarde / luego | **más tarde** |
| straight ahead | todo recto / de frente | **todo derecho** |

### Single translations corrected for Mexican usage or accuracy (14 words)

| English | Before | Now |
| --- | --- | --- |
| blanket | la manta | **la cobija** |
| tablet | la tableta | **la tablet** |
| television | el televisor | **la televisión** |
| classroom | el aula | **el salón de clases** |
| bathtub | la bañera | **la tina** |
| handle | el tirador | **la manija** |
| bulletin board | el tablón de anuncios | **el tablero de avisos** |
| clipboard | el portapapeles | **la tablilla con sujetapapeles** |
| bed rail | la barandilla de cama | **el barandal de la cama** |
| blood pressure monitor | el tensiómetro | **el baumanómetro** |
| handbag | el bolso | **la bolsa de mano** |
| jacket | la chaqueta | **la chamarra** |
| basketball | el balón de baloncesto | **el balón de basquetbol** |
| basketball hoop | la canasta de baloncesto | **la canasta de basquetbol** |

### Flagged for review (judgment calls)

- **lime / lemon:** in Mexico *limón* is the lime. *lemon* keeps `el limón` and *lime*
  became `el limón verde` so the two stay distinct (Mexicans would say *limón
  amarillo* for a lemon).
- **lunch:** `el almuerzo`, not Mexico's mid-afternoon *la comida*, which would
  duplicate *food*.
- **corn:** `el maíz` kept; `el elote` is the corn on the cob Mexicans usually mean.
- **tomato:** `el tomate` kept; central Mexico says *jitomate* and *tomate* means a
  different (green) fruit there, but the region split makes *tomate* the safer teaching word.
- **bus / truck:** Mexicans often say *el camión* for a city bus; `el autobús` kept
  because *truck* is already `el camión`.
- **car:** `el carro` (also *coche*, *auto* are heard); *driveway* follows it.
- **glass:** `el vidrio` kept because the key tags window panes, the bank teller
  glass and drinking glasses; `el vaso` would be wrong for the panes. Splitting it
  into *glass* and *window glass* is a vocabulary change left for the user.
- **bookshelf / bookcase:** both were `el librero`. *bookshelf* is now
  `el estante para libros`; recommend merging one into an alias.
- **ceiling:** `el techo interior` kept so it differs from *roof* (`el techo`);
  Mexican builders also say *el plafón*.
- **cabinet:** `el gabinete` (the old "de cocina" was wrong for the school and console cabinets).
- **bedroom:** `la recámara` (Mexican); the room signs (`data/sign_translations.json`)
  still print *DORMITORIO* and *AULA*, and *classroom* is now `el salón de clases`.
  Signs are not vocabulary and were not changed; align them if wanted.
- **clipboard:** `la tablilla con sujetapapeles`; *portapapeles* is the computer term.
- **tile / counter / hedge / deli counter / play tent:** best Mexican fit but less
  common words; confirm with a native speaker.
- **straight ahead:** `todo derecho`; the old options (*todo recto*, *de frente*)
  are Spain / uncommon. `docs/evidence/town-checks/TRANSPORT_NAV_TIME_ADDITIONS.json` is a historical
  manifest and still shows the old text.

### Authoring scripts

`tools/expand_civic_wings.py` and `tools/build_learning_assets.py` still contain old
Spanish copies (some already differed from `words.json` before this change).
`expand_civic_wings.py` would overwrite the words it creates if rerun; do not rerun
either to change vocabulary — edit `words.json`.

## Body and organ words — 31 October 2026

User request: 26 body/organ entries, taught by the hospital anatomy model. Reused
existing keys: head, eye, ear, nose, mouth, arm, hand, leg, foot, stomach (plus heart and
brain, kept on the model). Added (Health & Body): face *la cara*, hair *el pelo / el
cabello*, tooth *el diente*, tongue *la lengua*, neck *el cuello*, shoulder *el hombro*,
finger *el dedo*, chest *el pecho*, back *la espalda*, belly *la barriga*, knee *la
rodilla*, toe *el dedo del pie*, liver *el hígado*, small intestine *el intestino
delgado*, large intestine *el intestino grueso*.

- **Hair** is one word with two synonyms (*el pelo / el cabello*), an approved exception
  to one translation per word, recorded in its `note`.
- **lung → lungs** (*los pulmones*); the alias keeps old saves.
- **skull, organ, torso** retired (`removed_with_objects`) with the outdoor display: a
  skull scared rather than taught, and chest/belly/back cover the torso.

